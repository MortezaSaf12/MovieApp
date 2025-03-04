//
//  HomeViewModel.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import SwiftUI
import Observation
import SwiftData

@Observable
class HomeViewModel {
    var movies: [MovieSearchItem] = []
    var recommendations: [MovieSearchItem] = []
    var isLoading = false
    var errorMessage: String = ""
    var selectedGenre: String = "All"
    
    private var searchTask: Task<Void, Never>?
    private var watchlistMovies: [WatchlistMovie] = []
    
    let genres = ["All", "Action", "Adventure", "Animation", "Comedy", "Crime",
                  "Documentary", "Drama", "Family", "Fantasy", "History", "Horror",
                  "Music", "Mystery", "Romance", "Sci-Fi", "TV Movie", "Thriller",
                  "War", "Western"]
    
    func fetchInitialMovies() {
        Task {
            do {
                let page1 = try await APIService.shared.fetchPopularMovies(page: 1)
                let page2 = try await APIService.shared.fetchPopularMovies(page: 2)
                let combinedResults = page1 + page2
                
                await MainActor.run {
                    movies = combinedResults
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
            fetchInitialMovies()
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
    
    @MainActor
    func fetchRecommendations(context: ModelContext) async {
        
        let descriptor = FetchDescriptor<WatchlistMovie>()
        do {
            watchlistMovies = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch watchlist: \(error)")
            return
        }
        
        guard !watchlistMovies.isEmpty else {
            await MainActor.run { recommendations = [] }
            return
        }
        
        var allSimilar: [MovieSearchItem] = []
        
        for movie in watchlistMovies {
            do {
                let similar = try await APIService.shared.fetchSimilarMovies(movieID: movie.id)
                allSimilar.append(contentsOf: similar)
            } catch {
                print("Failed to fetch similar for \(movie.id): \(error)")
            }
        }
        
        // Check for duplicates and excldue movies that are already in Bookmark
        let watchlistIDs = Set(watchlistMovies.map { $0.id })
        var seenIDs = Set<Int>()
        
        let uniqueRecommendations = allSimilar
            .filter { !watchlistIDs.contains($0.id) }
            .filter { seenIDs.insert($0.id).inserted }
        
        await MainActor.run {
            recommendations = Array(uniqueRecommendations.prefix(20))
        }
    }
}
