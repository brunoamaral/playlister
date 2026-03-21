import Foundation

// MARK: - Extended Track Info

/// Full metadata for a track, fetched from the Plex /library/metadata/{ratingKey} endpoint.
/// Contains everything `Track` carries plus detailed media file information.
struct ExtendedTrackInfo: Identifiable {
    let track: Track

    // MARK: - Media container info
    let container: String?        // e.g. "mp3", "flac", "m4a"
    let bitrate: Int?             // overall container bitrate in kbps

    // MARK: - Audio stream info
    let audioCodec: String?       // e.g. "mp3", "flac", "aac", "alac"
    let channels: Int?            // 1 = mono, 2 = stereo, 6 = 5.1
    let sampleRate: Int?          // Hz, e.g. 44100
    let audioBitDepth: Int?       // bits per sample, e.g. 16, 24

    // MARK: - File info
    let filePath: String?         // absolute path on the Plex server
    let fileSize: Int?            // bytes

    // MARK: - Extended tags
    let genres: [String]
    let moods: [String]
    let styles: [String]
    let labels: [String]
    let studio: String?
    let contentRating: String?
    let artKey: String?           // full-res artwork key

    // MARK: - Identifiable

    var id: String { track.id }

    // MARK: - Formatted helpers

    var formattedBitrate: String? {
        guard let kbps = bitrate else { return nil }
        return "\(kbps) kbps"
    }

    var formattedFileSize: String? {
        guard let bytes = fileSize else { return nil }
        let mb = Double(bytes) / 1_048_576
        if mb >= 1000 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.1f MB", mb)
    }

    var channelDescription: String? {
        switch channels {
        case 1: return "Mono"
        case 2: return "Stereo"
        case 6: return "5.1 Surround"
        case 8: return "7.1 Surround"
        default:
            if let ch = channels { return "\(ch) channels" }
            return nil
        }
    }

    var formattedSampleRate: String? {
        guard let hz = sampleRate else { return nil }
        if hz % 1000 == 0 {
            return "\(hz / 1000) kHz"
        }
        return String(format: "%.1f kHz", Double(hz) / 1000)
    }
}

// MARK: - Plex API Response Mapping

extension ExtendedTrackInfo {
    init?(from dict: [String: Any], serverURL: String, token: String) {
        guard let track = Track(from: dict, serverURL: serverURL, token: token) else {
            return nil
        }
        self.track = track

        // Media container (first Media element)
        let mediaArray = dict["Media"] as? [[String: Any]]
        let firstMedia = mediaArray?.first

        container = firstMedia?["container"] as? String
        bitrate = firstMedia?["bitrate"] as? Int

        // Part (file-level info)
        let partArray = firstMedia?["Part"] as? [[String: Any]]
        let firstPart = partArray?.first
        filePath = firstPart?["file"] as? String
        fileSize = firstPart?["size"] as? Int

        // Audio stream inside the Part
        let streams = firstPart?["Stream"] as? [[String: Any]]
        let audioStream = streams?.first { ($0["streamType"] as? Int) == 2 }
        audioCodec       = audioStream?["codec"] as? String ?? firstMedia?["audioCodec"] as? String
        channels         = audioStream?["channels"] as? Int ?? firstMedia?["audioChannels"] as? Int
        sampleRate       = audioStream?["samplingRate"] as? Int
        audioBitDepth    = audioStream?["bitDepth"] as? Int

        // Tag arrays
        genres  = (dict["Genre"]  as? [[String: Any]])?.compactMap { $0["tag"] as? String } ?? []
        moods   = (dict["Mood"]   as? [[String: Any]])?.compactMap { $0["tag"] as? String } ?? []
        styles  = (dict["Style"]  as? [[String: Any]])?.compactMap { $0["tag"] as? String } ?? []
        labels  = (dict["Label"]  as? [[String: Any]])?.compactMap { $0["tag"] as? String } ?? []

        studio        = dict["studio"] as? String
        contentRating = dict["contentRating"] as? String
        artKey        = dict["art"] as? String ?? dict["thumb"] as? String
    }
}

// MARK: - Preview / Sample Data

#if DEBUG
extension ExtendedTrackInfo {
    static let sample = ExtendedTrackInfo(
        track: .sample,
        container: "flac",
        bitrate: 1411,
        audioCodec: "flac",
        channels: 2,
        sampleRate: 44100,
        audioBitDepth: 16,
        filePath: "/music/M83/Hurry Up, We're Dreaming/01 - Midnight City.flac",
        fileSize: 42_597_346,
        genres: ["Electronic", "Synth-pop"],
        moods: ["Euphoric", "Dreamy"],
        styles: ["Indie Electronic"],
        labels: ["Mute Records"],
        studio: nil,
        contentRating: nil,
        artKey: nil
    )
}
#endif
