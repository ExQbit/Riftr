# Zeitklingen: Stufen-Anforderungs-Tabelle (ZK-LEVEL-ANFORDERUNGEN-v2.0-20250521)

## Inhaltsverzeichnis
1. [Einführung und Übersicht](#1-einführung-und-übersicht)
2. [Level-Anforderungen im vereinfachten System](#2-level-anforderungen-im-vereinfachten-system)
3. [Meilenstein-Level und spezielle Anforderungen](#3-meilenstein-level-und-spezielle-anforderungen)
4. [Zeitkern-Effizienz und Optimierungsstrategien](#4-zeitkern-effizienz-und-optimierungsstrategien)
5. [Balancierung und Spielerprogression](#5-balancierung-und-spielerprogression)
6. [Implementationshinweise](#6-implementationshinweise)
7. [Abhängige Dokumente](#7-abhängige-dokumente)

---

## 1. Einführung und Übersicht

### 1.1 Zweck des Dokuments

Dieses Dokument definiert die präzisen Anforderungen für jedes Kartenlevel (1-50) im modernisierten Progressionssystem von Zeitklingen. Es ersetzt die bisherige komplexe XP-Kurve durch ein intuitives, materialbasiertes System mit direktem Leveling und bietet eine detaillierte Übersicht der Level-Anforderungen, Meilensteine und empfohlenen Strategien.

### 1.2 Grundlegender Wandel im Progressionsmodell

Das vereinfachte System basiert auf dem Grundprinzip:

**1 Zeitkern = 1 Level**

Damit wird das komplexe XP-System vollständig ersetzt. Spieler sammeln Zeitkerne und verwenden sie, um ihre Karten zu verbessern, wobei jeder Zeitkern genau einen Level-Aufstieg gewährt – unabhängig vom aktuellen Level der Karte.

### 1.3 Vorteile des vereinfachten Systems

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│ ALTES SYSTEM                 NEUES SYSTEM                   │
│ ──────────────               ────────────                   │
│                                                             │
│ • Komplexe XP-Kurve          • 1 Zeitkern = 1 Level         │
│ • Steigende XP-Anforderungen • Konstante Anforderung        │
│ • 5+ Materialtypen           • Ein Material (Zeitkern)      │
│ • Viele Berechnungen         • Intuitive Direktheit         │
│ • Zufällige XP-Verteilung    • Gezielte oder zufällige      │
│                              • Verwendung (Zeitkernkits)     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

Die neue Kurve folgt einem intuitiven, gleichmäßigen Fortschritt, der leicht zu verstehen und zu planen ist.

---

## 2. Level-Anforderungen im vereinfachten System

### 2.1 Grundprinzip des direkten Levelings

Im vereinfachten System gilt:
- Jedes Level kostet genau 1 Zeitkern
- Level 1 → 2 kostet 1 Zeitkern
- Level 49 → 50 kostet ebenfalls 1 Zeitkern
- Keine Steigerung der Kosten bei höheren Leveln
- Keine Unterschiede basierend auf Kartenseltenheit

### 2.2 Level-Anforderungstabelle

| Level-Bereich | Anforderung pro Level | Besonderheiten |
|---------------|----------------------|----------------|
| Level 1-9     | 1× Zeitkern          | Evolution bei Level 9 |
| Level 10      | 1× Zeitkern + Gate 1 | Gate 1: 1× Seltene Essenz |
| Level 11-19   | 1× Zeitkern          | Keine besonderen Anforderungen |
| Level 20      | 1× Zeitkern + Gate 2 | Gate 2: 2× Seltene Essenz |
| Level 21-24   | 1× Zeitkern          | Keine besonderen Anforderungen |
| Level 25      | 1× Zeitkern          | Evolution Stufe 2: 2× Elementarfragment |
| Level 26-29   | 1× Zeitkern          | Keine besonderen Anforderungen |
| Level 30      | 1× Zeitkern + Gate 3 | Gate 3: 3× Seltene Essenz |
| Level 31-34   | 1× Zeitkern          | Keine besonderen Anforderungen |
| Level 35      | 1× Zeitkern          | Evolution Stufe 3: 3× Elementarfragment |
| Level 36-39   | 1× Zeitkern          | Keine besonderen Anforderungen |
| Level 40      | 1× Zeitkern + Gate 4 | Gate 4: 4× Seltene Essenz |
| Level 41-49   | 1× Zeitkern          | Keine besonderen Anforderungen |
| Level 50      | 1× Zeitkern          | Maximales Level erreicht |

**Gesamt-Anforderungen für Maximallevel:**
- 50× Zeitkern (Level 1→50)
- 10× Seltene Essenz (alle Gates)
- 6× Elementarfragment (alle Evolutionen)

### 2.3 Zeitkern-Beschaffung

| Spielphase | Zeitkern-Gewinnrate | Hauptquellen |
|------------|---------------------|-------------|
| Früh (Level 1-10) | ~10 pro Stunde | Kämpfe, Tagesquests |
| Mittel (Level 11-20) | ~15 pro Stunde | Kämpfe, Quests, kleine Projekte |
| Fortgeschritten (Level 21-30) | ~20 pro Stunde | Quests, Projekte, Events |
| Spät (Level 31-40) | ~30 pro Stunde | Projekte, Events, Weltbosse |
| Endgame (Level 41-50) | ~40 pro Stunde | Events, Weltbosse, Zeitlose Kammer |

### 2.4 Zeitkernkit-System

Zeitkernkits ermöglichen gezieltes Leveling spezifischer Karten:

- **Funktion**: Gewährt +1 Level für eine ausgewählte Karte
- **Erhalt**: Nach jeweils 3 abgeschlossenen Tagesquests
- **Auswahlprozess**: Zeigt zwei zufällige Basis-Kartentypen und alle zugehörigen Kopien/Evolutionen
- **Beschränkung**: Kann nicht für Karten verwendet werden, die an einem Gate sind oder das maximale Level erreicht haben

---

## 3. Meilenstein-Level und spezielle Anforderungen

### 3.1 Evolutionsstufen

| Evolution | Level | Materialanforderung | Effekt |
|-----------|-------|---------------------|--------|
| **Evolution 1** | 9 | 1× Elementarfragment | Elementarspezialisierung (Feuer/Eis/Blitz) |
| **Evolution 2** | 25 | 2× Elementarfragment | Verbesserte Elementareffekte |
| **Evolution 3** | 35 | 3× Elementarfragment | Maximierte Elementarkraft |

### 3.2 Seltenheitsupgrades (Gates)

| Gate | Level | Materialanforderung | Effekt |
|------|-------|---------------------|--------|
| **Gate 1 (C→U)** | 10 | 1× Seltene Essenz | Uncommon + 10% auf ein zufälliges Attribut |
| **Gate 2 (U→R)** | 20 | 2× Seltene Essenz | Rare + 20% auf ein zufälliges Attribut |
| **Gate 3 (R→E)** | 30 | 3× Seltene Essenz | Epic + 30% auf ein zufälliges Attribut |
| **Gate 4 (E→L)** | 40 | 4× Seltene Essenz | Legendary + 45% auf ein zufälliges Attribut |

### 3.3 Sockelsystem-Anforderungen

| Sockel | Level | Materialanforderung | Effekt |
|--------|-------|---------------------|--------|
| **Sockel 1** | 10 | 1× Sockelstein | Ermöglicht das Einsetzen eines Edelsteins |
| **Sockel 2** | 20 | 2× Sockelstein | Ermöglicht das Einsetzen eines zweiten Edelsteins |

### 3.4 Spezielle Fassungen

| Fassung | Level | Materialanforderung | Effekt |
|---------|-------|---------------------|--------|
| **Arkane Fassung** | 15 | 8× Zeitkern, 3× Elementarfragment, 1× Seltene Essenz | +50% Edelsteineffektivität |
| **Chronomantische Fassung** | 35 | 15× Zeitkern, 5× Elementarfragment, 3× Seltene Essenz, 1× Sockelstein | +75% Edelsteineffektivität |

---

## 4. Zeitkern-Effizienz und Optimierungsstrategien

### 4.1 Progressionsstrategien nach Spielphase

#### 4.1.1 Frühe Phase (Level 1-10)
- **Fokus**: Einige wenige Kernkarten auf Level 9-10 bringen
- **Strategie**: Zeitkerne hauptsächlich für Angriffs- und Verteidigungskarten verwenden
- **Ressourcen**: Elementarfragmente für Evolution 1 bei Level 9 sparen
- **Tipp**: Wenn möglich, Gates bei Level 10 unmittelbar durchbrechen

#### 4.1.2 Mittlere Phase (Level 11-25)
- **Fokus**: Balance zwischen Kartenvielfalt und Spezialisierung
- **Strategie**: Zeitkernkits für wichtige Karten reservieren, zufällige Zeitkerne für Ergänzungskarten
- **Ressourcen**: Seltene Essenz für Gate 2 (Level 20) ansparen
- **Tipp**: Nach Gate 2 direkt auf Evolution 2 (Level 25) hinarbeiten

#### 4.1.3 Fortgeschrittene Phase (Level 26-40)
- **Fokus**: Deck-Optimierung und Spezialisierung
- **Strategie**: Ressourcen für Top-Karten reservieren, Experimentieren mit Builds
- **Ressourcen**: Zeitfokus für Rerolls der wichtigsten Karten sammeln
- **Tipp**: Vor dem Erreichen von Gate 4 (Level 40) genügend Seltene Essenz ansparen

#### 4.1.4 Endgame (Level 41-50)
- **Fokus**: Perfektionierung und Zenit-Vorbereitung
- **Strategie**: Eine potenzielle Zenit-Karte auf Level 45+ bringen
- **Ressourcen**: Alle Materialien für Zenit-Transformation sparen
- **Tipp**: Rerolls für optimale Attributverteilung verwenden

### 4.2 Zeitkern vs. Zeitkernkit - Entscheidungshilfe

| Aspekt | Zeitkern | Zeitkernkit |
|--------|----------|-------------|
| **Zufälligkeit** | Zufällige Karte | Ausgewählte Karte |
| **Menge** | Häufiger erhältlich | Begrenzte Verfügbarkeit |
| **Strategie** | Gesamtdeck verbessern | Schlüsselkarten optimieren |
| **Endgame** | Für Experimentieren | Für Zenit-Kandidaten |

### 4.3 Klassenstufenabhängige Einschränkungen

Kartenlevels können die doppelte Klassenstufe nicht überschreiten:

- **Klassenstufe 5**: Maximales Kartenlevel 10 (Gate 1)
- **Klassenstufe 10**: Maximales Kartenlevel 20 (Gate 2)
- **Klassenstufe 15**: Maximales Kartenlevel 30 (Gate 3)
- **Klassenstufe 20**: Maximales Kartenlevel 40 (Gate 4)
- **Klassenstufe 25**: Maximales Kartenlevel 50 (Max Level)

---

## 5. Balancierung und Spielerprogression

### 5.1 Progressionskurve und Spielerpacing

Das Zeit-Kern-System ist so ausbalanciert, dass ein durchschnittlicher Spieler folgende Meilensteine erreicht:

1. **Erste 5h**: Spieler erreichen Level 7-8 mit ihren Hauptkarten
2. **Erste 10h**: Evolution 1 (Level 9) und Gate 1 (Level 10) mit 2-3 Karten
3. **Erste 25h**: Gate 2 (Level 20) wird mit 1-2 Hauptkarten erreicht
4. **Erste 50h**: Evolution 2 (Level 25) wird mit 1-2 Hauptkarten erreicht
5. **Erste 100h**: Gate 3 (Level 30) wird mit 1 Hauptkarte erreicht
6. **Erste 150h**: Evolution 3 (Level 35) wird mit 1 Hauptkarte erreicht
7. **Erste 200h**: Gate 4 (Level 40) wird mit 1 Hauptkarte erreicht
8. **Erste 250h**: Eine Karte erreicht Level 45+ (Zenit-Vorbereitung)
9. **Erste 280h**: Level 50 (Maximallevel) wird mit 1 Hauptkarte erreicht

### 5.2 Vergleich mit dem alten System

| Aspekt | Altes System | Vereinfachtes System |
|--------|-------------|----------------------|
| **Level 10 Erreichen** | ~9h | ~9h |
| **Level 20 Erreichen** | ~35h | ~35h |
| **Level 30 Erreichen** | ~90h | ~90h |
| **Level 40 Erreichen** | ~180h | ~180h |
| **Level 50 Erreichen** | ~280h | ~280h |
| **Spieler-Agency** | Gering | Hoch (gezielte Verbesserung) |
| **Verständlichkeit** | Komplex | Intuitiv |
| **Voraussagbarkeit** | Variabel | Konstant und planbar |

### 5.3 F2P vs. Premium-Progression

| Spielertyp | Level 10 | Level 20 | Level 30 | Level 40 | Level 50 |
|------------|----------|----------|----------|----------|----------|
| F2P-Spieler | ~9h | ~35h | ~90h | ~180h | ~280h |
| Premium-Spieler | ~7h | ~28h | ~72h | ~144h | ~225h |
| Beschleunigung | ~20% | ~20% | ~20% | ~20% | ~20% |

*Hinweis: Die Premium-Beschleunigung basiert auf zusätzlichen Zeitkernen und Zeitkernkits durch Premium-Angebote, nicht auf exklusiven Inhalten.*

---

## 6. Implementationshinweise

### 6.1 Vereinfachte Datenstruktur

```json
// Kartenleveling-System
{
  "card_id": "unique_id",
  "level": 8,
  "rarity": "common",
  "is_at_gate": false
}

// Spieler-Materialien
{
  "player_id": "unique_id",
  "materials": {
    "time_core": 12,
    "elemental_fragment": 5,
    "rare_essence": 2,
    "time_focus": 3,
    "socket_stone": 1
  },
  "time_core_kits": 2
}
```

### 6.2 Leveling-Algorithmus

```pseudocode
function applyTimeCore(playerInventory, targetCard = null):
    // Überprüfe, ob Zeitkerne verfügbar sind
    if playerInventory.time_core <= 0:
        return "Keine Zeitkerne verfügbar"
    
    // Wenn keine Zielkarte angegeben ist, wähle eine zufällige levelbare Karte
    if targetCard == null:
        levelableCards = getLevelableCards(playerInventory.player_id)
        if levelableCards.isEmpty():
            return "Keine levelbare Karte verfügbar"
        targetCard = random.choice(levelableCards)
    
    // Überprüfe, ob die Karte levelbar ist
    if !isLevelable(targetCard):
        return "Karte kann nicht gelevelt werden"
    
    // Wende den Zeitkern an
    targetCard.level += 1
    playerInventory.time_core -= 1
    
    // Überprüfe, ob die Karte nun an einem Gate ist
    if isGateLevel(targetCard.level):
        targetCard.is_at_gate = true
    
    return "Erfolg: Karte wurde auf Level " + targetCard.level + " verbessert"

function isLevelable(card):
    // Überprüfe verschiedene Bedingungen
    if card.level >= 50:
        return false  // Maximallevel erreicht
    if isGateLevel(card.level) && card.is_at_gate:
        return false  // An einem Gate und muss erst upgraded werden
    if card.level >= getPlayerClassLevel(card.player_id) * 2:
        return false  // Überschreitet Klassenstufenbegrenzung
    return true

function isGateLevel(level):
    return level == 10 || level == 20 || level == 30 || level == 40
```

### 6.3 Zeitkernkit-Algorithmus

```pseudocode
function applyTimeCoreKit(playerInventory):
    // Überprüfe, ob Zeitkernkits verfügbar sind
    if playerInventory.time_core_kits <= 0:
        return "Keine Zeitkernkits verfügbar"
    
    // Wähle zwei zufällige Basiskarten
    allBaseCards = getPlayerBaseCards(playerInventory.player_id)
    if allBaseCards.length < 2:
        selectedCards = allBaseCards
    else:
        selectedCards = random.sample(allBaseCards, 2)
    
    // Finde alle Varianten dieser Basiskarten, die levelbar sind
    cardOptions = []
    for baseCard in selectedCards:
        variants = getAllCardVariants(baseCard)
        for variant in variants:
            if isLevelable(variant):
                cardOptions.append(variant)
    
    if cardOptions.isEmpty():
        return "Keine levelbare Karte in der Auswahl verfügbar"
    
    // Zeige Optionen an und warte auf Spielerauswahl
    selectedCard = showSelectionUIAndWaitForChoice(cardOptions)
    
    // Wende das Zeitkernkit an
    selectedCard.level += 1
    playerInventory.time_core_kits -= 1
    
    // Überprüfe, ob die Karte nun an einem Gate ist
    if isGateLevel(selectedCard.level):
        selectedCard.is_at_gate = true
    
    return "Erfolg: " + selectedCard.name + " wurde auf Level " + selectedCard.level + " verbessert"
```

---

## 7. Abhängige Dokumente

* `ZK-ZEITKERN-SYSTEM-v1.0.md`: Detaillierte Beschreibung des modernisierten Zeitkern-Systems
* `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`: Definition des vereinfachten 5-Material-Systems
* `ZK-KARTENPROGRESSION-v2.0.md`: Detaillierte Information zum Kartenleveling, Evolution und Gates
* `ZK-DROP-RATEN-v2.0.md`: Detaillierte Drop-Raten für Materialien
* `ZK-ECONOMY-BALANCING-v2.0.md`: Wirtschaftliches Gleichgewicht des Materialsystems
* `ZK-SYSTEM-INTERAKTION-v2.0.md`: Interaktion zwischen verschiedenen Spielsystemen
* `ZK-Klassenstufen- und Meisterschaftssystem-v1.0-.md`: Details zum Klassenstufen-System
* `ZK-Finale Definition und Balancing für "Zeitklingen"-v2.0.md`: Überblick und Zenit-System
* `Zeitklingen: Progression & Hook-Mechaniken-v1.3-.md`: Pacing und Hook-Definitionen