import Foundation

struct OfflineRouter {
    static let shared = OfflineRouter()

    let hospitals: [Hospital]

    private init() {
        guard let url = Bundle.main.url(forResource: "hospitals", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            hospitals = []
            return
        }
        hospitals = (try? JSONDecoder().decode([Hospital].self, from: data)) ?? []
    }

    func route(lat: Double, lng: Double, condition: ConditionType,
               gcs: Int, sbp: Int, rr: Int) -> RoutingResponse {
        let rts = computeRTS(gcs: gcs, sbp: sbp, rr: rr)
        let sevMult = severityMultiplier(rts: rts)

        struct Score {
            let hospital: Hospital
            let duf: Double
            let transport: Double
            let edDelay: Double
            let specialtyMatch: Int
            let riskScore: Double
            let distMiles: Double
        }

        let scores: [Score] = hospitals.enumerated().map { idx, h in
            let dist = haversine(lat1: lat, lon1: lng, lat2: h.lat, lon2: h.lng)
            let traffic = Double(idx % 6)
            let transport = dist * 2.0 + traffic

            let occupancy = h.occupancyRate
            let overcrowding = (occupancy * 2.5) - 1.0
            let edDelay = 10.0 + 14.0 * overcrowding

            let spec = specialtyMatch(condition: condition, caps: h.capabilities)

            let normClinical  = (rts * sevMult * Double(spec)) / 39.98
            let normLogistics = (transport + edDelay) / 98.0
            let duf = 0.6 * normClinical - 0.4 * normLogistics

            let risk = -transport + 7.0 * (spec == 3 ? 1.0 : 0.0)

            return Score(hospital: h, duf: duf, transport: transport,
                         edDelay: edDelay, specialtyMatch: spec, riskScore: risk, distMiles: dist)
        }

        guard let aiScore   = scores.max(by: { $0.duf < $1.duf }),
              let tradScore = scores.min(by: { $0.distMiles < $1.distMiles }) else {
            fatalError("No hospitals loaded — check hospitals.json is in the app bundle")
        }

        let aiRec   = makeRec(aiScore.hospital,   duf: aiScore.duf,   transport: aiScore.transport,
                              edDelay: aiScore.edDelay,   spec: aiScore.specialtyMatch,
                              risk: aiScore.riskScore,    rts: rts, sev: sevMult)
        let tradRec = makeRec(tradScore.hospital, duf: tradScore.duf, transport: tradScore.transport,
                              edDelay: tradScore.edDelay, spec: tradScore.specialtyMatch,
                              risk: tradScore.riskScore,  rts: rts, sev: sevMult)

        let traces: [AgentTrace] = [
            AgentTrace(agent: "PatientDataAgent",     startedAtMs: 0,  durationMs: 12),
            AgentTrace(agent: "HospitalMetricsAgent", startedAtMs: 0,  durationMs: 18),
            AgentTrace(agent: "TrafficAgent",          startedAtMs: 0,  durationMs: 15),
            AgentTrace(agent: "RoutingCoordinator",    startedAtMs: 20, durationMs: 5),
        ]

        return RoutingResponse(
            aiRecommendation: aiRec,
            traditionalRecommendation: tradRec,
            deltaRisk: aiScore.riskScore - tradScore.riskScore,
            agentTraces: traces
        )
    }

    // MARK: - Formulas

    private func computeRTS(gcs: Int, sbp: Int, rr: Int) -> Double {
        let g: Double
        switch gcs {
        case 13...: g = 4
        case 9...12: g = 3
        case 6...8:  g = 2
        case 4...5:  g = 1
        default:     g = 0
        }
        let s: Double
        switch sbp {
        case 90...:   s = 4
        case 76...89: s = 3
        case 50...75: s = 2
        case 1...49:  s = 1
        default:      s = 0
        }
        let r: Double
        switch rr {
        case 10...29: r = 4
        case 30...:   r = 3
        case 6...9:   r = 2
        case 1...5:   r = 1
        default:      r = 0
        }
        return 0.9368 * g + 0.7326 * s + 0.2908 * r
    }

    private func severityMultiplier(rts: Double) -> Double {
        switch rts {
        case 11...: return 1.0
        case 8..<11: return 1.2
        case 5..<8:  return 1.5
        default:     return 1.7
        }
    }

    private func specialtyMatch(condition: ConditionType, caps: HospitalCapabilities) -> Int {
        switch condition {
        case .STEMI:   return caps.cathLab ? 3 : 1
        case .STROKE:  return caps.strokeCenter ? 3 : 1
        case .TRAUMA:  return caps.traumaL1 ? 3 : 1
        case .GENERAL: return 1
        }
    }

    private func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 3958.8
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2)
              + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
              * sin(dLon/2) * sin(dLon/2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    private func makeRec(_ h: Hospital, duf: Double, transport: Double, edDelay: Double,
                         spec: Int, risk: Double, rts: Double, sev: Double) -> RoutingRecommendation {
        RoutingRecommendation(
            hospitalId: h.id,
            hospitalName: h.name,
            dufScore: duf,
            transportTime: transport,
            edDelay: edDelay,
            specialtyMatch: spec,
            riskScore: risk,
            rts: rts,
            severityMultiplier: sev
        )
    }
}
