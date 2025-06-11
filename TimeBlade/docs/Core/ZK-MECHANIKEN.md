# Zeitklingen: Zentrale Kampf- & Zeitmechaniken (KONSOLIDIERT v3.0)

## 🔥 **WICHTIGE ÄNDERUNGEN IN DIESER VERSION**

**Namensharmonisierung durchgeführt:**
- **Zeitraub** (Spieler): Stiehlt Zeit vom Gegner → klare Abgrenzung
- **Zeitdiebstahl** (Gegner): Stiehlt Zeit vom Spieler → etablierter Begriff beibehalten
- **Mobile-freundliche Namen**: Keine Bindestriche, kurze prägnante Begriffe
- **Klassenspezifische Mechaniken integriert**: Alle fehlenden Mechaniken aus Klassendokumenten hinzugefügt

---

## ⏰ **KERN-ZEITSYSTEM**

### 3-Minuten-Rift-System
- **Zeitlimit**: 180 Sekunden pro Rift
- **Natürliche Grenze**: 3-Minuten-Rift als einziges hartes Zeitlimit
- **Zeit als einzige Ressource**: SPIELER HABEN KEINE HP! Nur Zeit als Ressource
- **Rift-Punkte-System**: 
  - **Standard-Rifts**: 100 Punkte spawnen Rift-Boss
  - **Tutorial-Rifts**: Reduzierte Punktziele (10-50 Punkte)
  - **Quest-Ziele**: Übergeordnete Ziele (z.B. "300 Punkte gesamt") ändern NICHT das Boss-Spawn-Limit

### Opportunity Costs-System (NEUE BALANCE-PHILOSOPHIE)
| Zeitmanipulation | Kosten-Penalty | Schadens-Penalty | Begründung |
|------------------|----------------|------------------|------------|
| **Zeitraub 0,5s** | +0,5s | -10% Schaden | Sichtbare Trade-offs statt Caps |
| **Zeitraub 1,0s** | +0,5s | -20% Schaden | Proportionale Opportunity Costs |
| **Verzögerung 2,0s** | +0,5s | -15% Schaden | Mobile-freundliche 0,5s-Schritte |
| **Verzögerung 3,0s** | +0,5s | -25% Schaden | Klare strategische Entscheidungen |

### Zeitkosten-Berechnungssystem (MOBILE-OPTIMIERT)

#### Interne Berechnung
- **Präzision**: 0,01s genau für alle Berechnungen
- **Formel**: `final_internal_cost = round_to_0.01(base_card_cost * class_modifier * situational_modifiers)`
- **Klassenmodifikatoren**:
  - Chronomant: 
    - Bei 1+ Arkanpuls: Alle Karten -5% Zeitkosten
    - Bei 3+ Arkanpuls: Zeitmanipulation zusätzlich -10% (kumulativ -15%)
  - Zeitwächter: Verteidigungskarten -15% bei 2+ Schildmacht
  - Schattenschreiter: Schattenkarten -50% bei 3+ Momentum

#### Anzeige-System
- **Haupt-UI**: Gerundet auf nächste 0,5s für Mobile-Lesbarkeit
  - `displayed_ui_cost = normalize_to_0.5(final_internal_cost)`
  - Beispiel: 2,37s → 2,5s Anzeige
- **Detail-Ansicht**: Exakte interne Kosten sichtbar
  - `displayed_detail_cost = final_internal_cost`
  - Beispiel: "2,37s (gerundet: 2,5s)"
- **Touch-Hold**: 0,5s gedrückt halten zeigt präzise Werte

---

## 🎯 **ZEITMANIPULATION-MECHANIKEN**

### Spieler-Zeitmanipulation (Offensive)

#### Zeitraub (Opportunity Costs-Balance)
- **Definition**: Spieler stiehlt Zeit vom Gegner mit sichtbaren Trade-offs
- **Nutzer**: Primär Schattenschreiter (effizienteste Klasse), sekundär andere
- **Neue Balance**: 
  - Höhere Kartenkosten für Zeitraub-Effekte
  - Reduzierter Schaden bei Kombo-Karten
  - Keine Caps - nur Opportunity Costs
- **Beispiele**: "Temporaler Diebstahl" (1,5s Kosten für 0,5s Raub), "Chrono-Heist" (2,0s Kosten, 1,0s Raub + 1 Schaden)
- **Trade-off-Prinzip**: Zeit vs. Effizienz - bewusste strategische Entscheidung

#### Verzögerung (Opportunity Costs-Balance)
- **Definition**: Verschiebt Gegnerangriff mit sichtbaren Kosten-Trade-offs
- **Nutzer**: Alle Klassen (Chronomant spezialisiert)
- **Neue Balance**: +0,5s Kosten für Zeitkontroll-Effekte
- **Beispiele**: "Temporaler Aufschub" (2,5s Kosten für 2,0s Verzögerung), "Tempobindung" (3,0s für 3,0s Verzögerung)
- **Trade-off-Prinzip**: Längere Kartenzeit für taktische Kontrolle

#### Zeitverzerrung (Opportunity Costs-Balance)
- **Definition**: Verlangsamt Gegner-Timer mit proportionalen Kosten-Penalties
- **Nutzer**: Primär Chronomant
- **Neue Balance**: +0,5s Kosten pro 15% Verlangsamung
- **Beispiele**: "Chrono-Manipulation" (4,5s Kosten für 30% Verlangsamung)
- **Trade-off-Prinzip**: Mächtige Kontrolle kostet mehr Zeit

### Gegner-Zeitmanipulation (Defensive)

#### Zeitdiebstahl
- **Definition**: Gegner stiehlt Zeit vom Spieler-Timer
- **Nutzer**: Verschiedene Gegnertypen
- **Kategorien**:
  - **Schwach**: 0,5-1,0s (häufig, keine Vorwarnung)
  - **Mittel**: 1,0-2,0s (moderate Häufigkeit, 1s Vorwarnung)  
  - **Stark**: 2,0-3,0s (selten, 2s Vorwarnung)
  - **Kritisch**: 3,0-5,0s+ (Bosse, 3-5s Vorwarnung)
- **Maximum**: 27s pro Rift (15% des Zeitlimits)

#### Verfehlen
- **Definition**: Angriff trifft nicht, Timer läuft normal weiter
- **Nutzer**: Spezielle Gegner, Mechanik-Konter
- **Effekte**: Karte wird "verschwendet", Zeit geht verloren
- **Präventionen**: Schattenschreiter-Schleier, spezielle Karten

---

## 🗡️ **SCHADEN-MECHANIKEN**

### Basis-Schaden-Systeme

#### Direktschaden
- **Definition**: Sofortiger Schaden ohne zusätzliche Effekte
- **Alle Klassen**: Standardmechanik für die meisten Karten
- **Skalierung**: 1-15 Schaden je nach Karte und Evolution

#### Durchbruchschaden (Reaktiviert)
- **Definition**: Überschussschaden bei Rudel-Mitglied-Tod geht zu 50% auf nächstes Mitglied über
- **Automatisch**: Gilt für alle Einzelziel-Angriffe gegen Rudel
- **Beispiel**: 8 Schaden gegen 2-HP-Ziel → 2 verbraucht, 3 Überschuss-Schaden (50% von 6) auf nächstes Mitglied
- **Balance**: Belohnt starke Einzelangriffe ohne AoE zu entwerten

#### Kettenschaden
- **Definition**: Schaden springt sequenziell auf weitere Ziele mit abnehmendem Schaden
- **Schaden-Reduktion**: 1. Kette 60%, 2. Kette 40%, 3. Kette 20%
- **Begrenzt**: Fest definierte Anzahl zusätzlicher Ziele pro Karte
- **Nutzer**: Spezifische Karten mit "trifft X weitere Ziele"-Effekt
- **Sequenziell**: Trifft Ziele nacheinander, nicht gleichzeitig

#### AoE (Area of Effect)
- **Definition**: Flächenschaden trifft ALLE Ziele gleichzeitig für vollen Schaden
- **Rudel-Wirkung**: Trifft alle Rudel-Mitglieder auf allen Ebenen
- **Höchste Effizienz**: Gegen Rudel deutlich effektiver als Einzelziel
- **Beispiele**: "Zeitbeben" (10 AoE), "Schattensturm" (8 AoE)

### Erweiterte Schaden-Systeme

#### DoT (Damage over Time)
- **Definition**: Schaden über Zeit in regelmäßigen Intervallen ("Ticks")
- **Kategorien**:
  - **Schwach**: 1 Schaden/Tick, +0,5s Zeitgewinn
  - **Mittel**: 2-3 Schaden/Tick, +1,0s Zeitgewinn  
  - **Stark**: 4-5 Schaden/Tick, +1,5s Zeitgewinn
- **Nicht stapelbar**: Gleicher DoT-Typ überschreibt vorherigen
- **Rudel-Fokus**: Wirkt nur auf aktuell fokussiertes Mitglied
- **Zeitgewinn**: Bei jedem Tick, maximiert DoT-Wert

---

## 🛡️ **KLASSEN-MECHANIKEN**

### Chronomant-Mechaniken

#### Arkanpuls (0-5)
- **Generierung**: +1 pro Zeitmanipulations- oder Elementarkarte bei Treffer
- **Verfall**: -1 pro Sekunde nach 3s Inaktivität
- **Schwellenboni**:
  - **1**: +5% Zeiteffizienz (alle Karten kosten 5% weniger Zeit)
  - **2+**: +10% Elementarschaden
  - **3+**: -0,5s Zeitkosten für Zeitmanipulation  
  - **4+**: +15% Zeitmanipulation-Effektivität
- **Arkanschub (bei 5)**: Nächste Karte +50% Effektivität → Reset auf 0

#### Kartenreihenfolge
- **Definition**: Reihenfolgen-abhängige Synergien zwischen Kartentypen
- **Zeitmanip → Elementar**: +20% Schaden für nächste Elementarkarte
- **Elementar → Zeitmanip**: +10% Effektivität für nächste Zeitmanipulation
- **Strategisch**: Belohnt durchdachte Kartensequenzen

### Zeitwächter-Mechaniken

#### Schildmacht (0-5)
- **Generierung**: +1 pro erfolgreichem Block
- **Verfall-Mechanik** (präzisiert):
  - **Inaktivitäts-Timer**: Nach 5s ohne erfolgreichen Block beginnt Verfall
  - **Normaler Verfall** (0-2 SM): -1 SM alle 10s (max. 1 SM pro abgeschlossenem 10s-Intervall)
  - **Soft-Cap-Verfall** (3+ SM): -1 SM alle 5s (max. 1 SM pro abgeschlossenem 5s-Intervall)
  - **Verfall-Reset**: Erfolgreicher Block stoppt Verfall sofort und setzt Timer zurück
- **Passive Boni** (kumulativ):
  - **1**: +5% Blockdauer
  - **2+**: +0,5s Zeitrückgewinn bei Block-Karten
  - **3+**: +1 Schaden bei Angriffskarten
  - **4+**: Immunität gegen nächsten Zeitdiebstahl
- **Schildbruch (bei 5)**: 15 direkter Schaden + 2,0s Zeitraub → Reset auf 0

#### Phasenwechsel
- **Definition**: Alternierung zwischen Angriff und Verteidigung mit Boni
- **Nach Verteidigung**: Nächste Angriffskarte +15% Schaden
- **Nach Angriff**: Nächste Verteidigungskarte +1s Zeitgewinn
- **Strategisch**: Belohnt ausgewogenes Spiel zwischen Offensiv/Defensiv

#### Zeitfessel
- **Definition**: Spezieller Verzögerungseffekt des Zeitwächters
- **Effekt**: +3s Gegnerverzögerung (Basis-Version)
- **Evolutionen**: Bis zu +5s möglich
- **Klassenthema**: Defensive Kontrolle durch Gegner-Zeitmanipulation

### Schattenschreiter-Mechaniken

#### Momentum (0-5)
- **Generierung**: +1 pro gespielter Karte (auch bei 0-Zeit-Karten)
- **Verfall**: -1 pro Sekunde nach 3s Inaktivität
- **Schwellenboni** (kumulativ):
  - **1**: +5% Schaden für Angriffskarten
  - **2+**: +10% Schaden für Angriffskarten
  - **3+**: Angriffskarte nach Schattenkarte +20% Schaden
  - **4+**: +0,5s Zeitgewinn pro gespielter Karte
- **Schattenrausch (bei 5)**: Nächste 5s alle Karten +25% Effektivität → Reset auf 0

#### Schattensynergie
- **Definition**: Schattenkarten machen nachfolgende Angriffskarten kostenlos oder günstiger
- **Schattensynergie-Karten**: Schleier, Schattenform, spezielle Evolutionen
- **Effekte**:
  - **Primär**: Nächste Angriffskarte kostet 0 Zeit
  - **Sekundär**: Nächste Angriffskarte -50% Kosten (falls nicht kostenlos möglich)
- **Tempo-Fokus**: Ermöglicht explosive Kartenfolgen

---

## 🎮 **KAMPF-SPEZIAL-MECHANIKEN**

### Rudel-Kampf-Mechaniken

#### Mathematische Effizienz von AoE vs Einzelziel
Playtest-Ergebnis: AoE spart ~12s pro 3 Rudel (2er-Gruppen)
- Einzelziel: ~28s für 6 Gegner
- AoE-Strategie: ~16s für 6 Gegner
- ROI: AoE-Karten amortisieren höhere Kosten nach 2 Rudeln

#### Zeit-Economy-Richtlinien
Ziel-DPS (Damage per Second inklusive Kartenkosten):
- Tutorial: 1-2 DPS genügt
- Welt 1: 2-3 DPS Standard
- Welt 1 Boss: 3-4 DPS erforderlich

#### Rudel-System ("Rudel als Schild")
- **Darstellung**: Ein sichtbares Haupt-Modell repräsentiert das ganze Rudel
- **Schild-Sphären**: Kleine leuchtende Kugeln unterhalb des Haupt-Sprites (1 pro zusätzlichem Mitglied)
- **HP-Anzeige**: "20 HP ×3 (60)" - einzeln und gesamt
- **Kein manuelles Targeting**: Spieler trifft AUTOMATISCH immer das vorderste Mitglied
- **Ebenen-System**: Angriffe wirken auf aktuelle "Ebene" (vorderstes lebendes Mitglied)

#### Schadensverrechnung bei Rudeln
1. **Einzelziel-Angriffe**: Treffen nur vorderstes Mitglied + Durchbruchschaden
2. **AoE-Angriffe**: 
   - **Basis-Regel**: "Trifft primäres Ziel und bis zu 2 weitere zufällige Ziele"
   - **Rudel-Anpassung**: Bei Rudeln sind die "weiteren Ziele" die nächsten Schild-Sphären
   - **Beispiel**: AoE gegen 4er-Rudel trifft vorderstes Mitglied (100%) + nächste 2 Sphären (je 50%)
3. **DoT-Effekte**: Nur auf aktuell fokussiertes (vorderstes) Mitglied
4. **Kettenschaden**: Springt sequenziell vom vordersten zu den nächsten Mitgliedern

### Block- und Abwehr-Mechaniken

#### Block-System
- **Definition**: Verhindert nächsten Angriff innerhalb des Zeitfensters
- **Zeitfenster**: Meist 3-7 Sekunden je nach Karte
- **Erfolgs-Boni**: Klassenspezifische Belohnungen (SM, Zeitgewinn, etc.)
- **Strategisch**: Timing-abhängig, erfordert Vorhersage

#### Reflexion
- **Definition**: Erlittener Schaden/Effekt wird teilweise oder vollständig zum Angreifer zurückgeworfen
- **Zeitwächter-Fokus**: Primäre Klasse für Reflexions-Mechaniken
- **Typen**: Schadens-Reflexion, Zeitdiebstahl-Reflexion
- **Beispiele**: "Zeitparade" (reflektiert Zeitdiebstahl + 6 Schaden)

### Ressourcen-Interaktion

#### Gegner-Ressourcen-Konter
- **Chrono-Intelligenz**: Konter gegen Ressourcenverbrauch-Effekte
- **Zeitfestung**: Konter gegen massive AoE-Zeitmanipulation  
- **Momentum-Unterbrechung**: Gegner können Momentum-Aufbau stören

#### Elemental-Resistenzen
- **Standard**: +50% vs eigenes Element, -25% vs Konter-Element
- **Feuer vs Eis**: Klassische Gegensätze
- **Blitz**: Neutral zu anderen, Fokus auf Geschwindigkeit
- **Wechselnd**: Manche Gegner ändern Resistenzen (Phasen, Zeit-basiert)

---

## 📊 **KATEGORISIERTE MECHANIK-REFERENZ**

### Zeitmanipulation
| Mechanik | Nutzer | Effekt | Mobile Name |
|----------|--------|--------|-------------|
| **Zeitraub** | Spieler | Stiehlt Zeit vom Gegner | Zeitraub |
| **Zeitdiebstahl** | Gegner | Stiehlt Zeit vom Spieler | Zeitdiebstahl |
| **Verzögerung** | Spieler | Verschiebt nächsten Angriff | Verzögern |
| **Zeitverzerrung** | Spieler | Verlangsamt Gegner-Timer | Zeitverzerrung |
| **Zeitgewinn** | Spieler | Direkter Zeitbonus | Zeitgewinn |

### Schaden-Typen
| Mechanik | Zieltyp | Besonderheit | Mobile Name |
|----------|---------|--------------|-------------|
| **Direktschaden** | Einzelziel | Standard-Schaden | Direktschaden |
| **AoE** | Alle Ziele | Voller Schaden auf alle | Flächenschaden |
| **Kettenschaden** | Mehrere | Abnehmender Schaden | Kettenschaden |
| **Durchbruchschaden** | Rudel | 50% Überschuss weiter | Durchbruchschaden |
| **DoT** | Einzelziel | Schaden über Zeit | Dauerschaden |

### Klassen-Ressourcen
| Klasse | Ressource | Maximum | Verfall | Mobile Name |
|--------|-----------|---------|---------|-------------|
| **Chronomant** | Arkanpuls | 5 | -1/s nach 3s | Arkanpuls |
| **Zeitwächter** | Schildmacht | 5 | -1/10s nach 5s | Schildmacht |
| **Schattenschreiter** | Momentum | 5 | -1/s nach 3s | Momentum |

### Spezial-Mechaniken
| Mechanik | Klasse | Auslöser | Mobile Name |
|----------|--------|----------|-------------|
| **Arkanschub** | Chronomant | 5 Arkanpuls | Arkanschub |
| **Schildbruch** | Zeitwächter | 5 Schildmacht | Schildbruch |
| **Schattenrausch** | Schattenschreiter | 5 Momentum | Schattenrausch |
| **Kartenreihenfolge** | Chronomant | Sequenz-abhängig | Kartenreihenfolge |
| **Phasenwechsel** | Zeitwächter | Abwechselnd | Phasenwechsel |
| **Schattensynergie** | Schattenschreiter | Nach Schattenkarte | Schattensynergie |

---

## ⚖️ **BALANCING-RICHTLINIEN (OPPORTUNITY COSTS-SYSTEM)**

### Zeitmanipulation-Trade-offs (Keine Caps)
- **Natürliche Grenze**: Nur 3-Minuten-Rift als hartes Limit
- **Kosten-Penalties**: Alle in 0,5s-Schritten für Mobile-Lesbarkeit
- **Schadens-Penalties**: Proportional zur Zeitmanipulations-Stärke
- **Klassenbalance**: Schattenschreiter effizienteste Zeitraub-Klasse

### Schaden-Balance
- **AoE vs Einzelziel**: AoE 20-30% weniger Schaden pro Ziel
- **DoT vs Direktschaden**: DoT verteilt über Zeit, Zeitgewinn als Kompensation
- **Kettenschaden**: Stark abnehmend (60%/40%/20%) für Balance

### Klassenressourcen-Balance
- **Aufbau-Geschwindigkeit**: 1 Punkt pro relevante Aktion
- **Verfall-Timing**: 3s Inaktivität für Momentum/Arkanpuls, 5s für Schildmacht
- **Maximum-Effekte**: Spielwendende Power bei 5 Punkten
- **Verfall-Resistenz**: Zeitwächter mit langsamem Verfall (10s) als Klassenbonus

---

## 🚀 **STRATEGISCHE IMPLIKATIONEN**

### Rudel-Optimierung
1. **AoE-Priorität**: Gegen Rudel immer bevorzugen
2. **Durchbruchschaden**: Starke Einzelangriffe auf schwächste Mitglieder
3. **DoT-Timing**: Nur auf letztes/stärkstes Rudel-Mitglied
4. **Kettenschaden-Evolutionen**: Für dichte Rudel-Formationen

### Zeiteffizienz-Strategien
1. **Frühe Phase**: Hohe Effizienz-Karten (kurze Zeitkosten)
2. **Mittlere Phase**: Balance zwischen Schaden und Zeitkosten
3. **Endgame**: Optimierte Kombos mit Klassenressourcen

### Klassen-Synergien
1. **Chronomant**: Arkanpuls-Management + Kartenreihenfolge
2. **Zeitwächter**: Schildmacht-Zyklen + Phasenwechsel
3. **Schattenschreiter**: Momentum-Ketten + Schattensynergie

---

## 📋 **ABHÄNGIGKEITEN & INTEGRATION**

### Referenz-Dokumente
- **ZK-CARDS.md**: Spezifische Karteneffekte und Evolutionen
- **ZK-CHRONOMANT.md**: Detaillierte Arkanpuls-Mechaniken
- **ZK-ZEITWAECHTER.md**: Schildmacht und Phasenwechsel Details  
- **ZK-SCHATTENSCHREITER.md**: Momentum und Schattensynergie Details
- **ZK-GEGNER-DATENBANK.md**: Gegner-Zeitmanipulationen und Resistenzen

### Implementierung-Prioritäten
1. **Kern-Zeitsystem**: 3-Minuten-Rifts mit Zeitmanipulation
2. **Klassen-Ressourcen**: Arkanpuls, Schildmacht, Momentum
3. **Schaden-Systeme**: Durchbruch, Kette, AoE, DoT
4. **Spezial-Mechaniken**: Klassenspezifische Synergien

---

**✅ STATUS: MECHANIKEN VOLLSTÄNDIG KONSOLIDIERT**
**🔥 NAMENSKONVENTIONEN: MOBILE-FREUNDLICH & INTUITIV**  
**⚡ KLASSENMECHANIKEN: VOLLSTÄNDIG INTEGRIERT**
**📝 KONSISTENZ: ALLE WIDERSPRÜCHE AUFGELÖST**
**🎯 BALANCE: STRATEGISCHE TIEFE MAXIMIERT**