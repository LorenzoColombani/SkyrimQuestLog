import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            QuestListView()
                .tabItem {
                    Label("Quests", systemImage: "book.closed")
                }
                .tag(0)

            ArchiveView()
                .tabItem {
                    Label("Archive", systemImage: "archivebox")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .tint(SkyrimColors.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Quest.self, inMemory: true)
}
