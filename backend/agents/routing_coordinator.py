import asyncio
import time
from typing import List, Tuple
from models.hospital import Hospital, HospitalWithMetrics
from models.incident import IncidentRequest, ConditionType
from models.routing_result import RoutingRecommendation, RoutingResponse, AgentTrace
from agents import patient_data_agent, hospital_metrics_agent, traffic_agent

# Normalization constants
CLINICAL_MAX = 7.84 * 1.7 * 3   # 39.9576
LOGISTICS_MAX = 60 + 38          # 98 min (max transport + max ED delay)
CLINICAL_WEIGHT = 0.6
LOGISTICS_WEIGHT = 0.4


def compute_duf(rts: float, severity_multiplier: float, specialty_match: int,
                transport_time: float, ed_delay: float) -> float:
    norm_clinical = (rts * severity_multiplier * specialty_match) / CLINICAL_MAX
    norm_logistics = (transport_time + ed_delay) / LOGISTICS_MAX
    return (CLINICAL_WEIGHT * norm_clinical) - (LOGISTICS_WEIGHT * norm_logistics)


def compute_risk_score(transport_time: float, specialty_match: int, k: int = 7) -> float:
    specialty_indicator = 1 if specialty_match == 3 else 0
    return -transport_time + (k * specialty_indicator)


async def route(incident: IncidentRequest, hospitals: List[Hospital], k: int = 7) -> RoutingResponse:
    request_start = time.time()

    # Run 3 agents concurrently
    patient_task = asyncio.create_task(patient_data_agent.run(incident))
    metrics_task = asyncio.create_task(hospital_metrics_agent.run(hospitals, incident.condition))
    traffic_task = asyncio.create_task(traffic_agent.run(incident, hospitals))

    patient_result, metrics_result, traffic_result = await asyncio.gather(
        patient_task, metrics_task, traffic_task
    )

    rts = patient_result["rts"]
    severity_multiplier = patient_result["severity_multiplier"]

    # Coordinator runs after all 3 complete
    coord_start = time.time()
    scored_hospitals: List[HospitalWithMetrics] = []
    for h in hospitals:
        hm = metrics_result["metrics"][h.id]
        ht = traffic_result["transport"][h.id]
        duf = compute_duf(rts, severity_multiplier, hm["specialty_match"],
                          ht["transport_time"], hm["ed_delay_minutes"])
        risk = compute_risk_score(ht["transport_time"], hm["specialty_match"], k)
        scored = HospitalWithMetrics(
            **h.model_dump(),
            distance_miles=ht["distance_miles"],
            ed_overcrowding_score=hm["ed_overcrowding_score"],
            ed_delay_minutes=hm["ed_delay_minutes"],
            specialty_match=hm["specialty_match"],
            transport_time=ht["transport_time"],
            duf_score=round(duf, 4),
            risk_score=round(risk, 4),
        )
        scored_hospitals.append(scored)

    coord_duration = (time.time() - coord_start) * 1000

    # AI: highest DUF
    ai_hospital = max(scored_hospitals, key=lambda h: h.duf_score)
    # Traditional: shortest distance
    trad_hospital = min(scored_hospitals, key=lambda h: h.distance_miles)

    def to_recommendation(h: HospitalWithMetrics) -> RoutingRecommendation:
        return RoutingRecommendation(
            hospital_id=h.id,
            hospital_name=h.name,
            duf_score=h.duf_score,
            transport_time=h.transport_time,
            ed_delay=h.ed_delay_minutes,
            specialty_match=h.specialty_match,
            risk_score=h.risk_score,
            rts=rts,
            severity_multiplier=severity_multiplier,
        )

    # Build agent traces (offset from request start)
    def make_trace(name: str, result: dict) -> AgentTrace:
        offset_ms = (result["_started_at"] - request_start) * 1000
        return AgentTrace(
            agent=name,
            started_at_ms=round(offset_ms, 1),
            duration_ms=round(result["_duration_ms"], 1),
            output_summary={k: v for k, v in result.items() if not k.startswith("_")},
        )

    traces = [
        make_trace("PatientDataAgent", patient_result),
        make_trace("HospitalMetricsAgent", {**metrics_result, "_started_at": metrics_result["_started_at"], "_duration_ms": metrics_result["_duration_ms"]}),
        make_trace("TrafficAgent", {**traffic_result, "_started_at": traffic_result["_started_at"], "_duration_ms": traffic_result["_duration_ms"]}),
        AgentTrace(
            agent="RoutingCoordinator",
            started_at_ms=round((coord_start - request_start) * 1000, 1),
            duration_ms=round(coord_duration, 1),
            output_summary={
                "ai_hospital": ai_hospital.name,
                "traditional_hospital": trad_hospital.name,
                "hospitals_evaluated": len(scored_hospitals),
            }
        )
    ]

    return RoutingResponse(
        ai_recommendation=to_recommendation(ai_hospital),
        traditional_recommendation=to_recommendation(trad_hospital),
        delta_risk=round(ai_hospital.risk_score - trad_hospital.risk_score, 4),
        all_hospitals_scored=sorted(scored_hospitals, key=lambda h: h.duf_score, reverse=True),
        agent_traces=traces,
    )
