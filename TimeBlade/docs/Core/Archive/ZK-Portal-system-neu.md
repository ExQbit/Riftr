# Zeitklingen: Portal- und Missionssystem (MoCo-Adaption)

## 1. Hauptportal-Interface

### Weltenübersicht:
- **Weltenauswahl** (Tab am unteren Bildschirmrand)
- **Kapitelstruktur** zeigt Fortschritt an (Prolog, Kapitel 1, etc.)
- **Weitere Modi** als Tabs neben "WELTEN":
  - "RIFTS" (kurze, zeitlich begrenzte Herausforderungen)
  - "DOJO" (Solo-Herausforderungen)
  - "VERSUS" (PvP-Modus, falls gewünscht)

### Dungeons/Karten:
- Jeder Dungeon wird als Kachel dargestellt mit:
  - **Name und atmosphärisches Bild** (z.B. "Zeitwirbel-Tal", "Flammen-Schmiede")
  - **Level-Anforderung** (rechts oben, Zahlenwert mit Flaggensymbol)
  - **Aktive Jobs** (als Zahl im orangem Banner, z.B. "4 JOBS")
  - **Events** mit Countdown-Timer (z.B. "ANSTEHENDES EVENT" mit "2m 29s")
  - **Spezielle Tags** (z.B. #zeitwirbel, #feuer)
  - **Fortschrittsindikator** für die Welt/Kapitel

### Status-Anzeigen:
- **Kampf-XP-Multiplikator** (oben rechts, z.B. "4X")
- **XP-Fortschrittsbalken** (aktuelle/benötigte XP)
- **Zurücksetzungs-Timer** für Boni (oben rechts, "Zurücksetzung in 18h 57m")

## 2. Dungeon-Auswahl & Kampf-Interface

Nach Auswahl eines Dungeons:
- **Dungeon-Info** wird angezeigt (Name, Welt, Kapitel)
- **Empfohlene/Aktuelle Ausrüstungsstärke** (wie "EMPFOHLEN: 600")
- **Gegnertypen** als visuelle Elemente mit Fortschrittsanzeigen (z.B. "0/2", "0/5")
- **"KÄMPFEN"-Button** (groß, orange) zum Starten des Dungeons
- **Aktive Jobs/Projekte** für diesen Dungeon werden angezeigt
- **Spezielle Fundstücke** wie "mo.co-Kisten" (in Zeitklingen: "Zeit-Kisten")

## 3. Missionstypen & Quests

### Hauptquests:
- Von Haupt-NPCs vergeben (Zeitlords oder andere Charaktere)
- Mit Story-Dialog und Hintergrundkontext verbunden
- Klare Aufträge wie "Jagen / [Gegnername]"
- Automatische Abschluss-Erkennung im Dungeon

### Jobs (tägliche/kurze Aufgaben):
- Einfache Ziele wie "Besiege X Gegner vom Typ Y"
- Mehrere pro Dungeon (wie "4 JOBS")
- Rotieren regelmäßig (alle 3 Stunden neue Jobs)
- Geben moderate XP und Materialien

### Projekte (langfristige Ziele):
- Anspruchsvollere, längerfristige Aufgaben
- Angezeigt mit Projektanzahl (wie "6 PROJEKTE")
- Mit speziellen Hashtags markiert (#Zeitsammler, #ElementarMeister)
- Größere Belohnungen (z.B. Evolutionsmaterialien, Reroll-Materialien)

### Belohnungssystem:
- **XP** für Level-Fortschritt
- **Materialien** (Zeit- und Elementarressourcen)
- **Zeit-Kits** (ähnlich wie mo.co-Kisten) für spezielle Upgrades
- **Kosmetika** für visuelle Anpassungen

## 4. Events & spezielle Aktivitäten

### Zeitlich begrenzte Events:
- **Events pro Dungeon** mit Countdown (wie "ANSTEHENDES EVENT")
- **Spezielle Begegnungstypen** (z.B. "RIFT-ALARM!" oder "ELEMENTARAUSBRUCH!")
- Wiederholbar in regelmäßigen Abständen
- Bessere Belohnungen als normale Kämpfe

### XP-Multiplikator:
- **Kampf-XP-Schub** (wie im Screenshot erklärt)
- Erhöht temporär gewonnene XP und Material-Drops
- Wirkt nur auf Kampf-XP, nicht auf Quest-XP
- Regelmäßige Aktualisierung (z.B. "Aktualisierung auf 4× in 18h 33m")
- Motiviert regelmäßiges Spielen

## 5. Dungeon-Mechanik

### Grundstruktur:
- **Kontinuierliche Begegnungen**: Nach Auswahl eines Dungeons beginnt eine Folge zufälliger Kämpfe
- **Kein Zeitlimit**: Spieler können beliebig lange im Dungeon bleiben
- **Automatisches Missions-Tracking**: Fortschritt wird während des Spielens automatisch aktualisiert
- **Freier Ausstieg**: Spieler können jederzeit den Dungeon verlassen und Belohnungen mitnehmen

### Gegner-Begegnungen:
- **Zufällige Gegnerauswahl** aus dem thematischen Pool des Dungeons
- **Keine steigende Schwierigkeit** je länger man spielt (keine Bestrafung für längeres Spielen)
- **Verschiedene Gegnertypen** mit unterschiedlichen Kampfmechaniken
- **Spezielle Gegner** bei Events mit garantierten selteneren Drops

### Kartenspiel-Mechanik:
- Nach Gegnerkontakt schaltet das Spiel in den bekannten Kartenspiel-Modus
- Standardmechanik: 60 Sekunden Zeit, Zeitkosten für Karten, etc.
- Nach Kampfende direkt zur nächsten Begegnung (nahtloser Übergang)

## 6. Design-Kernpunkte

1. **Nahtlose Dungeon-Erfahrung**:
   - Spieler können so lange im Dungeon bleiben, wie sie möchten
   - Aufgaben werden automatisch während des Spielens abgeschlossen
   - Keine künstlichen Zeitbegrenzungen oder Energiekosten

2. **Belohnungsprioritäten**:
   - Missionen geben die meisten XP und spezielle Materialien
   - Kämpfe geben moderate XP (verstärkt durch Multiplikatoren)
   - Events bieten seltene und zeitlich begrenzte Belohnungen

3. **Progression und Motivation**:
   - Levelanforderungen für bestimmte Dungeons
   - Regelmäßige Events und rotierende Boni (tägliche Rückstellung)
   - Kombination aus Langzeitzielen (Projekte) und Kurzzeitaufgaben (Jobs)

4. **Materialökonomie**:
   - Primäre Materialquelle: Quest-Belohnungen und Events
   - Sekundäre Materialquelle: Gegner-Drops
   - Spezielle Materialien (für Rerolls, Zeitkerne, etc.) hauptsächlich aus Projekten und Events

## 7. Vorteile des Systems

- **Hoher Wiederspielwert** durch zufällige Begegnungen und rotierende Events
- **Flexible Spielsessions** (kurz oder lang je nach verfügbarer Zeit)
- **Klare Progression** durch sichtbare Level-Anforderungen und Kapitelstruktur
- **Vielseitige Belohnungen** für verschiedene Spielertypen
- **Einfache, aber motivierende Struktur** ohne komplizierte Subsysteme
- **Natürliche Anti-Ausnutzungs-Mechanik** durch Quest-fokussierte Belohnungen statt reines Grinding