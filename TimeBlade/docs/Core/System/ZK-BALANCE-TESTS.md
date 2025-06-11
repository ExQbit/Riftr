# Zeitklingen: Balance-Testfälle

## Übersicht

Dieses Dokument definiert strukturierte Testfälle zur Validierung der implementierten Balance-Änderungen und Kern-Mechaniken. Jeder Testfall ist mit klaren Erwartungen, Durchführungsschritten und Erfolgskriterien dokumentiert.

## Testfall-Kategorien

### 1. Schildmacht-Verfall (Zeitwächter)

#### Test 1.1: Basis-Verfall nach Inaktivität
**Beschreibung**: Überprüfung des korrekten Schildmacht-Verfalls nach 3 Sekunden Inaktivität.

**Vorbedingungen**:
- Zeitwächter mit Schildmacht-Level 3
- Keine aktiven Kampfhandlungen

**Durchführung**:
1. Schildmacht auf 3 aufbauen (durch Block-Aktionen)
2. 3 Sekunden warten ohne Aktion
3. Schildmacht-Wert überprüfen
4. Weitere 3 Sekunden warten
5. Erneut Schildmacht-Wert überprüfen

**Erwartetes Ergebnis**:
- Nach 3s: Schildmacht = 2
- Nach 6s: Schildmacht = 1
- Nach 9s: Schildmacht = 0

**Erfolgskriterien**:
- Verfall beginnt exakt nach 3s Inaktivität
- Verfall erfolgt mit 1 Punkt pro 3 Sekunden
- UI aktualisiert sich sofort bei Verfall

---

#### Test 1.2: Verfall-Unterbrechung durch Block
**Beschreibung**: Verfall-Timer wird durch erfolgreichen Block zurückgesetzt.

**Vorbedingungen**:
- Zeitwächter mit Schildmacht-Level 2
- Aktiver Gegner vorhanden

**Durchführung**:
1. 2.5 Sekunden warten (kurz vor Verfall)
2. Erfolgreichen Block durchführen
3. Weitere 2.5 Sekunden warten
4. Schildmacht überprüfen

**Erwartetes Ergebnis**:
- Schildmacht bleibt bei 2 (kein Verfall)
- Timer wurde durch Block zurückgesetzt

**Erfolgskriterien**:
- Block unterbricht Verfall-Timer komplett
- Neuer 3s-Timer startet nach Block

---

#### Test 1.3: Soft-Cap bei hoher Schildmacht
**Beschreibung**: Validierung der Wirkungsreduktion bei Schildmacht > 3.

**Vorbedingungen**:
- Zeitwächter mit verschiedenen Schildmacht-Leveln
- Identische Verteidigungskarten

**Durchführung**:
1. Zeitkosten-Reduktion bei SM=1 messen (5%)
2. Zeitkosten-Reduktion bei SM=2 messen (10%)
3. Zeitkosten-Reduktion bei SM=3 messen (15%)
4. Zeitkosten-Reduktion bei SM=4 messen
5. Zeitkosten-Reduktion bei SM=5 messen

**Erwartetes Ergebnis**:
- SM 1-3: Lineare Skalierung (5%/10%/15%)
- SM 4: ~17.5% Reduktion (halbe Effektivität)
- SM 5: ~18.75% Reduktion (Viertel Effektivität)

**Erfolgskriterien**:
- Korrekte Soft-Cap-Berechnung
- UI zeigt reduzierte Effektivität an

---

### 2. Zeitkosten-Berechnungssystem

#### Test 2.1: Interne Präzision vs. UI-Rundung
**Beschreibung**: Überprüfung der korrekten Trennung zwischen internen und angezeigten Werten.

**Vorbedingungen**:
- Karten mit verschiedenen Basis-Zeitkosten
- Testfälle: 1.34s, 2.49s, 2.51s, 3.99s

**Durchführung**:
1. Karte mit 1.34s Basis-Zeitkosten prüfen
   - Haupt-UI-Anzeige notieren
   - Detailansicht öffnen
   - Präzisen Wert vergleichen
2. Für alle Testwerte wiederholen

**Erwartetes Ergebnis**:
| Interner Wert | UI-Anzeige | Detail-Anzeige |
|---------------|------------|----------------|
| 1.34s | 1.5s | 1.34s |
| 2.49s | 2.5s | 2.49s |
| 2.51s | 2.5s | 2.51s |
| 3.99s | 4.0s | 3.99s |

**Erfolgskriterien**:
- Korrekte Rundung auf 0.5s in Haupt-UI
- Präzise Werte in Detailansicht
- Konsistente Darstellung

---

#### Test 2.2: Prozentuale Modifikatoren
**Beschreibung**: Validierung der korrekten Anwendung klassenspezifischer Modifikatoren.

**Vorbedingungen**:
- Chronomant mit Arkanpuls > 0
- Zeit-Manipulationskarte mit 2.00s Basis-Kosten

**Durchführung**:
1. Basis-Zeitkosten ohne Modifikator prüfen
2. Mit 1 Arkanpuls: Zeitkosten prüfen
3. Berechnung verifizieren: 2.00s × 0.85 = 1.70s
4. UI-Rundung prüfen: 1.70s → 1.5s

**Erwartetes Ergebnis**:
- Interner Wert: 1.70s
- UI-Anzeige: 1.5s
- Modifikator-Anzeige: "-15% (Arkanpuls)"

**Erfolgskriterien**:
- Korrekte mathematische Berechnung
- Richtige Rundung für UI
- Klare Modifikator-Kennzeichnung

---

#### Test 2.3: Mehrfache Modifikatoren
**Beschreibung**: Test der Interaktion mehrerer gleichzeitiger Modifikatoren.

**Vorbedingungen**:
- Karte mit mehreren aktiven Effekten
- Z.B. Arkanpuls + Elementar-Synergie

**Durchführung**:
1. Einzelne Modifikatoren aktivieren
2. Kombinierte Wirkung messen
3. Berechnungsreihenfolge verifizieren

**Erwartetes Ergebnis**:
- Modifikatoren werden multiplikativ angewendet
- Beispiel: 2.00s × 0.85 × 0.90 = 1.53s

**Erfolgskriterien**:
- Korrekte Stapelungs-Logik
- Transparente Berechnung in Detailansicht

---

### 3. Chronomant Arkanpuls-Bonus

#### Test 3.1: Deterministischer Bonus bei 1 AP
**Beschreibung**: Validierung des konsistenten -15% Bonus bei genau 1 Arkanpuls.

**Vorbedingungen**:
- Chronomant mit verschiedenen AP-Leveln
- Zeit-Manipulationskarten

**Durchführung**:
1. Mit 0 AP: Keine Reduktion
2. Mit 1 AP: -15% Reduktion
3. Mit 2-5 AP: Andere Boni (falls implementiert)
4. 10 Durchläufe zur Konsistenz-Prüfung

**Erwartetes Ergebnis**:
- 0 AP: 0% Reduktion
- 1 AP: Immer exakt -15%
- Kein RNG bei 1 AP

**Erfolgskriterien**:
- 100% Konsistenz bei 1 AP
- Korrekte Kartentyp-Erkennung
- Sofortige UI-Aktualisierung

---

#### Test 3.2: Kartentyp-Validierung
**Beschreibung**: Nur Zeit-Manipulationskarten erhalten den Bonus.

**Vorbedingungen**:
- Verschiedene Kartentypen
- Chronomant mit 1 AP

**Durchführung**:
1. Zeit-Manipulationskarte testen → Bonus erwartet
2. Normale Angriffskarte testen → Kein Bonus
3. Verteidigungskarte testen → Kein Bonus
4. Elementarkarte testen → Kein Bonus

**Erwartetes Ergebnis**:
- Nur is_time_manipulation=true Karten erhalten Bonus

**Erfolgskriterien**:
- Korrekte Datenbank-Flag-Abfrage
- Keine falschen Bonus-Anwendungen

---

### 4. Starterdeck-Balance

#### Test 4.1: 12-Sekunden-Regel
**Beschreibung**: Überprüfung der Einhaltung der 12s-Gesamtkosten für Starterdecks.

**Vorbedingungen**:
- Neue Spieler aller 3 Klassen
- Standard-Starterdecks

**Durchführung**:
1. Chronomant-Starterdeck summieren
2. Zeitwächter-Starterdeck summieren
3. Schattenschreiter-Starterdeck summieren
4. Mit 12.0s ± 0.5s vergleichen

**Erwartetes Ergebnis**:
- Chronomant: 11.5s - 12.5s
- Zeitwächter: 11.5s - 12.5s
- Schattenschreiter: 11.5s - 12.5s

**Erfolgskriterien**:
- Alle Decks innerhalb der Toleranz
- Ausgewogene Kartenverteilung

---

#### Test 4.2: Erstes Spielgefühl
**Beschreibung**: Qualitative Tests für neue Spieler-Erfahrung.

**Vorbedingungen**:
- Test-Accounts ohne Progression
- Erster Kampf gegen Tutorial-Gegner

**Durchführung**:
1. Kampf mit Starterdeck durchführen
2. Mindestens 6-8 Karten spielbar in 60s
3. Klassenidentität spürbar
4. Sieg erreichbar

**Erwartetes Ergebnis**:
- Flüssiges Spielgefühl
- Keine Zeitknappheit
- Klare Klassenmechanik

**Erfolgskriterien**:
- 70%+ Siegrate im Tutorial
- Positive Spieler-Rückmeldung

---

### 5. Opportunity Costs

#### Test 5.1: Zeit-Kit-Verwendungsstrategie
**Beschreibung**: Validierung der optimalen Kit-Verwendung.

**Vorbedingungen**:
- 3 Zeit-Kits verfügbar
- Kerne mit verschiedenen Ladungen

**Durchführung**:
1. Auto-Empfehlung testen
2. Manuelle Verteilung testen
3. Effizienz vergleichen

**Erwartetes Ergebnis**:
- Auto-Empfehlung wählt niedrigste Ladungen
- Keine Verschwendung durch Überladung

**Erfolgskriterien**:
- Optimale Kit-Nutzung
- Klare UI-Empfehlungen

---

### 6. Performance-Tests

#### Test 6.1: Mobile Performance mit 0.01s Präzision
**Beschreibung**: Sicherstellung flüssiger Performance trotz erhöhter Berechnungen.

**Vorbedingungen**:
- Low-End Android Gerät (2GB RAM)
- 20+ aktive Karten mit Modifikatoren

**Durchführung**:
1. FPS während Kampf messen
2. UI-Reaktionszeit bei Kartenwechsel
3. Speicherverbrauch überwachen

**Erwartetes Ergebnis**:
- Stabile 30+ FPS
- <100ms UI-Reaktionszeit
- <150MB RAM-Nutzung

**Erfolgskriterien**:
- Keine spürbaren Lags
- Smooth Animations

---

### 7. Integrations-Tests

#### Test 7.1: Klassen-Synergie-Validierung
**Beschreibung**: Überprüfung der Interaktion aller Klassenmechaniken.

**Vorbedingungen**:
- Alle 3 Klassen auf Level 10+
- Verschiedene Kartenkombinationen

**Durchführung**:
1. Chronomant: AP-Aufbau → Zeit-Manipulation
2. Zeitwächter: SM-Aufbau → Verteidigung
3. Schattenschreiter: Momentum → Burst

**Erwartetes Ergebnis**:
- Jede Klasse hat einzigartige Spielmuster
- Keine Überlappungen oder Konflikte

**Erfolgskriterien**:
- Distinkte Klassenidentität
- Balancierte Stärken/Schwächen

---

## Test-Ausführungsplan

### Phase 1: Unit-Tests (Automatisiert)
- Mathematische Berechnungen
- Datenbank-Constraints
- API-Funktionen

### Phase 2: Integrations-Tests (Semi-Automatisiert)
- Klassen-Interaktionen
- Material-Flüsse
- Progression-Systeme

### Phase 3: Gameplay-Tests (Manuell)
- Spielgefühl
- Balance-Validierung
- Performance auf Zielgeräten

### Phase 4: A/B-Tests (Live)
- Drop-Raten-Optimierung
- Progression-Geschwindigkeit
- Monetarisierungs-Balance

## Metriken & Erfolgskriterien

### Quantitative Metriken
- **Schildmacht-Nutzung**: >60% der Zeitwächter nutzen aktiv
- **Arkanpuls-Aktivierung**: >70% der Chronomanten bei 1 AP
- **Zeitkosten-Präzision**: 0% Rundungsfehler
- **Performance**: <5% Frame-Drops auf Zielgeräten

### Qualitative Metriken
- **Spieler-Feedback**: "Klassen fühlen sich einzigartig an"
- **Progression**: "Fortschritt ist spürbar und fair"
- **Monetarisierung**: "Premium beschleunigt, dominiert nicht"

## Dokumentations-Updates

Nach jedem Test-Zyklus:
1. Ergebnisse in Test-Report dokumentieren
2. Balance-Anpassungen in GDD übertragen
3. Neue Edge-Cases als Tests hinzufügen
4. Performance-Benchmarks aktualisieren

---

**Version**: 1.0  
**Letzte Aktualisierung**: [Aktuelles Datum]  
**Nächster Review**: Nach Phase 1 Unit-Tests
