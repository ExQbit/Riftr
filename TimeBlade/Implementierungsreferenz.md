# Zeitklingen Implementierungsreferenz

Dieses Dokument dient als zentrale Referenz und Blueprint für die technische Implementierung des Zeitklingen-Spiels. Es verbindet die Konzepte aus den Designdokumenten mit den konkreten Code-Artefakten.

**Status-Legende:**
*   `[ ]` Nicht begonnen
*   `[/]` In Arbeit
*   `[x]` Implementiert

---

## 1. Kernmechaniken und Systeme (_Core)

### 1.1 GameManager
*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: Game Flow]`
*   **Pfad:** `Assets/_Core/GameManager/`
*   **Benötigte Skripte:**
    *   `GameManager.cs`: Zentrale Steuerung des Spielzustands (Singleton, State Machine). `[/]` *(Struktur erstellt)*
*   **Abhängigkeiten:** UI, SaveSystem.
*   **Status:** `[/]`

### 1.2 Zeitsystem
*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: ZK-TIME-.md]`
*   **Pfad:** `Assets/_Core/TimeSystem/`
*   **Benötigte Skripte:**
    *   `TimeManager.cs`: Zentrale Steuerung der Zeitmanipulation (Countdown, Verlangsamung/Beschleunigung). `[ ]`
    *   `TimeAffectedObject.cs`: Basisklasse für Objekte, die vom Zeitsystem beeinflusst werden. `[ ]`
    *   `GameStateHistory.cs`: Speichert vergangene Spielzustände für das Zurückspulen (falls implementiert). `[ ]`
*   **Abhängigkeiten:** Viele andere Systeme.
*   **Status:** `[ ]`

### 1.3 SaveSystem
*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: Speicherstruktur]`
*   **Pfad:** `Assets/_Core/SaveSystem/`
*   **Benötigte Skripte:**
    *   `SaveManager.cs`: Logik zum Speichern und Laden des Spielerfortschritts. `[ ]`
    *   `PlayerProgress.cs`: Datenstruktur für den Spielerfortschritt. `[ ]`
*   **Abhängigkeiten:** Fast alle Systeme.
*   **Status:** `[ ]`

### 1.4 AudioManager
*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: Sound Design]`
*   **Pfad:** `Assets/_Core/AudioManager/`
*   **Benötigte Skripte:**
    *   `AudioManager.cs`: Steuert Musik und Soundeffekte. `[ ]`
*   **Abhängigkeiten:** UI, Combat.
*   **Status:** `[ ]`

### 1.5 Kartensystem (Basis)
*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: ZK-KARTENPROGRESSION-v1.5-.md]`, `[DESIGNDOC-REFERENZ: Kartenbasis]`
*   **Pfad:** `Assets/Cards/Base/`, `Assets/Cards/Data/`
*   **Benötigte Skripte:**
    *   `CardData.cs` (ScriptableObject): Basisdaten für alle Karten (ID, Name, Typ, Kosten, etc.). `[ ]`
    *   `CardInstance.cs`: Repräsentiert eine spezifische Karte im Spiel (im Deck, auf der Hand, im Spiel). `[ ]`
    *   `DeckManager.cs`: Verwaltet Spieler-Decks. `[ ]`
    *   `HandManager.cs`: Verwaltet Karten auf der Spielerhand. `[ ]`
    *   `CardEffectExecutor.cs`: Führt Karteneffekte aus. `[ ]`
*   **Abhängigkeiten:** Keine direkten.
*   **Status:** `[ ]`

### 1.6 Materialsystem
*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: Materialsystem]`
*   **Pfad:** `Assets/Economy/Materials/`
*   **Benötigte Skripte:**
    *   `MaterialData.cs` (ScriptableObject): Definition von Materialtypen. `[ ]`
    *   `InventoryManager.cs`: Verwaltet das Materialinventar des Spielers. `[ ]`
    *   `PlayerMaterials.cs`: Speichert den Materialbestand des Spielers. `[ ]`
*   **Abhängigkeiten:** Kartensystem (für Evolution).
*   **Status:** `[ ]`

### 1.7 Kampfsystem (Basis)
*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: Kampfsystem]`
*   **Pfad:** `Assets/Combat/BattleManager/`
*   **Benötigte Skripte:**
    *   `BattleManager.cs`: Steuert den Ablauf eines Kampfes. `[ ]`
    *   `PlayerController.cs`: Verarbeitet Spieleraktionen im Kampf. `[ ]`
    *   `EnemyAIController.cs`: Basis-KI für Gegner. `[ ]`
    *   `TurnManager.cs`: Verwaltet die Zugreihenfolge. `[ ]`
*   **Abhängigkeiten:** Kartensystem, Zeitsystem.
*   **Status:** `[ ]`

---

## 2. Klassenimplementierung

### 2.1 Chronomant
*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: Klassen - Chronomant]`
*   **Spezifische Skripte:**
    *   `ChronomancerSkills.cs`: Implementiert klassenspezifische Fähigkeiten und Zeitmanipulations-Boni. `[ ]`
*   **Abhängigkeiten:** Zeitsystem, Kartensystem.
*   **Status:** `[ ]`

### 2.2 Zeitwächter
*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: Klassen - Zeitwächter]`
*   **Spezifische Skripte:**
    *   `GuardianSkills.cs`: Implementiert defensive und zeitverzerrende Fähigkeiten. `[ ]`
*   **Abhängigkeiten:** Zeitsystem, Kartensystem.
*   **Status:** `[ ]`

### 2.3 Schattenschreiter
*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: Klassen - Schattenschreiter]`
*   **Spezifische Skripte:**
    *   `ShadeWalkerSkills.cs`: Implementiert auf Schaden und Ausweichen fokussierte Fähigkeiten. `[ ]`
*   **Abhängigkeiten:** Zeitsystem, Kartensystem.
*   **Status:** `[ ]`

---

## 3. Kartenimplementierung (Erweitert)

*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: ZK-KARTENPROGRESSION-v1.5-.md]`

### 3.1 Basis-Kartensystem
*   **Skripte:** Siehe Abschnitt 1.5
*   **Status:** `[ ]`

### 3.2 Leveling-System
*   **Benötigte Skripte:**
    *   `CardLeveling.cs`: Logik für das Sammeln von XP und Levelaufstiege von Karten. `[ ]`
    *   Erweiterungen in `CardInstance.cs`: Speicherung von Level und XP. `[ ]`
*   **Status:** `[ ]`

### 3.3 Evolution-System
*   **Benötigte Skripte:**
    *   `CardEvolution.cs`: Logik für die Evolution von Karten (Materialprüfung, Statusänderung). `[ ]`
    *   Erweiterungen in `CardData.cs`: Definition von Evolutionspfaden und Materialkosten. `[ ]`
*   **Abhängigkeiten:** Materialsystem.
*   **Status:** `[ ]`

### 3.4 Seltenheits-Gates und Attribut-Boosting
*   **Benötigte Skripte:**
    *   `RarityBoost.cs`: Wendet Attribut-Boosts basierend auf Seltenheit an. `[ ]`
    *   Erweiterungen in `CardData.cs`: Definition von Seltenheitsstufen. `[ ]`
*   **Status:** `[ ]`

### 3.5 Sockelsystem
*   **Benötigte Skripte:**
    *   `SocketSystem.cs`: Logik für das Hinzufügen und Entfernen von Sockel-Items. `[ ]`
    *   `SocketItemData.cs` (ScriptableObject): Definition von Sockel-Items und deren Effekten. `[ ]`
    *   Erweiterungen in `CardInstance.cs`: Speicherung gesockelter Items. `[ ]`
*   **Status:** `[ ]`

### 3.6 Zenit-System
*   **Benötigte Skripte:**
    *   `ZenithSystem.cs`: Logik für das Erreichen des Zenit-Status und Aktivierung der Zenit-Fähigkeit. `[ ]`
    *   Erweiterungen in `CardData.cs`: Definition der Zenit-Fähigkeit. `[ ]`
*   **Status:** `[ ]`

---

## 4. Gegner und Welten

*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: Gegner-DB]`, `[DESIGNDOC-REFERENZ: Welten]`

### 4.1 Zeitwirbel-Tal
*   **Gegnertypen:**
    *   `Zeitgeist`: Basis-Gegner. `[ ]`
    *   `Chronoschrecke`: Schneller Angreifer. `[ ]`
    *   `Verlorener Wächter`: Tank-Gegner. `[ ]`
*   **Kampffeld-Effekte:**
    *   `TemporalDistortionField.cs`: Verlangsamt zufällige Einheiten. `[ ]`
*   **Status:** `[ ]`

### 4.2 Flammen-Schmiede
*   **Gegnertypen:**
    *   `Lavaspucker`: Fernkämpfer mit Feuerschaden. `[ ]`
    *   `Gluthund`: Nahkämpfer mit Brenn-Effekt. `[ ]`
    *   `Schmiedegolem`: Stark gepanzerter Gegner. `[ ]`
*   **Kampffeld-Effekte:**
    *   `BurningGround.cs`: Verursacht periodischen Feuerschaden. `[ ]`
*   **Status:** `[ ]`

*(Weitere Welten hier hinzufügen)*

---

## 5. UI und Spielflow

*   **Quelldokumente:** `[DESIGNDOC-REFERENZ: UI-Mockups]`, `[DESIGNDOC-REFERENZ: Spielfluss]`

### 5.1 Hauptmenü und Navigation
*   **Benötigte Elemente/Skripte:**
    *   `MainMenuController.cs`: Logik für Hauptmenü-Buttons. `[ ]`
    *   `SceneLoader.cs`: Lädt verschiedene Spielszenen. `[ ]`
*   **Status:** `[ ]`

### 5.2 Kampfbildschirm
*   **Benötigte Elemente/Skripte:**
    *   `BattleUIController.cs`: Aktualisiert HP, Mana, Kartenhand etc. `[ ]`
    *   `CardDisplayUI.cs`: Visuelle Darstellung von Karten. `[ ]`
    *   `TargetingSystemUI.cs`: Spieler-Feedback für Zielauswahl. `[ ]`
*   **Abhängigkeiten:** Kampfsystem, Kartensystem.
*   **Status:** `[ ]`

### 5.3 Inventar und Materialienbildschirm
*   **Benötigte Elemente/Skripte:**
    *   `InventoryUIController.cs`: Zeigt gesammelte Materialien an. `[ ]`
    *   `MaterialDisplayUI.cs`: Visuelle Darstellung von Materialien. `[ ]`
*   **Abhängigkeiten:** Materialsystem.
*   **Status:** `[ ]`

### 5.4 Level-Auswahl
*   **Benötigte Elemente/Skripte:**
    *   `WorldMapController.cs`: Navigation auf der Weltkarte. `[ ]`
    *   `LevelSelectNodeUI.cs`: Interaktive Knoten für Levelauswahl. `[ ]`
*   **Status:** `[ ]`

### 5.5 Quests und Dialogsystem
*   **Benötigte Elemente/Skripte:**
    *   `QuestManager.cs`: Verfolgt aktive und abgeschlossene Quests. `[ ]`
    *   `DialogueManager.cs`: Zeigt Dialoge an und verarbeitet Spielerantworten. `[ ]`
    *   `QuestLogUI.cs`: Anzeige des Questfortschritts. `[ ]`
*   **Status:** `[ ]`

---

## 6. Implementierungsreihenfolge und Abhängigkeiten

*Ziel: Eine logische Reihenfolge definieren, um Abhängigkeiten aufzulösen und iterative Tests zu ermöglichen.*

**Phase 1: Kernsysteme Basis**
1.  Kartensystem (Basis: `CardData`, `CardInstance`) `[ ]`
2.  Materialsystem (Basis: `MaterialData`, `InventoryManager`) `[ ]`
3.  Kampfsystem (Basis: `BattleManager`, `TurnManager`, einfache Gegner-KI) `[ ]`
4.  Basis UI (Kampfbildschirm Grundgerüst) `[ ]`

**Phase 2: Kernmechanik Zeit & Kartenprogression**
1.  Zeitsystem (Basis: `TimeManager`, `GameStateHistory`) `[ ]`
2.  Karten Leveling & Evolution `[ ]`
3.  Materialien in Evolution integrieren `[ ]`
4.  UI für Inventar/Materialien `[ ]`

**Phase 3: Klassen & Erweiterte Kartensysteme**
1.  Implementierung der Klassen-Fähigkeiten (Chronomant zuerst?) `[ ]`
2.  Seltenheitssystem & Boosting `[ ]`
3.  Sockelsystem `[ ]`
4.  Zenit-System `[ ]`

**Phase 4: Welten, Gegner & Spielfluss**
1.  Erste Welt (Zeitwirbel-Tal) mit Gegnern und Effekten `[ ]`
2.  Level-Auswahl UI `[ ]`
3.  Hauptmenü & Szenenübergänge `[ ]`

**Phase 5: Quests & Politur**
1.  Quest- und Dialogsystem `[ ]`
2.  Weitere Welten und Gegner `[ ]`
3.  Balancing, Bugfixing, Performance-Optimierung `[ ]`

*(Diese Reihenfolge ist ein Vorschlag und kann angepasst werden.)*
