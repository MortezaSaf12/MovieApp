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
    var errorMessage: String? = nil
    
    func fetchMovies() {
        isLoading = true
        Task {
            do {
                let results = try await APIService.shared.searchMovies(searchTerm: "Batman") //initial default search term
                movies = results
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            
        }
    }
}
