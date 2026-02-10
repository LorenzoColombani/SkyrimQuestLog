import Foundation
import SwiftData

@Model
final class Quest {
    var title: String
    var questDescription: String
    var category: String
    var isActive: Bool
    var isComplete: Bool
    var isFailed: Bool
    var xpReward: Int
    var createdAt: Date
    var completedAt: Date?

    @Relationship(deleteRule: .cascade)
    var objectives: [Objective]

    init(
        title: String,
        questDescription: String = "",
        category: String = QuestCategory.sideQuests.rawValue,
        isActive: Bool = false,
        isComplete: Bool = false,
        isFailed: Bool = false,
        xpReward: Int = 100,
        objectives: [Objective] = []
    ) {
        self.title = title
        self.questDescription = questDescription
        self.category = category
        self.isActive = isActive
        self.isComplete = isComplete
        self.isFailed = isFailed
        self.xpReward = xpReward
        self.createdAt = Date()
        self.objectives = objectives
    }

    var questCategory: QuestCategory {
        get { QuestCategory(rawValue: category) ?? .sideQuests }
        set { category = newValue.rawValue }
    }

    var completedObjectivesCount: Int {
        objectives.filter(\.isComplete).count
    }

    var totalObjectivesCount: Int {
        objectives.count
    }

    var progress: Double {
        guard totalObjectivesCount > 0 else { return 0 }
        return Double(completedObjectivesCount) / Double(totalObjectivesCount)
    }
}

@Model
final class Objective {
    var title: String
    var isComplete: Bool
    var sortOrder: Int

    @Relationship(inverse: \Quest.objectives)
    var quest: Quest?

    init(title: String, isComplete: Bool = false, sortOrder: Int = 0) {
        self.title = title
        self.isComplete = isComplete
        self.sortOrder = sortOrder
    }
}
