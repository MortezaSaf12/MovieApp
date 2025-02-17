//
//  Movies.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-17.
//

import Foundation
import SwiftData

@Model
final class Movie {
    var title: String
    var genre: String
    var imdbID: Int // Unique identifier from IMDb
    
    // Link to the User who saved this movie
    var user: User?
    
    init(title: String, genre: String, imdbID: Int) {
        self.title = title
        self.genre = genre
        self.imdbID = imdbID
    }
}
