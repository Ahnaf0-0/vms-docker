from pydantic import BaseModel, EmailStr
from typing import Optional, List

# Token Schemas
class Token(BaseModel):
    access_token: str
    token_type: str
    role: str

# User Schemas
class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    phone: Optional[str] = None
    nid: Optional[str] = None
    company: Optional[str] = None
    designation: Optional[str] = None
    # Assuming face images will be uploaded as multipart/form-data separately or base64
    # We will handle face registration through a separate endpoint for now
    
class UserResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    is_blacklisted: bool
    
    class Config:
        from_attributes = True

# Officer Schemas
class OfficerCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    department: str

class OfficerResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    department: str
    status: str

    class Config:
        from_attributes = True

# Appointment Schemas
from datetime import datetime

class AppointmentCreate(BaseModel):
    officer_id: int
    purpose: str
    requested_date: datetime

class AppointmentUpdate(BaseModel):
    status: str # "Approved", "Cancelled", "Postponed"
    new_date: Optional[datetime] = None # Used if status is Postponed

class AppointmentResponse(BaseModel):
    id: int
    visitor_id: int
    officer_id: int
    purpose: str
    requested_date: datetime
    status: str
    qr_token: Optional[str] = None
    entry_time: Optional[datetime] = None
    exit_time: Optional[datetime] = None
    
    # Nested relations (optional for response)
    visitor: Optional[UserResponse] = None
    officer: Optional[OfficerResponse] = None

    class Config:
        from_attributes = True

# Verification Schemas
class QRVerifyRequest(BaseModel):
    qr_token: str

class QRVerifyResponse(BaseModel):
    valid: bool
    message: str
    appointment: Optional[AppointmentResponse] = None

class FaceVerifyResponse(BaseModel):
    match: bool
    confidence: float
    message: str

# Admin Schemas
class OfficerUpdateStatus(BaseModel):
    status: str # "Active", "Transferred"

class UserUpdateBlacklist(BaseModel):
    is_blacklisted: bool

class SystemReportResponse(BaseModel):
    total_officers: int
    total_visitors: int
    pending_appointments: int
    accepted_appointments: int
    daily_appointments: List[AppointmentResponse]
    blacklisted_users: List[UserResponse]
    present_officers: List[OfficerResponse]
    transferred_officers: List[OfficerResponse]
