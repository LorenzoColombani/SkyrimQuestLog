import SwiftUI
import SwiftData

struct QuestListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quest.createdAt, order: .reverse) private var allQuests: [Quest]

    @State private var searchText = ""
    @State private var showNewQuestForm = false
    @State private var sortOrder: SortOrder = .dateCreated
    @State private var filterCategory: QuestCategory?

    enum SortOrder: String, CaseIterable {
        case dateCreated = "Date Created"
        case name = "Name"
        case category = "Category"
        case xpReward = "XP Reward"
    }

    private var activeQuests: [Quest] {
        allQuests.filter { !$0.isComplete && !$0.isFailed }
    }

    private var filteredQuests: [Quest] {
        var quests = activeQuests

        if !searchText.isEmpty {
            quests = quests.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.questDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let category = filterCategory {
            quests = quests.filter { $0.category == category.rawValue }
        }

        return quests
    }

    private var trackedQuests: [Quest] {
        filteredQuests
            .filter { $0.isActive }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var groupedQuests: [(category: QuestCategory, quests: [Quest])] {
        let untracked = filteredQuests.filter { !$0.isActive }
        let sorted = untracked.sorted { q1, q2 in
            switch sortOrder {
            case .dateCreated: return q1.createdAt > q2.createdAt
            case .name: return q1.title < q2.title
            case .category: return q1.questCategory.sortOrder < q2.questCategory.sortOrder
            case .xpReward: return q1.xpReward > q2.xpReward
            }
        }

        let grouped = Dictionary(grouping: sorted) { $0.questCategory }
        return QuestCategory.allCases
            .compactMap { category in
                guard let quests = grouped[category], !quests.isEmpty else { return nil }
                return (category: category, quests: quests)
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SkyrimColors.background.ignoresSafeArea()

                if activeQuests.isEmpty && searchText.isEmpty {
                    emptyStateView
                } else {
                    questListContent
                }
            }
            .navigationTitle("QUESTS")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search quests...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewQuestForm = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(SkyrimColors.accent)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Sort By") {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Button {
                                    sortOrder = order
                                } label: {
                                    HStack {
                                        Text(order.rawValue)
                                        if sortOrder == order {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }

                        Section("Filter Category") {
                            Button("All Categories") {
                                filterCategory = nil
                            }
                            ForEach(QuestCategory.allCases) { category in
                                Button {
                                    filterCategory = category
                                } label: {
                                    HStack {
                                        Label(category.rawValue, systemImage: category.icon)
                                        if filterCategory == category {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(SkyrimColors.secondary)
                    }
                }
            }
            .sheet(isPresented: $showNewQuestForm) {
                QuestFormView()
            }
        }
    }

    // MARK: - Quest List Content

    private var questListContent: some View {
        List {
            // Tracked quests pinned section
            if !trackedQuests.isEmpty {
                Section {
                    ForEach(trackedQuests) { quest in
                        NavigationLink(value: quest) {
                            QuestRowView(quest: quest, showCategory: true)
                        }
                        .listRowBackground(SkyrimColors.selectionGlow)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                completeQuest(quest)
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            .tint(SkyrimColors.success)

                            Button {
                                failQuest(quest)
                            } label: {
                                Label("Fail", systemImage: "xmark")
                            }
                            .tint(SkyrimColors.failure)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteQuest(quest)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                withAnimation {
                                    quest.isActive = false
                                    HapticManager.selection()
                                }
                            } label: {
                                Label("Untrack", systemImage: "diamond")
                            }
                            .tint(SkyrimColors.accent)
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "diamond.fill")
                            .font(.caption2)
                        Text("Tracked")
                    }
                    .skyrimSectionHeader()
                }
                .listRowSeparatorTint(SkyrimColors.divider)
            }

            // Category sections
            ForEach(groupedQuests, id: \.category) { group in
                Section {
                    ForEach(group.quests) { quest in
                        NavigationLink(value: quest) {
                            QuestRowView(quest: quest)
                        }
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                completeQuest(quest)
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            .tint(SkyrimColors.success)

                            Button {
                                failQuest(quest)
                            } label: {
                                Label("Fail", systemImage: "xmark")
                            }
                            .tint(SkyrimColors.failure)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteQuest(quest)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                withAnimation {
                                    quest.isActive = true
                                    HapticManager.selection()
                                }
                            } label: {
                                Label("Track", systemImage: "diamond.fill")
                            }
                            .tint(SkyrimColors.accent)
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: group.category.icon)
                            .font(.caption2)
                        Text(group.category.rawValue)
                    }
                    .skyrimSectionHeader()
                }
                .listRowSeparatorTint(SkyrimColors.divider)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: Quest.self) { quest in
            QuestDetailView(quest: quest)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "scroll")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(SkyrimColors.dimmed)

            VStack(spacing: 8) {
                Text("NO ACTIVE QUESTS")
                    .font(SkyrimFont.sectionHeader())
                    .tracking(4)
                    .foregroundStyle(SkyrimColors.secondary)

                Text("Begin your journey by adding a new quest")
                    .font(SkyrimFont.body())
                    .foregroundStyle(SkyrimColors.dimmed)
            }

            Button {
                showNewQuestForm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("NEW QUEST")
                        .tracking(2)
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SkyrimColors.accent)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SkyrimColors.accent.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Actions

    private func completeQuest(_ quest: Quest) {
        withAnimation {
            quest.isComplete = true
            quest.completedAt = Date()
            HapticManager.questCompleted()
        }
    }

    private func failQuest(_ quest: Quest) {
        withAnimation {
            quest.isFailed = true
            quest.completedAt = Date()
            HapticManager.questFailed()
        }
    }

    private func deleteQuest(_ quest: Quest) {
        withAnimation {
            modelContext.delete(quest)
        }
    }
}

#Preview {
    QuestListView()
        .modelContainer(for: Quest.self, inMemory: true)
        .preferredColorScheme(.dark)
}
