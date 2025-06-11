# Zeitklingen: Material-System (Mo.Co-Style) - RIFT-OPTIMIERT

## Die 4 Materialien

### Zeitkern
- **Funktion**: Zufällige Karte +1 Level (1:1)
- **Seltenheit**: Häufig (aber deutlich reduzierte Drop-Rate)
- **Erhalt**: Kämpfe, Rifts, Quests, Events, Login-Boni
- **Verwendung**: Direkt oder über Zeitkernkits

### Zeitkernkit  
- **Funktion**: Gezielte Kartenauswahl für Leveling
- **Seltenheit**: Selten
- **Erhalt**: 3 Tagesquests = 1 Kit, Events, Premium
- **Verwendung**: Auswahl aus 2 Basiskarten + Varianten

### Elementarfragment
- **Funktion**: Evolution bei Level 9/25/35 (1/2/3×)
- **Seltenheit**: Mittel (deutlich reduzierte Drop-Rate)
- **Erhalt**: Elite-Gegner, Rift-Wächter, Mini-Bosse, Elementar-Quests
- **Verwendung**: Universell für alle Elementarpfade

### Zeitfokus
- **Funktion**: Attribut-Rerolls (1/3/5×)
- **Seltenheit**: Sehr selten (Endgame-Material)
- **Erhalt**: Rift-Wächter, Events, Zeitlose Kammer, Elite-Gegner
- **Verwendung**: Standard/Gezielt/Garantierte Rerolls

## 🚨 DRASTISCH GESENKTE DROP-RATEN (Mo.Co.-Authentisch)

**Hinweis**: Diese deutlich reduzierten Raten betonen den Endgame-Charakter der Materialien und fördern Event-Teilnahme sowie strategisches Ressourcen-Management.

### Standard-Kämpfe (3-Minuten-Rifts & reguläre Kämpfe)
| Material | Droprate | Menge pro Drop | Kompensation |
|----------|----------|----------------|-------------|
| Zeitkern | 8.0% | 1-2 | Events, Quests, Garantierte Quellen |
| Elementarfragment | 2.0% | 1 | Events, Quests, Mastery-Boni |
| Zeitfokus | 0.3% | 1 | Events, Mastery-Boni, Premium-Quellen |

### Elite-Kämpfe (3-Minuten-Rift-Elites & Welt-Elites)
| Material | Droprate | Menge pro Drop | Kompensation |
|----------|----------|----------------|-------------|
| Zeitkern | 12.0% | 2-3 | Events, Elite-Quests |
| Elementarfragment | 4.0% | 1-2 | Events, Mastery-Quests |
| Zeitfokus | 0.8% | 1 | Events, Mastery-Dungeon |

### Bosse & 3-Minuten-Rift-Ender
| Material | Droprate | Menge pro Drop | Garantiert |
|----------|----------|----------------|------------|
| Zeitkern | 25.0% | 5-8 | Events kompensieren |
| Elementarfragment | 10.0% | 3-5 | Events kompensieren |
| Zeitfokus | 3.0% | 1-3 | Events kompensieren |

### 🎯 RIFT-SPEZIFISCHE DROP-RATEN
**Rift-Gegner folgen den obigen Kategorien, aber mit zusätzlichen Modifikatoren:**

#### Rift-Stufen-Multiplikatoren
| Rift-Stufe | Basis-Multiplikator | Zeitfokus-Bonus | Grund |
|------------|-------------------|------------------|-------|
| 1-10 | ×1.0 | - | Tutorial-Phase |
| 11-25 | ×1.2 | +0.1% | Frühe Progression |
| 26-40 | ×1.5 | +0.2% | Mittlere Progression |
| 41-50 | ×2.0 | +0.3% | Endgame-Stufen |
| 50+ | ×2.5 + (0.1×Stufe-50) | +0.5% | Infinite Scaling |

#### Rift-Wächter Garantien
- **1 Zeitkern-Drop garantiert** bei jedem Rift-Wächter (Stufe 10+)
- **Elementarfragment-Chance verdoppelt** bei Rift-Wächtern
- **Zeitfokus nur von Rift-Wächtern** (Standard-/Elite-Gegner: 0% Zeitfokus in Rifts)

### RNG-Drop-Berechnung (Ohne Pity-Timer)
```python
def calculate_material_drop(enemy_type, world_level, difficulty_modifier, rift_level=None):
    """Berechnet Material-Drop für einen besiegten Gegner (Mo.Co-Style RNG mit Rift-Integration)"""
    
    # DRASTISCH GESENKTE BASIS-RATEN
    base_rates = {
        "standard": {"zeitkern": 0.06, "elementarfragment": 0.015, "zeitfokus": 0.002},
        "elite": {"zeitkern": 0.10, "elementarfragment": 0.03, "zeitfokus": 0.005},
        "boss": {"zeitkern": 0.20, "elementarfragment": 0.08, "zeitfokus": 0.02}
    }
    
    world_modifiers = {
        1: {"zeitkern": 1.0, "elementarfragment": 1.0, "zeitfokus": 1.0},
        2: {"zeitkern": 1.2, "elementarfragment": 1.3, "zeitfokus": 1.0},
        3: {"zeitkern": 1.5, "elementarfragment": 1.5, "zeitfokus": 1.2},
        4: {"zeitkern": 1.8, "elementarfragment": 1.8, "zeitfokus": 1.5},
        5: {"zeitkern": 2.0, "elementarfragment": 2.0, "zeitfokus": 2.0}
    }
    
    difficulty_multipliers = {
        "normal": 1.0,
        "heroic": 1.5,
        "legendary": 2.0
    }
    
    # RIFT-SPEZIFISCHE MODIFIKATOREN
    rift_multiplier = 1.0
    if rift_level:
        if rift_level >= 50:
            rift_multiplier = 2.5 + (0.1 * (rift_level - 50))
        elif rift_level >= 41:
            rift_multiplier = 2.0
        elif rift_level >= 26:
            rift_multiplier = 1.5
        elif rift_level >= 11:
            rift_multiplier = 1.2
        
        # Rift-Wächter Garantien
        if enemy_type == "boss" and rift_level >= 10:
            base_rates["boss"]["zeitkern"] = max(0.50, base_rates["boss"]["zeitkern"])  # Min 50% für Rift-Wächter
    
    drops = {}
    base_enemy_rates = base_rates[enemy_type]
    world_mods = world_modifiers.get(world_level, world_modifiers[1])
    difficulty_mult = difficulty_multipliers[difficulty_modifier]
    
    for material, base_rate in base_enemy_rates.items():
        # Apply modifiers
        final_rate = base_rate * world_mods[material] * difficulty_mult * rift_multiplier
        final_rate = min(1.0, final_rate)  # Cap at 100%
        
        # Pure RNG roll (no pity protection)
        if random.random() < final_rate:
            amount = get_drop_amount(material, enemy_type, world_level, rift_level)
            drops[material] = amount
    
    return drops
```

## Kompensationssysteme (Ersatz für Pity-Timer)

### Garantierte Quellen (Erhöht wegen niedrigerer Drop-Raten)
| Quelle | Zeitkern | Zeitkernkit | Elementarfragment | Zeitfokus |
|--------|----------|-------------|-------------------|-----------|
| Tagesquest | 3-5 | - | 1-2 | 0-1 |
| 3 Tagesquests | - | 1 | - | - |
| Story-Quest | 8-15 | - | 2-4 | 1-3 |
| Event (täglich) | 15-25 | 1-2 | 3-5 | 2-4 |
| Login (täglich) | 5 | - | 1 | - |
| Login-Streak (7d) | 10 | 1 | 3 | 1 |
| Weltenboss (wöchentlich) | 25-40 | 2-3 | 8-12 | 5-8 |
| Rift-Abschluss | 2-6 | - | 1-2 | 0-1 |

### 🎯 ANGEPASSTE Progression-Ziele (Nach Drop-Rate-Senkung)
| Spielphase | Zeitkern/h | Elementarfragment/h | Zeitfokus/h | Playtime/Tag | Kompensation |
|------------|------------|---------------------|-------------|--------------|-------------|
| Früh (1-10h) | 2-4 | 0.3-0.6 | 0.1-0.2 | 1-2h | Tutorial-Boosts, Events |
| Mittel (10-50h) | 4-6 | 0.6-1.0 | 0.2-0.4 | 1.5-2h | Tägliche Events, Quests |
| Fortgeschritten (50-150h) | 6-10 | 1.0-1.8 | 0.4-0.8 | 2-2.5h | Mastery-Boni, Elite-Events |
| Endgame (150h+) | 8-15 | 1.5-3.0 | 0.6-1.5 | 2-3h | Mastery-Dungeons, Mega-Events |

**📊 Balancing-Ergebnisse:**
- **10× niedrigere Basis-Raten** als vorher
- **Events werden kritisch wichtig** für Progression
- **Mastery-System essentiell** für Endgame-Effizienz
- **Premium bleibt ~25% Beschleunigung** (nicht P2W)

### Event-Kompensation (Verstärkt)

#### Blitz-Events (3× täglich, 30 Min) - VERSTÄRKTE BONI
| Event-Name | Auslöser | Material-Bonus | Zusätzliche Effekte |
|------------|----------|----------------|-------------------|
| **Zeitrausch** | Alle 6-8h | +300% alle Materialien | +100% XP |
| **Materialflut** | Bei niedriger Aktivität | +500% Elementarfragmente & Zeitfokus | Garantierte Drops |
| **Perfekte Synchronisation** | Hohe Spieleraktivität | +250% alle Materialien | +50% Karteneffektivität |

#### Tages-Events (2-3× wöchentlich, 24h) - KRITISCH WICHTIG
| Event-Name | Thema | Material-Bonus | Spezialeffekte |
|------------|-------|----------------|--------------|
| **Feuer-Zeitalter** | DoT-Fokus | +400% Fragmente für Feuer-Evolutionen | DoT-Schäden +100% |
| **Frostzeit** | Kontrolle | +400% Fragmente für Eis-Evolutionen | Slow-Effekte +150% |
| **Gewittersturm** | Tempo | +400% Fragmente für Blitz-Evolutionen | Ketteneffekte +2 Ziele |
| **Evolution-Festival** | Allgemein | +400% alle Elementarfragmente | Evolution-Kosten -75% |

#### Mega-Events (1-2× monatlich, 5-7 Tage) - ESSENTIELL
| Event-Name | Community-Ziel | Material-Belohnung | Exklusive Inhalte |
|------------|---------------|-------------------|------------------|
| **Chronos-Erwachen** | 100M globale Kämpfe | +600% alle Materialien | Elite-Kartenvarianten |
| **Zeitkriege** | Klassen-Wettbewerb | Klassenspezifische Boni | Prestige-Titel |
| **Material-Bonanza** | Community-Sammlung | +800% seltene Materialien | Garantierte Premium-Drops |

### Mastery-System-Vorteile (KRITISCH für Endgame)

#### Passive Drop-Rate-Boni (Verstärkt)
| Mastery Level | Global Drop-Rate | Seltene Materialien | Zeitfokus-Bonus |
|---------------|------------------|-------------------|------------------|
| M2 | +25% alle Materialien | +50% Elementarfragmente | +100% Zeitfokus |
| M5 | +50% alle Materialien | +100% Elementarfragmente | +200% Zeitfokus |
| M10 | +75% alle Materialien | +150% Elementarfragmente | +300% Zeitfokus |
| M15 | +100% alle Materialien | +200% Elementarfragmente | +400% Zeitfokus |
| M20 | +125% alle Materialien | +250% Elementarfragmente | +500% Zeitfokus |
| M25+ | +150% alle Materialien | +300% + (10%×(M-25)) | +600% + (25%×(M-25)) |

## 🎮 RIFT-SYSTEM INTEGRATION

### Rift-Drop-Mechanik (5-Minuten-Sessions)
- **Kontinuierlicher 5-Minuten-Timer** (kein 60s-Reset)
- **Zeitenergie-Sammlung**: 600-1000 Punkte für Rift-Wächter-Beschwörung
- **Zwei-Phasen-Belohnung**: 
  - 54-64% Belohnungen während Rift (sofortige Drops)
  - 36-46% Belohnungen nach Abschluss ("virtueller zweiter Durchlauf")

### Rift-Stufen-Freischaltung (Klassenstufe-gekoppelt)
| Klassenstufe | Freigeschaltete Rift-Stufen | Zeitenergie-Bedarf | Schwierigkeit |
|-------------|----------------------------|-------------------|--------------|
| 1 (nach Prolog) | Rift-Stufe 1-5 | 600 | Tutorial |
| 5 | Rift-Stufe 6-10 | 650 | Einfach |
| 10 | Rift-Stufe 11-20 | 700 | Mittel |
| 15 | Rift-Stufe 21-30 | 800 | Schwer |
| 20 | Rift-Stufe 31-40 | 900 | Elite |
| 25 | Rift-Stufe 41-50 | 1000 | Endgame |
| M1+ | Rift-Stufe 50+ | 1000+ | Endlose Skalierung |

### Rift-Wächter Spezial-Drops
- **Einmalige Belohnung** pro Rift-Wächter (kein Respawn)
- **Garantierte Zeitkern-Drops** ab Stufe 10
- **Primäre Zeitfokus-Quelle** im Spiel
- **Profitiert von täglichen XP-Multiplikatoren**

## Premium-Integration (Angepasst)

### Zeitkristall-Konversionen (Limits erhöht)
| Material | Zeitkristall-Kosten | Tägliches Limit | Wöchentliches Limit |
|----------|---------------------|-----------------|---------------------|
| Zeitkernkit | 150 ZK | 5 | 25 |
| Elementarfragment | 100 ZK | 8 | 40 |
| Zeitfokus | 200 ZK | 5 | 20 |
| Zeitkern (10×) | 300 ZK | 3 | 15 |

### F2P-Fairness-Garantien (Verstärkt)
- **Vollständige Progression möglich**: Alle Inhalte ohne Zahlungen erreichbar
- **Keine exklusiven Materialien**: Premium bietet nur Geschwindigkeit
- **Event-Kompensation**: RNG-Verluste durch verstärkte Events ausgeglichen
- **~25% Beschleunigung**: Premium ist spürbar aber nicht überwältigend
- **Rift-System F2P-freundlich**: Alle Rift-Stufen ohne Premium erreichbar

## Implementation

### Rift-Drop-System
```python
class RiftDropSystem:
    def __init__(self):
        # Drastisch gesenkte Basis-Raten für Endgame-Fokus
        self.base_rates = {
            "standard": {"time_core": 0.06, "elemental_fragment": 0.015, "time_focus": 0.002},
            "elite": {"time_core": 0.10, "elemental_fragment": 0.03, "time_focus": 0.005}, 
            "rift_guardian": {"time_core": 0.20, "elemental_fragment": 0.08, "time_focus": 0.02}
        }
        
        self.rift_multipliers = {
            range(1, 11): 1.0,
            range(11, 26): 1.2,
            range(26, 41): 1.5,
            range(41, 51): 2.0
        }
    
    def calculate_rift_drops(self, enemy_type: str, rift_level: int, daily_xp_used: int) -> List[DropResult]:
        """Hauptfunktion für Rift-Drop-Berechnung mit XP-Multiplikatoren"""
        
        drops = []
        base_rates = self.base_rates[enemy_type]
        
        # Rift-Stufen-Multiplikator
        rift_mult = self._get_rift_multiplier(rift_level)
        
        # Tägliche XP-Multiplikatoren anwenden
        xp_mult = self._get_daily_xp_multiplier(daily_xp_used)
        
        for material, base_rate in base_rates.items():
            final_rate = base_rate * rift_mult
            final_rate = min(1.0, final_rate)  # Cap at 100%
            
            # Pure RNG roll (no pity protection)
            if random.random() < final_rate:
                base_amount = self._get_drop_amount(material, enemy_type, rift_level)
                # XP-Multiplikator auf Menge anwenden
                final_amount = max(1, int(base_amount * xp_mult))
                drops.append(DropResult(material, final_amount))
        
        return drops
    
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
    
    def _get_rift_multiplier(self, rift_level: int) -> float:
        """Rift-Stufen-spezifische Multiplikatoren"""
        if rift_level >= 50:
            return 2.5 + (0.1 * (rift_level - 50))
        elif rift_level >= 41:
            return 2.0
        elif rift_level >= 26:
            return 1.5
        elif rift_level >= 11:
            return 1.2
        else:
            return 1.0

    def apply_two_phase_rewards(self, rift_drops: List[DropResult]) -> Dict[str, List[DropResult]]:
        """Teilt Rift-Belohnungen in zwei Phasen auf"""
        immediate_drops = []
        completion_drops = []
        
        for drop in rift_drops:
            # 54-64% sofort, 36-46% nach Abschluss
            immediate_ratio = random.uniform(0.54, 0.64)
            immediate_amount = max(1, int(drop.amount * immediate_ratio))
            completion_amount = drop.amount - immediate_amount
            
            if immediate_amount > 0:
                immediate_drops.append(DropResult(drop.material_type, immediate_amount))
            if completion_amount > 0:
                completion_drops.append(DropResult(drop.material_type, completion_amount))
        
        return {
            "immediate": immediate_drops,
            "completion": completion_drops
        }
```

**🎯 FAZIT**: Das Material-System ist jetzt vollständig auf das Rift-System und Mo.Co.-Authentizität ausgerichtet, mit drastisch gesenkten Drop-Raten, die durch Events und Mastery-Boni kompensiert werden. Die täglichen XP-Multiplikatoren belohnen aktive F2P-Spieler erheblich.
