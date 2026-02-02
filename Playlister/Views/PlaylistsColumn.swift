import SwiftUI

// MARK: - Playlists Column (Column 1)

/// Sidebar showing all playlists with add/delete functionality
struct PlaylistsColumn: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PlaylistViewModel
    @State private var isHoveringNewButton = false
    @State private var filterText = ""
    @State private var isShowingSmartPlaylistSheet = false
    @State private var editingSmartPlaylist: Playlist?
    
    // MARK: - Computed Properties
    
    private var regularPlaylists: [Playlist] {
        let nonSmart = viewModel.playlists.filter { !$0.smart }
        if filterText.isEmpty {
            return nonSmart
        }
        return nonSmart.filter { $0.title.localizedCaseInsensitiveContains(filterText) }
    }
    
    private var smartPlaylists: [Playlist] {
        let smart = viewModel.playlists.filter { $0.smart }
        if filterText.isEmpty {
            return smart
        }
        return smart.filter { $0.title.localizedCaseInsensitiveContains(filterText) }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Filter playlists...", text: $filterText)
                    .textFieldStyle(.plain)
                if !filterText.isEmpty {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary)
            
            List(selection: $viewModel.selectedPlaylist) {
                Section("Playlists") {
                    ForEach(regularPlaylists) { playlist in
                        PlaylistRow(playlist: playlist)
                            .tag(playlist)
                            .contextMenu {
                                playlistContextMenu(for: playlist)
                            }
                    }
                    .onDelete { indexSet in
                        deletePlaylist(at: indexSet, from: regularPlaylists)
                    }
                }
                
                Section {
                    ForEach(smartPlaylists) { playlist in
                        PlaylistRow(playlist: playlist)
                            .tag(playlist)
                            .contextMenu {
                                smartPlaylistContextMenu(for: playlist)
                            }
                    }
                } header: {
                    HStack {
                        Text("Smart Playlists")
                        Spacer()
                        Button {
                            editingSmartPlaylist = nil
                            isShowingSmartPlaylistSheet = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("New Smart Playlist")
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 200)
        .navigationTitle("Playlists")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if viewModel.playlists.isEmpty {
                emptyState
            }
        }
        .sheet(isPresented: $isShowingSmartPlaylistSheet) {
            SmartPlaylistView(viewModel: viewModel, existingPlaylist: editingSmartPlaylist)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Playlists", systemImage: "music.note.list")
        } description: {
            Text("Create your first playlist to get started.")
        } actions: {
            VStack(spacing: 12) {
                Button("New Playlist") {
                    viewModel.startCreatingPlaylist()
                }
                .buttonStyle(.borderedProminent)
                
                Button("New Smart Playlist") {
                    editingSmartPlaylist = nil
                    isShowingSmartPlaylistSheet = true
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func playlistContextMenu(for playlist: Playlist) -> some View {
        Button {
            viewModel.selectedPlaylist = playlist
        } label: {
            Label("Show Tracks", systemImage: "list.bullet")
        }
        
        Divider()
        
        Button(role: .destructive) {
            Task { await viewModel.deletePlaylist(playlist) }
        } label: {
            Label("Delete Playlist", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private func smartPlaylistContextMenu(for playlist: Playlist) -> some View {
        Button {
            viewModel.selectedPlaylist = playlist
        } label: {
            Label("Show Tracks", systemImage: "list.bullet")
        }
        
        Button {
            editingSmartPlaylist = playlist
            isShowingSmartPlaylistSheet = true
        } label: {
            Label("Edit Smart Playlist...", systemImage: "pencil")
        }
        
        Divider()
        
        Button(role: .destructive) {
            Task { await viewModel.deletePlaylist(playlist) }
        } label: {
            Label("Delete Playlist", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    
    private func createPlaylist() {
        Task {
            await viewModel.createPlaylist(name: viewModel.newPlaylistName)
        }
    }
    
    private func deletePlaylist(at indexSet: IndexSet, from playlists: [Playlist]) {
        for index in indexSet {
            let playlist = playlists[index]
            Task { await viewModel.deletePlaylist(playlist) }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationSplitView {
        PlaylistsColumn(viewModel: {
            let vm = PlaylistViewModel()
            return vm
        }())
    } detail: {
        Text("Detail")
    }
    .frame(width: 800, height: 600)
}
#endif
