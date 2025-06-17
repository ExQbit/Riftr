# Card-Aware Parallax System Implementation

## Zusammenfassung

Das neue card-aware Parallax System berücksichtigt, welche Karte initial berührt wurde, und begrenzt die Handbewegung entsprechend. Das löst das Problem, dass man die Hand über die Grenzen hinaus bewegen konnte, wenn man bereits auf eine Randkarte geklickt hatte.

## Kernkonzept

1. **Initial Touch Detection**: Beim Touch-Start wird erkannt, welche Karte berührt wurde (links, mitte, rechts)
2. **Smart Limits**: Die Bewegungsgrenzen werden basierend auf der Kartenposition berechnet
3. **Directional Constraints**: Die Hand kann nur in die "erlaubte" Richtung bewegt werden

## Technische Details

### Neue Variablen
```csharp
private float initialCardNormalizedPosition = 0.5f; // 0=left, 1=right
private float initialHandOffsetForCard = 0f; // Initial offset based on touched card
private float maxAllowedLeftMovement = 0f; // How much hand can move left
private float maxAllowedRightMovement = 0f; // How much hand can move right
```

### Verhalten

- **Rechte Karte berührt**: Hand startet am linken Maximum → kann nur nach rechts
- **Linke Karte berührt**: Hand startet am rechten Maximum → kann nur nach links
- **Mittlere Karte**: Symmetrische Bewegung in beide Richtungen möglich

### Formeln

```csharp
// Normalisierte Position (0 = ganz links, 1 = ganz rechts)
normalizedPos = cardIndex / (cardCount - 1)

// Initialer Offset (invertiert: rechte Karte = Hand links)
initialOffset = Lerp(+250, -250, normalizedPos)

// Erlaubte Bewegung
if (fingerMovement > 0) // Finger nach rechts
    allowed = Min(fingerMovement, maxAllowedLeft)
else // Finger nach links
    allowed = Max(fingerMovement, -maxAllowedRight)
```

## Testing

1. Touch auf rechte Karte → Nach rechts ziehen sollte KEINE weitere Bewegung zeigen
2. Touch auf linke Karte → Nach links ziehen sollte KEINE weitere Bewegung zeigen
3. Touch auf mittlere Karte → Bewegung in beide Richtungen möglich
4. Die Symmetrie sollte perfekt sein (gleicher Ausschlag für linke/rechte Karte)

## Debug-Output

Mit `logParallaxDetails = true` siehst du:

```
CARD-AWARE PARALLAX INIT: Card 4/4 (norm=1.00), initial offset=-250.0, allowed movement: left=500.0, right=0.0
CARD-AWARE PARALLAX: finger=(820.9), movement=-48.1, allowed=-0.0, offset=-250.0 (from initial -250.0)
```

Dies zeigt, dass die rechte Karte (4/4) berührt wurde, die Hand am linken Maximum (-250) startet und keine Bewegung nach rechts (right=0.0) erlaubt ist.
