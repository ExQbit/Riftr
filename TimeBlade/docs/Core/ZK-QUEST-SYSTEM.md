# Zeitklingen: Zentrales Quest-System

## 🎯 **Quest-System Übersicht**

**Zweck**: Zentrale Verwaltung aller Quests, XP-Verteilung und Belohnungsstrukturen für alle drei Klassen (Zeitwächter, Chronomant, Schattenschreiter).

**10.000 XP Cap**: Alle Bonus-XP-Quests sind auf maximal 10.000 XP begrenzt.

---

## 📚 **Quest-Kategorien & ID-System**

### **Quest-ID Format:**
- **P-Q##**: Prolog-Quests (P-Q01, P-Q02, P-Q03)
- **W#-C#-Q##**: Welt-Kapitel-Quests (W1-C1-Q01 = Welt 1, Kapitel 1, Quest 1)
- **W#-DQ-##**: Dungeon-Quests (W1-DQ-01 = Welt 1, Dungeon-Quest 1)
- **W#-BQ-##**: Boss-Quests (W1-BQ-01 = Welt 1, Boss-Quest 1)
- **DQ-##**: Tägliche Quests (DQ-01, DQ-02, etc.)
- **WQ-##**: Wöchentliche Quests (WQ-01, WQ-02, etc.)
- **PQ-##**: Projekte (PQ-01, PQ-02, etc.)
- **BXQ-##**: Bonus-XP-Quests (BXQ-01, BXQ-02, etc.)

---

## 🎓 **PROLOG-QUESTS**

### **P-Q01: "Erste Reflexe"**
- **Quest-Typ**: Tutorial-Quest
- **Titel**: "Erste Reflexe"
- **Ziele**: Besiege 1× Zeitschatten (Tutorial-Gegner)
- **Basis-XP**: 25 XP (fester Wert)
- **XP-Skalierung**: Keine (Tutorial)
- **Primäre Belohnungen**: Keine (Tutorial-Fortschritt)
- **Freischalt-Bedingung**: Spielstart

### **P-Q02: "Schildmacht erwecken"**
- **Quest-Typ**: Tutorial-Quest
- **Titel**: "Schildmacht erwecken"  
- **Ziele**: Besiege 1× Zeitwirbel-Sprössling mit Schildmacht-Demo
- **Basis-XP**: 50 XP (fester Wert)
- **XP-Skalierung**: Keine (Tutorial)
- **Primäre Belohnungen**: Keine (Tutorial-Fortschritt)
- **Freischalt-Bedingung**: Nach P-Q01

### **P-Q03: "Schildbruch-Macht"**
- **Quest-Typ**: Tutorial-Quest
- **Titel**: "Schildbruch-Macht"
- **Ziele**: Besiege 1× Anfänger-Zeitschleifer mit Schildbruch-Demo
- **Basis-XP**: 100 XP (fester Wert)
- **XP-Skalierung**: Keine (Tutorial)
- **Primäre Belohnungen**: 5× Zeitkern, 2× Elementarfragment, neue Karte: Schildschlag
- **Freischalt-Bedingung**: Nach P-Q02

---

## 🌪️ **WELT 1 QUESTS**

### **Kapitel 1 Quests**

#### **W1-C1-Q01: "Erkunde das Tal"**
- **Quest-Typ**: Hauptquest
- **Titel**: "Erkunde das Tal"
- **Ziele**: Besiege 8× Zeitschatten (realistisch für 60s-Begegnungen)
- **Basis-XP**: 400 XP
- **XP-Skalierung**: Basis-XP × 4.0 (XP-Boost Tier 1) = 1.600 XP
- **Primäre Belohnungen**: 3× Zeitkern
- **Freischalt-Bedingung**: Nach Prolog-Abschluss

#### **W1-C1-Q02: "Zeitschleifer-Problem"**
- **Quest-Typ**: Hauptquest
- **Titel**: "Zeitschleifer-Problem"
- **Ziele**: Besiege 6× Zeitschleifer (realistisch für mehrere 60s-Begegnungen)
- **Basis-XP**: 800 XP
- **XP-Skalierung**: Basis-XP × 4.0 = 3.200 XP
- **Primäre Belohnungen**: 4× Zeitkern, 1× Elementarfragment, neue Karte: Zeitfessel
- **Freischalt-Bedingung**: Nach W1-C1-Q01

#### **W1-C1-Q03: "Erste Herausforderung"**
- **Quest-Typ**: Hauptquest
- **Titel**: "Erste Herausforderung"
- **Ziele**: Besiege 1× Temporaler Wächter (Elite-Gegner)
- **Basis-XP**: 1.200 XP
- **XP-Skalierung**: Basis-XP × 4.0 = 4.800 XP
- **Primäre Belohnungen**: 6× Zeitkern, 2× Elementarfragment, neue Karte: Vorlauf
- **Freischalt-Bedingung**: Nach W1-C1-Q02

#### **W1-C1-BQ01: "Zeitwirbel-Kern"**
- **Quest-Typ**: Boss-Quest
- **Titel**: "Zeitwirbel-Kern"
- **Ziele**: Besiege 1× Tempus-Verschlinger (Mini-Boss)
- **Basis-XP**: 2.000 XP
- **XP-Skalierung**: Basis-XP × 4.0 = 8.000 XP
- **Primäre Belohnungen**: 12× Zeitkern, 4× Elementarfragment, 1× Zeitfokus, neue Karte: Zeitbarriere
- **Freischalt-Bedingung**: Nach W1-C1-Q03

### **Bonus-XP-Quest für Kapitel 1**

#### **BXQ-01: "Kapitel 1 Meisterschaft"**
- **Quest-Typ**: Bonus-Quest: Kapitel-Abschluss
- **Titel**: "Kapitel 1 Meisterschaft"
- **Ziele**: Komplettiere alle Kapitel 1 Quests
- **Basis-XP**: 10.000 XP (Cap erreicht)
- **XP-Skalierung**: Keine (fester Bonus)
- **Primäre Belohnungen**: Klassenbonus freigeschaltet
- **Freischalt-Bedingung**: Nach W1-C1-BQ01

---

## 📈 **TÄGLICHE QUESTS**

### **DQ-01: "Schildwall-Training"**
- **Quest-Typ**: Tagesquest
- **Titel**: "Schildwall-Training"
- **Ziele**: Verwende erfolgreiche Blocks 12×
- **Basis-XP**: 600 XP
- **XP-Skalierung**: Basis-XP × (1 + Spieler-Level × 0.05) × XP-Boost
- **Primäre Belohnungen**: 4× Zeitkern
- **Freischalt-Bedingung**: Level 5 erreicht
- **Reset**: Täglich um 00:00 UTC

### **DQ-02: "Zeitschleifer-Kontrolle"**
- **Quest-Typ**: Tagesquest
- **Titel**: "Zeitschleifer-Kontrolle"
- **Ziele**: Besiege 6× Zeitschleifer
- **Basis-XP**: 700 XP
- **XP-Skalierung**: Basis-XP × (1 + Spieler-Level × 0.05) × XP-Boost
- **Primäre Belohnungen**: 3× Zeitkern, 1× Elementarfragment
- **Freischalt-Bedingung**: Level 5 erreicht
- **Reset**: Täglich um 00:00 UTC

### **DQ-03: "Zeitnebel-Durchbruch"**
- **Quest-Typ**: Tagesquest
- **Titel**: "Zeitnebel-Durchbruch"
- **Ziele**: Besiege 4× Zeitnebel
- **Basis-XP**: 800 XP
- **XP-Skalierung**: Basis-XP × (1 + Spieler-Level × 0.05) × XP-Boost
- **Primäre Belohnungen**: 3× Zeitkern
- **Freischalt-Bedingung**: Level 5 erreicht
- **Reset**: Täglich um 00:00 UTC
- **Bonus**: 1× Zeitkernkit bei Abschluss aller 3 Tagesquests

---

## 📅 **WÖCHENTLICHE QUESTS**

### **WQ-01: "Wächter-Meisterschaft"**
- **Quest-Typ**: Wochenquest
- **Titel**: "Wächter-Meisterschaft"
- **Ziele**: Erreiche 25× Schildbruch-Aktivierungen
- **Basis-XP**: 5.000 XP
- **XP-Skalierung**: Basis-XP × (1 + Spieler-Level × 0.03)
- **Primäre Belohnungen**: 15× Zeitkern, 5× Elementarfragment, 1× Zeitfokus
- **Freischalt-Bedingung**: Level 5 erreicht
- **Reset**: Wöchentlich montags um 00:00 UTC

---

## 🏗️ **PROJEKTE**

### **PQ-01: "Zeitwirbel-Stabilisierung"**
- **Quest-Typ**: Projekt
- **Titel**: "Zeitwirbel-Stabilisierung"
- **Ziele**: Sammle 20× Zeitfragmente von Gegnern
- **Basis-XP**: 2.500 XP
- **XP-Skalierung**: Basis-XP × (1 + Spieler-Level × 0.04)
- **Primäre Belohnungen**: 8× Zeitkern, 2× Elementarfragment
- **Freischalt-Bedingung**: Level 5 erreicht
- **Wiederholbar**: Ja, alle 48h

### **PQ-02: "Defensive Meisterschaft"**
- **Quest-Typ**: Projekt
- **Titel**: "Defensive Meisterschaft"
- **Ziele**: Gewinne 8 Kämpfe ohne Zeitdiebstahl zu erleiden
- **Basis-XP**: 3.000 XP
- **XP-Skalierung**: Basis-XP × (1 + Spieler-Level × 0.04)
- **Primäre Belohnungen**: 10× Zeitkern, 1× Zeitfokus
- **Freischalt-Bedingung**: Level 5 erreicht
- **Wiederholbar**: Ja, alle 48h

---

## 🏰 **DUNGEON-QUESTS**

### **W1-DQ-01: "Eingangshalle"**
- **Quest-Typ**: Dungeon-Quest
- **Titel**: "Zeitkristall-Höhlen: Eingangshalle"
- **Ziele**: Komplettiere Dungeon-Stufe 1 (6× Zeitschleifer, 2× Zeitnebel, 1× Temporaler Wächter)
- **Basis-XP**: 3.500 XP
- **XP-Skalierung**: Basis-XP × XP-Boost (aktiver Tier)
- **Primäre Belohnungen**: 8× Zeitkern, 3× Elementarfragment
- **Freischalt-Bedingung**: Level 10 erreicht

### **BXQ-02: "Eingangshalle Meisterschaft"**
- **Quest-Typ**: Bonus-Quest: Dungeon-Abschluss
- **Titel**: "Eingangshalle Meisterschaft"
- **Ziele**: Erste Komplettierung von W1-DQ-01
- **Basis-XP**: 6.000 XP (unter 10.000 XP Cap)
- **XP-Skalierung**: Keine (fester Bonus)
- **Primäre Belohnungen**: Keine (nur XP-Bonus)
- **Freischalt-Bedingung**: Bei erster Komplettierung von W1-DQ-01

### **W1-DQ-02: "Kristall-Kammer"**
- **Quest-Typ**: Dungeon-Quest
- **Titel**: "Zeitkristall-Höhlen: Kristall-Kammer"
- **Ziele**: Komplettiere Dungeon-Stufe 2 (4× Zeitnebel, 3× Temporaler Wächter, 1× Chrono-Former)
- **Basis-XP**: 5.000 XP
- **XP-Skalierung**: Basis-XP × XP-Boost (aktiver Tier)
- **Primäre Belohnungen**: 12× Zeitkern, 4× Elementarfragment, 1× Zeitfokus
- **Freischalt-Bedingung**: Nach W1-DQ-01

### **BXQ-03: "Kristall-Kammer Meisterschaft"**
- **Quest-Typ**: Bonus-Quest: Dungeon-Abschluss
- **Titel**: "Kristall-Kammer Meisterschaft"
- **Ziele**: Erste Komplettierung von W1-DQ-02
- **Basis-XP**: 8.000 XP (unter 10.000 XP Cap)
- **XP-Skalierung**: Keine (fester Bonus)
- **Primäre Belohnungen**: Keine (nur XP-Bonus)
- **Freischalt-Bedingung**: Bei erster Komplettierung von W1-DQ-02

### **W1-DQ-03: "Tiefe Gewölbe"**
- **Quest-Typ**: Dungeon-Quest
- **Titel**: "Zeitkristall-Höhlen: Tiefe Gewölbe"
- **Ziele**: Komplettiere Dungeon-Stufe 3 (2× Chrono-Former, 4× Temporaler Wächter, 8× Zeitnebel)
- **Basis-XP**: 6.500 XP
- **XP-Skalierung**: Basis-XP × XP-Boost (aktiver Tier)
- **Primäre Belohnungen**: 15× Zeitkern, 6× Elementarfragment, 2× Zeitfokus
- **Freischalt-Bedingung**: Nach W1-DQ-02

### **BXQ-04: "Tiefe Gewölbe Meisterschaft"**
- **Quest-Typ**: Bonus-Quest: Dungeon-Abschluss
- **Titel**: "Tiefe Gewölbe Meisterschaft"
- **Ziele**: Erste Komplettierung von W1-DQ-03
- **Basis-XP**: 10.000 XP (Cap erreicht)
- **XP-Skalierung**: Keine (fester Bonus)
- **Primäre Belohnungen**: Keine (nur XP-Bonus)
- **Freischalt-Bedingung**: Bei erster Komplettierung von W1-DQ-03

### **W1-DQ-04: "Kristall-Herz"**
- **Quest-Typ**: Dungeon-Quest
- **Titel**: "Zeitkristall-Höhlen: Kristall-Herz"
- **Ziele**: Komplettiere Dungeon-Stufe 4 (1× Tempus-Verschlinger, 6× Elite-Gegner-Mix)
- **Basis-XP**: 8.000 XP
- **XP-Skalierung**: Basis-XP × XP-Boost (aktiver Tier)
- **Primäre Belohnungen**: 20× Zeitkern, 8× Elementarfragment, 3× Zeitfokus, 1× Zeitkernkit
- **Freischalt-Bedingung**: Nach W1-DQ-03

### **BXQ-05: "Kristall-Herz Meisterschaft"**
- **Quest-Typ**: Bonus-Quest: Dungeon-Abschluss
- **Titel**: "Kristall-Herz Meisterschaft"
- **Ziele**: Erste Komplettierung von W1-DQ-04
- **Basis-XP**: 10.000 XP (Cap erreicht)
- **XP-Skalierung**: Keine (fester Bonus)
- **Primäre Belohnungen**: Keine (nur XP-Bonus)
- **Freischalt-Bedingung**: Bei erster Komplettierung von W1-DQ-04

### **W1-DQ-05: "Zeitkristall-Kern"**
- **Quest-Typ**: Dungeon-Quest
- **Titel**: "Zeitkristall-Höhlen: Zeitkristall-Kern"
- **Ziele**: Komplettiere Dungeon-Stufe 5 (2× Tempus-Verschlinger, 1× Proto-Nebelwandler)
- **Basis-XP**: 10.000 XP
- **XP-Skalierung**: Basis-XP × XP-Boost (aktiver Tier)
- **Primäre Belohnungen**: 25× Zeitkern, 12× Elementarfragment, 4× Zeitfokus, 2× Zeitkernkit
- **Freischalt-Bedingung**: Nach W1-DQ-04

### **BXQ-06: "Zeitkristall-Kern Meisterschaft"**
- **Quest-Typ**: Bonus-Quest: Dungeon-Abschluss
- **Titel**: "Zeitkristall-Kern Meisterschaft"
- **Ziele**: Erste Komplettierung von W1-DQ-05
- **Basis-XP**: 10.000 XP (Cap erreicht)
- **XP-Skalierung**: Keine (fester Bonus)
- **Primäre Belohnungen**: Neue Karte: Zeitparade
- **Freischalt-Bedingung**: Bei erster Komplettierung von W1-DQ-05

---

## 👑 **WELTBOSS-QUESTS**

### **W1-BQ-02: "Nebelproben"**
- **Quest-Typ**: Boss-Vorbereitung
- **Titel**: "Nebelproben"
- **Ziele**: Sammle 8× Nebelproben von Zeitnebel-Gegnern
- **Basis-XP**: 3.000 XP
- **XP-Skalierung**: Basis-XP × XP-Boost (aktiver Tier)
- **Primäre Belohnungen**: 10× Zeitkern, 4× Elementarfragment
- **Freischalt-Bedingung**: Level 15 erreicht

### **W1-BQ-03: "Nebel-Wächter"**
- **Quest-Typ**: Boss-Vorbereitung
- **Titel**: "Nebel-Wächter"
- **Ziele**: Besiege 3× Elite-Nebel-Wächter
- **Basis-XP**: 4.500 XP
- **XP-Skalierung**: Basis-XP × XP-Boost (aktiver Tier)
- **Primäre Belohnungen**: 15× Zeitkern, 6× Elementarfragment, 2× Zeitfokus
- **Freischalt-Bedingung**: Nach W1-BQ-02

### **W1-BQ-04: "Defensive Perfektion"**
- **Quest-Typ**: Boss-Vorbereitung
- **Titel**: "Defensive Perfektion"
- **Ziele**: Erreiche 15× perfekte Schildbruch-Sequenzen
- **Basis-XP**: 4.000 XP
- **XP-Skalierung**: Basis-XP × XP-Boost (aktiver Tier)
- **Primäre Belohnungen**: 12× Zeitkern, 5× Elementarfragment, 3× Zeitfokus
- **Freischalt-Bedingung**: Nach W1-BQ-03

### **W1-BQ-05: "Nebelwandler-Konfrontation"**
- **Quest-Typ**: Weltboss-Kampf
- **Titel**: "Nebelwandler-Konfrontation"
- **Ziele**: Besiege Nebelwandler (Weltboss)
- **Basis-XP**: 5.000 XP
- **XP-Skalierung**: Basis-XP × XP-Boost (aktiver Tier)
- **Primäre Belohnungen**: 35× Zeitkern, 18× Elementarfragment, 8× Zeitfokus, 3× Zeitkernkit, neue Karte: Zeitfestung
- **Freischalt-Bedingung**: Nach W1-BQ-04

### **BXQ-07: "Nebelwandler-Erstschlag"**
- **Quest-Typ**: Bonus-Quest: Weltboss-Sieg
- **Titel**: "Nebelwandler-Erstschlag"
- **Ziele**: Erste Niederlage des Nebelwandlers
- **Basis-XP**: 10.000 XP (Cap erreicht)
- **XP-Skalierung**: Keine (fester Bonus)
- **Primäre Belohnungen**: Prestige-Titel: "Nebelbrecher"
- **Freischalt-Bedingung**: Bei erster Komplettierung von W1-BQ-05

---

## 🎴 **KARTEN-FREISCHALTUNG DURCH QUESTS**

### **📚 Startkarten pro Klasse (verfügbar ab Level 1):**

#### **⚔️ Zeitwächter Startkarten:**
- **4× Schwertschlag** (2.5s, 5 Schaden) - Basis-Angriffskarte
- **4× Zeitblock** (2.5s, Block + 1 SM) - Defensive Grundlage

#### **🔮 Chronomant Startkarten:**
- **4× Arkanstrahl** (2.0s, 5 Schaden + 1 Arkanpuls) - Elementar-Basis
- **2× Verzögern** (2.0s, verzögert Gegnerangriff um 2s) - Zeitmanipulation
- **2× Beschleunigen** (2.5s, nächste 2 Karten reduzierte Kosten) - Tempo-Kontrolle

#### **🗡️ Schattenschreiter Startkarten:**
- **3× Schattendolch** (1.0s, 3 Schaden) - Schnelle Angriffe
- **3× Giftklinge** (1.5s, 2 Schaden + DoT) - DoT-Einführung
- **2× Schleier** (0.5s, nächster Angriff verfehlt + Schattensynergie) - Schattensynergie-Basis

---

### **🏆 Karten-Freischaltungsreihenfolge aller Klassen:**

#### **⚔️ Zeitwächter Karten-Progression:**

| Quest-ID | Level | Karte | Zeitkosten | Effekt | Freischaltung |
|----------|-------|-------|------------|--------|---------------|
| P-Q03 | 2 | Schildschlag | 2.5s | 5 Schaden + 15% Zeitdiebstahlschutz | Prolog-Abschluss |
| W1-C1-Q02 | 3 | Zeitfessel | 2.5s | +3s Gegnerverzögerung | Zeitschleifer-Problem gelöst |
| W1-C1-Q03 | 4 | Vorlauf | 3.0s | Nächste Verteidigungskarte -1.0s | Elite-Herausforderung |
| W1-C1-BQ01 | 5 | Zeitbarriere | 3.5s | -30% Zeitdiebstahl (5s) | Mini-Boss besiegt |
| BXQ-01 | 5 | Zeitkürass | 3.0s | Reflektiert 25% nächsten Zeitdiebstahl | Klassenbonus 1 |
| Level 10 | 10 | Wächterblick | 2.0s | +1.5s Zeitgewinn bei erfolgreichem Block | Klassenbonus 2 |
| BXQ-06 | 15 | Zeitparade | 4.0s | Reflektiert nächsten Zeitdiebstahl + 6 Schaden | Dungeon-Meisterschaft |
| W1-BQ-05 | 17 | Zeitfestung | 5.0s | +4s Zeit, 30% Zeitdiebstahlreduktion, +1 Karte | Weltboss besiegt |

#### **🔮 Chronomant Karten-Progression:**

| Quest-ID | Level | Karte | Zeitkosten | Effekt | Freischaltung |
|----------|-------|-------|------------|--------|---------------|
| P-Q03 | 2 | Chronowall | 2.0s | Blockiert nächsten Angriff, +1 extra Arkanpuls bei Block | Prolog-Abschluss |
| W1-C1-Q02 | 3 | Chrono-Ernte | 3.0s | +2s Zeit wenn Gegner in 5s stirbt, +1 Arkanpuls | Zeitschleifer-Problem |
| W1-C1-Q03 | 4 | Elementarfokus | 2.5s | Nächster Elementarzauber +25-45% Effektivität | Elite-Herausforderung |
| W1-C1-BQ01 | 5 | Arkanblick | 1.0s | Ziehe Karten basierend auf Arkanpuls-Level | Mini-Boss besiegt |
| BXQ-01 | 5 | Zeitbeben | 5.0s | +3s Zeit, 10 AoE-Schaden, +1 Karte, +1 Arkanpuls | Klassenbonus 1 |
| Level 10 | 10 | Arkane Intelligenz | 1.0s | Ziehe Karten basierend auf Arkanpuls, +1 Arkanpuls | Klassenbonus 2 |
| BXQ-06 | 15 | Zeitverzerrung | 4.0s | Verlangsamt Ziel 30% (3s), modifiziert Arkanschub | Dungeon-Meisterschaft |
| W1-BQ-05 | 17 | Chrono-Meisterschaft | 6.0s | Ultimative Zeitmanipulation, +5s Zeit, AoE-Effekte | Weltboss besiegt |

#### **🗡️ Schattenschreiter Karten-Progression:**

| Quest-ID | Level | Karte | Zeitkosten | Effekt | Freischaltung |
|----------|-------|-------|------------|--------|---------------|
| P-Q03 | 2 | Schattenform | 1.5s | Nächste 2 Angriffe verfehlen, +0.5s/vermiedenem Angriff | Prolog-Abschluss |
| W1-C1-Q02 | 3 | Zeitdiebstahl | 1.0s | Stiehlt 0.5s Zeit vom Gegner | Zeitschleifer-Problem |
| W1-C1-Q03 | 4 | Schattenschritt | 1.0s | +25% Effekte nächste, +15% übernächste Karte | Elite-Herausforderung |
| W1-C1-BQ01 | 5 | Temporaler Raub | 1.5s | Stiehlt 1s Zeit + 2 Schaden | Mini-Boss besiegt |
| BXQ-01 | 5 | Schattenkonzentration | 1.5s | +2 Momentum, bei 4+ Momentum: +1 Karte | Klassenbonus 1 |
| Level 10 | 10 | Zeitsprung | 3.0s | Stiehlt 1.5s Zeit, +2 Karten, modifiziert Momentum | Klassenbonus 2 |
| BXQ-06 | 15 | Schattensturm | 4.0s | 8 AoE-Schaden, +0.5s Zeit pro Treffer | Dungeon-Meisterschaft |
| W1-BQ-05 | 17 | Schatten-Suprematie | 5.0s | Ultimativer AoE + Momentum-Explosion | Weltboss besiegt |

---

## 📊 **XP-SKALIERUNG FORMELN**

### **Standard-Skalierung:**
```
Finale_XP = Basis_XP × (1 + Spieler_Level × 0.05) × XP_Boost_Multiplikator
```

### **XP-Boost-Multiplikatoren:**
- **Tier 1** (0-10k täglich XP): 4.0×
- **Tier 2** (10k-22.5k täglich XP): 3.0×
- **Tier 3** (22.5k-37.5k täglich XP): 2.0×
- **Tier 4** (37.5k+ täglich XP): 1.0×

### **Level-Skalierung für Quests:**
- **Tagesquests**: +5% pro Spieler-Level
- **Projekte**: +4% pro Spieler-Level
- **Wochenquests**: +3% pro Spieler-Level

### **Bonus-XP-Quests:**
- **Feste Werte**: Keine Skalierung, 10.000 XP Maximum
- **Einmalig**: Nur bei erster Komplettierung

---

## 🔄 **QUEST-WIEDERHOLBARKEIT**

### **Einmalige Quests:**
- Alle Hauptquests (W#-C#-Q##)
- Alle Boss-Quests (W#-BQ-##)
- Alle Bonus-XP-Quests (BXQ-##)

### **Wiederholbare Quests:**
- Tägliche Quests (DQ-##): Reset alle 24h
- Wöchentliche Quests (WQ-##): Reset alle 7 Tage
- Projekte (PQ-##): Reset alle 48h
- Dungeon-Quests (W#-DQ-##): Unbegrenzt wiederholbar in Grind-Zonen

---

## 📈 **BALANCING-PARAMETER**

### **Live-Anpassbare Werte:**
```python
QUEST_BALANCE_CONFIG = {
    "xp_multipliers": {
        "daily_quests": 1.0,
        "weekly_quests": 1.0,
        "projects": 1.0,
        "main_quests": 1.0
    },
    "material_multipliers": {
        "time_cores": 1.0,
        "elemental_fragments": 1.0,
        "time_focus": 1.0,
        "time_core_kits": 1.0
    },
    "bonus_xp_cap": 10000,
    "level_scaling_rates": {
        "daily": 0.05,
        "weekly": 0.03,
        "projects": 0.04
    }
}
```

### **XP-Tracking:**
- **Tägliche XP**: Reset um 00:00 UTC
- **XP-Boost-Tier**: Automatische Anpassung basierend auf täglicher XP
- **Quest-Fortschritt**: Persistent gespeichert
- **Wiederholungs-Timer**: Serverseitig verwaltet

---

**📝 FAZIT: Zentrales Quest-System implementiert**

✅ **10.000 XP Cap**: Alle Bonus-Quests begrenzt
✅ **Klare ID-Struktur**: Eindeutige Quest-Identifikation
✅ **Skalierbare XP**: Level-abhängige Belohnungen
✅ **Flexible Balancing**: Live-anpassbare Parameter
✅ **Quest-Kategorien**: Tutorial, Haupt, Neben, Täglich, Wöchentlich, Projekte, Bonus

**Entwicklungsbereit für Unity-Implementation!** 🚀
