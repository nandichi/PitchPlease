// Authentication Views voor login en registratie
// Deze views zorgen voor gebruiker authenticatie via Firebase
import SwiftUI

// Main authentication view die switcht tussen login en signup
struct AuthenticationView: View {
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack {
                // App logo en titel
                VStack(spacing: 20) {
                    Image(systemName: "music.note.house.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("PitchPlease")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Beoordeel en deel je favoriete albums")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Authentication form
                if isShowingSignUp {
                    SignUpView(isShowingSignUp: $isShowingSignUp)
                } else {
                    LoginView(isShowingSignUp: $isShowingSignUp)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

// Login view voor bestaande gebruikers
struct LoginView: View {
    @Binding var isShowingSignUp: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Login form
            VStack(spacing: 16) {
                TextField("Email adres", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Wachtwoord", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Login button
            Button(action: performLogin) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Inloggen")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            
            // Switch to sign up
            Button(action: {
                isShowingSignUp = true
            }) {
                Text("Nog geen account? Registreer hier")
                    .foregroundColor(.blue)
            }
        }
    }
    
    // Functie om login uit te voeren
    private func performLogin() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await FirebaseManager.shared.signIn(email: email, password: password)
                
                DispatchQueue.main.async {
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Login mislukt: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Sign up view voor nieuwe gebruikers
struct SignUpView: View {
    @Binding var isShowingSignUp: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Sign up form
            VStack(spacing: 16) {
                TextField("Gebruikersnaam", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email adres", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Wachtwoord", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Bevestig wachtwoord", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            // Sign up button
            Button(action: performSignUp) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Registreren")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!isFormValid || isLoading)
            
            // Switch to login
            Button(action: {
                isShowingSignUp = false
            }) {
                Text("Al een account? Login hier")
                    .foregroundColor(.blue)
            }
        }
    }
    
    // Computed property om form validatie te checken
    private var isFormValid: Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               !displayName.isEmpty &&
               password == confirmPassword &&
               password.count >= 6
    }
    
    // Functie om registratie uit te voeren
    private func performSignUp() {
        // Extra validatie
        guard password == confirmPassword else {
            errorMessage = "Wachtwoorden komen niet overeen"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Wachtwoord moet minimaal 6 karakters bevatten"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await FirebaseManager.shared.signUp(
                    email: email,
                    password: password,
                    displayName: displayName
                )
                
                DispatchQueue.main.async {
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Registratie mislukt: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Preview voor SwiftUI development
#Preview {
    AuthenticationView()
} 