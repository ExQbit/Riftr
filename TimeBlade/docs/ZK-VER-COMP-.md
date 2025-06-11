# Versionierungs- und Release-Management (ZK-VER-COMP-v1.0-20250325)

## Änderungshistorie
- v1.0 (2025-03-25): Komprimierte Version von ZK-VER-v1.0-20250325

## Zusammenfassung
Strategie und Prozesse für Versions- und Release-Management des Zeitklingen-Projekts: Versionsnummerierung, Branching-Strategien, Release-Typen und -Zyklen sowie Deployment-Prozesse. Strukturierte, vorhersehbare Releases mit minimierten Risiken.

## 1. Versionierungsstrategie

### 1.1 Semantische Versionierung
```
MAJOR.MINOR.PATCH
   │     │     │
   │     │     └─► Bugfixes, kleine Änderungen
   │     │ 
   │     └─────► Neue Funktionen (rückwärtskompatibel)
   │
   └─────────► Inkompatible Änderungen, fundamentale Spieländerungen
```

#### 1.1.1 Richtlinien
- **MAJOR**: Inkompatible Änderungen, Redesign von Kernsystemen, Daten-Inkompatibilität
- **MINOR**: Neue Features, Inhalte, Balance-Änderungen, UI/UX-Verbesserungen
- **PATCH**: Bugfixes, kleine Anpassungen, Performance-Optimierungen, Textkorrekturen

#### 1.1.2 Pre-Release und Metadaten
- **Alpha**: `MAJOR.MINOR.PATCH-alpha.N` (z.B. `1.0.0-alpha.3`)
- **Beta**: `MAJOR.MINOR.PATCH-beta.N` (z.B. `1.0.0-beta.2`)
- **Release-Kandidaten**: `MAJOR.MINOR.PATCH-rc.N` (z.B. `1.0.0-rc.1`)
- **Build-Metadaten**: `MAJOR.MINOR.PATCH+YYYYMMDD` (z.B. `1.0.0+20250325`)

### 1.2 Interne Entwicklungsversionierung
```
[Major].[Minor].[Patch].[Build]-[Stage].[Iteration]
Beispiel: 0.8.2.1045-alpha.3
```

## 2. Branching-Strategie

### 2.1 GitFlow-Modell
```
──────────── main ───────────────────────────►
     │           ▲           ▲
     │           │           │
     │      ┌────┴──┐   ┌────┴────┐
     │      │release│   │hotfix   │
     │      │branch │   │branches │
     │      └───┬───┘   └────┬────┘
     ▼          │            │
──── develop ───┼────────────┼──────────────►
     ▲    ▲     │            │
     │    │     │            │
┌────┴─┐ ┌┴────┐│            │
│feat- │ │feat-││            │
│ure A │ │ure B││            │
└──────┘ └─────┘│            │
```

### 2.2 Branch-Typen
| Typ | Benennungskonvention | Lebensdauer | Basis | Merge-Ziel |
|-----|----------------------|-------------|-------|------------|
| Main | `main` | Permanent | - | - |
| Develop | `develop` | Permanent | `main` | - |
| Feature | `feature/TK-[id]-[beschreibung]` | Temporär | `develop` | `develop` |
| Release | `release/v[major].[minor].0` | Temporär | `develop` | `main` + `develop` |
| Hotfix | `hotfix/v[major].[minor].[patch]` | Temporär | `main` | `main` + `develop` |
| Bugfix | `bugfix/TK-[id]-[beschreibung]` | Temporär | `develop` | `develop` |

### 2.3 Branch-Workflows

#### 2.3.1 Feature-Branches
- Von `develop` abzweigen
- Maximal 2 Wochen Lebensdauer
- Pull-Request mit mindestens einem Reviewer
- Nach Merge löschen

#### 2.3.2 Release-Branches
- Von `develop` abzweigen wenn Release-Features bereit
- Nur Bugfixes, Dokumentation, Release-Vorbereitung
- Merge in `main` und zurück in `develop`
- Tag mit Release-Version erstellen

#### 2.3.3 Hotfix-Branches
- Von `main` abzweigen bei kritischen Fehlern
- Nur spezifische Fehlerkorrekturen
- Merge in `main` und `develop`
- Neues Tag mit aktualisierter Patch-Version

### 2.4 Code-Review-Prozess
- Aussagekräftiger PR-Titel mit Ticket-ID
- Mindestens ein genehmigender Review
- Automatisierte Tests bestanden
- Squash-and-Merge für Feature-Branches

## 3. Release-Typen und -Zyklen

### 3.1 Release-Typen
```
MAJOR        MINOR        PATCH      HOTFIX
RELEASE      RELEASE      RELEASE    RELEASE
┌────┐       ┌────┐       ┌────┐     ┌────┐
│1.0.0│       │1.1.0│       │1.1.1│     │1.1.2│
└────┘       └────┘       └────┘     └────┘
   │            │            │          │
Neue Haupt-  Neue Features  Bugfixes   Kritische
version mit   und Inhalte    und kleine  Fehler-
Breaking      (rückwärts-    Verbesse-   behebungen
Changes       kompatibel)    rungen
```

### 3.2 Release-Zyklen
| Typ | Häufigkeit | Vorlaufzeit | Teststufen |
|-----|------------|-------------|------------|
| Major | Jährlich | 3-6 Monate | Alpha, Beta, RC |
| Minor | Vierteljährlich | 1-3 Monate | Beta, RC |
| Patch | Monatlich | 1-4 Wochen | Fokussierte Tests |
| Hotfix | Bei Bedarf | 24-72 Stunden | Gezielte Tests |

### 3.3 Release-Planer 2025-2026
| Version | Typ | Datum | Schwerpunkte |
|---------|-----|-------|--------------|
| 0.1.0 | Alpha | April 2025 | Kernsysteme |
| 0.5.0 | Beta | August 2025 | Alle Klassen, erster Dungeon |
| 1.0.0 | Release | November 2025 | Erster öffentlicher Release |
| 1.1.0 | Minor | Februar 2026 | Neue Karten, saisonale Inhalte |
| 1.2.0 | Minor | Mai 2026 | Neue Klasse: Zeitwandler |
| 2.0.0 | Major | November 2026 | Kooperativer Mehrspielermodus |

## 4. Release-Prozess

### 4.1 Release-Vorbereitung
```
FEATURE-   FEATURE    RELEASE     QA &     RELEASE
PLANUNG    FREEZE     BRANCH      UAT      BUILD
   │          │          │          │         │
   ▼          ▼          ▼          ▼         ▼
Feature-    Keine     Branch-    Vollständige Finale
Umfang      neuen     Erstellung Tests und   Build-
festlegen   Features               UAT       Erstellung
```

#### 4.1.1 Feature-Planung
- Feature-Umfang festlegen
- Tickets priorisieren und Sprints zuweisen
- Release-Plan mit Zeitplan und Meilensteinen

#### 4.1.2 Feature-Freeze
- 2-4 Wochen vor Release
- Nur noch Bugfixes akzeptiert
- Alle geplanten Features integriert

### 4.2 Release-Validierung
- Vollständige Testreihe auf Release-Branch
- Regressionstest aller Kernsysteme
- Performance- und Kompatibilitätstests
- UAT auf Release-Kandidaten

### 4.3 Release-Checkliste
```
□ Alle geplanten Features implementiert
□ Alle kritischen Fehler behoben
□ QA-Signoff erhalten
□ Release-Notes vollständig
□ Versionsnummern aktualisiert
□ Build-Prozess erfolgreich
□ Store-Assets aktualisiert
□ Marketingmaterialien vorbereitet
□ Supportteam informiert
□ Infrastruktur vorbereitet
□ Backup-Strategie implementiert
□ Rollback-Plan dokumentiert
```

### 4.4 Deployment-Prozess
- Store-Submission vorbereiten
- Release-Koordination mit Marketing
- Monitoring der ersten 24-48 Stunden nach Release

## 5. Hotfix-Prozess

### 5.1 Kriterien
- Kritische Fehler mit erheblichen Auswirkungen
- Sicherheitslücken, Datenverlustprobleme
- Entscheidung durch technischen Lead und Produktmanager

### 5.2 Hotfix-Workflow
```
PROBLEM     HOTFIX     EXPRESS    DEPLOY
IDENTIFIKATION BRANCH   TESTING    & MONITOR
    │          │          │          │
    ▼          ▼          ▼          ▼
Validierung  Branch-   Beschleunigte Deployment
und          Erstellung Tests mit    und intensive
Priorisierung von main   Fokus       Überwachung
```

## 6. Versionsdokumentation

### 6.1 Änderungshistorie-Format
```markdown
# Änderungshistorie
Alle wichtigen Änderungen an diesem Projekt werden hier dokumentiert.

## [Unreleased]
### Hinzugefügt
- Neue Features, die noch nicht veröffentlicht wurden

## [1.1.0] - 2026-02-15
### Hinzugefügt
- 10 neue Karten für den Chronomanten
- Saisonaler Winterdungeon mit speziellen Belohnungen

### Geändert
- Verbesserte Darstellung der Zeiteffekte mit neuen Animationen

### Behoben
- Fehler, durch den Zeitkristalle falsch berechnet wurden
```

### 6.2 Version-Tracking
- Zentrales Dokument: `VERSION.md`
- Automatische Aktualisierung im Release-Prozess
- In-Game-Versionsanzeige im Startbildschirm

### 6.3 Kompatibilitätsrichtlinien
- Major-Releases: Datenformatänderungen erlaubt (mit Migration)
- Minor-Releases: Abwärtskompatibel mit letztem Major-Release
- Patch-Releases: Vollständige Abwärtskompatibilität

## 7. Rollen und Verantwortlichkeiten

### 7.1 Release-Management-Team
- **Release Manager**: Koordiniert den gesamten Prozess
- **QA-Lead**: Testplanung und Qualitätssicherung
- **Build-Ingenieur**: Build-Prozesse und -werkzeuge
- **Produktmanager**: Release-Umfang und -prioritäten

### 7.2 RACI-Matrix
| Aktivität | RM | QA | BI | PM | Entwicklung |
|-----------|----|----|----|----|------------|
| Feature-Planung | A | I | I | R | C |
| Branch-Erstellung | A | I | R | I | C |
| Build-Erstellung | A | I | R | I | I |
| QA-Validierung | A | R | I | I | C |
| Release-Genehmigung | A | R | I | R | I |
| Deployment | A | I | R | I | I |

**Legende**: R-Responsible, A-Accountable, C-Consulted, I-Informed

## 8. Tools und Infrastruktur

### 8.1 Versionskontrolle
- Git als primäres System
- GitHub/GitLab für Repository-Hosting
- Git-Flow-Extensions für Workflow

### 8.2 Build und Release
- Jenkins/GitHub Actions: CI/CD
- Unity Cloud Build: Plattform-Builds
- Fastlane: Mobile-Deployment
- SteamPipe: Steam-Releases

### 8.3 Tracking und Dokumentation
- JIRA/Linear: Issue-Tracking
- Confluence/Notion: Prozessdokumentation
- Discord/Slack: Kommunikationskanäle

## 9. Risikomanagement

### 9.1 Release-Risiken
| Risiko | Wahrscheinlichkeit | Auswirkung | Vermeidungsstrategie |
|--------|-------------------|------------|---------------------|
| Kritische Fehler nach Release | Mittel | Hoch | Umfassende QA, gestaffelter Rollout |
| App-Store-Ablehnung | Niedrig | Hoch | Vorprüfung, frühzeitige Einreichung |
| Build-Fehler | Mittel | Hoch | Redundante Systeme, automatisierte Tests |

### 9.2 Rollback-Prozesse
- **Vollständiger Rollback**: Zurücksetzen auf vorherige stabile Version
- **Partieller Rollback**: Rückgängigmachung spezifischer Änderungen
- **Post-Mortem-Prozess**: Root-Cause-Analyse nach kritischen Fehlern

## 10. Kontinuierliche Verbesserung

### 10.1 Release-Retrospektiven
- Nach jedem Release durchgeführt
- Fokus auf Prozessverbesserungen
- Dokumentierte Aktionspunkte

### 10.2 Metriken und KPIs
- Release-Zeitplan-Einhaltung
- Fehlerrate nach Release
- Release-Qualität (Kundenzufriedenheit)
- Hotfix-Rate pro Release

## Abhängigkeiten
- ZK-PROJ-v1.0-20250325: Projektübersicht
- ZK-TECH-v1.0-20250325: Technischer Designleitfaden
- ZK-TEST-v1.0-20250325: Teststrategie und QA-Prozesse