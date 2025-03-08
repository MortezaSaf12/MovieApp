//
//  MovieRowView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-03-08.
//

import Foundation
import SwiftUI

struct MovieRowView: View {
    let movie: MovieSearchItem
    
    var body: some View {
        HStack(spacing: 15) {
            ImageLoadingView(url: APIService.shared.fullPosterURL(for: movie.posterPath),
                             maxWidth: 50,
                             height: 75)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(movie.title)
                    .font(.headline)
                Text("(\(String(movie.releaseDate.prefix(4))))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
