// Album Detail View voor het bekijken en beoordelen van albums
// Deze view toont album details en laat gebruikers ratings en reviews toevoegen
import SwiftUI

// Album detail view met rating functionaliteit
struct AlbumDetailView: View {
    let album: SpotifyAlbum
    
    @ObservedObject var storageManager = LocalStorageManager.shared
    
    @State private var userRating: LocalAlbumRating?
    @State private var newRating: Int = 0
    @State private var reviewText: String = ""
    @State private var allRatings: [LocalAlbumRating] = []
    @State private var averageRating: Double = 0.0
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingRatingForm = false
    @State private var errorMessage = ""
    @State private var isLoaded = false
    
    var body: some View {
        ZStack {
            // Background gradient voor de hele view
            LinearGradient.pitchBackgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: PitchSpacing.xl) {
                    // Hero sectie met album artwork
                    heroSectionView
                    
                    // Rating sectie met moderne styling
                    modernRatingSectionView
                    
                    // Action buttons
                    actionButtonsView
                    
                    // Reviews sectie met alle ratings
                    reviewsSectionView
                    
                    Spacer(minLength: PitchSpacing.xxxl)
                }
                .padding(.vertical, PitchSpacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showingRatingForm) {
            ModernRatingFormView(
                album: album,
                existingRating: userRating,
                onSave: {
                    loadAlbumData()
                }
            )
        }
        .onAppear {
            loadAlbumData()
            withAnimation(.pitchSpring.delay(0.1)) {
                isLoaded = true
            }
        }
    }
    
    // Hero sectie met album artwork en basis informatie
    private var heroSectionView: some View {
        VStack(spacing: PitchSpacing.lg) {
            // Album artwork met glassmorphism effect
            AsyncImage(url: URL(string: album.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    LinearGradient.pitchCardGradient
                    
                    VStack(spacing: PitchSpacing.sm) {
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.pitchTextTertiary)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .pitchAccent))
                        }
                    }
                }
            }
            .frame(width: 280, height: 280)
            .cornerRadius(PitchRadius.xl)
            .pitchShadowLarge()
            .overlay(
                RoundedRectangle(cornerRadius: PitchRadius.xl)
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
            )
            .scaleEffect(isLoaded ? 1.0 : 0.8)
            .animation(.pitchSpring.delay(0.2), value: isLoaded)
            
            // Album informatie met moderne typography
            VStack(spacing: PitchSpacing.md) {
                Text(album.name)
                    .font(PitchTypography.title2)
                    .foregroundColor(.pitchText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Text(album.artistNames)
                    .font(PitchTypography.title3)
                    .foregroundColor(.pitchTextSecondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: PitchSpacing.lg) {
                    HStack(spacing: PitchSpacing.xs) {
                        Image(systemName: "calendar")
                            .foregroundColor(.pitchTextTertiary)
                        Text(formatReleaseDate(album.releaseDate))
                            .font(PitchTypography.callout)
                            .foregroundColor(.pitchTextTertiary)
                    }
                    
                    HStack(spacing: PitchSpacing.xs) {
                        Image(systemName: "music.note.list")
                            .foregroundColor(.pitchTextTertiary)
                        Text("\(album.totalTracks) nummers")
                            .font(PitchTypography.callout)
                            .foregroundColor(.pitchTextTertiary)
                    }
                }
            }
        }
        .padding(.horizontal, PitchSpacing.md)
        .scaleEffect(isLoaded ? 1.0 : 0.9)
        .opacity(isLoaded ? 1.0 : 0.0)
        .animation(.pitchSpring.delay(0.1), value: isLoaded)
    }
    
    // Moderne rating sectie
    private var modernRatingSectionView: some View {
        VStack(spacing: PitchSpacing.lg) {
            // Gemiddelde rating card
            VStack(spacing: PitchSpacing.md) {
                Text("Gemiddelde Rating")
                    .font(PitchTypography.headline)
                    .foregroundColor(.pitchText)
                
                if averageRating > 0 {
                    VStack(spacing: PitchSpacing.sm) {
                        HStack(spacing: PitchSpacing.sm) {
                            Text(String(format: "%.1f", averageRating))
                                .font(PitchTypography.title1)
                                .foregroundColor(.pitchStarFilled)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: PitchSpacing.xxs) {
                                ModernStarRatingView(rating: averageRating, size: 20)
                                Text("uit 5 sterren")
                                    .font(PitchTypography.caption)
                                    .foregroundColor(.pitchTextTertiary)
                            }
                        }
                        
                        Text("(\(allRatings.count) \(allRatings.count == 1 ? "rating" : "ratings"))")
                            .font(PitchTypography.callout)
                            .foregroundColor(.pitchTextSecondary)
                    }
                } else {
                    VStack(spacing: PitchSpacing.sm) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.pitchTextTertiary)
                        
                        Text("Nog geen ratings")
                            .font(PitchTypography.callout)
                            .foregroundColor(.pitchTextTertiary)
                        
                        Text("Wees de eerste om dit album te beoordelen!")
                            .font(PitchTypography.caption)
                            .foregroundColor(.pitchTextTertiary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .pitchCard(padding: PitchSpacing.xl)
            .padding(.horizontal, PitchSpacing.md)
            
            // Gebruiker rating (indien aanwezig)
            if let userRating = userRating {
                VStack(spacing: PitchSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: PitchSpacing.xs) {
                            Text("Jouw Rating")
                                .font(PitchTypography.headline)
                                .foregroundColor(.pitchText)
                            
                            Text("Gegeven op \(formatDate(userRating.createdAt))")
                                .font(PitchTypography.caption)
                                .foregroundColor(.pitchTextTertiary)
                        }
                        Spacer()
                        
                        Button("Bewerken") {
                            newRating = userRating.rating
                            reviewText = userRating.review ?? ""
                            showingRatingForm = true
                        }
                        .font(PitchTypography.caption)
                        .foregroundColor(.pitchAccent)
                    }
                    
                    VStack(spacing: PitchSpacing.sm) {
                        ModernStarRatingView(rating: Double(userRating.rating), size: 22)
                        
                        if let review = userRating.review, !review.isEmpty {
                            Text(review)
                                .font(PitchTypography.body)
                                .foregroundColor(.pitchTextSecondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                        }
                    }
                }
                .pitchCard(padding: PitchSpacing.lg)
                .padding(.horizontal, PitchSpacing.md)
            }
        }
        .scaleEffect(isLoaded ? 1.0 : 0.9)
        .opacity(isLoaded ? 1.0 : 0.0)
        .animation(.pitchSpring.delay(0.3), value: isLoaded)
    }
    
    // Action buttons sectie
    private var actionButtonsView: some View {
        VStack(spacing: PitchSpacing.md) {
            // Rating button
            Button(action: {
                if let userRating = userRating {
                    newRating = userRating.rating
                    reviewText = userRating.review ?? ""
                } else {
                    newRating = 0
                    reviewText = ""
                }
                showingRatingForm = true
            }) {
                HStack(spacing: PitchSpacing.sm) {
                    Image(systemName: userRating != nil ? "star.fill" : "star")
                        .font(.system(size: 18, weight: .semibold))
                    Text(userRating != nil ? "Rating Bijwerken" : "Album Beoordelen")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PitchPrimaryButtonStyle())
            
            // Share button
            Button(action: shareAlbum) {
                HStack(spacing: PitchSpacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Deel Album")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PitchSecondaryButtonStyle())
        }
        .padding(.horizontal, PitchSpacing.md)
        .scaleEffect(isLoaded ? 1.0 : 0.9)
        .opacity(isLoaded ? 1.0 : 0.0)
        .animation(.pitchSpring.delay(0.4), value: isLoaded)
    }
    
    // Reviews sectie met alle gebruikersratings
    private var reviewsSectionView: some View {
        VStack(alignment: .leading, spacing: PitchSpacing.lg) {
            if !allRatings.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: PitchSpacing.xs) {
                        Text("Alle Reviews")
                            .font(PitchTypography.title3)
                            .foregroundColor(.pitchText)
                        
                        Text("\(allRatings.count) gebruiker\(allRatings.count == 1 ? " heeft" : "s hebben") dit album beoordeeld")
                            .font(PitchTypography.caption)
                            .foregroundColor(.pitchTextTertiary)
                    }
                    Spacer()
                }
                .padding(.horizontal, PitchSpacing.md)
                
                LazyVStack(spacing: PitchSpacing.md) {
                    ForEach(Array(allRatings.enumerated()), id: \.element.id) { index, rating in
                        ModernLocalRatingRowView(rating: rating)
                            .padding(.horizontal, PitchSpacing.md)
                            .scaleEffect(isLoaded ? 1.0 : 0.9)
                            .opacity(isLoaded ? 1.0 : 0.0)
                            .animation(.pitchSpring.delay(0.5 + Double(index) * 0.1), value: isLoaded)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Functie om album data te laden
    private func loadAlbumData() {
        isLoading = true
        
        // Alle ratings voor dit album laden
        let ratings = storageManager.getRatingsForAlbum(albumId: album.id)
        
        // Gemiddelde rating berekenen
        let average = storageManager.getAverageRating(for: album.id)
        
        // Gebruik standaard user voor development (geen login vereist)
        let currentUserRating = ratings.first { rating in
            // Voor development nemen we de eerste rating als gebruikersrating
            true
        }
        
        DispatchQueue.main.async {
            allRatings = ratings
            averageRating = average
            userRating = currentUserRating
            isLoading = false
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
    
    // Helper functie om share tekst te maken
    private func createShareText() -> String {
        var shareText = "🎵 Bekijk dit album: \(album.name) van \(album.artistNames)"
        
        if let userRating = userRating {
            shareText += "\n\n⭐ Mijn rating: \(String(repeating: "⭐", count: userRating.rating)) (\(userRating.rating)/5)"
            
            if let review = userRating.review, !review.isEmpty {
                shareText += "\n💭 \"\(review)\""
            }
        }
        
        if averageRating > 0 {
            shareText += "\n📊 Gemiddelde rating: \(String(format: "%.1f", averageRating))/5 (\(allRatings.count) ratings)"
        }
        
        shareText += "\n\n🎧 Gedeeld via PitchPlease"
        
        return shareText
    }
    
    // Helper functie voor datum formatting
    private func formatReleaseDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
        
        return dateString
    }
    
    // Helper functie voor datum formatting
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: date)
    }
}

// Moderne lokale rating row view
struct ModernLocalRatingRowView: View {
    let rating: LocalAlbumRating
    
    var body: some View {
        VStack(spacing: PitchSpacing.md) {
            HStack(spacing: PitchSpacing.sm) {
                // User avatar placeholder
                Circle()
                    .fill(LinearGradient.pitchAccentGradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(rating.userDisplayName.prefix(1)).uppercased())
                            .font(PitchTypography.headline)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    )
                
                VStack(alignment: .leading, spacing: PitchSpacing.xxs) {
                    Text(rating.userDisplayName)
                        .font(PitchTypography.callout)
                        .foregroundColor(.pitchText)
                        .fontWeight(.semibold)
                    
                    Text(formatDate(rating.createdAt))
                        .font(PitchTypography.caption2)
                        .foregroundColor(.pitchTextTertiary)
                }
                
                Spacer()
                
                ModernStarRatingView(rating: Double(rating.rating), size: 16)
            }
            
            if let review = rating.review, !review.isEmpty {
                HStack {
                    Text(review)
                        .font(PitchTypography.body)
                        .foregroundColor(.pitchTextSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                    Spacer()
                }
            }
        }
        .pitchCard(padding: PitchSpacing.md)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: date)
    }
}

// Moderne rating form view
struct ModernRatingFormView: View {
    let album: SpotifyAlbum
    let existingRating: LocalAlbumRating?
    let onSave: () -> Void
    
    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @State private var isSaving = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var storageManager = LocalStorageManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.pitchBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: PitchSpacing.xl) {
                        // Album info header
                        HStack(spacing: PitchSpacing.md) {
                            AsyncImage(url: URL(string: album.imageUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ZStack {
                                    LinearGradient.pitchCardGradient
                                    Image(systemName: "music.note")
                                        .foregroundColor(.pitchTextTertiary)
                                }
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(PitchRadius.md)
                            .pitchShadowMedium()
                            
                            VStack(alignment: .leading, spacing: PitchSpacing.xs) {
                                Text(album.name)
                                    .font(PitchTypography.headline)
                                    .foregroundColor(.pitchText)
                                    .lineLimit(2)
                                
                                Text(album.artistNames)
                                    .font(PitchTypography.callout)
                                    .foregroundColor(.pitchTextSecondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                        .pitchCard()
                        
                        // Rating sectie
                        VStack(spacing: PitchSpacing.lg) {
                            VStack(spacing: PitchSpacing.md) {
                                Text("Jouw Rating")
                                    .font(PitchTypography.title3)
                                    .foregroundColor(.pitchText)
                                
                                ModernInteractiveStarRatingView(rating: $rating, size: 40)
                                    .pitchGlow(color: rating > 0 ? .pitchStarFilled : .clear)
                                
                                if rating > 0 {
                                    Text(ratingDescription(for: rating))
                                        .font(PitchTypography.callout)
                                        .foregroundColor(.pitchTextSecondary)
                                        .animation(.pitchEaseOut, value: rating)
                                }
                            }
                            .pitchCard()
                            
                            // Review sectie
                            VStack(alignment: .leading, spacing: PitchSpacing.md) {
                                Text("Review (optioneel)")
                                    .font(PitchTypography.headline)
                                    .foregroundColor(.pitchText)
                                
                                ZStack(alignment: .topLeading) {
                                    if reviewText.isEmpty {
                                        Text("Deel je gedachten over dit album...")
                                            .font(PitchTypography.body)
                                            .foregroundColor(.pitchTextTertiary)
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                    }
                                    
                                    TextEditor(text: $reviewText)
                                        .font(PitchTypography.body)
                                        .foregroundColor(.pitchText)
                                        .frame(minHeight: 120)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                }
                                .padding(PitchSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: PitchRadius.md)
                                        .fill(Color.pitchCard.opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: PitchRadius.md)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            .pitchCard()
                        }
                        
                        // Error message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(PitchTypography.callout)
                                .foregroundColor(.pitchError)
                                .pitchCard()
                        }
                        
                        Spacer(minLength: PitchSpacing.xxxl)
                    }
                    .padding(.all, PitchSpacing.md)
                }
            }
            .navigationTitle(existingRating != nil ? "Rating Bijwerken" : "Album Beoordelen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.pitchTextSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveRating) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .pitchAccent))
                                .scaleEffect(0.8)
                        } else {
                            Text("Opslaan")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(rating > 0 ? .pitchAccent : .pitchTextTertiary)
                    .disabled(rating == 0 || isSaving)
                }
            }
        }
        .onAppear {
            if let existingRating = existingRating {
                rating = existingRating.rating
                reviewText = existingRating.review ?? ""
            }
        }
    }
    
    // Helper functie voor rating beschrijving
    private func ratingDescription(for rating: Int) -> String {
        switch rating {
        case 1: return "Slecht"
        case 2: return "Matig"
        case 3: return "Goed"
        case 4: return "Zeer goed"
        case 5: return "Uitstekend"
        default: return ""
        }
    }
    
    // Functie om rating op te slaan
    private func saveRating() {
        guard rating > 0 else {
            errorMessage = "Selecteer een rating"
            return
        }
        
        isSaving = true
        errorMessage = ""
        
        // Gebruik de ingelogde gebruiker of maak een tijdelijke gebruiker aan
        guard let currentUser = storageManager.currentUser else {
            errorMessage = "Je moet ingelogd zijn om een rating te geven"
            isSaving = false
            return
        }
        
        if let existingRating = existingRating {
            // Update bestaande rating
            let updatedRating = LocalAlbumRating(
                id: existingRating.id,
                userId: currentUser.id,
                userDisplayName: currentUser.displayName,
                albumId: album.id,
                albumName: album.name,
                artistName: album.artistNames,
                albumImageUrl: album.imageUrl,
                rating: rating,
                review: reviewText.isEmpty ? nil : reviewText,
                createdAt: existingRating.createdAt
            )
            
            storageManager.updateRating(updatedRating)
        } else {
            // Nieuwe rating aanmaken
            let newAlbumRating = LocalAlbumRating(
                userId: currentUser.id,
                userDisplayName: currentUser.displayName,
                album: album,
                rating: rating,
                review: reviewText.isEmpty ? nil : reviewText
            )
            
            storageManager.saveRating(newAlbumRating)
        }
        
        isSaving = false
        onSave()
        presentationMode.wrappedValue.dismiss()
    }
}

// Moderne interactieve star rating view
struct ModernInteractiveStarRatingView: View {
    @Binding var rating: Int
    let size: CGFloat
    let maxRating: Int = 5
    
    var body: some View {
        HStack(spacing: PitchSpacing.xs) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(index <= rating ? .pitchStarFilled : .pitchStarEmpty)
                    .font(.system(size: size, weight: .semibold))
                    .scaleEffect(index <= rating ? 1.2 : 1.0)
                    .animation(.pitchBouncy, value: rating)
                    .onTapGesture {
                        withAnimation(.pitchBouncy) {
                            rating = index
                        }
                    }
            }
        }
    }
}

// Extension om rating form toe te voegen
extension AlbumDetailView {
    func withRatingForm() -> some View {
        self
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
    }
} 