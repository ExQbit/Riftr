# Zeitklingen: Detaillierter Kampfablauf

> ⚔️ **[PLATZHALTER: Kampf-Flow-Diagramm - Visualisierung des gesamten Kampfablaufs]**

## 🎯 Übersicht

Dieses Dokument beschreibt den detaillierten Ablauf eines Kampfes in Zeitklingen, von der Rift-Auswahl bis zum Sieg oder Niederlage. Es dient als technische Referenz für die Implementierung und als Designgrundlage für das Kampfsystem.

## 📋 Inhaltsverzeichnis

1. [Vor dem Kampf](#vor-dem-kampf)
2. [Rift-Initialisierung](#rift-initialisierung)
3. [Der Kampfzyklus](#der-kampfzyklus)
4. [Kartenmechaniken im Detail](#kartenmechaniken-im-detail)
5. [Gegnermechaniken](#gegnermechaniken)
6. [Zeit-Management](#zeit-management)
7. [Rift-Punkte-System](#rift-punkte-system)
8. [Kampfende und Belohnungen](#kampfende-und-belohnungen)
9. [Spezialfälle und Edge-Cases](#spezialfälle-und-edge-cases)

---

## Vor dem Kampf

### Rift-Auswahl

**1. Rift-Menü öffnen**
- Spieler wählt "Rift betreten" im Hauptmenü
- Verfügbare Rifts werden angezeigt:
  - **Story-Rifts**: Einmalig, narrativ gebunden
  - **Grind-Zone-Rifts**: Wiederholbar, farming-orientiert
  - **Event-Rifts**: Zeitlich begrenzt, spezielle Belohnungen

**2. Rift-Informationen**
```
┌─────────────────────────────────────┐
│ Zeitwirbel-Tal - Rift Stufe 5      │
├─────────────────────────────────────┤
│ ⏱️ Dauer: 3 Minuten (180s)          │
│ 🎯 Ziel: 100 Rift-Punkte           │
│ 👹 Gegnertypen: 3-5                 │
│ 💎 Belohnungen:                     │
│   - Zeitkerne: 5-8                  │
│   - Elementarfragmente: 10% Chance  │
│   - Boss-Bonus: +3 Zeitkerne       │
└─────────────────────────────────────┘
```

### Pre-Combat Screen

**Gegner-Vorschau** (wenn verfügbar)
```
┌─────────────────────────────────────┐
│ 🛡️ RIFT-GEGNER-VORSCHAU            │
├─────────────────────────────────────┤
│ Mögliche Gegner:                    │
│ • Zeitschatten (8 HP) - 70%         │
│ • Zeitschleifer (18 HP) - 25%       │
│ • Temporaler Wächter (35 HP) - 5%   │
│                                     │
│ Boss: Tempus-Verschlinger (60 HP)   │
│ Erscheint bei 100 Rift-Punkten      │
└─────────────────────────────────────┘
```

---

## Rift-Initialisierung

### 1. Rift-Start-Sequenz

**Timeline (0-3 Sekunden)**
```
[0.0s] Rift-Portal-Animation startet
[0.5s] Spieler-Avatar betritt Rift
[1.0s] Kampfumgebung wird geladen
[1.5s] UI-Elemente erscheinen
[2.0s] Deck wird gemischt
[2.5s] Starthand wird gezogen (5 Karten)
[3.0s] Timer startet bei 180.00s
[3.1s] Erster Gegner spawnt
```

### 2. Initiale Spielerzustände

**Klassen-spezifische Startwerte**
- **Chronomant**: Arkanpuls = 0, Zeitstrom = Neutral
- **Zeitwächter**: Schildmacht = 0, Letzter Zyklus = Neutral
- **Schattenschreiter**: Momentum = 0, Schattensynergie = Inaktiv

**Universelle Startwerte**
- Zeit: 180.00 Sekunden
- Rift-Punkte: 0/100
- Handkarten: 5
- Nachziehstapel: 7-15 Karten (je nach Deck)
- Ablagestapel: Leer

### 3. Gegner-Spawn-System

**Spawn-Algorithmus**
```python
def spawn_next_enemy(rift_points, time_remaining):
    if rift_points >= 100:
        return spawn_rift_boss()
    
    # Gewichtete Auswahl basierend auf Fortschritt
    spawn_weights = calculate_spawn_weights(rift_points, time_remaining)
    enemy_type = weighted_random_choice(enemy_pool, spawn_weights)
    
    # 2-3 Sekunden Verzögerung zwischen Spawns
    delay = random.uniform(2.0, 3.0)
    schedule_spawn(enemy_type, delay)
```

---

## Der Kampfzyklus

### Hauptschleife

> 🔄 **[PLATZHALTER: Kampfzyklus-Animation - Zeigt den Flow zwischen Phasen]**

**1. Zeitphase (Kontinuierlich)**
- Timer läuft ununterbrochen (Präzision: 0.01s)
- Zeit-Anzeige aktualisiert sich alle 0.1s
- Bei 60s, 30s, 10s: Warnung-Animation

**2. Spielerphase (Aktiv)**
- Karte aus Hand wählbar
- Zeitkosten-Vorschau beim Hover
- Karte ausspielen:
  ```
  1. Karte wird ausgewählt
  2. Zeitkosten werden berechnet (mit allen Modifikatoren)
  3. Zeit wird abgezogen
  4. Karteneffekt wird ausgeführt
  5. Karte geht auf Ablagestapel
  6. Neue Karte wird gezogen (wenn Stapel vorhanden)
  ```

**3. Gegnerphase (Reaktiv)**
- Gegner-Timer läuft parallel
- Bei Erreichen des Angriffszeitpunkts:
  ```
  1. Angriffs-Animation startet
  2. Spieler hat Reaktionsfenster (0.5-1.0s)
  3. Schaden/Effekt wird angewendet
  4. Gegner-Ressourcen werden aktualisiert
  ```

### Detaillierter Aktionsablauf

**Kartenaktion-Pipeline**
```
[Input] → [Validierung] → [Kosten] → [Ausführung] → [Konsequenzen]
   ↓           ↓             ↓            ↓              ↓
Auswahl    Spielbar?    Zeit bezahlen  Effekte     State-Updates
```

**Beispiel: Schwertschlag (Zeitwächter)**
```
1. INPUT: Spieler wählt "Schwertschlag"
2. VALIDIERUNG: 
   - Genug Zeit? (2.5s verfügbar?)
   - Ziel vorhanden? (Gegner aktiv?)
3. KOSTEN:
   - Basis: 2.5s
   - Klassenboni: -0.0s (keine aktiv)
   - Final: 2.5s → Zeit: 177.50s
4. AUSFÜHRUNG:
   - Animation: Schwertschlag (0.3s)
   - Schaden: 8 (Basis) × 1.0 (keine Boni) = 8
   - Gegner HP: 18 → 10
5. KONSEQUENZEN:
   - Phasenwechsel-Bonus aktiviert
   - Nächste Verteidigung +1s Zeit
   - Karte → Ablagestapel
   - Neue Karte ziehen
```

---

## Kartenmechaniken im Detail

### Zeitkosten-Berechnung

**Basis-Formel**
```
Finale_Kosten = Basis_Kosten × Klassen_Mod × Situative_Mods
```

**Modifikator-Stack**
1. **Basis-Zeitkosten** (auf Karte definiert)
2. **Klassen-Modifikatoren**:
   - Chronomant: -5% bei 1+ Arkanpuls
   - Zeitwächter: -15% Verteidigung bei 2+ Schildmacht
   - Schattenschreiter: -50% Schatten bei 3+ Momentum
3. **Buff/Debuff-Modifikatoren**:
   - Zeitverzerrung: +15-30% Kosten
   - Beschleunigung: -10-20% Kosten
4. **Karten-Evolution-Boni**:
   - Können Zeitkosten modifizieren

**Anzeige-System**
```
Interne Berechnung: 2.37s
UI-Anzeige: 2.5s (gerundet auf 0.5s)
Detail-Tooltip: "2.37s (angezeigt als 2.5s)"
```

### Karteneffekt-Ausführung

**Effekt-Prioritäten** (von hoch zu niedrig)
1. **Sofort-Effekte**: Schaden, Heilung
2. **Zustandsänderungen**: Buffs, Debuffs
3. **Ressourcen-Generierung**: Arkanpuls, Schildmacht, Momentum
4. **Verzögerte Effekte**: DoTs, verzögerte Aktionen
5. **Karten-Manipulation**: Ziehen, Abwerfen, Mischen

**Effekt-Resolution**
```python
def resolve_card_effect(card, target, player_state):
    # 1. Soforteffekte
    if card.damage > 0:
        apply_damage(target, calculate_damage(card, player_state))
    
    # 2. Zeitmanipulation
    if card.time_gain > 0:
        player_state.time += card.time_gain
        trigger_time_gain_animation()
    
    # 3. Klassenressourcen
    if card.generates_resource:
        update_class_resource(player_state, card.resource_type)
    
    # 4. Statuseffekte
    for effect in card.status_effects:
        apply_status(target, effect, card.duration)
```

### Karten-Synergien

**Combo-System** (Klassenspezifisch)

**Chronomant - Elementar-Ketten**
```
Feuer → Feuer = +20% Schaden (Hitze-Aufbau)
Eis → Feuer = Dampf-Explosion (AoE)
Blitz → Beliebig = Kettenreaktion möglich
```

**Zeitwächter - Phasenwechsel**
```
Angriff → Verteidigung = +1s Zeitgewinn
Verteidigung → Angriff = +15% Schaden
Verteidigung → Verteidigung = +1 Schildmacht
```

**Schattenschreiter - Schattensynergie**
```
Schatten → Angriff = 0 Zeitkosten
Schatten → Schatten = Momentum +2 statt +1
Angriff × 3 schnell = Schattenrausch-Trigger
```

---

## Gegnermechaniken

### Gegner-KI-System

**Basis-Verhaltensmuster**
```python
class EnemyAI:
    def __init__(self, enemy_type):
        self.attack_pattern = enemy_type.pattern
        self.attack_timer = enemy_type.base_timer
        self.special_threshold = enemy_type.special_conditions
    
    def update(self, delta_time, player_state):
        self.attack_timer -= delta_time
        
        if self.attack_timer <= 0:
            action = self.determine_action(player_state)
            self.execute_action(action)
            self.reset_timer()
```

### Gegner-Ressourcen-System

**Beispiel: Zeitschleifer**
```
Schleifenergie: 0-3
- Generierung: +1 alle 4s
- Bei 2+ Energie: Temporaler Stoß verfügbar
- Bei 3 Energie: Doppelter Zeitdiebstahl
- Nach Spezial: Reset auf 0
```

**Boss-Phasen-System**
```
Phase 1 (100-70% HP): Basis-Angriffe, langsamer Aufbau
Phase 2 (70-40% HP): Erhöhte Frequenz, neue Fähigkeiten
Phase 3 (40-0% HP): Verzweiflung-Modus, alle Fähigkeiten
```

### Gegner-Spawn-Patterns

**Rift-Fortschritts-basiert**
```
0-25 Punkte: Hauptsächlich Standard-Gegner
25-50 Punkte: Mix aus Standard und Verstärkt
50-75 Punkte: Verstärkte Gegner dominieren
75-99 Punkte: Elite-Gegner erscheinen häufiger
100 Punkte: BOSS SPAWN
```

---

## Zeit-Management

### Zeit-Fluss-Mechaniken

**Basis-Zeitverlauf**
- Konstant: -1.00s pro Sekunde Realzeit
- Keine Pause-Funktion während Rift
- Präzision: 0.01s intern gespeichert

**Zeit-Modifikatoren**

**Zeitgewinn-Quellen**
1. **Direkt**: Karten mit "+Xs Zeit"
2. **DoT-Ticks**: +0.5s bis +1.5s pro Tick
3. **Klasseneffekte**: 
   - Zeitwächter: Block-Erfolg +0.5s
   - Chronomant: Arkanschub +1.0s
4. **Gegner-Niederlage**: Kleine Zeitboni möglich

**Zeitverlust-Quellen**
1. **Kartenkosten**: Primäre Zeitsenke
2. **Gegner-Zeitdiebstahl**: -0.5s bis -5.0s
3. **Debuffs**: Zeitverzerrung erhöht Kosten
4. **Verfehlen**: Zeit ohne Effekt verloren

### "Keine Caps"-Philosophie

**Opportunity Cost System**
```
Zeitmanipulation hat Kosten:
- Zeitraub-Karte: Kostet mehr Zeit als sie gibt
- Balance durch Kartenkosten, nicht durch Limits
- Theoretisch unbegrenzt, praktisch durch Rift begrenzt
```

**Beispiel-Kalkulation**
```
Temporaler Diebstahl (Schattenschreiter):
- Kosten: 2.0s
- Effekt: Stehle 1.0s vom Gegner
- Netto: -1.0s für Spieler
- Vorteil: Gegner-Angriff verzögert
```

---

## Rift-Punkte-System

### Punkte-Generierung

**Basis-Punktewerte**
| Gegnertyp | HP-Bereich | Rift-Punkte | Zeit-Belohnung |
|-----------|------------|-------------|----------------|
| Standard | 5-15 | 10-15 | 0-0.5s |
| Verstärkt | 16-30 | 15-20 | 0.5-1.0s |
| Elite | 31-50 | 20-30 | 1.0-2.0s |
| Mini-Boss | 51-80 | 30-40 | 2.0-3.0s |
| Rift-Boss | 80+ | 0 (Sieg) | 5.0s+ |

**Multiplikatoren**
- Schneller Kill (<5s): ×1.2 Punkte
- Perfekter Kill (kein Zeitverlust): ×1.5 Punkte
- Combo-Kill (mehrere schnell): ×1.1 pro Combo

### Boss-Spawn-Mechanik

**Bei 100 Punkten:**
1. Aktuelle Gegner despawnen (mit Warnung)
2. 3-Sekunden-Countdown
3. Boss-Spawn-Animation
4. Boss-HP-Leiste erscheint
5. Boss-Musik startet

**Boss-Besonderheiten**
- Keine weiteren Gegner-Spawns
- Zeit läuft weiter
- Spezielle Belohnungen bei Sieg
- Teilbelohnungen auch bei Niederlage

---

## Kampfende und Belohnungen

### Sieg-Bedingungen

**1. Boss besiegt**
- Volle Belohnungen
- Bonus-Materialien
- Fortschritts-Freischaltungen

**2. Zeit abgelaufen (mit Punkten)**
- Basis-Belohnungen für Punkte
- Reduzierte Material-Drops
- XP basierend auf Performance

**3. Aufgeben**
- Minimale Belohnungen
- Behält gesammelte Punkte
- Keine Strafzeit

### Belohnungs-Berechnung

**Basis-Formel**
```python
def calculate_rewards(rift_data):
    base_rewards = {
        'zeitkerne': rift_data.defeated_enemies * 0.6,
        'xp': rift_data.rift_points * 10,
        'fragments': 0
    }
    
    # Boss-Bonus
    if rift_data.boss_defeated:
        base_rewards['zeitkerne'] += 5
        base_rewards['fragments'] += roll_fragment_chance(0.25)
    
    # Zeit-Effizienz-Bonus
    time_efficiency = rift_data.time_remaining / 180.0
    if time_efficiency > 0.5:
        base_rewards['xp'] *= 1.25
    
    return apply_drop_modifiers(base_rewards)
```

### Post-Combat Screen

```
┌─────────────────────────────────────┐
│ RIFT ABGESCHLOSSEN                  │
├─────────────────────────────────────┤
│ Status: SIEG ⭐                      │
│ Zeit: 42.37s verbleibend            │
│ Rift-Punkte: 100/100                │
│ Boss: Tempus-Verschlinger ✓         │
├─────────────────────────────────────┤
│ BELOHNUNGEN:                        │
│ • Zeitkerne: 8                      │
│ • Elementarfragmente: 2             │
│ • XP: 1,250                         │
│ • Gold: 150                         │
├─────────────────────────────────────┤
│ [ERNEUT] [FORTFAHREN]               │
└─────────────────────────────────────┘
```

---

## Spezialfälle und Edge-Cases

### Technische Edge-Cases

**1. Gleichzeitige Aktionen**
```
Problem: Spieler und Gegner agieren im selben Frame
Lösung: Spieleraktionen haben immer Priorität
```

**2. Zeit erreicht 0 während Animation**
```
Problem: Karte wurde gespielt, Zeit läuft ab
Lösung: Aktuelle Aktion wird fertig ausgeführt
```

**3. Disconnect während Rift**
```
Problem: Verbindungsverlust
Lösung: 30s Reconnect-Fenster, dann Auto-Niederlage
```

### Gameplay Edge-Cases

**1. Unendliche Combos**
```
Theoretisch möglich durch "Keine Caps"
Praktisch begrenzt durch:
- Kartenlimit im Deck
- Rift-Timer
- Gegner-Interrupts
```

**2. Negative Zeit**
```
Unmöglich - Zeit minimum ist 0.00
Überschüssiger Zeitdiebstahl verfällt
```

**3. Deck erschöpft**
```
Ablagestapel wird automatisch gemischt
1.0s Shuffle-Animation
Keine Zeitstrafe
```

### Balance-Sicherungen

**Anti-Exploit-Maßnahmen**
1. **Makro-Erkennung**: Unmenschlich schnelle Inputs
2. **Zeit-Validierung**: Server-seitige Überprüfung
3. **Damage-Caps**: Einzelangriff max 999 Schaden
4. **Combo-Limiter**: Max 10 Aktionen pro Sekunde

---

## 🎮 Zusammenfassung

Der Kampfablauf in Zeitklingen ist ein fein abgestimmtes System aus:
- **Zeitdruck**: 3-Minuten-Limit erzeugt Spannung
- **Strategische Tiefe**: Kartenkosten vs. Effekte
- **Klassen-Identität**: Unique Mechaniken pro Klasse
- **Progression**: Spürbare Macht-Steigerung
- **Fairness**: Keine RNG in Kernmechaniken

Das System ist designed für:
- **Mobile Sessions**: 3-5 Minuten perfekt
- **Skill-Expression**: Meisterschaft möglich
- **Accessibility**: Einfach zu lernen
- **Depth**: Schwer zu meistern

> 📊 **[PLATZHALTER: Statistik-Dashboard - Zeigt durchschnittliche Kampfmetriken]**

---

**Version**: 1.0  
**Letzte Aktualisierung**: [DATUM]  
**Nächste Review**: Nach Alpha-Testing