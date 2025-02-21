//
//  WatchlistViewModel.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import SwiftData

@MainActor
@Observable
class WatchlistViewModel {
    var watchlistMovies: [WatchlistMovie] = []
    var modelContext: ModelContext?
    
    func fetchMovies() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<WatchlistMovie>(sortBy: [SortDescriptor(\.title)])
        do {
            watchlistMovies = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching watchlist: \(error)")
        }
    }
}
