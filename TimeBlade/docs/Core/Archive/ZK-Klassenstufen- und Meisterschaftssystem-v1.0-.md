# Zeitklingen: Klassenstufen- und Meisterschaftssystem
*Design-Dokument v1.0*

## Einleitung

Dieses Dokument detailliert das Klassenstufen- und Meisterschaftssystem für Zeitklingen, das parallel zur Kartenprogression existiert und globale Spielerboni freischaltet. Es beschreibt die Mechanik der Klassenerfahrung, die detaillierten Effekte der Klassenstufen-Boni und das Endgame-Meisterschaftssystem für jede der drei Klassen.

## 1. Klassenerfahrungs-System (Class XP)

### 1.1 Grundmechanik
- Klassenerfahrung ist **separat** von Karten-XP und wird parallel dazu gesammelt
- Repräsentiert die wachsende Beherrschung der klasseneigenen Zeitmanipulations-Fähigkeiten
- Beeinflusst globale Spielerboni, die unabhängig von der Kartenwahl/Evolution wirken
- Maximum: **Level 25** (danach beginnt das Meisterschaftssystem)

### 1.2 XP-Quellen und Vergaberaten

| Aktivität | XP-Vergabe | Modifikatoren |
|-----------|------------|---------------|
| **Kampfsieg (Standard)** | 25-50 XP | +50% (Heroisch), +100% (Legendär)<br>Multiplikator: Welt 1: 1.0×, Welt 2: 1.5×, Welt 3: 2.0×, Welt 4: 2.5×, Welt 5: 3.0× |
| **Elite-Gegner** | 100-150 XP | Gleiche Multiplikatoren wie Standard |
| **Mini-Boss** | 250-350 XP | Gleiche Multiplikatoren wie Standard |
| **Dungeon-Boss** | 500-750 XP | Gleiche Multiplikatoren wie Standard |
| **Weltabschluss (Normal)** | 1,500 XP | +50% (Heroisch), +100% (Legendär) |
| **Tägliche Klassen-Quest** | 200-300 XP | - |
| **Wöchentliche Klassen-Quest** | 1,000-1,500 XP | - |
| **Zeitlose Kammer** | 50 XP pro 5 Stufen | +10 XP pro 10 Stufen |
| **Klassenstufen-Herausforderungen** | 1,000-5,000 XP | Einmalige, stufenspezifische Prüfungen (für Stufen 5, 10, 15, 20) |

### 1.3 XP-Kurve (Benötigte XP pro Level)

Die Kurve ist so konzipiert, dass die Progression mit den Pacing-Zielen aus `Zeitklingen: Progression & Hook-Mechaniken-v1.3` übereinstimmt.

| Level | Benötigte XP | Kumulierte XP | Spielzeit (Ziel) |
|-------|-------------|---------------|------------------|
| 1 → 2 | 1,000 | 1,000 | ~4 Stunden |
| 2 → 3 | 1,800 | 2,800 | ~10 Stunden |
| 3 → 4 | 2,700 | 5,500 | ~18 Stunden |
| 4 → 5 | 3,800 | 9,300 | **~30 Stunden** |
| 5 → 6 | 5,000 | 14,300 | ~38 Stunden |
| 6 → 7 | 6,500 | 20,800 | ~48 Stunden |
| 7 → 8 | 8,200 | 29,000 | ~58 Stunden |
| 8 → 9 | 10,000 | 39,000 | ~68 Stunden |
| 9 → 10 | 12,000 | 51,000 | **~80 Stunden** |
| 10 → 11 | 13,500 | 64,500 | ~90 Stunden |
| 11 → 12 | 15,000 | 79,500 | ~100 Stunden |
| 12 → 13 | 16,500 | 96,000 | ~110 Stunden |
| 13 → 14 | 18,000 | 114,000 | ~120 Stunden |
| 14 → 15 | 19,500 | 133,500 | **~130 Stunden** |
| 15 → 16 | 21,000 | 154,500 | ~140 Stunden |
| 16 → 17 | 22,500 | 177,000 | ~150 Stunden |
| 17 → 18 | 24,000 | 201,000 | ~160 Stunden |
| 18 → 19 | 25,500 | 226,500 | ~170 Stunden |
| 19 → 20 | 27,000 | 253,500 | **~180 Stunden** |
| 20 → 21 | 28,500 | 282,000 | ~190 Stunden |
| 21 → 22 | 30,000 | 312,000 | ~205 Stunden |
| 22 → 23 | 32,000 | 344,000 | ~220 Stunden |
| 23 → 24 | 34,000 | 378,000 | ~235 Stunden |
| 24 → 25 | 36,000 | 414,000 | **~250 Stunden** |

### 1.4 Klassenstufen-Herausforderungen

Um den wichtigsten Stufenübergängen (5/10/15/20) zusätzliche Bedeutung zu verleihen, müssen Spieler spezielle Prüfungen absolvieren:

| Herausforderung | Beschreibung | Belohnung |
|-----------------|--------------|-----------|
| **Pfad des Novizen (Stufe 5)** | Absolviere eine spezielle Mission mit klassenspezifischen Mechaniken | Entsperrt Stufe-5-Bonus + Einzigartiges Klassenemblem |
| **Prüfung des Adepten (Stufe 10)** | Besiege einen mächtigen klassenspezifischen Gegner | Entsperrt Stufe-10-Bonus + Spezielles Kosmetikitem |
| **Ritual des Meisters (Stufe 15)** | Erfülle eine komplexe Herausforderung, die tiefes Verständnis der Klassensynergien erfordert | Entsperrt Stufe-15-Bonus + Visueller Klasseneffekt |
| **Schildbruch (Stufe 20)** | Überwinde eine extrem anspruchsvolle zeitbasierte Herausforderung | Entsperrt Stufe-20-Bonus + Klassentitel |

## 2. Detaillierte Klassenstufen-Boni

### 2.1 Chronomant

#### Stufe 5: Arkane Präkognition
- **Mechanik:** Zu Kampfbeginn wird die Starthand analysiert. Falls keine Signaturkarte (*Arkanblick* oder *Zeitverzerrung*) enthalten ist, wird eine zufällig ausgewählte dem Spieler hinzugefügt.
- **Implementierungsdetails:**
  - Prüfung findet VOR dem anfänglichen Kartenziehen statt
  - Keine zusätzliche Zeit-/Ressourcenkosten
  - Animation: Kurzes blaues Aufleuchten der hinzugefügten Karte
  - UI: Kleines "Präkognition"-Symbol auf der hinzugefügten Karte

#### Stufe 10: Elementare Resonanz
- **Mechanik:** Karten mit gleicher Elementar-Evolution verstärken sich gegenseitig. Für jede Karte mit derselben Elementar-Evolution im Deck erhält der Spieler +5% Effektivität für Karten dieses Elements.
- **Implementierungsdetails:**
  - Maximalbonus: +25% pro Element (ab 5 Karten mit gleicher Evolution)
  - Berechnung: `ElementBonus[Element] = Min(5, AnzahlKartenMitElement) * 5%`
  - Betrifft: Schaden, Heilung, DoT-Werte, Dauer von Statuseffekten
  - UI: Elementare Bonusanzeige im Kampfinterface

#### Stufe 15: Zeitrückgewinnung
- **Mechanik:** Nach dem Spielen jeder Karte gewinnt der Spieler 0,2 Sekunden Zeit zurück.
- **Implementierungsdetails:**
  - Kumulative Verrechnung mit anderen Zeitgewinn-Effekten
  - Maximaler Zeitgewinn pro Kampf: unbegrenzt (innerhalb des Kämpflimits)
  - Animation: Kleiner "+0,2s" Effekt bei jeder Kartenspielung
  - UI: Kurzfristige grüne Zeitanzeige-Animation

#### Stufe 20: Arkane Synergie
- **Mechanik:** Wenn zwei Karten desselben Elements nacheinander gespielt werden, erhält die zweite +15% Effektivität auf alle ihre Effekte.
- **Implementierungsdetails:**
  - Der Bonus wird automatisch auf die nächste Angriffskarte angewendet
  - Zeitfenster: 5 Sekunden nach dem erfolgreichen Block
  - Wirkt auf alle Schadenskomponenten (direkt, DoT, Spezial)
  - Animation: Die Angriffskarte leuchtet golden nach einem Block
  - UI: "Vergeltung bereit"-Statusanzeige mit Timer

#### Stufe 25: Zeitmanipulation
- **Mechanik:** Freischaltung des Meisterschaftssystems. Zusätzlich beginnt jeder Kampf mit 5 Sekunden mehr Anfangszeit (65s statt 60s).
- **Implementierungsdetails:**
  - Permanent erhöhte Startzeit für alle Kämpfe
  - Meisterschaftssystem wird entsperrt (siehe Abschnitt 3)
  - UI: Überarbeitetes HUD mit Meisterschaftsoption und längerer Timer-Anzeige

### 2.2 Zeitwächter

#### Stufe 5: Wachsame Verteidigung
- **Mechanik:** Der Spieler startet jeden Kampf mit einem automatischen Block für den ersten eingehenden Angriff.
- **Implementierungsdetails:**
  - Block gilt für jede Art von Angriff (physisch, magisch, etc.)
  - Wird nicht durch "Durchdringende" Angriffe umgangen (vollständige Immunität)
  - Animation: Permanentes Schildsymbol zu Kampfbeginn, das beim ersten Block verschwindet
  - UI: Schildindikator im HUD zeigt den aktiven Auto-Block-Status

#### Stufe 10: Schild-Echo
- **Mechanik:** Nach jedem erfolgreichen Block besteht eine 15% Chance, den nächsten gegnerischen Angriff zu reflektieren.
- **Implementierungsdetails:**
  - Prüfung erfolgt bei jedem Block-Ereignis
  - Reflexion wirkt wie ein vollständiger Konter mit 100% des ursprünglichen Schadens
  - Maximale Dauer des Reflex-Zustands: 5 Sekunden nach dem Block
  - Animation: Pulsierendes Schild bei aktivem Reflex
  - UI: "Echo bereit"-Statusanzeige nach erfolgreicher Aktivierung

#### Stufe 15: Temporale Rüstung
- **Mechanik:** Alle Zeitdiebstahl-Effekte von Gegnern und zeitreduzierende Effekte werden um 15% abgeschwächt.
- **Implementierungsdetails:**
  - Multiplikative Berechnung: `Finaler_Zeitverlust = Basis_Zeitverlust * 0,85`
  - Wirkt auf alle Formen von Zeitverlust (Diebstahl, Reduktion, Verzögerung)
  - Animation: Visuelle Abwehreffekte bei eingehendem Zeitdiebstahl
  - UI: Animation reduzierter Zahlen bei Zeitverlusten

#### Stufe 20: Vergeltung
- **Mechanik:** Nach einem erfolgreichen Block verursacht die nächste Angriffskarte 35% mehr Schaden.
- **Implementierungsdetails:**
  - Der Bonus wird automatisch auf die nächste Angriffskarte angewendet
  - Zeitfenster: 5 Sekunden nach dem erfolgreichen Block
  - Wirkt auf alle Schadenskomponenten (direkt, DoT, Spezial)
  - Animation: Die Angriffskarte leuchtet golden nach einem Block
  - UI: "Vergeltung bereit"-Statusanzeige mit Timer

#### Stufe 25: Zeitfortifikation
- **Mechanik:** Freischaltung des Meisterschaftssystems. Zusätzlich dauern alle defensiven Effekte 20% länger.
- **Implementierungsdetails:**
  - Betrifft: Blockdauer, Reflektionsdauer, Ausweichzeit, Schild-Effekte
  - Berechnung: `Finale_Dauer = Basis_Dauer * 1,2`
  - Meisterschaftssystem wird entsperrt (siehe Abschnitt 3)
  - UI: Überarbeitetes HUD mit Meisterschaftsoption

### 2.3 Schattenschreiter

#### Stufe 5: Schnellzieher
- **Mechanik:** Der Spieler beginnt jeden Kampf mit +1 Momentum.
- **Implementierungsdetails:**
  - Wird automatisch zu Kampfbeginn angewendet
  - Erscheint vor jeglicher Karteninteraktion
  - Animation: Momentum-Ladung erscheint sofort (statt leer)
  - UI: Momentum-Anzeige startet bei 1/5 statt 0/5

#### Stufe 10: Verbesserte Schattensynergie
- **Mechanik:** Die Schattensynergie wirkt auf die nächsten 2 Angriffskarten statt nur auf eine.
- **Implementierungsdetails:**
  - Nach dem Spielen einer Schattenkarte kosten die nächsten 2 Angriffskarten 0 Zeit
  - Die 0-Kosten gelten nur für Karten mit dem "angriff"-Tag
  - Animation: Doppelte Schatten-Aura um die Hand nach Aktivierung
  - UI: Bis zu 2 Karten in der Hand werden als kostenlos markiert

#### Stufe 15: Momentum-Katalysator
- **Mechanik:** Die Momentum-Haltbarkeit wird um 25% verlängert.
- **Implementierungsdetails:**
  - Verfall beginnt nach 3,75 Sekunden (statt 3 Sekunden)
  - Die Verfallrate bleibt bei 1 Punkt/Sekunde
  - Animation: Langsameres Pulsieren der Momentum-Anzeige
  - UI: Veränderte Verfallswarnung mit verlängertem Timer

#### Stufe 20: Zeitdiebstahl-Meister
- **Mechanik:** Alle Zeitdiebstahl-Effekte (Karten mit "zeitsplitter"-Tag) werden um 20% wirksamer.
- **Implementierungsdetails:**
  - Berechnung: `Finaler_Zeitgewinn = Basis_Zeitgewinn * 1,2`
  - Betrifft alle eigenen Zeitdiebstahl-Karten und -Effekte
  - Animation: Verstärkter visueller Effekt bei Zeitdiebstahl
  - UI: Größere Zahlendarstellung bei Zeitdiebstahleffekten

#### Stufe 25: Schattenverschmelzung
- **Mechanik:** Freischaltung des Meisterschaftssystems. Zusätzlich generieren Schattenkarten +1 Momentum beim Spielen.
- **Implementierungsdetails:**
  - Alle Karten mit dem "shadow"-Tag generieren +1 zusätzliches Momentum (insgesamt +2)
  - Momentum-Maximum bleibt bei 5
  - Meisterschaftssystem wird entsperrt (siehe Abschnitt 3)
  - UI: Überarbeitetes HUD mit Meisterschaftsoption

## 3. Meisterschaftssystem

### 3.1 Meisterschaftspunkte-Vergabe

Nach Erreichen von Klassenstufe 25 werden Meisterschaftspunkte durch folgende Aktivitäten verdient:

| Aktivität | Meisterschaftspunkte | Anmerkungen |
|-----------|---------------------|-------------|
| **Virtuelle Level-Ups** | 1 Punkt | Für jede Klassenstufe 25 XP-Grenze (36,000), die überschritten wird |
| **Weltabschluss (Heroisch/Legendär)** | 1 Punkt | Kann einmal pro Welt und Schwierigkeitsgrad verdient werden (10 max.) |
| **Zeitlose Kammer (Meilensteine)** | 1 Punkt | Bei Erreichen von Stufe 50/100/150/200/250/300/350/400/450/500 |
| **Zenitfortschritt** | 1 Punkt | Für jede transformierte Zenit-Karte (selten) |
| **Meisterschaftsherausforderungen** | 1-3 Punkte | Spezielle, schwierige Aufgaben (25 Punkte max.) |

- Das System erlaubt unbegrenztes Wachstum, mit abnehmenden Vorteilen pro investiertem Punkt
- Realistische Obergrenze pro Baum: 20-25 Punkte für Fokussierung, 30-40 verteilt über alle Bäume
- Jeder Punkt muss bewusst in einen der drei Bäume investiert werden
- Im Endgame wäre eine theoretische Obergrenze bei 100+ Punkten nach mehreren hundert Spielstunden

### 3.2 Chronomant-Meisterschaftsbäume

#### 3.2.1 Elementarmeisterschaft (Chronomant)

*Fokussiert auf die Verstärkung elementarer Zauber und Reaktionen.*

**Stufe 1 (Einstiegspunkte, jeweils 1 Punkt):**
- **Elementare Affinität**: +5% Schaden mit allen Elementarzaubern.
- **Arkane Konduktion**: +10% Effektdauer für alle Elementarzauber.
- **Katalysator**: +5% Chance auf doppelte Arkankraft-Generierung bei Elementarzaubern.

**Stufe 2 (benötigen 1-2 Punkte in vorherigen Knoten, jeweils 2 Punkte):**
- **Feuermeisterschaft**: +15% Schaden und +0,5s DoT-Dauer für Feuer-Zauber. *(erfordert Elementare Affinität)*
- **Eismeisterschaft**: +15% Effektivität und +0,5s Slow-Dauer für Eis-Zauber. *(erfordert Arkane Konduktion)*
- **Blitzmeisterschaft**: +15% Schaden und +1 Kettensprung für Blitz-Zauber. *(erfordert Katalysator)*

**Stufe 3 (benötigen 3-4 Punkte in vorherigen Knoten, jeweils 3 Punkte):**
- **Pyrokinese**: Feuer-DoTs ticken 15% schneller. *(erfordert Feuermeisterschaft)*
- **Kryokinese**: Eis-Slow-Effekte reduzieren auch Gegnerangriffe um 10%. *(erfordert Eismeisterschaft)*
- **Elektrokinese**: Blitz-Zauber haben 15% Chance, 0 Zeit zu kosten. *(erfordert Blitzmeisterschaft)*

**Stufe 4 (Kapazitäts-Knoten, jeweils 5 Punkte):**
- **Elementarsphäre**: Beim Erreichen von 5 Arkankraft werden AoE-Effekte mit 30% Wirksamkeit auf alle Gegner angewendet. *(erfordert 2 Stufe-3-Knoten)*

#### 3.2.2 Zeitmeisterschaft (Chronomant)

*Verbessert Zeitmanipulation und Ressourceneffizienz.*

**Stufe 1 (Einstiegspunkte, jeweils 1 Punkt):**
- **Zeitexperte**: -5% Zeitkosten für alle Karten.
- **Chronoeinsparung**: +0,1s Zeitgewinn pro gespielter Karte (kumulativ mit dem Klassenstufe-15-Bonus).
- **Raum-Zeit-Kontinuum**: +5% Chance, beim Kartenziehen zusätzliche Karten zu ziehen.

**Stufe 2 (benötigen 1-2 Punkte in vorherigen Knoten, jeweils 2 Punkte):**
- **Zeitkompression**: -10% Zeitkosten für Karten, die 3,0s oder mehr kosten. *(erfordert Zeitexperte)*
- **Temporale Verlängerung**: +15% Dauer für alle zeitbasierten Effekte (Verzögerung, Slow). *(erfordert Chronoeinsparung)*
- **Dimensionstasche**: Bei Kampfbeginn ziehe +1 Karte. *(erfordert Raum-Zeit-Kontinuum)*

**Stufe 3 (benötigen 3-4 Punkte in vorherigen Knoten, jeweils 3 Punkte):**
- **Präzisionszeitdilettant**: Nach dem Spielen von 3 Karten innerhalb von 2 Sekunden: Die vierte Karte kostet 0 Zeit. *(erfordert Zeitkompression)*
- **Chrono-Umkehr**: 10% Chance nach Schadenserhalt, 1,0s Zeit zurückzugewinnen. *(erfordert Temporale Verlängerung)*
- **Kartenschleife**: 5% Chance beim Spielen einer Karte, eine Kopie in die Hand zu bekommen. *(erfordert Dimensionstasche)*

**Stufe 4 (Kapazitäts-Knoten, jeweils 5 Punkte):**
- **Zeitgabelung**: Bei Kampfbeginn: 25% Chance auf +10 Sekunden Startzeit. *(erfordert 2 Stufe-3-Knoten)*

#### 3.2.3 Arkanmeisterschaft (Chronomant)

*Spezialisiert auf die Zeitliche Arkankraft-Mechanik und Zeitstrom-Resonanz.*

**Stufe 1 (Einstiegspunkte, jeweils 1 Punkt):**
- **Arkane Verstärkung**: +10% Effektivität bei Effekten, die von Zeitlicher Arkankraft abhängen.
- **Resonanzverstärkung**: +5% stärkere Boni durch Zeitstrom-Resonanz.
- **Chrono-Katalysator**: +0,5 Sekunden verlängerte Dauer für Schwellenboni bei 4+ Arkankraft.

**Stufe 2 (benötigen 1-2 Punkte in vorherigen Knoten, jeweils 2 Punkte):**
- **Machtreserve**: Der Schwellenbonus bei 2 Arkankraft erhöht sich von +10% auf +15% Schaden. *(erfordert Arkane Verstärkung)*
- **Resonanzharmonie**: Der Beschleunigte Strom gibt zusätzlich +0,1s Zeitgewinn pro Elementarzauber. *(erfordert Resonanzverstärkung)*
- **Verbesserter Bruch**: Der Bruch bei 5 Arkankraft gewährt +10% zusätzliche Effektivität. *(erfordert Chrono-Katalysator)*

**Stufe 3 (benötigen 3-4 Punkte in vorherigen Knoten, jeweils 3 Punkte):**
- **Arkane Effizienz**: Der Schwellenbonus bei 3 Arkankraft reduziert Zeitkosten um 0,75s statt 0,5s. *(erfordert Machtreserve)*
- **Tiefe Resonanz**: Der Verlangsamte Strom gewährt zusätzlich +5% Effektdauer für Zeitmanipulationskarten. *(erfordert Resonanzharmonie)*
- **Verfeinerte Kontrolle**: Arkankraft verfällt nur alle 1,5 Sekunden statt jede Sekunde. *(erfordert Verbesserter Bruch)*

**Stufe 4 (Kapazitäts-Knoten, jeweils 5 Punkte):**
- **Ständige Arkanum**: Beginne jeden Kampf mit 2 Zeitlicher Arkankraft. *(erfordert 2 Stufe-3-Knoten)*

### 3.3 Zeitwächter-Meisterschaftsbäume

#### 3.3.1 Elementarmeisterschaft (Zeitwächter)

*Fokussiert auf Elementare Verstärkung und Reflexion.*

**Stufe 1 (Einstiegspunkte, jeweils 1 Punkt):**
- **Elementarschutz**: +5% Schadensreduktion gegen elementare Angriffe.
- **Elementare Vergeltung**: +10% Reflexionsschaden bei elementaren Evolutionen.
- **Elementare Durchdringung**: +5% Schaden mit Elementarangriffen gegen blockende Gegner.

**Stufe 2 (benötigen 1-2 Punkte in vorherigen Knoten, jeweils 2 Punkte):**
- **Feuerschutz**: Erfolgreiche Blocks gegen Feuerangriffe verursachen 2 DoT am Angreifer. *(erfordert Elementarschutz)*
- **Eisschild**: Erfolgreiche Blocks gegen Angriffe verlangsamen den Angreifer um 10% für 2s. *(erfordert Elementare Vergeltung)*
- **Blitzreflektion**: Erfolgreiche Blocks haben 10% Chance, 2 Schaden an alle Gegner zu verursachen. *(erfordert Elementare Durchdringung)*

**Stufe 3 (benötigen 3-4 Punkte in vorherigen Knoten, jeweils 3 Punkte):**
- **Feuerabsorption**: Nach 3 erfolgreichen Blocks erhält die nächste Feuer-Evolution +30% Schaden. *(erfordert Feuerschutz)*
- **Kryostase**: Nach einem erfolgreichen Block: 15% Chance auf einen zusätzlichen freien Block. *(erfordert Eisschild)*
- **Leitfähigkeit**: Erfolgreiche Blocks haben 10% Chance, 1 Schildmacht zu generieren. *(erfordert Blitzreflektion)*

**Stufe 4 (Kapazitäts-Knoten, jeweils 5 Punkte):**
- **Elementarabsorber**: Jeder 5. erfolgreiche Block gewährt einen elemental aufgeladenen Vergeltungseffekt, der automatisch 8 Schaden des entsprechenden Elements verursacht. *(erfordert 2 Stufe-3-Knoten)*

#### 3.3.2 Zeitmeisterschaft (Zeitwächter)

*Verbessert Zeitkontrolle und defensive Fähigkeiten.*

**Stufe 1 (Einstiegspunkte, jeweils 1 Punkt):**
- **Zeitexperte**: -5% Zeitkosten für alle Karten.
- **Erhöhte Präsenz**: +10% Dauer für zeitreduzierende Effekte auf Gegner.
- **Chrono-Reserven**: +2 Sekunden initiale Kampfzeit.

**Stufe 2 (benötigen 1-2 Punkte in vorherigen Knoten, jeweils 2 Punkte):**
- **Schnelle Reflexe**: -10% Zeitkosten für alle Verteidigungskarten. *(erfordert Zeitexperte)*
- **Zeitbarriere**: +10% Stärke aller Zeitdiebstahlschutz-Effekte (kumulativ mit dem Klassenstufe-15-Bonus). *(erfordert Erhöhte Präsenz)*
- **Ressourcenmanagement**: +0,2s Zeitgewinn nach jedem erfolgreichen Block. *(erfordert Chrono-Reserven)*

**Stufe 3 (benötigen 3-4 Punkte in vorherigen Knoten, jeweils 3 Punkte):**
- **Chrono-Schild**: Jeder 5. Karteneffekt, der Zeit kostet, wird um 50% reduziert. *(erfordert Schnelle Reflexe)*
- **Nullfeld**: Zeitdiebstahlschutz-Effekte reduzieren gegnerische Zeitgewinne um 10%. *(erfordert Zeitbarriere)*
- **Zeitliche Kontrolle**: Nach 4 erfolgreichen Blocks werden alle Gegnerangriffe für 1,0s pausiert. *(erfordert Ressourcenmanagement)*

**Stufe 4 (Kapazitäts-Knoten, jeweils 5 Punkte):**
- **Zeitlords Privileg**: Bei unter 15 Sekunden Restzeit: +25% Effektivität aller defensiven Karten und -25% Zeitkosten. *(erfordert 2 Stufe-3-Knoten)*

#### 3.3.3 Wächtermeisterschaft (Zeitwächter)

*Spezialisiert auf Schildmacht und den Schild-Schwert-Zyklus.*

**Stufe 1 (Einstiegspunkte, jeweils 1 Punkt):**
- **Energiereserve**: +10% erhöhte maximale Schildmacht (von 5 auf 5,5 abgerundet).
- **Zyklusverstärkung**: +5% verstärkte Boni für den Schild-Schwert-Zyklus.
- **Vorwärtsdrang**: +10% Dauer für den "Nächste Angriffskarte verstärkt"-Effekt nach einem Block.

**Stufe 2 (benötigen 1-2 Punkte in vorherigen Knoten, jeweils 2 Punkte):**
- **Energetische Blockade**: Jeder erfolgreiche Block mit 4+ Schildmacht generiert zusätzliche 0,5 Schildmacht. *(erfordert Energiereserve)*
- **Verstärkter Zyklus**: Die Verteidigung→Angriff-Verstärkung im Zyklus erhöht den Schaden um +25% statt +20%. *(erfordert Zyklusverstärkung)*
- **Defensiver Konter**: Nach einem erfolgreichen Block mit 0 verfügbaren Angriffskarten ziehe eine Angriffskarte. *(erfordert Vorwärtsdrang)*

**Stufe 3 (benötigen 3-4 Punkte in vorherigen Knoten, jeweils 3 Punkte):**
- **Energetischer Ausbruch**: Der Bruch-Effekt bei 5 Schildmacht hat 20% Chance, keine Energie zu verbrauchen. *(erfordert Energetische Blockade)*
- **Kettenreaktion**: Nach erfolgreichem Abschluss eines Verteidigung→Angriff→Verteidigung-Zyklus: Ziehe 1 Karte. *(erfordert Verstärkter Zyklus)*
- **Konter-Spezialist**: Die Vergeltungsmechanik (Stufe 20) gewährt zusätzlich +0,5s Zeitgewinn pro Angriff nach einem Block. *(erfordert Defensiver Konter)*

**Stufe 4 (Kapazitäts-Knoten, jeweils 5 Punkte):**
- **Zeitlicher Wächter-Erwacht**: Bei 5 Schildmacht und einem erfolgreichen Block: Bruch-Effekt verursacht zusätzlich 0,5s Zeitstillstand für alle Gegner. *(erfordert 2 Stufe-3-Knoten)*

### 3.4 Schattenschreiter-Meisterschaftsbäume

#### 3.4.1 Elementarmeisterschaft (Schattenschreiter)

*Fokussiert auf Elementare Verstärkung und DoT-Effekte.*

**Stufe 1 (Einstiegspunkte, jeweils 1 Punkt):**
- **Elementare Präzision**: +5% kritische Trefferchance mit Elementarzaubern.
- **Elementare Infiltration**: +10% Effektdauer für alle elementaren DoTs.
- **Elementare Geschwindigkeit**: -0,1s Zeitkosten für elementare Angriffskarten.

**Stufe 2 (benötigen 1-2 Punkte in vorherigen Knoten, jeweils 2 Punkte):**
- **Flammende Klingen**: Feuer-Angriffe haben 15% Chance, einen zusätzlichen DoT-Tick zu verursachen. *(erfordert Elementare Präzision)*
- **Frostschneide**: Eis-Angriffe mit Slow-Effekt verlangsamen um zusätzliche 10%. *(erfordert Elementare Infiltration)*
- **Zackige Klinge**: Blitz-Angriffe haben 15% Chance, 1 zusätzliches Momentum zu generieren. *(erfordert Elementare Geschwindigkeit)*

**Stufe 3 (benötigen 3-4 Punkte in vorherigen Knoten, jeweils 3 Punkte):**
- **Brennende Schatten**: Bei 4+ Momentum fügen Feuer-Angriffe +2 DoT hinzu (Schwach). *(erfordert Flammende Klingen)*
- **Eisige Schatten**: Bei 4+ Momentum verlängern Eis-Angriffe ihre Effektdauer um 0,5s. *(erfordert Frostschneide)*
- **Blitzschatten**: Bei 4+ Momentum haben Blitz-Angriffe 25% Chance, kein Momentum zu verbrauchen. *(erfordert Zackige Klinge)*

**Stufe 4 (Kapazitäts-Knoten, jeweils 5 Punkte):**
- **Elementarsturm**: Während des Schattenrausch (Bruch) bei 5 Momentum erhalten alle Elementarangriffe +20% erhöhten Schaden zusätzlich zum Basissbonus. *(erfordert 2 Stufe-3-Knoten)*

#### 3.4.2 Zeitmeisterschaft (Schattenschreiter)

*Verbessert Zeitdiebstahl und -manipulation.*

**Stufe 1 (Einstiegspunkte, jeweils 1 Punkt):**
- **Zeitexperte**: -5% Zeitkosten für alle Karten.
- **Diebeskunst**: +10% erhöhte Effektivität für Zeitdiebstahl-Effekte.
- **Chrono-Effizienz**: +0,1s Zeitgewinn für jedes generierte Momentum.

**Stufe 2 (benötigen 1-2 Punkte in vorherigen Knoten, jeweils 2 Punkte):**
- **Schneller Dolch**: -15% Zeitkosten für Karten, die 1,5s oder weniger kosten. *(erfordert Zeitexperte)*
- **Chrono-Plünderung**: Zeitdiebstahl-Effekte haben 10% Chance, ihre Effektivität zu verdoppeln. *(erfordert Diebeskunst)*
- **Momentum-Gleiter**: Beim Erreichen von 5 Momentum wird zusätzlich 0,5s Zeit gewonnen. *(erfordert Chrono-Effizienz)*

**Stufe 3 (benötigen 3-4 Punkte in vorherigen Knoten, jeweils 3 Punkte):**
- **Blitzangriff**: Nach drei 0-Kosten-Karten in Folge kostet die nächste Karte ebenfalls 0 Zeit. *(erfordert Schneller Dolch)*
- **Dieb der Ewigkeit**: Wenn Zeitdiebstahl einen Gegner auf 0 Zeit reduziert, gewinne +1,0s Bonus-Zeit. *(erfordert Chrono-Plünderung)*
- **Zeitstrom-Navigation**: Bei 4+ Momentum generieren Zeitdiebstahl-Effekte +10% mehr Zeit. *(erfordert Momentum-Gleiter)*

**Stufe 4 (Kapazitäts-Knoten, jeweils 5 Punkte):**
- **Meister-Chronokleptomane**: Beim Spielen von 3 Karten innerhalb von 1,0s besteht eine 25% Chance, 2,0s Zeit zu stehlen. *(erfordert 2 Stufe-3-Knoten)*

#### 3.4.3 Schattenmeisterschaft (Schattenschreiter)

*Spezialisiert auf das Momentum-System und Schattensynergien.*

**Stufe 1 (Einstiegspunkte, jeweils 1 Punkt):**
- **Momentum-Meister**: +10% längere Momentum-Haltbarkeit (kumulativ mit dem Klassenstufe-15-Bonus).
- **Verbesserte Schatten**: +15% Effektivität für alle Schattenkarten.
- **Schatteneffekt**: +0,5s verlängerte Dauer für die Schattensynergie-Effekte.

**Stufe 2 (benötigen 1-2 Punkte in vorherigen Knoten, jeweils 2 Punkte):**
- **Momentum-Konservierung**: 15% Chance, beim Ausspielen einer Karte kein Momentum zu verbrauchen. *(erfordert Momentum-Meister)*
- **Beschleunigte Schatten**: Schattenkarten haben eine 15% Chance, ein zusätzliches Momentum zu generieren. *(erfordert Verbesserte Schatten)*
- **Synergiekette**: Wenn eine durch Schattensynergie kostenlose Karte gespielt wird, besteht eine 15% Chance, die Synergie zu erneuern. *(erfordert Schatteneffekt)*

**Stufe 3 (benötigen 3-4 Punkte in vorherigen Knoten, jeweils 3 Punkte):**
- **Schattenrausch-Meister**: Der Schattenrausch (Bruch) bei 5 Momentum gewährt +5% zusätzliche Effektivität (insgesamt +30%). *(erfordert Momentum-Konservierung)*
- **Schattenwanderer**: Schattenkarten mit 0 Kosten durch Momentum 3+ verbrauchen nur 1 statt 2 Momentum. *(erfordert Beschleunigte Schatten)*
- **Synergiemeister**: Die verbesserte Schattensynergie (Stufe 10) betrifft zusätzlich die nächste Zeitdiebstahl-Karte. *(erfordert Synergiekette)*

**Stufe 4 (Kapazitäts-Knoten, jeweils 5 Punkte):**
- **Ewiger Schatten**: Bei 5 Momentum: 25% Chance, dass der Schattenrausch (Bruch) das Momentum nicht zurücksetzt, sondern auf 3 reduziert. *(erfordert 2 Stufe-3-Knoten)*

### 3.5 UI und Implementierungshinweise

#### 3.5.1 UI-Elemente
- **Meisterschaftspunkte-Anzeige**: In der Spielercharakterübersicht, zeigt verfügbare und ausgegebene Punkte
- **Meisterschaftsbaum-Bildschirm**: Zugang über Charakterbildschirm, zeigt alle drei Bäume mit visuellen Verbindungen
- **Knoten-UI**: Zeigt aktuellen Status (verfügbar/aktiviert/gesperrt), Kosten, Beschreibung und Voraussetzungen
- **Effekt-Anzeigen**: Aktive Meisterschaftseffekte werden durch subtile UI-Elemente im Kampf signalisiert
- **Fortschrittsanzeige**: Visualisierung der Sammlung virtueller "Level-Ups" nach Klassenstufe 25

#### 3.5.2 Spielersperre und Zurücksetzung
- **Punkt-Vergabe**: Einmal ausgegebene Punkte sind permanent, aber...
- **Zurücksetzungs-Option**: Für Premium-Währung (z.B. 100 Zeitkristalle) oder sehr seltene Spielressourcen (z.B. "Essenz des Neubeginns") können Meisterschaftspunkte zurückgesetzt werden
- **Teil-Zurücksetzung**: Option, nur einen einzelnen Baum zurückzusetzen, zu geringeren Kosten

#### 3.5.3 Balancing-Hinweise
- **Schrittweises Wachstum**: Die meisten numerischen Werte sind bewusst klein gehalten (5-15%), um kumulatives Wachstum zu kontrollieren
- **Anti-Stagnation**: Jede Klasse hat mehrere gleichwertige Pfade, um Spielerzwang zu einem bestimmten Build zu vermeiden
- **Synergie mit Zenit**: Meisterschaftseffekte sollten mit dem Zenit-System komplementär wirken, nicht multiplikativ
- **Strategisches Ziel**: 85-90% der Spielstärke sollte durch Karten, Evolution und Aufwertung kommen, 10-15% durch Meisterschaft

## 4. Zusammenfassung und Entwicklungsempfehlungen

### 4.1 Entwicklungspriorität
1. **Klassenstufen-Boni (Stufen 5, 10, 15, 20, 25)**: Diese sind sofort spielrelevant und beeinflussen die Progression kontinuierlich
2. **Class XP System**: Paralleles Progressionssystem, das früh zur Motivation und Langzeitbindung beiträgt
3. **Meisterschaftssystem**: Endgame-Inhalt, kann schrittweise implementiert werden

### 4.2 Testhierarchie
1. **Numerische Balancetests**: Überprüfung, ob die Boni den Schwierigkeitsgrad angemessen beeinflussen
2. **XP-Kurventests**: Validierung der Progression entsprechend der Pacing-Ziele
3. **Synergietests**: Prüfung der Wechselwirkungen mit anderen Progressionssystemen (Karten, Evolution, Zenit)
4. **Meisterschaftsbaum-Tests**: Validierung verschiedener Build-Pfade und Spielstile

### 4.3 Integration ins bestehende Spiel
- Das Klassenstufen-System sollte visuelle Priorität nach den Karten haben, aber über dem Zenit-System (da früher relevant)
- UI-Anzeige der Klassenstufe sollte prominent neben dem Spielercharakter erscheinen
- Klassenstufenboni sollten durch klare visuelle Effekte und Tutorials erklärt werden
- Die Einführung der Meisterschaft sollte ein besonderes Ereignis nach Erreichen von Stufe 25 sein

Das Klassenstufen- und Meisterschaftssystem fügt eine wichtige langfristige Progression hinzu, die parallel zur Kartenprogression verläuft und globale Spielerverbesserungen bietet, die unabhängig vom aktuellen Deck wirken, wodurch die strategische Tiefe des Spiels erweitert wird.