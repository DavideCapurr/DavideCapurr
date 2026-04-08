import Foundation
import FirebaseFirestore

struct VQUser: Identifiable, Codable {
    @DocumentID var id: String?
    let email: String
    var displayName: String
    var avatarUrl: String?
    var walletBalance: Int // cents
    var questsCreated: Int
    var questsCompleted: Int
    let createdAt: Date

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        avatarUrl: String? = nil,
        walletBalance: Int = 10000, // 100€ starter balance for MVP testing
        questsCreated: Int = 0,
        questsCompleted: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.walletBalance = walletBalance
        self.questsCreated = questsCreated
        self.questsCompleted = questsCompleted
        self.createdAt = createdAt
    }

    var balanceFormatted: String {
        FormatUtils.centsToEuro(walletBalance)
    }
}
