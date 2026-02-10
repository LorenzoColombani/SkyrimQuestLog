import SwiftUI

enum QuestCategory: String, CaseIterable, Codable, Identifiable {
    case mainQuest = "Main Quest"
    case collegeOfWinterhold = "College of Winterhold"
    case companions = "Companions"
    case thievesGuild = "Thieves Guild"
    case darkBrotherhood = "Dark Brotherhood"
    case civilWar = "Civil War"
    case daedric = "Daedric"
    case sideQuests = "Side Quests"
    case miscellaneous = "Miscellaneous"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .mainQuest: return "shield.lefthalf.filled"
        case .collegeOfWinterhold: return "wand.and.stars"
        case .companions: return "figure.2"
        case .thievesGuild: return "eye.slash"
        case .darkBrotherhood: return "moon.fill"
        case .civilWar: return "flag.fill"
        case .daedric: return "star.circle.fill"
        case .sideQuests: return "signpost.right.fill"
        case .miscellaneous: return "ellipsis.circle"
        }
    }

    var sortOrder: Int {
        switch self {
        case .mainQuest: return 0
        case .collegeOfWinterhold: return 1
        case .companions: return 2
        case .thievesGuild: return 3
        case .darkBrotherhood: return 4
        case .civilWar: return 5
        case .daedric: return 6
        case .sideQuests: return 7
        case .miscellaneous: return 8
        }
    }
}
