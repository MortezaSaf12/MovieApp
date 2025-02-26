//
//  HomeViewModel.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import SwiftUI
import Observation

@Observable
class HomeViewModel {
    var movies: [MovieSearchItem] = []
    var isLoading = false
    var errorMessage: String = ""
    private var searchTask: Task<Void, Never>?
    
    var selectedGenre: String = "All"
    let genres = ["All", "Action", "Adventure", "Animation", "Comedy", "Crime", "Documentary", "Drama", "Family", "Fantasy", "History", "Horror", "Music", "Mystery", "Romance", "Sci-Fi", "TV Movie", "Thriller", "War", "Western"]
    
    func fetchInitialMovies() {
        Task {
            do {
                let results = try await APIService.shared.fetchPopularMovies()
                await MainActor.run {
                    movies = results
                    isLoading = false
                    errorMessage = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    movies = []
                }
            }
        }
    }
    
    func handleSearch(text: String) {
        guard !text.isEmpty else {
            movies = []
            return
        }
        
        searchTask?.cancel()
        searchTask = Task {
            guard !Task.isCancelled else { return }
            await fetchMovies(searchTerm: text)
        }
    }
    
    func fetchMovies(searchTerm: String) async {
        isLoading = true
        
        do {
            let results = try await APIService.shared.searchMovies(searchTerm: searchTerm)
            
            if selectedGenre == "All" {
                await MainActor.run {
                    movies = results
                    isLoading = false
                    errorMessage = ""
                }
            } else {
                
                let filteredMovies = await filterMoviesByGenre(movies: results, genre: selectedGenre)
                
                await MainActor.run {
                    movies = filteredMovies
                    isLoading = false
                    errorMessage = filteredMovies.isEmpty ? "No movies found for selected genre" : ""
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
                movies = []
            }
        }
    }
    
    private func filterMoviesByGenre(movies: [MovieSearchItem], genre: String) async -> [MovieSearchItem] {
        var filteredResults: [MovieSearchItem] = []
        
        for movie in movies {
            if let movieDetail = try? await APIService.shared.fetchMovieDetails(movieID: movie.id),
               movieDetail.genres.contains(where: { $0.name == genre }) {
                filteredResults.append(movie)
            }
        }
        
        return filteredResults
    }
}
