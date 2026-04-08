import SwiftUI

struct QuestCard: View {
    let quest: Quest
    var distance: String? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    RewardBadge(tier: quest.tier)
                    Spacer()
                    StatusChip(status: quest.status)
                }

                Text(quest.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(VQTheme.textPrimary)
                    .lineLimit(1)

                if !quest.description.isEmpty {
                    Text(quest.description)
                        .font(.subheadline)
                        .foregroundStyle(VQTheme.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: 16) {
                    Label(quest.taskType.label, systemImage: quest.taskType.icon)
                        .font(.caption)
                        .foregroundStyle(VQTheme.textSecondary)

                    if let distance {
                        Label(distance, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(VQTheme.cyan)
                    }

                    Spacer()

                    Text(quest.earnerRewardFormatted)
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundStyle(quest.tier == .micro ? VQTheme.microColor : VQTheme.macroColor)
                }
            }
            .padding(VQTheme.paddingMd)
            .background(VQTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: VQTheme.radiusLg)
                    .stroke(
                        quest.tier == .micro
                            ? VQTheme.microColor.opacity(0.15)
                            : VQTheme.macroColor.opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
