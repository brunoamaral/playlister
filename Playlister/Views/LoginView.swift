import SwiftUI
import AppKit

// MARK: - Login View

/// Handles Plex OAuth authentication
struct LoginView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - State
    
    @AppStorage("allowInsecureConnections") private var allowInsecureConnections: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 32) {
            // Logo/Icon
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            
            VStack(spacing: 8) {
                Text("Playlister")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Manage your Plex playlists")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            // State-dependent content
            Group {
                switch authViewModel.state {
                case .unauthenticated:
                    signInButton
                    
                case .authenticating:
                    authenticatingView
                    
                case .waitingForOAuth(_, _):
                    waitingForOAuthView
                    
                case .authenticated:
                    authenticatedView
                    
                case .error(let message):
                    errorView(message: message)
                }
            }
            .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
    
    // MARK: - Sign In Button
    
    private var signInButton: some View {
        VStack(spacing: 16) {
            Button {
                Task { await authViewModel.startOAuthFlow() }
            } label: {
                HStack {
                    Image(systemName: "person.badge.key")
                    Text("Sign in with Plex")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Text("You'll be redirected to Plex to authorize this app.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Authenticating View
    
    private var authenticatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Preparing authentication...")
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Waiting for OAuth
    
    private var waitingForOAuthView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            VStack(spacing: 8) {
                Text("Waiting for authorization...")
                    .font(.headline)
                
                Text("Please complete the sign-in process in your browser.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    authViewModel.cancelOAuthFlow()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Open Plex Again") {
                    if case .waitingForOAuth(let url, _) = authViewModel.state {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
    // MARK: - Authenticated View (Connecting to Server)
    
    private var authenticatedView: some View {
        VStack(spacing: 20) {
            if let user = authViewModel.currentUser {
                HStack(spacing: 12) {
                    // User avatar
                    AsyncImage(url: user.thumb.flatMap { URL(string: $0) }) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text("Welcome, \(user.title)")
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Server selection
            switch authViewModel.connectionState {
            case .disconnected:
                serverSelectionView
                
            case .connecting:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Connecting to server...")
                        .foregroundStyle(.secondary)
                }
                
            case .connected(let server):
                VStack(spacing: 8) {
                    Label("Connected to \(server.name)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    
                    ProgressView()
                        .padding(.top, 8)
                }
                
            case .error(let message):
                VStack(spacing: 12) {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    
                    serverSelectionView
                }
            }
        }
    }
    
    // MARK: - Server Selection
    
    private var serverSelectionView: some View {
        VStack(spacing: 16) {
            if authViewModel.servers.isEmpty {
                ProgressView("Finding servers...")
            } else {
                Text("Select a Plex Server")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    ForEach(authViewModel.servers) { server in
                        Button {
                            Task { await authViewModel.connectToServer(server) }
                        } label: {
                            HStack {
                                Image(systemName: "server.rack")
                                VStack(alignment: .leading) {
                                    Text(server.name)
                                        .font(.headline)
                                    Text(server.isLocal ? "Local" : "Remote")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if server.isOwned {
                                    Text("Owned")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Insecure connection toggle
                Divider()
                    .padding(.vertical, 8)
                
                VStack(spacing: 8) {
                    Toggle("Allow insecure connections", isOn: $allowInsecureConnections)
                        .toggleStyle(.checkbox)
                    
                    Text("Enable for local servers with self-signed SSL certificates")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .onChange(of: allowInsecureConnections) { _, newValue in
                    Task {
                        await authViewModel.updateInsecureConnectionsSetting(newValue)
                    }
                }
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)
            
            Text("Authentication Error")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task { await authViewModel.startOAuthFlow() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Unauthenticated") {
    LoginView()
        .environmentObject(AuthViewModel())
        .frame(width: 500, height: 600)
}
#endif
