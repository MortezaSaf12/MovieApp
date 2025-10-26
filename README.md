# Movie Recommendation App

iOS movie discovery application that provides personalized movie recommendations based on user preferences and viewing history using The Movie Database (TMDb) API.

## Features

### Core Functionality
- **Personalized Recommendations**: Intelligent algorithm analyzes bookmarked movies and genre preferences
- **Movie Search**: Search movies with genre filtering
- **Multiple Browse Categories**: Popular, Top Rated, and Upcoming movies
- **Detailed Movie Information**: Runtime, ratings, genres, overview, and reviews
- **Bookmark System**: Save movies to watchlist with offline poster caching
- **User Preferences**: Customize favorite genres, prioritize up to 3 genres, and set minimum rating threshold

### Smart Recommendation System
The app uses a sophisticated multi-factor algorithm:
- Analyzes genres from bookmarked movies
- Weights favorite and prioritized genres
- Considers minimum rating preferences
- Filters out already-bookmarked movies
- Scores movies based on genre overlap with preferences

## Tech Stack
SwiftUI, SwiftData, Swift Concurrency, TMDb API, MVVM Architecture

## MVVM Architecture
Models, ViewModels, Views

### Services
- `APIService` - TMDb API integration with async/await

## Key Features Implementation

### Recommendation Algorithm
1. Computes genre frequency from watchlist movies
2. Applies bonus weighting to favorite genres
3. Additional weighting for prioritized genres
4. Fetches movies matching top 3 genres above minimum rating
5. Scores by genre overlap with favorites
6. Returns top 20 scored recommendations

### Data Persistence
- SwiftData for local storage
- Caches poster images offline
- Maintains user preferences across sessions
- Relationship mapping between preferences and watchlist

## Requirements

- iOS 17.0+
- Xcode 15.0+
- TMDb API key (included in code)

## Setup

1. Clone the repository
2. Open the project in Xcode
3. Build and run on simulator or device
4. Configure your preferences in the Settings tab
5. Start bookmarking movies to get personalized recommendations

## API Integration

Uses [The Movie Database (TMDb) API](https://www.themoviedb.org/documentation/api) for:
- Movie search
- Popular/Top Rated/Upcoming movies (Real time)
- Detailed movie information
- User reviews
- Similar movies
- Genre-based discovery
- High-quality poster images

## Authors
- Morteza Safari
- Artin Seyhani Porshekoh
