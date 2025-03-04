//
//  MovieSearchItem.swift
//  Movie Recommendation App
//
//  Created by Artin Seyhani Porshekoh on 2025-02-17.
//


struct MovieSearchItem: Decodable, Identifiable {
    let id: Int
    let title: String
    let releaseDate: String
    let posterPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case releaseDate = "release_date"
        case posterPath = "poster_path"
    }
}

struct MovieSearchResponse: Decodable {
    let results: [MovieSearchItem]?
    let totalResults: Int?
    
    enum CodingKeys: String, CodingKey {
        case results
        case totalResults = "total_results"
    }
}
