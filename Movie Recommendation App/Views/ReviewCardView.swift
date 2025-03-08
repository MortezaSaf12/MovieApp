//
//  ReviewCardView.swift
//  Movie Recommendation App
//
//  Created by Artin Seyhani Porshekoh on 2025-02-26.
//
import SwiftUI

struct ReviewCardView: View {
    let review: MovieReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(review.author)
                    .font(.headline)
                    .foregroundColor(ThemeConstants.Colors.text)
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
                .foregroundColor(ThemeConstants.Colors.text)
                .lineLimit(4)
            
            Text(formatDate(review.createdAt))
                .font(.caption)
                .foregroundColor(ThemeConstants.Colors.secondaryText)
            
            Rectangle()
                .fill(ThemeConstants.Colors.cardBackground)
                .frame(height: 1)
        }
        .padding()
        .background(ThemeConstants.Colors.cardBackground)
        .cornerRadius(ThemeConstants.Dimensions.smallCornerRadius)
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
