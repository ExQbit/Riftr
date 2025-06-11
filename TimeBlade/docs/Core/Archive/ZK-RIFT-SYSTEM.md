# Zeitklingen: Rift-System - Zentraler Endgame-Inhalt

## 🌀 Rift-System Übersicht

Das Rift-System ist der zentrale Endgame-Inhalt von Zeitklingen, optimiert für mobile Sessions von 3-6 Minuten. Es bietet 50 Stufen mit progressiver Schwierigkeit und skaliert im Endgame unendlich. Das System dient als primäre Quelle für die gezielte Beschaffung von Endgame-Materialien.

## ⏰ Kern-Mechaniken

### 5-Minuten-Timer-System
- **Kontinuierlicher 5-Minuten-Timer** (kein 60s-Reset zwischen Gegnerbegegnungen)
- **Zeitenergie-Sammlung**: 600-1000 Punkte je nach Rift-Stufe
- **Rift-Wächter-Beschwörung**: Erfolgt bei Erreichen der Zeitenergie-Schwelle
- **Mobile-Optimierung**: Sessions von 3-6 Minuten perfekt für unterwegs

### Zeitenergie-Mechanik
```python
class RiftTimeEnergySystem:
    def __init__(self):
        self.energy_requirements = {
            range(1, 6): 600,      # Tutorial-Phase
            range(6, 11): 650,     # Einfach
            range(11, 21): 700,    # Mittel
            range(21, 31): 800,    # Schwer
            range(31, 41): 900,    # Elite
            range(41, 51): 1000,   # Endgame
            range(51, 999): 1000   # Infinite Scaling
        }
        
        self.energy_per_enemy = {
            "standard": 60,    # Standard-Gegner
            "elite": 120,      # Elite-Gegner
            "bonus": 200       # Bonus-Energie-Orbs
        }
    
    def get_energy_requirement(self, rift_level: int) -> int:
        """Bestimmt Zeitenergie-Bedarf für Rift-Stufe"""
        for level_range, requirement in self.energy_requirements.items():
            if rift_level in level_range:
                return requirement
        return 1000  # Fallback für sehr hohe Stufen
    
    def calculate_energy_gain(self, enemy_type: str, rift_level: int) -> int:
        """Berechnet Zeitenergie-Gewinn pro besiegtem Gegner"""
        base_energy = self.energy_per_enemy[enemy_type]
        
        # Höhere Rift-Stufen = mehr Energie pro Gegner
        level_multiplier = 1.0 + (rift_level - 1) * 0.02  # +2% pro Stufe
        
        return int(base_energy * level_multiplier)
```

## 🎯 Rift-Stufen-System

### Freischaltung (Klassenstufe-gekoppelt)
| Klassenstufe | Freigeschaltete Rift-Stufen | Zeitenergie-Bedarf | Schwierigkeit | Besondere Features |
|-------------|----------------------------|-------------------|--------------|-------------------|
| 1 (nach Prolog) | Rift-Stufe 1-5 | 600 | Tutorial | Feste Gegnerabfolge, erhöhte Drops |
| 5 | Rift-Stufe 6-10 | 650 | Einfach | Erste zufällige Begegnungen |
| 10 | Rift-Stufe 11-20 | 700 | Mittel | Elite-Gegner möglich |
| 15 | Rift-Stufe 21-30 | 800 | Schwer | Rudel-Kämpfe häufiger |
| 20 | Rift-Stufe 31-40 | 900 | Elite | Boss-ähnliche Rift-Wächter |
| 25 | Rift-Stufe 41-50 | 1000 | Endgame | Maximale Herausforderung |
| M1+ | Rift-Stufe 50+ | 1000+ | Infinite Scaling | Unbegrenzte Skalierung |

### Schwierigkeits-Progression
```python
def calculate_rift_difficulty(rift_level: int) -> Dict[str, float]:
    """Berechnet Schwierigkeits-Modifikatoren für Rift-Stufe"""
    
    base_multipliers = {
        "enemy_health": 1.0 + (rift_level - 1) * 0.15,      # +15% HP pro Stufe
        "enemy_damage": 1.0 + (rift_level - 1) * 0.10,      # +10% Schaden pro Stufe
        "enemy_speed": 1.0 + (rift_level - 1) * 0.05,       # +5% Geschwindigkeit pro Stufe
        "elite_chance": min(0.5, 0.05 + (rift_level - 1) * 0.02),  # Max 50% Elite-Chance
        "time_pressure": max(0.8, 1.0 - (rift_level - 1) * 0.01)   # Zeit wird knapper
    }
    
    # Infinite Scaling für Stufe 50+
    if rift_level >= 50:
        excess_levels = rift_level - 50
        base_multipliers["enemy_health"] *= 1.0 + (excess_levels * 0.25)
        base_multipliers["enemy_damage"] *= 1.0 + (excess_levels * 0.20)
        base_multipliers["elite_chance"] = min(0.8, base_multipliers["elite_chance"] + excess_levels * 0.05)
    
    return base_multipliers
```

## 🎮 Zwei-Phasen-Belohnungssystem

### Sofortige Belohnungen (54-64% der Gesamtbelohnung)
- **Während des Rifts**: Drops von besiegten Gegnern
- **Sofort sichtbar**: Material-Pickup-Animationen
- **Motivations-Verstärkung**: Kontinuierliches Feedback
- **Anteil**: 54-64% der Gesamtbelohnung (zufällig gewichtet)

### Abschluss-Belohnungen (36-46% der Gesamtbelohnung) 
- **Nach Rift-Wächter-Besiegen**: "Virtueller zweiter Durchlauf"
- **Große Belohnungs-Explosion**: Dramatische UI-Animation
- **Rift-Wächter-Bonus**: Zusätzliche garantierte Drops
- **Anteil**: 36-46% der Gesamtbelohnung

```python
class RiftRewardSystem:
    def __init__(self):
        self.immediate_ratio_range = (0.54, 0.64)
        self.completion_ratio_range = (0.36, 0.46)
    
    def distribute_rewards(self, total_rewards: Dict[str, int]) -> Dict[str, Dict[str, int]]:
        """Teilt Rift-Belohnungen in zwei Phasen auf"""
        
        # Zufällige Verteilung innerhalb der Ranges
        immediate_ratio = random.uniform(*self.immediate_ratio_range)
        completion_ratio = 1.0 - immediate_ratio
        
        immediate_rewards = {}
        completion_rewards = {}
        
        for material, total_amount in total_rewards.items():
            immediate_amount = max(1, int(total_amount * immediate_ratio))
            completion_amount = total_amount - immediate_amount
            
            if immediate_amount > 0:
                immediate_rewards[material] = immediate_amount
            if completion_amount > 0:
                completion_rewards[material] = completion_amount
        
        return {
            "immediate": immediate_rewards,
            "completion": completion_rewards
        }
    
    def apply_daily_xp_multiplier(self, rewards: Dict[str, int], daily_xp_used: int) -> Dict[str, int]:
        """Wendet tägliche XP-Multiplikatoren auf Belohnungen an"""
        
        multiplier = self._get_daily_xp_multiplier(daily_xp_used)
        
        boosted_rewards = {}
        for material, amount in rewards.items():
            boosted_rewards[material] = max(1, int(amount * multiplier))
        
        return boosted_rewards
    
    def _get_daily_xp_multiplier(self, daily_xp_used: int) -> float:
        """Bestimmt XP-Multiplikator basierend auf täglich genutzter XP"""
        if daily_xp_used < 10000:
            return 4.0  # Schnellstart-Boost
        elif daily_xp_used < 22500:
            return 3.0  # Aktiver Spieler-Boost
        elif daily_xp_used < 37500:
            return 2.0  # Standard-Boost
        else:
            return 1.0  # Basis-Rate
```

## 🎯 Rift-spezifische Drop-Raten (Mo.Co.-authentisch)

### Drastisch gesenkte Basis-Raten
| Material | Standard-Gegner | Elite-Gegner | Rift-Wächter |
|----------|-----------------|--------------|--------------|
| **Zeitkern** | 6.0% (1-2) | 10.0% (2-3) | 20.0% (5-8) |
| **Elementarfragment** | 1.5% (1) | 3.0% (1-2) | 8.0% (3-5) |
| **Zeitfokus** | 0.2% (1) | 0.5% (1) | 2.0% (1-3) |

### Rift-Stufen-Multiplikatoren
| Rift-Stufe | Basis-Multiplikator | Zeitfokus-Bonus | Grund |
|------------|-------------------|------------------|-------|
| 1-10 | ×1.0 | - | Tutorial-Phase |
| 11-25 | ×1.2 | +0.1% | Frühe Progression |
| 26-40 | ×1.5 | +0.2% | Mittlere Progression |
| 41-50 | ×2.0 | +0.3% | Endgame-Stufen |
| 50+ | ×2.5 + (0.1×(Stufe-50)) | +0.5% | Infinite Scaling |

### Rift-Wächter Spezial-Mechaniken
- **Einmalige Belohnung** pro Rift-Wächter (kein Respawn)
- **Garantierte Zeitkern-Drops** ab Stufe 10 (mindestens 1 Zeitkern)
- **Primäre Zeitfokus-Quelle** im Spiel
- **Profitiert von täglichen XP-Multiplikatoren**
- **Keine Zeitfokus-Drops** von Standard-/Elite-Gegnern in Rifts

## 🏆 Balancing-Ergebnisse & Ziele

### Material-Akkumulation (täglich, mit XP-Multiplikatoren)
| Spieler-Typ | Zeitkern/Tag | Elementarfragment/Tag | Zeitfokus/Tag | Rifts pro Tag |
|-------------|--------------|----------------------|---------------|---------------|
| Anfänger (4× Multiplikator) | ~5.4 | ~1.2 | ~0.3 | 2-3 |
| Fortgeschritten (1× Multiplikator) | ~2.4 | ~0.6 | ~0.15 | 3-4 |
| Hardcore (1× Multiplikator) | ~4.8 | ~1.2 | ~0.3 | 5-6 |

### Progression-Timing
- **Anfänger**: ~21 Tage für vollständiges Deck (mit Events & Quests)
- **Fortgeschritten**: ~30 Tage für vollständiges Deck
- **Tägliches Limit**: 15 Zeitkerne aus Rifts empfohlen (Balance)

### Rift-Completion-Raten (Ziel-Metriken)
| Rift-Stufe | Completion-Rate | Durchschnittliche Versuche | Grund |
|------------|----------------|---------------------------|-------|
| 1-10 | 95% | 1.1 | Tutorial-freundlich |
| 11-25 | 80% | 1.3 | Herausfordernd aber fair |
| 26-40 | 60% | 1.8 | Skill-Anforderung steigt |
| 41-50 | 40% | 2.5 | Endgame-Herausforderung |
| 50+ | 20% | 4.0+ | Nur für Hardcore-Spieler |

## 🎨 Prolog-Rift (Tutorial-Rift)

### Spezielle Tutorial-Mechaniken
- **Geringere Schwierigkeit**: 50% weniger Gegner-HP/Schaden
- **Feste Gegnerabfolge**: Keine Zufälligkeit für konsistente Lernerfahrung
- **Erhöhte Zeitenergie-Drops**: +100% für garantierten Rift-Wächter
- **Einfacherer Rift-Wächter**: Tutorial-Version mit reduzierten Fähigkeiten
- **Kein virtueller zweiter Durchlauf**: Vereinfacht für Lernzwecke

### Tutorial-Ablauf
1. **Rift-Einführung**: "Rifts sind Zeitrisse zu anderen Dimensionen..."
2. **Zeitenergie-Erklärung**: "Sammle Zeitenergie, um den Rift-Wächter zu beschwören"
3. **5-Minuten-Timer-Demo**: "Du hast 5 Minuten, um so viele Gegner wie möglich zu besiegen"
4. **Erste Gegner-Begegnungen**: 3-4 feste Standard-Gegner
5. **Rift-Wächter-Beschwörung**: Bei 600 Zeitenergie automatisch
6. **Tutorial-Rift-Wächter**: Vereinfachte Version des echten Bosses
7. **Belohnungs-Erklärung**: Sofortige Belohnungsverteilung (kein zweiter Durchlauf)

```python
class PrologRiftSystem(RiftSystem):
    def __init__(self):
        super().__init__()
        self.tutorial_modifications = {
            "enemy_health_modifier": 0.5,      # 50% weniger HP
            "enemy_damage_modifier": 0.5,      # 50% weniger Schaden
            "time_energy_bonus": 2.0,          # 100% mehr Zeitenergie
            "fixed_enemy_sequence": [
                "zeitschatten", "zeitschatten", 
                "zeitschleifer", "zeitnebel"
            ],
            "guaranteed_guardian_spawn": True,
            "no_second_phase_rewards": True
        }
    
    def generate_prolog_rift(self) -> Dict:
        """Generiert das spezielle Tutorial-Rift"""
        return {
            "rift_id": "prolog_tutorial_rift",
            "level": 0,  # Spezielle Tutorial-Stufe
            "time_limit_seconds": 300,
            "time_energy_requirement": 600,
            "enemy_sequence": self.tutorial_modifications["fixed_enemy_sequence"],
            "guardian": "tutorial_tempus_verschlinger",
            "difficulty_modifiers": {
                "enemy_health": self.tutorial_modifications["enemy_health_modifier"],
                "enemy_damage": self.tutorial_modifications["enemy_damage_modifier"],
                "time_energy_gain": self.tutorial_modifications["time_energy_bonus"]
            },
            "reward_structure": "tutorial_simplified",
            "ui_guidance": True,
            "skip_virtual_second_run": True
        }
```

## 🎯 Gegner-Pools & Zufalls-Generation

### Welt-spezifische Gegner-Pools
```python
RIFT_ENEMY_POOLS = {
    "welt_1": {
        "standard": [
            {"name": "zeitschatten", "weight": 35, "hp": 8},
            {"name": "zeitschleifer", "weight": 30, "hp": 18},
            {"name": "zeitnebel", "weight": 25, "hp": 22}
        ],
        "elite": [
            {"name": "elite_zeitschleifer", "weight": 40, "hp": 35},
            {"name": "temporaler_waechter", "weight": 35, "hp": 35},
            {"name": "chrono_former", "weight": 25, "hp": 40}
        ],
        "guardians": [
            {"name": "tempus_verschlinger", "hp": 60},
            {"name": "nebelwandler", "hp": 80}
        ]
    },
    "welt_2": {
        "standard": [
            {"name": "flammengeist", "weight": 40, "hp": 25, "dot_immune": True},
            {"name": "feuerschmied", "weight": 35, "hp": 30},
            {"name": "glutkern", "weight": 25, "hp": 20, "explodes_on_death": True}
        ],
        # ... weitere Welten
    }
}

def generate_rift_encounters(rift_level: int, world_pool: str) -> List[Dict]:
    """Generiert zufällige Begegnungen für ein Rift"""
    
    pool = RIFT_ENEMY_POOLS[world_pool]
    encounters = []
    
    # Anzahl Begegnungen basierend auf Rift-Stufe
    base_encounters = 8 + (rift_level // 5)  # Mehr Gegner in höheren Stufen
    
    # Elite-Chance basierend auf Stufe
    elite_chance = min(0.5, 0.05 + (rift_level - 1) * 0.02)
    
    for i in range(base_encounters):
        if random.random() < elite_chance:
            enemy = weighted_random_choice(pool["elite"])
        else:
            enemy = weighted_random_choice(pool["standard"])
        
        # Schwierigkeit skalieren
        scaled_enemy = scale_enemy_for_rift(enemy, rift_level)
        encounters.append(scaled_enemy)
    
    return encounters
```

## 📊 Telemetrie & Metriken

### Rift-spezifische KPIs
```python
RIFT_TELEMETRY_TARGETS = {
    "completion_rates": {
        "tutorial_rift": 0.95,      # 95% sollen Prolog-Rift schaffen
        "rift_1_10": 0.90,          # 90% für erste Stufen
        "rift_11_25": 0.75,         # 75% für mittlere Stufen
        "rift_26_40": 0.50,         # 50% für schwere Stufen
        "rift_41_50": 0.25,         # 25% für Endgame-Stufen
        "rift_50_plus": 0.10        # 10% für infinite scaling
    },
    "engagement": {
        "avg_rifts_per_day": 3.5,           # 3.5 Rifts pro aktiven Spieler
        "avg_rift_duration_seconds": 240,   # 4 Minuten durchschnittlich
        "time_energy_efficiency": 0.85,     # 85% erreichen Rift-Wächter
        "retry_rate": 0.3                   # 30% wiederholen gescheiterte Rifts
    },
    "rewards": {
        "zeitkern_per_rift": 1.8,          # 1.8 Zeitkerne pro Rift (Durchschnitt)
        "zeitfokus_per_week": 2.5,         # 2.5 Zeitfokus pro Woche aus Rifts
        "material_satisfaction": 0.75       # 75% zufrieden mit Drop-Raten
    }
}

def track_rift_performance(rift_result: Dict) -> None:
    """Trackt Rift-Performance für Balancing"""
    
    telemetry_data = {
        "rift_level": rift_result["level"],
        "completion_time_seconds": rift_result["duration"],
        "enemies_defeated": rift_result["enemies_killed"],
        "time_energy_collected": rift_result["time_energy"],
        "guardian_defeated": rift_result["guardian_killed"],
        "materials_earned": rift_result["rewards"],
        "attempts_needed": rift_result["attempt_count"],
        "player_level": rift_result["player_level"],
        "daily_xp_multiplier": rift_result["xp_multiplier_used"]
    }
    
    # Sende an Telemetrie-System
    send_telemetry("rift_completion", telemetry_data)
    
    # Prüfe auf Balancing-Probleme
    check_rift_balance_issues(telemetry_data)

def check_rift_balance_issues(data: Dict) -> None:
    """Automatische Balancing-Problem-Erkennung"""
    
    issues = []
    
    # Zu niedrige Completion-Rate
    if data["guardian_defeated"] and data["attempts_needed"] > 5:
        issues.append({
            "type": "difficulty_spike",
            "rift_level": data["rift_level"],
            "suggested_fix": "Reduce enemy HP by 10%"
        })
    
    # Zu schnelle Completion
    if data["completion_time_seconds"] < 120 and data["guardian_defeated"]:
        issues.append({
            "type": "too_easy",
            "rift_level": data["rift_level"],
            "suggested_fix": "Increase enemy count or HP by 15%"
        })
    
    # Material-Drop-Probleme
    total_materials = sum(data["materials_earned"].values())
    if total_materials == 0 and data["guardian_defeated"]:
        issues.append({
            "type": "no_drops",
            "rift_level": data["rift_level"],
            "suggested_fix": "Check drop rate calculation"
        })
    
    # Log Issues für Review
    if issues:
        log_balance_issues("rift_system", issues)
```

## 🎮 UI/UX Integration

### Rift-Auswahl-Interface
- **Verfügbare Stufen**: Klar markiert mit Schwierigkeits-Indikatoren
- **Belohnungs-Vorschau**: Zeigt erwartete Material-Drops
- **Zeitenergie-Anzeige**: Visueller Fortschrittsbalken
- **Rift-Wächter-Teaser**: Preview des Boss-Gegners

### In-Rift-UI-Elemente
- **5-Minuten-Timer**: Prominent und immer sichtbar
- **Zeitenergie-Sammler**: Animierter Fortschrittsbalken
- **Sofortige Drop-Anzeige**: Material-Pickup-Animationen
- **Gegner-Counter**: "Gegner besiegt: X/∞"
- **Rift-Wächter-Warnung**: "Rift-Wächter bereit!" bei Erreichen der Schwelle

### Post-Rift-Belohnungs-Screen
- **Zwei-Phasen-Darstellung**: Sofortige + Abschluss-Belohnungen
- **Virtueller Durchlauf-Animation**: Dramatische Belohnungs-Explosion
- **Progression-Feedback**: "Nächste Rift-Stufe freigeschaltet!"
- **Performance-Statistiken**: Zeit, Gegner besiegt, Effizienz

## 🔄 Integration mit anderen Systemen

### Quest-System-Verbindung
- **Rift-spezifische Quests**: "Komplettiere 3 Rifts der Stufe X"
- **Material-Sammel-Quests**: "Sammle 10 Zeitfokus aus Rifts"
- **Progression-Quests**: "Erreiche Rift-Stufe 25"

### Event-System-Integration
- **Rift-Events**: "Doppelte Zeitenergie-Wochenende"
- **Guardian-Events**: "Alle Rift-Wächter droppen garantiert Zeitfokus"
- **Speed-Events**: "Rift-Completion unter 3 Minuten = Bonus-Belohnungen"

### Mastery-System-Verbindung
- **Mastery-Rifts**: Exklusive Stufen 51+ für M1+ Spieler
- **Elite-Guardians**: Verstärkte Rift-Wächter ab M5
- **Mastery-Material-Boni**: Erhöhte Drop-Raten für hohe Mastery-Level

**🎯 FAZIT**: Das Rift-System ist das Herzstück des Zeitklingen-Endgames - mobile-optimiert, progressionsfördernd und perfekt in die Mo.Co.-authentische Material-Economy integriert. Es belohnt tägliches Engagement erheblich durch die XP-Multiplikatoren und bietet endlose Herausforderungen für Hardcore-Spieler.
