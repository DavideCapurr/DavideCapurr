import SwiftUI

struct RewardBadge: View {
    let tier: QuestTier
    var showAmount: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            Text(tier.emoji)
                .font(.caption)
            Text(tier.label.uppercased())
                .font(.caption2)
                .fontWeight(.black)
            if showAmount {
                Text(FormatUtils.centsToEuro(tier.earnerReward))
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tierColor.opacity(0.2))
        .foregroundStyle(tierColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(tierColor.opacity(0.5), lineWidth: 1)
        )
    }

    private var tierColor: Color {
        tier == .micro ? VQTheme.microColor : VQTheme.macroColor
    }
}
