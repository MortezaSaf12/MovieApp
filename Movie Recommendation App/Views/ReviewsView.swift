
//
//  ReviewsView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import SwiftUI

struct ReviewsView: View {
    let movieID: Int
    @State private var viewModel = ReviewsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Loading reviews...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if viewModel.reviews.isEmpty {
                    Text("No reviews available for this movie.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(viewModel.reviews) { review in
                        ReviewCardView(review: review)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchReviews(for: movieID)
        }
    }
}
