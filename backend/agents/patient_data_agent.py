import asyncio
import time
from models.incident import IncidentRequest

# GCS code lookup
GCS_CODES = {range(13, 16): 4, range(9, 13): 3, range(6, 9): 2, range(4, 6): 1, range(3, 4): 0}
SBP_CODES = [(90, 999, 4), (76, 90, 3), (50, 76, 2), (1, 50, 1), (0, 1, 0)]
RR_CODES = [(10, 30, 4), (30, 999, 3), (6, 10, 2), (1, 6, 1), (0, 1, 0)]


def _lookup_gcs_code(gcs: int) -> int:
    if gcs >= 13: return 4
    if gcs >= 9: return 3
    if gcs >= 6: return 2
    if gcs >= 4: return 1
    return 0


def _lookup_sbp_code(sbp: int) -> int:
    if sbp > 89: return 4
    if sbp >= 76: return 3
    if sbp >= 50: return 2
    if sbp >= 1: return 1
    return 0


def _lookup_rr_code(rr: int) -> int:
    if 10 <= rr <= 29: return 4
    if rr > 29: return 3
    if rr >= 6: return 2
    if rr >= 1: return 1
    return 0


def compute_rts(gcs: int, sbp: int, rr: int) -> float:
    gcs_code = _lookup_gcs_code(gcs)
    sbp_code = _lookup_sbp_code(sbp)
    rr_code = _lookup_rr_code(rr)
    return (0.9368 * gcs_code) + (0.7326 * sbp_code) + (0.2908 * rr_code)


def compute_severity_multiplier(rts: float) -> float:
    if rts >= 11: return 1.0
    if rts >= 8: return 1.2
    if rts >= 5: return 1.5
    return 1.7


async def run(incident: IncidentRequest) -> dict:
    start = time.time()
    await asyncio.sleep(0)  # yield to event loop (genuine async)
    rts = compute_rts(incident.gcs, incident.sbp, incident.rr)
    severity_multiplier = compute_severity_multiplier(rts)
    duration_ms = (time.time() - start) * 1000
    return {
        "rts": round(rts, 4),
        "severity_multiplier": severity_multiplier,
        "_started_at": start,
        "_duration_ms": duration_ms,
    }
