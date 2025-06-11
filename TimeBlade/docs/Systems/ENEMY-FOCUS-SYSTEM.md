# Enemy Focus System - Dokumentation

## Übersicht

Das Enemy Focus System verwaltet die Warteschlange der Gegner und bestimmt, welcher Gegner aktuell vom Spieler angegriffen werden kann. Es bietet eine visuelle Darstellung der Queue und unterstützt verschiedene Gegner-Attribute für strategische Tiefe.

## Core-Komponenten

### 1. EnemyFocusSystem.cs
- **Singleton-Manager** für die Gegner-Warteschlange
- Verwaltet die Queue-Reihenfolge basierend auf Gegner-Attributen
- Behandelt Boss-Phasen und Summoned Enemies
- Feuert Events für UI-Updates

### 2. UI-Komponenten

#### EnemyCardDisplay.cs
- Große zentrale Karten-Darstellung des fokussierten Gegners
- Zeigt HP, Name, Tier, Attribute und Spezial-Icons
- Animationen für Schaden, Tod und Zeitdiebstahl
- Targeting-Support für Karten die ein Ziel brauchen

#### EnemySphereDisplay.cs
- Kleine Sphären-Darstellung für die Warteschlange
- Zeigt Position, HP-Balken und Attribute-Icons
- Highlight-Animation für aktuelles Ziel
- Smooth Transitions beim Queue-Update

### 3. Enemy-Attribute

Das System unterstützt folgende Gegner-Attribute:

- **None**: Standard-Verhalten, hinten anstellen
- **Guardian**: Spawnt VOR dem zu schützenden Elite/Boss
- **Aggressor**: Drängt sich an die Spitze der Queue
- **Ambush**: Überraschungsangriff, spawnt am Ende
- **Supporter**: Bufft andere Gegner, spawnt am Ende
- **Summoned**: Vom Boss beschworen, muss zuerst besiegt werden

## Implementierte Gegner-Typen

### Standard-Gegner
1. **RudelEcho**: Basis-Gegner mit Gruppen-Synergie
2. **GuardianEcho**: Beschützt Elite-Gegner und heilt sie
3. **AggressorEcho**: Drängt an Spitze, Enrage bei niedrigen HP
4. **AmbushEcho**: Starker Anfangs-Burst, dann schwächer
5. **SupporterEcho**: Bufft nahegelegene Gegner

### Elite-Gegner
1. **EliteZeitJaeger**: 2-Phasen Elite mit Doppelschlag

### Boss-Gegner
1. **TempusVerschlinger**: Tutorial-Boss mit Echo-Wellen und Minions

## Setup in Unity

### 1. EnemyFocusSystem Setup
```
1. Erstelle ein GameObject "EnemyFocusSystem"
2. Füge EnemyFocusSystem.cs hinzu
3. Weise folgende UI-Referenzen zu:
   - Central Card Position: UI-Transform für große Karte
   - Queue Sphere Container: Horizontal Layout Group für Sphären
   - Enemy Card Prefab: Prefab mit EnemyCardDisplay
   - Enemy Sphere Prefab: Prefab mit EnemySphereDisplay
```

### 2. Enemy Prefab Setup
```
Für jeden Gegner-Typ:
1. Erstelle UI-Prefab (Canvas-Child)
2. Füge entsprechende Enemy-Script-Komponente hinzu
3. Setze Stats in Inspector
4. Füge Animator für Animationen hinzu (optional)
```

### 3. UI Prefab Struktur

#### Enemy Card Prefab:
```
EnemyCard (RectTransform)
├── Background (Image)
├── Portrait Container
│   └── Enemy Portrait (Image)
├── Info Panel
│   ├── Name Text (TMP)
│   ├── HP Bar (Slider)
│   ├── HP Text (TMP)
│   ├── Tier Text (TMP)
│   └── Attribute Text (TMP)
├── Attribute Icons
│   ├── Guardian Icon
│   ├── Aggressor Icon
│   ├── Ambush Icon
│   ├── Supporter Icon
│   └── Summoned Icon
├── Effects
│   ├── Damage Flash
│   └── Target Highlight
└── Shield Icon (für Boss)
```

#### Enemy Sphere Prefab:
```
EnemySphere (RectTransform)
├── Sphere Image (Image)
├── HP Fill (Image, Fill Mode)
├── Attribute Icon (Image)
├── Position Text (TMP)
├── Highlight Ring (Image)
└── Summoned Indicator (Image)
```

## Integration mit anderen Systemen

### RiftCombatManager
- Nutzt `GetCurrentTarget()` für automatisches Targeting
- Ruft `EnemyCardClicked()` für manuelles Targeting auf

### RiftEnemySpawner
- Fügt Gegner via `AddEnemyToQueue()` hinzu
- Unterstützt spezielle Spawn-Kombinationen (Rudel, Elite+Guardian)

### Boss-System
- Boss wird immer als zentrale Karte angezeigt
- Summoned Enemies blockieren Boss-Angriffe
- Boss wird verwundbar wenn alle Summons tot sind

## Events

Das System feuert folgende Events:

```csharp
// Fokus hat sich geändert
EnemyFocusSystem.OnFocusChanged(RiftEnemy newFocus)

// Gegner wurde zur Queue hinzugefügt
EnemyFocusSystem.OnEnemyAddedToQueue(RiftEnemy enemy)

// Gegner wurde aus Queue entfernt
EnemyFocusSystem.OnEnemyRemovedFromQueue(RiftEnemy enemy)

// Queue wurde aktualisiert
EnemyFocusSystem.OnQueueUpdated(List<RiftEnemy> currentQueue)
```

## Best Practices

1. **Performance**: Queue-Updates nur bei Änderungen
2. **Visuals**: Nutze Object Pooling für Sphären bei vielen Gegnern
3. **Balance**: Guardian sollte nicht zu viel HP haben
4. **UX**: Klare visuelle Unterscheidung der Attribute
5. **Animations**: Smooth Transitions für Queue-Änderungen

## Zukünftige Erweiterungen

- [ ] Drag & Drop für manuelle Queue-Sortierung
- [ ] Vorhersage-System für kommende Spawns
- [ ] Combo-System für bestimmte Gegner-Reihenfolgen
- [ ] Boss-Phasen-Anzeige in der UI
- [ ] Detaillierte Gegner-Info bei Hover/Touch
