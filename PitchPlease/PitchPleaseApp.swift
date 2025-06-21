//
//  PitchPleaseApp.swift
//  PitchPlease
//
//  Created by Naoufal Andichi on 21/06/2025.
//

import SwiftUI
import FirebaseCore

@main
struct PitchPleaseApp: App {
    
    // Firebase manager voor authenticatie status
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    // App lifecycle configuratie
    init() {
        // Firebase configureren bij app start
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            // Root view gebaseerd op authenticatie status
            if firebaseManager.isUserLoggedIn {
                // Gebruiker is ingelogd - toon main app
                MainTabView()
                    .environmentObject(firebaseManager)
            } else {
                // Gebruiker is niet ingelogd - toon login/signup
                AuthenticationView()
                    .environmentObject(firebaseManager)
            }
        }
    }
}
