import SwiftUI

private let PRESETS: [(String, ConditionType, Double, Double, Int, Int, Int)] = [
    ("Critical STEMI",  .STEMI,   34.850, -79.850, 10, 78,  24),
    ("Moderate Stroke", .STROKE,  35.450, -79.750, 8,  185, 18),
    ("Major Trauma",    .TRAUMA,  35.150, -80.150, 6,  62,  30),
    ("General Call",    .GENERAL, 35.048, -79.964, 15, 128, 16),
]

struct RoutingView: View {
    @EnvironmentObject var api: APIClient
    @StateObject private var speech = SpeechManager()

    @State private var condition: ConditionType = .STEMI
    @State private var lat: Double = 34.850
    @State private var lng: Double = -79.850
    @State private var gcs: Double = 10
    @State private var sbp: Double = 78
    @State private var rr:  Double = 24

    @State private var result: RoutingResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSpeechSheet = false
    @State private var isOffline = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    speechBanner
                    presetSection
                    vitalsSection
                    routeButton
                    if isOffline {
                        Label("Offline mode — routing computed on-device", systemImage: "wifi.slash")
                            .font(.caption).foregroundColor(.orange)
                            .padding(.horizontal)
                    }
                    if let result { resultsSection(result) }
                    if let err = errorMessage {
                        Text(err).foregroundColor(.red).font(.caption)
                            .multilineTextAlignment(.center).padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("EMS Routing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await speech.startListening() }
                    } label: {
                        Image(systemName: speech.isListening ? "mic.fill" : "mic")
                            .foregroundColor(speech.isListening ? .red : .accentColor)
                    }
                }
            }
            .onChange(of: speech.parsedVitals) { vitals in
                applyParsedVitals(vitals)
            }
        }
    }

    // MARK: – Speech banner
    @ViewBuilder
    private var speechBanner: some View {
        if speech.isListening || !speech.transcript.isEmpty {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: speech.isListening ? "waveform.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(speech.isListening ? .red : .green)
                        .font(.title3)
                    Text(speech.isListening ? "Listening…" : "Recognized")
                        .font(.subheadline).bold()
                    Spacer()
                    if speech.isListening {
                        Button("Stop") { speech.stopListening() }
                            .font(.caption).foregroundColor(.red)
                    }
                }

                if !speech.transcript.isEmpty {
                    Text(speech.transcript)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let v = speech.parsedVitals {
                    HStack(spacing: 12) {
                        if let c = v.condition { Tag(c.displayName, color: c.color) }
                        if let g = v.gcs       { Tag("GCS \(g)", color: .blue) }
                        if let s = v.sbp       { Tag("BP \(s)", color: .orange) }
                        if let r = v.rr        { Tag("RR \(r)", color: .purple) }
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .animation(.easeInOut, value: speech.isListening)
        }
    }

    // MARK: – Preset buttons
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PRESETS").font(.caption).foregroundColor(.secondary)
                Spacer()
                Button {
                    Task { await speech.startListening() }
                } label: {
                    Label(speech.isListening ? "Stop" : "Speak Vitals",
                          systemImage: speech.isListening ? "stop.circle" : "mic.circle.fill")
                        .font(.caption).bold()
                        .foregroundColor(speech.isListening ? .red : .accentColor)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PRESETS, id: \.0) { name, cond, plat, plng, pgcs, psbp, prr in
                        Button {
                            condition = cond; lat = plat; lng = plng
                            gcs = Double(pgcs); sbp = Double(psbp); rr = Double(prr)
                            result = nil; errorMessage = nil
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: cond.icon).font(.title3)
                                Text(name).font(.caption).multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(condition == cond ? cond.color.opacity(0.2) : Color(.systemGray6))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(condition == cond ? cond.color : Color.clear, lineWidth: 1.5))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(condition == cond ? cond.color : .primary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: – Vitals sliders
    private var vitalsSection: some View {
        GroupBox("Patient Vitals") {
            VStack(spacing: 14) {
                // Condition picker
                Picker("Condition", selection: $condition) {
                    ForEach(ConditionType.allCases) { c in
                        Label(c.displayName, systemImage: c.icon).tag(c)
                    }
                }
                .pickerStyle(.segmented)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("GCS", systemImage: "brain.head.profile")
                        Spacer()
                        Text("\(Int(gcs))").bold().monospacedDigit()
                            .foregroundColor(gcs < 9 ? .red : gcs < 13 ? .orange : .green)
                    }
                    Slider(value: $gcs, in: 3...15, step: 1)
                        .tint(gcs < 9 ? .red : gcs < 13 ? .orange : .green)
                }
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("SBP (mmHg)", systemImage: "waveform.path.ecg")
                        Spacer()
                        Text("\(Int(sbp))").bold().monospacedDigit()
                            .foregroundColor(sbp < 90 ? .red : sbp > 180 ? .orange : .green)
                    }
                    Slider(value: $sbp, in: 0...300, step: 1)
                        .tint(sbp < 90 ? .red : sbp > 180 ? .orange : .green)
                }
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label("RR (breaths/min)", systemImage: "lungs.fill")
                        Spacer()
                        Text("\(Int(rr))").bold().monospacedDigit()
                            .foregroundColor(rr < 10 || rr > 29 ? .red : .green)
                    }
                    Slider(value: $rr, in: 0...50, step: 1)
                        .tint(rr < 10 || rr > 29 ? .red : .green)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: – Route button
    private var routeButton: some View {
        Button {
            Task { await route() }
        } label: {
            HStack {
                if isLoading { ProgressView().tint(.white).padding(.trailing, 6) }
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                Text(isLoading ? "Routing…" : "Find Best Hospital").bold()
            }
            .frame(maxWidth: .infinity).padding()
            .background(isLoading ? Color.gray : Color.accentColor)
            .foregroundColor(.white).cornerRadius(14)
        }
        .disabled(isLoading)
        .padding(.horizontal)
    }

    private func route() async {
        speech.stopListening()
        isLoading = true; errorMessage = nil; isOffline = false
        do {
            result = try await api.routeIncident(
                lat: lat, lng: lng, condition: condition,
                gcs: Int(gcs), sbp: Int(sbp), rr: Int(rr)
            )
        } catch {
            // Backend unreachable — run routing engine on-device
            result = OfflineRouter.shared.route(
                lat: lat, lng: lng, condition: condition,
                gcs: Int(gcs), sbp: Int(sbp), rr: Int(rr)
            )
            isOffline = true
        }
        isLoading = false
    }

    private func applyParsedVitals(_ vitals: SpeechManager.ParsedVitals?) {
        guard let v = vitals else { return }
        if let c = v.condition { condition = c }
        if let g = v.gcs       { gcs = Double(g) }
        if let s = v.sbp       { sbp = Double(s) }
        if let r = v.rr        { rr  = Double(r) }
        // Auto-route if all vitals detected
        if v.isComplete { Task { await route() } }
    }

    // MARK: – Results
    @ViewBuilder
    private func resultsSection(_ r: RoutingResponse) -> some View {
        VStack(spacing: 16) {
            deltaBanner(r.deltaRisk)
            HStack(alignment: .top, spacing: 12) {
                recommendationCard(r.aiRecommendation, label: "AI", color: .blue, isAI: true)
                recommendationCard(r.traditionalRecommendation, label: "Traditional", color: .gray, isAI: false)
            }
            .padding(.horizontal)
            if !r.agentTraces.isEmpty { agentTimeline(r.agentTraces) }
        }
    }

    private func deltaBanner(_ delta: Double) -> some View {
        let positive = delta >= 0
        return HStack(spacing: 10) {
            Image(systemName: positive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(positive ? "AI Wins" : "Traditional Wins").font(.headline)
                Text("Risk score Δ \(positive ? "+" : "")\(String(format: "%.2f", delta))")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background((positive ? Color.green : Color.red).opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(positive ? Color.green : Color.red, lineWidth: 1))
        .cornerRadius(12)
        .padding(.horizontal)
        .foregroundColor(positive ? .green : .red)
    }

    private func recommendationCard(_ rec: RoutingRecommendation, label: String, color: Color, isAI: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: isAI ? "cpu" : "location.fill").foregroundColor(color)
                Text(label).font(.caption).bold().foregroundColor(color)
                Spacer()
            }
            Text(rec.hospitalName).font(.subheadline).bold().lineLimit(2).minimumScaleFactor(0.8)
            Divider()
            metricRow("Transport", "\(String(format: "%.1f", rec.transportTime)) min", icon: "car.fill")
            metricRow("ED Delay",  "\(String(format: "%.1f", rec.edDelay)) min",      icon: "clock.fill")
            metricRow("RTS",       String(format: "%.2f", rec.rts),                   icon: "chart.line.uptrend.xyaxis")
            HStack(spacing: 4) {
                Circle().fill(rec.specialtyMatchColor).frame(width: 8, height: 8)
                Text(rec.specialtyMatchLabel).font(.caption2).foregroundColor(rec.specialtyMatchColor)
            }
            if isAI {
                Text("DUF \(String(format: "%.3f", rec.dufScore))").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(12).background(Color(.systemGray6)).cornerRadius(12)
    }

    private func metricRow(_ label: String, _ value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).font(.caption2).foregroundColor(.secondary).frame(width: 16)
            Text(label).font(.caption2).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption).bold().monospacedDigit()
        }
    }

    private func agentTimeline(_ traces: [AgentTrace]) -> some View {
        let maxEnd = traces.map { $0.startedAtMs + $0.durationMs }.max() ?? 1
        return GroupBox("Agent Execution") {
            VStack(spacing: 10) {
                ForEach(traces) { trace in
                    HStack(spacing: 8) {
                        Text(trace.shortName).font(.caption2).frame(width: 90, alignment: .trailing).foregroundColor(.secondary)
                        GeometryReader { geo in
                            let start = trace.startedAtMs / maxEnd
                            let width = trace.durationMs / maxEnd
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5))
                                RoundedRectangle(cornerRadius: 4).fill(trace.color.opacity(0.8))
                                    .frame(width: max(4, geo.size.width * width))
                                    .offset(x: geo.size.width * start)
                            }
                        }
                        .frame(height: 20)
                        Text("\(Int(trace.durationMs))ms").font(.caption2).monospacedDigit()
                            .foregroundColor(.secondary).frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: – Small tag chip
private struct Tag: View {
    let text: String
    let color: Color
    init(_ text: String, color: Color) { self.text = text; self.color = color }
    var body: some View {
        Text(text).font(.caption2).bold()
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15)).foregroundColor(color).cornerRadius(6)
    }
}
