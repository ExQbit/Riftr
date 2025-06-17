using UnityEngine;
using System.Collections;

/// <summary>
/// Neue Arc-basierte Layout-Logik für das Handkarten-System
/// </summary>
public partial class HandController : MonoBehaviour
{
    /// <summary>
    /// Neue UpdateCardLayout Methode mit Arc-Movement
    /// </summary>
    public void UpdateCardLayoutArc(bool forceImmediate = false, bool isFromCardCreation = false, CardUI anchorCard = null)
    {
        int cardCount = activeCardUIs.Count;
        if (cardCount == 0) return;
        
        // CRITICAL FIX: Verhindere Layout-Updates während aktiver Hover-Animationen
        // Dies verhindert Lücken bei schnellen Hover-Wechseln
        if (!forceImmediate && !isFromCardCreation)
        {
            foreach (var cardObj in activeCardUIs)
            {
                if (cardObj != null)
                {
                    var cardUI = cardObj.GetComponent<CardUI>();
                    if (cardUI != null && cardUI.IsInHoverAnimation())
                    {
                        // Skip layout update - Hover animation is running
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
                    // Only reset non-hovered cards
                    if (!cardUI.IsHovering() && cardUI != draggedCardUI)
                    {
                        cardUI.ForceDisableHover();
                        cardObj.transform.localScale = Vector3.one;
                    }
                    
                    // Set layout animation flag for all cards
                    // This prevents hover animations from interfering during layout updates
                    cardUI.SetInLayoutAnimation(true);
                }
            }
        }
        
        // Berechne Parallax-Offset für Arc-Movement
        float effectiveParallaxOffset = isFanned ? currentHandOffset : 0f;
        
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
            
            // NEU: Berechne Position auf dem Bogen
            Vector3 targetPosition;
            float targetRotation;
            
            // EINHEITLICHER BOGEN für beide Zustände
            float normalizedPos = cardCount > 1 ? (float)i / (cardCount - 1) : 0.5f;
            
            // Horizontale Position - nur der Abstand ändert sich beim Fächern
            float spacing = isFanned ? fanSpacing : cardSpacing;
            float centerIndex = (cardCount - 1) * 0.5f;
            float x = (i - centerIndex) * spacing;
            
            // Füge Parallax-Offset hinzu wenn gefächert
            if (isFanned)
            {
                x += effectiveParallaxOffset;
            }
            
            // WICHTIG: Y-Position muss basierend auf der FINALEN X-Position berechnet werden!
            // So folgen die Karten dem Bogen auch beim Parallax-Movement
            
            // Erweitere den Bereich für den Bogen, damit er natürlicher aussieht
            // Verwende unterschiedliche Spans für gefächert und normal
            float spanMultiplier = isFanned ? 0.8f : 0.6f; // Kleinerer Bereich wenn nicht gefächert
            float arcSpan = (cardCount - 1) * spacing * spanMultiplier;
            float normalizedX = arcSpan > 0 ? x / arcSpan : 0f;
            
            // Vertikale Position - verwende eine sanftere Kurve
            float arcHeight = isFanned ? 35f : 30f; // Etwas höher wenn gefächert
            
            // PARABEL: Verwende normalizedX direkt für konsistenten Bogen
            // Die Parabel sollte bei -1 und 1 am tiefsten Punkt sein
            float parabola = 1f - (normalizedX * normalizedX);
            
            // Clamp die Parabel auf 0 als Minimum
            parabola = Mathf.Max(0f, parabola);
            
            // Direkte Höhenberechnung
            float y = arcHeight * parabola;
            
            // Debug-Ausgabe für extreme Positionen
            if (Mathf.Abs(normalizedX) > 1.0f && logCardPositions)
            {
                Debug.Log($"[HandController] Card {i} at extreme position: x={x:F2}, normalizedX={normalizedX:F2}, y={y:F2}");
            }
            
            // Rotation folgt auch der X-Position für konsistente Bogen-Bewegung
            // Begrenze die Rotation auf den sichtbaren Bereich
            float rotationNormalized = Mathf.Clamp(normalizedX, -1f, 1f);
            float angleInDegrees = rotationNormalized * 20f; // Direkte Skalierung für intuitivere Rotation
            float rotation = -angleInDegrees * 0.7f;
            
            targetPosition = new Vector3(x, y, 0);
            targetRotation = rotation;
            
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
