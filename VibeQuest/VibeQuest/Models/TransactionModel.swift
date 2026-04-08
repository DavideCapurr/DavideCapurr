import Foundation
import FirebaseFirestore

enum TransactionType: String, Codable {
    case deposit
    case questPayment
    case questEarning
    case refund

    var label: String {
        switch self {
        case .deposit: return "Deposit"
        case .questPayment: return "Quest Payment"
        case .questEarning: return "Quest Earning"
        case .refund: return "Refund"
        }
    }

    var icon: String {
        switch self {
        case .deposit: return "arrow.down.circle.fill"
        case .questPayment: return "arrow.up.circle.fill"
        case .questEarning: return "star.circle.fill"
        case .refund: return "arrow.uturn.left.circle.fill"
        }
    }

    var isCredit: Bool {
        switch self {
        case .deposit, .questEarning, .refund: return true
        case .questPayment: return false
        }
    }
}

struct Transaction: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let type: TransactionType
    let amount: Int // cents, always positive
    var questId: String?
    let description: String
    let balanceAfter: Int
    let createdAt: Date

    init(
        id: String? = nil,
        userId: String,
        type: TransactionType,
        amount: Int,
        questId: String? = nil,
        description: String,
        balanceAfter: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.amount = amount
        self.questId = questId
        self.description = description
        self.balanceAfter = balanceAfter
        self.createdAt = createdAt
    }

    var amountFormatted: String {
        let prefix = type.isCredit ? "+" : "-"
        return "\(prefix)\(FormatUtils.centsToEuro(amount))"
    }
}
