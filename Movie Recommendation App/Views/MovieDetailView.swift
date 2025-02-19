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
    
    @State private var viewModel = MovieDetailViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var bookmarkTask: Task<Void, Never>?

    @State private var isBookmarked = false

    init(imdbID: String, isBookmarked: Bool = false) {
        self.imdbID = imdbID
        self._isBookmarked = State(initialValue: isBookmarked)
    }
    
    @MainActor
    private func checkBookmarkStatus() async {
        
        guard let imdbID = viewModel.movieDetail?.imdbID else { return }
        
        let descriptor = FetchDescriptor<WatchlistMovie>(
            predicate: #Predicate { $0.imdbID == imdbID }
        )
        
        do {
            let count = try modelContext.fetchCount(descriptor)
            isBookmarked = count > 0
        } catch {
            print("Error checking bookmark status: \(error)")
        }
    }
    
    @MainActor
    private func addToWatchlist() async{
        guard let movie = viewModel.movieDetail else { return }
        let targetIMDbID = movie.imdbID
        
        let existingCheck = FetchDescriptor<WatchlistMovie>(
            predicate: #Predicate { $0.imdbID == targetIMDbID }
        )
        
        do {
            let existingCount = try modelContext.fetchCount(existingCheck)
            print("exists?")
            guard existingCount == 0 else {
                print("Movie already in watchlist")
                isBookmarked = true
                return
            }
            
            let newBookmark = WatchlistMovie(
                imdbID: targetIMDbID,
                title: movie.title,
                year: movie.year,
                poster: movie.poster
            )
            modelContext.insert(newBookmark)
            print("modelContext.save")
            try modelContext.save()
            isBookmarked = true
        } catch {
            print("Error saving bookmark: \(error)")
        }
    }
    
    @MainActor
    private func removeFromWatchlist() async {
        guard let imdbID = viewModel.movieDetail?.imdbID else { return }
        
        let descriptor = FetchDescriptor<WatchlistMovie>(
            predicate: #Predicate { $0.imdbID == imdbID }
        )
        
        do {
            let items = try modelContext.fetch(descriptor)
            for item in items {
                modelContext.delete(item)
            }
            try modelContext.save()
            isBookmarked = false
        } catch {
            print("Remove failed: \(error)")
        }
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
                await viewModel.fetchMovieDetails(imdbID: imdbID)
                await checkBookmarkStatus()
                
                NotificationCenter.default.addObserver(
                    forName: .NSManagedObjectContextDidSave,
                    object: modelContext,
                    queue: .main
                ) { _ in
                    Task {
                        await checkBookmarkStatus()
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
                    Task {
                        if isBookmarked {
                            await removeFromWatchlist()
                        } else {
                            await addToWatchlist()
                        }
                    }
                } label:{
                    //ChatGPT
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title)
                        .foregroundColor(.black)
                        .scaleEffect(x: 1.0, y: 0.8, anchor: .center)
                        .frame(width: 30) // Optional: Only apply a width frame
                }
            }
        }
    }
}
