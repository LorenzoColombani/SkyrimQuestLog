import SwiftUI

struct ObjectiveRowView: View {
    let objective: Objective
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Objective marker
                Image(systemName: objective.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(
                        objective.isComplete ? SkyrimColors.dimmed : SkyrimColors.primary
                    )
                    .symbolEffect(.bounce, value: objective.isComplete)

                // Objective text
                Text(objective.title)
                    .font(SkyrimFont.objective())
                    .tracking(0.3)
                    .foregroundStyle(
                        objective.isComplete ? SkyrimColors.dimmed : SkyrimColors.primary
                    )
                    .strikethrough(objective.isComplete, color: SkyrimColors.dimmed)

                Spacer()
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(objective.title), \(objective.isComplete ? "completed" : "incomplete")")
        .accessibilityHint("Double tap to toggle completion")
    }
}

#Preview {
    VStack {
        ObjectiveRowView(
            objective: Objective(title: "Speak to Jarl Balgruuf"),
            onToggle: {}
        )
        ObjectiveRowView(
            objective: {
                let o = Objective(title: "Retrieve the Dragonstone")
                o.isComplete = true
                return o
            }(),
            onToggle: {}
        )
    }
    .padding()
    .background(SkyrimColors.background)
    .preferredColorScheme(.dark)
}
