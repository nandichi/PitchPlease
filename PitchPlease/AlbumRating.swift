// Album Rating model voor het opslaan van gebruikersbeoordelingen
// Deze struct wordt gebruikt voor Firebase Firestore database operaties
import Foundation
import FirebaseFirestore

// Model voor album ratings
struct AlbumRating: Codable, Identifiable {
    let id: String
    let userId: String
    let userDisplayName: String
    let albumId: String
    let albumName: String
    let artistName: String
    let albumImageUrl: String?
    let rating: Int // 1 tot 5 sterren
    let review: String? // Optionele recensie tekst
    let createdAt: Timestamp
    let updatedAt: Timestamp
    
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
        let now = Timestamp()
        self.createdAt = now
        self.updatedAt = now
    }
    
    // Computed property om rating te valideren
    var isValidRating: Bool {
        return rating >= 1 && rating <= 5
    }
    
    // Functie om dictionary te maken voor Firestore
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "userDisplayName": userDisplayName,
            "albumId": albumId,
            "albumName": albumName,
            "artistName": artistName,
            "albumImageUrl": albumImageUrl ?? "",
            "rating": rating,
            "review": review ?? "",
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

// Manager class voor album rating database operaties
class AlbumRatingManager: ObservableObject {
    
    // Singleton instance
    static let shared = AlbumRatingManager()
    
    // Firebase Firestore referentie
    private let db = Firestore.firestore()
    
    // Collection naam in Firestore (meervoud zoals gewenst)
    private let collectionName = "album_ratings"
    
    private init() {}
    
    // Functie om een nieuwe rating op te slaan
    func saveRating(_ rating: AlbumRating) async throws {
        let document = db.collection(collectionName).document(rating.id)
        try await document.setData(rating.toDictionary())
    }
    
    // Functie om een bestaande rating te updaten
    func updateRating(_ rating: AlbumRating) async throws {
        var updatedRating = rating
        updatedRating = AlbumRating(
            id: rating.id,
            userId: rating.userId,
            userDisplayName: rating.userDisplayName,
            albumId: rating.albumId,
            albumName: rating.albumName,
            artistName: rating.artistName,
            albumImageUrl: rating.albumImageUrl,
            rating: rating.rating,
            review: rating.review,
            createdAt: rating.createdAt,
            updatedAt: Timestamp()
        )
        
        let document = db.collection(collectionName).document(rating.id)
        try await document.setData(updatedRating.toDictionary())
    }
    
    // Functie om ratings van een specifieke gebruiker op te halen
    func getRatingsForUser(userId: String) async throws -> [AlbumRating] {
        let query = db.collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .order(by: "updatedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: AlbumRating.self)
        }
    }
    
    // Functie om alle publieke ratings op te halen (voor timeline/feed)
    func getAllPublicRatings(limit: Int = 50) async throws -> [AlbumRating] {
        let query = db.collection(collectionName)
            .order(by: "updatedAt", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: AlbumRating.self)
        }
    }
    
    // Functie om ratings voor een specifiek album op te halen
    func getRatingsForAlbum(albumId: String) async throws -> [AlbumRating] {
        let query = db.collection(collectionName)
            .whereField("albumId", isEqualTo: albumId)
            .order(by: "updatedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: AlbumRating.self)
        }
    }
    
    // Functie om gemiddelde rating voor een album te berekenen
    func getAverageRating(for albumId: String) async throws -> Double {
        let ratings = try await getRatingsForAlbum(albumId: albumId)
        
        guard !ratings.isEmpty else { return 0.0 }
        
        let totalRating = ratings.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(ratings.count)
    }
    
    // Functie om te checken of gebruiker al een rating heeft voor een album
    func hasUserRatedAlbum(userId: String, albumId: String) async throws -> AlbumRating? {
        let query = db.collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .whereField("albumId", isEqualTo: albumId)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        return try snapshot.documents.first?.data(as: AlbumRating.self)
    }
    
    // Functie om een rating te verwijderen
    func deleteRating(ratingId: String) async throws {
        let document = db.collection(collectionName).document(ratingId)
        try await document.delete()
    }
}

// Extension voor AlbumRating om te werken met Firestore updates
extension AlbumRating {
    init(id: String, userId: String, userDisplayName: String, albumId: String, albumName: String, artistName: String, albumImageUrl: String?, rating: Int, review: String?, createdAt: Timestamp, updatedAt: Timestamp) {
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
} 