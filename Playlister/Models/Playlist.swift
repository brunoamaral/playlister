import Foundation

// MARK: - Playlist Model

/// Represents a Plex music playlist
struct Playlist: Identifiable, Hashable, Codable {
    let id: String
    let ratingKey: String
    let title: String
    let summary: String?
    let thumb: String?
    let playlistType: PlaylistType
    let duration: Int?
    let leafCount: Int
    let smart: Bool
    let addedAt: Date?
    let updatedAt: Date?
    
    enum PlaylistType: String, Codable {
        case audio
        case video
        case photo
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Plex API Response Mapping

extension Playlist {
    /// Initialize from Plex API response dictionary
    init?(from dict: [String: Any], serverURL: String, token: String? = nil) {
        guard let ratingKey = dict["ratingKey"] as? String,
              let title = dict["title"] as? String else {
            return nil
        }
        
        self.id = ratingKey
        self.ratingKey = ratingKey
        self.title = title
        self.summary = dict["summary"] as? String
        
        // Use thumb if available, otherwise fall back to composite (Plex auto-generated artwork)
        let thumbPath = dict["thumb"] as? String ?? dict["composite"] as? String
        if let path = thumbPath {
            if let token = token {
                self.thumb = serverURL + path + "?X-Plex-Token=\(token)"
            } else {
                self.thumb = serverURL + path
            }
        } else {
            self.thumb = nil
        }
        
        if let typeString = dict["playlistType"] as? String {
            self.playlistType = PlaylistType(rawValue: typeString) ?? .audio
        } else {
            self.playlistType = .audio
        }
        
        self.duration = dict["duration"] as? Int
        self.leafCount = dict["leafCount"] as? Int ?? 0
        self.smart = dict["smart"] as? Bool ?? false
        
        if let addedAtTimestamp = dict["addedAt"] as? TimeInterval {
            self.addedAt = Date(timeIntervalSince1970: addedAtTimestamp)
        } else {
            self.addedAt = nil
        }
        
        if let updatedAtTimestamp = dict["updatedAt"] as? TimeInterval {
            self.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)
        } else {
            self.updatedAt = nil
        }
    }
}

// MARK: - Preview/Sample Data

#if DEBUG
extension Playlist {
    static let sample = Playlist(
        id: "12345",
        ratingKey: "12345",
        title: "Chill Vibes",
        summary: "Relaxing music for work and study",
        thumb: nil,
        playlistType: .audio,
        duration: 7200000,
        leafCount: 25,
        smart: false,
        addedAt: Date(),
        updatedAt: Date()
    )
    
    static let samplePlaylists: [Playlist] = [
        Playlist(id: "1", ratingKey: "1", title: "Workout Mix", summary: "High energy tracks", thumb: nil, playlistType: .audio, duration: 3600000, leafCount: 15, smart: false, addedAt: Date(), updatedAt: Date()),
        Playlist(id: "2", ratingKey: "2", title: "Road Trip", summary: "Perfect for long drives", thumb: nil, playlistType: .audio, duration: 5400000, leafCount: 30, smart: false, addedAt: Date(), updatedAt: Date()),
        Playlist(id: "3", ratingKey: "3", title: "Top Rated", summary: "5-star tracks only", thumb: nil, playlistType: .audio, duration: 9000000, leafCount: 50, smart: true, addedAt: Date(), updatedAt: Date()),
        Playlist(id: "4", ratingKey: "4", title: "Recently Added", summary: "New music", thumb: nil, playlistType: .audio, duration: 1800000, leafCount: 10, smart: true, addedAt: Date(), updatedAt: Date())
    ]
}
#endif
