import Foundation
import Combine

// MARK: - Search View Model

/// Manages track search functionality
@MainActor
final class SearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var searchQuery: String = ""
    @Published private(set) var searchResults: [Track] = []
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var error: Error?
    @Published var selectedTracks: Set<Track> = []
    
    // Recent searches
    @Published private(set) var recentSearches: [String] = []
    
    // MARK: - Private Properties
    
    private let plexService: PlexAPIService
    private var searchTask: Task<Void, Never>?
    private var libraryKey: String?
    
    private let maxRecentSearches = 10
    private let recentSearchesKey = "RecentSearches"
    
    // MARK: - Initialization
    
    init(plexService: PlexAPIService = .shared) {
        self.plexService = plexService
        loadRecentSearches()
    }
    
    // MARK: - Configuration
    
    func configure(libraryKey: String?) {
        self.libraryKey = libraryKey
    }
    
    // MARK: - Search
    
    /// Perform a search with debouncing
    func search() {
        // Cancel previous search
        searchTask?.cancel()
        
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            // Debounce - wait 300ms before searching
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else { return }
            
            do {
                let results = try await plexService.searchTracks(
                    query: query,
                    libraryKey: libraryKey
                )
                
                guard !Task.isCancelled else { return }
                
                searchResults = results
                addToRecentSearches(query)
                
            } catch is CancellationError {
                // Ignore cancellation
            } catch {
                self.error = error
                searchResults = []
            }
            
            isSearching = false
        }
    }
    
    /// Clear search results
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        selectedTracks = []
        searchTask?.cancel()
    }
    
    // MARK: - Selection
    
    /// Toggle selection of a track
    func toggleSelection(_ track: Track) {
        if selectedTracks.contains(track) {
            selectedTracks.remove(track)
        } else {
            selectedTracks.insert(track)
        }
    }
    
    /// Select all visible results
    func selectAll() {
        selectedTracks = Set(searchResults)
    }
    
    /// Clear selection
    func clearSelection() {
        selectedTracks = []
    }
    
    /// Check if a track is selected
    func isSelected(_ track: Track) -> Bool {
        selectedTracks.contains(track)
    }
    
    // MARK: - Recent Searches
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }
    
    private func addToRecentSearches(_ query: String) {
        let normalized = query.trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else { return }
        
        // Remove if already exists
        recentSearches.removeAll { $0.lowercased() == normalized.lowercased() }
        
        // Add to front
        recentSearches.insert(normalized, at: 0)
        
        // Trim to max
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        // Save
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }
    
    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }
    
    func useRecentSearch(_ search: String) {
        searchQuery = search
        Task { search }
    }
}
