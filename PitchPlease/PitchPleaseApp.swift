//
//  PitchPleaseApp.swift
//  PitchPlease
//
//  Created by Naoufal Andichi on 21/06/2025.
//

import SwiftUI

@main
struct PitchPleaseApp: App {
    
    // Lokale storage manager voor authenticatie status
    @StateObject private var storageManager = LocalStorageManager.shared
    
    var body: some Scene {
        WindowGroup {
            // Tijdelijk login overslaan voor development
            MainTabView()
                .environmentObject(storageManager)
        }
    }
}
