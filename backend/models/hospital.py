from pydantic import BaseModel
from typing import Optional


class HospitalCapabilities(BaseModel):
    cath_lab: bool = False
    stroke_center: bool = False
    trauma_l1: bool = False
    trauma_l2: bool = False
    pediatric: bool = False


class Hospital(BaseModel):
    id: str
    name: str
    lat: float
    lng: float
    capabilities: HospitalCapabilities
    # Simulated real-time ED metrics (refreshable)
    ed_capacity: int  # total beds
    ed_current_patients: int  # current occupancy count

    @property
    def occupancy_rate(self) -> float:
        return self.ed_current_patients / self.ed_capacity

    @property
    def is_general_only(self) -> bool:
        caps = self.capabilities
        return not any([caps.cath_lab, caps.stroke_center, caps.trauma_l1, caps.trauma_l2])


class HospitalWithMetrics(Hospital):
    distance_miles: float = 0.0
    ed_overcrowding_score: float = 0.0
    ed_delay_minutes: float = 0.0
    specialty_match: int = 1
    transport_time: float = 0.0
    duf_score: float = 0.0
    risk_score: float = 0.0
