# Zeitwächter-Klasse Artefakt (ZK-CLASS-WAR-ARTIFACT-v2.1-20250522)

## Änderungshistorie
+ **v2.1 (2025-05-22):** Standardisierung der Evolutionskosten auf 1x/2x/3x Elementarfragment für Stufe 1/2/3. Vollständige Entfernung von 'Seltene Essenz' aus allen Evolutionskosten. Anpassung der Materialbeschreibungen, um das System mit drei Kern-Materialien (Zeitkern, Elementarfragment, Zeitfokus) zu reflektieren.
+ **v2.0 (2025-05-22):** Finalisierung der Materialsystem-Umstellung. Fokus auf drei Kern-Typen (Zeitkern, Elementarfragment, Zeitfokus) unter Entfernung von 'Sockelstein'. Rolle von 'Seltene Essenz' als allgemeines Evolutionsmaterial entfernt. Versionsanpassung auf v2.0.
+ **v1.9 (2025-05-21):** Integration des vereinfachten Materialsystems mit Fokus auf Kern-Materialtypen (Zeitkern, Elementarfragment, Zeitfokus). 'Seltene Essenz' nicht mehr als generelles Evolutionsmaterial für alle Stufen vorgesehen. Umstellung auf das "1 Zeitkern = 1 Level"-Prinzip. Anpassung aller Materialkosten für Evolutionen. Entfernung aller Verweise auf veraltete Materialien und XP-System.
- **v1.8.5 (2025-05-12):** Schildmacht und Schildbruch Mechaniken basierend auf v1.8.2 Spezifikationen wiederhergestellt (Max 5 SM, +1SM/Block, spezifische passive Boni und 'Schildbruch' bei 5 SM). Phasenwechsel-Bonus bleibt als Ersatz für Schild-Schwert-Zyklus bestehen und koexistiert.
- **v1.8.4 (2025-05-10):** Entfernung der Mechanik 'Schild-Schwert-Zyklus' und Einführung des neuen Phasenwechsel-Bonus für Angriffs-/Verteidigungsfolgen.
- **v1.8.3 (2025-04-21):** Überarbeitung von Abschnitt 4.3.3 (Wächterblick): Ersetzung der neutralen Evolution durch drei Elementarpfade (Feuer, Eis, Blitz) gemäß Anforderung. Anpassung der Effekte und Materialkosten an ZK-MAT v1.0 und 0,5s-Schritte.
- v1.8.1 (2025-04-19): Anpassung der Kartenanzahl in Abschnitt 3.1 und 3.2 zur Behebung der Inkonsistenz zwischen Detailauflistung (Summe 25) und Gesamtziel (26 Karten). Erhöhung von `Wächterblick` von 1 auf 2 Kopien. (Vorschlag: Der Dokumentar)
- v1.6 (2025-04-18): Entfernung von Abschnitt 4.2.4 (*Ewige Unendlichkeit*) und 4.3.4 (*Zeitwächter-Meisterschaft*) gemäß Änderungshistorie v1.1. Ersetzung der Kombo „Ewige Verteidigung“ durch „Zeitliche Barrikade“ in Abschnitt 6.2. Hinzufügung der Blitz-Evolutionen für *Zeitparade* in Abschnitt 4.3.1. Anpassung der Abschnittsnummerierung (4.3 → 4.2, 4.4 → 4.3). Korrektur der Deckzusammensetzung auf 26 Karten (Tippfehler „25 Karten“ in v1.1 korrigiert). Abgleich der Materialanforderungen mit `ZK-MAT-v1.0-.md`, Entfernung veralteter Materialien (z. B. Phönixfeder) und spezieller Materialien (z. B. Schattenstaub).
- v1.5 (2025-04-17): Reduktion der Signaturkarten auf 2 (Zeitfestung, Zeitparade), Verschiebung/Entfernung der übrigen Karten für Balance und Konsistenz. Anpassung der Startdeck-Zusammensetzung und aller Tabellen.
- v1.4 (2025-04-15): Umbenennung von Karten zur Vermeidung von Dubletten mit ROG-Karten.
- v1.0 (2025-04-17): Initiale Version. Zusammenführung von ZK-CLASS-WAR-COMP-v1.1-20250327 und ZK-CLASS-WAR-CARDS-COMP-v1.2-20250415. Integration der standardisierten Materialanforderungen aus ZK-MAT-COMPLETE-v1.0-20250417. Integration der Reduzierung auf 2 Signaturkarten und Entfernung spezifischer Karten. Anpassung Deckzusammensetzung initial auf 25 Karten.

## Zusammenfassung
Dieses Dokument dient als zentrales Artefakt für die Zeitwächter (WAR) Klasse. Es konsolidiert die Klassenidentität, Mechaniken, Deckzusammensetzung und detaillierte Kartenspezifikationen, einschließlich der aktualisierten Evolutionspfade und Materialkosten gemäß dem vereinfachten Materialsystem aus `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md` (mit Fokus auf Zeitkern, Elementarfragment und Zeitfokus). Der Zeitwächter ist eine Krieger-Klasse, die defensive Stärke mit Zeitkontrolle verbindet, charakterisiert durch Zeitverteidigung, Reflektionseffekte, die strategische Nutzung der **Phasenwechsel-Boni** sowie die mächtige **Schildmacht** und den daraus resultierenden **Schildbruch (Schildbruch)**. Dieses Dokument reflektiert das vereinfachte Materialsystem, das "1 Zeitkern = 1 Level"-Prinzip und die finale Deckgröße von 26 Karten.

## 1. Klassenidentität

### 1.1 Kernelemente
- **Defensive Zeitkontrolle**: Schutz eigener Zeit durch Blockaden und Zeitdiebstahl-Reduktion
- **Reflektive Kriegsführung**: Nutzen gegnerischer Angriffe zu eigenem Vorteil
- **Methodische Eskalation**: Strategische Nutzung der Phasenwechsel-Boni und Aufbau von Schildmacht
- **Überlebensfähigkeit**: Höhere Fehlertoleranz, besonders bei geringer Restzeit
- **Chrono-Manipulation**: Einsatz von Schildmacht für passive Boni und mächtige Chrono-Brüche

### 1.2 Psychologische Spielermotivation
- **Achiever**: Klare Kombo-Belohnungen, sichtbare defensive Erfolge, Timing der Phasenwechsel-Boni, Freischalten des Schildbruchs.
- **Explorer**: Synergien zwischen Verteidigung und Angriff entdecken, Timing der Phasenwechsel-Boni, Management der Schildmacht.
- **Socializer**: Auffällige Verteidigungseffekte und Reflexionen, starke Boni durch den Phasenwechsel, imposanter Schildbruch.
- **Killer**: Timing-basierte Blocks und Konter-Kombos, strategischer Einsatz der Phasenwechsel-Boni und des Schildbruchs.

## 2. Klassenspezifische Mechaniken

### 2.1 Phasenwechsel-Bonus (Kernmechanik)

Die Kernmechanik des Zeitwächters basiert auf einem direkten Wechsel zwischen Angriffs- und Verteidigungsphasen, wobei jede Phase die nächste, entgegengesetzte Phase verstärkt:
*   **Nach Verteidigungskarte:** Die nächste gespielte Angriffskarte erhält **+15% Schaden**.
*   **Nach Angriffskarte:** Die nächste gespielte Verteidigungskarte gewährt **+1 Sekunde Zeitgewinn**.

### 2.2 Schildmacht (SM)

- **Grundlagen:**
  - Zeitwächter können maximal **5 Schildmachtpunkte** ansammeln.
  - Sie starten den Kampf mit 0 SM.
- **Aufbau von Schildmacht:**
  - **Basis-Generierung: Grundsätzlich generiert jeder erfolgreiche Block +1 Schildmacht.**
  - Bestimmte Evolutionen von `Wächterblick` (insbesondere Blitz-Pfad) generieren zusätzlich oder modifiziert SM.
  - Einige Evolutionen von `Zeitfestung` (insbesondere Blitz-Pfad) können die SM-Generierung weiter modifizieren.
- **Passive kumulative Effekte durch angesammelte Schildmacht:**
  - **Ab 2 SM:** +0,5s Zeitrückgewinn (beim Ausspielen von Block-Karten).
  - **Ab 3 SM:** +1 Schaden (beim Ausspielen von Angriffskarten). *(Der 2-Punkte-Bonus bleibt ebenfalls aktiv).*
  - **Ab 4 SM:** Immunität gegen den nächsten Zeitdiebstahl-Effekt. *(Alle vorherigen Boni bleiben ebenfalls aktiv).*
  - Bei Erreichen von 5 SM werden alle passiven Boni durch den Schildbruch ersetzt/verbraucht.

### 2.3 Schildbruch (Schildbruch)

- **Auslösung:** Wird automatisch ausgelöst, sobald **5 Schildmachtpunkte** erreicht werden.
- **Effekt (Basis "Schildbruch"):** Verursacht **15 direkten Schaden** beim Gegner und **stiehlt +2,0s Zeit**.
- **Nach dem Bruch:** Die Schildmacht wird sofort auf **0 zurückgesetzt**. Alle passiven Boni (von 2, 3, 4 SM) sind deaktiviert, bis erneut Energie gesammelt wird.
- **Modifikation:** Die Effekte des Schildbruchs (Schildbruch) können durch verschiedene Evolutionen der `Zeitfestung`-Karte modifiziert und verstärkt werden (z.B. erhöhter Schaden, stärkere Debuffs oder zusätzliche Buffs für den Zeitwächter).

## 3. Deckzusammensetzung (26 Karten)

### 3.1 Kartenverteilung (Basis - *aktualisiert v1.8.1*)
| Kategorie          | Anzahl   | Anteil | Zweck                             |
|--------------------|----------|--------|-----------------------------------|
| Basisangriffe      | 12 (8+4) | ~46%   | Primäre Schadensquelle            |
| Verteidigungskarten | 6 (4+1+1)| ~23%   | Defensive, Zeitschutz             |
| Zeitmanipulation   | 6 (2+2+2)| ~23%   | Kontrolle, Effizienz, Zeitgewinn  |
| Signaturkarten     | 2 (1+1)  | ~8%    | Identitätsträger, Spezialisierung  |
| **Gesamt** | **26** | 100%   |                                   |
*(Hinweis: Ab v1.5 besitzt der Zeitwächter wie alle Klassen nur noch 2 Signaturkarten: Zeitfestung und Zeitparade. Die übrigen wurden verschoben oder entfernt. Die Deckzusammensetzung ist entsprechend angepasst.)*

### 3.2 Starterdeck (26 Karten) - Aktualisiert

| Karte | ID | Anzahl | Zeitkosten | Seltenheit | Effekt |
|-------|----|---------|-----------|-----------|--------------------|
| `Schwertschlag` | `CARD-WAR-SWORDSLASH` | 8 | 2,5s | **Gewöhnlich** | 5 Schaden |
| `Schildschlag` | `CARD-WAR-SHIELDSLASH` | 4 | 2,5s | **Gewöhnlich** | 5 Schaden + 15% Zeitdiebstahlschutz (2s) |
| `Zeitblock` | `CARD-WAR-TIMESHIELD` | 4 | 2,5s | **Ungewöhnlich** | Blockt nächsten Angriff (4s) + 0,5s Rückgewinn |
| `Zeitbarriere` | `CARD-WAR-TIMEBARRIER` | 1 | 3,5s | **Episch** | -30% Zeitdiebstahl (5s) |
| `Zeitkürass` | `CARD-WAR-TEMPORALARMOR` | 1 | 3,0s | **Selten** | Reflektiert 25% des nächsten Zeitdiebstahls |
| `Zeitfessel` | `CARD-WAR-TIMEFETTER` | 2 | 2,5s | **Ungewöhnlich** | +3s Gegnerverzögerung |
| `Vorlauf` | `CARD-WAR-TEMPORALEFFICIENCY` | 2 | 3,0s | **Selten** | Nächste Verteidigungskarte -1,0s |
| `Wächterblick` | `CARD-WAR-WARDERFOCUS` | 2 | 2,0s | **Episch** | +1,5s Zeitgewinn bei erfolgreicher Verteidigung |
| `Zeitparade` | `CARD-WAR-TEMPORALCOUNTER` | 1 | 4,0s | **Legendär** | Reflektiert nächsten Zeitdiebstahl + 6 Schaden |
| `Zeitfestung` | `CARD-WAR-TIMEFORTRESS` | 1 | 5,0s | **Legendär** | +4s, 30% Zeitdiebstahlreduktion (6s), +1 Karte |

*(Hinweis: Die Startdeck-Zusammensetzung wurde an die neue Signaturkartenregel und die finale Deckgröße von 26 Karten angepasst. Wächterblick ist jetzt Zeitmanipulation.)*

### 3.3 Progressives Freischaltsystem

Der Zeitwächter folgt dem "Progressive Unlock"-Design-Paradigma, bei dem Karten schrittweise freigeschaltet werden, um eine klare Lernkurve und bedeutungsvolle Momente zu schaffen:

#### 3.3.1 Starterdeck (Erste Spielminuten, 8 Karten)
- `Schwertschlag` (Gewöhnlich): 4 Kopien
- `Schildschlag` (Gewöhnlich): 2 Kopien
- `Zeitblock` (Ungewöhnlich): 2 Kopien

Diese Basiskonfiguration bietet offensive Grundlagen (`Schwertschlag`), defensive Offensive (`Schildschlag`) und reine Verteidigung (`Zeitblock`), perfekt für das Erlernen des Phasenwechsel-Bonus.

#### 3.3.2 Kartenfreischaltungssequenz

| Spielfortschritt | Freigeschaltete Karte | Seltenheit | Strategischer Zweck |
|------------------|---------------------|-----------|-------------------|
| Tutorial-Boss (~1h) | `Zeitfessel` (2×) | Ungewöhnlich | Erste Kontrolltaktik, Gegner-Verzögerung |
| Erster Dungeon (~2h) | `Vorlauf` (2×) | Selten | Kartenoptimierung, Kostenreduktion |
| Welt 1 Mini-Boss (~3h) | `Zeitkürass` (1×) | Selten | Reflexion, Einführung des Konter-Konzepts |
| Welt 1 Boss (~4-6h) | `Zeitparade` (1×) | Legendär | Erste Signaturkarte, volle Zeitreflexion |
| Welt 2 Einführung (~7h) | `Zeitblock` (+2×) | Ungewöhnlich | Evolution wird verfügbar, Elementarpfade eröffnet |
| Welt 2 Dungeon (~9h) | `Zeitbarriere` (1×) | Episch | Starke Zeitdiebstahl-Reduktion |
| Welt 2 Boss (~10h) | `Zeitfestung` (1×) | Legendär | Zweite Signaturkarte |
| Welt 3 Start (~12h) | `Wächterblick` (2×) | Episch | Spezialisierung |
| Spätere Welten | Weitere Kopien | - | Deckoptimierung und Spezialisierung |

#### 3.3.3 Design-Philosophie

Diese Freischaltungssequenz wurde entwickelt, um:
- Die Grundkonzepte der **Phasenwechsel-Boni** stufenweise zu vermitteln
- Den **Phasenwechsel** mit zunehmender Tiefe zu demonstrieren
- Die **Zeitliche Wächter**-Mechanik durch praktische Erfahrung zu verdeutlichen
- Legendäre Karten als Höhepunkte der Klassenidentität zu positionieren

Die Freischaltung aller 26 Karten erfolgt in den ersten ~15-20 Spielstunden, während die langfristige Progression durch Kartenverbesserung und Deckoptimierung erfolgt.

## 4. Detaillierte Kartenspezifikationen (mit aktualisierten Materialkosten)

### 4.1 Basisangriffe

#### 4.1.1 Schwertschlag (CARD-WAR-SWORDSLASH)
- **Basis**: 2,5s, 5 Schaden
- **Startdeck**: 8 Karten
- **Evolution**: 3 Elementarpfade

*Feuer-Evolution*
| Stufe | ID | Kosten | Effekt | DoT-Kategorie | Materialien |
|-------|-----|--------|--------|--------------|-------------|
| 1: Flammenschlag | CARD-WAR-FLAMMESLASH | 2,5s | 4 + 2 DoT | Schwach (0,5s) | 1× Elementarfragment |
| 2: Glutklinge | CARD-WAR-AVENGINGSWORD | 3,0s | 5 + 3 DoT, +1 Schaden pro Block | Mittel (1,0s) | 2× Elementarfragment |
| 3: Urteilsklinge | CARD-WAR-RETRIBUTIONSWORD | 3,5s | 6 + 4 DoT, +2 Schaden pro Block | Stark (2,0s) | 3× Elementarfragment |

*Eis-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Eisschlag | CARD-WAR-ICESLASH | 2,5s | 4 + 15% Slow | 1× Elementarfragment |
| 2: Frostschlag | CARD-WAR-FROSTSLASH | 3,0s | 5 + 25% Slow, -20% Zeitdiebstahl | 2× Elementarfragment |
| 3: Eisklinge | CARD-WAR-GLACIERSLASH | 3,5s | 6 + 35% Slow, -30% Zeitdiebstahl | 3× Elementarfragment |

*Blitz-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Blitzschlag | CARD-WAR-STORMSLASH | 2,0s | 4, -0,5s nächste Verteidigungskarte | 1× Elementarfragment |
| 2: Gewitterschlag | CARD-WAR-TEMPESTSLASH | 2,5s | 5, -1,0s nächste Verteidigungskarte | 2× Elementarfragment |
| 3: Sturmschlag | CARD-WAR-LIGHTNINGSLASH | 3,0s | 6, -1,5s nächste Verteidigungskarte | 3× Elementarfragment |

#### 4.1.2 Schildschlag (CARD-WAR-SHIELDSLASH)
- **Basis**: 2,5s, 5 Schaden + 15% Zeitdiebstahlschutz (2s)
- **Startdeck**: 4 Karten
- **Evolution**: 3 Elementarpfade

*Feuer-Evolution*
| Stufe | ID | Kosten | Effekt | DoT-Kategorie | Materialien |
|-------|-----|--------|--------|--------------|-------------|
| 1: Funkenstoß | CARD-WAR-SPARKBASH | 2,5s | 5 + 1 DoT, 15% Zeitdiebstahlschutz (2s) | Schwach (0,5s) | 1× Elementarfragment |
| 2: Glutstoß | CARD-WAR-EMBERBASH | 2,5s | 6 + 2 DoT, 20% Zeitdiebstahlschutz (2s) | Mittel (1,0s) | 2× Elementarfragment |
| 3: Feuerstoß | CARD-WAR-FIREBASH | 2,5s | 7 + 3 DoT, 25% Zeitdiebstahlschutz (2s) | Stark (2,0s) | 3× Elementarfragment |

*Eis-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Eisstoß | CARD-WAR-ICEBASH | 2,5s | 5 + 10% Slow, 15% Zeitdiebstahlschutz (2s) | 1× Elementarfragment |
| 2: Froststoß | CARD-WAR-FROSTBASH | 2,5s | 5 + 20% Slow, 20% Zeitdiebstahlschutz (2s) | 2× Elementarfragment |
| 3: Gletscherstoß | CARD-WAR-GLACIERBASH | 2,5s | 5 + 30% Slow, 25% Zeitdiebstahlschutz (2s) | 3× Elementarfragment |

*Blitz-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Blitzstoß | CARD-WAR-LIGHTNINGBASH | 2,5s | 6 Schaden, 15% Zeitdiebstahlschutz (2s) | 1× Elementarfragment |
| 2: Gewitterstoß | CARD-WAR-TEMPESTBASH | 2,5s | 7 Schaden, 20% Zeitdiebstahlschutz (2s) | 2× Elementarfragment |
| 3: Sturmstoß | CARD-WAR-STORMBASH | 2,5s | 8 Schaden, 25% Zeitdiebstahlschutz (2s) | 3× Elementarfragment |

### 4.2 Verteidigungskarten *(alt 4.3)*

#### 4.2.1 Zeitblock (CARD-WAR-TIMESHIELD - *alt 4.3.1*)
- **Basis**: 2,5s, Blockt nächsten Angriff (4s) + 0,5s Rückgewinn
- **Startdeck**: 4 Karten
- **Evolution**: 3 Elementarpfade

*Feuer-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Funkenschild | CARD-WAR-FLAMESHIELD | 2,5s | Blockt nächsten Angriff (4s), Reflektiert 2 Schaden. (+1 SM bei Block) | 1× Elementarfragment |
| 2: Feuerbarriere | CARD-WAR-FIREBARRIER | 3,0s | Blockt nächsten Angriff (4s), Reflektiert 4 Schaden. (+1 SM bei Block) | 2× Elementarfragment |
| 3: Feuerschutz | CARD-WAR-INFERNOSHIELD | 3,5s | Blockt nächsten Angriff (5s), Reflektiert 6 Schaden. (+1 SM bei Block) | 3× Elementarfragment |

*Eis-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Frostschutz | CARD-WAR-FROSTSHIELD | 2,5s | Blockt nächsten Angriff (5s), +1,0s zurück. (+1 SM bei Block) | 1× Elementarfragment |
| 2: Eisbarriere | CARD-WAR-ICEBARRIER | 3,0s | Blockt nächsten Angriff (6s), +1,0s zurück. (+1 SM bei Block) | 2× Elementarfragment |
| 3: Frostwall | CARD-WAR-PERMAFROSTSHIELD | 3,5s | Blockt nächsten Angriff (7s), +1,5s zurück. (+1 SM bei Block) | 3× Elementarfragment |

*Blitz-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Blitzschild | CARD-WAR-STORMSHIELD | 2,0s | Blockt nächsten Angriff (4s), +1 Karte ziehen. (+1 SM bei Block) | 1× Elementarfragment |
| 2: Gewitterschild | CARD-WAR-ENERGYSHIELD | 2,5s | Blockt nächsten Angriff (4s), +1 Karte ziehen, diese kostet -0,5s. (+1 SM bei Block) | 2× Elementarfragment |
| 3: Sturmschild | CARD-WAR-LIGHTNINGSHIELD | 3,0s | Blockt nächsten Angriff (4s), +2 Karten ziehen, beide kosten -0,5s. **Generiert +2 Schildmacht bei erfolgreichem Block.** | 3× Elementarfragment |

#### 4.2.2 Zeitbarriere (CARD-WAR-TIMEBARRIER - *alt 4.3.2*)
- **Basis**: 3,5s, -30% Zeitdiebstahl (5s)
- **Startdeck**: 1 Karte
- **Evolution**: 3 Elementarpfade

*Feuer-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Flammenbarriere | CARD-WAR-FLAMEBARRIER | 3,5s | -30% Zeitdiebstahl (5s), +1 DoT auf Angreifer | 1× Elementarfragment |
| 2: Glutbarriere | CARD-WAR-EMBERBARRIER | 4,0s | -40% Zeitdiebstahl (6s), +2 DoT auf Angreifer | 2× Elementarfragment |
| 3: Infernobarriere | CARD-WAR-INFERNOBARRIER | 4,5s | -50% Zeitdiebstahl (7s), +3 DoT auf Angreifer | 3× Elementarfragment |

*Eis-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Frostbarriere | CARD-WAR-FROSTBARRIER | 3,5s | -30% Zeitdiebstahl (5s), +10% Slow (3s) | 1× Elementarfragment |
| 2: Eiszeitbarriere | CARD-WAR-ICETIMEBARRIER | 4,0s | -40% Zeitdiebstahl (6s), +20% Slow (4s) | 2× Elementarfragment |
| 3: Gletscherbarriere | CARD-WAR-GLACIERBARRIER | 4,5s | -50% Zeitdiebstahl (7s), +30% Slow (5s) | 3× Elementarfragment |

*Blitz-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Blitzbarriere | CARD-WAR-LIGHTNINGBARRIER | 3,5s | -30% Zeitdiebstahl (5s), +1 Karte | 1× Elementarfragment |
| 2: Gewitternetz | CARD-WAR-STORMBARRIER | 4,0s | -40% Zeitdiebstahl (6s), +1 Karte, -0,5s nächste Karte | 2× Elementarfragment |
| 3: Sturmnetz | CARD-WAR-THUNDERBARRIER | 4,5s | -50% Zeitdiebstahl (7s), +2 Karten, -1,0s nächste Karte | 3× Elementarfragment |

#### 4.2.3 Zeitkürass (CARD-WAR-TEMPORALARMOR - *alt 4.3.3*)
- **Basis**: 3,0s, Reflektiert 25% des nächsten Zeitdiebstahls
- **Startdeck**: 1 Karte
- **Evolution**: 3 Elementarpfade

*Feuer-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Flammenrüstung | CARD-WAR-FLAMARMOR | 3,0s | Reflektiert 25% Zeitdiebstahl, +1 DoT auf Angreifer | 1× Elementarfragment |
| 2: Glührüstung | CARD-WAR-EMBERARMOR | 3,5s | Reflektiert 30% Zeitdiebstahl, +2 DoT auf Angreifer | 2× Elementarfragment |
| 3: Infernorüstung | CARD-WAR-INFERNOARMOR | 4,0s | Reflektiert 35% Zeitdiebstahl, +3 DoT auf Angreifer | 3× Elementarfragment |

*Eis-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Frostrüstung | CARD-WAR-FROSTARMOR | 3,0s | Reflektiert 25% Zeitdiebstahl, +10% Slow (3s) | 1× Elementarfragment |
| 2: Eisrüstung | CARD-WAR-ICEARMOR | 3,5s | Reflektiert 30% Zeitdiebstahl, +20% Slow (4s) | 2× Elementarfragment |
| 3: Gletscherrüstung | CARD-WAR-GLACIERARMOR | 4,0s | Reflektiert 35% Zeitdiebstahl, +30% Slow (5s) | 3× Elementarfragment |

*Blitz-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Voltpanzer | CARD-WAR-LIGHTNINGARMOR | 3,0s | Reflektiert 25% Zeitdiebstahl, +1 Karte | 1× Elementarfragment |
| 2: Gewitterpanzer | CARD-WAR-STORMARMOR | 3,5s | Reflektiert 30% Zeitdiebstahl, +1 Karte, -0,5s nächste Karte | 2× Elementarfragment |
| 3: Sturmpanzer | CARD-WAR-THUNDERARMOR | 4,0s | Reflektiert 35% Zeitdiebstahl, +2 Karten, -1,0s nächste Karte | 3× Elementarfragment |

### 4.3 Zeitmanipulationskarten *(alt 4.4)*

#### 4.3.1 Zeitfessel (CARD-WAR-TIMEFETTER - *alt 4.4.1*)
- **Basis**: 2,5s, +3s Gegnerverzögerung
- **Startdeck**: 2 Karten
- **Evolution**: 3 Elementarpfade

*Feuer-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Zeitbrand | CARD-WAR-TIMEBURN | 2,5s | +2,5s Gegnerverzögerung, +1 DoT (schwach) | 1× Elementarfragment |
| 2: Zeitflamme | CARD-WAR-TIMEFLAME | 3,0s | +3,0s Gegnerverzögerung, +2 DoT (mittel) | 2× Elementarfragment |
| 3: Zeitinferno | CARD-WAR-TIMEFETTERINFERNO | 3,5s | +3,5s Gegnerverzögerung, +3 DoT (stark) | 3× Elementarfragment |

*Eis-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Zeitfrost | CARD-WAR-TIMEFROST | 2,5s | +3,0s Gegnerverzögerung, 15% Slow (2s) | 1× Elementarfragment |
| 2: Zeiteisfall | CARD-WAR-TIMEICEFALL | 3,0s | +3,5s Gegnerverzögerung, 25% Slow (3s) | 2× Elementarfragment |
| 3: Zeitgletscher | CARD-WAR-TIMEGLACIER | 3,5s | +4,0s Gegnerverzögerung, 35% Slow (4s) | 3× Elementarfragment |

*Blitz-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Zeitblitz | CARD-WAR-TIMELIGHTNING | 2,0s | +2,5s Gegnerverzögerung, -0,5s für nächste Karte | 1× Elementarfragment |
| 2: Zeitgewitter | CARD-WAR-TIMETHUNDER | 2,5s | +3,0s Gegnerverzögerung, -0,5s für nächste 2 Karten | 2× Elementarfragment |
| 3: Zeitsturm | CARD-WAR-TIMESTORM | 3,0s | +3,5s Gegnerverzögerung, -0,5s für nächste 3 Karten | 3× Elementarfragment |

#### 4.3.2 Vorlauf (CARD-WAR-TEMPORALEFFICIENCY - *alt 4.4.2*)
- **Basis**: 3,0s, Nächste Verteidigungskarte -1,0s
- **Startdeck**: 2 Karten
- **Evolution**: 3 Elementarpfade

*Feuer-Pfad ("Flammzunge")*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|-------------|
| 1: Flammzunge | CARD-WAR-TIMEBURN | 3,0s | Nächste Angriffskombo +30% Effekt | 1× Elementarfragment |
| 2: Zeitinferno | CARD-WAR-TIMEINFERNO | 3,5s | Nächste 2 Angriffskombos +30% Effekt | 2× Elementarfragment |
| 3: Zeitfeuerwerk | CARD-WAR-TIMEFIREWORKS | 4,0s | Nächste 3 Angriffskombos +30% Effekt | 3× Elementarfragment |

*Eis-Pfad ("Frostgriff")*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Frostgriff | CARD-WAR-TIMESTASIS | 3,0s | Nächste Verteidigungskarte -1,0s, Dauer +50% | 1× Elementarfragment |
| 2: Zeitgefängnis | CARD-WAR-TIMEPRISON | 3,5s | Nächste 2 Verteidigungskarten -1,0s, Dauer +50% | 2× Elementarfragment |
| 3: Zeitkristallisation | CARD-WAR-TIMECRYSTALLIZATION | 4,0s | Nächste 3 Verteidigungskarten -1,0s, Dauer +50% | 3× Elementarfragment |

*Blitz-Pfad ("Zeitbeschleunigung")*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Zeitbeschleunigung | CARD-WAR-TIMEACCELERATION | 2,5s | Für die nächsten 5s kosten alle Karten -0,5s | 1× Elementarfragment |
| 2: Zeitsprint | CARD-WAR-TIMESPRINT | 3,0s | Für die nächsten 5s kosten alle Karten -1,0s | 2× Elementarfragment |
| 3: Zeitrausch | CARD-WAR-TIMERUSH | 3,5s | Für die nächsten 8s kosten alle Karten -1,0s | 3× Elementarfragment |

#### 4.3.3 Wächterblick (CARD-WAR-WARDERFOCUS)
- **Basis**: 2,0s, +1,5s Zeitgewinn bei erfolgreicher Verteidigung (Block)
- **Startdeck**: 2 Karten
- **Evolution**: 3 Elementarpfade (ersetzt die bisherige neutrale Evolution)

##### Feuer-Pfad ("Vergeltungsfokus")
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|----|--------|--------|-------------|
| 1: Funkenfokus | CARD-WAR-FOCUS-SPARK | 2,0s | +1,5s Zeitgewinn bei erfolgreicher Verteidigung, nächste Angriffskarte +1 Schaden | 1× Elementarfragment |
| 2: Flammfokus | CARD-WAR-FOCUS-FLAME | 2,5s | +2,0s Zeitgewinn bei erfolgreicher Verteidigung, nächste Angriffskarte +2 Schaden | 2× Elementarfragment |
| 3: Infernofokus | CARD-WAR-FOCUS-INFERNO | 2,5s | +2,0s Zeitgewinn bei erfolgreicher Verteidigung, nächste Angriffskarte +3 Schaden und wendet schwachen DoT an (0,5s Zeitgewinn) | 3× Elementarfragment |

##### Eis-Pfad ("Beharrlichkeitsfokus")
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|----|--------|--------|-------------|
| 1: Frostfokus | CARD-WAR-FOCUS-FROST | 2,0s | +2,0s Zeitgewinn bei erfolgreicher Verteidigung | 1× Elementarfragment |
| 2: Eisfokus | CARD-WAR-FOCUS-ICE | 2,5s | +2,5s Zeitgewinn bei erfolgreicher Verteidigung | 2× Elementarfragment |
| 3: Gletscherfokus | CARD-WAR-FOCUS-GLACIER | 3,0s | +3,0s Zeitgewinn bei erfolgreicher Verteidigung | 3× Elementarfragment |

##### Blitz-Pfad ("Tempofokus")
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|----|--------|--------|-------------|
| 1: Blitzfokus | CARD-WAR-FOCUS-LIGHTNING | 2,0s | +1,5s Zeitgewinn bei erfolgreicher Verteidigung, +1 Karte. Generiert zusätzlich +1 Schildmacht. | 1× Elementarfragment |
| 2: Gewitterfokus | CARD-WAR-FOCUS-STORM | 2,0s | +1,5s Zeitgewinn bei erfolgreicher Verteidigung, +1 Karte, ziehe 1 Karte. Generiert zusätzlich +1 Schildmacht. | 2× Elementarfragment |
| 3: Sturmfokus | CARD-WAR-FOCUS-THUNDER | 2,5s | +2,0s Zeitgewinn bei erfolgreicher Verteidigung, +2 Karten. Generiert zusätzlich +2 Schildmacht. | 3× Elementarfragment |

### 4.4 Signaturkarten *(alt 4.5)*

#### 4.4.1 Zeitparade (CARD-WAR-TEMPORALCOUNTER - *alt 4.5.1*)
- **Basis**: 4,0s, Reflektiert nächsten Zeitdiebstahl + 6 Schaden
- **Startdeck**: 1 Karte
- **Evolution**: 3 Elementarpfade

*Feuer-Evolution*
| Stufe | ID | Kosten | Effekt | DoT-Kategorie | Materialien |
|-------|-----|--------|--------|--------------|-------------|
| 1: Brandparade | CARD-WAR-FIRECOUNTER | 4,0s | Reflektiert nächsten Zeitdiebstahl + 8 Schaden | - | 2× Elementarfragment |
| 2: Glutkonter | CARD-WAR-INFERNALCOUNTERSTRIKE | 4,5s | Reflektiert nächsten Zeitdiebstahl + 10 Schaden + 3 DoT | Mittel (1,0s) | 2× Elementarfragment |
| 3: Flammspiegel | CARD-WAR-FLAMERIPOSTE | 5,0s | Reflektiert nächsten Zeitdiebstahl + 12 Schaden + 4 DoT | Stark (2,0s) | 3× Elementarfragment |

*Eis-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Eisparade | CARD-WAR-FROSTCOUNTER | 4,0s | Reflektiert nächsten Zeitdiebstahl + 6 Schaden + 25% Slow (3s) | 2× Elementarfragment |
| 2: Frostreflex | CARD-WAR-GLACIERRIPOSTE | 4,5s | Reflektiert nächsten Zeitdiebstahl + 8 Schaden + 40% Slow (5s) | 2× Elementarfragment |
| 3: Kryospiegel | CARD-WAR-ICETIMECOUNTER | 5,0s | Reflektiert nächsten Zeitdiebstahl + 10 Schaden + 50% Slow (6s) | 3× Elementarfragment |

*Blitz-Evolution*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|------------|
| 1: Voltparade   | CARD-WAR-LIGHTNINGCOUNTER | 3,5s | Reflektiert nächsten Zeitdiebstahl + 6 Schaden, +1 Karte | 2× Elementarfragment |
| 2: Donnerschlag   | CARD-WAR-STORMCOUNTER     | 4,0s | Reflektiert nächsten Zeitdiebstahl + 7 Schaden, +2 Karten | 2× Elementarfragment |
| 3: Blitzreflex| CARD-WAR-THUNDERCOUNTER   | 4,5s | Reflektiert nächsten Zeitdiebstahl + 8 Schaden, +3 Karten | 3× Elementarfragment |

#### 4.4.2 Zeitfestung (CARD-WAR-TIMEFORTRESS - *alt 4.5.2, angepasst v1.8.2*)
- **Basis**: 5,0s, +4s, 30% Zeitdiebstahlreduktion (6s), +1 Karte
- **Startdeck**: 1 Karte
- **Evolution**: 3 Elementarpfade (Feuer, Eis, Blitz)

*Feuer-Evolution ("Flammenherz") - Modifiziert den Schildbruch (Schildbruch)*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|-------------|
| 1: Flammwall | CARD-WAR-TIMEWARSTAND | 5,0s | +4s, 25% ZDR (Zeitdiebstahlreduktion) (6s), +1 Karte. **Schildbruch Mod:** Schaden der Zeitl. Entladung +5. | 2× Elementarfragment |
| 2: Feuermauer | CARD-WAR-TIMEWARARMOR | 5,5s | +5s, 30% ZDR (8s), +2 Karten. **Schildbruch Mod:** Schaden der Zeitl. Entladung +10, fügt schwachen DoT (2 Schaden/s für 3s) hinzu. | 2× Elementarfragment |
| 3: Flammherz | CARD-WAR-TIMEWARFLAME | 6,0s | +6s, 40% ZDR (10s), +3 Karten. **Schildbruch Mod:** Schaden der Zeitl. Entladung +15, fügt mittleren DoT (4 Schaden/s für 3s) hinzu. | 3× Elementarfragment |

*Eis-Evolution ("Ewige Aegis") - Modifiziert die passiven Schildmacht Boni*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|-------------|
| 1: Frostwehr | CARD-WAR-TIMEBASTION | 5,0s | +4s, 35% ZDR (10s), +1 Karte, 3s immun gg. Zeitdiebstahl. **Passive SM-Mod:** Der +0,5s Zeitrückgewinn-Bonus (ab 2 SM) ist verdoppelt auf +1,0s. | 2× Elementarfragment |
| 2: Frostmauer | CARD-WAR-ABSOLUTETIMEFORTRESS | 5,5s | +5s, 40% ZDR (15s), +2 Karten, 5s immun gg. Zeitdiebstahl. **Passive SM-Mod:** Zeitrückgewinn (ab 2 SM) auf +1,0s erhöht; der +1 Schaden-Bonus (ab 3 SM) ist verdoppelt auf +2 Schaden. | 2× Elementarfragment |
| 3: Kryoschanze | CARD-WAR-ETERNALTIMEBASTION | 6,0s | +6s, 50% ZDR (15s), +3 Karten, 6s immun gg. Zeitdiebstahl. **Passive SM-Mod:** Zeitrückgewinn (ab 2 SM) auf +1,5s; Schaden-Bonus (ab 3 SM) auf +2; Immunität gg. Zeitdiebstahl (normal ab 4 SM) wird bereits ab 3 SM aktiv. | 3× Elementarfragment |

*Blitz-Evolution ("Tempokern") - Modifiziert die Schildmacht Generierung*
| Stufe | ID | Kosten | Effekt | Materialien |
|-------|-----|--------|--------|-------------|
| 1: Voltwall | CARD-WAR-TIMEBATTLEMENT | 5,0s | +4s, 25% ZDR (6s), +2 Karten, nächste 3 Karten -1,0s. **SM-Generierungs-Mod:** Erfolgreiche Blocks mit *beliebigen* Verteidigungskarten generieren +1 zusätzliche SM (also +2 gesamt pro Block). | 2× Elementarfragment |
| 2: Gewitterwall | CARD-WAR-TIMESYNCHRONIZATIONTOWER | 5,5s | +5s, 30% ZDR (8s), +3 Karten, nächste 5 Karten -1,0s. **SM-Generierungs-Mod:** Erfolgreiche Blocks mit *beliebigen* Verteidigungskarten generieren +1 zusätzliche SM. Beim Ausspielen dieser Karte: +1 SM. | 2× Elementarfragment |
| 3: Sturmturm | CARD-WAR-CHRONOSTORMTOWER | 6,0s | +6s, 40% ZDR (10s), +4 Karten, nächste 5 Karten -1,0s. **SM-Generierungs-Mod:** Erfolgreiche Blocks mit *beliebigen* Verteidigungskarten generieren +2 zusätzliche SM (also +3 gesamt pro Block). Beim Ausspielen dieser Karte: +2 SM. | 3× Elementarfragment |

## 5. Strategische Pfade und Spielstile
*(Unverändert)*

### 5.1 Feuer-Pfad ("Zeitliche Vergeltung")
- **Strategie**: "Schaden zurückwerfen", Reflektion-Fokus, DoT
- **Stärken**: Höchster Einzelzielschaden, Gegner leiden unter eigenen Angriffen, Zeitgewinn durch DoT
- **Schwächen**: Geringere direkte Zeitrückgewinnung, abhängig von Gegneraktionen

### 5.2 Eis-Pfad ("Chronobarriere")
- **Strategie**: "Verzögern und Überleben", maximale Defensive
- **Stärken**: Höchste Zeitrückgewinnung, längste Blockdauer, Zeitdiebstahlschutz, Slow-Effekte
- **Schwächen**: Geringerer Direktschaden, längere Kämpfe

### 5.3 Blitz-Pfad ("Tempoverteidiger")
- **Strategie**: "Effizienz und Kartenfluss", Kostenreduktion
- **Stärken**: Höchste Kartenzugrate, Kostenreduktion, Kombo-Potenzial, Tempo
- **Schwächen**: Geringere Blockdauer, weniger direkte Schadensreduktion, geringere direkte Zeitrückgewinnung

## 6. Kartenkombo-Strategien
*(Annahme Abschnitt war bereits korrekt angepasst)*

### 6.1 "Zeitliche Vergeltung" (Defensiv-Offensiv-Kombo)
- **Komponenten**: Zeitblock → Schwertschlag → Zeitparade (oder Feuer-/Eis-/Blitz-Konter)
- **Mechanik**: Blockieren, dann verstärkter Gegenangriff mit Reflexion
- **Effekt**: Hoher Schaden plus Zeitrückgewinnung/Reflexion

### 6.2 "Zeitliche Barrikade" (Überlebens-Kombo - *aktualisiert v1.6*)
- **Komponenten**: Zeitbarriere (oder Eis-Variante) → Zeitblock (oder Eis-Variante) → Zeitblock (oder Eis-Variante)
- **Mechanik**: Fokus auf Zeitdiebstahlschutz und wiederholte Blocks mit Zeitrückgewinn.
- **Effekt**: Sehr hohe defensive Zeit mit potenzieller Zeitrückgewinnung und Schutz vor Zeitdiebstahl.

### 6.3 "Temporaler Sturm" (Tempo-Kombo)
- **Komponenten**: Vorlauf (Blitz-Pfad) → Zeitblock (Blitz-Pfad) → Sturmschwert → Schwertschlag (Blitz-Pfad)
- **Mechanik**: Reduzierte Kosten und Kartenziehen durch Effizienzverkettung
- **Effekt**: Schnelle Kartensequenzen mit moderatem Schaden

## 7. Interaktionen und Affinitäten
*(Unverändert)*

### 7.1 Weltinteraktionen (Zusammenfassung aus ZK-CLASS-WAR-COMP-.md v1.1)
- **Welt 1 (Zeitwirbel-Tal)**: Ausgeglichen, konsistente Überlebensrate. Empfehlung: Frostschutz. Restzeit: ~14s.
- **Welt 2 (Flammen-Chrono-Schmiede)**: Niedrig-Mittel Affinität. Herausforderung: DoT. Vorteil: Reflexion. Empfehlung: Flammenschlag. Restzeit: ~12s.
- **Welt 3 (Eiszeit-Festung)**: Hohe Affinität (Heimvorteil). Empfehlung: Eisbarriere. Restzeit: ~17s.
- **Welt 4 (Gewittersphäre)**: Mittel Affinität. Empfehlung: Blitzschild. Restzeit: ~14s.
- **Welt 5 (Chronos-Nexus)**: Hohe Affinität. Flexibilität ist Schlüssel. Empfehlung: Situationsabhängig. Restzeit: ~16s.

### 7.2 Weltspezifische Interaktionen (aus ZK-CLASS-WAR-CARDS-COMP-.md v1.2)
- **Eiszeit-Festung (Welt 3)**: Zeitwächter besonders effektiv dank guter defensiver Optionen.
- **Gewittersphäre (Welt 4)**: Gute Synergien mit defensiven Strategien und Blitz-Pfad.
- **DoT-Kategoriesystem**: Feuer-Evolutionen gewähren Zeitgewinn basierend auf DoT-Stärke (Schwach: 0,5s, Mittel: 1,0s, Stark: 2,0s). Siehe `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`.
- **Kritische Restzeit (<25% / <15s)**: Effizienz defensiver Karten wird erhöht (genaue Mechanik siehe `ZK-COMBAT-SYS`).

### 7.3 Angepasste Blitz-Ketteneffekte (aus ZK-CLASS-WAR-CARDS-COMP-.md v1.2)
- Alle Blitz-Ketteneffekte haben 70% Schadensübertragung.

## 8. Material- und Evolutionsprogression
*(Unverändert)*

### 8.1 Material-Verteilung und Akkumulation
- Das Spiel folgt dem 70/30-Materialverteilungssystem pro Welt.
- Detaillierte Materiallisten, Drop-Tabellen und Konversionsraten siehe `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`.
- Erwartete Akkumulation über 5 Welten: Ca. 6-8 Karten evolviert (23-31% des Decks), davon 2-3 auf Stufe 3.

### 8.2 Evolutionspriorität (Beispiel aus ZK-CLASS-WAR-COMP-.md v1.1)
- **Anfangsphase (0-5h)**: Fokus auf Defensive (z. B. 1× Zeitblock → Frostschild).
- **Mittlere Phase (5-15h)**: Balance zwischen Angriff und Verteidigung (z. B. 1× Schwertschlag → Flammenschwert, 1× Vorlauf → Flammzunge).
- **Spezialisierungsphase (15h+)**: Vertiefung in einen der Pfade (Feuer, Eis oder Blitz).

## Quellendokumente
- ZK-CLASS-WAR-COMP-v1.1-20250327: Ursprüngliche Klassenbeschreibung
- ZK-CLASS-WAR-CARDS-COMP-v1.2-20250415: Ursprüngliche Kartendetails
- ZK-MAT-COMPLETE-v1.0-20250417: Aktuelles Materialsystem und Kosten

## Abhängige Dokumente
- ZK-WORLDS-v1.0-20250327: Weltensystem (Akt 1)
- ZK-DUN-MECH-v1.0-20250327: Weltmechaniken
- ZK-BAL-v1.1-20250327: Balance-Framework
- ZK-TIME-v1.1-20250327: Zeitsystem
- ZK-COMBAT-SYS: Kampfsystem (für Kritische Restzeit Details)


---

### Anmerkungen
- **Materialanpassungen**: Vereinfachtes Materialsystem mit nun drei klar definierten Kern-Materialtypen (Zeitkern, Elementarfragment und Zeitfokus) gemäß `ZK-VEREINFACHTES-MATERIALSYSTEM-v1.0.md`. Konsistente Umsetzung des "1 Zeitkern = 1 Level"-Prinzips.
- **Supabase-Tabelle**: Die Blitz-Evolutionen für *Zeitparade* wurden aus der Tabelle übernommen, mit Effekten, die dem Blitz-Pfad (Kartenziehen, Kostenreduktion) entsprechen. Neutrale Evolutionen für *Zeitkürass* wurden hinzugefügt, um die Daten aus der Supabase-Tabelle zu reflektieren (Stand: 2025-04-17).
