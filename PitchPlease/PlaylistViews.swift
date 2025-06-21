// Playlist Views voor het weergeven en beheren van playlists
// Deze file bevat alle UI componenten voor het playlist systeem
import SwiftUI

// Playlist overzicht view
struct PlaylistsView: View {
    @StateObject private var playlistManager = PlaylistManager.shared
    @ObservedObject var storageManager = LocalStorageManager.shared
    @State private var showingCreatePlaylist = false
    @State private var isLoaded = false
    
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
                        
                        // Gebruiker playlists sectie
                        if !playlistManager.userPlaylists.isEmpty {
                            userPlaylistsSectionView
                        }
                        
                        // Publieke playlists sectie
                        if !playlistManager.publicPlaylists.isEmpty {
                            publicPlaylistsSectionView
                        }
                        
                        // Empty state
                        if playlistManager.userPlaylists.isEmpty && playlistManager.publicPlaylists.isEmpty {
                            emptyStateView
                        }
                        
                        Spacer(minLength: PitchSpacing.xxxl)
                    }
                    .padding(.vertical, PitchSpacing.lg)
                }
            }
            .navigationTitle("Playlists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreatePlaylist = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(LinearGradient.pitchAccentGradient)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlaylist) {
                CreatePlaylistView()
            }
            .onAppear {
                playlistManager.loadPlaylists()
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
                    Text("\(playlistManager.userPlaylists.count)")
                        .font(PitchTypography.title2)
                        .foregroundColor(.pitchAccent)
                        .fontWeight(.bold)
                    
                    Text("Mijn Playlists")
                        .font(PitchTypography.caption)
                        .foregroundColor(.pitchTextSecondary)
                }
                .pitchCard(padding: PitchSpacing.md)
                
                VStack(spacing: PitchSpacing.xs) {
                    Text("\(playlistManager.publicPlaylists.count)")
                        .font(PitchTypography.title2)
                        .foregroundColor(.pitchStarFilled)
                        .fontWeight(.bold)
                    
                    Text("Publieke Playlists")
                        .font(PitchTypography.caption)
                        .foregroundColor(.pitchTextSecondary)
                }
                .pitchCard(padding: PitchSpacing.md)
                
                // Quick action buttons
                VStack(spacing: PitchSpacing.xs) {
                    Button(action: {
                        createSmartPlaylist()
                    }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundStyle(LinearGradient.pitchAccentGradient)
                    }
                    
                    Text("Smart Playlist")
                        .font(PitchTypography.caption2)
                        .foregroundColor(.pitchTextSecondary)
                }
                .pitchCard(padding: PitchSpacing.md)
            }
        }
        .padding(.horizontal, PitchSpacing.md)
        .scaleEffect(isLoaded ? 1.0 : 0.9)
        .opacity(isLoaded ? 1.0 : 0.0)
        .animation(.pitchSpring.delay(0.1), value: isLoaded)
    }
    
    // Gebruiker playlists sectie
    private var userPlaylistsSectionView: some View {
        VStack(alignment: .leading, spacing: PitchSpacing.md) {
            HStack {
                Text("Mijn Playlists")
                    .font(PitchTypography.title3)
                    .foregroundColor(.pitchText)
                
                Spacer()
                
                Button("Maak Nieuwe") {
                    showingCreatePlaylist = true
                }
                .font(PitchTypography.callout)
                .foregroundColor(.pitchAccent)
            }
            .padding(.horizontal, PitchSpacing.md)
            
            LazyVStack(spacing: PitchSpacing.md) {
                ForEach(playlistManager.userPlaylists) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        PlaylistRowView(playlist: playlist, canEdit: true)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // Publieke playlists sectie
    private var publicPlaylistsSectionView: some View {
        VStack(alignment: .leading, spacing: PitchSpacing.md) {
            Text("Ontdek Playlists")
                .font(PitchTypography.title3)
                .foregroundColor(.pitchText)
                .padding(.horizontal, PitchSpacing.md)
            
            LazyVStack(spacing: PitchSpacing.md) {
                ForEach(playlistManager.publicPlaylists) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        PlaylistRowView(playlist: playlist, canEdit: false)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: PitchSpacing.lg) {
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient.pitchAccentGradient)
                .pitchGlow()
            
            VStack(spacing: PitchSpacing.sm) {
                Text("Nog geen playlists")
                    .font(PitchTypography.title3)
                    .foregroundColor(.pitchText)
                
                Text("Maak je eerste playlist om je favoriete albums te verzamelen")
                    .font(PitchTypography.body)
                    .foregroundColor(.pitchTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Maak Je Eerste Playlist") {
                showingCreatePlaylist = true
            }
            .buttonStyle(PitchPrimaryButtonStyle())
            .padding(.horizontal, PitchSpacing.xl)
        }
        .pitchCard(padding: PitchSpacing.xl)
        .padding(.horizontal, PitchSpacing.md)
    }
    
    // Smart playlist maken
    private func createSmartPlaylist() {
        guard let currentUser = storageManager.currentUser else { return }
        
        let _ = playlistManager.createSmartPlaylist(
            name: "Mijn 5-Sterren Albums",
            userId: currentUser.id,
            minRating: 5
        )
    }
}

// Playlist row component
struct PlaylistRowView: View {
    let playlist: LocalPlaylist
    let canEdit: Bool
    @StateObject private var playlistManager = PlaylistManager.shared
    @State private var albums: [LocalAlbumRating] = []
    @State private var isLoaded = false
    
    var body: some View {
        HStack(spacing: PitchSpacing.md) {
            // Cover art collage
            playlistCoverView
            
            // Playlist informatie
            VStack(alignment: .leading, spacing: PitchSpacing.xs) {
                Text(playlist.name)
                    .font(PitchTypography.headline)
                    .foregroundColor(.pitchText)
                    .lineLimit(2)
                
                if let description = playlist.description {
                    Text(description)
                        .font(PitchTypography.callout)
                        .foregroundColor(.pitchTextSecondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: PitchSpacing.sm) {
                    Image(systemName: "music.note")
                        .foregroundColor(.pitchTextTertiary)
                        .font(.system(size: 12))
                    
                    Text("\(playlist.albumIds.count) albums")
                        .font(PitchTypography.caption)
                        .foregroundColor(.pitchTextTertiary)
                    
                    if playlist.isPublic {
                        Image(systemName: "globe")
                            .foregroundColor(.pitchAccent)
                            .font(.system(size: 12))
                    }
                }
                
                Text("Bijgewerkt \(formatDate(playlist.updatedAt))")
                    .font(PitchTypography.caption2)
                    .foregroundColor(.pitchTextTertiary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(LinearGradient.pitchAccentGradient)
                .opacity(0.8)
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
        .pitchShadowMedium()
        .padding(.horizontal, PitchSpacing.md)
        .scaleEffect(isLoaded ? 1.0 : 0.9)
        .opacity(isLoaded ? 1.0 : 0.0)
        .onAppear {
            loadAlbums()
            withAnimation(.pitchSpring.delay(Double.random(in: 0...0.3))) {
                isLoaded = true
            }
        }
    }
    
    // Playlist cover view met album covers
    private var playlistCoverView: some View {
        ZStack {
            if albums.isEmpty {
                // Fallback cover
                RoundedRectangle(cornerRadius: PitchRadius.md)
                    .fill(LinearGradient.pitchCardGradient)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note.list")
                            .font(.system(size: 24))
                            .foregroundColor(.pitchTextTertiary)
                    )
            } else if albums.count == 1 {
                // Enkele cover
                AsyncImage(url: URL(string: albums[0].albumImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    LinearGradient.pitchCardGradient
                }
                .frame(width: 60, height: 60)
                .cornerRadius(PitchRadius.md)
            } else {
                // Collage van meerdere covers (2x2 grid)
                LazyVGrid(columns: [
                    GridItem(.fixed(28), spacing: 2),
                    GridItem(.fixed(28), spacing: 2)
                ], spacing: 2) {
                    ForEach(Array(albums.prefix(4).enumerated()), id: \.offset) { index, album in
                        AsyncImage(url: URL(string: album.albumImageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            LinearGradient.pitchCardGradient
                        }
                        .frame(width: 28, height: 28)
                        .cornerRadius(4)
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(PitchRadius.md)
            }
        }
        .pitchShadowSmall()
    }
    
    // Laad albums voor deze playlist
    private func loadAlbums() {
        albums = playlistManager.getAlbumsForPlaylist(playlistId: playlist.id)
    }
    
    // Helper functie voor datum formatting
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Create playlist view
struct CreatePlaylistView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var playlistManager = PlaylistManager.shared
    @ObservedObject var storageManager = LocalStorageManager.shared
    
    @State private var playlistName = ""
    @State private var playlistDescription = ""
    @State private var isPublic = false
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.pitchBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: PitchSpacing.xl) {
                        // Header
                        VStack(spacing: PitchSpacing.md) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(LinearGradient.pitchAccentGradient)
                                .pitchGlow()
                            
                            Text("Nieuwe Playlist")
                                .font(PitchTypography.title2)
                                .foregroundColor(.pitchText)
                            
                            Text("Verzamel je favoriete albums in een playlist")
                                .font(PitchTypography.callout)
                                .foregroundColor(.pitchTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, PitchSpacing.lg)
                        
                        // Form
                        VStack(spacing: PitchSpacing.lg) {
                            // Playlist naam
                            VStack(alignment: .leading, spacing: PitchSpacing.sm) {
                                Text("Playlist Naam")
                                    .font(PitchTypography.headline)
                                    .foregroundColor(.pitchText)
                                
                                TextField("Bijv. Mijn Favoriete Rock Albums", text: $playlistName)
                                    .font(PitchTypography.body)
                                    .foregroundColor(.pitchText)
                                    .padding(PitchSpacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: PitchRadius.lg)
                                            .fill(Color.pitchCard.opacity(0.7))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: PitchRadius.lg)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                            
                            // Beschrijving
                            VStack(alignment: .leading, spacing: PitchSpacing.sm) {
                                Text("Beschrijving (Optioneel)")
                                    .font(PitchTypography.headline)
                                    .foregroundColor(.pitchText)
                                
                                TextField("Korte beschrijving van je playlist...", text: $playlistDescription, axis: .vertical)
                                    .font(PitchTypography.body)
                                    .foregroundColor(.pitchText)
                                    .padding(PitchSpacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: PitchRadius.lg)
                                            .fill(Color.pitchCard.opacity(0.7))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: PitchRadius.lg)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    .lineLimit(3...6)
                            }
                            
                            // Publiek maken toggle
                            HStack {
                                VStack(alignment: .leading, spacing: PitchSpacing.xs) {
                                    Text("Publiek Maken")
                                        .font(PitchTypography.headline)
                                        .foregroundColor(.pitchText)
                                    
                                    Text("Andere gebruikers kunnen je playlist zien")
                                        .font(PitchTypography.caption)
                                        .foregroundColor(.pitchTextSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $isPublic)
                                    .toggleStyle(SwitchToggleStyle(tint: .pitchAccent))
                            }
                            .pitchCard(padding: PitchSpacing.md)
                        }
                        .padding(.horizontal, PitchSpacing.md)
                        
                        // Action buttons
                        VStack(spacing: PitchSpacing.md) {
                            Button(action: createPlaylist) {
                                HStack {
                                    if isCreating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                    
                                    Text(isCreating ? "Playlist Maken..." : "Playlist Maken")
                                }
                            }
                            .buttonStyle(PitchPrimaryButtonStyle(isDisabled: playlistName.isEmpty || isCreating))
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
            .navigationTitle("Nieuwe Playlist")
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
    
    // Create playlist functie
    private func createPlaylist() {
        guard let currentUser = storageManager.currentUser else { return }
        guard !playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isCreating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let _ = playlistManager.createPlaylist(
                name: playlistName.trimmingCharacters(in: .whitespacesAndNewlines),
                description: playlistDescription.isEmpty ? nil : playlistDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                userId: currentUser.id,
                isPublic: isPublic
            )
            
            isCreating = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// Playlist detail view
struct PlaylistDetailView: View {
    let playlist: LocalPlaylist
    @StateObject private var playlistManager = PlaylistManager.shared
    @State private var albums: [LocalAlbumRating] = []
    @State private var isLoaded = false
    
    var body: some View {
        ZStack {
            LinearGradient.pitchBackgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: PitchSpacing.xl) {
                    // Header met playlist info
                    playlistHeaderView
                    
                    // Albums in playlist
                    if !albums.isEmpty {
                        albumsListView
                    } else {
                        emptyPlaylistView
                    }
                    
                    Spacer(minLength: PitchSpacing.xxxl)
                }
                .padding(.vertical, PitchSpacing.lg)
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadAlbums()
            withAnimation(.pitchSpring.delay(0.1)) {
                isLoaded = true
            }
        }
    }
    
    // Header met playlist informatie
    private var playlistHeaderView: some View {
        VStack(spacing: PitchSpacing.lg) {
            // Playlist cover
            Group {
                if albums.isEmpty {
                    // Fallback cover
                    RoundedRectangle(cornerRadius: PitchRadius.xl)
                        .fill(LinearGradient.pitchCardGradient)
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.system(size: 60))
                                .foregroundColor(.pitchTextTertiary)
                        )
                } else if albums.count == 1 {
                    // Enkele cover
                    AsyncImage(url: URL(string: albums[0].albumImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        LinearGradient.pitchCardGradient
                    }
                    .frame(width: 200, height: 200)
                    .cornerRadius(PitchRadius.xl)
                } else {
                    // Collage van covers
                    LazyVGrid(columns: [
                        GridItem(.fixed(95), spacing: 5),
                        GridItem(.fixed(95), spacing: 5)
                    ], spacing: 5) {
                        ForEach(Array(albums.prefix(4).enumerated()), id: \.offset) { index, album in
                            AsyncImage(url: URL(string: album.albumImageUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                LinearGradient.pitchCardGradient
                            }
                            .frame(width: 95, height: 95)
                            .cornerRadius(PitchRadius.md)
                        }
                    }
                    .frame(width: 200, height: 200)
                    .cornerRadius(PitchRadius.xl)
                }
            }
            .pitchShadowLarge()
            .overlay(
                RoundedRectangle(cornerRadius: PitchRadius.xl)
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
            )
            .scaleEffect(isLoaded ? 1.0 : 0.8)
            .animation(.pitchSpring.delay(0.2), value: isLoaded)
            
            // Playlist informatie
            VStack(spacing: PitchSpacing.md) {
                Text(playlist.name)
                    .font(PitchTypography.title2)
                    .foregroundColor(.pitchText)
                    .multilineTextAlignment(.center)
                
                if let description = playlist.description {
                    Text(description)
                        .font(PitchTypography.body)
                        .foregroundColor(.pitchTextSecondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: PitchSpacing.lg) {
                    HStack(spacing: PitchSpacing.xs) {
                        Image(systemName: "music.note")
                            .foregroundColor(.pitchTextTertiary)
                        Text("\(albums.count) albums")
                            .font(PitchTypography.callout)
                            .foregroundColor(.pitchTextTertiary)
                    }
                    
                    if playlist.isPublic {
                        HStack(spacing: PitchSpacing.xs) {
                            Image(systemName: "globe")
                                .foregroundColor(.pitchAccent)
                            Text("Publiek")
                                .font(PitchTypography.callout)
                                .foregroundColor(.pitchAccent)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, PitchSpacing.md)
        .scaleEffect(isLoaded ? 1.0 : 0.9)
        .opacity(isLoaded ? 1.0 : 0.0)
        .animation(.pitchSpring.delay(0.1), value: isLoaded)
    }
    
    // Albums lijst
    private var albumsListView: some View {
        VStack(alignment: .leading, spacing: PitchSpacing.md) {
            Text("Albums")
                .font(PitchTypography.title3)
                .foregroundColor(.pitchText)
                .padding(.horizontal, PitchSpacing.md)
            
            LazyVStack(spacing: PitchSpacing.md) {
                ForEach(albums) { album in
                    NavigationLink(destination: AlbumDetailView(album: SpotifyAlbum(
                        id: album.albumId,
                        name: album.albumName,
                        artists: [SpotifyArtist(id: "artist", name: album.artistName)],
                        images: album.albumImageUrl != nil ? [SpotifyImage(url: album.albumImageUrl!, height: 300, width: 300)] : [],
                        releaseDate: "",
                        totalTracks: 0
                    ))) {
                        PlaylistAlbumRowView(album: album)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // Empty playlist view
    private var emptyPlaylistView: some View {
        VStack(spacing: PitchSpacing.lg) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.pitchTextTertiary)
            
            Text("Geen albums in deze playlist")
                .font(PitchTypography.headline)
                .foregroundColor(.pitchText)
            
            Text("Voeg albums toe door ze te zoeken en het playlist icoon te gebruiken")
                .font(PitchTypography.body)
                .foregroundColor(.pitchTextSecondary)
                .multilineTextAlignment(.center)
        }
        .pitchCard(padding: PitchSpacing.xl)
        .padding(.horizontal, PitchSpacing.md)
    }
    
    // Laad albums voor deze playlist
    private func loadAlbums() {
        albums = playlistManager.getAlbumsForPlaylist(playlistId: playlist.id)
    }
}

// Album row in playlist
struct PlaylistAlbumRowView: View {
    let album: LocalAlbumRating
    
    var body: some View {
        HStack(spacing: PitchSpacing.md) {
            // Album artwork
            AsyncImage(url: URL(string: album.albumImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                LinearGradient.pitchCardGradient
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.pitchTextTertiary)
                    )
            }
            .frame(width: 60, height: 60)
            .cornerRadius(PitchRadius.md)
            .pitchShadowSmall()
            
            // Album informatie
            VStack(alignment: .leading, spacing: PitchSpacing.xs) {
                Text(album.albumName)
                    .font(PitchTypography.headline)
                    .foregroundColor(.pitchText)
                    .lineLimit(1)
                
                Text(album.artistName)
                    .font(PitchTypography.callout)
                    .foregroundColor(.pitchTextSecondary)
                    .lineLimit(1)
                
                HStack(spacing: PitchSpacing.xs) {
                    ModernStarRatingView(rating: Double(album.rating), size: 14)
                    Text("\(album.rating)/5")
                        .font(PitchTypography.caption)
                        .foregroundColor(.pitchStarFilled)
                }
            }
            
            Spacer()
            
            // Navigation chevron
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
        .pitchShadowSmall()
        .padding(.horizontal, PitchSpacing.md)
    }
} 