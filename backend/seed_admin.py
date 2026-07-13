import asyncio
import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy.future import select

from database import DATABASE_URL
import models
from security import get_password_hash

async def seed_admin():
    engine = create_async_engine(DATABASE_URL, echo=True)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    print("Attempting to seed initial super-admin...")

    async with async_session() as db:
        # Check if an admin already exists
        result = await db.execute(select(models.Admin).where(models.Admin.email == "admin@bcghq.gov.bd"))
        existing_admin = result.scalars().first()

        if existing_admin:
            print("Admin already exists. Skipping seed.")
        else:
            # Create the super admin
            # Use environment variable for initial password in a real app, hardcoded here for testing
            raw_password = os.getenv("INITIAL_ADMIN_PASSWORD", "SuperSecure123!")
            hashed_pwd = get_password_hash(raw_password)

            new_admin = models.Admin(
                full_name="System Administrator",
                email="admin@bcghq.gov.bd",
                hashed_password=hashed_pwd
            )
            db.add(new_admin)
            await db.commit()
            print("Successfully created the initial super-admin account.")
            print(f"Email: admin@bcghq.gov.bd")
            print(f"Password: {raw_password}")
            
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(seed_admin())
