# Zeitklingen: Wartung und Automatisierung

Dieses Dokument enthält Anleitungen zur regelmäßigen Wartung und Automatisierung des Zeitklingen-Projekts. Es wird automatisch aktualisiert, wenn neue Automatisierungsskripte hinzugefügt werden.

**Letzte Aktualisierung:** 2025-04-07

## 📋 Regelmäßige Wartungsaufgaben

### Tägliche Aufgaben
- Aktualisiere die Dokumentation mit `./zk-commands/update-docs.sh`
- Synchronisiere Änderungen mit Git (`git add`, `git commit`, `git push`)

### Wöchentliche Aufgaben
- Führe alle Tests aus und überprüfe die Testabdeckung
- Aktualisiere `TASK.md` mit erledigten und neuen Aufgaben
- Überprüfe die Konsistenz der Dokumentation mit `./zk-commands/check-docs.py`

### Monatliche Aufgaben
- Überprüfe und aktualisiere Abhängigkeiten
- Führe Refactoring für komplexe oder unklare Codebereiche durch
- Aktualisiere `PLANNING.md` mit neuen Erkenntnissen und Entscheidungen

## 🔄 Automatisierungsskripte

### Dokumentationsautomatisierung

#### `generate-api-docs.py`
- **Zweck:** generate-api-docs.py
- **Verwendung:** ``
- **Wann ausführen:** Nach Code-Änderungen, vor Commits
- **Abhängigkeiten:** os, re, glob, json, datetime, defaultdict
- **Ausgabe:** API-Dokumentation aus Code-Kommentaren im Zeitklingen-Projekt

#### `check-docs.py`
- **Zweck:** Placeholder for check-docs.py script
- **Verwendung:** ``
- **Wann ausführen:** Nach Code-Änderungen, vor Commits
- **Abhängigkeiten:** os, re

#### `update-readme-features.py`
- **Zweck:** update-readme-features.py
- **Verwendung:** ``
- **Wann ausführen:** Nach Code-Änderungen, vor Commits
- **Abhängigkeiten:** os, re, glob, json, datetime
- **Ausgabe:** die README

#### `update-docs.sh`
- **Zweck:** !/bin/bash
- **Verwendung:** `./zk-commands/update-docs.sh`
- **Wann ausführen:** Nach Code-Änderungen, vor Commits
- **Ausgabe:** automatisch die Dokumentation des Zeitklingen-Projekts

### Datenbank-Automatisierung

#### `test_supabase_request.py`
- **Zweck:** Set up paths for iCloud access
- **Verwendung:** ``
- **Wann ausführen:** Bei Datenbankoperationen
- **Abhängigkeiten:** json, socket, sys, os, Path, subprocess, time

#### `mcp_supabase_server.py`
- **Zweck:** MCP Server für Zeitklingen Supabase Integration
- **Verwendung:** ``
- **Wann ausführen:** Bei Datenbankoperationen
- **Abhängigkeiten:** os, sys, json, Path, datetime, Dict, load_dotenv, FastMCP, create_client, BaseModel, argparse, traceback

#### `mcp_supabase_server_simple.py`
- **Zweck:** MCP Server für Zeitklingen Supabase Integration
- **Verwendung:** ``
- **Wann ausführen:** Bei Datenbankoperationen
- **Abhängigkeiten:** os, sys, json, asyncio, Path, datetime, Dict, load_dotenv, Server, InitializationOptions, mcp, stdio_server, create_client, BaseModel, traceback, traceback

#### `mcp_supabase_server 3.py`
- **Zweck:** MCP Server für Zeitklingen Supabase Integration
- **Verwendung:** ``
- **Wann ausführen:** Bei Datenbankoperationen
- **Abhängigkeiten:** os, sys, Path, load_dotenv, json, datetime, Dict, Server, Tool, CallToolRequest, BaseModel, create_client

#### `mcp_supabase_server 2.py`
- **Zweck:** MCP Server for Zeitklingen Card Game - Supabase Database Integration
- **Verwendung:** ``
- **Wann ausführen:** Bei Datenbankoperationen
- **Abhängigkeiten:** os, sys, Path, load_dotenv, json, datetime, Dict, Server, from, Tool, from, BaseModel, create_client, time, traceback

### Konsistenzprüfung

#### `check-memory-sync.py`
- **Zweck:** Prüft Projektkonsistenz
- **Verwendung:** ``
- **Wann ausführen:** Vor Releases, bei Verdacht auf Inkonsistenzen
- **Abhängigkeiten:** os, json

### Weitere Automatisierungen

#### `update-maintenance-doc.py`
- **Zweck:** update-maintenance-doc.py
- **Verwendung:** ``
- **Wann ausführen:** Nach Bedarf
- **Abhängigkeiten:** os, re, glob, json, datetime
- **Ausgabe:** die MAINTENANCE

#### `fastmcp_stub.py`
- **Zweck:** Erweiterte FastMCP Implementation für Zeitklingen
- **Verwendung:** ``
- **Wann ausführen:** Nach Bedarf
- **Abhängigkeiten:** Callable, BaseModel, inspect

## 📝 Dokumentationsrichtlinien

### C#-Dokumentationskommentare

Für optimale Automatisierung sollten C#-Dateien XML-Dokumentationskommentare verwenden:

```csharp
/// <summary>
/// Kurze Beschreibung der Klasse oder Methode.
/// </summary>
/// <param name="paramName">Beschreibung des Parameters</param>
/// <returns>Beschreibung des Rückgabewerts</returns>
/// <remarks>
/// Zusätzliche Informationen zur Verwendung.
/// </remarks>
/// <example>
/// Beispielcode zur Verwendung.
/// </example>
public ReturnType MethodName(ParamType paramName)
{
    // Implementierung
}
```

### Markdown-Dokumentation

- Verwende aussagekräftige Überschriften (# für Hauptüberschriften, ## für Abschnitte)
- Nutze Listen für Aufzählungen (- oder 1., 2., 3.)
- Verwende Codeblöcke mit Sprachkennung (```csharp)
- Füge Links zu anderen Dokumenten ein ([Linktext](pfad/zur/datei.md))

## 🔍 Fehlerbehebung

### Dokumentationsautomatisierung

- **Problem:** Keine Features gefunden
  - **Lösung:** Stelle sicher, dass C#-Dateien XML-Dokumentationskommentare haben
  - **Lösung:** Überprüfe die Pfade in den Skripten (SCRIPTS_PATH)

- **Problem:** API-Dokumentation unvollständig
  - **Lösung:** Füge fehlende XML-Tags hinzu (<summary>, <param>, etc.)
  - **Lösung:** Stelle sicher, dass Klassen und Methoden public sind

### Supabase-Integration

- **Problem:** Verbindungsfehler
  - **Lösung:** Überprüfe Supabase-Anmeldedaten in .env
  - **Lösung:** Stelle sicher, dass die Supabase-Instanz läuft

## 📅 Erinnerungen

- Führe `update-docs.sh` nach jeder größeren Code-Änderung aus
- Aktualisiere `TASK.md` am Ende jeder Arbeitssitzung
- Überprüfe die API-Dokumentation vor jedem Release
- Führe `check-docs.py` aus, wenn du neue Dokumentationsdateien hinzufügst

---

*Dieses Dokument wird automatisch aktualisiert. Manuelle Änderungen können überschrieben werden.*
