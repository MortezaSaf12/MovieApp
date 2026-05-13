//
//  FetchRecommendationsTests.swift
//  Movie Recommendation AppTests
//
//  Created by Test Generator on 2025-03-10.
//

import SwiftData
import Testing
@testable import Movie_Recommendation_App
import Foundation

@MainActor
struct FetchRecommendationsTests {
    
    /// Verifies that fetchRecommendations returns empty array when no top genres are identified
    @Test("fetchRecommendations returns empty recommendations when no top genres exist")
    func testFetchRecommendationsNoTopGenres() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: [], prioritizedGenres: [], minRating: 5.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        #expect(viewModel.recommendedMovies.isEmpty)
    }
    
    /// Verifies that fetchRecommendations correctly filters out bookmarked movies
    @Test("fetchRecommendations excludes movies already in watchlist")
    func testFetchRecommendationsExcludesBookmarked() async throws {
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        setupForTesting(mockAPI: mockAPI)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 5.0)
        context.insert(userPrefs)
        
        let bookmarkedMovie = WatchlistMovie(id: 1, title: "Bookmarked Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg")
        context.insert(bookmarkedMovie)
        
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Bookmarked Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "New Movie", releaseDate: "2025-01-02", posterPath: "/path2.jpg")
        ]
        
        let actionGenreMovie = MovieDetail(
            title: "New Movie",
            releaseDate: "2025-01-02",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 7.0,
            overview: "An action movie",
            runtime: 120,
            posterPath: "/path2.jpg",
            id: 2
        )
        
        mockAPI.movieDetailsToReturn = [2: actionGenreMovie]
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(!viewModel.recommendedMovies.contains(where: { $0.id == 1 }))
        #expect(viewModel.recommendedMovies.contains(where: { $0.id == 2 }))
    }
    
    /// Verifies that fetchRecommendations respects minimum rating threshold
    @Test("fetchRecommendations filters movies below minimum rating")
    func testFetchRecommendationsRespectsMinRating() async throws {
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        setupForTesting(mockAPI: mockAPI)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 8.0)
        context.insert(userPrefs)
        
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "High Rated Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "Low Rated Movie", releaseDate: "2025-01-02", posterPath: "/path2.jpg")
        ]
        
        let highRatedMovie = MovieDetail(
            title: "High Rated Movie",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.5,
            overview: "A high rated action movie",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        let lowRatedMovie = MovieDetail(
            title: "Low Rated Movie",
            releaseDate: "2025-01-02",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 6.0,
            overview: "A low rated action movie",
            runtime: 110,
            posterPath: "/path2.jpg",
            id: 2
        )
        
        mockAPI.movieDetailsToReturn = [1: highRatedMovie, 2: lowRatedMovie]
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.contains(where: { $0.id == 1 }))
        #expect(!viewModel.recommendedMovies.contains(where: { $0.id == 2 }))
    }
    
    /// Verifies that fetchRecommendations prioritizes movies matching multiple favorite genres
    @Test("fetchRecommendations scores movies with multiple matching genres higher")
    func testFetchRecommendationsMultipleGenreBonus() async throws {
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        setupForTesting(mockAPI: mockAPI)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action", "Comedy"], prioritizedGenres: [], minRating: 5.0)
        context.insert(userPrefs)
        
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Action Comedy", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "Just Action", releaseDate: "2025-01-02", posterPath: "/path2.jpg")
        ]
        
        let actionComedyMovie = MovieDetail(
            title: "Action Comedy",
            releaseDate: "2025-01-01",
            genres: [
                MovieDetail.Genre(id: 28, name: "Action"),
                MovieDetail.Genre(id: 35, name: "Comedy")
            ],
            voteAverage: 7.0,
            overview: "An action comedy movie",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        let actionMovie = MovieDetail(
            title: "Just Action",
            releaseDate: "2025-01-02",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 7.0,
            overview: "An action movie",
            runtime: 110,
            posterPath: "/path2.jpg",
            id: 2
        )
        
        mockAPI.movieDetailsToReturn = [1: actionComedyMovie, 2: actionMovie]
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.count == 2)
        #expect(viewModel.recommendedMovies[0].id == 1)
        #expect(viewModel.recommendedMovies[1].id == 2)
    }
    
    /// Verifies that fetchRecommendations handles API errors gracefully
    @Test("fetchRecommendations handles API errors without crashing")
    func testFetchRecommendationsHandlesAPIErrors() async throws {
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMoviesByGenres = true
        setupForTesting(mockAPI: mockAPI)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 5.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.isEmpty)
    }
    
    /// Verifies that fetchRecommendations correctly uses prioritized genres to boost frequency
    @Test("fetchRecommendations prioritizes movies from prioritized genres")
    func testFetchRecommendationsWithPrioritizedGenres() async throws {
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        setupForTesting(mockAPI: mockAPI)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(
            favoriteGenres: ["Action", "Drama"],
            prioritizedGenres: ["Drama"],
            minRating: 5.0
        )
        context.insert(userPrefs)
        
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Drama Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "Action Movie", releaseDate: "2025-01-02", posterPath: "/path2.jpg")
        ]
        
        let dramaMovie = MovieDetail(
            title: "Drama Movie",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 18, name: "Drama")],
            voteAverage: 7.0,
            overview: "A drama movie",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        let actionMovie = MovieDetail(
            title: "Action Movie",
            releaseDate: "2025-01-02",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 7.0,
            overview: "An action movie",
            runtime: 110,
            posterPath: "/path2.jpg",
            id: 2
        )
        
        mockAPI.movieDetailsToReturn = [1: dramaMovie, 2: actionMovie]
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.count == 2)
        
        let dramaMovieInResults = viewModel.recommendedMovies.first(where: { $0.id == 1 })
        let actionMovieInResults = viewModel.recommendedMovies.first(where: { $0.id == 2 })
        
        #expect(dramaMovieInResults != nil)
        #expect(actionMovieInResults != nil)
        
        let dramaIndex = viewModel.recommendedMovies.firstIndex(where: { $0.id == 1 })
        let actionIndex = viewModel.recommendedMovies.firstIndex(where: { $0.id == 2 })
        
        if let dramaIdx = dramaIndex, let actionIdx = actionIndex {
            #expect(dramaIdx < actionIdx)
        }
    }
    
    /// Verifies that fetchRecommendations successfully fetches and stores images for recommended movies
    @Test("fetchRecommendations fetches images for recommended movies")
    func testFetchRecommendationsFetchesImages() async throws {
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        mockAPI.shouldFailFetchImageData = false
        setupForTesting(mockAPI: mockAPI)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 5.0)
        context.insert(userPrefs)
        
        let testMovieId = 123
        let testPosterPath = "/test_path.jpg"
        
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: testMovieId, title: "Test Movie", releaseDate: "2025-01-01", posterPath: testPosterPath)
        ]
        
        let testMovie = MovieDetail(
            title: "Test Movie",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 7.0,
            overview: "A test movie",
            runtime: 120,
            posterPath: testPosterPath,
            id: testMovieId
        )
        
        mockAPI.movieDetailsToReturn = [testMovieId: testMovie]
        
        let testImageData = Data([1, 2, 3, 4, 5])
        if let imageURL = mockAPI.fullPosterURL(for: testPosterPath) {
            mockAPI.imageDataToReturn[imageURL] = testImageData
        }
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.contains(where: { $0.id == testMovieId }))
        #expect(viewModel.recommendationImages[testMovieId] == testImageData)
    }
    
    /// Verifies that fetchRecommendations limits results to top 20 movies
    @Test("fetchRecommendations returns maximum 20 recommendations")
    func testFetchRecommendationsLimitsToTwenty() async throws {
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        setupForTesting(mockAPI: mockAPI)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 5.0)
        context.insert(userPrefs)
        
        var manyMovies: [MovieSearchItem] = []
        var movieDetails: [Int: MovieDetail] = [:]
        
        for i in 1...30 {
            let movie = MovieSearchItem(id: i, title: "Movie \(i)", releaseDate: "2025-01-01", posterPath: "/path\(i).jpg")
            manyMovies.append(movie)
            
            let detail = MovieDetail(
                title: "Movie \(i)",
                releaseDate: "2025-01-01",
                genres: [MovieDetail.Genre(id: 28, name: "Action")],
                voteAverage: 7.0,
                overview: "Movie \(i)",
                runtime: 120,
                posterPath: "/path\(i).jpg",
                id: i
            )
            movieDetails[i] = detail
        }
        
        mockAPI.moviesByGenresToReturn = manyMovies
        mockAPI.movieDetailsToReturn = movieDetails
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.count == 20)
    }
    
    /// Verifies that fetchRecommendations works correctly with watchlist-based genre frequency
    @Test("fetchRecommendations uses watchlist to compute genre frequency")
    func testFetchRecommendationsUsesWatchlistForFrequency() async throws {
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        setupForTesting(mockAPI: mockAPI)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 5.0)
        context.insert(userPrefs)
        
        let watchlistMovie1 = WatchlistMovie(id: 100, title: "Watchlist Action", releaseDate: "2024-01-01", posterPath: "/watch1.jpg")
        let watchlistMovie2 = WatchlistMovie(id: 101, title: "Watchlist Comedy", releaseDate: "2024-01-02", posterPath: "/watch2.jpg")
        context.insert(watchlistMovie1)
        context.insert(watchlistMovie2)
        
        let watchlistActionDetail = MovieDetail(
            title: "Watchlist Action",
            releaseDate: "2024-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.0,
            overview: "Watchlist action movie",
            runtime: 120,
            posterPath: "/watch1.jpg",
            id: 100
        )
        
        let watchlistComedyDetail = MovieDetail(
            title: "Watchlist Comedy",
            releaseDate: "2024-01-02",
            genres: [MovieDetail.Genre(id: 35, name: "Comedy")],
            voteAverage: 7.5,
            overview: "Watchlist comedy movie",
            runtime: 110,
            posterPath: "/watch2.jpg",
            id: 101
        )
        
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "New Action", releaseDate: "2025-01-01", posterPath: "/path1.jpg")
        ]
        
        let newActionMovie = MovieDetail(
            title: "New Action",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 7.0,
            overview: "A new action movie",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        mockAPI.movieDetailsToReturn = [
            100: watchlistActionDetail,
            101: watchlistComedyDetail,
            1: newActionMovie
        ]
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.contains(where: { $0.id == 1 }))
    }
    
    /// Verifies that fetchRecommendations handles empty favorite genres with watchlist
    @Test("fetchRecommendations works with empty favorite genres but populated watchlist")
    func testFetchRecommendationsEmptyFavoritesWithWatchlist() async throws {
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        setupForTesting(mockAPI: mockAPI)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: [], prioritizedGenres: [], minRating: 5.0)
        context.insert(userPrefs)
        
        let watchlistMovie = WatchlistMovie(id: 100, title: "Watchlist Movie", releaseDate: "2024-01-01", posterPath: "/watch.jpg")
        context.insert(watchlistMovie)
        
        let watchlistDetail = MovieDetail(
            title: "Watchlist Movie",
            releaseDate: "2024-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.0,
            overview: "Watchlist movie",
            runtime: 120,
            posterPath: "/watch.jpg",
            id: 100
        )
        
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "New Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg")
        ]
        
        let newMovie = MovieDetail(
            title: "New Movie",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 7.0,
            overview: "A new movie",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        mockAPI.movieDetailsToReturn = [100: watchlistDetail, 1: newMovie]
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.contains(where: { $0.id == 1 }))
    }
}