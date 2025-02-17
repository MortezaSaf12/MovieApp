//
//  Movies.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-17.
//

import Foundation
import SwiftData


// Movie Entity
@Model
final class Movie {
    var title: String
    var genre: String
    var tmdbID: Int // Unique identifier from OMDP
    
    // Link to the User who saved this movie
    var user: User?
    
    init(title: String, genre: String, tmdbID: Int) {
        self.title = title
        self.genre = genre
        self.tmdbID = tmdbID
    }
}
