import SwiftUI

struct StatusChip: View {
    let status: QuestStatus

    var body: some View {
        Text(status.label)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .open: return VQTheme.cyan
        case .accepted: return .orange
        case .submitted: return .purple
        case .completed: return VQTheme.success
        case .rejected: return VQTheme.error
        case .expired: return VQTheme.textSecondary
        case .cancelled: return VQTheme.textSecondary
        }
    }
}
