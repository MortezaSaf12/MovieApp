//
//  HomeView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var context
    @State private var searchText = ""
    
    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        genreSelector
                        movieSection(title: "Popular Movies", movies: viewModel.movies)
                        
                        if !viewModel.recommendations.isEmpty {
                            movieSection(title: "You Might Also Like", movies: viewModel.recommendations)
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle("WatchList")
                .searchable(text: $searchText)
                .onChange(of: searchText) {
                    viewModel.handleSearch(text: searchText)
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
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            WatchlistView()
                .tabItem {
                    Label("Bookmarks", systemImage: "list.and.film")
                }
        }
        .task {
            viewModel.fetchInitialMovies()
                await viewModel.fetchRecommendations(context: context)
        }
    }
    
    private var genreSelector: some View {
        HStack {
            Spacer()
            Text("Select Genre: ")
            Menu {
                ForEach(viewModel.genres, id: \.self) { genre in
                    Button(genre) {
                        viewModel.selectedGenre = genre
                    }
                }
            } label: {
                Text(viewModel.selectedGenre)
                    .foregroundColor(.primary)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                    )
            }
            Spacer()
        }
        .padding(.top, 2)
        .padding(.bottom, 12)
    }
    
    private func movieSection(title: String, movies: [MovieSearchItem]) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(movies) { movie in
                        NavigationLink(destination: MovieDetailView(movieID: movie.id)) {
                            MovieGridItemView(movie: movie,
                                                imageData: viewModel.recommendationImages[movie.id])
                                .frame(width: 120)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct MovieGridItemView: View {
    let movie: MovieSearchItem
    var imageData: Data? = nil
    
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


#Preview {
    HomeView()
}
