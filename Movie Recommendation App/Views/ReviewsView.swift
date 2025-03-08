
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
                        .foregroundColor(ThemeConstants.Colors.text)
                        .tint(ThemeConstants.Colors.accent)
                        .padding()
                } else if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(ThemeConstants.Colors.accent)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if viewModel.reviews.isEmpty {
                    Text("No reviews available for this movie.")
                        .foregroundColor(ThemeConstants.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(viewModel.reviews) { review in
                        ReviewCardView(review: review)
                            .background(ThemeConstants.Colors.cardBackground)
                            .cornerRadius(ThemeConstants.Dimensions.cornerRadius)
                            .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
        .background(ThemeConstants.Colors.background)
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ThemeConstants.Colors.background, for: .navigationBar)
        .task {
            await viewModel.fetchReviews(for: movieID)
        }
    }
}
