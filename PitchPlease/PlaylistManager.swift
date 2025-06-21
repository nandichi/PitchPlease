// Playlist Manager voor het beheren van gebruiker playlists
// Deze class laat gebruikers playlists maken van hun favoriete albums
import Foundation

// Playlist model voor lokale opslag
struct LocalPlaylist: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let userId: String
    let albumIds: [String] // Array van album IDs
    let createdAt: Date
    let updatedAt: Date
    let isPublic: Bool
    let imageUrl: String? // Optionele cover afbeelding
    
    init(name: String, description: String?, userId: String, isPublic: Bool = false) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.userId = userId
        self.albumIds = []
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.isPublic = isPublic
        self.imageUrl = nil
    }
    
    // Update initializer
    init(id: String, name: String, description: String?, userId: String, albumIds: [String], createdAt: Date, isPublic: Bool, imageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.userId = userId
        self.albumIds = albumIds
        self.createdAt = createdAt
        self.updatedAt = Date()
        self.isPublic = isPublic
        self.imageUrl = imageUrl
    }
}

// Playlist manager class
class PlaylistManager: ObservableObject {
    
    // Singleton instance
    static let shared = PlaylistManager()
    
    // UserDefaults key
    private let playlistsKey = "stored_playlists"
    
    // Published properties
    @Published var userPlaylists: [LocalPlaylist] = []
    @Published var publicPlaylists: [LocalPlaylist] = []
    
    private init() {
        loadPlaylists()
    }
    
    // MARK: - Playlist Operations
    
    // Maak een nieuwe playlist
    func createPlaylist(name: String, description: String?, userId: String, isPublic: Bool = false) -> LocalPlaylist {
        let playlist = LocalPlaylist(name: name, description: description, userId: userId, isPublic: isPublic)
        
        var allPlaylists = getAllPlaylists()
        allPlaylists.append(playlist)
        savePlaylists(allPlaylists)
        
        DispatchQueue.main.async {
            self.loadPlaylists()
        }
        
        return playlist
    }
    
    // Voeg album toe aan playlist
    func addAlbumToPlaylist(playlistId: String, albumId: String) -> Bool {
        var allPlaylists = getAllPlaylists()
        
        guard let index = allPlaylists.firstIndex(where: { $0.id == playlistId }) else {
            return false
        }
        
        var playlist = allPlaylists[index]
        
        // Check of album al in playlist zit
        if playlist.albumIds.contains(albumId) {
            return false
        }
        
        // Voeg album toe
        var newAlbumIds = playlist.albumIds
        newAlbumIds.append(albumId)
        
        let updatedPlaylist = LocalPlaylist(
            id: playlist.id,
            name: playlist.name,
            description: playlist.description,
            userId: playlist.userId,
            albumIds: newAlbumIds,
            createdAt: playlist.createdAt,
            isPublic: playlist.isPublic,
            imageUrl: playlist.imageUrl
        )
        
        allPlaylists[index] = updatedPlaylist
        savePlaylists(allPlaylists)
        
        DispatchQueue.main.async {
            self.loadPlaylists()
        }
        
        return true
    }
    
    // Verwijder album uit playlist
    func removeAlbumFromPlaylist(playlistId: String, albumId: String) -> Bool {
        var allPlaylists = getAllPlaylists()
        
        guard let index = allPlaylists.firstIndex(where: { $0.id == playlistId }) else {
            return false
        }
        
        var playlist = allPlaylists[index]
        var newAlbumIds = playlist.albumIds
        newAlbumIds.removeAll { $0 == albumId }
        
        let updatedPlaylist = LocalPlaylist(
            id: playlist.id,
            name: playlist.name,
            description: playlist.description,
            userId: playlist.userId,
            albumIds: newAlbumIds,
            createdAt: playlist.createdAt,
            isPublic: playlist.isPublic,
            imageUrl: playlist.imageUrl
        )
        
        allPlaylists[index] = updatedPlaylist
        savePlaylists(allPlaylists)
        
        DispatchQueue.main.async {
            self.loadPlaylists()
        }
        
        return true
    }
    
    // Verwijder hele playlist
    func deletePlaylist(playlistId: String) -> Bool {
        var allPlaylists = getAllPlaylists()
        allPlaylists.removeAll { $0.id == playlistId }
        savePlaylists(allPlaylists)
        
        DispatchQueue.main.async {
            self.loadPlaylists()
        }
        
        return true
    }
    
    // Update playlist informatie
    func updatePlaylist(playlistId: String, name: String, description: String?, isPublic: Bool) -> Bool {
        var allPlaylists = getAllPlaylists()
        
        guard let index = allPlaylists.firstIndex(where: { $0.id == playlistId }) else {
            return false
        }
        
        let playlist = allPlaylists[index]
        
        let updatedPlaylist = LocalPlaylist(
            id: playlist.id,
            name: name,
            description: description,
            userId: playlist.userId,
            albumIds: playlist.albumIds,
            createdAt: playlist.createdAt,
            isPublic: isPublic,
            imageUrl: playlist.imageUrl
        )
        
        allPlaylists[index] = updatedPlaylist
        savePlaylists(allPlaylists)
        
        DispatchQueue.main.async {
            self.loadPlaylists()
        }
        
        return true
    }
    
    // MARK: - Data Loading
    
    // Laad alle playlists van de gebruiker
    func loadPlaylists() {
        let allPlaylists = getAllPlaylists()
        
        if let currentUser = LocalStorageManager.shared.currentUser {
            DispatchQueue.main.async {
                self.userPlaylists = allPlaylists.filter { $0.userId == currentUser.id }
                self.publicPlaylists = allPlaylists.filter { $0.isPublic && $0.userId != currentUser.id }
            }
        } else {
            DispatchQueue.main.async {
                self.userPlaylists = []
                self.publicPlaylists = allPlaylists.filter { $0.isPublic }
            }
        }
    }
    
    // Haal specifieke playlist op
    func getPlaylist(by id: String) -> LocalPlaylist? {
        return getAllPlaylists().first { $0.id == id }
    }
    
    // Haal albums op voor een playlist
    func getAlbumsForPlaylist(playlistId: String) -> [LocalAlbumRating] {
        guard let playlist = getPlaylist(by: playlistId) else { return [] }
        
        let allRatings = LocalStorageManager.shared.getAllRatings()
        return playlist.albumIds.compactMap { albumId in
            allRatings.first { $0.albumId == albumId }
        }
    }
    
    // Check of album in playlist zit
    func isAlbumInPlaylist(playlistId: String, albumId: String) -> Bool {
        guard let playlist = getPlaylist(by: playlistId) else { return false }
        return playlist.albumIds.contains(albumId)
    }
    
    // Maak automatische playlists gebaseerd op ratings
    func createSmartPlaylist(name: String, userId: String, minRating: Int) -> LocalPlaylist? {
        let allRatings = LocalStorageManager.shared.getAllRatings()
        let userRatings = allRatings.filter { $0.userId == userId && $0.rating >= minRating }
        
        let playlist = createPlaylist(name: name, description: "Albums met \(minRating)+ sterren", userId: userId)
        
        var allPlaylists = getAllPlaylists()
        guard let index = allPlaylists.firstIndex(where: { $0.id == playlist.id }) else {
            return nil
        }
        
        let albumIds = userRatings.map { $0.albumId }
        
        let updatedPlaylist = LocalPlaylist(
            id: playlist.id,
            name: playlist.name,
            description: playlist.description,
            userId: playlist.userId,
            albumIds: albumIds,
            createdAt: playlist.createdAt,
            isPublic: playlist.isPublic,
            imageUrl: playlist.imageUrl
        )
        
        allPlaylists[index] = updatedPlaylist
        savePlaylists(allPlaylists)
        
        DispatchQueue.main.async {
            self.loadPlaylists()
        }
        
        return updatedPlaylist
    }
    
    // MARK: - Private Methods
    
    private func getAllPlaylists() -> [LocalPlaylist] {
        guard let data = UserDefaults.standard.data(forKey: playlistsKey),
              let playlists = try? JSONDecoder().decode([LocalPlaylist].self, from: data) else {
            return []
        }
        return playlists
    }
    
    private func savePlaylists(_ playlists: [LocalPlaylist]) {
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: playlistsKey)
        }
    }
    

} 