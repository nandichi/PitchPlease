# PitchPlease - Album Beoordeling App

Een iOS-app gebouwd met SwiftUI waarmee gebruikers albums kunnen zoeken via de Spotify API, deze kunnen beoordelen met sterren en reviews, en hun beoordelingen kunnen delen.

## Functies

- 🔍 **Album Zoeken**: Zoek albums via de Spotify Web API
- ⭐ **Beoordeling Systeem**: Geef albums een rating van 1-5 sterren met optionele review
- 👥 **Sociale Functie**: Bekijk beoordelingen van andere gebruikers
- 🔐 **Gebruikersaccounts**: Lokale authenticatie en accountbeheer
- 💾 **Lokale Database**: Beoordelingen worden lokaal opgeslagen via UserDefaults
- 📱 **Delen**: Deel albums via AirDrop, sociale media of messaging
- 🎨 **Modern UI**: Clean en intuïtieve interface met SwiftUI

## Vereisten

- iOS 15.0+
- Xcode 15.0+
- Swift 5.8+
- Spotify Developer Account (gratis)

## Setup Instructies

### 1. Spotify API Setup

1. Ga naar [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Maak een nieuw app aan
3. Noteer je Client ID en Client Secret
4. Open `SpotifyManager.swift`
5. Vervang de placeholders:

```swift
private let clientId = "JOUW_SPOTIFY_CLIENT_ID"
private let clientSecret = "JOUW_SPOTIFY_CLIENT_SECRET"
```

### 2. Build en Run

1. Open het project in Xcode
2. Selecteer je target device of simulator
3. Klik op "Run" (Cmd+R)
4. De app gebruikt lokale opslag, dus geen extra configuratie nodig!

## Project Structuur

```
PitchPlease/
├── PitchPleaseApp.swift          # Main app entry point
├── ContentView.swift             # Template view (niet gebruikt in productie)
├── LocalStorageManager.swift     # Lokale authenticatie en data manager
├── SpotifyManager.swift          # Spotify API calls
├── AuthenticationView.swift      # Login/registratie views
├── MainTabView.swift            # Hoofdnavigatie met tabs
├── AlbumDetailView.swift        # Album detail en rating view
└── UIComponents.swift           # Herbruikbare UI componenten
```

## Data Schema

### LocalUser

```
{
  id: string
  email: string
  displayName: string
  createdAt: Date
}
```

### LocalAlbumRating

```
{
  id: string
  userId: string
  userDisplayName: string
  albumId: string
  albumName: string
  artistName: string
  albumImageUrl: string?
  rating: number (1-5)
  review: string? (optioneel)
  createdAt: Date
  updatedAt: Date
}
```

## Gebruik

### 1. Account Aanmaken

- Open de app
- Klik "Nog geen account? Registreer hier"
- Vul je gegevens in en registreer

### 2. Albums Zoeken

- Ga naar het "Zoeken" tabblad
- Typ een album- of artiestnaam
- Klik op een album om details te bekijken

### 3. Album Beoordelen

- Open een album
- Klik "Album Beoordelen"
- Selecteer sterren (1-5)
- Schrijf optioneel een review
- Klik "Opslaan"

### 4. Beoordelingen Bekijken

- **Feed tab**: Zie alle publieke beoordelingen
- **Mijn Ratings tab**: Zie je eigen beoordelingen
- **Album detail**: Zie alle beoordelingen voor een specifiek album

### 5. Delen

- Open een album
- Klik op het deel-icoon (bovenkant rechts)
- Kies hoe je wilt delen (AirDrop, Messages, etc.)

## Technische Details

### Architecture

- **MVVM Pattern**: Models, Views, ViewModels
- **Singleton Managers**: LocalStorageManager, SpotifyManager
- **Async/Await**: Moderne Swift concurrency voor Spotify API
- **SwiftUI**: Declarative UI framework

### API's & Storage

- **Spotify Web API**: Voor album zoeken (Client Credentials flow)
- **UserDefaults**: Voor lokale data opslag
- **JSON Encoding/Decoding**: Voor data serialisatie

### Beveiliging

- Client Credentials flow voor Spotify (geen gebruiker login required)
- Lokale data opslag (privaat per app)
- Input validatie voor ratings en reviews

## Development Tips

### Testing

1. Gebruik de iOS Simulator voor quick testing
2. Test op verschillende apparaten voor UI responsiveness
3. Test offline scenario's (geen internet)

### Debugging

- Check Console voor Firebase/Spotlight errors
- Gebruik Xcode debugger voor breakpoints
- Monitor Firebase Console voor database operations

### Performance

- Album afbeeldingen worden asynchroon geladen
- Database queries zijn geoptimaliseerd met indexen
- Ratings worden gecached voor betere UX

## Potentiële Uitbreidingen

- [ ] Push notifications voor nieuwe ratings
- [ ] Vriendensysteem
- [ ] Album aanbevelingen
- [ ] Dark mode support
- [ ] iPad ondersteuning
- [ ] Offline modus
- [ ] Export functie voor ratings
- [ ] Music player integratie

## Troubleshooting

### Spotify API Errors

- Verificeer Client ID en Client Secret
- Check of Spotify app status "Development" of "Extended Quota Mode" is
- Rate limiting: Spotify heeft API limits

### Build Errors

- Clean build folder (Cmd+Shift+K)
- Restart Xcode
- Check package dependencies

## Licentie

Dit project is voor educatieve doeleinden. Spotify API gebruiks voorwaarden zijn van toepassing.

## Auteur

Gebouwd als tutorial project voor iOS development met SwiftUI, Firebase en Spotify API integratie.
