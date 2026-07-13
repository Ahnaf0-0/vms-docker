from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy import func
from datetime import datetime, timedelta
import models
import schemas
from database import get_db
from security import get_current_admin, get_password_hash

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.post("/officers", response_model=schemas.OfficerResponse, status_code=status.HTTP_201_CREATED)
async def create_officer(
    officer_in: schemas.OfficerCreate,
    db: AsyncSession = Depends(get_db),
    admin: models.Admin = Depends(get_current_admin)
):
    # Check if email exists
    result = await db.execute(select(models.Officer).where(models.Officer.email == officer_in.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Email already registered")
        
    hashed_pwd = get_password_hash(officer_in.password)
    
    new_officer = models.Officer(
        full_name=officer_in.full_name,
        email=officer_in.email,
        department=officer_in.department,
        hashed_password=hashed_pwd,
        status="Active"
    )
    db.add(new_officer)
    await db.commit()
    await db.refresh(new_officer)
    return new_officer

@router.patch("/officers/{officer_id}/status", response_model=schemas.OfficerResponse)
async def update_officer_status(
    officer_id: int,
    payload: schemas.OfficerUpdateStatus,
    db: AsyncSession = Depends(get_db),
    admin: models.Admin = Depends(get_current_admin)
):
    result = await db.execute(select(models.Officer).where(models.Officer.id == officer_id))
    officer = result.scalars().first()
    if not officer:
        raise HTTPException(status_code=404, detail="Officer not found")
        
    officer.status = payload.status
    await db.commit()
    await db.refresh(officer)
    return officer

@router.patch("/users/{user_id}/blacklist", response_model=schemas.UserResponse)
async def toggle_blacklist(
    user_id: int,
    payload: schemas.UserUpdateBlacklist,
    db: AsyncSession = Depends(get_db),
    admin: models.Admin = Depends(get_current_admin)
):
    result = await db.execute(select(models.User).where(models.User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.is_blacklisted = payload.is_blacklisted
    await db.commit()
    await db.refresh(user)
    return user

@router.get("/reports", response_model=schemas.SystemReportResponse)
async def get_system_reports(
    db: AsyncSession = Depends(get_db),
    admin: models.Admin = Depends(get_current_admin)
):
    # 1. Total Officers & Visitors
    officers_count_res = await db.execute(select(func.count(models.Officer.id)))
    visitors_count_res = await db.execute(select(func.count(models.User.id)))
    
    # 2. Appointment Stats
    pending_res = await db.execute(select(func.count(models.Appointment.id)).where(models.Appointment.status == "Pending"))
    accepted_res = await db.execute(select(func.count(models.Appointment.id)).where(models.Appointment.status == "Approved"))
    
    # 3. Daily Appointments (Today)
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)
    daily_res = await db.execute(
        select(models.Appointment)
        .options(selectinload(models.Appointment.visitor), selectinload(models.Appointment.officer))
        .where(models.Appointment.requested_date >= today_start)
        .where(models.Appointment.requested_date < today_end)
    )
    daily_appointments = daily_res.scalars().all()
    
    # 4. Blacklisted Users
    blacklist_res = await db.execute(select(models.User).where(models.User.is_blacklisted == True))
    blacklisted_users = blacklist_res.scalars().all()
    
    # 5. Officers by Status
    active_res = await db.execute(select(models.Officer).where(models.Officer.status == "Active"))
    transferred_res = await db.execute(select(models.Officer).where(models.Officer.status == "Transferred"))
    
    return schemas.SystemReportResponse(
        total_officers=officers_count_res.scalar_one(),
        total_visitors=visitors_count_res.scalar_one(),
        pending_appointments=pending_res.scalar_one(),
        accepted_appointments=accepted_res.scalar_one(),
        daily_appointments=daily_appointments,
        blacklisted_users=blacklisted_users,
        present_officers=active_res.scalars().all(),
        transferred_officers=transferred_res.scalars().all()
    )
