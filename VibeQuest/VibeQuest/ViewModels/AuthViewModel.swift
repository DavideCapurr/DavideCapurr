import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        authHandle = AuthService.shared.addAuthStateListener { [weak self] user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                self?.currentUserId = user?.uid
            }
        }
    }

    deinit {
        if let handle = authHandle {
            AuthService.shared.removeAuthStateListener(handle)
        }
    }

    func register(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await AuthService.shared.register(
                email: email,
                password: password,
                displayName: displayName
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        do {
            try AuthService.shared.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
