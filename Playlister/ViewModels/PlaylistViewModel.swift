import Foundation
import Combine

// MARK: - Playlist View Model

/// Manages playlist data and operations
@MainActor
final class PlaylistViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var playlists: [Playlist] = []
    @Published private(set) var currentTracks: [PlaylistItem] = []
    @Published var selectedPlaylist: Playlist? {
        didSet {
            if let playlist = selectedPlaylist {
                // Cancel creation mode when selecting a playlist
                if isCreatingNewPlaylist {
                    isCreatingNewPlaylist = false
                    newPlaylistName = ""
                    newPlaylistDescription = ""
                    pendingTracks = []
                }
                // Clear selection when changing playlists
                clearSelection()
                Task { await fetchTracks(for: playlist) }
            } else {
                currentTracks = []
                clearSelection()
            }
        }
    }
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isLoadingTracks: Bool = false
    @Published private(set) var error: Error?
    @Published var showErrorAlert: Bool = false
    
    // Multi-selection for track reordering
    @Published var selectedTrackIds: Set<String> = []
    @Published var isSelectionModeActive: Bool = false
    
    // For new playlist creation
    @Published var isCreatingNewPlaylist: Bool = false
    @Published var newPlaylistName: String = ""
    @Published var newPlaylistDescription: String = ""
    @Published var pendingTracks: [Track] = []
    @Published var isShowingNewPlaylistSheet: Bool = false  // Keep for legacy, redirects to isCreatingNewPlaylist
    
    // For undo support
    private var undoStack: [(action: PlaylistAction, data: Any)] = []
    
    // MARK: - Private Properties
    
    private let plexService: PlexAPIService
    private var libraryKey: String?
    
    // MARK: - Initialization
    
    init(plexService: PlexAPIService = .shared) {
        self.plexService = plexService
    }
    
    // MARK: - Configuration
    
    func configure(libraryKey: String?) {
        self.libraryKey = libraryKey
    }
    
    // MARK: - Fetch Playlists
    
    /// Fetch all playlists from the server
    func fetchPlaylists() async {
        isLoading = true
        error = nil
        
        do {
            playlists = try await plexService.fetchPlaylists()
            
            // Re-select current playlist if still exists
            if let current = selectedPlaylist {
                selectedPlaylist = playlists.first { $0.id == current.id }
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Tracks
    
    /// Fetch tracks for a specific playlist
    func fetchTracks(for playlist: Playlist) async {
        isLoadingTracks = true
        
        do {
            currentTracks = try await plexService.fetchPlaylistTracks(playlistId: playlist.id)
        } catch {
            self.error = error
            currentTracks = []
        }
        
        isLoadingTracks = false
    }
    
    // MARK: - Playlist CRUD
    
    /// Start creating a new playlist
    func startCreatingPlaylist() {
        isCreatingNewPlaylist = true
        newPlaylistName = ""
        newPlaylistDescription = ""
        pendingTracks = []
        selectedPlaylist = nil
    }
    
    /// Cancel creating a new playlist
    func cancelCreatingPlaylist() {
        isCreatingNewPlaylist = false
        newPlaylistName = ""
        newPlaylistDescription = ""
        pendingTracks = []
    }
    
    /// Add a track to the pending new playlist
    func addToPendingPlaylist(_ track: Track) {
        if !pendingTracks.contains(where: { $0.id == track.id }) {
            pendingTracks.append(track)
        }
    }
    
    /// Remove a track from the pending new playlist
    func removeFromPendingPlaylist(_ track: Track) {
        pendingTracks.removeAll { $0.id == track.id }
    }
    
    /// Create the playlist with pending tracks
    func createPlaylistWithPendingTracks() async {
        guard !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = PlexAPIError.invalidResponse
            showErrorAlert = true
            return
        }
        
        guard !pendingTracks.isEmpty else {
            error = PlexAPIError.playlistRequiresTrack
            showErrorAlert = true
            return
        }
        
        guard let libraryKey = libraryKey else {
            error = PlexAPIError.notConnected
            showErrorAlert = true
            return
        }
        
        do {
            // Build URIs for all pending tracks
            var uris: [String] = []
            for track in pendingTracks {
                let uri = await plexService.trackURI(for: track, libraryKey: libraryKey)
                uris.append(uri)
            }
            
            let playlist = try await plexService.createPlaylist(title: newPlaylistName, trackURIs: uris)
            playlists.insert(playlist, at: 0)
            selectedPlaylist = playlist
            
            // Reset creation mode
            isCreatingNewPlaylist = false
            newPlaylistName = ""
            newPlaylistDescription = ""
            pendingTracks = []
            
            // Fetch the tracks to show in the middle column
            await fetchTracks(for: playlist)
        } catch {
            self.error = error
            self.showErrorAlert = true
            print("Failed to create playlist: \(error)")
        }
    }
    
    /// Create a new playlist (legacy method - now starts creation mode)
    func createPlaylist(name: String) async {
        // Redirect to new flow
        newPlaylistName = name
        startCreatingPlaylist()
    }
    
    /// Create a new playlist with the given tracks (for import functionality)
    func createPlaylist(name: String, tracks: [Track]) async throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PlexAPIError.invalidResponse
        }
        
        guard !tracks.isEmpty else {
            throw PlexAPIError.playlistRequiresTrack
        }
        
        guard let libraryKey = libraryKey else {
            throw PlexAPIError.notConnected
        }
        
        // Build URIs for all tracks
        var uris: [String] = []
        for track in tracks {
            let uri = await plexService.trackURI(for: track, libraryKey: libraryKey)
            uris.append(uri)
        }
        
        let playlist = try await plexService.createPlaylist(title: name, trackURIs: uris)
        playlists.insert(playlist, at: 0)
        selectedPlaylist = playlist
        
        // Fetch the tracks to show in the middle column
        await fetchTracks(for: playlist)
    }
    
    /// Update a playlist's title and/or summary
    func updatePlaylist(title: String? = nil, summary: String? = nil) async {
        guard let playlist = selectedPlaylist else { return }
        
        do {
            let updated = try await plexService.updatePlaylist(
                playlistId: playlist.id,
                title: title,
                summary: summary
            )
            
            // Update in list
            if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
                playlists[index] = updated
            }
            selectedPlaylist = updated
        } catch {
            self.error = error
            self.showErrorAlert = true
            print("Failed to update playlist: \(error)")
        }
    }
    
    /// Delete a playlist
    func deletePlaylist(_ playlist: Playlist) async {
        // Store for undo
        let tracks = currentTracks
        undoStack.append((.deletePlaylist, (playlist, tracks)))
        
        do {
            try await plexService.deletePlaylist(playlistId: playlist.id)
            playlists.removeAll { $0.id == playlist.id }
            
            if selectedPlaylist?.id == playlist.id {
                selectedPlaylist = nil
            }
        } catch {
            self.error = error
            // Remove from undo stack on failure
            undoStack.removeLast()
        }
    }
    
    // MARK: - Smart Playlist Operations
    
    /// Create a new smart playlist with filter rules
    func createSmartPlaylist(title: String, filter: String, limit: Int?, sort: SortOption) async throws {
        // Get the music library key (section ID) if not already set
        let sectionId: String
        if let key = libraryKey {
            sectionId = key
        } else if let key = try await plexService.getMusicLibraryKey() {
            sectionId = key
            libraryKey = key
        } else {
            throw PlexAPIError.notConnected
        }
        
        let playlist = try await plexService.createSmartPlaylist(
            title: title,
            sectionId: sectionId,
            filter: filter,
            limit: limit,
            sort: sort.plexSort
        )
        
        playlists.insert(playlist, at: 0)
        selectedPlaylist = playlist
    }
    
    /// Update an existing smart playlist
    func updateSmartPlaylist(playlistId: String, title: String, filter: String, limit: Int?, sort: SortOption) async throws {
        // Get the music library key (section ID) if not already set
        let sectionId: String
        if let key = libraryKey {
            sectionId = key
        } else if let key = try await plexService.getMusicLibraryKey() {
            sectionId = key
            libraryKey = key
        } else {
            throw PlexAPIError.notConnected
        }
        
        let updated = try await plexService.updateSmartPlaylist(
            playlistId: playlistId,
            sectionId: sectionId,
            title: title,
            filter: filter,
            limit: limit,
            sort: sort.plexSort
        )
        
        // Update in list
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index] = updated
        }
        selectedPlaylist = updated
    }
    
    // MARK: - Track Operations
    
    /// Add tracks to the current playlist
    func addTracks(_ tracks: [Track]) async {
        guard let playlist = selectedPlaylist,
              let libraryKey = libraryKey else { return }
        
        var uris: [String] = []
        for track in tracks {
            let uri = await plexService.trackURI(for: track, libraryKey: libraryKey)
            uris.append(uri)
        }
        
        do {
            try await plexService.addToPlaylist(playlistId: playlist.id, trackURIs: uris)
            await fetchTracks(for: playlist)
            
            // Store for undo
            undoStack.append((.addTracks, (playlist.id, tracks)))
        } catch {
            self.error = error
        }
    }
    
    /// Remove a track from the current playlist
    func removeTrack(_ item: PlaylistItem) async {
        guard let playlist = selectedPlaylist else { return }
        
        // Store for undo
        let index = currentTracks.firstIndex(of: item) ?? 0
        undoStack.append((.removeTrack, (playlist.id, item, index)))
        
        do {
            try await plexService.removeFromPlaylist(
                playlistId: playlist.id,
                playlistItemId: item.playlistItemID
            )
            currentTracks.removeAll { $0.id == item.id }
        } catch {
            self.error = error
            undoStack.removeLast()
        }
    }
    
    /// Move a track within the playlist (reorder)
    func moveTrack(from source: IndexSet, to destination: Int) async {
        guard let playlist = selectedPlaylist,
              let sourceIndex = source.first else { return }
        
        let item = currentTracks[sourceIndex]
        
        // Calculate the "after" item ID
        let afterItemId: String?
        if destination == 0 {
            afterItemId = nil // Move to beginning
        } else {
            let afterIndex = destination > sourceIndex ? destination - 1 : destination - 1
            afterItemId = currentTracks[safe: afterIndex]?.playlistItemID
        }
        
        // Optimistic update
        var newTracks = currentTracks
        newTracks.remove(at: sourceIndex)
        let insertIndex = destination > sourceIndex ? destination - 1 : destination
        newTracks.insert(item, at: insertIndex)
        currentTracks = newTracks
        
        // Store for undo
        undoStack.append((.moveTrack, (playlist.id, sourceIndex, destination)))
        
        do {
            try await plexService.movePlaylistItem(
                playlistId: playlist.id,
                playlistItemId: item.playlistItemID,
                afterItemId: afterItemId
            )
        } catch {
            // Revert on failure
            self.error = error
            await fetchTracks(for: playlist)
            undoStack.removeLast()
        }
    }
    
    // MARK: - Multi-Selection Operations
    
    /// Toggle selection mode
    func toggleSelectionMode() {
        isSelectionModeActive.toggle()
        if !isSelectionModeActive {
            clearSelection()
        }
    }
    
    /// Toggle selection for a track
    func toggleTrackSelection(_ item: PlaylistItem) {
        if selectedTrackIds.contains(item.id) {
            selectedTrackIds.remove(item.id)
        } else {
            selectedTrackIds.insert(item.id)
        }
    }
    
    /// Select a track
    func selectTrack(_ item: PlaylistItem) {
        selectedTrackIds.insert(item.id)
    }
    
    /// Deselect a track
    func deselectTrack(_ item: PlaylistItem) {
        selectedTrackIds.remove(item.id)
    }
    
    /// Clear all selections
    func clearSelection() {
        selectedTrackIds.removeAll()
        isSelectionModeActive = false
    }
    
    /// Select all tracks
    func selectAllTracks() {
        selectedTrackIds = Set(currentTracks.map { $0.id })
    }
    
    /// Check if a track is selected
    func isTrackSelected(_ item: PlaylistItem) -> Bool {
        selectedTrackIds.contains(item.id)
    }
    
    /// Get the selected tracks in their current order
    var selectedTracks: [PlaylistItem] {
        currentTracks.filter { selectedTrackIds.contains($0.id) }
    }
    
    /// Move selected tracks via drag to a destination index (used by List onMove)
    /// - Parameter destination: The destination index from the List's onMove
    func moveSelectedTracksViaDrag(to destination: Int) async {
        guard let playlist = selectedPlaylist else { return }
        guard !selectedTrackIds.isEmpty else { return }
        
        // Get selected items in their current order
        let itemsToMove = selectedTracks
        guard !itemsToMove.isEmpty else { return }
        
        // Find the indices of selected items
        let selectedIndices = currentTracks.enumerated()
            .filter { selectedTrackIds.contains($0.element.id) }
            .map { $0.offset }
        
        guard let firstSelectedIndex = selectedIndices.first else { return }
        
        // Calculate the actual destination considering the selection
        // When dragging down, the destination needs adjustment
        var adjustedDestination = destination
        if destination > firstSelectedIndex {
            // Count how many selected items are before the destination
            let selectedBeforeDestination = selectedIndices.filter { $0 < destination }.count
            adjustedDestination = destination - selectedBeforeDestination
        }
        
        // Calculate the "after" item ID
        let afterItemId: String?
        if adjustedDestination == 0 {
            afterItemId = nil // Move to beginning
        } else {
            // Find items that are NOT selected
            let nonSelectedItems = currentTracks.filter { !selectedTrackIds.contains($0.id) }
            let targetIndex = min(adjustedDestination - 1, nonSelectedItems.count - 1)
            if targetIndex >= 0 && targetIndex < nonSelectedItems.count {
                afterItemId = nonSelectedItems[targetIndex].playlistItemID
            } else {
                afterItemId = nil
            }
        }
        
        // Store original tracks for undo/revert
        let originalTracks = currentTracks
        
        // Optimistic update: reorder locally first
        var newTracks = currentTracks.filter { !selectedTrackIds.contains($0.id) }
        let insertIndex = min(adjustedDestination, newTracks.count)
        newTracks.insert(contentsOf: itemsToMove, at: insertIndex)
        currentTracks = newTracks
        
        // Move items one by one via API (Plex doesn't support batch move)
        var currentAfterItemId = afterItemId
        var success = true
        
        for item in itemsToMove {
            do {
                try await plexService.movePlaylistItem(
                    playlistId: playlist.id,
                    playlistItemId: item.playlistItemID,
                    afterItemId: currentAfterItemId
                )
                currentAfterItemId = item.playlistItemID
            } catch {
                success = false
                self.error = error
                break
            }
        }
        
        if !success {
            currentTracks = originalTracks
            await fetchTracks(for: playlist)
        }
        
        // Keep selection active so user can continue adjusting
    }
    
    /// Move selected tracks to a destination index
    /// - Parameter destinationIndex: The index where selected tracks should be moved (0 = beginning)
    func moveSelectedTracks(to destinationIndex: Int) async {
        guard let playlist = selectedPlaylist else { return }
        guard !selectedTrackIds.isEmpty else { return }
        
        // Get selected items in their current order
        let itemsToMove = selectedTracks
        guard !itemsToMove.isEmpty else { return }
        
        // Calculate the "after" item ID
        // We need to find the item that should be before our moved items
        let afterItemId: String?
        if destinationIndex == 0 {
            afterItemId = nil // Move to beginning
        } else {
            // Find items that are NOT selected and come before the destination
            let nonSelectedItems = currentTracks.filter { !selectedTrackIds.contains($0.id) }
            let targetIndex = min(destinationIndex - 1, nonSelectedItems.count - 1)
            if targetIndex >= 0 && targetIndex < nonSelectedItems.count {
                afterItemId = nonSelectedItems[targetIndex].playlistItemID
            } else {
                afterItemId = nil
            }
        }
        
        // Store original tracks for undo/revert
        let originalTracks = currentTracks
        
        // Optimistic update: reorder locally first
        var newTracks = currentTracks.filter { !selectedTrackIds.contains($0.id) }
        let insertIndex = min(destinationIndex, newTracks.count)
        newTracks.insert(contentsOf: itemsToMove, at: insertIndex)
        currentTracks = newTracks
        
        // Move items one by one via API (Plex doesn't support batch move)
        // We move them in order, each one after the previous
        var currentAfterItemId = afterItemId
        var success = true
        
        for item in itemsToMove {
            do {
                try await plexService.movePlaylistItem(
                    playlistId: playlist.id,
                    playlistItemId: item.playlistItemID,
                    afterItemId: currentAfterItemId
                )
                // The next item should be placed after this one
                currentAfterItemId = item.playlistItemID
            } catch {
                success = false
                self.error = error
                break
            }
        }
        
        if !success {
            // Revert on failure
            currentTracks = originalTracks
            await fetchTracks(for: playlist)
        }
        
        // Clear selection after move
        clearSelection()
    }
    
    /// Remove all selected tracks from the playlist
    func removeSelectedTracks() async {
        guard let playlist = selectedPlaylist else { return }
        guard !selectedTrackIds.isEmpty else { return }
        
        let itemsToRemove = selectedTracks
        
        for item in itemsToRemove {
            do {
                try await plexService.removeFromPlaylist(
                    playlistId: playlist.id,
                    playlistItemId: item.playlistItemID
                )
                currentTracks.removeAll { $0.id == item.id }
            } catch {
                self.error = error
            }
        }
        
        clearSelection()
    }
    
    // MARK: - Undo Support
    
    var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    func undo() async {
        guard let lastAction = undoStack.popLast() else { return }
        
        switch lastAction.action {
        case .deletePlaylist:
            // Can't really undo delete without recreating - would need to restore tracks too
            // For now, show message
            break
            
        case .addTracks:
            if let (playlistId, tracks) = lastAction.data as? (String, [Track]) {
                // Remove the added tracks
                if let playlist = playlists.first(where: { $0.id == playlistId }) {
                    // This is complex - would need to track which items were added
                    // For now, refresh
                    await fetchTracks(for: playlist)
                }
            }
            
        case .removeTrack:
            if let (playlistId, item, _) = lastAction.data as? (String, PlaylistItem, Int),
               let libraryKey = libraryKey {
                let uri = await plexService.trackURI(for: item.track, libraryKey: libraryKey)
                try? await plexService.addToPlaylist(playlistId: playlistId, trackURIs: [uri])
                if let playlist = playlists.first(where: { $0.id == playlistId }) {
                    await fetchTracks(for: playlist)
                }
            }
            
        case .moveTrack:
            if let (playlistId, oldIndex, newIndex) = lastAction.data as? (String, Int, Int) {
                // Move back
                if let playlist = playlists.first(where: { $0.id == playlistId }) {
                    let reverseSource = IndexSet(integer: newIndex > oldIndex ? newIndex - 1 : newIndex)
                    let reverseDest = oldIndex
                    await moveTrack(from: reverseSource, to: reverseDest)
                    // Remove the undo entry we just created
                    undoStack.removeLast()
                }
            }
        }
    }
}

// MARK: - Playlist Action Types

private enum PlaylistAction {
    case deletePlaylist
    case addTracks
    case removeTrack
    case moveTrack
}
