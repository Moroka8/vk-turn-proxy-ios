import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ProfileListView()
                .tabItem {
                    Label("Profiles", systemImage: "list.bullet.rectangle")
                }

            SessionView()
                .tabItem {
                    Label("Session", systemImage: "dot.radiowaves.left.and.right")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
