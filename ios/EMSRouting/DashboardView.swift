import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var api: APIClient
    @State private var hospitals: [Hospital] = []
    @State private var isLoading = false
    @State private var isRefreshing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading hospitals…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash").font(.largeTitle).foregroundColor(.secondary)
                        Text(err).multilineTextAlignment(.center).foregroundColor(.secondary)
                            .padding(.horizontal)
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(hospitals) { hospital in
                        HospitalRow(hospital: hospital)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Hospitals (\(hospitals.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await refresh() }
                    } label: {
                        if isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true; errorMessage = nil
        do {
            hospitals = try await api.getHospitals()
        } catch {
            errorMessage = "Could not load hospitals.\nCheck backend connection."
        }
        isLoading = false
    }

    private func refresh() async {
        isRefreshing = true
        do {
            hospitals = try await api.refreshHospitals()
        } catch {}
        isRefreshing = false
    }
}

struct HospitalRow: View {
    let hospital: Hospital

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hospital.name).font(.subheadline).bold()

            // Occupancy bar
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("ED Occupancy").font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text("\(hospital.occupancyPercent)%")
                        .font(.caption2).bold().monospacedDigit()
                        .foregroundColor(hospital.occupancyColor)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray5))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(hospital.occupancyColor)
                            .frame(width: geo.size.width * min(hospital.occupancyRate, 1.0))
                    }
                }
                .frame(height: 6)
            }

            // Capability badges
            let badges = hospital.capabilities.badges
            if !badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(badges, id: \.0) { label, color in
                            Text(label)
                                .font(.caption2).bold()
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(color.opacity(0.15))
                                .foregroundColor(color)
                                .cornerRadius(6)
                        }
                    }
                }
            } else {
                Text("General ED")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
