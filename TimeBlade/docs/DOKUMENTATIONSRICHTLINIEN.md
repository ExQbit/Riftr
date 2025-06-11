# Zeitklingen Dokumentationsrichtlinien

## Grundprinzipien

1. **Keine statischen Daten in der Dokumentation**
   - Keine festen Zahlenangaben (z.B. Kartenanzahl)
   - Keine absoluten Pfadangaben, die sich ändern könnten
   - Keine hartcodierten URLs oder API-Schlüssel

2. **Verweis auf zentrale Konfigurationsquellen**
   - Verweise auf `.windsurf.tools.json` für Serverpfade und -konfigurationen
   - Verweise auf `.env` für sensitive Daten und Verbindungsparameter
   - Verweise auf spezifische Dokumentationsdateien für Details

3. **Dynamische Informationsgewinnung**
   - Anleitung zur Ausführung von Skripten für aktuelle Daten
   - Beispiel: `python scripts/download_cards_from_supabase.py --count-only` für aktuelle Kartenanzahl
   - Beispiel: `python <server_skript> --help` für aktuelle Nutzungshinweise

4. **Zukunftssichere Codebeispiele**
   - Warnhinweise zu möglichen Änderungen der Importpfade
   - Generische Beispiele statt spezifischer Implementierungen
   - Kommentare zur Aktualität der Daten

## Für KI-Assistenten

Als KI-Assistent solltest du:

1. **Niemals statische Daten aus Memories oder Dokumentation zitieren**
   - Insbesondere keine Kartenanzahl, Pfade oder URLs
   - Stattdessen auf die Möglichkeit zur dynamischen Abfrage hinweisen

2. **Immer die aktuelle Datenbank abfragen**
   - Verwende `download_cards_from_supabase.py --count-only` für die aktuelle Kartenanzahl
   - Verwende andere Skripte für aktuelle Informationen zu Servern und Konfigurationen

3. **Auf zentrale Konfigurationsdateien verweisen**
   - `.windsurf.tools.json` für Serverpfade und -konfigurationen
   - `.env` für sensitive Daten und Verbindungsparameter

4. **Bei Unsicherheit immer die aktuelle Konfiguration prüfen**
   - Nie Annahmen basierend auf alten Memories oder Dokumentation treffen
   - Im Zweifel die aktuelle Konfiguration durch Skriptausführung ermitteln

## Beispiele

### ❌ Falsch:
"Das Zeitklingen-Projekt hat 179 Karten, aufgeteilt in Chronomant, Schattenschreiter und Zeitwächter."

### ✅ Richtig:
"Um die aktuelle Anzahl der Karten und ihre Verteilung zu ermitteln, kann das Skript `download_cards_from_supabase.py --count-only` ausgeführt werden."

### ❌ Falsch:
"Der Supabase-Server ist unter `scripts/mcp_supabase_server.py` zu finden."

### ✅ Richtig:
"Der Pfad zum Supabase-Server ist in der `.windsurf.tools.json`-Datei konfiguriert."
