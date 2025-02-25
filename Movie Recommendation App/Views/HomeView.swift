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
    
    let columns = [GridItem(.adaptive(minimum: 120), spacing: 16)]
    
    var body: some View {
        TabView {
            NavigationStack {
                VStack(alignment: .leading, spacing: 0) {
                    
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
                    
                    
                    Group {
                        if viewModel.isLoading {
                            ProgressView("Loading...")
                        } else if !viewModel.errorMessage.isEmpty {
                            Text("Error: \(viewModel.errorMessage)")
                                .foregroundColor(.red)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(viewModel.movies, id: \.id) { movie in
                                        NavigationLink(destination: MovieDetailView(movieID: movie.id)) {
                                            MovieGridItemView(movie: movie)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .navigationTitle("WatchList")
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                    .onSubmit(of: .search) {
                        viewModel.handleSearch(text: searchText)
                    }
                    .onChange(of: viewModel.selectedGenre) {
                        if !searchText.isEmpty {
                            viewModel.handleSearch(text: searchText)
                        } else {
                            viewModel.fetchInitialMovies()
                        }
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
        .onAppear {
            viewModel.fetchInitialMovies()
        }
    }
}

struct MovieGridItemView: View {
    let movie: MovieSearchItem
    
    var body: some View {
        VStack(spacing: 8) {
            ImageLoadingView(url: APIService.shared.fullPosterURL(for: movie.posterPath), maxWidth: 120, height: 180)
            .frame(width: 120, height: 180)
            .cornerRadius(8)
            
            Text(movie.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(maxWidth: 120)
            
            Text("(\(String(movie.releaseDate.prefix(4))))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
    }
}

#Preview {
    HomeView()
}
