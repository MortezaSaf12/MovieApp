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
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Menu {
                            Button("Action") {  }
                            Button("Adventure") {  }
                            Button("Comedy") {  }
                            Button("Crime") {  }
                            Button("Drama") {  }
                            Button("Fantasy") {  }
                            Button("Horror") {  }
                            Button("Romance") {  }
                            Button("Sci-Fi") {  }
                            Button("Thriller") { }
                        } label: {
                            Text("Genre")
                                .foregroundColor(.primary)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 140)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                                )
                            
                        }
                    }
                    .padding(.horizontal, 32)
                    
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
                                    ForEach(viewModel.movies, id: \.imdbID) { movie in
                                        NavigationLink(destination: MovieDetailView(imdbID: movie.imdbID)) {
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
