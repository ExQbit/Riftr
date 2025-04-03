# PLANNING.md für "Zeitklingen" Kartenspiel

## 📋 Projektübersicht

"Zeitklingen" ist ein innovatives, deterministisches Kartenspiel, das in Unity entwickelt wird. Das Spiel zeichnet sich durch seinen Fokus auf Zeitmanipulation und strategische Entscheidungen aus. Es soll sowohl für PC als auch möglicherweise für mobile Plattformen entwickelt werden.

## 🎮 Spielkonzept

### Kernmechaniken
- **Zeitmanipulation**: Spieler können Karten spielen, die den Spielverlauf beeinflussen (z.B. Züge zurücknehmen, voraussehen)
- **Deterministische Gameplay-Elemente**: Alle Spielzüge haben vorhersehbare Auswirkungen, was tiefgreifende Strategieentwicklung ermöglicht
- **Deckbuilding**: Spieler können ihre eigenen Kartendecks zusammenstellen und optimieren

### Spielziel
- Verringere die Lebenspunkte des Gegners auf 0 durch taktischen Einsatz von Karten
- Alternative Siegbedingungen durch spezielle Karten möglich

### Inspiration von bestehenden deterministischen Kartenspielen
- **Slay the Spire**: Für den Run-basierten Progressionsansatz
- **Hearthstone**: Für klare Karteninteraktionen und UI-Design
- **Dominion**: Für das Deckbuilding-Element
- **Inscryption**: Für innovative Mechaniken und Atmosphäre

## 🛠️ Technische Architektur

### Technologie-Stack
- **Game Engine**: Unity 2022.3 LTS
- **Programmiersprache**: C#
- **Versionskontrolle**: Git (GitHub/GitLab)
- **Assets**: Kombination aus eigenen Assets und Asset Store-Inhalten für den Prototyp

### Architektur-Entscheidungen
- **Model-View-Controller (MVC)** Pattern für die Trennung von Spiellogik und Darstellung
- **Scriptable Objects** für Kartendaten und Konfigurationen
- **Event-basiertes System** für Karteninteraktionen und Spielzustände
- **Zustandsmaschinen** für Spielablauf und KI-Verhalten
- **Serialisierung** für Speichern/Laden des Spielstands

### Modularisierung
- **Core**: Grundlegende Spielmechaniken und -logik
- **Cards**: Kartendefinitionen, -effekte und -interaktionen
- **UI**: Benutzeroberfläche und Visualisierungen
- **AI**: KI-Gegner und Entscheidungsfindung
- **TimeManipulation**: Spezielle Zeitmanipulationsmechaniken
- **Audio**: Soundeffekte und Musik

## 📱 Plattformen & Deployment

### Zielplattformen (nach Priorität)
1. PC (Windows, macOS, Linux)
2. Mobile (iOS, Android) - langfristiges Ziel
3. WebGL für browserbasiertes Spielen - potenziell für Demos

### Entwicklungsphasen
1. **Prototyp**: Grundlegende Spielmechaniken und Karteninteraktionen
2. **Alpha**: Erweitertes Kartenset, Grundlegende KI, Einfaches UI
3. **Beta**: Vollständiges Spielerlebnis, Balancing, Polishing
4. **Release**: Optimierung, Bugfixing, Plattform-spezifische Anpassungen

## 🔍 Technische Herausforderungen

### Identifizierte Herausforderungen
- Implementierung der Zeitmanipulationsmechaniken (Zugrücknahme, Vorausschau)
- Entwicklung einer ausgewogenen KI für Solo-Spiel
- Kartenbalancing für faires und spannendes Spielerlebnis
- Effiziente Serialisierung von Spielzuständen für Zeitmanipulation
- Entwicklung eines intuitiven und ansprechenden UI für Kartenspiel

### Lösungsansätze
- **Command Pattern** für reversible Aktionen (Zeitmanipulation)
- **Zustandsreplikation** für Speicherung von Spielzuständen
- **Parameterisierte KI-Schwierigkeitsgrade** für verschiedene Spielerfahrungen
- **Datengetriebenes Balancing** mit Telemetrie und Analysetools
- **Rapid Prototyping** mit Papierprototypen vor der digitalen Implementierung

## 📊 Projektumfang und Meilensteine

### Minimales spielbares Produkt (MVP)
- 2 Spieler (lokal oder gegen KI)
- 30 einzigartige Karten
- Grundlegende Zeitmanipulationsmechaniken
- Einfaches Deckbuilding
- Funktionales, wenn auch einfaches UI

### Langfristige Funktionen
- Online-Multiplayer
- Kampagnenmodus mit Story-Elementen
- Erweiterte Zeitmanipulation (z.B. parallele Zeitlinien)
- Fortgeschrittene KI mit verschiedenen Spielstilen
- Karteneditor für benutzerdefinierte Karten

### Meilensteine und Timeline
1. **Konzeptphase**: Spielregeln, Kartenentwürfe, Papierprototyp (2 Wochen)
2. **Technischer Prototyp**: Grundlegende Spielmechaniken in Unity (4 Wochen)
3. **Alpha-Version**: Spielbare Version mit grundlegenden Funktionen (8 Wochen)
4. **Beta-Version**: Vollständiges Spiel mit Balancing (12 Wochen)
5. **Release-Kandidat**: Optimierung und Bugfixing (16 Wochen)

## 🔄 Iterativer Entwicklungsprozess

### Feedback-Schleifen
- Regelmäßige Playtests mit externen Testern
- A/B-Tests für UI und Spielmechaniken
- Community-Feedback in späteren Phasen

### Anpassungsstrategie
- Flexibler Scope basierend auf Feedback und Entwicklungsfortschritt
- Priorisierung von Kernmechaniken vor visuellen Verbesserungen
- Agile Entwicklungspraktiken mit 2-Wochen-Sprints

## 📚 Ressourcen und Assets

### Benötigte Ressourcen
- Kartenillustrationen und Designs
- UI-Elemente und Animationen
- Soundeffekte und Musik
- 3D-Modelle für Spielbrett und Umgebung (falls relevant)

### Asset-Strategie
- Zunächst Platzhalter-Assets aus dem Asset Store
- Schrittweise Erstellung eigener Assets für finale Version
- Fokus auf konsistenten visuellen Stil

## 🧪 Teststrategien

### Teststrategie
- Unit-Tests für Kernmechaniken und Karteninteraktionen
- Integration Tests für Subsysteme
- Playtests für Spielerfahrung und Balancing
- Leistungstests für verschiedene Plattformen

### Qualitätssicherung
- Automatisierte Tests für Regression
- Code-Reviews vor Merges in den Hauptzweig
- Dedizierte QA-Phasen vor wichtigen Releases

---

*Dieses Planungsdokument wird regelmäßig aktualisiert, um Projektfortschritte und Änderungen widerzuspiegeln.*
