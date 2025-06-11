h# ZK-CI-CD - Zeitklingen CI/CD-Integration

## Dokumentationsautomatisierung

Die Dokumentationsautomatisierung ist in eine CI/CD-Pipeline integriert, die eine manuelle Bestätigung erfordert, bevor Änderungen vorgenommen werden.

### Workflow-Übersicht

Der Workflow besteht aus zwei Hauptschritten:

1. **Prüfung auf Änderungen**: Überprüft, ob Aktualisierungen der Dokumentation erforderlich sind
2. **Dokumentationsaktualisierung**: Führt die Aktualisierung durch, wenn Änderungen erforderlich sind

### Verwendung

1. Navigieren Sie zu Ihrem GitHub-Repository
2. Gehen Sie zum Tab "Actions"
3. Wählen Sie "Zeitklingen Dokumentationsautomatisierung"
4. Klicken Sie auf "Run workflow"
5. Konfigurieren Sie die Optionen:
   - **Dokumentationsprüfung durchführen?**: Aktiviert die Konsistenzprüfung mit check-docs.py
   - **Änderungen automatisch committen?**: Wenn aktiviert, werden Änderungen automatisch committet

### Parameter

- **--check, -c**: Führt die Dokumentationsprüfung durch
- **--dry-run, -d**: Zeigt Änderungen an, ohne sie zu speichern (für CI/CD)

### Vorteile

- **Manuelle Kontrolle**: Änderungen werden erst nach Bestätigung übernommen
- **Automatisierung**: Reduziert manuelle Arbeit bei der Dokumentationspflege
- **Konsistenz**: Gewährleistet einheitliche Dokumentationsstandards
- **Transparenz**: Zeigt alle vorgeschlagenen Änderungen vor dem Commit

### Empfohlene Nutzung

- Vor Releases
- Nach größeren Feature-Implementierungen
- Bei Änderungen an der Projektstruktur
- Monatlich zur Sicherstellung der Dokumentationsaktualität

## Integration in lokalen Workflow

Sie können die Dokumentationsautomatisierung auch lokal ausführen:

```bash
# Nur Änderungen anzeigen, ohne sie zu speichern
./zk-commands/update-docs.sh --dry-run

# Dokumentation aktualisieren und Konsistenz prüfen
./zk-commands/update-docs.sh --check
```

## Wartung und Erweiterung

Die CI/CD-Integration kann erweitert werden, um weitere Automatisierungen einzuschließen:

- Automatische Tests
- Code-Qualitätsprüfungen
- Build-Prozesse

Siehe [MAINTENANCE.md](MAINTENANCE.md) für weitere Informationen zur Wartung des Projekts.
