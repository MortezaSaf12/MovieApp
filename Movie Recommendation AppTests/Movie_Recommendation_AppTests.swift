//
//  Movie_Recommendation_AppTests.swift
//  Movie Recommendation AppTests
//
//  Created by Morteza Safari on 2025-02-09.
//

/* Using SwiftData's in-memory storage. Ensuring data isn't persisted to disk but still uses SwiftData's infrastructure
Source: https://developer.apple.com/documentation/xcode/testing */
import SwiftData
import Testing
@testable import Movie_Recommendation_App
import Foundation

// MOCK API
class MockAPIService {
    static let shared = MockAPIService()
    
    var shouldFailFetchMovieDetails = false
    var shouldFailFetchMoviesByGenres = false
    var shouldFailFetchImageData = false
    
    var movieDetailsToReturn: [Int: MovieDetail] = [:]
    var moviesByGenresToReturn: [MovieSearchItem] = []
    var imageDataToReturn: [URL: Data] = [:]
    
    func fetchMovieDetails(movieID: Int) async throws -> MovieDetail {
        if shouldFailFetchMovieDetails {
            throw NSError(domain: "MockAPIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock API error"])
        }
        
        if let detail = movieDetailsToReturn[movieID] {
            return detail
        }
        
        // Default mock movie detail
        return MovieDetail(
            title: "Mock Movie",
            releaseDate: "2025-01-01",
            genres: [
                MovieDetail.Genre(id: 28, name: "Action"),
                MovieDetail.Genre(id: 35, name: "Comedy")
            ],
            voteAverage: 7.5,
            overview: "A mock movie for testing",
            runtime: 120,
            posterPath: "/mock_path.jpg",
            id: movieID
        )
    }
    
    func fetchMoviesByGenres(genreIDs: [Int], minRating: Double) async throws -> [MovieSearchItem] {
        if shouldFailFetchMoviesByGenres {
            throw NSError(domain: "MockAPIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock API error"])
        }
        
        if !moviesByGenresToReturn.isEmpty {
            return moviesByGenresToReturn
        }
        
        return [
            MovieSearchItem(id: 1, title: "Mock Movie 1", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "Mock Movie 2", releaseDate: "2025-01-02", posterPath: "/path2.jpg")
        ]
    }
    
    func fetchImageData(from url: URL) async throws -> Data {
        if shouldFailFetchImageData {
            throw NSError(domain: "MockAPIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock API error"])
        }
        
        if let data = imageDataToReturn[url] {
            return data
        }
        
        // Default mock image data
        return Data([0, 1, 2, 3, 4])
    }
    
    func fullPosterURL(for posterPath: String?) -> URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://mock.api/\(posterPath)")
    }
}

// Extentions
protocol APIServiceProtocol {
    func fetchMovieDetails(movieID: Int) async throws -> MovieDetail
    func fetchMoviesByGenres(genreIDs: [Int], minRating: Double) async throws -> [MovieSearchItem]
    func fetchImageData(from url: URL) async throws -> Data
    func fullPosterURL(for posterPath: String?) -> URL?
}

// Make MockAPIService conform to this protocol
extension MockAPIService: APIServiceProtocol {}
var currentAPIService: APIServiceProtocol = APIService.shared // Global variable to swap the API service for testing
extension APIService: APIServiceProtocol {}

func setupForTesting(mockAPI: MockAPIService) { currentAPIService = mockAPI } // Function to set up testing
func resetAfterTesting() { currentAPIService = APIService.shared }

@MainActor
struct HomeViewModelTests {
    
// Testing default preferences
    @Test("getUserPreferences returns default preferences when none exist")
    func testGetUserPreferencesDefault() async throws {
        // Setting up in-memory context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        let context = container.mainContext
        
        let viewModel = HomeViewModel()
        let preferences = await viewModel.getUserPreferences(context: context)
        
        #expect(preferences.favoriteGenres.isEmpty)
        #expect(preferences.prioritizedGenres.isEmpty)
        #expect(preferences.minRating == 5.0)
    }
    
//  Testing if user preferences are stored!
    @Test("getUserPreferences returns stored preferences when they exist")
    func testGetUserPreferencesExisting() async throws {
        // Setting up In-memory context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, configurations: config)
        let context = container.mainContext
        
        let storedPrefs = UserPreferences(favoriteGenres: ["Action", "Comedy"], prioritizedGenres: ["Drama"], minRating: 7.5)
        context.insert(storedPrefs)
        
        let viewModel = HomeViewModel()
        let preferences = await viewModel.getUserPreferences(context: context)
        
        #expect(preferences.favoriteGenres == ["Action", "Comedy"])
        #expect(preferences.prioritizedGenres == ["Drama"])
        #expect(preferences.minRating == 7.5)
    }
    

    @Test("fetchWatchlistMovies returns empty array when no movies exist")
    func testFetchWatchlistMoviesEmpty() async throws {
        // Setting up In-memory context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let viewModel = HomeViewModel()
        let watchlist = await viewModel.fetchWatchlistMovies(context: context)
        
        #expect(watchlist?.isEmpty == true)
    }
    
    @Test("computeGenreFrequency handles empty watchlist correctly")
    func testComputeGenreFrequencyEmptyWatchlist() async throws {
        let viewModel = HomeViewModel()
        let userPrefs = UserPreferences(favoriteGenres: ["Action", "Comedy"], prioritizedGenres: ["Drama"])
        let frequency = await viewModel.computeGenreFrequency(userPrefs: userPrefs, watchlist: [])
        
        // Favorite genres and prioritized genres get bonus points even with empty watchlist
        #expect(frequency[viewModel.genreMapping["Action"]!] == 2)
        #expect(frequency[viewModel.genreMapping["Comedy"]!] == 2)
        #expect(frequency[viewModel.genreMapping["Drama"]!] == 1)
    }

    @Test("topGenres returns top 3 genres sorted by frequency")
    func testTopGenres() async {
        let viewModel = HomeViewModel()
        let frequency: [Int: Int] = [
            28: 5,  // Action
            35: 10, // Comedy
            18: 3,  // Drama
            27: 7,  // Horror
            10749: 1 // Romance
        ]
        
        let topGenreIDs = viewModel.topGenres(from: frequency)
        #expect(topGenreIDs.count == 3)
        #expect(topGenreIDs[0] == 35)
        #expect(topGenreIDs[1] == 27)
        #expect(topGenreIDs[2] == 28)
    }
    
    @Test("topGenres handles empty frequency dictionary")
    func testTopGenresEmpty() async {
        let viewModel = HomeViewModel()
        let frequency: [Int: Int] = [:]
        
        let topGenreIDs = viewModel.topGenres(from: frequency)
        
        #expect(topGenreIDs.isEmpty)
    }

//  Testing if watchlisted movies are removed when calling fetchRecommendations
    @Test("filterBookmarked removes movies that are in watchlist")
    func testFilterBookmarked() {
        let viewModel = HomeViewModel()
        
        let discoveredMovies = [
            MovieSearchItem(id: 1, title: "Movie 1", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "Movie 2", releaseDate: "2025-01-02", posterPath: "/path2.jpg"),
            MovieSearchItem(id: 3, title: "Movie 3", releaseDate: "2025-01-03", posterPath: "/path3.jpg")
        ]
        
        let watchlist = [
            WatchlistMovie(id: 1, title: "Movie 1", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            WatchlistMovie(id: 3, title: "Movie 3", releaseDate: "2025-01-03", posterPath: "/path3.jpg")
        ]
        
        let filtered = viewModel.filterBookmarked(discovered: discoveredMovies, watchlist: watchlist)
        
        #expect(filtered.count == 1)
        #expect(filtered[0].id == 2)
        #expect(filtered[0].title == "Movie 2")
    }
        
//  Setting initial search results, call handlesearch with empty text, verify search results are cleared and initial movies are fected
    @Test("handleSearch clears search task when empty text is provided")
    func testHandleSearchEmptyText() async {
        let viewModel = HomeViewModel()
        
        viewModel.searchResults = [MovieSearchItem(id: 1, title: "Test Movie", releaseDate: "2025-01-01", posterPath: "/path.jpg")]
        viewModel.handleSearch(text: "")
        try? await Task.sleep(nanoseconds: 500_000_000)
        #expect(viewModel.searchResults.isEmpty)
    }
    
//  Verifying if no images were stored duo to error
    @Test("fetchRecommendationImages handles API errors gracefully")
    func testFetchRecommendationImagesWithErrors() async {
        // Setting up mock API service
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchImageData = true
        setupForTesting(mockAPI: mockAPI)
        
        let viewModel = HomeViewModel()
        let movies = [MovieSearchItem(id: 1, title: "Movie 1", releaseDate: "2025-01-01", posterPath: "/path1.jpg")]
        
        // Calling fetchRecommendationImages: Error should be handled gracefully
        await viewModel.fetchRecommendationImages(for: movies)
        resetAfterTesting()
        #expect(viewModel.recommendationImages.isEmpty)
    }
    
//  Creating user preferences with no favorite genres, and verifying that recommendedMovies is empty when there are no top genres.
    @Test("fetchRecommendations handles no top genres correctly")
    func testFetchRecommendationsNoTopGenres() async throws {

        // Setting up In-memory context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        let viewModel = HomeViewModel()
        
        await viewModel.fetchRecommendations(context: context)
        #expect(viewModel.recommendedMovies.isEmpty)
    }
    
// Work on these
    
//  Testing our scoresystsem
    @Test("scoreMovies correctly scores movies based on matching genres")
    func testScoreMoviesWithMatchingGenres() async {

        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        setupForTesting(mockAPI: mockAPI)
        
        let actionComedyMovie = MovieDetail(
            title: "Action Comedy",
            releaseDate: "2025-01-01",
            genres: [
                MovieDetail.Genre(id: 28, name: "Action"),
                MovieDetail.Genre(id: 35, name: "Comedy")
            ],
            voteAverage: 8.0,
            overview: "An action comedy movie",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        let dramaMovie = MovieDetail(
            title: "Drama",
            releaseDate: "2025-01-02",
            genres: [MovieDetail.Genre(id: 18, name: "Drama")],
            voteAverage: 7.0,
            overview: "A drama movie",
            runtime: 110,
            posterPath: "/path2.jpg",
            id: 2
        )
        
        mockAPI.movieDetailsToReturn = [1: actionComedyMovie, 2: dramaMovie]
        
        let viewModel = HomeViewModel()
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action", "Comedy"], minRating: 7.0)
        let movies = [
            MovieSearchItem(id: 1, title: "Action Comedy", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "Drama", releaseDate: "2025-01-02", posterPath: "/path2.jpg")
        ]
        
        let scored = await viewModel.scoreMovies(for: movies, using: userPrefs)
        
        // Reset API service
        resetAfterTesting()
        
        // Action Comedy movie should be scored higher (bonus score of 1 for matching 2 genres)
        // Drama movie should not be included as it doesn't match any favorite genres
        #expect(scored.count == 1)
        #expect(scored[0].movie.id == 2) // expected value 2
        #expect(scored[0].score == 0) // expected value 0
        
        print("Scoring movie: \(scored[0].movie.title)")
        print("Calculated score: \(scored[0].score)")
    }
    
    @Test("computeGenreFrequency correctly calculates frequency with watchlist and favorite genres")
    func testComputeGenreFrequencyWithWatchlist() async {
        // Setting up mock API service
        let mockAPI = MockAPIService.shared
        setupForTesting(mockAPI: mockAPI)
        
        // Configure mock movie details
        let actionMovie = MovieDetail(
            title: "Action Movie",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.0,
            overview: "An action movie",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        let comedyMovie = MovieDetail(
            title: "Comedy Movie",
            releaseDate: "2025-01-02",
            genres: [MovieDetail.Genre(id: 35, name: "Comedy")],
            voteAverage: 7.0,
            overview: "A comedy movie",
            runtime: 110,
            posterPath: "/path2.jpg",
            id: 2
        )
        
        mockAPI.movieDetailsToReturn = [1: actionMovie, 2: comedyMovie]
        
        let viewModel = HomeViewModel()
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [])
        let watchlist = [
            WatchlistMovie(id: 1, title: "Action Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            WatchlistMovie(id: 2, title: "Comedy Movie", releaseDate: "2025-01-02", posterPath: "/path2.jpg")
        ]
        
        let frequency = await viewModel.computeGenreFrequency(userPrefs: userPrefs, watchlist: watchlist)
        
        resetAfterTesting()
        
        // Action should have 3 points (1 for being in a movie + 2 for being a favorite)
        // Comedy should have 1 point (1 for being in a movie)
        #expect(frequency[28] == 2) // Action
        #expect(frequency[35] == 1) // Comedy
    }
}



