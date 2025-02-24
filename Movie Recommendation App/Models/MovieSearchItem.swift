//
//  MovieSearchItem.swift
//  Movie Recommendation App
//
//  Created by Artin Seyhani Porshekoh on 2025-02-17.
//


struct MovieSearchItem: Decodable {
    let title: String
    let releaseDate: String
    let id: Int
    let posterPath: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case releaseDate = "release_date"
        case id
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



/*
// "?s=<searchTerm>" ((retrieves partial data))
struct MovieSearchItem: Decodable {
    let title: String
    let year: String
    let imdbID: String
    let type: String?
    let poster: String
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case year = "Year"
        case imdbID = "imdbID"
        case type = "Type"
        case poster = "Poster"
    }
}

// Array of movies, each with the above properties
struct MovieSearchResponse: Decodable {
    let search: [MovieSearchItem]?
    let totalResults: String?
    let response: String?
    
    // Map "Search" -> search, "Response" -> response
    enum CodingKeys: String, CodingKey {
        case search = "Search"
        case totalResults
        case response = "Response"
    }
}
*/

