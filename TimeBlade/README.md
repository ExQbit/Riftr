# Zeitklingen

![Zeitklingen Logo](Assets/Resources/Images/logo_placeholder.png)

## 📖 Übersicht

"Zeitklingen" ist ein innovatives, deterministisches Kartenspiel, bei dem Spieler mit Zeitmanipulationsmechaniken strategische Duelle austragen. Entwickelt mit Unity, kombiniert das Spiel klassische Kartenspiel-Elemente mit einzigartigen Zeitmanipulations-Fähigkeiten wie Zurückspulen von Zügen und das Voraussehen zukünftiger Aktionen.

## ✨ Hauptmerkmale

- **Zeitmanipulation**: Spiele Karten, die Züge zurücknehmen, zukünftige Aktionen voraussehen oder den Spielfluss verändern
- **Timeline-basiertes Kampfsystem**: Innovative Visualisierung von Gegneraktionen auf einer Zeitachse für intuitive strategische Entscheidungen
- **Deterministische Strategie**: Alle Spielzüge haben vorhersehbare Ergebnisse, was tiefgreifende strategische Planung ermöglicht
- **Deckbuilding**: Erstelle und optimiere dein eigenes Kartendeck aus verschiedenen Kartentypen
- **Einzelspieler & KI**: Tritt gegen herausfordernde KI-Gegner an, die unterschiedliche Spielstile repräsentieren


## 🛠️ Technische Details

- **Engine**: Unity 2022.3 LTS
- **Sprache**: C#
- **Backend**: Supabase für Datenbank und Authentifizierung
- **Plattformen**: PC (Windows, macOS, Linux), später möglicherweise Mobile (iOS, Android)

## 🗃️ Dokumentationssystem

- **Struktur**:
  - Alle Dokumente im `docs/` Verzeichnis
  - Benennungsschema: `ZK-<THEMA>-<TYP>.md`
- **Tools**:
  - `zk-commands/check-docs.py`: Prüft Dokumentenkonsistenz
  - `zk-commands/check-memory-sync.py`: Synchronisiert mit `.windsurf.memory.json`

## 🛠️ Entwicklungswerkzeuge

- **Automatisierung**:
  - Git-Tools für Repository-Verwaltung
  - Memory-System für persistente Konfiguration
  - Dokumentationsautomatisierung
- **Skripte**:
  - Alle Hilfsskripte im `zk-commands/` Ordner
  - `update-docs.sh` - Aktualisiert automatisch README und API-Dokumentation
  - `update-readme-features.py` - Scannt Codebase und aktualisiert Features in README.md
  - `generate-api-docs.py` - Generiert API-Dokumentation aus Code-Kommentaren
  
## 🖥️ MCP-Server & Supabase-Integration

### MCP-Server Konfiguration

Alle MCP-Server (Model Context Protocol Server) sind in der `.windsurf.tools.json`-Datei konfiguriert. Diese Datei ist die zentrale Konfigurationsquelle für alle verfügbaren Server und deren Funktionen.

- **Konfigurationsdatei**: `.windsurf.tools.json`
- **Struktur**: Jeder Server hat einen eindeutigen Namen, Befehl, Argumente und eine ausführliche Beschreibung
- **Dokumentation**: Ausführliche Beschreibungen direkt in der JSON-Datei und in `docs/MCP-SERVER-DOKUMENTATION.md`
- **Umgebung**: Die Windsurf-Umgebung lädt diese Konfiguration automatisch und macht die Server für KI-Assistenten verfügbar
- **Authentifizierung**: Sensitive Daten wie API-Schlüssel werden aus der `.env`-Datei geladen

### Verfügbare MCP-Server

1. **Grundlegende Infrastruktur**:
   - `filesystem`: Lese- und Schreibzugriff auf das lokale Zeitklingen-Dateisystem
   - `brave-search`: Web- und lokale Suche über die Brave-API (API-Key in `.env`)
   - `git`: Git-Versionskontrolle für das Zeitklingen-Repository
   - `memory`: Langzeitgedächtnis für KI-Assistenten

2. **Datenbank und Kartenverwaltung**:
   - `supabase`: Verbindung zur Supabase-Datenbank für Kartendaten und Spielerinformationen (`scripts/mcp_supabase_server.py`)
   - `card-downloader`: Download aller Karten aus der Supabase-Datenbank (`scripts/download_cards_from_supabase.py`)

3. **Analyse und Balancing**:
   - `card-data`: Kartenbalancing und Datenanalyse (`scripts/mcp_balance_server.py`)
   - `card-analyzer`: Analyse von Kartenformaten und -effekten (`scripts/analyze_card_formats.py`)
   - `progression-simulator`: Simulation von Spielerfortschritt und Klassenbalance (`progression_simulator.py`)

4. **Tests und Qualitätssicherung**:
   - `test-runner`: Automatisierte Tests für Spielmechaniken und Karteneffekte (`tests/`)

### Wichtige Server im Detail

- **Supabase-Server**:
  - Pfad: Siehe Konfiguration in `.windsurf.tools.json`
  - Ermöglicht Zugriff auf Supabase-Datenbank für Kartenverwaltung und Spielerdaten
  - Unterstützt Kartenabfragen, Spielerfortschritt und Spielsitzungsprotokollierung
  
- **Progression Simulator**:
  - Pfad: Siehe Konfiguration in `.windsurf.tools.json`
  - Simuliert Spielerfortschritt durch die Welten
  - Testet die Balance der Karten, Klassen und Mechaniken
  - Integriert sich mit dem ZeitklingenSimulator
  - Erstellt Visualisierungen für Klassenvergleiche
  
- **CardDataImporter**:
  - Unity-Editor-Tool zum Import von Kartendaten aus den MCP-Servern
  - Konvertiert Kartendaten automatisch in Unity ScriptableObjects
  - Integriert sich mit dem `card-downloader`-Server

### Verwendung der MCP-Server

Für aktuelle Beispiele und Nutzungshinweise, siehe die Dokumentation in `docs/MCP-SERVER-DOKUMENTATION.md`. Hier ein grundlegendes Beispiel:

```python
# Beispiel: Zugriff auf den Supabase-Server
# Importpfad kann sich ändern, siehe aktuelle Konfiguration
from supabase_client import get_supabase_client

supabase = get_supabase_client()
response = supabase.table("cards").select("*").execute()
cards = response.data  # Enthält alle aktuellen Karten

# Beispiel: Verwendung des Progression Simulators
# Importpfad kann sich ändern, siehe aktuelle Konfiguration
from progression_simulator import ProgressionSimulator

simulator = ProgressionSimulator()
results = simulator.simulate_progression("chronomant")
# Vergleich aller Klassen
comparison = simulator.compare_classes()
```

### Starten der MCP-Server

Die MCP-Server werden automatisch durch die Windsurf-Umgebung gestartet, wenn sie in der `.windsurf.tools.json` konfiguriert sind. Alternativ können sie auch manuell gestartet werden:

```bash
# Manuelles Starten eines Servers (Pfad aus .windsurf.tools.json entnehmen)
python <pfad_zum_server_skript>

# Aktuelle Kartenanzahl ermitteln
python scripts/download_cards_from_supabase.py --count-only
```
  
- **Supabase-Verbindung**:
  - URL: Siehe Konfiguration in `.env` und `.windsurf.tools.json`
  - Authentifizierung über Service-Role-Key in `.env`-Datei
  - Detaillierte Anleitung in `docs/SUPABASE-ANLEITUNG.md`
  
- **Kartenverwaltungsskripte**:
  - `download_cards_from_supabase.py` - Lädt alle Karten aus der Datenbank
  - `update_supabase_cards.py` - Aktualisiert Karten in der Datenbank
  - `extract_cards_to_json.py` - Extrahiert Karten aus Markdown-Dateien

## 🃏 Spielklassen & Mechaniken

- **Chronomant**: Manipulation der Zeitachse
- **Zeitwächter**: Schutz zeitlicher Kontinuität
- **Schattenschreiter**: Nutzung von Zeitlücken


## ⏰ Timeline-basiertes Kampfsystem

### Kernkonzept

Das innovative Kampfsystem visualisiert Gegneraktionen auf einer horizontalen Zeitachse, wodurch Zeit als spielbare Ressource greifbar wird:

- **Zeitvisualisierung**: Eine rote "JETZT"-Linie zeigt den aktuellen Moment, Gegnermarkierungen erscheinen dort, wo ihre nächste Aktion stattfinden wird
- **Farbcodierte Aktionen**: Gegnermarkierungen sind farblich gekennzeichnet (Rot: Angriffe, Lila: Zeitdiebstahl, Grün: Buffs)
- **DoT-Integration**: Farbige Punkte unter Gegnermarkierungen zeigen die Intensität von Schaden-über-Zeit-Effekten
- **Intelligentes Targeting**: Automatische Zielauswahl mit Möglichkeit zur manuellen Überschreibung

### Spielervorteile

- Intuitive Priorisierung von Bedrohungen
- Klare Visualisierung der Auswirkungen von Zeitmanipulationskarten
- Verbesserte strategische Tiefe durch vorausschauende Planung
- Nahtlose Integration in das Zeitmanipulationskonzept

Bei Nutzertests bevorzugten 83% der Tester dieses Interface gegenüber traditionellen Kartenspiel-Oberflächen.

## 🔧 Installation & Setup

### Voraussetzungen

- Unity 2022.3 LTS oder neuer
- Git (für Versionskontrolle)
- Allgemeine Kenntnisse in C# und Unity
- Supabase-Konto (für Backend-Integration)

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

4. Richte die Supabase-Verbindung ein:
   - Kopiere `.env.template` zu `.env`
   - Trage deine Supabase-Anmeldedaten ein (URL: `https://slvxtnfmktzjgomwqmxk.supabase.co`)
   - Führe die SQL-Skripte aus, um die Datenbank einzurichten:
     ```
     supabase_tables_setup.sql     # Karten-Tabelle
     player_tables_setup.sql       # Spielerdaten-Tabellen
     player_api_functions.sql      # API-Funktionen für Spielerdaten
     ```

## 🚀 Supabase-Datenbank Integration

Zeitklingen verwendet Supabase für die Datenbankanbindung und Spielerdatenverwaltung.

### Features

- **Kartendatenbank**: Verwalte alle Karten mit ihren Eigenschaften und Evolutionspfaden
- **Spielerprofile**: Verfolge Spielerdaten wie Level, Erfahrung und Spielstatistiken
- **Kartensammlungen**: Verwalte die Kartenkollektion jedes Spielers
- **Material-Inventar**: Verfolge gesammelte Materialien für Kartenevolutionen
- **Deck-Management**: Speichere und verwalte Spieler-Decks
- **Achievement-System**: Tracke Spielerfortschritte und Achievements
- **Zeitenergie-Mechanik**: Verwalte die Zeitenergie der Spieler
- **Spielmetriken**: Zeichne Spielsitzungen für Balancing und Analyse auf

### Datenbankstruktur

Die Datenbank besteht aus folgenden Hauptkomponenten:

1. **Karten-Tabellen**: Speichern aller Karteninformationen
   - `cards`: Grundlegende Karteninformationen
   
2. **Spielerdaten-Tabellen**: Speichern aller spielerbezogenen Daten
   - `player_data`: Spielerprofile und Statistiken
   - `player_cards`: Kartensammlungen der Spieler
   - `player_materials`: Materialien im Besitz der Spieler
   - `player_decks`: Gespeicherte Kartendecks
   - `player_achievements`: Errungenschaften und Fortschritte

3. **Welt- und Sitzungsdaten**: Zusätzliche Spieldaten
   - `worlds`: Spielwelten und Level
   - `game_sessions`: Aufzeichnungen von Spielsitzungen

### Einrichten der Datenbank

1. Erstelle ein Supabase-Projekt in der Supabase-Konsole

2. Führe die SQL-Skripte in der folgenden Reihenfolge aus:
   ```
   supabase_tables_setup.sql          # Grundtabellen und Karten-Tabelle
   player_tables_setup.sql            # Spielerdaten-Tabellen
   player_api_functions.sql           # API-Funktionen für Spielerdaten
   player_data_populate.sql (optional) # Testdaten
   ```

3. Bei Problemen mit bestehenden Tabellen:
   ```
   update_all_tables.sql              # Fehlende Spalten zu Tabellen hinzufügen
   activate_full_player_data_function.sql # Vollständige get_player_data-Funktion aktivieren
   final_player_api_functions.sql     # Alle API-Funktionen aktualisieren
   ```

4. Implementiere die Datenbankfunktionen gemäß `implementation_guide.md`

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
│   ├── Database/     # Supabase-Integration
│   └── TimeManipulation/ # Zeitmanipulationsmechaniken
└── Tests/            # Unit- und Integrationstests

SQL/                 # SQL-Skripte für Supabase-Setup
├── supabase_tables_setup.sql   # Karten-Tabellen
├── player_tables_setup.sql     # Spielerdaten-Tabellen
├── player_api_functions.sql    # API-Funktionen
└── player_data_populate.sql    # Testdaten

data/                # Daten und JSON-Dateien
└── cards/              # Kartendaten im JSON-Format

scripts/             # Python-Skripte für Datenverarbeitung
├── download_cards_from_supabase.py  # Karten von Supabase herunterladen
├── extract_cards_to_json.py        # Karten aus Markdown extrahieren
└── update_supabase_cards.py       # Karten in Supabase aktualisieren

tests/               # Testskripte und Debugging-Tools
├── test_supabase.py              # Supabase-Verbindungstest
└── weitere Testskripte...

zk-commands/         # Hilfsskripte und MCP-Server
├── mcp_supabase_server.py      # MCP-Server für Supabase-Integration
├── supabase_client.py          # Supabase-Client-Hilfsfunktionen
└── weitere Hilfsskripte...
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

## 📚 Game Design Dokumentation (GDD)

Die vollständige Game Design Dokumentation findest du im `docs/Core/` Verzeichnis:

### Kern-Dokumente
- **`docs/Core/ZK-GAME-OVERVIEW.md`** - Umfassende Spielübersicht mit allen Mechaniken
- **`docs/Core/ZK-MECHANIKEN.md`** - Detaillierte Kern-Mechaniken und Zeitsystem
- **`docs/Core/Gameplay/ZK-KAMPFABLAUF.md`** - Technischer Kampfablauf im Detail
- **`docs/Core/ZK-CARDS.md`** - Kartensystem und Evolution
- **`docs/Core/ZK-PROGRESSION.md`** - Progression und XP-System

### Klassendokumente
- **`docs/Core/Klassen/ZK-CHRONOMANT.md`** - Chronomant-Klasse
- **`docs/Core/Klassen/ZK-ZEITWAECHTER.md`** - Zeitwächter-Klasse
- **`docs/Core/Klassen/ZK-SCHATTENSCHREITER.md`** - Schattenschreiter-Klasse

### Weitere wichtige Dokumente
- **`docs/Core/ZK-QUEST-SYSTEM.md`** - Quest-System und Kartenfreischaltung
- **`docs/Core/ZK-GEGNER-DATENBANK.md`** - Gegner und ihre Mechaniken
- **`docs/Core/ZK-MATERIALS.md`** - Materialsystem

## 📚 Dokumentation

- `README.md` - Diese Datei, Projektübersicht und Einrichtung
- `PLANNING.md` - [ARCHIVIERT] Siehe Archive/PLANNING-archived.md
- `TASK.md` - Aktuelle Aufgaben und Fortschrittsverfolgung
- `implementation_guide.md` - Anleitung zur Integration der Supabase-Funktionen
- `docs/zeitklingen-combat-system-alternative.md` - Detaillierte Beschreibung des Timeline-basierten Kampfsystems
- `docs/SUPABASE-ANLEITUNG.md` - Detaillierte Anleitung zur Supabase-Integration
- `docs/ZK-SUPABASE.md` - Übersicht über die Supabase-Datenbankstruktur
- `docs/MCP-SERVER-DOKUMENTATION.md` - Umfassende Dokumentation aller MCP-Server und Tools
- Code-Dokumentation in XML-Format für IntelliSense-Unterstützung

## 📋 SQL-Skripte Übersicht

- **Hauptskripte**:
  - `supabase_tables_setup.sql` - Erstellt Grundtabellen und Karten-Tabelle
  - `player_tables_setup.sql` - Erstellt Spielerdaten-Tabellen
  - `player_api_functions.sql` - API-Funktionen für Spielerdatenverwaltung
  - `player_data_populate.sql` - Fügt Testdaten ein

- **Hilfsskripte**:
  - `activate_full_player_data_function.sql` - Aktiviert die vollständige get_player_data-Funktion
  - `check_all_tables.sql` - Überprüft die Tabellenstruktur
  - `check_table_structure.sql` - Überprüft eine bestimmte Tabellenstruktur
  - `final_player_api_functions.sql` - Aktualisierte Version aller API-Funktionen
  - `fix_player_data_function.sql` - Behebt Probleme mit der get_player_data-Funktion
  - `update_all_tables.sql` - Fügt fehlende Spalten zu Tabellen hinzu
  - `update_player_cards_table.sql` - Aktualisiert die player_cards-Tabelle

## 📄 Lizenz

[Deine Lizenzinformation hier]

---

*"Zeitklingen" - Wo die Zeit selbst zur Waffe wird.*
