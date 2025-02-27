//
//  MovieDetail.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import SwiftData

struct MovieDetail: Decodable {
    let title: String
    let releaseDate: String
    let genres: [Genre]
    let voteAverage: Double
    let overview: String
    let runtime: Int
    let posterPath: String?
    let id: Int
    
    enum CodingKeys: String, CodingKey {
        case title
        case releaseDate = "release_date"
        case genres
        case voteAverage = "vote_average"
        case overview
        case runtime
        case posterPath = "poster_path"
        case id
    }
    
    struct Genre: Decodable, Identifiable {
        let id: Int
        let name: String
    }
}
