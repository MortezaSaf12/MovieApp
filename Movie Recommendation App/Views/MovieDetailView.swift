//
//  MovieDetailView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import SwiftUI
import SwiftData

struct MovieDetailView: View {
    
    let imdbID: String
    @Environment(\.modelContext) private var modelContext
    private var viewModel: MovieDetailViewModel
    
    init(imdbID: String, isBookmarked: Bool = false) {
        self.imdbID = imdbID
        self.viewModel = MovieDetailViewModel(isBookmarked: isBookmarked)
    }
    
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
            .task {
                viewModel.modelContext = modelContext
                await viewModel.fetchMovieDetails(imdbID: imdbID)
                await viewModel.checkBookmarkStatus(imdbID: imdbID)
                
                NotificationCenter.default.addObserver(
                    forName: .NSManagedObjectContextDidSave,
                    object: modelContext,
                    queue: .main
                ) { _ in
                    Task {
                        await viewModel.checkBookmarkStatus(imdbID: imdbID)
                    }
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { @MainActor in
                        if viewModel.isBookmarked {
                            await viewModel.removeFromWatchlist(imdbID: imdbID)
                        } else if let movie = viewModel.movieDetail {
                            await viewModel.addToWatchlist(movie: movie)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title)
                        .foregroundColor(.black)
                        .scaleEffect(x: 1.0, y: 0.8)
                }
            }
        }
    }
}
