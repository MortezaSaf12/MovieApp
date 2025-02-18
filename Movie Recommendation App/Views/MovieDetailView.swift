//
//  MovieDetailView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import SwiftUI

struct MovieDetailView: View {
    let imdbID: String
    
    @State private var viewModel = MovieDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var isBookmarked = false
    
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading :)...")
                } else if let movie = viewModel.movieDetail {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            AsyncImage(url: URL(string: movie.poster)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                case .failure(_):
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }

                            .cornerRadius(8)
                            
                            Text(movie.title)
                                .font(.title)
                                .bold()
                            
                            HStack {
                                Text("\(movie.runtime)")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(movie.imdbRating) (IMDb)")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                            
                            Text("About Movie")
                                .font(.headline)
                            
                            Text(movie.plot)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            NavigationLink(destination: ReviewsView(imdbID: movie.imdbID)) {
                                Text("See reviews")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                } else if !viewModel.errorMessage.isEmpty {
                    Text("Error: \(viewModel.errorMessage)")
                        .foregroundColor(.red)
                } else {
                    Text("No movie details available.")
                }
            }
            .navigationTitle("Detail")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isBookmarked.toggle()
                } label: {
                    //ChatGPT
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title)
                        .foregroundColor(.black)
                        .scaleEffect(x: 1.0, y: 0.8, anchor: .center)
                        .frame(width: 30) // Optional: Only apply a width frame
                }
            }
        }
        
        .onAppear {
            viewModel.fetchMovieDetails(imdbID: imdbID)
        }
    }
}
