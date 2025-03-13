//
//  HomeContentView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-03-10.
//

import SwiftUI

struct HomeContentView: View {
    @State var viewModel: HomeViewModel
    @Binding var searchText: String
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            Group {
                if !searchText.isEmpty {
                    List(viewModel.searchResults) { movie in
                        NavigationLink(destination: MovieDetailView(movieID: movie.id)) {
                            MovieRowView(movie: movie)
                                .foregroundColor(ThemeConstants.Colors.text)
                        }
                    }
                    .listStyle(.plain)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            GenreSelectorView(selectedGenre: $viewModel.selectedGenre,
                                              genres: viewModel.genres)
                                .padding(.top, 8)
                            
                            MovieSectionView(
                                title: "Popular Movies",
                                movies: viewModel.popularMovies,
                                recommendationImages: viewModel.recommendationImages
                            )
                            
                            MovieSectionView(
                                title: "Top Rated Movies",
                                movies: viewModel.topRated,
                                recommendationImages: viewModel.recommendationImages
                            )
                            
                            MovieSectionView(
                                title: "Upcoming Movies",
                                movies: viewModel.upcomingMovies,
                                recommendationImages: viewModel.recommendationImages
                            )
                            
                            if !viewModel.recommendedMovies.isEmpty {
                                MovieSectionView(
                                    title: "You Might Also Like",
                                    movies: viewModel.recommendedMovies,
                                    recommendationImages: viewModel.recommendationImages
                                )
                            }
                        }
                        .padding(.vertical)
                        .foregroundColor(ThemeConstants.Colors.text)
                    }
                }
            }
            .refreshable {
                Task {
                    await viewModel.fetchAllData(context: context)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("WatchList")
                        .font(.headline)
                        .foregroundColor(ThemeConstants.Colors.text)
                }
            }
            .toolbarBackground(ThemeConstants.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark)
            .searchable(text: $searchText)
            .onChange(of: searchText) {
                if searchText.isEmpty {
                    viewModel.searchResults = []
                } else {
                    viewModel.handleSearch(text: searchText)
                }
            }
            .onChange(of: viewModel.selectedGenre) {
                if !searchText.isEmpty {
                    viewModel.handleSearch(text: searchText)
                } else {
                    viewModel.fetchInitialMovies()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                Task {
                    await viewModel.fetchRecommendations(context: context)
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchAllData(context: context)
                }
            }
            .background(ThemeConstants.Colors.background)
            .foregroundColor(ThemeConstants.Colors.text)
        }
    }
}

#Preview {
    HomeContentView(viewModel: HomeViewModel(), searchText: .constant(""))
}
