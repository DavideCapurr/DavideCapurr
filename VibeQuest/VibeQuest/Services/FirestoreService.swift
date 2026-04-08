import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Users

    func getUser(id: String) async throws -> VQUser? {
        let doc = try await db.collection(QuestConstants.usersCollection).document(id).getDocument()
        return try doc.data(as: VQUser.self)
    }

    func updateUserBalance(userId: String, newBalance: Int) async throws {
        try await db.collection(QuestConstants.usersCollection).document(userId).updateData([
            "walletBalance": newBalance
        ])
    }

    func incrementUserStat(userId: String, field: String) async throws {
        try await db.collection(QuestConstants.usersCollection).document(userId).updateData([
            field: FieldValue.increment(Int64(1))
        ])
    }

    // MARK: - Quests

    func createQuest(_ quest: Quest) async throws -> String {
        let ref = try db.collection(QuestConstants.questsCollection).addDocument(from: quest)
        return ref.documentID
    }

    func getQuest(id: String) async throws -> Quest? {
        let doc = try await db.collection(QuestConstants.questsCollection).document(id).getDocument()
        return try doc.data(as: Quest.self)
    }

    func updateQuestStatus(questId: String, status: QuestStatus, extraFields: [String: Any] = [:]) async throws {
        var data: [String: Any] = ["status": status.rawValue]
        for (key, value) in extraFields {
            data[key] = value
        }
        try await db.collection(QuestConstants.questsCollection).document(questId).updateData(data)
    }

    func streamOpenQuests() -> AsyncStream<[Quest]> {
        AsyncStream { continuation in
            let listener = db.collection(QuestConstants.questsCollection)
                .whereField("status", isEqualTo: QuestStatus.open.rawValue)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    let quests = documents.compactMap { doc in
                        try? doc.data(as: Quest.self)
                    }
                    continuation.yield(quests)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    func streamUserQuests(userId: String, asRequester: Bool) -> AsyncStream<[Quest]> {
        let field = asRequester ? "requesterId" : "earnerId"
        return AsyncStream { continuation in
            let listener = db.collection(QuestConstants.questsCollection)
                .whereField(field, isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    let quests = documents.compactMap { doc in
                        try? doc.data(as: Quest.self)
                    }
                    continuation.yield(quests)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Submissions

    func createSubmission(_ submission: Submission) async throws -> String {
        let ref = try db.collection(QuestConstants.submissionsCollection).addDocument(from: submission)
        return ref.documentID
    }

    func getSubmission(forQuest questId: String) async throws -> Submission? {
        let snapshot = try await db.collection(QuestConstants.submissionsCollection)
            .whereField("questId", isEqualTo: questId)
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first?.data(as: Submission.self)
    }

    func updateSubmissionStatus(submissionId: String, status: SubmissionStatus) async throws {
        try await db.collection(QuestConstants.submissionsCollection).document(submissionId).updateData([
            "status": status.rawValue,
            "reviewedAt": Timestamp(date: Date())
        ])
    }

    // MARK: - Transactions

    func createTransaction(_ transaction: Transaction) async throws {
        try db.collection(QuestConstants.transactionsCollection).addDocument(from: transaction)
    }

    func getTransactions(userId: String) async throws -> [Transaction] {
        let snapshot = try await db.collection(QuestConstants.transactionsCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Transaction.self)
        }
    }

    // MARK: - Atomic Quest Payment

    func createQuestWithPayment(quest: Quest, requesterId: String) async throws -> String {
        let userRef = db.collection(QuestConstants.usersCollection).document(requesterId)
        let questRef = db.collection(QuestConstants.questsCollection).document()

        try await db.runTransaction { transaction, errorPointer in
            let userDoc: DocumentSnapshot
            do {
                userDoc = try transaction.getDocument(userRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let balance = userDoc.data()?["walletBalance"] as? Int else {
                let error = NSError(domain: "VibeQuest", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Could not read wallet balance"
                ])
                errorPointer?.pointee = error
                return nil
            }

            guard balance >= quest.totalReward else {
                let error = NSError(domain: "VibeQuest", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Insufficient balance"
                ])
                errorPointer?.pointee = error
                return nil
            }

            let newBalance = balance - quest.totalReward
            transaction.updateData(["walletBalance": newBalance], forDocument: userRef)

            do {
                try transaction.setData(from: quest, forDocument: questRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            let tx = Transaction(
                userId: requesterId,
                type: .questPayment,
                amount: quest.totalReward,
                questId: questRef.documentID,
                description: "Quest: \(quest.title)",
                balanceAfter: newBalance
            )
            let txRef = self.db.collection(QuestConstants.transactionsCollection).document()
            do {
                try transaction.setData(from: tx, forDocument: txRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            return nil
        }

        return questRef.documentID
    }

    // MARK: - Atomic Quest Approval + Payout

    func approveQuestWithPayout(questId: String, earnerId: String, earnerReward: Int) async throws {
        let questRef = db.collection(QuestConstants.questsCollection).document(questId)
        let earnerRef = db.collection(QuestConstants.usersCollection).document(earnerId)

        try await db.runTransaction { transaction, errorPointer in
            let earnerDoc: DocumentSnapshot
            do {
                earnerDoc = try transaction.getDocument(earnerRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let balance = earnerDoc.data()?["walletBalance"] as? Int else {
                let error = NSError(domain: "VibeQuest", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Could not read earner balance"
                ])
                errorPointer?.pointee = error
                return nil
            }

            let newBalance = balance + earnerReward

            transaction.updateData([
                "status": QuestStatus.completed.rawValue,
                "completedAt": Timestamp(date: Date())
            ], forDocument: questRef)

            transaction.updateData([
                "walletBalance": newBalance,
                "questsCompleted": FieldValue.increment(Int64(1))
            ], forDocument: earnerRef)

            let tx = Transaction(
                userId: earnerId,
                type: .questEarning,
                amount: earnerReward,
                questId: questId,
                description: "Quest completed",
                balanceAfter: newBalance
            )
            let txRef = self.db.collection(QuestConstants.transactionsCollection).document()
            do {
                try transaction.setData(from: tx, forDocument: txRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            return nil
        }
    }
}
