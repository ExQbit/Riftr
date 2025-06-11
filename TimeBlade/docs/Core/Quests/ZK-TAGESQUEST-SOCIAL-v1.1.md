# Zeitklingen: Tagesquest-Pool - Social-Quests (v1.1-20250520)

## Inhaltsverzeichnis
1. [Einführung und Übersicht](#1-einführung-und-übersicht)
2. [Kartenspiel-Kooperation](#2-kartenspiel-kooperation)
3. [Kartenhandel](#3-kartenhandel)
4. [Zeitgilde-Quests](#4-zeitgilde-quests)
5. [Strategie-Mentoring](#5-strategie-mentoring)
6. [Turnier-Event-Quests](#6-turnier-event-quests)
7. [Quest-Rotation und Gewichtungen](#7-quest-rotation-und-gewichtungen)

---

## 1. Einführung und Übersicht

Dieses Dokument enthält den vollständigen Satz sozialbezogener Tagesquests für das Mo.Co-adaptierte Zeit-Kern-Progressionssystem von Zeitklingen. Diese Quests bilden etwa 15% des gesamten Tagesquest-Pools und fokussieren sich auf Kartenspiel-Interaktionen zwischen Spielern, kooperative Strategieentwicklung, Kartenhandel und den Aufbau einer aktiven Gemeinschaft von Zeitklingenstrategen.

### 1.1 Quest-Struktur

Jede Quest wird mit folgenden Elementen definiert:
- **ID**: Eindeutiger Identifikator für Datenbank-Referenz
- **Name**: Kurzer, einprägsamer Titel der Quest
- **Beschreibung**: Detaillierte Aufgabenbeschreibung
- **Schwierigkeit**: Standard, Herausfordernd oder Elite
- **Anforderungen**: Spezifische Bedingungen für den Abschluss
- **Kern-Vergabe**: Prozentwert der Zeit-Kern-Aufladung
- **Belohnungen**: Zusätzliche Belohnungen neben Kern-Aufladung (z.B. Karten, Zeitfragmente, Evolutionsmaterialien)
- **Welt-Beschränkung**: Falls die Quest nur in bestimmten Welten verfügbar ist
- **Rotationsgewichtung**: Wahrscheinlichkeit des Erscheinens im täglichen Pool

### 1.2 Kern-Vergabe

Die Zeit-Kern-Vergabe für sozialbezogene Quests folgt diesen Richtlinien:
- **Standard**: 7% Kern-Aufladung
- **Herausfordernd**: 10% Kern-Aufladung
- **Elite**: 15% Kern-Aufladung
- **Elementar-Spezialisierung**: Bei elementspezifischen Quests entstehen entsprechende Elementar-Kerne (Feuer, Eis, Blitz)
- **Multiplikator**: Welt 1: 1.0×, Welt 2: 1.2×, Welt 3: 1.5×, Welt 4: 1.8×, Welt 5: 2.0×

---

## 2. Kartenspiel-Kooperation

### 2.1 Gemeinschaftliche Strategieentwicklung

#### QUEST-SC-001: Zeitklingen-Strategieteam
- **Name**: Zeitklingen-Strategieteam
- **Beschreibung**: "Die besten Strategien entstehen im kreativen Austausch." - Erzchronistin Lyra. Analysiere mit 2 anderen Spielern deine Decks und entwickelt eine Verbesserungsstrategie.
- **Schwierigkeit**: Standard
- **Anforderungen**: 3 Deckanalysen durchführen und dokumentieren
- **Kern-Vergabe**: 7%
- **Belohnungen**: 5× Zeitfragmente, 1× Zufällige COM-Karte
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (25%)

#### QUEST-SC-002: Zeitklingenmeisterschaft
- **Name**: Zeitklingenmeisterschaft
- **Beschreibung**: "Perfekte Harmonie erfordert perfektes Timing." Absolviere eine vollständige Turnierrunde mit einem Team, bei der jeder Spieler mindestens einmal mit jeder Elementarkarte (Feuer, Eis, Blitz) einen zeitkritischen Vorteil erzielt.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Perfekte Team-Runde mit Elementar-Synergien
- **Kern-Vergabe**: 10%
- **Belohnungen**: 2× UNC Evolutionsmaterial
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-SC-003: Zeitecho-Kombination
- **Name**: Zeitecho-Kombination
- **Beschreibung**: "Die Macht der Zeitklingen vervielfacht sich, wenn sie in Harmonie schwingen." Führe mit 4 anderen Spielern eine synchronisierte Kartenkombination durch, bei der alle unterschiedliche Klassenkarten zur selben Zeit ausspielen.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 Synchron-Kombination mit 5 Spielern
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× RAR Klassenmaterial
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-SC-004: Chronoturnier-Expedition
- **Name**: Chronoturnier-Expedition
- **Beschreibung**: "Nur wer die Zeit zu beherrschen weiß, kann den ultimativen Sieg erringen." Führe mit deinem Team eine vollständige Turnier-Expedition in die Zeitschleifen-Arena durch und erreicht das Finale.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Elite-Turnier bis zum Finale
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Ewigkeitsfragment, 1× Zufällige UNC-Karte
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-SC-005: Zeitwächter-Team
- **Name**: Zeitwächter-Team
- **Beschreibung**: "In kritischen Momenten zeigt sich wahre Zeitbeherrschung." Rette 3 andere Spieler vor einer Niederlage, indem du in letzter Sekunde (bei <20% Zeitlimit) zeitmanipulierende Karten ausspielst.
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 Spieler mit Zeitmanipulation retten
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Splitter (50% Aufladung), 1× Defensiv-Karte
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%)

---

## 3. Kartenhandel

### 3.1 Kartenaustausch

#### QUEST-SC-006: Zeitklinger-Händler
- **Name**: Zeitklinger-Händler
- **Beschreibung**: "Ein produktiver Austausch bereichert beide Seiten." Tausche erfolgreich 5 Karten mit anderen Spielern über das Handelssystem.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Karten tauschen
- **Kern-Vergabe**: 7%
- **Belohnungen**: 1× Zufällige UNC-Karte
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (25%)

#### QUEST-SC-007: Seltenheitsjäger
- **Name**: Seltenheitsjäger
- **Beschreibung**: "Wahre Schätze erkennen und erwerben ist eine Kunst." Erwerbe 1 seltene oder epische Karte durch Handel mit einem anderen Spieler.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 1 RAR/EPI Karte erwerben
- **Kern-Vergabe**: 10%
- **Belohnungen**: 10× Zeitfragmente
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-SC-008: Elementarsammler
- **Name**: Elementarsammler
- **Beschreibung**: "Die Elemente in Balance zu halten ist der Schlüssel zur Zeitmeisterschaft." Erwerbe durch Handel je 1 Karte jedes Elements (Feuer, Eis, Blitz).
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: Je 1 Karte jedes Elements erwerben
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× Elementarmaterial (Wahl)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-SC-009: Kartenmeister-Tausch
- **Name**: Kartenmeister-Tausch
- **Beschreibung**: "Der Austausch von Meisterstücken formt die Chronogenese." Tausche 1 voll aufgewertete Karte (Level 50) mit einem anderen Spieler.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Level-50-Karte tauschen
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%)

#### QUEST-SC-010: Evolutionärer Händler
- **Name**: Evolutionärer Händler
- **Beschreibung**: "Im Fluss der Evolution findet jede Karte ihre Bestimmung." Tausche drei evolutionsfähige Karten desselben Elements (Feuer, Eis oder Blitz).
- **Schwierigkeit**: Elite
- **Anforderungen**: 3 evolutionsfähige Karten eines Elements tauschen
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Evolutionsmaterial (entsprechend dem Element)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

---

## 4. Zeitgilde-Quests

### 4.1 Gilden-Aktivitäten

#### QUEST-SC-011: Zeitgilde-Rekrutierung
- **Name**: Zeitgilde-Rekrutierung
- **Beschreibung**: "Eine Gilde ist nur so stark wie ihre Mitglieder." Rekrutiere erfolgreich 1 neues Mitglied für deine Zeitgilde.
- **Schwierigkeit**: Standard
- **Anforderungen**: 1 Mitglied rekrutieren
- **Kern-Vergabe**: 7%
- **Belohnungen**: 3× COM Gildenmaterial
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-SC-012: Chronogildenbeitrag
- **Name**: Chronogildenbeitrag
- **Beschreibung**: "Die Stärke einer Zeitgilde liegt in der kollektiven Zeitbeherrschung." Spende 10 Karten oder Materialien an deine Gildenhalle.
- **Schwierigkeit**: Standard
- **Anforderungen**: 10 Gegenstände spenden
- **Kern-Vergabe**: 7%
- **Belohnungen**: 5× COM/UNC Gildenmaterial
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-SC-013: Zeitlinien-Verteidiger
- **Name**: Zeitlinien-Verteidiger
- **Beschreibung**: "Gemeinsam schützen wir die Zeitströme vor dem Chaos." Nimm mit deiner Gilde an einer Zeitlinien-Verteidigungsaktion teil und erreicht mindestens Rang B.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: Rang B oder höher
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× UNC Gildenkarte
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-SC-014: Temporale Gildenexpedition
- **Name**: Temporale Gildenexpedition
- **Beschreibung**: "Die gefährlichsten Zeitanomalien erfordern vereinte Stärke." Führe eine vollständige Gildenexpedition in eine Zeitanomalie durch und bezwinge den Zeitboss.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Anomalie-Boss besiegen
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× RAR Gildenmaterial
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-SC-015: Chronokraten-Konklave
- **Name**: Chronokraten-Konklave
- **Beschreibung**: "Nur im Rat der Zeit finden wir die Kraft, die Zukunft zu formen." Veranstalte ein Gilden-Konklave mit mindestens 10 Mitgliedern und plane eine gemeinsame Chronostrategie.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Konklave mit 10+ Mitgliedern
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Splitter (75% Aufladung)
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 5. Strategie-Mentoring

### 5.1 Wissensweitergabe

#### QUEST-SC-016: Zeitklingen-Mentor
- **Name**: Zeitklingen-Mentor
- **Beschreibung**: "Wissen über die Zeit muss weitergegeben werden, um nicht verloren zu gehen." Unterstütze 3 neue Spieler (unter Level 10) bei der Optimierung ihrer Decks.
- **Schwierigkeit**: Standard
- **Anforderungen**: 3 Neulinge unterstützen
- **Kern-Vergabe**: 7%
- **Belohnungen**: 1× UNC Karte (Wahl)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (20%)

#### QUEST-SC-017: Tempotaktiken
- **Name**: Tempotaktiken
- **Beschreibung**: "Die Kunst des perfekten Timings ist der Schlüssel zum Sieg." Teile 5 Taktikanleitungen im Zeitklingen-Forum und erhalte positive Resonanz.
- **Schwierigkeit**: Standard
- **Anforderungen**: 5 Anleitungen mit Resonanz
- **Kern-Vergabe**: 7%
- **Belohnungen**: 2× UNC Karten (zufällig)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-SC-018: Chronostrategie-Tutor
- **Name**: Chronostrategie-Tutor
- **Beschreibung**: "Die effizienteste Zeitnutzung im Duell entscheidet über Sieg oder Niederlage." Führe 3 praktische Duell-Trainingseinheiten mit unerfahrenen Spielern durch.
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: 3 Trainingseinheiten
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× RAR Karte (zufällig)
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%)

#### QUEST-SC-019: Temporales Schulungszentrum
- **Name**: Temporales Schulungszentrum
- **Beschreibung**: "Die Meister der Zeit teilen ihr Wissen, um das zeitliche Gleichgewicht zu wahren." Veranstalte einen Strategieworkshop für mindestens 5 Spieler.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Workshop mit 5+ Teilnehmern
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Splitter (50% Aufladung)
- **Welt-Beschränkung**: Ab Welt 2
- **Rotationsgewichtung**: Niedrig (10%)

#### QUEST-SC-020: Zeit-Meister
- **Name**: Zeit-Meister
- **Beschreibung**: "Die größten Zeitwächter sind jene, die andere zu Meistern machen." Hilf einem Spieler, seinen ersten Gilden-Chronowächter-Rang zu erreichen.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Spieler zum Chronowächter aufsteigen lassen
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× RAR Karte (Wahl)
- **Welt-Beschränkung**: Ab Welt 3
- **Rotationsgewichtung**: Sehr niedrig (5%)

---

## 6. Turnier-Event-Quests

### 6.1 Wettbewerbliche Herausforderungen

#### QUEST-SC-021: Zeitturnier-Teilnehmer
- **Name**: Zeitturnier-Teilnehmer
- **Beschreibung**: "Die Zeitarena ruft die Mutigen und Geschickten." Nimm an einem offiziellen Zeitklingen-Turnier teil und erreiche mindestens die zweite Runde.
- **Schwierigkeit**: Standard
- **Anforderungen**: 2. Runde erreichen
- **Kern-Vergabe**: 7%
- **Belohnungen**: 1× Turnier-Ticket
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Hoch (25%, nur während des Turniers)

#### QUEST-SC-022: Klassenstratege
- **Name**: Klassenstratege
- **Beschreibung**: "Wahre Meisterschaft zeigt sich in der Spezialisierung." Gewinne 3 Duelle in einem klassenspezifischen Turnier (Zeitwächter, Schattenschreiter oder Chronomant).
- **Schwierigkeit**: Standard
- **Anforderungen**: 3 Siege in Klassenturnieren
- **Kern-Vergabe**: 7%
- **Belohnungen**: 1× UNC Klassenspezifisches Material
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%, nur während des Turniers)

#### QUEST-SC-023: Elementarmeister
- **Name**: Elementarmeister
- **Beschreibung**: "Die Elemente zu beherrschen bedeutet, die Zeit zu meistern." Erreiche das Halbfinale in einem elementspezialisiertem Turnier (Feuer, Eis oder Blitz).
- **Schwierigkeit**: Herausfordernd
- **Anforderungen**: Halbfinale erreichen
- **Kern-Vergabe**: 10%
- **Belohnungen**: 1× RAR Elementarmaterial
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Mittel (15%, nur während des Turniers)

#### QUEST-SC-024: Zeitlinien-Champion
- **Name**: Zeitlinien-Champion
- **Beschreibung**: "Die Arena ist der Schmelztiegel, in dem wahre Zeitmeister geformt werden." Gewinne ein komplettes Zeitklingen-Turnier in deiner Rangstufe.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1 Turniersieg
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× EPI Kartenrahmen
- **Welt-Beschränkung**: Keine
- **Rotationsgewichtung**: Niedrig (10%, nur während des Turniers)

#### QUEST-SC-025: Chronowettbewerbs-Dominator
- **Name**: Chronowettbewerbs-Dominator
- **Beschreibung**: "Die größten Zeitmeister sind jene, die alle anderen übertreffen." Erreiche den 1. Platz im saisonalen Chronowettbewerb in deiner Kategorie.
- **Schwierigkeit**: Elite
- **Anforderungen**: 1. Platz in Kategorie
- **Kern-Vergabe**: 15%
- **Belohnungen**: 1× Zeit-Essenz (100% Aufladung)
- **Welt-Beschränkung**: Ab Welt 4
- **Rotationsgewichtung**: Sehr niedrig (5%, nur während des Wettbewerbs)

---

## 7. Quest-Rotation und Gewichtungen

### 7.1 Tägliche Verteilung

Die tägliche Verteilung der Social-Quests folgt diesen Richtlinien:
- **Gesamtanteil**: 15% des täglichen Quest-Pools (1-2 von 10 Quests pro Tag)
- **Schwierigkeitsverteilung**: 1-2× Standard oder Herausfordernd/Elite (abwechselnd)
- **Kategorie-Verteilung**: Jede der 5 Kategorien soll regelmäßig im Umlauf sein

### 7.2 Rotationsregeln

Folgende Regeln werden für die Rotation von Social-Quests angewendet:
- **Abkühlzeit**: Eine spezifische Quest erscheint frühestens wieder nach 10 Tagen
- **Event-Priorisierung**: Event-bezogene Quests erscheinen nur während des entsprechenden Turniers oder Events
- **Gilde-Balance**: Gilden-Quests erscheinen häufiger am Wochenende
- **Variation**: Innerhalb einer Woche soll jede Social-Kategorie mindestens einmal vertreten sein

### 7.3 Gewichtungs-Modifier

Die Basis-Rotationsgewichtung kann durch folgende Faktoren modifiziert werden:
- **Spieleranzahl**: +10% für Kooperations-Quests an beliebten Turniertagen
- **Weltereignisse**: +15% für Quests, die zu aktuellen Saison-Events passen
- **Gildengröße**: +5% für Gilden-Quests bei großen Zeitgilden
- **Neulingsquote**: +10% für Mentoring-Quests bei hoher Neulingsrate im Spiel

### 7.4 Soziale Förderung

Das Social-Quest-System ist so konzipiert, dass es folgende Verhaltensweisen fördert:
- **Deck-Kooperation**: Spieler werden ermutigt, Strategien gemeinsam zu entwickeln
- **Kartenökonomie**: Ein aktiver Kartenhandel wird durch Quests und Belohnungen unterstützt
- **Gildenbildung**: Zeitgilden werden durch Quests und spezielle Mechaniken gefördert
- **Strategievermittlung**: Erfahrene Spieler werden belohnt, wenn sie Neulingen Deckstrategien vermitteln
- **Turnierkultur**: Regelmäßige Turniere fördern das kompetitive Gemeinschaftsgefühl