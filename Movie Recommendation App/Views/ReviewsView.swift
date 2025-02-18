
//
//  ReviewsView.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-09.
//

import Foundation
import SwiftUI

struct ReviewsView: View {
    let imdbID: String
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Reviews from another API
            }
            .padding()
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
    }
}
