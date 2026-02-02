import Foundation
import AppKit
import Combine

// MARK: - Auth View Model

/// Manages authentication state and Plex OAuth flow
@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: AuthenticationState = .unauthenticated
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var servers: [PlexServer] = []
    @Published private(set) var selectedServer: PlexServer?
    @Published private(set) var musicLibraries: [MusicLibrary] = []
    @Published var selectedLibrary: MusicLibrary?
    
    // MARK: - Private Properties
    
    private let plexService: PlexAPIService
    private let keychain = KeychainService.shared
    private var pinCheckTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var isAuthenticated: Bool {
        state.isAuthenticated
    }
    
    var isConnected: Bool {
        connectionState.isConnected
    }
    
    var currentUser: PlexUser? {
        state.user
    }
    
    // MARK: - Initialization
    
    init(plexService: PlexAPIService = .shared) {
        self.plexService = plexService
        
        // Try to restore session
        Task {
            await restoreSession()
        }
    }
    
    // MARK: - Session Restoration
    
    /// Attempt to restore a previous session from keychain
    func restoreSession() async {
        guard let user = keychain.getUser(),
              let token = keychain.getAuthToken() else {
            state = .unauthenticated
            return
        }
        
        state = .authenticated(user: user)
        await plexService.configure(authToken: token, server: nil)
        
        // Fetch servers
        await fetchServers()
    }
    
    // MARK: - OAuth Flow
    
    /// Start the OAuth authentication flow
    func startOAuthFlow() async {
        state = .authenticating
        
        do {
            let (pin, authURL) = try await plexService.requestOAuthPin()
            
            // Open browser for authentication
            NSWorkspace.shared.open(authURL)
            
            state = .waitingForOAuth(url: authURL, pin: pin)
            
            // Start polling for PIN completion
            startPinPolling(pin: pin)
            
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }
    
    /// Poll for PIN completion
    private func startPinPolling(pin: PlexAuthPin) {
        pinCheckTask?.cancel()
        
        pinCheckTask = Task {
            let maxAttempts = 60 // 5 minutes with 5 second intervals
            var attempts = 0
            
            while !Task.isCancelled && attempts < maxAttempts {
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    
                    if let authToken = try await plexService.checkPinStatus(pin: pin) {
                        // PIN claimed - fetch user
                        let user = try await plexService.fetchUser(authToken: authToken)
                        
                        // Save to keychain
                        try keychain.saveAuthToken(authToken)
                        try keychain.saveUser(user)
                        
                        state = .authenticated(user: user)
                        
                        // Fetch servers
                        await fetchServers()
                        return
                    }
                    
                    attempts += 1
                    
                } catch is CancellationError {
                    return
                } catch {
                    state = .error(message: error.localizedDescription)
                    return
                }
            }
            
            if attempts >= maxAttempts {
                state = .error(message: "Authentication timed out. Please try again.")
            }
        }
    }
    
    /// Cancel the OAuth flow
    func cancelOAuthFlow() {
        pinCheckTask?.cancel()
        state = .unauthenticated
    }
    
    // MARK: - Server Management
    
    /// Fetch available Plex servers
    func fetchServers() async {
        do {
            servers = try await plexService.fetchServers()
            
            // Auto-connect to first owned server if available
            if let ownedServer = servers.first(where: { $0.isOwned }) {
                await connectToServer(ownedServer)
            }
        } catch {
            // Don't show error for server fetch - user can manually select
            print("Failed to fetch servers: \(error)")
        }
    }
    
    /// Connect to a specific server
    func connectToServer(_ server: PlexServer) async {
        connectionState = .connecting
        
        do {
            try await plexService.connect(to: server)
            await plexService.configure(authToken: currentUser?.authToken, server: server)
            
            selectedServer = server
            connectionState = .connected(server: server)
            
            // Fetch music libraries
            await fetchMusicLibraries()
            
        } catch {
            connectionState = .error(message: error.localizedDescription)
        }
    }
    
    // MARK: - Music Libraries
    
    /// Fetch music libraries from connected server
    func fetchMusicLibraries() async {
        do {
            musicLibraries = try await plexService.fetchMusicLibraries()
            
            // Auto-select first library
            if selectedLibrary == nil {
                selectedLibrary = musicLibraries.first
            }
        } catch {
            print("Failed to fetch music libraries: \(error)")
        }
    }
    
    // MARK: - Sign Out
    
    /// Sign out and clear all credentials
    func signOut() async {
        pinCheckTask?.cancel()
        
        await plexService.signOut()
        try? keychain.clearAll()
        
        state = .unauthenticated
        connectionState = .disconnected
        servers = []
        selectedServer = nil
        musicLibraries = []
        selectedLibrary = nil
    }
    
    // MARK: - Settings
    
    /// Update the insecure connections setting
    func updateInsecureConnectionsSetting(_ allow: Bool) async {
        UserDefaults.standard.set(allow, forKey: "allowInsecureConnections")
        await plexService.setAllowInsecureConnections(allow)
    }
}
