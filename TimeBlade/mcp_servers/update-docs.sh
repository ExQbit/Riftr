#!/bin/bash
# update-docs.sh
#
# Dieses Skript aktualisiert automatisch die Dokumentation des Zeitklingen-Projekts.
# Es führt die README-Feature-Aktualisierung, API-Dokumentationsgenerierung und
# Wartungsdokumentationsaktualisierung aus.
#
# Verwendung:
#   ./update-docs.sh [Optionen]
#
# Optionen:
#   --check, -c     Führt auch die Dokumentationsprüfung aus (check-docs.py)
#   --dry-run, -d   Zeigt Änderungen an, ohne sie zu speichern (für CI/CD)

# Pfade
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Farben für Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Standardwerte für Optionen
RUN_CHECK=false
DRY_RUN=false

# Funktion zum Anzeigen von Nachrichten
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Befehlszeilenargumente verarbeiten
while [[ $# -gt 0 ]]; do
    case $1 in
        --check|-c)
            RUN_CHECK=true
            shift
            ;;
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        *)
            warning "Unbekannte Option: $1"
            shift
            ;;
    esac
done

# Prüfe, ob Python installiert ist
if ! command -v python3 &> /dev/null; then
    warning "Python 3 ist nicht installiert. Bitte installiere Python 3, um dieses Skript auszuführen."
    exit 1
fi

# Aktualisiere README-Features
log "Aktualisiere README-Features..."
if [ "$DRY_RUN" = true ]; then
    python3 "$SCRIPT_DIR/update-readme-features.py" --dry-run
else
    python3 "$SCRIPT_DIR/update-readme-features.py"
fi
if [ $? -eq 0 ]; then
    success "README-Features erfolgreich aktualisiert."
else
    warning "Fehler bei der Aktualisierung der README-Features."
fi

# Generiere API-Dokumentation
log "Generiere API-Dokumentation..."
if [ "$DRY_RUN" = true ]; then
    python3 "$SCRIPT_DIR/generate-api-docs.py" --dry-run
else
    python3 "$SCRIPT_DIR/generate-api-docs.py"
fi
if [ $? -eq 0 ]; then
    success "API-Dokumentation erfolgreich generiert."
else
    warning "Fehler bei der Generierung der API-Dokumentation."
fi

# Aktualisiere Wartungsdokumentation
log "Aktualisiere Wartungsdokumentation..."
if [ "$DRY_RUN" = true ]; then
    python3 "$SCRIPT_DIR/update-maintenance-doc.py" --dry-run
else
    python3 "$SCRIPT_DIR/update-maintenance-doc.py"
fi
if [ $? -eq 0 ]; then
    success "Wartungsdokumentation erfolgreich aktualisiert."
else
    warning "Fehler bei der Aktualisierung der Wartungsdokumentation."
fi

# Prüfe, ob Änderungen in Git vorhanden sind
if command -v git &> /dev/null && [ -d "$PROJECT_ROOT/.git" ]; then
    cd "$PROJECT_ROOT"
    if [ -n "$(git status --porcelain)" ]; then
        log "Änderungen in der Dokumentation erkannt. Du kannst sie mit 'git add' und 'git commit' festschreiben."
    else
        log "Keine Änderungen in der Dokumentation erkannt."
    fi
fi

# Führe Dokumentationsprüfung aus, wenn aktiviert
if [ "$RUN_CHECK" = true ]; then
    log "Führe Dokumentationsprüfung aus..."
    python3 "$SCRIPT_DIR/check-docs.py"
    if [ $? -eq 0 ]; then
        success "Dokumentationsprüfung erfolgreich abgeschlossen."
    else
        warning "Probleme bei der Dokumentationsprüfung gefunden."
    fi
fi

success "Dokumentationsaktualisierung abgeschlossen."
