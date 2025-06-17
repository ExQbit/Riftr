using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// TEIL 4/4: Hilfsmethoden und fehlende Implementierungen
/// </summary>
public partial class HandController : MonoBehaviour
{
    private void UpdateHandDisplay()
    {
        if (player == null)
        {
            LogError("UpdateHandDisplay - player is NULL!");
            return;
        }
        
        var hand = player.GetHand();
        LogWarning($"UpdateHandDisplay START - Player has {hand.Count} cards, existing UI: {activeCardUIs.Count}", logHandUpdates);
        
        if (hand.Count > activeCardUIs.Count && activeCardUIs.Count > 0)
        {
            bool existingCardsMatch = true;
            for (int i = 0; i < activeCardUIs.Count; i++)
            {
                if (activeCardUIs[i] == null)
                {
                    existingCardsMatch = false;
                    break;
                }
                var cardUI = activeCardUIs[i].GetComponent<CardUI>();
                if (cardUI == null || cardUI.GetCardData() != hand[i])
                {
                    existingCardsMatch = false;
                    break;
                }
            }
            
            if (existingCardsMatch)
            {
                LogInfo($"Adding {hand.Count - activeCardUIs.Count} new cards to existing hand", logHandUpdates);
                for (int i = activeCardUIs.Count; i < hand.Count; i++)
                {
                    CreateCardUI(hand[i]);
                }
                LogWarning($"UpdateHandDisplay END - Added new cards. Total: {activeCardUIs.Count}", logHandUpdates);
                return;
            }
        }
        
        if (hand.Count == activeCardUIs.Count)
        {
            bool handChanged = false;
            for (int i = 0; i < hand.Count; i++)
            {
                if (activeCardUIs[i] == null)
                {
                    handChanged = true;
                    break;
                }
                var cardUI = activeCardUIs[i].GetComponent<CardUI>();
                if (cardUI == null || cardUI.GetCardData() != hand[i])
                {
                    handChanged = true;
                    break;
                }
            }
            
            if (!handChanged)
            {
                LogInfo("Hand unchanged - skipping refresh", logHandUpdates);
                return;
            }
        }
        
        LogInfo($"Hand changed - performing full refresh (cards: {hand.Count} vs UI: {activeCardUIs.Count})", logHandUpdates);
        
        foreach (var cardUIGameObject in activeCardUIs)
        {
            if (cardUIGameObject != null)
            {
                LeanTween.cancel(cardUIGameObject);
            }
        }
        
        foreach (var cardUIGameObject in activeCardUIs)
        {
            if (cardUIGameObject != null)
            {
                LogInfo($"Destroying card UI: {cardUIGameObject.name}", logHandUpdates);
                Destroy(cardUIGameObject);
            }
        }
        activeCardUIs.Clear();
        hoveredCard = null;
        lastHoveredCard = null;
        draggedCard = null;
        isPlayingCard = false;
        
        LogInfo($"Creating UI for {hand.Count} cards from player hand", logHandUpdates);
        
        foreach (var card in hand)
        {
            CreateCardUI(card);
        }
        
        LogWarning($"UpdateHandDisplay END - Created {activeCardUIs.Count} card UIs", logHandUpdates);
        
        StartCoroutine(DebugCardPositions());
    }
    
    private void CreateCardUI(TimeCardData cardData)
    {
        if (cardUIPrefab == null)
        {
            Debug.LogError("[HandController] cardUIPrefab is NULL! Cannot create card UI.");
            return;
        }
        
        if (handContainer == null)
        {
            Debug.LogError("[HandController] handContainer is NULL! Cannot create card UI.");
            return;
        }
        
        GameObject cardUI = Instantiate(cardUIPrefab, handContainer);
        int targetSiblingIndex = activeCardUIs.Count;
        cardUI.transform.SetSiblingIndex(targetSiblingIndex);
        
        RectTransform cardRect = cardUI.GetComponent<RectTransform>();
        if (cardRect != null)
        {
            if (cardRect.pivot != Vector2.one * 0.5f)
            {
                Debug.LogWarning($"[HandController] Card has non-centered pivot: {cardRect.pivot}. Correcting to (0.5, 0.5)");
                cardRect.pivot = Vector2.one * 0.5f;
            }
            
            if (cardRect.anchorMin != Vector2.one * 0.5f || cardRect.anchorMax != Vector2.one * 0.5f)
            {
                Debug.LogWarning($"[HandController] Card has non-centered anchors. Correcting to (0.5, 0.5)");
                cardRect.anchorMin = Vector2.one * 0.5f;
                cardRect.anchorMax = Vector2.one * 0.5f;
            }
            
            cardRect.anchoredPosition = Vector2.zero;
            cardRect.localRotation = Quaternion.identity;
            cardRect.localScale = Vector3.one;
        }
        
        var cardUIComponent = cardUI.GetComponent<CardUI>();
        if (cardUIComponent != null)
        {
            cardUIComponent.InitializeCard(this, cardData, canvasCamera);
            cardUIComponent.OnCardClicked += HandleCardClick;
        }
        else
        {
            Debug.LogError($"[HandController] No CardUI component found on {cardUI.name}!");
        }
        
        activeCardUIs.Add(cardUI);
        
        if (cardUIComponent != null)
        {
            cardUIComponent.SetInLayoutAnimation(true);
        }
        
        UpdateCardLayout(true, true);
        
        if (cardUIComponent != null)
        {
            cardUIComponent.ForceDisableHover();
            cardUIComponent.SetInLayoutAnimation(false);
        }
        
        // Position-Check entfernt
        
        StartCoroutine(CheckCardScaleAfterCreation(cardUI, 0.1f));
        
        // Monitoring entfernt - nicht mehr benötigt
        
        // Creation-Check entfernt
    }
    
    private void HandleCardClick(TimeCardData cardData)
    {
        // Click sollte nur das Fanning beenden, nicht die Karte spielen!
        // Karten werden nur durch erfolgreiches Drag&Drop gespielt
        if (isFanned)
        {
            Debug.Log($"[HandController] Card '{cardData.cardName}' clicked while fanned - closing fan");
            isFanned = false;
            UpdateCardLayout(false);
        }
        else
        {
            Debug.Log($"[HandController] Card '{cardData.cardName}' clicked - ignored (cards are played via drag&drop only)");
        }
    }
    
    private System.Collections.IEnumerator DebugCardPositions()
    {
        yield return new WaitForSeconds(0.5f);
        
        LogInfo("=== CARD POSITIONS DEBUG ===", logCardPositions);
        for (int i = 0; i < activeCardUIs.Count; i++)
        {
            if (activeCardUIs[i] != null)
            {
                RectTransform rect = activeCardUIs[i].GetComponent<RectTransform>();
                LogInfo($"Card {i}: {activeCardUIs[i].name} - LocalPos: {rect.localPosition} - AnchoredPos: {rect.anchoredPosition} - WorldPos: {rect.position}", logCardPositions);
            }
        }
        LogInfo("=== END POSITIONS DEBUG ===", logCardPositions);
    }
    
    private System.Collections.IEnumerator CheckCardScaleAfterCreation(GameObject card, float delay)
    {
        int cardIndex = activeCardUIs.IndexOf(card);
        CardUI cardUI = card?.GetComponent<CardUI>();
        string originalCardName = cardUI?.GetCardData()?.cardName ?? "Unknown";
        
        yield return new WaitForSeconds(delay);
        
        if (card != null && card.transform.localScale != Vector3.one)
        {
            int siblingIndex = card.transform.GetSiblingIndex();
            Vector3 position = card.transform.localPosition;
            
            Debug.LogWarning($"[HandController] Card {cardIndex} '{originalCardName}' (SiblingIndex: {siblingIndex}, Position: {position}) has incorrect scale {delay}s after creation: {card.transform.localScale}. Fixing...");
            card.transform.localScale = Vector3.one;
        }
    }
    
    private System.Collections.IEnumerator ResetPlayingCardFlag()
    {
        yield return new WaitForSeconds(1.0f);
        isPlayingCard = false;
        Debug.Log($"[HandController] GUARD RESET - isPlayingCard flag cleared after 1 second");
    }
    
    private System.Collections.IEnumerator MonitorPlayingCardFlag()
    {
        while (true)
        {
            if (isPlayingCard)
            {
                Debug.LogWarning($"[HandController] *** MONITOR *** isPlayingCard is TRUE - touch updates are BLOCKED");
            }
            yield return new WaitForSeconds(1f);
        }
    }
    
    // ========== FEHLENDE METHODEN AUS MISSING_METHODS_FOR_HANDCONTROLLER.cs ==========
    
    private void InitializeCardAwareParallax(CardUI touchedCard)
    {
        // Feste Anschlagsgrenzen für die Hand
        const float MAX_HAND_OFFSET = 250f;
        
        if (touchedCard == null || activeCardUIs.Count == 0)
        {
            initialCardNormalizedPosition = 0.5f;
            initialHandOffsetForCard = 0f;
            maxAllowedLeftMovement = MAX_HAND_OFFSET;
            maxAllowedRightMovement = MAX_HAND_OFFSET;
            LogInfo("CARD-AWARE PARALLAX: No card touched, using symmetric limits", logParallaxDetails);
            return;
        }
        
        int touchedCardIndex = -1;
        for (int i = 0; i < activeCardUIs.Count; i++)
        {
            var cardUI = activeCardUIs[i].GetComponent<CardUI>();
            if (cardUI == touchedCard)
            {
                touchedCardIndex = i;
                break;
            }
        }
        
        if (touchedCardIndex == -1)
        {
            initialCardNormalizedPosition = 0.5f;
            initialHandOffsetForCard = 0f;
            maxAllowedLeftMovement = MAX_HAND_OFFSET;
            maxAllowedRightMovement = MAX_HAND_OFFSET;
            return;
        }
        
        int cardCount = activeCardUIs.Count;
        initialCardNormalizedPosition = cardCount > 1 ? (float)touchedCardIndex / (cardCount - 1) : 0.5f;
        
        // Die Hand startet IMMER bei ihrer aktuellen Position (normalerweise 0)
        // Aber die erlaubten Bewegungen hängen von der berührten Karte ab:
        // - Rechte Karte: Betrachte dies als maximalen Ausschlag, nur Bewegung nach links erlaubt
        // - Linke Karte: Betrachte dies als maximalen Ausschlag, nur Bewegung nach rechts erlaubt
        // - Mittlere Karten: Bewegung in beide Richtungen erlaubt
        
        // Hole die aktuelle Hand-Position (normalerweise 0 beim Start)
        RectTransform containerRect = handContainer.GetComponent<RectTransform>();
        float currentPosition = containerRect ? containerRect.localPosition.x : 0f;
        
        if (touchedCardIndex == cardCount - 1) // Ganz rechte Karte
        {
            // Rechte Karte berührt = betrachte aktuelle Position als rechten Anschlag
            // Nur Bewegung nach links (negative Richtung) erlaubt
            maxAllowedLeftMovement = MAX_HAND_OFFSET; // Volle Bewegung nach links möglich
            maxAllowedRightMovement = 0f; // Keine Bewegung nach rechts
        }
        else if (touchedCardIndex == 0) // Ganz linke Karte
        {
            // Linke Karte berührt = betrachte aktuelle Position als linken Anschlag
            // Nur Bewegung nach rechts (positive Richtung) erlaubt
            maxAllowedLeftMovement = 0f; // Keine Bewegung nach links
            maxAllowedRightMovement = MAX_HAND_OFFSET; // Volle Bewegung nach rechts möglich
        }
        else // Mittlere Karten
        {
            // Mittlere Karte = Bewegung in beide Richtungen erlaubt
            // Aber proportional zur Kartenposition begrenzt
            float t = (float)touchedCardIndex / (cardCount - 1);
            maxAllowedLeftMovement = t * MAX_HAND_OFFSET;
            maxAllowedRightMovement = (1f - t) * MAX_HAND_OFFSET;
        }
        
        // Speichere die aktuelle Position als Startposition
        initialHandOffsetForCard = currentPosition;
        currentHandOffset = currentPosition;
        
        // Speichere die berührte Karten-Position
        anchoredCardIndex = touchedCardIndex;
        
        // if (logParallaxDetails)
        // {
        //     LogInfo($"PARALLAX INIT: Card {touchedCardIndex+1}/{cardCount} touched at current position {currentPosition:F0}px", true);
        //     LogInfo($"Allowed movement: left={maxAllowedLeftMovement:F0}px, right={maxAllowedRightMovement:F0}px", true);
        // }
    }
    
    // Diese Methoden werden nicht mehr benötigt, da wir einen einheitlichen Bogen in UpdateCardLayoutArc verwenden
    // private Vector3 CalculateCardPositionOnArc(int cardIndex, int totalCards, float parallaxOffset) { }
    // private float CalculateCardRotationOnArc(int cardIndex, int totalCards, float parallaxOffset) { }
    
    private void UpdateParallaxHandShift(Vector2 position)
    {
        // CRITICAL DEBUG - Always log this
        Debug.Log($"[PARALLAX] UpdateParallaxHandShift called! pos: {position}, isFanned: {isFanned}, currentOffset: {currentHandOffset:F1}");
        
        if (!isFanned) 
        {
            LogInfo("[PARALLAX] Blocked - not fanned", true);
            return;
        }
        
        // Berechne Finger-Bewegung vom Start
        float fingerMovement = position.x - startTouchPosition.x;
        
        // WICHTIGE KORREKTUR: Invertierte Logik für natürliches Gefühl
        // Finger nach links → Hand/Karten bewegen sich nach RECHTS (entgegengesetzt)
        // So kommen die Karten dem Finger "entgegen"
        
        // Berechne die gewünschte Bewegung (invertiert) RELATIV zur Startposition
        float desiredMovement = -fingerMovement * parallaxSensitivity;
        float targetOffset = initialHandOffsetForCard + desiredMovement;
        
        // Begrenze die absolute Position auf die Anschläge
        const float MAX_HAND_OFFSET = 250f;
        targetOffset = Mathf.Clamp(targetOffset, -MAX_HAND_OFFSET, MAX_HAND_OFFSET);
        
        // CRITICAL FIX: Nur bei signifikanter Änderung updaten
        float offsetDifference = Mathf.Abs(targetOffset - currentHandOffset);
        if (offsetDifference < 5f) // Weniger als 5 Pixel Unterschied
        {
            return; // Keine Änderung nötig
        }
        
        // Setze den neuen Offset - ABER verschiebe NICHT den Container!
        currentHandOffset = targetOffset;
        
        // CRITICAL: Immer das Layout updaten, damit die Karten dem Bogen folgen
        // Verwende UpdateParallaxOffsetOnly für minimale Störungen
        UpdateParallaxOffsetOnly();
        
        // CRITICAL DEBUG - Always log this
        Debug.Log($"[PARALLAX] Offset updated to {currentHandOffset:F1} (finger moved {fingerMovement:F1}px)");
        
        // Nur bei größeren Bewegungen loggen (deaktiviert)
        // if (logParallaxDetails && Mathf.Abs(fingerMovement) > 10f)
        // {
        //     LogInfo($"PARALLAX: finger={position.x:F0}, movement={fingerMovement:F0} → arc offset={currentHandOffset:F0} (from start: {initialHandOffsetForCard:F0})", true);
        // }
    }
    
    private void NotifyLastHoveredCardChanged()
    {
        string lastHoveredName = lastHoveredCard != null ? lastHoveredCard.GetCardData()?.cardName ?? "NULL" : "none";
        
        foreach (var cardObj in activeCardUIs)
        {
            if (cardObj != null)
            {
                var cardUI = cardObj.GetComponent<CardUI>();
                if (cardUI != null)
                {
                    // TODO: Implementiere OnLastHoveredCardChanged in CardUI wenn benötigt
                    // cardUI.OnLastHoveredCardChanged(lastHoveredCard);
                }
            }
        }
        
        Debug.Log($"[HandController] NotifyLastHoveredCardChanged - all cards informed that lastHovered is now: '{lastHoveredName}'");
    }
    
    private void AnimateHandToCenter()
    {
        // NEU: Container wird nicht mehr bewegt, nur der Offset zurückgesetzt
        LeanTween.value(currentHandOffset, 0f, 0.3f)
            .setEase(LeanTweenType.easeOutExpo)
            .setOnUpdate((float value) => {
                currentHandOffset = value;
                UpdateCardLayout(forceImmediate: true, isFromCardCreation: false);
            })
            .setOnComplete(() => {
                currentHandOffset = 0f;
                initialHandOffsetForCard = 0f;
            });
    }
    
    private void CenterHandAfterDragStart()
    {
        // NEU: Container bleibt bei 0, nur Offset wird zurückgesetzt
        currentHandOffset = 0f;
        // Update das Layout, damit die verbleibenden Karten sich neu zentrieren
        UpdateCardLayout(true); // Force immediate für sofortiges Re-Layout
    }
    
    private bool IsCardPlayable(TimeCardData cardData)
    {
        if (cardData == null) return false;
        if (RiftTimeSystem.Instance == null) return false;
        
        // TODO: Verwende die korrekte Methode von RiftTimeSystem
        // Vermutlich: return RiftTimeSystem.Instance.HasEnoughTime(cardData.GetScaledTimeCost());
        // oder: return RiftTimeSystem.Instance.CanAffordTimeCost(cardData.GetScaledTimeCost());
        return true; // Temporär: Erlaube alle Karten
    }
    
    private void ReturnDraggedCardToHand()
    {
        if (draggedCardUI == null) return;
        
        Debug.Log($"[HandController] Returning card to hand: {draggedCardUI.GetCardData()?.cardName}");
        
        draggedCardUI.OnCentralDragEnd();
        AddCardBackToHand(draggedCardUI.gameObject);
        
        StartCoroutine(ResetPlayingCardFlag());
    }
    
    private RiftEnemy GetEnemyUnderDragPosition()
    {
        if (RiftCombatManager.Instance == null) return null;
        
        var activeEnemies = RiftCombatManager.Instance.GetActiveEnemies();
        foreach (var enemy in activeEnemies)
        {
            if (enemy != null && !enemy.IsDead())
            {
                Vector3 worldPos = Camera.main.ScreenToWorldPoint(lastDragPosition);
                worldPos.z = enemy.transform.position.z;
                
                float distance = Vector3.Distance(worldPos, enemy.transform.position);
                if (distance < 1.5f)
                {
                    return enemy;
                }
            }
        }
        
        return null;
    }
    
    private void PlayDraggedCardOnTarget(RiftEnemy target)
    {
        if (draggedCardUI == null || target == null) return;
        
        isPlayingCard = true;
        TimeCardData cardData = draggedCardUI.GetCardData();
        
        if (ZeitwaechterPlayer.Instance != null && RiftTimeSystem.Instance.TryPlayCard(cardData.GetScaledTimeCost()))
        {
            Debug.Log($"[HandController] Playing card {cardData.cardName} on target {target.name}");
            
            bool cardRemoved = ZeitwaechterPlayer.Instance.PlayCardFromCombat(cardData);
            if (cardRemoved)
            {
                RiftCombatManager.Instance.ExecuteCardEffectDirect(cardData, ZeitwaechterPlayer.Instance, target);
                
                if (activeCardUIs.Contains(draggedCardUI.gameObject))
                {
                    activeCardUIs.Remove(draggedCardUI.gameObject);
                }
                Destroy(draggedCardUI.gameObject);
            }
        }
        else
        {
            ReturnDraggedCardToHand();
        }
    }
    
    private void EnsureCorrectSiblingOrder()
    {
        for (int i = 0; i < activeCardUIs.Count; i++)
        {
            if (activeCardUIs[i] != null)
            {
                activeCardUIs[i].transform.SetSiblingIndex(i);
            }
        }
    }
    
    private System.Collections.IEnumerator CheckCardPositionAfterFrame(GameObject card, Vector3 expectedPosition, int expectedIndex)
    {
        yield return null;
        
        if (card != null)
        {
            Vector3 actualPos = card.transform.localPosition;
            if (Vector3.Distance(actualPos, expectedPosition) > 0.1f)
            {
                Debug.LogError($"[HandController] Card {expectedIndex} position mismatch after frame! Expected: {expectedPosition}, Actual: {actualPos}");
                card.transform.localPosition = expectedPosition;
            }
        }
    }
    
    private System.Collections.IEnumerator MonitorCard3SiblingIndex(GameObject card3)
    {
        // Deaktiviert - nicht mehr benötigt
        yield break;
    }
    
    private void SortCardUIsByPosition()
    {
        // WARNUNG: Diese Methode sollte NICHT mehr verwendet werden!
        // Sie verursacht Karten-Identitäts-Probleme, da die Reihenfolge in activeCardUIs
        // mit der Reihenfolge in player.hand übereinstimmen muss!
        Debug.LogWarning("[HandController] SortCardUIsByPosition() sollte nicht mehr verwendet werden!");
        return;
    }
    
    private void UpdateCardPreview()
    {
        if (!isFanned || hoveredCard == null)
        {
            HideCardPreview();
            return;
        }
        
        // TODO: Implementiere Vorschau-System
    }
    
    private void HideCardPreview()
    {
        if (cardPreview != null)
        {
            Destroy(cardPreview);
            cardPreview = null;
            cardPreviewUI = null;
            previewCanvasGroup = null;
        }
    }
    
    /// <summary>
    /// Optimierte Methode die nur den Parallax-Offset anwendet
    /// ohne das gesamte Layout neu zu berechnen
    /// </summary>
    private void UpdateParallaxOffsetOnly()
    {
        if (activeCardUIs.Count == 0) return;
        
        float effectiveParallaxOffset = currentHandOffset;
        int cardCount = activeCardUIs.Count;
        
        // CRITICAL DEBUG - Always log this  
        Debug.Log($"[PARALLAX] UpdateParallaxOffsetOnly - offset: {effectiveParallaxOffset:F1}, cards: {cardCount}");
        
        // EINFACHE KREISBOGEN-BERECHNUNG (gleich wie in UpdateCardLayoutArc)
        float circleRadius = arcRadius;
        float totalArcAngle = arcAngleFanned;  // Fanning-Winkel (da diese Methode nur bei isFanned aufgerufen wird)
        float startAngle = 90f - (totalArcAngle / 2f); // Oben minus halber Bogen
        
        // NEUER ANSATZ: Karten verschieben sich wie Perlen auf einer festen Kette
        // Berechne virtuelle Index-Verschiebung basierend auf Parallax-Offset
        float cardWidth = parallaxCardWidth;
        float indexShift = effectiveParallaxOffset / cardWidth; // Wie viele "Karten-Positionen" verschieben
        
        // Update ALLE Karten mit virtueller Position auf dem festen Bogen
        for (int i = 0; i < cardCount; i++)
        {
            GameObject card = activeCardUIs[i];
            if (card == null || card == draggedCard) continue;
            
            CardUI cardUI = card.GetComponent<CardUI>();
            if (cardUI == null) continue;
            
            // Berechne virtuelle Position (kann zwischen Karten-Slots liegen)
            float virtualIndex = i - indexShift; // Negative shift = Karten bewegen sich nach rechts
            
            // Winkel für virtuelle Position berechnen
            float angleStep = cardCount > 1 ? totalArcAngle / (cardCount - 1) : 0f;
            float currentAngle = startAngle + (virtualIndex * angleStep);
            float angleInRadians = currentAngle * Mathf.Deg2Rad;
            
            // EINFACHE KREIS-POSITION auf festem Bogen
            float x = Mathf.Cos(angleInRadians) * circleRadius;
            float y = Mathf.Sin(angleInRadians) * circleRadius - circleRadius + arcYOffset; // Oberer Teil des Kreises mit Offset
            
            Vector3 targetPosition = new Vector3(x, y, 0);
            
            // Rotation basiert auf virtueller Position
            float targetRotation = currentAngle - 90f;
            
            // Debug für extreme Positionen
            if (Mathf.Abs(effectiveParallaxOffset) > 200f && (i == 0 || i == cardCount - 1))
            {
                Debug.Log($"[PARALLAX DEBUG] Card {i}: virtualIndex={virtualIndex:F1}, angle={currentAngle:F1}°, pos=({x:F0}, {y:F0})");
            }
            
            // Update die Karte mit der vollen Arc-Position
            cardUI.UpdateParallaxPositionWithArc(targetPosition, 0.05f);
            
            // Rotation nur für nicht-hovering Karten setzen
            if (!cardUI.IsHovering() && !cardUI.IsInHoverAnimation())
            {
                cardUI.transform.localEulerAngles = new Vector3(0, 0, targetRotation);
            }
        }
        
        // Force Canvas update damit Collider mit visuellen Positionen übereinstimmen
        Canvas.ForceUpdateCanvases();
    }
    
    private float CalculateTotalHandWidth()
    {
        if (activeCardUIs.Count == 0) return 0f;
        
        float totalSpacing = isFanned ? fanSpacing : cardSpacing;
        float actualSpacing = totalSpacing;
        
        int cardCount = activeCardUIs.Count;
        if (cardCount > 3)
        {
            RectTransform containerRect = handContainer.GetComponent<RectTransform>();
            if (containerRect != null)
            {
                float containerWidth = Mathf.Abs(containerRect.rect.width);
                float maxWidth = (cardCount - 1) * totalSpacing + maxCardWidth;
                if (maxWidth > containerWidth * 0.9f)
                {
                    actualSpacing = (containerWidth * 0.9f - maxCardWidth) / (cardCount - 1);
                }
            }
        }
        
        float totalWidth = (cardCount - 1) * actualSpacing + maxCardWidth;
        
        return totalWidth;
    }
    
    // Legacy-Methoden für Kompatibilität
    private void AddCardToHand(TimeCardData cardData)
    {
        Debug.Log($"[HandController] LEGACY AddCardToHand called for: {cardData?.cardName}");
    }
    
    private void RemoveCardFromHand(TimeCardData cardData)
    {
        Debug.Log($"[HandController] LEGACY RemoveCardFromHand called for: {cardData?.cardName}");
    }
    
    public void PlayCardFromDrag(CardUI cardUI)
    {
        Debug.LogWarning($"[HandController] PlayCardFromDrag LEGACY call ignored for {cardUI?.GetCardData()?.cardName} - using centralized drag system");
    }
}
