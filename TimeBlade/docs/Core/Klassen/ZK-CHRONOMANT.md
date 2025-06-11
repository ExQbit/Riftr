# Zeitklingen: Chronomant

## Klassen-Übersicht

**Der Zeitmanipulator** - Meistert arkane Magie und Zeitfluss durch strategisches Ressourcen-Management.

**⚖️ NEUE BALANCE-PHILOSOPHIE**: Opportunity Costs statt Hartcaps - Zeitmanipulations-Karten kosten mehr Zeit aber ermöglichen mächtige Effekte ohne künstliche Limits. Alle Kosten in Mobile-freundlichen 0,5s-Schritten.

## Kernmechanik: Arkanpuls (0-5)

- **Generierung**: +1 pro Zeitmanipulations- oder Elementarkarte (bei Treffer)
- **Verfall**: -1 pro Sekunde nach 3s Inaktivität  
- **Schwellenboni**:
  - **1**: +5% Zeiteffizienz (alle Karten kosten 5% weniger Zeit)
  - **2+**: +10% Elementarschaden
  - **3+**: -0,5s Zeitkosten für Zeitmanipulation
  - **4+**: +15% Zeitmanipulation-Effektivität
- **Arkanschub (bei 5)**: Nächste Karte +50% Effektivität → Reset auf 0

## Bonusmechanik: Kartenreihenfolge

- **Zeitmanipulation → Elementar**: +20% Schaden für nächste Elementarkarte
- **Elementar → Zeitmanipulation**: +10% Effektivität für nächste Zeitmanipulation

## 🎯 **STARTERDECK (8 BASISKARTEN-INSTANZEN)**

**Jeder Chronomant beginnt mit exakt diesen 8 Karten:**

| Karte | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|--------|-----------|-----------|--------|
| **Arkanstrahl** | 4 | 1,5s | Gewöhnlich | 5 Schaden. +1 Arkanpuls-Ladung bei Treffer. |
| **Temporaler Aufschub** | 2 | 2,5s | Ungewöhnlich | Verzögert nächsten Gegnerangriff um 2,0s. +1 Arkanpuls-Ladung. **Trade-off**: +0,5s für Zeitkontrolle. |
| **Chronowall** | 2 | 0,5s | Ungewöhnlich | Blockiert nächsten Angriff innerhalb 3,0s. Bei Block: +1 zusätzliche Arkanpuls-Ladung. |

**🔓 Karten-Freischaltung**: Weitere 18 Karten werden durch Spielfortschritt freigeschaltet.

---

## Vollständige Kartenliste (26 Karten)

### Basiszauber (4 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|

| Arkanstrahl | CARD-MAGE-ARCANICRAY | 8 | 1,5s | Gewöhnlich | 5 Schaden. +1 Arkanpuls-Ladung bei Treffer. |
| Elementarfokus | CARD-MAGE-SPELLFOCUS | 3 | 2,5s | Episch | Nächster Elementarzauber +X% Effektivität (X = 25 + 5 × Arkanpuls). +1 Arkanpuls-Ladung. |

### Zeitmanipulation (20 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Temporaler Aufschub | CARD-MAGE-DELAY | 3 | 2,5s | Ungewöhnlich | Verzögert nächsten Gegnerangriff um 2,0s. +1 Arkanpuls-Ladung. **Trade-off**: +0,5s für Zeitkontrolle. |
| Beschleunigen | CARD-MAGE-ACCELERATE | 3 | 2,5s | Selten | Nächste 2 Karten -Y Sekunden Kosten (Y = 0,5s/1,0s/1,5s je nach Arkanpuls). +1 Arkanpuls-Ladung. |
| Chronowall | CARD-MAGE-CHRONOBARRIER | 2 | 0,5s | Ungewöhnlich | Blockiert nächsten Angriff innerhalb 3,0s. Bei Block: +1 zusätzliche Arkanpuls-Ladung. |
| Chrono-Ernte | CARD-MAGE-TEMPORALRIFTRECOVERY | 2 | 3,0s | Selten | Erhalte +2,0s Zeit, wenn Gegner innerhalb 5,0s stirbt. +1 Arkanpuls-Ladung. |
| Chronostoß | CARD-MAGE-TIMETREMOR | 1 | 4,5s | Episch | +3,0s Zeit, 6 AoE-Schaden, +1 Karte. +1 Arkanpuls-Ladung. **Trade-off**: -40% Schaden für Zeitgewinn. |
| Arkane Intelligenz | CARD-MAGE-ARCANEINTELLIGENCE | 1 | 1,5s | Legendär | Ziehe 1 Karte + 1 zusätzliche pro 2 Arkanpuls-Ladungen. +1 Arkanpuls-Ladung. |

### Signaturkarten (2 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Chrono-Manipulation | CARD-MAGE-TIMEWARP | 1 | 4,5s | Legendär | Verlangsamt Ziel um 30% für 3,0s. +1 Arkanpuls-Ladung. **Trade-off**: +0,5s für Zeitfluss-Kontrolle. Evolutionen modifizieren Arkanschub. |

## Evolution-System

### Elementarpfade
Alle Karten haben 3 Evolutionspfade:
- **Feuer**: DoT-Fokus, offensive Stärke
- **Eis**: Kontrolle, defensive Effekte  
- **Blitz**: Tempo, Ketteneffekte, Synergien

### Evolutionskosten
- **Stufe 1** (Level 9): 1× Elementarfragment
- **Stufe 2** (Level 25): 2× Elementarfragment
- **Stufe 3** (Level 35): 3× Elementarfragment

### Detaillierte Evolutionen

#### Arkanstrahl Evolutionen
**Feuer-Pfad:**
| Stufe | Name | Kosten | Effekt | DoT-Kategorie | Zeitgewinn |
|-------|------|--------|--------|---------------|------------|
| 1: Feuerball | Fireball | 2,0s | 5 + kleiner AoE + 2 DoT | Mittel | 1,0s |
| 2: Magmastrahl | Flamesphere | 2,5s | 7 + mittlerer AoE + 3 DoT | Stark | 2,0s |
| 3: Solarstrahl | Conflagration | 3,0s | 9 + großer AoE + 5 DoT | Stark | 2,0s |

**Eis-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Eisstrahl | Icelance | 2,0s | 4 Schaden + 20% Slow (3,0s) |
| 2: Froststrahl | Frostcascade | 2,5s | 6 Schaden + 30% Slow (3,5s, kleine AoE) |
| 3: Kryostrahl | Icestorm | 3,0s | 7 Schaden + 40% Slow (4,0s, mittlere AoE) |

**Blitz-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|---------|
| 1: Blitzstrahl | Lightningbolt | 1,5s | 4 Schaden + trifft 1 weiteres Ziel für 60% Schaden. Bei 4+ Arkanpuls: +1 Schaden und ziehe 1 Karte. |
| 2: Donnerstrahl | Lightningstorm | 2,0s | 5 Schaden + trifft 1 weiteres Ziel für 60% Schaden. Bei 4+ Arkanpuls: +2 Schaden und ziehe 1 Karte. |
| 3: Gewitterstrahl | Thunderstorm | 2,5s | 6 Schaden + trifft 2 weitere Ziele für 60%/40% Schaden. Bei 4+ Arkanpuls: +3 Schaden und ziehe 2 Karten. |

#### Verzögern Evolutionen
**Feuer-Pfad ("Zeitbrand"):**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Brandfessel | Timespark | 2,0s | Verzögert nächsten Angriff um 2,0s. Angreifer erleidet 2 Schaden. |
| 2: Glutfessel | Timeflame | 2,0s | Verzögert nächsten Angriff um 2,5s. Angreifer erleidet 3 Schaden + 1 DoT (Schwach). |
| 3: Feuerstau | Chronoinferno | 2,5s | Verzögert nächsten Angriff um 3,0s. Angreifer erleidet 5 Schaden + 2 DoT (Mittel). |

**Eis-Pfad ("Zeitfrost"):**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Frostfessel | Frostfetter | 2,0s | Verzögert nächsten Angriff um 3,0s. |
| 2: Eisfalle | Icetimetrap | 2,0s | Verzögert nächsten Angriff um 4,0s. Gegner +15% verlangsamt (3,0s). |
| 3: Kryostau | Cryostasis | 2,5s | Verzögert nächsten Angriff um 5,0s. Gegner +30% verlangsamt (3,0s). |

**Blitz-Pfad ("Zeitschock"):**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Schockfessel | Timespark | 2,0s | Verzögert nächsten Angriff um 2,5s. Verursacht 1 Schaden am Angreifer. |
| 2: Donnerfessel | Temporalshock | 2,0s | Verzögert nächsten Angriff um 3,0s. Verursacht 2 Schaden, 0,5s Stun. |
| 3: Gewitterstau | Chronothunderstorm | 2,5s | Verzögert nächsten Angriff um 3,5s. Verursacht 3 Schaden, 1,0s Stun. |

#### Beschleunigen Evolutionen
**Feuer-Pfad ("Zeitschub"):**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Feuerschub | Tempo Inferno | 2,5s | Nächste 2 Karten -0,5s Kosten. +5% Feuer-Schaden für nächste Karte. |
| 2: Glutschub | Temporal Acceleration Fire | 2,5s | Nächste 2 Karten -0,7s Kosten. +10% Feuer-Schaden für nächste 2 Karten. |
| 3: Magmaschub | Chronosphere Scorch | 3,0s | Nächste 3 Karten -1,0s Kosten. +15% Feuer-Schaden für nächste 3 Karten. |

#### Zeitverzerrung Evolutionen (Modifizieren Arkanschub)
**Feuer-Pfad ("Zeitliche Entzündung"):**
| Stufe | Name | Kosten | Effekt | Arkanschub-Modifikation |
|-------|------|--------|--------|------------------------|
| 1: Feuerkrümmung | Ignite | 4,0s | Verlangsamt Ziel um 30% (3s). Ziel erleidet 2 Feuerschaden/Sek. | Arkanschub verursacht +5 AoE Schaden. |
| 2: Glutkrümmung | Time Scorch | 4,0s | Verlangsamt Ziel um 35% (3,5s). Ziel erleidet 3 Feuerschaden/Sek. | Arkanschub verursacht +10 AoE Schaden. |
| 3: Magmakrümmung | Chrono Inferno | 4,5s | Verlangsamt Ziel um 40% (4s). Ziel erleidet 4 Feuerschaden/Sek. | Arkanschub verursacht +15 AoE Schaden. |

**Eis-Pfad ("Zeitlicher Stillstand"):**
| Stufe | Name | Kosten | Effekt | Arkanschub-Modifikation |
|-------|------|--------|--------|------------------------|
| 1: Eiskrümmung | Freeze | 4,0s | Verlangsamt Ziel um 40% (3s). | Arkanschub-Effekt wirkt AoE (falls auf Ziel). |
| 2: Frostkrümmung | Cryostasis | 4,0s | Verlangsamt Ziel um 50% (3,5s). | Arkanschub-Effekt wirkt AoE. |
| 3: Kryokrümmung | Absolute Zero | 4,5s | Verlangsamt Ziel um 60% (4s). | Arkanschub-Effekt wirkt AoE. |

**Blitz-Pfad ("Zeitparadoxon"):**
| Stufe | Name | Kosten | Effekt | System-Modifikation |
|-------|------|--------|--------|--------------------|
| 1: Blitzkrümmung | Fluctuate | 4,0s | Verlangsamt Ziel um 30% (3s). | Arkanschub: Bonus-Effektivität nur +25% (statt +50%). |
| 2: Donnerkrümmung | Paradox Pulse | 4,0s | Verlangsamt Ziel um 35% (3,5s). | Arkanschub: Bonus-Effektivität +50%. Arkanpuls-Verfall -0,5pkt/s. |
| 3: Chronoschritt | Chrono Collapse | 4,5s | Verlangsamt Ziel um 40% (4s). | Arkanschub: Bonus-Effektivität +75%. Arkanpuls-Verfall -0,5pkt/s. |

## 🎯 **Progression & Mastery-Integration (KRITISCH DETAILLIERT)**

### 📊 **Klassenstufen-System (Mo.Co-Style - VOLLSTÄNDIG)**
- **25 Klassenstufen** mit exponentieller XP-Kurve (1.329.000 XP total)
- **Kartenlevel-Limit**: Karten können maximal Klassenstufe × 2 erreichen
- **XP-Boost-System**: 4×/3×/2×/1× tägliche Boosts (60.000 XP Limit)
- **Geschätzte Spielzeit**: ~220h total F2P (280h ohne Boost)
- **Welt-Zugang**: Welt 2 bei Level 17, Welt 3 bei Level 33, etc.

### 🏆 **Detaillierte XP-Tabelle für Chronomant**
| Stufe | XP für Stufe | Kumulativ | Hauptquellen | Geschätzte Zeit |
|-------|--------------|-----------|-------------|----------------|
| 1→5 | 10.000 | 10.000 | Prolog + Kapitel 1 | 3h |
| 5→10 | 44.000 | 54.000 | Tagesquests + Projekte | 7h |
| 10→15 | 275.000 | 329.000 | Dungeon-Kette + Events | 35h |
| 15→17 | 200.000 | 529.000 | Weltboss-Vorbereitung | 25h |
| 17→25 | 800.000 | 1.329.000 | Welt 2-5 + Endgame | 150h |
| **Gesamt** | **1.329.000** | **1.329.000** | **Komplette Progression** | **220h** |

### 🔮 **Klassenspezifische Progression-Boni (KRITISCH ERWEITERT)**
| Klassenstufe | Chronomant-Bonus | Spielauswirkung | Material-Fokus |
|--------------|------------------|-----------------|----------------|
| **Stufe 5** | **Arkane Präkognition**: +10% Arkanpuls-Generierung | Schnellerer Arkanpuls-Aufbau, frühere Schwellenboni | Zeitfokus für Arkanpuls-Optimierung |
| **Stufe 10** | **Elementare Resonanz**: +5% Elementarschaden pro Element | Multi-Element-Strategien werden effektiver | Elementarfragmente für Evolution-Vielfalt |
| **Stufe 15** | **Zeitrückgewinnung**: +0.5s Zeit pro Arkanschub | Längere Kämpfe durch Zeitgewinn | Zeitkerne für Arkan-Schlüsselkarten |
| **Stufe 20** | **Arkane Synergie**: Kartenreihenfolge-Boni +5% stärker | Sequenz-Strategien werden dominierend | Event-Teilnahme für Premium-Materials |
| **Stufe 25** | **Zeitmanipulation**: Alle Zeiteffekte +15% stärker | Ultimative Zeit-Herrschaft erreicht | **Mastery-System freigeschaltet** |

### 🎆 **Arkanpuls-Skalierung pro Klassenstufe**
| Klassenstufe | Arkanpuls-Generierung | Schwellenboni | Arkanschub-Power |
|--------------|----------------------|---------------|------------------|
| Stufe 5 | +10% Generation | Standard (2+/3+/4+) | +50% Effektivität |
| Stufe 10 | +10% + Multi-Element | Verbesserte Boni | +50% + Element-Boni |
| Stufe 15 | +10% + +0.5s/Schub | Zeitgewinn-Integration | +50% + 0.5s Zeit |
| Stufe 20 | +15% (kumulativ) | Stärkere Sequenzen | +55% + Sequenz-Boni |
| Stufe 25 | +25% (kumulativ) | Alle Effekte verstärkt | +65% + Zeit-Meisterschaft |

### 🌟 **Kartenlevel-Limits pro Klassenstufe**
| Klassenstufe | Max Kartenlevel | Entspricht | Arkanpuls-Effizienz |
|--------------|-----------------|------------|--------------------|
| Stufe 5 | Level 10 | Gate 1 (Uncommon) | 1.1× Basis-Generierung |
| Stufe 10 | Level 20 | Gate 2 (Rare) | 1.3× + Element-Boni |
| Stufe 15 | Level 30 | Gate 3 (Epic) | 1.5× + Zeitgewinn |
| Stufe 20 | Level 40 | Gate 4 (Legendary) | 1.7× + Sequenz-Power |
| Stufe 25 | Level 50 | Maximum | 2.0× Zeit-Meisterschaft |

### Mastery-System (Post-Klassenstufe 25)

#### Chronomant Mastery-Boni
| Mastery Level | Bonus | Auswirkung |
|---------------|-------|------------|
| **M5** | **Erweiterte Präkognition** | +15% Arkanpuls-Generierung |
| **M15** | **Zeitmeisterschaft** | +1s Zeit pro Arkanschub |
| **M25** | **Chronos-Macht** | Alle Zeiteffekte +25% stärker |
| **M25+** | **Endlose Verbesserung** | Kontinuierliche Stat-Boni pro M-Level |

#### Mastery-Material-Vorteile
- **M5+**: Zugang zu Elite-Tagesquests (8-12 Zeitkerne, 3-5 Fragmente täglich)
- **M10+**: Mastery-Weltbosse (25-35 Zeitkerne, 8-12 Fragmente, 2× wöchentlich)
- **M15+**: Exklusive Mastery-Events mit Elite-Kartenvarianten
- **M20+**: Premium-Drop-Quellen mit garantierten seltenen Materialien

## Spielstrategien (Mo.Co-Integration)

### Frühe Phase (Klassenstufe 1-10) - ~5-22h Spielzeit
- **Arkanpuls-Management lernen**: Verstehe Generierung und Verfall
- **Kartenreihenfolge nutzen**: Wechsle zwischen Zeitmanipulation und Elementar
- **Erste Evolutionen**: Fokus auf Hauptschadens-Karten (Level 9/25/35)
- **Schwellenboni verstehen**: Nutze 2+/3+/4+ Boni optimal
- **Material-Sammlung**: Nutze tägliche Blitz-Events (+100-150% Material-Bonus)
- **Kartenlevel-Limit beachten**: Karten können nur bis Klassenstufe × 2 gelevelt werden

### Mittlere Phase (Klassenstufe 10-20) - ~22-150h Spielzeit  
- **Arkanschub-Timing**: Perfektioniere wann du den 5-Punkt-Bonus einsetzt
- **Elementarpfad wählen**: Spezialisiere auf Feuer/Eis/Blitz basierend auf Events
- **Event-Optimierung**: Teilnahme an thematischen Events (Feuer-Zeitalter, Frostzeit, Gewittersturm)
- **Erweiterte Kombos**: Nutze Kartenreihenfolge + Arkanpuls synergistisch
- **Zeitverzerrung Evolution**: Modifiziere Arkanschub nach Spielstil
- **Material-Effizienz**: Nutze Zeitkernkits für gezielte Kartenauswahl

### Endgame (Klassenstufe 20-25) - ~150-220h Spielzeit
- **Perfekte Kombos**: Meistere komplexe Arkanpuls/Kartenreihenfolge-Sequenzen
- **Optimierte Evolutionen**: Alle Schlüsselkarten auf höchster Stufe
- **Situative Anpassung**: Wähle Karten basierend auf Gegnermechaniken
- **Timing-Perfektion**: Nutze alle Mechaniken in optimaler Sequenz
- **Mastery-Vorbereitung**: Sammle Materialien für das Post-25 System

### Mastery-Phase (M1+) - ~220h+ Spielzeit
- **Elite-Content**: Nutze Mastery-exklusive Events und Weltbosse
- **Endlose Progression**: Kontinuierliche Verbesserung durch M-Level
- **Community-Events**: Teilnahme an Mega-Events mit globalen Zielen
- **Elite-Kartenvarianten**: Freischaltung verbesserter Kartenversionen
- **Mastery-Klassenboni**: Maximierung der +25% Zeiteffekt-Verstärkung

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

### Effizienz-Aufbau
1. **Beschleunigen** (2,5s, +1 Arkanpuls) → Kartenreihenfolge-Bonus aktiv
2. **Arkanblick** (1,0s → 0,5s durch 3+ Arkanpuls, +1 Arkanpuls) → Zieht 2 Karten
3. **Bei 5 Arkanpuls**: Arkanschub auf stärkste Elementarkarte (z.B. Solarstrahl)

### Defensive Kontrolle  
1. **Chronowall** (2,0s, +1 Arkanpuls) → Bereit für Gegnerangriff
2. **Bei erfolgreichem Block**: +1 zusätzliche Arkanpuls (Total 2)
3. **Verzögern** (2,0s → 1,5s durch 3+ Arkanpuls, +1 Arkanpuls) → +3s Gegnerverzögerung
4. **Counterattack** mit verstärktem Elementarzauber (10% Bonus durch 2+ Arkanpuls)

### Arkanschub-Maximierung
1. **Kartenreihenfolge beachten**: Zeitmanipulation vor Elementar für +20% Schaden
2. **Arkanpuls aufbauen**: 4 Karten spielen für 4+ Arkanpuls
3. **5. Karte spielen**: Löst Arkanschub aus
4. **Zeitverzerrung Evolution**: Modifiziert Arkanschub-Effekt (Feuer: +AoE, Eis: +AoE-Effekt, Blitz: +Effizienz)

Fokus auf **strategische Tiefe** durch Ressourcen-Management und Timing.
