import hashlib
import numpy as np

class MLService:
    """
    Mock ML Service that generates deterministic mock embeddings
    based on the input bytes. This adheres to the YAGNI principle
    by not installing heavy ML dependencies during early iteration.
    """
    def generate_embedding(self, image_bytes: bytes) -> list[float]:
        # Hash the image bytes to get a deterministic integer
        h = hashlib.sha256(image_bytes).hexdigest()
        seed = int(h[:8], 16)
        
        # Use numpy with the seed to generate a mock embedding (e.g. 512-dim vector for insightface)
        rng = np.random.default_rng(seed)
        embedding = rng.normal(size=512)
        
        # Normalize to unit length
        embedding = embedding / np.linalg.norm(embedding)
        return embedding.tolist()

ml_service = MLService()
