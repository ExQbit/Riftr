# Anchored Card Update Fix - Symmetrische Hand-Bewegung

## Problem Analysis
**Issue**: Asymmetrische Hand-Bewegung beim Gleiten von rechts nach links

### Symptome aus Log125.md:
- `Anchored card: 4` bleibt konstant während der gesamten Bewegung
- `Hand offset` erreicht Maximum (176.3) und "klebt" dort
- Bewegung von rechts nach links führt zu unterschiedlichen End-Positionen

### Root Cause:
Die `anchoredCardIndex` wurde nur beim Touch-Start gesetzt, aber **nie aktualisiert** wenn sich die gehöverte Karte während der Bewegung änderte.

**Ablauf des Problems**:
1. Benutzer berührt rechteste Karte (Index 4) → `anchoredCardIndex = 4`
2. Finger gleitet nach links über andere Karten → `hoveredCard` ändert sich
3. **Problem**: `anchoredCardIndex` bleibt bei 4, obwohl Finger jetzt über Karte 0-3 ist
4. Parallax-System versucht weiterhin Karte 4 unter dem Finger zu halten → Asymmetrie

## Solution Implemented
**File**: `/Assets/UI/HandController.cs` - `UpdateCardSelectionAtPosition()` Methode

### Neue Logik:
```csharp
// CRITICAL FIX: Update anchored card index when hovered card changes
// This ensures parallax movement follows the finger correctly
if (hoveredCard != null && isParallaxActive)
{
    int newAnchoredIndex = activeCardUIs.IndexOf(hoveredCard.gameObject);
    if (newAnchoredIndex != anchoredCardIndex && newAnchoredIndex >= 0)
    {
        int oldIndex = anchoredCardIndex;
        anchoredCardIndex = newAnchoredIndex;
        Debug.Log($"[HandController] *** ANCHOR UPDATED *** Changed anchored card from index {oldIndex} to {newAnchoredIndex} ('{hoveredCard.GetCardData()?.cardName}')");
        
        // Reset touch offset when anchor changes to prevent jumping
        if (hoveredCard != null)
        {
            RectTransform cardRect = hoveredCard.gameObject.GetComponent<RectTransform>();
            Vector2 currentCardScreenPos = RectTransformUtility.WorldToScreenPoint(canvasCamera, cardRect.position);
            touchOffsetFromAnchorCard = screenPosition - currentCardScreenPos;
        }
    }
}
```

### Key Improvements:
1. **Dynamic Anchor Update**: `anchoredCardIndex` wird aktualisiert wenn `hoveredCard` wechselt
2. **Offset Reset**: `touchOffsetFromAnchorCard` wird neu berechnet um Sprünge zu vermeiden
3. **Debug Logging**: Neue Logs für Anchor-Änderungen (`*** ANCHOR UPDATED ***`)

## Expected Behavior Changes

### Before Fix:
- Gleiten von rechts nach links: Anchored card bleibt bei 4
- Hand bewegt sich asymmetrisch wegen falscher Anker-Referenz
- End-Position unterscheidet sich je nach Start-Richtung

### After Fix:
- Anchored card folgt dem Finger: 4 → 3 → 2 → 1 → 0
- Symmetrische Bewegung da korrekter Anker verwendet wird
- Gleiche End-Position unabhängig von Start-Richtung

## Testing Instructions
1. **Teste rechts → links**: Berühre rechteste Karte, gleite nach links
2. **Teste links → rechts**: Berühre linkeste Karte, gleite nach rechts
3. **Erwartung**: Beide Bewegungen sollten gleiche maximale Distanz erreichen
4. **Debug Logs**: Achte auf `*** ANCHOR UPDATED ***` Messages im Console

## Related Fixes
- **Compilation Error**: Variable scope fix in `UpdateParallaxHandShift()`
- **Dynamic Bounds**: Symmetrische Grenzen-Berechnung basierend auf Hand-Breite
- **Edge Damping**: Weiche Bewegung an den Grenzen

Diese Änderung sollte das asymmetrische Hand-Bewegungs-Problem vollständig lösen.