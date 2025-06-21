// Spotify API Manager voor het zoeken van albums
// Deze class handelt alle communicatie met de Spotify Web API af
import Foundation

// Data modellen voor Spotify API responses
struct SpotifySearchResponse: Codable {
    let albums: SpotifyAlbumsResponse
}

struct SpotifyAlbumsResponse: Codable {
    let items: [SpotifyAlbum]
}

// Spotify Album model
struct SpotifyAlbum: Codable, Identifiable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    let images: [SpotifyImage]
    let releaseDate: String
    let totalTracks: Int
    
    // Computed properties voor gemakkelijke toegang
    var artistNames: String {
        artists.map { $0.name }.joined(separator: ", ")
    }
    
    var imageUrl: String? {
        images.first?.url
    }
    
    // Custom keys voor JSON mapping
    enum CodingKeys: String, CodingKey {
        case id, name, artists, images
        case releaseDate = "release_date"
        case totalTracks = "total_tracks"
    }
}

struct SpotifyArtist: Codable {
    let id: String
    let name: String
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

// Spotify Access Token response model
struct SpotifyTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

// Manager class voor Spotify API calls
class SpotifyManager: ObservableObject {
    
    // Singleton instance
    static let shared = SpotifyManager()
    
    // Spotify API credentials
    private let clientId = "ea77137366a8460097e540b473a7a6f9"
    private let clientSecret = "36aeab88f705495cb29528c1747db042"
    
    // API endpoints
    private let baseUrl = "https://api.spotify.com/v1"
    private let tokenUrl = "https://accounts.spotify.com/api/token"
    
    // Access token management
    private var accessToken: String?
    private var tokenExpirationDate: Date?
    
    private init() {}
    
    // Functie om access token op te halen via Client Credentials flow
    private func getAccessToken() async throws -> String {
        // Check of we een geldige token hebben
        if let token = accessToken,
           let expirationDate = tokenExpirationDate,
           Date() < expirationDate {
            return token
        }
        
        // Nieuwe token ophalen
        guard let url = URL(string: tokenUrl) else {
            throw SpotifyError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Basic authentication header
        let credentials = "\(clientId):\(clientSecret)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        // Request body
        let bodyString = "grant_type=client_credentials"
        request.httpBody = bodyString.data(using: .utf8)
        
        // API call uitvoeren
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.authenticationFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        
        // Token opslaan met expiration date
        self.accessToken = tokenResponse.accessToken
        self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        
        return tokenResponse.accessToken
    }
    
    // Functie om albums te zoeken
    func searchAlbums(query: String) async throws -> [SpotifyAlbum] {
        let token = try await getAccessToken()
        
        // URL encoding van de search query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseUrl)/search?q=\(encodedQuery)&type=album&limit=20") else {
            throw SpotifyError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // API call uitvoeren
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.apiCallFailed
        }
        
        let searchResponse = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
        return searchResponse.albums.items
    }
}

// Custom error types voor Spotify API
enum SpotifyError: Error, LocalizedError {
    case invalidUrl
    case authenticationFailed
    case apiCallFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "Ongeldige URL"
        case .authenticationFailed:
            return "Spotify authenticatie mislukt"
        case .apiCallFailed:
            return "Spotify API call mislukt"
        case .invalidResponse:
            return "Ongeldig antwoord van Spotify API"
        }
    }
} 