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
            Section(header: Text("Favorite Genres").foregroundColor(ThemeConstants.Colors.secondaryText)) {
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
                            .foregroundColor(ThemeConstants.Colors.text)
                    }
                    .tint(ThemeConstants.Colors.accent)
                    .listRowBackground(ThemeConstants.Colors.cardBackground)
                }
            }
            
            Section(header: Text("Minimum Rating").foregroundColor(ThemeConstants.Colors.secondaryText)) {
                Slider(
                    value: $minRating,
                    in: 0...10,
                    step: 0.5,
                    onEditingChanged: { _ in updatePreferences() }
                )
                .tint(ThemeConstants.Colors.accent)
                .listRowBackground(ThemeConstants.Colors.cardBackground)
                
                Text("Minimum Rating: \(minRating, specifier: "%.1f")")
                    .foregroundColor(ThemeConstants.Colors.text)
                    .listRowBackground(ThemeConstants.Colors.cardBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(ThemeConstants.Colors.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Preferences")
                    .font(.headline)
                    .foregroundColor(ThemeConstants.Colors.text)
            }
        }
        .toolbarBackground(ThemeConstants.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark)
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
