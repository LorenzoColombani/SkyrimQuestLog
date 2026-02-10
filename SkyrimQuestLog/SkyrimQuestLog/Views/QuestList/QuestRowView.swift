import SwiftUI

struct QuestRowView: View {
    let quest: Quest
    var showCategory: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            // Active quest marker
            if quest.isActive && !showCategory {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(SkyrimColors.accent)
            }

            // Quest info
            VStack(alignment: .leading, spacing: 6) {
                Text(quest.title)
                    .skyrimQuestTitle(isActive: quest.isActive, isComplete: quest.isComplete)

                if showCategory {
                    HStack(spacing: 4) {
                        Image(systemName: quest.questCategory.icon)
                            .font(.system(size: 9))
                        Text(quest.questCategory.rawValue)
                            .font(SkyrimFont.caption())
                            .tracking(0.5)
                    }
                    .foregroundStyle(SkyrimColors.dimmed)
                }

                HStack(spacing: 12) {
                    // Objectives progress
                    if quest.totalObjectivesCount > 0 {
                        Text("\(quest.completedObjectivesCount)/\(quest.totalObjectivesCount)")
                            .font(SkyrimFont.caption())
                            .foregroundStyle(SkyrimColors.dimmed)
                    }

                    // XP reward
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("\(quest.xpReward) XP")
                    }
                    .font(SkyrimFont.caption())
                    .foregroundStyle(SkyrimColors.accent.opacity(0.7))
                }
            }

            Spacer()

            // Progress indicator (if objectives exist)
            if quest.totalObjectivesCount > 0 {
                CircularProgressView(progress: quest.progress)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quest.title), \(quest.questCategory.rawValue), \(quest.completedObjectivesCount) of \(quest.totalObjectivesCount) objectives complete")
        .accessibilityHint("Double tap to view quest details")
    }
}

// MARK: - Circular Progress

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(SkyrimColors.divider, lineWidth: 2)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(SkyrimColors.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if progress >= 1.0 {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(SkyrimColors.accent)
            }
        }
    }
}

#Preview {
    let quest = Quest(
        title: "The Way of the Voice",
        questDescription: "Climb the 7,000 steps to High Hrothgar",
        category: QuestCategory.mainQuest.rawValue,
        isActive: true,
        xpReward: 250
    )
    return QuestRowView(quest: quest)
        .padding()
        .background(SkyrimColors.background)
        .preferredColorScheme(.dark)
}
