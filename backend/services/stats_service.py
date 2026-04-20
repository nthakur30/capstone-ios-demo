"""
Stats service — no scipy/numpy dependency (Python 3.14 compat).
Implements paired t-test and Cohen's d using stdlib math only.
"""
import math
from typing import List


def _mean(values: List[float]) -> float:
    return sum(values) / len(values)


def _std(values: List[float], ddof: int = 1) -> float:
    m = _mean(values)
    variance = sum((x - m) ** 2 for x in values) / (len(values) - ddof)
    return math.sqrt(variance)


def _norm_cdf(z: float) -> float:
    """Standard normal CDF via math.erfc."""
    return 0.5 * math.erfc(-z / math.sqrt(2))


def _two_tail_p(t: float) -> float:
    """Two-tailed p-value using normal approximation (valid for n >= 100)."""
    p = 2.0 * (1.0 - _norm_cdf(abs(t)))
    return max(p, 1e-10)


def compute_batch_stats(ai_scores: List[float], traditional_scores: List[float]) -> dict:
    deltas = [a - t for a, t in zip(ai_scores, traditional_scores)]
    n = len(deltas)
    mean_delta = _mean(deltas)
    std_delta = _std(deltas, ddof=1)
    se = std_delta / math.sqrt(n)
    t_stat = mean_delta / se if se > 0 else 0.0
    p_value = _two_tail_p(t_stat)
    cohens_d = mean_delta / std_delta if std_delta > 0 else 0.0

    ai_wins = sum(1 for d in deltas if d > 0)
    trad_wins = sum(1 for d in deltas if d < 0)
    ties = sum(1 for d in deltas if d == 0)

    return {
        "n_cases": n,
        "mean_delta": round(mean_delta, 4),
        "std_delta": round(std_delta, 4),
        "t_statistic": round(t_stat, 4),
        "p_value": round(p_value, 6),
        "cohens_d": round(abs(cohens_d), 4),
        "ai_wins": ai_wins,
        "traditional_wins": trad_wins,
        "tie": ties,
    }
