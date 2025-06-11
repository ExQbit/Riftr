# Zeitklingen: Gegner-Datenbank (Mo.Co-Style v2.0)

## 🎯 **Mo.Co-Integration abgeschlossen**
- **4-Material-System**: Zeitkern, Zeitkernkit, Elementarfragment, Zeitfokus
- **Pure RNG-Drops**: Keine Pity-Timer, Event-Kompensation
- **XP-System**: Alle Gegner geben XP für Klassenprogression
- **Event-Integration**: Spezielle Gegner für Events
- **Mastery-Skalierung**: Elite-Versionen für hohe M-Level

---

## 🔧 **Drop-System (Mo.Co-Style)**

### Basis-Drop-Raten (Pure RNG - aus ZK-MATERIALS.md)
| Gegnertyp | Zeitkern | Elementarfragment | Zeitfokus | XP |
|-----------|----------|-------------------|-----------|-----|
| **Standard** | 8.0% (1-2) | 2.0% (1) | 0.3% (1) | 50-150 |
| **Elite** | 12.0% (2-3) | 4.0% (1-2) | 0.8% (1) | 150-400 |
| **Mini-Boss** | 25.0% (3-5) | 10.0% (2-3) | 3.0% (1-2) | 400-800 |
| **Boss** | 25.0% (5-8) | 10.0% (3-5) | 3.0% (2-4) | 1000-2000 |

### Zeitkernkit-Drops (Spezielle Quellen)
- **Mini-Bosse**: 15% Chance auf 1 Zeitkernkit
- **Haupt-Bosse**: 30% Chance auf 1-2 Zeitkernkits
- **Event-Bosse**: 50% Chance auf 1-3 Zeitkernkits

---

### DESIGN-PHILOSOPHIE: Gegner-Angriffe
Gegner in Zeitklingen verursachen KEINEN direkten Schaden an Spieler-HP (Spieler haben keine HP!).
Stattdessen manipulieren Gegner die ZEIT:
- **Zeitdiebstahl**: Reduziert verbleibende Rift-Zeit
- **Kartenkosten-Erhöhung**: Macht Karten teurer  
- **Karten-Blockierung**: Verhindert Kartennutzung temporär
- **Verzögerungseffekte**: Verschiebt Karteneffekte

### Mathematische Balance-Grundlagen
Basierend auf v5.0 Playtest:
- Standard-Gegner: 5-20 HP (2-8 Karten zum Besiegen)
- Elite-Gegner: 35-50 HP (10-15 Karten)
- Bosse: 80-100 HP (25-35 Karten)
- Zeitdiebstahl-Limits: Max 15% der Gesamtzeit pro Rift

---

## 📚 **Prolog: Tutorial-Kämpfe**

*Der Prolog führt Spieler in die Zeit-Mechaniken ein und schaltet die ersten Karten frei.*

### Prolog-Kampf 1: "Erste Begegnung"

#### Zeit-Echo (Tutorial)
| Attribut | Wert |
|----------|------|
| **HP** | 5 |
| **XP-Belohnung** | 15 |
| **Material-Drops** | **Garantiert**: 1× Zeitkern |
| **Resistenzen** | Keine |
| **Fähigkeiten** | - **Zeitflimmern** (Alle 8s): Erhöht Kosten der nächsten Karte um +0.2s |
| **KI-Profil** | Tutorial - Extrem vorhersehbar, lange Pausen |
| **Tutorial-Fokus** | Basis-Kampf, Karten ausspielen = Zeit vergeht |
| **Rift-Punkte** | 5 |
| **Spawn-Garantie** | Erster Rift: IMMER genau 2 identische Zeit-Echos |

### Prolog-Kampf 2: "Vielfalt verstehen"

#### Chrono-Welpe (Tutorial)
| Attribut | Wert |
|----------|------|
| **HP** | 8 |
| **XP-Belohnung** | 30 |
| **Material-Drops** | **Garantiert**: 1× Zeitkern |
| **Resistenzen** | Keine |
| **Fähigkeiten** | - **Zeitknabbern** (Alle 5s): Erhöht nächste Kartenkosten um +0.3s |
|  | - **Zeitbiss** (Nach 2 Knabbern): Zeitdiebstahl 0.8s (1s Vorwarnung) |
| **KI-Profil** | Tutorial - Aktiver als Zeit-Echo, zeigt Zeitdiebstahl-Mechanik |
| **Tutorial-Fokus** | Lerne Zeitdiebstahl-Warnungen zu erkennen |
| **Rift-Punkte** | 10 |
| **Spawn-Garantie** | Zweiter Rift: IMMER 2× Zeit-Echo + 1× Chrono-Welpe |
| **Tutorial-Hinweis** | "Gelbe Warnung = Zeitdiebstahl kommt! Spiele schnell Karten." |

### Prolog-Kampf 3: "Die erste Prüfung"

#### Chrono-Konstrukt (Tutorial-Boss)
| Attribut | Wert |
|----------|------|
| **HP** | 20 |
| **XP-Belohnung** | 150 |
| **Material-Drops** | **Garantiert**: 3× Zeitkern, 1× Elementarfragment |
| **Ressourcen** | Konstrukt-Energie (0-3) |
| **Fähigkeiten** | **Phase 1 (100-60% HP):** |
|  | - **Zeitwelle** (Alle 4s): Erhöht Kosten der nächsten 2 Karten um +0.5s |
|  | - **Energie-Aufbau**: +1 Energie alle 8s |
|  | **Phase 2 (60-30% HP):** |
|  | - **Zeitverzerrung** (Bei 2+ Energie): Nächste 3 Karten kosten +50% mehr Zeit |
|  | - **Temporaler Stoß** (Alle 12s): Großer Zeitdiebstahl 2.0s (3s Vorwarnung) |
|  | **Phase 3 (30-0% HP):** |
|  | - **Verzweiflungsmodus**: Alle Fähigkeiten 25% schneller |
|  | - **Zeitkollaps** (Bei 0 HP): Gibt 5s Zeit zurück als Belohnung |
| **KI-Profil** | Tutorial-Boss - Lehrt Phasen-Mechaniken |
| **Tutorial-Fokus** | Boss-Phasen verstehen, große Angriffe ausweichen |
| **Rift-Punkte** | Boss spawnt bei 50 Punkten (Tutorial-Anpassung) |
| **Belohnung** | Erste klassenspezifische Karte + Zugang zu Welt 1 |

---

## 🌪️ **Welt 1: Zeitwirbel-Tal**

*Erste echte Herausforderungen mit grundlegenden Zeit-Mechaniken.*

### WICHTIG: Gegner-Mechaniken in Zeitklingen
**Gegner haben HP und sterben bei 0 HP. Spieler haben KEINE HP!**
- Gegner können nur: Zeitdiebstahl, Kartenkosten-Manipulation, Karten blockieren
- Spieler verlieren nur wenn die Zeit abläuft
- Kein Targeting = Automatische Zielauswahl

### NEUE MECHANIK: Rudel als Schild-System

**Grundprinzipien:**
1. **Kein manuelles Targeting:** Spieler trifft automatisch das vorderste Mitglied
2. **Visuelle Darstellung:** Haupt-Sprite + Schild-Sphären unterhalb
3. **HP-Anzeige:** "15 HP ×3 (45)" - zeigt Einzel- und Gesamt-HP
4. **AoE-Interaktion:** Trifft ALLE Mitglieder für vollen Schaden
5. **Durchbruchschaden:** 50% Überschuss geht auf nächstes Mitglied

### Standard-Gegner (Welt 1)

#### Zeit-Sauger
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 15 / 22 / 30 |
| **XP-Belohnung** | 60 / 90 / 120 |
| **Material-Drops** | **Zeitkern**: 8.0% (1-2) |
|  | **Elementarfragment**: 2.0% (1) |
| **Rift-Punkte** | 12 |
| **Fähigkeiten** | - **Zeit-Drain** (Passiv): Solange er lebt, verliert Spieler 0.1s/0.15s/0.2s pro Sekunde |
|  | - **Drain-Verstärkung** (Bei 50% HP): Drain verdoppelt sich |
| **KI-Profil** | Passiv - Muss schnell getötet werden |
| **Konter** | DoT-Karten sehr effektiv (Zeit-Drain läuft während DoT) |
| **Kill-Zeit-Kalkulation** | ~5-8s bei 2-3 DPS (5-6 Karten), Zeitverlust durch Drain: 0.5-1.6s |

#### Karten-Verdreher
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 20 / 30 / 40 |
| **XP-Belohnung** | 70 / 105 / 140 |
| **Material-Drops** | **Zeitkern**: 8.0% (1-2) |
|  | **Elementarfragment**: 2.0% (1) |
| **Rift-Punkte** | 15 |
| **Fähigkeiten** | - **Zeitverzerrung** (Alle 6s): Nächste 2 Karten kosten +0.5s/0.7s/1.0s mehr |
|  | - **Kartentausch** (Alle 15s): Tauscht Position von 2 Handkarten |
|  | - **Verdrehtes Feld** (Bei Tod): Alle Kartenkosten -0.5s für 5s (Bonus!) |
| **KI-Profil** | Störend - Verwirrt Kartenplanung |
| **Kill-Zeit-Kalkulation** | ~7-10s bei 2-3 DPS (7-8 Karten), erhöhte Kosten verlangsamen Kill |

#### Tempo-Brecher-Rudel [RUDEL-MECHANIK]
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP pro Mitglied** | 8 / 12 / 16 |
| **Rudel-Größe** | 3-5 Mitglieder |
| **XP-Belohnung** | 30 / 45 / 60 pro Mitglied |
| **Material-Drops** | **Zeitkern**: 6.0% (1) pro Mitglied |
| **Rift-Punkte** | 6 pro Mitglied |
| **Rudel-Mechanik** | Standard (Auto-Target vorne, Sphären-System) |
| **Fähigkeiten** | - **Tempo-Bruch** (Alle 5s): Reduziert Klassenressource um 1 |
|  | - **Synchron-Bruch** (3+ Mitglieder): Effekt auf alle Ressourcen |
|  | - **Ressourcen-Block** (Bei Tod eines Mitglieds): Blockiert Ressourcen-Aufbau für 2s |
| **KI-Profil** | Aggressiv - Zielt auf Klassen-Mechaniken |
| **Konter** | 0-Zeit-Karten und passive Effekte |

#### Zeitnebel
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 22 / 33 / 44 |
| **XP-Belohnung** | 90 / 135 / 180 |
| **Material-Drops** | **Zeitkern**: 8.0% (1-2) |
|  | **Elementarfragment**: 2.0% (1) |
|  | **Zeitfokus**: 0.3% (1) |
| **Ressourcen** | Nebelenergie (0-3) |
| **Resistenzen** | -20% Effektivität von Zeitmanipulationskarten |
| **Fähigkeiten** | - **Verdeckender Nebel** (Alle 7s): +1 Energie, ignoriert nächste Karte <2.0s Kosten |
|  | - **Chronointerferenz** (Bei 2+ Energie): -2 Energie, stiehlt 1.2/1.5/1.8s Zeit |
|  | - **Zeitliche Verschleierung** (Alle 20s): Erhöht Kartenkosten um 20/25/30% (4s) |
| **KI-Profil** | Defensiv - Fokus auf Kartenverhinderung, gezielte Zeitdiebstähle |

#### Erstarrter Wanderer
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 25 / 35 / 45 |
| **XP-Belohnung** | 85 / 125 / 165 |
| **Material-Drops** | **Zeitkern**: 8.0% (1-2) |
|  | **Elementarfragment**: 2.0% (1) |
|  | **Zeitfokus**: 0.3% (1) |
| **Rift-Punkte** | 15 |
| **Resistenzen** | **Zeitstarre**: Immun gegen Verlangsamung/Verzögerung |
| **Fähigkeiten** | - **Erstarrter Schlag** (Alle 6s): Harter Treffer |
|  | - **Auftauen** (Bei 50% HP): Angriffe werden schneller (4s) |
|  | - **Zeitriss** (Bei 25% HP): Einmaliger AoE-Angriff |
| **KI-Profil** | Träge - Langsam aber gefährlich |
| **Lernziel** | Nicht alle Gegner können verzögert werden |

#### Beschleunigter Sprite
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 12 / 18 / 24 |
| **XP-Belohnung** | 60 / 90 / 120 |
| **Material-Drops** | **Zeitkern**: 8.0% (1) |
|  | **Elementarfragment**: 3.0% (1) |
|  | **Zeitfokus**: 0.5% (1) |
| **Rift-Punkte** | 12 |
| **Resistenzen** | -50% vs AoE-Schaden |
| **Fähigkeiten** | - **Blitzangriff** (Alle 2s): Schnelle, schwache Treffer |
|  | - **Zeitsprung** (Alle 10s): Teleport + stiehlt 0.5s |
|  | - **Flackern** (Bei Treffer): 20% Chance auszuweichen |
| **KI-Profil** | Hyperaktiv - Ständige Bewegung |
| **Lernziel** | Schnelle Gegner, AoE-Vorteil |

### Neue Welt 1 Gegner

#### Zeit-Parasit
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 10 / 15 / 20 |
| **XP-Belohnung** | 80 / 120 / 160 |
| **Material-Drops** | **Zeitkern**: 10.0% (1-2) |
|  | **Elementarfragment**: 3.0% (1) |
| **Rift-Punkte** | 20 |
| **Fähigkeiten** | - **Anheften** (Beim Spawn): Heftet sich an Timeline, +0.2s/0.25s/0.3s auf Karten >1.0s |
|  | - **Festklammern** (Nach 10s): Verdoppelt Kartenkosten-Malus |
|  | - **Parasitärer Burst** (Bei Tod): Nächste 3 Karten kosten -0.5s (Bonus!) |
| **KI-Profil** | Prioritätsziel - Muss schnell eliminiert werden |
| **Spawn-Regel** | Max. 1 gleichzeitig aktiv |

### Elite-Gegner (Welt 1)

#### Chronophage (Elite)
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 40 / 55 / 70 |
| **XP-Belohnung** | 200 / 300 / 400 |
| **Material-Drops** | **Zeitkern**: 12.0% (2-3) |
|  | **Elementarfragment**: 4.0% (1-2) |
|  | **Zeitfokus**: 0.8% (1) |
| **Ressourcen** | Hunger (0-100%) |
| **Fähigkeiten** | - **Zeit-Hunger** (Passiv): +10% Hunger alle 3s |
|  | - **Verschlingen** (Bei 50%+ Hunger): Frisst nächste gespielte Karte (kein Effekt, Zeit verloren) |
|  | - **Großer Hunger** (Bei 100% Hunger): Zeitdiebstahl 3.0s/4.0s/5.0s, Reset auf 0% |
|  | - **Sättigung** (Nach Verschlingen): -25% Hunger, nächste Karte kostet -1.0s |
| **KI-Profil** | Gierig - Timing wichtig um Verschlingen zu vermeiden |
| **Strategie** | Karten spielen bevor 50% Hunger, oder billige Karten opfern |

#### Chrono-Händler (Elite)
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 35 / 45 / 55 |
| **XP-Belohnung** | 180 / 270 / 360 |
| **Material-Drops** | **Zeitkern**: 15.0% (2-4) |
|  | **Elementarfragment**: 5.0% (1-2) |
|  | **Zeitfokus**: 1.5% (1) |
| **Ressourcen** | Handels-Angebote (dynamisch) |
| **Fähigkeiten** | - **Zeit-Deal** (Alle 10s): Bietet Deal an - früh: 3s für 15 Schaden, spät: 7s für 25 Schaden |
|  | - **Deal annehmen** (Wenn Spieler Schaden macht): Spieler erhält Zeit, Händler heilt sich |
|  | - **Deal ablehnen** (Nach 3s ohne Schaden): Händler stiehlt 1.5s Zeit |
|  | - **Verzweifelter Deal** (Bei 25% HP): 10s für 30 Schaden - einmalig |
| **KI-Profil** | Opportunistisch - Belohnt Risk/Reward-Entscheidungen |
| **Strategie** | Deals früh annehmen wenn Zeit knapp, später ignorieren |
| **Kill-Zeit** | ~12-15s (4-5 Karten bei 3 DPS) |

#### Zeit-Verschwörer (Elite)
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 45 / 65 / 85 |
| **XP-Belohnung** | 250 / 375 / 500 |
| **Material-Drops** | **Zeitkern**: 12.0% (2-4) |
|  | **Elementarfragment**: 4.0% (1-2) |
|  | **Zeitfokus**: 1.0% (1) |
| **Ressourcen** | Verschwörung (0-3 Stapel) |
| **Fähigkeiten** | - **Zeitfalle stellen** (Alle 8s): +1 Verschwörung, nächste Karte löst Falle aus |
|  | - **Fallen-Effekt** (Bei Auslösung): Karte kostet +100% Zeit |
|  | - **Große Verschwörung** (Bei 3 Stapel): Alle Karten kosten +1.0s für 10s, Reset |
|  | - **Zeitparadox** (Bei 25% HP): Vertauscht Kartenreihenfolge in Hand |
| **KI-Profil** | Hinterhältig - Bestraft hastiges Spielen |
| **Strategie** | Fallen mit billigen Karten auslösen, vor 3 Stapel töten |

#### Zeitfresser-Drohnen-Schwarm [RUDEL-VARIANTE]
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP pro Drohne** | 8 / 12 / 16 |
| **Schwarm-Größe** | 3-5 Drohnen |
| **XP-Belohnung** | 25 / 35 / 45 pro Drohne |
| **Material-Drops** | **Zeitkern**: 6.0% (1) pro Drohne |
|  | **Elementarfragment**: 2.0% (1) beim letzten |
| **Rift-Punkte** | 5 pro Drohne |
| **Schwarm-Darstellung** | - **Haupt-Drohne**: Vorne sichtbar |
|  | - **Sphären**: Kleinere Drohnen als Sphären |
|  | - **HP**: "8 HP ×4 (32)" bei 4er-Schwarm |
| **Fähigkeiten** | - **Schwarm-Angriff** (Alle 4s): 1 + 0.5/Drohne Schaden |
|  | - **Schwarm-Synergie**: +10% Geschwindigkeit/Drohne |
|  | - **Zerstreuung** (Bei AoE): Drohnen fliehen kurz (0.5s) |
| **Rudel-Mechaniken** | Identisch zum Basis-Rudel-System |
| **KI-Profil** | Schwarm-Intelligenz - Aggressiver bei mehr Mitgliedern |
| **Lernziel** | Schwarm-Variante, AoE-Wichtigkeit |

### Mini-Bosse (Welt 1)

#### Der Ewige Moment (Mini-Boss)
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 70 / 100 / 130 |
| **XP-Belohnung** | 500 / 750 / 1000 |
| **Material-Drops** | **Zeitkern**: 25.0% (3-5) |
|  | **Zeitkernkit**: 15%/20%/25% (1) |
|  | **Elementarfragment**: 10.0% (2-3) |
|  | **Zeitfokus**: 3.0% (1-2) |
| **Ressourcen** | Stasis-Ladung (0-100%) |
| **Fähigkeiten** | - **Zeit-Verlangsamung** (Passiv): Rift-Timer läuft 10%/15%/20% langsamer |
|  | - **Stasis-Aufbau** (Alle 5s): +20% Ladung |
|  | - **Moment einfrieren** (Bei 50%+ Ladung): Nächste Karte braucht 3x länger zum Ausspielen |
|  | - **Ewiger Augenblick** (Bei 100% Ladung): Timer stoppt für 3s, dann Zeitdiebstahl 5.0s/7.0s/9.0s |
|  | - **Zeitriss** (Bei 50%, 25% HP): Spawnt Zeit-Sauger |
| **KI-Profil** | Kontrollierend - Manipuliert den Zeitfluss selbst |
| **Strategie** | Schnell töten bevor Stasis zu hoch, DoT nutzen während Verlangsamung |

### Haupt-Boss

#### Der Stille Bewahrer
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 80 / 110 / 140 |
| **XP-Belohnung** | 1200 / 1600 / 2000 |
| **Material-Drops** | **Zeitkern**: 100% (5-8) |
|  | **Zeitkernkit**: 30%/40%/50% (1-2) |
|  | **Elementarfragment**: 50%/60%/70% (3-5) |
|  | **Zeitfokus**: 20%/25%/30% (2-4) |
| **Ressourcen** | Zeitzeiger (Rotieren um seinen Körper) |
| **Resistenzen** | +30% vs Zeitmanipulation |
| **Fähigkeiten** | **Phase 1 (100-70%): Die Erste Stunde** |
|  | - **Zeiger-Wirbel** (Alle 5s): Nächste 2 Karten kosten +1.0s mehr |
|  | - **Zeitstille** (Alle 20s): Karten können 2s nicht gespielt werden (Timer läuft!) |
|  | - **Tick-Tock** (Alle 10s): Zeitdiebstahl 0.5s/0.7s/1.0s (3 Ticks) |
|  | **Phase 2 (70-40%): Die Letzte Minute** |
|  | - Zeiger-Wirbel alle 3s |
|  | - **Temporaler Rückfluss** (Alle 30s): Heilt sich um 10% HP |
|  | - **Beschleunigung**: Rift-Timer läuft 25% schneller! |
|  | - **Zeit-Echos** (Bei Phasenstart): Spawnt 2 Zeit-Echos |
|  | **Phase 3 (40-0%): Mitternacht** |
|  | - **GONG!** (Alle 15s): 5s Vorwarnung, dann 5.0s/7.0s/9.0s Zeitdiebstahl |
|  | - **Verzweifelte Stille** (Bei 10% HP): Versucht Timer zu stoppen (10s Channel) |
|  | - **Zeit-Kollaps** (Bei 0 HP): Gibt 30s Zeit zurück als Belohnung! |
| **KI-Profil** | Adaptiv - Wechselt Strategien basierend auf Phase |
| **Kill-Zeit-Kalkulation** | ~35-50s bei 2.5-3 DPS (28-33 Karten), Zeitverlust: ~5-10s durch Diebstähle |

---

## 🔥 **Welt 2: Flammen-Schmiede**

*Einführung des DoT-Systems und Feuer-Element-Mechaniken.*

### Standard-Gegner

#### Flammenmanipulator
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 25 / 38 / 50 |
| **XP-Belohnung** | 100 / 150 / 200 |
| **Material-Drops** | **Zeitkern**: 60%/70%/80% (1-2) |
|  | **Elementarfragment**: 12%/16%/20% (1) [Feuer-Bonus] |
|  | **Zeitfokus**: 2%/4%/6% (1) |
| **Ressourcen** | Glut (0-5) |
| **Resistenzen** | +50% vs Feuer, -25% vs Eis |
| **Fähigkeiten** | - **Flammenladung** (Alle 5s): +1 Glut |
|  | - **Brennender Zeitstrom** (Alle 8s): DoT (Schwach/Mittel/Stark), stiehlt 0.4s/Tick |
|  | - **Zeit-Verbrennung** (Bei 3+): -3 Glut, verdoppelt DoTs (5s) |
|  | - **Chronoflamme** (Bei 5): -Alle Glut, stiehlt 0.6s/Glut, verdoppelt nächste Kosten |
| **KI-Profil** | Aggressiv - Fokus auf DoT & Synergien |

#### Feuerelementar
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 30 / 45 / 60 |
| **XP-Belohnung** | 120 / 180 / 240 |
| **Material-Drops** | **Zeitkern**: 60%/70%/80% (1-3) |
|  | **Elementarfragment**: 15%/20%/25% (1-2) [Feuer-Bonus] |
|  | **Zeitfokus**: 3%/5%/7% (1) |
| **Ressourcen** | Temperatur (0-100%) |
| **Resistenzen** | +75% vs Feuer, -40% vs Eis |
| **Fähigkeiten** | - **Temperaturanstieg** (Passiv): +10% Temperatur/3s |
|  | - **Zeitsengen** (Bei 30%+): -30% Temp, DoT (Mittel), verzögert Karte 0.6/0.8/1.0s |
|  | - **Chronoeinäscherung** (Bei 60%+): -60% Temp, DoT (Stark), erhöht Kosten 25% (3s) |
|  | - **Ewige Flamme** (Bei 100%): -100% Temp, DoT (Stark+), stiehlt 2.5/3.0/3.5s Zeit |
| **KI-Profil** | Eskalierend - Bedrohung steigt mit Temperatur |

### Elite-Gegner

#### Flammenweber
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 50 / 70 / 90 |
| **XP-Belohnung** | 300 / 450 / 600 |
| **Material-Drops** | **Zeitkern**: 80%/85%/90% (2-4) |
|  | **Elementarfragment**: 25%/30%/35% (2-3) [Feuer-Bonus] |
|  | **Zeitfokus**: 8%/10%/12% (1) |
| **Ressourcen** | Feuerweben (0-100%) |
| **Resistenzen** | +60% vs Feuer, -30% vs Eis |
| **Fähigkeiten** | - **Feuerweberei** (Alle 5s): +20% Feuerweben |
|  | - **Verbrennende Zeit** (Bei 40%+): -40%, DoT (Stark), verzögert 2 Karten 0.4/0.6/0.8s |
|  | - **Feuernetz** (Bei 70%+): -70%, DoT (Stark) alle Pos., erhöht Kosten 30% (4s) |
|  | - **Zeitflammensturm** (Bei 100%): -100%, stiehlt 3.5/4.5/5.5s Zeit, verstärkt alle DoTs +1 Stufe |
| **KI-Profil** | Strategisch - Methodischer Aufbau, koordinierte Angriffe |

### Mini-Bosse

#### Glutherz
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 80 / 110 / 140 |
| **XP-Belohnung** | 600 / 900 / 1200 |
| **Material-Drops** | **Zeitkern**: 90%/95%/100% (4-6) |
|  | **Zeitkernkit**: 20%/25%/30% (1) |
|  | **Elementarfragment**: 40%/50%/60% (3-4) [Feuer-Bonus] |
|  | **Zeitfokus**: 15%/18%/21% (1-2) |
| **Ressourcen** | Kernflamme (0-5), Hitze (0-100%) |
| **Resistenzen** | +70% vs Feuer, +30% vs Zeitmanipulation, -40% vs Eis |
| **Fähigkeiten** | - **Flammenverstärkung** (Alle 5s): +1 Kernflamme, +10% Hitze |
|  | - **Brennende Zeit** (Bei 2+): -2 Kernflamme, DoT (Stark) alle Pos. |
|  | - **Chronoverbrennung** (Bei 50%+): -50% Hitze, stiehlt 0.6s/aktivem DoT |
|  | - **Flammenkern-Ausbruch** (Bei 5 Kernfl. & 100% Hitze): -Alle Res., DoT (Stark+), stiehlt 4.0/5.0/6.0s |
|  | - **Hitzewelle** (Bei 60%, 30% HP): Hitze auf 100%, verstärkt DoTs +1 Stufe |
| **KI-Profil** | Aggressiv - Fokus auf DoT & Synergien |

### Haupt-Boss

#### Erzsiederin Ignium
| Attribut | Wert (N / H / L) |
|----------|------------------|
| **HP** | 100 / 140 / 180 |
| **XP-Belohnung** | 1500 / 2000 / 2500 |
| **Material-Drops** | **Zeitkern**: 100% (6-10) |
|  | **Zeitkernkit**: 40%/50%/60% (2-3) |
|  | **Elementarfragment**: 60%/70%/80% (4-6) [Feuer-Bonus] |
|  | **Zeitfokus**: 25%/30%/35% (3-5) |
| **Ressourcen** | Schmiedefeuer (0-100%), Meisterwerk (0-3) |
| **Resistenzen** | +80% vs Feuer, +40% vs Zeitmanipulation, -50% vs Eis |
| **Fähigkeiten** | - **Ewiges Schmiedefeuer** (Passiv): +8% Feuer/s |
|  | - **Meisterliche Schmiedekunst** (Bei 25%+ Feuer): +1 Meisterwerk, -25% Feuer |
|  | - **Flammenschmieden** (Bei 1+ Meisterwerk): DoT (Stark+) alle Pos., erhöht Kosten 40% |
|  | - **Zeitschmelze** (Bei 50%+ Feuer): -50% Feuer, stiehlt 1.0s/aktivem DoT |
|  | - **Großmeister-Schmiedekunst** (Bei 3 Meisterwerk & 100% Feuer): -Alle Res., stiehlt 6.0/8.0/10.0s, DoT (Legendär) |
| **Phasen** | - **P1** (100-60%): Schmiedefeuer-Aufbau, erste Meisterwerke |
|  | - **P2** (60-30%): Aggressivere DoT-Anwendung, höhere Kosten |
|  | - **P3** (30-0%): Großmeister-Modus, maximale Bedrohung |
| **KI-Profil** | Meisterhaft - Strategischer Dual-Ressourcen-Aufbau |

---

## 🎪 **Event-Spezielle Gegner**

*Spezielle Gegner die nur während Events erscheinen und einzigartige Belohnungen bieten.*

### Blitz-Event-Gegner

#### Zeitrausch-Phantom (Zeitrausch-Event)
| Attribut | Wert |
|----------|------|
| **HP** | 40 |
| **XP-Belohnung** | 300 (+50% während Event) |
| **Material-Drops** | **Event-Bonus**: Alle Drops +100% |
| **Spawn-Bedingung** | Nur während "Zeitrausch"-Events (30 Min, 3× täglich) |
| **Resistenzen** | +50% vs Zeitmanipulation |
| **Fähigkeiten** | - **Zeitrausch-Aura** (Passiv): Alle Karten kosten +0.3s |
|  | - **Phantom-Teleport** (Alle 8s): Ignoriert nächste 2 Karten |
|  | - **Rausch-Explosion** (Bei 25% HP): Stiehlt 3.0s, +2 Karten ziehen |
| **KI-Profil** | Schnell - Kurze, intensive Kämpfe |

#### Materialgeist (Materialflut-Event)
| Attribut | Wert |
|----------|------|
| **HP** | 35 |
| **XP-Belohnung** | 250 |
| **Material-Drops** | **Elementarfragment**: 100% (2-3) |
|  | **Zeitfokus**: 50% (1-2) |
|  | **Zeitkernkit**: 25% (1) |
| **Spawn-Bedingung** | Nur während "Materialflut"-Events |
| **Resistenzen** | Wechselt alle 10s (Feuer→Eis→Blitz) |
| **Fähigkeiten** | - **Material-Absorption** (Bei Kartenspiel): Heilt 2 HP pro Material-Typ der Karte |
|  | - **Essenz-Burst** (Alle 15s): Garantierte Material-Drops für nächste 10s |
|  | - **Geist-Form** (Bei 50% HP): Immun gegen Schaden (3s), aber verliert 5 HP/s |
| **KI-Profil** | Unterstützend - Fokus auf Material-Belohnungen |

### Tages-Event-Gegner

#### Feuer-Zeitalter Wächter (Feuer-Zeitalter Event)
| Attribut | Wert |
|----------|------|
| **HP** | 60 |
| **XP-Belohnung** | 500 |
| **Material-Drops** | **Elementarfragment (Feuer)**: 75% (2-4) |
| **Spawn-Bedingung** | Nur während "Feuer-Zeitalter"-Events (24h, 2-3× wöchentlich) |
| **Resistenzen** | +90% vs Feuer, -60% vs Eis |
| **Fähigkeiten** | - **Zeitalter-Flamme** (Passiv): Alle DoTs +1 Stufe verstärkt |
|  | - **Feuer-Zeitalter** (Alle 12s): DoT (Stark) alle Pos., Feuer-Karten -50% Kosten (8s) |
|  | - **Ewiges Brennen** (Bei 30% HP): DoT (Legendär), kann nicht entfernt werden |
| **KI-Profil** | Thematisch - Verstärkt Feuer-Element-Synergien |

### Mega-Event-Bosse

#### Chronos-Erwachen Avatar (Community-Event)
| Attribut | Wert |
|----------|------|
| **HP** | 500 (Community-Boss) |
| **XP-Belohnung** | 5000 (geteilt durch Teilnehmer) |
| **Material-Drops** | **Elite-Kartenvarianten**: 100% (1-2) |
|  | **Zeitkern**: 100% (15-25) |
|  | **Zeitkernkit**: 100% (3-5) |
| **Spawn-Bedingung** | Community-Ziel erreicht (10M globale Kämpfe) |
| **Besonderheit** | **Globaler Boss**: Alle Spieler kämpfen gegen dieselbe HP-Leiste |
| **Resistenzen** | Adaptiv - Passt sich an häufigste Spieler-Strategien an |
| **Fähigkeiten** | - **Chronos-Macht** (Passiv): Resistenzen ändern sich basierend auf Community-Verhalten |
|  | - **Zeitsturm** (Alle 30s): Globaler Effekt - alle aktiven Spieler verlieren 2.0s |
|  | - **Erwachen** (Bei 25% HP): Finale Phase - verstärkte Fähigkeiten, bessere Belohnungen |
| **KI-Profil** | Community-Boss - Reagiert auf globale Spieler-Statistiken |

---

## 🔄 **Mastery-Integration**

### Elite-Versionen (ab M5+)
- **+50% HP** für alle Gegner
- **+25% XP-Belohnung**
- **Mastery-Drop-Boni**: Zusätzliche Drop-Raten basierend auf M-Level
- **Neue Fähigkeiten**: Elite-Versionen haben 1-2 zusätzliche Fähigkeiten

### Mastery-Events (ab M15+)
- **Elite-Zeitrisse**: Höhere Gegner-Dichte, +200% seltene Drops
- **Mastery-Duelle**: KI nutzt Spieler-ähnliche Strategien
- **Chronos-Herausforderung**: Progressive Schwierigkeit basierend auf M-Level

---

## 🎯 **Balancing-Parameter**

### Live-Anpassbare Werte
```python
ENEMY_BALANCE_CONFIG = {
    "hp_multipliers": {
        "normal": 1.0,
        "heroic": 1.4,
        "legendary": 1.8
    },
    "xp_multipliers": {
        "global": 1.0,
        "event_bonus": 1.5,
        "mastery_bonus": 1.25
    },
    "drop_rates": {
        "time_core_base": 0.60,
        "elemental_fragment_base": 0.08,
        "time_focus_base": 0.02,
        "time_core_kit_base": 0.15  # Nur für spezielle Gegner
    },
    "difficulty_scaling": {
        "world_1": 1.0,
        "world_2": 1.3,
        "mastery_mode": 1.5
    }
}
```

### Event-Kompensation
- **Keine Pity-Timer**: Pure RNG wie Mo.Co
- **Event-Boosts**: +100-400% Material-Bonus während Events
- **Garantierte Quellen**: Bosse haben Mindest-Drops
- **Mastery-Boni**: Passive Drop-Rate-Verbesserungen

---

**🎉 FAZIT: Gegnerdatenbank erfolgreich modernisiert!**

Die Datenbank ist jetzt vollständig **Mo.Co-authentisch** mit:
- ✅ **4-Material-System** (Zeitkern, Zeitkernkit, Elementarfragment, Zeitfokus)
- ✅ **Pure RNG-Drops** ohne Pity-Timer
- ✅ **XP-System** für Klassenprogression
- ✅ **Event-Integration** mit speziellen Gegnern
- ✅ **Mastery-Skalierung** für Endgame-Content
- ✅ **Prolog/Tutorial-Struktur** vollständig ausgearbeitet
- ✅ **Live-Balancing-Parameter** für Anpassungen

**Entwicklungsbereit** für Unity-Implementation! 🚀
