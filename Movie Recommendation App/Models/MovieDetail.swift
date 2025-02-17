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
    let genre: String
    let imdbRating: String
    let released: String
    let plot: String
    let runtime: String
    let poster: String
    let imdbID: String
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case genre = "Genre"
        case imdbRating = "imdbRating"
        case released = "Released"
        case plot = "Plot"
        case runtime = "Runtime"
        case poster = "Poster"
        case imdbID = "imdbID"
    }
}
