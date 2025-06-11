#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
update-maintenance-doc.py

Dieses Skript aktualisiert die MAINTENANCE.md-Datei mit aktuellen Informationen
über Automatisierungsskripte und Wartungsaufgaben.
"""

import os
import re
import glob
import json
from datetime import datetime

# Pfade
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DOCS_DIR = os.path.join(PROJECT_ROOT, "docs")
MAINTENANCE_FILE = os.path.join(DOCS_DIR, "MAINTENANCE.md")

def log(message):
    """Gibt eine Nachricht mit Zeitstempel aus."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")

def get_script_info(script_path):
    """Extrahiert Informationen aus einem Skript."""
    info = {
        "name": os.path.basename(script_path),
        "purpose": "",
        "usage": "",
        "when": "",
        "dependencies": [],
        "output": ""
    }
    
    try:
        with open(script_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Versuche, den Zweck aus Docstrings oder Kommentaren zu extrahieren
            purpose_match = re.search(r'"""(.+?)"""', content, re.DOTALL)
            if purpose_match:
                purpose = purpose_match.group(1).strip()
                first_line = purpose.split('\n')[0].strip()
                info["purpose"] = first_line
            else:
                # Alternativ nach Kommentaren suchen
                purpose_match = re.search(r'#\s*(.+?)$', content, re.MULTILINE)
                if purpose_match:
                    info["purpose"] = purpose_match.group(1).strip()
            
            # Verwendung extrahieren
            if "python" in script_path:
                info["usage"] = f"python3 ./zk-commands/{info['name']}"
            elif script_path.endswith(".sh"):
                info["usage"] = f"./zk-commands/{info['name']}"
                
            # Abhängigkeiten erkennen
            if "import" in content:
                imports = re.findall(r'import\s+(\w+)', content)
                info["dependencies"] = imports
                
            # Ausgabe erkennen
            output_match = re.search(r'(erstellt|generiert|erzeugt|aktualisiert)\s+([^\.]+)', content, re.IGNORECASE)
            if output_match:
                info["output"] = output_match.group(2).strip()
                
    except Exception as e:
        log(f"Fehler beim Lesen von {script_path}: {e}")
    
    return info

def update_maintenance_doc():
    """Aktualisiert die MAINTENANCE.md-Datei."""
    log("Starte Aktualisierung der MAINTENANCE.md...")
    
    # Stelle sicher, dass das Verzeichnis existiert
    os.makedirs(DOCS_DIR, exist_ok=True)
    
    # Sammle Informationen über Skripte
    scripts = []
    for script_path in glob.glob(os.path.join(SCRIPT_DIR, "*.py")) + glob.glob(os.path.join(SCRIPT_DIR, "*.sh")):
        script_info = get_script_info(script_path)
        scripts.append(script_info)
    
    # Kategorisiere Skripte
    docs_scripts = []
    db_scripts = []
    check_scripts = []
    other_scripts = []
    
    for script in scripts:
        name = script["name"].lower()
        if "docs" in name or "readme" in name or "api" in name:
            docs_scripts.append(script)
        elif "db" in name or "database" in name or "supabase" in name:
            db_scripts.append(script)
        elif "check" in name or "test" in name or "lint" in name:
            check_scripts.append(script)
        else:
            other_scripts.append(script)
    
    # Lese vorhandene Datei, falls vorhanden
    existing_content = ""
    if os.path.exists(MAINTENANCE_FILE):
        try:
            with open(MAINTENANCE_FILE, 'r', encoding='utf-8') as f:
                existing_content = f.read()
        except Exception as e:
            log(f"Fehler beim Lesen von {MAINTENANCE_FILE}: {e}")
    
    # Aktualisiere nur den Automatisierungsskripte-Abschnitt
    header = """# Zeitklingen: Wartung und Automatisierung

Dieses Dokument enthält Anleitungen zur regelmäßigen Wartung und Automatisierung des Zeitklingen-Projekts. Es wird automatisch aktualisiert, wenn neue Automatisierungsskripte hinzugefügt werden.

**Letzte Aktualisierung:** {date}

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
""".format(date=datetime.now().strftime("%Y-%m-%d"))

    # Dokumentationsautomatisierung
    docs_section = """
### Dokumentationsautomatisierung
"""
    for script in docs_scripts:
        docs_section += f"""
#### `{script["name"]}`
- **Zweck:** {script["purpose"] or "Automatisiert Dokumentationsaufgaben"}
- **Verwendung:** `{script["usage"]}`
- **Wann ausführen:** {script.get("when") or "Nach Code-Änderungen, vor Commits"}
"""
        if script["dependencies"]:
            docs_section += f"- **Abhängigkeiten:** {', '.join(script['dependencies'])}\n"
        if script["output"]:
            docs_section += f"- **Ausgabe:** {script['output']}\n"

    # Datenbank-Automatisierung
    db_section = """
### Datenbank-Automatisierung
"""
    if db_scripts:
        for script in db_scripts:
            db_section += f"""
#### `{script["name"]}`
- **Zweck:** {script["purpose"] or "Verwaltet Datenbankoperationen"}
- **Verwendung:** `{script["usage"]}`
- **Wann ausführen:** {script.get("when") or "Bei Datenbankoperationen"}
"""
            if script["dependencies"]:
                db_section += f"- **Abhängigkeiten:** {', '.join(script['dependencies'])}\n"
            if script["output"]:
                db_section += f"- **Ausgabe:** {script['output']}\n"
    else:
        db_section += """
#### `mcp_supabase_server.py`
- **Zweck:** Stellt Verbindung zur Supabase-Datenbank her
- **Verwendung:** Wird von anderen Skripten verwendet
- **Funktionen:** Karten lesen/erstellen, Spielerdaten verwalten
- **Wann ausführen:** Wird automatisch von anderen Skripten aufgerufen
"""

    # Konsistenzprüfung
    check_section = """
### Konsistenzprüfung
"""
    for script in check_scripts:
        check_section += f"""
#### `{script["name"]}`
- **Zweck:** {script["purpose"] or "Prüft Projektkonsistenz"}
- **Verwendung:** `{script["usage"]}`
- **Wann ausführen:** {script.get("when") or "Vor Releases, bei Verdacht auf Inkonsistenzen"}
"""
        if script["dependencies"]:
            check_section += f"- **Abhängigkeiten:** {', '.join(script['dependencies'])}\n"
        if script["output"]:
            check_section += f"- **Ausgabe:** {script['output']}\n"

    # Andere Skripte
    other_section = ""
    if other_scripts:
        other_section = """
### Weitere Automatisierungen
"""
        for script in other_scripts:
            other_section += f"""
#### `{script["name"]}`
- **Zweck:** {script["purpose"] or "Automatisiert verschiedene Aufgaben"}
- **Verwendung:** `{script["usage"]}`
- **Wann ausführen:** {script.get("when") or "Nach Bedarf"}
"""
            if script["dependencies"]:
                other_section += f"- **Abhängigkeiten:** {', '.join(script['dependencies'])}\n"
            if script["output"]:
                other_section += f"- **Ausgabe:** {script['output']}\n"

    # Dokumentationsrichtlinien und Fehlerbehebung
    footer = """
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
"""

    # Zusammensetzen des neuen Inhalts
    new_content = header + docs_section + db_section + check_section + other_section + footer
    
    # Schreibe die aktualisierte Datei
    try:
        with open(MAINTENANCE_FILE, 'w', encoding='utf-8') as f:
            f.write(new_content)
        log(f"MAINTENANCE.md erfolgreich aktualisiert: {MAINTENANCE_FILE}")
    except Exception as e:
        log(f"Fehler beim Schreiben von {MAINTENANCE_FILE}: {e}")
        return False
    
    return True

if __name__ == "__main__":
    update_maintenance_doc()
