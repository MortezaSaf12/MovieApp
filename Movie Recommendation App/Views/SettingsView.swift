//
//  SettingsView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-03-05.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var userPreferences: [UserPreferences]
    @State private var selectedGenres: Set<String> = []
    @State private var minRating: Double = 5.0
    
    // genres from HomeViewModel
    private let genres = ["Action", "Adventure", "Animation", "Comedy", "Crime",
                         "Documentary", "Drama", "Family", "Fantasy", "History", "Horror",
                         "Music", "Mystery", "Romance", "Sci-Fi", "TV Movie", "Thriller",
                         "War", "Western"]
    
    var body: some View {
        Form {
            Section(header: Text("Favorite Genres")) {
                ForEach(genres, id: \.self) { genre in
                    Toggle(isOn: Binding(
                        get: { selectedGenres.contains(genre) },
                        set: {
                            if $0 {
                                selectedGenres.insert(genre)
                            } else {
                                selectedGenres.remove(genre)
                            }
                            updatePreferences()
                        }
                    )) {
                        Text(genre)
                    }
                }
            }
            
            Section(header: Text("Minimum Rating")) {
                Slider(
                    value: $minRating,
                    in: 0...10,
                    step: 0.5,
                    onEditingChanged: { _ in updatePreferences() }
                )
                Text("Minimum Rating: \(minRating, specifier: "%.1f")")
            }
        }
        
        .navigationTitle("Preferences")
        .onAppear {
            if let prefs = userPreferences.first {
                selectedGenres = Set(prefs.favoriteGenres)
                minRating = prefs.minRating
            }
        }
    }
    
    private func updatePreferences() {
        if let prefs = userPreferences.first {
            prefs.favoriteGenres = Array(selectedGenres)
            prefs.minRating = minRating
            try? context.save()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserPreferences.self, WatchlistMovie.self])
}
