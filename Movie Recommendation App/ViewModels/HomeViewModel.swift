//
//  HomeViewModel.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
class HomeViewModel {
    var popularMovies: [MovieSearchItem] = []
    var topRated: [MovieSearchItem] = []
    var upcomingMovies: [MovieSearchItem] = []
    var recommendedMovies: [MovieSearchItem] = []
    var watchlistMovies: [WatchlistMovie] = []
    var searchResults: [MovieSearchItem] = []
    var recommendationImages: [Int: Data] = [:]
    
    var isLoading = false
    var errorMessage: String = ""
    var selectedGenre: String = "All"
    
    private var searchTask: Task<Void, Never>?
    private var userPrefs: UserPreferences?
    
    
    let genres = ["All", "Action", "Adventure", "Animation", "Comedy", "Crime",
                  "Documentary", "Drama", "Family", "Fantasy", "History", "Horror",
                  "Music", "Mystery", "Romance", "Sci-Fi", "TV Movie", "Thriller",
                  "War", "Western"]
    
    func fetchAllData(context: ModelContext) async {
        fetchInitialMovies()
        fetchTopRatedMovies()
        fetchUpcomingMovies()
        await fetchRecommendations(context: context)
    }
    
    private func fetchPaginatedData(
        endpoint: @escaping (Int) async throws -> [MovieSearchItem],
        assignTo: @escaping ([MovieSearchItem]) -> Void
    ) {
        Task {
            do {
                let page1 = try await endpoint(1)
                let page2 = try await endpoint(2)
                let page3 = try await endpoint(3)
                
                // Realized that TMDb API sometimes returns same movies in multiple pages, therefore must check results for duplicates
                var seenIDs = Set<Int>()
                let combined = (page1 + page2 + page3)
                    .filter { seenIDs.insert($0.id).inserted }
                
                await MainActor.run {
                    assignTo(combined)
                    isLoading = false
                    errorMessage = ""
                }
            } catch {
                await handleError(error, for: assignTo)
            }
        }
    }
    
    private func handleError(_ error: Error, for handler: @escaping ([MovieSearchItem]) -> Void) async {
        let message = "Failed to fetch data: \(error.localizedDescription)"
        
        await MainActor.run {
            handler([])
            errorMessage = message
            isLoading = false
        }
        print(message)
    }
    
    func fetchInitialMovies() {
        fetchPaginatedData(
            endpoint: APIService.shared.fetchPopularMovies(page:),
            assignTo: { self.popularMovies = $0 }
        )
    }
    
    func fetchTopRatedMovies() {
        fetchPaginatedData(
            endpoint: APIService.shared.fetchTopRatedMovies(page:),
            assignTo: { self.topRated = $0 }
        )
    }
    
    func fetchUpcomingMovies() {
        fetchPaginatedData(
            endpoint: APIService.shared.fetchUpcomingMovies(page:),
            assignTo: { self.upcomingMovies = $0 }
        )
    }
    
    func handleSearch(text: String) {
        guard !text.isEmpty else {
            fetchInitialMovies()
            return
        }
        
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            do {
                // Added 300ms delay to prevent exessive API calls
                try await Task.sleep(nanoseconds: 300_000_000)
                if Task.isCancelled { return }
                await fetchMovies(searchTerm: text)
            } catch {
                print("Search was cancelled or failed: \(error)")
            }
        }
    }
    
    func fetchMovies(searchTerm: String) async {
        isLoading = true
        
        do {
            let results = try await APIService.shared.searchMovies(searchTerm: searchTerm)
            
            if selectedGenre == "All" {
                await MainActor.run {
                    searchResults = results
                    isLoading = false
                    errorMessage = ""
                }
            } else {
                
                let filteredMovies = await filterMoviesByGenre(movies: results, genre: selectedGenre)
                
                await MainActor.run {
                    searchResults = filteredMovies
                    isLoading = false
                    errorMessage = filteredMovies.isEmpty ? "No movies found for selected genre" : ""
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
                searchResults = []
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
        let userPrefs = (try? context.fetch(FetchDescriptor<UserPreferences>()).first) ?? UserPreferences()
        
        let descriptor = FetchDescriptor<WatchlistMovie>()
        do {
            watchlistMovies = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch watchlist: \(error)")
            return
        }
        
        guard !watchlistMovies.isEmpty else {
            recommendedMovies = []
            return
        }
        
        var allSimilar: [MovieSearchItem] = []
        await withTaskGroup(of: [MovieSearchItem].self) { group in
            for movie in watchlistMovies {
                group.addTask {
                    do {
                        return try await APIService.shared.fetchSimilarMovies(movieID: movie.id)
                    } catch {
                        print("Failed to fetch similar for \(movie.id): \(error)")
                        return []
                    }
                }
            }
            for await similarMovies in group {
                allSimilar.append(contentsOf: similarMovies)
            }
        }
        
        // Deduplicate
        let watchlistIDs = Set(watchlistMovies.map { $0.id })
        var seenIDs = Set<Int>()
        let uniqueRecommendations = allSimilar
            .filter { !watchlistIDs.contains($0.id) }
            .filter { seenIDs.insert($0.id).inserted }
        
        // User preference recommendation
        var filteredMovies: [MovieSearchItem] = []
        await withTaskGroup(of: MovieSearchItem?.self) { group in
            for movie in uniqueRecommendations {
                group.addTask { [weak self] in
                    guard self != nil else { return nil }
                    do {
                        let detail = try await APIService.shared.fetchMovieDetails(movieID: movie.id)
                        let meetsRating = detail.voteAverage >= userPrefs.minRating
                        let hasFavoriteGenre = userPrefs.favoriteGenres.isEmpty ||
                        detail.genres.contains { userPrefs.favoriteGenres.contains($0.name) }
                        return (meetsRating && hasFavoriteGenre) ? movie : nil
                    } catch {
                        return nil
                    }
                }
            }
            for await result in group {
                if let validMovie = result {
                    filteredMovies.append(validMovie)
                }
            }
        }
        
        recommendedMovies = Array(uniqueRecommendations.prefix(20))
        
        await withTaskGroup(of: (Int, Data?).self) { group in
            for movie in recommendedMovies {
                if let url = APIService.shared.fullPosterURL(for: movie.posterPath) {
                    group.addTask {
                        do {
                            let data = try await APIService.shared.fetchImageData(from: url)
                            return (movie.id, data)
                        } catch {
                            print("Error fetching image for movie id \(movie.id): \(error)")
                            return (movie.id, nil)
                        }
                    }
                }
            }
            for await (movieId, data) in group {
                if let data = data {
                    recommendationImages[movieId] = data
                }
            }
        }
    }
}
