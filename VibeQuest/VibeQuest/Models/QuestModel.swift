import Foundation
import FirebaseFirestore

enum QuestStatus: String, Codable, CaseIterable {
    case open
    case accepted
    case submitted
    case completed
    case rejected
    case expired
    case cancelled

    var label: String {
        rawValue.capitalized
    }
}

enum QuestTier: String, Codable, CaseIterable {
    case micro
    case macro

    var totalReward: Int {
        switch self {
        case .micro: return QuestConstants.microTotal
        case .macro: return QuestConstants.macroTotal
        }
    }

    var earnerReward: Int {
        switch self {
        case .micro: return QuestConstants.microEarnerReward
        case .macro: return QuestConstants.macroEarnerReward
        }
    }

    var platformFee: Int {
        switch self {
        case .micro: return QuestConstants.microPlatformFee
        case .macro: return QuestConstants.macroPlatformFee
        }
    }

    var label: String {
        switch self {
        case .micro: return "Micro"
        case .macro: return "Macro"
        }
    }

    var emoji: String {
        switch self {
        case .micro: return "⚡"
        case .macro: return "🔥"
        }
    }
}

enum TaskType: String, Codable, CaseIterable {
    case photo
    case video
    case action

    var label: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .photo: return "camera.fill"
        case .video: return "video.fill"
        case .action: return "figure.walk"
        }
    }
}

struct Quest: Identifiable, Codable {
    @DocumentID var id: String?
    let requesterId: String
    var title: String
    var description: String
    let taskType: TaskType
    let tier: QuestTier
    let totalReward: Int
    let earnerReward: Int
    let platformFee: Int
    var status: QuestStatus
    let latitude: Double
    let longitude: Double
    var address: String?
    var earnerId: String?
    let createdAt: Date
    let expiresAt: Date
    var acceptedAt: Date?
    var submittedAt: Date?
    var completedAt: Date?

    init(
        id: String? = nil,
        requesterId: String,
        title: String,
        description: String,
        taskType: TaskType,
        tier: QuestTier,
        status: QuestStatus = .open,
        latitude: Double,
        longitude: Double,
        address: String? = nil,
        earnerId: String? = nil,
        createdAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.requesterId = requesterId
        self.title = title
        self.description = description
        self.taskType = taskType
        self.tier = tier
        self.totalReward = tier.totalReward
        self.earnerReward = tier.earnerReward
        self.platformFee = tier.platformFee
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.earnerId = earnerId
        self.createdAt = createdAt
        self.expiresAt = expiresAt ?? Calendar.current.date(
            byAdding: .hour,
            value: QuestConstants.questExpiryHours,
            to: createdAt
        )!
    }

    var totalRewardFormatted: String {
        FormatUtils.centsToEuro(totalReward)
    }

    var earnerRewardFormatted: String {
        FormatUtils.centsToEuro(earnerReward)
    }

    var isExpired: Bool {
        expiresAt < Date()
    }
}
