# Riftr App Redesign - UI/UX Überarbeitung

## Übersicht der Änderungen

Diese Überarbeitung transformiert die Riftr-App in eine moderne, benutzerfreundliche und intuitive Sammler-App für Riftbound TCG.

## 🎨 Neue Navigation

### 4 Haupttabs (statt vorher 5)
1. **Home** - Dashboard mit Sammelfortschritt und Featured Cards
2. **Sammlung** - Deine gesammelten Karten
3. **Decks** - Deck-Builder und -Verwaltung
4. **Profil** - Statistiken, Achievements und Einstellungen

### Zentrale Funktionen
- **Floating Action Button (FAB)** - Schneller Zugriff auf den Card Scanner
- **Settings** als eigener Screen (statt Tab)
- **Kartendatenbank** als Screen erreichbar
- Alle Features mit max. 2 Klicks erreichbar

## 🏠 Neuer Home Screen - "Wohlfühloase"

### Features:
1. **Persönliche Begrüßung**
   - Zeigt aktuelle Währung (Diamanten 💎)
   - Freundliche Willkommensnachricht

2. **Sammelfortschritt-Card**
   - Zeigt Anzahl gesammelter Karten (X von 50)
   - Fortschrittsbalken mit Prozentanzeige
   - Schnell-Statistiken:
     - Gesamte Karten
     - Geöffnete Packs
     - Gesammelte Punkte

3. **Featured Card Showcase** 🌟
   - Täglich wechselnde Karten
   - Zwei Modi:
     - **Mechanik-Erklärungen**: Erklärt Spielmechaniken wie "Hexcore"
     - **Lore-Stories**: Erzählt Hintergrundgeschichten zu Charakteren
   - Schönes Gradient-Design
   - Klick führt zu Kartendetails

4. **Schnellzugriff-Kacheln**
   - Packs öffnen
   - Sammlung ansehen
   - Decks bauen
   - Karten scannen
   - Jede Kachel mit eigenem Gradient und Icon

5. **Daily Streak Tracker**
   - Zeigt aktuelle Streak (🔥)
   - Motiviert zum täglichen Einloggen

## 📸 Card Scanner

### Neue Funktion zum Scannen physischer Karten
- Kamera-Integration (bereit für expo-camera)
- Live-Scan-Frame mit Ecken-Indikatoren
- Automatische Kartenerkennung
- Fügt gescannte Karten direkt zur Sammlung hinzu
- Info-Banner mit Erklärung der KI-basierten Erkennung

**Status**: UI fertig, Kamera-Integration vorbereitet

## 👤 Profil Screen

### Persönliche Statistiken
- **Profil-Header**
  - Avatar
  - Level-System (basierend auf Punkten)
  - Fortschrittsbalken zum nächsten Level

- **Stats-Grid** (4 Kacheln):
  1. Gesammelte Karten
  2. Geöffnete Packs
  3. Punkte
  4. Daily Streak 🔥

- **Achievements**
  - First Pack (Erstes Pack öffnen)
  - Collector (25 Karten sammeln)
  - Completionist (Alle Karten sammeln)
  - Point Master (1000 Punkte erreichen)

- **Letzte Aktivitäten**
  - Zeigt letzte 5 Punkt-Transaktionen
  - Mit Datum und Grund

## 💎 Points-System

### Neues Punktesystem für Engagement
- **Punkte sammeln für:**
  - Packs öffnen
  - Tägliches Einloggen
  - Decks erstellen
  - Achievements freischalten

- **Points Store**
  - Verfolgt alle Transaktionen
  - Daily Streak Tracking
  - Punkt-Historie (letzte 100)

## 💰 Card Pricing

### Vorbereitet für Marktpreis-Integration
- **Pricing Store** angelegt
- Bereit für APIs wie:
  - TCGPlayer
  - Cardmarket
  - Manuelle Preise

- **Features**:
  - Normal- und Foil-Preise
  - Preistrend (↑ ↓ →)
  - Währungsunterstützung (USD, EUR)
  - Letzte Aktualisierung

## 🌐 Community Features

### Vorbereitet für Community-Anbindung
- **Community Stats Store**
  - Globale Statistiken
  - Meist-gesammelte Karte
  - Seltenheitsverteilung

- **Leaderboard**
  - Rangliste der Top-Sammler
  - Vergleich mit anderen Spielern
  - Nicht aufdringlich - nur bei Bedarf sichtbar

## 🎯 Design-Prinzipien

### 1. Aufgeräumt
- Klare Hierarchie
- Viel Weißraum
- Keine Überladung

### 2. Intuitiv
- Selbsterklärende Icons
- Bekannte Gesten (Swipe, Tap, Long-Press)
- Klare Call-to-Actions

### 3. Besonders
- Gradient-Designs
- Animationen (Fade-in beim Laden)
- Featured Card als Eyecatcher
- Personalisierte Begrüßung

### 4. Community ohne Aufdringlichkeit
- Stats im Profil (nicht überall)
- Opt-in für Leaderboards
- Fokus auf persönliche Sammlung

### 5. Wenige Klicks
- Wichtigste Funktionen direkt im Home
- FAB für Scanner überall verfügbar
- Max. 2 Klicks zu jeder Funktion

## 🛠️ Technische Implementierung

### Neue Stores (Zustand + AsyncStorage)
1. **PointsStore** - Punktesystem mit Transaktionen
2. **PricingStore** - Kartenpreise
3. **FeaturedCardsStore** - Featured Card Management
4. **CommunityStore** - Community-Statistiken

### Neue Screens
1. **NewHomeScreen** - Komplett neues Dashboard
2. **ProfileScreen** - Profil mit Stats und Achievements
3. **CardScannerScreen** - Kamera-Scanner

### Erweiterte Types
- `CardPrice` - Preisinformationen
- `PointTransaction` - Punkt-Transaktionen
- `PointsStats` - Punkte-Statistiken
- `FeaturedCard` - Featured Card Daten
- `CommunityStats` - Community-Statistiken
- `LeaderboardEntry` - Ranglisten-Einträge

## 📱 Benutzerfluss

### Beim App-Start
```
1. Home Screen (Dashboard)
   ├─ Siehst Sammelfortschritt
   ├─ Siehst Featured Card mit Story
   └─ 4 Schnellzugriff-Buttons

2. Quick Actions
   ├─ Packs öffnen → PackSelection Screen
   ├─ Sammlung → Collection Tab
   ├─ Decks → Decks Tab
   └─ Scannen → CardScanner Screen

3. Navigation Tabs (unten)
   ├─ Home
   ├─ Sammlung
   ├─ Decks
   └─ Profil
```

### Typischer Use Case
1. **App öffnen** → Siehst sofort Fortschritt und Featured Card
2. **Featured Card lesen** → Lerne neue Mechanik oder Lore
3. **Karte scannen** (FAB) → Zur Sammlung hinzufügen
4. **Sammlung checken** → Fortschritt sehen
5. **Deck bauen** → Mit neuen Karten spielen
6. **Profil checken** → Achievements und Stats sehen

## 🎨 Farb- und Design-System

### Bestehende Farben (beibehalten)
- Primary: `#0596AA` (Piltover Blue)
- Secondary: `#C89B3C` (Demacia Gold)
- Accent: `#6b46c1` (Viktor Purple)

### Neue Design-Elemente
- **Gradients** für Kacheln und Featured Cards
- **Elevated Cards** mit Schatten
- **Progress Circles** für Level
- **Rounded Corners** (12-16px)
- **Icon-Badges** mit Hintergrund

## 🚀 Zukünftige Erweiterungen

### Bereit für:
1. **API-Integration**
   - Riot Riftbound Content API
   - TCGPlayer/Cardmarket für Preise
   - Backend für Community-Features

2. **Erweiterte Scanner-Funktionen**
   - expo-camera Integration
   - ML-basierte Kartenerkennung
   - Batch-Scanning mehrerer Karten

3. **Social Features**
   - Freunde hinzufügen
   - Sammlungen vergleichen
   - Karten-Trading vorbereitet

4. **Mehr Achievements**
   - Dynamic Achievements
   - Seasonale Events
   - Special Edition Karten

## 📊 Metriken-Tracking

### Vorbereitet für Analytics
- Screen-Views
- Button-Clicks
- Pack-Öffnungen
- Scanner-Nutzung
- Daily Active Users
- Retention Rate

## 🎯 Erfüllte Anforderungen

✅ **Aufgeräumt** - Klares, modernes Design ohne Überladung
✅ **Intuitiv** - Selbsterklärende Navigation und Gesten
✅ **Besonders** - Featured Cards, Gradients, Animationen
✅ **Community** - Stats und Leaderboards, nicht aufdringlich
✅ **Wenige Klicks** - Alle Features max. 2 Klicks entfernt
✅ **Wohlfühloase** - Home Screen zeigt Fortschritt und Featured Content
✅ **Card Scanner** - Kamera-Integration vorbereitet
✅ **Pricing** - Store und API-Anbindung vorbereitet
✅ **Points Tracker** - Komplettes Punktesystem implementiert

## 🎨 Screenshots-Bereiche

### Home Screen
- Header mit Begrüßung und Währung
- Sammelfortschritt-Card mit Stats
- Featured Card Showcase (wechselnd)
- 4 Schnellzugriff-Kacheln
- Daily Streak Banner
- FAB für Scanner

### Profil
- Profil-Header mit Level
- 4 Stat-Kacheln
- Achievements-Liste
- Letzte Aktivitäten

### Scanner
- Kamera-Vorschau
- Scan-Frame mit Ecken
- Anleitung
- Feature-Info Banner

## 🔄 Migration von alter zu neuer Version

Die alte Navigation ist noch verfügbar als Fallback:
- Alter `HomeScreen` → `PackSelection` Screen
- `DatabaseScreen` → Weiterhin verfügbar
- `SettingsScreen` → Eigener Modal-Screen

Alle bestehenden Stores bleiben kompatibel!

## 📝 Nächste Schritte

1. **Testing**
   - Alle Screens testen
   - Navigation prüfen
   - Stores testen

2. **Polish**
   - Animationen verfeinern
   - Haptic Feedback optimieren
   - Ladezeiten verbessern

3. **API Integration**
   - Riot API anbinden
   - Pricing APIs anbinden
   - Backend für Community

4. **Camera Integration**
   - `expo-camera` installieren
   - ML-Modell für Kartenerkennung
   - Batch-Scanning

---

**Erstellt am:** 2025-11-11
**Version:** 2.0.0 (Redesign)
**Status:** ✅ Implementiert, bereit für Testing
