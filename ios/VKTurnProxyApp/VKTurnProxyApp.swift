import SwiftUI

@main
struct VKTurnProxyApp: App {
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var runtime = ProxyRuntime()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileStore)
                .environmentObject(runtime)
        }
    }
}
