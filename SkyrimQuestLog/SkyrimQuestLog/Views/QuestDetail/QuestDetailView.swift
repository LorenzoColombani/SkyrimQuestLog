import SwiftUI
import SwiftData

struct QuestDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var quest: Quest

    @State private var showEditForm = false
    @State private var showDeleteAlert = false
    @State private var newObjectiveTitle = ""

    var body: some View {
        ZStack {
            SkyrimColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    headerSection

                    SkyrimDivider()

                    // Description
                    if !quest.questDescription.isEmpty {
                        descriptionSection
                        SkyrimDivider()
                    }

                    // Objectives
                    objectivesSection

                    SkyrimDivider()

                    // Add Objective
                    addObjectiveSection

                    // Quest Info Footer
                    questInfoFooter
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        quest.isActive.toggle()
                        HapticManager.selection()
                    } label: {
                        Label(
                            quest.isActive ? "Untrack Quest" : "Track Quest",
                            systemImage: quest.isActive ? "diamond" : "diamond.fill"
                        )
                    }

                    Button {
                        showEditForm = true
                    } label: {
                        Label("Edit Quest", systemImage: "pencil")
                    }

                    Divider()

                    if !quest.isComplete && !quest.isFailed {
                        Button {
                            completeQuest()
                        } label: {
                            Label("Complete Quest", systemImage: "checkmark.seal.fill")
                        }

                        Button {
                            failQuest()
                        } label: {
                            Label("Fail Quest", systemImage: "xmark.seal.fill")
                        }
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Quest", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(SkyrimColors.secondary)
                }
            }
        }
        .sheet(isPresented: $showEditForm) {
            QuestFormView(quest: quest)
        }
        .alert("DELETE QUEST?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(quest)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. The quest \"\(quest.title)\" will be permanently removed.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category badge
            HStack(spacing: 6) {
                Image(systemName: quest.questCategory.icon)
                    .font(.system(size: 11))
                Text(quest.questCategory.rawValue.uppercased())
                    .font(SkyrimFont.caption())
                    .tracking(2)
            }
            .foregroundStyle(SkyrimColors.accent)

            // Quest title
            Text(quest.title.uppercased())
                .font(SkyrimFont.questDetailTitle())
                .tracking(1.5)
                .foregroundStyle(
                    quest.isComplete ? SkyrimColors.dimmed : SkyrimColors.primary
                )

            // Status badges
            HStack(spacing: 16) {
                if quest.isActive {
                    statusBadge(icon: "diamond.fill", text: "TRACKED", color: SkyrimColors.accent)
                }
                if quest.isComplete {
                    statusBadge(icon: "checkmark.seal.fill", text: "COMPLETED", color: SkyrimColors.success)
                }
                if quest.isFailed {
                    statusBadge(icon: "xmark.seal.fill", text: "FAILED", color: SkyrimColors.failure)
                }

                Spacer()

                // XP reward
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text("\(quest.xpReward) XP")
                        .font(SkyrimFont.caption())
                        .tracking(1)
                }
                .foregroundStyle(SkyrimColors.accent)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quest.questDescription)
                .font(SkyrimFont.body())
                .foregroundStyle(SkyrimColors.secondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Objectives

    private var objectivesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OBJECTIVES")
                .skyrimSectionHeader()
                .padding(.top, 16)

            if quest.objectives.isEmpty {
                Text("No objectives defined")
                    .font(SkyrimFont.body())
                    .foregroundStyle(SkyrimColors.dimmed)
                    .padding(.vertical, 8)
            } else {
                ForEach(quest.objectives.sorted(by: { $0.sortOrder < $1.sortOrder })) { objective in
                    ObjectiveRowView(objective: objective) {
                        toggleObjective(objective)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteObjective(objective)
                        } label: {
                            Label("Delete Objective", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Add Objective

    private var addObjectiveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(SkyrimColors.dimmed)

                TextField("Add objective...", text: $newObjectiveTitle)
                    .font(SkyrimFont.objective())
                    .foregroundStyle(SkyrimColors.primary)
                    .onSubmit {
                        addObjective()
                    }
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Footer Info

    private var questInfoFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkyrimDivider()

            Group {
                infoRow(label: "Created", value: quest.createdAt.formatted(date: .abbreviated, time: .shortened))

                if let completedAt = quest.completedAt {
                    infoRow(label: "Completed", value: completedAt.formatted(date: .abbreviated, time: .shortened))
                }

                if quest.totalObjectivesCount > 0 {
                    infoRow(label: "Progress", value: "\(quest.completedObjectivesCount) / \(quest.totalObjectivesCount) objectives")
                }
            }
            .padding(.vertical, 2)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private func statusBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(SkyrimFont.caption())
                .tracking(1.5)
        }
        .foregroundStyle(color)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(SkyrimFont.caption())
                .tracking(1.5)
                .foregroundStyle(SkyrimColors.dimmed)

            Spacer()

            Text(value)
                .font(SkyrimFont.caption())
                .foregroundStyle(SkyrimColors.secondary)
        }
    }

    // MARK: - Actions

    private func toggleObjective(_ objective: Objective) {
        withAnimation(.easeInOut(duration: 0.2)) {
            objective.isComplete.toggle()
            if objective.isComplete {
                HapticManager.objectiveCompleted()
            }

            // Auto-complete quest if all objectives done
            if quest.objectives.allSatisfy(\.isComplete) && !quest.objectives.isEmpty {
                completeQuest()
            }
        }
    }

    private func addObjective() {
        let trimmed = newObjectiveTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let objective = Objective(
            title: trimmed,
            sortOrder: quest.objectives.count
        )
        quest.objectives.append(objective)
        newObjectiveTitle = ""
        HapticManager.impact(.light)
    }

    private func completeQuest() {
        withAnimation {
            quest.isComplete = true
            quest.completedAt = Date()
            HapticManager.questCompleted()
        }
    }

    private func failQuest() {
        withAnimation {
            quest.isFailed = true
            quest.completedAt = Date()
            HapticManager.questFailed()
        }
    }

    private func deleteObjective(_ objective: Objective) {
        withAnimation {
            quest.objectives.removeAll { $0.id == objective.id }
            modelContext.delete(objective)
            // Reindex remaining objectives
            for (index, obj) in quest.objectives.sorted(by: { $0.sortOrder < $1.sortOrder }).enumerated() {
                obj.sortOrder = index
            }
        }
    }
}

// MARK: - Skyrim Divider

struct SkyrimDivider: View {
    var body: some View {
        Rectangle()
            .fill(SkyrimColors.divider)
            .frame(height: 0.5)
    }
}

#Preview {
    let quest = Quest(
        title: "The Way of the Voice",
        questDescription: "Speak to the Greybeards atop the Throat of the World. Climb the 7,000 steps to High Hrothgar and discover the power of the Thu'um.",
        category: QuestCategory.mainQuest.rawValue,
        isActive: true,
        xpReward: 500
    )
    return NavigationStack {
        QuestDetailView(quest: quest)
    }
    .preferredColorScheme(.dark)
}
