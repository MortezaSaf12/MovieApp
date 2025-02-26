//
//  MovieReview.swift
//  Movie Recommendation App
//
//  Created by Artin Seyhani Porshekoh on 2025-02-26.
//

import Foundation

struct MovieReview: Decodable, Identifiable {
    let id: String
    let author: String
    let content: String
    let createdAt: String
    let authorDetails: AuthorDetails?
    
    enum CodingKeys: String, CodingKey {
        case id
        case author
        case content
        case createdAt = "created_at"
        case authorDetails = "author_details"
    }
    
    struct AuthorDetails: Decodable {
        let name: String?
        let username: String
        let rating: Double?
        
        enum CodingKeys: String, CodingKey {
            case name
            case username
            case rating
        }
    }
}

struct MovieReviewsResponse: Decodable {
    let page: Int
    let results: [MovieReview]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
