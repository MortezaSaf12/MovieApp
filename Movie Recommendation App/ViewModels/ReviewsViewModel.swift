//
//  ReviewsViewModel.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import Observation

@Observable
class ReviewsViewModel {
    var reviews: [MovieReview] = []
    var isLoading = false
    var errorMessage: String = ""
    
    func fetchReviews(for movieID: Int) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let fetchedReviews = try await APIService.shared.fetchMovieReviews(movieID: movieID)
            
            await MainActor.run {
                self.reviews = fetchedReviews
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load reviews: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
