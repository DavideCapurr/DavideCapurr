import SwiftUI

enum VQTheme {
    // MARK: - Colors
    static let background = Color(hex: "0D0D1A")
    static let surface = Color(hex: "1A1A2E")
    static let surfaceLight = Color(hex: "252542")
    static let primary = Color(hex: "E94560")
    static let secondary = Color(hex: "00FF87")
    static let gold = Color(hex: "FFD700")
    static let cyan = Color(hex: "00E5FF")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9E9E9E")
    static let success = Color(hex: "69F0AE")
    static let error = Color(hex: "FF5252")

    // MARK: - Quest Colors
    static let microColor = secondary
    static let macroColor = gold

    // MARK: - Spacing
    static let paddingSm: CGFloat = 8
    static let paddingMd: CGFloat = 16
    static let paddingLg: CGFloat = 24
    static let paddingXl: CGFloat = 32

    // MARK: - Corner Radius
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
    static let radiusXl: CGFloat = 24
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
