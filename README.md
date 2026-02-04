# Movie Recommendation App

An iOS movie discovery application that provides personalized movie recommendations based on user preferences and viewing history, powered by The Movie Database (TMDb) API.

## About

This app helps users discover new movies tailored to their tastes. By analyzing your bookmarked movies and genre preferences, the smart recommendation algorithm suggests films you're likely to enjoy. Browse popular, top-rated, and upcoming movies, search with filters, and build your personal watchlist.

## Features

- **Personalized Recommendations** — Intelligent algorithm analyzes your bookmarks and genre preferences to suggest movies
- **Movie Search** — Find movies with genre filtering options
- **Browse Categories** — Explore Popular, Top Rated, and Upcoming movies
- **Detailed Information** — View runtime, ratings, genres, overview, and user reviews
- **Bookmark System** — Save movies to your watchlist with offline poster caching
- **User Preferences** — Set favorite genres, prioritize up to 3 genres, and define minimum rating thresholds

## How the Recommendation Algorithm Works

The app uses a sophisticated multi-factor scoring system:

1. Analyzes genre frequency from your bookmarked movies
2. Applies bonus weighting to your favorite genres
3. Adds additional weighting for prioritized genres (top 3)
4. Fetches movies matching top genres above your minimum rating
5. Scores each movie based on genre overlap with your preferences
6. Returns the top 20 highest-scored recommendations
7. Filters out movies you've already bookmarked

## Tech Stack

| Technology | Purpose |
|------------|---------|
| SwiftUI | User interface |
| SwiftData | Local data persistence |
| Swift Concurrency | Async/await networking |
| TMDb API | Movie data source |
| MVVM | Architecture pattern |

## Project Structure (MVVM)

```
Movie Recommendation App/
├── Models/              # Data models
├── ViewModels/          # Business logic and state management
├── Views/               # SwiftUI views
├── Services/
│   └── APIService       # TMDb API integration with async/await
└── Resources/           # Assets and configuration
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- TMDb API key (included in code)

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/MortezaSaf12/MovieApp.git
   ```

2. **Open in Xcode**
   ```bash
   cd MovieApp
   open "Movie Recommendation App.xcodeproj"
   ```

3. **Build and run** on simulator or device

4. **Configure preferences** in the Settings tab

5. **Start bookmarking** movies to receive personalized recommendations

## API Integration

The app integrates with [The Movie Database (TMDb) API](https://www.themoviedb.org/documentation/api) for:

- Movie search functionality
- Popular, Top Rated, and Upcoming movie lists (real-time)
- Detailed movie information
- User reviews
- Similar movie suggestions
- Genre-based discovery
- High-quality poster images

## Data Persistence

- **SwiftData** for local storage
- Offline poster image caching
- Persistent user preferences across sessions
- Relationship mapping between preferences and watchlist

## Authors

- **Morteza Safari** — [GitHub](https://github.com/MortezaSaf12)
- **Artin Seyhani Porshekoh**

## Acknowledgments

- [The Movie Database (TMDb)](https://www.themoviedb.org/) for providing the movie data API

---

Project Link: [https://github.com/MortezaSaf12/MovieApp](https://github.com/MortezaSaf12/MovieApp)
