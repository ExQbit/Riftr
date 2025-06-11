# MCP-Server-Dokumentation für Zeitklingen

Dieses Dokument beschreibt die verschiedenen MCP-Server (Master Content Provider) und Tools, die für das Zeitklingen-Projekt verfügbar sind.

## 1. Supabase MCP-Server

### Hauptserver (`mcp_supabase_server.py`)

**Pfad:** `zk-commands/mcp_supabase_server.py`

**Funktionen:**
- Verbindung zur Supabase-Datenbank herstellen
- Kartendaten abrufen und filtern
- Spielerfortschritt verwalten
- Spielsitzungen protokollieren

**Verbindungsdaten:**
- URL: `https://slvxtnfmktzjgomwqmxk.supabase.co`
- API-Key: Wird aus der `.env`-Datei geladen

**Verwendung:**
```python
# Beispiel für den Zugriff auf Karten
from zk-commands.mcp_supabase_server import get_supabase_client

supabase = get_supabase_client()
response = supabase.table("cards").select("*").execute()
cards = response.data
```

### Vereinfachter Server (`mcp_supabase_server_simple.py`)

Eine vereinfachte Version des Hauptservers mit reduzierten Funktionen, ideal für schnelle Tests.

## 2. Progression Simulator

**Pfad:** `progression_simulator.py`

**Funktionen:**
- Simuliert den Spielfortschritt durch die Welten von Zeitklingen
- Testet die Balance der Karten, Klassen und Mechaniken
- Erstellt Visualisierungen für Klassenvergleiche
- Integriert sich mit dem ZeitklingenSimulator

**Komponenten:**
- `MCPClient`: Verbindet sich mit Supabase, um Kartendaten abzurufen
- `ProgressionSimulator`: Hauptklasse für die Simulation
- `MockZeitklingenSimulator`: Fallback, wenn der echte Simulator nicht verfügbar ist

**Verwendung:**
```python
# Beispiel für die Verwendung des Simulators
simulator = ProgressionSimulator()
results = simulator.simulate_progression("chronomant")
# Oder alle Klassen vergleichen
comparison = simulator.compare_classes()
```

## 3. Kartendaten-Management

### Download-Skript (`download_cards_from_supabase.py`)

**Funktionen:**
- Lädt alle Karten aus der Supabase-Datenbank
- Speichert sie in JSON-Dateien (nach Typ sortiert und als Array)
- Verwendet die korrekte Supabase-URL und den Service-Role-Key

**Verwendung:**
```bash
python3 download_cards_from_supabase.py
```

### Extraktions-Skript (`extract_cards_to_json.py`)

**Funktionen:**
- Extrahiert Kartendaten aus Markdown-Dateien
- Konvertiert sie in das Supabase-Kartenformat
- Speichert sie in JSON-Dateien

**Verwendung:**
```bash
python3 extract_cards_to_json.py
```

### Update-Skript (`update_supabase_cards.py`)

**Funktionen:**
- Aktualisiert Karten in der Supabase-Datenbank
- Kann neue Karten hinzufügen oder bestehende aktualisieren
- Unterstützt Batch-Operationen

**Verwendung:**
```bash
python3 update_supabase_cards.py
```

## 4. CardDataImporter für Unity

Ein Editor-Tool, das Kartendaten von einem MCP-Server abrufen und in Unity-ScriptableObjects konvertieren kann.

**Funktionen:**
- Verbindung zu einem API-Endpunkt mit optionalem API-Key
- Abrufen und Anzeigen aller verfügbaren Karten
- Filtern und Auswählen spezifischer Karten
- Automatisches Erstellen von ScriptableObjects

**Zugriff:**
- Über das Menü "Zeitklingen/Card Data Importer" in Unity
- Standard-URL: `https://mcp.zeitklingen.com/api/cards` (anpassbar)

## 5. Fehlerbehebung

### Verbindungsprobleme

1. Überprüfe die `.env`-Datei auf korrekte Anmeldedaten
2. Stelle sicher, dass die Supabase-URL korrekt ist: `https://slvxtnfmktzjgomwqmxk.supabase.co`
3. Überprüfe, ob der Service-Role-Key gültig ist
4. Prüfe die Internetverbindung

### Importprobleme

1. Stelle sicher, dass die Supabase-Bibliothek installiert ist: `pip install supabase`
2. Überprüfe, ob die Tabellen in der Datenbank existieren
3. Bei Unity-Importen: Überprüfe die API-Endpunkt-Konfiguration
