import SwiftUI

// MARK: - Playlister App

/// Main app entry point
@main
struct PlaylisterApp: App {
    
    // MARK: - State
    
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isShowingSmartPlaylist = false
    
    // MARK: - Body
    
    var body: some Scene {
        // Main Window
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 700)
        .commands {
            appCommands
        }
        
        // Settings Window
        Settings {
            SettingsView()
                .environmentObject(authViewModel)
        }
    }
    
    // MARK: - Commands
    
    @CommandsBuilder
    private var appCommands: some Commands {
        // Replace New menu items
        CommandGroup(replacing: .newItem) {
            Button("New Playlist") {
                NotificationCenter.default.post(name: .newPlaylist, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("New Smart Playlist...") {
                NotificationCenter.default.post(name: .newSmartPlaylist, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command, .option])
            
            Divider()
        }
        
        // Edit menu additions
        CommandGroup(after: .undoRedo) {
            Divider()
            
            Button("Select All") {
                NotificationCenter.default.post(name: .selectAll, object: nil)
            }
            .keyboardShortcut("a", modifiers: .command)
        }
        
        // View menu
        CommandGroup(after: .sidebar) {
            Button("Refresh Playlists") {
                NotificationCenter.default.post(name: .refreshPlaylists, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
        }
        
        // Playback menu
        CommandMenu("Playback") {
            Button("Play/Pause") {
                AudioPreviewService.shared.togglePlayPause()
            }
            .keyboardShortcut(.space, modifiers: [])
            
            Divider()
            
            Button("Skip Forward") {
                AudioPreviewService.shared.skipForward()
            }
            .keyboardShortcut(.rightArrow, modifiers: .command)
            
            Button("Skip Backward") {
                AudioPreviewService.shared.skipBackward()
            }
            .keyboardShortcut(.leftArrow, modifiers: .command)
            
            Divider()
            
            Button("Stop") {
                AudioPreviewService.shared.stop()
            }
            .keyboardShortcut(".", modifiers: .command)
            
            Divider()
            
            Button("Volume Up") {
                let current = AudioPreviewService.shared.volume
                AudioPreviewService.shared.volume = min(1.0, current + 0.1)
            }
            .keyboardShortcut(.upArrow, modifiers: .command)
            
            Button("Volume Down") {
                let current = AudioPreviewService.shared.volume
                AudioPreviewService.shared.volume = max(0.0, current - 0.1)
            }
            .keyboardShortcut(.downArrow, modifiers: .command)
        }
        
        // Account menu
        CommandMenu("Account") {
            if authViewModel.isAuthenticated {
                if let user = authViewModel.currentUser {
                    Text("Signed in as \(user.username)")
                }
                
                Divider()
                
                if let server = authViewModel.selectedServer {
                    Text("Server: \(server.name)")
                    
                    if authViewModel.servers.count > 1 {
                        Menu("Switch Server") {
                            ForEach(authViewModel.servers) { server in
                                Button(server.name) {
                                    Task { await authViewModel.connectToServer(server) }
                                }
                            }
                        }
                    }
                    
                    Divider()
                }
                
                Button("Sign Out") {
                    Task { await authViewModel.signOut() }
                }
            } else {
                Button("Sign In with Plex...") {
                    Task { await authViewModel.startOAuthFlow() }
                }
            }
        }
        
        // Help menu additions
        CommandGroup(replacing: .help) {
            Button("Playlister Help") {
                // Open help
            }
            
            Divider()
            
            Link("Plex Support", destination: URL(string: "https://support.plex.tv")!)
            
            Link("Report an Issue", destination: URL(string: "https://github.com/playlister/issues")!)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newPlaylist = Notification.Name("newPlaylist")
    static let newSmartPlaylist = Notification.Name("newSmartPlaylist")
    static let refreshPlaylists = Notification.Name("refreshPlaylists")
    static let selectAll = Notification.Name("selectAll")
}
