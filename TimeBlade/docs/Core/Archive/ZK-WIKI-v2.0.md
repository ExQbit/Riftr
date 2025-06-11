# ZK-WIKI - Zeitklingen Wiki (v2.1 - 20250521)

## Änderungshistorie
- **v2.2 (2025-05-22):** Radikale Vereinfachung: Entfernung Sockelsystem, weltspezifische Feld-Mechaniken, klassenspezifische Welteffekte. Gates erfolgen automatisch ohne Materialkosten.
- **v2.0 (2025-05-21):** Vollständige Revision für das vereinfachte Materialsystem mit nur fünf Materialtypen (Zeitkern, Elementarfragment, Seltene Essenz, Zeitfokus) und Integration des modernisierten Zeitkern-Systems ("1 Zeitkern = 1 Level" statt XP-System). Aktualisierung aller Abschnitte, insbesondere 2.3, 2.4, 5.1-5.7 und 9.2-9.3. Entfernung aller XP-Referenzen und Aktualisierung aller Dokumentreferenzen auf neueste Versionen. Hinzufügung einer neuen Materialsystem-Visualisierung und des neuen Zeitkernkit-Konzepts.
- **v1.4 (2025-04-29):** Integration der detaillierten Spielerprogression (Tutorial, Welten 1-5) und der Monetarisierungsstrategie aus `Zeitklingen: Integriertes Gesamt-Design-Dokument (v2.1).md`. Struktur aus v1.3 beibehalten und erweitert.
- **v1.3 (2025-04-22):** Integration finaler Definitionen aus `Finale Definition...`: Pity Timer, Fassungskosten. Integration Klärungen aus `Gebündelte Aufgaben.txt`: Max Level, DoT Stark+, Passive Schattenschreiter, Zeitwächter Kombos. Integration finaler Evo-Level. Aktualisierung Pacing-Ziele. Integration Attribut-Skalierung/Reroll-Attribute. Referenzen auf finale Versionen aktualisiert (`KartenProgression-v1.5`, `MAT-v1.4`, `Hooks-v1.3`). Alle Abschnitte vollständig ausformuliert.
- **v1.2 (2025-04-22):** Anpassung an finale Balancing-Werte: Attribut-Boosts (+10%/+20%/+30%/+45%), finales Reroll-System (Standard/Gezielt/Garantiert), aktualisierte Pacing-Ziele/Zeit-Schätzungen. Referenzen aktualisiert. Alle Abschnitte vollständig ausformuliert.
- **v1.1 (2025-04-22):** Überarbeitung von Konzept, Mechaniken, Progression basierend auf finalem Balancing (Progressive Unlock, Continuous Leveling, Rarity-System Boost/Reroll). Ersetzung Abschnitt 5.
- **v1.0 (25.03.2025):** Initiale Dokumentation des Spielkonzepts.

---

**Inhaltsverzeichnis**

- [1. Einführung](#1-einführung)
  - [1.1 Spielkonzept](#11-spielkonzept)
  - [1.2 Schlüsselmechaniken](#12-schlüsselmechaniken)
  - [1.3 Versionshistorie](#13-versionshistorie)
- [2. Grundsysteme](#2-grundsysteme)
  - [2.1 Zeitsystem](#21-zeitsystem)
  - [2.2 DoT-Kategoriesystem](#22-dot-kategoriesystem)
  - [2.3 Materialsystem (Vereinfacht)](#23-materialsystem-vereinfacht)
  - [2.4 Zeitkern-System & Kartenprogression](#24-zeitkern-system--kartenprogression)

- [3. Klassen](#3-klassen)
  - [3.1 Chronomant](#31-chronomant)
  - [3.2 Zeitwächter](#32-zeitwächter)
  - [3.3 Schattenschreiter](#33-schattenschreiter)
- [4. Welten](#4-welten)
  - [4.1 Welt 1: Zeitwirbel-Tal](#41-welt-1-zeitwirbel-tal)
  - [4.2 Welt 2: Flammen-Schmiede](#42-welt-2-flammen-schmiede)
  - [4.3 Welt 3: Eiszeit-Festung](#43-welt-3-eiszeit-festung)
  - [4.4 Welt 4: Gewittersphäre](#44-welt-4-gewittersphäre)
  - [4.5 Welt 5: Chronos-Nexus](#45-welt-5-chronos-nexus)
- [5. Spielerprogression und Onboarding](#5-spielerprogression-und-onboarding)
  - [5.1 Tutorial-Phase (FTUE, 0-2 Stunden)](#51-tutorial-phase-ftue-0-2-stunden)
  - [5.2 Welt 1: Zeitwirbel-Tal (2-9 Stunden)](#52-welt-1-zeitwirbel-tal-2-9-stunden)
  - [5.3 Welt 2: Flammen-Schmiede (9-35 Stunden)](#53-welt-2-flammen-schmiede-9-35-stunden)
  - [5.4 Welt 3: Eiszeit-Festung (35-90 Stunden)](#54-welt-3-eiszeit-festung-35-90-stunden)
  - [5.5 Welt 4: Gewittersphäre (90-180 Stunden)](#55-welt-4-gewittersphäre-90-180-stunden)
  - [5.6 Welt 5: Chronos-Nexus (180-280 Stunden)](#56-welt-5-chronos-nexus-180-280-stunden)
  - [5.7 Endgame: Meisterschaftssystem & Zeitlose Kammer](#57-endgame-meisterschaftssystem--zeitlose-kammer)
  - [5.8 Schwierigkeitsstufen](#58-schwierigkeitsstufen)
- [6. Kartenreferenz](#6-kartenreferenz)
  - [6.1 Chronomant-Karten](#61-chronomant-karten)
  - [6.2 Zeitwächter-Karten](#62-zeitwächter-karten)
  - [6.3 Schattenschreiter-Karten](#63-schattenschreiter-karten)
- [7. Gameplay-Strategien](#7-gameplay-strategien)
  - [7.1 Chronomant-Strategien](#71-chronomant-strategien)
  - [7.2 Zeitwächter-Strategien](#72-zeitwächter-strategien)
  - [7.3 Schattenschreiter-Strategien](#73-schattenschreiter-strategien)
- [8. Monetarisierungsstrategie](#8-monetarisierungsstrategie)
  - [8.1 Philosophie](#81-philosophie)
  - [8.2 Premium-Währung: Zeitkristalle](#82-premium-währung-zeitkristalle)
  - [8.3 Strategische Angebote & Battle Pass](#83-strategische-angebote--battle-pass)
  - [8.4 Wiederkehrende Angebote & Kosmetika](#84-wiederkehrende-angebote--kosmetika)
  - [8.5 Service-Optionen & Fairness](#85-service-optionen--fairness)
- [9. Balancing Übersicht](#9-balancing-übersicht)
  - [9.1 Spielerprogression KPIs](#91-spielerprogression-kpis)
  - [9.2 Materialprogression Zusammenfassung](#92-materialprogression-zusammenfassung)
  - [9.3 Materialökonomie Zusammenfassung](#93-materialökonomie-zusammenfassung)
  - [9.4 Power-Level Progression (Relativ)](#94-power-level-progression-relativ)
- [10. Abhängige Dokumente](#10-abhängige-dokumente)

---

## 1. Einführung

### 1.1 Spielkonzept

Zeitklingen ist ein innovatives zeit-basiertes Kartenspiel mit strategischer Tiefe. In dieser einzigartigen Spielwelt ist Zeit die einzige Ressource. Kämpfe finden innerhalb eines 60-Sekunden-Zeitlimits statt, und jede gespielte Karte verbraucht Zeit. Anstatt zufällig neue Karten zu sammeln, **schalten Spieler schrittweise Karten aus einem definierten Pool frei**, der für ihre gewählte Klasse verfügbar ist. Der Fokus liegt auf der **Verbesserung und Spezialisierung** dieser freigeschalteten Karten durch ein vielschichtiges, aber intuitives Progressionssystem mit vier klar definierten Materialtypen (Zeitkern, Elementarfragment, Seltene Essenz, Zeitfokus).

Das Spiel legt Wert auf strategische Entscheidungen und präzises Timing. Während die Kernprogression (Leveling mit Zeitkernen, Evolutionswahl mit Elementarfragmenten) deterministisch ist, bieten Endgame-Systeme (Seltenheits-Boosts, Rerolls mit Zeitfokus) Möglichkeiten zur Optimierung mit kontrollierten Zufallselementen.

### 1.2 Schlüsselmechaniken

- **Zeit als einzige Ressource**: 60-Sekunden-Timer statt traditioneller Ressourcen.
- **Progressive Kartenfreischaltung**: Spieler starten mit wenigen Karten und schalten den Rest des Klassenpools durch Spielfortschritt frei.
- **Direktes Leveling mit Zeitkernen**: Jeder Zeitkern erhöht das Level einer Karte um 1 (max. Level 50).
- **Zeitkernkit-System**: Ermöglicht gezielte Kartenauswahl beim Leveln nach 3 abgeschlossenen Tagesquests.
- **Automatische Gates**: Bei Level 10, 20, 30, 40 erfolgt automatisches Seltenheits-Upgrade ohne Materialkosten.
- **Karten-Seltenheit (Gewöhnlich bis Legendär)**: Beeinflusst visuelle Darstellung und ermöglicht Optimierung durch zufällige Attribut-Boosts (**+10% bis +45%**).
- **Attribut-Boost Reroll mit Zeitfokus**: Möglichkeit, den zufälligen Attribut-Boost neu auszuwürfeln (**Standard**, **Gezielt**, **Garantiert**).
- **Elementare Evolution mit Elementarfragmenten**: Jede Karte kann in eine Feuer-, Eis- oder Blitzvariante entwickelt werden, was ihre Funktion grundlegend ändert. Freischaltung bei **Lvl 9 / 25 / 35**.
- **DoT-Kategoriesystem**: Standardisierte Damage-over-Time-Effekte mit festen Zeitgewinnen (inkl. Stark+ mit 2,5s).


- **Pity-Timer-System**: Garantiert Materialdrops nach einer Serie erfolgloser Versuche.

### 1.3 Versionshistorie

| Version | Datum | Wichtige Änderungen |
|---------|-------|---------------------|
| v2.1 | 2025-05-21 | Vereinfachung der Spielmechaniken durch Entfernung des Sockelsystems und des Zenit-Systems (für spätere Erweiterungen ausgelagert). Entfernung aller Kampffeld-Effekte und Standardisierung des Bossverhaltens für alle Klassen. |
| v2.0 | 2025-05-21 | Vollständige Revision für das vereinfachte Materialsystem mit fünf Materialtypen und Integration des modernisierten Zeitkern-Systems. |
| v1.4 | 2025-04-29 | Integration der detaillierten Spielerprogression und Monetarisierungsstrategie. |
| v1.3 | 2025-04-22 | Integration finaler Balancing-Definitionen. Aktualisierung Pacing-Ziele. Referenzen aktualisiert. |
| v1.2 | 2025-04-22 | Anpassung an finale Balancing-Werte. Aktualisierung der Pacing-Ziele/Zeit-Schätzungen. |
| v1.1 | 2025-04-22 | Überarbeitung von Konzept, Mechaniken, Progression basierend auf finalem Balancing. |
| v1.0 | 2025-03-25 | Initiale Dokumentation des Spielkonzepts. |

---

## 2. Grundsysteme

### 2.1 Zeitsystem
*(Siehe `ZK-TIME-v1.2-.md`)*
Zeit ist die einzige Ressource, Kämpfe sind auf 60s limitiert. Karten kosten Zeit zum Spielen. Mechaniken umfassen Zeitverbrauch, Zeitrückgewinnung, Zeitdiebstahl und Zeitmanipulation (Beschleunigung/Verlangsamung).

### 2.2 DoT-Kategoriesystem
*(Siehe `ZK-TIME-v1.2-.md`)*
Standardisiert DoTs in Kategorien (Schwach, Mittel, Stark, Stark+) mit festen Zeitgewinnwerten (0,5s, 1,0s, 2,0s, 2,5s), die sofort bei Anwendung ausgelöst werden (max. 6s pro Kampf).

### 2.3 Materialsystem (Vereinfacht)
*(Siehe `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`)*

Das vereinfachte Materialsystem reduziert die Komplexität auf fünf klar definierte Materialtypen mit dem Prinzip "Ein Material, ein Zweck":

| Material | Hauptfunktion | Relative Seltenheit | Primäre Quellen |
|----------|---------------|---------------------|-----------------|
| **Zeitkern** | Kartenleveling (1 = 1 Level) | Häufig | Kämpfe, Quests, Events |
| **Elementarfragment** | Evolution (Stufe 1/2/3) | Mittel | Elite-Gegner, Mini-Bosse |
| **Seltene Essenz** | Gate-Durchbrüche (1/2/3/4) | Selten | Mini-Bosse, Dungeon-Bosse |
| **Zeitfokus** | Attribut-Rerolls (1/3/5) | Mittel | Quests, Events, Kammer |


![Vereinfachtes Materialsystem](../Assets/MaterialSystem_v2.0.png)

Dieses vereinfachte System bietet folgende Vorteile:
- **Klare Funktionszuordnung**: Jedes Material hat genau einen Verwendungszweck
- **Intuitive Skalierung**: Linear ansteigende Materialmengen (1/2/3/4)
- **Visuelle Klarheit**: Jedes Material hat ein einzigartiges Design
- **Reduzierte kognitive Belastung**: Einfachere Entscheidungen für Spieler
- **Pity-Timer-System**: Garantiert Materialdrops nach einer Serie erfolgloser Versuche

Jedes Material entspricht einer klaren Spielentscheidung:
- **Zeitkerne**: "Welche Karten will ich verstärken?"
- **Elementarfragmente**: "Wie will ich meine Kartenfunktion spezialisieren?"
- **Seltene Essenzen**: "Welche Karten sollen die nächste Qualitätsstufe erreichen?"
- **Zeitfokus**: "Wie optimiere ich meine Karten für maximale Synergie?"


### 2.4 Zeitkern-System & Kartenprogression
*(Siehe `ZK-ZEITKERN-SYSTEM-v1.0.md` und `ZK-KARTENPROGRESSION-v2.1.md`)*

Das modernisierte Zeitkern-System ersetzt das traditionelle XP-System durch eine direkte, intuitive Mechanik:

#### 2.4.1 Leveling mit Zeitkernen
- **Grundprinzip**: 1 Zeitkern = 1 Level-Aufstieg für eine Karte
- Karten können bis Level 50 verbessert werden (benötigen insgesamt 50 Zeitkerne)
- Levelups erhöhen Basisattribute der Karte gemäß definierter Skalierung:
  - Level 1-10: +3% pro Level
  - Level 11-20: +4% pro Level
  - Level 21-30: +5% pro Level
  - Level 31-40: +6% pro Level
  - Level 41-50: +7% pro Level
- Zeitkerne werden durch Kämpfe, Quests und Events erhalten

#### 2.4.2 Zeitkernkit-System
- **Zeitkernkits** ergänzen die direkte Zeitkern-Verwendung
- Erhalten nach je 3 abgeschlossenen Tagesquests oder durch Events
- Bietet Auswahl aus zwei zufälligen Basiskarten und all ihren Varianten
- Ermöglicht gezieltes Leveln strategisch wichtiger Karten
- Verhindert Frustration durch Zeitkern-Zufallsverteilung

![Zeitkernkit-Interface](../Assets/Zeitkernkit_v2.0.png)

#### 2.4.3 Seltenheits-Gates mit Seltenen Essenzen
- Bei Level 10, 20, 30, 40 ist ein Seltenheits-Upgrade nötig, um weiterzuleveln
- Jedes Gate erfordert Seltene Essenzen (1/2/3/4× je nach Gate)
- Gate-Durchbrüche gewähren zufällige Attribut-Boosts (+10/20/30/45%)
- Attribut-Boosts können mit Zeitfokus neu ausgewürfelt werden

#### 2.4.4 Evolution mit Elementarfragmenten
- Evolutionen bei Level 9, 25, 35 spezialisieren die Kartenfunktion
- Drei Evolutionspfade: Feuer, Eis, Blitz
- Jede Evolutionsstufe kostet Elementarfragmente (1/2/3×)
- Wahl des Pfades bei Stufe 1 legt Richtung für alle weiteren Stufen fest

---

## 3. Klassen

### 3.1 Chronomant
*(Siehe `ZK-CLASS-MAGE-v1.6-.md`)*
- **Kernmechanik:** Zeitliche Arkankraft (0-5 Punkte, generiert durch Karten, verstärkt Effekte, Bruch bei 5).
- **Sekundärmechanik:** Zeitstrom-Resonanz (Wechsel zwischen Beschleunigt/Verlangsamt durch Kartenreihenfolge).
- **Spielstil:** Strategisches Management der Arkankraft, Nutzen von Elementar-Synergien und Zeitmanipulation.
- **Optimale Materialverwendung:** Fokus auf Zeitfokus für gezielte Rerolls von Arkankraft-Attributen.

### 3.2 Zeitwächter
*(Siehe `ZK-CLASS-WAR-v1.8.3-.md`)*
- **Kernmechanik:** Schildmacht (0-5 Punkte, generiert durch Blocks, passive Boni, Bruch bei 5).
- **Passive:** Zeitlicher Wächter (Phasen-Boni), Schild-Schwert-Zyklus (Kombo-Boni).
- **Spielstil:** Defensive Kontrolle, Blocken und Kontern, methodische Eskalation durch Schildmacht.
- **Optimale Materialverwendung:** Ausgewogene Verteilung von Elementarfragmenten für defensive und offensive Evolutionen.

### 3.3 Schattenschreiter
*(Siehe `ZK-CLASS-ROG-v2.4-.md`)*
- **Kernmechanik:** Momentum-System (0-5 Punkte, generiert durch Kartenspiel, Schwellenboni, Bruch bei 5).
- **Synergie:** Schattensynergie (Schattenkarte → nächste Angriffskarte kostet 0 Zeit).
- **Sekundäre Mechanik:** Zeitsplitter (Zeitdiebstahl-Effekte).
- **Spielstil:** Hohes Tempo, Kombos, Ausweichen, Zeitdiebstahl, Management von Momentum und Schattensynergie.
- **Optimale Materialverwendung:** Priorisierung von Zeitkernen für Schlüsselkarten und Zeitfokus für Synergie-Attribute.

---

## 4. Welten

*(Siehe `ZK-DUN-MECH-COMP-.md`)*

### 4.1 Welt 1: Zeitwirbel-Tal

- **Klassenbalance:** Ausgeglichen.
- **Hauptmaterialien:** Zeitkerne, wenige Elementarfragmente.

### 4.2 Welt 2: Flammen-Schmiede

- **Klassenbalance:** Chronomant > Schattenschreiter > Zeitwächter.
- **Hauptmaterialien:** Zeitkerne, Elementarfragmente, erste Seltene Essenzen.

### 4.3 Welt 3: Eiszeit-Festung

- **Klassenbalance:** Zeitwächter > Chronomant > Schattenschreiter.
- **Hauptmaterialien:** Zeitkerne, Elementarfragmente, Seltene Essenzen, erste Zeitfokus.

### 4.4 Welt 4: Gewittersphäre

- **Klassenbalance:** Schattenschreiter > Chronomant > Zeitwächter.
- **Hauptmaterialien:** Zeitkerne, Elementarfragmente, Seltene Essenzen, Zeitfokus.

### 4.5 Welt 5: Chronos-Nexus

- **Klassenbalance:** Ausgeglichen.
- **Hauptmaterialien:** Alle fünf Materialtypen in höheren Mengen.

---

## 5. Spielerprogression und Onboarding

### 5.1 Tutorial-Phase (FTUE, 0-2 Stunden)

- **Ziel:** Kernmechaniken (Karte spielen, Zeit, Klasse) einführen, erste Erfolgserlebnisse, Fundament legen.
- **Minute 0-30 (Phase 1 - Grundlagen):** 
  - Starterdeck (8 Karten, wenige Uniques)
  - Kernmechanik-Einführung (Zeitressource, Karten spielen)
  - Erster Kampf gegen "Zeitschleifer" (10HP)
  - Erste Zeitkern-Drops (garantiert 3×)
  - Direktes Level-Up einer Karte durch Zeitkern-Verwendung
  - Dialog: "Ein Zeitkern erhöht das Level deiner Karte direkt um 1. Wähle weise!"
  - Hinweis auf Klassenstufen-System
- **Minute 30-60 (Phase 2 - Zeitmanipulation & Klasse):** 
  - Gegner "Kristallwächter" (25HP)
  - Weitere Zeitkern-Drops (garantiert 5×)
  - Freischaltung erster Defensiv-/Kontrollkarte nach Sieg
  - Einführung klassenspezifischer Kernmechanik
  - Tutorial zum Class XP System
  - Dialog: "Mit genug Zeitkernen kannst du deine liebsten Karten stärker machen!"
- **Minute 60-120 (Phase 3 - Elementar & Material):** 
  - Erster Dungeon "Zerbrochene Chronologie"
  - Gegner "Chrono-Anomalie" (40HP)
  - Freischaltung erster Effizienz-/Ressourcenkarte
  - Einführung des Elementar-/DoT-Konzepts 
  - Vorstellung aller fünf Materialtypen und ihrer speziellen Funktionen
  - Erstes Elementarfragment-Drop (garantiert)
  - Dialog: "Mit diesen fünf Materialien kannst du deine Karten auf verschiedene Weise verbessern."

### 5.2 Welt 1: Zeitwirbel-Tal (2-9 Stunden)

- **Thema/Gegner:** Temporale Störungen, Zeitrisse, Zeitschleifer/Nebel/Wächter etc.

- **Hauptmaterialien:** Zeitkerne (häufig), Elementarfragmente (selten).
- **Progression:**
    - **~3-4h:** 
        - Mini-Bosse "Tempus-Verschlinger", "Kristall-Chronologe"
        - Freischaltung seltener Utility-Karten
        - Erste zuverlässige Elementarfragment-Drops
        - Einführung täglicher Quests (1-3 Zeitkerne pro Quest)
    - **~5-6h:** 
        - Welt-Boss "Nebelwandler" 
        - **Erste Legendäre Signaturkarte** freischaltbar
        - Schmied-Freischaltung
        - Dialog: "Der Schmied kann dir helfen, deine Karten weiter zu verbessern!"
    - **~9h:** 
        - Erreichen von Kartenlevel 9/10 (durch ~9-10 Zeitkerne)
        - **Evo 1** (1× Elementarfragment) wird möglich

        - **Gate 1** (Common→Uncommon, 1× Seltene Essenz) wird möglich
        - Tutorial für alle drei Systeme
        - Dialog: "Du hast jetzt Zugang zu den wichtigsten Verbesserungssystemen!"

### 5.3 Welt 2: Flammen-Schmiede (9-35 Stunden)

- **Thema/Gegner:** Vulkanisch, Feuer & Zeit, DoT-Gegner.

- **Hauptmaterialien:** Zeitkerne (häufig), Elementarfragmente (moderat), erste Seltene Essenzen.
- **Progression:**
    - **~9-10h:** 
        - Start Welt 2
        - Aktive Nutzung von **Evolution & Sockel 1**
        - Tägliche Quests liefern regelmäßig Zeitkerne und gelegentlich Elementarfragmente
        - Tutorial: "Manche Elite-Gegner droppen besonders viele Elementarfragmente!"
    - **~12-15h:** 
        - Zeitlose Kammer Einführung
        - Erste **Zeitkernkits** nach je 3 abgeschlossenen Tagesquests
        - Tutorial zum Zeitkernkit-System: "Wähle gezielt, welche Karten du verbessern möchtest!"
    - **~16-20h:** 
        - Dungeon "Die Chrono-Esse"
        - Freischaltung epischer Spezialkarten
        - Erste Zeitfokus-Drops (selten)
        - Dialog: "Zeitfokus wird später wichtig, um deine Karten zu optimieren."
    - **~25-30h:** 
        - **Klassenstufe 5** erreichbar (Pfad des Novizen abgeschlossen)
        - Erster Klassenbonus freigeschaltet
        - Verbesserte Zeitkern-Droprate in allen Kämpfen
    - **~30-35h:** 
        - Welt-Boss "Erzsiederin Ignium" 
        - **Zweite Legendäre Signaturkarte** freigeschaltet

        - Dialog: "Mit deinen gesammelten Materialien bist du bereit für die nächste Herausforderung!"

### 5.4 Welt 3: Eiszeit-Festung (35-90 Stunden)

- **Thema/Gegner:** Eis & Zeit, Kristallin, Slow/Freeze-Gegner.

- **Hauptmaterialien:** Zeitkerne, Elementarfragmente, Seltene Essenzen, erste Zeitfokus.
- **Progression:**
    - **~35h:** 
        - Start Welt 3
        - **Gate 2** (Uncommon→Rare, 2× Seltene Essenz) verfügbar

        - Level 20 bei ersten Hauptkarten erreicht (durch ~20 Zeitkerne)
        - Freischaltung letzter einzigartiger Karten
        - Ausführliche Einführung des **Zeitfokus-Systems für Rerolls**
        - Tutorial: "Mit Zeitfokus kannst du die zufälligen Attribut-Boosts neu würfeln!"
        - Pity-Timer-System für alle Materialien wird aktiv
    - **~60h:** 
        - **Evolution Stufe 2** verfügbar (Level 25 erreicht, 2× Elementarfragment)
        - Deutlich stärkere Evolutionseffekte werden freigeschaltet
        - Zeitkernkits werden verbessert (mehr Auswahlmöglichkeiten)
        - Dialog: "Deine Karten erreichen jetzt eine neue Evolutionsstufe!"
    - **~75-80h:** 
        - **Klassenstufe 10** erreichbar (Prüfung des Adepten)
        - Zweiter Klassenbonus freigeschaltet
        - Verbesserte Droprate für alle Materialien
        - Neue strategische Deckoptionen werden verfügbar

### 5.5 Welt 4: Gewittersphäre (90-180 Stunden)

- **Thema/Gegner:** Schwebende Inseln, Gewitter, Ketten/Resonanz-Gegner.

- **Hauptmaterialien:** Zeitkerne, Elementarfragmente, Seltene Essenzen, Zeitfokus.
- **Progression:**
    - **~90h:** 
        - Start Welt 4
        - **Gate 3** (Rare→Epic, 3× Seltene Essenz) verfügbar
        - Level 30 bei Hauptkarten erreicht (durch ~30 Zeitkerne)
        - Verbesserte Zeitkernkit-Optionen werden freigeschaltet
        - Tutorial: "Die Epic-Seltenheitsstufe bietet +30% Boost auf ein Attribut!"
        - Gezielte Reroll-Optionen mit Zeitfokus werden wichtiger
    - **~130h:** 
        - **Klassenstufe 15** erreichbar (Ritual des Meisters)
        - Dritter Klassenbonus freigeschaltet
        - Verbesserte Droprate für alle Materialien
        - Spezielle wöchentliche Herausforderungen mit garantierten Materialbelohnungen
    - **~135h:** 
        - **Evolution Stufe 3** verfügbar (Level 35 erreicht, 3× Elementarfragment)
        - Höchste Evolutionsstufe bietet transformative Karteneffekte
        - Dialog: "Die höchste Evolutionsstufe ändert deine Karten fundamental!"

### 5.6 Welt 5: Chronos-Nexus (180-280 Stunden)

- **Thema/Gegner:** Konvergenz der Zeitlinien, Elementar/Echo/Zeitlinien-Gegner.

- **Hauptmaterialien:** Alle fünf Materialtypen in höheren Mengen.
- **Progression:**
    - **~180h:** 
        - Start Welt 5
        - **Gate 4** (Epic→Legendary, 4× Seltene Essenz) verfügbar
        - **Klassenstufe 20** erreichbar
        - Level 40 bei Hauptkarten erreicht (durch ~40 Zeitkerne)
        - Höchste Seltenheitsstufe bietet +45% Boost auf ein Attribut
        - Garantierter Zeitfokus-Drop für optimierte Reroll-Strategien
        - Tutorial: "Die legendäre Seltenheitsstufe ist die stärkste im Spiel!"
    - **~250h:** 
        - **Klassenstufe 25** erreichbar (Zeitl. Transzendenz)
        - Fünfter Klassenbonus freigeschaltet
        - **Meisterschaftssystem-Freischaltung**
        - Dialog: "Als Meister der Zeit kannst du nun deine Kräfte weiter spezialisieren."
        - Alle Materialien droppen in erhöhten Mengen
    - **Post Lvl 45 / W5 Heroic / Meister 10:** 
        - Weltzugang 5
    - **~280h:** 
        - Erreichen von **Maximallevel 50** bei Hauptkarten
        - Benötigt insgesamt 50 Zeitkerne pro Karte
        - Vollständige Optimierung mit allen fünf Materialtypen
        - Dialog: "Du hast das Maximum erreicht, doch die Zeitlose Kammer stellt dich immer neu auf die Probe."

### 5.7 Endgame: Zeitlose Kammer

- **Zeitlose Kammer:** 
  - Unendlicher Dungeon mit skalierender Schwierigkeit 
  - Zeitkern/Elementarfragment/Zeitfokus als Hauptbelohnungen

### 5.8 Schwierigkeitsstufen
- **Normal:** Basis-Schwierigkeit
- **Heroisch:** +50% Droprate aller Materialien
- **Legendär:** +100% Droprate aller Materialien

---

## 6. Kartenreferenz

### 6.1 Chronomant-Karten
*(Siehe `ZK-CLASS-MAGE-v1.6-.md`)*
### 6.2 Zeitwächter-Karten
*(Siehe `ZK-CLASS-WAR-v1.8.3-.md`)*
### 6.3 Schattenschreiter-Karten
*(Siehe `ZK-CLASS-ROG-v2.4-.md`)*

---

## 7. Gameplay-Strategien

### 7.1 Chronomant-Strategien
*(Siehe `ZK-CLASS-MAGE-v1.6-.md`)*
- **Frühphase (Lvl 1-20):** Fokus auf Arkankraft-Generierung und Zeitkern-Sammlung für Schlüsselkarten.
- **Mittlere Phase (Lvl 20-40):** Evolution mit Elementarfragmenten für Elementar-Synergien, Seltene Essenzen für Gates.
- **Endgame:** Zeitfokus für gezielte Rerolls von Arkankraft-Attributen, Vorbereitung auf Zenit.

### 7.2 Zeitwächter-Strategien
*(Siehe `ZK-CLASS-WAR-v1.8.3-.md`)*
- **Frühphase (Lvl 1-20):** Ausgewogene Verteilung von Zeitkernen auf defensive und offensive Karten.
- **Mittlere Phase (Lvl 20-40):** Sockelsteine für defensive Verstärkung, Evolution mit Elementarfragmenten für Blocksynergien.
- **Endgame:** Balance zwischen allen fünf Materialien, Optimierung des Schild-Schwert-Zyklus.

### 7.3 Schattenschreiter-Strategien
*(Siehe `ZK-CLASS-ROG-v2.4-.md`)*
- **Frühphase (Lvl 1-20):** Zeitkerne priorisieren für Schattenkarten und Momentum-Generatoren.
- **Mittlere Phase (Lvl 20-40):** Fokus auf Elementarfragmente für Blitz-Evolutionen, Zeitfokus für Rerolls.
- **Endgame:** Spezialisation auf Zeitdiebstahl und Tempo-Mechaniken.

---

## 8. Monetarisierungsstrategie

### 8.1 Philosophie
- **Fairness:** Vollständig spielbar ohne Ausgaben (F2P). Alle fünf Materialtypen sind erspielbar.
- **Komfort & Kosmetik:** Fokus auf "Pay for Convenience" (Zeitsparer, Beschleunigung) und kosmetische Items.
- **Progressive Preisstruktur:** Sanfter Einstieg mit günstigen Angeboten, steigende Preise für wiederkehrende Käufe oder Endgame-Optimierung.

### 8.2 Premium-Währung: Zeitkristalle
- Kaufbar für Echtgeld.
- **Hauptverwendungen:**
  - Materialpakete (begrenzte Mengen aller fünf Materialtypen)
  - Direkte Zeitkernkit-Käufe (max. 3/Tag)
  - Premium Battle Pass
  - Kosmetika (Kartenrahmen, Effekte, Avatare)
- In kleinen Mengen auch F2P erhältlich (Events, Login, etc.).

### 8.3 Strategische Angebote & Battle Pass
- **Zeitlich abgestimmte Angebote:** Pakete werden an psychologisch relevanten Punkten angeboten (nach Erfolg/Frust, vor Herausforderungen), beginnend mit €0,99.
- **Zeitloser Pfad (Battle Pass):** Monatlich (~€4.99), bietet kostenlose Belohnungsspur und optionale Premium-Spur mit mehr/besseren Materialien.

### 8.4 Wiederkehrende Angebote & Kosmetika
- **Tägliche/Wöchentliche Angebote:** Kleine, rotierende Pakete mit progressiven Preisen.
- **Kosmetika:** Direkter Kauf von Kartenrahmen, Effekten, Avataren, Titeln.
- **Event-Angebote:** Zeitlich limitierte Pakete passend zu Events.

### 8.5 Service-Optionen & Fairness
- **Optionale Käufe:** Meisterschafts-Reset, zusätzliche Loadouts, Inventarplätze etc. gegen Zeitkristalle.
- **Kein Pay-to-Win:** Premium-Vorteil liegt primär in beschleunigter Progression (~20-30% schneller), nicht im Zugang zu exklusiver Macht.
- **Limits:** Begrenzung für den Kauf spielstarker Vorteile (z.B. max. 2 Meisterschaftspunkte/Monat via Echtgeld).

---

## 9. Balancing Übersicht

### 9.1 Spielerprogression KPIs

*(Zeiten sind F2P-Schätzungen)*
| Meilenstein | Zeit (ca.) | Materialanforderung | Validierung |
| :---------- | :--------- | :------------------ | :---------- |
| Lvl 10 / Gate 1 / Evo 1 / Sockel 1 | ~9h | 10× Zeitkern, 1× Seltene Essenz, 1× Elementarfragment, 1× Sockelstein | Validiert |
| Klassenstufe 5 | ~25-30h | - | Validiert |
| Lvl 20 / Gate 2 / Sockel 2 | ~35h | 20× Zeitkern, 2× Seltene Essenz, 2× Sockelstein | Validiert |
| Evo 2 (Lvl 25) | ~60h | 25× Zeitkern, 2× Elementarfragment | Validiert |
| Klassenstufe 10 | ~75-80h | - | Validiert |
| Lvl 30 / Gate 3 | ~90h | 30× Zeitkern, 3× Seltene Essenz | Validiert |
| Klassenstufe 15 | ~130h | - | Validiert |
| Evo 3 (Lvl 35) | ~135h | 35× Zeitkern, 3× Elementarfragment | Validiert |
| Lvl 40 / Gate 4 / Klassenstufe 20 | ~180h | 40× Zeitkern, 4× Seltene Essenz | Validiert |
| Klassenstufe 25 / Meisterschaft | ~250h | - | Validiert |
| Zenit-Freischaltung | ~250h | Komplexe Anforderungen (siehe 2.5.2) | Validiert |
| Lvl 50 (Max) | ~280h | 50× Zeitkern total | Validiert |

### 9.2 Materialprogression Zusammenfassung

**Zeitkern-Progression:**
- Frühe Phase (W1): ~5-8 pro Stunde
- Mittlere Phase (W2-3): ~10-15 pro Stunde
- Fortgeschrittene Phase (W4-5): ~15-25 pro Stunde
- Endgame (Zeitlose Kammer): ~20-30 pro Stunde
- **Zeitkernkits:** 1 nach je 3 täglichen Quests (≈ 1 pro Tag)

**Elementarfragment-Progression:**
- Frühe Phase (W1): ~1-2 pro Stunde
- Mittlere Phase (W2-3): ~2-4 pro Stunde
- Fortgeschrittene Phase (W4-5): ~4-6 pro Stunde
- Endgame (Zeitlose Kammer): ~5-8 pro Stunde
- **Pity-Timer:** Garantiert 1 nach 8 erfolglosen Versuchen

**Seltene Essenz-Progression:**
- Frühe Phase (W1): ~0-1 pro Stunde
- Mittlere Phase (W2-3): ~1-2 pro Stunde
- Fortgeschrittene Phase (W4-5): ~2-3 pro Stunde
- Endgame (Zeitlose Kammer): ~2-4 pro Stunde
- **Pity-Timer:** Garantiert 1 nach 25 erfolglosen Versuchen

**Zeitfokus-Progression:**
- Mittlere Phase (W3): ~1-2 pro Stunde
- Fortgeschrittene Phase (W4-5): ~2-4 pro Stunde
- Endgame (Zeitlose Kammer): ~4-8 pro Stunde
- **Pity-Timer:** Garantiert 1 nach 12 erfolglosen Versuchen

**Sockelstein-Progression:**
- Mittlere Phase (W2-3): ~0-1 pro Stunde
- Fortgeschrittene Phase (W4-5): ~1-2 pro Stunde
- Endgame (Zeitlose Kammer): ~1-3 pro Stunde
- **Pity-Timer:** Garantiert 1 nach 30 erfolglosen Versuchen

**Gesamtprogression (Materialien pro Woche, F2P):**

| Material | Früh (W1) | Mittel (W2-3) | Fortgeschritten (W4-5) | Endgame |
|----------|-----------|---------------|------------------------|------------|
| Zeitkern | 140-200 | 280-420 | 420-700 | 700-840 |
| Elementarfragment | 15-30 | 40-75 | 110-165 | 140-225 |
| Seltene Essenz | 0-10 | 25-40 | 55-80 | 70-110 |
| Zeitfokus | 0-5 | 25-40 | 55-80 | 140-225 |
| Sockelstein | 0-2 | 5-15 | 25-40 | 40-60 |

### 9.3 Materialökonomie Zusammenfassung

#### 9.3.1 Strategische Materialverteilung
- **Zeitkern-Fokus**: Das häufigste Material, bildet die Grundlage der Progression und ermöglicht kontinuierliches Leveling.
- **Elementarfragment-Engpass**: Erste strategische Entscheidung in W2 (9-35h), begrenzt die Anzahl verfügbarer Evolutionen.
- **Seltene Essenz-Engpass**: Zweiter wichtiger Engpass in W3-4 (35-180h), begrenzt Qualitätsupgrades.
- **Zeitfokus-Engpass**: Wichtigstes Endgame-Material (ab 180h+), begrenzt Optimierungsmöglichkeiten.
- **Sockelstein-Rarität**: Seltenster Materialtyp, fördert strategische Sockelplatzierung.

#### 9.3.2 Material-Interaktionen
- **Levelabhängigkeiten**: Evolution (Lvl 9/25/35), Sockel (Lvl 10/20), Gates (Lvl 10/20/30/40)
- **Materialsynergien**: Zeitkerne bestimmen, wann andere Materialien relevant werden
- **Pity-Timer-System**: Garantiert regelmäßige Drops aller selteneren Materialien
  - Elementarfragment: Nach 8 erfolglosen Versuchen
  - Seltene Essenz: Nach 25 erfolglosen Versuchen
  - Zeitfokus: Nach 12 erfolglosen Versuchen
  - Sockelstein: Nach 30 erfolglosen Versuchen

#### 9.3.3 F2P vs. Premium
- **Premium-Vorteil**: ~20-30% mehr Materialien, primär durch Battle Pass und begrenzte Angebote
- **Direktkauf-Limits**: Strikte Grenzen für direkte Materialkäufe
- **Zeitkernkits**: Premium-Spieler erhalten ~40% mehr Kits
- **Keine exklusiven Materialien**: Alle fünf Materialtypen sind für F2P-Spieler zugänglich

#### 9.3.4 Materialökonomie-Kurve
![Materialökonomie-Kurve](../Assets/MaterialKurve_v2.0.png)

### 9.4 Power-Level Progression (Relativ)
*(Werte sind Multiplikatoren vs. Basis-Power)*
| Fortschritt | Total F2P | Total Premium (geschätzt) |
| :---------- | :-------- | :------------------------ |
| Früh (~30h) | ~132%     | ~145%                     |
| Mittel (~90h)| ~286%     | ~315%                     |
| Fort. (~180h)| ~640%     | ~705%                     |
| Endgame (~250h)| ~1089%    | ~1200%                    |
| Meisterlich (~500h)| ~2016% | ~2220% |

---

## 10. Abhängige Dokumente

### 10.1 Kern-Dokumente (Vereinfachtes System)
- `ZK-KARTENPROGRESSION-v2.1.md`: Detaillierte Beschreibung des modernisierten Karten-Progressionssystems mit Zeitkernen.
- `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`: Definition der fünf Materialtypen und ihrer spezifischen Einsatzzwecke.
- `ZK-ZEITKERN-SYSTEM-v1.0.md`: Detaillierte Beschreibung des Zeitkern-Systems und der Zeitkernkits.
- `ZK-DROP-RATEN-v2.0.md`: Dropwahrscheinlichkeiten und -mengen für alle fünf Materialtypen.

### 10.2 Progression und Balancing
- `ZK-Progression & Hook-Mechaniken-v2.0.md`: Pacing, Hooks und motivierende Spieler-Loops für das vereinfachte System.
- `ZK-ECONOMY-BALANCING-v2.0.md`: Wirtschaftliches Balancing für das vereinfachte System.
- `ZK-Finale Definition und Balancing für "Zeitklingen"-v2.0.md`: Detaillierte Beschreibung des Zenit-Systems.

### 10.3 Klassen und Mechaniken
- `ZK-CLASS-MAGE-v1.6-.md`: Detaillierte Beschreibung der Chronomant-Klasse.
- `ZK-CLASS-WAR-v1.8.3-.md`: Detaillierte Beschreibung der Zeitwächter-Klasse.
- `ZK-CLASS-ROG-v2.4-.md`: Detaillierte Beschreibung der Schattenschreiter-Klasse.
- `ZK-TIME-v1.2-.md`: Zeitsystem, DoT-Kategoriesystem.
- `ZK-DUN-MECH-COMP-.md`: Mechaniken der verschiedenen Welten.
- `ZK-Klassenstufen- und Meisterschaftssystem-v1.0-.md`: Details zu Klassenstufen und Meisterschaft.

### 10.4 Systemintegration
- `ZK-SYSTEM-INTERAKTION-v2.0.md`: Systeminteraktionen und Datenflüsse zwischen den verschiedenen Mechaniken des vereinfachten Systems.