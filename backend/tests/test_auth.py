import pytest
from httpx import AsyncClient, ASGITransport
from main import app
from database import get_db

# Mock database session for auth tests
class MockSession:
    async def execute(self, *args, **kwargs):
        class MockResult:
            def scalars(self):
                class MockScalars:
                    def first(self):
                        return None
                return MockScalars()
        return MockResult()
    
    def add(self, *args, **kwargs):
        pass
        
    async def commit(self):
        pass
        
    async def refresh(self, obj):
        # assign mock database defaults
        obj.id = 1
        obj.is_blacklisted = False

async def override_get_db():
    yield MockSession()

@pytest.mark.asyncio
async def test_register_user():
    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/register", 
            json={
                "full_name": "Test User",
                "email": "test@example.com",
                "password": "strongpassword",
                "phone": "123456789",
                "nid": "NID123"
            }
        )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["full_name"] == "Test User"
    assert data["is_blacklisted"] is False
    assert "id" in data
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_login_user_not_found():
    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/login", 
            data={
                "username": "wrong@example.com",
                "password": "wrongpassword"
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
    assert response.status_code == 401
    app.dependency_overrides.clear()
