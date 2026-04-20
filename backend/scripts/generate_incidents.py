"""
Run once: python scripts/generate_incidents.py
Generates 500 seeded EMS incidents and saves to data/incidents.json
"""
import json
import random
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

# DC metro bounding box
LAT_MIN, LAT_MAX = 38.75, 39.05
LNG_MIN, LNG_MAX = -77.30, -76.85

CONDITIONS = ["STEMI", "STROKE", "TRAUMA", "GENERAL"]
# 125 of each condition

# Realistic vitals by condition
VITALS_BY_CONDITION = {
    "STEMI": {
        "gcs": (10, 15),   # mostly alert but some altered
        "sbp": (70, 130),  # hypotension common
        "rr":  (12, 28),
    },
    "STROKE": {
        "gcs": (7, 14),    # altered mentation
        "sbp": (130, 220), # hypertension
        "rr":  (12, 24),
    },
    "TRAUMA": {
        "gcs": (3, 15),    # wide range
        "sbp": (50, 140),  # hemorrhagic shock possible
        "rr":  (8, 35),
    },
    "GENERAL": {
        "gcs": (13, 15),   # mostly alert
        "sbp": (90, 160),
        "rr":  (14, 22),
    },
}

rng = random.Random(42)

incidents = []
for i, condition in enumerate(c for c in CONDITIONS for _ in range(125)):
    v = VITALS_BY_CONDITION[condition]
    incident = {
        "incident_id": f"INC-{i+1:04d}",
        "patient_lat": round(rng.uniform(LAT_MIN, LAT_MAX), 6),
        "patient_lng": round(rng.uniform(LNG_MIN, LNG_MAX), 6),
        "condition": condition,
        "gcs": rng.randint(*v["gcs"]),
        "sbp": rng.randint(*v["sbp"]),
        "rr": rng.randint(*v["rr"]),
    }
    incidents.append(incident)

out_path = Path(__file__).parent.parent / "data" / "incidents.json"
out_path.parent.mkdir(exist_ok=True)
with open(out_path, "w") as f:
    json.dump(incidents, f, indent=2)

print(f"Generated {len(incidents)} incidents → {out_path}")
