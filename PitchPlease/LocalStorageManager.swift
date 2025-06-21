// Lokale Storage Manager voor het opslaan van data zonder Firebase
// Deze class gebruikt UserDefaults en JSON encoding voor data persistentie
import Foundation

// Lokale gebruiker model
struct LocalUser: Codable {
    let id: String
    let email: String
    let displayName: String
    let createdAt: Date
    
    init(email: String, displayName: String) {
        self.id = UUID().uuidString
        self.email = email
        self.displayName = displayName
        self.createdAt = Date()
    }
    
    init(id: String, email: String, displayName: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = Date()
    }
}

// Lokale album rating model (zonder Firebase dependencies)
struct LocalAlbumRating: Codable, Identifiable {
    let id: String
    let userId: String
    let userDisplayName: String
    let albumId: String
    let albumName: String
    let artistName: String
    let albumImageUrl: String?
    let rating: Int // 1 tot 5 sterren
    let review: String? // Optionele recensie tekst
    let createdAt: Date
    let updatedAt: Date
    
    // Custom initializer voor nieuwe ratings
    init(userId: String, userDisplayName: String, album: SpotifyAlbum, rating: Int, review: String?) {
        self.id = UUID().uuidString
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.albumId = album.id
        self.albumName = album.name
        self.artistName = album.artistNames
        self.albumImageUrl = album.imageUrl
        self.rating = rating
        self.review = review
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
    
    // Initializer voor updates
    init(id: String, userId: String, userDisplayName: String, albumId: String, albumName: String, artistName: String, albumImageUrl: String?, rating: Int, review: String?, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.albumId = albumId
        self.albumName = albumName
        self.artistName = artistName
        self.albumImageUrl = albumImageUrl
        self.rating = rating
        self.review = review
        self.createdAt = createdAt
        self.updatedAt = Date()
    }
    
    // Direct initializer
    init(id: String, userId: String, userDisplayName: String, albumId: String, albumName: String, artistName: String, albumImageUrl: String?, rating: Int, review: String?, createdAt: Date, updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.albumId = albumId
        self.albumName = albumName
        self.artistName = artistName
        self.albumImageUrl = albumImageUrl
        self.rating = rating
        self.review = review
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed property om rating te valideren
    var isValidRating: Bool {
        return rating >= 1 && rating <= 5
    }
}

// Manager class voor lokale data opslag
class LocalStorageManager: ObservableObject {
    
    // Singleton instance
    static let shared = LocalStorageManager()
    
    // UserDefaults keys
    private let usersKey = "stored_users"
    private let ratingsKey = "stored_ratings"
    private let currentUserKey = "current_user_id"
    
    // Published properties voor UI updates
    @Published var currentUser: LocalUser?
    @Published var isUserLoggedIn = false
    
    private init() {
        loadCurrentUser()
    }
    
    // MARK: - User Management
    
    // Functie om gebruiker in te loggen
    func signIn(email: String, password: String) throws {
        let users = getAllUsers()
        
        // Zoek gebruiker op email (password wordt genegeerd voor simpliciteit)
        guard let user = users.first(where: { $0.email.lowercased() == email.lowercased() }) else {
            throw LocalStorageError.userNotFound
        }
        
        currentUser = user
        isUserLoggedIn = true
        UserDefaults.standard.set(user.id, forKey: currentUserKey)
    }
    
    // Functie om nieuwe gebruiker aan te maken
    func signUp(email: String, password: String, displayName: String) throws {
        let users = getAllUsers()
        
        // Check of email al bestaat
        if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            throw LocalStorageError.emailAlreadyExists
        }
        
        // Nieuwe gebruiker aanmaken
        let newUser = LocalUser(email: email, displayName: displayName)
        var updatedUsers = users
        updatedUsers.append(newUser)
        
        // Opslaan
        saveUsers(updatedUsers)
        
        // Inloggen
        currentUser = newUser
        isUserLoggedIn = true
        UserDefaults.standard.set(newUser.id, forKey: currentUserKey)
    }
    
    // Functie om uit te loggen
    func signOut() {
        currentUser = nil
        isUserLoggedIn = false
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
    
    // Private functie om huidige gebruiker te laden
    private func loadCurrentUser() {
        guard let userId = UserDefaults.standard.string(forKey: currentUserKey) else { return }
        
        let users = getAllUsers()
        if let user = users.first(where: { $0.id == userId }) {
            currentUser = user
            isUserLoggedIn = true
        } else {
            // Gebruiker niet gevonden, uitloggen
            signOut()
        }
    }
    
    // MARK: - Rating Management
    
    // Functie om alle ratings op te halen
    func getAllRatings() -> [LocalAlbumRating] {
        guard let data = UserDefaults.standard.data(forKey: ratingsKey),
              let ratings = try? JSONDecoder().decode([LocalAlbumRating].self, from: data) else {
            return []
        }
        return ratings
    }
    
    // Functie om een nieuwe rating op te slaan
    func saveRating(_ rating: LocalAlbumRating) {
        var ratings = getAllRatings()
        ratings.append(rating)
        saveRatings(ratings)
    }
    
    // Functie om een bestaande rating te updaten
    func updateRating(_ rating: LocalAlbumRating) {
        var ratings = getAllRatings()
        
        if let index = ratings.firstIndex(where: { $0.id == rating.id }) {
            ratings[index] = rating
            saveRatings(ratings)
        }
    }
    
    // Functie om ratings van een specifieke gebruiker op te halen
    func getRatingsForUser(userId: String) -> [LocalAlbumRating] {
        let ratings = getAllRatings()
        return ratings
            .filter { $0.userId == userId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // Functie om alle publieke ratings op te halen
    func getAllPublicRatings(limit: Int = 50) -> [LocalAlbumRating] {
        let ratings = getAllRatings()
        return Array(ratings
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(limit))
    }
    
    // Functie om ratings voor een specifiek album op te halen
    func getRatingsForAlbum(albumId: String) -> [LocalAlbumRating] {
        let ratings = getAllRatings()
        return ratings
            .filter { $0.albumId == albumId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // Functie om gemiddelde rating voor een album te berekenen
    func getAverageRating(for albumId: String) -> Double {
        let ratings = getRatingsForAlbum(albumId: albumId)
        
        guard !ratings.isEmpty else { return 0.0 }
        
        let totalRating = ratings.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(ratings.count)
    }
    
    // Functie om te checken of gebruiker al een rating heeft voor een album
    func hasUserRatedAlbum(userId: String, albumId: String) -> LocalAlbumRating? {
        let ratings = getAllRatings()
        return ratings.first { $0.userId == userId && $0.albumId == albumId }
    }
    
    // Functie om een rating te verwijderen
    func deleteRating(ratingId: String) {
        var ratings = getAllRatings()
        ratings.removeAll { $0.id == ratingId }
        saveRatings(ratings)
    }
    
    // MARK: - Private Helper Methods
    
    private func getAllUsers() -> [LocalUser] {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([LocalUser].self, from: data) else {
            return []
        }
        return users
    }
    
    private func saveUsers(_ users: [LocalUser]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }
    
    private func saveRatings(_ ratings: [LocalAlbumRating]) {
        if let data = try? JSONEncoder().encode(ratings) {
            UserDefaults.standard.set(data, forKey: ratingsKey)
        }
    }
}

// Custom error types voor lokale opslag
enum LocalStorageError: Error, LocalizedError {
    case userNotFound
    case emailAlreadyExists
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Gebruiker niet gevonden. Controleer je email adres."
        case .emailAlreadyExists:
            return "Dit email adres is al in gebruik."
        case .invalidData:
            return "Ongeldige gegevens."
        }
    }
} 