import SwiftUI

// MARK: - Track Info View

/// Sheet showing full metadata for a track, fetched from /library/metadata/{ratingKey}
struct TrackInfoView: View {

    let track: Track

    @Environment(\.dismiss) private var dismiss

    @State private var info: ExtendedTrackInfo?
    @State private var isLoading = true
    @State private var loadError: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Track Info")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if isLoading {
                Spacer()
                ProgressView("Loading…")
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        artworkHeader
                        Divider()
                        infoSections
                    }
                    .padding()
                }
            }
        }
        .frame(width: 480)
        .frame(minHeight: 520)
        .task {
            await loadInfo()
        }
    }

    // MARK: - Artwork Header

    private var artworkHeader: some View {
        HStack(spacing: 16) {
            PlexImage(url: effectiveTrack.thumb) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.15))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: 80, height: 80)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(radius: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(effectiveTrack.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(effectiveTrack.artistName)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(effectiveTrack.albumName)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    // MARK: - Info Sections

    private var infoSections: some View {
        VStack(spacing: 16) {
            // Basic metadata
            InfoSection(title: "Track") {
                InfoRow(label: "Title",       value: effectiveTrack.title)
                InfoRow(label: "Artist",      value: effectiveTrack.artistName)
                InfoRow(label: "Album",       value: effectiveTrack.albumName.isEmpty ? nil : effectiveTrack.albumName)
                InfoRow(label: "Track #",     value: effectiveTrack.trackNumber.map { "\($0)" })
                InfoRow(label: "Year",        value: effectiveTrack.year.map { "\($0)" })
                InfoRow(label: "Duration",    value: effectiveTrack.formattedDuration)

                // Extended tag arrays
                if let info {
                    InfoRow(label: "Genre",   value: tagList(info.genres) ?? effectiveTrack.genre)
                    InfoRow(label: "Mood",    value: tagList(info.moods))
                    InfoRow(label: "Style",   value: tagList(info.styles))
                    InfoRow(label: "Label",   value: tagList(info.labels))
                    InfoRow(label: "Studio",  value: info.studio)
                } else {
                    InfoRow(label: "Genre",   value: effectiveTrack.genre)
                }
            }

            // Playback stats
            InfoSection(title: "Statistics") {
                InfoRow(label: "Play Count", value: effectiveTrack.playCount.map { "\($0)" })
                InfoRow(label: "Rating",     value: ratingString(effectiveTrack.rating))
                InfoRow(label: "Last Played",value: effectiveTrack.lastViewedAt.map { $0.relativeFormatted })
                InfoRow(label: "Added",      value: effectiveTrack.addedAt.map { $0.shortFormatted })
            }

            // File / media info (only when loaded)
            if let info {
                InfoSection(title: "File") {
                    InfoRow(label: "Format",      value: info.container?.uppercased())
                    InfoRow(label: "Codec",       value: info.audioCodec?.uppercased())
                    InfoRow(label: "Bitrate",     value: info.formattedBitrate)
                    InfoRow(label: "Sample Rate", value: info.formattedSampleRate)
                    InfoRow(label: "Bit Depth",   value: info.audioBitDepth.map { "\($0)-bit" })
                    InfoRow(label: "Channels",    value: info.channelDescription)
                    InfoRow(label: "File Size",   value: info.formattedFileSize)
                    InfoRow(label: "Location",    value: info.filePath, selectable: true)
                }
            }

            if let loadError {
                Text("Could not load extended info: \(loadError)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Helpers

    /// Falls back to the base Track when extended info isn't loaded yet
    private var effectiveTrack: Track {
        info?.track ?? track
    }

    private func tagList(_ tags: [String]) -> String? {
        tags.isEmpty ? nil : tags.joined(separator: ", ")
    }

    private func ratingString(_ rating: Double?) -> String? {
        guard let r = rating else { return nil }
        let stars = Int(r / 2)   // Plex stores 0–10; map to 0–5 stars
        return String(repeating: "★", count: min(stars, 5)) + String(repeating: "☆", count: max(0, 5 - stars))
    }

    // MARK: - Data Loading

    private func loadInfo() async {
        isLoading = true
        loadError = nil
        do {
            info = try await PlexAPIService.shared.fetchTrackMetadata(ratingKey: track.ratingKey)
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Sub-views

private struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.bottom, 2)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct InfoRow: View {
    let label: String
    let value: String?
    var selectable: Bool = false

    var body: some View {
        if let value {
            HStack(alignment: .top, spacing: 8) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 96, alignment: .trailing)
                if selectable {
                    Text(value)
                        .font(.subheadline)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(value)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    TrackInfoView(track: .sample)
        .task {
            // Preview falls back to the basic info displayed from Track.sample
        }
}
#endif
