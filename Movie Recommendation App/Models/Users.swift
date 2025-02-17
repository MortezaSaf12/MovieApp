//
//  Users.swift
//  Movie Recommendation App
//
//  Created by Morteza Safari on 2025-02-17.
//

import Foundation
import SwiftData

@Model
final class User {
    var name: String
    var preferences: [String]
    @Relationship(deleteRule: .cascade) var savedMovies: [Movie] = [] // One-to-many relationship, a user can save many Movie objects
    
    init(name: String, preferences: [String]) {
        self.name = name
        self.preferences = preferences
    }
}
