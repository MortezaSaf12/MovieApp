//
//  Movie_Recommendation_AppApp.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import SwiftUI
import SwiftData

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [User.self, Movie.self])  // SwiftData container for User and Movies
    }
}

