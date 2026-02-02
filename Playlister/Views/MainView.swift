import SwiftUI

// MARK: - Main View

/// Three-column layout for playlist management
struct MainView: View {
    
    // MARK: - Environment & State
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var playlistViewModel = PlaylistViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var audioService = AudioPreviewService.shared
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Column 1: Playlists
            PlaylistsColumn(viewModel: playlistViewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } content: {
            // Column 2: Tracks in selected playlist
            TracksColumn(viewModel: playlistViewModel)
                .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 600)
        } detail: {
            // Column 3: Search
            SearchColumn(
                viewModel: searchViewModel,
                playlistViewModel: playlistViewModel
            )
            .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 600)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            toolbarContent
        }
        .searchable(
            text: $searchViewModel.searchQuery,
            placement: .toolbar,
            prompt: "Search tracks..."
        )
        .onSubmit(of: .search) {
            searchViewModel.search()
        }
        .onChange(of: searchViewModel.searchQuery) { _, _ in
            searchViewModel.search()
        }
        .task {
            // Configure view models when view appears
            if let libraryKey = authViewModel.selectedLibrary?.key {
                playlistViewModel.configure(libraryKey: libraryKey)
                searchViewModel.configure(libraryKey: libraryKey)
            }
            await playlistViewModel.fetchPlaylists()
        }
        .onChange(of: authViewModel.selectedLibrary) { _, newLibrary in
            if let key = newLibrary?.key {
                playlistViewModel.configure(libraryKey: key)
                searchViewModel.configure(libraryKey: key)
            }
        }
        // Now Playing overlay at bottom
        .safeAreaInset(edge: .bottom) {
            if audioService.currentTrack != nil {
                NowPlayingView()
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .alert("Error", isPresented: $playlistViewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(playlistViewModel.error?.localizedDescription ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // Refresh button
            Button {
                Task { await playlistViewModel.fetchPlaylists() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .keyboardShortcut("r", modifiers: .command)
            .help("Refresh playlists (⌘R)")
            
            // New playlist button
            Button {
                playlistViewModel.startCreatingPlaylist()
            } label: {
                Label("New Playlist", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
            .help("Create new playlist (⌘N)")
            .disabled(playlistViewModel.isCreatingNewPlaylist)
        }
        
        ToolbarItem(placement: .navigation) {
            // Server/library picker
            if let server = authViewModel.selectedServer {
                Menu {
                    if authViewModel.musicLibraries.count > 1 {
                        Picker("Library", selection: $authViewModel.selectedLibrary) {
                            ForEach(authViewModel.musicLibraries) { library in
                                Text(library.title).tag(library as MusicLibrary?)
                            }
                        }
                        Divider()
                    }
                    
                    if authViewModel.servers.count > 1 {
                        Menu("Switch Server") {
                            ForEach(authViewModel.servers) { s in
                                Button(s.name) {
                                    Task { await authViewModel.connectToServer(s) }
                                }
                            }
                        }
                    }
                } label: {
                    Label(server.name, systemImage: "server.rack")
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    MainView()
        .environmentObject(AuthViewModel())
        .frame(width: 1200, height: 700)
}
#endif
