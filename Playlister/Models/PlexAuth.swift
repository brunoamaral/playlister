import Foundation

// MARK: - Plex Authentication Models

/// Plex OAuth PIN for authentication flow
struct PlexAuthPin: Codable {
    let id: Int
    let code: String
    let expiresAt: Date?
    let authToken: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case expiresAt = "expires_at"
        case authToken = "auth_token"
    }
}

/// Plex User information
struct PlexUser: Identifiable, Codable {
    let id: Int
    let uuid: String
    let email: String
    let username: String
    let title: String
    let thumb: String?
    let authToken: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case email
        case username
        case title
        case thumb
        case authToken = "authToken"
    }
}

extension PlexUser {
    /// Initialize from Plex.tv user API response
    init?(from dict: [String: Any], authToken: String) {
        guard let id = dict["id"] as? Int,
              let uuid = dict["uuid"] as? String,
              let email = dict["email"] as? String,
              let username = dict["username"] as? String else {
            return nil
        }
        
        self.id = id
        self.uuid = uuid
        self.email = email
        self.username = username
        self.title = dict["title"] as? String ?? username
        self.thumb = dict["thumb"] as? String
        self.authToken = authToken
    }
}

// MARK: - Authentication State

enum AuthenticationState: Equatable {
    case unauthenticated
    case authenticating
    case waitingForOAuth(url: URL, pin: PlexAuthPin)
    case authenticated(user: PlexUser)
    case error(message: String)
    
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    var user: PlexUser? {
        if case .authenticated(let user) = self {
            return user
        }
        return nil
    }
    
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticating, .authenticating):
            return true
        case (.waitingForOAuth(let url1, _), .waitingForOAuth(let url2, _)):
            return url1 == url2
        case (.authenticated(let user1), .authenticated(let user2)):
            return user1.id == user2.id
        case (.error(let msg1), .error(let msg2)):
            return msg1 == msg2
        default:
            return false
        }
    }
}

// MARK: - Connection State

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(server: PlexServer)
    case error(message: String)
    
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    var server: PlexServer? {
        if case .connected(let server) = self {
            return server
        }
        return nil
    }
}

// MARK: - Plex Client Identifier

/// Generates and persists a unique client identifier for this app instance
struct PlexClientIdentifier {
    static let key = "PlexClientIdentifier"
    
    static var identifier: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newIdentifier = UUID().uuidString
        UserDefaults.standard.set(newIdentifier, forKey: key)
        return newIdentifier
    }
}

// MARK: - Plex Headers

/// Standard headers required for Plex API requests
struct PlexHeaders {
    static let clientIdentifier = PlexClientIdentifier.identifier
    static let product = "Playlister"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let platform = "macOS"
    static let platformVersion = ProcessInfo.processInfo.operatingSystemVersionString
    static let device = Host.current().localizedName ?? "Mac"
    
    /// Generate headers dictionary for API requests
    static func headers(token: String? = nil) -> [String: String] {
        var headers: [String: String] = [
            "X-Plex-Client-Identifier": clientIdentifier,
            "X-Plex-Product": product,
            "X-Plex-Version": version,
            "X-Plex-Platform": platform,
            "X-Plex-Platform-Version": platformVersion,
            "X-Plex-Device": device,
            "X-Plex-Device-Name": device,
            "Accept": "application/json"
        ]
        
        if let token = token {
            headers["X-Plex-Token"] = token
        }
        
        return headers
    }
}

// MARK: - Preview/Sample Data

#if DEBUG
extension PlexUser {
    static let sample = PlexUser(
        id: 12345,
        uuid: "user-uuid",
        email: "user@example.com",
        username: "plexuser",
        title: "Plex User",
        thumb: nil,
        authToken: "sample-auth-token"
    )
}
#endif
