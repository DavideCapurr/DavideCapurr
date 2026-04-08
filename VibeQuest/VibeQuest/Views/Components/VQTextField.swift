import SwiftUI

struct VQTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(VQTheme.textSecondary)
                    .frame(width: 20)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(16)
        .background(VQTheme.surface)
        .foregroundStyle(VQTheme.textPrimary)
        .clipShape(RoundedRectangle(cornerRadius: VQTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: VQTheme.radiusMd)
                .stroke(VQTheme.surfaceLight, lineWidth: 1)
        )
    }
}
