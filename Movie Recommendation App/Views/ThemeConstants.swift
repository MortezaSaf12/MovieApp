//
//  ThemeConstants.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-03-08.
//

import SwiftUI
import Foundation

//CHATGPT!

struct ThemeConstants {
    // MARK: - Colors
    struct Colors {
        static let background = Color.black
        static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.13)
        static let accent = Color(red: 0.87, green: 0.2, blue: 0.23) // Cinema red
        static let secondaryAccent = Color(red: 0.95, green: 0.81, blue: 0.32) // Gold
        static let text = Color.white
        static let secondaryText = Color.gray
        
        // Rating colors
        static func ratingColor(for rating: Double) -> Color {
            switch rating {
            case 0..<5:
                return Color(red: 0.85, green: 0.24, blue: 0.24) // Red for low ratings
            case 5..<7:
                return Color(red: 0.95, green: 0.68, blue: 0.24) // Orange for medium ratings
            default:
                return Color(red: 0.24, green: 0.85, blue: 0.34) // Green for high ratings
            }
        }
        
        // Genre-based gradient generation
        static func genreGradient(for genre: String) -> Gradient {
            switch genre {
            case "Action", "Adventure", "Thriller", "War":
                return Gradient(colors: [Color(red: 0.8, green: 0.2, blue: 0.2), Color(red: 0.5, green: 0.1, blue: 0.1)])
            case "Comedy", "Family", "Animation":
                return Gradient(colors: [Color(red: 0.9, green: 0.7, blue: 0.1), Color(red: 0.7, green: 0.4, blue: 0.1)])
            case "Drama", "Romance", "Music":
                return Gradient(colors: [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 0.2, green: 0.1, blue: 0.5)])
            case "Horror", "Mystery", "Crime":
                return Gradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.1)])
            case "Sci-Fi", "Fantasy":
                return Gradient(colors: [Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.1, green: 0.2, blue: 0.5)])
            default:
                return Gradient(colors: [Color(red: 0.3, green: 0.3, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.1)])
            }
        }
    }
    
    // MARK: - Dimensions
    struct Dimensions {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        static let posterHeightRegular: CGFloat = 220
        static let posterHeightLarge: CGFloat = 280
        static let posterWidth: CGFloat = 150
        
        static let genreButtonHeight: CGFloat = 36
    }
    
    // MARK: - Animation
    struct Animations {
        static let standardSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let slowSpring = Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let fastSpring = Animation.spring(response: 0.2, dampingFraction: 0.7)
    }
}
