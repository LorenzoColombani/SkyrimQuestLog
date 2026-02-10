import SwiftUI
import SwiftData

struct QuestFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Editing an existing quest, or nil for new
    var quest: Quest?

    @State private var title = ""
    @State private var questDescription = ""
    @State private var category: QuestCategory = .sideQuests
    @State private var xpReward = 100
    @State private var objectiveTitles: [String] = [""]

    private var isEditing: Bool { quest != nil }
    private var isValid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                SkyrimColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        formSection("QUEST NAME") {
                            TextField("Enter quest title...", text: $title)
                                .font(SkyrimFont.questTitle())
                                .foregroundStyle(SkyrimColors.primary)
                        }

                        // Description
                        formSection("DESCRIPTION") {
                            TextField("Enter quest description...", text: $questDescription, axis: .vertical)
                                .font(SkyrimFont.body())
                                .foregroundStyle(SkyrimColors.primary)
                                .lineLimit(3...8)
                        }

                        // Category
                        formSection("CATEGORY") {
                            Picker("Category", selection: $category) {
                                ForEach(QuestCategory.allCases) { cat in
                                    Label(cat.rawValue, systemImage: cat.icon)
                                        .tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(SkyrimColors.accent)
                        }

                        // XP Reward
                        formSection("XP REWARD") {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(SkyrimColors.accent)
                                    .font(.system(size: 14))

                                TextField("XP", value: $xpReward, format: .number)
                                    .font(SkyrimFont.questTitle())
                                    .foregroundStyle(SkyrimColors.primary)
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)

                                Text("XP")
                                    .font(SkyrimFont.caption())
                                    .foregroundStyle(SkyrimColors.secondary)
                            }
                        }

                        // Objectives
                        formSection("OBJECTIVES") {
                            VStack(spacing: 8) {
                                ForEach(objectiveTitles.indices, id: \.self) { index in
                                    HStack(spacing: 12) {
                                        Image(systemName: "circle")
                                            .font(.system(size: 14, weight: .light))
                                            .foregroundStyle(SkyrimColors.dimmed)

                                        TextField("Objective \(index + 1)...", text: $objectiveTitles[index])
                                            .font(SkyrimFont.objective())
                                            .foregroundStyle(SkyrimColors.primary)
                                            .onSubmit {
                                                if index == objectiveTitles.count - 1 {
                                                    objectiveTitles.append("")
                                                }
                                            }

                                        if objectiveTitles.count > 1 {
                                            Button {
                                                objectiveTitles.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(SkyrimColors.dimmed)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }

                                Button {
                                    objectiveTitles.append("")
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 12))
                                        Text("Add Objective")
                                            .font(SkyrimFont.caption())
                                            .tracking(1)
                                    }
                                    .foregroundStyle(SkyrimColors.accent)
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "EDIT QUEST" : "NEW QUEST")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(SkyrimColors.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveQuest()
                    }
                    .foregroundStyle(isValid ? SkyrimColors.accent : SkyrimColors.dimmed)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let quest {
                    title = quest.title
                    questDescription = quest.questDescription
                    category = quest.questCategory
                    xpReward = quest.xpReward
                    objectiveTitles = quest.objectives
                        .sorted { $0.sortOrder < $1.sortOrder }
                        .map(\.title)
                    if objectiveTitles.isEmpty {
                        objectiveTitles = [""]
                    }
                }
            }
        }
    }

    // MARK: - Form Section Helper

    private func formSection<Content: View>(_ header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .skyrimSectionHeader()

            content()

            SkyrimDivider()
        }
    }

    // MARK: - Save

    private func saveQuest() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let validObjectives = objectiveTitles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let quest {
            // Update existing
            quest.title = trimmedTitle
            quest.questDescription = questDescription
            quest.questCategory = category
            quest.xpReward = xpReward

            // Rebuild objectives
            quest.objectives.forEach { modelContext.delete($0) }
            quest.objectives = validObjectives.enumerated().map { index, title in
                Objective(title: title, sortOrder: index)
            }
        } else {
            // Create new
            let newQuest = Quest(
                title: trimmedTitle,
                questDescription: questDescription,
                category: category.rawValue,
                isActive: true,
                xpReward: xpReward,
                objectives: validObjectives.enumerated().map { index, title in
                    Objective(title: title, sortOrder: index)
                }
            )
            modelContext.insert(newQuest)
        }

        HapticManager.impact(.medium)
        dismiss()
    }
}

#Preview {
    QuestFormView()
        .modelContainer(for: Quest.self, inMemory: true)
        .preferredColorScheme(.dark)
}
