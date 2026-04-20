export type ConditionType = 'STEMI' | 'STROKE' | 'TRAUMA' | 'GENERAL';

export interface HospitalCapabilities {
  cath_lab: boolean;
  stroke_center: boolean;
  trauma_l1: boolean;
  trauma_l2: boolean;
  pediatric: boolean;
}

export interface Hospital {
  id: string;
  name: string;
  lat: number;
  lng: number;
  capabilities: HospitalCapabilities;
  ed_capacity: number;
  ed_current_patients: number;
}

export interface HospitalWithMetrics extends Hospital {
  distance_miles: number;
  ed_overcrowding_score: number;
  ed_delay_minutes: number;
  specialty_match: number;
  transport_time: number;
  duf_score: number;
  risk_score: number;
}

export interface AgentTrace {
  agent: string;
  started_at_ms: number;
  duration_ms: number;
  output_summary: Record<string, unknown>;
}

export interface RoutingRecommendation {
  hospital_id: string;
  hospital_name: string;
  duf_score: number;
  transport_time: number;
  ed_delay: number;
  specialty_match: number;
  risk_score: number;
  rts: number;
  severity_multiplier: number;
}

export interface RoutingResponse {
  ai_recommendation: RoutingRecommendation;
  traditional_recommendation: RoutingRecommendation;
  delta_risk: number;
  all_hospitals_scored: HospitalWithMetrics[];
  agent_traces: AgentTrace[];
}

export interface IncidentRequest {
  patient_lat: number;
  patient_lng: number;
  condition: ConditionType;
  gcs: number;
  sbp: number;
  rr: number;
  incident_id?: string;
}

export interface BatchStats {
  n_cases: number;
  mean_delta: number;
  std_delta: number;
  t_statistic: number;
  p_value: number;
  cohens_d: number;
  ai_wins: number;
  traditional_wins: number;
  tie: number;
  by_condition: Record<string, { n: number; mean_delta: number; std_delta: number }>;
}
