using UnityEngine;
using System.Collections;

/// <summary>
/// Neue Arc-basierte Layout-Logik für das Handkarten-System
/// </summary>
public partial class HandController : MonoBehaviour
{
    /// <summary>
    /// Vereinfachte UpdateCardLayout Methode mit einfachem Kreisbogen
    /// </summary>
    public void UpdateCardLayoutArc(bool forceImmediate = false, bool isFromCardCreation = false, CardUI anchorCard = null)
    {
        int cardCount = activeCardUIs.Count;
        if (cardCount == 0) return;
        
        // CRITICAL FIX: Verhindere Layout-Updates während aktiver Hover-Animationen
        if (!forceImmediate && !isFromCardCreation)
        {
            foreach (var cardObj in activeCardUIs)
            {
                if (cardObj != null)
                {
                    var cardUI = cardObj.GetComponent<CardUI>();
                    if (cardUI != null && cardUI.IsInHoverAnimation())
                    {
                        return;
                    }
                }
            }
        }
        
        // Reset hover states für alle Karten außer der gehoverten
        foreach (var cardObj in activeCardUIs)
        {
            if (cardObj != null)
            {
                var cardUI = cardObj.GetComponent<CardUI>();
                if (cardUI != null)
                {
                    if (!cardUI.IsHovering() && cardUI != draggedCardUI)
                    {
                        cardUI.ForceDisableHover();
                        cardObj.transform.localScale = Vector3.one;
                    }
                    cardUI.SetInLayoutAnimation(true);
                }
            }
        }
        
        // Berechne Parallax-Offset für Arc-Movement
        float effectiveParallaxOffset = isFanned ? currentHandOffset : 0f;
        
        // EINFACHE KREISBOGEN-BERECHNUNG - verwendet Inspector-Werte
        float circleRadius = arcRadius;
        float totalArcAngle = isFanned ? arcAngleFanned : arcAngleNormal;
        float startAngle = 90f - (totalArcAngle / 2f); // Startwinkel (90° = oben, minus halber Bogen)
        
        // Debug für Fanning
        if (isFromCardCreation || forceImmediate)
        {
            Debug.Log($"[ARC LAYOUT] Cards: {cardCount}, isFanned: {isFanned}, totalAngle: {totalArcAngle}°, parallaxOffset: {effectiveParallaxOffset:F1}");
        }
        
        // Layout jede Karte
        for (int i = 0; i < cardCount; i++)
        {
            GameObject card = activeCardUIs[i];
            
            if (card == null)
            {
                Debug.LogError($"[HandController] Card at index {i} is NULL!");
                continue;
            }
            
            if (card == draggedCard)
            {
                Debug.Log($"[HandController] Skipping dragged card at index {i}");
                continue;
            }
            
            RectTransform cardRect = card.GetComponent<RectTransform>();
            CardUI cardUI = card.GetComponent<CardUI>();
            
            if (cardRect == null || cardUI == null) continue;
            
            // EINFACHE WINKELBERECHNUNG
            float angleStep = cardCount > 1 ? totalArcAngle / (cardCount - 1) : 0f;
            float currentAngle = startAngle + (i * angleStep); // Von links nach rechts
            
            // NEUER ANSATZ: Virtuelle Index-Position für Perlen-auf-Kette-Effekt
            float virtualIndex = i;
            if (isFanned && Mathf.Abs(effectiveParallaxOffset) > 0.1f)
            {
                float cardWidth = parallaxCardWidth;
                float indexShift = effectiveParallaxOffset / cardWidth;
                virtualIndex = i - indexShift; // Negative shift = Karten nach rechts
                
                // Debug für alle Karten bei großem Offset
                if (Mathf.Abs(effectiveParallaxOffset) > 10f)
                {
                    Debug.Log($"[ARC] Card {i}: virtualIndex={virtualIndex:F2}, shift={indexShift:F2}, offset={effectiveParallaxOffset:F1}");
                }
            }
            
            // Berechne Winkel basierend auf virtueller Position
            float virtualAngle = startAngle + (virtualIndex * angleStep);
            float angleInRadians = virtualAngle * Mathf.Deg2Rad;
            
            // EINFACHE KREIS-POSITION
            // Der Kreis liegt unterhalb bei (0, -circleRadius)
            // Wir wollen den oberen Teil des Kreises verwenden
            float x = Mathf.Cos(angleInRadians) * circleRadius;
            float y = Mathf.Sin(angleInRadians) * circleRadius - circleRadius + arcYOffset; // Y-Offset nach unten + Verschiebung nach oben
            
            // Karten-Rotation folgt der Tangente des Kreises
            float targetRotation = virtualAngle - 90f; // Tangente für oberen Kreisbogen
            
            Vector3 targetPosition = new Vector3(x, y, 0);
            
            // Debug-Ausgabe
            if (logCardPositions && (i == 0 || i == cardCount - 1))
            {
                Debug.Log($"[HandController] Card {i}: angle={currentAngle:F1}°, pos=({x:F0}, {y:F0})");
            }
            
            // CRITICAL FIX: Setze Sibling Index nur für nicht-gehoverte Karten
            // Gehoverte Karten behalten ihren hohen SiblingIndex bei
            if (cardUI == null || !cardUI.IsHovering())
            {
            card.transform.SetSiblingIndex(i);
            }
            // Debug-Log entfernt - zu viel Spam
            
            // Speichere Original-Rotation
            if (cardUI != null)
            {
                cardUI.SetOriginalRotation(targetRotation);
            }
            
            Vector3 targetRotationVector = new Vector3(0, 0, targetRotation);
            
            // Sofortige oder animierte Positionierung
            if (forceImmediate || draggedCard != null)
            {
                // CRITICAL: Während Parallax-Movement hovering Karten NICHT updaten
                if (cardUI != null)
                {
                    if (cardUI.IsHovering() || cardUI.IsInHoverAnimation())
                    {
                        // Hovering Karten: Update die Position mit Bogen-Bewegung
                        cardUI.UpdateParallaxPositionWithArc(targetPosition, 0.05f);
                        continue;
                    }
                    else
                    {
                        // Nur nicht-hovering Karten updaten
                        cardRect.localPosition = targetPosition;
                        cardRect.localEulerAngles = targetRotationVector;
                        cardUI.UpdateLayoutTargetPosition(targetPosition, 0f, true);
                    }
                }
            }
            else
            {
                // Animierte Bewegung
                float duration = isFanned ? fanAnimationDuration : 0.2f;
                LeanTweenType easing = isFanned ? fanEaseType : LeanTweenType.easeOutCubic;
                
                // CRITICAL: Hovering Karten sanft mit bewegen
                if (cardUI != null && (cardUI.IsHovering() || cardUI.IsInHoverAnimation()))
                {
                    // Hovering Karten: Sanfte Bewegung mit Bogen-Anpassung
                    cardUI.UpdateParallaxPositionWithArc(targetPosition, duration * 0.5f); // Halbe Geschwindigkeit für smoothen Effekt
                    continue;
                }
                
                LeanTween.cancel(card);
                
                // Update layout target position nur für nicht-hovering Karten
                if (cardUI != null)
                {
                    cardUI.UpdateLayoutTargetPosition(targetPosition, duration, false);
                }
                
                // Position Animation
                LeanTween.moveLocal(card, targetPosition, duration).setEase(easing);
                
                // Rotation Animation
                LeanTween.rotateLocal(card, targetRotationVector, duration).setEase(easing)
                    .setOnComplete(() => {
                        if (cardUI != null)
                        {
                            cardUI.SetInLayoutAnimation(false);
                        }
                    });
            }
        }
        
        // Cleanup nach immediate update
        if (forceImmediate && !isFromCardCreation)
        {
            foreach (var cardObj in activeCardUIs)
            {
                if (cardObj != null)
                {
                    var cardUI = cardObj.GetComponent<CardUI>();
                    if (cardUI != null)
                    {
                        cardUI.SetInLayoutAnimation(false);
                    }
                }
            }
        }
        
        if (forceImmediate)
        {
            // Ensure base sibling order for non-hovered cards
            for (int i = 0; i < activeCardUIs.Count; i++)
            {
                GameObject cardObj = activeCardUIs[i];
                if (cardObj != null)
                {
                    var cardUI = cardObj.GetComponent<CardUI>();
                    // Only set sibling index for non-hovered cards
                    if (cardUI == null || !cardUI.IsHovering())
                    {
                        cardObj.transform.SetSiblingIndex(i);
                    }
                }
            }
            
            // CRITICAL FIX: Ensure hovered cards stay on top after layout update
            foreach (var cardObj in activeCardUIs)
            {
                if (cardObj != null)
                {
                    var cardUI = cardObj.GetComponent<CardUI>();
                    if (cardUI != null && cardUI.IsHovering())
                    {
                        // Re-apply SetAsLastSibling for hovered cards
                        cardObj.transform.SetAsLastSibling();
                        // Debug-Log entfernt - zu viel Spam
                    }
                }
            }
        }
    }
}
