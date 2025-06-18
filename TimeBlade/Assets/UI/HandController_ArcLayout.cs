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
        
        // Debug für Fanning (deaktiviert für Performance)
        // if (isFromCardCreation || forceImmediate)
        // {
        //     Debug.Log($"[ARC LAYOUT] Cards: {cardCount}, isFanned: {isFanned}, totalAngle: {totalArcAngle}°, parallaxOffset: {effectiveParallaxOffset:F1}");
        // }
        
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
                
                // Debug für alle Karten bei großem Offset (deaktiviert für Performance)
                // if (Mathf.Abs(effectiveParallaxOffset) > 10f)
                // {
                //     Debug.Log($"[ARC] Card {i}: virtualIndex={virtualIndex:F2}, shift={indexShift:F2}, offset={effectiveParallaxOffset:F1}");
                // }
            }
            
            // Berechne BEIDE Winkel - real für Layout, virtual für Parallax-Position
            float realAngle = startAngle + (i * angleStep); // Echter Index ohne Parallax
            float virtualAngle = startAngle + (virtualIndex * angleStep); // Mit Parallax-Verschiebung
            
            // WICHTIG: Für echte Kreisbahn-Bewegung beim Parallax:
            // Die Karten müssen sich AUF DEM KREISBOGEN bewegen, nicht linear!
            float angleInRadians = virtualAngle * Mathf.Deg2Rad;
            
            // KREISBOGEN-POSITION mit Parallax
            // Der Kreis liegt unterhalb bei (0, -circleRadius)
            // Karten bewegen sich auf diesem Kreisbogen
            float x = Mathf.Cos(angleInRadians) * circleRadius;
            float y = Mathf.Sin(angleInRadians) * circleRadius - circleRadius + arcYOffset;
            
            // PERSPEKTIVE: Karten in der Mitte sind etwas höher (näher)
            // Dies verstärkt den 3D-Effekt des Kreisbogens
            float distanceFromCenter = Mathf.Abs(virtualIndex - (cardCount - 1) * 0.5f);
            float perspectiveY = (1f - (distanceFromCenter / (cardCount * 0.5f))) * 10f; // Max 10 Pixel höher in der Mitte
            y += perspectiveY;
            
            // RADIALE ROTATION - Karten zeigen IMMER zum Kreismittelpunkt
            // Die Rotation folgt der POSITION auf dem Kreisbogen
            float targetRotation = virtualAngle - 90f; // Rotation passt sich der Kreisposition an
            
            Vector3 targetPosition = new Vector3(x, y, 0);
            // KEIN Hover-Offset mehr - nur Scale für stabiles Hover!
            
            // Debug-Ausgabe für Kreisbahn-Visualisierung
            if (logCardPositions && (i == 0 || i == cardCount - 1 || Mathf.Abs(effectiveParallaxOffset) > 50f))
            {
                Debug.Log($"[ARC LAYOUT] Card {i}: realAngle={realAngle:F1}°, virtualAngle={virtualAngle:F1}°, rotation={targetRotation:F1}°, pos=({x:F0}, {y:F0}), parallax={effectiveParallaxOffset:F0}");
                
                // Zeige Kreismittelpunkt für Debug
                if (i == 0)
                {
                    Vector3 circleCenter = new Vector3(0, -circleRadius + arcYOffset, 0);
                    Debug.Log($"[CIRCLE CENTER] Position: {circleCenter}, Radius: {circleRadius}");
                }
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
                // DEBUG: Verifikation der Original-Rotation
                if (logCardPositions && (i == 0 || i == cardCount - 1))
                {
                    Debug.Log($"[ORIGINAL ROTATION] Card {i}: setting originalRotation to {targetRotation:F1}° (realAngle={realAngle:F1}°)");
                }
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
                        cardRect.localRotation = Quaternion.Euler(0, 0, targetRotation);
                        cardUI.UpdateLayoutTargetPosition(targetPosition, targetRotation, true);
                        
                        // DEBUG: Überprüfe ob Rotation korrekt gesetzt wurde
                        // ERWEITERTE DEBUG-AUSGABE für Rotation
                        if (isFanned && Mathf.Abs(effectiveParallaxOffset) > 50f) // Niedrigerer Threshold
                        {
                        float actualRotation = cardRect.localRotation.eulerAngles.z;
                            float rotationDiff = Mathf.Abs(targetRotation - actualRotation);
                        if (rotationDiff > 1f) // Warnung bei Abweichung
                        {
                            Debug.LogWarning($"[ROTATION MISMATCH] Card {i}: target={targetRotation:F1}°, actual={actualRotation:F1}°, diff={rotationDiff:F1}°, realAngle={realAngle:F1}°, virtualAngle={virtualAngle:F1}°");
                        }
                        else if (i == 0 || i == cardCount - 1)
                        {
                            Debug.Log($"[ROTATION OK] Card {i}: rotation={actualRotation:F1}° (target={targetRotation:F1}°), realAngle={realAngle:F1}°");
                        }
                    }
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
                    cardUI.UpdateLayoutTargetPosition(targetPosition, targetRotation, duration, false);
                }
                
                // Position Animation
                LeanTween.moveLocal(card, targetPosition, duration).setEase(easing)
                    .setOnComplete(() => {
                        if (cardUI != null)
                        {
                            cardUI.SetInLayoutAnimation(false);
                        }
                    });
                
                // Rotation Animation
                LeanTween.rotateLocal(card, targetRotationVector, duration).setEase(easing);
                
                // DEBUG: Verifiziere animierte Rotation
                if (logCardPositions && isFanned && (i == 0 || i == cardCount - 1))
                {
                    Debug.Log($"[ANIM ROTATION] Card {i}: animating to rotation {targetRotation:F1}° (realAngle={realAngle:F1}°)");
                }
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
