import SwiftUI

// MARK: - Settings View

/// App settings/preferences
struct SettingsView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - State
    
    @AppStorage("autoPlay") private var autoPlay: Bool = false
    @AppStorage("previewVolume") private var previewVolume: Double = 0.8
    @AppStorage("allowInsecureConnections") private var allowInsecureConnections: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            accountSettings
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
            
            playbackSettings
                .tabItem {
                    Label("Playback", systemImage: "play.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
    
    // MARK: - General Settings
    
    private var generalSettings: some View {
        Form {
            Section {
                Toggle("Auto-play next track in preview", isOn: $autoPlay)
            } header: {
                Text("Behavior")
            }
            
            Section {
                Toggle("Allow insecure connections", isOn: $allowInsecureConnections)
                Text("Enable this to connect to local Plex servers with self-signed or invalid SSL certificates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Network")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: allowInsecureConnections) { _, newValue in
            Task {
                await authViewModel.updateInsecureConnectionsSetting(newValue)
            }
        }
    }
    
    // MARK: - Account Settings
    
    private var accountSettings: some View {
        Form {
            if let user = authViewModel.currentUser {
                Section {
                    LabeledContent("Username", value: user.username)
                    LabeledContent("Email", value: user.email)
                } header: {
                    Text("Plex Account")
                }
                
                if let server = authViewModel.selectedServer {
                    Section {
                        LabeledContent("Server", value: server.name)
                        LabeledContent("Address", value: server.baseURL)
                    } header: {
                        Text("Connected Server")
                    }
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        Task { await authViewModel.signOut() }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("Not Signed In", systemImage: "person.slash")
                } description: {
                    Text("Sign in with Plex to view account details.")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Playback Settings
    
    private var playbackSettings: some View {
        Form {
            Section {
                LabeledContent("Preview Volume") {
                    Slider(value: $previewVolume, in: 0...1)
                        .frame(width: 200)
                }
            } header: {
                Text("Audio")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: previewVolume) { _, newValue in
            AudioPreviewService.shared.volume = Float(newValue)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
#endif
