import Foundation
import AVFoundation
import Combine

// MARK: - Audio Preview Service

/// Service for previewing/playing track audio
@MainActor
final class AudioPreviewService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTrack: Track?
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    
    /// Volume from 0.0 to 1.0
    @Published var volume: Float = 0.8 {
        didSet {
            player?.volume = volume
        }
    }
    
    // MARK: - Private Properties
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    
    // For SSL bypass - download audio before playing
    private lazy var insecureSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config, delegate: InsecureAudioSessionDelegate(), delegateQueue: nil)
    }()
    
    // MARK: - Singleton
    
    static let shared = AudioPreviewService()
    
    private init() {
        setupNotifications()
    }
    
    // Note: No deinit needed - this is a singleton that lives for the app's lifetime.
    // Cleanup is handled in stop() when playback ends.
    
    // MARK: - Playback Control
    
    /// Play a track
    func play(_ track: Track) {
        guard let urlString = track.streamURL,
              let url = URL(string: urlString) else {
            self.error = AudioPreviewError.invalidURL
            return
        }
        
        // Stop current playback
        stop()
        
        isLoading = true
        currentTrack = track
        error = nil
        
        let allowInsecure = UserDefaults.standard.bool(forKey: "allowInsecureConnections")
        
        if allowInsecure {
            // Download audio first using our insecure session, then play
            Task {
                await downloadAndPlay(url: url)
            }
        } else {
            // Standard playback
            playDirectly(url: url)
        }
    }
    
    /// Download audio using SSL-bypassing session, then play from data
    private func downloadAndPlay(url: URL) async {
        do {
            let (data, response) = try await insecureSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AudioPreviewError.networkError
            }
            
            // Save to temp file and play
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp3")
            
            try data.write(to: tempURL)
            
            // Play from local file
            playDirectly(url: tempURL)
            
        } catch {
            self.error = error
            self.isLoading = false
            print("Audio download failed: \(error)")
        }
    }
    
    /// Play directly from URL (for trusted connections or local files)
    private func playDirectly(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = volume
        
        // Start playing immediately without waiting for full buffer
        player?.automaticallyWaitsToMinimizeStalling = false
        
        // Observe player status
        statusObserver = playerItem.observe(\.status) { [weak self] item, _ in
            Task { @MainActor in
                self?.handleStatusChange(item.status, error: item.error)
            }
        }
        
        // Observe playback rate
        rateObserver = player?.observe(\.rate) { [weak self] player, _ in
            Task { @MainActor in
                self?.isPlaying = player.rate > 0
            }
        }
        
        // Setup time observer
        setupTimeObserver()
        
        // Start playback immediately
        isLoading = false
        isPlaying = true
        player?.play()
    }
    
    /// Pause playback
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    /// Resume playback
    func resume() {
        player?.play()
        isPlaying = true
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    /// Stop playback completely
    func stop() {
        // Remove observers first while we still have the player reference
        if let observer = timeObserver, let currentPlayer = player {
            currentPlayer.removeTimeObserver(observer)
        }
        timeObserver = nil
        
        statusObserver?.invalidate()
        statusObserver = nil
        rateObserver?.invalidate()
        rateObserver = nil
        
        player?.pause()
        player = nil
        
        isPlaying = false
        isLoading = false
        currentTrack = nil
        currentTime = 0
        duration = 0
    }
    
    /// Seek to a specific time
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: cmTime) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = time
            }
        }
    }
    
    /// Seek forward by seconds
    func skipForward(_ seconds: TimeInterval = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    /// Seek backward by seconds
    func skipBackward(_ seconds: TimeInterval = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handlePlaybackEnded()
            }
        }
    }
    
    private func setupTimeObserver() {
        // Remove any existing observer from the current player
        if let observer = timeObserver, let currentPlayer = player {
            currentPlayer.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: 1000)
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds
            }
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver, let currentPlayer = player {
            currentPlayer.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func handleStatusChange(_ status: AVPlayerItem.Status, error playerError: Error?) {
        isLoading = false
        
        switch status {
        case .readyToPlay:
            if let duration = player?.currentItem?.duration {
                self.duration = duration.seconds.isFinite ? duration.seconds : 0
            }
            isPlaying = true
            
        case .failed:
            let errorToReport = playerError ?? player?.currentItem?.error ?? AudioPreviewError.playbackFailed
            self.error = errorToReport
            print("Playback failed: \(errorToReport.localizedDescription)")
            // Don't call stop() here - let the user see the error and dismiss manually
            isPlaying = false
            
        case .unknown:
            break
            
        @unknown default:
            break
        }
    }
    
    private func handlePlaybackEnded() {
        isPlaying = false
        currentTime = 0
        seek(to: 0)
    }
}

// MARK: - Audio Preview Errors

enum AudioPreviewError: LocalizedError {
    case invalidURL
    case playbackFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid audio URL"
        case .playbackFailed:
            return "Failed to play audio"
        case .networkError:
            return "Network error during playback"
        }
    }
}

// MARK: - Time Formatting Extension

extension AudioPreviewService {
    /// Format time interval as MM:SS
    static func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Insecure Session Delegate for Audio Downloads

/// URLSession delegate that bypasses SSL certificate validation for audio streaming
final class InsecureAudioSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
