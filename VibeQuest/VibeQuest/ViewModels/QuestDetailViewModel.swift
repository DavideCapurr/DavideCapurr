import Foundation
import FirebaseFirestore

@MainActor
final class QuestDetailViewModel: ObservableObject {
    @Published var quest: Quest
    @Published var submission: Submission?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared

    init(quest: Quest) {
        self.quest = quest
    }

    func loadSubmission() async {
        guard let questId = quest.id else { return }
        do {
            submission = try await firestoreService.getSubmission(forQuest: questId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptQuest(earnerId: String) async {
        guard let questId = quest.id else { return }
        isLoading = true
        errorMessage = nil

        do {
            try await firestoreService.updateQuestStatus(
                questId: questId,
                status: .accepted,
                extraFields: [
                    "earnerId": earnerId,
                    "acceptedAt": Date()
                ]
            )
            quest.status = .accepted
            quest.earnerId = earnerId
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func approveSubmission() async {
        guard let questId = quest.id,
              let earnerId = quest.earnerId,
              let submissionId = submission?.id else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await firestoreService.updateSubmissionStatus(
                submissionId: submissionId,
                status: .approved
            )
            try await firestoreService.approveQuestWithPayout(
                questId: questId,
                earnerId: earnerId,
                earnerReward: quest.earnerReward
            )
            quest.status = .completed
            submission?.status = .approved
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func rejectSubmission() async {
        guard let questId = quest.id,
              let submissionId = submission?.id else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await firestoreService.updateSubmissionStatus(
                submissionId: submissionId,
                status: .rejected
            )
            try await firestoreService.updateQuestStatus(
                questId: questId,
                status: .open,
                extraFields: [
                    "earnerId": FirebaseFirestore.FieldValue.delete(),
                    "acceptedAt": FirebaseFirestore.FieldValue.delete(),
                    "submittedAt": FirebaseFirestore.FieldValue.delete()
                ]
            )
            quest.status = .open
            quest.earnerId = nil
            submission?.status = .rejected
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

