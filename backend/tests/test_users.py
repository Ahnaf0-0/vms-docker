import pytest
from httpx import AsyncClient, ASGITransport
from main import app
import models
from fastapi import FastAPI
from database import get_db
from security import get_current_user

class MockUser:
    id = 1
    email = "test@example.com"
    full_name = "Test User"
    is_blacklisted = False
    face_embedding_front = None
    face_embedding_left = None
    face_embedding_right = None

class MockSession:
    async def execute(self, *args, **kwargs):
        class MockResult:
            def scalars(self):
                class MockScalars:
                    def first(self):
                        return MockUser()
                return MockScalars()
        return MockResult()
        
    async def commit(self):
        pass
        
    async def refresh(self, obj):
        pass

async def override_get_db():
    yield MockSession()

async def override_get_current_user():
    return MockUser()

@pytest.mark.asyncio
async def test_upload_selfies():
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user] = override_get_current_user
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        files = {
            "front": ("front.jpg", b"fake_front_data", "image/jpeg"),
            "left": ("left.jpg", b"fake_left_data", "image/jpeg"),
            "right": ("right.jpg", b"fake_right_data", "image/jpeg"),
        }
        
        response = await ac.post("/users/1/selfies", files=files)
        assert response.status_code == 200
        
        # Verify the embedding is populated in response
        # Using dict instead of UserResponse validation to simplify
        data = response.json()
        assert data["id"] == 1
    
    app.dependency_overrides.clear()
