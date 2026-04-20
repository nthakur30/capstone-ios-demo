from pydantic import BaseModel
from typing import List, Optional
from models.hospital import HospitalWithMetrics


class AgentTrace(BaseModel):
    agent: str
    started_at_ms: float  # ms offset from request start
    duration_ms: float
    output_summary: dict


class RoutingRecommendation(BaseModel):
    hospital_id: str
    hospital_name: str
    duf_score: float
    transport_time: float
    ed_delay: float
    specialty_match: int
    risk_score: float
    rts: float
    severity_multiplier: float


class RoutingResponse(BaseModel):
    ai_recommendation: RoutingRecommendation
    traditional_recommendation: RoutingRecommendation
    delta_risk: float  # ai - traditional (positive = AI wins)
    all_hospitals_scored: List[HospitalWithMetrics]
    agent_traces: List[AgentTrace]


class BatchStats(BaseModel):
    n_cases: int
    mean_delta: float
    std_delta: float
    t_statistic: float
    p_value: float
    cohens_d: float
    ai_wins: int
    traditional_wins: int
    tie: int
    by_condition: dict  # {"STEMI": {"mean_delta": X, "n": Y}, ...}
