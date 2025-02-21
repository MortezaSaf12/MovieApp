//
//  MovieDetailViewModel.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
class MovieDetailViewModel {
    var movieDetail: MovieDetail?
    var isLoading = false
    var errorMessage: String = ""
    var isBookmarked: Bool
    var modelContext: ModelContext?
    
    init(isBookmarked: Bool = false) {
        self.isBookmarked = isBookmarked
    }
    
    @MainActor
    func checkBookmarkStatus(imdbID: String) async {
        guard let modelContext else { return }
        
        let descriptor = FetchDescriptor<WatchlistMovie>(
            predicate: #Predicate { $0.imdbID == imdbID }
        )
        
        do {
            let count = try modelContext.fetchCount(descriptor)
            isBookmarked = count > 0
        } catch {
            print("Error checking bookmark status: \(error)")
        }
    }
    
    @MainActor
    func addToWatchlist(movie: MovieDetail) async {
        guard let modelContext else { return }
        let targetIMDbID = movie.imdbID
        
        let existingCheck = FetchDescriptor<WatchlistMovie>(
            predicate: #Predicate { $0.imdbID == targetIMDbID }
        )
        
        do {
            let existingCount = try modelContext.fetchCount(existingCheck)
            guard existingCount == 0 else {
                isBookmarked = true
                return
            }
            
            var posterData: Data? = nil
            if let posterURL = URL(string: movie.poster) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: posterURL)
                    posterData = data
                } catch {
                    print("Error downloading poster: \(error)")
                }
            }
            
            let newBookmark = WatchlistMovie(
                imdbID: targetIMDbID,
                title: movie.title,
                year: movie.year,
                poster: movie.poster,
                posterData: posterData
            )
            modelContext.insert(newBookmark)
            try modelContext.save()
            isBookmarked = true
        } catch {
            print("Error saving bookmark: \(error)")
        }
    }
    
    @MainActor
    func removeFromWatchlist(imdbID: String) async {
        guard let modelContext else { return }
        
        let descriptor = FetchDescriptor<WatchlistMovie>(
            predicate: #Predicate { $0.imdbID == imdbID }
        )
        
        do {
            let items = try modelContext.fetch(descriptor)
            for item in items {
                modelContext.delete(item)
            }
            try modelContext.save()
            isBookmarked = false
        } catch {
            print("Remove failed: \(error)")
        }
    }
    
    @MainActor
    func fetchMovieDetails(imdbID: String) async {
        isLoading = true
        
        Task {
            do {
                let detail = try await APIService.shared.fetchMovieDetails(imdbID: imdbID)
                await MainActor.run {
                    self.movieDetail = detail
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
