// Discovery View voor het weergeven van album aanbevelingen
// Deze view toont gepersonaliseerde aanbevelingen gebaseerd op gebruiker voorkeuren
import SwiftUI

// Discovery view met aanbevelingen
struct DiscoveryView: View {
    @StateObject private var recommendationEngine = RecommendationEngine.shared
    @ObservedObject var storageManager = LocalStorageManager.shared
    @State private var isLoaded = false
    @State private var showingPreferences = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient.pitchBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: PitchSpacing.xl) {
                        // Header sectie
                        headerSectionView
                        
                        // Aanbevelingen sectie
                        if recommendationEngine.isAnalyzing {
                            loadingStateView
                        } else if !recommendationEngine.currentRecommendations.isEmpty {
                            recommendationsSectionView
                        } else {
                            emptyStateView
                        }
                        
                        Spacer(minLength: PitchSpacing.xxxl)
                    }
                    .padding(.vertical, PitchSpacing.lg)
                }
                .refreshable {
                    await refreshRecommendations()
                }
            }
            .navigationTitle("Ontdekken")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await refreshRecommendations()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(.pitchAccent)
                    }
                    .disabled(recommendationEngine.isAnalyzing)
                }
            }
            .onAppear {
                loadRecommendations()
                withAnimation(.pitchSpring.delay(0.1)) {
                    isLoaded = true
                }
            }
        }
    }
    
    // Header sectie met statistieken
    private var headerSectionView: some View {
        VStack(spacing: PitchSpacing.md) {
            HStack(spacing: PitchSpacing.lg) {
                VStack(spacing: PitchSpacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(LinearGradient.pitchAccentGradient)
                        .pitchGlow()
                    
                    Text("Voor Jou")
                        .font(PitchTypography.headline)
                        .foregroundColor(.pitchText)
                    
                    Text("Gepersonaliseerde aanbevelingen")
                        .font(PitchTypography.caption)
                        .foregroundColor(.pitchTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .pitchCard(padding: PitchSpacing.md)
                
                VStack(spacing: PitchSpacing.xs) {
                    Text("\(recommendationEngine.currentRecommendations.count)")
                        .font(PitchTypography.title2)
                        .foregroundColor(.pitchStarFilled)
                        .fontWeight(.bold)
                    
                    Text("Nieuwe Albums")
                        .font(PitchTypography.caption)
                        .foregroundColor(.pitchTextSecondary)
                }
                .pitchCard(padding: PitchSpacing.md)
                
                VStack(spacing: PitchSpacing.xs) {
                    Button(action: {
                        Task {
                            await refreshRecommendations()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundStyle(LinearGradient.pitchAccentGradient)
                    }
                    .disabled(recommendationEngine.isAnalyzing)
                    
                    Text("Vernieuwen")
                        .font(PitchTypography.caption2)
                        .foregroundColor(.pitchTextSecondary)
                }
                .pitchCard(padding: PitchSpacing.md)
            }
            
            // Laatste update indicator
            if let lastUpdate = recommendationEngine.lastAnalysisDate {
                Text("Laatst bijgewerkt: \(formatDate(lastUpdate))")
                    .font(PitchTypography.caption2)
                    .foregroundColor(.pitchTextTertiary)
            }
        }
        .padding(.horizontal, PitchSpacing.md)
        .scaleEffect(isLoaded ? 1.0 : 0.9)
        .opacity(isLoaded ? 1.0 : 0.0)
        .animation(.pitchSpring.delay(0.1), value: isLoaded)
    }
    
    // Loading state
    private var loadingStateView: some View {
        VStack(spacing: PitchSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .pitchAccent))
                .scaleEffect(2.0)
            
            VStack(spacing: PitchSpacing.sm) {
                Text("Analyseren van je muziek...")
                    .font(PitchTypography.headline)
                    .foregroundColor(.pitchText)
                
                Text("We bekijken je ratings om perfecte aanbevelingen te vinden")
                    .font(PitchTypography.body)
                    .foregroundColor(.pitchTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .pitchCard(padding: PitchSpacing.xl)
        .padding(.horizontal, PitchSpacing.md)
    }
    
    // Aanbevelingen sectie
    private var recommendationsSectionView: some View {
        VStack(alignment: .leading, spacing: PitchSpacing.lg) {
            HStack {
                Text("Aanbevelingen Voor Jou")
                    .font(PitchTypography.title3)
                    .foregroundColor(.pitchText)
                
                Spacer()
                
                Button("Vernieuwen") {
                    Task {
                        await refreshRecommendations()
                    }
                }
                .font(PitchTypography.callout)
                .foregroundColor(.pitchAccent)
                .disabled(recommendationEngine.isAnalyzing)
            }
            .padding(.horizontal, PitchSpacing.md)
            
            // Aanbevelingen grid
            LazyVStack(spacing: PitchSpacing.lg) {
                ForEach(recommendationEngine.currentRecommendations) { recommendation in
                    RecommendationCardView(recommendation: recommendation)
                        .onTapGesture {
                            // Markeer als gezien
                            recommendationEngine.markRecommendationAsSeen(recommendation.id)
                        }
                }
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: PitchSpacing.lg) {
            Image(systemName: "music.note.house")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient.pitchAccentGradient)
                .pitchGlow()
            
            VStack(spacing: PitchSpacing.sm) {
                Text("Geen aanbevelingen beschikbaar")
                    .font(PitchTypography.title3)
                    .foregroundColor(.pitchText)
                
                Text("Beoordeel eerst een paar albums om gepersonaliseerde aanbevelingen te krijgen")
                    .font(PitchTypography.body)
                    .foregroundColor(.pitchTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Genereer Aanbevelingen") {
                Task {
                    await refreshRecommendations()
                }
            }
            .buttonStyle(PitchPrimaryButtonStyle())
            .padding(.horizontal, PitchSpacing.xl)
        }
        .pitchCard(padding: PitchSpacing.xl)
        .padding(.horizontal, PitchSpacing.md)
    }
    
    // Laad aanbevelingen
    private func loadRecommendations() {
        // Als er geen recente aanbevelingen zijn, genereer nieuwe
        if !recommendationEngine.hasRecentRecommendations() {
            Task {
                await recommendationEngine.generateRecommendations()
            }
        }
    }
    
    // Vernieuw aanbevelingen
    private func refreshRecommendations() async {
        await recommendationEngine.generateRecommendations()
    }
    
    // Helper functie voor datum formatting
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Recommendation card component
struct RecommendationCardView: View {
    let recommendation: AlbumRecommendation
    @State private var isLoaded = false
    
    var body: some View {
        NavigationLink(destination: AlbumDetailView(album: recommendation.album)) {
            VStack(spacing: PitchSpacing.md) {
                // Album artwork en score
                HStack(spacing: PitchSpacing.md) {
                    // Album artwork
                    AsyncImage(url: URL(string: recommendation.album.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            LinearGradient.pitchCardGradient
                            
                            Image(systemName: "music.note")
                                .font(.system(size: 32))
                                .foregroundColor(.pitchTextTertiary)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .cornerRadius(PitchRadius.lg)
                    .pitchShadowMedium()
                    .overlay(
                        RoundedRectangle(cornerRadius: PitchRadius.lg)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Album informatie
                    VStack(alignment: .leading, spacing: PitchSpacing.sm) {
                        Text(recommendation.album.name)
                            .font(PitchTypography.headline)
                            .foregroundColor(.pitchText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(recommendation.album.artistNames)
                            .font(PitchTypography.callout)
                            .foregroundColor(.pitchTextSecondary)
                            .lineLimit(1)
                        
                        // Aanbeveling score
                        HStack(spacing: PitchSpacing.xs) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.pitchStarFilled)
                            
                            Text("\(Int(recommendation.score * 100))% match")
                                .font(PitchTypography.caption)
                                .foregroundColor(.pitchStarFilled)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, PitchSpacing.sm)
                        .padding(.vertical, PitchSpacing.xs)
                        .background(
                            Capsule()
                                .fill(Color.pitchStarFilled.opacity(0.2))
                        )
                        
                        // Tags
                        if !recommendation.tags.isEmpty {
                            HStack(spacing: PitchSpacing.xs) {
                                ForEach(recommendation.tags.prefix(2), id: \.self) { tag in
                                    Text(tag.capitalized)
                                        .font(PitchTypography.caption2)
                                        .foregroundColor(.pitchTextTertiary)
                                        .padding(.horizontal, PitchSpacing.xs)
                                        .padding(.vertical, PitchSpacing.xxs)
                                        .background(
                                            Capsule()
                                                .fill(Color.pitchCard.opacity(0.8))
                                        )
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Aanbeveling reden
                VStack(alignment: .leading, spacing: PitchSpacing.sm) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.pitchAccent)
                        
                        Text("Waarom dit album?")
                            .font(PitchTypography.callout)
                            .foregroundColor(.pitchAccent)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    
                    Text(recommendation.reason)
                        .font(PitchTypography.body)
                        .foregroundColor(.pitchTextSecondary)
                        .lineLimit(3)
                }
                .padding(PitchSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: PitchRadius.md)
                        .fill(Color.pitchAccent.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: PitchRadius.md)
                                .stroke(Color.pitchAccent.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Action button
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Bekijk Album")
                }
                .font(PitchTypography.callout)
                .foregroundColor(.pitchAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, PitchSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: PitchRadius.md)
                        .stroke(LinearGradient.pitchAccentGradient, lineWidth: 2)
                )
            }
            .padding(PitchSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PitchRadius.xl)
                    .fill(LinearGradient.pitchCardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PitchRadius.xl)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .pitchShadowMedium()
            .padding(.horizontal, PitchSpacing.md)
            .scaleEffect(isLoaded ? 1.0 : 0.9)
            .opacity(isLoaded ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.pitchSpring.delay(Double.random(in: 0...0.3))) {
                    isLoaded = true
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Discovery preferences view
struct DiscoveryPreferencesView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var preferPopular = true
    @State private var preferNew = true
    @State private var adventurousness: Double = 0.5
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.pitchBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: PitchSpacing.xl) {
                        // Header
                        VStack(spacing: PitchSpacing.md) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 60))
                                .foregroundStyle(LinearGradient.pitchAccentGradient)
                                .pitchGlow()
                            
                            Text("Discovery Voorkeuren")
                                .font(PitchTypography.title2)
                                .foregroundColor(.pitchText)
                            
                            Text("Stel in welke soort aanbevelingen je wilt ontvangen")
                                .font(PitchTypography.callout)
                                .foregroundColor(.pitchTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, PitchSpacing.lg)
                        
                        // Voorkeuren
                        VStack(spacing: PitchSpacing.lg) {
                            // Populaire albums
                            HStack {
                                VStack(alignment: .leading, spacing: PitchSpacing.xs) {
                                    Text("Populaire Albums")
                                        .font(PitchTypography.headline)
                                        .foregroundColor(.pitchText)
                                    
                                    Text("Toon albums die momenteel trending zijn")
                                        .font(PitchTypography.caption)
                                        .foregroundColor(.pitchTextSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $preferPopular)
                                    .toggleStyle(SwitchToggleStyle(tint: .pitchAccent))
                            }
                            .pitchCard(padding: PitchSpacing.md)
                            
                            // Nieuwe releases
                            HStack {
                                VStack(alignment: .leading, spacing: PitchSpacing.xs) {
                                    Text("Nieuwe Releases")
                                        .font(PitchTypography.headline)
                                        .foregroundColor(.pitchText)
                                    
                                    Text("Focus op recent uitgebrachte albums")
                                        .font(PitchTypography.caption)
                                        .foregroundColor(.pitchTextSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $preferNew)
                                    .toggleStyle(SwitchToggleStyle(tint: .pitchAccent))
                            }
                            .pitchCard(padding: PitchSpacing.md)
                            
                            // Avontuurlijkheid
                            VStack(alignment: .leading, spacing: PitchSpacing.md) {
                                Text("Avontuurlijkheid")
                                    .font(PitchTypography.headline)
                                    .foregroundColor(.pitchText)
                                
                                Text("Hoe ver buiten je comfort zone wil je gaan?")
                                    .font(PitchTypography.caption)
                                    .foregroundColor(.pitchTextSecondary)
                                
                                VStack(spacing: PitchSpacing.sm) {
                                    Slider(value: $adventurousness, in: 0...1)
                                        .accentColor(.pitchAccent)
                                    
                                    HStack {
                                        Text("Veilig")
                                            .font(PitchTypography.caption2)
                                            .foregroundColor(.pitchTextTertiary)
                                        
                                        Spacer()
                                        
                                        Text("Experimenteel")
                                            .font(PitchTypography.caption2)
                                            .foregroundColor(.pitchTextTertiary)
                                    }
                                }
                            }
                            .pitchCard(padding: PitchSpacing.md)
                        }
                        .padding(.horizontal, PitchSpacing.md)
                        
                        // Action buttons
                        VStack(spacing: PitchSpacing.md) {
                            Button("Opslaan") {
                                // Hier zouden we de voorkeuren opslaan
                                presentationMode.wrappedValue.dismiss()
                            }
                            .buttonStyle(PitchPrimaryButtonStyle())
                            .padding(.horizontal, PitchSpacing.md)
                            
                            Button("Annuleren") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .font(PitchTypography.callout)
                            .foregroundColor(.pitchTextSecondary)
                        }
                        
                        Spacer(minLength: PitchSpacing.xxxl)
                    }
                }
            }
            .navigationTitle("Voorkeuren")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.pitchTextSecondary)
                }
            }
        }
    }
}

// Add to playlist view
struct AddToPlaylistView: View {
    let album: SpotifyAlbum
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var playlistManager = PlaylistManager.shared
    @ObservedObject var storageManager = LocalStorageManager.shared
    @State private var selectedPlaylistId: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.pitchBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: PitchSpacing.xl) {
                        // Album info
                        VStack(spacing: PitchSpacing.md) {
                            AsyncImage(url: URL(string: album.imageUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                LinearGradient.pitchCardGradient
                            }
                            .frame(width: 120, height: 120)
                            .cornerRadius(PitchRadius.lg)
                            .pitchShadowMedium()
                            
                            VStack(spacing: PitchSpacing.xs) {
                                Text(album.name)
                                    .font(PitchTypography.headline)
                                    .foregroundColor(.pitchText)
                                    .multilineTextAlignment(.center)
                                
                                Text(album.artistNames)
                                    .font(PitchTypography.callout)
                                    .foregroundColor(.pitchTextSecondary)
                            }
                        }
                        .padding(.top, PitchSpacing.lg)
                        
                        // Playlists
                        VStack(alignment: .leading, spacing: PitchSpacing.md) {
                            Text("Kies een playlist:")
                                .font(PitchTypography.headline)
                                .foregroundColor(.pitchText)
                                .padding(.horizontal, PitchSpacing.md)
                            
                            if playlistManager.userPlaylists.isEmpty {
                                Text("Je hebt nog geen playlists. Maak er eerst een aan!")
                                    .font(PitchTypography.body)
                                    .foregroundColor(.pitchTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .pitchCard(padding: PitchSpacing.lg)
                                    .padding(.horizontal, PitchSpacing.md)
                            } else {
                                LazyVStack(spacing: PitchSpacing.sm) {
                                    ForEach(playlistManager.userPlaylists) { playlist in
                                        Button(action: {
                                            selectedPlaylistId = playlist.id
                                            addToPlaylist(playlist)
                                        }) {
                                            HStack(spacing: PitchSpacing.md) {
                                                Image(systemName: "music.note.list")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.pitchAccent)
                                                
                                                VStack(alignment: .leading, spacing: PitchSpacing.xs) {
                                                    Text(playlist.name)
                                                        .font(PitchTypography.callout)
                                                        .foregroundColor(.pitchText)
                                                    
                                                    Text("\(playlist.albumIds.count) albums")
                                                        .font(PitchTypography.caption)
                                                        .foregroundColor(.pitchTextSecondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.pitchTextTertiary)
                                            }
                                            .padding(PitchSpacing.md)
                                            .background(
                                                RoundedRectangle(cornerRadius: PitchRadius.lg)
                                                    .fill(LinearGradient.pitchCardGradient)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: PitchRadius.lg)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, PitchSpacing.md)
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: PitchSpacing.xxxl)
                    }
                }
            }
            .navigationTitle("Toevoegen aan Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.pitchTextSecondary)
                }
            }
            .onAppear {
                playlistManager.loadPlaylists()
            }
        }
    }
    
    private func addToPlaylist(_ playlist: LocalPlaylist) {
        let success = playlistManager.addAlbumToPlaylist(playlistId: playlist.id, albumId: album.id)
        
        if success {
            presentationMode.wrappedValue.dismiss()
        }
    }
} 