import Foundation
import AuthenticationServices

@Observable
final class LoginViewModel: NSObject {
    var isLoading = false
    var errorMessage: String?

    func demoLogin() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthManager.shared.demoLogin()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func connectWithTikTok() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            // 1. Get the auth URL from the backend
            struct AuthUrlResponse: Decodable { let authUrl: String }
            let urlResp: AuthUrlResponse = try await APIClient.shared.request(.tiktokAuthorize)

            guard let authURL = URL(string: urlResp.authUrl) else {
                errorMessage = "Invalid authorization URL."
                return
            }

            // 2. Open TikTok OAuth in ASWebAuthenticationSession
            let callbackURL = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
                let session = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: "tiktoktrends"
                ) { url, error in
                    if let url { cont.resume(returning: url) }
                    else if let error { cont.resume(throwing: error) }
                }
                session.prefersEphemeralWebBrowserSession = false
                session.start()
            }

            // 3. Extract code + state from callback URL
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
            guard let code  = components?.queryItems?.first(where: { $0.name == "code" })?.value,
                  let state = components?.queryItems?.first(where: { $0.name == "state" })?.value else {
                errorMessage = "Missing code or state in callback."
                return
            }

            // 4. Exchange with backend
            let response: AuthResponse = try await APIClient.shared.request(
                .tiktokCallback,
                body: TikTokCallbackRequest(code: code, state: state)
            )
            await AuthManager.shared.handleAuthResponse(response)

        } catch ASWebAuthenticationSessionError.canceledLogin {
            // User cancelled — silent
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
