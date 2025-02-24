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
    var id: Int //var imdbID: String
    var title: String
    var releaseDate: String  // previously year: String
    var posterPath: String  // previously poster: String
    var posterData: Data?

    init(id: Int, title: String, releaseDate: String, posterPath: String, posterData: Data? = nil) { // previously init(imdbID: String, title: String, year: String, poster: String, posterData: Data? = nil) {
        self.id = id // previously self.imdbID = imdbID
        self.title = title
        self.releaseDate = releaseDate //previously self.year = year
        self.posterPath = posterPath // previously self.poster = poster
        self.posterData = posterData
    }
}
