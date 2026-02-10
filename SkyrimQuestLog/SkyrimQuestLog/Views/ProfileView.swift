import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var allQuests: [Quest]
    @AppStorage("playerName") private var playerName = "Dragonborn"
    @State private var isEditingName = false
    @State private var editedName = ""

    private var totalQuests: Int { allQuests.count }
    private var completedQuests: Int { allQuests.filter(\.isComplete).count }
    private var activeQuests: Int { allQuests.filter { !$0.isComplete && !$0.isFailed }.count }
    private var failedQuests: Int { allQuests.filter(\.isFailed).count }
    private var totalXP: Int { allQuests.filter(\.isComplete).reduce(0) { $0 + $1.xpReward } }

    private var level: Int {
        // Every 1000 XP = 1 level
        max(1, totalXP / 1000 + 1)
    }

    private var xpToNextLevel: Int {
        1000 - (totalXP % 1000)
    }

    private var levelProgress: Double {
        Double(totalXP % 1000) / 1000.0
    }

    private var categoryCounts: [(category: QuestCategory, count: Int)] {
        let completed = allQuests.filter(\.isComplete)
        let grouped = Dictionary(grouping: completed) { $0.questCategory }
        return QuestCategory.allCases.compactMap { category in
            let count = grouped[category]?.count ?? 0
            guard count > 0 else { return nil }
            return (category: category, count: count)
        }
        .sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SkyrimColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Player Name
                        playerNameSection

                        // Level & XP
                        levelSection

                        SkyrimDivider()

                        // Stats overview
                        statsSection

                        SkyrimDivider()

                        // Category breakdown
                        if !categoryCounts.isEmpty {
                            categorySection
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("PROFILE")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Player Name Section

    private var playerNameSection: some View {
        VStack(spacing: 8) {
            if isEditingName {
                TextField("Enter name...", text: $editedName)
                    .font(SkyrimFont.questDetailTitle())
                    .tracking(1.5)
                    .foregroundStyle(SkyrimColors.primary)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            playerName = trimmed
                        }
                        isEditingName = false
                    }
            } else {
                Text(playerName.uppercased())
                    .font(SkyrimFont.questDetailTitle())
                    .tracking(1.5)
                    .foregroundStyle(SkyrimColors.primary)
            }

            Button {
                if isEditingName {
                    let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        playerName = trimmed
                    }
                    isEditingName = false
                } else {
                    editedName = playerName
                    isEditingName = true
                }
            } label: {
                Text(isEditingName ? "SAVE" : "EDIT NAME")
                    .font(SkyrimFont.caption())
                    .tracking(1.5)
                    .foregroundStyle(SkyrimColors.accent)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Level Section

    private var levelSection: some View {
        VStack(spacing: 20) {
            // Level badge
            ZStack {
                Circle()
                    .stroke(SkyrimColors.divider, lineWidth: 3)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: levelProgress)
                    .stroke(SkyrimColors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(level)")
                        .font(.system(size: 36, weight: .ultraLight))
                        .foregroundStyle(SkyrimColors.primary)

                    Text("LEVEL")
                        .font(SkyrimFont.caption())
                        .tracking(2)
                        .foregroundStyle(SkyrimColors.dimmed)
                }
            }

            // XP info
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("\(totalXP) XP")
                        .font(SkyrimFont.questTitle())
                        .tracking(1)
                }
                .foregroundStyle(SkyrimColors.accent)

                Text("\(xpToNextLevel) XP to next level")
                    .font(SkyrimFont.caption())
                    .foregroundStyle(SkyrimColors.dimmed)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GENERAL STATS")
                .skyrimSectionHeader()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statCard(value: "\(totalQuests)", label: "TOTAL QUESTS", icon: "scroll")
                statCard(value: "\(activeQuests)", label: "ACTIVE", icon: "diamond.fill")
                statCard(value: "\(completedQuests)", label: "COMPLETED", icon: "checkmark.seal.fill")
                statCard(value: "\(failedQuests)", label: "FAILED", icon: "xmark.seal.fill")
            }
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QUESTS BY CATEGORY")
                .skyrimSectionHeader()

            ForEach(categoryCounts, id: \.category) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(SkyrimColors.accent)
                        .frame(width: 24)

                    Text(item.category.rawValue)
                        .font(SkyrimFont.body())
                        .foregroundStyle(SkyrimColors.secondary)

                    Spacer()

                    Text("\(item.count)")
                        .font(SkyrimFont.questTitle())
                        .foregroundStyle(SkyrimColors.primary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Stat Card

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(SkyrimColors.accent)

            Text(value)
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundStyle(SkyrimColors.primary)

            Text(label)
                .font(SkyrimFont.caption())
                .tracking(1.5)
                .foregroundStyle(SkyrimColors.dimmed)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(SkyrimColors.surface)
        )
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: Quest.self, inMemory: true)
        .preferredColorScheme(.dark)
}
