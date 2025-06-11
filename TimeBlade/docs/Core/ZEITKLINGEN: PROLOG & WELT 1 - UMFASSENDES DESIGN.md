# 🎮 ZEITKLINGEN: PROLOG & WELT 1 - UMFASSENDES DESIGN

## TEIL 1: DESIGN VON PROLOG UND WELT 1

### A. PROLOG: "Das Erwachen der Zeit"

**Thematische Ausrichtung:** Der Spieler erwacht als Zeit-Manipulator ohne Erinnerungen. Die Zeit selbst ist instabil - Fragmente der Vergangenheit und Zukunft kollidieren. Der Prolog lehrt die Grundmechaniken durch diese temporalen Anomalien.

#### **Kapitel 1: "Zeitriss" (5-10 Minuten)**

**Narrative Einbettung:** Du erwachst in einem kollabierten Zeitriss. Die ersten temporalen Echos greifen an - sie sind schwach, aber lehren die Grundlagen.

**Quest-Konzept:**
- Überlebe deinen ersten Rift (90 Sekunden statt 180 - Tutorial-Rift)
- Sammle 10 Rift-Punkte (Tutorial-Anpassung)
- Lerne die Basis-Mechaniken: Karte spielen = Zeit vergeht

**Gegner-Einführung:**

##### 🕐 **Zeit-Echo** (Prolog-Gegner #1)
- **Visuelle Beschreibung:** Transparente, flackernde Kopie eines Humanoiden, ständig zwischen verschiedenen Zeitpunkten phasenverschiebend
- **Verhalten & Fähigkeiten:**
  - Einfacher Nahkampfangriff alle 8 Sekunden (extra langsam für Tutorial)
  - Keine Spezialfähigkeiten
  - Timeline-Anzeige: Einfacher roter Marker
- **Lernziel:** Basis-Kampf, Karten ausspielen, Zeitkosten verstehen
- **Rift-Punkte:** 5
- **Tutorial-Garantie:** Erster Rift spawnt IMMER genau 2 identische Zeit-Echos, keine Variationen
- **Klassen-Balance:**
  - Zeitwächter: Perfekt für erste Block-Übungen
  - Schattenschreiter: Einfaches Momentum-Aufbauen
  - Chronomant: Sichere Arkanpuls-Generierung

#### **Kapitel 2: "Temporale Instabilität" (10-15 Minuten)**

**Quest-Konzept:**
- Meistere einen vollen 180-Sekunden-Rift
- Sammle 20 Rift-Punkte (Tutorial-Anpassung)
- Lerne verschiedene Gegnertypen zu priorisieren

**Neue Gegner:**

##### ⏰ **Chrono-Welpe** (Prolog-Gegner #2)
- **Visuelle Beschreibung:** Kleines, hundeähnliches Wesen aus purer Zeitenergie, pulsiert in verschiedenen Farben
- **Verhalten & Fähigkeiten:**
  - Schnelle Zeitkosten-Erhöhung alle 3 Sekunden (+0.3s auf nächste Karte)
  - **Zeitknabbern**: Nach 2 Erhöhungen stiehlt er 1 Sekunde Zeit
  - Timeline: Gelber Marker für Zeitdiebstahl nach jeder 2. Erhöhung
- **Lernziel:** Zeitdiebstahl-Mechanik, Prioritätensetzung
- **Rift-Punkte:** 12
- **Klassen-Balance:**
  - Zeitwächter: Muss Blocks timen für Zeitdiebstahl-Schutz
  - Schattenschreiter: Schnell töten bevor Zeitdiebstahl
  - Chronomant: Kann mit Verzögerung kontern

**Tutorial-Setup:** Zweiter Rift spawnt IMMER:
- 2× Zeit-Echo (gleiche Stats wie Kapitel 1)
- 1× Chrono-Welpe
- **Keine anderen Gegner-Variationen im Tutorial-Rift!**

#### **Kapitel 3: "Der Erste Wächter" (15-20 Minuten)**

**Quest-Konzept:**
- Besiege den Prolog-Boss
- Überlebe mit mindestens 30 Sekunden Restzeit
- Verdiene deine erste Klassen-Karte

**Boss-Einführung:**

##### 👑 **Proto-Zeitwächter** (Prolog-Boss)
- **Visuelle Beschreibung:** Imposante Rüstung aus kristallisierter Zeit, trägt ein zerbrochenes Zeitschwert
- **Verhalten & Fähigkeiten:**
  - **Phase 1 (100-60% HP):**
    - Schwertschlag alle 4 Sekunden (Schaden: niedrig)
    - **Zeitschild**: Blockt jeden 3. Angriff
  - **Phase 2 (60-30% HP):**
    - Schwertschlag wird schneller (alle 3 Sekunden)
    - **Temporaler Stoß**: Große Attacke mit 3s Vorwarnung, stiehlt 3s Zeit
  - **Phase 3 (30-0% HP):**
    - **Verzweiflungsmodus**: Alle Angriffe 25% schneller
    - Kein Zeitschild mehr
- **Lernziel:** Boss-Phasen, große Angriffe ausweichen/blocken, Ausdauer
- **Rift-Punkte:** N/A (Boss-Spawn bei 50 Punkten im Prolog)
- **Klassen-Balance:**
  - Zeitwächter: Vorteil durch Block-Mechanik gegen Temporalen Stoß
  - Schattenschreiter: Muss Momentum für Phase 3 aufsparen
  - Chronomant: Kann mit Verzögerung den Stoß hinauszögern

**Belohnungen:** Erste klassenspezifische Karte + Zugang zu Welt 1

### ⛔️ Mathematische Herausforderung: Chrono-Konstrukt
- **Gesamt-HP**: 20
- **Benötigte Karten**: ~8-10 (je nach Klasse)
- **Zeitbudget**: 35-45s von 180s
- **Zeitverlust durch Boss**: Max 2s (1× Temporaler Stoß)
- **Schwierigkeit**: Tutorial-gerecht (unmöglich zu scheitern)

---

### NEUE MECHANIK-DEFINITION: "Rudel als Schild"-System & AoE-Interaktionen

#### Grundprinzipien:
1. **Kein manuelles Targeting:** Spieler können keine individuellen Rudel-Mitglieder auswählen
2. **Automatisches Ziel:** Immer das vorderste (aktive) Mitglied
3. **Visuelle Klarheit:** Haupt-Sprite + Schild-Sphären darunter

#### AoE-Mechanik-Integration (gemäß ZK-MECHANIKEN.md):
- **Basis-Definition:** "Flächenschaden trifft immer das primäre Ziel und bis zu 2 weitere zufällige Ziele"
- **Rudel-Anpassung:** Bei Rudeln werden die "weiteren Ziele" als die nächsten Schild-Sphären interpretiert
- **Beispiel:** AoE-Angriff gegen 4er-Rudel trifft:
  - Vorderstes Mitglied: 100% Schaden
  - Nächste 2 Sphären: Je 50% Schaden (gemäß Basis-AoE-Regel)
  - 4. Mitglied: Kein Schaden (AoE-Limit erreicht)

#### Durchbruchschaden bei Rudeln:
- **Definition:** 50% des Überschussschadens geht auf nächstes Mitglied
- **Beispiel:** 10 Schaden gegen 3-HP-Ziel = 3 verbraucht, 3.5 Schaden (50% von 7) auf nächstes
- **Synergie mit AoE:** Durchbruch wirkt pro getroffenem Ziel separat

#### Kettenschaden bei Rudeln:
- **Sequenziell:** Springt von aktuellem Ziel zum nächsten
- **Reduzierung:** 60% → 40% → 20% Schaden
- **Rudel-Spezial:** Kann innerhalb des Rudels springen ODER zu anderen Gegnern

---

### B. WELT 1: "Das Zeitlose Tal"

**Thematische Ausrichtung:** Ein Tal, in dem die Zeit stillsteht - aber nicht überall gleichzeitig. Manche Bereiche sind in Zeitschleifen gefangen, andere altern in Sekunden. Die Bewohner sind temporal korrumpiert.

**WICHTIG: Standard-Rift-Mechanik**
- **Alle Standard-Rifts:** 100 Rift-Punkte für Boss-Spawn
- **Quest-Ziele:** Sind üBERGEORDNETE Ziele (z.B. "Sammle 300 Punkte insgesamt")
- **Story-Rifts:** Können abweichende Punktziele haben (explizit markiert)

#### **Kapitel 1: "Ankunft im Stillstand" (30-45 Minuten)**

**Quest-Konzept:**
- Erkunde 3 verschiedene Zeitblasen (3 Standard-Rifts)
- Sammle 300 Rift-Punkte INSGESAMT über alle Rifts (Quest-Ziel)
- Jeder einzelne Rift: Standard 100 Punkte für Boss-Spawn
- Lerne die Zeitanomalie-Mechanik

**Neue Gegner (3):**

##### 🛡️ **Zeitschleifer-Rudel** (W1-Gegner #1) 
[NEUE MECHANIK: "Rudel als Schild"-System]
- **Visuelle Beschreibung:** Gruppe von 2-4 humanoiden Wesen mit Zeitkristall-Rüstungen
- **Rudel-Darstellung:**
  - **Haupt-Modell:** Ein sichtbarer Zeitschleifer repräsentiert das ganze Rudel
  - **Schild-Sphären:** Kleine leuchtende Kugeln unterhalb des Haupt-Sprites (1 pro zusätzlichem Mitglied)
  - **HP-Anzeige:** "15 HP ×3 (45)" - zeigt Einzel-HP und Gesamt-HP
- **Verhalten & Fähigkeiten:**
  - **Synchron-Angriff:** Alle 5s, erhöht Kartenkosten um +0.2s × Anzahl lebender Mitglieder
  - **Zeitschleifung:** Bei Synchron-Angriff zusätzlich +0.3s auf nächste 2 Karten
  - **Rudel-Koordination:** Greifen immer gleichzeitig an
- **Rudel-Mechaniken:**
  - **Automatisches Targeting:** Spieler trifft IMMER das vorderste (aktive) Mitglied
  - **Durchbruchschaden:** 50% Überschussschaden geht auf nächstes Mitglied
  - **AoE-Interaktion:** Flächenschaden trifft ALLE Mitglieder für vollen Schaden
  - **DoT-Interaktion:** Wirkt nur auf aktuell fokussiertes Mitglied
- **Lernziel:** Rudel-System verstehen, AoE-Vorteile erkennen
- **Rift-Punkte:** 8 pro Mitglied
- **Klassen-Balance:**
  - Zeitwächter: Schildbruch (5 SM) perfekt gegen Rudel
  - Schattenschreiter: Kettenschaden-Karten werden wichtig
  - Chronomant: Elementar-AoE glänzt

##### ⏸️ **Erstarrter Wanderer** (W1-Gegner #2)
- **Visuelle Beschreibung:** Humanoid, halb in der Zeit eingefroren, bewegt sich ruckartig
- **Verhalten & Fähigkeiten:**
  - Langsame, aber harte Schläge alle 6 Sekunden
  - **Zeitstarre**: Immun gegen Verlangsamung/Verzögerung
  - **Auftauen**: Bei 50% HP wird er schneller (4s Angriffe)
- **Lernziel:** Nicht alle Gegner können verzögert werden
- **Rift-Punkte:** 15
- **Klassen-Balance:**
  - Zeitwächter: Starke Defensive nötig
  - Schattenschreiter: Perfekt für Burst-Damage
  - Chronomant: Muss auf Direktschaden setzen

##### ⏩ **Beschleunigter Sprite** (W1-Gegner #2)
- **Visuelle Beschreibung:** Kleines, vogelartiges Wesen, flackert zwischen Positionen
- **Verhalten & Fähigkeiten:**
  - Sehr schnelle, schwache Angriffe alle 2 Sekunden
  - **Zeitsprung**: Alle 10s teleportiert er und stiehlt 0.5s
  - Nimmt doppelten Schaden von AoE
- **Lernziel:** Schnelle Gegner, AoE-Vorteil
- **Rift-Punkte:** 12
- **Klassen-Balance:**
  - Alle frühen AoE-Karten sind effektiv

##### 🔄 **Schleifenfänger** (W1-Gegner #3)
- **Visuelle Beschreibung:** Tentakelwesen aus reiner Zeitenergie, pulsiert rhythmisch
- **Verhalten & Fähigkeiten:**
  - **Zeitschleife**: Fängt die letzte gespielte Karte - sie kostet nochmal 50% Zeit
  - Angriff alle 5 Sekunden
  - Stirbt nach 3 gefangenen Karten automatisch
- **Lernziel:** Kartenauswahl-Strategie, billige Karten opfern
- **Rift-Punkte:** 18
- **Klassen-Balance:**
  - Besonders gemein für Schattenschreiter (0-Zeit-Karten trotzdem betroffen)

**Bekannte Gegner:** Zeit-Echo (aus Prolog), leicht verstärkt

#### **Kapitel 2: "Die Zeitfresser-Kolonie" (45-60 Minuten)**

**Quest-Konzept:**
- Zerstöre 3 Zeitfresser-Nester
- Überlebe Schwarm-Angriffe
- Meistere Multi-Gegner-Situationen

**Neue Gegner (3):**

##### 🦗 **Zeitfresser-Drohnen-Schwarm** (W1-Gegner #4)
[RUDEL-VARIANTE: Schwarm-Formation]
- **Visuelle Beschreibung:** Insektenartige Kreaturen mit durchscheinenden Flügeln
- **Rudel-Darstellung:**
  - **Schwarm-Formation:** 3-5 Drohnen bilden einen Schwarm
  - **Visuelle Darstellung:** Haupt-Drohne vorne, andere als kleinere Sphären dahinter
  - **HP-Anzeige:** "8 HP ×4 (32)" bei 4er-Schwarm
- **Verhalten & Fähigkeiten:**
  - **Schwarm-Angriff:** Alle 4s, Basis-Schaden 1 + 0.5 pro lebendem Mitglied
  - **Schwarm-Synergie:** Geschwindigkeit +10% pro lebendem Mitglied
  - **Zerstreuung:** Bei Tod des letzten Mitglieds kleine Zeitexplosion (-0.5s)
- **Rudel-Mechaniken:**
  - **Identisch zum Basis-System:** Automatisches Targeting auf vorderste Drohne
  - **Schwarm-Spezial:** Bei AoE-Treffer fliehen überlebende Drohnen kurz auseinander (0.5s)
- **Lernziel:** Schwarm-Variante des Rudel-Systems, schnelle Gegner priorisieren
- **Rift-Punkte:** 5 pro Drohne
- **Klassen-Balance:**
  - Zeitwächter: Schildbruch bei 5 SM perfekt für Schwärme
  - Schattenschreiter: Kettenschaden-Karten glänzen
  - Chronomant: Elementar-AoE wird wichtig

##### 🐛 **Zeitfresser-Wächter** (W1-Elite #1)
- **Visuelle Beschreibung:** Große Insekten-Kreatur, gepanzert mit Zeitkristallen
- **Verhalten & Fähigkeiten:**
  - Starker Angriff alle 5 Sekunden
  - **Nest-Ruf**: Spawnt 2 Drohnen wenn er unter 50% HP fällt
  - **Zeitpanzer**: Erste 3 Angriffe machen -50% Schaden
- **Lernziel:** Elite-Gegner Konzept, Rüstung durchbrechen
- **Rift-Punkte:** 25
- **Klassen-Balance:**
  - Multi-Hit-Karten brechen Panzer schneller

##### ⏱️ **Temporaler Parasit** (W1-Gegner #5) 
*[Basierend auf meinem Playtest-Feedback]*
- **Visuelle Beschreibung:** Wurmartige Kreatur die sich an die Timeline heftet
- **Verhalten & Fähigkeiten:**
  - Kein direkter Schaden
  - **Zeit-Drain**: Alle Karten kosten +0.3s mehr
  - **Festklammern**: Nach 15s verdoppelt sich der Drain
  - Nur 8 HP
- **Lernziel:** Prioritäts-Ziele, Zeitmanagement
- **Rift-Punkte:** 20
- **Klassen-Balance:**
  - Muss schnell fokussiert werden von allen

**Bekannte Gegner:** Chrono-Welpe, Beschleunigter Sprite (passen thematisch zu Schwärmen)

#### **Kapitel 3: "Der Verzerrte Marktplatz" (60-75 Minuten)**

**Quest-Konzept:**
- Befreie 5 zeitgefangene Händler
- Meistere Rift-Modifikatoren (erste Einführung)
- Sammle 500 Punkte in einem einzigen Rift

**Neue Gegner (2):**

##### 💰 **Zeit-Händler** (W1-Gegner #6)
- **Visuelle Beschreibung:** Korrumpierter Händler mit Zeittaschen voller instabiler Energie
- **Verhalten & Fähigkeiten:**
  - **Zeithandel**: Bietet Deal an - 5s Zeit für 20 Rift-Punkte (kann angenommen/abgelehnt werden)
  - Wird aggressiv wenn abgelehnt (schnelle Angriffe)
  - **Taschenexplosion**: Bei Tod gibt er 2-4s Zeit zurück
- **Lernziel:** Entscheidungs-Mechanik, Risk/Reward
- **Rift-Punkte:** 15 (oder 20 wenn Deal angenommen)
- **Klassen-Balance:**
  - Interessante taktische Entscheidung für alle

##### 🎭 **Doppelgänger** (W1-Gegner #7)
- **Visuelle Beschreibung:** Verzerrte Spiegelung des Spieler-Avatars
- **Verhalten & Fähigkeiten:**
  - **Kopie**: Nutzt eine zufällige Karte aus deinem Deck gegen dich
  - **Spiegelung**: Erlittener Schaden wird zu 25% reflektiert
  - Wird stärker je mehr Karten du upgegradet hast
- **Lernziel:** Eigene Stärken können gegen dich verwendet werden
- **Rift-Punkte:** 22
- **Klassen-Balance:**
  - Zeigt Spielern ihre eigenen Karten aus Gegnerperspektive

**Bekannte Gegner:** Erstarrter Wanderer, Schleifenfänger, Zeit-Echo (für Variety)#### **Kapitel 4: "Die Zerrissenen Ruinen" (75-90 Minuten)**

**Quest-Konzept:**
- Navigiere durch zeitlich instabile Ruinen
- Meistere deinen ersten "Chrono-Sturm" (spezielles Event)
- Besiege einen Mini-Boss

**Neue Gegner (2):**

##### 🏛️ **Ruinen-Wächter** (W1-Elite #2)
- **Visuelle Beschreibung:** Massive Steinstatue, teilweise von Zeit zerfressen, Augen glühen temporal
- **Verhalten & Fähigkeiten:**
  - Langsame, vernichtende Schläge alle 7 Sekunden
  - **Zeitriss-Schlag**: Bei 75%, 50%, 25% HP - massiver AoE, 3s Vorwarnung
  - **Antike Resistenz**: -20% Schaden von Karten unter Level 3
  - **Zusammenbruch**: Bei 0 HP explodiert er, gibt aber 5s Zeit zurück
- **Lernziel:** Mini-Boss-Mechaniken, Positionierung, Karten-Level matters
- **Rift-Punkte:** 40
- **Klassen-Balance:**
  - Zeitwächter: Blocks crucial für Zeitriss-Schläge
  - Schattenschreiter: Muss zwischen Angriffen maximalen Schaden machen
  - Chronomant: Verzögerung kann Zeitriss-Schläge hinauszögern

##### ⚡ **Chrono-Sturm Elementar** (W1-Gegner #8)
- **Visuelle Beschreibung:** Wirbelnde Masse aus Blitzen und Zeitenergie
- **Verhalten & Fähigkeiten:**
  - **Sturm-Aura**: Alle 3s verlieren alle Einheiten (auch Spieler) 0.5s Zeit
  - **Blitzschlag**: Gezielter Angriff alle 4s
  - **Instabilität**: Bei Tod löst er einen Zeitrückfluss aus (+3s für Spieler)
- **Lernziel:** Umgebungseffekte, schnelles Handeln erforderlich
- **Rift-Punkte:** 20
- **Klassen-Balance:**
  - Alle Klassen müssen schnell handeln

**Bekannte Gegner:** Zeitfresser-Wächter, Doppelgänger, Temporaler Parasit (gefährliche Kombination!)

#### **Kapitel 5: "Das Herz der Stille" (90-120 Minuten)**

**Quest-Konzept:**
- Bereite dich auf den Weltboss vor
- Sammle 3 Zeitkern-Fragmente in speziellen Herausforderungs-Rifts
- Stelle dich dem Stillen Bewahrer

**Neue Gegner (1):**

##### 🌟 **Zeitkern-Wächter** (W1-Elite #3)
- **Visuelle Beschreibung:** Schwebender Kristall-Golem, pulsiert mit reiner Zeitenergie
- **Verhalten & Fähigkeiten:**
  - **Kern-Schild**: Absorbiert erste 20 Schadenspunkte
  - **Zeitpuls**: Alle 6s eine Welle die 1s stiehlt
  - **Kern-Überladung**: Bei 25% HP verdoppelt sich Angriffsgeschwindigkeit
  - **Fragment-Drop**: Garantiertes Zeitkern-Fragment bei Sieg
- **Lernziel:** Vorbereitung auf Boss-Mechaniken
- **Rift-Punkte:** 50
- **Klassen-Balance:**
  - Designed als faire Herausforderung für alle

**Bekannte Gegner:** Mix aus allen vorherigen Gegnern der Welt

#### **WELT-BOSS: Der Stille Bewahrer**

##### 🕰️ **Der Stille Bewahrer** (Welt 1 Boss)
- **Visuelle Beschreibung:** Gigantische Gestalt aus kristallisierter Zeit, schwebt über einem eingefrorenen Uhrenturm. Mehrere Zeiger rotieren um seinen Körper.

- **Verhalten & Fähigkeiten:**

  **Phase 1: "Die Erste Stunde" (100-70% HP)**
  - **Zeiger-Schlag**: Alle 5s ein mächtiger Angriff mit einem der Uhrzeiger
  - **Zeitstille**: Alle 20s friert er für 2s alle Karteneffekte ein (aber nicht den Timer!)
  - **Tick-Tock**: Rhythmischer Puls der 0.3s Zeit pro Tick stiehlt (alle 10s)

  **Phase 2: "Die Letzte Minute" (70-40% HP)**
  - Zeiger-Schläge werden schneller (alle 3s)
  - **Temporaler Rückfluss**: Heilt sich um den Schaden der letzten 3s (alle 30s)
  - **Beschleunigung**: Der Rift-Timer läuft 25% schneller!
  - Spawnt Zeit-Echos als Ablenkung

  **Phase 3: "Mitternacht" (40-0% HP)**
  - **GONG!**: Massive AoE-Attacke alle 15s (5s Vorwarnung durch Glockenläuten)
  - **Verzweifelte Stille**: Versucht den Timer komplett anzuhalten (muss durch Schaden unterbrochen werden)
  - Alle vorherigen Mechaniken aktiv
  - **Zeit-Kollaps**: Bei 0 HP gibt er 30s Zeit zurück als Belohnung!

- **Lernziel:** Erster "echter" Boss, Phasen-Management, Ressourcen einteilen
- **Rift-Punkte:** N/A (Spawnt bei 100 Punkten)

- **Klassen-spezifische Strategien:**
  - **Zeitwächter**: Schildbruch timing für GONG! kritisch, Defensive in Phase 2
  - **Schattenschreiter**: Momentum für Phase 3 aufsparen, Burst zwischen Heilungen
  - **Chronomant**: Kann mit Verzögerung den Rückfluss manipulieren

- **Belohnungen:** 
  - Garantierte seltene Materialien
  - Neue Karte für jede Klasse
  - Freischaltung von Welt 2
  - Titel: "Bewahrer der Zeit"

### ⛔️ Mathematische Herausforderung: Der Stille Bewahrer
- **Gesamt-HP**: 80 (Normal) / 110 (Heroisch) / 140 (Legendär)
- **Benötigte Karten**: ~28-35 (bei 2.5-3 DPS)
- **Zeitbudget**: 70-100s von 180s
- **Zeitverlust durch Boss**: 
  - Phase 1: ~3-5s (Tick-Tock)
  - Phase 2: +25% schnellerer Timer
  - Phase 3: ~5-15s (GONG!-Attacken)
- **Zeitgewinn bei Sieg**: +30s zurück
- **Schwierigkeit**: Erster echter Boss-Test

---

## TEIL 2: KONZEPTIONELLER PLAYTEST UND ITERATION

### Simulierter Playtest - Neue Spieler-Perspektive

Ich spiele nun mental durch die entworfenen Inhalte aus Sicht eines brandneuen Spielers für jede Klasse:

#### **Zeitwächter-Playtest:**

**Prolog:**
- ✅ Zeit-Echos sind perfekt zum Block-Training
- ✅ Chrono-Welpe lehrt Timing-Wichtigkeit
- ⚠️ Proto-Zeitwächter könnte zu ähnlich zur Spielerklasse sein

**Welt 1:**
- ✅ Erstarrte Wanderer fordern defensive Spielweise
- ✅ Schwarm-Situationen machen Schildbruch wertvoll
- ⚠️ Kapitel 3 (Marktplatz) könnte zu leicht sein
- ❌ Chrono-Sturm Elementar + Parasit Combo ist zu hart!

**Boss:**
- ✅ GONG!-Mechanik perfekt für Block-Training
- ⚠️ Phase 2 Heilung könnte frustrieren

#### **Schattenschreiter-Playtest:**

**Prolog:**
- ✅ Schnelles Momentum-Building gegen Echos
- ⚠️ Instabiler Zeitwirbel nervt wegen Kartenkosten
- ✅ Boss Phase 3 macht mit Momentum Spaß

**Welt 1:**
- ✅ Sprite-Jagd macht Spaß
- ✅ Schwärme perfekt für Ketten-Schaden
- ❌ Schleifenfänger zu brutal für 0-Zeit-Karten!
- ✅ Zeit-Händler Risk/Reward passt zur Klasse

**Boss:**
- ⚠️ Keine guten Fenster für Burst in Phase 2
- ✅ Phase 3 Chaos passt zum Spielstil

#### **Chronomant-Playtest:**

**Prolog:**
- ✅ Arkanpuls-Aufbau smooth
- ✅ Verzögerung gegen Chrono-Welpe satisfying
- ✅ Boss gibt Zeit für Elementar-Combos

**Welt 1:**
- ⚠️ Zu wenig Elementar-Resistenz-Variety
- ✅ Parasit + andere Gegner = interessante Puzzles
- ✅ Doppelgänger zeigt eigene Macht
- ❌ Kapitel 4 Ruinen-Wächter zu hart ohne Level 5+ Karten

**Boss:**
- ✅ Viele Möglichkeiten für clevere Plays
- ✅ Balance zwischen Phasen gut

### Identifizierte Probleme:

1. **Schleifenfänger zu hart für Schattenschreiter**
2. **Chrono-Sturm + Parasit Combo zu oppressiv**
3. **Ruinen-Wächter Resistenz zu früh/stark**
4. **Proto-Zeitwächter zu generisch**
5. **Fehlende Elementar-Variety**
6. **Manche Kapitel-Übergänge zu abrupt**

### Konkrete Anpassungen:

#### **1. Schleifenfänger-Nerf:**
- **Alt:** Fängt letzte Karte für 50% Extrakosten
- **Neu:** Fängt letzte Karte für +0.5s Fixkosten (max 1.5s Extra)
- **Begründung:** Fairer für alle Klassen, besonders Schattenschreiter

#### **2. Gegner-Spawn-Anpassung Kapitel 4:**
- **Entferne:** Gleichzeitiges Spawnen von Sturm-Elementar + Parasit
- **Neue Regel:** Diese beiden spawnen nie zusammen
- **Ergänze:** Warnung vor gefährlichen Kombinationen

#### **3. Ruinen-Wächter-Anpassung:**
- **Alt:** -50% Schaden von Karten unter Level 5
- **Neu:** -30% Schaden von Karten unter Level 3
- **Begründung:** Spieler haben zu diesem Zeitpunkt 3-5 Karten auf Level 3+

#### **4. Proto-Zeitwächter-Redesign:**
- **Neuer Name:** "Chrono-Konstrukt"
- **Neue Mechanik:** Statt Zeitschild → "Zeitecho-Angriff" (kopiert letzten Spielerangriff mit 50% Kraft)
- **Begründung:** Einzigartiger, lehrt über Kartenauswahl

#### **5. Elementar-Gegner-Addition (Kapitel 3):**
##### 🔥 **Instabiler Feuerkern** (W1-Gegner #9)
- **Verhalten:** Explodiert nach 10s für massiven Schaden
- **Elementar:** Nimmt doppelten Schaden von Eis
- **Lernziel:** Elementar-Interaktionen
- **Rift-Punkte:** 15

#### **6. Verbesserte Kapitel-Übergänge:**
- **Narrative Brücken:** Kurze Story-Texte zwischen Kapiteln
- **Mechanik-Preview:** Zeige kommende Gegnertypen in sicherer Umgebung
- **Schwierigkeits-Rampe:** Graduellerer Anstieg

### Zusätzliche Verbesserungen:

1. **Tutorial-Rift-Garantien:**
   - Prolog-Rift 1 spawnt IMMER nur Zeit-Echos
   - Keine zufälligen Elite-Spawns vor Kapitel 2

2. **Checkpoint-System:**
   - Nach jedem Kapitel wird Progress gespeichert
   - Spieler können Kapitel wiederholen für Materialien

3. **Adaptive Hints:**
   - Wenn Spieler 3x an gleicher Stelle scheitert → Tipp einblenden
   - Klassen-spezifische Strategiehinweise

4. **Erste-Karte-Garantie:**
   - Prolog-Boss droppt IMMER eine starke Klassenkarte
   - Motiviert zum Weiterspielen

---

## TEIL 3: WELT-RIFT KONZEPT

### "Zeitloses Tal - Ewiger Rift"

Nach Abschluss aller 5 Kapitel wird der Welt-Rift freigeschaltet:

**Funktionsweise:**
- **Endlos-Modus:** Keine Zeitbegrenzung, aber eskalierende Schwierigkeit
- **Wellen-System:** 
  - Welle 1-5: Standard-Gegner (Zeit-Echo bis Sprite)
  - Welle 6-10: + Elite-Gegner
  - Welle 11-15: + Mini-Bosse
  - Welle 16+: Chaos-Modus (alles möglich)
  - Alle 10 Wellen: Bewahrer erscheint als Zwischen-Boss

**Gegner-Pool:** 
- ALLE Gegner aus Prolog + Welt 1
- Gefährliche Kombinationen möglich
- Seltene "Goldene" Varianten mit besseren Drops

**Belohnungs-Struktur:**
- Jede Welle = Materialien
- Alle 5 Wellen = Garantierter Zeitkern
- Alle 10 Wellen = Seltene Materialien
- Highscore-System mit Belohnungen

**Primärer Zweck:**
- 70% Farming (Materialien für Progression)
- 30% Herausforderung (Wie weit kommst du?)
- Perfekt für "noch eine Runde"-Mentalität

---

## TEIL 4: GEGNER-SHARD-MECHANIK [ZURÜCKGESTELLT]

**HINWEIS:** Die Gegner-Shard-Mechanik wird für eine spätere Entwicklungsphase zurückgestellt. Das folgende Konzept dient als Referenz für zukünftige Implementierung.

### Konzeptuelle Integration:

**Grundprinzip:**
- Besiegte Gegner haben 10% Chance einen Shard zu droppen
- 5 Shards eines Gegnertyps = Kann diesen Gegner "aufwerten"
- Aufgewertete Gegner in speziellen "Shard-Rifts"

**Geeignete Gegnertypen:**
- **Standard-Gegner:** Häufigste Shards, moderate Upgrades
- **Elite-Gegner:** Seltene Shards, starke Upgrades
- **Bosse:** Keine Shards (zu mächtig)

**Mögliche Modifikationen durch Shards:**

1. **Tier 1 (Bronze-Shard):**
   - +50% HP
   - +30% Schaden
   - +50% Rift-Punkte
   - Chance auf Bonus-Zeitkern

2. **Tier 2 (Silber-Shard, 10 Bronze kombinieren):**
   - Gegner erhält neue Fähigkeit:
     - Zeit-Echo → Spawnt Kopie bei Tod
     - Sprite → Hinterlässt Beschleunigungs-Feld
     - Parasit → Drain wirkt auf alle Karten
   - +100% Materialien-Drops

3. **Tier 3 (Gold-Shard, 10 Silber kombinieren):**
   - Gegner wird zum "Apex-Predator":
     - Kombiniert Fähigkeiten anderer Gegner
     - Adaptive KI (lernt aus Spielerverhalten)
     - Garantierte seltene Drops
     - Cosmetic Rewards (Titel, Kartenrücken)

**Integration mit anderen Systemen:**
- Shard-Rifts als tägliche Herausforderung
- Sammler-Aspekt für Completionists
- Langzeit-Ziel nach Welt-Abschluss
- Vorbereitung auf schwierigere Welten

**Balance-Überlegungen:**
- Shards sind OPTIONAL - kein Zwang
- Aufgewertete Gegner nur in speziellen Rifts
- Belohnungen proportional zur Herausforderung
- Kein Pay-to-Win (Shards nicht kaufbar)

---

## 🎯 FAZIT

Das Design von Prolog und Welt 1 bietet:

1. **Klare Lernkurve:** Jeder Gegner lehrt spezifische Mechanik
2. **Klassenidentität:** Verschiedene Strategien für jede Klasse
3. **Progression-Gefühl:** Vom schwachen Echo zum epischen Boss
4. **Wiederspielwert:** Welt-Rift und Shard-System
5. **"Noch eine Runde":** 3-Minuten-Rifts mit klaren Zielen

Mit den Iterationen nach dem Playtest sollte das Onboarding:
- **Fesselnd** vom ersten Moment
- **Fair** für alle Klassen
- **Lehrreich** ohne zu tutorialisieren
- **Motivierend** für die lange Reise ahead

Das Spiel würde Spieler von der ersten Sekunde packen und nicht mehr loslassen! 🔥