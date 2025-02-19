//
//  Movies.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-17.
//

import Foundation
import SwiftData

@Model
final class WatchlistMovie {
    var imdbID: String
    var title: String
    var year: String
    var poster: String
    
    init(imdbID: String, title: String, year: String, poster: String) {
        self.imdbID = imdbID
        self.title = title
        self.year = year
        self.poster = poster
    }
}
