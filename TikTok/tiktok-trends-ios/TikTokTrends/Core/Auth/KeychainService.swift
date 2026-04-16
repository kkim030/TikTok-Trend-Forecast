import Foundation
import Security

enum KeychainService {
    private static let jwtKey     = "com.tiktoktrends.jwt"
    private static let userKey    = "com.tiktoktrends.user"

    // MARK: - JWT

    static func saveJWT(_ token: String) {
        save(key: jwtKey, value: token)
    }

    static func loadJWT() -> String? {
        load(key: jwtKey)
    }

    static func deleteJWT() {
        delete(key: jwtKey)
    }

    // MARK: - Stored User Info (JSON-encoded AuthResponse minus token)

    static func saveUserInfo(_ user: StoredUser) {
        if let data = try? JSONEncoder().encode(user),
           let str = String(data: data, encoding: .utf8) {
            save(key: userKey, value: str)
        }
    }

    static func loadUserInfo() -> StoredUser? {
        guard let str = load(key: userKey),
              let data = str.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(StoredUser.self, from: data)
    }

    static func deleteUserInfo() {
        delete(key: userKey)
    }

    // MARK: - Primitives

    private static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecValueData:        data,
            kSecAttrAccessible:   kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Stored User (lightweight, Keychain-safe)

struct StoredUser: Codable {
    let userId: String
    let tiktokHandle: String
    let niche: String?
    let displayName: String?
    let avatarUrl: String?
}
