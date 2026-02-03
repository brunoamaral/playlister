import SwiftUI

// MARK: - Smart Playlist View

/// Interface for creating and editing smart playlists (rule-based)
struct SmartPlaylistView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PlaylistViewModel
    
    // Editing existing playlist
    let existingPlaylist: Playlist?
    
    @State private var playlistName: String = ""
    @State private var rules: [SmartPlaylistRule] = [SmartPlaylistRule()]
    @State private var matchType: MatchType = .all
    @State private var limitEnabled: Bool = false
    @State private var limitCount: Int = 25
    @State private var limitType: LimitType = .tracks
    @State private var sortBy: SortOption = .random
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
    // MARK: - Initialization
    
    init(viewModel: PlaylistViewModel, existingPlaylist: Playlist? = nil) {
        self.viewModel = viewModel
        self.existingPlaylist = existingPlaylist
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
                    // Match type
                    matchTypeSection
                    
                    // Rules
                    rulesSection
                    
                    // Limit
                    limitSection
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(errorMessage)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 650, height: 550)
        .onAppear {
            loadExistingPlaylist()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Image(systemName: "wand.and.stars")
                .font(.title2)
                .foregroundStyle(.purple)
            
            TextField("Smart Playlist Name", text: $playlistName)
                .textFieldStyle(.plain)
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Match Type
    
    private var matchTypeSection: some View {
        HStack {
            Text("Match")
            Picker("", selection: $matchType) {
                Text("all").tag(MatchType.all)
                Text("any").tag(MatchType.any)
            }
            .labelsHidden()
            .frame(width: 80)
            
            Text("of the following rules:")
        }
    }
    
    // MARK: - Rules
    
    private var rulesSection: some View {
        VStack(spacing: 8) {
            ForEach($rules) { $rule in
                SmartPlaylistRuleRow(rule: $rule) {
                    if rules.count > 1 {
                        rules.removeAll { $0.id == rule.id }
                    }
                }
            }
            
            Button {
                rules.append(SmartPlaylistRule())
            } label: {
                Label("Add Rule", systemImage: "plus.circle")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }
    
    // MARK: - Limit
    
    private var limitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Limit to", isOn: $limitEnabled)
            
            if limitEnabled {
                HStack {
                    TextField("", value: $limitCount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    
                    Picker("", selection: $limitType) {
                        Text("tracks").tag(LimitType.tracks)
                        Text("minutes").tag(LimitType.minutes)
                        Text("hours").tag(LimitType.hours)
                        Text("GB").tag(LimitType.gigabytes)
                    }
                    .labelsHidden()
                    .frame(width: 100)
                    
                    Text("selected by")
                    
                    Picker("", selection: $sortBy) {
                        Text("random").tag(SortOption.random)
                        Text("most played").tag(SortOption.mostPlayed)
                        Text("least played").tag(SortOption.leastPlayed)
                        Text("most recently added").tag(SortOption.recentlyAdded)
                        Text("highest rated").tag(SortOption.highestRated)
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }
                .padding(.leading, 20)
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
            
            if isSaving {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.horizontal)
            }
            
            Button(existingPlaylist != nil ? "Update Smart Playlist" : "Create Smart Playlist") {
                saveSmartPlaylist()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(playlistName.isEmpty || rules.isEmpty || isSaving)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func loadExistingPlaylist() {
        guard let playlist = existingPlaylist else { return }
        playlistName = playlist.title
        // Note: Plex doesn't expose smart playlist rules via API
        // Users will need to recreate the rules when editing
    }
    
    private func saveSmartPlaylist() {
        isSaving = true
        errorMessage = nil
        
        let filterString = buildFilterString()
        
        Task {
            do {
                if let existing = existingPlaylist {
                    // Update existing smart playlist
                    try await viewModel.updateSmartPlaylist(
                        playlistId: existing.id,
                        title: playlistName,
                        filter: filterString,
                        limit: limitEnabled ? limitCount : nil,
                        sort: sortBy
                    )
                } else {
                    // Create new smart playlist
                    try await viewModel.createSmartPlaylist(
                        title: playlistName,
                        filter: filterString,
                        limit: limitEnabled ? limitCount : nil,
                        sort: sortBy
                    )
                }
                await viewModel.fetchPlaylists()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
    
    /// Build the filter string for Plex API
    /// Format: field1=value1&field2=value2 (all rules joined with &)
    /// For "any" match type, we add push=1&or=1 parameters
    private func buildFilterString() -> String {
        var filterParts: [String] = []
        
        // Add match type parameters for "any" (OR) matching
        if matchType == .any && rules.count > 1 {
            filterParts.append("push=1")
            filterParts.append("or=1")
        }
        
        for rule in rules {
            guard !rule.value.isEmpty else { continue }
            
            let field = rule.field.plexKey
            let comparison = rule.comparison.plexOperator
            
            // Format value based on field type
            var formattedValue = rule.value
            
            // For date fields, convert to relative format (e.g., "30" days -> "-30d")
            if rule.field.fieldType == .date {
                // Plex uses negative values for "in the last X days"
                formattedValue = "-\(rule.value)d"
            }
            
            // For rating field, Plex uses 0-10 scale (multiply by 2 if user enters 1-5)
            if rule.field == .rating {
                if let rating = Int(rule.value), rating <= 5 {
                    formattedValue = "\(rating * 2)"
                }
            }
            
            // URL encode the value
            let encodedValue = formattedValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? formattedValue
            
            filterParts.append("\(field)\(comparison)\(encodedValue)")
        }
        
        // Close the OR group if we opened one
        if matchType == .any && rules.count > 1 {
            filterParts.append("pop=1")
        }
        
        return filterParts.joined(separator: "&")
    }
}

// MARK: - Rule Row

struct SmartPlaylistRuleRow: View {
    @Binding var rule: SmartPlaylistRule
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Picker("", selection: $rule.field) {
                Text("Artist").tag(RuleField.artist)
                Text("Album").tag(RuleField.album)
                Text("Track Title").tag(RuleField.title)
                Text("Genre").tag(RuleField.genre)
                Text("Year").tag(RuleField.year)
                Text("Rating").tag(RuleField.rating)
                Text("Play Count").tag(RuleField.playCount)
                Text("Date Added").tag(RuleField.dateAdded)
                Text("Last Played").tag(RuleField.lastPlayed)
            }
            .labelsHidden()
            .frame(width: 120)
            .onChange(of: rule.field) { _, newField in
                // Reset to first valid comparison when field changes
                rule.comparison = newField.availableComparisons.first ?? .contains
            }
            
            Picker("", selection: $rule.comparison) {
                ForEach(rule.field.availableComparisons, id: \.self) { comparison in
                    Text(comparison.displayName).tag(comparison)
                }
            }
            .labelsHidden()
            .frame(width: 140)
            
            // Value input (different types based on field)
            valueInput
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.8))
            }
            .buttonStyle(.borderless)
        }
    }
    
    @ViewBuilder
    private var valueInput: some View {
        switch rule.field {
        case .rating:
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: Int(rule.value) ?? 0 >= star ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                        .onTapGesture {
                            rule.value = "\(star)"
                        }
                }
            }
            .frame(minWidth: 100)
        case .year:
            TextField("Year", text: $rule.value)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
        case .playCount:
            TextField("Count", text: $rule.value)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
        case .dateAdded, .lastPlayed:
            HStack {
                TextField("Days", text: $rule.value)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("days")
                    .foregroundStyle(.secondary)
            }
        default:
            TextField("Value", text: $rule.value)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Supporting Types

struct SmartPlaylistRule: Identifiable {
    let id = UUID()
    var field: RuleField = .artist
    var comparison: RuleComparison = .contains
    var value: String = ""
}

enum RuleField: String, CaseIterable {
    case artist, album, title, genre, year, rating, playCount, dateAdded, lastPlayed
    
    var plexKey: String {
        switch self {
        case .artist: return "artist.title"
        case .album: return "album.title"
        case .title: return "title"
        case .genre: return "genre"
        case .year: return "year"
        case .rating: return "userRating"
        case .playCount: return "viewCount"
        case .dateAdded: return "addedAt"
        case .lastPlayed: return "lastViewedAt"
        }
    }
    
    var fieldType: FieldType {
        switch self {
        case .artist, .album, .title, .genre:
            return .string
        case .year, .rating, .playCount:
            return .integer
        case .dateAdded, .lastPlayed:
            return .date
        }
    }
    
    var availableComparisons: [RuleComparison] {
        switch fieldType {
        case .string:
            return [.contains, .doesNotContain, .exactMatch, .doesNotExactMatch, .beginsWith, .endsWith]
        case .integer:
            return [.equals, .notEquals, .greaterThanOrEqual, .lessThanOrEqual]
        case .date:
            return [.inTheLast, .notInTheLast]
        }
    }
}

enum FieldType {
    case string, integer, date
}

enum RuleComparison: String, CaseIterable {
    // String comparisons (per Plex API docs)
    case contains           // = (contains substring)
    case doesNotContain     // != (does not contain)
    case exactMatch         // == (exact match)
    case doesNotExactMatch  // !== (does not exact match)
    case beginsWith         // <= (begins with)
    case endsWith           // >= (ends with)
    
    // Integer comparisons (per Plex API docs)
    case equals             // = (equals)
    case notEquals          // != (not equals)
    case greaterThanOrEqual // >>= (greater than or equal)
    case lessThanOrEqual    // <<= (less than or equal)
    
    // Date comparisons (use relative values like 30d, 4w)
    case inTheLast          // >>= with relative date
    case notInTheLast       // <<= with relative date
    
    var displayName: String {
        switch self {
        case .contains: return "contains"
        case .doesNotContain: return "does not contain"
        case .exactMatch: return "is exactly"
        case .doesNotExactMatch: return "is not exactly"
        case .beginsWith: return "begins with"
        case .endsWith: return "ends with"
        case .equals: return "is"
        case .notEquals: return "is not"
        case .greaterThanOrEqual: return "is greater than or equal to"
        case .lessThanOrEqual: return "is less than or equal to"
        case .inTheLast: return "is in the last"
        case .notInTheLast: return "is not in the last"
        }
    }
    
    var plexOperator: String {
        switch self {
        // String operators per Plex API
        case .contains: return "="
        case .doesNotContain: return "!="
        case .exactMatch: return "=="
        case .doesNotExactMatch: return "!=="
        case .beginsWith: return "<="
        case .endsWith: return ">="
        // Integer operators per Plex API
        case .equals: return "="
        case .notEquals: return "!="
        case .greaterThanOrEqual: return ">>="
        case .lessThanOrEqual: return "<<="
        // Date operators (use integer operators with relative values)
        case .inTheLast: return ">>="
        case .notInTheLast: return "<<="
        }
    }
}

enum MatchType: String {
    case all, any
}

enum LimitType: String {
    case tracks, minutes, hours, gigabytes
}

enum SortOption: String {
    case random, mostPlayed, leastPlayed, recentlyAdded, highestRated
    
    var plexSort: String {
        switch self {
        case .random: return "random"
        case .mostPlayed: return "viewCount:desc"
        case .leastPlayed: return "viewCount:asc"
        case .recentlyAdded: return "addedAt:desc"
        case .highestRated: return "userRating:desc"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SmartPlaylistView(viewModel: PlaylistViewModel())
}
#endif
