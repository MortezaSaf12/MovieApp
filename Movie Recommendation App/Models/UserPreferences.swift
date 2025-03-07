//
//  UserPreferencesViewModel.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-03-05.
//

import Foundation
import SwiftData

@Model
class UserPreferences {
    var favoriteGenres: [String]
    var minRating: Double
    
    // The users relationship to Watchlist, 1 user <-> Many movies
    @Relationship(deleteRule: .nullify) var watchlist: [WatchlistMovie]?
    
    init(favoriteGenres: [String] = [], minRating: Double = 5.0) {
        self.favoriteGenres = favoriteGenres
        self.minRating = minRating
    }
}
