import Foundation

enum QuestConstants {
    // Reward tiers (in euro cents to avoid floating point)
    static let microTotal: Int = 250        // 2.50€
    static let microEarnerReward: Int = 150 // 1.50€
    static let microPlatformFee: Int = 100  // 1.00€

    static let macroTotal: Int = 1000       // 10.00€
    static let macroEarnerReward: Int = 750 // 7.50€
    static let macroPlatformFee: Int = 250  // 2.50€

    // Quest settings
    static let defaultRadiusKm: Double = 5.0
    static let maxVideoSeconds: Int = 15
    static let questExpiryHours: Int = 24

    // Firestore collections
    static let usersCollection = "users"
    static let questsCollection = "quests"
    static let submissionsCollection = "submissions"
    static let transactionsCollection = "transactions"
}

enum FormatUtils {
    static func centsToEuro(_ cents: Int) -> String {
        let euros = Double(cents) / 100.0
        return String(format: "%.2f€", euros)
    }

    static func distanceString(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000.0)
        }
    }
}
