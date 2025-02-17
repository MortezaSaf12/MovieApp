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
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView("Loading...")
        } else {
            // TODO
        }
    }
}

#Preview {
    HomeView()
}
