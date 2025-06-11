# Drag-and-Drop System für Feinde - Implementation

## Problem
- Spieler können Angriffskarten (requiresTarget=1) wie "Schwertschlag" spielen
- Das Targeting-System aktiviert sich, aber es gibt keine Möglichkeit Feinde auszuwählen
- Gewünschtes Verhalten: Karte direkt auf Gegner ziehen und ablegen

## Lösung Implementiert

### 1. HandController.cs Erweitert
- `EndDragOperation()` prüft jetzt auf Gegner unter Drag-Position
- `GetEnemyUnderDragPosition()` verwendet Raycast um Gegner zu finden
- `PlayDraggedCardOnTarget()` spielt Karte direkt mit Ziel

### 2. RiftCombatManager.cs Erweitert  
- `ExecuteCardEffectDirect()` umgeht das Targeting-System
- Direkte Kartenausführung mit vordefiniertem Ziel

### 3. Erforderliche Gegner-Konfiguration
Gegner benötigen:
- **Collider2D oder Collider3D** für Raycast-Detection
- **RiftEnemy Component** (bereits vorhanden)
- Korrekte **Layer-Konfiguration**

## Test-Schritte

1. **Überprüfe Gegner-Collider:**
   ```cs
   // In TutorialEnemy Prefab sollte sein:
   - BoxCollider2D oder CircleCollider2D
   - isTrigger = false (für Raycast)
   ```

2. **Test Drag-and-Drop:**
   - Spiele eine Schwertschlag Karte
   - Ziehe sie auf einen Gegner
   - Erwartung: "DRAG-AND-DROP CARD PLAY" Log-Message
   - Erwartung: Gegner nimmt Schaden

3. **Debug-Logs überwachen:**
   ```
   [HandController] Found enemy under drag position: EnemyName
   [HandController] *** DRAG-AND-DROP CARD PLAY *** Playing: Schwertschlag on EnemyName
   [RiftCombat] ExecuteCardEffectDirect: Schwertschlag on EnemyName
   [RiftEnemy] EnemyName nimmt 3 Schaden. HP: X/Y
   ```

## Fallback-Verhalten
- Wenn kein Gegner unter der Drag-Position: normale Spielzonen-Logik
- Wenn Karte nicht requiresTarget: normale Spielweise
- Zeit wird korrekt verwaltet (Rückerstattung bei Fehlern)

## Nächste Schritte
1. Teste mit aktueller Implementation
2. Falls Raycast fehlschlägt: Gegner-Collider überprüfen
3. Falls erfolgreich: Visuelles Feedback beim Drag over Enemy hinzufügen