// Recommendation Engine voor het aanbevelen van albums
// Deze class analyseert gebruiker voorkeuren en doet aanbevelingen
import Foundation

// Aanbeveling model
struct AlbumRecommendation: Codable, Identifiable {
    let id: String
    let album: SpotifyAlbum
    let score: Double // Aanbeveling score (0.0 - 1.0)
    let reason: String // Reden voor aanbeveling
    let tags: [String] // Genre/stijl tags
    let similarTo: String? // Album waar dit op lijkt
    let createdAt: Date
    
    init(album: SpotifyAlbum, score: Double, reason: String, tags: [String] = [], similarTo: String? = nil) {
        self.id = UUID().uuidString
        self.album = album
        self.score = score
        self.reason = reason
        self.tags = tags
        self.similarTo = similarTo
        self.createdAt = Date()
    }
}

// Gebruiker muziek profiel
struct UserMusicProfile: Codable {
    let userId: String
    var favoriteGenres: [String: Double] // Genre -> Weight mapping
    var favoriteArtists: [String: Int] // Artist -> Count mapping
    var averageRatingByGenre: [String: Double] // Genre -> Average rating
    var ratingHistory: [AlbumRatingAnalysis] // Historische rating analyse
    var discoveryPreferences: DiscoveryPreferences
    var lastUpdated: Date
    
    init(userId: String) {
        self.userId = userId
        self.favoriteGenres = [:]
        self.favoriteArtists = [:]
        self.averageRatingByGenre = [:]
        self.ratingHistory = []
        self.discoveryPreferences = DiscoveryPreferences()
        self.lastUpdated = Date()
    }
}

// Discovery voorkeuren
struct DiscoveryPreferences: Codable {
    var preferPopular: Bool = true // Voorkeur voor populaire albums
    var preferNew: Bool = true // Voorkeur voor nieuwe releases
    var preferSimilar: Bool = true // Voorkeur voor vergelijkbare muziek
    var adventurousness: Double = 0.5 // Hoe avontuurlijk (0.0 = safe, 1.0 = experimental)
    var excludeGenres: [String] = [] // Genres om te vermijden
    var preferredDecades: [String] = [] // Gewenste decennia
}

// Album rating analyse
struct AlbumRatingAnalysis: Codable {
    let albumId: String
    let rating: Int
    let genres: [String]
    let artist: String
    let releaseYear: Int?
    let ratedAt: Date
    let confidence: Double // Hoe zeker zijn we van de genre classificatie
}

// Recommendation Engine class
class RecommendationEngine: ObservableObject {
    
    // Singleton instance
    static let shared = RecommendationEngine()
    
    // UserDefaults keys
    private let profilesKey = "user_music_profiles"
    private let recommendationsKey = "cached_recommendations"
    
    // Published properties
    @Published var currentRecommendations: [AlbumRecommendation] = []
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    
    // Spotify Manager reference
    private let spotifyManager = SpotifyManager.shared
    private let storageManager = LocalStorageManager.shared
    
    private init() {
        loadCachedRecommendations()
    }
    
    // MARK: - Main Recommendation Functions
    
    // Genereer aanbevelingen voor de huidige gebruiker
    func generateRecommendations() async {
        guard let currentUser = storageManager.currentUser else { return }
        
        DispatchQueue.main.async {
            self.isAnalyzing = true
        }
        
        // Analyseer gebruiker profiel
        let profile = await analyzeUserProfile(userId: currentUser.id)
        
        // Genereer aanbevelingen
        let recommendations = await generateRecommendations(for: profile)
        
        DispatchQueue.main.async {
            self.currentRecommendations = recommendations
            self.isAnalyzing = false
            self.lastAnalysisDate = Date()
            self.cacheRecommendations(recommendations)
        }
    }
    
    // Analyseer gebruiker muziek profiel
    private func analyzeUserProfile(userId: String) async -> UserMusicProfile {
        var profile = loadUserProfile(userId: userId) ?? UserMusicProfile(userId: userId)
        
        // Haal alle ratings van de gebruiker op
        let userRatings = storageManager.getAllRatings().filter { $0.userId == userId }
        
        // Reset counters voor nieuwe analyse
        profile.favoriteGenres.removeAll()
        profile.favoriteArtists.removeAll()
        profile.averageRatingByGenre.removeAll()
        profile.ratingHistory.removeAll()
        
        // Analyseer elke rating
        for rating in userRatings {
            // Geschatte genres gebaseerd op artiest (simpele heuristiek)
            let estimatedGenres = estimateGenres(for: rating.artistName)
            let releaseYear = extractYear(from: rating.createdAt)
            
            let analysis = AlbumRatingAnalysis(
                albumId: rating.albumId,
                rating: rating.rating,
                genres: estimatedGenres,
                artist: rating.artistName,
                releaseYear: releaseYear,
                ratedAt: rating.createdAt,
                confidence: 0.7 // Basis confidence level
            )
            
            profile.ratingHistory.append(analysis)
            
            // Update artiest voorkeur
            profile.favoriteArtists[rating.artistName, default: 0] += 1
            
            // Update genre voorkeuren gebaseerd op rating
            for genre in estimatedGenres {
                let currentWeight = profile.favoriteGenres[genre, default: 0.0]
                let ratingWeight = Double(rating.rating) / 5.0 // Normaliseer naar 0.0-1.0
                profile.favoriteGenres[genre] = currentWeight + ratingWeight
                
                // Update gemiddelde rating per genre
                let currentAvg = profile.averageRatingByGenre[genre, default: 0.0]
                let currentCount = profile.ratingHistory.filter { $0.genres.contains(genre) }.count
                profile.averageRatingByGenre[genre] = ((currentAvg * Double(currentCount - 1)) + Double(rating.rating)) / Double(currentCount)
            }
        }
        
        // Normaliseer genre gewichten
        let maxWeight = profile.favoriteGenres.values.max() ?? 1.0
        for genre in profile.favoriteGenres.keys {
            profile.favoriteGenres[genre] = profile.favoriteGenres[genre]! / maxWeight
        }
        
        profile.lastUpdated = Date()
        saveUserProfile(profile)
        
        return profile
    }
    
    // Genereer aanbevelingen gebaseerd op profiel
    private func generateRecommendations(for profile: UserMusicProfile) async -> [AlbumRecommendation] {
        var recommendations: [AlbumRecommendation] = []
        
        // Verschillende aanbeveling strategieën
        recommendations += await generateGenreBasedRecommendations(profile: profile)
        recommendations += await generateArtistBasedRecommendations(profile: profile)
        recommendations += await generateTrendingRecommendations(profile: profile)
        
        // Sorteer op score en retourneer top 15
        return Array(recommendations.sorted { $0.score > $1.score }.prefix(15))
    }
    
    // Genre-gebaseerde aanbevelingen
    private func generateGenreBasedRecommendations(profile: UserMusicProfile) async -> [AlbumRecommendation] {
        var recommendations: [AlbumRecommendation] = []
        
        // Voor elk favoriete genre, zoek albums
        for (genre, weight) in profile.favoriteGenres.sorted(by: { $0.value > $1.value }).prefix(3) {
            do {
                let searchResults = try await spotifyManager.searchAlbums(query: genre)
                
                for album in searchResults.prefix(3) {
                    // Check of gebruiker dit album al heeft beoordeeld
                    let hasRated = storageManager.hasUserRatedAlbum(userId: profile.userId, albumId: album.id) != nil
                    
                    if !hasRated {
                        let score = weight * 0.8 + Double.random(in: 0.0...0.2)
                        let recommendation = AlbumRecommendation(
                            album: album,
                            score: score,
                            reason: "Gebaseerd op je voorkeur voor \(genre)",
                            tags: [genre],
                            similarTo: nil
                        )
                        recommendations.append(recommendation)
                    }
                }
            } catch {
                print("Fout bij zoeken naar \(genre): \(error)")
            }
            
            // Korte pauze tussen API calls
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconden
        }
        
        return recommendations
    }
    
    // Artiest-gebaseerde aanbevelingen
    private func generateArtistBasedRecommendations(profile: UserMusicProfile) async -> [AlbumRecommendation] {
        var recommendations: [AlbumRecommendation] = []
        
        // Voor elke favoriete artiest, zoek gerelateerde albums
        for (artist, count) in profile.favoriteArtists.sorted(by: { $0.value > $1.value }).prefix(2) {
            do {
                let searchResults = try await spotifyManager.searchAlbums(query: artist)
                
                for album in searchResults.prefix(2) {
                    // Check of gebruiker dit album al heeft beoordeeld
                    let hasRated = storageManager.hasUserRatedAlbum(userId: profile.userId, albumId: album.id) != nil
                    
                    if !hasRated {
                        let artistWeight = Double(count) / Double(profile.favoriteArtists.values.max() ?? 1)
                        let score = artistWeight * 0.9 + Double.random(in: 0.0...0.1)
                        let recommendation = AlbumRecommendation(
                            album: album,
                            score: score,
                            reason: "Meer werk van \(artist), een van je favoriete artiesten",
                            tags: ["favorite-artist"],
                            similarTo: artist
                        )
                        recommendations.append(recommendation)
                    }
                }
            } catch {
                print("Fout bij zoeken naar \(artist): \(error)")
            }
            
            // Korte pauze tussen API calls
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconden
        }
        
        return recommendations
    }
    
    // Trending/populaire aanbevelingen
    private func generateTrendingRecommendations(profile: UserMusicProfile) async -> [AlbumRecommendation] {
        var recommendations: [AlbumRecommendation] = []
        
        if profile.discoveryPreferences.preferPopular {
            let trendingQueries = ["popular 2024", "best albums"]
            
            for query in trendingQueries.prefix(2) {
                do {
                    let searchResults = try await spotifyManager.searchAlbums(query: query)
                    
                    for album in searchResults.prefix(2) {
                        let hasRated = storageManager.hasUserRatedAlbum(userId: profile.userId, albumId: album.id) != nil
                        
                        if !hasRated {
                            let score = 0.6 + Double.random(in: 0.0...0.3)
                            let recommendation = AlbumRecommendation(
                                album: album,
                                score: score,
                                reason: "Trending en populair dit jaar",
                                tags: ["trending", "popular"],
                                similarTo: nil
                            )
                            recommendations.append(recommendation)
                        }
                    }
                } catch {
                    print("Fout bij zoeken naar trending albums: \(error)")
                }
                
                // Korte pauze tussen API calls
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconden
            }
        }
        
        return recommendations
    }
    
    // MARK: - Helper Functions
    
    // Schat genres gebaseerd op artiest (simpele heuristiek)
    private func estimateGenres(for artist: String) -> [String] {
        let artistLower = artist.lowercased()
        
        // Simpele genre mapping gebaseerd op bekende artiesten
        let genreMapping: [String: [String]] = [
            "taylor swift": ["pop", "country", "folk"],
            "the beatles": ["rock", "pop", "classic"],
            "radiohead": ["alternative", "rock", "electronic"],
            "miles davis": ["jazz", "fusion"],
            "daft punk": ["electronic", "dance", "house"],
            "billie eilish": ["pop", "alternative", "indie"],
            "michael jackson": ["pop", "r&b", "funk"],
            "nirvana": ["grunge", "rock", "alternative"],
            "bob dylan": ["folk", "rock", "country"],
            "kanye west": ["hip-hop", "rap", "electronic"]
        ]
        
        // Zoek exacte match
        if let genres = genreMapping[artistLower] {
            return genres
        }
        
        // Fallback genres
        return ["pop", "general"]
    }
    
    // Extraheer jaar uit datum
    private func extractYear(from date: Date) -> Int? {
        let calendar = Calendar.current
        return calendar.component(.year, from: date)
    }
    
    // MARK: - Data Persistence
    
    // Laad gebruiker profiel
    private func loadUserProfile(userId: String) -> UserMusicProfile? {
        guard let data = UserDefaults.standard.data(forKey: "\(profilesKey)_\(userId)"),
              let profile = try? JSONDecoder().decode(UserMusicProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    // Sla gebruiker profiel op
    private func saveUserProfile(_ profile: UserMusicProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "\(profilesKey)_\(profile.userId)")
        }
    }
    
    // Laad gecachte aanbevelingen
    private func loadCachedRecommendations() {
        guard let currentUser = storageManager.currentUser,
              let data = UserDefaults.standard.data(forKey: "\(recommendationsKey)_\(currentUser.id)"),
              let recommendations = try? JSONDecoder().decode([AlbumRecommendation].self, from: data) else {
            return
        }
        
        DispatchQueue.main.async {
            self.currentRecommendations = recommendations
        }
    }
    
    // Cache aanbevelingen
    private func cacheRecommendations(_ recommendations: [AlbumRecommendation]) {
        guard let currentUser = storageManager.currentUser,
              let data = try? JSONEncoder().encode(recommendations) else {
            return
        }
        
        UserDefaults.standard.set(data, forKey: "\(recommendationsKey)_\(currentUser.id)")
    }
    
    // MARK: - Public Helper Functions
    
    // Markeer aanbeveling als bekeken/genegeerd
    func markRecommendationAsSeen(_ recommendationId: String) {
        DispatchQueue.main.async {
            self.currentRecommendations.removeAll { $0.id == recommendationId }
        }
    }
    
    // Check of er recente aanbevelingen zijn (minder dan 24 uur oud)
    func hasRecentRecommendations() -> Bool {
        guard let lastAnalysis = lastAnalysisDate else { return false }
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return lastAnalysis > dayAgo && !currentRecommendations.isEmpty
    }
} 