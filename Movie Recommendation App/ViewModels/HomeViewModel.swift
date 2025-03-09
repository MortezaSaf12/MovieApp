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
    
    // Mapping from genre names to TMDb genre IDs
    let genreMapping: [String: Int] = [
        "Action": 28,
        "Adventure": 12,
        "Animation": 16,
        "Comedy": 35,
        "Crime": 80,
        "Documentary": 99,
        "Drama": 18,
        "Family": 10751,
        "Fantasy": 14,
        "History": 36,
        "Horror": 27,
        "Music": 10402,
        "Mystery": 9648,
        "Romance": 10749,
        "Sci-Fi": 878,
        "TV Movie": 10770,
        "Thriller": 53,
        "War": 10752,
        "Western": 37
    ]
    
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
        let fetchedUserPrefs = try? context.fetch(FetchDescriptor<UserPreferences>()).first
        let userPreferences = fetchedUserPrefs ?? UserPreferences()
        self.userPrefs = userPreferences
        
        let descriptor = FetchDescriptor<WatchlistMovie>()
        do {
            watchlistMovies = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch watchlist: \(error)")
            return
        }
        
        var genreFrequency: [Int: Int] = [:]
        if watchlistMovies.isEmpty {
            for favorite in userPreferences.favoriteGenres {
                if let genreId = genreMapping[favorite] {
                    genreFrequency[genreId, default: 0] += 2
                }
            }
        } else {
            await withTaskGroup(of: MovieDetail?.self) { group in
                for movie in watchlistMovies {
                    group.addTask {
                        try? await APIService.shared.fetchMovieDetails(movieID: movie.id)
                    }
                }
                for await detail in group {
                    if let detail = detail {
                        for genre in detail.genres {
                            genreFrequency[genre.id, default: 0] += 1
                        }
                    }
                }
            }
            for favorite in userPreferences.favoriteGenres {
                if let genreId = genreMapping[favorite] {
                    genreFrequency[genreId, default: 0] += 2
                }
            }
        }
        
        let topGenres = genreFrequency.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        guard !topGenres.isEmpty else {
            recommendedMovies = []
            return
        }
        
        var discoveredMovies: [MovieSearchItem] = []
        do {
            discoveredMovies = try await APIService.shared.fetchMoviesByGenres(
                genreIDs: topGenres,
                minRating: userPreferences.minRating
            )
        } catch {
            print("Error fetching discovered movies: \(error)")
        }
        
        let bookmarkedIDs = Set(watchlistMovies.map { $0.id })
        discoveredMovies = discoveredMovies.filter { !bookmarkedIDs.contains($0.id) }
        
        /* Filter movies based on user preferences and calculate bonus score.
         Added complexity to the business logic: If a user has a movie in bookmarks that matches on of their preferred genre(s), give an extra bonus for that. */
        var scoredMovies: [(movie: MovieSearchItem, score: Int)] = []
        await withTaskGroup(of: (MovieSearchItem, Int)?.self) { group in
            for movie in discoveredMovies {
                group.addTask { [weak self] in
                    guard self != nil else { return nil }
                    do {
                        let detail = try await APIService.shared.fetchMovieDetails(movieID: movie.id)
                        let meetsRating = detail.voteAverage >= userPreferences.minRating
                        let matchingFavoriteGenres = detail.genres.filter { userPreferences.favoriteGenres.contains($0.name) }
                        let hasFavoriteGenre = !matchingFavoriteGenres.isEmpty
                        let bonusScore = matchingFavoriteGenres.count > 1 ? matchingFavoriteGenres.count - 1 : 0
                        if meetsRating && (hasFavoriteGenre || userPreferences.favoriteGenres.isEmpty) {
                            return (movie, bonusScore)
                        } else {
                            return nil
                        }
                    } catch {
                        return nil
                    }
                }
            }
            
            for await result in group {
                if let (movie, score) = result {
                    scoredMovies.append((movie, score))
                }
            }
        }
        
        scoredMovies.sort { $0.score > $1.score }
        recommendedMovies = scoredMovies.prefix(20).map { $0.movie }
        
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
