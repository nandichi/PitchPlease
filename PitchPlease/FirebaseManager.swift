// Firebase Manager voor authenticatie en database operaties
// Deze class zorgt voor de verbinding met Firebase services
import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// Singleton klasse voor Firebase operaties
class FirebaseManager: ObservableObject {
    
    // Shared instance voor het singleton patroon
    static let shared = FirebaseManager()
    
    // Huidige gebruiker status
    @Published var currentUser: User?
    @Published var isUserLoggedIn = false
    
    // Firebase services
    let auth: Auth
    let firestore: Firestore
    
    // Private initializer voor singleton patroon
    private init() {
        // Firebase configureren (moet alleen de eerste keer)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Firebase services initialiseren
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        
        // Luisteren naar authentication status changes
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isUserLoggedIn = user != nil
            }
        }
    }
    
    // Functie om gebruiker in te loggen met email en wachtwoord
    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }
    
    // Functie om nieuwe gebruiker aan te maken
    func signUp(email: String, password: String, displayName: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        
        // Gebruikersprofiel updaten met display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        // Gebruiker document maken in Firestore
        try await createUserDocument(for: result.user, displayName: displayName)
    }
    
    // Functie om uit te loggen
    func signOut() throws {
        try auth.signOut()
    }
    
    // Private functie om gebruiker document te maken in Firestore
    private func createUserDocument(for user: User, displayName: String) async throws {
        let userData = [
            "email": user.email ?? "",
            "displayName": displayName,
            "userId": user.uid,
            "createdAt": Timestamp()
        ] as [String : Any]
        
        try await firestore.collection("users").document(user.uid).setData(userData)
    }
} 