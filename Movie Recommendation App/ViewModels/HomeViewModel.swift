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
            searchResults = []
            return
        }
        
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            do {
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
    
    func filterMoviesByGenre(movies: [MovieSearchItem], genre: String) async -> [MovieSearchItem] {
        var filteredResults: [MovieSearchItem] = []
        
        for movie in movies {
            if let movieDetail = try? await APIService.shared.fetchMovieDetails(movieID: movie.id),
               movieDetail.genres.contains(where: { $0.name == genre }) {
                filteredResults.append(movie)
            }
        }
        return filteredResults
    }
    
    // Refactored fetchRecommendationImages responsible for downloading images
    func fetchRecommendationImages(for movies: [MovieSearchItem]) async {
        await withTaskGroup(of: (Int, Data?).self) { group in
            for movie in movies {
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
                if data != nil {
                    recommendationImages.removeValue(forKey: movieId)
                }
            }
        }
    }
}

@MainActor
extension HomeViewModel {
    
    func fetchRecommendations(context: ModelContext) async {
        // Fetch user preferences
        let userPreferences = await getUserPreferences(context: context)
        self.userPrefs = userPreferences
        
        // Fetch watchlist movies
        guard let watchlist = await fetchWatchlistMovies(context: context) else {
            return
        }
        self.watchlistMovies = watchlist
        
        // Compute frequency of genres based on watchlist and user preferences
        let frequency = await computeGenreFrequency(userPrefs: userPreferences, watchlist: watchlist)
        
        //Get the top 3 genre IDs based on computed frequency.
        let topGenresIDs = topGenres(from: frequency)
        guard !topGenresIDs.isEmpty else {
            recommendedMovies = [] // Clear recommendations if no top genres found.
            return
        }
        
        // Fetch movies from API matching top genres meeting min rating.
        var discoveredMovies: [MovieSearchItem] = []
        do {
            discoveredMovies = try await fetchDiscoveredMovies(topGenres: topGenresIDs, minRating: userPreferences.minRating)
        } catch {
            print("Error fetching discovered movies: \(error)")
            recommendedMovies = []
            return
        }
        
        // Remove movies already bookmarked.
        let filteredMovies = filterBookmarked(discovered: discoveredMovies, watchlist: watchlist)
        
        let scoredMovies = await scoreMovies(for: filteredMovies, using: userPreferences)
        
        // Sort scored movies and take the top 20 recommendations.
        recommendedMovies = scoredMovies.sorted { $0.score > $1.score }
            .prefix(20)
            .map { $0.movie }
        
        await fetchRecommendationImages(for: recommendedMovies)
        
    }
    
//----------------------------------------------------------------------------------------------------------------------------------------//
    
    // Retrieves user preferences from the persistent storage.
    func getUserPreferences(context: ModelContext) async -> UserPreferences {
        let fetchedPrefs = (try? context.fetch(FetchDescriptor<UserPreferences>()))?.first
        let prefs = fetchedPrefs ?? UserPreferences()
        return prefs
    }
    
    // Fetches the list of bookmarked movies from the persistent storage.
    func fetchWatchlistMovies(context: ModelContext) async -> [WatchlistMovie]? {
        let descriptor = FetchDescriptor<WatchlistMovie>()
        do {
            let movies = try context.fetch(descriptor)
            return movies
        } catch {
            return nil
        }
    }
    

    //Gather genre counts from the watchlist movie details, add bonus counts for favorite genres (and prioritized genres)
    func computeGenreFrequency(userPrefs: UserPreferences, watchlist: [WatchlistMovie]) async -> [Int: Int] {
        var frequency: [Int: Int] = [:]
        
        if watchlist.isEmpty {
            for favorite in userPrefs.favoriteGenres {
                if let genreId = genreMapping[favorite] {
                    frequency[genreId, default: 0] += 2
                }
            }
        } else {
            // Concurrently fetch details for each movie in the watchlist
            await withTaskGroup(of: MovieDetail?.self) { group in
                for movie in watchlist {
                    group.addTask {
                        try? await APIService.shared.fetchMovieDetails(movieID: movie.id)
                    }
                }
                // For each fetched movie detail, count each genre
                for await detail in group {
                    if let detail = detail {
                        for genre in detail.genres {
                            // Standard increment
                            frequency[genre.id, default: 0] += 1
                            // Bonus if genre is among favorite genres
                            if userPrefs.favoriteGenres.contains(genre.name) {
                                frequency[genre.id, default: 0] += 1
                            }
                        }
                    }
                }
            }
            // Bonus for each favorite genre
            for favorite in userPrefs.favoriteGenres {
                if let genreId = genreMapping[favorite] {
                    frequency[genreId, default: 0] += 2
                }
            }
        }
        // Bonus for prioritized genres
        for prioritized in userPrefs.prioritizedGenres {
            if let genreId = genreMapping[prioritized] {
                frequency[genreId, default: 0] += 1
            }
        }
        print("FREQUENCY::: \(frequency)")
        return frequency
    }

    
    // Returns the top 3 genre IDs sorted by frequency.
    func topGenres(from frequency: [Int: Int]) -> [Int] {
        let top = frequency.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        return top
    }
    
    // Fetch movies from the API based on top genre IDs and min rating.
    func fetchDiscoveredMovies(topGenres: [Int], minRating: Double) async throws -> [MovieSearchItem] {
        let movies = try await APIService.shared.fetchMoviesByGenres(genreIDs: topGenres, minRating: minRating)
        return movies
    }
    
    // Filter out movies already present in watchlist.
    func filterBookmarked(discovered: [MovieSearchItem], watchlist: [WatchlistMovie]) -> [MovieSearchItem] {
        let bookmarkedIDs = Set(watchlist.map { $0.id })
        let filtered = discovered.filter { !bookmarkedIDs.contains($0.id) }
        print("filterBookmarked: Filtered out \(discovered.count - filtered.count) movies already bookmarked")
        return filtered
    }
    
    // Score each movie by fetching details, checking if it meets the minimum rating, then calculates bonus score based on how many favorite genres match.
    func scoreMovies(for movies: [MovieSearchItem], using userPrefs: UserPreferences) async -> [(movie: MovieSearchItem, score: Int)] {
        var scored: [(movie: MovieSearchItem, score: Int)] = []
        await withTaskGroup(of: (MovieSearchItem, Int)?.self) { group in
            for movie in movies {
                group.addTask { [weak self] in
                    guard self != nil else { return nil }
                    do {
                        let detail = try await APIService.shared.fetchMovieDetails(movieID: movie.id)
                        let meetsRating = detail.voteAverage >= userPrefs.minRating
                        let matchingFavorites = detail.genres.filter { userPrefs.favoriteGenres.contains($0.name) }
                        let bonusScore = matchingFavorites.count > 1 ? matchingFavorites.count - 1 : 0
                        if meetsRating && (!matchingFavorites.isEmpty || userPrefs.favoriteGenres.isEmpty) {
                            return (movie, bonusScore)
                        } else {
                            return nil
                        }
                    } catch {
                        return nil
                    }
                }
            }
            // Collect scores from each task.
            for await result in group {
                if let item = result {
                    scored.append(item)
                }
            }
        }
        return scored
    }
}
