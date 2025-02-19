//
//  MovieDetailViewModel.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import SwiftUI

@Observable
class MovieDetailViewModel {
    var movieDetail: MovieDetail?
    var isLoading = false
    var errorMessage: String = ""
    
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
