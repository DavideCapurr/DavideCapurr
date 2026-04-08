import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: VQUser?
    @Published var transactions: [Transaction] = []
    @Published var createdQuests: [Quest] = []
    @Published var acceptedQuests: [Quest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared
    private var createdQuestsTask: Task<Void, Never>?
    private var acceptedQuestsTask: Task<Void, Never>?

    func loadProfile(userId: String) async {
        isLoading = true
        do {
            user = try await firestoreService.getUser(id: userId)
            transactions = try await firestoreService.getTransactions(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func startListeningQuests(userId: String) {
        createdQuestsTask = Task {
            for await quests in firestoreService.streamUserQuests(userId: userId, asRequester: true) {
                self.createdQuests = quests
            }
        }

        acceptedQuestsTask = Task {
            for await quests in firestoreService.streamUserQuests(userId: userId, asRequester: false) {
                self.acceptedQuests = quests
            }
        }
    }

    func stopListening() {
        createdQuestsTask?.cancel()
        acceptedQuestsTask?.cancel()
    }

    func refresh(userId: String) async {
        await loadProfile(userId: userId)
    }
}
