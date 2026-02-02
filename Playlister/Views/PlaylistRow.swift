import SwiftUI

// MARK: - Playlist Row

/// Row component for displaying a playlist in the sidebar
struct PlaylistRow: View {
    
    // MARK: - Properties
    
    let playlist: Playlist
    @State private var isHovered = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 10) {
            // Playlist icon
            playlistIcon
            
            // Playlist info
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.title)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("\(playlist.leafCount) tracks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if playlist.smart {
                        Image(systemName: "wand.and.stars")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - Playlist Icon
    
    private var playlistIcon: some View {
        PlexImage(url: playlist.thumb) {
            iconPlaceholder
        }
        .frame(width: 32, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(playlist.smart ? Color.purple.opacity(0.2) : Color.accentColor.opacity(0.2))
            .overlay {
                Image(systemName: playlist.smart ? "wand.and.stars" : "music.note.list")
                    .font(.caption)
                    .foregroundStyle(playlist.smart ? .purple : .accentColor)
            }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    List {
        ForEach(Playlist.samplePlaylists) { playlist in
            PlaylistRow(playlist: playlist)
        }
    }
    .listStyle(.sidebar)
    .frame(width: 250, height: 400)
}
#endif
