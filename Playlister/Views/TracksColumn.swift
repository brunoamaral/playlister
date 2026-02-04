import SwiftUI

// MARK: - Tracks Column (Column 2)

/// Shows tracks in the selected playlist with reordering support
struct TracksColumn: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PlaylistViewModel
    @StateObject private var audioService = AudioPreviewService.shared
    
    // Editing state
    @State private var isEditingTitle = false
    @State private var isEditingDescription = false
    @State private var editedTitle = ""
    @State private var editedDescription = ""
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let playlist = viewModel.selectedPlaylist {
                trackList(for: playlist)
            } else if viewModel.isCreatingNewPlaylist {
                newPlaylistPlaceholder
            } else {
                noPlaylistSelected
            }
        }
        .frame(minWidth: 300)
    }
    
    // MARK: - Track List
    
    @ViewBuilder
    private func trackList(for playlist: Playlist) -> some View {
        VStack(spacing: 0) {
            // Header with editable fields
            playlistHeader(playlist)
            
            Divider()
            
            // Selection toolbar (shown when in selection mode)
            if viewModel.isSelectionModeActive {
                selectionToolbar
                Divider()
            }
            
            // Tracks
            if viewModel.isLoadingTracks {
                Spacer()
                ProgressView("Loading tracks...")
                Spacer()
            } else if viewModel.currentTracks.isEmpty {
                emptyPlaylist
            } else {
                List(selection: $viewModel.selectedTrackIds) {
                    ForEach(viewModel.currentTracks) { item in
                        TrackRow(
                            track: item.track,
                            isPlaying: audioService.currentTrack?.id == item.track.id && audioService.isPlaying,
                            isSelected: viewModel.isTrackSelected(item),
                            showsPlayButton: true,
                            showsRemoveButton: !viewModel.isSelectionModeActive,
                            isSelectionMode: viewModel.isSelectionModeActive,
                            onRemove: {
                                Task {
                                    await viewModel.removeTrack(item)
                                }
                            }
                        )
                        .tag(item.id)
                        .contextMenu {
                            trackContextMenu(for: item)
                        }
                    }
                    .onMove { source, destination in
                        Task {
                            // If we have multiple selections and we're moving one of them
                            if viewModel.selectedTrackIds.count > 1,
                               let sourceIndex = source.first,
                               viewModel.selectedTrackIds.contains(viewModel.currentTracks[sourceIndex].id) {
                                await viewModel.moveSelectedTracksViaDrag(to: destination)
                            } else {
                                await viewModel.moveTrack(from: source, to: destination)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        deleteTrack(at: indexSet)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle(playlist.title)
    }
    
    // MARK: - Selection Toolbar
    
    private var selectionToolbar: some View {
        HStack(spacing: 16) {
            // Selection count with hint
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.selectedTrackIds.count) selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if viewModel.selectedTrackIds.count > 0 {
                    Text("Use the drag handles to reorder")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Select All / Deselect All
            Button {
                if viewModel.selectedTrackIds.count == viewModel.currentTracks.count {
                    viewModel.clearSelection()
                } else {
                    viewModel.selectAllTracks()
                }
            } label: {
                Text(viewModel.selectedTrackIds.count == viewModel.currentTracks.count ? "Deselect All" : "Select All")
                    .font(.subheadline)
            }
            .buttonStyle(.borderless)
            
            // Remove button
            Button(role: .destructive) {
                Task { await viewModel.removeSelectedTracks() }
            } label: {
                Label("Remove", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.selectedTrackIds.isEmpty)
            
            // Cancel selection mode
            Button {
                viewModel.clearSelection()
            } label: {
                Text("Done")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
    }
    
    // MARK: - Playlist Header
    
    private func playlistHeader(_ playlist: Playlist) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Playlist artwork
            playlistArtwork(playlist)
            
            // Playlist info (editable)
            VStack(alignment: .leading, spacing: 8) {
                // Title (editable)
                if isEditingTitle {
                    TextField("Playlist Title", text: $editedTitle)
                        .textFieldStyle(.plain)
                        .font(.headline)
                        .focused($isTitleFocused)
                        .onSubmit {
                            saveTitle()
                        }
                        .onExitCommand {
                            cancelEditingTitle()
                        }
                } else {
                    Text(playlist.title)
                        .font(.headline)
                        .onTapGesture(count: 2) {
                            startEditingTitle(playlist)
                        }
                }
                
                // Description (editable)
                if isEditingDescription {
                    TextField("Add a description...", text: $editedDescription, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2...4)
                        .focused($isDescriptionFocused)
                        .onSubmit {
                            saveDescription()
                        }
                        .onExitCommand {
                            cancelEditingDescription()
                        }
                } else {
                    if let summary = playlist.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .onTapGesture(count: 2) {
                                startEditingDescription(playlist)
                            }
                    } else {
                        Text("Double-click to add description")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .italic()
                            .onTapGesture(count: 2) {
                                startEditingDescription(playlist)
                            }
                    }
                }
                
                // Stats
                HStack(spacing: 8) {
                    Text("\(viewModel.currentTracks.count) tracks")
                    
                    if let duration = totalDuration {
                        Text("•")
                        Text(duration)
                    }
                    
                    if playlist.smart {
                        Text("•")
                        Label("Smart", systemImage: "wand.and.stars")
                            .font(.caption)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            if !viewModel.currentTracks.isEmpty {
                HStack(spacing: 8) {
                    // Select button (for multi-select mode)
                    if !playlist.smart && !viewModel.isSelectionModeActive {
                        Button {
                            viewModel.toggleSelectionMode()
                        } label: {
                            Label("Select", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Play all button
                    Button {
                        if let firstTrack = viewModel.currentTracks.first {
                            audioService.play(firstTrack.track)
                        }
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Playlist Artwork
    
    private func playlistArtwork(_ playlist: Playlist) -> some View {
        PlexImage(url: playlist.thumb) {
            artworkPlaceholder(playlist)
        }
        .aspectRatio(contentMode: .fill)
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
    }
    
    private func artworkPlaceholder(_ playlist: Playlist) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(playlist.smart ? Color.purple.opacity(0.2) : Color.accentColor.opacity(0.2))
            .overlay {
                Image(systemName: playlist.smart ? "wand.and.stars" : "music.note.list")
                    .font(.title)
                    .foregroundStyle(playlist.smart ? .purple : .accentColor)
            }
    }
    
    // MARK: - Empty State
    
    private var emptyPlaylist: some View {
        ContentUnavailableView {
            Label("Empty Playlist", systemImage: "music.note")
        } description: {
            Text("Search for tracks on the right and add them to this playlist.")
        }
    }
    
    private var noPlaylistSelected: some View {
        ContentUnavailableView {
            Label("No Playlist Selected", systemImage: "music.note.list")
        } description: {
            Text("Select a playlist from the sidebar to view its tracks.")
        }
    }
    
    private var newPlaylistPlaceholder: some View {
        ContentUnavailableView {
            Label("Creating New Playlist", systemImage: "plus.circle")
        } description: {
            Text("Enter a name and add tracks in the search panel to the right.")
        }
    }
    
    // MARK: - Editing Helpers
    
    private func startEditingTitle(_ playlist: Playlist) {
        guard !playlist.smart else { return } // Can't edit smart playlists
        editedTitle = playlist.title
        isEditingTitle = true
        isTitleFocused = true
    }
    
    private func saveTitle() {
        guard !editedTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            cancelEditingTitle()
            return
        }
        
        Task {
            await viewModel.updatePlaylist(title: editedTitle)
        }
        isEditingTitle = false
    }
    
    private func cancelEditingTitle() {
        isEditingTitle = false
        editedTitle = ""
    }
    
    private func startEditingDescription(_ playlist: Playlist) {
        guard !playlist.smart else { return } // Can't edit smart playlists
        editedDescription = playlist.summary ?? ""
        isEditingDescription = true
        isDescriptionFocused = true
    }
    
    private func saveDescription() {
        Task {
            await viewModel.updatePlaylist(summary: editedDescription)
        }
        isEditingDescription = false
    }
    
    private func cancelEditingDescription() {
        isEditingDescription = false
        editedDescription = ""
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func trackContextMenu(for item: PlaylistItem) -> some View {
        Button {
            audioService.play(item.track)
        } label: {
            Label("Play", systemImage: "play")
        }
        
        Divider()
        
        // Selection options
        if viewModel.isSelectionModeActive {
            if viewModel.isTrackSelected(item) {
                Button {
                    viewModel.deselectTrack(item)
                } label: {
                    Label("Deselect", systemImage: "circle")
                }
            } else {
                Button {
                    viewModel.selectTrack(item)
                } label: {
                    Label("Select", systemImage: "checkmark.circle")
                }
            }
            
            Divider()
        } else {
            // Quick select option when not in selection mode
            Button {
                viewModel.toggleSelectionMode()
                viewModel.selectTrack(item)
            } label: {
                Label("Select to Reorder", systemImage: "checkmark.circle")
            }
            
            Divider()
        }
        
        Button(role: .destructive) {
            Task { await viewModel.removeTrack(item) }
        } label: {
            Label("Remove from Playlist", systemImage: "minus.circle")
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalDuration: String? {
        let totalMs = viewModel.currentTracks.reduce(0) { $0 + $1.track.duration }
        guard totalMs > 0 else { return nil }
        
        let totalSeconds = totalMs / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    // MARK: - Actions
    
    private func deleteTrack(at indexSet: IndexSet) {
        for index in indexSet {
            let item = viewModel.currentTracks[index]
            Task { await viewModel.removeTrack(item) }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    TracksColumn(viewModel: {
        let vm = PlaylistViewModel()
        return vm
    }())
    .frame(width: 400, height: 600)
}
#endif
