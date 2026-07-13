from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from datetime import datetime
from database import Base

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    company = Column(String, nullable=True)
    designation = Column(String, nullable=True)
    is_blacklisted = Column(Boolean, default=False)
    
    # Encrypted fields
    encrypted_phone = Column(String, nullable=True)
    encrypted_nid = Column(String, nullable=True)
    
    # 3 face embeddings (size typical for insightface is 512, adjust as needed)
    face_embedding_front = Column(Vector(512), nullable=True)
    face_embedding_left = Column(Vector(512), nullable=True)
    face_embedding_right = Column(Vector(512), nullable=True)
    
    appointments = relationship("Appointment", back_populates="visitor")

class Officer(Base):
    __tablename__ = 'officers'
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, index=True)
    department = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    status = Column(String, default="Active") # Active, Transferred
    
    appointments = relationship("Appointment", back_populates="officer")

class Admin(Base):
    __tablename__ = 'admins'
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)

class Appointment(Base):
    __tablename__ = 'appointments'
    id = Column(Integer, primary_key=True, index=True)
    visitor_id = Column(Integer, ForeignKey('users.id'))
    officer_id = Column(Integer, ForeignKey('officers.id'))
    
    purpose = Column(Text)
    requested_date = Column(DateTime)
    status = Column(String, default="Pending") # Pending, Approved, Cancelled, Postponed
    
    qr_token = Column(String, nullable=True) # Token valid for QR code
    entry_time = Column(DateTime, nullable=True)
    exit_time = Column(DateTime, nullable=True)
    
    visitor = relationship("User", back_populates="appointments")
    officer = relationship("Officer", back_populates="appointments")
