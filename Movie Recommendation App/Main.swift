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
        .modelContainer(for: [UserPreferences.self, WatchlistMovie.self]) { result in
            switch result {
            case .success(let container):
                let context = container.mainContext
                let fetchRequest = FetchDescriptor<UserPreferences>()
                if ((try? context.fetch(fetchRequest).isEmpty) != nil) {
                    context.insert(UserPreferences())
                    try? context.save()
                }
            case .failure(let error):
                print("Failed to create model container: \(error)")
            }
        }
    }
}

