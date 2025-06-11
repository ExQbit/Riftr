#!/bin/bash
# update-database.sh
#
# Dieses Skript synchronisiert die Zeitklingen-Datenbank mit Supabase.
# Es führt das sync-database.py-Skript aus und bietet verschiedene Optionen.
#
# Verwendung:
#   ./update-database.sh [Optionen]
#
# Optionen:
#   --env, -e ENV     Umgebung (dev, staging, prod), Standard: dev
#   --dry-run, -d     Zeigt Änderungen an, ohne sie anzuwenden
#   --verbose, -v     Ausführliche Ausgabe

# Pfade
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

# Standardwerte für Optionen
ENVIRONMENT="dev"
DRY_RUN=false
VERBOSE=false

# Funktion zum Anzeigen von Nachrichten
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

success() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] \033[0;32m$1\033[0m"
}

warning() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] \033[0;33m$1\033[0m"
}

error() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] \033[0;31m$1\033[0m"
}

# Befehlszeilenargumente verarbeiten
while [[ $# -gt 0 ]]; do
    case $1 in
        --env|-e)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            warning "Unbekannte Option: $1"
            shift
            ;;
    esac
done

# Prüfen, ob die Umgebung gültig ist
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
    error "Ungültige Umgebung: $ENVIRONMENT. Erlaubte Werte: dev, staging, prod"
    exit 1
fi

# Prüfen, ob Python und die erforderlichen Pakete installiert sind
if ! command -v python3 &> /dev/null; then
    error "Python 3 ist nicht installiert."
    exit 1
fi

# Prüfen, ob die Supabase-Bibliothek installiert ist
if ! python3 -c "import supabase" &> /dev/null; then
    warning "Supabase-Bibliothek nicht gefunden. Installiere sie jetzt..."
    pip3 install supabase
    if [ $? -ne 0 ]; then
        error "Fehler bei der Installation der Supabase-Bibliothek."
        exit 1
    fi
    success "Supabase-Bibliothek erfolgreich installiert."
fi

# Prüfen, ob die dotenv-Bibliothek installiert ist
if ! python3 -c "import dotenv" &> /dev/null; then
    warning "dotenv-Bibliothek nicht gefunden. Installiere sie jetzt..."
    pip3 install python-dotenv
    if [ $? -ne 0 ]; then
        error "Fehler bei der Installation der dotenv-Bibliothek."
        exit 1
    fi
    success "dotenv-Bibliothek erfolgreich installiert."
fi

# Prüfen, ob die .env-Datei existiert
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    error ".env-Datei nicht gefunden. Bitte erstellen Sie eine .env-Datei mit den Supabase-Zugangsdaten."
    exit 1
fi

# Kommandozeilenargumente für das Python-Skript erstellen
PYTHON_ARGS="--env $ENVIRONMENT"

if [ "$DRY_RUN" = true ]; then
    PYTHON_ARGS="$PYTHON_ARGS --dry-run"
fi

if [ "$VERBOSE" = true ]; then
    PYTHON_ARGS="$PYTHON_ARGS --verbose"
fi

# Datenbank synchronisieren
log "Starte Datenbanksynchronisierung für Umgebung: $ENVIRONMENT"

if [ "$DRY_RUN" = true ]; then
    log "DRY-RUN-MODUS: Keine Änderungen werden angewendet."
fi

python3 "$SCRIPT_DIR/sync-database.py" $PYTHON_ARGS

if [ $? -eq 0 ]; then
    success "Datenbanksynchronisierung erfolgreich abgeschlossen."
else
    error "Fehler bei der Datenbanksynchronisierung."
    exit 1
fi

# Änderungen in Git erkennen
if [ -d "$PROJECT_ROOT/.git" ]; then
    if git -C "$PROJECT_ROOT" status --porcelain | grep -q .; then
        warning "Änderungen in der Dokumentation erkannt. Du kannst sie mit 'git add' und 'git commit' festschreiben."
    fi
fi

log "Datenbanksynchronisierung abgeschlossen."
