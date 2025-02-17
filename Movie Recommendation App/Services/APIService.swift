//
//  APIService.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation


class APIService {
    static let shared = APIService()
    private let apiKey = "df341e38"
    private let baseURL = "https://www.omdbapi.com/"
    
    func searchMovies(searchTerm: String) async throws -> [MovieSearchItem] {
        guard let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?apikey=\(apiKey)&s=\(encodedSearchTerm)&type=movie") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let searchResponse = try JSONDecoder().decode(MovieSearchResponse.self, from: data)
        
        return searchResponse.search ?? []
    }
    
    func fetchMovieDetails(imdbID: String) async throws -> MovieDetail {
        guard let url = URL(string: "\(baseURL)?apikey=\(apiKey)&i=\(imdbID)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let movieDetail = try JSONDecoder().decode(MovieDetail.self, from: data)
        return movieDetail
    }
}

