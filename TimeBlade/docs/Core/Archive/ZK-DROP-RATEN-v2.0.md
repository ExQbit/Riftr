# Zeitklingen: Drop-Raten-Dokument (ZK-DROP-RATEN-v2.2-20250521)

## Inhaltsverzeichnis
1. [Einführung und Übersicht](#1-einführung-und-übersicht)
2. [Gegnerbasierte Materialgewinne](#2-gegnerbasierte-materialgewinne)
3. [Weltspezifische Modifikatoren](#3-weltspezifische-modifikatoren)
4. [Event- und Questbelohnungen](#4-event--und-questbelohnungen)
5. [Akkumulationsraten und Balancing](#5-akkumulationsraten-und-balancing)
6. [Saisonale und Zeitlimitierte Drop-Boni](#6-saisonale-und-zeitlimitierte-drop-boni)
7. [Pity-Timer und Garantierte Gewinne](#7-pity-timer-und-garantierte-gewinne)
8. [Abhängige Dokumente](#8-abhängige-dokumente)

---

## 1. Einführung und Übersicht

### 1.1 Zweck des Dokuments

Dieses Dokument definiert die präzisen Wahrscheinlichkeiten für Materialgewinne in Zeitklingen, aufgeschlüsselt nach Gegnertypen, Welten, Events und Quest-Kategorien. Es dient als umfassende Referenz für die Balance des radikal vereinfachten Materialsystems mit seinen vier klar definierten Materialtypen.

### 1.2 Schlüsselprinzipien der Drop-Balancierung

* **Ein Material, ein Zweck**: Jedes Material hat eine klare, eindeutige Funktion im Spiel
* **Konsistente Progression**: Vorhersehbare Akkumulationsraten ohne übermäßige Glücksabhängigkeit
* **Welt-Progression**: Höhere Welten bieten bessere Materialqualität und Quantität
* **Gegnertyp-Hierarchie**: Stärkere Gegner bieten bessere Material-Chancen
* **Quest-Fokus**: 70% der Materialgewinne aus Quests und Events, 30% aus Kämpfen
* **Anti-Pech-Mechanismen**: Pity-Timer garantieren regelmäßige hochwertige Drops

### 1.3 Materialtypen und ihre Hauptfunktionen

| Material | Hauptfunktion | Relative Seltenheit | Primäre Quellen |
|----------|---------------|---------------------|------------------|
| **Zeitkern** | Kartenleveling | Häufig | Alle Gegnertypen, Quests |
| **Elementarfragment** | Evolution (Level 9/25/35) | Mittel | Elite-Gegner, Mini-Bosse |
| **Seltene Essenz** | Gate-Durchbrüche (Level 10/20/30/40) | Selten | Mini-Bosse, Dungeon-Bosse |
| **Zeitfokus** | Attribut-Rerolls | Mittel | Quests, Events |


### 1.4 Prozessvisualisierung

```
──────────────────────────────────────────────────────────────────────────────────────────────
|──────────────────────────────────────────────────────────────────────────────────────────────|
|  GEGNER/QUEST/EVENT                                               |
|        |                                                          |
|        ─                                                          |
|  MATERIALTYP-AUSWAHL (Zeitkern/Elementarfragment/Essenz/etc.)     |
|        |                                                          |
|        ─                                                          |
|  BASISWAHRSCHEINLICHKEIT                                         |
|        |                                                          |
|        ─                                                          |
|  WELT-MODIFIKATOR            SCHWIERIGKEITSGRAD-MODIFIKATOR       |
|        |                              |                           |
|        ─                              ─                           |
|  MODIIFIZIERTE WAHRSCHEINLICHKEIT                                |
|        |                                                          |
|        ─                                                          |
|  SPIELER-FAKTOREN (Glucksmechanik, Pity-Timer, Buffs)            |
|        |                                                          |
|        ─                                                          |
|  FINALE DROP-CHANCE                                               |
|        |                                                          |
|        ─                                                          |
|  ERFOLG?                                                          |
|    /       \                                                      |
|   /         \                                                     |
|  JA          NEIN                                                 |
|  |           |                                                    |
|  |           ───────────────> Pity-Timer für dieses Material erhöhen |
|  |                                                               |
|  ────> DROP: 1-X Einheiten des gewählten Materials           |
|──────────────────────────────────────────────────────────────────────────────────────────────|
```

---

## 2. Gegnerbasierte Materialgewinne

### 2.1 Basis-Droprate nach Gegnertyp

| Gegnertyp | Zeitkern | Elementarfragment | Seltene Essenz | Zeitfokus |
|-----------|---------|-------------------|--------------|-----------|
| **Standardgegner** | 15% | 3% | 0,5% | 1% |
| **Elite-Gegner** | 30% | 10% | 3% | 5% |
| **Mini-Boss** | 60% | 25% | 10% | 15% |
| **Dungeon-Boss** | 100% | 50% | 25% | 30% |
| **Welt-Boss** | 200% | 100% | 50% | 60% |

### 2.2 Durchschnittliche Materialmengen pro Drop

| Gegnertyp | Zeitkern | Elementarfragment | Seltene Essenz | Zeitfokus |
|-----------|---------|-------------------|--------------|-----------|
| **Standardgegner** | 1-2 | 1 | - | 1 |
| **Elite-Gegner** | 2-3 | 1-2 | 1 | 1 |
| **Mini-Boss** | 3-5 | 2-3 | 1 | 1-2 |
| **Dungeon-Boss** | 5-8 | 3-4 | 1-2 | 2-3 |
| **Welt-Boss** | 10-15 | 5-7 | 2-3 | 3-5 |

## 3. Schwierigkeitsgrad-Modifikatoren

| Schwierigkeitsgrad | Zeitkern | Elementarfragment | Seltene Essenz | Zeitfokus |
|-------------------|----------|-------------------|--------------|-----------|
| **Normal** | ×1,0 | ×1,0 | ×1,0 | ×1,0 |
| **Heroisch** | ×1,5 | ×1,5 | ×1,5 | ×1,5 |
| **Legendär** | ×2,0 | ×2,0 | ×2,0 | ×2,0 |

Die Schwierigkeitsgrad-Modifikatoren werden nach dem Welt-Multiplikator angewendet.

---

## 4. Event- und Questbelohnungen

### 4.1 Tagesquests

| Quest-Kategorie | Zeitkern | Elementarfragment | Seltene Essenz | Zeitfokus |
|-----------------|----------|-------------------|----------------|-----------|
| **Kampf** | 3-4 | 0-1 | - | 0-1 |
| **Sammlung** | 2-3 | 1 | 0-1 | - |
| **Erkundung** | 1-2 | 0-1 | - | 1-2 |
| **Handwerk** | 2 | - | - | 0-1 |
| **Sozial** | 1 | - | - | 1 |

### 4.2 Wöchentliche Events

| Event-Typ | Häufigkeit | Zeitkern | Elementarfragment | Seltene Essenz | Zeitfokus |
|-----------|------------|---------|-------------------|---------------|-----------|
| **Zeit-Riss** | Tägliche Quests | 1-3× | 0-1× | 0 | 0-1× |
| **Tägliche Herausforderung** | 1/Tag | 3-5 | 1 | 0-1 | 1-2 |
| **Welt-Invasion** | 3/Woche | 5-8 | 2-3 | 1 | 2-3 |
| **Arena-Herausforderung** | 1/Woche | 8-12 | 3-5 | 1-2 | 3-5 |
| **Raid-Boss** | 1/Woche | 10-15 | 4-6 | 2-3 | 4-6 |
| Saisonales Event | Alle 4-6 Wochen | 25-50× | 5-10× | 2-5× | 3-8× |
| **Zeitstorm** | 1/Monat | 25-30 | 10-15 | 5-6 | 10-12 |

### 4.3 Projektbelohnungen

| Projekt-Größe | Dauer | Zeitkern | Elementarfragment | Seltene Essenz | Zeitfokus |
|---------------|-------|---------|-------------------|---------------|-----------|
| **Klein** | Welt-Quests | 10-20× | 3-5× | 1-2× | 2-4× |
| **Mittel** | 4-7 Tage | 20-25 | 5-8 | 2-3 | 5-8 |
| **Groß** | 10-14 Tage | 30-40 | 10-15 | 3-5 | 10-15 |
| **Episch** | 20-30 Tage | 50-75 | 20-30 | 5-10 | 20-30 |

---

## 5. Spielervariationen

### 5.1 Materialien pro Spielzeit

| Spielzeit | Zeitkern | Elementarfragment | Seltene Essenz | Zeitfokus |
|-----------|---------|-------------------|---------------|-----------|
| **1 Stunde** | 10-15 | 3-5 | 0-1 | 2-4 |
| **3 Stunden** | 25-35 | 8-12 | 2-3 | 5-8 |
| 1 Woche (Kernspieler) | 50-75 | 15-25 | 3-5 | 8-12 |

### 5.2 Wöchentliche Materialakkumulation (nach Spielertyp)

| Spielertyp | Spielzeit/Woche | Zeitkern | Elementarfragment | Seltene Essenz | Zeitfokus |
|------------|----------------|---------|-------------------|---------------|-----------|
| 1 Woche (Gelegenheitsspieler) | 25-35 | 5-10 | 1-2 | 3-5 |
| **Regelmäßiger Spieler** | 1 Woche (Hardcore-Spieler) | 100-150 | 30-50 | 8-12 | 15-25 |
| **Intensivspieler** | 20+ Stunden | 250-350 | 70-100 | 15-25 | 50-75 |
| Hardcore-Spieler | 15-30h+ | 100-150 | 30-50 | 8-12 | 15-25 |

### 5.3 Materialverbrauch und Kartenverbesserung

| Phase | Zeitkern | Elementarfragment | Seltene Essenz | Zeitfokus | Hauptquelle |
|------|---------|-------------------|---------------|-----------|-------------|
| **Anfängerphase (Welt 1-2)** | 10-15 pro Karte | 3-5 pro Kartenlevel | 1 pro Gate | 1-2 pro Reroll | Kampf-Drops, Tagesquests |
| **Mittlere Phase (Welt 3-5)** | 15-25 pro Karte | 5-8 pro Kartenlevel | 2-3 pro Gate | 2-4 pro Reroll | Alle Quellen |
| **Fortgeschrittene (Welt 6-8)** | 25-40 pro Karte | 8-12 pro Kartenlevel | 3-5 pro Gate | 4-6 pro Reroll | Events, Raids, Weltbosse |
| **Endgame (Welt 9+)** | 40-60 pro Karte | 12-20 pro Kartenlevel | 5-8 pro Gate | 6-10 pro Reroll | Alle Endgame-Quellen |

---

## 6. Saisonale und Zeitlimitierte Drop-Boni

### 6.1 Wöchentliche Rotationen

| Tag | Fokus-Material | Bonus-Effekt |
|-----|---------------|-------------|
| **Montag** | Zeitkern | +50% Droprate, +1 pro Drop |
| **Dienstag** | Elementarfragment | +100% Droprate |
| **Mittwoch** | Seltene Essenz | +50% Droprate |
| **Donnerstag** | Zeitfokus | +100% Droprate |
| **Freitag** | Zeitfokus | +25% Droprate |
| **Samstag/Sonntag** | Alle Materialien | +30% Droprate für alle Materialien |

### 6.2 Monatliche Events

| Event | Zeitraum | Fokus | Bonus-Effekt |
|------|---------|------|-------------|
| **Zeitflut** | 1.-7. jeden Monats | Zeitkern | Doppelte Zeitkern-Drops in allen Kämpfen |
| **Elementare Konvergenz** | 15.-21. jeden Monats | Elementarfragment | Garantierte Elementarfragment-Drops bei Elitegegnern |
| **Essenz-Schauer** | Letzte Woche des Monats | Alle Materialien | +50% Menge aller Materialdrops |
| **Material-Jagd** | 22.-28. jeden Monats | Seltene Materialien | Garantierter Zeitfokus pro 3 Dungeon-Bosse |
| **Fokus-Finale** | Letztes Wochenende | Zeitfokus | Zeitfokus-Droprate +150% |

### 6.3 Seltene Events

| Event | Seltenheit | Materialbonus | Einzigartige Belohnung |
|-------|-----------|--------------|----------------------|
| **Zeitstoß** | 1× pro Quartal | 2× Material-Drops aller Typen | Exklusive Kartenrückseite |
| **Zeitriss-Festival** | 1× pro Jahr | 3× Material-Drops, 5× Zeitkerne | Exklusive Karte |
| **Jubiläumswoche** | 1× pro Jahr | Alle Materialien +100% | Spezial-Edition Materialien |
| **Elementar-Konvergenz** | 1× pro Halbjahr | 5× Elementarfragmente garantiert pro Boss | Premium-Evolution-Animation |
| **Chronosvoid** | 1× pro Jahr | 100% Chance auf alle 5 Materialien bei Elite+ Gegnern | Zeitmanipulation-Effekt für Kartenspiel |
| **Materialfusion** | 1× pro Halbjahr | Doppelte Materialeffektivität bei Verwendung | Garantierte erfolgreiche Kartenevolution ohne Materialverbrauch |

---

## 7. Pity-Timer und Garantierte Gewinne

### 7.1 Pity-Timer-System

Das Pity-Timer-System gewährleistet garantierte seltene Materialdrops nach einer längeren Serie ohne entsprechende Materialgewinne:

| Material | Initialer Timer | Erhöhung pro Kampf | Garantie nach |
|----------|----------------|---------------------|---------------|
| **Zeitkern** | Standard-Drop | - | In jedem Kampf mind. 1 |
| **Elementarfragment** | 0% Bonus | +5% pro Kampf ohne Drop | 20 Kämpfen |
| **Seltene Essenz** | 0% Bonus | +2% pro Kampf ohne Drop | 50 Kämpfen |
| **Zeitfokus** | 0% Bonus | +3% pro Kampf ohne Drop | 35 Kämpfen |
| **Zeitfokus** | 0% Bonus | +1% pro Kampf ohne Drop | 100 Kämpfen |

## 8. Pity-Timer und Garantie-Systeme

Das Pity-Timer-System gewährleistet garantierte Materialdrops nach einer längeren Serie ohne entsprechende Materialgewinne:

| Material | Pity-Timer | Max. Kämpfe | Garantie-Mechanik |
|---------|-----------|------------|------------------|
| **Zeitkern** | Standard-Drop | - | In jedem Kampf mind. 2-3 |
| **Elementarfragment** | Nach 5 Kämpfen | 8 | Mind. 1 pro 5 Elite-Kämpfe |
| **Seltene Essenz** | Nach 15 Kämpfen | 25 | Mind. 1 pro 15 Bosse |
| **Zeitfokus** | Nach 8 Kämpfen | 12 | Mind. 1 pro 8 Elite-Kämpfe |
| **Zeitfokus** | Nach 20 Kämpfen | 30 | Mind. 1 pro 20 Weltbosse/Events |

### 8.1 Pity-Timer-Modifikatoren

| Faktor | Auswirkung auf Timer | Anmerkung |
|--------|----------------------|-----------|
| **Weltenstufe** | ×(0.9 - 0.5) | Höhere Welten beschleunigen den Timer |
| **Schwierigkeitsgrad** | ×(0.8 - 0.5) | Höhere Schwierigkeit beschleunigt den Timer |
| **Gegnerrang** | ×(0.7 - 0.3) | Bosse beschleunigen den Timer stark |
| **Tagesquests** | +10% für alle Timer | Bei Questabschluss pro Tag |
| **Wochenevents** | Garantiert 1× jedes Material | Bei wöchentlichem Eventabschluss |

### 8.2 Hart garantierte Drops

Unabhängig von den Wahrscheinlichkeiten sind folgende Drops absolut garantiert:

| Aktivität | Garantierter Drop | Häufigkeit |
|-----------|-------------------|-----------|
| **Täglicher Login** | 3× Zeitkern | Täglich |
| **3 Tagesquests** | 1× von jedem Material | Alle 3 Tage |
| **Wöchentliches Event** | 5× Elementarfragment, 2× Seltene Essenz | Wöchentlich |
| **Weltenboss** | 4× Zeitfokus | Wöchentlich |
| **Monatsevent** | 5× von jedem Material | Monatlich |

## 9. Login-Bonus und Belohnungssystem

| Belohnungstyp | Materialbelohnung | Häufigkeit |
|--------------|------------------|------------|
| **Täglicher Login** | 3× Zeitkern | Täglich |
| **Login-Streak (7 Tage)** | 5× Zeitkern, 2× Elementarfragment | Wöchentlich |
| **Premium-Login** | 5× Zeitkern, 3× Elementarfragment, 1× Zeitfokus | Täglich mit Premium-Pass |
| **Community-Meilenstein** | 10× Zeitkern, 5× Elementarfragment, 2× Seltene Essenz | Bei Erreichung von Community-Zielen |

## 10. Abhängigkeiten und Referenzen

* `zeitkern-system-spezifikation.md`: Technische Grundlage des direkten Karten-Leveling-Systems
* `zeitklingen-vereinfachtes-materialsystem.md`: Definition und Zweck der 4 Materialtypen
* `ZK-KARTENPROGRESSION-v1.5-.md`: Kartenleveling und Evolutionsprozess
* `ZK-LEVEL-ANFORDERUNGEN-v1.0.md`: Materialanforderungen für Spielerprogression
* `ZK-Progression & Hook-Mechaniken-v1.3-.md`: Langfristige Spielerbindung durch Materialsystem
* `ZK-complete-economy-balancing.md`: Wirtschaftliches Gleichgewicht des Materialsystems
* `Zeitklingen: Integriertes Gesamt-Design-Dokument (v2.1).md`: Überblicksdokument
