import pytest
from httpx import AsyncClient, ASGITransport
from datetime import datetime, timedelta
from unittest.mock import patch
import uuid
from main import app
from database import get_db
from security import get_current_user, get_current_officer
import models
import numpy as np


# --- Mock Objects ---

class MockUser:
    id = 1
    email = "visitor@test.com"
    full_name = "Test Visitor"
    is_blacklisted = False
    face_embedding_front = np.random.default_rng(42).normal(size=512).tolist()
    face_embedding_left = np.random.default_rng(43).normal(size=512).tolist()
    face_embedding_right = np.random.default_rng(44).normal(size=512).tolist()


class MockOfficer:
    id = 2
    email = "officer@test.com"
    full_name = "Test Officer"
    department = "Security"


VALID_QR_TOKEN = str(uuid.uuid4())


class MockApprovedAppointment:
    id = 10
    visitor_id = 1
    officer_id = 2
    purpose = "Meeting"
    requested_date = datetime.utcnow()  # today
    status = "Approved"
    qr_token = VALID_QR_TOKEN
    visitor = MockUser()
    officer = MockOfficer()


class MockPendingAppointment:
    id = 11
    visitor_id = 1
    officer_id = 2
    purpose = "Meeting"
    requested_date = datetime.utcnow()
    status = "Pending"
    qr_token = None
    visitor = MockUser()
    officer = MockOfficer()


class MockExpiredAppointment:
    id = 12
    visitor_id = 1
    officer_id = 2
    purpose = "Old Meeting"
    requested_date = datetime.utcnow() - timedelta(days=5)
    status = "Approved"
    qr_token = "expired-token"
    visitor = MockUser()
    officer = MockOfficer()


# Tracks which token to look up
_mock_db_tokens = {
    VALID_QR_TOKEN: MockApprovedAppointment(),
    "expired-token": MockExpiredAppointment(),
}


class MockSession:
    async def execute(self, *args, **kwargs):
        query_str = str(args[0])
        parent = self

        class MockResult:
            def scalars(self):
                class MockScalars:
                    def first(self):
                        if "qr_token" in query_str:
                            # Extract the token from the bound params
                            for token, appt in _mock_db_tokens.items():
                                if token in query_str:
                                    return appt
                            return None
                        if "User" in query_str:
                            return MockUser()
                        return None
                return MockScalars()
        return MockResult()


async def override_get_db():
    yield MockSession()


async def override_get_current_user():
    return MockUser()


@pytest.fixture(autouse=True)
def setup_overrides():
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user] = override_get_current_user
    yield
    app.dependency_overrides.clear()


# --- RED: QR Verification Tests ---

@pytest.mark.asyncio
async def test_verify_qr_valid_token():
    """A valid QR token for an approved, same-day appointment should return valid=True."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/verify/qr",
            json={"qr_token": VALID_QR_TOKEN}
        )
    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is True
    assert data["appointment"]["id"] == 10


@pytest.mark.asyncio
async def test_verify_qr_invalid_token():
    """A non-existent token should return valid=False."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/verify/qr",
            json={"qr_token": "does-not-exist"}
        )
    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is False
    assert "not found" in data["message"].lower() or "invalid" in data["message"].lower()


@pytest.mark.asyncio
async def test_verify_qr_expired_date():
    """A token for an appointment on a past date should return valid=False."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/verify/qr",
            json={"qr_token": "expired-token"}
        )
    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is False
    assert "date" in data["message"].lower() or "expired" in data["message"].lower()


# --- RED: Face Verification Tests ---

@pytest.mark.asyncio
async def test_verify_face_matching_selfie():
    """A selfie generating an embedding close to the registered ones should return match=True."""
    # We patch ml_service to return an embedding identical to front embedding
    with patch("routers.verification.ml_service") as mock_ml:
        mock_ml.generate_embedding.return_value = MockUser.face_embedding_front
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            response = await ac.post(
                "/verify/face",
                data={"qr_token": VALID_QR_TOKEN},
                files={"selfie": ("selfie.jpg", b"fake-image-bytes", "image/jpeg")}
            )
    assert response.status_code == 200
    data = response.json()
    assert data["match"] is True
    assert data["confidence"] >= 0.7


@pytest.mark.asyncio
async def test_verify_face_non_matching_selfie():
    """A selfie generating a random embedding should return match=False."""
    random_embedding = np.random.default_rng(999).normal(size=512).tolist()
    with patch("routers.verification.ml_service") as mock_ml:
        mock_ml.generate_embedding.return_value = random_embedding
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            response = await ac.post(
                "/verify/face",
                data={"qr_token": VALID_QR_TOKEN},
                files={"selfie": ("selfie.jpg", b"fake-image-bytes", "image/jpeg")}
            )
    assert response.status_code == 200
    data = response.json()
    assert data["match"] is False
    assert data["confidence"] < 0.7
