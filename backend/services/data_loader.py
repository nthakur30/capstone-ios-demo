import json
import random
from pathlib import Path
from typing import List
from models.hospital import Hospital

DATA_DIR = Path(__file__).parent.parent / "data"
_hospitals: List[Hospital] = []


def load_hospitals() -> List[Hospital]:
    global _hospitals
    if not _hospitals:
        with open(DATA_DIR / "hospitals.json") as f:
            data = json.load(f)
        _hospitals = [Hospital(**h) for h in data]
    return _hospitals


def refresh_hospitals(seed: int = None) -> List[Hospital]:
    """Re-randomize ED occupancy for demo reset."""
    global _hospitals
    rng = random.Random(seed)
    hospitals = load_hospitals()
    refreshed = []
    for h in hospitals:
        new_patients = int(h.ed_capacity * rng.uniform(0.55, 1.30))
        new_patients = min(new_patients, int(h.ed_capacity * 1.40))
        data = h.model_dump()
        data["ed_current_patients"] = new_patients
        refreshed.append(Hospital(**data))
    _hospitals = refreshed
    return _hospitals


def load_incidents() -> list:
    with open(DATA_DIR / "incidents.json") as f:
        return json.load(f)
