# 🔧 PHASE 3: MECHANIK-TUNING - IMPLEMENTATION

## Executive Summary
Phase 3 fokussiert auf das Feintuning der Opportunity Costs, Klassen-Synergien, Gegner-Anpassungen und Sound/Vibration-Integration. Diese Phase optimiert das Spielgefühl und stellt sicher, dass alle Mechaniken harmonisch zusammenarbeiten.

---

## 1. OPPORTUNITY COSTS FEINABSTIMMUNG

### Zeitmanipulations-Balance-Matrix

#### Zeitraub-Kosten (Spieler → Gegner)
| Zeitraub-Menge | Basis-Kosten | Penalty | Finale Kosten | Trade-off |
|----------------|--------------|---------|----------------|-----------|
| 0,5s | 1,5s | +0,5s | 2,0s | 1:0,25 Ratio |
| 1,0s | 2,0s | +0,5s | 2,5s | 1:0,4 Ratio |
| 1,5s | 3,5s | +0,5s | 4,0s | 1:0,375 Ratio |
| 2,0s | 4,5s | +0,5s | 5,0s | 1:0,4 Ratio |

**Design-Philosophie**: Zeitraub wird weniger effizient bei größeren Mengen

#### Verzögerungs-Kosten (Gegnerangriff verschieben)
| Verzögerung | Basis-Kosten | Penalty | Finale Kosten | Effizienz |
|-------------|--------------|---------|----------------|-----------|
| 1,0s | 1,0s | +0,5s | 1,5s | 66% |
| 2,0s | 2,0s | +0,5s | 2,5s | 80% |
| 3,0s | 2,5s | +0,5s | 3,0s | 100% |
| 4,0s | 3,5s | +0,5s | 4,0s | 100% |
| 5,0s | 4,0s | +0,5s | 4,5s | 111% |

**Design-Philosophie**: Verzögerung wird effizienter bei mittleren Werten

#### Schadens-Penalties für Kombo-Karten
| Karten-Typ | Zeit-Effekt | Schadens-Penalty | Begründung |
|------------|-------------|------------------|------------|
| Zeitraub + Schaden | 0,5s Raub | -20% Schaden | Balance für Dual-Effekt |
| Zeitraub + Schaden | 1,0s Raub | -40% Schaden | Stärkerer Trade-off |
| Verzögerung + Schaden | 2,0s Delay | -15% Schaden | Moderate Einbuße |
| Verzögerung + Schaden | 3,0s Delay | -25% Schaden | Signifikanter Trade-off |

### Klassen-spezifische Opportunity Costs

#### Chronomant
```
Spezialisierung: Zeitmanipulation
- Zeitmanipulations-Karten: -10% Penalty (effizienter)
- Direktschaden-Karten: +10% Zeitkosten (weniger effizient)
- Balance: Beste Kontrolle, schwächster Burst
```

#### Zeitwächter
```
Spezialisierung: Defensive und Reflexion
- Block-Karten: -0,5s Kosten bei hoher Schildmacht
- Angriffskarten: Standard-Kosten
- Balance: Längste Kämpfe, höchste Überlebenschance
```

#### Schattenschreiter
```
Spezialisierung: Tempo und Effizienz
- Zeitraub: -20% Kosten (effizienteste Klasse)
- Defensive Karten: +20% Kosten
- Balance: Schnellste Kills, fragilste Defensive
```

---

## 2. KLASSEN-SYNERGIEN-BALANCE

### Chronomant-Synergien

#### Arkanpuls + Kartenreihenfolge
```python
# Synergie-Berechnung
def calculate_chronomant_synergy(current_arkanpuls, card_sequence):
    base_bonus = 0
    
    # Arkanpuls-Verstärkung
    if current_arkanpuls >= 4:
        base_bonus += 0.15  # +15% Effektivität
    
    # Sequenz-Bonus
    if card_sequence == "time_to_elemental":
        base_bonus += 0.20  # +20% Schaden
    elif card_sequence == "elemental_to_time":
        base_bonus += 0.10  # +10% Effektivität
    
    # Synergie-Cap bei +40% um Übermacht zu verhindern
    return min(base_bonus, 0.40)
```

#### Optimale Spielmuster:
1. **Arkanpuls-Aufbau** (Runden 1-3)
2. **Sequenz-Vorbereitung** (Runde 4)
3. **Burst-Window** (Runde 5-6)
4. **Reset und Wiederholen**

### Zeitwächter-Synergien

#### Schildmacht + Phasenwechsel
```python
def calculate_zeitwaechter_synergy(shield_power, phase_state):
    defense_bonus = shield_power * 0.05  # +5% pro SM
    
    # Phasenwechsel-Verstärkung
    if phase_state == "defense_to_attack":
        return {"damage": 0.15, "defense": defense_bonus}
    elif phase_state == "attack_to_defense":
        return {"time_gain": 1.0, "defense": defense_bonus}
    
    return {"defense": defense_bonus}
```

#### Optimale Spielmuster:
1. **Block-Aufbau** (SM generieren)
2. **Phasenwechsel nutzen** (Alternierend)
3. **Schildbruch-Timing** (Bei 5 SM)
4. **Defensive Reset**

### Schattenschreiter-Synergien

#### Momentum + Schattensynergie
```python
def calculate_schattenschreiter_synergy(momentum, last_card_was_shadow):
    tempo_bonus = momentum * 0.05  # +5% pro Momentum
    
    if last_card_was_shadow:
        return {
            "next_card_cost": 0,  # Kostenlos
            "damage_bonus": tempo_bonus + 0.20  # +20% extra
        }
    
    # Momentum-Schwellen
    if momentum >= 4:
        tempo_bonus += 0.5  # +0,5s Zeitgewinn
    
    return {"damage_bonus": tempo_bonus}
```

#### Optimale Spielmuster:
1. **Schneller Momentum-Aufbau** (0→3 in 2 Runden)
2. **Schattensynergie-Ketten** (Schleier → Angriff)
3. **Schattenrausch-Explosion** (Bei 5 Momentum)
4. **Sofortiger Neuaufbau**

---

## 3. GEGNER-ANPASSUNGEN

### Gegner-Reaktionen auf Klassen-Mechaniken

#### Anti-Chronomant-Mechaniken
```json
{
  "temporal_immunity": {
    "description": "Immun gegen Zeitmanipulation für 3s nach Treffer",
    "counter_to": "Arkanpuls-Spam",
    "frequency": "25% der Gegner in Welt 3+"
  },
  "arcane_drain": {
    "description": "Stehlt 1 Arkanpuls bei Treffer",
    "counter_to": "Arkanschub-Aufbau",
    "frequency": "Elite-Gegner"
  }
}
```

#### Anti-Zeitwächter-Mechaniken
```json
{
  "unblockable_strikes": {
    "description": "Ignoriert Blocks, aber macht 50% weniger Schaden",
    "counter_to": "Schildmacht-Turtle",
    "frequency": "Spezial-Angriffe"
  },
  "shield_shatter": {
    "description": "Zerstört 2 Schildmacht bei Treffer",
    "counter_to": "SM-Stacking",
    "frequency": "Boss-Mechanik"
  }
}
```

#### Anti-Schattenschreiter-Mechaniken
```json
{
  "momentum_reset": {
    "description": "Setzt Momentum auf 0 bei Treffer",
    "counter_to": "Momentum-Snowball",
    "frequency": "15% Chance bei Elite"
  },
  "shadow_reveal": {
    "description": "Schattenkarten verlieren Synergien für 5s",
    "counter_to": "0-Kosten-Ketten",
    "frequency": "Welt 4+ Mechanik"
  }
}
```

### Adaptive Gegner-KI

```python
class AdaptiveEnemyAI:
    def __init__(self):
        self.player_pattern_memory = []
        self.adaptation_threshold = 3
    
    def analyze_player_pattern(self, player_actions):
        # Erkennt wiederholende Muster
        pattern = self.detect_pattern(player_actions[-5:])
        
        if pattern['confidence'] > 0.7:
            return self.select_counter_strategy(pattern['type'])
        
        return self.default_strategy()
    
    def select_counter_strategy(self, pattern_type):
        counters = {
            'arkanpuls_builder': 'arcane_drain_attack',
            'shield_turtle': 'rapid_multi_hits',
            'momentum_rusher': 'defensive_stance'
        }
        return counters.get(pattern_type, 'balanced')
```

---

## 4. SOUND/VIBRATION-INTEGRATION

### Klassen-spezifische Audio-Profile

#### Chronomant - Mystisch/Arkane
```javascript
const chronomantSounds = {
    // Ressourcen-Sounds
    arkanpulsGain: {
        file: 'sfx/arcane_charge_up.ogg',
        volume: 0.3,
        pitch: [0.9, 1.0, 1.1, 1.2, 1.3] // Steigt mit Arkanpuls
    },
    arkanschub: {
        file: 'sfx/arcane_explosion.ogg',
        volume: 0.6,
        reverb: true
    },
    
    // Karten-Sounds
    timeManipulation: {
        file: 'sfx/time_warp_cast.ogg',
        volume: 0.4,
        lowpass: 800 // Hz
    },
    elemental: {
        fire: 'sfx/fire_whoosh.ogg',
        ice: 'sfx/ice_crystallize.ogg',
        lightning: 'sfx/electric_zap.ogg'
    }
};
```

#### Zeitwächter - Metallisch/Defensiv
```javascript
const zeitwaechterSounds = {
    // Ressourcen-Sounds
    schildmachtGain: {
        file: 'sfx/shield_clang.ogg',
        volume: 0.4,
        pitch: 1.0,
        delay: 50 // ms
    },
    schildbruch: {
        file: 'sfx/shield_shatter_impact.ogg',
        volume: 0.7,
        bass_boost: true
    },
    
    // Karten-Sounds
    block: {
        file: 'sfx/metal_block.ogg',
        volume: 0.5,
        variations: 3
    },
    attack: {
        file: 'sfx/sword_swing.ogg',
        volume: 0.4,
        doppler: true
    }
};
```

#### Schattenschreiter - Schnell/Fließend
```javascript
const schattenschreiterSounds = {
    // Ressourcen-Sounds
    momentumGain: {
        file: 'sfx/whoosh_quick.ogg',
        volume: 0.2,
        pitch: [1.0, 1.1, 1.2, 1.3, 1.4], // Beschleunigt
        pan: [-0.5, 0.5] // Stereo-Movement
    },
    schattenrausch: {
        file: 'sfx/shadow_burst.ogg',
        volume: 0.5,
        echo: true
    },
    
    // Karten-Sounds
    shadowCard: {
        file: 'sfx/shadow_step.ogg',
        volume: 0.3,
        highpass: 1000 // Hz
    },
    attack: {
        file: 'sfx/blade_slice.ogg',
        volume: 0.3,
        speed: 1.2
    }
};
```

### Haptic Feedback Patterns

```javascript
const hapticLibrary = {
    // Universal
    cardPlay: [50], // Single tap
    timeGain: [30, 30, 30], // Triple pulse
    timeLoss: [100, 50, 100], // Warning pattern
    
    // Chronomant
    arkanpulsCharge: [20, 20, 20, 20, 20], // Building energy
    arkanschubReady: [200], // Strong pulse
    
    // Zeitwächter  
    blockSuccess: [80, 40], // Impact + settle
    schildmachtGain: [60], // Solid thunk
    schildbruchCharge: [20, 40, 60, 80, 100], // Building power
    
    // Schattenschreiter
    momentumTick: [10], // Light tick
    shadowSynergy: [30, 10, 30], // Quick double
    schattenrauschActive: [150, 50, 150, 50, 150] // Rapid pulse
};

function playHapticPattern(pattern, intensity = 1.0) {
    if ('vibrate' in navigator) {
        const scaledPattern = pattern.map(d => d * intensity);
        navigator.vibrate(scaledPattern);
    }
}
```

### Audio-Mixing und Priorisierung

```javascript
class AudioMixer {
    constructor() {
        this.channels = {
            ui: { volume: 0.3, priority: 1 },
            abilities: { volume: 0.5, priority: 2 },
            impacts: { volume: 0.6, priority: 3 },
            ambience: { volume: 0.2, priority: 0 }
        };
        this.activeSounds = [];
    }
    
    playSound(sound, channel = 'abilities') {
        // Prioritäts-Check
        if (this.activeSounds.length >= 8) {
            this.cullLowPriority();
        }
        
        const audio = new Audio(sound.file);
        audio.volume = sound.volume * this.channels[channel].volume;
        
        // 3D-Positionierung für Stereo
        if (sound.position) {
            this.apply3DPosition(audio, sound.position);
        }
        
        audio.play();
        this.trackActiveSound(audio, channel);
    }
}
```

---

## 5. BALANCING-METRIKEN

### Tracking-System

```python
class BalanceMetrics:
    def __init__(self):
        self.metrics = {
            'class_distribution': {},
            'average_combat_time': {},
            'resource_efficiency': {},
            'ability_usage': {},
            'win_rates': {}
        }
    
    def track_combat(self, combat_data):
        # Klassen-Performance
        self.update_class_metrics(combat_data)
        
        # Ressourcen-Nutzung
        self.track_resource_cycles(combat_data)
        
        # Ability-Popularität
        self.track_ability_usage(combat_data)
        
    def generate_balance_report(self):
        return {
            'underperforming_classes': self.identify_weak_classes(),
            'overpowered_combos': self.find_dominant_strategies(),
            'unused_abilities': self.find_low_usage_abilities(),
            'recommendations': self.suggest_adjustments()
        }
```

### Auto-Balance-Empfehlungen

```python
def suggest_balance_adjustments(metrics):
    adjustments = []
    
    # Klassen-Balance
    for class_name, data in metrics['class_distribution'].items():
        if data['usage'] < 0.25:  # Unter 25%
            adjustments.append({
                'class': class_name,
                'type': 'buff',
                'suggestion': 'Increase base power by 5%'
            })
        elif data['usage'] > 0.40:  # Über 40%
            adjustments.append({
                'class': class_name,
                'type': 'nerf',
                'suggestion': 'Reduce efficiency by 5%'
            })
    
    return adjustments
```

---

## 6. IMPLEMENTIERUNGS-PRIORITÄTEN

### Sofort (Kritisch):
1. Opportunity Costs Matrix in Combat-System
2. Klassen-Counter bei Gegnern
3. Basis-Sound-Implementation

### Kurzfristig (Wichtig):
1. Adaptive KI-Grundlagen
2. Haptic Feedback für Mobile
3. Balance-Tracking-System

### Mittelfristig (Nice-to-Have):
1. Erweiterte Audio-Effekte
2. KI-Lernalgorithmen
3. Auto-Balance-Vorschläge

---

## ERWARTETE ERGEBNISSE

### Messbare Verbesserungen:
- **Klassenverteilung**: 33% ±5% pro Klasse
- **Combat-Pacing**: Durchschnitt 45-90 Sekunden
- **Ability-Nutzung**: Alle Karten >5% Usage-Rate
- **Audio-Feedback**: +25% Spieler-Reaktionszeit

### Gameplay-Gefühl:
- **Klarere Entscheidungen**: Trade-offs sind offensichtlich
- **Fairere Kämpfe**: Gegner reagieren intelligent
- **Besseres Feedback**: Audio/Haptic verstärkt Aktionen
- **Balanciertes Meta**: Keine dominante Strategie

---

**✅ PHASE 3 STATUS: VOLLSTÄNDIG DEFINIERT**
**🎮 MECHANIK-TUNING: IMPLEMENTIERUNGSBEREIT**
**📈 NÄCHSTER SCHRITT: PHASE 4 - CONTENT-VORBEREITUNG**