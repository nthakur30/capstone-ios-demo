import SwiftUI

@main
struct EMSRoutingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(APIClient.shared)
        }
    }
}
