import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
import numpy as np
from database import get_db
import models
import schemas
from services.ml_service import ml_service

router = APIRouter(prefix="/verify", tags=["Verification"])

FACE_MATCH_THRESHOLD = 0.7


def cosine_similarity(a: list[float], b: list[float]) -> float:
    a_arr = np.array(a)
    b_arr = np.array(b)
    dot = np.dot(a_arr, b_arr)
    norm_a = np.linalg.norm(a_arr)
    norm_b = np.linalg.norm(b_arr)
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return float(dot / (norm_a * norm_b))


@router.post("/qr", response_model=schemas.QRVerifyResponse)
async def verify_qr(
    payload: schemas.QRVerifyRequest,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(models.Appointment)
        .options(
            selectinload(models.Appointment.visitor),
            selectinload(models.Appointment.officer),
        )
        .where(models.Appointment.qr_token == payload.qr_token)
    )
    appointment = result.scalars().first()

    if not appointment:
        return schemas.QRVerifyResponse(valid=False, message="Token not found or invalid.")

    if appointment.status != "Approved":
        return schemas.QRVerifyResponse(valid=False, message="Appointment is not approved.")

    # Check same-day
    today = datetime.utcnow().date()
    appt_date = appointment.requested_date
    # Handle both datetime and date objects
    if hasattr(appt_date, 'date'):
        appt_date = appt_date.date()
    if appt_date != today:
        return schemas.QRVerifyResponse(valid=False, message="Appointment date has expired or is not today.")

    return schemas.QRVerifyResponse(
        valid=True,
        message="QR token is valid.",
        appointment=appointment,
    )


@router.post("/face", response_model=schemas.FaceVerifyResponse)
async def verify_face(
    qr_token: str = Form(...),
    selfie: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    # Look up appointment by token
    result = await db.execute(
        select(models.Appointment)
        .options(selectinload(models.Appointment.visitor))
        .where(models.Appointment.qr_token == qr_token)
    )
    appointment = result.scalars().first()

    if not appointment:
        return schemas.FaceVerifyResponse(match=False, confidence=0.0, message="Invalid QR token.")

    visitor = appointment.visitor
    if not visitor:
        return schemas.FaceVerifyResponse(match=False, confidence=0.0, message="Visitor not found.")

    # Generate embedding from the live selfie
    selfie_bytes = await selfie.read()
    live_embedding = ml_service.generate_embedding(selfie_bytes)

    # Compare against all 3 registered embeddings, take the best score
    scores = []
    for registered in [visitor.face_embedding_front, visitor.face_embedding_left, visitor.face_embedding_right]:
        if registered is not None:
            scores.append(cosine_similarity(live_embedding, registered))

    if not scores:
        return schemas.FaceVerifyResponse(match=False, confidence=0.0, message="No registered face embeddings found.")

    best_score = max(scores)
    is_match = best_score >= FACE_MATCH_THRESHOLD

    return schemas.FaceVerifyResponse(
        match=is_match,
        confidence=round(best_score, 4),
        message="Face match successful." if is_match else "Face does not match registered visitor.",
    )
