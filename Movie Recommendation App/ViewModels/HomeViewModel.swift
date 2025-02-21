//
//  HomeViewModel.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import SwiftUI
import Observation

@Observable
class HomeViewModel {
    var movies: [MovieSearchItem] = []
    var isLoading = false
    var errorMessage: String = ""
    private var searchTask: Task<Void, Never>?
    
    var selectedGenre: String = "All"
    let genres = ["All", "Action", "Adventure", "Comedy", "Crime", "Drama", "Fantasy", "Horror", "Romance", "Sci-Fi", "Thriller"]
    
    func fetchInitialMovies() {
        Task {
            await fetchMovies(searchTerm: "2023")
        }
    }
    
    func handleSearch(text: String) {
        guard !text.isEmpty else {
            movies = []
            return
        }
        
        searchTask?.cancel()
        searchTask = Task {
            guard !Task.isCancelled else { return }
            await fetchMovies(searchTerm: text)
        }
    }
    
    func fetchMovies(searchTerm: String) async {
        isLoading = true
        
        do {
            let results = try await APIService.shared.searchMovies(searchTerm: searchTerm)
            
            if selectedGenre == "All"{
                await MainActor.run {
                    movies = results
                    isLoading = false
                    errorMessage = "error due to genre selection"
                }
            } else {
               // more logic coming
            }
            
            await MainActor.run {
                movies = results
                isLoading = false
                errorMessage = ""
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
                movies = []
            }
        }
    }
}
