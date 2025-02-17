//
//  DataModels.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import SwiftData

struct FetchOMDbData: Decodable {
    let title: String
    let genre: String
    let imdbRating: String
    let released: String
    let description: String
    let runtime: String
    let posterURL: String
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case genre = "Genre"
        case imdbRating = "imdbRating"
        case released = "Released"
        case description = "Plot"
        case runtime = "Runtime"
        case posterURL = "Poster"
    }
}
