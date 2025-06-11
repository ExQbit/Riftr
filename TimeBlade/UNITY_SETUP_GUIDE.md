# Unity Meta Files Information

## ⚠️ WICHTIG: Meta-Dateien

Unity erstellt automatisch `.meta`-Dateien für alle Assets. Diese sind WICHTIG für:
- Asset-Referenzen zwischen Szenen und Prefabs
- Import-Einstellungen
- GUIDs für Assets

### Nach dem Import in Unity:

1. Unity wird automatisch `.meta`-Dateien für alle Scripts erstellen
2. **COMMITTEN SIE DIESE META-DATEIEN** in Ihr Versionskontrollsystem
3. Löschen Sie niemals `.meta`-Dateien manuell

### Wenn Fehler auftreten:

**"The associated script can not be loaded"**
- Script-Datei und .meta-Datei stimmen nicht überein
- Lösung: Beide löschen und Script neu importieren

**"Missing Prefab"**
- Prefab-Referenzen sind gebrochen
- Lösung: Prefabs neu erstellen und Referenzen neu zuweisen

## 🎨 Asset-Erstellung

### Benötigte Sprites (Placeholder)
- Card Background (200x300px)
- Enemy Sprites (64x64px oder 128x128px)
- UI Elements (verschiedene Größen)

### Benötigte Prefabs
1. **CardUI** - Karten-Darstellung
2. **ZeitEcho** - Tutorial-Gegner
3. **TempusVerschlinger** - Tutorial-Boss
4. **EnemySpawnPoint** - Spawn-Position

### UI-Setup
1. Canvas mit Scale With Screen Size (1920x1080 Reference)
2. Hand Area am unteren Bildschirmrand
3. Zeit/Punkte-Anzeige oben
4. Schildmacht-Icons links

## 📁 Empfohlene Ordnerstruktur

```
Assets/
├── _Core/                    # Alle Core-Scripts
├── Prefabs/
│   ├── Cards/               # Karten-Prefabs
│   ├── Enemies/             # Gegner-Prefabs
│   └── UI/                  # UI-Prefabs
├── Sprites/
│   ├── Cards/               # Karten-Artwork
│   ├── Enemies/             # Gegner-Sprites
│   └── UI/                  # UI-Elemente
├── Materials/               # Shader/Materials
├── Audio/                   # Sound-Effekte
└── Scenes/
    ├── TestBattle.unity     # Test-Szene
    └── MainMenu.unity       # Hauptmenü
```
