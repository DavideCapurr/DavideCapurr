import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {}

    var currentUserId: String? {
        auth.currentUser?.uid
    }

    var isAuthenticated: Bool {
        auth.currentUser != nil
    }

    func register(email: String, password: String, displayName: String) async throws -> VQUser {
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        let user = VQUser(
            id: uid,
            email: email,
            displayName: displayName
        )

        try db.collection(QuestConstants.usersCollection)
            .document(uid)
            .setData(from: user)

        return user
    }

    func login(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }

    func logout() throws {
        try auth.signOut()
    }

    func addAuthStateListener(_ handler: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener { _, user in
            handler(user)
        }
    }

    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
}
