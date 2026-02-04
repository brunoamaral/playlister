import SwiftUI
import UniformTypeIdentifiers

// MARK: - Import Playlist View

/// View for importing playlists from text files, CSV, or direct text input
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
            allowedContentTypes: [.plainText, .commaSeparatedText],
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
            
            Text("Supported formats:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• **CSV**: With columns \"Artist(s) Name\" and \"Track Name\" (Spotify/Spotlistr export)")
                Text("• **Text**: One song per line as **Artist - Song Title**")
            }
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
                
                HStack(spacing: 8) {
                    Label("\(importViewModel.matchedCount)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    if importViewModel.needsSelectionCount > 0 {
                        Label("\(importViewModel.needsSelectionCount)", systemImage: "questionmark.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    if importViewModel.missingCount > 0 {
                        Label("\(importViewModel.missingCount)", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
                .font(.subheadline)
            }
            
            // Warning if selections needed
            if importViewModel.needsSelectionCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Please select a version for \(importViewModel.needsSelectionCount) track(s) before creating the playlist")
                        .font(.caption)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Filter tabs
            Picker("Filter", selection: $importViewModel.resultFilter) {
                Text("All (\(importViewModel.parsedEntries.count))").tag(ImportResultFilter.all)
                Text("Ready (\(importViewModel.matchedCount))").tag(ImportResultFilter.found)
                if importViewModel.needsSelectionCount > 0 {
                    Text("Select (\(importViewModel.needsSelectionCount))").tag(ImportResultFilter.needsSelection)
                }
                if importViewModel.missingCount > 0 {
                    Text("Missing (\(importViewModel.missingCount))").tag(ImportResultFilter.missing)
                }
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
        
        // Dismiss immediately so user sees the playlist being populated
        dismiss()
        
        do {
            try await playlistViewModel.createPlaylist(
                name: importViewModel.playlistName,
                tracks: tracks
            )
        } catch {
            // Error will be shown via playlistViewModel.showErrorAlert
            print("Failed to create playlist: \(error.localizedDescription)")
        }
        
        importViewModel.isCreating = false
    }
}

// MARK: - Import Entry Row

struct ImportEntryRow: View {
    let entry: ImportEntry
    let onSelectAlternative: (Track) -> Void
    
    @State private var isExpanded = false
    
    /// Determine if this entry needs user selection (multiple versions found)
    private var needsSelection: Bool {
        entry.matchedTrack == nil && !entry.alternatives.isEmpty
    }
    
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
                        HStack(spacing: 4) {
                            Text("→ \(track.artistName) - \(track.title)")
                            if !track.albumName.isEmpty {
                                Text("(\(track.albumName))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                    } else if !entry.alternatives.isEmpty {
                        Text("Multiple versions found - please select one ↓")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    } else {
                        Text("Not found in library")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Spacer()
                
                // Expand button for alternatives (auto-expanded if needs selection)
                if needsSelection {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            // Alternatives - auto-expand when selection is needed
            if (isExpanded || needsSelection) && entry.matchedTrack == nil && !entry.alternatives.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select the version you want:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(entry.alternatives) { track in
                        Button {
                            onSelectAlternative(track)
                        } label: {
                            HStack {
                                Image(systemName: "music.note")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(track.artistName) - \(track.title)")
                                        .font(.caption)
                                    if !track.albumName.isEmpty {
                                        Text(track.albumName)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.leading, 28)
            }
        }
        .padding(12)
        .background(needsSelection ? Color.orange.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(needsSelection ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1)
        )
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
    
    var needsSelectionCount: Int {
        parsedEntries.filter { $0.matchedTrack == nil && !$0.alternatives.isEmpty }.count
    }
    
    var missingCount: Int {
        parsedEntries.filter { $0.matchedTrack == nil && $0.alternatives.isEmpty }.count
    }
    
    var canCreatePlaylist: Bool {
        !playlistName.isEmpty && matchedCount > 0 && needsSelectionCount == 0
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
        case .needsSelection:
            return parsedEntries.filter { $0.matchedTrack == nil && !$0.alternatives.isEmpty }
        case .missing:
            return parsedEntries.filter { $0.matchedTrack == nil && $0.alternatives.isEmpty }
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
        
        // Detect format and parse
        let parsedLines = parseInput(rawText)
        
        guard !parsedLines.isEmpty else {
            parseError = "No songs found in the input"
            isSearching = false
            return
        }
        
        var entries: [ImportEntry] = []
        
        for (artist, title) in parsedLines {
            // Search for the track
            let (matchedTrack, alternatives) = await searchTrack(artist: artist, title: title)
            
            let displayText = artist.isEmpty ? title : "\(artist) - \(title)"
            let entry = ImportEntry(
                originalText: displayText,
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
    
    // MARK: - Input Parsing
    
    /// Detect and parse input format (CSV or plain text)
    private func parseInput(_ text: String) -> [(artist: String, title: String)] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else { return [] }
        
        // Check if it's CSV format (has header with Artist and Track columns)
        // Also handle common typo "Arist" instead of "Artist" (Spotlistr export)
        let firstLine = lines[0].lowercased()
        let hasArtistColumn = firstLine.contains("artist") || firstLine.contains("arist")
        let hasTrackColumn = firstLine.contains("track") || firstLine.contains("title") || firstLine.contains("song")
        
        // Also detect CSV by checking if first line contains comma and looks like a header
        let looksLikeCSVHeader = firstLine.contains(",") && hasTrackColumn
        
        if (hasArtistColumn && hasTrackColumn) || looksLikeCSVHeader {
            return parseCSV(lines)
        }
        
        // Otherwise, parse as plain text (Artist - Title format)
        return parsePlainText(lines)
    }
    
    /// Parse CSV format (Spotify/Spotlistr export)
    private func parseCSV(_ lines: [String]) -> [(artist: String, title: String)] {
        guard lines.count > 1 else { return [] }
        
        // Parse header to find column indices
        let header = parseCSVLine(lines[0])
        let headerLower = header.map { $0.lowercased() }
        
        // Find artist column (could be "Artist(s) Name", "Artist", "Artists", "Arist" (typo), etc.)
        let artistIndex = headerLower.firstIndex { col in
            col.contains("artist") || col.contains("arist")
        }
        
        // Find track column (could be "Track Name", "Track", "Title", "Song", etc.)
        let trackIndex = headerLower.firstIndex { col in
            col.contains("track") || col.contains("title") || col.contains("song")
        }
        
        // If we can't find specific columns, check if we have exactly 2 columns
        if artistIndex == nil || trackIndex == nil || artistIndex == trackIndex {
            if header.count >= 2 {
                // Assume first column is artist, second is track
                return parseCSVWithIndices(lines, artistIndex: 0, trackIndex: 1)
            }
            return []
        }
        
        return parseCSVWithIndices(lines, artistIndex: artistIndex!, trackIndex: trackIndex!)
    }
    
    private func parseCSVWithIndices(_ lines: [String], artistIndex: Int, trackIndex: Int) -> [(artist: String, title: String)] {
        var results: [(String, String)] = []
        
        // Skip header, process data rows
        for line in lines.dropFirst() {
            let columns = parseCSVLine(line)
            
            guard columns.count > max(artistIndex, trackIndex) else { continue }
            
            var artist = columns[artistIndex].trimmingCharacters(in: .whitespaces)
            let title = columns[trackIndex].trimmingCharacters(in: .whitespaces)
            
            guard !title.isEmpty else { continue }
            
            // Handle multiple artists separated by semicolons (Spotify format)
            // e.g., "Carla Gugino; Oscar Isaac" -> use first artist
            if artist.contains(";") {
                artist = artist.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespaces) ?? artist
            }
            
            results.append((artist, title))
        }
        
        return results
    }
    
    /// Parse a single CSV line, handling quoted fields
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // Add the last field
        fields.append(currentField.trimmingCharacters(in: .whitespaces))
        
        return fields
    }
    
    /// Parse plain text format (Artist - Title per line)
    private func parsePlainText(_ lines: [String]) -> [(artist: String, title: String)] {
        var results: [(String, String)] = []
        
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
            
            if !title.isEmpty {
                results.append((artist, title))
            }
        }
        
        return results
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
            
            // If we have exactly ONE exact match, auto-select it
            if exactMatches.count == 1 {
                return (exactMatches.first, [])
            }
            
            // If we have MULTIPLE exact matches, user must pick
            if exactMatches.count > 1 {
                // Sort by album to group versions, then return all as alternatives
                let sorted = exactMatches.sorted { ($0.albumName, $0.title) < ($1.albumName, $1.title) }
                return (nil, sorted)
            }
            
            // If we have partial matches, user must pick (could be different versions, remixes, etc.)
            if !partialMatches.isEmpty {
                let sorted = partialMatches.sorted { $0.title.count < $1.title.count }
                return (nil, Array(sorted.prefix(10)))
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
        // Create a new entry with the selected track to ensure SwiftUI detects the change
        var updatedEntry = parsedEntries[index]
        updatedEntry.matchedTrack = track
        updatedEntry.alternatives = []
        parsedEntries[index] = updatedEntry
        
        // Force objectWillChange to ensure UI updates
        objectWillChange.send()
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
    case needsSelection
    case missing
}
