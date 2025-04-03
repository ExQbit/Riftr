# Zeitklingen

![Zeitklingen Logo](Assets/Resources/Images/logo_placeholder.png)

## 📖 Übersicht

"Zeitklingen" ist ein innovatives, deterministisches Kartenspiel, bei dem Spieler mit Zeitmanipulationsmechaniken strategische Duelle austragen. Entwickelt mit Unity, kombiniert das Spiel klassische Kartenspiel-Elemente mit einzigartigen Zeitmanipulations-Fähigkeiten wie Zurückspulen von Zügen und das Voraussehen zukünftiger Aktionen.

## ✨ Hauptmerkmale

- **Zeitmanipulation**: Spiele Karten, die Züge zurücknehmen, zukünftige Aktionen voraussehen oder den Spielfluss verändern
- **Deterministische Strategie**: Alle Spielzüge haben vorhersehbare Ergebnisse, was tiefgreifende strategische Planung ermöglicht
- **Deckbuilding**: Erstelle und optimiere dein eigenes Kartendeck aus verschiedenen Kartentypen
- **Einzelspieler & KI**: Tritt gegen herausfordernde KI-Gegner an, die unterschiedliche Spielstile repräsentieren

## 🛠️ Technische Details

- **Engine**: Unity 2022.3 LTS
- **Sprache**: C#
- **Plattformen**: PC (Windows, macOS, Linux), später möglicherweise Mobile (iOS, Android)

## 🔧 Installation & Setup

### Voraussetzungen

- Unity 2022.3 LTS oder neuer
- Git (für Versionskontrolle)
- Allgemeine Kenntnisse in C# und Unity

### Entwicklungsumgebung einrichten

1. Klone das Repository:
   ```
   git clone https://github.com/deine-organisation/zeitklingen.git
   ```

2. Öffne das Projekt in Unity:
   - Starte Unity Hub
   - Klicke auf "Projekt hinzufügen"
   - Navigiere zum geklonten Repository-Ordner
   - Wähle den Ordner aus und öffne das Projekt

3. Installiere benötigte Packages:
   - Öffne den Package Manager (Fenster > Package Manager)
   - Installiere benötigte Abhängigkeiten aus der Package-Liste

## 🎮 Spielen & Testen

- Drücke den Play-Button in Unity, um das Spiel im Editor zu testen
- Nutze die Testszene unter `Assets/Scenes/TestingScene.unity` für schnelles Debugging
- Für Builds: Nutze den Build-Dialog (Datei > Build Settings)

## 📁 Projektstruktur

```
Assets/
├── Animations/       # Animations-Assets und Controller
├── Audio/            # Soundeffekte und Musik
├── Prefabs/          # Wiederverwendbare Spielobjekte
├── Resources/        # Zur Laufzeit geladene Ressourcen
├── Scenes/           # Unity-Szenen
├── ScriptableObjects/# Karten- und Konfigurationsdaten
│   └── Cards/        # Kartendefinitionen
├── Scripts/          # C#-Skripte
│   ├── Core/         # Kernmechaniken
│   ├── Cards/        # Kartenlogik und -interaktionen
│   ├── UI/           # Benutzeroberfläche
│   ├── AI/           # KI-Gegner
│   └── TimeManipulation/ # Zeitmanipulationsmechaniken
└── Tests/            # Unit- und Integrationstests
```

## 🧪 Tests

Teste neue Funktionen mit dem Unity Test Framework:

1. Öffne das Test Runner-Fenster (Fenster > Allgemein > Test Runner)
2. Wähle zwischen Edit Mode Tests (für Unit-Tests) und Play Mode Tests (für Integrationstests)
3. Führe Tests aus durch Klick auf "Run All" oder einzelne Tests

## 📝 Mitwirken

1. Prüfe die `TASK.md` für aktuelle Aufgaben und offene Punkte
2. Erstelle einen Feature-Branch (`git checkout -b feature/meine-neue-funktion`)
3. Committe deine Änderungen (`git commit -m 'Neue Funktion: XYZ hinzugefügt'`)
4. Pushe zum Branch (`git push origin feature/meine-neue-funktion`)
5. Erstelle einen Pull Request

## 📚 Dokumentation

- `README.md` - Diese Datei, Projektübersicht und Einrichtung
- `PLANNING.md` - Detailierte Projektplanung, Architektur und Designentscheidungen
- `TASK.md` - Aktuelle Aufgaben und Fortschrittsverfolgung
- Code-Dokumentation in XML-Format für IntelliSense-Unterstützung

## 📄 Lizenz

[Deine Lizenzinformation hier]

---

*"Zeitklingen" - Wo die Zeit selbst zur Waffe wird.*
