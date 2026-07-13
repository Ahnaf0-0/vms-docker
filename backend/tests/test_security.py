import pytest
from jose import jwt
from security import (
    verify_password,
    get_password_hash,
    create_access_token,
    encrypt_data,
    decrypt_data,
    SECRET_KEY,
    ALGORITHM
)

def test_password_hashing():
    password = "supersecretpassword123"
    hashed = get_password_hash(password)
    
    assert hashed != password
    assert verify_password(password, hashed) is True
    assert verify_password("wrongpassword", hashed) is False

def test_create_access_token():
    subject = "123"
    role = "officer"
    
    token = create_access_token(subject, role)
    decoded = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    
    assert decoded["sub"] == subject
    assert decoded["role"] == role
    assert "exp" in decoded

def test_encryption():
    data = "Sensitive NID: 1234567890"
    encrypted = encrypt_data(data)
    
    assert encrypted != data
    assert decrypt_data(encrypted) == data
    
def test_encryption_empty():
    assert encrypt_data(None) is None
    assert decrypt_data(None) is None
