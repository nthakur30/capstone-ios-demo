import SwiftUI

struct ContentView: View {
    var body: some View {
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
