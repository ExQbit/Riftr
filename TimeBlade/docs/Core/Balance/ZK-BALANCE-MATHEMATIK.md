# Zeitklingen: Balance-Mathematik & Kill-Zeit-Kalkulationen

## Grundformeln

### Effektive DPS-Berechnung
```
Effektiver_DPS = Kartenschaden / (Kartenkosten + Animationszeit)
Animationszeit = 0.3s (konstant)
```

### Zeit-Budget pro Gegnertyp
| Gegnertyp | HP-Range | Kill-Zeit-Ziel | % der Rift-Zeit |
|-----------|----------|----------------|-----------------|
| Standard | 5-25 | 5-15s | 3-8% |
| Elite | 35-50 | 20-30s | 11-17% |
| Mini-Boss | 50-80 | 35-50s | 19-28% |
| Boss | 80-120 | 70-100s | 39-56% |

### Rudel-Effizienz-Matrix

#### Einzelziel vs AoE Kalkulation
**Szenario:** 6 Gegner (3 Rudel à 2 Mitglieder, je 10 HP)

**Einzelziel-Strategie:**
- Karte: 3 Schaden für 1.0s
- Pro Gegner: 4 Karten = 4.0s (+ 0.3s Animation × 4 = 1.2s) = 5.2s
- 6 Gegner total: 31.2s

**AoE-Strategie:**
- Karte: 2 AoE-Schaden für 1.5s
- Pro Rudel: 5 Karten = 7.5s (+ 0.3s × 5 = 1.5s) = 9.0s
- 3 Rudel total: 18.0s (da AoE beide Mitglieder gleichzeitig trifft)

**Effizienz-Gewinn:** 13.2s gespart (42% schneller)

#### Durchbruchschaden-Effizienz
**Beispiel:** 8-Schaden-Karte gegen 3-HP-Ziel
- Primäres Ziel: 3 HP (tot)
- Überschuss: 5 Schaden
- Durchbruch: 2.5 Schaden (50%) auf nächstes Mitglied
- Effizienz: 5.5 Schaden für eine Karte statt nur 3

### Starter-Karten Zeitkosten-Balance (Level 1)

| Kartentyp | Zeitkosten | Schaden/Effekt | DPS | Verwendungszweck |
|-----------|------------|----------------|-----|------------------|
| **Basis-Angriff** | 0.8-1.0s | 2-3 Schaden | 2.0-2.5 | Standard-Schaden |
| **Starker Angriff** | 2.0-2.5s | 6-8 Schaden | 2.4-2.7 | Burst/Finisher |
| **Utility/Block** | 0.8-1.5s | Spezialeffekte | - | Situativ |
| **AoE (früh)** | 1.5-2.0s | 2-3 AoE | 1.0-1.5/Ziel | Rudel-Kontrolle |
| **DoT** | 1.2-1.8s | 1-2/Tick (3 Ticks) | 1.7-2.5 | Zeit-Effizienz |

### Zeit-Economy Benchmarks (v5.0 Playtest-Ergebnisse)

#### Tutorial-Rifts
- **Verfügbare Zeit:** 90-180s
- **Benötigte Zeit:** 5-35s
- **Reserve:** 55-175s (massive Sicherheit)
- **Lernziel:** Experimentieren ohne Zeitdruck

#### Welt 1 Standard-Rifts
- **Verfügbare Zeit:** 180s
- **Durchschnittlich benötigt:** 40-60s
- **Reserve:** 120-140s (komfortabel)
- **Ziel-DPS:** 2-3

#### Welt 1 Boss-Rift
- **Verfügbare Zeit:** 180s
- **Boss-Kill-Zeit:** 70-100s
- **Weg zum Boss:** 20-30s
- **Reserve:** 50-90s (herausfordernd aber fair)
- **Ziel-DPS:** 3-4

### Balance-Anpassungen aus Playtest v5.0

#### Zeit-Parasit
- **Alt:** +0.3s auf ALLE Karten
- **Neu:** +0.2s auf Karten >1.0s
- **Begründung:** Billige Karten bleiben viable als Konter

#### Chrono-Händler
- **Frühe Deals:** 3s Zeit für 15 Schaden (5 DPS-Äquivalent)
- **Späte Deals:** 7s Zeit für 25 Schaden (3.6 DPS-Äquivalent)
- **Begründung:** Dynamische Risk/Reward basierend auf Spielfortschritt

#### Ruinen-Wächter
- **Alt:** -50% Schaden von Karten <Level 5
- **Neu:** -20% Schaden von Karten <Level 3
- **Begründung:** Spieler haben zu diesem Zeitpunkt 3-5 Karten auf Level 3+

### AoE-Effizienz-Breakpoints

| Rudel-Größe | Einzelziel-Zeit | AoE-Zeit | Break-Even bei | Empfehlung |
|-------------|-----------------|----------|----------------|------------|
| 2 Gegner | 10s | 8s | 1.25× Kosten | AoE lohnt sich |
| 3 Gegner | 15s | 10s | 1.5× Kosten | AoE stark überlegen |
| 4 Gegner | 20s | 12s | 1.67× Kosten | AoE essentiell |
| 5+ Gegner | 25s+ | 14s | 1.8× Kosten | AoE alternativlos |

### Klassen-spezifische DPS-Kurven

#### Zeitwächter
- **Start (SM 0):** 1.8-2.2 DPS
- **Mid (SM 2-3):** 2.5-3.0 DPS
- **Peak (SM 5):** 4.0-5.0 DPS (Schildbruch-Spike)
- **Durchschnitt:** 2.5-3.0 DPS

#### Schattenschreiter
- **Start (M 0):** 2.0-2.5 DPS
- **Mid (M 2-3):** 3.0-3.5 DPS
- **Peak (M 5):** 5.0-6.0 DPS (Schattenrausch)
- **Durchschnitt:** 3.0-3.5 DPS

#### Chronomant
- **Start (AP 0):** 1.5-2.0 DPS
- **Mid (AP 2-3):** 2.5-3.0 DPS
- **Peak (AP 5):** 4.5-5.5 DPS (Arkanschub)
- **Durchschnitt:** 2.8-3.2 DPS

### Zeitdiebstahl-Limits

**Maximaler Zeitverlust pro Rift:** 15% (27s von 180s)

| Quelle | Max pro Instanz | Häufigkeit | Total-Beitrag |
|--------|-----------------|------------|---------------|
| Kleine Diebstähle | 0.5-1.0s | Häufig | 10-15s |
| Mittlere Diebstähle | 1.5-2.5s | Gelegentlich | 5-10s |
| Boss-Diebstähle | 3.0-5.0s | 2-3× pro Kampf | 6-15s |
| Umgebung/Passive | 0.1s/s | Dauerhaft | Variable |

### Material-Drop-Effizienz

#### Zeitkern-Farming
- **Standard-Gegner:** 8% × 10-15 pro Rift = 0.8-1.2 Kerne/Rift
- **Elite-Gegner:** 12% × 2-3 pro Rift = 0.24-0.36 Kerne/Rift
- **Boss:** 25% × 5-8 Kerne = 1.25-2.0 Kerne/Rift
- **Total pro Rift:** ~2.3-3.6 Zeitkerne

#### Zeit pro Kartenlevel
- **1 Zeitkern = 1 Level**
- **Rifts pro Level:** 0.3-0.5 (mit perfekten Runs)
- **Zeit pro Rift:** 3-5 Minuten
- **Zeit pro Level:** 1-2.5 Minuten Spielzeit

### Opportunity-Cost-Formeln

#### Zeitmanipulation Trade-offs
```
Effektive_Kosten = Basis_Kosten + Opportunity_Penalty
Effektiver_Schaden = Basis_Schaden × (1 - Schadens_Penalty)

Beispiel Zeitraub-Karte:
- Basis: 1.0s Kosten, 3 Schaden, 0.5s Zeitraub
- Mit Penalties: 1.5s Kosten, 2.7 Schaden (-10%), 0.5s Zeitraub
- Netto-Zeitgewinn: 0.5s - 0.5s (Penalty) = 0s
- Wert: Taktischer Vorteil, nicht Zeit-Effizienz
```

### Skalierung über Kartenlevel

| Level | Stat-Bonus | Zeitkosten | Effektiver DPS | Bemerkung |
|-------|------------|------------|----------------|-----------|
| 1 | 100% | 1.0s | 2.0 | Basis |
| 10 | 130% | 1.0s | 2.6 | +30% Effizienz |
| 20 | 170% | 1.0s | 3.4 | +70% Effizienz |
| 30 | 220% | 1.0s | 4.4 | +120% Effizienz |
| 40 | 280% | 1.0s | 5.6 | +180% Effizienz |
| 50 | 350% | 1.0s | 7.0 | +250% Effizienz |

### Boss-Phasen-Mathematik

#### Phase-Übergangs-DPS-Anforderungen
- **Phase 1 → 2:** Sollte in 20-30s abgeschlossen sein
- **Phase 2 → 3:** Weitere 25-35s
- **Phase 3 → Kill:** Finale 25-35s

#### Heilungs-Gegenkalkulation
**Beispiel Chrono-Rückfluss (Welt 1 Boss):**
- Heilt 10% HP (8-11 HP) alle 30s
- Erfordert 3-4 zusätzliche Karten
- Verlängert Kampf um ~10-15s pro Heilung
- Maximal 2 Heilungen realistisch = +20-30s Kampfzeit

### Performance-Metriken

#### Erfolgreiche Rift-Completion
- **S-Rank:** <60s verbraucht (>120s Reserve)
- **A-Rank:** 60-90s verbraucht (90-120s Reserve)
- **B-Rank:** 90-120s verbraucht (60-90s Reserve)
- **C-Rank:** 120-150s verbraucht (30-60s Reserve)
- **Knapp:** >150s verbraucht (<30s Reserve)

#### Effizienz-Indikatoren
- **Karten pro Gegner:** Optimal 3-5 für Standard, 8-12 für Elite
- **Zeitverlust-Ratio:** <10% der Gesamtzeit optimal
- **AoE-Nutzung:** >50% Schaden durch AoE bei Rudel-Rifts
- **Ressourcen-Uptime:** Klassen-Ressource >60% der Zeit aktiv

### Endgame-Skalierung

#### Rift-Stufen-Progression
| Stufe | Gegner-HP | Gegner-Schaden | Zeit-Limit | Belohnungs-Multi |
|-------|-----------|----------------|------------|------------------|
| 1-10 | 100-150% | 100-125% | 180s | 1.0-1.5× |
| 11-20 | 150-250% | 125-175% | 180s | 1.5-2.5× |
| 21-30 | 250-400% | 175-250% | 180s | 2.5-4.0× |
| 31-40 | 400-700% | 250-400% | 180s | 4.0-7.0× |
| 41-50 | 700-1000% | 400-600% | 180s | 7.0-10.0× |
| 50+ | +100%/Stufe | +50%/Stufe | 180s | +1.0×/Stufe |

### Balance-Validierungs-Checkliste

- [ ] Tutorial unmöglich zu verlieren (<20% Zeit verbraucht)
- [ ] Welt 1 Standard-Rifts in 40-60s schaffbar
- [ ] Boss-Kämpfe fordern 70-100s (faire Herausforderung)
- [ ] AoE mindestens 40% effizienter gegen Rudel
- [ ] Zeitdiebstahl unter 15% Limit pro Rift
- [ ] Alle Klassen erreichen 2.5-3.5 DPS Durchschnitt
- [ ] Progression fühlt sich stetig an (keine Plateaus)
- [ ] Material-Drops ermöglichen stetiges Leveling

---

**STATUS: Balance-Framework etabliert und playtest-validiert**
**NÄCHSTE SCHRITTE: Implementierung und Live-Daten-Sammlung**