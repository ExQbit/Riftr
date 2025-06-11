

# Chronomant-Klasse und Karten (ZK-CLASS-MAGE-v2.1-20250522)

## Änderungshistorie

* **v2.1 (2025-05-22):** `Seltene Essenz` vollständig aus Stufe 3 Evolutionskosten entfernt. Alle Evolutionen kosten nun `1x/2x/3x Elementarfragment` für Stufe 1/2/3. Anpassung an `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`.
* **v2.0 (2025-05-22):** Standardisierung der Stufe 3 Evolutionskosten: Alle Stufe 3 Evolutionen (einschließlich Signaturkarten) kosten nun `3x Elementarfragment, 1x Seltene Essenz`. Aktualisierung der Materialliste und Versionsnummer.
* **v1.9 (2025-05-22):** Anpassung an das finale System mit vier Materialtypen (Zeitkern, Elementarfragment, Seltene Essenz, Zeitfokus). 'Sockelstein' und Referenzen auf fünf Materialien entfernt. Alle Evolutionskosten auf 'X x Elementarfragment' standardisiert (Stufe 3 initial ohne Seltene Essenz). Versionsnummer und Änderungsvermerk in Kopfzeile und Abschnitt 4 aktualisiert.
* **v1.8 (2025-05-21):** Integration des vereinfachten Materialsystems mit nur fünf klar definierten Materialtypen (Zeitkern, Elementarfragment, Seltene Essenz, Zeitfokus, Sockelstein). Umstellung auf das "1 Zeitkern = 1 Level"-Prinzip. Anpassung aller Materialkosten für Evolutionen. Entfernung aller Verweise auf veraltete Materialien und XP-System.
* **v1.7.3 (2025-05-19):** Klassenmechanik "Zeitliche Arkankraft" zu "Arkanpuls" umbenannt für bessere Thematik und Mobilfreundlichkeit. Evolutionskartennamen für konsistentere Elementarbezeichnungen optimiert.
* **v1.7.2 (2025-05-10):** Mobile-optimierte Kartennamen eingeführt und Namenskonflikte mit anderen Klassen behoben.
* **v1.7 (2025-05-10):** Entfernung der Mechanik 'Zeitstrom-Resonanz' und Einführung neuer Bonusmechanik für Zeitmanipulations- und Elementarkarten basierend auf Reihenfolge.
* **v1.6 (2025-04-21):** Materialkosten für alle Evolutionen angepasst. Platzhalter entfernt und spezifische Material-IDs und Mengen eingesetzt. Fehlende Abschnitte 9-13 hinzugefügt/wiederhergestellt.
* **v1.5 (2025-04-21):** Einführung der sekundären Mechanik „Zeitstrom-Resonanz“. Anpassung der Zeitlichen Arkankraft (Max 5 Punkte, Blitz-Evo von `Zeitverzerrung` überarbeitet).
* **v1.4 (2025-04-21):** Implementierung von spezifischen Arkankraft-Interaktionen für 4 Schlüsselkarten (`Elementarfokus`, `Arkane Intelligenz`, `Beschleunigen`, `Zeitschild`). Anpassung der Basis-Karteneffekte.
* **v1.3 (2025-04-21):** Implementierung der Kernmechanik "Arkanpuls". Standardisierung auf 3 Elementar-Evolutionspfade. Entfernung der alten Mechaniken "Arkane Vorhersehung" und "Zeitboni-System".
* **v1.2 (2025-04-21):** Reduzierung auf 2 Signaturkarten (`Arkane Intelligenz`, `Zeitverzerrung`). `Elementarfokus` und `Zeitbeben` zu Zeitmanipulationskarten umklassifiziert.
* **v1.1 (2025-04-21):** Kartennamen überarbeitet für Mobile-Freundlichkeit.
* **v1.0 (2025-04-21):** Initiale Zusammenführung von `ZK-CLASS-MAGE-COMP-v1.1-20250327` und `ZK-CLASS-MAGE-CARDS-v1.1-20250327`.

## 1. Einleitung/Zusammenfassung

Dieses Dokument beschreibt die Chronomant-Klasse (MAGE), eine Magier-Klasse, die Zeitmanipulation mit arkaner Macht verbindet. Es umfasst die Klassenidentität, die Kernmechanik "Arkanpuls", die Bonusmechanik durch Kartenreihenfolge, die Spezifikation aller Karten inklusive ihrer Elementar-Evolutionspfade und standardisierten Materialkosten gemäß dem vereinfachten Materialsystem aus `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md` (Zeitkern, Elementarfragment, Zeitfokus), Spielstrategien, UI/UX-Hinweise und Balancing-Anmerkungen.

## 2. Klassenübersicht

### 2.1 Klassenidentität

#### 2.1.1 Designphilosophie

* **Zeitliche Dualität**: Manipulation eigener und gegnerischer Zeit.
* **Strategische Tiefe durch Mechaniken**: Nutzung der „Zeitlichen Arkankraft“ und der Kartenreihenfolge-Boni für dynamische, belohnende Effekte.
* **Eskalierendes Machtwachstum**: Progression durch Karten-Evolution, Arkankraft-Management und Reihenfolge-Boni.

#### 2.1.2 Psychologische Spielermotivation

* **Achiever**: Meistern der Zeitlichen Arkankraft und optimale Nutzung der Kartenreihenfolge-Boni.
* **Explorer**: Entdecken von Synergien durch Kartenreihenfolge.
* **Socializer**: Visuell eindrucksvolle Effekte der Elementarmagie, Arkankraft-Bruchs und Reihenfolge-Boni.
* **Killer**: Technisch anspruchsvolle Kombos durch präzises Timing von Reihenfolge-Boni und Arkanschub-Effekt.

### 2.2 Klassenspezifische Mechaniken

#### 2.2.1 Arkanpuls (Kernmechanik)

Der Chronomant nutzt seine Fähigkeit, Zeit und arkane Magie zu vereinen, um eine Ressource namens „Arkanpuls“ aufzubauen. Diese Kraft verstärkt seine Zauber und Zeitmanipulationen und entlädt sich in einem mächtigen Effekt.

* **Maximum:** **5 Pulsladungen** (fest, nicht modifizierbar).
* **Generierung:**
    * **+1 Ladung** für jede gespielte **Zeitmanipulationskarte**.
    * **+1 Ladung** für jeden **Elementarzauber**, der einen Gegner trifft oder einen Effekt auslöst.
    * *Spezifische Karten können zusätzliche Generierung haben (siehe Abschnitt 4).*
* **Verfall:** Sinkt um **1 Ladung pro Sekunde**, wenn **3 Sekunden** lang keine relevante Karte gespielt wird.
* **Schwellenboni (kumulativ):**
    * **Ab 2 Ladungen:** +10% Schaden für Elementarzauber.
    * **Ab 3 Ladungen:** Zeitkosten von Zeitmanipulationskarten sinken um 0,5 Sekunden.
    * **Ab 4 Ladungen:** +15% Effektivität für Zeitmanipulationskarten.
* **Arkanschub (bei 5 Ladungen):**
    * Beeinflusst die **nächste** gespielte Karte.
    * **Elementarzauber**: +50% Schaden/Effektivität, +0,5s Unterbrechung des Ziels.
    * **Zeitmanipulationskarte**: +100% Effektivität.
    * Arkanpuls wird auf **0** zurückgesetzt.
* **Signaturkarten-Interaktion:** Evolutionen von `Zeitverzerrung` modifizieren den Arkanschub (siehe Abschnitt 4.3.2).
* **Interaktion mit Kartenreihenfolge-Bonus:**
    * **Kartenreihenfolge-Bonus**: Jede Zeitmanipulationskarte verstärkt die nächste Elementarkarte um +20% Schaden. Jede Elementarkarte verstärkt die nächste Zeitmanipulationskarte um +10% Effektivität.

#### 2.2.2 Kartenreihenfolge-Bonus (Bonusmechanik)

Jede Zeitmanipulationskarte verstärkt die nächste Elementarkarte um +20% Schaden. Jede Elementarkarte verstärkt die nächste Zeitmanipulationskarte um +10% Effektivität.

## 3. Deckzusammensetzung (26 Karten)

### 3.1 Kartenverteilung

| Kategorie        | Anzahl im Deck     | Anteil Deck | Zweck                                         | Beispielkarten                                        |
| :--------------- | :----------------- | :---------- | :-------------------------------------------- | :---------------------------------------------------- |
| Basiszauber      | 12 (8+4)           | 46%         | Primäre Schadensquelle, Arkankraft-Gen.        | Arkanblick, Arkanstrahl                               |
| Zeitmanipulation | 12 (3+3+2+2 +1+1) | 46%         | Kontrolle, Effizienz, Arkankraft-Gen./Interaktion | Verzögern, Beschleunigen, Chronowall, Chrono-Ernte, Zauberfokus, Zeitbeben |
| Signaturkarten   | 2 (1+1)            | 8%          | Kernidentität, Spezialeffekte, Kernmechanik-Interaktion | Arkanblick, Zeitverzerrung                      |
| **Gesamt** | **26** | **100%** | -                                             | -                                                     |

### 3.2 Starterdeck (26 Karten) - Aktualisiert

| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| `Arkanblick` | `CARD-MAGE-ARCANEINTELLIGENCE` | 1 | 1,0s | **Legendär** | Ziehe **1 Karte + 1 zusätzliche Karte pro 2 voller Arkanpuls-Ladungen**. *Generiert +1 Arkanpuls-Ladung.* |
| `Arkanstrahl` | `CARD-MAGE-ARCANICRAY` | 4 | 2,0s | **Gewöhnlich** | 5 Schaden. *Generiert +1 Arkanpuls-Ladung bei Treffer.* |
| `Verzögern` | `CARD-MAGE-DELAY` | 3 | 2,0s | **Ungewöhnlich** | Verzögert nächsten Gegnerangriff um 2,0s. *Generiert +1 Arkanpuls-Ladung.* |
| `Beschleunigen` | `CARD-MAGE-ACCELERATE` | 3 | 2,5s | **Selten** | Nächste 2 Karten **-Y Sekunden Kosten**, wobei **Y = 0,5s bei 0-2 Kraft / 1,0s bei 3-4 Kraft / 1,5s bei 5 Kraft**. *Generiert +1 Arkanpuls-Ladung.* |
| `Chronowall` | `CARD-MAGE-CHRONOBARRIER` | 2 | 2,0s | **Ungewöhnlich** | Blockiert nächsten Angriff innerhalb 3,0s. **Bei erfolgreichem Block: +1 zusätzliche Arkanpuls-Ladung.** |
| `Chronoernte` | `CARD-MAGE-TEMPORALRIFTRECOVERY` | 2 | 3,0s | **Selten** | Erhalte +2,0s Zeit, wenn ein Gegner innerhalb von 5,0s stirbt. *Generiert +1 Arkanpuls-Ladung.* |
| `Zauberfokus` | `CARD-MAGE-SPELLFOCUS` | 1 | 2,5s | **Episch** | Nächster Elementarzauber +X% Effektivität, wobei **X = 25 + (5 \* aktuelle Arkanpuls-Ladungen)** (Max +50% bei 5 Ladungen). *Generiert +1 Arkanpuls-Ladung.* |
| `Zeitbeben` | `CARD-MAGE-TIMETREMOR` | 1 | 5,0s | **Episch** | +3,0s Zeit, 10 AoE-Schaden, +1 Karte. *Generiert +1 Arkanpuls-Ladung.* |
| `Arkanblick` | `CARD-MAGE-ARCANEINTELLIGENCE` | 1 | 1,0s | **Legendär** | Ziehe **1 Karte + 1 zusätzliche Karte pro 2 voller Arkanpuls-Ladungen**. *Generiert +1 Arkanpuls-Ladung.* |
| `Zeitverzerrung` | `CARD-MAGE-TIMEWARP` | 1 | 4,0s | **Legendär** | Verlangsamt Ziel um 30% für 3,0s. *Generiert +1 Arkanpuls-Ladung.* |

### 3.3 Progressives Freischaltsystem

Im Einklang mit dem "Progressive Unlock"-Spieldesign werden Chronomant-Karten schrittweise freigeschaltet, wodurch regelmäßige "WOW"-Momente und eine natürliche Lernkurve entstehen:

#### 3.3.1 Starterdeck (Erste Spielminuten, 8 Karten)
- `Arkanblick` (Gewöhnlich): 1 Kopie
- `Arkanstrahl` (Gewöhnlich): 2 Kopien
- `Verzögern` (Ungewöhnlich): 2 Kopien

Dieser initiale Kartensatz bietet grundlegende Offensive (`Arkanblick`, `Arkanstrahl`) und erste Zeitmanipulation (`Verzögern`), während er einfach genug bleibt, um neue Spieler nicht zu überfordern.

#### 3.3.2 Kartenfreischaltungssequenz

| Spielfortschritt | Freigeschaltete Karte | Seltenheit | Strategischer Zweck |
|------------------|---------------------|-----------|-------------------|
| Tutorial-Boss (~1h) | `Chronowall` (2×) | Ungewöhnlich | Überlebensfähigkeit, Einführung der defensiven Spielweise |
| Erster Dungeon (~2h) | `Beschleunigen` (2×) | Selten | Effizienzkonzept, höhere APM ermöglichen |
| Welt 1 Mini-Boss (~3h) | `Chrono-Ernte` (2×) | Selten | Ressourcenmanagement, Beginn der strategischen Planung |
| Welt 1 Boss (~4-6h) | `Arkanblick` (1×) | Legendär | Erste Signaturkarte, Arkankraft-Integration |
| Welt 2 Einführung (~7h) | `Beschleunigen` (+1×) | Selten | Evolution wird verfügbar, Elementarpfade eröffnet |
| Welt 2 Dungeon (~9h) | `Zauberfokus` (1×) | Episch | Elementare Synergie, verstärkte Spezialisierung |
| Welt 2 Boss (~10h) | `Zeitverzerrung` (1×) | Legendär | Zweite Signaturkarte, Arkankraft-Modifikation |
| Welt 3 Start (~12h) | `Zeitbeben` (1×) | Episch | AoE-Macht, komplexere Strategien |
| Spätere Welten | Weitere Kopien | - | Deckoptimierung und Spezialisierung |

#### 3.3.3 Design-Philosophie

Diese Freischaltungssequenz verbindet narrative Progression mit mechanischer Komplexität:
- Führt die **Arkanpuls** schrittweise ein
- Ermöglicht das Erlernen der **Kartenreihenfolge-Bonus**-Mechanik mit zunehmender Kartenkomplexität
- Zentrale Mechaniken werden mit emotionalen "WOW"-Momenten verknüpft
- Legendäre Karten erscheinen an narrativen Wendepunkten

Die vollständige Sammlung aller 26 Karten wird innerhalb der ersten ~15-20 Spielstunden erreicht, während das Maximieren von Kopien, Evolutionen und Seltenheiten die längerfristige Progression darstellt.

## 4. Kartenbeschreibungen und Evolutionen

*(Hinweis: Alle Karten haben nun 3 Elementar-Evolutionspfade. Kosten, Werte sind vorläufig. **Materialkosten entsprechen dem vereinfachten System aus ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md mit den drei klar definierten Materialtypen (Zeitkern, Elementarfragment, Zeitfokus).** **Fett** markierte Effekte zeigen die direkte Interaktion mit Arkanpuls.)*

### 4.1 Basiszauber

#### 4.1.1 Arkanblick (`CARD-MAGE-ARCANEINTELLIGENCE`)

* **Basis**: 1,0s | Ziehe **1 Karte + 1 zusätzliche Karte pro 2 voller Arkanpuls-Ladungen**. *Generiert +1 Arkanpuls-Ladung.*
* **Startdeck**: 1 Karte

* **Feuer-Evolution:**
    | Stufe           | Name           | Kosten | Effekt                     | DoT-Kat. | Zeitgew. | Materialien          |
    | :-------------- | :------------- | :----- | :------------------------- | :------- | :------- | :------------------- |
    | 1: Funke        | Spark          | 1,0s   | 2 + 1 DoT                  | Schwach  | 0,5s     | `1x Elementarfragment` |
    | 2: Feuerstoß    | Firebolt       | 1,5s   | 4 + 2 DoT                  | Mittel   | 1,0s     | `2x Elementarfragment` |
    | 3: Feuerlanze   | Firelance      | 2,0s   | 6 + 4 DoT                  | Stark    | 2,0s     | `3x Elementarfragment` |
* **Eis-Evolution:**
    | Stufe             | Name             | Kosten | Effekt                   | Materialien          |
    | :---------------- | :--------------- | :----- | :----------------------- | :------------------- |
    | 1: Frosthauch     | Frostbreath      | 1,5s   | 3 Schaden + 15% Slow (2,0s)| `1x Elementarfragment` |
    | 2: Eissplitter    | Iceshard         | 2,0s   | 5 Schaden + 25% Slow (2,5s)| `2x Elementarfragment` |
    | 3: Frostexplosion | Frostexplosion   | 2,5s   | 6 Schaden + 35% AoE Slow (3,0s) | `3x Elementarfragment` |
* **Blitz-Evolution:**
    | Stufe          | Name                 | Kosten | Effekt             | Ketteneff. | Materialien          |
    | :------------- | :------------------- | :----- | :----------------- | :--------- | :------------------- |
    | 1: Statik      | Staticdischarge      | 1,0s   | 3 Schaden + Kette (1) | 70%        | `1x Elementarfragment` |
    | 2: Kettenblitz | Chainlightning       | 2,0s   | 4 Schaden + Kette (2) | 70%        | `2x Elementarfragment` |
    | 3: Gewitter    | Lightningdischarge   | 2,5s   | 5 Schaden + Kette (alle) | 70%        | `3x Elementarfragment` |

#### 4.1.2 Arkanstrahl (`CARD-MAGE-ARCANICRAY`)

* **Basis**: 2,0s | 5 Schaden. *Generiert +1 Arkanpuls-Ladung bei Treffer.*
* **Startdeck**: 4 Karten

* **Feuer-Evolution:**
    | Stufe           | Name           | Kosten | Effekt                     | DoT-Kat. | Zeitgew. | Materialien          |
    | :-------------- | :------------- | :----- | :------------------------- | :------- | :------- | :------------------- |
    | 1: Feuerball    | Fireball       | 2,0s   | 5 + kleiner AoE + 2 DoT    | Mittel   | 1,0s     | `1x Elementarfragment` |
    | 2: Magmastrahl  | Flamesphere    | 2,5s   | 7 + mittlerer AoE + 3 DoT  | Stark    | 2,0s     | `2x Elementarfragment` |
    | 3: Solarstrahl  | Conflagration  | 3,0s   | 9 + großer AoE + 5 DoT     | Stark    | 2,0s     | `3x Elementarfragment` |
* **Eis-Evolution:**
    | Stufe           | Name            | Kosten | Effekt                      | Materialien          |
    | :-------------- | :-------------- | :----- | :-------------------------- | :------------------- |
    | 1: Eisstrahl    | Icelance        | 2,0s   | 4 Schaden + 20% Slow (3,0s) | `1x Elementarfragment` |
    | 2: Froststrahl  | Frostcascade    | 2,5s   | 6 Schaden + 30% Slow (3,5s, kleine AoE) | `2x Elementarfragment` |
    | 3: Kryostrahl   | Icestorm        | 3,0s   | 7 Schaden + 40% Slow (4,0s, mittlere AoE) | `3x Elementarfragment` |
* **Blitz-Evolution:**
    | Stufe           | Name            | Kosten | Effekt                         | Ketteneff. | Materialien          |
    | :-------------- | :-------------- | :----- | :----------------------------- | :--------- | :------------------- |
    | 1: Blitzstrahl  | Lightningbolt   | 1,5s   | 4 Schaden + Kette (1)          | 70%        | `1x Elementarfragment` |
    | 2: Donnerstrahl | Lightningstorm  | 2,0s   | 5 Schaden + Kette (2)          | 70%        | `2x Elementarfragment` |
    | 3: Gewitterstrahl| Thunderstorm    | 2,5s   | 6 Schaden + Kette (3)          | 70%        | `3x Elementarfragment` |

### 4.2 Zeitmanipulationskarten

#### 4.2.1 Verzögern (`CARD-MAGE-DELAY`)

* **Basis**: 2,0s | Verzögert nächsten Gegnerangriff um 2,0s. *Generiert +1 Arkanpuls-Ladung.*
* **Startdeck**: 3 Karten

* **Feuer-Pfad ("Zeitbrand"):**
    | Stufe             | Name            | Kosten | Effekt                                                       | Materialien          |
    | :---------------- | :-------------- | :----- | :----------------------------------------------------------- | :------------------- |
    | 1: Brandfessel    | Timespark       | 2,0s   | Verzögert nächsten Angriff um 2,0s. Angreifer erleidet 2 Schaden.| `1x Elementarfragment` |
    | 2: Glutfessel     | Timeflame       | 2,0s   | Verzögert nächsten Angriff um 2,5s. Angreifer erleidet 3 Schaden + 1 DoT (Schwach).| `2x Elementarfragment` |
    | 3: Feuerstau      | Chronoinferno   | 2,5s   | Verzögert nächsten Angriff um 3,0s. Angreifer erleidet 5 Schaden + 2 DoT (Mittel). | `3x Elementarfragment` |
* **Eis-Pfad ("Zeitfrost"):**
    | Stufe             | Name           | Kosten | Effekt                                                           | Materialien          |
    | :---------------- | :------------- | :----- | :--------------------------------------------------------------- | :------------------- |
    | 1: Frostfessel    | Frostfetter    | 2,0s   | Verzögert nächsten Angriff um 3,0s.                              | `1x Elementarfragment` |
    | 2: Eisfalle       | Icetimetrap    | 2,0s   | Verzögert nächsten Angriff um 4,0s. Gegner +15% verlangsamt (3,0s). | `2x Elementarfragment` |
    | 3: Kryostau       | Cryostasis     | 2,5s   | Verzögert nächsten Angriff um 5,0s. Gegner +30% verlangsamt (3,0s). | `3x Elementarfragment` |
* **Blitz-Pfad ("Zeitschock"):**
    | Stufe               | Name              | Kosten | Effekt                                                              | Materialien          |
    | :------------------ | :---------------- | :----- | :------------------------------------------------------------------ | :------------------- |
    | 1: Schockfessel     | Timespark         | 2,0s   | Verzögert nächsten Angriff um 2,5s. Verursacht 1 Schaden am Angreifer.| `1x Elementarfragment` |
    | 2: Donnerfessel   | Temporalshock     | 2,0s   | Verzögert nächsten Angriff um 3,0s. Verursacht 2 Schaden, 0,5s Stun.| `2x Elementarfragment` |
    | 3: Gewitterstau   | Chronothunderstorm| 2,5s   | Verzögert nächsten Angriff um 3,5s. Verursacht 3 Schaden, 1,0s Stun.| `3x Elementarfragment` |

#### 4.2.2 Tempo (`CARD-MAGE-ACCELERATE`)

* **Basis**: 2,5s | (`Tempo`) Nächste 2 Karten **-Y Sekunden Kosten**, wobei **Y = 0,5s bei 0-2 Kraft / 1,0s bei 3-4 Kraft / 1,5s bei 5 Kraft**. *Generiert +1 Arkanpuls-Ladung.*
* **Startdeck**: 3 Karten

* **Feuer-Pfad ("Zeitschub")**:
    | Stufe                   | Name                      | Kosten | Effekt                                                                | Materialien          |
    | :---------------------- | :------------------------ | :----- | :-------------------------------------------------------------------- | :------------------- |
    | 1: Feuerschub           | Tempo Inferno             | 2,5s   | Nächste 2 Karten -0,5s Kosten. +5% Feuer-Schaden für nächste Karte.     | `1x Elementarfragment` |
    | 2: Glutschub            | Temporal Acceleration Fire| 2,5s   | Nächste 2 Karten -0,7s Kosten. +10% Feuer-Schaden für nächste 2 Karten. | `2x Elementarfragment` |
    | 3: Magmaschub           | Chronosphere Scorch       | 3,0s   | Nächste 3 Karten -1,0s Kosten. +15% Feuer-Schaden für nächste 3 Karten. | `3x Elementarfragment` |
* **Eis-Pfad ("Zeitfluss")**:
    | Stufe                     | Name                      | Kosten | Effekt                                                                    | Materialien          |
    | :------------------------ | :------------------------ | :----- | :------------------------------------------------------------------------ | :------------------- |
    | 1: Eisschub             | Cryo Sprint               | 2,5s   | Nächste 2 Karten -0,5s Kosten. Nächste Eis-Karte +5% Verlangsamung.       | `1x Elementarfragment` |
    | 2: Frostschub           | Icy Acceleration          | 2,5s   | Nächste 2 Karten -0,7s Kosten. Nächste 2 Eis-Karten +10% Verlangsamung.   | `2x Elementarfragment` |
    | 3: Kryoschub            | Glacial Flow              | 3,0s   | Nächste 3 Karten -1,0s Kosten. Nächste 3 Eis-Karten +15% Verlangsamung.   | `3x Elementarfragment` |
* **Blitz-Pfad ("Zeitsprung")**:
    | Stufe                     | Name                      | Kosten | Effekt                                                                          | Materialien          |
    | :------------------------ | :------------------------ | :----- | :------------------------------------------------------------------------------ | :------------------- |
    | 1: Blitzschub           | Voltaic Leap              | 2,5s   | Nächste 2 Karten -0,5s Kosten. Nächste Blitz-Karte +1 Kettenziel.              | `1x Elementarfragment` |
    | 2: Donnerschub          | Chrono Discharge Leap     | 2,5s   | Nächste 2 Karten -0,7s Kosten. Nächste 2 Blitz-Karten +1 Kettenziel, +5% Schaden.| `2x Elementarfragment` |
    | 3: Tempoblitz           | Temporal Storm Bolt       | 3,0s   | Nächste 3 Karten -1,0s Kosten. Nächste 3 Blitz-Karten +2 Kettenziele, +10% Schaden.| `3x Elementarfragment` |

#### 4.2.3 Chronowall (`CARD-MAGE-CHRONOBARRIER`)

* **Basis**: 2,0s | Blockiert nächsten Angriff innerhalb 3,0s. **Bei erfolgreichem Block: Generiere +1 zusätzliche Arkanpuls-Ladung.** *Generiert +1 Arkanpuls-Ladung beim Ausspielen.*
* **Startdeck**: 2 Karten

* **Feuer-Pfad ("Flammenbarriere")**:
    | Stufe                 | Name                  | Kosten | Effekt                                                                      | Materialien          |
    | :-------------------- | :-------------------- | :----- | :-------------------------------------------------------------------------- | :------------------- |
    | 1: Flammenwall        | Searing Aegis         | 2,0s   | Blockiert Angriff. Bei Block: Angreifer erleidet 2 Feuerschaden.             | `1x Elementarfragment` |
    | 2: Magmawall          | Inferno Wall          | 2,0s   | Blockiert Angriff. Bei Block: Angreifer erleidet 4 Feuerschaden + 1 DoT (Schwach). | `2x Elementarfragment` |
    | 3: Solarwall          | Sunfire Bastion       | 2,5s   | Blockiert Angriff. Bei Block: Angreifer erleidet 6 Feuerschaden + 2 DoT (Mittel).  | `3x Elementarfragment` |
* **Eis-Pfad ("Eisbarriere")**:
    | Stufe                 | Name                  | Kosten | Effekt                                                                         | Materialien          |
    | :-------------------- | :-------------------- | :----- | :----------------------------------------------------------------------------- | :------------------- |
    | 1: Eiswall            | Frost Shield          | 2,0s   | Blockiert Angriff. Bei Block: Angreifer +15% verlangsamt (3,0s).              | `1x Elementarfragment` |
    | 2: Frostwall          | Glacial Wall          | 2,0s   | Blockiert Angriff. Bei Block: Angreifer +25% verlangsamt (3,5s), -10% Schaden (3,5s).| `2x Elementarfragment` |
    | 3: Kryowall           | Cryonic Fortress      | 2,5s   | Blockiert Angriff. Bei Block: Angreifer +35% verlangsamt (4,0s), -20% Schaden (4,0s).| `3x Elementarfragment` |
* **Blitz-Pfad ("Sturmbarriere")**:
    | Stufe                   | Name                  | Kosten | Effekt                                                                       | Materialien          |
    | :---------------------- | :-------------------- | :----- | :--------------------------------------------------------------------------- | :------------------- |
    | 1: Blitzwall          | Static Barrier        | 2,0s   | Blockiert Angriff. Bei Block: Nächste Blitz-Karte +1 Kettenziel.              | `1x Elementarfragment` |
    | 2: Donnerwall         | Thunderfront          | 2,0s   | Blockiert Angriff. Bei Block: Nächste 2 Blitz-Karten +1 Kettenziel, +5% Schaden.| `2x Elementarfragment` |
    | 3: Sturmwall          | Voltaic Citadel       | 2,5s   | Blockiert Angriff. Bei Block: Nächste 3 Blitz-Karten +2 Kettenziele, +10% Schaden.| `3x Elementarfragment` |

#### 4.2.4 Zeitsiphon (`CARD-MAGE-TEMPORALRIFTRECOVERY`)

* **Basis**: 3,0s | (`Zeitsiphon`) Erhalte +2,0s Zeit, wenn ein Gegner innerhalb von 5,0s stirbt. *Generiert +1 Arkanpuls-Ladung.*
* **Startdeck**: 2 Karten

* **Feuer-Pfad ("Seelenbrand-Ernte")**:
    | Stufe                   | Name                      | Kosten | Effekt                                                                                | Materialien          |
    | :---------------------- | :------------------------ | :----- | :------------------------------------------------------------------------------------ | :------------------- |
    | 1: Feuersiphon          | Spark Extraction          | 3,0s   | +2,0s Zeit bei Tod. Getöteter Gegner explodiert (1 Feuerschaden AoE).                 | `1x Elementarfragment` |
    | 2: Glutsiphon           | Flame Absorption          | 3,0s   | +2,5s Zeit bei Tod. Getöteter Gegner explodiert (2 Feuerschaden AoE, 1 DoT Schwach).      | `2x Elementarfragment` |
    | 3: Magmasiphon          | Infernal Essence Harvest  | 3,5s   | +3,0s Zeit bei Tod. Getöteter Gegner explodiert (3 Feuerschaden AoE, 2 DoT Mittel).     | `3x Elementarfragment` |
* **Eis-Pfad ("Kryo-Ernte")**:
    | Stufe                     | Name                      | Kosten | Effekt                                                                                  | Materialien          |
    | :------------------------ | :------------------------ | :----- | :-------------------------------------------------------------------------------------- | :------------------- |
    | 1: Eissiphon              | Frostbreath Collection    | 3,0s   | +2,0s Zeit bei Tod. Gegner in Nähe +10% verlangsamt (2,0s).                           | `1x Elementarfragment` |
    | 2: Frostsiphon            | Ice Core Extraction       | 3,0s   | +2,5s Zeit bei Tod. Gegner in Nähe +20% verlangsamt (2,5s), -5% Schaden (2,5s).         | `2x Elementarfragment` |
    | 3: Kryosiphon             | Glacier Soul Harvest      | 3,5s   | +3,0s Zeit bei Tod. Gegner in Nähe +30% verlangsamt (3,0s), -10% Schaden (3,0s).        | `3x Elementarfragment` |
* **Blitz-Pfad ("Voltaische Ernte")**:
    | Stufe                     | Name                      | Kosten | Effekt                                                                                       | Materialien          |
    | :------------------------ | :------------------------ | :----- | :------------------------------------------------------------------------------------------- | :------------------- |
    | 1: Blitzsiphon            | Energy Siphon             | 3,0s   | +2,0s Zeit bei Tod. Nächste Blitz-Karte +5% Schaden.                                         | `1x Elementarfragment` |
    | 2: Donnersiphon           | Storm Essence Collection  | 3,0s   | +2,5s Zeit bei Tod. Nächste 2 Blitz-Karten +7% Schaden, +1 Kettenziel.                       | `2x Elementarfragment` |
    | 3: Sturmsiphon            | Chrono Lightning Collector| 3,5s   | +3,0s Zeit bei Tod. Nächste 3 Blitz-Karten +10% Schaden, +1 Kettenziel, Kette springt schneller.| `3x Elementarfragment` |

#### 4.2.5 Zauberfokus (`CARD-MAGE-SPELLFOCUS`)

* **Basis**: 2,5s | Nächster Elementarzauber +X% Effektivität, wobei **X = 25 + (5 \* aktuelle Arkanpuls-Ladungen)** (Max +50% bei 5 Ladungen). *Generiert +1 Arkanpuls-Ladung.*
* **Startdeck**: 1 Karte

* **Feuer-Pfad ("Flammenfokus")**:
    | Stufe                 | Name                  | Kosten | Effekt                                                     | Materialien          |
    | :-------------------- | :-------------------- | :----- | :--------------------------------------------------------- | :------------------- |
    | 1: Feuerfokus         | Searing Focus         | 2,5s   | Nächster Elementarzauber +15% Schaden/Effektivität. Nächster Feuerzauber +5% DoT-Stärke. | `1x Elementarfragment` |
    | 2: Glutfokus          | Pyric Focus           | 2,5s   | Nächster Elementarzauber +20% Schaden/Effektivität. Nächster Feuerzauber +10% DoT-Stärke, +0,5s DoT-Dauer. | `2x Elementarfragment` |
    | 3: Magmafokus         | Infernal Focus        | 3,0s   | Nächster Elementarzauber +25% Schaden/Effektivität. Nächster Feuerzauber +15% DoT-Stärke, +1,0s DoT-Dauer, erzeugt kleine Feuerfläche. | `3x Elementarfragment` |
* **Eis-Pfad ("Frostfokus")**:
    | Stufe                 | Name                  | Kosten | Effekt                                                              | Materialien          |
    | :-------------------- | :-------------------- | :----- | :------------------------------------------------------------------ | :------------------- |
    | 1: Eisfokus           | Cold Focus            | 2,5s   | Nächster Elementarzauber +15% Schaden/Effektivität. Nächster Eiszauber +5% Verlangsamungs-Effekt. | `1x Elementarfragment` |
    | 2: Frostfokus         | Icy Focus             | 2,5s   | Nächster Elementarzauber +20% Schaden/Effektivität. Nächster Eiszauber +10% Verlangsamungs-Effekt, +0,5s Dauer. | `2x Elementarfragment` |
    | 3: Kryofokus          | Cryomantic Focus      | 3,0s   | Nächster Elementarzauber +25% Schaden/Effektivität. Nächster Eiszauber +15% Verlangsamungs-Effekt, +1,0s Dauer, hinterlässt Eisfläche. | `3x Elementarfragment` |
* **Blitz-Pfad ("Sturmfokus")**:
    | Stufe                 | Name                  | Kosten | Effekt                                                                  | Materialien          |
    | :-------------------- | :-------------------- | :----- | :---------------------------------------------------------------------- | :------------------- |
    | 1: Blitzfokus         | Static Focus          | 2,5s   | Nächster Elementarzauber +15% Schaden/Effektivität. Nächster Blitzzauber +1 Kettenziel. | `1x Elementarfragment` |
    | 2: Donnerfokus        | Voltaic Focus         | 2,5s   | Nächster Elementarzauber +20% Schaden/Effektivität. Nächster Blitzzauber +1 Kettenziel, +5% Ketten-Schaden. | `2x Elementarfragment` |
    | 3: Sturmfokus         | Thunder Focus         | 3,0s   | Nächster Elementarzauber +25% Schaden/Effektivität. Nächster Blitzzauber +2 Kettenziele, +10% Ketten-Schaden, schnellerer Sprung. | `3x Elementarfragment` |

#### 4.2.6 Zeitbeben (`CARD-MAGE-TIMETREMOR`)

* **Basis**: 5,0s | +3,0s Zeit, 10 AoE-Schaden, +1 Karte. *Generiert +1 Arkanpuls-Ladung.*
* **Startdeck**: 1 Karte

* **Feuer-Pfad ("Magmabeben")**:
    | Stufe           | Name            | Kosten | Effekt                                                                      | Materialien          |
    | :-------------- | :-------------- | :----- | :-------------------------------------------------------------------------- | :------------------- |
    | 1: Feuerbeben   | Eruption        | 5,0s   | +3,0s Zeit, 12 AoE-Schaden, +1 Karte. Hinterlässt brennenden Boden (2 DoT, 3s).| `1x Elementarfragment` |
    | 2: Glutbeben    | Lava Wave       | 5,0s   | +3,5s Zeit, 15 AoE-Schaden, +1 Karte. Brennender Boden (3 DoT, 4s).        | `2x Elementarfragment` |
    | 3: Magmaburst   | Volcanic Storm  | 5,5s   | +4,0s Zeit, 18 AoE-Schaden, +2 Karten. Brennender Boden (4 DoT, 5s), Ascheregen (verlangsamt Gegner).| `3x Elementarfragment` |
* **Eis-Pfad ("Gletscherbeben")**:
    | Stufe           | Name            | Kosten | Effekt                                                                         | Materialien          |
    | :-------------- | :-------------- | :----- | :----------------------------------------------------------------------------- | :------------------- |
    | 1: Eisbeben     | Frost Shock     | 5,0s   | +3,0s Zeit, 10 AoE-Schaden, +1 Karte. Gegner -15% verlangsamt (3s).           | `1x Elementarfragment` |
    | 2: Frostbeben   | Ice Shatter     | 5,0s   | +3,5s Zeit, 12 AoE-Schaden, +1 Karte. Gegner -25% verlangsamt (4s), -10% Schaden.| `2x Elementarfragment` |
    | 3: Kryobeben    | Avalanche Fall  | 5,5s   | +4,0s Zeit, 15 AoE-Schaden, +2 Karten. Gegner -35% verlangsamt (5s), -20% Schaden, Chance auf Einfrieren (1s).| `3x Elementarfragment` |
* **Blitz-Pfad ("Donnerbeben")**:
    | Stufe                 | Name                    | Kosten | Effekt                                                                                 | Materialien          |
    | :-------------------- | :---------------------- | :----- | :------------------------------------------------------------------------------------- | :------------------- |
    | 1: Blitzbeben         | Concussion              | 5,0s   | +3,0s Zeit, 10 AoE-Schaden, +1 Karte. Chance auf 0,5s Stun.                             | `1x Elementarfragment` |
    | 2: Donnerbeben        | Shockwave               | 5,0s   | +3,5s Zeit, 12 AoE-Schaden, +1 Karte. Höhere Chance auf 0,7s Stun, +1 Kettenblitz auf nahes Ziel.| `2x Elementarfragment` |
    | 3: Sturmbeben         | Resonance Cataclysm     | 5,5s   | +4,0s Zeit, 15 AoE-Schaden, +2 Karten. Garantierter 1,0s Stun, +2 Kettenblitze.        | `3x Elementarfragment` |

### 4.3 Signaturkarten

#### 4.3.1 Arkanblick (`CARD-MAGE-ARCANEINTELLIGENCE`)

* **Basis**: 1,0s | Ziehe **1 Karte + 1 zusätzliche Karte pro 2 voller Arkanpuls-Ladungen** (Max 3 Karten bei 4+ Kraft). *Generiert +1 Arkanpuls-Ladung.*
* **Startdeck**: 1 Karte

* **Feuer-Pfad ("Pyrisches Orakel"):**
    | Stufe                  | Name              | Kosten | Effekt                                                                  | Materialien          |
    | :--------------------- | :---------------- | :----- | :---------------------------------------------------------------------- | :------------------- |
    | 1: Flammenruf          | Callofflame       | 1,5s   | Ziehe Karten (Basis-Skalierung). Nächste *Feuer*-Karte -0,5s & +15% Schaden.     | `1x Elementarfragment` |
    | 2: Infernosecho        | Echoofinferno     | 2,0s   | Ziehe Karten (Basis-Skalierung). Nächste 2 *Feuer*-Karten -0,5s & +20% Schaden.| `2x Elementarfragment` |
    | 3: Urflammenwille      | Willofflame       | 2,5s   | Ziehe Karten (Basis-Skalierung). Nächste 2 *Feuer*-Karten -1,0s & +30% Schaden.| `3x Elementarfragment` |
* **Eis-Pfad ("Kryonisches Archiv"):**
    | Stufe                      | Name            | Kosten | Effekt                                                                 | Materialien          |
    | :------------------------- | :-------------- | :----- | :--------------------------------------------------------------------- | :------------------- |
    | 1: Frostruf            | Calloffrost     | 1,5s   | Ziehe Karten (Basis-Skalierung). Nächste *Eis*-Karte -0,5s & +15% Effektivität.| `1x Elementarfragment` |
    | 2: Gletscherecho       | Echoofglacier   | 2,0s   | Ziehe Karten (Basis-Skalierung +1 bei 4+ Kraft). Nächste *Eis*-Karte -1,0s & +20% Effektivität.| `2x Elementarfragment` |
    | 3: Eiswille              | Willofice       | 2,5s   | Ziehe Karten (Basis-Skalierung +1 bei 4+ Kraft). Nächste 2 *Eis*-Karten -1,0s & +30% Effektivität.| `3x Elementarfragment` |
* **Blitz-Pfad ("Synaptischer Fluss"):**
    | Stufe                 | Name              | Kosten | Effekt                                       | Materialien          |
    | :-------------------- | :---------------- | :----- | :------------------------------------------- | :------------------- |
    | 1: Blitzruf           | Calloflightning   | 1,0s   | Ziehe Karten (Basis-Skalierung +1).          | `1x Elementarfragment` |
    | 2: Sturmecho          | Echoofstorm       | 1,0s   | Ziehe Karten (Basis-Skalierung +1). Nächste Karte -0,5s Kosten. | `2x Elementarfragment` |
    | 3: Gewitterwille      | Willofthunder     | 1,5s   | Ziehe Karten (Basis-Skalierung +2). Nächste 2 Karten -0,5s Kosten.| `3x Elementarfragment` |

#### 4.3.2 Zeitkrümmung (`CARD-MAGE-TIMEWARP`)

* **Basis**: 4,0s | (`Zeitkrümmung`) Verlangsamt Ziel um 30% für 3,0s. *Generiert +1 Arkanpuls-Ladung.*
* **Startdeck**: 1 Karte
* **Besonderheit:** Die Evolutionen dieser Karte modifizieren die Kernmechanik "Arkanpuls".

* **Feuer-Evo ("Zeitliche Entzündung")**:
    | Stufe           | Name            | Kosten | Effekt                                                                                              | Arkanschub-Modifikation         | Materialien          |
    | :-------------- | :-------------- | :----- | :-------------------------------------------------------------------------------------------------- | :------------------------- | :------------------- |
    | 1: Feuerkrümmung| Ignite          | 4,0s   | Verlangsamt Ziel um 30% (3s). Ziel erleidet 2 Feuerschaden/Sek. Arkanschub: +DoT-Dauer, +DoT-Stärke.    | Arkanschub verursacht +5 AoE Schaden. | `1x Elementarfragment` |
    | 2: Glutkrümmung | Time Scorch     | 4,0s   | Verlangsamt Ziel um 35% (3,5s). Ziel erleidet 3 Feuerschaden/Sek. Arkanschub: Fläche mit DoT.         | Arkanschub verursacht +10 AoE Schaden.| `2x Elementarfragment` |
    | 3: Magmakrümmung| Chrono Inferno  | 4,5s   | Verlangsamt Ziel um 40% (4s). Ziel erleidet 4 Feuerschaden/Sek. Arkanschub: Explodiert am Ende mit AoE-Schaden. | Arkanschub verursacht +15 AoE Schaden.| `3x Elementarfragment` |
* **Eis-Evo ("Zeitlicher Stillstand")**:
    | Stufe                 | Name                  | Kosten | Effekt                                                                                                | Arkanschub-Modifikation                       | Materialien          |
    | :-------------------- | :-------------------- | :----- | :---------------------------------------------------------------------------------------------------- | :--------------------------------------- | :------------------- |
    | 1: Eiskrümmung        | Freeze                | 4,0s   | Verlangsamt Ziel um 40% (3s). Arkanschub: +Slow-Stärke, +Slow-Dauer.                                  | Arkanschub-Effekt wirkt AoE (falls auf Ziel). | `1x Elementarfragment` |
    | 2: Frostkrümmung      | Cryostasis            | 4,0s   | Verlangsamt Ziel um 50% (3,5s). Arkanschub: Friert Ziel für 1s ein.                                     | Arkanschub-Effekt wirkt AoE.                   | `2x Elementarfragment` |
    | 3: Kryokrümmung       | Absolute Zero         | 4,5s   | Verlangsamt Ziel um 60% (4s). Arkanschub: Friert Ziel für 2s ein, hinterlässt verlangsamende Eisfläche. | Arkanschub-Effekt wirkt AoE.                   | `3x Elementarfragment` |
* **Blitz-Evo ("Zeitparadoxon")**:
    | Stufe               | Name                  | Kosten | Effekt                                                                                                    | Arkanschub-Modifikation / System-Modifikation | Materialien          |
    | :------------------ | :-------------------- | :----- | :-------------------------------------------------------------------------------------------------------- | :--------------------------------------- | :------------------- |
    | 1: Blitzkrümmung    | Fluctuate             | 4,0s   | Verlangsamt Ziel um 30% (3s). Arkanschub: Nächste Karte -1s Kosten.                                         | Arkanschub: Bonus-Effektivität nur +25% (statt +50%). | `1x Elementarfragment` |
    | 2: Donnerkrümmung   | Paradox Pulse         | 4,0s   | Verlangsamt Ziel um 35% (3,5s). Arkanschub: Nächste 2 Karten -0,7s Kosten, +Chance auf kostenlose Karte.    | Arkanschub: Bonus-Effektivität +50%. Arkanpuls-Verfall -0,5pkt/s.| `2x Elementarfragment` |
    | 3: Chronoschritt    | Chrono Collapse       | 4,5s   | Verlangsamt Ziel um 40% (4s). Arkanschub: Nächste 3 Karten -1s Kosten, hohe Chance auf kostenlose Karte.      | Arkanschub: Bonus-Effektivität +75%. Arkanpuls-Verfall -0,5pkt/s.| `3x Elementarfragment` |

## 5. Benötigte Materialien

* **Vereinfachtes Materialsystem:**
    * **Zeitkern**: Ausschließlich für Kartenleveling (1 Zeitkern = 1 Level)
    * **Elementarfragment**: Ausschließlich für Evolution
        * Stufe 1 Evolution: 1× Elementarfragment
        * Stufe 2 Evolution: 2× Elementarfragment
        * Stufe 3 Evolution: 3× Elementarfragment
        * Signaturkarten (höchste Stufe): 3× Elementarfragment
    * **Seltene Essenz**: Keine Verwendung
    * **Zeitfokus**: Ausschließlich für Attribut-Rerolls

## 6. Spielstil und Strategie

* **Kernspielweise:** Management des **Arkanpuls** durch Weben von Zeitmanipulations- und Elementarkarten. Nutzen der Schwellenboni. Strategischer Einsatz des **Arkanschub**-Effekts. Berücksichtigung der **Kartenreihenfolge-Bonus** für zusätzliche Boni durch Kartenreihenfolge.
* **Arkanpuls-Management:** Hohe Ladungen verstärken `Zauberfokus`, `Arkanblick`, `Beschleunigen`. Erfolgreiche Blocks mit `Chronowall` generieren extra Ladungen.
* **Arkanschub-Timing:** Wähle die richtige Karte (Elementar für Schaden/Interrupt, Zeitmanipulation für extreme Effektivität) für den Arkanschub.
* **Kartenreihenfolge-Bonus**: Nutze den Bonus: Nach Zeitmanipulation sind Elementarzauber billiger/effizienter (mit Zeitgewinn und Arkanpuls-Bonus); nach Elementarzauber sind Zeitmanipulationen effektiver (mit Zeitgewinn und Arkanpuls-Bonus).
* **Zeitverzerrung-Synergie:** Spezialisiert den Bruch oder das Arkanpuls-Management (Schaden, AoE-Kontrolle, oder höhere Effektivität/langsamerer Verfall).

## 7. Beispiel-Kombos (mit Arkanpuls und Kartenreihenfolge-Bonus)

* **Effizienz-Aufbau & Nutzung:**
    1.  `Beschleunigen` (2,5s, 0 Kraft -> Effekt -0,5s) -> +1 Kraft (Total 1). Zustand: **Kartenreihenfolge-Bonus**.
    2.  `Arkanblick` (1,0s -> 0,5s) -> +0,5s Zeitgewinn, +2 Kraft (1 Basis + 1 Bonus) (Total 3) -> *Boni 1&2 aktiv*. Zustand: **Kartenreihenfolge-Bonus**.
    3.  `Arkanblick` (1,0s -> 0,5s) -> Zieht 2 Karten. +15% Effektivität, +0,5s Zeitgewinn, +2 Kraft (1 Basis + 1 Bonus) (Total 5) -> **Bruch bereit!**. Zustand: **Kartenreihenfolge-Bonus**.
    4.  `Feuerlanze` (2,0s -> 0s) -> +0,5s Zeitgewinn. Profitiert von Bruch (+50% Eff, 0,5s Interrupt). Kraft -> 0. Zustand: **Kartenreihenfolge-Bonus**.
* **Chronowall-Konter:**
    1.  Gegner bereitet Angriff vor.
    2.  Spiele `Chronowall` (2,0s) -> +1 Kraft. Zustand: **Kartenreihenfolge-Bonus**.
    3.  Block erfolgreich -> +1 zusätzliche Kraft (Total 2). *Bonus +10% Ele-Dmg aktiv*.
    4.  Kontere mit `Arkanstrahl` (2,0s -> 1,5s) -> +0,5s Zeitgewinn, +2 Kraft (1+1) (Total 4). *Boni -0,5s Zeitmanip + +15% Zeitmanip Effektivität aktiv*. Zustand: **Kartenreihenfolge-Bonus**.

## 8. Klassenspezifische Synergien

* **Arkanpuls:** Zentral, verbindet beide Kartentypen. Skaliert Effekte, ermöglicht Bruch.
* **Schwellenboni:** Passive Stärkung bei 2, 3, 4 Ladungen.
* **Arkanschub:** Flexibler, starker Bonus auf nächste Karte.
* **Kartenreihenfolge-Bonus**: Belohnt abwechselndes Spielen mit Effizienz-/Effektivitätsboni und zusätzlicher Arkanpuls-Generierung.
* **Zeitverzerrung-Modifikation:** Spezialisiert den Bruch oder das Arkanpuls-Management (Schaden, AoE-Kontrolle, oder höhere Effektivität/langsamerer Verfall).

## 9. UI/UX Hinweise

Zusätzlich zu allgemeinen UI-Prinzipien (klare Timer, Effekte etc.):

* **Arkanpuls Anzeige:**
    * Eine klare Anzeige (z.B. 5 arkane Kugeln/Symbole) für die aktuellen Arkanpuls-Ladungen (0-5).
    * Visuelles Feedback, wenn ein Punkt generiert wird (z.B. Aufleuchten/Füllen der Kugel).
    * Deutliche Hervorhebung aktiver Schwellenboni (z.B. Leuchten der entsprechenden Kugeln, Icons neben der Anzeige).
    * Starke visuelle und auditive Hervorhebung, wenn 5 Punkte erreicht sind und der "Arkanschub"-Bruch bereit ist (z.B. Pulsieren aller Kugeln, Soundeffekt).
    * Ein Indikator für den drohenden Verfall (z.B. leichtes Ausgrauen oder Blinken nach 3s Inaktivität).
* **Kartenreihenfolge-Bonus Anzeige**:
    * Visueller Hinweis auf der nächsten Karte in der Hand, welcher Bonus aktiv ist (z.B. ein Icon "+20% Schaden" auf der nächsten Elementarkarte nach einer gespielten Zeitmanipulationskarte, oder "+10% Effektivität" auf der nächsten Zeitmanipulationskarte nach einem gespielten Elementarzauber).
* **Karten-Feedback**:
    * Karten, die von Kartenreihenfolge-Bonus profitieren, zeigen dies idealerweise direkt an (z.B. reduzierte Kosten werden angezeigt, Buff-Symbol für +15% Effektivität).
    * Karten, die mit Arkankraft skalieren (`Elementarfokus`, `Arkanblick`, `Beschleunigen`), sollten den *aktuell* zu erwartenden Effekt anzeigen (z.B. "+40% Effektivität" bei `Elementarfokus` wenn 3 Kraft vorhanden).
    * Bei `Arkanblick` sollte klar sein, wie viele Karten man *aktuell* ziehen würde.
    * Bei `Chronowall` klares Feedback bei erfolgreichem Block und der zusätzlichen Arkankraft-Generierung.
* **Bruch-Bonus Vorschau:** Wenn der Bruch bereit ist, könnten die Karten auf der Hand anzeigen, welchen Bonus sie erhalten würden (z.B. "+50% Dmg + Interrupt" Icon bei Elementarzaubern, "+100% Eff." Icon bei Zeitmanipulation). Das erleichtert die taktische Entscheidung.
* **DoT-Visualisierung:**
    * Konsistente Icons/Farbeffekte auf Gegnern für DoTs.
    * Unterscheidung nach Stärke (●, ●●, ●●●) und Farbe (Gelb, Orange, Rot).
    * Anzeige der verbleibenden DoT-Dauer.
* **Touch-Optimierung:** Ausreichend große Touch-Flächen, ggf. "Schnellauswahl"-Zone berücksichtigen.
* **Skalierungs-Anzeige:** Bei Karten wie `Elementarfokus`, `Arkanblick`, `Beschleunigen` sollte die UI idealerweise dynamisch anzeigen, welchen Bonus die Karte *aktuell* basierend auf der Arkankraft gewähren würde (z.B. im Tooltip oder direkt auf der Karte).
* **Chronowall-Feedback:** Klares visuelles/auditives Feedback, wenn ein Block erfolgreich war UND zusätzliche Arkankraft generiert wurde.

## 10. Quellendokumente

* `ZK-CLASS-MAGE-COMP-v1.1-20250327` / `ZK-CLASS-MAGE-CARDS-v1.1-20250327`: Ursprungsdaten.
* `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`: Quelle für die drei Materialtypen und ihre Verwendungszwecke.
* Gesprächsverlauf (Input zu Mechaniken, Evolutionen, Korrekturen).
* `ZK-TIME-v1.1-20250327`, `ZK-BAL-v1.1-20250327` etc.

## 11. Abhängige Dokumente

* `ZK-TIME-v1.1-20250327`: Zeitsystem für Kartenkosten/-effekte und DoT-Interaktion.
* `ZK-KARTENPROGRESSION-v2.1.md`: Details zu allen Aspekten der Kartenprogression.
* `ZK-WORLDS-v1.0-20250327`: Weltensystem und Interaktionen.
* `ZK-DUN-MECH-v1.0-20250327`: Weltmechaniken.
* `ZK-COMBAT-SYS`: Kampfsystem (für Details zur Kritischen Restzeit und Interrupts).
* `ZK-CLASS-MAGE-EVO-v1.1-20250327`: (Implizit, falls separates Evo-Dokument existiert)

## 12. Anmerkungen

* Version v2.1 integriert das finale System mit drei Materialtypen (Zeitkern, Elementarfragment, Zeitfokus) und standardisiert alle Evolutionskosten auf das Muster 1x/2x/3x Elementarfragment. `Seltene Essenz` wurde entfernt.
* Balancing aller Werte und Effekte ist ausstehend.
* Die spezifische Skalierung der Eis-Evolution von `Beschleunigen` muss noch final definiert werden (siehe Anmerkung in Tabelle 4.2.2).

## 13. Arkanpuls

Eine Ressource mit maximal 5 Ladungen, die durch Zeitmanipulationskarten (+1 Ladung) und Elementarzauber (+1 Ladung bei Treffer) generiert wird. Verfällt um 1 Ladung pro Sekunde nach 3 Sekunden Inaktivität. Jede Zeitmanipulationskarte verstärkt die nächste Elementarkarte um +20% Schaden. Jede Elementarkarte verstärkt die nächste Zeitmanipulationskarte um +10% Effektivität.