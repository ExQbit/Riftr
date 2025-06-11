# Zeitklingen: XP-Balance-Dokument (ZK-XP-BALANCE-v1.0-20250520)

## Inhaltsverzeichnis
1. [Einführung und Übersicht](#1-einführung-und-übersicht)
2. [Neue XP-Verteilung und Aktivitätsgewichtung](#2-neue-xp-verteilung-und-aktivitätsgewichtung)
3. [Klassenstufen-XP-System](#3-klassenstufen-xp-system)
4. [Karten-XP-Vergabe via Zeit-Kerne](#4-karten-xp-vergabe-via-zeit-kerne)
5. [XP-Verdienstaktivitäten im Detail](#5-xp-verdienstaktivitäten-im-detail)
6. [Balancierung und Spielerprogression](#6-balancierung-und-spielerprogression)
7. [Implementationshinweise](#7-implementationshinweise)
8. [Abhängige Dokumente](#8-abhängige-dokumente)

---

## 1. Einführung und Übersicht

### 1.1 Zweck des Dokuments

Dieses Dokument beschreibt die angepasste XP-Vergabe im Mo.Co-adaptierten Progressionssystem für Zeitklingen. Es definiert, wie die Reduzierung der direkten XP-Vergabe aus Kämpfen durch das neue Zeit-Kern-System ausgeglichen wird und dokumentiert die angepassten XP-Werte für alle Spielaktivitäten.

### 1.2 Grundlegende Veränderungen

Die wichtigsten Änderungen an der XP-Vergabe sind:

1. **Reduzierung der kampfbasierten XP** um 80% (von 80% auf 20% des Gesamtfortschritts)
2. **Einführung des Zeit-Kern-Systems** als Hauptprogression für Karten (80% des Fortschritts)
3. **Beibehaltung der Klassenstufen-XP** als separaten Progressionszweig
4. **Erhöhung der quest- und projektbasierten XP-Vergabe** für beide Progressionssysteme
5. **Neue XP-Gewichtung** für Entdeckungen, Events und Weltabschlüsse

### 1.3 Verhältnis von XP und Zeit-Kernen

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│ AKTIVITÄTSBASIERTE XP-VERGABE                               │
│                  │                                          │
│                  ▼                                          │
│           ┌─────────────┐                                   │
│           │             │                                   │
│           ▼             ▼                                   │
│   ┌──────────────┐  ┌──────────────┐                        │
│   │ KLASSEN-XP   │  │   KARTEN-XP  │                        │
│   │ (unverändert)│  │  (reduziert) │                        │
│   └──────────────┘  └──────────────┘                        │
│                            │                                │
│                            ▼                                │
│                     ┌──────────────┐                        │
│                     │  ZEIT-KERNE  │                        │
│                     │   (neu)      │                        │
│                     └──────────────┘                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Neue XP-Verteilung und Aktivitätsgewichtung

### 2.1 Alte vs. Neue Gesamtverteilung (Karten-XP)

| Aktivitätskategorie | Alte Verteilung | Neue Verteilung | Änderung |
|---------------------|----------------|----------------|----------|
| **Kampf-XP** | 80% | 20% | -60% |
| **Quest-XP** | 15% | 60% | +45% |
| **Event-XP** | 5% | 15% | +10% |
| **Entdeckungs-XP** | 0% | 5% | +5% |

### 2.2 Quest-Gewichtung

| Quest-Typ | Alte Gewichtung | Neue Gewichtung | Anmerkung |
|-----------|----------------|----------------|-----------|
| **Tägliche Quests** | 40% | 30% | Leicht reduziert, aber häufiger |
| **Wochen-Quests** | 30% | 25% | Leicht reduziert |
| **Kleine Projekte** | 10% | 15% | Erhöht für besseres Engagement |
| **Mittlere Projekte** | 15% | 20% | Erhöht für besseres Engagement |
| **Große Projekte** | 5% | 10% | Verdoppelt für langfristige Motivation |

### 2.3 Event-Gewichtung

| Event-Typ | Alte Gewichtung | Neue Gewichtung | Anmerkung |
|-----------|----------------|----------------|-----------|
| **Stündliche Events** | 5% | 15% | Stark erhöht für regelmäßiges Engagement |
| **Tägliche Events** | 20% | 25% | Leicht erhöht |
| **Wöchentliche Events** | 45% | 35% | Reduziert, aber immer noch bedeutend |
| **Monatliche Events** | 30% | 25% | Leicht reduziert |

---

## 3. Klassenstufen-XP-System

### 3.1 Grundmechanik (unverändert)

Das Klassenstufen-XP-System bleibt weitgehend unverändert, da es als separater Progressionszweig funktioniert. Die XP-Kurve und Anforderungen pro Level entsprechen weiterhin dem Dokument `ZK-Klassenstufen- und Meisterschaftssystem-v1.0-.md`.

### 3.2 Angepasste Quellen und Raten

| Aktivität | Alte XP-Vergabe | Neue XP-Vergabe | Modifikatoren |
|-----------|----------------|----------------|---------------|
| **Kampfsieg (Standard)** | 25-50 XP | 25-50 XP (unverändert) | +50% (Heroisch), +100% (Legendär)<br>Multiplikator: Welt 1: 1.0×, Welt 2: 1.5×, Welt 3: 2.0×, Welt 4: 2.5×, Welt 5: 3.0× |
| **Elite-Gegner** | 100-150 XP | 100-150 XP (unverändert) | Gleiche Multiplikatoren wie Standard |
| **Mini-Boss** | 250-350 XP | 250-350 XP (unverändert) | Gleiche Multiplikatoren wie Standard |
| **Dungeon-Boss** | 500-750 XP | 500-750 XP (unverändert) | Gleiche Multiplikatoren wie Standard |
| **Weltabschluss (Normal)** | 1,500 XP | 1,500 XP (unverändert) | +50% (Heroisch), +100% (Legendär) |
| **Tägliche Klassen-Quest** | 200-300 XP | 250-350 XP (+25%) | - |
| **Wöchentliche Klassen-Quest** | 1,000-1,500 XP | 1,250-1,750 XP (+25%) | - |
| **Zeitlose Kammer** | 50 XP pro 5 Stufen | 75 XP pro 5 Stufen (+50%) | +10 XP pro 10 Stufen |
| **Klassenstufen-Herausforderungen** | 1,000-5,000 XP | 1,500-7,500 XP (+50%) | Einmalige, stufenspezifische Prüfungen (für Stufen 5, 10, 15, 20) |

### 3.3 XP-Kurve für Klassenstufen (unverändert)

| Level | Benötigte XP | Kumulierte XP | Spielzeit (Ziel) |
|-------|-------------|---------------|------------------|
| 1 → 2 | 1,000 | 1,000 | 2-3h |
| 2 → 3 | 1,500 | 2,500 | 5-6h |
| 3 → 4 | 2,000 | 4,500 | 8-10h |
| 4 → 5 | 2,500 | 7,000 | 12-15h |
| 5 → 6 | 3,000 | 10,000 | 18-20h |
| ... | ... | ... | ... |
| 24 → 25 | 12,500 | 169,000 | 280-300h |

---

## 4. Karten-XP-Vergabe via Zeit-Kerne

### 4.1 Reduzierte direkte XP-Vergabe

Die direkte XP-Vergabe an Karten aus Kämpfen wird um 80% reduziert:

| Aktivität | Alte XP-Vergabe/Karte | Neue XP-Vergabe/Karte | Anmerkung |
|-----------|---------------------|---------------------|-----------|
| **Standardkampf** | 5-10 XP | 1-2 XP | 80% Reduktion |
| **Elite-Gegner** | 15-25 XP | 3-5 XP | 80% Reduktion |
| **Mini-Boss** | 30-50 XP | 6-10 XP | 80% Reduktion |
| **Dungeon-Boss** | 75-125 XP | 15-25 XP | 80% Reduktion |

### 4.2 Zeit-Kern-XP-Werte

| Kern-Stufe | Bezeichnung | Basis-XP-Wert | Element-Match-Bonus |
|------------|------------|--------------|---------------------|
| 1 | Zeit-Fragment | 100 XP | +50% (150 XP) |
| 2 | Zeit-Splitter | 150 XP | +50% (225 XP) |
| 3 | Zeit-Kristall | 250 XP | +50% (375 XP) |
| 4 | Zeit-Essenz | 400 XP | +50% (600 XP) |
| 5 | Zeit-Kern | 650 XP | +50% (975 XP) |

### 4.3 Levelabhängige Kern-Effektivität

| Kartenlevel | Multiplikator | Beispiel (Stufe 3 Kern) |
|-------------|--------------|-------------------------|
| 1-10 | 1.0× | 250 XP |
| 11-20 | 1.1× | 275 XP |
| 21-30 | 1.2× | 300 XP |
| 31-40 | 1.3× | 325 XP |
| 41-50 | 1.4× | 350 XP |

Werte werden leicht aufgerundet (nächste 5er-Stufe).

---

## 5. XP-Verdienstaktivitäten im Detail

### 5.1 Kampfbasierte XP (reduziert)

| Gegnertyp | Welt 1 | Welt 2 | Welt 3 | Welt 4 | Welt 5 |
|-----------|--------|--------|--------|--------|--------|
| **Standard** | 1 XP | 1.5 XP | 2 XP | 2.5 XP | 3 XP |
| **Elite** | 3 XP | 4.5 XP | 6 XP | 7.5 XP | 9 XP |
| **Mini-Boss** | 6 XP | 9 XP | 12 XP | 15 XP | 18 XP |
| **Dungeon-Boss** | 15 XP | 22.5 XP | 30 XP | 37.5 XP | 45 XP |

Multiplikatoren: ×1.5 (Heroisch), ×2.0 (Legendär)

### 5.2 Questbasierte XP und Zeit-Kern-Gewinne

| Quest-Typ | Direkte XP | Aufladungs-% | Zeit-Kern-Belohnung |
|-----------|-----------|-------------|-------------------|
| **Tägliche Standard-Quest** | 5 XP | 5% | 50% Stufe 1 |
| **Tägliche Herausforderungs-Quest** | 10 XP | 10% | 1× Stufe 1 |
| **Tägliche Elite-Quest** | 15 XP | 15% | 1× Stufe 2 (25%) |
| **Wöchentliche Quest** | 25 XP | 25% | 1× Stufe 2 |
| **Monatliche Quest** | 50 XP | 50% | 1× Stufe 3 |

Zusätzlich: 1× Zeit-Kit für je 3 abgeschlossene Tagesquests.

### 5.3 Projektbasierte XP und Zeit-Kern-Gewinne

| Projekt-Größe | Direkte XP pro Meilenstein | Gesamte Zeit-Kern-Belohnung |
|---------------|---------------------------|---------------------------|
| **Klein (3 Meilensteine)** | 10 XP | 1× Stufe 2 + 2× Stufe 1 |
| **Mittel (5 Meilensteine)** | 15 XP | 1× Stufe 3 + 2× Stufe 2 |
| **Groß (7 Meilensteine)** | 25 XP | 1× Stufe 4 + 2× Stufe 3 |
| **Episch (10 Meilensteine)** | 40 XP | 1× Stufe 5 + 2× Stufe 4 |

### 5.4 Eventbasierte XP und Zeit-Kern-Gewinne

| Event-Typ | Direkte XP | Zeit-Kern-Belohnung |
|-----------|-----------|-------------------|
| **Stündliche Zeit-Risse** | 5 XP | 50% Stufe 1 |
| **Tägliche Herausforderung** | 20 XP | 1× Stufe 2 + 1× Stufe 1 |
| **Welt-Invasionen** | 40 XP | 1× Stufe 3 + 1× Stufe 2 |
| **Zeit-Anomalie (Mi/Do)** | 75 XP | 1× Stufe 3 + 2× Stufe 2 |
| **Weltenboss (Fr-So)** | 100 XP | 1× Stufe 4 + 1× Elementarkern |
| **Monatliche Zeitstürme** | 150 XP | 1× Stufe 4 + 3× Stufe 3 |

### 5.5 Entdeckungs-XP (neu)

| Entdeckung | Direkte XP | Zeit-Kern-Beitrag |
|------------|-----------|------------------|
| **Neue Zone entdecken** | 5 XP | 2% Aufladung |
| **Zeitanomalien finden** | 10 XP | 5% Aufladung |
| **Verborgene Bereiche** | 15 XP | 7% Aufladung |
| **Zeitlose Echos** | 20 XP | 10% Aufladung |
| **Kartenfragmente** | 25 XP | 15% Aufladung |

---

## 6. Balancierung und Spielerprogression

### 6.1 Tägliche XP-Gewinne (durchschnittlicher Spieler)

| Aktivität | Spielzeit | Direkte XP | Zeit-Kern-Äquivalent | Gesamt-Fortschritt |
|-----------|----------|-----------|---------------------|-------------------|
| **5 Standardkämpfe** | 15 min | 5-10 XP | 50-100 XP (1× Stufe 1) | 55-110 XP |
| **3 Tagesquests** | 30 min | 15-30 XP | 150-300 XP (1,5× Stufe 2) | 165-330 XP |
| **1 Tägliches Event** | 15 min | 20 XP | 150 XP (1× Stufe 1 + 50% Stufe 1) | 170 XP |
| **Projektfortschritt** | 15 min | 10-25 XP | 50-100 XP (50% Stufe 2) | 60-125 XP |
| **Total (1h)** | 1h 15min | 50-85 XP | 400-650 XP | 450-735 XP |

### 6.2 Wöchentliche XP-Gewinne (durchschnittlicher Spieler)

| Aktivität | Sessions/Woche | Direkte XP | Zeit-Kern-Äquivalent | Gesamt-Fortschritt |
|-----------|---------------|-----------|---------------------|-------------------|
| **Tägliche Aktivitäten** | 7 (7h) | 350-595 XP | 2,800-4,550 XP | 3,150-5,145 XP |
| **Wöchentliche Quests** | 3 (1h) | 75 XP | 750 XP (3× Stufe 2) | 825 XP |
| **Weltenboss** | 1 (30 min) | 100 XP | 900 XP (1× Stufe 4) | 1,000 XP |
| **Projekt-Abschluss** | 1 klein (30 min) | 30 XP | 450 XP (1× Stufe 2 + 2× Stufe 1) | 480 XP |
| **Total (9h)** | - | 555-800 XP | 4,900-6,650 XP | 5,455-7,450 XP |

### 6.3 Monatliche XP-Gewinne (durchschnittlicher Spieler)

| Aktivität | Frequenz/Monat | Direkte XP | Zeit-Kern-Äquivalent | Gesamt-Fortschritt |
|-----------|---------------|-----------|---------------------|-------------------|
| **Wöchentliche Aktivitäten** | 4 Wochen (36h) | 2,220-3,200 XP | 19,600-26,600 XP | 21,820-29,800 XP |
| **Monatliche Quests** | 2 (1h) | 100 XP | 1,000 XP (2× Stufe 3) | 1,100 XP |
| **Monatsevents** | 1 (1h) | 150 XP | 2,200 XP (1× Stufe 4 + 3× Stufe 3) | 2,350 XP |
| **Projekt-Abschluss** | 1 mittel (2h) | 75 XP | 1,250 XP (1× Stufe 3 + 2× Stufe 2) | 1,325 XP |
| **Total (40h)** | - | 2,545-3,525 XP | 24,050-31,050 XP | 26,595-34,575 XP |

### 6.4 Vergleich mit alten Progressionszielen

| Progression | Altes System | Neues System | Änderung |
|-------------|-------------|-------------|----------|
| **Level 10 (Gate 1)** | ~8h | ~9h | +12.5% |
| **Level 20 (Gate 2)** | ~30h | ~32h | +6.7% |
| **Level 30 (Gate 3)** | ~75h | ~72h | -4.0% |
| **Level 40 (Gate 4)** | ~160h | ~160h | +0% |
| **Level 50 (Max)** | ~260h | ~260h | +0% |

---

## 7. Implementationshinweise

### 7.1 XP-Reduzierungs-Formeln

Die Reduzierung der direkten XP-Vergabe folgt dieser Formel:

```
Neue_XP = Alte_XP * 0.2
```

### 7.2 Zeit-Kern-zu-XP-Konvertierung

Für die Umrechnung von Zeit-Kern-Aufladung in XP-Äquivalente:

```
XP_Äquivalent = Aufladungs_Prozent * Basis_XP_Wert * Stufen_Multiplikator
```

Beispiel: 50% Aufladung eines Stufe 3 Kerns (Basis 250 XP) = 125 XP

### 7.3 Level-Cap und Klassenlevel-Integration

Die Beziehung zwischen Klassenlevel und maximalem Kartenlevel bleibt bestehen:

```
Max_Kartenlevel = Klassenlevel * 2
```

### 7.4 Backend-Anpassungen

Folgende Änderungen an der Supabase-Datenbank sind erforderlich:

* Neue Spalte `reduzierte_xp_vergabe` in der `kampf_belohnungen` Tabelle
* Anpassung der XP-Vergabe-Trigger für Quest- und Event-Abschlüsse
* Neue Tabellen für Zeit-Kern-Verwaltung und -Umrechnung
* Aktualisierte Stored Procedures für die XP-Berechnung und -Anwendung

---

## 8. Abhängige Dokumente

* `ZK-ZEIT-KERN-TECHNIK-v1.0.md`: Technische Grundlagen des Kern-Systems
* `ZK-LEVEL-ANFORDERUNGEN-v1.0.md`: Level-Anforderungen im neuen System
* `ZK-DROP-RATEN-v1.0.md`: Detaillierte Drop-Wahrscheinlichkeiten
* `ZK-KARTENPROGRESSION-v1.5-.md`: Bisheriges Kartenprogressionssystem
* `ZK-Klassenstufen- und Meisterschaftssystem-v1.0-.md`: Klassenstufen und XP
* `Zeitklingen: Progression & Hook-Mechaniken-v1.3-.md`: Allgemeine Progression
* `XP Curve.md`: Originale XP-Tabelle (als Referenz)
* `complete-economy-balancing.md`: Übergeordnetes Wirtschaftssystem
