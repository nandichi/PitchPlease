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
    
    // Direct initializer voor demo data
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
        createDemoDataIfNeeded()
    }
    
    // MARK: - Demo Data Creation
    
    private func createDemoDataIfNeeded() {
        // Controleer of er al demo data bestaat
        let existingRatings = getAllRatings()
        if existingRatings.isEmpty {
            createDemoRatings()
        }
    }
    
    private func createDemoRatings() {
        let demoUsers = [
            LocalUser(id: "demo_user_1", email: "anna@example.com", displayName: "Anna Muziek"),
            LocalUser(id: "demo_user_2", email: "peter@example.com", displayName: "Peter Pop"),
            LocalUser(id: "demo_user_3", email: "lisa@example.com", displayName: "Lisa Rock"),
            LocalUser(id: "demo_user_4", email: "mark@example.com", displayName: "Mark Jazz")
        ]
        
        let demoRatings = [
            LocalAlbumRating(
                id: "demo_rating_1",
                userId: "demo_user_1",
                userDisplayName: "Anna Muziek",
                albumId: "demo_album_1",
                albumName: "Folklore",
                artistName: "Taylor Swift",
                albumImageUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/8b/c4/9c/8bc49c69-485c-5f36-88c3-df0526e5be78/20UMGIM66770.rgb.jpg/300x300bb.jpg",
                rating: 5,
                review: "Een prachtig album vol met intieme verhalen en geweldige songwriting. Taylor Swift laat zien dat ze een echte artiest is.",
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            ),
            LocalAlbumRating(
                id: "demo_rating_2",
                userId: "demo_user_2",
                userDisplayName: "Peter Pop",
                albumId: "demo_album_2",
                albumName: "Abbey Road",
                artistName: "The Beatles",
                albumImageUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/64/4f/7e/644f7e91-8e0b-7cae-7dfe-a1175c34cf8e/00602547885050.rgb.jpg/300x300bb.jpg",
                rating: 5,
                review: "Een tijdloos meesterwerk. Elk nummer is perfect en de productie is ongeëvenaard. Must-have in elke collectie!",
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            LocalAlbumRating(
                id: "demo_rating_3",
                userId: "demo_user_3",
                userDisplayName: "Lisa Rock",
                albumId: "demo_album_3",
                albumName: "OK Computer",
                artistName: "Radiohead",
                albumImageUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/1d/63/6b/1d636b9b-6d4d-8e35-8de8-1c8a8e6e4e5c/mzi.ftkdblxk.jpg/300x300bb.jpg",
                rating: 4,
                review: "Revolutionair album dat de grens tussen rock en elektronische muziek wegneemt. Paranoid Android is een meesterwerk.",
                createdAt: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
            ),
            LocalAlbumRating(
                id: "demo_rating_4",
                userId: "demo_user_4",
                userDisplayName: "Mark Jazz",
                albumId: "demo_album_4",
                albumName: "Kind of Blue",
                artistName: "Miles Davis",
                albumImageUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/74/8c/98/748c98c0-3dc4-e48c-e8ea-e0ea8c56e8ac/886445635850.jpg/300x300bb.jpg",
                rating: 5,
                review: "Het beste jazz album ooit gemaakt. Miles Davis speelt als een god en elke muzikant draagt bij aan dit perfecte geheel.",
                createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date()
            ),
            LocalAlbumRating(
                id: "demo_rating_5",
                userId: "demo_user_1",
                userDisplayName: "Anna Muziek",
                albumId: "demo_album_5",
                albumName: "Random Access Memories",
                artistName: "Daft Punk",
                albumImageUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/6e/9f/0e/6e9f0e9c-eb8e-6424-7a1c-e2f0a7b6e5dc/13UUUM1217562.rgb.jpg/300x300bb.jpg",
                rating: 4,
                review: "Daft Punk keert terug naar hun roots met echte instrumenten en perfecte productie. Get Lucky is een instant klassieker!",
                createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
            ),
            LocalAlbumRating(
                id: "demo_rating_6",
                userId: "demo_user_2",
                userDisplayName: "Peter Pop",
                albumId: "demo_album_6",
                albumName: "Thriller",
                artistName: "Michael Jackson",
                albumImageUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/7a/5d/99/7a5d996e-7f54-5a5e-de48-90086346e4c2/mzi.mzkfrtql.jpg/300x300bb.jpg",
                rating: 5,
                review: "Het meest invloedrijke pop album aller tijden. Michael Jackson was een genie en dit album bewijst het.",
                createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date()
            ),
            LocalAlbumRating(
                id: "demo_rating_7",
                userId: "demo_user_3",
                userDisplayName: "Lisa Rock",
                albumId: "demo_album_7",
                albumName: "Led Zeppelin IV",
                artistName: "Led Zeppelin",
                albumImageUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music111/v4/b9/c5/20/b9c520c8-7f5e-9c9c-2f7e-19f3a8c7e4d5/mzi.cgfcrvnh.jpg/300x300bb.jpg",
                rating: 5,
                review: "Stairway to Heaven alleen al maakt dit tot een 5-sterren album. Pure rock perfectie van begin tot eind.",
                createdAt: Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date()
            ),
            LocalAlbumRating(
                id: "demo_rating_8",
                userId: "demo_user_4",
                userDisplayName: "Mark Jazz",
                albumId: "demo_album_8",
                albumName: "The Dark Side of the Moon",
                artistName: "Pink Floyd",
                albumImageUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/3c/1b/a0/3c1ba0c8-60b4-8e44-95f5-7e9c8e7e8e8e/mzi.gqvulvqg.jpg/300x300bb.jpg",
                rating: 5,
                review: "Een conceptueel meesterwerk dat je meeneemt op een emotionele reis. Time en Money zijn absolute klassiekers.",
                createdAt: Date()
            )
        ]
        
        // Sla demo users en ratings op
        saveUsers(demoUsers)
        saveRatings(demoRatings)
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