//
//  MovieSectionView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-03-08.
//

import Foundation
import SwiftUI

struct MovieSectionView: View {
    let title: String
    let movies: [MovieSearchItem]
    let recommendationImages: [Int: Data]

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(movies) { movie in
                        NavigationLink(destination: MovieDetailView(movieID: movie.id)) {
                            MovieGridItemView(movie: movie,
                                              imageData: recommendationImages[movie.id])
                            .frame(width: 120)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
