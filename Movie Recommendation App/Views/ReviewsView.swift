
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

struct ReviewCard: View {
    let review: MovieReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(review.author)
                    .font(.headline)
                Spacer()
                if let rating = review.authorDetails?.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(rating, specifier: "%.1f")")
                            .font(.subheadline)
                    }
                }
            }
            
            Text(review.content)
                .font(.body)
                .lineLimit(4)
            
            HStack {
                Spacer()
                Text(formatDate(review.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.current
        
        return formatter.string(from: date)
    }
}








/* old code:
struct ReviewsView: View {
    let imdbID: String
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Reviews from another API
            }
            .padding()
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
    }
}
*/
