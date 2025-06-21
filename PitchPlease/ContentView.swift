//
//  ContentView.swift
//  PitchPlease
//
//  Created by Naoufal Andichi on 21/06/2025.
//

// Content View - Tijdelijke view voor development/testing
// Deze view wordt niet meer gebruikt in de productie app maar kan handig zijn voor testing
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "music.note.house.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 60))
            
            Text("PitchPlease")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Album Beoordeling App")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
