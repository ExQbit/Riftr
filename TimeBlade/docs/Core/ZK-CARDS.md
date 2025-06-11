# Zeitklingen: Karten-System

## Zeitkern-System

### Grundprinzip
**1 Zeitkern = 1 Level** für eine Karte (bis Level 50)

### Zeitkern
- **Funktion**: Zufällige Karte +1 Level
- **Erhalt**: Kämpfe (60% Chance), Quests (2-3 garantiert), Events
- **Auto-Verwendung**: Optional aktivierbar
- **Limits**: Keine Obergrenze

### Zeitkernkit
- **Funktion**: Gezielte Kartenauswahl → +1 Level
- **Erhalt**: 3 Tagesquests = 1 Kit, Events, Premium (150 Zeitkristalle)
- **Auswahl**: 2 zufällige Basiskarten + alle Varianten/Evolutionen
- **Limits**: Max. 10 im Inventar

### Einschränkungen
- **Klassenstufen-Limit**: Kartenlevel ≤ Klassenstufe × 2
- **Gates blockieren**: Karten an Level 10/20/30/40 können nicht gelevelt werden
- **Max Level**: Karten auf Level 50 können nicht gelevelt werden

## Automatische Gates

### Gate-Mechanik
Bei Level 10, 20, 30, 40 erfolgen **automatische** Seltenheits-Upgrades ohne Materialkosten.

| Level | Upgrade | Attribut-Boost | Visueller Effekt |
|-------|---------|---------------|------------------|
| 10 | Common → Uncommon | +10% zufällig | Grüner Rahmen |
| 20 | Uncommon → Rare | +20% zufällig | Blauer Rahmen |
| 30 | Rare → Epic | +30% zufällig | Violetter Rahmen |
| 40 | Epic → Legendary | +45% zufällig | Goldener Rahmen |

### Attribut-Boosts
Zufällige Verbesserung eines numerischen Attributs:
- **Schaden-Attribute**: Direkter Schaden, DoT-Schaden, AoE-Schaden
- **Zeit-Attribute**: Zeitkosten, Zeitgewinn, Effektdauer
- **Klassen-Attribute**: Arkankraft, Schildmacht, Momentum
- **Spezial-Attribute**: Kettenziele, Statuseffekte

### Gate-Boost-Berechnung
```python
def calculate_gate_boost(base_value, rarity_multiplier):
    boost_value = base_value * rarity_multiplier
    return min(boost_value, base_value * 2.0)  # Max 100% boost
```

## Evolution-System

### Evolution-Freischaltung
- **Level 9**: Evolution 1 (1× Elementarfragment)
- **Level 25**: Evolution 2 (2× Elementarfragment)  
- **Level 35**: Evolution 3 (3× Elementarfragment)

### Elementarpfade
**Pfadwahl bei Evolution 1 legt alle weiteren fest:**
- **Feuer**: DoT-Fokus, offensive Stärke
- **Eis**: Kontrolle, defensive Effekte
- **Blitz**: Tempo, Ketteneffekte, Synergien

### Evolution-Effekte
Jede Stufe verändert Kartenfunktion grundlegend:
- **Stufe 1**: Grundlegende Elementarspezialisierung
- **Stufe 2**: Verstärkte Elementareffekte + neue Mechaniken
- **Stufe 3**: Maximale Elementarkraft + transformative Effekte

## Stat-Skalierung

### Level-Skalierung
Jedes Level erhöht Basisattribute gemäß Skalierung:

| Level-Bereich | Steigerung pro Level | Kumulativ |
|---------------|---------------------|-----------|
| Level 1-10 | +3% | +30% |
| Level 11-20 | +4% | +70% |
| Level 21-30 | +5% | +120% |
| Level 31-40 | +6% | +180% |
| Level 41-50 | +7% | +250% |

### Betroffene Attribute
- **Direkter Schaden**: Primärer Schadenswert
- **Blockwert**: Defensive Schadensverweigerung
- **DoT-Schaden pro Tick**: Schaden über Zeit-Effekte
- **Heilungswert**: Gesundheitswiederherstellung
- **Flächenschaden**: AoE-Schadenswerte
- **Reflektierter Schaden**: Zurückgeworfener Schaden

### Skalierungs-Formeln
```python
def calculate_stat_scaling(base_value, current_level):
    """Berechnet skalierten Attributwert basierend auf Level"""
    if current_level <= 10:
        multiplier = 1.0 + (current_level * 0.03)
    elif current_level <= 20:
        multiplier = 1.30 + ((current_level - 10) * 0.04)
    elif current_level <= 30:
        multiplier = 1.70 + ((current_level - 20) * 0.05)
    elif current_level <= 40:
        multiplier = 2.20 + ((current_level - 30) * 0.06)
    else:  # Level 41-50
        multiplier = 2.80 + ((current_level - 40) * 0.07)
    
    return int(base_value * multiplier)
```

## Reroll-System

### Reroll-Mechanik
Spieler können Karten-Attribute mit **Zeitfokus** neu würfeln.

### Reroll-Typen
| Typ | Zeitfokus-Kosten | Erfolgsrate | Effekt |
|-----|------------------|-------------|--------|
| Standard | 1× | 100% | Komplett zufälliges neues Attribut |
| Gezielt | 3× | 100% | Zufälliges Attribut aus gewählter Familie |
| Garantiert | 5× | 100% | Exakt gewähltes Attribut |
| Premium | 10× | 100% | Wähle aus 3 garantierten Optionen |

### Attribut-Familien
**Offensiv:**
- Direkter Schaden (+5% bis +25%)
- DoT-Schaden (+3% bis +20%)
- Kettenziele (+1 bis +3)
- AoE-Radius (+10% bis +40%)
- Kritische Trefferchance (+2% bis +15%)

**Defensiv:**
- Blockwert (+5% bis +30%)
- Resistenzen (+10% bis +35%)
- Reflexion (+5% bis +25%)
- Schadensreduktion (+3% bis +20%)

**Temporal:**
- Zeitkosten (-0.1s bis -1.0s)
- Zeitgewinn (+0.2s bis +1.5s)
- Effektdauer (+10% bis +50%)
- Cooldownreduktion (+5% bis +30%)

**Klassen-spezifisch:**
- Arkankraft-Generierung (+1 bis +3)
- Schildmacht-Boni (+10% bis +40%)
- Momentum-Effizienz (+5% bis +25%)

## Power-Level-Berechnung

### Gesamtstärke-Formula
```python
def calculate_card_power(card):
    """Berechnet die Gesamtstärke einer Karte"""
    
    base_power = card.base_stats.power
    
    # Level-Skalierung
    level_multiplier = get_level_multiplier(card.level)
    
    # Seltenheits-Boni
    rarity_bonus = get_rarity_bonus(card.rarity)
    
    # Evolution-Boni
    evolution_bonus = get_evolution_bonus(card.evolution_level, card.element)
    
    # Attribut-Boni
    attribute_bonus = sum(card.bonus_attributes.values())
    
    total_power = (base_power * level_multiplier * rarity_bonus * evolution_bonus) + attribute_bonus
    
    return int(total_power)
```

## Implementation

### Datenmodell
```sql
CREATE TABLE player_cards (
    card_id UUID PRIMARY KEY,
    player_id UUID NOT NULL,
    base_card_id VARCHAR(50) NOT NULL,
    level INTEGER DEFAULT 1 CHECK (level >= 1 AND level <= 50),
    rarity VARCHAR(20) DEFAULT 'common' CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
    evolution_path VARCHAR(20) DEFAULT NULL CHECK (evolution_path IN ('fire', 'ice', 'lightning', NULL)),
    evolution_level INTEGER DEFAULT 0 CHECK (evolution_level >= 0 AND evolution_level <= 3),
    bonus_attributes JSONB DEFAULT '{}',
    is_at_gate BOOLEAN DEFAULT FALSE,
    power_level INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE player_materials (
    player_id UUID PRIMARY KEY,
    time_cores INTEGER DEFAULT 0 CHECK (time_cores >= 0),
    time_core_kits INTEGER DEFAULT 0 CHECK (time_core_kits >= 0 AND time_core_kits <= 10),
    elemental_fragments INTEGER DEFAULT 0 CHECK (elemental_fragments >= 0),
    time_focus INTEGER DEFAULT 0 CHECK (time_focus >= 0),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE card_evolution_data (
    id UUID PRIMARY KEY,
    base_card_id VARCHAR(50) NOT NULL,
    element_path VARCHAR(20) NOT NULL,
    evolution_level INTEGER NOT NULL,
    modified_attributes JSONB NOT NULL,
    new_effects JSONB DEFAULT '[]',
    art_variant VARCHAR(100),
    particle_effects JSONB DEFAULT '[]'
);
```

### Leveling-Algorithmus
```python
def level_card_with_time_core(player_id, card_id=None):
    """Levele eine Karte mit einem Zeitkern"""
    
    player_materials = get_player_materials(player_id)
    if player_materials.time_cores <= 0:
        return {"success": False, "error": "Keine Zeitkerne verfügbar"}
    
    if not card_id:
        card_id = get_random_levelable_card(player_id)
    
    card = get_player_card(card_id)
    if not card:
        return {"success": False, "error": "Karte nicht gefunden"}
    
    if not is_card_levelable(card):
        reason = get_level_block_reason(card)
        return {"success": False, "error": f"Karte kann nicht gelevelt werden: {reason}"}
    
    old_level = card.level
    card.level += 1
    player_materials.time_cores -= 1
    
    gate_applied = False
    if card.level in [10, 20, 30, 40]:
        gate_applied = apply_automatic_gate_upgrade(card)
    
    card.power_level = calculate_card_power(card)
    
    save_player_card(card)
    save_player_materials(player_materials)
    
    return {
        "success": True,
        "old_level": old_level,
        "new_level": card.level,
        "gate_applied": gate_applied,
        "new_power": card.power_level
    }

def is_card_levelable(card):
    """Prüft ob eine Karte gelevelt werden kann"""
    
    if card.level >= 50:
        return False
    
    if card.is_at_gate:
        return False
    
    player_class_level = get_player_class_level(card.player_id, card.class_type)
    max_allowed_level = player_class_level * 2
    if card.level >= max_allowed_level:
        return False
    
    return True

def apply_automatic_gate_upgrade(card):
    """Wendet automatisches Gate-Upgrade an"""
    
    gate_upgrades = {
        10: ("common", "uncommon", 0.10),
        20: ("uncommon", "rare", 0.20),
        30: ("rare", "epic", 0.30),
        "40": ("epic", "legendary", 0.45)
    }
    
    if card.level not in gate_upgrades:
        return False
    
    from_rarity, to_rarity, boost_multiplier = gate_upgrades[card.level]
    
    if card.rarity != from_rarity:
        return False
    
    card.rarity = to_rarity
    
    available_attributes = get_boostable_attributes(card)
    if available_attributes:
        chosen_attribute = random.choice(available_attributes)
        current_value = card.bonus_attributes.get(chosen_attribute, 0)
        boost = int(current_value * boost_multiplier) if current_value > 0 else int(get_base_attribute_value(chosen_attribute) * boost_multiplier)
        card.bonus_attributes[chosen_attribute] = current_value + boost
    
    return True
```

## Zeitkosten-Berechnungssystem

### Interne Präzision vs. Anzeige
```python
def calculate_card_time_cost(base_cost, player_state):
    """Berechnet finale Zeitkosten mit allen Modifikatoren"""
    
    # Basis-Kosten aus Kartendefinition
    internal_cost = base_cost
    
    # Klassen-spezifische Modifikatoren
    class_modifier = get_class_time_modifier(player_state)
    internal_cost *= class_modifier
    
    # Situative Modifikatoren (Evolution, Buffs, etc.)
    situational_modifiers = get_situational_modifiers(player_state)
    for modifier in situational_modifiers:
        internal_cost *= modifier
    
    # Präzise interne Berechnung (0,01s genau)
    final_internal_cost = round(internal_cost, 2)
    
    # Anzeige-Werte
    displayed_ui_cost = normalize_to_half_second(final_internal_cost)
    
    return {
        "internal": final_internal_cost,      # Für Berechnungen
        "ui_display": displayed_ui_cost,      # Für Haupt-UI
        "detail_display": final_internal_cost  # Für Detail-Ansicht
    }

def normalize_to_half_second(cost):
    """Rundet auf nächste 0,5s für Mobile-UI"""
    return round(cost * 2) / 2

def get_class_time_modifier(player_state, card_type=None):
    """Berechnet klassen-spezifische Zeitkosten-Modifikatoren"""
    
    if player_state.class_type == "chronomant":
        # Basis-Zeiteffizienz bei 1+ Arkanpuls
        if player_state.arkanpuls >= 1:
            modifier = 0.95  # -5% für alle Karten
        else:
            modifier = 1.0
            
        # Zusätzlicher Bonus für Zeitmanipulation bei 3+ Arkanpuls
        if player_state.arkanpuls >= 3 and card_type == "time_manipulation":
            modifier *= 0.9  # Weitere -10% (kumulativ -15%)
        
        return modifier
    
    elif player_state.class_type == "zeitwaechter":
        if player_state.schildmacht >= 2 and card_type == "defense":
            return 0.85  # -15% für Verteidigungskarten
    
    elif player_state.class_type == "schattenschreiter":
        if player_state.momentum >= 3 and card_type == "shadow":
            return 0.5  # -50% für Schattenkarten
    
    return 1.0  # Kein Modifikator
```

### Kartenkosten-Attribute
```sql
-- Erweiterte Karten-Tabelle mit Zeitkosten-Daten
ALTER TABLE cards ADD COLUMN base_time_cost DECIMAL(5,2) NOT NULL;
ALTER TABLE cards ADD COLUMN is_time_manipulation BOOLEAN DEFAULT FALSE;
ALTER TABLE cards ADD COLUMN is_defense_card BOOLEAN DEFAULT FALSE;
ALTER TABLE cards ADD COLUMN is_shadow_card BOOLEAN DEFAULT FALSE;
```

## Balancing-Parameter

### Anpassbare Werte
```python
BALANCE_CONFIG = {
    "level_scaling": {
        "tier_1": 0.03,  # Level 1-10
        "tier_2": 0.04,  # Level 11-20  
        "tier_3": 0.05,  # Level 21-30
        "tier_4": 0.06,  # Level 31-40
        "tier_5": 0.07   # Level 41-50
    },
    "gate_boosts": {
        "uncommon": 0.10,
        "rare": 0.20,
        "epic": 0.30,
        "legendary": 0.45
    },
    "reroll_costs": {
        "standard": 1,
        "targeted": 3,
        "guaranteed": 5,
        "premium": 10
    },
    "time_cost_modifiers": {
        "chronomant_time_manipulation": 0.9,
        "zeitwaechter_defense": 0.85,
        "schattenschreiter_shadow": 0.5
    }
}
```
