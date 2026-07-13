import pytest
from httpx import AsyncClient, ASGITransport
from datetime import datetime, timedelta
from unittest.mock import patch
from main import app
from database import get_db
from security import get_current_admin
import models

# --- Mock Objects ---
class MockUser:
    id = 1
    email = "visitor@test.com"
    full_name = "Test Visitor"
    is_blacklisted = False

class MockOfficer:
    id = 2
    email = "officer@test.com"
    full_name = "Test Officer"
    department = "Security"
    status = "Active"

class MockAdmin:
    id = 3
    email = "admin@bcghq.gov.bd"
    full_name = "System Administrator"

class MockAppointment:
    id = 10
    visitor_id = 1
    officer_id = 2
    purpose = "Meeting"
    requested_date = datetime.utcnow()
    status = "Approved"
    qr_token = "fake-token"
    entry_time = None
    exit_time = None

class MockSession:
    async def execute(self, *args, **kwargs):
        query_str = str(args[0])
        
        class MockResult:
            def scalars(self):
                class MockScalars:
                    def first(self):
                        q = query_str.lower()
                        if "email" in q:
                            return None
                        if "users" in q:
                            return MockUser()
                        elif "officer" in q:
                            return MockOfficer()
                        return None
                    def all(self):
                        q = query_str.lower()
                        if "officer" in q:
                            return [MockOfficer()]
                        elif "users" in q:
                            return [MockUser()]
                        elif "appointment" in q:
                            return [MockAppointment()]
                        return []
                return MockScalars()
                
            def scalar_one(self):
                return 5 # Dummy count
                
        return MockResult()
        
    async def commit(self):
        pass
        
    async def refresh(self, obj):
        pass
        
    def add(self, obj):
        obj.id = 99

async def override_get_db():
    yield MockSession()

async def override_get_current_admin():
    return MockAdmin()

@pytest.fixture(autouse=True)
def setup_overrides():
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_admin] = override_get_current_admin
    yield
    app.dependency_overrides.clear()

# --- RED: Admin TDD Tests ---

@pytest.mark.asyncio
async def test_create_officer():
    """An admin should be able to create a new officer."""
    payload = {
        "full_name": "New Officer",
        "email": "new.officer@test.com",
        "password": "SecurePassword123!",
        "department": "Operations"
    }
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/admin/officers", json=payload)
    
    assert response.status_code == 201
    data = response.json()
    assert data["full_name"] == "New Officer"
    assert data["department"] == "Operations"
    assert "password" not in data

@pytest.mark.asyncio
async def test_update_officer_status():
    """An admin should be able to mark an officer as transferred."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.patch(
            "/admin/officers/2/status",
            json={"status": "Transferred"}
        )
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "Transferred"

@pytest.mark.asyncio
async def test_toggle_visitor_blacklist():
    """An admin should be able to toggle a visitor's blacklist status."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.patch(
            "/admin/users/1/blacklist",
            json={"is_blacklisted": True}
        )
    
    assert response.status_code == 200
    data = response.json()
    assert data["is_blacklisted"] is True

@pytest.mark.asyncio
async def test_get_system_reports():
    """An admin should be able to fetch comprehensive system reports."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/admin/reports")
    
    assert response.status_code == 200
    data = response.json()
    
    # Assert all requested fields are present
    assert "total_officers" in data
    assert "total_visitors" in data
    assert "pending_appointments" in data
    assert "accepted_appointments" in data
    assert "daily_appointments" in data
    assert "blacklisted_users" in data
    assert "present_officers" in data
    assert "transferred_officers" in data
    
    # Assert the list shapes
    assert isinstance(data["daily_appointments"], list)
    assert isinstance(data["blacklisted_users"], list)
    assert isinstance(data["present_officers"], list)
    assert isinstance(data["transferred_officers"], list)
