from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List
import uuid
from database import get_db
import models
import schemas
from security import get_current_user, get_current_officer

router = APIRouter(prefix="/appointments", tags=["Appointments"])

@router.post("/", response_model=schemas.AppointmentResponse, status_code=status.HTTP_201_CREATED)
async def create_appointment(
    appointment: schemas.AppointmentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    # Verify officer exists
    result = await db.execute(select(models.Officer).where(models.Officer.id == appointment.officer_id))
    officer = result.scalars().first()
    if not officer:
        raise HTTPException(status_code=404, detail="Officer not found")

    new_app = models.Appointment(
        visitor_id=current_user.id,
        officer_id=appointment.officer_id,
        purpose=appointment.purpose,
        requested_date=appointment.requested_date,
        status="Pending"
    )
    db.add(new_app)
    await db.commit()
    await db.refresh(new_app)
    
    # Load relationships for response
    result = await db.execute(
        select(models.Appointment)
        .options(selectinload(models.Appointment.officer), selectinload(models.Appointment.visitor))
        .where(models.Appointment.id == new_app.id)
    )
    return result.scalars().first()

@router.get("/visitor", response_model=List[schemas.AppointmentResponse])
async def list_visitor_appointments(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    result = await db.execute(
        select(models.Appointment)
        .options(selectinload(models.Appointment.officer))
        .where(models.Appointment.visitor_id == current_user.id)
        .order_by(models.Appointment.requested_date.desc())
    )
    return result.scalars().all()

@router.get("/officer", response_model=List[schemas.AppointmentResponse])
async def list_officer_appointments(
    db: AsyncSession = Depends(get_db),
    current_officer: models.Officer = Depends(get_current_officer)
):
    result = await db.execute(
        select(models.Appointment)
        .options(selectinload(models.Appointment.visitor))
        .where(models.Appointment.officer_id == current_officer.id)
        .order_by(models.Appointment.requested_date.desc())
    )
    return result.scalars().all()

@router.patch("/{appointment_id}/status", response_model=schemas.AppointmentResponse)
async def update_appointment_status(
    appointment_id: int,
    update_data: schemas.AppointmentUpdate,
    db: AsyncSession = Depends(get_db),
    current_officer: models.Officer = Depends(get_current_officer)
):
    result = await db.execute(
        select(models.Appointment)
        .options(selectinload(models.Appointment.visitor))
        .where(models.Appointment.id == appointment_id)
    )
    appointment = result.scalars().first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
        
    if appointment.officer_id != current_officer.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this appointment")
        
    appointment.status = update_data.status
    if update_data.status == "Postponed" and update_data.new_date:
        appointment.requested_date = update_data.new_date
    
    # Auto-generate QR token on approval
    if update_data.status == "Approved" and not appointment.qr_token:
        appointment.qr_token = str(uuid.uuid4())
        
    await db.commit()
    await db.refresh(appointment)
    return appointment

