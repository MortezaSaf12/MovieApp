//
//  MovieDetailView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import SwiftUI
import SwiftData

struct MovieDetailView: View {
    
    let movieID: Int
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MovieDetailViewModel
    
    init(movieID: Int, isBookmarked: Bool = false) {
            self.movieID = movieID
            _viewModel = State(initialValue: MovieDetailViewModel(isBookmarked: isBookmarked))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading :)...")
                } else if let movie = viewModel.movieDetail {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            ImageLoadingView(url: APIService.shared.fullPosterURL(for: movie.posterPath))
                            
                            .cornerRadius(8)
                            
                            Text(movie.title)
                                .font(.title)
                                .bold()
                            
                            HStack {
                                Text("\(movie.runtime) min")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(String(format: "%.1f", movie.voteAverage)) ★")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                            
                            Text("About Movie")
                                .font(.headline)
                            
                            Text(movie.overview)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            NavigationLink(destination: ReviewsView(movieID: movie.id)) {
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
                await viewModel.fetchMovieDetails(movieID: movieID)
                await viewModel.checkBookmarkStatus(movieID: movieID)
                
                NotificationCenter.default.addObserver(
                    forName: .NSManagedObjectContextDidSave,
                    object: modelContext,
                    queue: .main
                ) { _ in
                    Task {
                        await viewModel.checkBookmarkStatus(movieID: movieID)
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
                            await viewModel.removeFromWatchlist(movieID: movieID)
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
