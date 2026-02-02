import Foundation
import Security

// MARK: - Keychain Service

/// Secure storage for Plex authentication tokens using the system Keychain
final class KeychainService {
    
    // MARK: - Keys
    
    private enum Keys {
        static let service = "com.playlister.app"
        static let authToken = "plex_auth_token"
        static let userData = "plex_user_data"
    }
    
    // MARK: - Singleton
    
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Auth Token
    
    /// Save the Plex auth token to keychain
    func saveAuthToken(_ token: String) throws {
        let data = Data(token.utf8)
        try save(data: data, forKey: Keys.authToken)
    }
    
    /// Retrieve the stored Plex auth token
    func getAuthToken() -> String? {
        guard let data = getData(forKey: Keys.authToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Delete the stored auth token
    func deleteAuthToken() throws {
        try delete(forKey: Keys.authToken)
    }
    
    // MARK: - User Data
    
    /// Save user information to keychain
    func saveUser(_ user: PlexUser) throws {
        let data = try JSONEncoder().encode(user)
        try save(data: data, forKey: Keys.userData)
    }
    
    /// Retrieve stored user information
    func getUser() -> PlexUser? {
        guard let data = getData(forKey: Keys.userData) else { return nil }
        return try? JSONDecoder().decode(PlexUser.self, from: data)
    }
    
    /// Delete stored user data
    func deleteUser() throws {
        try delete(forKey: Keys.userData)
    }
    
    // MARK: - Clear All
    
    /// Remove all stored credentials
    func clearAll() throws {
        try? deleteAuthToken()
        try? deleteUser()
    }
    
    // MARK: - Private Keychain Operations
    
    private func save(data: Data, forKey key: String) throws {
        // First try to delete any existing item
        try? delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }
    
    private func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return result as? Data
    }
    
    private func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case saveFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case readFailed(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        case .readFailed(let status):
            return "Failed to read from keychain: \(status)"
        }
    }
}
