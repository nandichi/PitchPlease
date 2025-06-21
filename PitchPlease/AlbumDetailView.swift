// Album Detail View voor het bekijken en beoordelen van albums
// Deze view toont album details en laat gebruikers ratings en reviews toevoegen
import SwiftUI

// Album detail view met rating functionaliteit
struct AlbumDetailView: View {
    let album: SpotifyAlbum
    
    @ObservedObject var firebaseManager = FirebaseManager.shared
    @StateObject private var ratingManager = AlbumRatingManager.shared
    
    @State private var userRating: AlbumRating?
    @State private var newRating: Int = 0
    @State private var reviewText: String = ""
    @State private var allRatings: [AlbumRating] = []
    @State private var averageRating: Double = 0.0
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingRatingForm = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Album header
                albumHeaderView
                
                // Rating sectie
                ratingSectionView
                
                // Reviews sectie
                reviewsSectionView
            }
            .padding()
        }
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareButton(album: album, rating: userRating?.rating)
            }
        }
        .onAppear {
            loadAlbumData()
        }
    }
    
    // Album header met afbeelding en informatie
    private var albumHeaderView: some View {
        VStack(spacing: 16) {
            // Album afbeelding
            AsyncImage(url: URL(string: album.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 200, height: 200)
            .cornerRadius(12)
            .shadow(radius: 8)
            
            // Album informatie
            VStack(spacing: 8) {
                Text(album.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(album.artistNames)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Uitgegeven: \(album.releaseDate)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(album.totalTracks) nummers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Rating sectie met gemiddelde en gebruikersrating
    private var ratingSectionView: some View {
        VStack(spacing: 16) {
            // Gemiddelde rating
            VStack(spacing: 8) {
                Text("Gemiddelde Rating")
                    .font(.headline)
                
                if averageRating > 0 {
                    HStack(spacing: 8) {
                        StarRatingView(rating: averageRating, size: 20)
                        Text(String(format: "%.1f", averageRating))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("(\(allRatings.count) \(allRatings.count == 1 ? "rating" : "ratings"))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Nog geen ratings")
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Gebruikersrating sectie
            if let userRating = userRating {
                // Bestaande rating tonen
                VStack(spacing: 12) {
                    Text("Jouw Rating")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        StarRatingView(rating: Double(userRating.rating), size: 18)
                        
                        if let review = userRating.review, !review.isEmpty {
                            Text(review)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    Button("Rating Bewerken") {
                        newRating = userRating.rating
                        reviewText = userRating.review ?? ""
                        showingRatingForm = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            } else {
                // Nieuwe rating toevoegen
                VStack(spacing: 12) {
                    Text("Geef jouw rating")
                        .font(.headline)
                    
                    Button("Album Beoordelen") {
                        newRating = 0
                        reviewText = ""
                        showingRatingForm = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Reviews sectie met alle gebruikersratings
    private var reviewsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alle Reviews")
                .font(.headline)
            
            if isLoading {
                LoadingView(message: "Laden...")
            } else if allRatings.isEmpty {
                EmptyStateView(
                    icon: "star",
                    title: "Nog geen reviews",
                    message: "Wees de eerste om dit album te beoordelen!"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(allRatings) { rating in
                        RatingRowView(rating: rating)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // Functie om album data te laden
    private func loadAlbumData() {
        isLoading = true
        
        Task {
            do {
                // Alle ratings voor dit album laden
                let ratings = try await ratingManager.getRatingsForAlbum(albumId: album.id)
                
                // Gemiddelde rating berekenen
                let average = try await ratingManager.getAverageRating(for: album.id)
                
                // Gebruikersrating ophalen (indien aanwezig)
                var currentUserRating: AlbumRating?
                if let userId = firebaseManager.currentUser?.uid {
                    currentUserRating = try await ratingManager.hasUserRatedAlbum(
                        userId: userId,
                        albumId: album.id
                    )
                }
                
                DispatchQueue.main.async {
                    allRatings = ratings
                    averageRating = average
                    userRating = currentUserRating
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Fout bij laden van gegevens: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Functie om rating op te slaan
    private func saveRating() {
        guard let user = firebaseManager.currentUser,
              let displayName = user.displayName,
              newRating > 0 else {
            errorMessage = "Selecteer een rating"
            return
        }
        
        isSaving = true
        errorMessage = ""
        
        Task {
            do {
                if let existingRating = userRating {
                    // Update bestaande rating
                    let updatedRating = AlbumRating(
                        id: existingRating.id,
                        userId: user.uid,
                        userDisplayName: displayName,
                        albumId: album.id,
                        albumName: album.name,
                        artistName: album.artistNames,
                        albumImageUrl: album.imageUrl,
                        rating: newRating,
                        review: reviewText.isEmpty ? nil : reviewText,
                        createdAt: existingRating.createdAt,
                        updatedAt: existingRating.updatedAt
                    )
                    
                    try await ratingManager.updateRating(updatedRating)
                } else {
                    // Nieuwe rating aanmaken
                    let newAlbumRating = AlbumRating(
                        userId: user.uid,
                        userDisplayName: displayName,
                        album: album,
                        rating: newRating,
                        review: reviewText.isEmpty ? nil : reviewText
                    )
                    
                    try await ratingManager.saveRating(newAlbumRating)
                }
                
                DispatchQueue.main.async {
                    isSaving = false
                    showingRatingForm = false
                    // Data opnieuw laden
                    loadAlbumData()
                }
            } catch {
                DispatchQueue.main.async {
                    isSaving = false
                    errorMessage = "Fout bij opslaan: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Extension voor rating form sheet
extension AlbumDetailView {
    // Rating form als sheet
    private var ratingFormSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Album info
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: album.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text(album.name)
                            .font(.headline)
                        Text(album.artistNames)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Rating sterren
                VStack(spacing: 8) {
                    Text("Jouw rating")
                        .font(.headline)
                    
                    InteractiveStarRatingView(rating: $newRating, size: 30)
                }
                
                // Review tekst
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review (optioneel)")
                        .font(.headline)
                    
                    TextEditor(text: $reviewText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                
                // Save button
                Button(action: saveRating) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Opslaan")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: newRating == 0 || isSaving))
                .disabled(newRating == 0 || isSaving)
            }
            .padding()
            .navigationTitle("Rating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        showingRatingForm = false
                    }
                }
            }
        }
    }
}

// Sheet modifier toevoegen aan de main view
extension AlbumDetailView {
    func withRatingForm() -> some View {
        self.sheet(isPresented: $showingRatingForm) {
            ratingFormSheet
        }
    }
}

// Preview voor SwiftUI development
#Preview {
    let sampleAlbum = SpotifyAlbum(
        id: "sample",
        name: "Sample Album",
        artists: [SpotifyArtist(id: "artist1", name: "Sample Artist")],
        images: [],
        releaseDate: "2023-01-01",
        totalTracks: 10
    )
    
    return NavigationView {
        AlbumDetailView(album: sampleAlbum)
            .withRatingForm()
    }
} 