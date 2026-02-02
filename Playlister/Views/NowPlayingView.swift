import SwiftUI

// MARK: - Now Playing View

/// Mini player bar showing current track with playback controls
struct NowPlayingView: View {
    
    // MARK: - Properties
    
    @StateObject private var audioService = AudioPreviewService.shared
    @State private var isHovered = false
    
    // MARK: - Body
    
    var body: some View {
        if let track = audioService.currentTrack {
            HStack(spacing: 16) {
                // Track artwork
                artwork(for: track)
                
                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(track.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(minWidth: 150, alignment: .leading)
                
                Spacer()
                
                // Progress bar (compact)
                progressBar
                
                // Playback controls
                playbackControls
                
                // Volume control
                volumeControl
                
                // Close button
                Button {
                    audioService.stop()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .opacity(isHovered ? 1 : 0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            }
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }
    
    // MARK: - Artwork
    
    private func artwork(for track: Track) -> some View {
        ZStack {
            if let thumbURL = track.thumb, let url = URL(string: thumbURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    artworkPlaceholder
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(width: 48, height: 48)
        .cornerRadius(6)
    }
    
    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.accentColor.opacity(0.2))
            .overlay {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
            }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(
                            width: audioService.duration > 0
                                ? geometry.size.width * (audioService.currentTime / audioService.duration)
                                : 0,
                            height: 4
                        )
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let percentage = value.location.x / geometry.size.width
                            let time = audioService.duration * max(0, min(1, percentage))
                            audioService.seek(to: time)
                        }
                )
            }
            .frame(height: 4)
            
            // Time labels
            HStack {
                Text(AudioPreviewService.formatTime(audioService.currentTime))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                
                Spacer()
                
                Text(AudioPreviewService.formatTime(audioService.duration))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .frame(width: 200)
    }
    
    // MARK: - Playback Controls
    
    private var playbackControls: some View {
        HStack(spacing: 8) {
            // Skip backward
            Button {
                audioService.skipBackward()
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .help("Skip back 10 seconds")
            
            // Play/Pause
            Button {
                audioService.togglePlayPause()
            } label: {
                Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.space, modifiers: [])
            .help(audioService.isPlaying ? "Pause" : "Play")
            
            // Skip forward
            Button {
                audioService.skipForward()
            } label: {
                Image(systemName: "goforward.10")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .help("Skip forward 10 seconds")
        }
    }
    
    // MARK: - Volume Control
    
    private var volumeControl: some View {
        HStack(spacing: 4) {
            Image(systemName: volumeIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            
            Slider(value: $audioService.volume, in: 0...1)
                .frame(width: 80)
        }
        .opacity(isHovered ? 1 : 0.7)
    }
    
    private var volumeIcon: String {
        if audioService.volume == 0 {
            return "speaker.slash.fill"
        } else if audioService.volume < 0.3 {
            return "speaker.fill"
        } else if audioService.volume < 0.7 {
            return "speaker.wave.1.fill"
        } else {
            return "speaker.wave.2.fill"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack {
        Spacer()
        NowPlayingView()
            .padding()
    }
    .frame(width: 800, height: 200)
    .onAppear {
        AudioPreviewService.shared.play(Track.sample)
    }
}
#endif
