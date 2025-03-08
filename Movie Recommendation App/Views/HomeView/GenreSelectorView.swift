//
//  GenreSelectorView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-03-08.
//

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
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedGenre = genre
                        }
                    } label: {
                        Text(genre)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(selectedGenre == genre ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                if selectedGenre == genre {
                                    Capsule()
                                        .fill(Color.blue.gradient)
                                        .shadow(color: .blue.opacity(0.25), radius: 6, x: 0, y: 3)
                                } else {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.15))
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
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.horizontal)
        }
    }
}
