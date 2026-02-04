import SwiftUI

// MARK: - Search Column (Column 3)

/// Search interface for finding and adding tracks to playlists
struct SearchColumn: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: SearchViewModel
    @ObservedObject var playlistViewModel: PlaylistViewModel
    @StateObject private var audioService = AudioPreviewService.shared
    @FocusState private var isTitleFocused: Bool
    
    /// Search results filtered to exclude tracks already in the current playlist
    private var filteredSearchResults: [Track] {
        // Get the IDs of tracks already in the playlist
        let playlistTrackIds = Set(playlistViewModel.currentTracks.map { $0.track.id })
        
        // Filter out tracks that are already in the playlist
        return viewModel.searchResults.filter { !playlistTrackIds.contains($0.id) }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // New playlist creation header
            if playlistViewModel.isCreatingNewPlaylist {
                newPlaylistHeader
                Divider()
            }
            
            // Selection toolbar (when not creating new playlist)
            if !viewModel.selectedTracks.isEmpty && !playlistViewModel.isCreatingNewPlaylist {
                selectionToolbar
                Divider()
            }
            
            // Content
            if viewModel.searchQuery.isEmpty {
                emptySearchState
            } else if viewModel.isSearching {
                searchingState
            } else if filteredSearchResults.isEmpty {
                noResultsState
            } else {
                searchResultsList
            }
        }
        .frame(minWidth: 300)
        .navigationTitle(playlistViewModel.isCreatingNewPlaylist ? "New Playlist" : "Search")
    }
    
    // MARK: - New Playlist Header
    
    private var newPlaylistHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("New Playlist")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    playlistViewModel.cancelCreatingPlaylist()
                }
                .buttonStyle(.borderless)
            }
            
            TextField("Playlist Title", text: $playlistViewModel.newPlaylistName)
                .textFieldStyle(.roundedBorder)
                .focused($isTitleFocused)
            
            TextField("Description (optional)", text: $playlistViewModel.newPlaylistDescription)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(.secondary)
            
            // Pending tracks
            if !playlistViewModel.pendingTracks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tracks to add (\\(playlistViewModel.pendingTracks.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(playlistViewModel.pendingTracks) { track in
                                pendingTrackChip(track)
                            }
                        }
                    }
                }
            }
            
            // Create button
            HStack {
                Spacer()
                Button {
                    Task {
                        await playlistViewModel.createPlaylistWithPendingTracks()
                    }
                } label: {
                    Label("Create Playlist", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(playlistViewModel.newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty || playlistViewModel.pendingTracks.isEmpty)
            }
            
            if playlistViewModel.pendingTracks.isEmpty {
                Text("Search and add at least one track below")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .onAppear {
            isTitleFocused = true
        }
    }
    
    private func pendingTrackChip(_ track: Track) -> some View {
        HStack(spacing: 4) {
            Text(track.title)
                .font(.caption)
                .lineLimit(1)
            
            Button {
                playlistViewModel.removeFromPendingPlaylist(track)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Selection Toolbar
    
    private var selectionToolbar: some View {
        HStack {
            Text("\(viewModel.selectedTracks.count) selected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Clear") {
                viewModel.clearSelection()
            }
            .buttonStyle(.borderless)
            
            Button {
                addSelectedToPlaylist()
            } label: {
                Label("Add to Playlist", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(playlistViewModel.selectedPlaylist == nil)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
    
    // MARK: - Search Results
    
    private var searchResultsList: some View {
        List(filteredSearchResults, selection: Binding(
            get: { viewModel.selectedTracks },
            set: { viewModel.selectedTracks = $0 }
        )) { track in
            TrackRow(
                track: track,
                isPlaying: audioService.currentTrack?.id == track.id && audioService.isPlaying,
                isSelected: viewModel.isSelected(track),
                showsPlayButton: true,
                showsAddButton: playlistViewModel.selectedPlaylist != nil || playlistViewModel.isCreatingNewPlaylist,
                isPendingAdd: playlistViewModel.pendingTracks.contains(where: { $0.id == track.id }),
                onAdd: {
                    if playlistViewModel.isCreatingNewPlaylist {
                        playlistViewModel.addToPendingPlaylist(track)
                    } else {
                        addTrackToPlaylist(track)
                    }
                }
            )
            .tag(track)
            .contextMenu {
                trackContextMenu(for: track)
            }
        }
        .listStyle(.inset)
    }
    
    // MARK: - Empty States
    
    private var emptySearchState: some View {
        VStack(spacing: 20) {
            ContentUnavailableView {
                Label("Search for Tracks", systemImage: "magnifyingglass")
            } description: {
                Text("Use the search bar above to find tracks in your library.")
            }
            
            // Recent searches
            if !viewModel.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Searches")
                            .font(.headline)
                        Spacer()
                        Button("Clear") {
                            viewModel.clearRecentSearches()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    
                    ForEach(viewModel.recentSearches, id: \.self) { search in
                        Button {
                            viewModel.searchQuery = search
                            viewModel.search()
                        } label: {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)
                                Text(search)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(maxWidth: 300)
            }
        }
    }
    
    private var searchingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Searching...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var noResultsState: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "magnifyingglass")
        } description: {
            if viewModel.searchResults.isEmpty {
                Text("No tracks found for \"\(viewModel.searchQuery)\"")
            } else {
                Text("All matching tracks are already in the playlist")
            }
        } actions: {
            Button("Clear Search") {
                viewModel.clearSearch()
            }
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func trackContextMenu(for track: Track) -> some View {
        Button {
            audioService.play(track)
        } label: {
            Label("Play", systemImage: "play")
        }
        
        if playlistViewModel.selectedPlaylist != nil {
            Button {
                addTrackToPlaylist(track)
            } label: {
                Label("Add to Playlist", systemImage: "plus")
            }
        }
        
        Divider()
        
        if viewModel.isSelected(track) {
            Button {
                viewModel.toggleSelection(track)
            } label: {
                Label("Deselect", systemImage: "checkmark.circle")
            }
        } else {
            Button {
                viewModel.toggleSelection(track)
            } label: {
                Label("Select", systemImage: "circle")
            }
        }
        
        Button {
            viewModel.selectAll()
        } label: {
            Label("Select All", systemImage: "checkmark.circle.fill")
        }
    }
    
    // MARK: - Actions
    
    private func addTrackToPlaylist(_ track: Track) {
        Task {
            await playlistViewModel.addTracks([track])
        }
    }
    
    private func addSelectedToPlaylist() {
        let tracks = Array(viewModel.selectedTracks)
        Task {
            await playlistViewModel.addTracks(tracks)
            viewModel.clearSelection()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SearchColumn(
        viewModel: SearchViewModel(),
        playlistViewModel: PlaylistViewModel()
    )
    .frame(width: 400, height: 600)
}
#endif
