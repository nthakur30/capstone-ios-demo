import Foundation

@MainActor
class APIClient: ObservableObject {
    static let shared = APIClient()

    // Update to your Mac's WiFi IP when testing on a real device
    var baseURL = "http://172.20.9.108:8000"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 3
        config.timeoutIntervalForResource = 3
        return URLSession(configuration: config)
    }()

    func routeIncident(lat: Double, lng: Double, condition: ConditionType,
                       gcs: Int, sbp: Int, rr: Int) async throws -> RoutingResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/route")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "patient_lat": lat, "patient_lng": lng,
            "condition": condition.rawValue,
            "gcs": gcs, "sbp": sbp, "rr": rr
        ])
        let (data, _) = try await session.data(for: request)
        return try decoder().decode(RoutingResponse.self, from: data)
    }

    func getHospitals() async throws -> [Hospital] {
        let (data, _) = try await session.data(from: URL(string: "\(baseURL)/api/hospitals")!)
        return try decoder().decode([Hospital].self, from: data)
    }

    func refreshHospitals() async throws -> [Hospital] {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/hospitals/refresh")!)
        request.httpMethod = "POST"
        let (data, _) = try await session.data(for: request)
        return try decoder().decode([Hospital].self, from: data)
    }

    func runBatchSimulation(k: Int = 7) async throws -> BatchStats {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/simulate/batch?k=\(k)")!)
        request.httpMethod = "POST"
        let (data, _) = try await session.data(for: request)
        return try decoder().decode(BatchStats.self, from: data)
    }

    func getRandomIncident() async throws -> StoredIncident {
        let (data, _) = try await session.data(from: URL(string: "\(baseURL)/api/incidents/random")!)
        return try decoder().decode(StoredIncident.self, from: data)
    }

    private func decoder() -> JSONDecoder {
        JSONDecoder()
    }
}
