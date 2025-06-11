# Zeitklingen: Modernisiertes Zeitkern-System

## Inhaltsverzeichnis
1. [Einführung und Übersicht](#1-einführung-und-übersicht)
2. [Hauptkomponenten](#2-hauptkomponenten)
3. [Spieler-Interaktionen](#3-spieler-interaktionen)
4. [System-Limitierungen und Edge Cases](#4-system-limitierungen-und-edge-cases)
5. [Benutzeroberfläche und Feedback](#5-benutzeroberfläche-und-feedback)
6. [Implementation Guidelines](#6-implementation-guidelines)
7. [Beispielszenarien](#7-beispielszenarien)

---

## 1. Einführung und Übersicht

Das modernisierte Zeitkern-System ersetzt das komplexe Aufladungs- und Stufensystem der ursprünglichen Spezifikation durch einen vereinfachten, intuitiven Ansatz, der sich an erfolgreichen Mobile Games wie Monster Collection (MoCo) orientiert.

### 1.1 Designziele

- **Vereinfachung ohne Tiefenverlust**: Reduzierung von Komplexität ohne Verlust strategischer Entscheidungen
- **Mobile-optimierte Interaktion**: Klare, direkte Mechaniken für Touch-Interfaces
- **Balance zwischen Zufall und Kontrolle**: Mischung aus zufälligen Verbesserungen und strategischen Entscheidungen
- **Langzeitmotivation**: System unterstützt kontinuierliches Engagement

### 1.2 Systemübersicht

Das System besteht aus drei Hauptkomponenten:

1. **Zeitkern**: Universelle Ressource, die beim Einsatz eine zufällige Karte um ein Level verbessert
2. **Zeitkernkit**: Bietet Auswahl aus zwei zufälligen Basiskarten und allen ihren Varianten/Kopien/Evolutionen
3. **Zeitsplitter**: Sekundäre Währung für Battle Pass Progression (nicht Teil des Kern-Leveling-Systems)

### 1.3 Interaktion mit bestehenden Systemen

- **Klassenstufen-System**: Kartenlevel kann Klassenstufe × 2 nicht überschreiten
- **Gate-System**: Bei Level 10, 20, 30, 40 erfordern Karten ein Seltenheits-Upgrade, bevor sie weiter gelevelt werden können
- **Evolutions-System**: Bei Level 9, 25, 35 können Karten in einen von drei Elementarpfaden (Feuer, Eis, Blitz) evolutioniert werden

---

## 2. Hauptkomponenten

### 2.1 Zeitkern

#### 2.1.1 Grundfunktion
- Universelle Ressource zum Leveln von Karten
- Bei Verwendung: Zufällige Karte aus dem Deck des Spielers erhält ein Level
- Eine Einheit = ein Levelaufstieg (keine Variationen in Wert/Qualität)

#### 2.1.2 Erhalt
- Primäre Quellen: Kämpfe, Quests, Projekte, Events
- Durchschnittliche Gewinnrate: [Spezifische Rate basierend auf Balancing]
- Kann nicht gekauft werden (außer in speziellen Pack-Angeboten)

#### 2.1.3 Einschränkungen
- Kann nicht bei Karten verwendet werden, die an einem Gate sind (Level 10, 20, 30, 40)
- Kann nicht bei Karten verwendet werden, die das maximale Level erreicht haben (Level 50)
- Kann nicht bei Karten verwendet werden, deren Level über der Klassenstufen-Begrenzung liegt (Klassenstufe × 2)

### 2.2 Zeitkernkit

#### 2.2.1 Grundfunktion
- Bietet eine Auswahl von Karten zum gezielten Leveln
- Zeigt zwei zufällige Basiskarten und all ihre Varianten (Kopien, Evolutionen) an
- Spieler wählt eine spezifische Karte/Variante aus, die ein Level aufsteigt

#### 2.2.2 Erhalt
- Primäre Quelle: Abschluss von 3 Tagesquests
- Sekundäre Quellen: Events, Battle Pass, spezielle Angebote
- Kann in begrenzter Menge mit Premium-Währung erworben werden

#### 2.2.3 Auswahlmechanik
- Zwei zufällige Basiskarten werden ausgewählt
- Alle im Deck vorhandenen Kopien dieser Basiskarten werden angezeigt
- Alle evolutionierten Versionen dieser Karten werden angezeigt
- Der Spieler wählt eine spezifische Karte/Variante zum Verbessern aus

#### 2.2.4 Einschränkungen
- Karten an Gates (Level 10, 20, 30, 40) werden nicht angezeigt
- Karten mit maximalem Level (50) werden nicht angezeigt
- Karten, die über der Klassenstufen-Begrenzung liegen würden, werden nicht angezeigt

### 2.3 Zeitsplitter

#### 2.3.1 Grundfunktion
- Sekundäre Währung für Battle Pass Progression
- Nicht direkt mit dem Kartenleveling-System verbunden

#### 2.3.2 Erhalt
- Primäre Quellen: Tägliche/wöchentliche Quests, Events
- Kann in begrenzter Menge mit Premium-Währung erworben werden

---

## 3. Spieler-Interaktionen

### 3.1 Zeitkern-Verwendung

#### 3.1.1 Direkte Verwendung
```
1. Spieler erhält einen Zeitkern
2. System benachrichtigt über neuen Zeitkern
3. Spieler kann Zeitkern entweder:
   a. Sofort einsetzen (Schaltfläche "Jetzt verwenden")
   b. Für später aufbewahren (Inventar)
4. Bei Einsatz:
   a. System wählt zufällig eine valid levelbare Karte
   b. Animation zeigt Levelaufstieg
   c. Erfolgsbenachrichtigung wird angezeigt
```

#### 3.1.2 Automatische Option
```
1. Spieler aktiviert "Auto-Verwendung" in den Einstellungen
2. Bei Erhalt eines Zeitkerns wird dieser automatisch eingesetzt
3. Bildschirmbenachrichtigung zeigt die verbesserte Karte
```

### 3.2 Zeitkernkit-Verwendung

#### 3.2.1 Aktivierungs-Flow
```
1. Spieler erhält ein Zeitkernkit
2. System benachrichtigt über neues Kit
3. Bei Aktivierung:
   a. Benutzeroberfläche zeigt zwei Basiskarten-Gruppen
   b. Jede Gruppe enthält alle Kopien und evolutionierten Versionen
   c. Nicht levelbare Karten (Gate, Max, Klassenbegrenzung) werden ausgegraut
4. Spieler wählt eine spezifische Karte
5. Bestätigungsanimation zeigt Levelaufstieg
```

#### 3.2.2 Ablehnen einer Auswahl
```
1. Spieler kann die angebotenen Karten ablehnen
2. Kit bleibt im Inventar für spätere Verwendung
3. Kein Verlust des Kits bei Ablehnung
```

### 3.3 Zeitkern-Inventar

#### 3.3.1 Bestandsverwaltung
- Inventar zeigt aktuelle Anzahl der Zeitkerne und Zeitkernkits
- Keine Obergrenze für Zeitkerne
- Maximale Anzahl Zeitkernkits: [Balancing-Entscheidung, z.B. 10]

#### 3.3.2 Einlösungs-Mechanik
- Inventarbildschirm bietet Schnellzugriff auf:
  - "Zeitkern verwenden" (zufällige Kartenverbesserung)
  - "Zeitkernkit öffnen" (Auswahl an Karten)

---

## 4. System-Limitierungen und Edge Cases

### 4.1 Gate-Behandlung

#### 4.1.1 Kartenidentifikation an Gates
- System identifiziert automatisch Karten, die aktuell an einem Gate sind (Level 10, 20, 30, 40)
- Diese Karten werden aus dem Zufallspool für Zeitkerne ausgeschlossen
- Bei Zeitkernkits werden diese Karten ausgegraut und mit "Benötigt Gate-Upgrade" markiert

#### 4.1.2 Gate-Upgrade-Erinnerung
- Wenn eine Karte ein Gate erreicht, erscheint eine Benachrichtigung
- Die Nachricht verlinkt direkt zur Gate-Upgrade-Schnittstelle
- Nach erfolgreichem Gate-Upgrade wird die Karte wieder für Zeitkerne/Zeitkernkits verfügbar

### 4.2 Klassenstufenbegrenzung

#### 4.2.1 Automatische Einhaltung
- System prüft die Klassenstufe des Spielers vor jeder Kartenverbesserung
- Karten, die bereits am Limit sind (Kartenlevel = Klassenstufe × 2), werden vom System nicht ausgewählt
- Zeitkernkits zeigen diese Karten ausgegraut mit "Benötigt höhere Klassenstufe" an

#### 4.2.2 Klassenstufen-Erinnerung
- Spezielle Benachrichtigung, wenn viele Karten die Klassenbegrenzung erreicht haben
- Empfehlung, sich auf Klassenlevel-Quests zu konzentrieren

### 4.3 Vollständig entwickeltes Deck

#### 4.3.1 Extreme Randfall-Behandlung
- Wenn alle Karten eines Spielers an Gates, maximalen Levels oder Klassenbegrenzungen sind
- Zeitkerne werden im Inventar gespeichert mit Hinweis "Keine levelbare Karte verfügbar"
- Zeitkernkits zeigen nur levelbare Karten an, wenn vorhanden

#### 4.3.2 Wiederverwendung
- Gespeicherte Zeitkerne werden automatisch verwendet, sobald neue levelbare Karten verfügbar werden
- System priorisiert die Verwendung älterer Zeitkerne zuerst (FIFO-Prinzip)

---

## 5. Benutzeroberfläche und Feedback

### 5.1 Zeitkern-Visualisierung

#### 5.1.1 Kern-Design
- Kristalline, blaue Form mit pulsierender Zeitenergie
- Einfaches, aber einprägsames Design für sofortige Erkennung
- Animation beim Erhalt: Materialisation mit blauem Lichteffekt

#### 5.1.2 Bestandsanzeige
- Permanente Anzeige im Hauptbildschirm oder Hub
- Format: Icon + Zahl (z.B. [Kern-Icon] × 5)
- Taktile Feedback-Animation bei Zu-/Abnahme

### 5.2 Zeitkernkit-Visualisierung

#### 5.2.1 Kit-Design
- Mysteriöse Box mit Zeitenergie-Effekten
- Pulsierendes Glühen zur Andeutung des Inhalts
- Öffnungsanimation: Energieexplosion, die in Kartenoptionen übergeht

#### 5.2.2 Auswahlbildschirm
- Übersichtliche Zweiteilung für die beiden Basiskarten
- Hierarchische Darstellung:
  - Basiskarte als Überschrift
  - Indentierte Auflistung aller Kopien mit Leveln
  - Weiter indentierte Auflistung aller Evolutionen mit Leveln
- Levelbare Karten hervorgehoben, nicht-levelbare ausgegraut

### 5.3 Feedback-Schleifen

#### 5.3.1 Belohnungs-Animationen
- Zeitkern-Erhalt: Kurze, befriedigende Animation
- Zufälliger Levelaufstieg: Medium-Länge Animation mit Fokus auf die verbesserte Karte
- Gezielter Levelaufstieg (Kit): Verlängerte, befriedigendere Animation

#### 5.3.2 Fortschrittsanzeigen
- Nach jedem Levelaufstieg: Anzeige des neuen Levels
- Bei Annäherung an Gate: Vorschau auf das kommende Gate-Upgrade
- Bei Annäherung an Evolution: Hinweis auf bevorstehende Evolutionsmöglichkeit

---

## 6. Implementation Guidelines

### 6.1 Datenmodell

#### 6.1.1 Spieler-Ressourcen
```json
{
  "player_id": "unique_id",
  "resources": {
    "time_cores": 5,
    "time_core_kits": 2,
    "time_shards": 120
  }
}
```

#### 6.1.2 Karten-Status-Tracking
```json
{
  "card_id": "unique_id",
  "base_card_id": "base_card_id", // Verknüpfung zur Basiskarte
  "copy_number": 2,
  "level": 8,
  "evolution": null, // oder "fire", "ice", "lightning"
  "evolution_level": 0, // 0, 1, 2 oder 3
  "at_gate": false
}
```

#### 6.1.3 Gate-Status-Tracking
```json
{
  "card_id": "unique_id",
  "current_gate": 1, // 1, 2, 3 oder 4 für die vier Gates
  "gate_progress": {
    "materials_required": [...],
    "materials_collected": [...]
  }
}
```

### 6.2 Algorithmische Überlegungen

#### 6.2.1 Zufällige Kartenauswahl (Zeitkern)
```pseudocode
function selectRandomLevelableCard(playerDeck):
    levelableCards = []
    
    for each card in playerDeck:
        if isLevelable(card):
            levelableCards.append(card)
    
    if levelableCards.isEmpty():
        return null
    
    return randomSelection(levelableCards)

function isLevelable(card):
    if card.level >= 50:
        return false
    if card.level >= playerClassLevel * 2:
        return false
    if isAtGate(card): // Level 10, 20, 30, 40
        return false
    return true
```

#### 6.2.2 Kit-Kartenauswahl (Zeitkernkit)
```pseudocode
function selectCardsForTimeKit(playerDeck):
    // Wähle zwei unterschiedliche Basiskarten zufällig aus
    availableBaseCards = getUniqueBaseCards(playerDeck)
    if availableBaseCards.length < 2:
        return availableBaseCards
    
    selectedBaseCards = randomSelectTwo(availableBaseCards)
    result = []
    
    for each baseCard in selectedBaseCards:
        cardGroup = {
            baseCard: baseCard,
            copies: [],
            evolutions: []
        }
        
        // Finde alle Kopien
        for each card in playerDeck:
            if card.baseCardId == baseCard.id:
                if isLevelable(card):
                    cardGroup.copies.append({
                        card: card,
                        levelable: true
                    })
                else:
                    cardGroup.copies.append({
                        card: card,
                        levelable: false,
                        reason: getLevelingBlockReason(card)
                    })
        
        // Finde alle Evolutionen
        for each card in playerDeck:
            if card.baseCardId == baseCard.id && card.evolution != null:
                if isLevelable(card):
                    cardGroup.evolutions.append({
                        card: card,
                        levelable: true
                    })
                else:
                    cardGroup.evolutions.append({
                        card: card,
                        levelable: false,
                        reason: getLevelingBlockReason(card)
                    })
        
        result.append(cardGroup)
    
    return result
```

### 6.3 Netzwerk-Überlegungen

#### 6.3.1 Offline-Verhalten
- Zeitkerne sollten offline gesammelt werden können
- Offline-Verbesserungen werden synchronisiert, wenn online
- Zeitkernkits sollten online geöffnet werden, um Server-validierte Auswahl zu gewährleisten

#### 6.3.2 Anti-Cheat-Maßnahmen
- Server-seitige Validierung aller Kartenverbesserungen
- Protokollierung aller Zeitkern-Transaktionen
- Ratenbegrenzungen für Zeitkern-Gewinne pro Zeit

---

## 7. Beispielszenarien

### 7.1 Standardszenarien

#### 7.1.1 Neuer Spieler (Klassenstufe 3)
- **Situation**: Spieler hat gerade erste Quest abgeschlossen, erhält ersten Zeitkern
- **System-Verhalten**: Erklärendes Tutorial zeigt, wie Zeitkerne funktionieren
- **Ergebnis**: Zufällige Karte verbessert sich, klarer Fortschritt sichtbar

#### 7.1.2 Mittlerer Spieler (Klassenstufe 8)
- **Situation**: Mehrere Karten nahe an Gates, erhält Zeitkernkit
- **System-Verhalten**: Kit zeigt zwei Basiskarten-Gruppen, einige Karten an Gates sind ausgegraut
- **Ergebnis**: Spieler kann strategisch entscheiden, welche Karte zu verbessern ist

#### 7.1.3 Fortgeschrittener Spieler (Klassenstufe 15+)
- **Situation**: Verschiedene evolutionierte Karten, komplexeres Deck
- **System-Verhalten**: Kit zeigt umfangreichere Auswahl an Basis-, Kopie- und Evolutionsoptionen
- **Ergebnis**: Tiefere strategische Entscheidung über Spezialisierung und Deck-Balance

### 7.2 Edge Cases

#### 7.2.1 Alle Karten an Gates
- **Situation**: Jede Karte im Deck ist entweder an einem Gate oder am Klassenlimit
- **System-Verhalten**: Zeitkerne werden gespeichert, Benachrichtigung "Keine levelbare Karte"
- **Ergebnis**: Spieler wird zur Gate-Upgrade-Schnittstelle oder zu Klassenstufen-Quests geführt

#### 7.2.2 Mischung aus Standard- und evolutionierten Karten
- **Situation**: Spieler hat verschiedene Kopien derselben Karte in unterschiedlichen Evolutionspfaden
- **System-Verhalten**: Zeitkernkit gruppiert alle verwandten Karten klar und übersichtlich
- **Ergebnis**: Spieler kann gezielt bestimmte evolutionäre Pfade stärken

#### 7.2.3 Maximal-Level-Deck
- **Situation**: Spieler hat ein vollständig maximiertes Deck (alle Karten Level 50)
- **System-Verhalten**: Zeitkerne werden für neue, noch nicht maximierte Karten gespeichert
- **Ergebnis**: System schlägt vor, alternative Decks oder Klassen zu erkunden

---

*Dieses Dokument dient als Entwicklungsreferenz für das modernisierte Zeitkern-System in Zeitklingen. Die genauen Balancewerte und visuellen Designs müssen während der Implementierung und des Testings angepasst werden.*