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
    private var _favoriteGenresData: Data?
    private var _prioritizedGenresData: Data?
    var minRating: Double
    
    @Relationship(deleteRule: .nullify) var watchlist: [WatchlistMovie]?
    
    //
    var favoriteGenres: [String] {
        get {
            guard let data = _favoriteGenresData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            _favoriteGenresData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var prioritizedGenres: [String] {
        get {
            guard let data = _prioritizedGenresData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            let limited = Array(newValue.prefix(3))
            _prioritizedGenresData = try? JSONEncoder().encode(limited)
        }
    }
    
    init(favoriteGenres: [String] = [], prioritizedGenres: [String] = [], minRating: Double = 5.0) {
        self._favoriteGenresData = try? JSONEncoder().encode(favoriteGenres)
        self._prioritizedGenresData = try? JSONEncoder().encode(prioritizedGenres)
        self.minRating = minRating
    }
}
