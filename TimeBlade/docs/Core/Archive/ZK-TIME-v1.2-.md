# Zeitsystem (ZK-TIME-v1.2-20250511)

## Änderungshistorie
- v1.0 (2025-03-25): Initiale Version
- v1.1 (2025-03-27): Integration des DoT-Kategoriesystems, Anpassung der Zeitrückgewinn- und Zeitdiebstahl-Mechaniken
- v1.2 (2025-05-11): Erweiterungen zu Gegner-Zeitinteraktion, Welteffekten, Kartenprogression, Gegnerressourcen und Klassenstrategie

## Zusammenfassung
Zeit ist die einzige Ressource im Spielsystem. Jeder Kampf hat ein Zeitlimit (60s); Karten verbrauchen Zeit; Zeitmanipulation bildet die strategische Kernmechanik. DoT-Effekte werden in Kategorien mit festen Zeitrückgewinnwerten eingeteilt.

## 1. Zeitmechanik-Grundgerüst

### 1.1 Echtzeit-Kampfsystem
- Zeitlimit: 60s/Kampf → bei Ablauf: Niederlage
- Zeit = einzige Ressource (kein LP-System)
- Timer-Visualisierung: >30s (blau) → 15-30s (gelb) → <15s (rot, pulsierend)

### 1.2 Kartenverbrauch
- Jede Karte: Spezifische Zeitkosten
- Stärkere Effekte = höhere Kosten
- Effizienz-Metrik: Effektwert/Zeitkosten

## 2. Zeitmanipulationsmechaniken

### 2.1 Zeitverbrauch
- Standard: Kartenkosten werden vom Haupttimer abgezogen
- Balanceformel: Effizienz = Effektwert/Zeitkosten

### 2.2 Zeitrückgewinnung
- Aktiv: Spezielle Karten (z.B. "Temporale Riftrückgewinnung")
- Passiv: Bei Ereignissen (Gegner besiegen) 
- Zeitbonus: Gegner <20s besiegt = +3s
- Limit: Nie mehr als ursprüngliche Kartenkosten

### 2.2.5 Zeitgewinn-Akkumulation und Obergrenze
- Gesamtzeit kann nie 75s überschreiten (125% des Basis-Zeitlimits)
- Zeitgewinn wird bei niedrigeren Restzeiten wertvoller (nicht-lineare Wertkurve)
- Die letzten 15s (60-75s) dienen als strategische Reserve für kritische Kämpfe
- Visuelle Anzeige warnt bei Erreichen von 90% der maximalen Zeitgewinn-Kapazität
- Zeitwächter können durch effizientes Defensivspiel bis zu 25% Zeitbonus erreichen

### 2.3 Zeitdiebstahl
- Gegner können Zeit stehlen (spezielle Aktionen)
- Prävention: Verzögerungskarten
- Kritikalität steigt bei niedriger Restzeit
- Maximal 15% der Gesamtzeit (9s) können pro Kampf gestohlen werden

#### 2.3.3 Gegner-Zeitmanipulationsklassen
- **Zeitschleifer**: Regelmäßige kleine Zeitdiebstähle (0.5-1.0s)
- **Zeitnebel**: Ignorieren/Verzögern von Karten + moderate Zeitdiebstähle
- **Temporale Wächter**: Zeitfragment-basierte Ressourcensysteme mit eskalierenden Diebstählen
- **Chrono-Former**: Energiebasierte Zeitmanipulation mit hohem Bedrohungspotential
- **Elite-Zeitmanipulatoren**: Komplexe Ressourcensysteme mit Phasenübergängen und klassenspezifischen Kontern

#### 2.3.4 Gegner-Zeitdiebstahl-Kategorisierung
| Kategorie | Diebstahlwert | Vorwarnzeit | Häufigkeit | Konter-Mechanik |
|-----------|---------------|-------------|------------|-----------------|
| Schwach   | 0.5-1.0s      | Keine/Minimal| Hoch       | Standard-Block  |
| Mittel    | 1.0-2.0s      | 1s Indikator | Mittel     | Aktive Abwehr   |
| Stark     | 2.0-3.0s      | 2s Indikator | Niedrig    | Spezial-Konter  |
| Kritisch  | 3.0-5.0s+     | 3-5s Indikator| Boss-only  | Mechanik-Konter |

## 3. DoT-Kategoriesystem

### 3.1 Kategorisierung von DoT-Effekten
| Kategorie | Schadenswert/Tick | Zeitgewinn | Visuelle Darstellung | Farbkodierung |
|-----------|------------------|------------|----------------------|---------------|
| Schwach | 1 | 0,5s | Ein Punkt (●) | Hellgelb/Gold |
| Mittel | 2-3 | 1,0s | Zwei Punkte (●●) | Orange |
| Stark | 4-5 | 1,5s | Drei Punkte (●●●) | Rot |

## 4. Zeitkosten-Balancierung & Effizienz

### 4.1 Zeitkosten nach Kartentyp
- Diese dienen nur als allgemeine Richtlinien für die Kartentyp-Balancierung:
- **Basis-Schaden**: 1-1.5s (hohe Effizienz)
- **Mittlerer Schaden**: 2-3s (ausgeglichene Effizienz)
- **Hocheffekt**: 3-5s (niedrige Effizienz)
- **Zeitmanipulation**: 2-3s (kontextabhängige Effizienz)
- **Signaturkarten**: 4-6s (spielwendende Effekte)

### 4.3 Kritische Parameter
- Zeitdiebstahl-Maximum: 15% der Gesamtkampfzeit (9s bei 60s)
- Zeitrückgewinnung-Maximum: 30% der Gesamtkampfzeit (18s bei 60s)
- DoT-Zeitgewinn-Maximum: 10% der Gesamtkampfzeit (6s bei 60s)

- Zeitlinienkonvergenz-Zähler zeigt aktuelle und kommende Phase

## 6. Klassenspezifische Zeitinteraktionen

### 6.1 Chronomant (Magier)
- Primärer Zeitmanipulator
- Effiziente Zeitnutzung
- Signatur: "Chronofluktuation" (Zeitrückgewinn)
- Blitz-Evolution: Ketteneffekte auf 70% Schadensübertragung reduziert (vorher 80%)

### 6.2 Zeitwächter (Krieger)
- Zeitverteidigung/Präventions-Fokus
- Passive Zeitrückgewinnung durch Verteidigung
- Kombos für Zeitkostenreduktion
- Temporale Aegis: +0,5s nach jedem erfolgreichen Block

### 6.3 Schattenschreiter (Schurke)
- Extrem günstige Karten mit Ketteneffekten
- Zeitdiebstahl gegen Gegner
- Hoher Kartendurchsatz
- 0-Kosten-Ketten nach Schattenkarten

### 6.4 Klassenspezifische Zeitstrategie-Empfehlungen

#### 6.4.1 Chronomant
- Starke Zeitrückgewinnung durch DoT-Effekte (besonders in Welt 2)
- Fokus auf Manipulation der Gegner-Zeitaktionen durch Zeitverzerrung
- Chrono-Intelligenz als Konter gegen Ressourcenverbrauch-Effekte
- Zeitbeben als Konter gegen Frostmechaniken in Welt 3

#### 6.4.2 Zeitwächter
- Temporaler Konter reflektiert Zeitdiebstahl auf Gegner 
- Zeitfestung als Konter gegen massive AoE-Zeitmanipulation
- Ausnutzung der Stasis-Mechanik in Welt 3 für maximalen Schutz
- Gezielte Block-Timing gegen Gegner-Zeitdiebstahl-Vorwarnungen

#### 6.4.3 Schattenschreiter
- Zeitsprung zum Umgehen von Momentum-unterbrechenden Mechaniken
- Schattensturm als effektiver Konter gegen Multi-Target-Bedrohungen
- Schattenkonzentration für Momentum-Kontrolle gegen vorhersehbare Angriffe
- Maximale Effizienz mit Blitz-Element in Welt 4 (Gewittersphäre)

## 7. Zeitsystem-Progression

### 7.1 Kartenverbesserung und Zeiteffizienz
- **Leveling**: Jedes Level reduziert Zeitkosten prozentual (Level 1-10: 3%, 11-20: 4%, 21-30: 5%, 31-40: 6%, 41-50: 7%)
- **Evolution**: Jede Evolutionsstufe kann spezifische zeitbasierte Synergien freischalten
- **Seltenheits-Boosts**: Zeitkosten (-10% bis -45%), Zeitgewinn/Diebstahl (+10% bis +45%), Zeiteffektdauer (+10% bis +45%)
- **Sockel**: Zeitkristall-Sockel (10-30% Zeitkosten zurück), Topas (-0.2 bis -0.6s Kosten)

### 7.2 Power-Progression im Zeitsystem
- Frühe Phase (~9h): Kartenspielzeit ~1.8-2.4s/Karte, max. 30-33 Karten/Kampf
- Mittlere Phase (~35h): Kartenspielzeit ~1.2-1.8s/Karte, max. 38-45 Karten/Kampf
- Fortgeschritten (~90h): Kartenspielzeit ~0.9-1.5s/Karte, max. 45-55 Karten/Kampf
- Endgame (~180h): Kartenspielzeit ~0.6-1.2s/Karte, max. 55-70 Karten/Kampf

## 8. Gegner-Zeitressourcen

### 8.1 Ressourcenarten und Zeitauswirkungen
- **Aufladungsressourcen**: Gegner bauen über Zeit Ressourcen auf (Energie, Fragmente, Ladung, etc.)
- **Schwellenwerteffekte**: Bei Erreichen bestimmter Werte werden Zeitmanipulationen ausgelöst
- **Phasenbasierte Ressourcen**: Ändern Verhalten und Zeitmanipulationen bei HP-Schwellen
- **Resonanzressourcen**: Reagieren auf Spieleraktionen mit zeitbasierten Kontern

### 8.2 Visuelle Indikation
- Ressourcen-UI: Klare Anzeige von Gegnerressourcen und Schwellenwerten
- Vorwarnungs-System: Zeitliche und visuelle Indikatoren für bevorstehende Zeitmanipulationen
- Phasenübergangs-Indikatoren: Deutliche Anzeige von HP-basierten Verhaltensänderungen

## Abhängigkeiten
- ZK-MECH-v1.0-20250325: Nutzt als Grundlage
- ZK-CLASS-*-v1.0-20250325: Implementiert klassen-spezifische Zeitfähigkeiten
- ZK-DUN-MECH-v1.0-20250327: Kampffeld-Effekte für Welten 1-5
