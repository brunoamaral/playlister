import Foundation

// MARK: - Track Model

/// Represents a music track from Plex
struct Track: Identifiable, Hashable, Codable {
    let id: String
    let ratingKey: String
    let title: String
    let artistName: String
    let albumName: String
    let duration: Int // in milliseconds
    let trackNumber: Int?
    let year: Int?
    let thumb: String?
    let rating: Double?
    let playCount: Int?
    let lastViewedAt: Date?
    let addedAt: Date?
    let mediaKey: String?
    let genre: String?
    
    /// Playback URL for streaming
    var streamURL: String?
    
    // MARK: - Computed Properties
    
    /// Duration formatted as MM:SS
    var formattedDuration: String {
        let totalSeconds = duration / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Display string combining artist and album
    var artistAndAlbum: String {
        if albumName.isEmpty {
            return artistName
        }
        return "\(artistName) — \(albumName)"
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Plex API Response Mapping

extension Track {
    /// Initialize from Plex API response dictionary
    init?(from dict: [String: Any], serverURL: String, token: String) {
        guard let ratingKey = dict["ratingKey"] as? String,
              let title = dict["title"] as? String else {
            return nil
        }
        
        self.id = ratingKey
        self.ratingKey = ratingKey
        self.title = title
        
        // Artist can be in "grandparentTitle" (for album tracks) or "originalTitle"
        self.artistName = dict["grandparentTitle"] as? String
            ?? dict["originalTitle"] as? String
            ?? "Unknown Artist"
        
        // Album is typically in "parentTitle"
        self.albumName = dict["parentTitle"] as? String ?? ""
        
        self.duration = dict["duration"] as? Int ?? 0
        self.trackNumber = dict["index"] as? Int
        self.year = dict["year"] as? Int
            ?? dict["parentYear"] as? Int
        
        if let thumbPath = dict["thumb"] as? String
            ?? dict["parentThumb"] as? String
            ?? dict["grandparentThumb"] as? String {
            self.thumb = serverURL + thumbPath + "?X-Plex-Token=\(token)"
        } else {
            self.thumb = nil
        }
        
        self.rating = dict["userRating"] as? Double ?? dict["rating"] as? Double
        self.playCount = dict["viewCount"] as? Int
        
        if let lastViewedTimestamp = dict["lastViewedAt"] as? TimeInterval {
            self.lastViewedAt = Date(timeIntervalSince1970: lastViewedTimestamp)
        } else {
            self.lastViewedAt = nil
        }
        
        if let addedAtTimestamp = dict["addedAt"] as? TimeInterval {
            self.addedAt = Date(timeIntervalSince1970: addedAtTimestamp)
        } else {
            self.addedAt = nil
        }
        
        // Extract media key for streaming
        if let mediaArray = dict["Media"] as? [[String: Any]],
           let firstMedia = mediaArray.first,
           let partArray = firstMedia["Part"] as? [[String: Any]],
           let firstPart = partArray.first,
           let key = firstPart["key"] as? String {
            self.mediaKey = key
            self.streamURL = serverURL + key + "?X-Plex-Token=\(token)"
        } else {
            self.mediaKey = nil
            self.streamURL = nil
        }
        
        // Genre extraction
        if let genreArray = dict["Genre"] as? [[String: Any]],
           let firstGenre = genreArray.first,
           let genreTag = firstGenre["tag"] as? String {
            self.genre = genreTag
        } else {
            self.genre = nil
        }
    }
}

// MARK: - Playlist Item (Track in playlist context)

/// Wrapper for a track within a playlist, including playlist-specific metadata
struct PlaylistItem: Identifiable, Hashable {
    let id: String
    let playlistItemID: String
    let track: Track
    let playlistOrder: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(playlistItemID)
    }
    
    static func == (lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
        lhs.playlistItemID == rhs.playlistItemID
    }
}

// MARK: - Preview/Sample Data

#if DEBUG
extension Track {
    static let sample = Track(
        id: "track1",
        ratingKey: "track1",
        title: "Midnight City",
        artistName: "M83",
        albumName: "Hurry Up, We're Dreaming",
        duration: 243000,
        trackNumber: 1,
        year: 2011,
        thumb: nil,
        rating: 4.5,
        playCount: 42,
        lastViewedAt: Date(),
        addedAt: Date(),
        mediaKey: nil,
        genre: "Electronic",
        streamURL: nil
    )
    
    static let sampleTracks: [Track] = [
        Track(id: "t1", ratingKey: "t1", title: "Midnight City", artistName: "M83", albumName: "Hurry Up, We're Dreaming", duration: 243000, trackNumber: 1, year: 2011, thumb: nil, rating: 5.0, playCount: 42, lastViewedAt: nil, addedAt: nil, mediaKey: nil, genre: "Electronic", streamURL: nil),
        Track(id: "t2", ratingKey: "t2", title: "Digital Love", artistName: "Daft Punk", albumName: "Discovery", duration: 301000, trackNumber: 3, year: 2001, thumb: nil, rating: 4.5, playCount: 38, lastViewedAt: nil, addedAt: nil, mediaKey: nil, genre: "Electronic", streamURL: nil),
        Track(id: "t3", ratingKey: "t3", title: "Intro", artistName: "The xx", albumName: "xx", duration: 127000, trackNumber: 1, year: 2009, thumb: nil, rating: 4.0, playCount: 25, lastViewedAt: nil, addedAt: nil, mediaKey: nil, genre: "Indie", streamURL: nil),
        Track(id: "t4", ratingKey: "t4", title: "Time", artistName: "Pink Floyd", albumName: "The Dark Side of the Moon", duration: 413000, trackNumber: 4, year: 1973, thumb: nil, rating: 5.0, playCount: 100, lastViewedAt: nil, addedAt: nil, mediaKey: nil, genre: "Progressive Rock", streamURL: nil),
        Track(id: "t5", ratingKey: "t5", title: "Bizarre Love Triangle", artistName: "New Order", albumName: "Brotherhood", duration: 413000, trackNumber: 5, year: 1986, thumb: nil, rating: 4.5, playCount: 60, lastViewedAt: nil, addedAt: nil, mediaKey: nil, genre: "Synth-pop", streamURL: nil)
    ]
}

extension PlaylistItem {
    static let sampleItems: [PlaylistItem] = Track.sampleTracks.enumerated().map { index, track in
        PlaylistItem(id: "pi\(index)", playlistItemID: "pi\(index)", track: track, playlistOrder: index)
    }
}
#endif
