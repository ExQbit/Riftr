# Zeitklingen: Tagesquest-Pool - Sammlungsquests (v1.0-20250520)

## Inhaltsverzeichnis
1. [Einführung und Übersicht](#1-einführung-und-übersicht)
2. [Ressourcen-Quests](#2-ressourcen-quests)
3. [Zeitfragment-Quests](#3-zeitfragment-quests)
4. [Elementare-Quests](#4-elementare-quests)
5. [Zeitkern-Quests](#5-zeitkern-quests)
6. [Seltenheiten-Quests](#6-seltenheiten-quests)
7. [Quest-Rotation und Gewichtungen](#7-quest-rotation-und-gewichtungen)

---

## 1. Einführung und Übersicht

Dieses Dokument enthält den vollständigen Satz sammlungsbezogener Tagesquests für das Mo.Co-adaptierte Progressionssystem von Zeitklingen. Diese Quests bilden etwa 25% des gesamten Tagesquest-Pools und fokussieren sich auf die Sammlung von Materialien, Zeitfragmenten und anderen Ressourcen für die Aufladung und Nutzung von Zeit-Kernen.

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

Die Kern-Vergabe für sammlungsbezogene Quests folgt diesen Richtlinien:
- **Standard**: 6% Kern-Aufladung
- **Herausfordernd**: 9% Kern-Aufladung
- **Elite**: 12% Kern-Aufladung
- **Multiplikator**: Welt 1: 1.0×, Welt 2: 1.2×, Welt 3: 1.5×, Welt 4: 1.8×, Welt 5: 2.0×

---

## 2. Ressourcen-Quests

### 2.1 Grundlegende Materialien

#### QUEST-S-001: Rohstoff-Sammler
- **Name**: Rohstoff-Sammler
- **Beschreibung**: Sammle 20 grundlegende Rohstoffe (Holz, Stein, Pflanzenfasern).
- **Schwierigkeit**: Standard
- **Anforderungen**: 20 Rohstoffe sammeln
- **Kern-Vergabe**: 6%
- **Belohnungen**: 5× COM Handwerksmaterial
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (25%)

#### QUEST-S-002: Erz-Schürfer
- **Name**: Erz-Schürfer
- **Beschreibung**: Baue 15 Erze aus der Umgebung ab.
- **Schwierigkeit**: Standard
- **Anforderungen**: 15 Erze abbauen
- **Kern-Vergabe**: 6%
- **Belohnungen**: 3× COM Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-S-003: Kräutersucher
- **Name**: Kräutersucher
- **Beschreibung**: Sammle 10 Kräuter und Pflanzen für Alchemie.
- **Schwierigkeit**: Standard
- **Anforderungen**: 10 Kräuter sammeln
- **Kern-Vergabe**: 6%
- **Belohnungen**: 2× UNC Alchemie-Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-S-004: Metallurgist
- **Name**: Metallurgist
- **Beschreibung**: Gewinne 10 raffinierte Metalle aus Erzen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 10 raffinierte Metalle produzieren
- **Kern-Vergabe**: 9%
- **Belohnungen**: 2× UNC Handwerksmaterial
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-S-005: Alchemistische Basis
- **Name**: Alchemistische Basis
- **Beschreibung**: Stelle 5 alchemistische Grundsubstanzen her.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5 Alchemie-Grundsubstanzen
- **Kern-Vergabe**: 9%
- **Belohnungen**: 1× RAR Alchemie-Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

### 2.2 Spezielle Materialien

#### QUEST-S-006: Extraktor seltener Elemente
- **Name**: Extraktor seltener Elemente
- **Beschreibung**: Extrahiere 5 seltene Elemente aus speziellen Quellen.
- **Schwierigkeit**: Elite
- **Anforderungen**: 5 seltene Elemente extrahieren
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× RAR Elementarmaterial (Spielerwahl)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-S-007: Essenzsammler
- **Name**: Essenzsammler
- **Beschreibung**: Sammle 3 stabile Essenzen von elementaren Wesen.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 stabile Essenzen sammeln
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-S-008: Mondsplitter-Sucher
- **Name**: Mondsplitter-Sucher
- **Beschreibung**: Sammle 3 Mondsplitter, die nur im Mondlicht sichtbar sind.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 Mondsplitter sammeln
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× EPI Handwerksmaterial
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-S-009: Fluss des Lebens
- **Name**: Fluss des Lebens
- **Beschreibung**: Sammle 10 flüssige Lebenselemente aus Zeitquellen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 10 Lebenselemente sammeln
- **Kern-Vergabe**: 9%
- **Belohnungen**: 1× Zeit-Splitter (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-S-010: Seelenkristall-Sucher
- **Name**: Seelenkristall-Sucher
- **Beschreibung**: Finde 1 seltenen Seelenkristall in einer versteckten Höhle.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Seelenkristall finden
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 3. Zeitfragment-Quests

### 3.1 Grundlegende Zeitfragmente

#### QUEST-S-011: Zeitsammler
- **Name**: Zeitsammler
- **Beschreibung**: Sammle 25 Basis-Zeitfragmente aus der Umgebung.
- **Schwierigkeit**: Standard
- **Anforderungen**: 25 Zeitfragmente sammeln
- **Kern-Vergabe**: 6%
- **Belohnungen**: 5× Zeitfragment
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Sehr hoch (30%)

#### QUEST-S-012: Zeitpunktsammler
- **Name**: Zeitpunktsammler
- **Beschreibung**: Sammle präzise 10 instabile Zeitfragmente genau dann, wenn sie aufleuchten.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 10 instabile Zeitfragmente im richtigen Moment sammeln
- **Kern-Vergabe**: 9%
- **Belohnungen**: 1× Zeit-Splitter (25% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-S-013: Schattenfragmente
- **Name**: Schattenfragmente
- **Beschreibung**: Sammle 15 Schattenfragmente aus verlorenen Zeit-Echos.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 15 Schattenfragmente sammeln
- **Kern-Vergabe**: 9%
- **Belohnungen**: 2× UNC Elementarmaterial (Dunkel)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-S-014: Riss-Sammler
- **Name**: Riss-Sammler
- **Beschreibung**: Gewinne 5 Zeitfragmente aus instabilen Zeitrissen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5 Riss-Zeitfragmente gewinnen
- **Kern-Vergabe**: 9%
- **Belohnungen**: 1× Zeit-Splitter (50% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-S-015: Zeitkristallwachstum
- **Name**: Zeitkristallwachstum
- **Beschreibung**: Kultiviere 3 Zeitfragmente zu kleinen Zeitkristallen.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 Zeitkristalle züchten
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (10%)

### 3.2 Spezielle Zeitfragmente

#### QUEST-S-016: Chronos Tränen
- **Name**: Chronos Tränen
- **Beschreibung**: Sammle 3 flüssige Zeittränen aus Zeitbrunnen.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 Zeittränen sammeln
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (75% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-S-017: Zeitverzerrungsreste
- **Name**: Zeitverzerrungsreste
- **Beschreibung**: Sammle 5 Fragmente aus Bereichen mit starker Zeitverzerrung.
- **Schwierigkeit**: Elite
- **Anforderungen**: 5 Verzerrungsfragmente sammeln
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-S-018: Kristallisierte Erinnerungen
- **Name**: Kristallisierte Erinnerungen
- **Beschreibung**: Sammle 3 kristallisierte Erinnerungen aus verwaisten Zeitlinien.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 Erinnerungskristalle sammeln
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-S-019: Eo-Fragment
- **Name**: Eo-Fragment
- **Beschreibung**: Finde ein Fragment aus dem Anbeginn der Zeit.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Eo-Fragment finden
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-S-020: Ewigkeitspartikel
- **Name**: Ewigkeitspartikel
- **Beschreibung**: Gewinne stabile Partikel aus einem Ewigkeitskreislauf.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Ewigkeitspartikel gewinnen
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× EPI Elementarmaterial (Zeitlich)
- **Welt-Beschränkung**: Ab Welt 5
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 4. Elementare-Quests

### 4.1 Elementarsammlungen

#### QUEST-S-021: Feuerherzsucher
- **Name**: Feuerherzsucher
- **Beschreibung**: Sammle 5 Feuerherzen aus elementaren Flammen.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Feuerherzen sammeln
- **Kern-Vergabe**: 6%
- **Belohnungen**: 3× COM Elementarmaterial (Feuer)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-S-022: Eisschollensammler
- **Name**: Eisschollensammler
- **Beschreibung**: Sammle 5 perfekte Eisschollen aus elementaren Eiskristallen.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Eisschollen sammeln
- **Kern-Vergabe**: 6%
- **Belohnungen**: 3× COM Elementarmaterial (Eis)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-S-023: Blitzsammler
- **Name**: Blitzsammler
- **Beschreibung**: Fange 5 elektrische Entladungen mit einem Blitzsammler.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Blitze sammeln
- **Kern-Vergabe**: 6%
- **Belohnungen**: 3× COM Elementarmaterial (Blitz)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-S-024: Erdenergie-Sammler
- **Name**: Erdenergie-Sammler
- **Beschreibung**: Extrahiere 5 Erdenergie-Knötchen aus elementaren Erdknoten.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Erdenergie-Knötchen sammeln
- **Kern-Vergabe**: 6%
- **Belohnungen**: 3× COM Elementarmaterial (Erde)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-S-025: Windhaucher
- **Name**: Windhaucher
- **Beschreibung**: Sammle 5 Windhauche aus elementaren Luftwirbeln.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Windhauche sammeln
- **Kern-Vergabe**: 6%
- **Belohnungen**: 3× COM Elementarmaterial (Wind)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

### 4.2 Elementar-Kombinationen

#### QUEST-S-026: Bi-Elementarsammler
- **Name**: Bi-Elementarsammler
- **Beschreibung**: Sammle 3 Stücke eines Elementes und 3 eines kontrastierenden Elementes.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: Je 3 kontrastierende Elemente
- **Kern-Vergabe**: 9%
- **Belohnungen**: 2× UNC Elementarmaterial (beide Typen)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-S-027: Drei-Elemente-Harmonisierer
- **Name**: Drei-Elemente-Harmonisierer
- **Beschreibung**: Sammle und harmonisiere drei verschiedene Elementartypen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 verschiedene Elemente harmonisieren
- **Kern-Vergabe**: 9%
- **Belohnungen**: 1× RAR Elementarmaterial (zufällig)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-S-028: Fünf-Elemente-Sammler
- **Name**: Fünf-Elemente-Sammler
- **Beschreibung**: Sammle jeweils mindestens 1 Stück aller fünf Elementartypen.
- **Schwierigkeit**: Elite
- **Anforderungen**: Alle 5 Elementartypen sammeln
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Splitter (100% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-S-029: Feuer-und-Eis-Fusion
- **Name**: Feuer-und-Eis-Fusion
- **Beschreibung**: Sammle 3 Feuerherzen und 3 Eisschollen und kombiniere sie zu einem instabilen Dampfkern.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Dampfkern erschaffen
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× RAR Elementarmaterial (Wahl)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-S-030: Elementarimmersion
- **Name**: Elementarimmersion
- **Beschreibung**: Tauche ein in eine Elementar-Konzentration und extrahiere deren Essenz.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Elementaressenz extrahieren
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× EPI Elementarmaterial (entsprechender Typ)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 5. Zeitkern-Quests

### 5.1 Zeitkern-Materialien

#### QUEST-S-031: Zeit-Splitter-Sammler
- **Name**: Zeit-Splitter-Sammler
- **Beschreibung**: Sammle Materialien für 1 Zeit-Splitter (25% Aufladung).
- **Schwierigkeit**: Herausfordernd 
- **Anforderungen**: Splitter-Materialien sammeln
- **Kern-Vergabe**: 9%
- **Belohnungen**: 1× Zeit-Splitter (25% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-S-032: Reinen Kristall formen
- **Name**: Reinen Kristall formen
- **Beschreibung**: Sammle die notwendigen Materialien für einen reinen Zeitkristall.
- **Schwierigkeit**: Elite
- **Anforderungen**: Alle Kristall-Materialien sammeln
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Kristall (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-S-033: Essenz-Materialien
- **Name**: Essenz-Materialien
- **Beschreibung**: Sammle die seltenen Komponenten für eine Zeitessenz-Herstellung.
- **Schwierigkeit**: Elite
- **Anforderungen**: Alle Essenz-Materialien sammeln
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× RAR Elementarmaterial (Wahl)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-S-034: Zeitkern-Grundsubstanzen
- **Name**: Zeitkern-Grundsubstanzen
- **Beschreibung**: Sammle die fünf Grundsubstanzen für Zeit-Kern-Aktivierung.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 5 Kern-Grundsubstanzen
- **Kern-Vergabe**: 9%
- **Belohnungen**: 1× Zeit-Splitter (50% Aufladung)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-S-035: Zeitenergie-Konverter
- **Name**: Zeitenergie-Konverter
- **Beschreibung**: Sammle Materialien für einen temporalen Energiekonverter.
- **Schwierigkeit**: Elite
- **Anforderungen**: Alle Konverter-Materialien
- **Kern-Vergabe**: 12%
- **Belohnungen**: 1× Zeit-Essenz (25% Aufladung)
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%)

