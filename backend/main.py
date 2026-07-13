from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from datetime import timedelta
from contextlib import asynccontextmanager

from database import engine, Base, get_db
import models, schemas, security
from routers import users, appointments, verification, admin

@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── Schema Management ─────────────────────────────────────────────────────
    # Table creation is now handled by Alembic migrations.
    # Run `alembic upgrade head` to apply all pending migrations.
    # DO NOT use create_all in production — it cannot handle schema changes.
    #
    # async with engine.begin() as conn:
    #     await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(title="BCGHQ VMS API", lifespan=lifespan)

app.include_router(users.router)
app.include_router(appointments.router)
app.include_router(verification.router)
app.include_router(admin.router)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
async def register_user(user_in: schemas.UserCreate, db: AsyncSession = Depends(get_db)):
    # Check if user exists
    result = await db.execute(select(models.User).where(models.User.email == user_in.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Email already registered")
        
    # Encrypt PII
    encrypted_phone = security.encrypt_data(user_in.phone) if user_in.phone else None
    encrypted_nid = security.encrypt_data(user_in.nid) if user_in.nid else None
    
    # Hash password
    hashed_pwd = security.get_password_hash(user_in.password)
    
    new_user = models.User(
        full_name=user_in.full_name,
        email=user_in.email,
        hashed_password=hashed_pwd,
        company=user_in.company,
        designation=user_in.designation,
        encrypted_phone=encrypted_phone,
        encrypted_nid=encrypted_nid
    )
    
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    return new_user

@app.post("/login", response_model=schemas.Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    # Simple login logic checking users then officers then admin
    # In a real app, you might want separate login endpoints or a role field in the request
    
    # Check User
    result = await db.execute(select(models.User).where(models.User.email == form_data.username))
    user = result.scalars().first()
    if user and security.verify_password(form_data.password, user.hashed_password):
        access_token = security.create_access_token(
            subject=user.id, role="visitor", expires_delta=timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        return {"access_token": access_token, "token_type": "bearer", "role": "visitor"}

    # Check Officer
    result = await db.execute(select(models.Officer).where(models.Officer.email == form_data.username))
    officer = result.scalars().first()
    if officer and security.verify_password(form_data.password, officer.hashed_password):
        access_token = security.create_access_token(
            subject=officer.id, role="officer", expires_delta=timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        return {"access_token": access_token, "token_type": "bearer", "role": "officer"}

    # Check Admin
    result = await db.execute(select(models.Admin).where(models.Admin.email == form_data.username))
    admin = result.scalars().first()
    if admin and security.verify_password(form_data.password, admin.hashed_password):
        access_token = security.create_access_token(
            subject=admin.id, role="admin", expires_delta=timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        return {"access_token": access_token, "token_type": "bearer", "role": "admin"}
        
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Incorrect email or password",
        headers={"WWW-Authenticate": "Bearer"},
    )
