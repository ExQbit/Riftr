# Zeitklingen - Unity Gameplay Loop Implementation

## 🎮 Überblick

Dies ist die erste spielbare Implementierung des Zeitklingen-Gameplay-Loops. Das System implementiert die Kern-Mechaniken eines zeit-basierten Kartenspiels, bei dem **Zeit die einzige Ressource** ist - Spieler haben KEINE Lebenspunkte!

### ⚡ Kern-Features

- **3-Minuten-Rift-System** (180 Sekunden Standard, 90 Sekunden Tutorial)
- **Echtzeitbasierter Kampf** (kein rundenbasiertes System)
- **Schildmacht-Mechanik** für den Zeitwächter
- **100 Rift-Punkte** System für Boss-Spawn
- **Kartensystem mit Zeitkosten** (gerundet auf 0.5s für Mobile)
- **Tutorial-Gegner** (Zeit-Echo) und Boss (Tempus-Verschlinger)

## 🚀 Quick Start

### 1. Test-Szene einrichten

1. Erstelle eine neue Unity-Szene
2. Füge ein leeres GameObject hinzu und nenne es "GameSystems"
3. Füge das `RiftTestController`-Script hinzu
4. Drücke Play!

Der RiftTestController erstellt automatisch alle benötigten Systeme.

### 2. Manuelle Einrichtung (für Production)

```
Hierarchy:
├── GameSystems
│   ├── RiftTimeSystem
│   ├── RiftPointSystem
│   ├── RiftCombatManager
│   └── RiftEnemySpawner
├── Player
│   ├── ZeitwaechterPlayer
│   └── ShieldPowerSystem
├── UI
│   ├── RiftUIController
│   └── HandController
└── Enemies (werden zur Laufzeit gespawnt)
```

## 🎯 Systeme im Detail

### Zeit-System (`RiftTimeSystem`)
- Verwaltet die 3-Minuten-Timer
- "Keine Caps"-Philosophie - Zeit kann über 180s steigen
- Präzision: 0.01s intern, 0.5s UI-Anzeige
- Events: `OnTimeChanged`, `OnTimeExpired`, `OnTimeGained`, `OnTimeStolen`

### Punkte-System (`RiftPointSystem`)
- 100 Punkte = Boss-Spawn
- Standard-Gegner: 10-15 Punkte
- Elite-Gegner: 20-30 Punkte
- Speed & Combo-Multiplikatoren

### Schildmacht (`ShieldPowerSystem`)
- 0-5 Schildmacht, generiert durch erfolgreiche Blocks
- Verfalls-Mechanik: Nach 5s Inaktivität
- Passive Boni bei 1/2/3/4 SM
- Schildbruch bei 5 SM: 15 Schaden + 2s Zeitraub

### Kampf-Manager (`RiftCombatManager`)
- Koordiniert alle Kampf-Systeme
- States: Inactive → RiftStarting → InCombat → BossPhase → Victory/Defeat
- Verwaltet Gegner-Spawning und Boss-Trigger

## 🃏 Karten-System

### Zeitwächter Starter-Deck
- **4x Schwertschlag** (1.5s, 5 Schaden)
- **2x Schildschlag** (1.5s, 5 Schaden + Zeitschutz)
- **2x Zeitblock** (1.5s, 4s Block, +0.5s bei Erfolg)

### Karten-Factory
```csharp
// Erstelle Starter-Deck
var deck = ZeitwaechterCardFactory.CreateStarterDeck();

// Erstelle einzelne Karten
var schwertschlag = ZeitwaechterCardFactory.CreateSchwertschlag();
```

## 🎮 Test-Controls

Im `RiftTestController`:
- **R** - Neuen Rift starten
- **T** - Tutorial-Rift (90s)
- **S** - Standard-Rift (180s)
- **ESC** - Test beenden

Debug-Cheats:
- **F1** - +10s Zeit
- **F2** - +20-30 Punkte
- **F3** - +1 Schildmacht

## 🔧 Prefab-Erstellung

### Card UI Prefab
1. Erstelle ein UI-Panel (200x300)
2. Füge folgende Komponenten hinzu:
   - Image (Background)
   - Image (Card Art)
   - TextMeshPro (Name)
   - TextMeshPro (Cost)
   - TextMeshPro (Description)
   - CanvasGroup
   - CardUI Script

### Enemy Prefabs
1. Erstelle GameObject mit Sprite
2. Füge RiftEnemy-Komponente hinzu (oder Unterklasse)
3. Konfiguriere Stats:
   - Tutorial: 6 HP, 0.5s Zeitdiebstahl
   - Standard: 10-15 HP, 1s Zeitdiebstahl
   - Boss: 60 HP, 1.5s Zeitdiebstahl

## 📝 Nächste Schritte

### Priorität 1: UI-Verbesserungen
- [ ] Visuelle Karten-Assets
- [ ] Animations-System für Karten
- [ ] Floating Combat Text
- [ ] Boss-HP-Leiste

### Priorität 2: Gameplay-Features
- [ ] Weitere Zeitwächter-Karten
- [ ] DoT-System mit Zeitgewinn
- [ ] Elementar-Evolutionen
- [ ] Phasenwechsel-Visualisierung

### Priorität 3: Content
- [ ] Weitere Gegner-Typen
- [ ] Welt 1 Gegner
- [ ] Rudel-System
- [ ] Material-Drops

### Priorität 4: Polish
- [ ] Sound-Effekte
- [ ] Partikel-Effekte
- [ ] Screen-Shake
- [ ] Tutorial-Overlays

## ⚠️ Bekannte Limitierungen

1. **Keine visuellen Assets** - Nur Placeholder
2. **Basis-UI** - Funktional aber nicht polished
3. **Keine Speicherung** - Alles nur zur Laufzeit
4. **Keine Audio-Integration** - AudioManager-Calls sind vorbereitet
5. **Kein echtes Targeting** - Automatisches Ziel-System

## 🐛 Debugging

### Häufige Probleme

**"Zeit läuft nicht"**
- Prüfe ob `RiftCombatManager.StartRift()` aufgerufen wurde
- Stelle sicher dass `RiftTimeSystem` existiert

**"Keine Gegner spawnen"**
- `RiftEnemySpawner` benötigt Prefabs
- Spawn-Point muss gesetzt sein

**"Karten werden nicht angezeigt"**
- `HandController` benötigt Card UI Prefab
- `ZeitwaechterPlayer` muss initialisiert sein

### Debug-Anzeige
Der `RiftTestController` zeigt alle wichtigen Werte:
- Aktuelle Zeit und Rift-Status
- Punkte und Boss-Status
- Schildmacht und Kartenhand
- Aktive Gegner

## 💡 Entwickler-Tipps

1. **Zeit-Präzision**: Intern 0.01s, UI zeigt 0.5s-Schritte
2. **Opportunity Costs**: Keine harten Caps, Balance durch Kosten
3. **Mobile-First**: Alle Werte für Touch-Steuerung optimiert
4. **Event-Driven**: Nutze Events für lose Kopplung

## 📚 Dokumentations-Referenz

- `/docs/Core/ZK-GAME-OVERVIEW.md` - Gesamt-Konzept
- `/docs/Core/ZK-MECHANIKEN.md` - Detaillierte Mechaniken
- `/docs/Core/Klassen/ZK-ZEITWAECHTER.md` - Zeitwächter-Details
- `/docs/Core/Gameplay/ZK-KAMPFABLAUF.md` - Kampf-Ablauf

---

**Version**: 0.1.0 (Gameplay Loop Prototype)  
**Unity Version**: 2021.3+ empfohlen  
**Letzte Aktualisierung**: [DATUM]
