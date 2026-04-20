import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            offlineToggleBar
            TabView {
                RoutingView()
                    .tabItem {
                        Label("Live Routing", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    }
                DashboardView()
                    .tabItem {
                        Label("Hospitals", systemImage: "building.2.fill")
                    }
                SimulationView()
                    .tabItem {
                        Label("Simulation", systemImage: "chart.bar.fill")
                    }
            }
        }
    }

    private var offlineToggleBar: some View {
        HStack(spacing: 10) {
            Image(systemName: settings.isOfflineMode ? "wifi.slash" : "wifi")
                .foregroundColor(settings.isOfflineMode ? .orange : .green)
                .font(.subheadline)
            Text(settings.isOfflineMode ? "Demo / Offline Mode" : "Live Mode")
                .font(.caption)
                .bold()
                .foregroundColor(settings.isOfflineMode ? .orange : .green)
            Spacer()
            Toggle("", isOn: $settings.isOfflineMode)
                .labelsHidden()
                .tint(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}
