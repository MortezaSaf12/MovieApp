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
    var id: Int
    var title: String
    var releaseDate: String
    var posterPath: String
    var posterData: Data?
    
    @Relationship(inverse: \UserPreferences.watchlist) var user: UserPreferences?

    init(id: Int, title: String, releaseDate: String, posterPath: String, posterData: Data? = nil) {
        self.id = id
        self.title = title
        self.releaseDate = releaseDate
        self.posterPath = posterPath
        self.posterData = posterData
    }
}
