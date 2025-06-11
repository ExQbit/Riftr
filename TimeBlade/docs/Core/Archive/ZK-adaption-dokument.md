# Zeitklingen: Mo.Co-Adaptiertes Progressionssystem

## Inhaltsverzeichnis

1. [Einführung & Übersicht](#1-einführung--übersicht)
2. [Klassenstufen-Progression](#2-klassenstufen-progression)
3. [Kartenverbesserungssystem](#3-kartenverbesserungssystem)
4. [Quest-Struktur](#4-quest-struktur)
5. [Projektliste (Auswahl)](#5-projektliste-auswahl)
6. [Event-System](#6-event-system)
7. [Benutzeroberfläche](#7-benutzeroberfläche)
8. [Material-Ökonomie](#8-material-ökonomie)
9. [Progressionsbalance](#9-progressionsbalance)
10. [Übersicht der Systeme & Interaktionen](#10-übersicht-der-systeme--interaktionen)

---

## 1. Einführung & Übersicht

### 1.1 Ziel der Anpassung

Die Anpassung von Zeitklingen an das Mo.Co-System verfolgt mehrere Ziele:

- **Quest-basierte Progression** gegenüber reinem Grinding priorisieren
- **Materialbasiertes Kartenverbesserungssystem** einführen
- **Klare, zugängliche Spielerfahrung** schaffen
- **Tägliche Engagement-Loops** optimieren

### 1.2 Die drei Progressionssysteme

Zeitklingen enthält drei parallele Progressionssysteme:

1. **Klassenstufen-Progression (XP-basiert)**
   - Stufenbereich: 1-25
   - Wichtige Meilensteine: Stufe 5, 10, 15, 20, 25
   - Bestimmt maximales Kartenlevel

2. **Kartenverbesserung (Material-basiert)**
   - Levelbereich: 1-50 
   - Gates bei Level 10, 20, 30, 40
   - Nutzt Zeit-Kerne mit Aufladungssystem

3. **Meisterschaftssystem (Punkt-basiert)**
   - Freigeschaltet nach Klassenstufe 25
   - Endgame-System für Langzeitmotivation
   - Erfordert spezielle Herausforderungen

### 1.3 Grundlegendes Spielprinzip

- **80% der Progression** erfolgt durch Quests, Projekte und Events
- **20% der Progression** erfolgt durch normales Grinding/Kämpfen
- Quest-gesteuerte Fortschritte verhindern übermäßiges Grinding
- Die Progression wird durch Klassenstufen begrenzt (Kartenlevel kann Klassenstufe × 2 nicht überschreiten)

---

## 2. Klassenstufen-Progression

### 2.1 Grundmechanik

- Spieler erhalten **Klassen-XP** für Kämpfe, Quests, Projekte und Events
- Jede Klassenstufe schaltet neue Spielinhalte frei
- **Anforderungen für Levelaufstieg steigen progressiv** (z.B. 2.000 XP für Stufe 2, 30.000 XP für Stufe 20)

### 2.2 Klassenstufen-Meilensteine

| Stufe | Freischaltung | Klassenbonus |
|-------|---------------|--------------|
| 5 | Maximales Kartenlevel 10 | Chronomant: Arkane Präkognition<br>Zeitwächter: Wachsame Verteidigung<br>Schattenschreiter: Schnellzieher |
| 10 | Maximales Kartenlevel 20 | Chronomant: Elementare Resonanz<br>Zeitwächter: Schild-Echo<br>Schattenschreiter: Verbesserte Schattensynergie |
| 15 | Maximales Kartenlevel 30 | Chronomant: Zeitrückgewinnung<br>Zeitwächter: Temporale Rüstung<br>Schattenschreiter: Momentum-Katalysator |
| 20 | Maximales Kartenlevel 40 | Chronomant: Arkane Synergie<br>Zeitwächter: Vergeltung<br>Schattenschreiter: Zeitdiebstahl-Meister |
| 25 | Maximales Kartenlevel 50<br>Meisterschaftssystem | Chronomant: Zeitmanipulation<br>Zeitwächter: Zeitfortifikation<br>Schattenschreiter: Schattenverschmelzung |

### 2.3 Klassen-XP-Quellen

| Aktivität | XP-Gewinn | Anmerkungen |
|-----------|-----------|-------------|
| Standard-Gegner | 25-50 XP | Reduzierter Wert, Fokus auf Materialdrops |
| Elite-Gegner | 100-150 XP | Reduzierter Wert, Fokus auf Materialdrops |
| Mini-Boss | 300-500 XP | Reduzierter Wert, Fokus auf Materialdrops |
| Dungeon-Boss | 1.000-1.500 XP | Reduzierter Wert, Fokus auf Materialdrops |
| Tagesquest | 2.000-4.000 XP | Hauptquelle für Klassen-XP |
| Wöchentliches Projekt | 10.000-30.000 XP | Bedeutende XP-Quelle für wichtige Fortschritte |
| Events | 5.000-50.000 XP | Abhängig vom Event-Typ und -Dauer |

---

## 3. Kartenverbesserungssystem

### 3.1 Zeit-Kern-System

#### 3.1.1 Grundprinzip

- **Ein einziger Kern pro Materialtyp** mit Stufen 0-5
- Nach Verwendung eines Kerns wird dieser auf **Stufe 0** zurückgesetzt
- Bei Stufe 5 muss der Kern verwendet werden (Kartenverbesserung oder Umwandlung)

#### 3.1.2 Kern-Typen und Levelbereich

| Kern-Typ | Levelbereich | Erhalt |
|----------|--------------|--------|
| Zeitfragment-Kern | 1-10 | Häufig: Standardgegner, Tagesquests, Zeitkits |
| Zeitkristall-Kern | 11-20 | Moderat: Elite-Gegner, Tagesquests, Zeitkits |
| Zeitessenz-Kern | 21-30 | Selten: Mini-Bosse, Projekte, Zeitkits |
| Zeitkern-Kern | 31-40 | Sehr selten: Dungeon-Bosse, Projekte, besondere Zeitkits |
| Reiner Zeitkern-Kern | 41-50 | Extrem selten: Welt-Bosse, spezielle Events, Meisterschaftsbelohnungen |

#### 3.1.3 Aufladungs- und Verwendungsmechanik

**Stufen-Anforderungen für Kartenleveling:**
- Level 1→2: Stufe 1
- Level 2→4: Stufe 2
- Level 4→6: Stufe 3
- Level 6→8: Stufe 4
- Level 8→10: Stufe 5
- *Ähnliches Muster für höhere Levelbereiche*

**Aufladung:**
- Zeitfragment-Kern Stufe 3 + Gewinn von 1 Stufe → Stufe 4
- Stufe gewinnt man durch Kämpfe, Quest-Abschluss, Events

**Verwendung:**
- Zeitfragment-Kern Stufe 4 für Karte Level 6→8 → Kern wird auf Stufe 0 zurückgesetzt
- Spieler kann wählen, welche Karte verbessert werden soll

**Stufe 5 Regel:**
- Nach Kampfende muss ein Kern mit Stufe 5 verwendet werden
- Optionen: Kartenverbesserung ODER Umwandlung in höherwertigen Kern

#### 3.1.4 Umwandlung in höherwertige Kerne

| Umwandlung | Zusatzkosten |
|------------|--------------|
| Zeitfragment-Kern (Stufe 5) → Zeitkristall-Kern | +10 Zeitstaub |
| Zeitkristall-Kern (Stufe 5) → Zeitessenz-Kern | +5 Zeitfragment |
| Zeitessenz-Kern (Stufe 5) → Zeitkern-Kern | +3 Zeitkristall |
| Zeitkern-Kern (Stufe 5) → Reiner Zeitkern-Kern | +1 Zeitessenz |

### 3.2 Zeit-Kits

**Beschreibung:**
- Spezielle Belohnungspakete für den Abschluss von 3 Tagesquests
- Bieten eine Auswahl aus 3 zufälligen Kartenverbesserungen
- Erlauben gezielte Verbesserung von Lieblingskarten

**Funktionsweise:**
1. Spieler schließt 3 Tagesquests ab
2. Zeit-Kit wird als Belohnung freigeschaltet
3. Spieler wählt aus 3 angebotenen Kartenverbesserungen
4. Die gewählte Karte erhält einen Levelaufstieg (unabhängig vom Kern-System)

### 3.3 Gates und Seltenheitsupgrades

Die bestehenden Gates bei Level 10, 20, 30 und 40 bleiben erhalten:
- **Gate 1 (Level 10)**: Common → Uncommon
- **Gate 2 (Level 20)**: Uncommon → Rare
- **Gate 3 (Level 30)**: Rare → Epic
- **Gate 4 (Level 40)**: Epic → Legendary

Jedes Gate erfordert spezifische Materialien und gewährt einen Seltenheits-Boost (+10/20/30/45%).

### 3.4 Evolution-System

Das Evolutionssystem bleibt unverändert, mit Freischaltung bei bestimmten Kartenleveln:
- **Evolution Stufe 1**: Freigeschaltet ab Kartenlevel 9
- **Evolution Stufe 2**: Freigeschaltet ab Kartenlevel 25
- **Evolution Stufe 3**: Freigeschaltet ab Kartenlevel 35

---

## 4. Quest-Struktur

### 4.1 Tagesquests (Daily Jobs)

**Grundmechanik:**
- Bis zu 10 Tagesquests können gleichzeitig aktiv sein
- Alle 3 Stunden wird eine neue Quest angeboten
- Quests bleiben aktiv, bis sie abgeschlossen werden

**Belohnungen:**
- Klassen-XP (2.000-4.000)
- Zeit-Kern-Stufen (+1 bis +3)
- Ein Zeit-Kit für je 3 abgeschlossene Quests
- Gelegentlich: Seltenere Materialien (z.B. Zeitfluss-Splitter)

**Klassenstufen-Tagesquests** (Beispiele):
- **Chronomant**: "Erreiche 20 Mal Arkankraft 4+", "Aktiviere 5 Zeitstrom-Resonanzfelder"
- **Zeitwächter**: "Blocke 30 Angriffe", "Erzeuge 50 Chrono-Energie"
- **Schattenschreiter**: "Aktiviere 10 Schattensynergien", "Halte 1 Minute lang Momentum über 3"

**Kartenbezogene Tagesquests** (Beispiele):
- "Aktiviere [Karte X] 15 Mal in einem Kampf"
- "Verursache 200 Schaden mit [Karte X]"

### 4.2 Projekte

**Grundmechanik:**
- Langfristige, mehrstufige Herausforderungen
- Immer verfügbar (keine Zeitbegrenzung)
- Freischaltung nach Erreichen bestimmter Meilensteine

**Belohnungen:**
- Große Mengen Klassen-XP (10.000-30.000)
- Seltene Materialien (Evo-Materialien, Reroll-Materialien)
- Zeitkerne höherer Stufen
- Besondere Belohnungen (z.B. Kosmetika)

**Typen von Projekten:**
- **Klassenprojekte**: Fokus auf Klassenmechaniken und -spezialisierungen
- **Elementarprojekte**: Fokus auf Evolution und Elementarbeherrschung
- **Weltbezogene Projekte**: Fokus auf Erkundung und Weltenabschluss
- **Endgame-Projekte**: Fokus auf Meisterschaft und Zenit-System

---

## 5. Projektliste (Auswahl)

### 5.1 Elementare Meisterschaft

**Projekt: Feuer-Beherrschung**
- **Freischaltung**: Nach Erster Evolution (Stufe 1) einer Feuer-Karte
- **Stufen**:
  1. Verursache 500 Feuer-DoT-Schaden *(5.000 XP, 10× Elementar-UNC (Feuer))*
  2. Erreiche die höchste DoT-Kategorie (Stark+) 10 Mal *(10.000 XP, 5× Elementar-RAR (Feuer))*
  3. Besiege 3 Mini-Bosse in der Flammen-Schmiede *(15.000 XP, 3× Elementar-EPI (Feuer))*
  4. Abschlussherausforderung: Besiege die Erzsiederin Ignium ohne Schaden zu erleiden *(25.000 XP, 1× Elementar-LEG (Feuer), 1× Essenz des Schadens)*

**Projekt: Eis-Beherrschung**
- **Freischaltung**: Nach Erster Evolution (Stufe 1) einer Eis-Karte
- **Stufen**:
  1. Verlangsame Gegner um insgesamt 1.000% *(5.000 XP, 10× Elementar-UNC (Eis))*
  2. Halte jeden Gegnertypus in der Eiszeit-Festung für 5 Sekunden eingefroren *(10.000 XP, 5× Elementar-RAR (Eis))*
  3. Besiege 3 Mini-Bosse in der Eiszeit-Festung *(15.000 XP, 3× Elementar-EPI (Eis))*
  4. Abschlussherausforderung: Besiege den Permafrost-Monarchen ohne mehr als 2 Karten zu spielen *(25.000 XP, 1× Elementar-LEG (Eis), 1× Essenz der Dauer)*

**Projekt: Blitz-Beherrschung**
- **Freischaltung**: Nach Erster Evolution (Stufe 1) einer Blitz-Karte
- **Stufen**:
  1. Verursache 20 Kettenschaden-Sprünge *(5.000 XP, 10× Elementar-UNC (Blitz))*
  2. Aktiviere 30 Mal Karten mit 0 Zeitkosten *(10.000 XP, 5× Elementar-RAR (Blitz))*
  3. Besiege 3 Mini-Bosse in der Gewittersphäre *(15.000 XP, 3× Elementar-EPI (Blitz))*
  4. Abschlussherausforderung: Besiege den Frequenzmeister in weniger als 20 Sekunden *(25.000 XP, 1× Elementar-LEG (Blitz), 1× Essenz der Regeneration)*

### 5.2 Klassenmeisterschaften

**Projekt: Chronomant-Meisterschaft**
- **Freischaltung**: Ab Klassenstufe 5
- **Stufen**:
  1. Aktiviere 50 Karten während das Beschleunigte Zeitstrom-Resonanzfeld aktiv ist *(8.000 XP, 10× Zeitfragment)*
  2. Löse den Zeitlichen Arkankraft-Bruch 25 Mal aus *(12.000 XP, 5× Zeitkristall)*
  3. Erreiche in 10 verschiedenen Kämpfen mindestens 4 Arkankraft ohne dass sie verfällt *(18.000 XP, 3× Zeitessenz)*
  4. Meistere alle drei Elementarpfade – Besitze je eine Evolution Stufe 2 für Feuer, Eis und Blitz *(30.000 XP, 1× Zeitkern, 1× Essenz der Synergie)*

**Projekt: Zeitwächter-Meisterschaft**
- **Freischaltung**: Ab Klassenstufe 5
- **Stufen**:
  1. Blocke 100 gegnerische Angriffe erfolgreich *(8.000 XP, 10× Zeitfragment)*
  2. Löse den Bruch-Effekt bei 5 Chrono-Energie 25 Mal aus *(12.000 XP, 5× Zeitkristall)*
  3. Reflektiere insgesamt 500 Schaden zurück auf Gegner *(18.000 XP, 3× Zeitessenz)*
  4. Vollende einen perfekten Schild-Schwert-Zyklus 20 Mal *(30.000 XP, 1× Zeitkern, 1× Essenz der Zeit)*

**Projekt: Schattenschreiter-Meisterschaft**
- **Freischaltung**: Ab Klassenstufe 5
- **Stufen**:
  1. Aktiviere 50 Schattensynergien *(8.000 XP, 10× Zeitfragment)*
  2. Löse den Schattenrausch (Bruch bei 5 Momentum) 25 Mal aus *(12.000 XP, 5× Zeitkristall)*
  3. Stehle insgesamt 300 Sekunden von Gegnern *(18.000 XP, 3× Zeitessenz)*
  4. Spiele 30 Karten in einer einzigen Kampfrunde *(30.000 XP, 1× Zeitkern, 1× Essenz der Ketten)*

### 5.3 Weltmeisterschaften und Endgame-Projekte

**Projekt: Weltenentdecker**
- Entdecke alle Gebiete in jeder Welt
- Stufenweise Belohnungen, Abschluss: 1× Reiner Zeitkern, 1× Resonanzfokus nach Wahl

**Projekt: Kistenjäger**
- Finde alle versteckten Zeit-Kisten in jeder Welt
- Stufenweise Belohnungen, Abschluss: 1× Reiner Zeitkern, 1× Essenz nach Wahl

**Projekt: Zenit-Vorbereitung**
- Komplexes Endgame-Projekt für die Zenit-Transformation
- Erforderlich: Level 45+, Welt 5 Heroisch, Meisterschaftsstufe 10

---

## 6. Event-System

### 6.1 Regelmäßige Events (jede Stunde / alle 2-3 Stunden)

**Temporäre Rift**

- **Dauer**: 15 Minuten
- **Beschreibung**: Eine temporäre Rift hat sich in einer der Welten geöffnet. Starke Monster strömen heraus!
- **Mechanik**: Gegner werden 50% stärker, geben aber +100% Materialien
- **Belohnungen**: Garantierter Zeitkristall, erhöhte Drop-Rate für seltene Materialien

**Elementarausbruch**
- **Dauer**: 20 Minuten
- **Beschreibung**: Eine Welle elementarer Energie durchflutet die Welt
- **Mechanik**: Alle Elementarkarten einer zufälligen Evolutionsrichtung (Feuer/Eis/Blitz) erhalten +30% Effektivität
- **Belohnungen**: Garantierte Elementarmaterialien des entsprechenden Typs

**Zeit-Begünstigung**
- **Dauer**: 10 Minuten
- **Beschreibung**: Die Zeitlinie ist instabil! Manche Karten kosten temporär weniger Zeit
- **Mechanik**: Alle 3. gespielte Karte kostet 0 Zeit
- **Belohnungen**: Erhöhte Chance auf Zeitfragmente und -kristalle

### 6.2 Tägliche Events

**Zeit-Rush**
- **Dauer**: 1 Stunde (feste Tageszeit, z.B. 20:00-21:00 Uhr)
- **Beschreibung**: Besiege so viele Monster wie möglich in der vorgegebenen Zeit
- **Belohnungen**: Rangliste mit Belohnungen basierend auf besiegten Gegnern

**Rift-Herausforderung**
- **Dauer**: 30 Minuten (rotierender Zeitslot)
- **Beschreibung**: Spezielle Rift-Variante mit besonderen Regeln
- **Belohnungen**: Zeitfluss-Splitter, Resonanzfokus, XP-Belohnungen

### 6.3 Wöchentliche Events

**Weltenboss-Erscheinung**
- **Dauer**: 3 Tage (Fr-So)
- **Beschreibung**: Ein besonders mächtiger Weltenboss erscheint, der Koordination erfordert
- **Belohnungen**: Hohe XP, Zeitkern, Elementar-LEG

**Zeit-Anomalie**
- **Dauer**: 2 Tage (Mi-Do)
- **Beschreibung**: Eine Zeitanomalie verändert die Spielregeln grundlegend
- **Belohnungen**: Aufsteigende Belohnungen je nach Teilnahme-Intensität

### 6.4 Monatliche Events / Kapitel-Events

Ausführliche Story-Events mit einzigartigen Belohnungen, die die Kerngeschichte von Zeitklingen vorantreiben.

---

## 7. Benutzeroberfläche

### 7.1 Hub-Bereich

**Zeit-Kern-Verwaltung:**
```
[ZEITKERNE]
-----------------------
Zeitfragment-Kern: Stufe 3 ●●●○○
Zeitkristall-Kern: Stufe 1 ●○○○○
Zeitessenz-Kern: Stufe 0 ○○○○○
Zeitkern-Kern: Nicht freigeschaltet
Reiner Zeitkern-Kern: Nicht freigeschaltet

[VERWENDEN] | [UMWANDELN]
```

**Quest-Tab:**
```
[TAGESQUESTS (7/10)]
-----------------------
✓ "Zeitlicher Reinigungs-Job" [ABGESCHLOSSEN]
✓ "Eliten-Verfolgung" [ABGESCHLOSSEN]
✓ "Zeitfluss-Kit erhalten!" [ABHOLEN]
→ "Chronomant-Herausforderung" (14/20)
→ "Zeitdiebstahl-Meister" (42/60)
...

[PROJEKTE]
-----------------------
→ "Feuer-Beherrschung" (Stufe 2/4)
→ "Chronomant-Meisterschaft" (Stufe 1/4)
...
```

### 7.2 Kartenleveling-Interface

```
[KARTE VERBESSERN]
-----------------------
"Feuerstoß" (Level 7 → 8)
Benötigt: Zeitfragment-Kern Stufe 4

Aktueller Kern: Stufe 3
[VERBESSERUNG NICHT MÖGLICH]

Hinweis: Sammle weitere Zeit-Kerne im Kampf
oder schließe Tagesquests ab!
```

### 7.3 Umwandlungs-Interface

```
[KERN UMWANDELN]
-----------------------
Zeitfragment-Kern (Stufe 5) → Zeitkristall-Kern
Zusatzkosten: 10 Zeitstaub (vorhanden: 24)

HINWEIS: Nach der Umwandlung wird der
Zeitfragment-Kern auf Stufe 0 zurückgesetzt.

[ABBRECHEN] | [UMWANDELN]
```

### 7.4 Nach-Kampf-Interface

```
[KAMPF ABGESCHLOSSEN]
-----------------------
Gewonnene XP: 3.000
Zeitfragment-Kern: +2 Stufen (jetzt Stufe 5)

ACHTUNG: Zeitfragment-Kern hat Stufe 5 erreicht!
Du musst den Kern verwenden.

[KARTE VERBESSERN] | [UMWANDELN]
```

---

## 8. Material-Ökonomie

### 8.1 Kern-Progressionsbalance

**Zeitfragment-Kern-Stufen (pro Stunde):**
- Frühe Spielphase (Level 1-10): ~2-3 Stufen
- Mittlere Spielphase (Level 11-20): ~3-4 Stufen
- Fortgeschrittene Spielphase (Level 21+): ~4-5 Stufen

**Zeitkristall-Kern-Stufen (pro Stunde):**
- Ab Welt 2: ~1-2 Stufen
- Ab Welt 3: ~2-3 Stufen
- Ab Welt 4-5: ~3-4 Stufen

**Zeitessenz-Kern-Stufen:**
- Ab Welt 3: ~0,5-1 Stufen pro Stunde
- Ab Welt 4-5: ~1-2 Stufen pro Stunde

**Zeitkern-Kern und Reiner Zeitkern-Kern:**
- Primär durch Projekte und Events

### 8.2 Umwandlungs-Effizienz

Die Umwandlung höherstufiger Kerne ist effizienter als das direkte Sammeln:

- 5 Zeitfragment-Kern-Stufen + 10 Zeitstaub = 1 Zeitkristall-Kern
- Dieser eine Zeitkristall-Kern entspricht ~3 Stunden Farming in Welt 2

Diese Effizienz schafft strategische Entscheidungen: Sofort verwenden oder auf höherwertige Umwandlung sparen?

### 8.3 Quest-Belohnungsstruktur

**Tagesquests:**
- 1-2 Stufen für Zeit-Kerne
- 2.000-4.000 Klassen-XP
- Alle 3 Quests: 1 Zeit-Kit

**Projekte:**
- Große Mengen Klassen-XP (10.000-30.000)
- Zeit-Kerne höherer Stufen (1-5)
- Seltene Materialien (Elementarmaterialien, Reroll-Materialien)

**Events:**
- Mix aus Klassen-XP und Zeit-Kern-Stufen
- Spezielle Materialien (Zeitfluss-Splitter, Resonanzfokus)
- Kosmetische Belohnungen

---

## 9. Progressionsbalance

### 9.1 Grundlegende Balancierung

#### 9.1.1 Kartenleveling-Geschwindigkeit (F2P)

| Spielphase | Level-Bereich | Zeit pro Level | Hauptquelle |
|------------|---------------|----------------|-------------|
| Früh | 1-10 | ~45-60 Minuten | Zeitfragment-Kerne, Zeit-Kits |
| Mittel | 11-20 | ~2-3 Stunden | Zeitkristall-Kerne, Zeit-Kits, Projekte |
| Fortgeschritten | 21-30 | ~4-5 Stunden | Zeitessenz-Kerne, Projekte, Events |
| Spät | 31-40 | ~6-8 Stunden | Zeitkern-Kerne, Spezielle Projekte |
| Endgame | 41-50 | ~10-12 Stunden | Reine Zeitkern-Kerne, Endgame-Projekte |

#### 9.1.2 Klassenstufen-Progression (F2P)

| Stufen-Bereich | Zeit pro Stufe | Hauptquelle |
|----------------|----------------|-------------|
| 1-5 | ~5-6 Stunden | Tagesquests, Kämpfe |
| 6-10 | ~10-12 Stunden | Tagesquests, Projekte |
| 11-15 | ~15-20 Stunden | Projekte, Events |
| 16-20 | ~20-25 Stunden | Fortgeschrittene Projekte, weltweite Events |
| 21-25 | ~25-30 Stunden | Endgame-Projekte, besondere Events |

### 9.2 Quest vs. Kampf-Balancierung

| Aktivität | Beitrag zur Kartenverbesserung | Beitrag zur Klassenstufe |
|-----------|--------------------------------|--------------------------|
| 1 Stunde Kämpfe | ~1-2 Zeit-Kern-Stufen<br>~500-1.000 Klassen-XP | ~3-5% eines Levelaufstiegs |
| 3 Tagesquests | ~3-5 Zeit-Kern-Stufen<br>1 Zeit-Kit<br>~8.000-12.000 Klassen-XP | ~20-40% eines Levelaufstiegs |
| 1 Projektstufe | ~2-3 Zeit-Kern-Stufen<br>~10.000-20.000 Klassen-XP<br>Seltene Materialien | ~30-50% eines Levelaufstiegs |

### 9.3 Kritische Engpässe

Sorgfältig platzierte Engpässe sorgen für langfristige Motivation:

- **Level 10 Gate**: Erster Seltenheitssprung, erfordert gezielte Materialsammlung
- **Evo-2-Materialien**: Werden zum ersten echten Engpass in der mittleren Spielphase
- **Zeitessenz-Kern**: Hauptengpass für Fortgeschrittene (Level 21-30)
- **Zeitkern/Reiner Zeitkern**: Ultimativer Engpass für Endgame-Spieler

---

## 10. Übersicht der Systeme & Interaktionen

### 10.1 Systemhierarchie

```
[KLASSENSTUFEN-PROGRESSION]
       |
       ├── Bestimmt maximales Kartenlevel
       |
       ├── Schaltet Klassenboni frei (5/10/15/20/25)
       |
       └── Ermöglicht Meisterschaftssystem (ab 25)
              |
              └── Endgame-Progression

[KARTENVERBESSERUNGSSYSTEM]
       |
       ├── Zeit-Kerne (Stufen 0-5)
       |    |
       |    ├── Automatische Aufladung durch Kämpfe/Quests
       |    |
       |    └── Verwendung oder Umwandlung bei Stufe 5
       |
       ├── Zeit-Kits (für gezielte Verbesserung)
       |
       ├── Gates & Seltenheitsupgrades (10/20/30/40)
       |    |
       |    └── Zufälliger Attribut-Boost
       |
       └── Evolution (9/25/35)
            |
            └── Feuer/Eis/Blitz-Pfade

[QUEST-SYSTEM]
       |
       ├── Tagesquests (bis zu 10 aktiv)
       |    |
       |    └── Zeit-Kit für je 3 abgeschlossene Quests
       |
       ├── Projekte (langfristig, mehrstufig)
       |
       └── Events (stündlich, täglich, wöchentlich, monatlich)
```

### 10.2 Täglicher Spielzyklus

1. **Schnelle Session (15-30 Minuten):**
   - 1-2 Tagesquests abschließen
   - Zeit-Kerne aufwerten
   - Evtl. an einem laufenden Event teilnehmen

2. **Standard-Session (30-60 Minuten):**
   - 3+ Tagesquests abschließen
   - Zeit-Kit erhalten und verwenden
   - An Projekten weiterarbeiten
   - Evtl. ein Gate-Upgrade durchführen

3. **Lange Session (1-2 Stunden):**
   - Alle verfügbaren Tagesquests abschließen
   - Mehrere Zeit-Kits sammeln und gezielt verwenden
   - Größere Fortschritte bei Projekten erzielen
   - Events abschließen
   - Evtl. eine Evolution oder ein Seltenheitsupgrade durchführen

### 10.3 Wöchentlicher Spielzyklus

- **Montag-Dienstag:** Fokus auf neue wöchentliche Quests
- **Mittwoch-Donnerstag:** Zeit-Anomalie-Event
- **Freitag-Sonntag:** Weltenboss-Event
- **Wochenende:** Erhöhte Droprate, besondere Events

### 10.4 Langzeitprogression

- **Erste Woche:** Fokus auf Klassenstufe 5 und erste Kartenlevels bis 10
- **Erste 2-4 Wochen:** Welt 1-2 abschließen, mehrere Karten auf Level 20 bringen
- **Erste 1-2 Monate:** Klassenstufe 10-15 erreichen, Hauptdeck auf Level 20-30
- **Erste 3-6 Monate:** Klassenstufe 20-25 erreichen, Hauptdeck auf Level 30-40
- **Langzeit (6+ Monate):** Meisterschaftssystem, Zenit-Transformationen, Optimierung