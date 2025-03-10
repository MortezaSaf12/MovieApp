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
            HomeContentView(viewModel: viewModel, searchText: $searchText)
            .tabItem {
                Label("Home", systemImage: "house")
                    .foregroundColor(ThemeConstants.Colors.text)
            }
            
            WatchlistView()
                .tabItem {
                    Label("Bookmarks", systemImage: "list.and.film")
                        .foregroundColor(ThemeConstants.Colors.text)
                }
            
            SettingsView()
                .tabItem {
                    Label("Preferences", systemImage: "slider.horizontal.3")
                        .foregroundColor(ThemeConstants.Colors.text)
                }
        }
        .accentColor(ThemeConstants.Colors.accent)
    }
}

#Preview {
    HomeView()
}
