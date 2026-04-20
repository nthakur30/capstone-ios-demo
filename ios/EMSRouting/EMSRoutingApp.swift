import SwiftUI

@main
struct EMSRoutingApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(APIClient.shared)
                .environmentObject(settings)
        }
    }
}
