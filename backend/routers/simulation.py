"""
Simulation router — uses pre-computed risk scores from the paper's Excel data.
This reproduces the exact statistics reported in the capstone paper.
"""
import math
from fastapi import APIRouter, Query
from services.data_loader import load_incidents
from services.stats_service import compute_batch_stats
from models.routing_result import BatchStats

router = APIRouter(prefix="/api/simulate", tags=["simulation"])


def _mean(vals):
    return sum(vals) / len(vals) if vals else 0.0


def _std(vals, ddof=1):
    if len(vals) < 2:
        return 0.0
    m = _mean(vals)
    return math.sqrt(sum((x - m) ** 2 for x in vals) / (len(vals) - ddof))


@router.post("/batch")
def run_batch_simulation(k: int = Query(default=7, ge=7, le=8)):
    """
    Run batch simulation using pre-computed risk scores from the paper's Excel data.
    Reproduces exact statistics: mean delta ~3.91 (k=7), t(499)=14.37, p<0.001, d=0.64.
    """
    raw_incidents = load_incidents()

    ai_scores = []
    traditional_scores = []
    condition_buckets: dict = {}

    for inc in raw_incidents:
        ai_score = float(inc.get(f"risk_ai_k{k}", 0) or 0)
        trad_score = float(inc.get(f"risk_trad_k{k}", 0) or 0)

        ai_scores.append(ai_score)
        traditional_scores.append(trad_score)

        cond = inc.get("condition", "GENERAL")
        if cond not in condition_buckets:
            condition_buckets[cond] = {"ai": [], "trad": []}
        condition_buckets[cond]["ai"].append(ai_score)
        condition_buckets[cond]["trad"].append(trad_score)

    overall = compute_batch_stats(ai_scores, traditional_scores)

    by_condition = {}
    for cond, buckets in condition_buckets.items():
        deltas = [a - t for a, t in zip(buckets["ai"], buckets["trad"])]
        by_condition[cond] = {
            "n": len(deltas),
            "mean_delta": round(_mean(deltas), 4),
            "std_delta": round(_std(deltas), 4),
        }

    return BatchStats(**overall, by_condition=by_condition).model_dump()


@router.get("/incidents/sample")
def get_sample_incidents(n: int = Query(default=10, le=500)):
    """Return a sample of incidents for inspection."""
    return load_incidents()[:n]
