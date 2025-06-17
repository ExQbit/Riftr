# Hover State Machine Dokumentation

## Übersicht

Das Hover-System in TimeBlade verwendet eine robuste State Machine, um Race Conditions und Animation-Konflikte zwischen verschiedenen Systemen zu vermeiden.

## Problem

Vorher konkurrierten mehrere Systeme um die Kontrolle der Kartenpositionen:
- **Hover-System**: Wollte Karten anheben und skalieren
- **Layout-System**: Wollte Karten an ihre Layout-Position bewegen
- **Parallax-System**: Wollte alle Karten horizontal verschieben
- **Drag-System**: Wollte einzelne Karten bewegen

Dies führte zu:
- Karten, die im Hover-Zustand "hängen" blieben
- Lücken im Layout bei schnellen Hover-Wechseln
- Ruckelnde Animationen
- Inkonsistente Z-Order (Überlappung)

## Lösung: State Machine

### States

```csharp
public enum HoverState
{
    None,           // Normalzustand
    EnteringHover,  // Animation zum Hover läuft
    Hovered,        // Vollständig im Hover-Zustand
    ExitingHover    // Animation zurück vom Hover läuft
}
```

### Position Tracking

Anstatt eine einzelne Position zu haben, trackt das System jetzt:

1. **layoutTargetPosition**: Wo die Karte laut Layout sein sollte
2. **visualPosition**: Aktuelle visuelle Position (kann animiert sein)
3. **hoverOffset**: Zusätzlicher Offset für den Hover-Effekt

### State Transitions

```
None → EnteringHover → Hovered
  ↑                        ↓
  ←─── ExitingHover ←──────┘
```

## Implementierung

### 1. Animation Management

Jede Animation hat eine eigene ID:
```csharp
private int positionAnimationId = -1;
private int scaleAnimationId = -1;
private int rotationAnimationId = -1;
```

Neue Animationen canceln alte sauber:
```csharp
private void CancelAllAnimations()
{
    if (positionAnimationId >= 0)
    {
        LeanTween.cancel(positionAnimationId);
        positionAnimationId = -1;
    }
    // ... etc
}
```

### 2. Layout Updates

Layout-Updates werden verzögert, wenn die Karte im Hover-Zustand ist:

```csharp
public void UpdateLayoutTargetPosition(Vector3 newPosition, float animationDuration, bool immediate)
{
    layoutTargetPosition = newPosition;
    
    if (currentHoverState == HoverState.Hovered || currentHoverState == HoverState.EnteringHover)
    {
        // Verzögere das Update
        pendingLayoutUpdate = StartCoroutine(DelayedLayoutUpdate(animationDuration));
    }
    else
    {
        // Führe das Update sofort aus
        AnimateToLayoutPosition(animationDuration);
    }
}
```

### 3. State-spezifisches Verhalten

#### EnteringHover
- Speichert aktuellen SiblingIndex
- Bringt Karte nach vorne (SetAsLastSibling)
- Berechnet Hover-Offset
- Startet Animations zu Hover-Position und -Scale

#### Hovered
- Karte ist vollständig im Hover-Zustand
- Layout-Updates werden verzögert
- Position = layoutTargetPosition + hoverOffset

#### ExitingHover
- Stellt Original-SiblingIndex wieder her
- Setzt Hover-Offset auf 0
- Animiert zurück zur Layout-Position

## Integration mit anderen Systemen

### HandController
```csharp
// Alte API (deprecated):
cardUI.UpdateBasePosition(targetPosition);

// Neue API:
cardUI.UpdateLayoutTargetPosition(targetPosition, duration, immediate);
```

### Parallax Movement
Das Parallax-System updated nur die layoutTargetPosition. Die CardUI State Machine kümmert sich darum, ob und wie diese Position angewendet wird.

### Drag & Drop
Während eines Drags werden alle Hover-States deaktiviert:
```csharp
cardUI.ForceDisableHover();
```

## Best Practices

1. **Niemals direkt transform.position setzen** - Immer über UpdateLayoutTargetPosition
2. **State Transitions nutzen** - Nicht direkt States setzen
3. **Animation IDs prüfen** - Vor dem Starten neuer Animationen alte canceln
4. **ForceDisableHover bei Bedarf** - Z.B. während Drag-Operationen

## Debugging

Aktiviere Debug-Logs in CardUI.cs:
```csharp
Debug.Log($"[CardUI] {cardData?.cardName} State: {oldState} → {newState}");
```

Dies zeigt alle State-Übergänge und hilft beim Debugging von Hover-Problemen.

## Performance

Die State Machine verhindert unnötige Updates:
- Keine redundanten Animationen
- Verzögerte Layout-Updates während Hover
- Effiziente State-Übergänge

## Zukünftige Erweiterungen

Das System kann einfach erweitert werden:
- Neue States hinzufügen (z.B. "Pressed", "Selected")
- Zusätzliche Animations-Typen
- Komplexere Übergänge zwischen States