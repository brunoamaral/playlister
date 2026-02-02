import SwiftUI

// MARK: - Content View

/// Root view that switches between login and main interface
struct ContentView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated && authViewModel.isConnected {
                MainView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isConnected)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Logged Out") {
    ContentView()
        .environmentObject(AuthViewModel())
        .frame(width: 1000, height: 700)
}
#endif
