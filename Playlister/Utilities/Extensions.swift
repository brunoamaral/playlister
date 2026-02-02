import Foundation
import SwiftUI

// MARK: - URL Extensions

extension URL {
    /// Append query items to URL
    func appending(queryItems: [URLQueryItem]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        var existingItems = components.queryItems ?? []
        existingItems.append(contentsOf: queryItems)
        components.queryItems = existingItems
        return components.url!
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format date as relative time (e.g., "2 hours ago")
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format date as short date string
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

// MARK: - Int Extensions

extension Int {
    /// Format milliseconds as duration string (MM:SS or HH:MM:SS)
    var formattedDuration: String {
        let totalSeconds = self / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply a modifier if the value is non-nil
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Color Extensions

extension Color {
    /// System background colors that adapt to Dark Mode
    static var systemBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }
    
    static var secondarySystemBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }
}

// MARK: - String Extensions

extension String {
    /// Truncate string to specified length with ellipsis
    func truncated(to length: Int) -> String {
        if count <= length {
            return self
        }
        return String(prefix(length - 1)) + "…"
    }
    
    /// Check if string contains only whitespace
    var isBlank: Bool {
        trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - Collection Extensions

extension Collection {
    /// Safe subscript that returns nil if index is out of bounds
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Binding Extensions

extension Binding {
    /// Create a binding with a custom setter that also performs an action
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

// MARK: - Task Extensions

extension Task where Success == Never, Failure == Never {
    /// Sleep for a specified number of milliseconds
    static func sleep(milliseconds: UInt64) async throws {
        try await sleep(nanoseconds: milliseconds * 1_000_000)
    }
}

// MARK: - NSImage Extensions

extension NSImage {
    /// Resize image to specified size
    func resized(to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        self.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: self.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }
}

// MARK: - PlexImage (SSL-bypassing image loader)

/// Custom image loader that bypasses SSL certificate validation for self-signed certificates
@MainActor
final class PlexImageLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var currentTask: Task<Void, Never>?
    private static let cache = NSCache<NSString, NSImage>()
    
    /// URL session delegate that accepts self-signed certificates
    private final class InsecureSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
        func urlSession(
            _ session: URLSession,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config, delegate: InsecureSessionDelegate(), delegateQueue: nil)
    }()
    
    func load(from url: URL?) {
        currentTask?.cancel()
        
        guard let url = url else {
            self.image = nil
            return
        }
        
        let cacheKey = url.absoluteString as NSString
        
        // Check cache first
        if let cached = Self.cache.object(forKey: cacheKey) {
            self.image = cached
            return
        }
        
        isLoading = true
        error = nil
        
        currentTask = Task {
            do {
                let (data, response) = try await session.data(from: url)
                
                guard !Task.isCancelled else { return }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                guard let nsImage = NSImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                
                // Cache the image
                Self.cache.setObject(nsImage, forKey: cacheKey)
                
                self.image = nsImage
                self.isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func cancel() {
        currentTask?.cancel()
    }
}

/// A SwiftUI view that loads images from URLs with SSL bypass for self-signed certificates
struct PlexImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder
    
    @StateObject private var loader = PlexImageLoader()
    
    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }
    
    init(url: String?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url.flatMap { URL(string: $0) }
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(nsImage: image)
                    .resizable()
            } else if loader.isLoading {
                ProgressView()
            } else {
                placeholder()
            }
        }
        .onAppear {
            loader.load(from: url)
        }
        .onChange(of: url) { _, newURL in
            loader.load(from: newURL)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
