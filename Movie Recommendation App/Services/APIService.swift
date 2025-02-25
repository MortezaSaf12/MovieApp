//
//  APIService.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation

class APIService {
    static let shared = APIService()
    private let apiKey = "8e6de3cdd4b080b928857481c7062653"
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBaseURL = "https://image.tmdb.org/t/p/original"
    

    func searchMovies(searchTerm: String) async throws -> [MovieSearchItem] {
        guard let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/movie?api_key=\(apiKey)&query=\(encodedSearchTerm)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let searchResponse = try JSONDecoder().decode(MovieSearchResponse.self, from: data)
        
        return searchResponse.results ?? []
    }
    
    func fetchMovieDetails(movieID: Int) async throws -> MovieDetail {
        guard let url = URL(string: "\(baseURL)/movie/\(movieID)?api_key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let movieDetail = try JSONDecoder().decode(MovieDetail.self, from: data)
        return movieDetail
    }
    
    func fullPosterURL(for posterPath: String?) -> URL? {
            guard let posterPath = posterPath else { return nil }
            return URL(string: "\(imageBaseURL)\(posterPath)")
        }
}


/* old code under here:
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
*/
