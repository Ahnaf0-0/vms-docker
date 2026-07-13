import pytest
from httpx import AsyncClient, ASGITransport
from datetime import datetime, timedelta
from main import app
from database import get_db
from security import get_current_user, get_current_officer
import models

class MockUser:
    id = 1
    email = "visitor@test.com"
    full_name = "Test Visitor"

class MockOfficer:
    id = 2
    email = "officer@test.com"
    full_name = "Test Officer"
    department = "Security"

class MockAppointment:
    id = 1
    visitor_id = 1
    officer_id = 2
    purpose = "Meeting"
    requested_date = datetime.utcnow()
    status = "Pending"
    qr_token = None
    officer = MockOfficer()
    visitor = MockUser()

class MockSession:
    async def execute(self, *args, **kwargs):
        class MockResult:
            def scalars(self):
                class MockScalars:
                    def first(self):
                        query = str(args[0])
                        if "Officer" in query and "id =" in query:
                            return MockOfficer()
                        elif "Appointment" in query:
                            return MockAppointment()
                        return None
                    def all(self):
                        return [MockAppointment()]
                return MockScalars()
        return MockResult()
    
    def add(self, *args, **kwargs):
        pass
        
    async def commit(self):
        pass
        
    async def refresh(self, obj):
        obj.id = 1
        
async def override_get_db():
    yield MockSession()

async def override_get_current_user():
    return MockUser()

async def override_get_current_officer():
    return MockOfficer()

@pytest.fixture(autouse=True)
def setup_overrides():
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user] = override_get_current_user
    app.dependency_overrides[get_current_officer] = override_get_current_officer
    yield
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_create_appointment():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        req_date = (datetime.utcnow() + timedelta(days=1)).isoformat()
        response = await ac.post(
            "/appointments/", 
            json={
                "officer_id": 2,
                "purpose": "Security Audit",
                "requested_date": req_date
            }
        )
    assert response.status_code == 201
    data = response.json()
    assert data["officer_id"] == 2
    assert data["status"] == "Pending"

@pytest.mark.asyncio
async def test_list_visitor_appointments():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/appointments/visitor")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["visitor_id"] == 1

@pytest.mark.asyncio
async def test_list_officer_appointments():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/appointments/officer")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["officer_id"] == 2

@pytest.mark.asyncio
async def test_update_appointment_status():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.patch(
            "/appointments/1/status",
            json={
                "status": "Approved"
            }
        )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "Approved"
