import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Quest> { $0.isComplete || $0.isFailed },
        sort: \Quest.completedAt,
        order: .reverse
    ) private var archivedQuests: [Quest]

    @State private var searchText = ""

    private var filteredQuests: [Quest] {
        if searchText.isEmpty {
            return archivedQuests
        }
        return archivedQuests.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var completedQuests: [Quest] {
        filteredQuests.filter(\.isComplete)
    }

    private var failedQuests: [Quest] {
        filteredQuests.filter(\.isFailed)
    }

    private var totalXP: Int {
        completedQuests.reduce(0) { $0 + $1.xpReward }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SkyrimColors.background.ignoresSafeArea()

                if archivedQuests.isEmpty {
                    emptyArchiveView
                } else {
                    List {
                        // Stats header
                        Section {
                            HStack(spacing: 24) {
                                statItem(
                                    icon: "checkmark.seal.fill",
                                    value: "\(completedQuests.count)",
                                    label: "COMPLETED"
                                )

                                statItem(
                                    icon: "xmark.seal.fill",
                                    value: "\(failedQuests.count)",
                                    label: "FAILED"
                                )

                                statItem(
                                    icon: "sparkles",
                                    value: "\(totalXP)",
                                    label: "TOTAL XP"
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .listRowBackground(SkyrimColors.surface)
                        }

                        // Completed quests
                        if !completedQuests.isEmpty {
                            Section {
                                ForEach(completedQuests) { quest in
                                    NavigationLink(value: quest) {
                                        archivedQuestRow(quest: quest)
                                    }
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            restoreQuest(quest)
                                        } label: {
                                            Label("Restore", systemImage: "arrow.uturn.backward")
                                        }
                                        .tint(SkyrimColors.accent)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            modelContext.delete(quest)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption2)
                                    Text("Completed")
                                }
                                .skyrimSectionHeader()
                            }
                        }

                        // Failed quests
                        if !failedQuests.isEmpty {
                            Section {
                                ForEach(failedQuests) { quest in
                                    NavigationLink(value: quest) {
                                        archivedQuestRow(quest: quest)
                                    }
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            restoreQuest(quest)
                                        } label: {
                                            Label("Restore", systemImage: "arrow.uturn.backward")
                                        }
                                        .tint(SkyrimColors.accent)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            modelContext.delete(quest)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.seal.fill")
                                        .font(.caption2)
                                    Text("Failed")
                                }
                                .skyrimSectionHeader()
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .navigationDestination(for: Quest.self) { quest in
                        QuestDetailView(quest: quest)
                    }
                }
            }
            .navigationTitle("ARCHIVE")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search archive...")
        }
    }

    // MARK: - Subviews

    private func archivedQuestRow(quest: Quest) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(quest.title)
                .font(SkyrimFont.questTitle())
                .tracking(0.5)
                .foregroundStyle(SkyrimColors.dimmed)

            HStack(spacing: 12) {
                Label(quest.questCategory.rawValue, systemImage: quest.questCategory.icon)
                    .font(SkyrimFont.caption())
                    .foregroundStyle(SkyrimColors.dimmed)

                if let completedAt = quest.completedAt {
                    Text(completedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(SkyrimFont.caption())
                        .foregroundStyle(SkyrimColors.dimmed)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text("\(quest.xpReward) XP")
                }
                .font(SkyrimFont.caption())
                .foregroundStyle(SkyrimColors.accent.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(SkyrimColors.accent)

            Text(value)
                .font(SkyrimFont.questDetailTitle())
                .foregroundStyle(SkyrimColors.primary)

            Text(label)
                .font(SkyrimFont.caption())
                .tracking(1.5)
                .foregroundStyle(SkyrimColors.dimmed)
        }
    }

    private func restoreQuest(_ quest: Quest) {
        withAnimation {
            quest.isComplete = false
            quest.isFailed = false
            quest.completedAt = nil
            HapticManager.selection()
        }
    }

    private var emptyArchiveView: some View {
        VStack(spacing: 24) {
            Image(systemName: "archivebox")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(SkyrimColors.dimmed)

            VStack(spacing: 8) {
                Text("NO COMPLETED QUESTS")
                    .font(SkyrimFont.sectionHeader())
                    .tracking(4)
                    .foregroundStyle(SkyrimColors.secondary)

                Text("Completed and failed quests will appear here")
                    .font(SkyrimFont.body())
                    .foregroundStyle(SkyrimColors.dimmed)
            }
        }
    }
}

#Preview {
    ArchiveView()
        .modelContainer(for: Quest.self, inMemory: true)
        .preferredColorScheme(.dark)
}
