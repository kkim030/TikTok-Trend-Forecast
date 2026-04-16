import Foundation

@Observable
final class AuthManager {
    static let shared = AuthManager()

    private(set) var isAuthenticated = false
    private(set) var currentUser: StoredUser?

    private init() {
        // Restore session from Keychain on launch
        if let token = KeychainService.loadJWT(),
           let user  = KeychainService.loadUserInfo() {
            APIClient.shared.bearerToken = token
            currentUser = user
            isAuthenticated = true
        }

        // Wire 401 handler
        APIClient.shared.onUnauthorized = { [weak self] in
            Task { @MainActor in self?.logout() }
        }
    }

    // MARK: - Login

    @MainActor
    func handleAuthResponse(_ response: AuthResponse) {
        let user = StoredUser(
            userId:       response.userId,
            tiktokHandle: response.tiktokHandle,
            niche:        response.niche,
            displayName:  response.displayName,
            avatarUrl:    response.avatarUrl
        )
        KeychainService.saveJWT(response.token)
        KeychainService.saveUserInfo(user)
        APIClient.shared.bearerToken = response.token
        currentUser = user
        isAuthenticated = true
    }

    // MARK: - Demo Login

    func demoLogin() async throws {
        let response: AuthResponse = try await APIClient.shared.request(.demoLogin)
        await handleAuthResponse(response)
    }

    // MARK: - Logout

    @MainActor
    func logout() {
        KeychainService.deleteJWT()
        KeychainService.deleteUserInfo()
        APIClient.shared.bearerToken = nil
        currentUser = nil
        isAuthenticated = false
    }
}
