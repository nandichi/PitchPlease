// Herbruikbare UI componenten voor de app
// Deze file bevat alle custom SwiftUI views die door de app worden gebruikt
import SwiftUI

// Album row view voor het tonen van een album in een lijst
struct AlbumRowView: View {
    let album: SpotifyAlbum
    @State private var averageRating: Double = 0.0
    
    var body: some View {
        HStack(spacing: 12) {
            // Album afbeelding
            AsyncImage(url: URL(string: album.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            // Album informatie
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(album.artistNames)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(album.releaseDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Gemiddelde rating weergave
                HStack(spacing: 4) {
                    StarRatingView(rating: averageRating, size: 12)
                    Text(String(format: "%.1f", averageRating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Navigatie indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .onAppear {
            loadAverageRating()
        }
    }
    
    // Functie om gemiddelde rating te laden
    private func loadAverageRating() {
        Task {
            do {
                let rating = try await AlbumRatingManager.shared.getAverageRating(for: album.id)
                DispatchQueue.main.async {
                    averageRating = rating
                }
            } catch {
                print("Error loading average rating: \(error)")
            }
        }
    }
}

// Rating row view voor het tonen van een rating in een lijst
struct RatingRowView: View {
    let rating: AlbumRating
    let showUserName: Bool
    
    init(rating: AlbumRating, showUserName: Bool = true) {
        self.rating = rating
        self.showUserName = showUserName
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Album afbeelding
                AsyncImage(url: URL(string: rating.albumImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 50, height: 50)
                .cornerRadius(6)
                
                // Rating informatie
                VStack(alignment: .leading, spacing: 4) {
                    Text(rating.albumName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(rating.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if showUserName {
                        Text("door \(rating.userDisplayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Rating sterren
                StarRatingView(rating: Double(rating.rating), size: 16)
            }
            
            // Review tekst (indien aanwezig)
            if let review = rating.review, !review.isEmpty {
                HStack {
                    Text(review)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

// Star rating view voor het tonen van sterren
struct StarRatingView: View {
    let rating: Double
    let size: CGFloat
    let maxRating: Int = 5
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .foregroundColor(.yellow)
                    .font(.system(size: size))
            }
        }
    }
    
    // Functie om type ster te bepalen (vol, half, leeg)
    private func starType(for index: Int) -> String {
        let difference = rating - Double(index - 1)
        
        if difference >= 1.0 {
            return "star.fill"
        } else if difference >= 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// Interactive star rating view voor het geven van ratings
struct InteractiveStarRatingView: View {
    @Binding var rating: Int
    let maxRating: Int = 5
    let size: CGFloat
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(index <= rating ? .yellow : .gray)
                    .font(.system(size: size))
                    .onTapGesture {
                        rating = index
                    }
            }
        }
    }
}

// Async image view met caching (voor betere performance)
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (AsyncImagePhase) -> Content
    
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }
    
    var body: some View {
        AsyncImage(url: url) { phase in
            content(phase)
        }
    }
}

// Loading view component
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// Empty state view component
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// Custom button style voor de app
struct PrimaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isDisabled ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isDisabled ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Share button component
struct ShareButton: View {
    let album: SpotifyAlbum
    let rating: Int?
    
    var body: some View {
        Button(action: shareAlbum) {
            Image(systemName: "square.and.arrow.up")
                .font(.title2)
        }
    }
    
    // Functie om album te delen
    private func shareAlbum() {
        let shareText = createShareText()
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Get the top-most view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            var topController = rootViewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(activityViewController, animated: true)
        }
    }
    
    // Functie om share tekst te maken
    private func createShareText() -> String {
        var shareText = "Bekijk dit album: \(album.name) van \(album.artistNames)"
        
        if let rating = rating {
            shareText += "\n\nMijn rating: \(String(repeating: "⭐", count: rating)) (\(rating)/5)"
        }
        
        shareText += "\n\nGedeeld via PitchPlease 🎵"
        
        return shareText
    }
}

// Preview voor SwiftUI development
#Preview {
    VStack {
        // Preview van verschillende componenten
        StarRatingView(rating: 3.5, size: 16)
        
        InteractiveStarRatingView(rating: .constant(4), size: 20)
        
        LoadingView(message: "Laden...")
        
        EmptyStateView(
            icon: "star",
            title: "Geen ratings",
            message: "Voeg je eerste rating toe!"
        )
    }
    .padding()
} 