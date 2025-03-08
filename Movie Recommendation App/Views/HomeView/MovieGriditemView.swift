//
//  MovieGriditemView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-03-08.
//

import Foundation
import SwiftUI

struct MovieGridItemView: View {
    let movie: MovieSearchItem
    var imageData: Data?

    var body: some View {
        VStack(spacing: 8) {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 180)
            } else {
                ImageLoadingView(url: APIService.shared.fullPosterURL(for: movie.posterPath),
                                 maxWidth: 120,
                                 height: 180)
            }
            
            Text(movie.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(maxWidth: 120)
            
            Text("(\(String(movie.releaseDate.prefix(4))))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
