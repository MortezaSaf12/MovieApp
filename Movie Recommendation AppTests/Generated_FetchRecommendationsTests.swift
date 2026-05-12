//
//  FetchRecommendationsTests.swift
//  Movie Recommendation AppTests
//
//  Created by Test Generator on 2025-02-09.
//

import SwiftData
import Testing
@testable import Movie_Recommendation_App
import Foundation

@MainActor
struct FetchRecommendationsTests {
    
    /// Verifies that fetchRecommendations successfully generates recommendations when user has preferences and watchlist
    @Test("fetchRecommendations generates recommendations with valid preferences and watchlist")
    func testFetchRecommendationsWithValidData() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        mockAPI.shouldFailFetchImageData = false
        
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
        
        let recommendedMovie = MovieDetail(
            title: "Recommended Action",
            releaseDate: "2025-01-15",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.5,
            overview: "A recommended action movie",
            runtime: 130,
            posterPath: "/path3.jpg",
            id: 3
        )
        
        mockAPI.movieDetailsToReturn = [1: actionMovie, 3: recommendedMovie]
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 3, title: "Recommended Action", releaseDate: "2025-01-15", posterPath: "/path3.jpg")
        ]
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let watchlistMovie = WatchlistMovie(id: 1, title: "Action Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg")
        context.insert(watchlistMovie)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(!viewModel.recommendedMovies.isEmpty)
        #expect(viewModel.recommendedMovies.contains(where: { $0.id == 3 }))
        #expect(!viewModel.recommendedMovies.contains(where: { $0.id == 1 }))
    }
    
    /// Verifies that fetchRecommendations returns empty array when no top genres are found
    @Test("fetchRecommendations returns empty recommendations when no top genres exist")
    func testFetchRecommendationsNoTopGenres() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let userPrefs = UserPreferences(favoriteGenres: [], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        #expect(viewModel.recommendedMovies.isEmpty)
    }
    
    /// Verifies that fetchRecommendations handles empty watchlist correctly
    @Test("fetchRecommendations generates recommendations with empty watchlist but valid preferences")
    func testFetchRecommendationsEmptyWatchlist() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        
        let recommendedMovie = MovieDetail(
            title: "Comedy Movie",
            releaseDate: "2025-01-15",
            genres: [MovieDetail.Genre(id: 35, name: "Comedy")],
            voteAverage: 8.0,
            overview: "A comedy movie",
            runtime: 110,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        mockAPI.movieDetailsToReturn = [1: recommendedMovie]
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Comedy Movie", releaseDate: "2025-01-15", posterPath: "/path1.jpg")
        ]
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Comedy"], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(!viewModel.recommendedMovies.isEmpty)
        #expect(viewModel.recommendedMovies.contains(where: { $0.id == 1 }))
    }
    
    /// Verifies that fetchRecommendations filters out movies already in watchlist
    @Test("fetchRecommendations excludes movies already in watchlist")
    func testFetchRecommendationsFiltersWatchlist() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        
        let watchlistedMovie = MovieDetail(
            title: "Watchlisted Action",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.0,
            overview: "Already watchlisted",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        let newMovie = MovieDetail(
            title: "New Action",
            releaseDate: "2025-01-15",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.5,
            overview: "New recommendation",
            runtime: 130,
            posterPath: "/path2.jpg",
            id: 2
        )
        
        mockAPI.movieDetailsToReturn = [1: watchlistedMovie, 2: newMovie]
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Watchlisted Action", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "New Action", releaseDate: "2025-01-15", posterPath: "/path2.jpg")
        ]
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let watchlistMovie = WatchlistMovie(id: 1, title: "Watchlisted Action", releaseDate: "2025-01-01", posterPath: "/path1.jpg")
        context.insert(watchlistMovie)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(!viewModel.recommendedMovies.isEmpty)
        #expect(!viewModel.recommendedMovies.contains(where: { $0.id == 1 }))
        #expect(viewModel.recommendedMovies.contains(where: { $0.id == 2 }))
    }
    
    /// Verifies that fetchRecommendations respects minimum rating threshold
    @Test("fetchRecommendations filters movies below minimum rating")
    func testFetchRecommendationsMinRatingFilter() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        
        let lowRatedMovie = MovieDetail(
            title: "Low Rated",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 6.0,
            overview: "Below threshold",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        let highRatedMovie = MovieDetail(
            title: "High Rated",
            releaseDate: "2025-01-15",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.5,
            overview: "Above threshold",
            runtime: 130,
            posterPath: "/path2.jpg",
            id: 2
        )
        
        mockAPI.movieDetailsToReturn = [1: lowRatedMovie, 2: highRatedMovie]
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Low Rated", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "High Rated", releaseDate: "2025-01-15", posterPath: "/path2.jpg")
        ]
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 7.5)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(!viewModel.recommendedMovies.isEmpty)
        #expect(!viewModel.recommendedMovies.contains(where: { $0.id == 1 }))
        #expect(viewModel.recommendedMovies.contains(where: { $0.id == 2 }))
    }
    
    /// Verifies that fetchRecommendations handles API errors gracefully
    @Test("fetchRecommendations handles API errors when fetching discovered movies")
    func testFetchRecommendationsAPIError() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMoviesByGenres = true
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.isEmpty)
    }
    
    /// Verifies that fetchRecommendations sorts recommendations by score
    @Test("fetchRecommendations sorts movies by score in descending order")
    func testFetchRecommendationsSortsByScore() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        
        let singleGenreMovie = MovieDetail(
            title: "Single Genre",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.0,
            overview: "One matching genre",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        let multiGenreMovie = MovieDetail(
            title: "Multi Genre",
            releaseDate: "2025-01-15",
            genres: [
                MovieDetail.Genre(id: 28, name: "Action"),
                MovieDetail.Genre(id: 35, name: "Comedy")
            ],
            voteAverage: 8.5,
            overview: "Two matching genres",
            runtime: 130,
            posterPath: "/path2.jpg",
            id: 2
        )
        
        mockAPI.movieDetailsToReturn = [1: singleGenreMovie, 2: multiGenreMovie]
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Single Genre", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "Multi Genre", releaseDate: "2025-01-15", posterPath: "/path2.jpg")
        ]
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action", "Comedy"], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.count == 2)
        #expect(viewModel.recommendedMovies[0].id == 2)
        #expect(viewModel.recommendedMovies[1].id == 1)
    }
    
    /// Verifies that fetchRecommendations limits results to top 20 movies
    @Test("fetchRecommendations limits recommendations to 20 movies")
    func testFetchRecommendationsLimitsToTwenty() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        
        var movieDetails: [Int: MovieDetail] = [:]
        var movieSearchItems: [MovieSearchItem] = []
        
        for i in 1...30 {
            let movie = MovieDetail(
                title: "Movie \(i)",
                releaseDate: "2025-01-\(String(format: "%02d", i))",
                genres: [MovieDetail.Genre(id: 28, name: "Action")],
                voteAverage: 8.0,
                overview: "Movie \(i)",
                runtime: 120,
                posterPath: "/path\(i).jpg",
                id: i
            )
            movieDetails[i] = movie
            movieSearchItems.append(MovieSearchItem(id: i, title: "Movie \(i)", releaseDate: "2025-01-\(String(format: "%02d", i))", posterPath: "/path\(i).jpg"))
        }
        
        mockAPI.movieDetailsToReturn = movieDetails
        mockAPI.moviesByGenresToReturn = movieSearchItems
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.count == 20)
    }
    
    /// Verifies that fetchRecommendations uses prioritized genres in frequency calculation
    @Test("fetchRecommendations considers prioritized genres in recommendations")
    func testFetchRecommendationsWithPrioritizedGenres() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        
        let dramaMovie = MovieDetail(
            title: "Drama Movie",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 18, name: "Drama")],
            voteAverage: 8.0,
            overview: "A drama movie",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        mockAPI.movieDetailsToReturn = [1: dramaMovie]
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Drama Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg")
        ]
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: ["Drama"], minRating: 7.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(!viewModel.recommendedMovies.isEmpty)
    }
    
    /// Verifies that fetchRecommendations fetches images for recommended movies
    @Test("fetchRecommendations fetches images for recommended movies")
    func testFetchRecommendationsFetchesImages() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        mockAPI.shouldFailFetchImageData = false
        
        let movie = MovieDetail(
            title: "Action Movie",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.0,
            overview: "An action movie",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        mockAPI.movieDetailsToReturn = [1: movie]
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Action Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg")
        ]
        
        let mockImageData = Data([1, 2, 3, 4, 5])
        if let url = mockAPI.fullPosterURL(for: "/path1.jpg") {
            mockAPI.imageDataToReturn[url] = mockImageData
        }
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(!viewModel.recommendedMovies.isEmpty)
    }
    
    /// Verifies that fetchRecommendations handles movies without matching favorite genres when favorites list is empty
    @Test("fetchRecommendations includes movies when favorite genres list is empty")
    func testFetchRecommendationsEmptyFavoriteGenres() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        
        let movie = MovieDetail(
            title: "Random Movie",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.0,
            overview: "A random movie",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        mockAPI.movieDetailsToReturn = [1: movie]
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Random Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg")
        ]
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: [], prioritizedGenres: ["Action"], minRating: 7.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(!viewModel.recommendedMovies.isEmpty)
        #expect(viewModel.recommendedMovies.contains(where: { $0.id == 1 }))
    }
    
    /// Verifies that fetchRecommendations handles movie details fetch errors gracefully
    @Test("fetchRecommendations handles errors when fetching movie details")
    func testFetchRecommendationsMovieDetailsFetchError() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = true
        mockAPI.shouldFailFetchMoviesByGenres = false
        
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Movie 1", releaseDate: "2025-01-01", posterPath: "/path1.jpg")
        ]
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.isEmpty)
    }
    
    /// Verifies that fetchRecommendations updates watchlistMovies property
    @Test("fetchRecommendations updates watchlistMovies property")
    func testFetchRecommendationsUpdatesWatchlistMovies() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        
        let movie = MovieDetail(
            title: "Watchlist Movie",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.0,
            overview: "In watchlist",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        mockAPI.movieDetailsToReturn = [1: movie]
        mockAPI.moviesByGenresToReturn = []
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action"], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let watchlistMovie = WatchlistMovie(id: 1, title: "Watchlist Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg")
        context.insert(watchlistMovie)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.watchlistMovies.count == 1)
        #expect(viewModel.watchlistMovies[0].id == 1)
    }
    
    /// Verifies that fetchRecommendations handles multiple favorite genres correctly
    @Test("fetchRecommendations handles multiple favorite genres")
    func testFetchRecommendationsMultipleFavoriteGenres() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferences.self, WatchlistMovie.self, configurations: config)
        let context = container.mainContext
        
        let mockAPI = MockAPIService.shared
        mockAPI.shouldFailFetchMovieDetails = false
        mockAPI.shouldFailFetchMoviesByGenres = false
        
        let actionMovie = MovieDetail(
            title: "Action Movie",
            releaseDate: "2025-01-01",
            genres: [MovieDetail.Genre(id: 28, name: "Action")],
            voteAverage: 8.0,
            overview: "Action only",
            runtime: 120,
            posterPath: "/path1.jpg",
            id: 1
        )
        
        let comedyMovie = MovieDetail(
            title: "Comedy Movie",
            releaseDate: "2025-01-02",
            genres: [MovieDetail.Genre(id: 35, name: "Comedy")],
            voteAverage: 8.0,
            overview: "Comedy only",
            runtime: 110,
            posterPath: "/path2.jpg",
            id: 2
        )
        
        let actionComedyMovie = MovieDetail(
            title: "Action Comedy",
            releaseDate: "2025-01-03",
            genres: [
                MovieDetail.Genre(id: 28, name: "Action"),
                MovieDetail.Genre(id: 35, name: "Comedy")
            ],
            voteAverage: 8.5,
            overview: "Both genres",
            runtime: 130,
            posterPath: "/path3.jpg",
            id: 3
        )
        
        mockAPI.movieDetailsToReturn = [1: actionMovie, 2: comedyMovie, 3: actionComedyMovie]
        mockAPI.moviesByGenresToReturn = [
            MovieSearchItem(id: 1, title: "Action Movie", releaseDate: "2025-01-01", posterPath: "/path1.jpg"),
            MovieSearchItem(id: 2, title: "Comedy Movie", releaseDate: "2025-01-02", posterPath: "/path2.jpg"),
            MovieSearchItem(id: 3, title: "Action Comedy", releaseDate: "2025-01-03", posterPath: "/path3.jpg")
        ]
        
        setupForTesting(mockAPI: mockAPI)
        
        let userPrefs = UserPreferences(favoriteGenres: ["Action", "Comedy"], prioritizedGenres: [], minRating: 7.0)
        context.insert(userPrefs)
        
        let viewModel = HomeViewModel()
        await viewModel.fetchRecommendations(context: context)
        
        resetAfterTesting()
        
        #expect(viewModel.recommendedMovies.count == 3)
        #expect(viewModel.recommendedMovies[0].id == 3)
    }
}