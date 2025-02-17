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
    
    let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 16)
    ]
    
    var body: some View {
        TabView {
            NavigationStack {
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                    } else if !viewModel.errorMessage.isEmpty {
                        Text("Error: \(viewModel.errorMessage)")
                            .foregroundColor(.red)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.movies, id: \.imdbID) { movie in
                                    MovieGridItemView(movie: movie)
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
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            WatchListView()
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
            AsyncImage(url: URL(string: movie.poster)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 120, height: 180)
            .cornerRadius(8)
            
            Text(movie.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(maxWidth: 120)
            
            Text("(\(movie.year))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
    }
}

#Preview {
    HomeView()
}
