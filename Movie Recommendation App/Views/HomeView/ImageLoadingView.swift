//
//  ImageLoadingView.swift
//  Movie Recommendation App
//
//  Created by Artin Seyhani Porshekoh on 2025-02-25.
//

import SwiftUI

struct ImageLoadingView: View {
    let url: URL?
    var maxWidth: CGFloat? = .infinity
    var height: CGFloat? = nil
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .tint(ThemeConstants.Colors.accent)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: maxWidth, maxHeight: height)
                    .clipped()
            case .failure(_):
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(ThemeConstants.Colors.secondaryText)
                    .frame(maxWidth: maxWidth, maxHeight: height)
            @unknown default:
                EmptyView()
            }
        }
        .cornerRadius(ThemeConstants.Dimensions.smallCornerRadius)
    }
}

