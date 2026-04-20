import Foundation

enum ConditionType: String, CaseIterable, Identifiable, Codable, Equatable {
    case STEMI, STROKE, TRAUMA, GENERAL
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .STEMI:   return "STEMI"
        case .STROKE:  return "Stroke"
        case .TRAUMA:  return "Trauma"
        case .GENERAL: return "General"
        }
    }
    var icon: String {
        switch self {
        case .STEMI:   return "heart.fill"
        case .STROKE:  return "brain.head.profile"
        case .TRAUMA:  return "cross.case.fill"
        case .GENERAL: return "stethoscope"
        }
    }
    var color: Color {
        switch self {
        case .STEMI:   return .red
        case .STROKE:  return .purple
        case .TRAUMA:  return .orange
        case .GENERAL: return .blue
        }
    }
}

import SwiftUI

struct HospitalCapabilities: Codable {
    let cathLab: Bool
    let strokeCenter: Bool
    let traumaL1: Bool
    let traumaL2: Bool
    let pediatric: Bool

    enum CodingKeys: String, CodingKey {
        case cathLab = "cath_lab"
        case strokeCenter = "stroke_center"
        case traumaL1 = "trauma_l1"
        case traumaL2 = "trauma_l2"
        case pediatric
    }

    var badges: [(String, Color)] {
        var b: [(String, Color)] = []
        if cathLab     { b.append(("Cath Lab", .red)) }
        if strokeCenter { b.append(("Stroke", .purple)) }
        if traumaL1    { b.append(("Trauma I", .orange)) }
        if traumaL2    { b.append(("Trauma II", .yellow)) }
        if pediatric   { b.append(("Peds", .green)) }
        return b
    }
}

struct Hospital: Codable, Identifiable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
    let capabilities: HospitalCapabilities
    let edCapacity: Int
    let edCurrentPatients: Int

    var occupancyRate: Double { Double(edCurrentPatients) / Double(edCapacity) }
    var occupancyPercent: Int { Int(occupancyRate * 100) }
    var occupancyColor: Color {
        if occupancyRate < 0.7 { return .green }
        if occupancyRate < 1.0 { return .yellow }
        return .red
    }

    enum CodingKeys: String, CodingKey {
        case id, name, lat, lng, capabilities
        case edCapacity = "ed_capacity"
        case edCurrentPatients = "ed_current_patients"
    }
}

struct RoutingRecommendation: Codable {
    let hospitalId: String
    let hospitalName: String
    let dufScore: Double
    let transportTime: Double
    let edDelay: Double
    let specialtyMatch: Int
    let riskScore: Double
    let rts: Double
    let severityMultiplier: Double

    enum CodingKeys: String, CodingKey {
        case hospitalId = "hospital_id"
        case hospitalName = "hospital_name"
        case dufScore = "duf_score"
        case transportTime = "transport_time"
        case edDelay = "ed_delay"
        case specialtyMatch = "specialty_match"
        case riskScore = "risk_score"
        case rts
        case severityMultiplier = "severity_multiplier"
    }

    var specialtyMatchLabel: String {
        switch specialtyMatch {
        case 3: return "Full Match"
        case 2: return "Partial"
        default: return "General ED"
        }
    }

    var specialtyMatchColor: Color {
        switch specialtyMatch {
        case 3: return .green
        case 2: return .yellow
        default: return .gray
        }
    }
}

struct AgentTrace: Codable, Identifiable {
    let agent: String
    let startedAtMs: Double
    let durationMs: Double
    var id: String { agent }

    var shortName: String {
        switch agent {
        case "PatientDataAgent":     return "Patient Data"
        case "HospitalMetricsAgent": return "Hospital Metrics"
        case "TrafficAgent":         return "Traffic"
        case "RoutingCoordinator":   return "Coordinator"
        default: return agent
        }
    }

    var color: Color {
        switch agent {
        case "PatientDataAgent":     return .blue
        case "HospitalMetricsAgent": return .purple
        case "TrafficAgent":         return .orange
        case "RoutingCoordinator":   return .green
        default: return .gray
        }
    }

    enum CodingKeys: String, CodingKey {
        case agent
        case startedAtMs = "started_at_ms"
        case durationMs  = "duration_ms"
    }
}

struct RoutingResponse: Codable {
    let aiRecommendation: RoutingRecommendation
    let traditionalRecommendation: RoutingRecommendation
    let deltaRisk: Double

    let agentTraces: [AgentTrace]

    enum CodingKeys: String, CodingKey {
        case aiRecommendation = "ai_recommendation"
        case traditionalRecommendation = "traditional_recommendation"
        case deltaRisk = "delta_risk"
        case agentTraces = "agent_traces"
    }
}

struct BatchStats: Codable {
    let nCases: Int
    let meanDelta: Double
    let stdDelta: Double
    let tStatistic: Double
    let pValue: Double
    let cohensD: Double
    let aiWins: Int
    let traditionalWins: Int
    let tie: Int

    enum CodingKeys: String, CodingKey {
        case nCases = "n_cases"
        case meanDelta = "mean_delta"
        case stdDelta = "std_delta"
        case tStatistic = "t_statistic"
        case pValue = "p_value"
        case cohensD = "cohens_d"
        case aiWins = "ai_wins"
        case traditionalWins = "traditional_wins"
        case tie
    }

    var pValueDisplay: String {
        pValue < 0.001 ? "< 0.001" : String(format: "%.4f", pValue)
    }
}

struct StoredIncident: Codable {
    let incidentId: String
    let condition: ConditionType
    let gcs: Int
    let sbp: Int
    let rr: Int
    let patientLat: Double
    let patientLng: Double

    enum CodingKeys: String, CodingKey {
        case incidentId = "incident_id"
        case condition, gcs, sbp, rr
        case patientLat = "patient_lat"
        case patientLng = "patient_lng"
    }
}
