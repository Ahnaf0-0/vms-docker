from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from database import get_db
import models
import schemas
from security import get_current_user
from services.ml_service import ml_service

router = APIRouter(prefix="/users", tags=["Users"])

@router.post("/{user_id}/selfies", response_model=schemas.UserResponse)
async def upload_selfies(
    user_id: int,
    front: UploadFile = File(...),
    left: UploadFile = File(...),
    right: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this user's selfies")
        
    result = await db.execute(select(models.User).where(models.User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    front_bytes = await front.read()
    left_bytes = await left.read()
    right_bytes = await right.read()
    
    # Generate embeddings
    emb_front = ml_service.generate_embedding(front_bytes)
    emb_left = ml_service.generate_embedding(left_bytes)
    emb_right = ml_service.generate_embedding(right_bytes)
    
    user.face_embedding_front = emb_front
    user.face_embedding_left = emb_left
    user.face_embedding_right = emb_right
    
    await db.commit()
    await db.refresh(user)
    
    return user
