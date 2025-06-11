# Zeitklingen: Tagesquest-Pool - Erkundungsquests (v1.0-20250520)

## Inhaltsverzeichnis
1. [Einführung und Übersicht](#1-einführung-und-übersicht)
2. [Entdeckungs-Quests](#2-entdeckungs-quests)
3. [Sammlungs-Quests](#3-sammlungs-quests)
4. [Untersuchungs-Quests](#4-untersuchungs-quests)
5. [Zeitanomalien-Quests](#5-zeitanomalien-quests)
6. [Weltspezifische Quests](#6-weltspezifische-quests)
7. [Quest-Rotation und Gewichtungen](#7-quest-rotation-und-gewichtungen)

---

## 1. Einführung und Übersicht

Dieses Dokument enthält den vollständigen Satz erkundungsbezogener Tagesquests für das Mo.Co-adaptierte Progressionssystem von Zeitklingen. Diese Quests bilden etwa 30% des gesamten Tagesquest-Pools und fokussieren sich auf Exploration, Sammlung und Interaktion mit der Spielwelt, wobei sie Zeit-Kerne als Hauptbelohnung anbieten.

### 1.1 Quest-Struktur

Jede Quest wird mit folgenden Elementen definiert:
- **ID**: Eindeutiger Identifikator für Datenbank-Referenz
- **Name**: Kurzer, einprägsamer Titel der Quest
- **Beschreibung**: Detaillierte Aufgabenbeschreibung
- **Schwierigkeit**: Standard, Herausfordernd oder Elite
- **Anforderungen**: Spezifische Bedingungen für den Abschluss
- **Kern-Vergabe**: Prozentwert der Zeit-Kern-Aufladung
- **Belohnungen**: Zusätzliche Belohnungen neben Kern-Aufladung
- **Welt-Beschränkung**: Falls die Quest nur in bestimmten Welten verfügbar ist
- **Rotationsgewichtung**: Wahrscheinlichkeit des Erscheinens im täglichen Pool

### 1.2 Kern-Vergabe

Die Kern-Vergabe für erkundungsbezogene Quests folgt diesen Richtlinien:
- **Standard**: 7% Kern-Aufladung (höher als Kampf-Quests)
- **Herausfordernd**: 10% Kern-Aufladung
- **Elite**: 15% Kern-Aufladung
- **Multiplikator**: Welt 1: 1.0×, Welt 2: 1.2×, Welt 3: 1.5×, Welt 4: 1.8×, Welt 5: 2.0×

---

## 2. Entdeckungs-Quests

### 2.1 Neue Gebiete

#### QUEST-E-001: Chronokartograph
- **Name**: Chronokartograph
- **Beschreibung**: "Um die Zeitströme zu verwalten, müssen wir sie erst kennen." - Erzchronistin Lyra. Entdecke und kartiere 3 neue Zonen in der aktuellen Welt und trage zur großen Chronikkarte des Zeitrates bei.
- **Schwierigkeit**: Standard
- **Anforderungen**: 3 neue Zonen entdecken
- **Kern-Vergabe**: 7%
- **Belohnungen**: 3× Zeitfragment
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (25%)

#### QUEST-E-002: Zeitpfadfinder
- **Name**: Zeitpfadfinder
- **Beschreibung**: Zwischen den bekannten Zeitwegen existieren verborgene Pfade, die nur jene mit scharfer Wahrnehmung entdecken können. Die Schattenschreiter-Gilde sucht nach solchen Pfaden in den Nebelreichen. Finde 2 versteckte Pfade in der aktuellen Welt.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 2 versteckte Pfade entdecken
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Splitter (50% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-003: Chronometriker
- **Name**: Chronometriker
- **Beschreibung**: Die Chronometriker-Bruderschaft hat Temporal-Anomalien in den Zersplitterten Landen registriert - Bereiche, in denen die Zeit anders fließt. Entdecke einen dieser zeitlich verschobenen Bereiche und berichte der Bruderschaft über deine Funde.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Zeitverschiebungsbereich entdecken
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Kristall (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-E-004: Weltenwanderer
- **Name**: Weltenwanderer
- **Beschreibung**: Besuche 5 verschiedene Zonen in einer beliebigen Welt.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 verschiedene Zonen besuchen
- **Kern-Vergabe**: 7%
- **Belohnungen**: 2× COM Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-E-005: Dimensionsreisender
- **Name**: Dimensionsreisender
- **Beschreibung**: Seit dem Großen Zeitbruch in der Chrono-Wüste sind temporale Portale entstanden, die zu alternativen Zeitlinien führen. Der Zeitrat benötigt Informationen über diese Parallelwelten. Reise durch ein temporales Portal und erforsche das dahinterliegende Gebiet.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 temporales Portal nutzen
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× UNC Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Mittel (15%)

### 2.2 Landmarken und Strukturen

#### QUEST-E-006: Turm der Zeit
- **Name**: Turm der Zeit
- **Beschreibung**: Finde und erklimme einen Zeitturm.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Zeitturm erklimmen
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Splitter (75% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-007: Ruinenkundler
- **Name**: Ruinenkundler
- **Beschreibung**: Erforsche eine antike Zeitruine vollständig.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Ruine vollständig erkunden
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Kristall (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-E-008: Schreinentdecker
- **Name**: Schreinentdecker
- **Beschreibung**: Finde 3 Zeitschreine und aktiviere sie.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 Zeitschreine aktivieren
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Splitter (100% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-009: Höhlenerkunder
- **Name**: Höhlenerkunder
- **Beschreibung**: Erforsche 2 Höhlen und finde ihre versteckten Schätze.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 2 Höhlen vollständig erkunden
- **Kern-Vergabe**: 10%
- **Belohnungen**: 2× UNC Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-010: Monument der Ewigkeit
- **Name**: Monument der Ewigkeit
- **Beschreibung**: Finde und aktiviere ein antikes Zeitmonument.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Zeitmonument aktivieren
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Kristall (75% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

---

## 3. Sammlungs-Quests

### 3.1 Materialsammlung

#### QUEST-E-011: Zeitfragmentjäger
- **Name**: Zeitfragmentjäger
- **Beschreibung**: Sammle 15 Zeitfragmente in der Welt.
- **Schwierigkeit**: Standard
- **Anforderungen**: 15 Zeitfragmente sammeln
- **Kern-Vergabe**: 7%
- **Belohnungen**: 5× Zeitfragment
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (25%)

#### QUEST-E-012: Elementarsammler
- **Name**: Elementarsammler
- **Beschreibung**: Sammle 10 elementare Materialien (Feuer, Eis oder Blitz).
- **Schwierigkeit**: Standard
- **Anforderungen**: 10 Elementarmaterialien
- **Kern-Vergabe**: 7%
- **Belohnungen**: 3× COM Elementarmaterial (entsprechend)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-E-013: Kristallsucher
- **Name**: Kristallsucher
- **Beschreibung**: Finde 5 Zeitkristalle in Höhlen oder versteckten Bereichen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5 Zeitkristalle finden
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Kristall (25% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-014: Essenzextraktor
- **Name**: Essenzextraktor
- **Beschreibung**: Extrahiere Zeitessenz aus 3 Zeitquellen.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 Zeitquellen anzapfen
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-E-015: Seltenheitssucher
- **Name**: Seltenheitssucher
- **Beschreibung**: Finde ein seltenes Element-Artefakt in der Welt.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 seltenes Artefakt finden
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× RAR Elementarmaterial (entsprechend)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (10%)

### 3.2 Spezielle Sammlungen

#### QUEST-E-016: Echo-Sammler
- **Name**: Echo-Sammler
- **Beschreibung**: Sammle 5 zeitliche Echos von vergangenen Ereignissen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5 Zeitechos sammeln
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Splitter (75% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-017: Schriftensammler
- **Name**: Schriftensammler
- **Beschreibung**: Finde 3 verlorene Zeitschriften in der Welt.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 Zeitschriften finden
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Kit
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-018: Karten-Archäologe
- **Name**: Karten-Archäologe
- **Beschreibung**: Finde 1 verlorenes Kartenfragment in einer Ruine.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Kartenfragment finden
- **Kern-Vergabe**: 15%
- **Belohnungen**: Zusätzliche Versuche für Kartenziehung
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-E-019: Artefaktsucher
- **Name**: Artefaktsucher
- **Beschreibung**: Sammle die 3 Teile eines antiken Artefakts.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 Artefaktteile sammeln
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× EPI Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-E-020: Sternenfragment-Sucher
- **Name**: Sternenfragment-Sucher
- **Beschreibung**: Finde 1 kosmisches Zeitfragment, das nachts leuchtet.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 kosmisches Fragment finden
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 4. Untersuchungs-Quests

### 4.1 Zeitanomalien-Untersuchung

#### QUEST-E-021: Zeitriss-Inspektor
- **Name**: Zeitriss-Inspektor
- **Beschreibung**: Untersuche 3 temporale Risse in der Welt.
- **Schwierigkeit**: Standard
- **Anforderungen**: 3 Zeitrisse untersuchen
- **Kern-Vergabe**: 7%
- **Belohnungen**: 1× Zeit-Splitter (25% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-E-022: Anomalie-Analyst
- **Name**: Anomalie-Analyst
- **Beschreibung**: Analysiere das Verhalten einer instabilen Zeitanomalie.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 instabile Anomalie analysieren
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Splitter (100% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-023: Zeitparadox-Erforscher
- **Name**: Zeitparadox-Erforscher
- **Beschreibung**: Finde und löse ein temporales Paradoxon in der Welt.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Zeitparadoxon lösen
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Kristall (75% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-E-024: Echo-Horcher
- **Name**: Echo-Horcher
- **Beschreibung**: Höre 5 zeitlichen Echos zu und dokumentiere sie.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Zeitechos anhören
- **Kern-Vergabe**: 7%
- **Belohnungen**: 3× Zeitfragment
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-E-025: Vergangenheitsforscher
- **Name**: Vergangenheitsforscher
- **Beschreibung**: Rekonstruiere ein vergangenes Ereignis durch die Untersuchung von Zeitfragmenten.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Ereignis rekonstruieren
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Kristall (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Mittel (15%)

### 4.2 Historische Untersuchungen

#### QUEST-E-026: Zeitzeuge
- **Name**: Zeitzeuge
- **Beschreibung**: Finde und interagiere mit einem zeitlichen Geist, der Wissen aus der Vergangenheit teilt.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Zeitgeist befragen
- **Kern-Vergabe**: 10%
- **Belohnungen**: 2× UNC Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-027: Chronik-Archivar
- **Name**: Chronik-Archivar
- **Beschreibung**: Vervollständige einen Eintrag in der Weltchronik durch Sammlung historischer Daten.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Chronik-Eintrag vervollständigen
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Kit
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-028: Epochen-Beobachter
- **Name**: Epochen-Beobachter
- **Beschreibung**: Beobachte aus sicherer Entfernung ein historisches Ereignis durch einen Zeitspalt.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 historisches Ereignis beobachten
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Kristall (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-E-029: Dokumentarforscher
- **Name**: Dokumentarforscher
- **Beschreibung**: Rekonstruiere einen vergangenen Tag einer wichtigen historischen Figur.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 historischen Tag rekonstruieren
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-E-030: Wahrheitssucher
- **Name**: Wahrheitssucher
- **Beschreibung**: Decke die wahre Geschichte hinter einem verfälschten historischen Ereignis auf.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 historisches Geheimnis aufdecken
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 5. Zeitanomalien-Quests

### 5.1 Zeitriss-Interaktionen

#### QUEST-E-031: Riss-Stabilisierer
- **Name**: Riss-Stabilisierer
- **Beschreibung**: Stabilisiere 3 instabile Zeitrisse, bevor sie kollabieren.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 Zeitrisse stabilisieren
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Splitter (100% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-032: Dimensionsflicker
- **Name**: Dimensionsflicker
- **Beschreibung**: Überquere die Grenzen zweier überlappender Zeitströme.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 2 Zeitströme überqueren
- **Kern-Vergabe**: 10%
- **Belohnungen**: 2× UNC Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-033: Zeitanomalie-Bändiger
- **Name**: Zeitanomalie-Bändiger
- **Beschreibung**: Neutralisiere eine kritische Zeitanomalie, bevor sie expandiert.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 kritische Anomalie neutralisieren
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Kristall (75% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-E-034: Zeitbrücken-Konstrukteur
- **Name**: Zeitbrücken-Konstrukteur
- **Beschreibung**: Erschaffe eine stabile Brücke zwischen zwei getrennten Zeitperioden.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Zeitbrücke konstruieren
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-E-035: Chrono-Ingenieur
- **Name**: Chrono-Ingenieur
- **Beschreibung**: Repariere einen defekten Zeitfluss-Regulator.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Regulator reparieren
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× RAR Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

### 5.2 Zeitliche Phänomene

#### QUEST-E-036: Zeit-Beobachter
- **Name**: Zeit-Beobachter
- **Beschreibung**: Beobachte und dokumentiere 5 verschiedene zeitliche Phänomene in der Welt.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Phänomene dokumentieren
- **Kern-Vergabe**: 7%
- **Belohnungen**: 5× Zeitfragment
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-E-037: Zeitfluss-Messer
- **Name**: Zeitfluss-Messer
- **Beschreibung**: Messe und dokumentiere Zeitflussverzerrungen an 3 verschiedenen Orten.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 Messungen durchführen
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Splitter (75% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-038: Chrono-Botaniker
- **Name**: Chrono-Botaniker
- **Beschreibung**: Sammle Proben von 3 Pflanzen, die in anomalen Zeitzonen wachsen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 Zeitpflanzen-Proben sammeln
- **Kern-Vergabe**: 10%
- **Belohnungen**: 2× UNC Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-E-039: Temporaler Zoologe
- **Name**: Temporaler Zoologe
- **Beschreibung**: Beobachte und dokumentiere das Verhalten eines zeitmutierenden Wesens.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Zeitwesen beobachten
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Kristall (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-E-040: Zeitwirbel-Segler
- **Name**: Zeitwirbel-Segler
- **Beschreibung**: Durchquere einen temporalen Wirbelsturm und überlebe.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Zeitwirbel durchqueren
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 6. Weltspezifische Quests

### 6.1 Welt 1: Nebelreiche

#### QUEST-E-041: Nebelläufer
- **Name**: Nebelläufer
- **Beschreibung**: Durchquere drei Bereiche dichter Zeitnebel in den Nebelreichen.
- **Schwierigkeit**: Standard
- **Anforderungen**: 3 Nebelbereiche durchqueren
- **Kern-Vergabe**: 7%
- **Belohnungen**: 3× Zeitfragment
- **Welt-Beschränkung**: Nur Welt 1
- **Rotationsgewichtung**: Hoch (25%, wenn in Welt 1)

#### QUEST-E-042: Nebelchronist
- **Name**: Nebelchronist
- **Beschreibung**: Sammle die verstreuten Seiten eines Nebelchronik-Bandes.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5 Chronikseiten finden
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Splitter (75% Aufladung)
- **Welt-Beschränkung**: Nur Welt 1
- **Rotationsgewichtung**: Mittel (15%, wenn in Welt 1)

### 6.2 Welt 2: Zersplitterte Lande

#### QUEST-E-043: Fragment-Restaurator
- **Name**: Fragment-Restaurator
- **Beschreibung**: Stelle die Verbindung zwischen zwei zersplitterten Landmassen wieder her.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Landverbindung herstellen
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Kristall (25% Aufladung)
- **Welt-Beschränkung**: Nur Welt 2
- **Rotationsgewichtung**: Hoch (25%, wenn in Welt 2)

#### QUEST-E-044: Brückenläufer
- **Name**: Brückenläufer
- **Beschreibung**: Überquere 5 temporale Brücken in den Zersplitterten Landen, ohne zu fallen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5 Brücken überqueren
- **Kern-Vergabe**: 10%
- **Belohnungen**: 2× UNC Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Nur Welt 2
- **Rotationsgewichtung**: Mittel (15%, wenn in Welt 2)

### 6.3 Welt 3: Chrono-Wüste

#### QUEST-E-045: Sandsturm-Durchquerer
- **Name**: Sandsturm-Durchquerer
- **Beschreibung**: Überlebe einen temporalen Sandsturm in der Chrono-Wüste.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Sandsturm überstehen
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Zeit-Kristall (50% Aufladung)
- **Welt-Beschränkung**: Nur Welt 3
- **Rotationsgewichtung**: Hoch (25%, wenn in Welt 3)

#### QUEST-E-046: Oasensucher
- **Name**: Oasensucher
- **Beschreibung**: Finde eine versteckte Zeitoase in der Chrono-Wüste.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Zeitoase finden
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (25% Aufladung)
- **Welt-Beschränkung**: Nur Welt 3
- **Rotationsgewichtung**: Mittel (15%, wenn in Welt 3)

### 6.4 Welt 4: Uhrwerkriese

#### QUEST-E-047: Zahnrad-Mechaniker
- **Name**: Zahnrad-Mechaniker
- **Beschreibung**: Repariere einen defekten Zahnradmechanismus im Uhrwerkriesen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Mechanismus reparieren
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× RAR Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Nur Welt 4
- **Rotationsgewichtung**: Hoch (25%, wenn in Welt 4)

#### QUEST-E-048: Pendelkletterer
- **Name**: Pendelkletterer
- **Beschreibung**: Erklimme das Große Pendel des Uhrwerkriesen.
- **Schwierigkeit**: Elite
- **Anforderungen**: Pendel erklimmen
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (50% Aufladung)
- **Welt-Beschränkung**: Nur Welt 4
- **Rotationsgewichtung**: Mittel (15%, wenn in Welt 4)

### 6.5 Welt 5: Ewige Schleife

#### QUEST-E-049: Schleifenbrecher
- **Name**: Schleifenbrecher
- **Beschreibung**: Durchbrich eine temporale Kausalkette in der Ewigen Schleife.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Kausalkette durchbrechen
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (75% Aufladung)
- **Welt-Beschränkung**: Nur Welt 5
- **Rotationsgewichtung**: Hoch (25%, wenn in Welt 5)

#### QUEST-E-050: Ewigkeitspilger
- **Name**: Ewigkeitspilger
- **Beschreibung**: Besuche alle 5 Ewigkeitsschreine in der Ewigen Schleife.
- **Schwierigkeit**: Elite
- **Anforderungen**: 5 Schreine besuchen
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× EPI Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Nur Welt 5
- **Rotationsgewichtung**: Mittel (15%, wenn in Welt 5)

---

## 7. Quest-Rotation und Gewichtungen

### 7.1 Tägliche Verteilung

Die tägliche Verteilung der Erkundungsquests folgt diesen Richtlinien:
- **Gesamtanteil**: 30% des täglichen Quest-Pools (3 von 10 Quests pro Tag)
- **Schwierigkeitsverteilung**: 1× Standard, 1× Herausfordernd, 1× Elite
- **Weltspezifische Quoten**: Mindestens 1 Quest muss der aktuellen Spielerwelt entsprechen

### 7.2 Rotationsregeln

Folgende Regeln werden für die Rotation von Erkundungsquests angewendet:
- **Abkühlzeit**: Eine spezifische Quest erscheint frühestens wieder nach 5 Tagen
- **Variation**: Innerhalb einer Woche sollten keine Quest-Typen (Entdeckung, Sammlung, etc.) doppelt erscheinen
- **Priorisierung**: Quests mit höherer Rotationsgewichtung werden bevorzugt ausgewählt

### 7.3 Gewichtungs-Modifier

Die Basis-Rotationsgewichtung kann durch folgende Faktoren modifiziert werden:
- **Spieler-Fortschritt**: +5% für nicht abgeschlossene Quest-Linien
- **Saisonale Events**: +10% für event-relevante Erkundungsquests
- **Welt-Relevanz**: +15% für Quests, die zur aktuellen Story-Progression passen

### 7.4 Seltene Elite-Quests

Bestimmte Elite-Quests haben eine sehr niedrige Rotationsgewichtung (5%), sind aber besonders wertvoll:
- Erscheinen garantiert mindestens 1× pro Monat
- Bieten die wertvollsten Belohnungen im Erkundungsquest-Pool
- Können als "Featured Quest" mit visueller Hervorhebung markiert werden