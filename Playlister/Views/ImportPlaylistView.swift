import SwiftUI
import UniformTypeIdentifiers

// MARK: - Import Playlist View

/// View for importing playlists from text files or direct text input
struct ImportPlaylistView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    @ObservedObject var playlistViewModel: PlaylistViewModel
    @StateObject private var importViewModel: ImportPlaylistViewModel
    
    // MARK: - Initialization
    
    init(playlistViewModel: PlaylistViewModel, plexService: PlexAPIService = .shared) {
        self.playlistViewModel = playlistViewModel
        self._importViewModel = StateObject(wrappedValue: ImportPlaylistViewModel(plexService: plexService))
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Playlist name
                    playlistNameSection
                    
                    // Input method
                    inputSection
                    
                    // Parse button
                    if !importViewModel.rawText.isEmpty && importViewModel.parsedEntries.isEmpty {
                        parseButton
                    }
                    
                    // Results
                    if !importViewModel.parsedEntries.isEmpty {
                        resultsSection
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 600, height: 700)
        .fileImporter(
            isPresented: $importViewModel.isShowingFilePicker,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: false
        ) { result in
            importViewModel.handleFileImport(result)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Import Playlist")
                .font(.headline)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // MARK: - Playlist Name Section
    
    private var playlistNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Playlist Name")
                .font(.headline)
            
            TextField("Enter playlist name", text: $importViewModel.playlistName)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Songs")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    importViewModel.isShowingFilePicker = true
                } label: {
                    Label("Import File", systemImage: "doc")
                }
                .buttonStyle(.bordered)
            }
            
            Text("Enter one song per line in the format: **Artist - Song Title**")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $importViewModel.rawText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
            
            if let error = importViewModel.parseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
    
    // MARK: - Parse Button
    
    private var parseButton: some View {
        HStack {
            Spacer()
            Button {
                Task {
                    await importViewModel.parseAndSearch()
                }
            } label: {
                if importViewModel.isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                    Text("Searching...")
                } else {
                    Label("Find Tracks", systemImage: "magnifyingglass")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(importViewModel.isSearching)
            Spacer()
        }
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Summary
            HStack {
                Text("Results")
                    .font(.headline)
                
                Spacer()
                
                Text("\(importViewModel.matchedCount) found, \(importViewModel.missingCount) missing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Filter tabs
            Picker("Filter", selection: $importViewModel.resultFilter) {
                Text("All (\(importViewModel.parsedEntries.count))").tag(ImportResultFilter.all)
                Text("Found (\(importViewModel.matchedCount))").tag(ImportResultFilter.found)
                Text("Missing (\(importViewModel.missingCount))").tag(ImportResultFilter.missing)
            }
            .pickerStyle(.segmented)
            
            // Results list
            LazyVStack(spacing: 8) {
                ForEach(importViewModel.filteredEntries) { entry in
                    ImportEntryRow(
                        entry: entry,
                        onSelectAlternative: { track in
                            importViewModel.selectAlternative(for: entry.id, track: track)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            if !importViewModel.parsedEntries.isEmpty {
                Button("Clear") {
                    importViewModel.clear()
                }
            }
            
            Button("Create Playlist") {
                Task {
                    await createPlaylist()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!importViewModel.canCreatePlaylist || importViewModel.isCreating)
            .keyboardShortcut(.defaultAction)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func createPlaylist() async {
        let tracks = importViewModel.tracksToAdd
        guard !tracks.isEmpty else { return }
        
        importViewModel.isCreating = true
        
        do {
            try await playlistViewModel.createPlaylist(
                name: importViewModel.playlistName,
                tracks: tracks
            )
            dismiss()
        } catch {
            importViewModel.parseError = "Failed to create playlist: \(error.localizedDescription)"
        }
        
        importViewModel.isCreating = false
    }
}

// MARK: - Import Entry Row

struct ImportEntryRow: View {
    let entry: ImportEntry
    let onSelectAlternative: (Track) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Status icon
                statusIcon
                
                // Original text
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.originalText)
                        .font(.body)
                    
                    if let track = entry.matchedTrack {
                        Text("→ \(track.artistName) - \(track.title)")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if !entry.alternatives.isEmpty {
                        Text("No exact match - \(entry.alternatives.count) similar found")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text("Not found in library")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Spacer()
                
                // Expand button for alternatives
                if !entry.alternatives.isEmpty && entry.matchedTrack == nil {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            // Alternatives
            if isExpanded && entry.matchedTrack == nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Did you mean:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(entry.alternatives) { track in
                        Button {
                            onSelectAlternative(track)
                        } label: {
                            HStack {
                                Image(systemName: "music.note")
                                    .foregroundStyle(.secondary)
                                Text("\(track.artistName) - \(track.title)")
                                    .font(.caption)
                                Spacer()
                                Image(systemName: "plus.circle")
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.leading, 28)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        if entry.matchedTrack != nil {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else if !entry.alternatives.isEmpty {
            Image(systemName: "questionmark.circle.fill")
                .foregroundStyle(.orange)
        } else {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}

// MARK: - Import Playlist View Model

@MainActor
final class ImportPlaylistViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var playlistName: String = ""
    @Published var rawText: String = ""
    @Published var parsedEntries: [ImportEntry] = []
    @Published var isSearching: Bool = false
    @Published var isCreating: Bool = false
    @Published var parseError: String?
    @Published var isShowingFilePicker: Bool = false
    @Published var resultFilter: ImportResultFilter = .all
    
    // MARK: - Computed Properties
    
    var matchedCount: Int {
        parsedEntries.filter { $0.matchedTrack != nil }.count
    }
    
    var missingCount: Int {
        parsedEntries.filter { $0.matchedTrack == nil }.count
    }
    
    var canCreatePlaylist: Bool {
        !playlistName.isEmpty && matchedCount > 0
    }
    
    var tracksToAdd: [Track] {
        parsedEntries.compactMap { $0.matchedTrack }
    }
    
    var filteredEntries: [ImportEntry] {
        switch resultFilter {
        case .all:
            return parsedEntries
        case .found:
            return parsedEntries.filter { $0.matchedTrack != nil }
        case .missing:
            return parsedEntries.filter { $0.matchedTrack == nil }
        }
    }
    
    // MARK: - Private Properties
    
    private let plexService: PlexAPIService
    
    // MARK: - Initialization
    
    init(plexService: PlexAPIService = .shared) {
        self.plexService = plexService
    }
    
    // MARK: - File Import
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                parseError = "Unable to access the selected file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                rawText = try String(contentsOf: url, encoding: .utf8)
                
                // Auto-set playlist name from filename if empty
                if playlistName.isEmpty {
                    playlistName = url.deletingPathExtension().lastPathComponent
                }
            } catch {
                parseError = "Failed to read file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            parseError = "Failed to import file: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Parse and Search
    
    func parseAndSearch() async {
        parseError = nil
        isSearching = true
        
        // Parse lines
        let lines = rawText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            parseError = "No songs found in the input"
            isSearching = false
            return
        }
        
        var entries: [ImportEntry] = []
        
        for line in lines {
            // Parse "Artist - Title" format
            let parts = line.components(separatedBy: " - ")
            
            let artist: String
            let title: String
            
            if parts.count >= 2 {
                artist = parts[0].trimmingCharacters(in: .whitespaces)
                title = parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespaces)
            } else {
                // Try to use the whole line as title
                artist = ""
                title = line
            }
            
            // Search for the track
            let (matchedTrack, alternatives) = await searchTrack(artist: artist, title: title)
            
            let entry = ImportEntry(
                originalText: line,
                parsedArtist: artist,
                parsedTitle: title,
                matchedTrack: matchedTrack,
                alternatives: alternatives
            )
            entries.append(entry)
        }
        
        parsedEntries = entries
        isSearching = false
    }
    
    // MARK: - Search Track
    
    private func searchTrack(artist: String, title: String) async -> (Track?, [Track]) {
        do {
            // Search by title first
            let results = try await plexService.searchTracks(query: title, libraryKey: nil)
            
            // Normalize for comparison
            let normalizedArtist = normalizeText(artist).lowercased()
            let normalizedTitle = normalizeText(title).lowercased()
            
            // Find exact matches
            var exactMatches: [Track] = []
            var partialMatches: [Track] = []
            
            for track in results {
                let trackTitle = normalizeText(track.title).lowercased()
                let trackArtist = normalizeText(track.artistName).lowercased()
                
                // Check artist match
                let artistMatches = artist.isEmpty || 
                    artistsMatch(normalizedArtist, trackArtist)
                
                if artistMatches {
                    // Exact title match
                    if trackTitle == normalizedTitle {
                        exactMatches.append(track)
                    }
                    // Partial title match
                    else if trackTitle.contains(normalizedTitle) || normalizedTitle.contains(trackTitle) {
                        partialMatches.append(track)
                    }
                }
            }
            
            // Return best match
            if let exact = exactMatches.first {
                return (exact, [])
            }
            
            // If we have partial matches, return the shortest (most likely the original version)
            if !partialMatches.isEmpty {
                let sorted = partialMatches.sorted { $0.title.count < $1.title.count }
                return (sorted.first, Array(sorted.dropFirst().prefix(5)))
            }
            
            // No match found, search by artist for alternatives
            if !artist.isEmpty {
                let artistResults = try await plexService.searchTracks(query: artist, libraryKey: nil)
                let filtered = artistResults.filter { track in
                    let trackArtist = normalizeText(track.artistName).lowercased()
                    return artistsMatch(normalizedArtist, trackArtist)
                }
                return (nil, Array(filtered.prefix(5)))
            }
            
            return (nil, [])
            
        } catch {
            return (nil, [])
        }
    }
    
    // MARK: - Text Normalization
    
    private func normalizeText(_ text: String) -> String {
        var result = text
        // Replace curly quotes and special characters with ASCII equivalents
        result = result.replacingOccurrences(of: "\u{2019}", with: "'")  // Right single curly quote
        result = result.replacingOccurrences(of: "\u{2018}", with: "'")  // Left single curly quote
        result = result.replacingOccurrences(of: "\u{201C}", with: "\"") // Left double curly quote
        result = result.replacingOccurrences(of: "\u{201D}", with: "\"") // Right double curly quote
        result = result.replacingOccurrences(of: "\u{2013}", with: "-")  // En dash
        result = result.replacingOccurrences(of: "\u{2014}", with: "-")  // Em dash
        result = result.replacingOccurrences(of: "\u{2010}", with: "-")  // Unicode hyphen
        result = result.replacingOccurrences(of: "\u{2026}", with: "...") // Ellipsis
        return result
    }
    
    private func simplifyArtistName(_ name: String) -> String {
        var simplified = normalizeText(name).lowercased()
        simplified = simplified.replacingOccurrences(of: "'s ", with: " ")
        simplified = simplified.replacingOccurrences(of: "' ", with: " ")
        simplified = simplified.replacingOccurrences(of: " & ", with: " ")
        simplified = simplified.replacingOccurrences(of: " and ", with: " ")
        simplified = simplified.replacingOccurrences(of: "feat.", with: "")
        simplified = simplified.replacingOccurrences(of: "featuring", with: "")
        simplified = simplified.replacingOccurrences(of: "ft.", with: "")
        // Remove extra whitespace
        simplified = simplified.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return simplified
    }
    
    private func artistsMatch(_ artist1: String, _ artist2: String) -> Bool {
        // Direct comparison
        if artist1.contains(artist2) || artist2.contains(artist1) {
            return true
        }
        
        // Simplified comparison
        let simple1 = simplifyArtistName(artist1)
        let simple2 = simplifyArtistName(artist2)
        
        if simple1.contains(simple2) || simple2.contains(simple1) {
            return true
        }
        
        // Word matching
        let words1 = Set(simple1.components(separatedBy: " ").filter { $0.count > 2 })
        let words2 = Set(simple2.components(separatedBy: " ").filter { $0.count > 2 })
        let common = words1.intersection(words2)
        
        if common.count >= 2 || (common.count >= 1 && (words1.count <= 2 || words2.count <= 2)) {
            return true
        }
        
        return false
    }
    
    // MARK: - Actions
    
    func selectAlternative(for entryId: UUID, track: Track) {
        guard let index = parsedEntries.firstIndex(where: { $0.id == entryId }) else { return }
        parsedEntries[index].matchedTrack = track
        parsedEntries[index].alternatives = []
    }
    
    func clear() {
        rawText = ""
        parsedEntries = []
        parseError = nil
    }
}

// MARK: - Import Entry Model

struct ImportEntry: Identifiable {
    let id = UUID()
    let originalText: String
    let parsedArtist: String
    let parsedTitle: String
    var matchedTrack: Track?
    var alternatives: [Track]
}

// MARK: - Import Result Filter

enum ImportResultFilter {
    case all
    case found
    case missing
}
