//
//  GenreSelectorView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-03-08.
//

import Foundation
import SwiftUI

import Foundation
import SwiftUI

struct GenreSelectorView: View {
    @Binding var selectedGenre: String
    let genres: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(genres, id: \.self) { genre in
                    Button {
                        withAnimation(ThemeConstants.Animations.standardSpring) {
                            selectedGenre = genre
                        }
                    } label: {
                        Text(genre)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedGenre == genre ? ThemeConstants.Colors.text : ThemeConstants.Colors.secondaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                if selectedGenre == genre {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [ThemeConstants.Colors.accent, ThemeConstants.Colors.secondaryAccent],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: ThemeConstants.Colors.accent.opacity(0.4), radius: 6, x: 0, y: 3)
                                } else {
                                    Capsule()
                                        .fill(ThemeConstants.Colors.cardBackground)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background {
            Rectangle()
                .fill(ThemeConstants.Colors.background.opacity(0.95))
                .edgesIgnoringSafeArea(.horizontal)
        }
    }
}
