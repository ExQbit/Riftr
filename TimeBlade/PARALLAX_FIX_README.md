# Parallax Symmetrie Fix für HandController

## Problem
Das aktuelle Parallax-System ist asymmetrisch. Wenn der Spieler rechts startet und nach links gleitet, ist der Abstand zur Mitte größer als umgekehrt. Das liegt daran, dass das System die Bewegungen akkumuliert (delta-basiert) anstatt absolut von der Startposition zu rechnen.

## Lösung
Wechsel von einem delta-basierten zu einem absoluten Parallax-System, das auf der initialen Touch-Position basiert.

## Implementierung

### 1. Variable hinzufügen (bereits erledigt)
In HandController.cs wurde bereits hinzugefügt:
```csharp
private Vector2 startTouchPosition = Vector2.zero; // Store initial touch position for absolute parallax
```

### 2. StartPosition speichern (bereits erledigt)
In HandleTouchStart wurde bereits hinzugefügt:
```csharp
startTouchPosition = position; // Store for absolute parallax
```

### 3. UpdateParallaxHandShift Methode ersetzen
Die Methode UpdateParallaxHandShift muss komplett ersetzt werden. Die neue Implementierung ist in `HandController_ParallaxFix.cs`.

**Alte Implementierung (delta-basiert):**
```csharp
float horizontalDelta = currentPosition.x - lastFingerPosition.x;
float parallaxDelta = -horizontalDelta * parallaxSensitivity;
float targetHandOffset = currentHandOffset + parallaxDelta; // AKKUMULATION!
```

**Neue Implementierung (absolut):**
```csharp
float totalMovement = currentPosition.x - startTouchPosition.x;
float targetHandOffset = -totalMovement * parallaxSensitivity; // ABSOLUT!
```

## Vorteile der neuen Lösung
1. **Symmetrisch**: Gleiche Distanz zur Mitte, egal ob von links oder rechts gestartet
2. **Vorhersagbar**: Hand-Position basiert direkt auf Gesamtbewegung vom Start
3. **Pokemon Pocket-Style**: Finger in Mitte = Hand in Mitte

## Test
1. Touch auf rechte Karte starten
2. Nach links zur linken Karte gleiten
3. Abstand der Hand zur Bildschirmmitte messen
4. Umgekehrt testen (links starten, nach rechts gleiten)
5. Abstände sollten identisch sein

## Debug-Logs
Die neue Implementierung loggt:
```
[HandController] ABSOLUTE PARALLAX: finger=(x, y), totalMovement=X, targetHandOffset=Y
```

Anstatt:
```
[HandController] SMOOTH PARALLAX: finger=(x, y), delta=X, parallaxDelta=Y, targetHandOffset=Z
```
