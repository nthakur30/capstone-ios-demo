import asyncio
import time
from typing import List
from models.hospital import Hospital
from models.incident import ConditionType

# Specialty match: minimum 1 (never 0 - avoids zero-product in DUF)
SPECIALTY_MATCH_TABLE = {
    "STEMI":   {"cath_lab": 3, "stroke_center": 1, "trauma_l1": 1, "trauma_l2": 1, "general": 1},
    "STROKE":  {"cath_lab": 1, "stroke_center": 3, "trauma_l1": 1, "trauma_l2": 1, "general": 1},
    "TRAUMA":  {"cath_lab": 1, "stroke_center": 1, "trauma_l1": 3, "trauma_l2": 2, "general": 1},
    "GENERAL": {"cath_lab": 1, "stroke_center": 1, "trauma_l1": 1, "trauma_l2": 1, "general": 1},
}


def compute_specialty_match(condition: ConditionType, hospital: Hospital) -> int:
    table = SPECIALTY_MATCH_TABLE[condition]
    caps = hospital.capabilities
    if condition == "STEMI" and caps.cath_lab:
        return table["cath_lab"]
    if condition == "STROKE" and caps.stroke_center:
        return table["stroke_center"]
    if condition == "TRAUMA":
        if caps.trauma_l1:
            return table["trauma_l1"]
        if caps.trauma_l2:
            return table["trauma_l2"]
    return table["general"]  # always >= 1


def compute_ed_overcrowding_score(occupancy_rate: float) -> float:
    # Range [0.5, 2.0] — linear transformation of occupancy
    score = (occupancy_rate * 2.5) - 1.0
    return max(0.5, min(2.0, score))


def compute_ed_delay(ed_overcrowding_score: float) -> float:
    # 10 min baseline + 14 min per overcrowding unit
    return 10.0 + (14.0 * ed_overcrowding_score)


async def run(hospitals: List[Hospital], condition: ConditionType) -> dict:
    start = time.time()
    await asyncio.sleep(0)
    results = {}
    for h in hospitals:
        occ = h.occupancy_rate
        ocs = compute_ed_overcrowding_score(occ)
        ed_delay = compute_ed_delay(ocs)
        sm = compute_specialty_match(condition, h)
        results[h.id] = {
            "occupancy_rate": round(occ, 3),
            "ed_overcrowding_score": round(ocs, 3),
            "ed_delay_minutes": round(ed_delay, 2),
            "specialty_match": sm,
        }
    duration_ms = (time.time() - start) * 1000
    return {"metrics": results, "_started_at": start, "_duration_ms": duration_ms}
