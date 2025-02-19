//
//  WatchlistView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

// WatchlistView.swift
import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Query(sort: \WatchlistMovie.title) private var watchlistMovies: [WatchlistMovie]

    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            Group {
                if watchlistMovies.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark.slash",
                        description: Text("Save movies to see them here")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(watchlistMovies) { movie in
                                NavigationLink(destination: MovieDetailView(imdbID: movie.imdbID, isBookmarked: true)) {
                                    MovieGridItemView(movie: MovieSearchItem(
                                        title: movie.title,
                                        year: movie.year,
                                        imdbID: movie.imdbID,
                                        type: nil,
                                        poster: movie.poster
                                    ))
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
