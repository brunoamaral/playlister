import SwiftUI

// MARK: - Track Row

/// Reusable row component for displaying a track
struct TrackRow: View {
    
    // MARK: - Properties
    
    let track: Track
    var isPlaying: Bool = false
    var isSelected: Bool = false
    var showsPlayButton: Bool = true
    var showsAddButton: Bool = false
    var showsRemoveButton: Bool = false
    var isPendingAdd: Bool = false
    var isSelectionMode: Bool = false
    var onAdd: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil
    var onSelectionToggle: (() -> Void)? = nil
    
    @StateObject private var audioService = AudioPreviewService.shared
    @State private var isHovered = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox (shown in selection mode)
            if isSelectionMode {
                Button {
                    onSelectionToggle?()
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Artwork
            artwork
            
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(track.title)
                        .font(.body)
                        .fontWeight(isPlaying ? .semibold : .regular)
                        .lineLimit(1)
                    
                    if isPendingAdd {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
                
                Text(track.artistAndAlbum)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration
            Text(track.formattedDuration)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            
        // Action buttons (add/remove buttons always visible when enabled, play on hover)
            if showsAddButton || showsRemoveButton || isHovered || isPlaying || isPendingAdd {
                actionButtons
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    // MARK: - Background Color
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if isPendingAdd {
            return Color.green.opacity(0.1)
        }
        return Color.clear
    }
    
    // MARK: - Artwork
    
    private var artwork: some View {
        ZStack {
            PlexImage(url: track.thumb) {
                artworkPlaceholder
            }
            
            // Play overlay
            if isPlaying {
                Color.black.opacity(0.4)
                Image(systemName: "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.secondary.opacity(0.2))
            .overlay {
                Image(systemName: "music.note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 4) {
            if showsPlayButton && (isHovered || isPlaying) {
                Button {
                    if isPlaying {
                        audioService.togglePlayPause()
                    } else {
                        audioService.play(track)
                    }
                } label: {
                    Image(systemName: isPlaying && audioService.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .help(isPlaying ? "Pause" : "Play")
            }
            
            // Add button - always visible when showsAddButton is true
            if showsAddButton, let onAdd = onAdd {
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .help("Add to playlist")
            }
            
            // Remove button - always visible when showsRemoveButton is true
            if showsRemoveButton, let onRemove = onRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .help("Remove from playlist")
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    List {
        TrackRow(track: .sample)
        TrackRow(track: .sample, isPlaying: true)
        TrackRow(track: .sample, isSelected: true, isSelectionMode: true)
        TrackRow(track: .sample, showsAddButton: true, onAdd: {
            print("Add tapped")
        })
    }
    .frame(width: 400, height: 300)
}
#endif
