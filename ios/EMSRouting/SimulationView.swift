import SwiftUI

struct SimulationView: View {
    @EnvironmentObject var api: APIClient
    @EnvironmentObject var settings: AppSettings
    @State private var stats: BatchStats?
    @State private var k: Int = 7
    @State private var isRunning = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    controlSection
                    if let stats {
                        statsSection(stats)
                        winRateSection(stats)
                    }
                    if let err = errorMessage {
                        Text(err).foregroundColor(.red).font(.caption)
                            .multilineTextAlignment(.center).padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Simulation")
        }
    }

    private var controlSection: some View {
        GroupBox {
            VStack(spacing: 14) {
                HStack {
                    Text("k value (specialty weight)")
                        .font(.subheadline)
                    Spacer()
                    Picker("k", selection: $k) {
                        Text("k = 7").tag(7)
                        Text("k = 8").tag(8)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }

                Text("Runs 500 pre-generated EMS cases and computes paired t-test statistics matching the paper.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                Button {
                    Task { await runSimulation() }
                } label: {
                    HStack {
                        if isRunning { ProgressView().tint(.white).padding(.trailing, 4) }
                        Image(systemName: "play.fill")
                        Text(isRunning ? "Running 500 cases…" : "Run 500 Cases")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRunning ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isRunning)

                if settings.isOfflineMode {
                    Label("Simulation requires live backend. Disable Demo Mode to run.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal)
    }

    private func statsSection(_ s: BatchStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATISTICAL RESULTS").font(.caption).foregroundColor(.secondary).padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard("Mean Δ Risk", String(format: "+%.2f", s.meanDelta),
                         subtitle: "AI advantage", color: .green)
                statCard("SD", String(format: "%.2f", s.stdDelta),
                         subtitle: "Standard deviation", color: .blue)
                statCard("t-statistic", String(format: "%.2f", s.tStatistic),
                         subtitle: "t(\(s.nCases - 1))", color: .purple)
                statCard("p-value", s.pValueDisplay,
                         subtitle: "Two-tailed", color: s.pValue < 0.001 ? .green : .orange)
                statCard("Cohen's d", String(format: "%.2f", s.cohensD),
                         subtitle: "Effect size", color: .indigo)
                statCard("n = \(s.nCases)", "\(s.aiWins) AI wins",
                         subtitle: "\(s.traditionalWins) trad · \(s.tie) ties", color: .teal)
            }
            .padding(.horizontal)
        }
    }

    private func winRateSection(_ s: BatchStats) -> some View {
        GroupBox("Win Rates") {
            VStack(spacing: 10) {
                winBar("AI Routing",          s.aiWins,          s.nCases, color: .blue)
                winBar("Traditional Routing", s.traditionalWins, s.nCases, color: .gray)
                winBar("Tie",                 s.tie,             s.nCases, color: .secondary)
            }
        }
        .padding(.horizontal)
    }

    private func winBar(_ label: String, _ count: Int, _ total: Int, color: Color) -> some View {
        let pct = Double(count) / Double(total)
        return HStack(spacing: 10) {
            Text(label).font(.caption).frame(width: 120, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.7))
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 18)
            Text("\(Int(pct * 100))%")
                .font(.caption2).bold().monospacedDigit()
                .frame(width: 36, alignment: .trailing)
        }
    }

    private func statCard(_ title: String, _ value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.title2).bold().foregroundColor(color).monospacedDigit()
            Text(subtitle).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }

    private func runSimulation() async {
        guard !settings.isOfflineMode else {
            errorMessage = "Simulation requires a live backend connection.\nDisable Demo Mode to run."
            return
        }
        isRunning = true; errorMessage = nil; stats = nil
        do {
            stats = try await api.runBatchSimulation(k: k)
        } catch {
            errorMessage = "Simulation failed: \(error.localizedDescription)"
        }
        isRunning = false
    }
}
