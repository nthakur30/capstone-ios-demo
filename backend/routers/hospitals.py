import random
from fastapi import APIRouter
from services.data_loader import load_hospitals, refresh_hospitals

router = APIRouter(prefix="/api/hospitals", tags=["hospitals"])


@router.get("")
def get_hospitals():
    hospitals = load_hospitals()
    return [h.model_dump() for h in hospitals]


@router.post("/refresh")
def refresh_ed_metrics():
    """Re-randomize ED occupancy for demo resets."""
    hospitals = refresh_hospitals(seed=random.randint(0, 9999))
    return [h.model_dump() for h in hospitals]
