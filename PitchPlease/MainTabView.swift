// Main Tab View die de verschillende onderdelen van de app bevat
// Deze view toont de navigatie tabs en zorgt voor de overall app structuur
import SwiftUI

// Main tab view met verschillende schermen
struct MainTabView: View {
    @ObservedObject var firebaseManager = FirebaseManager.shared
    
    var body: some View {
        TabView {
            // Search tab - zoeken naar albums
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Zoeken")
                }
            
            // Feed tab - bekijk alle ratings
            FeedView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Feed")
                }
            
            // My Ratings tab - eigen ratings
            MyRatingsView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Mijn Ratings")
                }
            
            // Profile tab - gebruikersprofiel
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profiel")
                }
        }
        .accentColor(.blue)
    }
}

// Search view voor het zoeken van albums
struct SearchView: View {
    @StateObject private var spotifyManager = SpotifyManager.shared
    @State private var searchText = ""
    @State private var searchResults: [SpotifyAlbum] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Zoek albums...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                    
                    Button("Zoeken", action: performSearch)
                        .disabled(searchText.isEmpty || isLoading)
                }
                .padding(.horizontal)
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Loading indicator
                if isLoading {
                    ProgressView("Zoeken...")
                        .padding()
                }
                
                // Search results
                List(searchResults) { album in
                    NavigationLink(destination: AlbumDetailView(album: album).withRatingForm()) {
                        AlbumRowView(album: album)
                    }
                }
                .listStyle(PlainListStyle())
                
                Spacer()
            }
            .navigationTitle("Zoek Albums")
        }
    }
    
    // Functie om zoekactie uit te voeren
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let results = try await spotifyManager.searchAlbums(query: searchText)
                
                DispatchQueue.main.async {
                    searchResults = results
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Zoeken mislukt: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Feed view voor het bekijken van alle ratings
struct FeedView: View {
    @StateObject private var ratingManager = AlbumRatingManager.shared
    @State private var ratings: [AlbumRating] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Laden...")
                        .padding()
                } else if ratings.isEmpty {
                    Text("Geen ratings gevonden")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(ratings) { rating in
                        RatingRowView(rating: rating)
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .navigationTitle("Feed")
            .onAppear {
                loadRatings()
            }
            .refreshable {
                loadRatings()
            }
        }
    }
    
    // Functie om ratings te laden
    private func loadRatings() {
        isLoading = true
        
        Task {
            do {
                let publicRatings = try await ratingManager.getAllPublicRatings()
                
                DispatchQueue.main.async {
                    ratings = publicRatings
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    print("Error loading ratings: \(error)")
                }
            }
        }
    }
}

// My Ratings view voor eigen ratings
struct MyRatingsView: View {
    @StateObject private var ratingManager = AlbumRatingManager.shared
    @ObservedObject var firebaseManager = FirebaseManager.shared
    @State private var myRatings: [AlbumRating] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Laden...")
                        .padding()
                } else if myRatings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Nog geen ratings")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Zoek naar albums en geef je eerste rating!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(myRatings) { rating in
                        RatingRowView(rating: rating, showUserName: false)
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .navigationTitle("Mijn Ratings")
            .onAppear {
                loadMyRatings()
            }
            .refreshable {
                loadMyRatings()
            }
        }
    }
    
    // Functie om eigen ratings te laden
    private func loadMyRatings() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        isLoading = true
        
        Task {
            do {
                let userRatings = try await ratingManager.getRatingsForUser(userId: userId)
                
                DispatchQueue.main.async {
                    myRatings = userRatings
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    print("Error loading my ratings: \(error)")
                }
            }
        }
    }
}

// Profile view voor gebruikersprofiel
struct ProfileView: View {
    @ObservedObject var firebaseManager = FirebaseManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User info
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(firebaseManager.currentUser?.displayName ?? "Gebruiker")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(firebaseManager.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Logout button
                Button(action: performLogout) {
                    Text("Uitloggen")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Profiel")
        }
    }
    
    // Functie om uit te loggen
    private func performLogout() {
        do {
            try firebaseManager.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

// Preview voor SwiftUI development
#Preview {
    MainTabView()
} 