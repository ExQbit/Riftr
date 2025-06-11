# Zeitklingen: Zeitwächter

## Klassen-Übersicht

**Der Defensive Kontrolleur** - Meistert Zeit durch Blocks, Reflexion und methodischen Schildmacht-Aufbau.

**⚖️ NEUE BALANCE-PHILOSOPHIE**: Opportunity Costs statt Hartcaps - Zeitmanipulations-Karten kosten mehr Zeit aber ermöglichen mächtige Effekte ohne künstliche Limits. Alle Kosten in Mobile-freundlichen 0,5s-Schritten.

## Kernmechanik: Schildmacht (0-5)

- **Generierung**: +1 pro erfolgreichem Block
- **Verfall-Mechanik** (präzisiert):
  - **Inaktivitäts-Timer**: Nach 5s ohne erfolgreichen Block beginnt Verfall
  - **Normaler Verfall** (0-2 SM): -1 SM alle 10s (max. 1 SM pro abgeschlossenem 10s-Intervall)
  - **Soft-Cap-Verfall** (3+ SM): -1 SM alle 5s (max. 1 SM pro abgeschlossenem 5s-Intervall) 
  - **Verfall-Reset**: Erfolgreicher Block stoppt Verfall sofort und setzt Timer zurück
- **Passive Boni** (kumulativ):
  - **1 SM**: +5% Blockdauer
  - **2+ SM**: +0,5s Zeitrückgewinn bei Block-Karten
  - **3+ SM**: +1 Schaden bei Angriffskarten  
  - **4+ SM**: Immunität gegen nächsten Zeitdiebstahl
- **Schildbruch (bei 5 SM)**: 15 direkter Schaden + 2,0s Zeitdiebstahl → Reset zu 0 SM

## Bonusmechanik: Phasenwechsel

- **Nach Verteidigung**: Nächste Angriffskarte +15% Schaden
- **Nach Angriff**: Nächste Verteidigungskarte +1s Zeitgewinn

## 🎯 **STARTERDECK (8 BASISKARTEN-INSTANZEN)**

**Jeder Zeitwächter beginnt mit exakt diesen 8 Karten:**

| Karte | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|--------|-----------|-----------|--------|
| **Schwertschlag** | 4 | 1,5s | Gewöhnlich | 5 Schaden (profitiert von SM-Boni) |
| **Schildschlag** | 2 | 1,5s | Gewöhnlich | 5 Schaden + 15% Zeitdiebstahlschutz (2s) |
| **Zeitblock** | 2 | 1,5s | Ungewöhnlich | Blockt nächsten Angriff (4s) + 0,5s Rückgewinn, +1 SM bei Block |

**🔓 Karten-Freischaltung**: Weitere 20 Karten werden durch Spielfortschritt freigeschaltet.

---

## Vollständige Kartenliste (26 Karten)

### Basisangriffe (12 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Schwertschlag | CARD-WAR-SWORDSLASH | 8 | 1,5s | Gewöhnlich | 5 Schaden (profitiert von SM-Boni) |
| Schildschlag | CARD-WAR-SHIELDSLASH | 4 | 1,5s | Gewöhnlich | 5 Schaden + 15% Zeitdiebstahlschutz (2s) |

### Verteidigung (6 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Zeitblock | CARD-WAR-TIMESHIELD | 4 | 1,5s | Ungewöhnlich | Blockt nächsten Angriff (4s) + 0,5s Rückgewinn, +1 SM bei Block |
| Zeitbarriere | CARD-WAR-TIMEBARRIER | 1 | 3,5s | Episch | -30% Zeitdiebstahl (5s) |
| Zeitkürass | CARD-WAR-TEMPORALARMOR | 1 | 3,0s | Selten | Reflektiert 25% nächsten Zeitdiebstahl |

### Zeitmanipulation (6 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Tempobindung | CARD-WAR-TIMEFETTER | 2 | 3,0s | Ungewöhnlich | +3s Gegnerverzögerung. **Trade-off**: +0,5s für defensive Spezialisierung. |
| Vorlauf | CARD-WAR-TEMPORALEFFICIENCY | 2 | 3,0s | Selten | Nächste Verteidigungskarte -1,0s |
| Wächterblick | CARD-WAR-WARDERFOCUS | 2 | 2,0s | Episch | +1,5s Zeitgewinn bei erfolgreichem Block |

### Signaturkarten (2 Karten)
| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| Zeitparade | CARD-WAR-TEMPORALCOUNTER | 1 | 4,0s | Legendär | Reflektiert nächsten Zeitdiebstahl + 6 Schaden |
| Temporale Bastion | CARD-WAR-TIMEFORTRESS | 1 | 5,0s | Legendär | +4s Zeit, 30% Zeitdiebstahlreduktion (6s), +1 Karte. **Trade-off**: +0,5s für premium defensive Option. |

## Evolution-System

### Elementarpfade
Alle Karten haben 3 Evolutionspfade:
- **Feuer**: Reflexion und DoT-Schaden
- **Eis**: Maximale Defensive und Zeitrückgewinnung
- **Blitz**: Karteneffizienz und Tempo

### Evolutionskosten
- **Stufe 1** (Level 9): 1× Elementarfragment
- **Stufe 2** (Level 25): 2× Elementarfragment
- **Stufe 3** (Level 35): 3× Elementarfragment

### Detaillierte Evolutionen

#### Schwertschlag Evolutionen
**Feuer-Pfad:**
| Stufe | Name | Kosten | Effekt | DoT-Kategorie | Zeitgewinn |
|-------|------|--------|--------|---------------|------------|
| 1: Flammenschlag | Flammeslash | 2,5s | 4 + 2 DoT | Schwach | 0,5s |
| 2: Glutklinge | Avengingsword | 3,0s | 5 + 3 DoT, +1 Schaden pro Block | Mittel | 1,0s |
| 3: Urteilsklinge | Retributionsword | 3,5s | 6 AoE-Schaden + 4 DoT, +2 Schaden pro Block | Stark | 2,0s |

**Eis-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Eisschlag | Iceslash | 2,5s | 4 + 15% Slow |
| 2: Frostschlag | Frostslash | 3,0s | 5 + 25% Slow, -20% Zeitdiebstahl |
| 3: Eisklinge | Glacierslash | 3,5s | 6 + 35% Slow, -30% Zeitdiebstahl |

**Blitz-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Blitzschlag | Stormslash | 2,0s | 4, -0,5s nächste Verteidigungskarte |
| 2: Gewitterschlag | Tempestslash | 2,5s | 5, -1,0s nächste Verteidigungskarte |
| 3: Sturmschlag | Lightningslash | 3,0s | 6, -1,5s nächste Verteidigungskarte |

#### Zeitblock Evolutionen
**Feuer-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Funkenschild | Flameshield | 2,5s | Blockt nächsten Angriff (4s), Reflektiert 2 Schaden. (+1 SM bei Block) |
| 2: Feuerbarriere | Firebarrier | 3,0s | Blockt nächsten Angriff (4s), Reflektiert 4 Schaden. (+1 SM bei Block) |
| 3: Feuerschutz | Infernoshield | 3,5s | Blockt nächsten Angriff (5s), Reflektiert 6 Schaden. (+1 SM bei Block) |

**Eis-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Frostschutz | Frostshield | 2,5s | Blockt nächsten Angriff (5s), +1,0s zurück. (+1 SM bei Block) |
| 2: Eisbarriere | Icebarrier | 3,0s | Blockt nächsten Angriff (6s), +1,0s zurück. (+1 SM bei Block) |
| 3: Frostwall | Permafrostshield | 3,5s | Blockt nächsten Angriff (7s), +1,5s zurück. (+1 SM bei Block) |

**Blitz-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Blitzschild | Stormshield | 2,0s | Blockt nächsten Angriff (4s), +1 Karte ziehen. (+1 SM bei Block) |
| 2: Gewitterschild | Energyshield | 2,5s | Blockt nächsten Angriff (4s), +1 Karte, diese kostet -0,5s. (+1 SM bei Block) |
| 3: Sturmschild | Lightningshield | 3,0s | Blockt nächsten Angriff (4s), +2 Karten, beide kosten -0,5s. **Generiert +2 SM bei Block.** |

#### Zeitfestung Evolutionen (Modifizieren Schildbruch und SM-System)
**Feuer-Pfad ("Flammenherz") - Modifiziert Schildbruch:**
| Stufe | Name | Kosten | Effekt | Schildbruch-Modifikation |
|-------|------|--------|--------|------------------------|
| 1: Flammwall | Timewarstand | 5,0s | +4s, 25% ZDR (6s), +1 Karte. | Schildbruch Schaden +5. |
| 2: Feuermauer | Timewararmor | 5,5s | +5s, 30% ZDR (8s), +2 Karten. | Schildbruch Schaden +10, fügt schwachen DoT hinzu. |
| 3: Flammherz | Timewarflame | 6,0s | +6s, 40% ZDR (10s), +3 Karten. | Schildbruch Schaden +15, fügt mittleren DoT hinzu. |

**Eis-Pfad ("Ewige Aegis") - Modifiziert passive SM-Boni:**
| Stufe | Name | Kosten | Effekt | Passive SM-Modifikation |
|-------|------|--------|--------|------------------------|
| 1: Frostwehr | Timebastion | 5,0s | +4s, 35% ZDR (10s), +1 Karte, 3s immun gg. Zeitdiebstahl. | +0,5s Zeitrückgewinn-Bonus (ab 2 SM) verdoppelt auf +1,0s. |
| 2: Frostmauer | Absolutetimefortress | 5,5s | +5s, 40% ZDR (15s), +2 Karten, 5s immun gg. Zeitdiebstahl. | Zeitrückgewinn auf +1,0s; +1 Schaden-Bonus (ab 3 SM) verdoppelt auf +2. |
| 3: Kryoschanze | Eternaltimebastion | 6,0s | +6s, 50% ZDR (15s), +3 Karten, 6s immun gg. Zeitdiebstahl. | Zeitrückgewinn auf +1,5s; Schaden-Bonus auf +2; Immunität bereits ab 3 SM aktiv. |

**Blitz-Pfad ("Tempokern") - Modifiziert SM-Generierung:**
| Stufe | Name | Kosten | Effekt | SM-Generierungs-Modifikation |
|-------|------|--------|--------|----------------------------|
| 1: Voltwall | Timebattlement | 5,0s | +4s, 25% ZDR (6s), +2 Karten, nächste 3 Karten -1,0s. | Erfolgreiche Blocks generieren +1 zusätzliche SM (also +2 gesamt pro Block). |
| 2: Gewitterwall | Timesynchronizationtower | 5,5s | +5s, 30% ZDR (8s), +3 Karten, nächste 5 Karten -1,0s. | Erfolgreiche Blocks +1 zusätzliche SM. Beim Ausspielen: +1 SM. |
| 3: Sturmturm | Chronostormtower | 6,0s | +6s, 40% ZDR (10s), +4 Karten, nächste 5 Karten -1,0s. | Erfolgreiche Blocks +2 zusätzliche SM (also +3 gesamt). Beim Ausspielen: +2 SM. |

#### Zeitparade Evolutionen
**Feuer-Pfad:**
| Stufe | Name | Kosten | Effekt | DoT-Kategorie | Zeitgewinn |
|-------|------|--------|--------|--------------|------------|
| 1: Brandparade | Firecounter | 4,0s | Reflektiert nächsten Zeitdiebstahl + 8 Schaden | - | - |
| 2: Glutkonter | Infernalcounterstrike | 4,5s | Reflektiert nächsten Zeitdiebstahl + 10 Schaden + 3 DoT | Mittel | 1,0s |
| 3: Flammspiegel | Flameriposte | 5,0s | Reflektiert nächsten Zeitdiebstahl + 12 Schaden + 4 DoT | Stark | 2,0s |

**Eis-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Eisparade | Frostcounter | 4,0s | Reflektiert nächsten Zeitdiebstahl + 6 Schaden + 25% Slow (3s) |
| 2: Frostreflex | Glacierriposte | 4,5s | Reflektiert nächsten Zeitdiebstahl + 8 Schaden + 40% Slow (5s) |
| 3: Kryospiegel | Icetimecounter | 5,0s | Reflektiert nächsten Zeitdiebstahl + 10 Schaden + 50% Slow (6s) |

**Blitz-Pfad:**
| Stufe | Name | Kosten | Effekt |
|-------|------|--------|--------|
| 1: Voltparade | Lightningcounter | 3,5s | Reflektiert nächsten Zeitdiebstahl + 6 Schaden, +1 Karte |
| 2: Donnerschlag | Stormcounter | 4,0s | Reflektiert nächsten Zeitdiebstahl + 7 Schaden, +2 Karten |
| 3: Blitzreflex | Thundercounter | 4,5s | Reflektiert nächsten Zeitdiebstahl + 8 Schaden, +3 Karten |

## Strategische Pfade

### Feuer-Pfad ("Zeitliche Vergeltung")
- **Fokus**: "Schaden zurückwerfen", Reflektion, DoT
- **Stärken**: Höchster Einzelzielschaden, Gegner leiden unter eigenen Angriffen, Zeitgewinn durch DoT
- **Schwächen**: Geringere direkte Zeitrückgewinnung, abhängig von Gegneraktionen
- **Zeitfestung Mod**: Schildbruch +15 Schaden + mittlerer DoT

### Eis-Pfad ("Chronobarriere")  
- **Fokus**: "Verzögern und Überleben", maximale Defensive
- **Stärken**: Höchste Zeitrückgewinnung, längste Blockdauer, Zeitdiebstahlschutz, Slow-Effekte
- **Schwächen**: Geringerer Direktschaden, längere Kämpfe
- **Zeitfestung Mod**: Passive SM-Boni verstärkt (+1,5s statt +0,5s Zeitrückgewinn)

### Blitz-Pfad ("Tempoverteidiger")
- **Fokus**: "Effizienz und Kartenfluss", Kostenreduktion
- **Stärken**: Höchste Kartenzugrate, Kostenreduktion, Kombo-Potenzial, Tempo
- **Schwächen**: Geringere Blockdauer, weniger direkte Schadensreduktion
- **Zeitfestung Mod**: +2 SM-Generierung pro Block

## 🎯 **Progression & Mastery-Integration (KRITISCH DETAILLIERT)**

### 📊 **Klassenstufen-System (Mo.Co-Style - VOLLSTÄNDIG)**
- **25 Klassenstufen** mit exponentieller XP-Kurve (1.329.000 XP total)
- **Kartenlevel-Limit**: Karten können maximal Klassenstufe × 2 erreichen
- **XP-Boost-System**: 4×/3×/2×/1× tägliche Boosts (60.000 XP Limit)
- **Geschätzte Spielzeit**: ~220h total F2P (280h ohne Boost)
- **Welt-Zugang**: Welt 2 bei Level 17, Welt 3 bei Level 33, etc.

### 🏆 **Detaillierte XP-Tabelle für Zeitwächter**
| Stufe | XP für Stufe | Kumulativ | Hauptquellen | Geschätzte Zeit |
|-------|--------------|-----------|-------------|----------------|
| 1→5 | 10.000 | 10.000 | Prolog + Kapitel 1 | 3h |
| 5→10 | 44.000 | 54.000 | Tagesquests + Projekte | 7h |
| 10→15 | 275.000 | 329.000 | Dungeon-Kette + Events | 35h |
| 15→17 | 200.000 | 529.000 | Weltboss-Vorbereitung | 25h |
| 17→25 | 800.000 | 1.329.000 | Welt 2-5 + Endgame | 150h |
| **Gesamt** | **1.329.000** | **1.329.000** | **Komplette Progression** | **220h** |

### 🛡️ **Klassenspezifische Progression-Boni (KRITISCH ERWEITERT)**
| Klassenstufe | Zeitwächter-Bonus | Spielauswirkung | Material-Fokus |
|--------------|-------------------|-----------------|----------------|
| **Stufe 5** | **Wachsame Verteidigung**: +15% Blockdauer | Sicherere Blocks, weniger Timing-Fehler | Zeitkerne für Starterkarte-Levels |
| **Stufe 10** | **Schild-Echo**: +1 Schildmacht bei Block | Doppelte SM-Generierung (2 statt 1) | Elementarfragmente für erste Evolutionen |
| **Stufe 15** | **Temporale Rüstung**: -10% Zeitdiebstahl-Schaden | Weniger Zeitverlust durch Gegnerangriffe | Zeitfokus für Defensive Attribut-Rerolls |
| **Stufe 20** | **Vergeltung**: Reflektierter Schaden +25% | Gegner schädigen sich selbst stärker | Event-Teilnahme für seltene Drops |
| **Stufe 25** | **Zeitfortifikation**: Schildbruch +5 Schaden, -1s Cooldown | Mächtigere und häufigere Schildbrüche | **Mastery-System freigeschaltet** |

### 🌟 **Kartenlevel-Limits pro Klassenstufe**
| Klassenstufe | Max Kartenlevel | Entspricht | Beispiel-Power |
|--------------|-----------------|------------|----------------|
| Stufe 5 | Level 10 | Gate 1 (Uncommon) | 130% Basisstärke |
| Stufe 10 | Level 20 | Gate 2 (Rare) | 170% Basisstärke |
| Stufe 15 | Level 30 | Gate 3 (Epic) | 220% Basisstärke |
| Stufe 20 | Level 40 | Gate 4 (Legendary) | 280% Basisstärke |
| Stufe 25 | Level 50 | Maximum | 350% Basisstärke |

### Mastery-System (Post-Klassenstufe 25)

#### Zeitwächter Mastery-Boni
| Mastery Level | Bonus | Auswirkung |
|---------------|-------|-----------|
| **M5** | **Verstärkte Verteidigung** | +20% Blockdauer |
| **M15** | **Temporale Festung** | -15% Zeitdiebstahl-Schaden |
| **M25** | **Zeitunbezwingbar** | Schildbruch +10 Schaden, -2s Cooldown |
| **M25+** | **Endlose Fortifikation** | Kontinuierliche Defensive-Boni pro M-Level |

#### Mastery-Material-Vorteile
- **M5+**: Zugang zu Elite-Tagesquests (8-12 Zeitkerne, 3-5 Fragmente täglich)
- **M10+**: Mastery-Weltbosse (25-35 Zeitkerne, 8-12 Fragmente, 2× wöchentlich)
- **M15+**: Exklusive Mastery-Events mit Elite-Kartenvarianten
- **M20+**: Premium-Drop-Quellen mit garantierten seltenen Materialien

## Spielstrategien (Mo.Co-Integration)

### Frühe Phase (Klassenstufe 1-10) - ~5-22h Spielzeit
- **Schildmacht-Management lernen**: Verstehe Generierung durch Blocks
- **Phasenwechsel nutzen**: Wechsle zwischen Verteidigung und Angriff für Boni
- **Erste defensive Evolutionen**: Fokus auf Zeitblock und Hauptverteidigung (Level 9/25/35)
- **Passive SM-Boni verstehen**: Nutze 2+/3+/4+ Boni optimal
- **Material-Sammlung**: Nutze tägliche Blitz-Events (+100-150% Material-Bonus)
- **Kartenlevel-Limit beachten**: Karten können nur bis Klassenstufe × 2 gelevelt werden

### Mittlere Phase (Klassenstufe 10-20) - ~22-150h Spielzeit
- **Schildbruch-Timing**: Perfektioniere wann du den 5-SM-Bonus einsetzt
- **Elementarpfad wählen**: Spezialisiere auf Feuer/Eis/Blitz basierend auf Events
- **Event-Optimierung**: Teilnahme an thematischen Events (Feuer-Zeitalter, Frostzeit, Gewittersturm)
- **Erweiterte Defensive**: Nutze Phasenwechsel + SM synergistisch
- **Zeitfestung Evolution**: Modifiziere SM-System nach Spielstil
- **Material-Effizienz**: Nutze Zeitkernkits für gezielte Kartenauswahl

### Endgame (Klassenstufe 20-25) - ~150-220h Spielzeit
- **Perfekte SM-Aufbau-Zyklen**: Meistere methodische SM-Generierung
- **Optimierte Evolutionen**: Alle Schlüsselkarten auf höchster Stufe
- **Situative Verteidigung**: Wähle Karten basierend auf Gegnermechaniken
- **Defensive Überlegenheit**: Meistere alle Zeitwächter-Mechaniken
- **Mastery-Vorbereitung**: Sammle Materialien für das Post-25 System

### Mastery-Phase (M1+) - ~220h+ Spielzeit
- **Elite-Content**: Nutze Mastery-exklusive Events und Weltbosse
- **Endlose Progression**: Kontinuierliche Verbesserung durch M-Level
- **Community-Events**: Teilnahme an Mega-Events mit globalen Zielen
- **Elite-Kartenvarianten**: Freischaltung verbesserter Kartenversionen
- **Mastery-Klassenboni**: Maximierung der Zeitunbezwingbar-Fähigkeiten

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

### Schildmacht-Aufbau
1. **Zeitblock** (2,5s, Block erfolgreich = +1 SM, Phasenwechsel-Bonus aktiv)
2. **Schwertschlag** (+15% Schaden durch Phasenwechsel, +1 Schaden bei 3+ SM)
3. **Bei 5 SM**: Automatischer Schildbruch (15 Schaden + 2s Zeitdiebstahl)

### Defensive Kontrolle
1. **Zeitfessel** (+3s Gegnerverzögerung, Phasenwechsel-Bonus aktiv)
2. **Zeitblock** (+1s Zeitgewinn durch Phasenwechsel, +1 SM bei Block)
3. **Zeitparade** (Reflektiert Zeitdiebstahl + Schaden)

### Zeitliche Vergeltung (Feuer-Pfad)
1. **Funkenschild** (Blockt + reflektiert 2 Schaden, +1 SM)
2. **Flammenschlag** (4 + 2 DoT, +1 Schaden durch 3+ SM)
3. **Bei 5 SM**: Flammenherz-Schildbruch (30 Schaden + mittlerer DoT)

### Chronobarriere (Eis-Pfad)
1. **Frostschutz** (Blockt 5s, +1,0s zurück, verstärkt durch Eis-Mod)
2. **Eisschlag** (4 + 15% Slow, +Schaden-Bonus durch SM)
3. **Kryoschanze-Bonus**: Immunität bereits ab 3 SM aktiv

### Tempoverteidiger (Blitz-Pfad)
1. **Sturmschild** (Blockt, +2 Karten -0,5s, +2 SM bei Block)
2. **Schnelle Kartenfolge** durch Kostenreduktion
3. **Sturmturm-Bonus**: +3 SM pro Block für explosive SM-Generierung

Fokus auf **methodische Kontrolle** durch defensive Überlegenheit.
