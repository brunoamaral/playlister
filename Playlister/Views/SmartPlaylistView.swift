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
    private func buildFilterString() -> String {
        let operator_ = matchType == .all ? "&" : "|"
        
        let filterParts = rules.compactMap { rule -> String? in
            guard !rule.value.isEmpty else { return nil }
            
            let field = rule.field.plexKey
            let comparison = rule.comparison.plexOperator
            let value = rule.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? rule.value
            
            return "\(field)\(comparison)\(value)"
        }
        
        return filterParts.joined(separator: operator_)
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
    
    var availableComparisons: [RuleComparison] {
        switch self {
        case .artist, .album, .title, .genre:
            return [.contains, .doesNotContain, .equals, .startsWith, .endsWith]
        case .year, .rating, .playCount:
            return [.equals, .lessThan, .greaterThan, .inRange]
        case .dateAdded, .lastPlayed:
            return [.inTheLast, .notInTheLast, .before, .after]
        }
    }
}

enum RuleComparison: String, CaseIterable {
    case contains, doesNotContain, equals, startsWith, endsWith
    case lessThan, greaterThan, inRange
    case inTheLast, notInTheLast, before, after
    
    var displayName: String {
        switch self {
        case .contains: return "contains"
        case .doesNotContain: return "does not contain"
        case .equals: return "is"
        case .startsWith: return "starts with"
        case .endsWith: return "ends with"
        case .lessThan: return "is less than"
        case .greaterThan: return "is greater than"
        case .inRange: return "is in the range"
        case .inTheLast: return "is in the last"
        case .notInTheLast: return "is not in the last"
        case .before: return "is before"
        case .after: return "is after"
        }
    }
    
    var plexOperator: String {
        switch self {
        case .contains: return "~="
        case .doesNotContain: return "!~="
        case .equals: return "="
        case .startsWith: return "^="
        case .endsWith: return "$="
        case .lessThan: return "<"
        case .greaterThan: return ">"
        case .inRange: return "><"
        case .inTheLast: return ">>="
        case .notInTheLast: return "<<="
        case .before: return "<"
        case .after: return ">"
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
