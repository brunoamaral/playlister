import Foundation

// MARK: - Plex Server Model

/// Represents a Plex Media Server connection
struct PlexServer: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let address: String
    let port: Int
    let scheme: String
    let accessToken: String?
    let isLocal: Bool
    let isOwned: Bool
    let machineIdentifier: String
    
    /// Full base URL for API requests
    var baseURL: String {
        "\(scheme)://\(address):\(port)"
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(machineIdentifier)
    }
    
    static func == (lhs: PlexServer, rhs: PlexServer) -> Bool {
        lhs.machineIdentifier == rhs.machineIdentifier
    }
}

// MARK: - Plex API Response Mapping

extension PlexServer {
    /// Initialize from Plex.tv resources API response
    init?(from dict: [String: Any]) {
        guard let name = dict["name"] as? String,
              let machineIdentifier = dict["clientIdentifier"] as? String,
              let connections = dict["connections"] as? [[String: Any]],
              let firstConnection = connections.first else {
            return nil
        }
        
        // Prefer local connections when available
        let preferredConnection = connections.first { ($0["local"] as? Bool) == true } ?? firstConnection
        
        guard let address = preferredConnection["address"] as? String,
              let port = preferredConnection["port"] as? Int else {
            return nil
        }
        
        self.id = machineIdentifier
        self.name = name
        self.address = address
        self.port = port
        self.scheme = preferredConnection["protocol"] as? String ?? "http"
        self.accessToken = dict["accessToken"] as? String
        self.isLocal = preferredConnection["local"] as? Bool ?? false
        self.isOwned = dict["owned"] as? Bool ?? false
        self.machineIdentifier = machineIdentifier
    }
}

// MARK: - Music Library

/// Represents a music library section on a Plex server
struct MusicLibrary: Identifiable, Hashable, Codable {
    let id: String
    let key: String
    let title: String
    let type: String
    let uuid: String
    
    var isMusic: Bool {
        type == "artist"
    }
}

extension MusicLibrary {
    /// Initialize from Plex library sections API response
    init?(from dict: [String: Any]) {
        guard let key = dict["key"] as? String,
              let title = dict["title"] as? String,
              let type = dict["type"] as? String else {
            return nil
        }
        
        self.id = key
        self.key = key
        self.title = title
        self.type = type
        self.uuid = dict["uuid"] as? String ?? key
    }
}

// MARK: - Preview/Sample Data

#if DEBUG
extension PlexServer {
    static let sample = PlexServer(
        id: "server1",
        name: "Home Media Server",
        address: "192.168.1.100",
        port: 32400,
        scheme: "http",
        accessToken: "sample-token",
        isLocal: true,
        isOwned: true,
        machineIdentifier: "server1"
    )
}

extension MusicLibrary {
    static let sample = MusicLibrary(
        id: "1",
        key: "1",
        title: "Music",
        type: "artist",
        uuid: "music-library-uuid"
    )
}
#endif
