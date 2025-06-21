// Main Tab View die de verschillende onderdelen van de app bevat
// Deze view toont de navigatie tabs en zorgt voor de overall app structuur
import SwiftUI

// Main tab view met verschillende schermen
struct MainTabView: View {
    @ObservedObject var storageManager = LocalStorageManager.shared
    
    var body: some View {
        TabView {
            // Search tab - zoeken naar albums
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass.circle.fill")
                    Text("Zoeken")
                }
            
            // Feed tab - bekijk alle ratings
            FeedView()
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Feed")
                }
            
            // Discovery tab - aanbevelingen
            DiscoveryView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Ontdekken")
                }
            
            // My Ratings tab - eigen ratings
            MyRatingsView()
                .tabItem {
                    Image(systemName: "star.circle.fill")
                    Text("Mijn Ratings")
                }
            
            // Playlists tab - playlist beheer
            PlaylistsView()
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Playlists")
                }
            
            // Profile tab - gebruikersprofiel
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profiel")
                }
        }
        .background(LinearGradient.pitchBackgroundGradient.ignoresSafeArea())
        .accentColor(.pitchAccent)
        .onAppear {
            // Custom tab bar styling
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(Color.pitchCard.opacity(0.8))
            
            // Tab bar item colors
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.pitchAccent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color.pitchAccent)
            ]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.pitchTextTertiary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Color.pitchTextTertiary)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// Search view voor het zoeken van albums
struct SearchView: View {
    @StateObject private var spotifyManager = SpotifyManager.shared
    @State private var searchText = ""
    @State private var searchResults: [SpotifyAlbum] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showSearchResults = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient.pitchBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: PitchSpacing.lg) {
                        // Header met app logo
                        VStack(spacing: PitchSpacing.sm) {
                            Image(systemName: "music.note.house.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(LinearGradient.pitchAccentGradient)
                                .pitchGlow()
                            
                            Text("PitchPlease")
                                .font(PitchTypography.title1)
                                .foregroundColor(.pitchText)
                            
                            Text("Ontdek en beoordeel je favoriete albums")
                                .font(PitchTypography.callout)
                                .foregroundColor(.pitchTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, PitchSpacing.lg)
                        
                        // Modern search bar
                        VStack(spacing: PitchSpacing.md) {
                            HStack(spacing: PitchSpacing.sm) {
                                HStack(spacing: PitchSpacing.sm) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.pitchTextSecondary)
                                    
                                    TextField("Zoek albums, artiesten...", text: $searchText)
                                        .font(PitchTypography.body)
                                        .foregroundColor(.pitchText)
                                        .onSubmit {
                                            performSearch()
                                        }
                                }
                                .padding(PitchSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: PitchRadius.lg)
                                        .fill(Color.pitchCard.opacity(0.7))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: PitchRadius.lg)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .glassmorphism()
                                
                                // Search button
                                Button(action: performSearch) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(LinearGradient.pitchAccentGradient)
                                }
                                .disabled(searchText.isEmpty || isLoading)
                                .scaleEffect(searchText.isEmpty ? 0.8 : 1.0)
                                .animation(.pitchSpring, value: searchText.isEmpty)
                            }
                            
                            // Quick search suggestions
                            if searchText.isEmpty && !showSearchResults {
                                VStack(alignment: .leading, spacing: PitchSpacing.sm) {
                                    Text("Populaire zoekopdrachten:")
                                        .font(PitchTypography.caption)
                                        .foregroundColor(.pitchTextTertiary)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: PitchSpacing.xs) {
                                        ForEach(["Taylor Swift", "The Beatles", "Radiohead", "Billie Eilish"], id: \.self) { suggestion in
                                            Button(suggestion) {
                                                searchText = suggestion
                                                performSearch()
                                            }
                                            .font(PitchTypography.caption)
                                            .foregroundColor(.pitchTextSecondary)
                                            .padding(.horizontal, PitchSpacing.sm)
                                            .padding(.vertical, PitchSpacing.xs)
                                            .background(
                                                Capsule()
                                                    .fill(Color.pitchCard.opacity(0.5))
                                            )
                                        }
                                    }
                                }
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .padding(.horizontal, PitchSpacing.md)
                        
                        // Error message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(PitchTypography.callout)
                                .foregroundColor(.pitchError)
                                .pitchCard()
                                .padding(.horizontal, PitchSpacing.md)
                        }
                        
                        // Loading indicator
                        if isLoading {
                            VStack(spacing: PitchSpacing.md) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .pitchAccent))
                                    .scaleEffect(1.5)
                                
                                Text("Albums zoeken...")
                                    .font(PitchTypography.callout)
                                    .foregroundColor(.pitchTextSecondary)
                            }
                            .pitchCard()
                            .padding(.horizontal, PitchSpacing.md)
                        }
                        
                        // Search results
                        if !searchResults.isEmpty {
                            LazyVStack(spacing: PitchSpacing.md) {
                                ForEach(searchResults) { album in
                                    NavigationLink(destination: AlbumDetailView(album: album).withRatingForm()) {
                                        ModernAlbumRowView(album: album)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, PitchSpacing.md)
                        }
                        
                        // Empty state wanneer geen zoekresultaten
                        if showSearchResults && searchResults.isEmpty && !isLoading && errorMessage.isEmpty {
                            VStack(spacing: PitchSpacing.md) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 50))
                                    .foregroundColor(.pitchTextTertiary)
                                
                                Text("Geen albums gevonden")
                                    .font(PitchTypography.headline)
                                    .foregroundColor(.pitchTextSecondary)
                                
                                Text("Probeer een andere zoekopdracht")
                                    .font(PitchTypography.callout)
                                    .foregroundColor(.pitchTextTertiary)
                            }
                            .pitchCard()
                            .padding(.horizontal, PitchSpacing.md)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // Functie om zoekactie uit te voeren
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        showSearchResults = true
        
        // Smooth animation voor state changes
        withAnimation(.pitchEaseOut) {
            searchResults = []
        }
        
        Task {
            do {
                let results = try await spotifyManager.searchAlbums(query: searchText)
                
                DispatchQueue.main.async {
                    withAnimation(.pitchSpring) {
                        searchResults = results
                        isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    withAnimation(.pitchEaseOut) {
                        isLoading = false
                        errorMessage = "Zoeken mislukt: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

// Feed view voor het bekijken van alle ratings
struct FeedView: View {
    @StateObject private var storageManager = LocalStorageManager.shared
    @State private var ratings: [LocalAlbumRating] = []
    @State private var isLoading = true
    @State private var isLoaded = false
    
    private var sortedRatings: [LocalAlbumRating] {
        ratings.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient.pitchBackgroundGradient
                    .ignoresSafeArea()
                
                if isLoading {
                    // Loading state
                    VStack(spacing: PitchSpacing.lg) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pitchAccent))
                            .scaleEffect(1.5)
                        
                        Text("Community feed laden...")
                            .font(PitchTypography.callout)
                            .foregroundColor(.pitchTextSecondary)
                    }
                } else if ratings.isEmpty {
                    // Empty state
                    VStack(spacing: PitchSpacing.lg) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 80))
                            .foregroundColor(.pitchTextTertiary)
                            .pitchGlow(color: .pitchAccent.opacity(0.3))
                        
                        VStack(spacing: PitchSpacing.sm) {
                            Text("Nog geen ratings")
                                .font(PitchTypography.title3)
                                .foregroundColor(.pitchTextSecondary)
                            
                            Text("Ratings van alle gebruikers verschijnen hier wanneer er albums zijn beoordeeld")
                                .font(PitchTypography.callout)
                                .foregroundColor(.pitchTextTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, PitchSpacing.xl)
                        }
                        
                        Button("Zoek Albums") {
                            // Kan later worden geïmplementeerd voor navigatie naar search tab
                        }
                        .buttonStyle(PitchSecondaryButtonStyle())
                        .padding(.horizontal, PitchSpacing.xl)
                    }
                    .pitchCard(padding: PitchSpacing.xl)
                    .padding(.horizontal, PitchSpacing.md)
                } else {
                    ScrollView {
                        LazyVStack(spacing: PitchSpacing.lg) {
                            // Header
                            VStack(spacing: PitchSpacing.sm) {
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 28))
                                        .foregroundStyle(LinearGradient.pitchAccentGradient)
                                    
                                    Text("Community Feed")
                                        .font(PitchTypography.title2)
                                        .foregroundColor(.pitchText)
                                }
                                
                                Text("\(ratings.count) recente rating\(ratings.count == 1 ? "" : "s")")
                                    .font(PitchTypography.callout)
                                    .foregroundColor(.pitchTextSecondary)
                            }
                            .padding(.top, PitchSpacing.lg)
                            .scaleEffect(isLoaded ? 1.0 : 0.9)
                            .opacity(isLoaded ? 1.0 : 0.0)
                            .animation(.pitchSpring.delay(0.1), value: isLoaded)
                            
                            // Ratings lijst
                            ForEach(Array(sortedRatings.enumerated()), id: \.element.id) { index, rating in
                                ModernFeedRatingRowView(rating: rating)
                                    .scaleEffect(isLoaded ? 1.0 : 0.9)
                                    .opacity(isLoaded ? 1.0 : 0.0)
                                    .animation(.pitchSpring.delay(0.2 + Double(index) * 0.1), value: isLoaded)
                            }
                            
                            Spacer(minLength: PitchSpacing.xxxl)
                        }
                        .padding(.horizontal, PitchSpacing.md)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear {
                loadRatings()
                withAnimation(.pitchSpring.delay(0.1)) {
                    isLoaded = true
                }
            }
            .refreshable {
                loadRatings()
            }
        }
    }
    
    // Functie om ratings te laden
    private func loadRatings() {
        isLoading = true
        
        let publicRatings = storageManager.getAllRatings()
        withAnimation(.pitchEaseOut) {
            ratings = publicRatings
            isLoading = false
        }
    }
}

// My Ratings view voor eigen ratings
struct MyRatingsView: View {
    @StateObject private var storageManager = LocalStorageManager.shared
    @State private var myRatings: [LocalAlbumRating] = []
    @State private var isLoading = true
    @State private var isLoaded = false
    
    private var sortedRatings: [LocalAlbumRating] {
        myRatings.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient.pitchBackgroundGradient
                    .ignoresSafeArea()
                
                if isLoading {
                    // Loading state
                    VStack(spacing: PitchSpacing.lg) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pitchAccent))
                            .scaleEffect(1.5)
                        
                        Text("Jouw ratings laden...")
                            .font(PitchTypography.callout)
                            .foregroundColor(.pitchTextSecondary)
                    }
                } else if myRatings.isEmpty {
                    // Empty state
                    VStack(spacing: PitchSpacing.lg) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 100))
                            .foregroundStyle(LinearGradient.pitchAccentGradient)
                            .pitchGlow()
                        
                        VStack(spacing: PitchSpacing.md) {
                            Text("Nog geen ratings")
                                .font(PitchTypography.title2)
                                .foregroundColor(.pitchText)
                            
                            Text("Zoek naar albums en geef je eerste rating!")
                                .font(PitchTypography.callout)
                                .foregroundColor(.pitchTextSecondary)
                                .multilineTextAlignment(.center)
                            
                            Text("Jouw beoordelingen en reviews verschijnen hier")
                                .font(PitchTypography.caption)
                                .foregroundColor(.pitchTextTertiary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Begin met beoordelen") {
                            // Kan later worden geïmplementeerd voor navigatie naar search tab
                        }
                        .buttonStyle(PitchPrimaryButtonStyle())
                        .padding(.horizontal, PitchSpacing.xl)
                    }
                    .pitchCard(padding: PitchSpacing.xl)
                    .padding(.horizontal, PitchSpacing.md)
                } else {
                    ScrollView {
                        LazyVStack(spacing: PitchSpacing.lg) {
                            // Header met statistieken
                            VStack(spacing: PitchSpacing.lg) {
                                HStack {
                                    Image(systemName: "star.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(LinearGradient.pitchAccentGradient)
                                    
                                    Text("Mijn Ratings")
                                        .font(PitchTypography.title2)
                                        .foregroundColor(.pitchText)
                                }
                                .scaleEffect(isLoaded ? 1.0 : 0.9)
                                .opacity(isLoaded ? 1.0 : 0.0)
                                .animation(.pitchSpring.delay(0.1), value: isLoaded)
                                
                                // Statistieken cards
                                HStack(spacing: PitchSpacing.md) {
                                    VStack(spacing: PitchSpacing.xs) {
                                        Text("\(myRatings.count)")
                                            .font(PitchTypography.title1)
                                            .foregroundColor(.pitchAccent)
                                            .fontWeight(.bold)
                                        
                                        Text("Album\(myRatings.count == 1 ? "" : "s")")
                                            .font(PitchTypography.caption)
                                            .foregroundColor(.pitchTextTertiary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .pitchCard()
                                    
                                    VStack(spacing: PitchSpacing.xs) {
                                        Text(String(format: "%.1f", averageUserRating))
                                            .font(PitchTypography.title1)
                                            .foregroundColor(.pitchStarFilled)
                                            .fontWeight(.bold)
                                        
                                        Text("Gemiddeld")
                                            .font(PitchTypography.caption)
                                            .foregroundColor(.pitchTextTertiary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .pitchCard()
                                }
                                .scaleEffect(isLoaded ? 1.0 : 0.9)
                                .opacity(isLoaded ? 1.0 : 0.0)
                                .animation(.pitchSpring.delay(0.2), value: isLoaded)
                            }
                            .padding(.top, PitchSpacing.lg)
                            
                            // Ratings lijst
                            VStack(alignment: .leading, spacing: PitchSpacing.md) {
                                HStack {
                                    Text("Recente Beoordelingen")
                                        .font(PitchTypography.headline)
                                        .foregroundColor(.pitchText)
                                    Spacer()
                                }
                                
                                ForEach(Array(sortedRatings.enumerated()), id: \.element.id) { index, rating in
                                    ModernMyRatingRowView(rating: rating)
                                        .scaleEffect(isLoaded ? 1.0 : 0.9)
                                        .opacity(isLoaded ? 1.0 : 0.0)
                                        .animation(.pitchSpring.delay(0.3 + Double(index) * 0.1), value: isLoaded)
                                }
                            }
                            
                            Spacer(minLength: PitchSpacing.xxxl)
                        }
                        .padding(.horizontal, PitchSpacing.md)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear {
                loadMyRatings()
                withAnimation(.pitchSpring.delay(0.1)) {
                    isLoaded = true
                }
            }
            .refreshable {
                loadMyRatings()
            }
        }
    }
    
    // Computed property voor gemiddelde rating
    private var averageUserRating: Double {
        guard !myRatings.isEmpty else { return 0.0 }
        let total = myRatings.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(myRatings.count)
    }
    
    // Functie om eigen ratings te laden
    private func loadMyRatings() {
        isLoading = true
        
        // Haal alleen ratings van de ingelogde gebruiker op
        let userRatings: [LocalAlbumRating]
        if let currentUser = storageManager.currentUser {
            userRatings = storageManager.getAllRatings().filter { $0.userId == currentUser.id }
        } else {
            userRatings = []
        }
        
        withAnimation(.pitchEaseOut) {
            myRatings = userRatings
            isLoading = false
        }
    }
}

// Profile view voor gebruikersprofiel
struct ProfileView: View {
    @ObservedObject var storageManager = LocalStorageManager.shared
    @State private var isLoaded = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient.pitchBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: PitchSpacing.xl) {
                        // Profile header
                        VStack(spacing: PitchSpacing.lg) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.pitchAccentGradient)
                                    .frame(width: 120, height: 120)
                                    .pitchShadowLarge()
                                
                                Text("\(storageManager.currentUser?.displayName.prefix(1).uppercased() ?? "U")")
                                    .font(PitchTypography.title1)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .scaleEffect(isLoaded ? 1.0 : 0.8)
                            .animation(.pitchSpring.delay(0.1), value: isLoaded)
                            
                            // User info
                            VStack(spacing: PitchSpacing.sm) {
                                Text(storageManager.currentUser?.displayName ?? "Gebruiker")
                                    .font(PitchTypography.title2)
                                    .foregroundColor(.pitchText)
                                    .fontWeight(.semibold)
                                
                                Text(storageManager.currentUser?.email ?? "geen email")
                                    .font(PitchTypography.callout)
                                    .foregroundColor(.pitchTextSecondary)
                                
                                HStack(spacing: PitchSpacing.xs) {
                                    Image(systemName: "music.note")
                                        .foregroundColor(.pitchAccent)
                                    Text("Muziekliefhebber sinds 2024")
                                        .font(PitchTypography.caption)
                                        .foregroundColor(.pitchTextTertiary)
                                }
                            }
                            .scaleEffect(isLoaded ? 1.0 : 0.9)
                            .opacity(isLoaded ? 1.0 : 0.0)
                            .animation(.pitchSpring.delay(0.2), value: isLoaded)
                        }
                        .padding(.top, PitchSpacing.xl)
                        
                        // Stats cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: PitchSpacing.md) {
                            StatCardView(
                                icon: "star.fill",
                                title: "Ratings",
                                value: "\(storageManager.getAllRatings().count)",
                                color: .pitchStarFilled
                            )
                            
                            StatCardView(
                                icon: "music.note.list",
                                title: "Albums",
                                value: "\(Set(storageManager.getAllRatings().map { $0.albumId }).count)",
                                color: .pitchAccent
                            )
                        }
                        .padding(.horizontal, PitchSpacing.md)
                        .scaleEffect(isLoaded ? 1.0 : 0.9)
                        .opacity(isLoaded ? 1.0 : 0.0)
                        .animation(.pitchSpring.delay(0.3), value: isLoaded)
                        
                        // Profile options
                        VStack(spacing: PitchSpacing.md) {
                            ProfileOptionRow(
                                icon: "bell.fill",
                                title: "Notificaties",
                                subtitle: "Ontvang updates over nieuwe ratings"
                            )
                            
                            ProfileOptionRow(
                                icon: "heart.fill",
                                title: "Favorieten",
                                subtitle: "Jouw favoriete albums en artiesten"
                            )
                            
                            ProfileOptionRow(
                                icon: "square.and.arrow.up.fill",
                                title: "Delen",
                                subtitle: "Deel jouw muzieksmaak met vrienden"
                            )
                            
                            ProfileOptionRow(
                                icon: "gearshape.fill",
                                title: "Instellingen",
                                subtitle: "App voorkeuren en privacy"
                            )
                        }
                        .padding(.horizontal, PitchSpacing.md)
                        .scaleEffect(isLoaded ? 1.0 : 0.9)
                        .opacity(isLoaded ? 1.0 : 0.0)
                        .animation(.pitchSpring.delay(0.4), value: isLoaded)
                        
                        // App info
                        VStack(spacing: PitchSpacing.sm) {
                            Text("PitchPlease")
                                .font(PitchTypography.callout)
                                .foregroundColor(.pitchTextSecondary)
                                .fontWeight(.semibold)
                            
                            Text("Versie 1.0.0 • Made with ❤️")
                                .font(PitchTypography.caption)
                                .foregroundColor(.pitchTextTertiary)
                        }
                        .scaleEffect(isLoaded ? 1.0 : 0.9)
                        .opacity(isLoaded ? 1.0 : 0.0)
                        .animation(.pitchSpring.delay(0.5), value: isLoaded)
                        
                        Spacer(minLength: PitchSpacing.xxxl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.pitchSpring.delay(0.1)) {
                    isLoaded = true
                }
            }
        }
    }
}

// Preview voor SwiftUI development
#Preview {
    MainTabView()
} 
