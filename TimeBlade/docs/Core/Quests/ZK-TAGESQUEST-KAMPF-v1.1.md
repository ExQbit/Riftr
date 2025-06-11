# Zeitklingen: Tagesquest-Pool - Kampfbezogene Quests (v1.1-20250520)

## Inhaltsverzeichnis
1. [Einführung und Übersicht](#1-einführung-und-übersicht)
2. [Duell-Quests](#2-duell-quests)
3. [Elite-Kartenstrategien](#3-elite-kartenstrategien)
4. [Kartenmeister-Quests](#4-kartenmeister-quests)
5. [Elementar-Deck-Quests](#5-elementar-deck-quests)
6. [Klassenspezialisierte Deck-Quests](#6-klassenspezialisierte-deck-quests)
7. [Quest-Rotation und Gewichtungen](#7-quest-rotation-und-gewichtungen)

---

## 1. Einführung und Übersicht

Dieses Dokument enthält den vollständigen Satz kampfbezogener Tagesquests für das Mo.Co-adaptierte Zeit-Kern-Progressionssystem von Zeitklingen. Diese Quests bilden etwa 40% des gesamten Tagesquest-Pools und fokussieren sich auf Duell-Herausforderungen unterschiedlicher Schwierigkeitsgrade. Sie sind darauf ausgerichtet, Spieler zur Verwendung verschiedener Decks und Zeitmanipulations-Strategien zu motivieren, während sie Zeit-Kerne akkumulieren.

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

## 2. Duell-Quests

### 2.1 Grundlegende Kampf-Quests

#### QUEST-K-001: Zeitklingenkämpfer
- **Name**: Zeitklingenkämpfer
- **Beschreibung**: "Ein wahrer Zeitklingenkämpfer übt unermüdlich." Gewinne 3 Duelle mit deinem Standarddeck.
- **Schwierigkeit**: Standard
- **Anforderungen**: 3 Duelle gewinnen
- **Kern-Vergabe**: 5%
- **Belohnungen**: 3× Zeitfragmente
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Sehr hoch (35%)

#### QUEST-K-002: Zeiteffizienter Duellant
- **Name**: Zeiteffizienter Duellant
- **Beschreibung**: "Zeit ist die wertvollste Ressource - nutze sie weise." Gewinne 2 Duelle mit mindestens 30 Sekunden Restzeit.
- **Schwierigkeit**: Standard
- **Anforderungen**: 2 Duelle mit >30s Restzeit
- **Kern-Vergabe**: 5%
- **Belohnungen**: 1× Zufällige COM-Karte
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (25%)

#### QUEST-K-003: Kartenmeister
- **Name**: Kartenmeister
- **Beschreibung**: "Die Beherrschung deiner Karten ist der Schlüssel zum Sieg." Spiele in einem Duell mindestens 25 Karten aus.
- **Schwierigkeit**: Standard
- **Anforderungen**: 25+ Karten in 1 Duell
- **Kern-Vergabe**: 5%
- **Belohnungen**: 2× COM Evolutionsmaterial
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (25%)

#### QUEST-K-004: Zeitretter
- **Name**: Zeitretter
- **Beschreibung**: "Am Rande der Niederlage zeigt sich wahre Meisterschaft." Gewinne ein Duell mit weniger als 5 Sekunden Restzeit.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Duell mit <5s Restzeit gewinnen
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Zeitmanipulations-Karte
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-005: Temporale Kombo
- **Name**: Temporale Kombo
- **Beschreibung**: "Der Fluss der Zeit lässt sich durch geschickte Kombinationen beeinflussen." Spiele eine Sequenz von 5 Karten in unter 3 Sekunden.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5-Karten-Kombo in <3s
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Schnelligkeits-Karte
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

---

## 3. Elite-Kartenstrategien

### 3.1 Fortgeschrittene Kampftechniken

#### QUEST-K-006: Zeitdieb
- **Name**: Zeitdieb
- **Beschreibung**: "Zeit zu stehlen ist eine Kunst, die nur wenige beherrschen." Stehle in einem Duell insgesamt 10 Sekunden von deinem Gegner durch entsprechende Karten.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 10s stehlen in 1 Duell
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Zeitdiebstahl-Karte
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-007: Zeitbeschleuniger
- **Name**: Zeitbeschleuniger
- **Beschreibung**: "Die Zeit zu beschleunigen ermöglicht blitzschnelle Strategien." Spiele 3 Karten in unter 1 Sekunde durch Zeitbeschleunigungseffekte.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 Karten in <1s
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Beschleunigungs-Karte
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-008: Zeitlicher Verteidiger
- **Name**: Zeitlicher Verteidiger
- **Beschreibung**: "Die perfekte Verteidigung hält die Zeit an." Blocke 5 gegnerische Karteneffekte durch Zeitverzögerungskarten.
- **Schwierigkeit**: Elite
- **Anforderungen**: 5 Effekte blocken
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× RAR Verteidigungskarte
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-K-009: Zeitparadoxon-Meister
- **Name**: Zeitparadoxon-Meister
- **Beschreibung**: "Ein wahrer Zeitmeister kann sogar Paradoxa zu seinem Vorteil nutzen." Erzeuge ein Zeitparadoxon, indem du 3 kontradiktorische Zeitkarten in Folge ausspielst.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 kontradiktorische Karten
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× RAR Paradoxon-Karte
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-K-010: Zeitschleifen-Virtuose
- **Name**: Zeitschleifen-Virtuose
- **Beschreibung**: "Die größte Kunst ist es, denselben Moment immer wieder neu zu erleben." Aktiviere in einem Duell dreimal dieselbe Zeitschleifenkarte.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3× dieselbe Zeitschleifenkarte
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× RAR Zeitschleifen-Karte
- **Welt-Beschränkung**: Ab Welt 5
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 4. Kartenmeister-Quests

### 4.1 Kartenkombinationen

#### QUEST-K-011: Zeitklinger-Novize
- **Name**: Zeitklinger-Novize
- **Beschreibung**: "Der Weg zur Meisterschaft beginnt mit dem Verständnis der Grundlagen." Gewinne ein Duell mit einem Deck, das nur Karten unter Level 10 enthält.
- **Schwierigkeit**: Standard
- **Anforderungen**: 1 Sieg mit Level <10 Karten
- **Kern-Vergabe**: 5%
- **Belohnungen**: 3× COM Karten (zufällig)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-K-012: Evolutionsstratege
- **Name**: Evolutionsstratege
- **Beschreibung**: "Evolution verstärkt die Macht der Zeit." Gewinne ein Duell mit mindestens 3 evolvierten Karten im Deck.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Sieg mit 3+ evolvierten Karten
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Evolutionsmaterial
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-013: Seltenheits-Sammler
- **Name**: Seltenheits-Sammler
- **Beschreibung**: "Die seltensten Karten bergen die größte Macht." Gewinne ein Duell mit einem Deck aus mindestens 5 seltenen oder epischen Karten.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Sieg mit 5+ RAR/EPI
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× RAR Karte (zufällig)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-K-014: Maximaler Zeitfluss
- **Name**: Maximaler Zeitfluss
- **Beschreibung**: "Die Zeit fließt für jene, die sie zu kontrollieren wissen." Gewinne ein Duell und erhalte dabei mehr als 20 Sekunden durch Zeitrückgewinnkarten.
- **Schwierigkeit**: Elite
- **Anforderungen**: >20s Zeitrückgewinn
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× RAR Zeitrückgewinn-Karte
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-K-015: Legendärer Stratege
- **Name**: Legendärer Stratege
- **Beschreibung**: "Die größten Zeitklinger beherrschen die seltensten Artefakte." Gewinne ein Duell mit mindestens einer legendären Karte im Deck.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Sieg mit LGD Karte
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 5. Elementar-Deck-Quests

### 5.1 Feuer-Element

#### QUEST-K-016: Flammenzüngelnde Zeit
- **Name**: Flammenzüngelnde Zeit
- **Beschreibung**: "Feuer verbrennt die Zeit und beschleunigt den Sieg." Gewinne 2 Duelle mit einem Deck, das mindestens 8 Feuer-Elementarkarten enthält.
- **Schwierigkeit**: Standard
- **Anforderungen**: 2 Siege mit 8+ Feuerkarten
- **Kern-Vergabe**: 5% (+ 3% Feuer-Kern)
- **Belohnungen**: 2× COM Feuer-Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-K-017: Feuerstratege
- **Name**: Feuerstratege
- **Beschreibung**: "Die Flammen der Zeit brennen am hellsten unter Druck." Gewinne ein Duell mit unter 10 Sekunden Restzeit mit einem reinen Feuer-Elementardeck.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Sieg mit <10s (reines Feuerdeck)
- **Kern-Vergabe**: 8% (+ 3% Feuer-Kern)
- **Belohnungen**: 1× UNC Feuer-Karte
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Mittel (15%)

### 5.2 Eis-Element

#### QUEST-K-018: Gefrorene Zeit
- **Name**: Gefrorene Zeit
- **Beschreibung**: "Eis verlangsamt die Zeit und ermöglicht präzise Strategien." Gewinne 2 Duelle mit einem Deck, das mindestens 8 Eis-Elementarkarten enthält.
- **Schwierigkeit**: Standard
- **Anforderungen**: 2 Siege mit 8+ Eiskarten
- **Kern-Vergabe**: 5% (+ 3% Eis-Kern)
- **Belohnungen**: 2× COM Eis-Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-K-019: Frostklingenstratege
- **Name**: Frostklingenstratege
- **Beschreibung**: "Ein eingefrorener Gegner kann die Zeit nicht nutzen." Verlangsame mit Eis-Karten die gegnerischen Aktionen um insgesamt 10 Sekunden.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 10s Verlangsamung durch Eis
- **Kern-Vergabe**: 8% (+ 3% Eis-Kern)
- **Belohnungen**: 1× UNC Eis-Karte
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Mittel (15%)

### 5.3 Blitz-Element

#### QUEST-K-020: Zeitblitze
- **Name**: Zeitblitze
- **Beschreibung**: "Blitz schlägt in den Fluss der Zeit ein und erschafft neue Möglichkeiten." Gewinne 2 Duelle mit einem Deck, das mindestens 8 Blitz-Elementarkarten enthält.
- **Schwierigkeit**: Standard
- **Anforderungen**: 2 Siege mit 8+ Blitzkarten
- **Kern-Vergabe**: 5% (+ 3% Blitz-Kern)
- **Belohnungen**: 2× COM Blitz-Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-K-021: Blitztempomeister
- **Name**: Blitztempomeister
- **Beschreibung**: "Mit Blitzgeschwindigkeit überrascht man Raum und Zeit." Spiele 10 Karten in unter 10 Sekunden mit einem Blitz-fokussierten Deck.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 10 Karten in <10s (Blitzdeck)
- **Kern-Vergabe**: 8% (+ 3% Blitz-Kern)
- **Belohnungen**: 1× UNC Blitz-Karte
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Mittel (15%)

---

## 6. Klassenspezialisierte Deck-Quests

### 6.1 Zeitwächter-Klasse

#### QUEST-K-022: Zeitwächter-Adept
- **Name**: Zeitwächter-Adept
- **Beschreibung**: "Ein Zeitwächter kontrolliert die Zeit mit Präzision und Geduld." Gewinne 2 Duelle mit einem Zeitwächter-Deck und nutze die Phasenwechsel-Mechanik mindestens 3 Mal.
- **Schwierigkeit**: Standard
- **Anforderungen**: 2 Siege mit 3+ Phasenwechseln
- **Kern-Vergabe**: 5%
- **Belohnungen**: 1× Zeitwächter-Karte (COM)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-K-023: Zeitwächter-Meister
- **Name**: Zeitwächter-Meister
- **Beschreibung**: "Nach der Verteidigung schlägt ein wahrer Zeitwächter noch härter zu." Aktiviere den +15% Schadensbonus nach Verteidigung in einem Duell mindestens 3 Mal.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3× Phasenbonus aktivieren
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Zeitwächter-Karte
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Mittel (15%)

### 6.2 Schattenschreiter-Klasse

#### QUEST-K-024: Schattenschreiter-Adept
- **Name**: Schattenschreiter-Adept
- **Beschreibung**: "Ein Schattenschreiter bewegt sich zwischen den Zeitlinien wie ein Schatten." Gewinne 2 Duelle mit einem Schattenschreiter-Deck und erreiche dabei mindestens 3 Momentum.
- **Schwierigkeit**: Standard
- **Anforderungen**: 2 Siege mit 3+ Momentum
- **Kern-Vergabe**: 5%
- **Belohnungen**: 1× Schattenschreiter-Karte (COM)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-K-025: Schattenschreiter-Meister
- **Name**: Schattenschreiter-Meister
- **Beschreibung**: "Im Schatten lauert die größte Kraft." Aktiviere den +20% Schadensbonus für Angriffe nach Schattenkarten bei 3 Momentum mindestens 2 Mal in einem Duell.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 2× Schattenbonus aktivieren
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Schattenschreiter-Karte
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Mittel (15%)

### 6.3 Chronomant-Klasse

#### QUEST-K-026: Chronomant-Adept
- **Name**: Chronomant-Adept
- **Beschreibung**: "Ein Chronomant webt die Fäden der Zeit mit arkaner Präzision." Gewinne 2 Duelle mit einem Chronomant-Deck und sammle dabei mindestens 4 Punkte Zeitliche Arkankraft.
- **Schwierigkeit**: Standard
- **Anforderungen**: 2 Siege mit 4+ Arkankraft
- **Kern-Vergabe**: 5%
- **Belohnungen**: 1× Chronomant-Karte (COM)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-K-027: Chronomant-Meister
- **Name**: Chronomant-Meister
- **Beschreibung**: "Die höchste Arkankraft kontrolliert sogar das Schicksal." Erreiche 5 Punkte Zeitliche Arkankraft und nutze die Zeitstrom-Resonanz mindestens 3 Mal in einem Duell.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3× Resonanz bei 5 Arkankraft
- **Kern-Vergabe**: 8%
- **Belohnungen**: 1× UNC Chronomant-Karte
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Mittel (15%)

---

## 7. Quest-Rotation und Gewichtungen

### 7.1 Tägliche Quest-Rotation

Der Tagesquest-Pool wird nach folgenden Prinzipien rotiert:

| Quest-Typ | Verfügbare Quests/Tag | Gewichtung |
|-----------|----------------------|------------|
| **Duell-Quests** | 3-4 | 40% |
| **Elite-Kartenstrategien** | 1-2 | 20% |
| **Kartenmeister** | 1 | 10% |
| **Elementar-Deck** | 1-2 | 20% |
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