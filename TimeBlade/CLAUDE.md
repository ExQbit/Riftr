# TimeBlade / Zeitklingen - Unity Projekt Memory

## 🎮 Projektübersicht
**TimeBlade** (deutsch: Zeitklingen) ist ein Unity-basiertes Kartenspiel mit Zeit als primäre Ressource. Spieler haben keine HP, sondern nur Zeit. Wenn die Zeit abläuft, ist das Spiel verloren.

**Unity Version**: Unity 6 (6000.0.38f1)  
**Plattform**: iOS / Mobile  
**Aktuelle Scene**: TestBattle.unity  
**Letzte Aktualisierung**: 2025-06-11

## <� Projektstruktur

### Core-Systeme (`Assets/_Core/`)
- **GameManager**: Globaler Spielzustand-Manager (Singleton)
- **RiftCombatManager**: Verwaltet echtzeitbasierte K�mpfe
- **RiftTimeSystem**: Zeit-als-Ressource-System
- **RiftPointSystem**: Punktesystem f�r Boss-Spawning
- **ZeitwaechterPlayer**: Spieler-Controller ohne HP-System

### UI-Komponenten (`Assets/UI/`)
- **HandController**: Zentralisiertes Drag&Drop-System f�r Handkarten
- **CardUI**: Einzelne Karten-UI ohne eigenes Drag-System
- **RiftUIController**: Zeigt Zeit, Punkte und Schildmacht
- **ActionTimelineDisplay**: Vertikale Timeline f�r Gegneraktionen

### Karten-System (`Assets/Cards/`)
- **TimeCardData**: ScriptableObject f�r Kartendaten
- **CardManager**: Verwaltet Deck, Hand und Ablagestapel
- **ZeitwaechterCardFactory**: Erstellt Starter-Decks

## <� Handkarten-System Architektur

### Zentralisiertes Drag-System
**Problem**: Unity's Drag-Events gehen immer an die Start-Karte, nicht an die Karte unter dem Finger.

**L�sung**: HandController �bernimmt das komplette Touch-Tracking:
1. Touch im HandContainer aktiviert Fanning
2. Kontinuierliche Finger-Position-Verfolgung
3. Dynamische Kartenauswahl basierend auf aktueller Position
4. Drag startet nach 80px Bewegung oder 25px Aufw�rtsbewegung

### Wichtige Eigenschaften:
- **Fan-Animation**: 0.15s mit easeOutExpo
- **Layout-Animation**: 0.2s mit easeOutCubic
- **Touch-Area**: +50px erweiterte Erkennung
- **Hover**: Nur bei Desktop-Mouse, nicht bei Touch

### Event-Flow beim Kartenspielen:
1. `PlayerWantsToPlayCard()` � Zeit-Check
2. `ExecuteCardEffect()` � Effekt ausf�hren
3. `PlayCardFromCombat()` � Karte entfernen
4. `OnHandChanged` � UI Update
5. `DrawCard()` � Neue Karte ziehen

## = Bekannte Probleme & Fixes

### Skalierungsprobleme
- Canvas mit Scale (0,0,0) bricht alle Positionierungen
- L�sung: Force Scale auf (1,1,1) in HandController

### SiblingIndex-Probleme
- Hover setzt Karte nach vorne mit `SetAsLastSibling()`
- Beim Hover-Ende muss originalSiblingIndex wiederhergestellt werden
- Fallback: `EnsureCorrectSiblingOrder()` nach Layout

### Touch-Koordinaten
- Verschiedene Canvas-RenderModes brauchen unterschiedliche Kameras
- ScreenSpaceOverlay: keine Kamera
- ScreenSpaceCamera: Canvas.worldCamera verwenden

### Timer-Display-Probleme (BEHOBEN 2025-06-11)
- **Problem**: Timer lief laggy und sprunghaft, manchmal gar nicht
- **Ursache**: Dual-Timer-System - UIManager nutzte alten TimeManager (Update() jeden Frame), RiftUIController nutzte neuen RiftTimeSystem
- **Lösung**: UIManager auf RiftTimeSystem umgestellt, alte TimeManager-Events entfernt
- **Resultat**: Einheitliche 0.1s UI-Update-Intervalle statt Frame-by-Frame Updates

## <� Gameplay-Mechaniken

### Zeit-System
- Spieler starten mit ~90s Zeit
- Karten kosten Zeit zum Spielen (0.5s - 3s)
- Gegner k�nnen Zeit stehlen
- Block-Karten k�nnen Zeit zur�ckgewinnen

### Schildmacht (Zeitw�chter-Spezial)
- 0-5 Schildmacht-Punkte
- Bei 3+ SM: +1 Bonus-Schaden
- Bei 5 SM: Immunit�t gegen n�chsten Zeitdiebstahl
- Erfolgreiche Blocks erh�hen SM

### Rift-System
- Gegner spawnen kontinuierlich
- Punkte f�r besiegte Gegner
- Bei 100 Punkten: Boss spawnt
- Boss besiegt = Sieg, Zeit abgelaufen = Niederlage

## =� Wichtige Dateien f�r Handkarten
- `/Assets/UI/HandController.cs` - Zentrale Hand-Verwaltung
- `/Assets/UI/CardUI.cs` - Karten-UI-Komponente
- `/HANDKARTEN_SYSTEM_FUNKTIONALE_SPEZIFIKATION.md` - Detaillierte Spezifikation
- `/DRAG_SYSTEM_DOCUMENTATION.md` - Drag&Drop Dokumentation

## =' Debug-Commands
```csharp
// Force Hand-Update
HandController.Instance.UpdateHandDisplay();

// Check Canvas Scale
Debug.Log($"Canvas Scale: {canvas.transform.localScale}");

// Monitor SiblingIndex
StartCoroutine(MonitorCard3SiblingIndex(card));
```

## 💡 Entwicklungs-Tipps
1. Immer NULL-Checks für HandController-Referenzen
2. Canvas-Scales prüfen bei Positionierungs-Problemen
3. SiblingIndex nach Hover-Animationen kontrollieren
4. Touch-Events über `CardUI.SetTouchStartedOnValidArea()` validieren
5. Log-Spam reduzieren durch Auskommentieren häufiger Debug-Logs

## 📊 Projekt-Status Highlights (aus PROJECT_STATUS.md)

### ✅ Kürzlich gelöste Probleme (2025-06-11):
- **Drag-and-Drop Kampfsystem**: Angriffskarten funktionieren jetzt korrekt
  - Auto-Targeting findet ersten verfügbaren Gegner
  - Schaden wird korrekt angewendet
  - Karten werden nach dem Spielen automatisch nachgezogen
- **Schadenssystem geklärt**: Karten nutzen ZeitwaechterCardFactory-Werte (5 Schaden)

### ✅ Weitere gelöste Probleme:
- **Card Scaling Bug**: Karten blieben bei 1.15x hängen - gelöst mit Tween ID Tracking
- **Zentrales Drag-System**: Unity Event-Problem gelöst - HandController verwaltet jetzt alles
- **Timer-Anzeige**: Zeigt konsistent nur Sekunden (90s statt 1:30)
- **HP-Gesamtanzeige**: Queue-Logik vereinfacht, alle Gegner werden korrekt gezählt

### 🔄 Aktuelle Implementierungen:
- **Gegner-Aktionssystem**: EnemyActionType mit TimeSteal, DoubleStrike, etc.
- **ActionTimelineDisplay**: Zeigt kommende Gegneraktionen in vertikaler Timeline
- **Phasensystem**: +15% Schaden nach Verteidigung, +1s Zeit nach Angriff

### 📝 Nächste Schritte:
- Enemy_Card.prefab mit ActionPanel erweitern
- HorizontalLayoutGroup vom HandContainer entfernen (für korrektes Fächer-Layout)
- Gegner-Spawn-System mit ausgewogenen Raten finalisieren
- Material-Drop-System implementieren