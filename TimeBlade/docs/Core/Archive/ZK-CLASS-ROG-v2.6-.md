# Schattenschreiter-Klasse und Karten (ZK-CLASS-ROG-v2.7-20250523)

## Änderungshistorie

* **v2.7 (2025-05-23):** `Seltene Essenz` vollständig aus Stufe 3 Evolutionskosten entfernt. Alle Stufe 3 Evolutionen kosten nun `3x Elementarfragment`. Anpassung an `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`. Versionsnummer aktualisiert.
* **v2.6 (2025-05-22):** Vollständige Standardisierung aller Evolutionskosten, einschließlich Signaturkarten, auf das Muster 1x/2x/3x Elementarfragment (+ 1x Seltene Essenz für Stufe 3). Entfernung von 'Sockelstein' und Finalisierung auf vier Materialtypen (Zeitkern, Elementarfragment, Seltene Essenz, Zeitfokus). Anpassung der Materialbeschreibungsnotiz.
* **v2.5 (2025-05-21):** Integration des vereinfachten Materialsystems mit vier klar definierten Materialtypen (Zeitkern, Elementarfragment, Seltene Essenz, Zeitfokus) nach Entfernung von 'Sockelstein'. Umstellung auf das "1 Zeitkern = 1 Level"-Prinzip. Standardisierung der Evolutionskosten für Nicht-Signaturkarten.
* **v2.4 (2025-05-10):** Überarbeitung der Schattensynergie: Schattenkarten verbrauchen kein Momentum mehr und haben immer normale Zeitkosten. Neuer Bonus bei 3 Momentum: +20% Schaden für Angriff nach Schattenkarte.
* **v2.3 (2025-04-21):** Korrektur der fehlerhaften v2.3. Entfernung der Basiskarte `Giftpfeil` (CARD-ROG-POISONARROW) und ihrer Evolutionen (alt 4.1.3), um die Anzahl einzigartiger Basiskarten auf 10 zu reduzieren (analog zu WAR/MAGE). Anpassung der Kartenverteilung (3.1) und des Starterdecks (3.2) - Anzahl `Schattendolch` auf 3 erhöht, um Deckgröße 26 beizubehalten. Anpassung der Abschnittsnummerierung in Sektion 4. Anpassung von Referenzen in Sektion 6, 7, 8. Alle Abschnitte vollständig ausgeschrieben.
* **v2.2 (2025-04-20):** Blitz-Evolutionen für *Giftpfeil* (Abschnitt 4.1.3) gemäß User-Input aktualisiert (Namen, Effekte, Chain-Mechanik, Momentum-Interaktion).
* **v2.1 (2025-04-19):** Regeln für Schattenkarten-Kosten und Synergien präzisiert (Abschnitte 2.0, 2.1, 8). Schattensynergie macht nur nächste *Angriffskarte* kostenlos. Bei 3+ Momentum kosten Schattenkarten 0 Zeit, aber verbrauchen 2 Momentum (Netto -1 Momentum pro Spielzug, da +1 generiert wird). Beispiel-Kombos (Abschnitt 7) benötigen Überarbeitung basierend auf diesen Regeln.
* **v2.0 (2025-04-19):** Interaktion zwischen Momentum-Bonus (3+) und Schattensynergie geklärt (Abschnitte 2.0, 2.1, 8). Beide Regeln gelten; eine bei 3+ Momentum gespielte (kostenlose) Schattenkarte löst zusätzlich die Schattensynergie für die Folgekarte aus. Konflikt-Anmerkung entfernt.
* **v1.9 (2025-04-19):** Momentum-System-Beschreibung (Abschnitt 2.1) gemäß User-Input detailliert (spezifische Schwellenboni). Evolutionen für *Zeitsprung* (Abschnitt 4.5.1) gemäß User-Input aktualisiert (Bruch-Skalierung, Schwellen-Modifikation, Ressourcen-Generierung), überschreibt damit die Daten aus `evo ROG.csv` für diese spezifische Karte. Hinweis auf Regelkonflikt bei Schattenkarten-Kosten hinzugefügt.
* **v1.8 (2025-04-19):** Materialkosten für alle ROG-Evolutionen angepasst. Hinweise auf Platzhalter-Materialkosten entfernt.
* **v1.7 (2025-04-19):** Evolutionen aller 11 Basis-Karten in Abschnitt 4 vollständig mit `evo ROG.csv` synchronisiert (Namen, Kosten, Effekte). DoT-Kategorien anhand `dot_categories_rows-4.csv` korrekt zugeordnet. Bestehende Materialkosten beibehalten (da nicht in `evo ROG.csv`), müssen ggf. überprüft werden. *Zeitsprung*-Evolutionen entsprechen nun wieder der CSV, nicht den spezifischen Mechanik-Änderungen aus v1.5. Gesamt-Dokument neu generiert.
* **v1.6 (2025-04-19):** Abschnitt 3 (Deckzusammensetzung) und Abschnitt 4 (Kartenbeschreibungen Basis-Karten) vollständig mit `cards_rows-16.csv` synchronisiert (CSV als Quelle der Wahrheit). Basis-Effekte und -Kosten angepasst. Überflüssige/falsche Basis-Karten-Beschreibungen entfernt, fehlende hinzugefügt. Starterdeck korrigiert. Evolutionen bestehender Karten beibehalten.
* **v1.5 (2025-04-18):** Vollständige Überarbeitung der Evolutionen für *Zeitsprung* (`CARD-ROG-TIMESHIFT`) gemäß neuen Spezifikationen (Feuer: Bruch-Effektivität, Eis: Momentum-Schwellen/Verfall, Blitz: Momentum-Generierung/Bruch-Bonus). Bestehende Kosten und Materialien wurden beibehalten und müssen ggf. auf Balance geprüft werden.
* **v1.4 (2025-04-18):** Korrektur des Fehlers in `v1.2` bezüglich *Ewige Unendlichkeit*. Klarstellung zu Schattenstaub. Einführungs-Kombo hinzugefügt. Stark+ DoT-Visualisierung ergänzt.
* **v1.3 (2025-04-18):** Überarbeitung Momentum-System (Schattenrausch bei 5). Evolutionen von *Zeitsprung* angepasst (alt, durch v1.5/v1.7 überschrieben). Momentum-Effekte bei 5 für andere Karten entfernt.
* **v1.2 (2025-04-18):** Deckgröße korrigiert auf 26 Karten.
* **v1.1 (2025-04-18):** Anpassung DoT-Werte an Kategorien.
* **v1.0 (2025-04-17):** Initiale Zusammenführung und Integration Materialsystem.

## 1. Einleitung

Dieses Dokument beschreibt die Schattenschreiter-Klasse (ROG - Rogue), eine agile, auf Zeitmanipulation, Kombos und Momentum spezialisierte Klasse im Spiel *Zeitenkristall*. Es umfasst die Klassenmechaniken, die 10 Basis-Karten, deren Evolutionen sowie strategische Hinweise. Ziel ist es, eine schnelle, trickreiche Spielweise zu ermöglichen, die hohe Geschicklichkeit belohnt.

## 2. Klassenübersicht

* **ID:** `09e2ecf1-c4dd-4c5a-a226-3e9f73d442a2` (aus `classes_rows-5.csv`)
* **Name:** Schattenschreiter (Rogue - ROG)
* **Fokus:** Zeitmanipulation (Zeitdiebstahl), Komboketten (Momentum), Ausweichen/Täuschung (Schattenkarten).
* **Schwierigkeit:** Hoch. Erfordert präzises Timing und Ressourcenmanagement.
* **Kernmechaniken:**
    * **Momentum:** Wird durch das Spielen von Karten generiert. Erhöht die Effektivität bestimmter Karten bei Erreichen von Schwellenwerten. Verfällt nach 3 Sekunden ohne Kartenspiel (modifizierbar durch Zeitsprung Eis-Evo).
    * **Bruch (Schattenrausch):** Wird bei Erreichen von 5 Momentum ausgelöst. Gewährt einen starken, temporären Bonus (modifizierbar durch Zeitsprung Feuer-Evo).
    * **Zeitdiebstahl:** Gewinnt zusätzliche Aktionszeit vom Gegner hinzu. Essentiell, um lange Kombos zu ermöglichen.
    * **Schattensynergie:** Schattenkarten machen die nächste Angriffskarte kostenlos (0 Zeitkosten). Schattenkarten haben immer ihre normalen Zeitkosten und verbrauchen kein Momentum.

### 2.1 Momentum (Klassenressource)

* **Generierung:** +1 Momentum pro gespielter Karte (Basis, auch wenn die Karte 0 Zeit kostet), modifizierbar durch *Zeitsprung* Blitz-Evo.
* **Maximalwert:** 5 Momentum.
* **Verfall:** Momentum sinkt um 1 pro Sekunde, wenn 3 Sekunden lang keine Karte gespielt wird (Basis). Die Verfallszeit ist modifizierbar durch *Zeitsprung* Eis-Evo.
* **Schwellenboni:** Treten bei bestimmten Momentum-Stufen ein. Der genaue Zeitpunkt kann durch *Zeitsprung* Eis-Evo modifiziert werden.
    * **Ab 2 Momentum:** +10% Schaden für Angriffskarten.
    * **Ab 3 Momentum:** Die Angriffskarte nach einer Schattenkarte verursacht +20% Schaden.
    * **Ab 4 Momentum:** +0,5s Zeitgewinn pro gespielter Karte (Basis). Modifizierbar durch *Zeitsprung* Eis-Evo.
    * *(Zusätzliche Schwellenboni können auf einzelnen Karten definiert sein, z.B. Schattendolch bei 4+)*
* **Bruch / Schattenrausch (bei 5 Momentum):**
    * Auslösung: Erreichen von 5 Momentum.
    * Basis-Effekt: Für die nächsten 5 Sekunden haben alle Karten +25% Effektivität, und das Momentum wird auf 0 zurückgesetzt.
    * Modifikation: Die Stärke (+X% Effektivität) und zusätzliche Effekte während des Bruchs werden durch *Zeitsprung* Feuer-Evo modifiziert.
* **Evolutionen von *Zeitsprung* (gemäß User-Input v1.9):** Die Wahl eines Elementarpfades bei der *Zeitsprung*-Evolution modifiziert Aspekte des Momentum-Systems dauerhaft:
    * **Feuer-Pfad:** Verstärkt den Bruch-Effekt (Schattenrausch).
    * **Eis-Pfad:** Modifiziert Schwellenboni (früherer Eintritt) und die Verfallszeit des Momentums.
    * **Blitz-Pfad:** Verbessert die Momentum-Generierungsrate und fügt einen Bonus bei Bruch hinzu.

## 3. Deckzusammensetzung

### 3.1 Kartenverteilung (Basis: 10 Karten, Deck: 26 Karten)

Basierend auf den 10 verbleibenden einzigartigen Basis-Karten und angepassten Deck-Counts.

| Kategorie          | Karten (Anzahl im Deck)                                            | Anzahl Uniq. | Anteil Deck | Zweck                                      |
| :----------------- | :----------------------------------------------------------------- | :----------- | :---------- | :----------------------------------------- |
| Basisangriffe      | Schattendolch (3), Giftklinge (3)                                  | 2            | 23%         | Primäre Schadensquelle                     |
| Verteidigung/Shadow| Schleier (4), Schattenform (3)                                     | 2            | 27%         | Ausweichen, 0-Kosten-Synergien            |
| Zeitdiebstahl      | Zeitdiebstahl (2), Temporaler Raub (3)                             | 2            | 19%         | Ressourcengewinnung                       |
| Utility/Momentum   | Schattenschritt (4), Schattenkonzentration (2)                     | 2            | 23%         | Kombo-Verbindungen, Momentum-Management   |
| Signaturkarten     | Zeitsprung (1), Schattensturm (1)                                  | 2            | 8%          | Wendepunkt-Fähigkeiten                    |
| **Gesamt** | **(Summe Deck Counts: 3+3 + 4+3 + 2+3 + 4+2 + 1+1 = 26)** | **10** | **100%** | -                                          |

### 3.2 Starterdeck (26 Karten) - Aktualisiert

| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| `Schattendolch` | `CARD-ROG-SHADOWDAGGER` | 3 | 1,0s | **Gewöhnlich** | 3 Schaden. Bei 4+ Momentum: +2 Schaden und ziehe 1 Karte. |
| `Giftklinge` | `CARD-ROG-POISONBLADE` | 3 | 1,5s | **Gewöhnlich** | 2 Schaden + DoT: 1/Sek für 3s. Bei 4+ Momentum: DoT-Schaden +1/Sek und Dauer x1,5. |
| `Schleier` | `CARD-ROG-VEIL` | 4 | 0,5s | **Ungewöhnlich** | Der nächste Angriff verfehlt. |
| `Schattenform` | `CARD-ROG-SHADOWFORM` | 3 | 1,5s | **Selten** | Die nächsten 2 Angriffe verfehlen. Gewinne +0,5s Zeit pro vermiedenem Angriff. |
| `Zeitdiebstahl` | `CARD-ROG-TIMETHEFT` | 2 | 1,0s | **Ungewöhnlich** | Stiehlt 0,5s Zeit vom Gegner. |
| `Temporaler Raub` | `CARD-ROG-TEMPORALTHEFT` | 3 | 1,5s | **Selten** | Stiehlt 1,0s Zeit vom Gegner und verursacht 2 Schaden. |
| `Schattenschritt` | `CARD-ROG-SHADOWSTEP` | 4 | 1,0s | **Selten** | +25% Effekte für nächste Karte. +15% Effekte für übernächste Karte, wenn sie Schaden verursacht. |
| `Schattenkonzentration` | `CARD-ROG-SHADOWFOCUS` | 2 | 1,5s | **Episch** | Generiert +2 Momentum. Bei 4+ Momentum: Ziehe 1 Karte. |
| `Zeitsprung` | `CARD-ROG-TIMESHIFT` | 1 | 3,0s | **Legendär** | Stiehlt 1,5s Zeit und zieht 2 Karten. Wähle einen Evolutionspfad, um das Momentum-System anzupassen. |
| `Schattensturm` | `CARD-ROG-SHADOWSTORM` | 1 | 4,0s | **Legendär** | 8 Schaden auf alle Gegner. +0,5s Zeit pro Treffer. |

### 3.3 Progressives Freischaltsystem

Der Schattenschreiter folgt einem progressiven Kartenfreischaltungssystem, das komplexe Kombomechaniken schrittweise einführt:

#### 3.3.1 Starterdeck (Erste Spielminuten, 8 Karten)
- `Schattendolch` (Gewöhnlich): 2 Kopien
- `Giftklinge` (Gewöhnlich): 2 Kopien
- `Schleier` (Ungewöhnlich): 2 Kopien
- `Zeitdiebstahl` (Ungewöhnlich): 2 Kopien

Dieser Anfangssatz bietet die grundlegenden Werkzeuge des Schattenschreiters: direkte Angriffe (`Schattendolch`), DoT-Schaden (`Giftklinge`), Verteidigung (`Schleier`) und Ressourcengewinnung (`Zeitdiebstahl`).

#### 3.3.2 Kartenfreischaltungssequenz

| Spielfortschritt | Freigeschaltete Karte | Seltenheit | Strategischer Zweck |
|------------------|---------------------|-----------|-------------------|
| Tutorial-Boss (~1h) | `Schattenform` (2×) | Selten | Erweiterte Verteidigung, Schattensynergie |
| Erster Dungeon (~2h) | `Temporaler Raub` (2×) | Selten | Verbesserter Zeitdiebstahl, Ressourcen-Kontrolle |
| Welt 1 Mini-Boss (~3h) | `Schattenschritt` (2×) | Selten | Combo-Verstärkung, Effizienzkarte |
| Welt 1 Boss (~4-6h) | `Zeitsprung` (1×) | Legendär | Erste Signaturkarte, Momentum-System-Modifikation |
| Welt 2 Einführung (~7h) | `Schleier` und `Schattendolch` (+1×/+1×) | Ungewöhnlich | Evolution wird verfügbar, Elementarpfade eröffnet |
| Welt 2 Dungeon (~9h) | `Schattenkonzentration` (2×) | Episch | Direkte Momentum-Manipulation |
| Welt 2 Boss (~10h) | `Schattensturm` (1×) | Legendär | Zweite Signaturkarte, AoE-Macht |
| Welt 3 Start (~12h) | `Schattenschritt` (+2×) | Selten | Erweiterte Kombooptionen |
| Spätere Welten | Weitere Kopien | - | Deckoptimierung und Spezialisierung |

#### 3.3.3 Design-Philosophie

Diese Freischaltungssequenz wurde entwickelt, um:
- Das **Momentum-System** schrittweise zu vermitteln, ohne den Spieler zu überfordern
- Die **Schattensynergie** mit zunehmend komplexeren Kartenkombinationen zu entwickeln
- **Zeitdiebstahl**-Mechaniken als Teil der Klassenidentität zu etablieren
- Mit den legendären Karten besondere Wendepunkte in der Momentum-Mechanik zu markieren

Die vollständige Sammlung von Karten wird innerhalb von ~15-20 Spielstunden erreicht, während das Meistern von Kartensynergien, Evolutionen und optimalen Kombinationen die langfristige Progression darstellt.

## 4. Kartenbeschreibungen und Evolutionen

*(Hinweis: Materialkosten entsprechen ZK-MAT v1.0. Evolutionen für Zeitsprung entsprechen User-Input v1.9, andere `evo ROG.csv`. Abschnittsnummerierung angepasst.)*

### 4.1 Basisangriffe *(alt 4.1 ohne 4.1.3)*

#### 4.1.1 Schattendolch (`CARD-ROG-SHADOWDAGGER`, ID: `92f9284a-5ed9-482d-94a4-77fd2c9086a5`) *(alt 4.1.1)*

* **Basis (aus CSV):** 1.0s, 3 Schaden. Bei 4+ Momentum: +2 Schaden und ziehe 1 Karte.
* **Startdeck:** 3 Karten.
* **Tags:** `["momentum","angriff"]`.
* **Besonderheiten:** *Schattensynergie*.

##### Feuer-Evolution:
| Stufe | ID                                       | Name         | Kosten | Effekt                                                                      | Materialien                                             | DoT-Kategorie   |
| :---- | :--------------------------------------- | :----------- | :----- | :-------------------------------------------------------------------------- | :------------------------------------------------------ | :-------------- |
| 1     | `888c8e4f-624d-4792-8e89-27bf04358bf1`    | Brennender Dolch | 1.0s   | 4 Schaden + DoT: 1 Schaden/Sek für 3s. Bei 4+ Momentum: +2 Schaden und ziehe 1 Karte. | `1× Elementarfragment` | Schwach         |
| 2     | `e435ef00-99cb-455b-943c-45c1f30f9417`    | Ascheklinge      | 1.2s   | 4 Schaden + DoT: 2 Schaden/Sek für 3s. Bei 4+ Momentum: +3 Schaden und ziehe 1 Karte. | `2× Elementarfragment` | Mittel          |
| 3     | `c0feb489-6d3a-49a2-beb3-2847e3864b66`    | Höllenstich      | 1.5s   | 5 Schaden + DoT: 4 Schaden/Sek für 3s. Bei 4+ Momentum: +4 Schaden und ziehe 1 Karte. | `3× Elementarfragment` | Stark           |
##### Eis-Evolution:
| Stufe | ID                                       | Name         | Kosten | Effekt                                                                              | Materialien                                             |
| :---- | :--------------------------------------- | :----------- | :----- | :---------------------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `d9864a0b-decf-4483-b038-69b82b63cee5`    | Frostdolch   | 1.0s   | 3 Schaden. Verlangsamt Gegner um 10% für 3s. Bei 4+ Momentum: +2 Schaden und verlangsamt um 15% für 3s. | `1× Elementarfragment` |
| 2     | `31913e5d-77a5-4949-85c0-a1b5a7c39a86`    | Eisklinge    | 1.2s   | 4 Schaden. Verlangsamt Gegner um 20% für 3s. Bei 4+ Momentum: +3 Schaden und verlangsamt um 25% für 3s. | `2× Elementarfragment` |
| 3     | `84964a58-7229-44ed-813a-337b24020968`    | Absolutstich | 1.5s   | 5 Schaden. Verlangsamt Gegner um 30% für 3s. Bei 4+ Momentum: +4 Schaden und verlangsamt um 40% für 3s. | `3× Elementarfragment` |
##### Blitz-Evolution:
| Stufe | ID                                       | Name           | Kosten | Effekt                                                                                    | Materialien                                             |
| :---- | :--------------------------------------- | :------------- | :----- | :---------------------------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `aafa2cc6-c81a-402d-904e-a568a5112781`    | Blitzdolch     | 1.0s   | 3 Schaden. Kostet 0s bei 3+ Momentum. Bei 4+ Momentum: +2 Schaden, ziehe 1 Karte und +1 Momentum. | `1× Elementarfragment` |
| 2     | `562d6c17-c94a-425e-a628-e64700719706`    | Sturmklinge    | 1.0s   | 4 Schaden. Kostet 0s bei 3+ Momentum. Bei 4+ Momentum: +3 Schaden, ziehe 1 Karte und +1 Momentum. | `2× Elementarfragment` |
| 3     | `d0a78533-4553-402e-9a62-134b902e34ab`    | Gewitterstich  | 1.5s   | 5 Schaden. Kostet 0s bei 3+ Momentum. Bei 4+ Momentum: +4 Schaden, ziehe 1 Karte und +1 Momentum. | `3× Elementarfragment` |

#### 4.1.2 Giftklinge (`CARD-ROG-POISONBLADE`, ID: `3522ea73-539f-4318-80d3-85b7d7a7689c`) *(alt 4.1.2)*

* **Basis (aus CSV):** 1.5s, 2 Schaden + DoT: 1/Sek für 3s. Bei 4+ Momentum: DoT-Schaden +1/Sek und Dauer x1,5.
* **Startdeck:** 3 Karten.
* **Tags:** `["dot","momentum","angriff"]`.
* **DoT-Kategorie:** `ecd0019f-28b3-4a75-83e7-e9ba1892c7a5` (Schwach).
* **Besonderheiten:** *Schattensynergie*.

##### Feuer-Evolution:
| Stufe | ID                                       | Name         | Kosten | Effekt                                                                              | Materialien                                             | DoT-Kategorie   |
| :---- | :--------------------------------------- | :----------- | :----- | :---------------------------------------------------------------------------------- | :------------------------------------------------------ | :-------------- |
| 1     | `33a4e09c-17f9-4c53-842b-21e99421a8dc`    | Königsklinge           | 1.0s   | 2 Schaden + DoT: 2 Schaden/Sek für 4s. Bei 4+ Momentum: DoT erhöht sich auf 3 Schaden/Sek. | `1× Elementarfragment` | Mittel          |
| 2     | `bd2c6da7-5cc5-4b98-99fb-2a8a5f0c7946`    | Toxinklinge             | 1.2s   | 3 Schaden + DoT: 3 Schaden/Sek für 4s. Bei 4+ Momentum: DoT erhöht sich auf 4 Schaden/Sek. | `2× Elementarfragment` | Stark           |
| 3     | `8a62f7e4-ff51-4797-8744-bd58ab6af384`    | Klinge des Weltentodes  | 1.5s   | 4 Schaden + DoT: 4 Schaden/Sek für 4s. Bei 4+ Momentum: DoT erhöht sich auf 6 Schaden/Sek. | `3× Elementarfragment` | Verheerend      |    |
##### Eis-Evolution:
| Stufe | ID                                       | Name             | Kosten | Effekt                                                                                          | Materialien                                             | DoT-Kategorie   |
| :---- | :--------------------------------------- | :--------------- | :----- | :---------------------------------------------------------------------------------------------- | :------------------------------------------------------ | :-------------- |
| 1     | `0a9b8cf2-3986-47f5-86c0-d70bc956e618`    | Frostgiftklinge  | 1.5s   | 2 Schaden + DoT: 1 Schaden/Sek für 3s. Verlangsamt Gegner um 15% für 3s. Bei 4+ Momentum: DoT-Schaden +1/Sek und verlangsamt um 20% für 3s. | `1× Elementarfragment` | Schwach         |
| 2     | `89577b2e-b86a-4db2-8cd2-10482792cfb3`    | Lähmungsklinge   | 2.0s   | 3 Schaden + DoT: 1 Schaden/Sek für 3s. Verlangsamt Gegner um 25% für 3s. Bei 4+ Momentum: DoT-Schaden +1,5/Sek und verlangsamt um 30% für 3s. | `2× Elementarfragment` | Schwach         |
| 3     | `a3a7f904-498c-4396-b8bc-10c501aaad9d`    | Zeitstillklinge  | 2.5s   | 4 Schaden + DoT: 2 Schaden/Sek für 3s. Verlangsamt Gegner um 40% für 3s. Bei 4+ Momentum: DoT-Schaden +2/Sek und verlangsamt um 30% für 3s. | `3× Elementarfragment` | Mittel          |
##### Blitz-Evolution:
| Stufe | ID                                       | Name           | Kosten | Effekt                                                                                             | Materialien                                             | DoT-Kategorie   |
| :---- | :--------------------------------------- | :------------- | :----- | :------------------------------------------------------------------------------------------------- | :------------------------------------------------------ | :-------------- |
| 1     | `eb2dfc17-0557-4f5e-acbb-1e60b5ad7994`    | Schockklinge   | 1.0s   | 2 Schaden + DoT: 1 Schaden/Sek für 3s. Bei 4+ Momentum: DoT-Schaden +1/Sek und +0,5 Momentum pro Sekunde, solange der DoT aktiv ist. | `1× Elementarfragment` | Schwach         |
| 2     | `cb88228b-1495-492e-967d-8a1697b899d8`    | Neuronenklinge | 1.5s   | 3 Schaden + DoT: 2 Schaden/Sek für 3s. Bei 4+ Momentum: DoT-Schaden +1,5/Sek und +1 Momentum pro Sekunde, solange der DoT aktiv ist. | `2× Elementarfragment` | Mittel          |
| 3     | `300ad4d4-955c-4a5f-bd44-f4fea36e22c5`    | Synapsenklinge | 2.0s   | 4 Schaden + DoT: 4 Schaden/Sek für 3s. Bei 4+ Momentum: DoT-Schaden +2/Sek und die nächste Karte kostet 0,5s weniger. | `3× Elementarfragment` | Stark           |

### 4.2 Verteidigung / Schattenkarten *(alt 4.2)*

#### 4.2.1 Schleier (`CARD-ROG-VEIL`, ID: `a0258a2e-b334-4f01-bb40-f48cb9c3fe3d`) *(alt 4.2.1)*

{{ ... }}
* **Basis (aus CSV):** 0.5s, Der nächste Angriff verfehlt.
* **Startdeck:** 4 Karten.
* **Tags:** `["momentum","shadow"]`.
* **Besonderheiten:** Aktiviert *Schattensynergie*.

##### Feuer-Evolution:
| Stufe | ID                                       | Name          | Kosten | Effekt                                                          | Materialien                                             |
| :---- | :--------------------------------------- | :------------ | :----- | :-------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `2fa58424-c12d-4f49-ba69-96a0d958eca5`    | Rauchschleier | 0.5s   | Der nächste Angriff verfehlt. Verursache 1 Schaden auf den Angreifer | `1× Elementarfragment` |
| 2     | `334f0c9b-ad05-4621-b07f-215464a91e84`    | Ascheschleier | 1.0s   | Die nächsten 2 Angriffe verfehlen. Verursache 1 Schaden pro vermiedenem Angriff | `2× Elementarfragment` |
| 3     | `6a6f9d93-2b9f-4f2f-b82f-0032d6dcf5fe`    | Feuerschleier | 1.5s   | Die nächsten 2 Angriffe verfehlen. Verursache 2 Schaden pro vermiedenem Angriff | `3× Elementarfragment` |
##### Eis-Evolution:
| Stufe | ID                                       | Name          | Kosten | Effekt                        | Materialien                                             |
| :---- | :--------------------------------------- | :------------ | :----- | :---------------------------- | :------------------------------------------------------ |
| 1     | `bad4e14e-9e87-4109-8351-74fa1d178ca1`    | Nebelschleier | 0.5s   | Die nächsten 2 Angriffe verfehlen | `1× Elementarfragment` |
| 2     | `844b13ac-14bc-4c3d-a299-333bea97dcaf`    | Frostschleier | 1.0s   | Die nächsten 3 Angriffe verfehlen | `2× Elementarfragment` |
| 3     | `ecea4e28-3bf2-426b-9b47-41a9a600cc41`    | Eisnebel      | 1.5s   | Die nächsten 4 Angriffe verfehlen | `3× Elementarfragment` |
##### Blitz-Evolution:
| Stufe | ID                                       | Name            | Kosten | Effekt                                                         | Materialien                                             |
| :---- | :--------------------------------------- | :-------------- | :----- | :------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `5f309521-1a54-4837-800a-08761824432a`    | Blitzschleier   | 0.5s   | Der nächste Angriff verfehlt. Verlangsamt Angreifer um 15% für 2s. | `1× Elementarfragment` |
| 2     | `d24abb82-4657-4eb5-96e4-2c555991c11a`    | Sturmschleier   | 0.5s   | Der nächste Angriff verfehlt. Verlangsamt Angreifer um 25% für 2s. | `2× Elementarfragment` |
| 3     | `8a8046b5-2405-4183-b5ce-2239cf4dc1b5`    | Gewitterschleier| 1.0s   | Der nächste Angriff verfehlt. Verlangsamt Angreifer um 35% für 2s. | `3× Elementarfragment` |

#### 4.2.2 Schattenform (`CARD-ROG-SHADOWFORM`, ID: `3411cbd8-dec2-4908-8536-3e5eab9a2660`) *(alt 4.2.2)*

* **Basis (aus CSV):** 1.5s, Die nächsten 2 Angriffe verfehlen. Gewinne +0,5s Zeit pro vermiedenem Angriff.
* **Startdeck:** 3 Karten.
* **Tags:** `["momentum","shadow"]`.
* **Besonderheiten:** Aktiviert *Schattensynergie*.

##### Feuer-Evolution:
| Stufe | ID                                       | Name            | Kosten | Effekt                                                          | Materialien                                             |
| :---- | :--------------------------------------- | :-------------- | :----- | :-------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `74fb3a2b-7a72-4aae-89cb-3e2e998de77d`    | Flammenschatten | 1.5s   | Die nächsten 2 Angriffe verfehlen. Verursache 2 Schaden pro vermiedenem Angriff | `1× Elementarfragment` |
| 2     | `0912af4b-23da-4aff-96e0-1e5b1f5c60e8`    | Gluthülle       | 2.0s   | Die nächsten 3 Angriffe verfehlen. Verursache 2 Schaden pro vermiedenem Angriff | `2× Elementarfragment` |
| 3     | `56e50825-05a0-42eb-8e5b-d404a416bcc9`    | Höllenhulle     | 2.5s   | Die nächsten 3 Angriffe verfehlen. Verursache 3 Schaden pro vermiedenem Angriff | `3× Elementarfragment` |
##### Eis-Evolution:
| Stufe | ID                                       | Name          | Kosten | Effekt                                                                      | Materialien                                             |
| :---- | :--------------------------------------- | :------------ | :----- | :-------------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `3787f456-5f43-4cf4-ad6e-cea0e5f56cad`    | Schattenmantel| 1.5s   | Die nächsten 3 Angriffe verfehlen. Gewinne +0,5s Zeit pro vermiedenem Angriff | `1× Elementarfragment` |
| 2     | `8ffb0114-6996-452b-b9af-e8a7f46740cb`    | Nebelmantel   | 2.0s   | Die nächsten 3 Angriffe verfehlen. Gewinne +1,0s Zeit pro vermiedenem Angriff | `2× Elementarfragment` |
| 3     | `77a4e745-74d3-417c-b0d5-b8c372ee3b65`    | Phantomform   | 2.5s   | Die nächsten 4 Angriffe verfehlen. Gewinne +1,0s Zeit pro vermiedenem Angriff | `3× Elementarfragment` |
##### Blitz-Evolution:
| Stufe | ID                                       | Name           | Kosten | Effekt                                                                                 | Materialien                                             |
| :---- | :--------------------------------------- | :------------- | :----- | :------------------------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `8bb69a9e-3456-4788-9d1b-2a2b09ef9544`    | Blitzschatten  | 1.0s   | Die nächsten 2 Angriffe verfehlen. Ziehe 1 Karte pro vermiedenem Angriff                | `1× Elementarfragment` |
| 2     | `84c4cd05-67e3-44f4-a9d8-b7f439c458e9`    | Sturmform      | 1.5s   | Die nächsten 2 Angriffe verfehlen. Ziehe 1 Karte und +1 Momentum pro vermiedenem Angriff | `2× Elementarfragment` |
| 3     | `50171ab0-e082-4b13-befa-665d929b2204`    | Gewitterwandler| 2.0s   | Die nächsten 3 Angriffe verfehlen. Ziehe 1 Karte und +1 Momentum pro vermiedenem Angriff | `3× Elementarfragment` |

### 4.3 Zeitdiebstahlkarten *(alt 4.3)*

#### 4.3.1 Zeitdiebstahl (`CARD-ROG-TIMETHEFT`, ID: `f4b15658-1136-42f2-b7f2-8d396dbd0c3a`) *(alt 4.3.1)*

* **Basis (aus CSV):** 1.0s, Stiehlt 0,5s Zeit vom Gegner.
* **Startdeck:** 2 Karten.
* **Tags:** `["zeitsplitter"]`.

##### Feuer-Evolution:
| Stufe | ID                                       | Name            | Kosten | Effekt                                                          | Materialien                                             | DoT-Kategorie   |
| :---- | :--------------------------------------- | :-------------- | :----- | :-------------------------------------------------------------- | :------------------------------------------------------ | :-------------- |
| 1     | `f87f13b5-1b3d-4801-93a2-5b011fcb3e5c`    | Brennender Raub | 1.0s   | Stiehlt 0,5s Zeit vom Gegner und fügt DoT: 1 Schaden/Sek für 3s hinzu | `1× Elementarfragment` | Schwach         |
| 2     | `fe6cdbe5-0e1f-4c38-b591-122ede045937`    | Glutraub        | 1.5s   | Stiehlt 1,0s Zeit vom Gegner und fügt DoT: 2 Schaden/Sek für 3s hinzu | `2× Elementarfragment` | Mittel          |
| 3     | `84e173ca-95ee-4bff-b4cd-f67ed0bb4e47`    | Feuerraub       | 2.0s   | Stiehlt 1.5s Zeit vom Gegner und fügt DoT: 2 Schaden/Sek für 3s hinzu | `3× Elementarfragment` | Mittel          |
##### Eis-Evolution:
| Stufe | ID                                       | Name          | Kosten | Effekt                                                           | Materialien                                             |
| :---- | :--------------------------------------- | :------------ | :----- | :--------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `c1107b21-045b-4a6d-8f49-f0d8c6bae12c`    | Frostdiebstahl| 1.0s   | Stiehlt 0,5s Zeit vom Gegner und verlangsamt ihn um 10% für 3s | `1× Elementarfragment` |
| 2     | `8960b512-6ba6-4a98-9d1d-9a5e701f49e1`    | Eisraub       | 1.5s   | Stiehlt 0,5s Zeit vom Gegner und verlangsamt ihn um 20% für 3s | `2× Elementarfragment` |
| 3     | `cc06fc9c-960d-46c6-9521-650dc72dc94c`    | Kryoraub     | 2.0s   | Stiehlt 1,0s Zeit vom Gegner und verlangsamt ihn um 30% für 3s | `3× Elementarfragment` |
##### Blitz-Evolution:
| Stufe | ID                                       | Name         | Kosten | Effekt                                                   | Materialien                                             |
| :---- | :--------------------------------------- | :----------- | :----- | :------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `d6c46be7-06ee-4917-bd92-56e03badcd78`    | Blitzraub    | 0.5s   | Stiehlt 0,5s Zeit vom Gegner und generiert +1 Momentum   | `1× Elementarfragment` |
| 2     | `3dae67e6-fd6c-42d5-96c4-9e5cd0542e25`    | Sturmraub    | 1.0s   | Stiehlt 0,5s Zeit vom Gegner und generiert +2 Momentum   | `2× Elementarfragment` |
| 3     | `1e3acaa7-b1e8-4b10-91e9-77e21ade1f6c`    | Gewitterraub | 1.0s   | Stiehlt 1,0s Zeit vom Gegner und generiert +3 Momentum   | `3× Elementarfragment` |

#### 4.3.2 Temporaler Raub (`CARD-ROG-TEMPORALTHEFT`, ID: `57937d13-d345-47a3-a816-696424cafc5a`) *(alt 4.3.2)*

* **Basis (aus CSV):** 1.5s, Stiehlt 1,0s Zeit vom Gegner und verursacht 2 Schaden.
* **Startdeck:** 3 Karten.
* **Tags:** `["zeitsplitter","angriff"]`.

##### Feuer-Evolution:
| Stufe | ID                                       | Name                    | Kosten | Effekt                                                                  | Materialien                                             | DoT-Kategorie   |
| :---- | :--------------------------------------- | :---------------------- | :----- | :---------------------------------------------------------------------- | :------------------------------------------------------ | :-------------- |
| 1     | `aa65b775-cdfb-49df-a298-514d7ef24f7d`    | Feuerraub | 1.5s   | Stiehlt 1,0s Zeit vom Gegner, verursacht 1 Schaden + DoT: 2 Schaden/Sek für 3s | `1× Elementarfragment` | Mittel          |
| 2     | `759485bf-5e0d-47f5-a947-7bc6d4e6d129`    | Ascheraub               | 2.0s   | Stiehlt 1.2s Zeit vom Gegner, verursacht 3 Schaden + DoT: 2 Schaden/Sek für 3s | `2× Elementarfragment` | Mittel          |
| 3     | `b75d5090-99d1-4de3-beec-3db49eb4847e`    | Höllenraub    | 2.5s   | Stiehlt 1.5s Zeit vom Gegner, verursacht 4 Schaden + DoT: 4 Schaden/Sek für 3s | `3× Elementarfragment` | Stark           |
##### Eis-Evolution:
| Stufe | ID                                       | Name                   | Kosten | Effekt                                                                                | Materialien                                             |
| :---- | :--------------------------------------- | :--------------------- | :----- | :------------------------------------------------------------------------------------ | :------------------------------------------------------ |
| 1     | `93f5ed88-ac07-4c14-8313-6fb95d783eff`    | Frost-Temporalraub   | 1.5s   | Stiehlt 1,0s Zeit vom Gegner, verursacht 2 Schaden und verlangsamt ihn um 15% für 3s | `1× Elementarfragment` |
| 2     | `b0902f2b-b665-4bb5-9fcc-90b03cef0bb5`    | Eiskalter Raub         | 2.0s   | Stiehlt 1,0s Zeit vom Gegner, verursacht 3 Schaden und verlangsamt Gegner um 25% für 3s | `2× Elementarfragment` |
| 3     | `eb955a37-540c-4ad0-97bc-2686f11a7383`    | Frostzeitraub     | 2.5s   | Stiehlt 1,5s Zeit vom Gegner und verursacht 4 Schaden. Verlangsamt Gegner um 35% für 3s   | `3× Elementarfragment` |
##### Blitz-Evolution:
| Stufe | ID                                       | Name                 | Kosten | Effekt                                                                 | Materialien                                             |
| :---- | :--------------------------------------- | :------------------- | :----- | :--------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `5b4a5b52-25e2-4264-adac-4f522cbeaf0f`    | Blitz-Temporalraub   | 1.5s   | Stiehlt 1,0s Zeit vom Gegner, verursacht 2 Schaden und zieht 1 Karte | `1× Elementarfragment` |
| 2     | `e469233e-8d1d-4458-8a2f-3f59958e8075`    | Temporaler Sturm     | 1.5s   | Stiehlt 1,0s Zeit vom Gegner, verursacht 3 Schaden und zieht 1 Karte | `2× Elementarfragment` |
| 3     | `e60a5e2f-2122-4b0d-912b-5e9213306d9c`    | Chrono-Blitzeinschlag| 2.0s   | Stiehlt 1,5s Zeit vom Gegner, verursacht 4 Schaden und zieht 2 Karten | `3× Elementarfragment` |

### 4.4 Utility / Momentum Karten *(alt 4.4)*

#### 4.4.1 Schattenschritt (`CARD-ROG-SHADOWSTEP`, ID: `027b6888-0804-4abf-b3f2-debb3dd2bffd`) *(alt 4.4.1)*

* **Basis (aus CSV):** 1.0s, +25% Effekte für nächste Karte. +15% Effekte für übernächste Karte, wenn sie Schaden verursacht.
* **Startdeck:** 4 Karten.
* **Tags:** `[]`.

##### Feuer-Evolution:
| Stufe | ID                                       | Name         | Kosten | Effekt                                                                               | Materialien                                             | DoT-Kategorie   |
| :---- | :--------------------------------------- | :----------- | :----- | :----------------------------------------------------------------------------------- | :------------------------------------------------------ | :-------------- |
| 1     | `2a77f846-5ebc-40b4-9f94-792cf89b0160`    | Feuerschritt | 1.0s   | Die nächste Karte erhält +25% zu allen Effekten. Fügt Angriffen +1 DoT-Schaden/Sek für 3s hinzu | `1× Elementarfragment` | Schwach         |
| 2     | `886dfc18-4047-41e4-8209-3b320eb88553`    | Gluthüpfer   | 1.5s   | Die nächste Karte erhält +30% zu allen Effekten. Fügt Angriffen +2 DoT-Schaden/Sek für 3s hinzu | `2× Elementarfragment` | Mittel          |
| 3     | `9e13c388-3d4b-4c46-b9e9-510ba916789d`    | Flammentanz  | 2.0s   | Die nächste Karte erhält +35% zu allen Effekten. Fügt Angriffen +3 DoT-Schaden/Sek für 3s hinzu | `3× Elementarfragment` | Mittel          |
##### Eis-Evolution:
| Stufe | ID                                       | Name             | Kosten | Effekt                                                               | Materialien                                             |
| :---- | :--------------------------------------- | :--------------- | :----- | :------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `71d7b329-59f8-4b75-bd06-4566710717df`    | Eisschritt       | 1.0s   | Die nächste Karte erhält +25% zu allen Effekten. Der nächste Angriff verfehlt | `1× Elementarfragment` |
| 2     | `226938dc-b074-4796-9a28-f2d711288021`    | Frostgleiter     | 1.5s   | Die nächste Karte erhält +30% zu allen Effekten. Die nächsten 2 Angriffe verfehlen | `2× Elementarfragment` |
| 3     | `73742c8e-6b1f-445a-b77b-b2ddc4c41d93`    | Nullpunktsprung  | 2.0s   | Die nächste Karte erhält +35% zu allen Effekten. Die nächsten 3 Angriffe verfehlen | `3× Elementarfragment` |
##### Blitz-Evolution:
| Stufe | ID                                       | Name           | Kosten | Effekt                                                                | Materialien                                             |
| :---- | :--------------------------------------- | :------------- | :----- | :-------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `5ff8c382-e595-48e4-b356-a2fd69a4878a`    | Blitzschritt   | 1.0s   | Die nächsten 2 Karten erhalten +25% zu allen Effekten. Kostet 0s bei 3+ Momentum | `1× Elementarfragment` |
| 2     | `02f2b68c-aec6-4fd1-a5c7-717d59d4c3e2`    | Quantenschritt | 1.0s   | Die nächsten 3 Karten erhalten +25% zu allen Effekten. Kostet 0s bei 3+ Momentum | `2× Elementarfragment` |
| 3     | `9e96e4e1-eb56-47f5-b603-2ccdfb6e10dd`    | Chronoschritt  | 1.5s   | +35% Effekt für nächste 3 Karten. Zieht 1 Karte. Kostet 0s bei 3+ Momentum.  | `3× Elementarfragment` |

#### 4.4.2 Schattenkonzentration (`CARD-ROG-SHADOWFOCUS`, ID: `805401c4-4bc4-4617-86d0-856629a93cfc`) *(alt 4.4.2)*

* **Basis (aus CSV):** 1.5s, Generiert +2 Momentum. Bei 4+ Momentum: Ziehe 1 Karte.
* **Startdeck:** 2 Karten.
* **Tags:** `["momentum","shadow"]`.
* **Besonderheiten:** Aktiviert *Schattensynergie*.

##### Feuer-Evolution:
| Stufe | ID                                       | Name                     | Kosten | Effekt                                                                                   | Materialien                                             | DoT-Kategorie   |
| :---- | :--------------------------------------- | :----------------------- | :----- | :--------------------------------------------------------------------------------------- | :------------------------------------------------------ | :-------------- |
| 1     | `cc3a50cb-baf5-42b3-951d-d1c97d270689`    | Fokussierte Flamme       | 1.5s   | Generiert +2 Momentum. Bei 4+ Momentum: Ziehe 1 Karte und füge ihr +2 DoT hinzu          | `1× Elementarfragment` | Mittel          |
| 2     | `8892bbe6-150c-4a67-88d6-f22db668b480`    | Brennende Konzentration  | 2.0s   | Generiert +3 Momentum. Bei 4+ Momentum: Ziehe 2 Karten und füge ihnen +3 DoT hinzu       | `2× Elementarfragment` | Mittel          |
| 3     | `5dc46e22-a385-4909-b4e9-b425fbe59724`    | Höllisches Fokus         | 2.5s   | Generiert +3 Momentum. Die nächste Karte mit DoT erhält +4 DoT-Schaden/Sek und wird auf alle Gegner angewendet | `3× Elementarfragment` | Stark           |
##### Eis-Evolution:
| Stufe | ID                                       | Name                 | Kosten | Effekt                                                                                          | Materialien                                             |
| :---- | :--------------------------------------- | :------------------- | :----- | :----------------------------------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `892a7da7-37ce-458a-b97a-f099749eb629`    | Frostfokus           | 1.5s   | Generiert +2 Momentum. Bei 4+ Momentum: Ziehe 1 Karte und der nächste Angriff verlangsamt um 15% für 3s | `1× Elementarfragment` |
| 2     | `fb0c7bee-1ff8-4573-b833-dbb552b24669`    | Eisige Präzision     | 1.5s   | Generiert +2 Momentum. Bei 4+ Momentum: Ziehe 2 Karten und verlangsame Gegner um 20% für 3s        | `2× Elementarfragment` |
| 3     | `e86ab849-5398-4954-b404-26f89c568851`    | Kryokonzentration| 2.0s   | Generiert +3 Momentum. Bei 5 Momentum: Nächste Karte kostet 0s und erhält +100% zu allen Effekten     | `3× Elementarfragment` |
##### Blitz-Evolution:
| Stufe | ID                                       | Name           | Kosten | Effekt                                                                                 | Materialien                                             |
| :---- | :--------------------------------------- | :------------- | :----- | :------------------------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `6446f490-101a-49c9-805a-cbdc7b38d408`    | Gedankenblitz  | 1.0s   | Generiert +3 Momentum. Ziehe 1 Karte für jede Karte im Zug mit 0s Kosten              | `1× Elementarfragment` |
| 2     | `dbbf6835-659d-406b-a331-a1d62454ffc4`    | Neuronenfokus  | 1.5s   | Generiert +3 Momentum. Momentum verfällt für die nächsten 4s nicht                   | `2× Elementarfragment` |
| 3     | `db52559a-5a5b-40e3-8a27-753f43f7c762`    | Gedankensturm  | 2.5s   | Generiert +4 Momentum. Ziehe 3 Karten. Die nächsten 2 Karten kosten jeweils 0,5s weniger | `3× Elementarfragment` |

### 4.5 Signaturkarten *(alt 4.5)*

#### 4.5.1 Zeitsprung (`CARD-ROG-TIMESHIFT`, ID: `816ec03a-3011-4f99-986a-083127eaa24c`) *(alt 4.5.1)*

* **Basis (aus CSV):** 3.0s, Stiehlt 1,5s Zeit und zieht 2 Karten. **Wähle einen Evolutionspfad (Feuer/Eis/Blitz), um das globale Momentum-System anzupassen.**
* **Startdeck:** 1 Karte.
* **Tags:** `["zeitsplitter"]`.
* **Anmerkung:** Die folgenden Evolutionseffekte entsprechen User-Input v1.9 und überschreiben die Daten aus `evo ROG.csv`. Namen und Zeitkosten stammen weiterhin aus `evo ROG.csv` und benötigen ggf. Anpassung an die neuen Effekte.

##### Feuer-Evolution: Verstärkt den Bruch-Effekt (Schattenrausch)
| Stufe | ID                                       | Name                     | Kosten | Effekt                                                                                                               | Materialien                                             | DoT-Kategorie   |
| :---- | :--------------------------------------- | :----------------------- | :----- | :------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------ | :-------------- |
| 1     | `53fd5823-f386-4d95-abcd-f68a002c5f8f`    | Brennender Zeitsprung    | 3.0s   | Bruch-Effekt (Schattenrausch): Für 5 Sekunden +35% Effektivität für alle Karten.                                     | `1× Elementarfragment` | -               |
| 2     | `eb56e172-c37b-4e8c-9aac-c74d302b23bf`    | Infernaler Zeitsprung    | 3.5s   | Bruch-Effekt (Schattenrausch): Für 5 Sekunden +40% Effektivität für alle Karten.                                     | `2× Elementarfragment` | -               |
| 3     | `c4c6e56c-34d9-4b4f-9087-23a5562ce0f0`    | Endzeitsprung| 4.0s   | Bruch-Effekt (Schattenrausch): Für 5 Sekunden +45% Effektivität für alle Karten **und** +1 DoT auf alle Angriffskarten währenddessen. | `3× Elementarfragment` | Schwach         |
##### Eis-Evolution: Modifiziert Momentum-Schwellen und -Verfall
| Stufe | ID                                       | Name                | Kosten | Effekt                                                                                                          | Materialien                                             |
| :---- | :--------------------------------------- | :------------------ | :----- | :-------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `a8799f1d-b5ec-43e8-b8b8-cf65c74d2d6b`    | Frostzeitsprung     | 3.0s   | Momentum-Schwellenboni treten 1 Momentum früher ein (z.B. +10% Schaden ab 1 Mom).                               | `1× Elementarfragment` |
| 2     | `d6a41e62-eb17-47a9-bbce-a60ef3bbc993`    | Eiszeit             | 3.5s   | Momentum-Schwellenboni treten 1 Momentum früher ein **und** Momentum-Verfallszeit erhöht sich auf 4 Sekunden (von 3s). | `2× Elementarfragment` |
| 3     | `3e7db5b1-4bc4-473d-b5ba-3105cc7c1a35`    | Ewiger Frostsprung  | 4.0s   | Momentum-Schwellenboni treten 1 Momentum früher ein, Verfallszeit erhöht sich auf 5 Sekunden **und** bei 4+ Momentum: +1,0s Zeitgewinn pro Karte (statt +0,5s). | `3× Elementarfragment` |
##### Blitz-Evolution: Verbessert Momentum-Generierung
| Stufe | ID                                       | Name               | Kosten | Effekt                                                                                        | Materialien                                             |
| :---- | :--------------------------------------- | :----------------- | :----- | :-------------------------------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `0a8ae73e-e290-47b9-80cd-3c099d7b415b`    | Blitzzeitsprung    | 2.5s   | Jede 3. gespielte Karte generiert +1 zusätzliches Momentum.                                     | `1× Elementarfragment` |
| 2     | `d9cf514c-690b-433d-b448-84c2ec0ccaa0`    | Temposhocksprung   | 3.0s   | Jede 2. gespielte Karte generiert +1 zusätzliches Momentum.                                     | `2× Elementarfragment` |
| 3     | `d215afad-410e-4cdc-92d5-72eab677a360`    | Chronosturmsprung  | 3.5s   | Jede gespielte Karte generiert +1 zusätzliches Momentum **und** bei Bruch: Nächste 2 Karten kosten 0 Zeit. | `3× Elementarfragment` |

#### 4.5.2 Schattensturm (`CARD-ROG-SHADOWSTORM`, ID: `76972e48-05ac-4e01-a9d4-c6f1cf43f18a`) *(alt 4.5.2)*

* **Basis (aus CSV):** 4.0s, 8 Schaden auf alle Gegner. +0,5s Zeit pro Treffer.
* **Startdeck:** 1 Karte.
* **Tags:** `["aoe","angriff"]`.

##### Feuer-Evolution:
| Stufe | ID                                       | Name              | Kosten | Effekt                                                                               | Materialien                                             | DoT-Kategorie   |
| :---- | :--------------------------------------- | :---------------- | :----- | :----------------------------------------------------------------------------------- | :------------------------------------------------------ | :-------------- |
| 1     | `fdde884a-5e5c-4f6e-9cb7-6d804f8bf7eb`    | Feuersturm        | 4.0s   | 10 Schaden auf alle Gegner. Gewinne +0,5s Zeit pro Treffer. Fügt +3 DoT-Schaden/Sek für 3s hinzu | `1× Elementarfragment` | Mittel          |
| 2     | `6215e708-554c-486b-93b3-64c76a86947e`    | Inferno           | 5.0s   | 12 Schaden auf alle Gegner. Gewinne +1,0s Zeit pro Treffer. Fügt +4 DoT-Schaden/Sek für 3s hinzu | `2× Elementarfragment` | Stark           |
| 3     | `799f91b4-4a8d-417d-a04a-3053814f9f43`    | Höllenfeuersturm  | 5.0s   | 14 Schaden auf alle Gegner. Gewinne +1,5s Zeit pro Treffer. Fügt +5 DoT-Schaden/Sek für 3s hinzu | `3× Elementarfragment` | Stark+          |
##### Eis-Evolution:
| Stufe | ID                                       | Name                 | Kosten | Effekt                                                                                  | Materialien                                             |
| :---- | :--------------------------------------- | :------------------- | :----- | :-------------------------------------------------------------------------------------- | :------------------------------------------------------ |
| 1     | `23351d4d-f639-413d-8e08-f2629db39545`    | Frostsphäre          | 4.0s   | 9 Schaden auf alle Gegner. Gewinne +0,5s Zeit pro Treffer. Verlangsamt Gegner um 30% für 3s | `1× Elementarfragment` |
| 2     | `069aa8e7-554e-4958-996e-5756060b2ac4`    | Absoluter Nullpunkt  | 5.0s   | 10 Schaden auf alle Gegner. Gewinne +1,0s Zeit pro Treffer. Verlangsamt Gegner um 50% für 3s| `2× Elementarfragment` |
| 3     | `8d18630a-acc7-4db9-9eb7-5e04898b9253`    | Polarkatastrophe     | 5.0s   | 11 Schaden auf alle Gegner. Gewinne +1,5s Zeit pro Treffer. Verlangsamt Gegner um 70% für 3s| `3× Elementarfragment` |
##### Blitz-Evolution:
| Stufe | ID                                       | Name          | Kosten | Effekt                                                                                 | Materialien                                             | Chain Eff. (%) |
| :---- | :--------------------------------------- | :------------ | :----- | :------------------------------------------------------------------------------------- | :------------------------------------------------------ | :------------- |
| 1     | `487450de-525c-4b60-85f6-7b24ca4cfc50`    | Blitzsphäre   | 3.5s   | 8 Schaden auf alle Gegner. Gewinne +0,5s Zeit und ziehe 1 Karte pro Treffer            | `1× Elementarfragment` | 70.00          |
| 2     | `bca8821d-5e8e-4d6d-875c-ce223846bc19`    | Hyperblitz    | 4.0s   | 9 Schaden auf alle Gegner. Gewinne +0,5s Zeit, ziehe 1 Karte und +1 Momentum pro Treffer | `2× Elementarfragment` | 70.00          |
| 3     | `b7a66a61-8330-438b-a81b-d81d4a8da8b3`    | Ultrablitz    | 4.5s   | 10 Schaden auf alle Gegner. Gewinne +0,5s Zeit, ziehe 2 Karten und +2 Momentum pro Treffer | `3× Elementarfragment` | 70.00          |

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

Der Schattenschreiter ist eine Klasse, die auf Geschwindigkeit, präzises Timing und das Ausnutzen kurzer Gelegenheitsfenster setzt.

* **Kernspielweise:** Ziel ist es, durch schnelles Spielen von Karten Momentum aufzubauen und dieses für verstärkte Effekte (siehe Schwellenboni in 2.1 und auf Karten) oder den mächtigen "Schattenrausch"-Bruch zu nutzen. Zeitdiebstahl ist entscheidend, um die benötigte Aktionszeit für lange Kombos zu generieren.
* **Momentum Management:** Spieler müssen abwägen, ob sie niedrige Schwellenboni nutzen oder bis zum Bruch bei 5 Momentum aufbauen wollen. Die gewählte *Zeitsprung*-Evolution beeinflusst diese Entscheidung maßgeblich (Fokus auf Bruch, frühere Boni, oder schnellere Generierung).
* **Schatten-Interaktion:** Schattenkarten aktivieren eine Schattensynergie, die dazu führt, dass die nächste *Angriffskarte* 0 Zeit kostet. Zusätzlich gibt es einen Bonus von +20% Schaden für Angriffe, die auf Schattenkarten folgen, wenn der Spieler 3+ Momentum hat.
* **DoT-Management:** Die verbleibende Giftkarte (`Giftklinge`) bietet Schaden über Zeit. Ihre Effektivität kann durch Momentum (Basis-Effekt) und Feuer-Evolutionen gesteigert werden. *Zeitsprung* Feuer-Evo kann ebenfalls DoTs hinzufügen. *(Angepasst v2.3)*
* **Überleben:** Die Klasse ist fragil und verlässt sich auf das Vermeiden von Angriffen durch *Schleier*, *Schattenform* und deren Evolutionen.
* **Skill Cap:** Die Klasse belohnt Spieler, die Kartenreihenfolgen planen, Synergien optimal nutzen und schnell auf die Spielsituation reagieren können.

## 7. Beispiel-Kombos

*(Hinweis: Diese Kombos sind Beispiele und müssen dringend auf Basis der präzisierten Regeln (insb. Momentum-Kosten für Schattenkarten) überarbeitet und auf Effektivität geprüft werden. Giftpfeil wurde entfernt.)*

* **Einführungs-Kombo (geringes Momentum):**
    1.  `Schleier` (0.5s) -> +1 Mom (Total 1) -> löst Synergie aus
    2.  `Schattendolch` (1.0s -> 0s dank Synergie) -> +1 Mom (Total 2) -> 3 Schaden
    3.  `Zeitdiebstahl` (1.0s, stiehlt 0.5s) -> +1 Mom (Total 3) -> Netto +0.5s
* **Momentum Aufbau & Nutzung (mittleres Momentum):** *(Angepasst v2.3)*
    1.  Start bei Mom 2.
    2.  `Schattenkonzentration` (1.5s) -> +1 Mom (Total 3). Karte ziehen? (4+ benötigt). Schattenkarten kosten jetzt 0 Zeit / -2 Mom.
    3.  `Schleier` (Zeit 0s, Mom -2) -> +1 Mom (Netto -1, Total 2). Löst Synergie aus.
    4.  `Giftklinge` (Zeit 0s dank Synergie, Base 1.5s) -> +1 Mom (Total 3). Schaden und DoT.
* **Schattenrausch-Burst (nach Bruch bei 5 Momentum, mit Zeitsprung Feuer-Evo Lvl 3):**
    1.  Momentum 5 -> Schattenrausch (+45% Effektivität für 5s) -> Mom 0
    2.  `Schattensturm` (4.0s -> ~2.2s?, 8 Schaden AoE + DoT(Schwach), +0.5s Zeit pro Treffer + DoT(Schwach)) -> +1 Mom
    3.  `Temporaler Raub` (1.5s -> ~0.8s?, Stiehlt 1.0s Zeit, 2 Schaden + DoT(Schwach)) -> +1 Mom
    4.  ...

## 8. Klassenspezifische Synergien

* **Momentum:** Die zentrale Ressource. Wird durch Karten generiert (+1 pro Karte, modifiziert durch *Zeitsprung* Blitz-Evo). Löst Schwellenboni aus (siehe 2.1) und bei 5 den Schattenrausch (Bruch). Verfall und Schwellen modifizierbar durch *Zeitsprung* Eis-Evo. Stärke des Bruch modifizierbar durch *Zeitsprung* Feuer-Evo.
* **Schatten-Interaktion:** Diese Mechaniken wirken zusammen:
    1.  **Momentum-Bonus (>= 3):** Schattenkarten kosten 0 Zeit, verbrauchen aber 2 Momentum beim Ausspielen (Netto -1 Momentum pro Schattenkarte).
    2.  **Schattensynergie (Auslöser: Schattenkarte spielen):** Macht die nächste *Angriffskarte* kostenlos (0 Zeitkosten).
    Dies ermöglicht ab 3 Momentum potenziell sehr mächtige, zeitsparende Komboketten, die jedoch Momentum kosten.
* **Zeitdiebstahl:** Gewinnt Zeit hinzu (`zeitsplitter`-Tag), was längere Züge ermöglicht. Kann durch den 4+ Momentum Bonus (+0.5s/Karte, modifizierbar durch *Zeitsprung* Eis-Evo) ergänzt werden.
* **DoTs:** Schaden über Zeit (`dot`-Tag) wird primär durch `Giftklinge` repräsentiert. Kann durch Momentum (Basis-Effekt) oder Feuer-Evolutionen gesteigert werden. *Zeitsprung* Feuer-Evo Lvl 3 fügt DoTs während des Bruch hinzu. *(Angepasst v2.3)*

## 9. UI/UX Hinweise

### 9.1 Momentum-Anzeige

* Klare Anzeige des aktuellen Momentum-Levels (0-5).
* Deutliche Hervorhebung aktiver Schwellenboni (z.B. Icons für +10% Schaden, 0 Zeit/-2 Mom für Schatten, +Zeitgewinn).
* Deutliche Hervorhebung, wenn der Bruch-Effekt (Schattenrausch) aktiv wird (visueller Effekt, Timer für die Dauer, Anzeige der aktuellen Effektivitätssteigerung).
* Indikator für den drohenden Verfall (Timer/Blinken nach X Sekunden Inaktivität, wobei X von Zeitsprung Eis-Evo abhängt).

### 9.2 Schattensynergie / Momentum 3 Feedback

* Visuelles Feedback, wenn Schattensynergie für die nächste Angriffskarte aktiv ist.
* Klare Anzeige der 0 Zeitkosten auf der nächsten gültigen Angriffskarte (Synergie).
* Klare Anzeige der 0 Zeitkosten **und** des -2 Momentum Verbrauchs auf Schattenkarten auf der Hand, wenn Momentum >= 3 ist.

### 9.3 DoT-Visualisierung

* Konsistente Icons/Farbeffekte auf Gegnern.
* Unterschiedliche Intensität/Farbe je nach DoT-Stärke (Schwach, Mittel, Stark, Stark+), basierend auf `dot_categories_rows-4.csv`:
    * Schwach (`ecd0019f...`): Leichter violetter Effekt (#8A2BE2).
    * Mittel (`ed08f7d9...`): Intensiver violetter Effekt (#9400D3).
    * Stark (`6d756b9b...`): Dunkelvioletter Effekt mit Partikeln (#8B008B).
    * Stark+ (`1b1ba49a...`): Dunkelrot mit pulsierendem Rand (#8B0000).
* Anzeige der verbleibenden DoT-Dauer.

### 9.4 Zeitmanipulations-Feedback

* Deutliches visuelles und auditives Feedback bei Zeitdiebstahl und Zeitgewinn durch Momentum.
* Klar erkennbare Änderungen an der Zeit-UI des Gegners und des Spielers.

## 10. Quellendokumente

* `cards_rows-16.csv`: Definitive Datenquelle für die 10 Basis-Karten (nach Entfernung Giftpfeil).
* `evo ROG.csv`: Definitive Datenquelle für die Evolutionen - **AUSSER Zeitsprung und Giftpfeil**.
* `User Input (v1.9 / v2.1 Request)`: Quelle für Momentum-Details (2.1) und Zeitsprung-Evolutionen (4.5.1) sowie Klärung der Synergie-Regeln.
* `dot_categories_rows-4.csv`: Definition der DoT-Kategorien.
* `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`: Vereinfachtes Materialsystem mit vier klar definierten Materialtypen und dem "1 Zeitkern = 1 Level"-Prinzip.
* `classes_rows-5.csv`: Quelle für Klassen-ID und Namen.

## 11. Abhängige Dokumente

* `ZK-WORLDS-v1.0-20250327` : Weltensystem (Akt 1).
* `ZK-DUN-MECH-v1.0-20250327` : Weltmechaniken.
* `ZK-BAL-v1.1-20250327` : Balance-Framework.
* `ZK-TIME-v1.1-20250327` : Zeitsystem.
* `ZK-COMBAT-SYS` : Kampfsystem (für Kritische Restzeit Details).

## 12. Anmerkungen

* **Zeitsprung Evo Details:** Namen und Zeitkosten für die Zeitsprung-Evolutionen wurden aus `evo ROG.csv` beibehalten, passen aber möglicherweise nicht mehr optimal zu den neuen Effekten und sollten ggf. überarbeitet werden.
* **Spielstil/Kombos:** Abschnitte 6 und 7 wurden angepasst, um die Entfernung von `Giftpfeil` zu reflektieren, benötigen aber Playtesting.
* **DoT-Kategorien:** *(Anmerkung über fehlende IDs bleibt, falls relevant für andere Karten)*.