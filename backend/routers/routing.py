import asyncio
from fastapi import APIRouter, HTTPException
from models.incident import IncidentRequest
from agents.routing_coordinator import route
from services.data_loader import load_hospitals

router = APIRouter(prefix="/api", tags=["routing"])


@router.post("/route")
async def route_incident(incident: IncidentRequest):
    hospitals = load_hospitals()
    if not hospitals:
        raise HTTPException(status_code=500, detail="No hospital data loaded")
    result = await route(incident, hospitals)
    return result.model_dump()


@router.get("/incidents/random")
def get_random_incident():
    """Return a random pre-built demo preset."""
    from services.data_loader import load_incidents
    import random
    incidents = load_incidents()
    return random.choice(incidents)
