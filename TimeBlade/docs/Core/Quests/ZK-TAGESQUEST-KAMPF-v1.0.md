# Zeitklingen: Tagesquest-Pool - Kampfbezogene Quests (v1.0-20250520)

## Inhaltsverzeichnis
1. [Einführung und Übersicht](#1-einführung-und-übersicht)
2. [Standardkampf-Quests](#2-standardkampf-quests)
3. [Elite-Gegner-Quests](#3-elite-gegner-quests)
4. [Boss-Quests](#4-boss-quests)
5. [Elementar-Kampf-Quests](#5-elementar-kampf-quests)
6. [Klassenspezialisierte Kampf-Quests](#6-klassenspezialisierte-kampf-quests)
7. [Quest-Rotation und Gewichtungen](#7-quest-rotation-und-gewichtungen)

---

## 1. Einführung und Übersicht

Dieses Dokument enthält den vollständigen Satz kampfbezogener Tagesquests für das Mo.Co-adaptierte Progressionssystem von Zeitklingen. Diese Quests bilden etwa 40% des gesamten Tagesquest-Pools und fokussieren sich auf Kampfherausforderungen unterschiedlicher Schwierigkeitsgrade. Sie sind darauf ausgerichtet, Spieler zur Verwendung verschiedener Decks und Strategien zu motivieren, während sie Zeit-Kerne akkumulieren.

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

Die Kern-Vergabe für kampfbezogene Quests folgt diesen Richtlinien:
- **Standard**: 5% Kern-Aufladung
- **Herausfordernd**: 8% Kern-Aufladung
- **Elite**: 12% Kern-Aufladung
- **Element-Fokus**: +3% für entsprechende Elementar-Kerne
- **Multiplikator**: Welt 1: 1.0×, Welt 2: 1.2×, Welt 3: 1.5×, Welt 4: 1.8×, Welt 5: 2.0×

---

## 2. Standardkampf-Quests

### 2.1 Grundlegende Kampf-Quests

#### QUEST-K-001: Zeitwächter-Patrouille
- **Name**: Zeitwächter-Patrouille
- **Beschreibung**: Als Verteidiger der Zeitlinien ist es deine Pflicht, die Stabilität zu wahren. Besiege 10 Gegner in beliebigen Bereichen von Welt 1 oder höher.
- **Schwierigkeit**: Standard
- **Anforderungen**: 10 Gegner besiegen
- **Kern-Vergabe**: 5%
- **Belohnungen**: 25 Zeitfragmente
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (25%)

#### QUEST-K-002: Meister der Zeitklingen
- **Name**: Meister der Zeitklingen
- **Beschreibung**: Die Kraft der Zeitklingen liegt in der Präzision. Besiege 5 Gegner mit Angriffsschaden von mindestens 50, um deine Beherrschung der Klingenmanipulation zu beweisen.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Gegner mit min. 50 Angriffsschaden besiegen
- **Kern-Vergabe**: 5%
- **Belohnungen**: 1× COM Waffenmaterial
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-003: Defensor Temporis
- **Name**: Defensor Temporis
- **Beschreibung**: Die Chronomeister lehren: "Wer die Zeit selbst beschützt, muss auch sich zu schützen wissen." Blocke 15 Angriffe mit Verteidigungskarten und beweise deine Schutzfähigkeiten.
- **Schwierigkeit**: Standard
- **Anforderungen**: 15 Angriffe blocken
- **Kern-Vergabe**: 5%
- **Belohnungen**: 1× COM Rüstungsmaterial
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-004: Zeitdieb
- **Name**: Zeitdieb
- **Beschreibung**: Die subtile Kunst des Zeitdiebstahls ist eine mächtige Fähigkeit der Schattenschreiter. Stehle insgesamt 10 Sekunden von Gegnern während deiner Kämpfe in den Nebelreichen.
- **Schwierigkeit**: Standard
- **Anforderungen**: 10s Zeitdiebstahl akkumulieren
- **Kern-Vergabe**: 5%
- **Belohnungen**: 2× Zeitfragment
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-005: Temporale Effizienz
- **Name**: Temporale Effizienz
- **Beschreibung**: "Zeit ist die kostbarste Ressource im Multiversum" - Erzchronomant Vaethus. Beweise dein temporales Gespür, indem du 3 Kämpfe mit mindestens 20 Sekunden Restzeit abschließt.
- **Schwierigkeit**: Standard
- **Anforderungen**: 3 Kämpfe mit 20s+ Restzeit
- **Kern-Vergabe**: 5%
- **Belohnungen**: 3× Zeitfragment
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

### 2.2 Herausfordernde Kampf-Quests

#### QUEST-K-006: Zeitlose Präzision
- **Name**: Zeitlose Präzision
- **Beschreibung**: Erziele 5 kritische Treffer in einem einzigen Kampf.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5 kritische Treffer in 1 Kampf
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Zeitfragment
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-K-007: Perfektes Timing
- **Name**: Perfektes Timing
- **Beschreibung**: Besiege 3 Gegner, ohne Schaden zu nehmen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 perfekte Siege
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× Zeit-Splitter (25% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-K-008: Kombo-Experte
- **Name**: Kombo-Experte
- **Beschreibung**: Spiele 3 Karten desselben Elements in Folge in einem Kampf.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3er Element-Kombo in 1 Kampf
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-009: DoT-Meister
- **Name**: DoT-Meister
- **Beschreibung**: Verursache 200 Schaden durch DoT-Effekte.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 200 akkumulierter DoT-Schaden
- **Kern-Vergabe**: 8%
- **Belohnungen**: 2× UNC Zeitfragment
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-K-010: Zeit-Rückgewinner
- **Name**: Zeit-Rückgewinner
- **Beschreibung**: Gewinne insgesamt 30 Sekunden durch Zeit-Rückgewinnungskarten zurück.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 30s Zeitgewinn akkumulieren
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× Zeit-Splitter (50% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

### 2.3 Elite Kampf-Quests

#### QUEST-K-011: Zeitstrom-Beherrscher
- **Name**: Zeitstrom-Beherrscher
- **Beschreibung**: Spiele 50 Karten in einem einzigen Kampf.
- **Schwierigkeit**: Elite
- **Anforderungen**: 50 Karten in 1 Kampf spielen
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (25% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-K-012: Temporale Überlegenheit
- **Name**: Temporale Überlegenheit
- **Beschreibung**: Besiege einen Gegner, der mindestens 3 Level über dir ist.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Gegner besiegen (Level +3)
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (8%)

#### QUEST-K-013: Chronoschock
- **Name**: Chronoschock
- **Beschreibung**: Füge 500 Schaden in einem einzigen Kampf zu.
- **Schwierigkeit**: Elite
- **Anforderungen**: 500 Schaden in 1 Kampf
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× RAR Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (8%)

#### QUEST-K-014: Zeit-Antagonist
- **Name**: Zeit-Antagonist
- **Beschreibung**: Besiege 3 Elite-Gegner mit mehr als 40 Sekunden Restzeit.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 Elite-Gegner mit 40s+ Restzeit
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (75% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-K-015: Chronische Ausdauer
- **Name**: Chronische Ausdauer
- **Beschreibung**: Überlebe 90 Sekunden in einem Kampf mit einem Mini-Boss.
- **Schwierigkeit**: Elite
- **Anforderungen**: 90s gegen Mini-Boss überleben
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (10% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 3. Elite-Gegner-Quests

### 3.1 Elite-Gegner Jagd

#### QUEST-K-016: Elite-Bereinigung
- **Name**: Elite-Bereinigung
- **Beschreibung**: Dem Zeitrat wurde berichtet, dass Zeitanomalien in Form von Elite-Gegnern die Stabilität der Zeitlinien bedrohen. Besiege 5 Elite-Gegner, um das Gleichgewicht zu bewahren.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Elite-Gegner besiegen
- **Kern-Vergabe**: 5%
- **Belohnungen**: 1× Zeit-Splitter (25% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-K-017: Zeitwächter-Instinkt
- **Name**: Zeitwächter-Instinkt
- **Beschreibung**: Die Chronomantengilde beobachtet, wie die Spezialfähigkeiten der Elite-Zeitanomalien immer stärker werden. Perfektioniere deinen Zeitwächter-Instinkt, indem du 3 Elite-Gegner besiegst, ohne von ihren Spezialfähigkeiten getroffen zu werden.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 Elite-Gegner ohne Spezialangriff-Treffer
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× Zeit-Kristall (25% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-K-018: Elite-Entthroner
- **Name**: Elite-Entthroner
- **Beschreibung**: In den Chroniken der Zeitfestung wird von Kriegern berichtet, die einen Zeitriss mit einem einzigen, perfekt ausgerichteten Schlag schließen konnten. Zeige ähnliche Effizienz, indem du einen Elite-Gegner in weniger als 20 Sekunden besiegst.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Elite-Gegner in unter 20s
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-K-019: Zeitraffer-Technik
- **Name**: Zeitraffer-Technik
- **Beschreibung**: Besiege 3 Elite-Gegner mit demselben Element.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 Elite-Gegner mit gleichem Element
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Elementarmaterial (entsprechend)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-020: Chrono-Vorherrschaft
- **Name**: Chrono-Vorherrschaft
- **Beschreibung**: Besiege 10 Elite-Gegner.
- **Schwierigkeit**: Elite
- **Anforderungen**: 10 Elite-Gegner besiegen
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (100% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (8%)

### 3.2 Mini-Boss-Quests

#### QUEST-K-021: Mini-Boss-Herausforderer
- **Name**: Mini-Boss-Herausforderer
- **Beschreibung**: Besiege 1 Mini-Boss.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Mini-Boss besiegen
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× Zeit-Splitter (100% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-K-022: Bosslose Zeit
- **Name**: Bosslose Zeit
- **Beschreibung**: Besiege 3 Mini-Bosse.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 Mini-Bosse besiegen
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (75% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-023: Zeitlose Präzision
- **Name**: Zeitlose Präzision
- **Beschreibung**: Besiege einen Mini-Boss, ohne von seinen Standard-Angriffen getroffen zu werden.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Mini-Boss ohne Standardtreffer
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (8%)

#### QUEST-K-024: Zeitfresser-Bezwinger
- **Name**: Zeitfresser-Bezwinger
- **Beschreibung**: Besiege einen Mini-Boss mit mehr als 30 Sekunden Restzeit.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Mini-Boss mit 30s+ Restzeit
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-K-025: Klassisch geschult
- **Name**: Klassisch geschult
- **Beschreibung**: Besiege einen Mini-Boss ohne Evolutionskarten.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Mini-Boss ohne Evo-Karten
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kit
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

---

## 4. Boss-Quests

### 4.1 Dungeon-Boss-Quests

#### QUEST-K-026: Zeit-Herrscher
- **Name**: Zeit-Herrscher
- **Beschreibung**: Besiege 1 Dungeon-Boss.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Dungeon-Boss besiegen
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (100% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-K-027: Zeitoptimierer
- **Name**: Zeitoptimierer
- **Beschreibung**: Besiege einen Dungeon-Boss in unter 45 Sekunden.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Dungeon-Boss in unter 45s
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (50% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-K-028: Wahrer Zeit-Beherrscher
- **Name**: Wahrer Zeit-Beherrscher
- **Beschreibung**: Besiege einen Dungeon-Boss, ohne von seinen Spezialfähigkeiten getroffen zu werden.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Dungeon-Boss ohne Spezialangriff-Treffer
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (75% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-K-029: Boss-Rush
- **Name**: Boss-Rush
- **Beschreibung**: Besiege 3 Dungeon-Bosse an einem Tag.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 Dungeon-Bosse besiegen
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (100% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-K-030: Perfekte Zeit
- **Name**: Perfekte Zeit
- **Beschreibung**: Besiege einen Dungeon-Boss mit mehr als 40 Sekunden Restzeit.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Dungeon-Boss mit 40s+ Restzeit
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kern (10% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (3%)

---

## 5. Elementar-Kampf-Quests

### 5.1 Feuer-Quests

#### QUEST-K-031: Feuerbringer
- **Name**: Feuerbringer
- **Beschreibung**: Verursache 300 Feuerschaden an Gegnern.
- **Schwierigkeit**: Standard
- **Anforderungen**: 300 Feuerschaden zufügen
- **Kern-Vergabe**: 5% (Neutral) + 3% (Feuer)
- **Belohnungen**: 1× Feuer-COM
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-032: Inferno-Entfacher
- **Name**: Inferno-Entfacher
- **Beschreibung**: Besiege 5 Eis-Gegner mit Feuerkarten.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5 Eis-Gegner mit Feuer-Element
- **Kern-Vergabe**: 8% (Neutral) + 3% (Feuer)
- **Belohnungen**: 1× Feuer-UNC
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-033: Vulkanischer Zorn
- **Name**: Vulkanischer Zorn
- **Beschreibung**: Verursache mit einer einzigen Feuerkarte mindestens 100 Schaden.
- **Schwierigkeit**: Elite
- **Anforderungen**: 100+ Schaden mit 1 Feuerkarte
- **Kern-Vergabe**: 12% (Neutral) + 3% (Feuer)
- **Belohnungen**: 1× Feuer-RAR
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (8%)

### 5.2 Eis-Quests

#### QUEST-K-034: Frostwächter
- **Name**: Frostwächter
- **Beschreibung**: Verursache 300 Eisschaden an Gegnern.
- **Schwierigkeit**: Standard
- **Anforderungen**: 300 Eisschaden zufügen
- **Kern-Vergabe**: 5% (Neutral) + 3% (Eis)
- **Belohnungen**: 1× Eis-COM
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-035: Eisbrecher
- **Name**: Eisbrecher
- **Beschreibung**: Besiege 5 Feuer-Gegner mit Eiskarten.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5 Feuer-Gegner mit Eis-Element
- **Kern-Vergabe**: 8% (Neutral) + 3% (Eis)
- **Belohnungen**: 1× Eis-UNC
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-036: Absolute Null
- **Name**: Absolute Null
- **Beschreibung**: Friere Gegner für insgesamt 15 Sekunden ein.
- **Schwierigkeit**: Elite
- **Anforderungen**: 15s akkumulierte Einfrierzeit
- **Kern-Vergabe**: 12% (Neutral) + 3% (Eis)
- **Belohnungen**: 1× Eis-RAR
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (8%)

### 5.3 Blitz-Quests

#### QUEST-K-037: Sturmrufer
- **Name**: Sturmrufer
- **Beschreibung**: Verursache 300 Blitzschaden an Gegnern.
- **Schwierigkeit**: Standard
- **Anforderungen**: 300 Blitzschaden zufügen
- **Kern-Vergabe**: 5% (Neutral) + 3% (Blitz)
- **Belohnungen**: 1× Blitz-COM
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-038: Kettenschlag
- **Name**: Kettenschlag
- **Beschreibung**: Treffe 10 Gegner mit Kettenblitz-Effekten.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 10 Kettenblitz-Treffer
- **Kern-Vergabe**: 8% (Neutral) + 3% (Blitz)
- **Belohnungen**: 1× Blitz-UNC
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-039: Zeitblitz
- **Name**: Zeitblitz
- **Beschreibung**: Besiege einen Gegner mit einem kritischen Blitztreffer von über 150 Schaden.
- **Schwierigkeit**: Elite
- **Anforderungen**: 150+ kritischer Blitzschaden
- **Kern-Vergabe**: 12% (Neutral) + 3% (Blitz)
- **Belohnungen**: 1× Blitz-RAR
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (8%)

---

## 6. Klassenspezialisierte Kampf-Quests

### 6.1 Zeitwächter-Quests

#### QUEST-K-040: Zeitliche Barrikade
- **Name**: Zeitliche Barrikade
- **Beschreibung**: [Zeitwächter] Blocke 300 Schaden mit Verteidigungskarten.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 300 geblockter Schaden
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× WAR-UNC Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-041: Schildmacht-Meister
- **Name**: Schildmacht-Meister
- **Beschreibung**: [Zeitwächter] Erreiche 5 Stufen Schildmacht und entlade sie mit einer Angriffskarte.
- **Schwierigkeit**: Elite
- **Anforderungen**: Volle Schildmacht entladen
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× WAR-RAR Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

### 6.2 Schattenschreiter-Quests

#### QUEST-K-042: Momentum-Tänzer
- **Name**: Momentum-Tänzer
- **Beschreibung**: [Schattenschreiter] Erreiche 3 Momentum in 3 verschiedenen Kämpfen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3× 3 Momentum erreichen
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× ROG-UNC Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-043: Schattensynergie
- **Name**: Schattensynergie
- **Beschreibung**: [Schattenschreiter] Spiele 5 Schattenkarten gefolgt von Angriffskarten mit Bonus-Schaden.
- **Schwierigkeit**: Elite
- **Anforderungen**: 5× Schattensynergie nutzen
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× ROG-RAR Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

### 6.3 Chronomant-Quests

#### QUEST-K-044: Arkanpuls-Virtuose
- **Name**: Arkanpuls-Virtuose
- **Beschreibung**: [Chronomant] Erreiche 5 Stufen Arkanpuls in 3 verschiedenen Kämpfen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3× 5 Arkanpuls erreichen
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× MAGE-UNC Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-045: Elementarer Rhythmus
- **Name**: Elementarer Rhythmus
- **Beschreibung**: [Chronomant] Spiele abwechselnd 5 Paare aus Zeitmanipulations- und Elementkarten.
- **Schwierigkeit**: Elite
- **Anforderungen**: 5× Zeit-Element-Paare
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× MAGE-RAR Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

---

## 7. Quest-Rotation und Gewichtungen

### 7.1 Tägliche Quest-Rotation

Der Tagesquest-Pool wird nach folgenden Prinzipien rotiert:

| Quest-Typ | Verfügbare Quests/Tag | Gewichtung |
|-----------|----------------------|------------|
| **Standardkampf** | 3-4 | 40% |
| **Elite-Gegner** | 1-2 | 20% |
| **Boss-Kampf** | 1 | 10% |
| **Elementar-Kampf** | 1-2 | 20% |
| **Klassenspezifisch** | 1 | 10% |

### 7.2 Schwierigkeitsverteilung

| Schwierigkeitsgrad | Anteil im täglichen Pool | Belohnungsstufe |
|--------------------|--------------------------|-----------------|
| **Standard** | 50% | Basis-Reward |
| **Herausfordernd** | 30% | 1,6× Basis-Reward |
| **Elite** | 20% | 2,4× Basis-Reward |

### 7.3 Gewichtungsmechanik

Die Gewichtungsmechanik stellt sicher, dass:
- Quests mit niedriger Rotationsgewichtung nicht zu oft erscheinen
- Keine Quest an zwei aufeinanderfolgenden Tagen erscheint
- Mindestens eine Quest aus jeder Hauptkategorie pro Tag verfügbar ist
- Die Gesamtschwierigkeit pro Tag ausbalanciert bleibt

### 7.4 Weltspezifische Anpassungen

Mit Fortschritt zu höheren Welten werden zusätzliche, weltspezifische Quests freigeschalten:

| Welt | Neue Quest-Typen | Besonderheiten |
|------|-----------------|----------------|
| **Welt 1** | Basis-Pool | Standard-Schwierigkeitsgrad |
| **Welt 2** | Feuer-Spezial-Quests | Höhere Feuer-Kern-Belohnungen |
| **Welt 3** | Eis-Spezial-Quests | Höhere Eis-Kern-Belohnungen |
| **Welt 4** | Blitz-Spezial-Quests | Höhere Blitz-Kern-Belohnungen |
| **Welt 5** | Ultimative Zeit-Quests | Multi-Element-Belohnungen |

### 7.5 Integration mit Zeit-Kern-System

Die Quest-Rotation ist so gestaltet, dass ein durchschnittlicher Spieler folgende Zeit-Kern-Aufladung erhält:

- **3 Quests**: ~20% Aufladung (1 Kern pro 2-3 Tage)
- **6 Quests**: ~40% Aufladung (1 Kern pro 1-2 Tage)
- **9 Quests**: ~60% Aufladung (1-2 Kerne pro Tag)

Dies entspricht dem Ziel, dass ein aktiver Spieler 5-8 vollständig aufgeladene Kerne pro Tag erhält, wobei ~80% dieser Kerne aus Quests und Events stammen.