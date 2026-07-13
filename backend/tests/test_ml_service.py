import pytest
from services.ml_service import ml_service
import numpy as np

def test_generate_embedding_deterministic():
    img1 = b"test_image_data_1"
    img2 = b"test_image_data_2"
    
    emb1 = ml_service.generate_embedding(img1)
    emb2 = ml_service.generate_embedding(img2)
    emb1_again = ml_service.generate_embedding(img1)
    
    assert len(emb1) == 512
    assert len(emb2) == 512
    assert emb1 == emb1_again  # Deterministic
    assert emb1 != emb2  # Different seeds
    
    # Check unit length
    norm = np.linalg.norm(emb1)
    assert np.isclose(norm, 1.0)
