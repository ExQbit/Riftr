# Zeitklingen: Radikal vereinfachtes Materialsystem (v1.2)

## Änderungshistorie
- **v1.2 (2025-05-22):** Radikale Vereinfachung: Entfernung Sockelsystem, automatische Gates. Beibehaltung von 4 Materialien: Zeitkern, Zeitkernkit, Elementarfragment, Zeitfokus.

## Kernprinzipien

**Vier klare Materialien:**
- **Zeitkern**: Zufällige Kartenverbesserung (1 = 1 Level)
- **Zeitkernkit**: Gezielte Kartenverbesserung
- **Elementarfragment**: Evolution bei Level 9/25/35
- **Zeitfokus**: Attribut-Rerolls

**Automatische Gates**: Level 10/20/30/40 ohne Materialkosten

## Materialsystem

### Zeitkern
- **Funktion**: Zufällige Karte +1 Level
- **Erhalt**: Kämpfe, Quests, Events

### Zeitkernkit  
- **Funktion**: Auswahl aus 2 Basiskarten → gezieltes Leveling
- **Erhalt**: 3 Tagesquests = 1 Kit

### Elementarfragment
- **Funktion**: Evolution (1/2/3× bei Level 9/25/35)
- **Erhalt**: Elite-Gegner, Bosse

### Zeitfokus
- **Funktion**: Attribut-Rerolls (1/3/5×)
- **Erhalt**: Events, Zeitlose Kammer

## Automatische Gates

**Level 10/20/30/40**: Automatisches Seltenheits-Upgrade ohne Materialkosten
- +10%/+20%/+30%/+45% zufällige Attribut-Boosts
- Rerolls mit Zeitfokus möglich

## Vorteile

- **Maximale Klarheit**: Nur 4 Materialtypen
- **Keine Gate-Blockaden**: Automatische Progression
- **Entfernte Komplexität**: Sockelsystem weg
- **Mobile-optimiert**: Einfachste Mechaniken
- **Klare Weltprogression**: Ohne klassenspezifische Effekte

## Implementation

```sql
CREATE TABLE player_materials (
    player_id UUID PRIMARY KEY,
    time_cores INTEGER DEFAULT 0,
    time_core_kits INTEGER DEFAULT 0,
    elemental_fragments INTEGER DEFAULT 0,
    time_focus INTEGER DEFAULT 0
);
```

Vier Materialien, klare Funktionen, automatische Gates - maximale Vereinfachung.
