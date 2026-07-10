import SwiftData
import SwiftUI

/// Root tab shell for Nest — Home, Voice, Tools, and Personal.
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            CaptureView()
                .tabItem {
                    Label("Voice", systemImage: "waveform")
                }
                .tag(1)

            ToolsView()
                .tabItem {
                    Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(2)

            PersonalView()
                .tabItem {
                    Label("Personal", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(Color(red: 0.72, green: 0.55, blue: 1.0))
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Thought.self, ThoughtFolder.self], inMemory: true)
}
