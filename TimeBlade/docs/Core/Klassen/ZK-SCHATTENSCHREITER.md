# Zeitklingen: Schattenschreiter

## Klassen-Übersicht

**Der Tempo-Meister** - Erreicht höchste Karteneffizienz durch Momentum-Aufbau und Schattenkarten-Synergien.

**⚖️ NEUE BALANCE-PHILOSOPHIE**: Opportunity Costs statt Hartcaps - Zeitmanipulations-Karten kosten mehr Zeit aber ermöglichen mächtige Effekte ohne künstliche Limits. **Klassenbonus**: Schattenschreiter sind die effizienteste Klasse für Zeitraub. Alle Kosten in 0,5s-Schritten.

## Kernmechanik: Momentum (0-5)

- **Generierung**: +1 pro gespielter Karte (auch bei 0-Zeit-Karten)
- **Verfall**: -1 pro Sekunde nach 3s Inaktivität
- **Schwellenboni** (kumulativ):
  - **1 Momentum**: +5% Schaden für Angriffskarten
  - **2+ Momentum**: +10% Schaden für Angriffskarten
  - **3+ Momentum**: Angriffskarte nach Schattenkarte +20% Schaden
  - **4+ Momentum**: +0,5s Zeitgewinn pro gespielter Karte
- **Schattenrausch (bei 5 Momentum)**: Nächste 5s alle Karten +25% Effektivität → Reset auf 0

## Bonusmechanik: Schattensynergie

- **Schattenkarten**: Machen nächste Angriffskarte kostenlos (0 Zeit)
- **Nach Schattenkarte**: Nächste Angriffskarte -50% Kosten (falls nicht kostenlos)
- **Schattensynergie-Karten**: Schleier, Schattenform, spezielle Evolutionen

## 🎯 **STARTERDECK (8 BASISKARTEN-INSTANZEN)**

**Jeder Schattenschreiter beginnt mit exakt diesen 8 Karten:**

| Karte | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|--------|-----------|-----------|--------|
| **Schattendolch** | 3 | 2,0s | Gewöhnlich | 3 Schaden. Bei 4+ Momentum: +2 Schaden und ziehe 1 Karte. |
| **Giftklinge** | 2 | 1,5s | Gewöhnlich | 2 Schaden + DoT: 1/Sek für 3s. Bei 4+ Momentum: DoT-Schaden +1/Sek und Dauer ×1,5. |
| **Schleier** | 3 | 1,0s | Ungewöhnlich | Der nächste Angriff verfehlt. **Schattensynergie**: Nächste Angriffskarte kostet 0 Zeit. |

**🔓 Karten-Freischaltung**: Weitere 18 Karten werden durch Spielfortschritt freigeschaltet.

---

## Vollständige Kartenliste (26 Karten)

### Basisangriffe (6 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Schattendolch | CARD-ROG-SHADOWDAGGER | 3 | 2,0s | Gewöhnlich | 3 Schaden. Bei 4+ Momentum: +2 Schaden und ziehe 1 Karte. |
| Giftklinge | CARD-ROG-POISONBLADE | 3 | 1,5s | Gewöhnlich | 2 Schaden + DoT: 1/Sek für 3s. Bei 4+ Momentum: DoT-Schaden +1/Sek und Dauer ×1,5. |

### Schattenkarten (7 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Schleier | CARD-ROG-VEIL | 4 | 1,0s | Ungewöhnlich | Der nächste Angriff verfehlt. **Schattensynergie**: Nächste Angriffskarte kostet 0 Zeit. |
| Schattenform | CARD-ROG-SHADOWFORM | 3 | 1,5s | Selten | Die nächsten 2 Angriffe verfehlen. +0,5s Zeit pro vermiedenem Angriff. **Schattensynergie**: Nächste Angriffskarte kostet 0 Zeit. |

### Zeitraub (5 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Temporaler Diebstahl | CARD-ROG-TIMEHEIST | 2 | 2,0s | Ungewöhnlich | Raubt 0,5s Zeit vom Gegner. **Trade-off**: +0,5s aber effizienter als andere Klassen. |
| Chrono-Heist | CARD-ROG-TEMPORALTHEFT | 3 | 2,5s | Selten | Raubt 1,0s Zeit vom Gegner und verursacht 1 Schaden. **Trade-off**: +0,5s Kosten, -50% Schaden für Zeitfokus. |

### Utility/Momentum (6 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Schattenschritt | CARD-ROG-SHADOWSTEP | 4 | 1,0s | Selten | +25% Effekte für nächste Karte. +15% Effekte für übernächste Karte, wenn sie Schaden verursacht. |
| Schattenkonzentration | CARD-ROG-SHADOWFOCUS | 2 | 1,5s | Episch | Generiert +2 Momentum. Bei 4+ Momentum: Ziehe 1 Karte. |

### Signaturkarten (2 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Temporaler Sprung | CARD-ROG-TIMESHIFT | 1 | 4,0s | Legendär | Raubt 1,5s Zeit und zieht 2 Karten. **Trade-off**: +1,0s für mächtigen Kombinations-Effekt. Evolutionen modifizieren Momentum-System. |
| Schattensturm | CARD-ROG-SHADOWSTORM | 1 | 4,0s | Legendär | 8 Schaden auf alle Gegner. +0,5s Zeit pro Treffer. |

## Evolution-System

### Elementarpfade
Alle Karten haben 3 Evolutionspfade:
- **Feuer**: DoT-Fokus, Burst-Schaden
- **Eis**: Zeitkontrolle, Verlangsamung
- **Blitz**: Maximale Geschwindigkeit, Ketteneffekte

### Evolutionskosten
- **Stufe 1** (Level 9): 1× Elementarfragment
- **Stufe 2** (Level 25): 2× Elementarfragment
- **Stufe 3** (Level 35): 3× Elementarfragment

### Detaillierte Evolutionen

#### Schattendolch Evolutionen
**Feuer-Pfad:**
| Stufe | Name | Kosten | Effekt | DoT-Kategorie | Zeitgewinn |
|-------|------|--------|--------|---------------|------------|
| 1: Brennender Dolch | Brennender Dolch | 1,0s | 4 Schaden + DoT: 1/Sek für 3s. Bei 4+ Momentum: +2 Schaden und ziehe 1 Karte. | Schwach | 0,5s |
| 2: Ascheklinge | Ascheklinge | 1,0s | 4 Schaden + DoT: 2/Sek für 3s. Bei 4+ Momentum: +3 Schaden und ziehe 1 Karte. | Mittel | 1,0s |
| 3: Höllenstich | Höllenstich | 1,5s | 5 Schaden + DoT: 4/Sek für 3s. Bei 4+ Momentum: +4 Schaden und ziehe 1 Karte. | Stark | 2,0s |

**Eis-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Frostdolch | Frostdolch | 1,0s | 3 Schaden. Verlangsamt Gegner um 10% für 3s. Bei 4+ Momentum: +2 Schaden und verlangsamt um 15% für 3s. |
| 2: Eisklinge | Eisklinge | 1,0s | 4 Schaden. Verlangsamt Gegner um 20% für 3s. Bei 4+ Momentum: +3 Schaden und verlangsamt um 25% für 3s. |
| 3: Absolutstich | Absolutstich | 1,5s | 5 Schaden. Verlangsamt Gegner um 30% für 3s. Bei 4+ Momentum: +4 Schaden und verlangsamt um 40% für 3s. |

**Blitz-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Blitzdolch | Blitzdolch | 1,0s | 3 Schaden. Kostet 0s bei 3+ Momentum. Bei 4+ Momentum: +2 Schaden, ziehe 1 Karte und +1 Momentum. |
| 2: Sturmklinge | Sturmklinge | 1,0s | 4 Schaden. Kostet 0s bei 3+ Momentum. Bei 4+ Momentum: +3 Schaden, ziehe 1 Karte und +1 Momentum. |
| 3: Donnerstich | Donnerstich | 1,0s | 5 Schaden. Kostet 0s bei 2+ Momentum. Bei 4+ Momentum: +4 Schaden, ziehe 2 Karten und +2 Momentum. |

#### Giftklinge Evolutionen
**Feuer-Pfad:**
| Stufe | Name | Kosten | Effekt | DoT-Kategorie | Zeitgewinn |
|-------|------|--------|--------|---------------|------------|
| 1: Brennende Klinge | Brennende Klinge | 1,5s | 2 Schaden + DoT: 2/Sek für 3s. Bei 4+ Momentum: DoT-Schaden +1/Sek und Dauer ×1,5. | Mittel | 1,0s |
| 2: Ätzende Klinge | Ätzende Klinge | 1,5s | 3 Schaden + DoT: 3/Sek für 3s. Bei 4+ Momentum: DoT-Schaden +2/Sek und Dauer ×1,5. | Stark | 2,0s |
| 3: Höllensäure | Höllensäure | 2,0s | 4 Schaden + DoT: 5/Sek für 4s. Bei 4+ Momentum: DoT-Schaden +3/Sek und Dauer ×2. | Stark | 2,0s |

#### Schleier Evolutionen
**Feuer-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Flammenschleier | Flammenschleier | 0,5s | Der nächste Angriff verfehlt. **Schattensynergie + DoT**: Nächste Angriffskarte kostet 0 Zeit und verursacht +1 DoT (Schwach). |
| 2: Glutschleier | Glutschleier | 0,5s | Der nächste Angriff verfehlt. **Schattensynergie + DoT**: Nächste Angriffskarte kostet 0 Zeit und verursacht +2 DoT (Mittel). |
| 3: Infernoschatten | Infernoschatten | 0,5s | Der nächste Angriff verfehlt. **Schattensynergie + DoT**: Nächste Angriffskarte kostet 0 Zeit und verursacht +3 DoT (Stark). |

**Eis-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Frostschleier | Frostschleier | 0,5s | Der nächste Angriff verfehlt. **Schattensynergie + Slow**: Nächste Angriffskarte kostet 0 Zeit und verlangsamt Ziel um 15% (3s). |
| 2: Eisschleier | Eisschleier | 0,5s | Der nächste Angriff verfehlt. **Schattensynergie + Slow**: Nächste Angriffskarte kostet 0 Zeit und verlangsamt Ziel um 25% (4s). |
| 3: Kryoschatten | Kryoschatten | 0,5s | Der nächste Angriff verfehlt. **Schattensynergie + Slow**: Nächste Angriffskarte kostet 0 Zeit und verlangsamt Ziel um 35% (5s). |

**Blitz-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Blitzschleier | Blitzschleier | 0,5s | Der nächste Angriff verfehlt. **Schattensynergie + Tempo**: Nächste Angriffskarte kostet 0 Zeit und +1 Momentum. |
| 2: Sturmschleier | Sturmschleier | 0,5s | Der nächste Angriff verfehlt. **Schattensynergie + Tempo**: Nächste 2 Angriffskarten kosten 0 Zeit und +1 Momentum jede. |
| 3: Gewitterschatten | Gewitterschatten | 0,5s | Der nächste Angriff verfehlt. **Schattensynergie + Tempo**: Nächste 3 Angriffskarten kosten 0 Zeit, +1 Momentum jede, +1 Karte ziehen. |

#### Zeitsprung Evolutionen (Modifizieren Momentum-System)
**Feuer-Pfad ("Verstärkter Bruch"):**
| Stufe | Name | Kosten | Effekt | Bruch-Modifikation |
|-------|------|--------|--------|-------------------|
| 1: Flammsprung | Feuersprung | 3,0s | Raubt 1,5s Zeit und zieht 2 Karten. | Schattenrausch: +35% Effektivität (statt +25%). |
| 2: Glutsprung | Infernosprung | 3,0s | Raubt 2,0s Zeit und zieht 2 Karten. | Schattenrausch: +45% Effektivität, +2 DoT (Mittel) auf alle Angriffe. |
| 3: Magmasprung | Höllensprung | 3,5s | Raubt 2,5s Zeit und zieht 3 Karten. | Schattenrausch: +60% Effektivität, +3 DoT (Stark) auf alle Angriffe. |

**Eis-Pfad ("Momentum-Kontrolle"):**
| Stufe | Name | Kosten | Effekt | System-Modifikation |
|-------|------|--------|--------|-------------------|
| 1: Frostsprung | Eissprung | 3,0s | Raubt 1,5s Zeit und zieht 2 Karten. | Momentum-Verfall: 4s statt 3s Wartezeit. Schwellenboni: Ab 1/2/3 statt 2/3/4. |
| 2: Eissprung | Kryosprung | 3,0s | Raubt 2,0s Zeit und zieht 2 Karten. | Momentum-Verfall: 5s Wartezeit. Schwellenboni: Ab 1/2/3. +0,5s Zeitgewinn (ab 3 Momentum). |
| 3: Kryosprung | Absolutsprung | 3,5s | Raubt 2,5s Zeit und zieht 3 Karten. | Momentum-Verfall: 6s Wartezeit. Schwellenboni: Ab 1/2/3. +1,0s Zeitgewinn (ab 3 Momentum). |

**Blitz-Pfad ("Momentum-Beschleunigung"):**
| Stufe | Name | Kosten | Effekt | Momentum-Modifikation |
|-------|------|--------|--------|---------------------|
| 1: Blitzsprung | Stromsprung | 3,0s | Raubt 1,5s Zeit und zieht 2 Karten. | +2 Momentum beim Ausspielen (statt +1). Schattenrausch: +1 zusätzliche Karte pro Kartenspiel. |
| 2: Sturmsprung | Donnersprung | 3,0s | Raubt 2,0s Zeit und zieht 2 Karten. | +2 Momentum beim Ausspielen. Schattenkarten: +1 zusätzliches Momentum. Schattenrausch: +2 Karten pro Kartenspiel. |
| 3: Gewittersprung | Blitzsprung | 3,5s | Raubt 2,5s Zeit und zieht 3 Karten. | +3 Momentum beim Ausspielen. Schattenkarten: +1 Momentum. Alle Karten: +1 Momentum bei 4+ Momentum. |

#### Schattensturm Evolutionen
**Feuer-Pfad:**
| Stufe | Name | Kosten | Effekt | DoT-Kategorie | Zeitgewinn |
|-------|------|--------|--------|---------------|------------|
| 1: Flammensturm | Flammensturm | 4,0s | 9 Schaden auf alle Gegner + DoT: 1/Sek für 3s. +0,5s Zeit pro Treffer. | Schwach | 0,5s |
| 2: Glutsturm | Infernosturm | 4,5s | 10 Schaden auf alle Gegner + DoT: 2/Sek für 3s. +0,5s Zeit pro Treffer. | Mittel | 1,0s |
| 3: Höllensturm | Apokalypse | 5,0s | 12 Schaden auf alle Gegner + DoT: 4/Sek für 4s. +1,0s Zeit pro Treffer. | Stark | 2,0s |

**Eis-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Froststurm | Froststurm | 4,0s | 8 Schaden auf alle Gegner. Verlangsamt alle um 20% für 4s. +0,5s Zeit pro Treffer. |
| 2: Eissturm | Blizzard | 4,5s | 9 Schaden auf alle Gegner. Verlangsamt alle um 30% für 5s. +0,5s Zeit pro Treffer. |
| 3: Kryosturm | Absolute Zero | 5,0s | 10 Schaden auf alle Gegner. Verlangsamt alle um 40% für 6s. +1,0s Zeit pro Treffer. |

**Blitz-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Blitzsturm | Gewittersturm | 4,0s | 8 AoE-Schaden + trifft 1 weiteres Ziel für 60% Schaden. +0,5s Zeit pro Treffer, +1 Momentum pro Treffer. |
| 2: Donnersturm | Sturmsalve | 4,5s | 9 AoE-Schaden + trifft 1 weiteres Ziel für 60% Schaden. +0,5s Zeit pro Treffer, +1 Momentum pro Treffer, +1 Karte. |
| 3: Gewittersturm | Blitzkrieg | 5,0s | 10 AoE-Schaden + trifft 2 weitere Ziele für 60%/40% Schaden. +1,0s Zeit pro Treffer, +2 Momentum pro Treffer, +2 Karten. |

## Strategische Pfade

### Feuer-Pfad ("Explosive Schatten")
- **Fokus**: Maximaler Burst-Schaden durch DoT-Synergien
- **Stärken**: Höchster AoE-Schaden, DoT-Ketten, Zeitgewinn durch DoT
- **Schwächen**: Weniger Kontrolle, abhängig von DoT-Akkumulation
- **Zeitsprung Mod**: Schattenrausch +60% Effektivität + DoT auf alle Angriffe

### Eis-Pfad ("Frostschatten")
- **Fokus**: Zeitkontrolle und Gegner-Verlangsamung
- **Stärken**: Maximale Zeitdiebstähle, Slow-Effekte, längere Momentum-Kontrolle
- **Schwächen**: Geringerer direkter Schaden, langsamerer Spielstil
- **Zeitsprung Mod**: Momentum-Schwellen ab 1/2/3 + 6s Verfallzeit

### Blitz-Pfad ("Tempo-Assassine")
- **Fokus**: Maximale Karteneffizienz und Momentum-Generierung
- **Stärken**: Höchste Kartenzugrate, beste Schattensynergien, explosives Momentum
- **Schwächen**: Komplex zu spielen, benötigt perfektes Timing
- **Zeitsprung Mod**: +3 Momentum beim Ausspielen + Momentum-Boni

## 🎯 **Progression & Mastery-Integration (KRITISCH DETAILLIERT)**

### 📊 **Klassenstufen-System (Mo.Co-Style - VOLLSTÄNDIG)**
- **25 Klassenstufen** mit exponentieller XP-Kurve (1.329.000 XP total)
- **Kartenlevel-Limit**: Karten können maximal Klassenstufe × 2 erreichen
- **XP-Boost-System**: 4×/3×/2×/1× tägliche Boosts (60.000 XP Limit)
- **Geschätzte Spielzeit**: ~220h total F2P (280h ohne Boost)
- **Welt-Zugang**: Welt 2 bei Level 17, Welt 3 bei Level 33, etc.

### 🏆 **Detaillierte XP-Tabelle für Schattenschreiter**
| Stufe | XP für Stufe | Kumulativ | Hauptquellen | Geschätzte Zeit |
|-------|--------------|-----------|-------------|----------------|
| 1→5 | 10.000 | 10.000 | Prolog + Kapitel 1 | 3h |
| 5→10 | 44.000 | 54.000 | Tagesquests + Projekte | 7h |
| 10→15 | 275.000 | 329.000 | Dungeon-Kette + Events | 35h |
| 15→17 | 200.000 | 529.000 | Weltboss-Vorbereitung | 25h |
| 17→25 | 800.000 | 1.329.000 | Welt 2-5 + Endgame | 150h |
| **Gesamt** | **1.329.000** | **1.329.000** | **Komplette Progression** | **220h** |

### 🗡️ **Klassenspezifische Progression-Boni (KRITISCH ERWEITERT)**
| Klassenstufe | Schattenschreiter-Bonus | Spielauswirkung | Material-Fokus |
|--------------|-------------------------|-----------------|----------------|
| **Stufe 5** | **Schnellzieher**: +10% Momentum bei Kampfstart | Schnellerer Tempo-Aufbau, frühe Schwellenboni | Zeitkerne für Tempo-Schlüsselkarten |
| **Stufe 10** | **Verbesserte Schattensynergie**: 0-Zeit-Karten +5% Effektivität | Schattensynergie-Ketten werden dominierend | Elementarfragmente für Schatten-Evolutionen |
| **Stufe 15** | **Momentum-Katalysator**: Momentum verfällt 50% langsamer | Längere Kontrolle über hohe Momentum-Phasen | Zeitfokus für Tempo-Attribut-Optimierung |
| **Stufe 20** | **Zeitdiebstahl-Meister**: Zeitdiebstahl +20% effektiver | Aggressivere Zeit-Kontrolle gegen Gegner | Event-Teilnahme für Elite-Schatten-Materials |
| **Stufe 25** | **Schattenverschmelzung**: Schattenrausch +2s Dauer | Längste Power-Phasen aller Klassen | **Mastery-System freigeschaltet** |

### ⚡ **Momentum-Skalierung pro Klassenstufe**
| Klassenstufe | Momentum-Start | Verfall-Resistenz | Schattenrausch-Power |
|--------------|----------------|------------------|----------------------|
| Stufe 5 | +10% Start-Momentum | Standard (3s) | +25% Effektivität (5s) |
| Stufe 10 | +10% + Schatten-Bonus | Standard + 5% Schatten-Eff. | +25% + Schatten-Synergie |
| Stufe 15 | +10% + 50% länger | 4.5s bis Verfall | +25% + längere Kontrolle |
| Stufe 20 | +10% + Zeitdiebstahl | Zeitdiebstahl +20% | +25% + Zeit-Aggression |
| Stufe 25 | +15% (kumulativ) | Schattenrausch +2s | +30% + 7s Dauer |

### 🌟 **Kartenlevel-Limits pro Klassenstufe**
| Klassenstufe | Max Kartenlevel | Entspricht | Tempo-Effizienz |
|--------------|-----------------|------------|------------------|
| Stufe 5 | Level 10 | Gate 1 (Uncommon) | 1.1× Momentum-Start |
| Stufe 10 | Level 20 | Gate 2 (Rare) | 1.3× + Schatten-Boni |
| Stufe 15 | Level 30 | Gate 3 (Epic) | 1.5× + längere Kontrolle |
| Stufe 20 | Level 40 | Gate 4 (Legendary) | 1.7× + Zeit-Aggression |
| Stufe 25 | Level 50 | Maximum | 2.0× Schatten-Meisterschaft |

### Mastery-System (Post-Klassenstufe 25)

#### Schattenschreiter Mastery-Boni
| Mastery Level | Bonus | Auswirkung |
|---------------|-------|-----------|
| **M5** | **Perfekter Zieher** | +15% Momentum bei Kampfstart |
| **M15** | **Momentum-Virtuose** | Momentum verfällt 75% langsamer |
| **M25** | **Schattenfusion** | Schattenrausch +4s Dauer |
| **M25+** | **Endlose Geschwindigkeit** | Kontinuierliche Tempo-Boni pro M-Level |

#### Mastery-Material-Vorteile
- **M5+**: Zugang zu Elite-Tagesquests (8-12 Zeitkerne, 3-5 Fragmente täglich)
- **M10+**: Mastery-Weltbosse (25-35 Zeitkerne, 8-12 Fragmente, 2× wöchentlich)
- **M15+**: Exklusive Mastery-Events mit Elite-Kartenvarianten
- **M20+**: Premium-Drop-Quellen mit garantierten seltenen Materialien

## Spielstrategien (Mo.Co-Integration)

### Frühe Phase (Klassenstufe 1-10) - ~5-22h Spielzeit
- **Momentum-Management lernen**: Verstehe Generierung und Verfall
- **Schattensynergie nutzen**: Wechsle zwischen Schattenkarten und Angriffen
- **Erste Evolutionen**: Fokus auf Schattendolch und Schleier (Level 9/25/35)
- **Schwellenboni verstehen**: Nutze 2+/3+/4+ Boni optimal
- **Material-Sammlung**: Nutze tägliche Blitz-Events (+100-150% Material-Bonus)
- **Kartenlevel-Limit beachten**: Karten können nur bis Klassenstufe × 2 gelevelt werden

### Mittlere Phase (Klassenstufe 10-20) - ~22-150h Spielzeit
- **Schattenrausch-Timing**: Perfektioniere wann du den 5-Momentum-Bonus einsetzt
- **Elementarpfad wählen**: Spezialisiere auf Feuer/Eis/Blitz basierend auf Events
- **Event-Optimierung**: Teilnahme an thematischen Events (Feuer-Zeitalter, Frostzeit, Gewittersturm)
- **Komplexe Kartenketten**: Nutze Schattensynergie + Momentum synergistisch
- **Zeitsprung Evolution**: Modifiziere Momentum-System nach Spielstil
- **Material-Effizienz**: Nutze Zeitkernkits für gezielte Kartenauswahl

### Endgame (Klassenstufe 20-25) - ~150-220h Spielzeit
- **Perfekte Momentum-Zyklen**: Meistere kontinuierliche Momentum-Generierung
- **Maximale Schattensynergie**: Nutze 0-Zeit-Karten optimal
- **Situative Anpassung**: Wähle Karten basierend auf Gegnermechaniken
- **Tempo-Perfektion**: Meistere alle Schattenschreiter-Mechaniken
- **Mastery-Vorbereitung**: Sammle Materialien für das Post-25 System

### Mastery-Phase (M1+) - ~220h+ Spielzeit
- **Elite-Content**: Nutze Mastery-exklusive Events und Weltbosse
- **Endlose Progression**: Kontinuierliche Verbesserung durch M-Level
- **Community-Events**: Teilnahme an Mega-Events mit globalen Zielen
- **Elite-Kartenvarianten**: Freischaltung verbesserter Kartenversionen
- **Mastery-Klassenboni**: Maximierung der +4s Schattenrausch-Dauer

### Material-Beschaffungs-Strategien

#### Events-Kalender optimieren
- **Täglich**: 3× Blitz-Events (Zeitrausch, Materialflut, Perfekte Synchronisation)
- **Wöchentlich**: Thematische Events für Elementarpfad-Spezialisierung
- **Monatlich**: Mega-Events für massive Material-Belohnungen

#### Mo.Co-Style RNG-Management
- **Keine Pity-Timer**: Pure RNG-Drops, kompensiert durch Events
- **Garantierte Quellen**: Tagesquests, Login-Streaks, Weltbosse
- **Mastery-Multiplikatoren**: +5% bis +30%+ Drop-Rate-Boni

## Beispiel-Kombos

### Momentum-Aufbau
1. **Schleier** (0,5s, +1 Momentum) → Schattensynergie aktiv
2. **Schattendolch** (0s durch Schattensynergie, +1 Momentum) → Total 2 Momentum
3. **Schattenkonzentration** (1,5s, +2 Momentum) → Total 4 Momentum
4. **Bei 5 Momentum**: Schattenrausch (+25% Effektivität für 5s)

### Explosiver Burst (Feuer-Pfad)
1. **Flammenschleier** (0,5s, Schattensynergie + DoT-Bonus)
2. **Höllenstich** (0s, 5 + 4 DoT, verstärkt durch Schattensynergie)
3. **Höllensturm** (5,0s, 12 AoE + 4 DoT auf alle) → Massive DoT-Akkumulation

### Zeitkontrolle (Eis-Pfad)
1. **Frostschleier** (0,5s, Schattensynergie + Slow-Bonus)
2. **Absolutstich** (0s, 5 Schaden + 40% Slow, verstärkt)
3. **Kryosturm** (5,0s, 10 AoE + 40% Slow auf alle) → Totale Kontrolle

### Tempo-Maximierung (Blitz-Pfad)
1. **Gewitterschatten** (0,5s, nächste 3 Angriffe 0s + Momentum + Karte)
2. **Donnerstich** → **Donnerstich** → **Donnerstich** (alle 0s, +6 Momentum total)
3. **Gewittersturm** (5,0s, verstärkt durch Momentum-Boni)

### Schattenrausch-Maximierung
1. **Momentum auf 4 aufbauen** durch Kartenkombinationen
2. **Zeitsprung Evolution nutzen**: (Feuer: +60% Effektivität, Eis: Frühe Schwellen, Blitz: +Momentum-Generation)
3. **Schattenrausch auslösen**: Nächste 5s alle Karten massiv verstärkt
4. **Während Rausch**: Maximale Kartenfolge für enormen Schaden/Kontrolle

Fokus auf **blitzschnelle Kartenfolgen** und perfekte Momentum-Kontrolle.
