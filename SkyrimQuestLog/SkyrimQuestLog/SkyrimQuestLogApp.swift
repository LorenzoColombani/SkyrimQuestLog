import SwiftUI
import SwiftData

@main
struct SkyrimQuestLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Quest.self, Objective.self])
    }
}
