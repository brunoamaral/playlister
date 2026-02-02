import Foundation
import AppKit

// MARK: - SSL Bypass Delegate

/// URLSession delegate that allows self-signed certificates for local servers
final class InsecureURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Accept any server certificate for local connections
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Plex API Service

/// Main service for interacting with the Plex API
actor PlexAPIService {
    
    // MARK: - Singleton
    
    static let shared = PlexAPIService()
    
    // MARK: - Plex.tv API Endpoints
    
    private enum PlexTVEndpoint {
        static let base = "https://plex.tv"
        static let pins = "/api/v2/pins"
        static let user = "/api/v2/user"
        static let resources = "/api/v2/resources"
    }
    
    // MARK: - Properties
    
    private var session: URLSession
    private var insecureSession: URLSession
    private let insecureDelegate = InsecureURLSessionDelegate()
    private var authToken: String?
    private var currentServer: PlexServer?
    private var allowInsecureConnections: Bool = false
    
    // MARK: - Initialization
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.insecureSession = URLSession(configuration: config, delegate: insecureDelegate, delegateQueue: nil)
        
        // Load preference
        self.allowInsecureConnections = UserDefaults.standard.bool(forKey: "allowInsecureConnections")
    }
    
    // MARK: - Configuration
    
    func configure(authToken: String?, server: PlexServer?) {
        self.authToken = authToken
        self.currentServer = server
    }
    
    func setAllowInsecureConnections(_ allow: Bool) {
        self.allowInsecureConnections = allow
    }
    
    /// Returns the appropriate session based on insecure connection settings
    private var activeSession: URLSession {
        allowInsecureConnections ? insecureSession : session
    }
    
    // MARK: - OAuth Authentication
    
    /// Request a new PIN for OAuth authentication
    func requestOAuthPin() async throws -> (pin: PlexAuthPin, authURL: URL) {
        let url = URL(string: PlexTVEndpoint.base + PlexTVEndpoint.pins)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = PlexHeaders.headers()
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "strong=true".data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw PlexAPIError.authenticationFailed
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? Int,
              let code = json["code"] as? String else {
            throw PlexAPIError.invalidResponse
        }
        
        let pin = PlexAuthPin(id: id, code: code, expiresAt: nil, authToken: nil)
        
        // Build OAuth URL - Plex uses fragment with exclamation mark: https://app.plex.tv/auth#!?...
        let params = [
            "clientID=\(PlexHeaders.clientIdentifier)",
            "code=\(code)",
            "context[device][product]=\(PlexHeaders.product.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? PlexHeaders.product)"
        ].joined(separator: "&")
        
        guard let authURL = URL(string: "https://app.plex.tv/auth#!?\(params)") else {
            throw PlexAPIError.invalidURL
        }
        
        return (pin, authURL)
    }
    
    /// Check if the PIN has been claimed (user completed OAuth)
    func checkPinStatus(pin: PlexAuthPin) async throws -> String? {
        let url = URL(string: "\(PlexTVEndpoint.base)\(PlexTVEndpoint.pins)/\(pin.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = PlexHeaders.headers()
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.authenticationFailed
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PlexAPIError.invalidResponse
        }
        
        // authToken will be present if user completed authentication
        return json["authToken"] as? String
    }
    
    /// Fetch the authenticated user's information
    func fetchUser(authToken: String) async throws -> PlexUser {
        let url = URL(string: PlexTVEndpoint.base + PlexTVEndpoint.user)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: authToken)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.authenticationFailed
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let user = PlexUser(from: json, authToken: authToken) else {
            throw PlexAPIError.invalidResponse
        }
        
        self.authToken = authToken
        return user
    }
    
    // MARK: - Server Discovery
    
    /// Fetch available Plex servers for the authenticated user
    func fetchServers() async throws -> [PlexServer] {
        guard let token = authToken else {
            throw PlexAPIError.notAuthenticated
        }
        
        var components = URLComponents(string: PlexTVEndpoint.base + PlexTVEndpoint.resources)!
        components.queryItems = [
            URLQueryItem(name: "includeHttps", value: "1"),
            URLQueryItem(name: "includeRelay", value: "0")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.serverError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw PlexAPIError.invalidResponse
        }
        
        // Filter to only servers (not players)
        let servers = json
            .filter { ($0["provides"] as? String)?.contains("server") == true }
            .compactMap { PlexServer(from: $0) }
        
        return servers
    }
    
    /// Connect to a specific server
    func connect(to server: PlexServer) async throws {
        // Test connection
        let url = URL(string: server.baseURL + "/identity")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: authToken)
        request.timeoutInterval = 10
        
        let (_, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.connectionFailed
        }
        
        self.currentServer = server
    }
    
    // MARK: - Music Libraries
    
    /// Fetch music libraries from the connected server
    func fetchMusicLibraries() async throws -> [MusicLibrary] {
        guard let server = currentServer else {
            throw PlexAPIError.notConnected
        }
        
        let url = URL(string: server.baseURL + "/library/sections")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: authToken)
        
        let (data, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.serverError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let container = json["MediaContainer"] as? [String: Any],
              let directories = container["Directory"] as? [[String: Any]] else {
            throw PlexAPIError.invalidResponse
        }
        
        return directories
            .compactMap { MusicLibrary(from: $0) }
            .filter { $0.isMusic }
    }
    
    // MARK: - Playlists
    
    /// Fetch all audio playlists
    func fetchPlaylists() async throws -> [Playlist] {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        var components = URLComponents(string: server.baseURL + "/playlists")!
        components.queryItems = [
            URLQueryItem(name: "playlistType", value: "audio")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (data, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.serverError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let container = json["MediaContainer"] as? [String: Any] else {
            throw PlexAPIError.invalidResponse
        }
        
        guard let metadata = container["Metadata"] as? [[String: Any]] else {
            // No playlists yet - return empty array
            return []
        }
        
        return metadata.compactMap { Playlist(from: $0, serverURL: server.baseURL, token: token) }
    }
    
    /// Fetch tracks for a specific playlist
    func fetchPlaylistTracks(playlistId: String) async throws -> [PlaylistItem] {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        let url = URL(string: server.baseURL + "/playlists/\(playlistId)/items")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (data, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.serverError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let container = json["MediaContainer"] as? [String: Any] else {
            throw PlexAPIError.invalidResponse
        }
        
        guard let metadata = container["Metadata"] as? [[String: Any]] else {
            return []
        }
        
        return metadata.enumerated().compactMap { index, dict -> PlaylistItem? in
            guard let track = Track(from: dict, serverURL: server.baseURL, token: token) else {
                return nil
            }
            // For smart playlists, playlistItemID might not exist - use ratingKey as fallback
            let playlistItemId: String
            if let itemId = dict["playlistItemID"] as? Int {
                playlistItemId = "\(itemId)"
            } else if let ratingKey = dict["ratingKey"] as? String {
                playlistItemId = ratingKey
            } else {
                playlistItemId = "\(index)"
            }
            return PlaylistItem(
                id: playlistItemId,
                playlistItemID: playlistItemId,
                track: track,
                playlistOrder: index
            )
        }
    }
    
    /// Create a new playlist
    /// Note: Plex may require at least one track URI to create a playlist
    func createPlaylist(title: String, trackURIs: [String] = []) async throws -> Playlist {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        var components = URLComponents(string: server.baseURL + "/playlists")!
        components.queryItems = [
            URLQueryItem(name: "type", value: "audio"),
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "smart", value: "0")
        ]
        
        if !trackURIs.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "uri", value: trackURIs.joined(separator: ",")))
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlexAPIError.invalidResponse
        }
        
        // Log for debugging
        #if DEBUG
        print("Create playlist response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Create playlist response: \(responseString)")
        }
        #endif
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            // If we get a 400 error without tracks, it might mean Plex requires at least one track
            if httpResponse.statusCode == 400 && trackURIs.isEmpty {
                throw PlexAPIError.playlistRequiresTrack
            }
            throw PlexAPIError.serverError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let container = json["MediaContainer"] as? [String: Any],
              let metadata = container["Metadata"] as? [[String: Any]],
              let playlistDict = metadata.first,
              let playlist = Playlist(from: playlistDict, serverURL: server.baseURL, token: token) else {
            throw PlexAPIError.invalidResponse
        }
        
        return playlist
    }
    
    /// Update a playlist's title and/or summary
    func updatePlaylist(playlistId: String, title: String? = nil, summary: String? = nil) async throws -> Playlist {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        var components = URLComponents(string: server.baseURL + "/playlists/\(playlistId)")!
        var queryItems: [URLQueryItem] = []
        
        if let title = title {
            queryItems.append(URLQueryItem(name: "title", value: title))
        }
        if let summary = summary {
            queryItems.append(URLQueryItem(name: "summary", value: summary))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (data, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.serverError
        }
        
        // Try to parse response, otherwise fetch the updated playlist
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let container = json["MediaContainer"] as? [String: Any],
           let metadata = container["Metadata"] as? [[String: Any]],
           let playlistDict = metadata.first,
           let playlist = Playlist(from: playlistDict, serverURL: server.baseURL, token: token) {
            return playlist
        }
        
        // Fetch updated playlist
        let playlists = try await fetchPlaylists()
        guard let updated = playlists.first(where: { $0.id == playlistId }) else {
            throw PlexAPIError.invalidResponse
        }
        return updated
    }
    
    /// Get auth token for authenticated image URLs
    func getAuthToken() -> String? {
        return authToken
    }
    
    /// Delete a playlist
    func deletePlaylist(playlistId: String) async throws {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        let url = URL(string: server.baseURL + "/playlists/\(playlistId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (_, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw PlexAPIError.serverError
        }
    }
    
    /// Add tracks to a playlist
    func addToPlaylist(playlistId: String, trackURIs: [String]) async throws {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        var components = URLComponents(string: server.baseURL + "/playlists/\(playlistId)/items")!
        components.queryItems = [
            URLQueryItem(name: "uri", value: trackURIs.joined(separator: ","))
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (_, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.serverError
        }
    }
    
    /// Remove a track from a playlist
    func removeFromPlaylist(playlistId: String, playlistItemId: String) async throws {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        let url = URL(string: server.baseURL + "/playlists/\(playlistId)/items/\(playlistItemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (_, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw PlexAPIError.serverError
        }
    }
    
    /// Move a track within a playlist (reorder)
    func movePlaylistItem(playlistId: String, playlistItemId: String, afterItemId: String?) async throws {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        var components = URLComponents(string: server.baseURL + "/playlists/\(playlistId)/items/\(playlistItemId)/move")!
        if let afterId = afterItemId {
            components.queryItems = [URLQueryItem(name: "after", value: afterId)]
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (_, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.serverError
        }
    }
    
    // MARK: - Search
    
    /// Search for tracks across all music libraries
    func searchTracks(query: String, libraryKey: String? = nil) async throws -> [Track] {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        // If no library key provided, search all
        let searchPath: String
        if let key = libraryKey {
            searchPath = "/library/sections/\(key)/search"
        } else {
            searchPath = "/search"
        }
        
        var components = URLComponents(string: server.baseURL + searchPath)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "type", value: "10"), // 10 = track
            URLQueryItem(name: "limit", value: "50")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (data, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.serverError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let container = json["MediaContainer"] as? [String: Any] else {
            throw PlexAPIError.invalidResponse
        }
        
        guard let metadata = container["Metadata"] as? [[String: Any]] else {
            return []
        }
        
        return metadata.compactMap { Track(from: $0, serverURL: server.baseURL, token: token) }
    }
    
    // MARK: - Track URI Helper
    
    /// Build a track URI for playlist operations
    func trackURI(for track: Track, libraryKey: String) -> String {
        guard let server = currentServer else { return "" }
        return "server://\(server.machineIdentifier)/com.plexapp.plugins.library/library/metadata/\(track.ratingKey)"
    }
    
    // MARK: - Smart Playlist Operations
    
    /// Create a new smart playlist with filter rules
    func createSmartPlaylist(title: String, libraryKey: String, filter: String, limit: Int?, sort: String?) async throws -> Playlist {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        var components = URLComponents(string: server.baseURL + "/playlists")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "type", value: "audio"),
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "smart", value: "1"),
            URLQueryItem(name: "uri", value: "server://\(server.machineIdentifier)/com.plexapp.plugins.library/library/sections/\(libraryKey)/all?\(filter)")
        ]
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "sort", value: sort))
        }
        
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlexAPIError.invalidResponse
        }
        
        #if DEBUG
        print("Create smart playlist response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Create smart playlist response: \(responseString)")
        }
        #endif
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw PlexAPIError.serverError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let container = json["MediaContainer"] as? [String: Any],
              let metadata = container["Metadata"] as? [[String: Any]],
              let playlistDict = metadata.first,
              let playlist = Playlist(from: playlistDict, serverURL: server.baseURL, token: token) else {
            throw PlexAPIError.invalidResponse
        }
        
        return playlist
    }
    
    /// Update an existing smart playlist's filter rules
    func updateSmartPlaylist(playlistId: String, libraryKey: String, title: String?, filter: String?, limit: Int?, sort: String?) async throws -> Playlist {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        var components = URLComponents(string: server.baseURL + "/playlists/\(playlistId)")!
        var queryItems: [URLQueryItem] = []
        
        if let title = title {
            queryItems.append(URLQueryItem(name: "title", value: title))
        }
        
        if let filter = filter {
            queryItems.append(URLQueryItem(name: "uri", value: "server://\(server.machineIdentifier)/com.plexapp.plugins.library/library/sections/\(libraryKey)/all?\(filter)"))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "sort", value: sort))
        }
        
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (data, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.serverError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let container = json["MediaContainer"] as? [String: Any],
              let metadata = container["Metadata"] as? [[String: Any]],
              let playlistDict = metadata.first,
              let playlist = Playlist(from: playlistDict, serverURL: server.baseURL, token: token) else {
            throw PlexAPIError.invalidResponse
        }
        
        return playlist
    }
    
    /// Get the library key for the music library
    func getMusicLibraryKey() async throws -> String? {
        guard let server = currentServer, let token = authToken else {
            throw PlexAPIError.notConnected
        }
        
        var components = URLComponents(string: server.baseURL + "/library/sections")!
        components.queryItems = [URLQueryItem(name: "X-Plex-Token", value: token)]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = PlexHeaders.headers(token: token)
        
        let (data, response) = try await activeSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PlexAPIError.serverError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let container = json["MediaContainer"] as? [String: Any],
              let directories = container["Directory"] as? [[String: Any]] else {
            throw PlexAPIError.invalidResponse
        }
        
        // Find music library
        for dir in directories {
            if let type = dir["type"] as? String, type == "artist",
               let key = dir["key"] as? String {
                return key
            }
        }
        
        return nil
    }
    
    // MARK: - Signout
    
    func signOut() {
        authToken = nil
        currentServer = nil
    }
}

// MARK: - Plex API Errors

enum PlexAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notAuthenticated
    case authenticationFailed
    case notConnected
    case connectionFailed
    case serverError
    case networkError(underlying: Error)
    case playlistRequiresTrack
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .notAuthenticated:
            return "Not authenticated. Please sign in."
        case .authenticationFailed:
            return "Authentication failed"
        case .notConnected:
            return "Not connected to a Plex server"
        case .connectionFailed:
            return "Failed to connect to server"
        case .serverError:
            return "Server error"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .playlistRequiresTrack:
            return "Plex requires at least one track to create a playlist. Search and add a track first."
        }
    }
}
