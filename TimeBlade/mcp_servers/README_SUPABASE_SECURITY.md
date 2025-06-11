# Supabase-Sicherheit für Zeitklingen

## Überblick

Dieses Dokument erklärt die sichere Handhabung von Supabase-Anmeldeinformationen im Zeitklingen-Projekt. Es beschreibt die implementierte Lösung für das Problem mit der .env-Datei und bietet Richtlinien für die sichere Verwendung von API-Schlüsseln.

## Problem und Lösung

### Identifiziertes Problem

Bei der Integration von Supabase wurde festgestellt, dass der API-Schlüssel in der `.env`-Datei nicht korrekt geladen wurde, obwohl er syntaktisch korrekt aussah. Dies führte zu "Invalid API key"-Fehlern bei der Verwendung des Supabase-Clients.

### Implementierte Lösung

Wir haben einen `ConfigManager` implementiert, der mehrere Quellen für Konfigurationswerte und Anmeldeinformationen unterstützt:

1. **Mehrschichtige Konfiguration**: Der Manager sucht Werte in dieser Reihenfolge:
   - Umgebungsvariablen
   - `secrets.json` (für sensible Daten)
   - `config.json` (für nicht-sensible Konfigurationen)
   - Fallback-Werte (für kritische Konfigurationen)

2. **Sichere Speicherung**: Sensible Daten wie API-Schlüssel werden in der `secrets.json`-Datei gespeichert, die in `.gitignore` aufgeführt ist.

3. **Robuste Fehlerbehandlung**: Der Manager bietet klare Fehlermeldungen und Logging für Diagnose und Fehlerbehebung.

## Verwendung

### Einrichtung

1. Stelle sicher, dass die `secrets.json`-Datei im Projektroot existiert und den Supabase-Schlüssel enthält:
   ```json
   {
     "SUPABASE_SERVICE_ROLE_KEY": "dein-supabase-schlüssel"
   }
   ```

2. Stelle sicher, dass `secrets.json` in `.gitignore` aufgeführt ist, um versehentliches Einchecken zu verhindern.

### Code-Beispiel

```python
# Importiere den ConfigManager
from zk-commands.config_manager import get_config_manager

# Hole eine Konfiguration
config = get_config_manager()
supabase_url = config.get("SUPABASE_URL")

# Oder verwende die Hilfsfunktion für Supabase
from zk-commands.supabase_client import get_supabase_client
client = get_supabase_client()
```

## Sicherheitsrichtlinien

1. **Keine Hardcoded Secrets**: Speichere niemals API-Schlüssel oder andere sensible Daten direkt im Code.

2. **Verwende den ConfigManager**: Nutze immer den ConfigManager, um auf Konfigurationen und Anmeldeinformationen zuzugreifen.

3. **Gitignore-Regeln**: Stelle sicher, dass alle Dateien mit sensiblen Daten in `.gitignore` aufgeführt sind.

4. **Regelmäßige Rotation**: Rotiere API-Schlüssel regelmäßig und aktualisiere die `secrets.json`-Datei entsprechend.

5. **Berechtigungen**: Stelle sicher, dass die `secrets.json`-Datei die richtigen Dateiberechtigungen hat (nur Besitzer kann lesen/schreiben).

## CI/CD-Integration

Für CI/CD-Pipelines sollten Umgebungsvariablen verwendet werden, anstatt auf die `secrets.json`-Datei zuzugreifen. Der ConfigManager wird automatisch Umgebungsvariablen verwenden, wenn sie verfügbar sind.

## Fehlerbehebung

Wenn du Probleme mit der Supabase-Verbindung hast:

1. Überprüfe, ob die `secrets.json`-Datei existiert und den korrekten Schlüssel enthält.
2. Stelle sicher, dass der ConfigManager korrekt importiert wird.
3. Aktiviere Debug-Logging, um detaillierte Informationen zu erhalten.

---

Erstellt am: 2025-04-07  
Letzte Aktualisierung: 2025-04-07
