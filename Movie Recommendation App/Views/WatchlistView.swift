//
//  WatchlistView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WatchlistViewModel()
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.watchlistMovies.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark.slash",
                        description: Text("Save movies to see them here")
                            .foregroundColor(ThemeConstants.Colors.secondaryText)
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewModel.watchlistMovies) { movie in
                                NavigationLink(destination: MovieDetailView(movieID: movie.id, isBookmarked: true)
                                ) {
                                    VStack {
                                        if let data = movie.posterData, let image = UIImage(data: data) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 200)
                                                .clipped()
                                                .cornerRadius(8)
                                        } else {
                                            ImageLoadingView(url: APIService.shared.fullPosterURL(for: movie.posterPath), height: 200)
                                        }
                                        Text(movie.title)
                                            .lineLimit(1)
                                            .foregroundColor(ThemeConstants.Colors.text)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .background(ThemeConstants.Colors.background)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Bookmarks")
                        .font(.headline)
                        .foregroundColor(ThemeConstants.Colors.text)
                }
            }
            .toolbarBackground(ThemeConstants.Colors.background, for: .navigationBar)
            .background(ThemeConstants.Colors.background)
            .foregroundColor(ThemeConstants.Colors.text)
            .task {
                viewModel.modelContext = modelContext
                viewModel.fetchMovies()
                
                NotificationCenter.default.addObserver(
                    forName: .NSManagedObjectContextDidSave,
                    object: modelContext,
                    queue: .main
                ) { _ in
                    Task {
                        await MainActor.run {
                            viewModel.fetchMovies()
                        }
                    }
                }
            }
        }
        .tint(ThemeConstants.Colors.accent)
        .onAppear {
            viewModel.fetchMovies()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
        .onChange(of: modelContext) { newContext, _ in
            viewModel.modelContext = newContext
            viewModel.fetchMovies()
        }
    }
}
