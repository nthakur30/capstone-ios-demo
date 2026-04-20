from pydantic import BaseModel, Field
from typing import Literal, Optional


ConditionType = Literal["STEMI", "STROKE", "TRAUMA", "GENERAL"]


class IncidentRequest(BaseModel):
    patient_lat: float
    patient_lng: float
    condition: ConditionType
    gcs: int = Field(..., ge=3, le=15, description="Glasgow Coma Scale 3-15")
    sbp: int = Field(..., ge=0, le=300, description="Systolic Blood Pressure mmHg")
    rr: int = Field(..., ge=0, le=60, description="Respiratory Rate breaths/min")
    incident_id: Optional[str] = None  # used for seeded traffic penalty


class StoredIncident(BaseModel):
    """Pre-generated incident for batch simulation."""
    incident_id: str
    patient_lat: float
    patient_lng: float
    condition: ConditionType
    gcs: int
    sbp: int
    rr: int
