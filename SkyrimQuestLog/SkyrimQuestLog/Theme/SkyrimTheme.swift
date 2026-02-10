import SwiftUI

// MARK: - Skyrim Color Palette

enum SkyrimColors {
    static let background = Color(red: 0.067, green: 0.067, blue: 0.067)       // #111111
    static let surface = Color(red: 0.102, green: 0.102, blue: 0.102)          // #1A1A1A
    static let primary = Color(red: 0.910, green: 0.910, blue: 0.878)          // #E8E8E0
    static let secondary = Color(red: 0.545, green: 0.545, blue: 0.514)        // #8B8B83
    static let dimmed = Color(red: 0.400, green: 0.400, blue: 0.376)           // #666660
    static let accent = Color(red: 0.784, green: 0.659, blue: 0.306)           // #C8A84E
    static let divider = Color(red: 0.200, green: 0.200, blue: 0.188)          // #333330
    static let highlight = Color.white.opacity(0.08)
    static let selectionGlow = Color.white.opacity(0.12)

    // Status colors (muted to match Skyrim aesthetic)
    static let success = Color(red: 0.400, green: 0.650, blue: 0.400)          // Muted green
    static let failure = Color(red: 0.700, green: 0.300, blue: 0.300)          // Muted red
    static let warning = Color(red: 0.750, green: 0.580, blue: 0.280)          // Muted amber
}

// MARK: - Skyrim Typography

enum SkyrimFont {
    /// Large title — used for screen headers
    static func largeTitle() -> Font {
        .system(size: 34, weight: .light, design: .default)
    }

    /// Section header — ALL CAPS with tracking
    static func sectionHeader() -> Font {
        .system(size: 14, weight: .medium, design: .default)
    }

    /// Quest title in list
    static func questTitle() -> Font {
        .system(size: 17, weight: .light, design: .default)
    }

    /// Quest title in detail view
    static func questDetailTitle() -> Font {
        .system(size: 28, weight: .light, design: .default)
    }

    /// Body text — descriptions
    static func body() -> Font {
        .system(size: 15, weight: .light, design: .default)
    }

    /// Small text — metadata
    static func caption() -> Font {
        .system(size: 12, weight: .regular, design: .default)
    }

    /// Objective text
    static func objective() -> Font {
        .system(size: 15, weight: .light, design: .default)
    }
}

// MARK: - View Modifiers

struct SkyrimSectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(SkyrimFont.sectionHeader())
            .tracking(3)
            .textCase(.uppercase)
            .foregroundStyle(SkyrimColors.secondary)
    }
}

struct SkyrimQuestTitleStyle: ViewModifier {
    let isActive: Bool
    let isComplete: Bool

    func body(content: Content) -> some View {
        content
            .font(SkyrimFont.questTitle())
            .tracking(0.5)
            .foregroundStyle(
                isComplete ? SkyrimColors.dimmed :
                isActive ? SkyrimColors.primary :
                SkyrimColors.secondary
            )
    }
}

struct SkyrimBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(SkyrimColors.background)
    }
}

// MARK: - View Extensions

extension View {
    func skyrimSectionHeader() -> some View {
        modifier(SkyrimSectionHeaderStyle())
    }

    func skyrimQuestTitle(isActive: Bool = false, isComplete: Bool = false) -> some View {
        modifier(SkyrimQuestTitleStyle(isActive: isActive, isComplete: isComplete))
    }

    func skyrimBackground() -> some View {
        modifier(SkyrimBackgroundModifier())
    }
}
