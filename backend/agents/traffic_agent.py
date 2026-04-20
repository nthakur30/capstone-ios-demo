import asyncio
import time
import math
import random
from typing import List, Optional
from models.hospital import Hospital
from models.incident import IncidentRequest


def haversine_miles(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 3958.8  # Earth radius in miles
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def compute_transport_time(distance_miles: float, traffic_penalty: float) -> float:
    # 2 min/mile + traffic penalty
    return (distance_miles * 2.0) + traffic_penalty


async def run(incident: IncidentRequest, hospitals: List[Hospital]) -> dict:
    start = time.time()
    await asyncio.sleep(0)
    results = {}
    # Seed by incident_id for reproducibility; fallback to random seed
    seed_str = incident.incident_id or f"{incident.patient_lat:.4f}{incident.patient_lng:.4f}"
    rng = random.Random(hash(seed_str) % (2**32))

    for h in hospitals:
        dist = haversine_miles(incident.patient_lat, incident.patient_lng, h.lat, h.lng)
        traffic_penalty = rng.uniform(0.0, 5.0)
        transport_time = compute_transport_time(dist, traffic_penalty)
        results[h.id] = {
            "distance_miles": round(dist, 3),
            "traffic_penalty": round(traffic_penalty, 2),
            "transport_time": round(transport_time, 2),
        }
    duration_ms = (time.time() - start) * 1000
    return {"transport": results, "_started_at": start, "_duration_ms": duration_ms}
