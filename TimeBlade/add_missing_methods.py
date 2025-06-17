#!/usr/bin/env python3

import os

# Die fehlenden Methoden
MISSING_METHODS = '''
    /// <summary>
    /// Initialisiert das card-aware Parallax System basierend auf der berührten Karte
    /// </summary>
    private void InitializeCardAwareParallax(CardUI touchedCard)
    {
        const float FIXED_MAX_OFFSET = 250f;
        
        if (touchedCard == null || activeCardUIs.Count == 0)
        {
            // Fallback: Kein Karten-Kontext, verwende symmetrisches System
            initialCardNormalizedPosition = 0.5f;
            initialHandOffsetForCard = 0f;
            maxAllowedLeftMovement = FIXED_MAX_OFFSET;
            maxAllowedRightMovement = FIXED_MAX_OFFSET;
            LogInfo("CARD-AWARE PARALLAX: No card touched, using symmetric limits", logParallaxDetails);
            return;
        }
        
        // Finde die Position der berührten Karte im Fächer (0=links, 1=rechts)
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
            // Fallback
            initialCardNormalizedPosition = 0.5f;
            initialHandOffsetForCard = 0f;
            maxAllowedLeftMovement = FIXED_MAX_OFFSET;
            maxAllowedRightMovement = FIXED_MAX_OFFSET;
            return;
        }
        
        // Berechne normalisierte Position (0=ganz links, 1=ganz rechts)
        int cardCount = activeCardUIs.Count;
        initialCardNormalizedPosition = cardCount > 1 ? (float)touchedCardIndex / (cardCount - 1) : 0.5f;
        
        // Berechne den initialen Hand-Offset basierend auf Kartenposition
        // Linke Karte (0) → Hand sollte rechts sein (+maxOffset)
        // Rechte Karte (1) → Hand sollte links sein (-maxOffset)
        initialHandOffsetForCard = Mathf.Lerp(FIXED_MAX_OFFSET, -FIXED_MAX_OFFSET, initialCardNormalizedPosition);
        
        // Berechne erlaubte Bewegungsgrenzen
        // Wenn wir die rechte Karte berühren (Hand ist links), können wir nur nach rechts
        // Wenn wir die linke Karte berühren (Hand ist rechts), können wir nur nach links
        maxAllowedLeftMovement = initialHandOffsetForCard - (-FIXED_MAX_OFFSET); // Wie viel nach links möglich
        maxAllowedRightMovement = FIXED_MAX_OFFSET - initialHandOffsetForCard; // Wie viel nach rechts möglich
        
        // Setze die Hand sofort auf die korrekte Position für die berührte Karte
        currentHandOffset = initialHandOffsetForCard;
        RectTransform containerRect = handContainer.GetComponent<RectTransform>();
        if (containerRect != null)
        {
            Vector3 pos = containerRect.localPosition;
            pos.x = currentHandOffset;
            containerRect.localPosition = pos;
        }
        
        LogInfo($"CARD-AWARE PARALLAX INIT: Card {touchedCardIndex}/{cardCount-1} (norm={initialCardNormalizedPosition:F2}), " +
               $"initial offset={initialHandOffsetForCard:F1}, allowed movement: left={maxAllowedLeftMovement:F1}, right={maxAllowedRightMovement:F1}", 
               logParallaxDetails);
    }
    
    /// <summary>
    /// NEUE METHODE: Aktualisiert die Parallax-Verschiebung der Hand basierend auf Finger-Position
    /// Verwendet CARD-AWARE PARALLAX: Berücksichtigt welche Karte initial berührt wurde
    /// </summary>
    private void UpdateParallaxHandShift(Vector2 position)
    {
        if (!isParallaxActive || !isFanned) return;
        
        // CARD-AWARE PARALLAX
        // Berechne Finger-Bewegung vom Start
        float fingerMovement = position.x - startTouchPosition.x;
        
        // Bestimme erlaubte Bewegung basierend auf Richtung
        float allowedMovement = 0f;
        
        if (fingerMovement > 0) 
        {
            // Finger bewegt sich nach rechts → Hand soll nach links
            // Aber nur wenn wir noch nicht am linken Limit sind
            allowedMovement = Mathf.Min(fingerMovement, maxAllowedLeftMovement / parallaxSensitivity);
        }
        else 
        {
            // Finger bewegt sich nach links → Hand soll nach rechts
            // Aber nur wenn wir noch nicht am rechten Limit sind
            allowedMovement = Mathf.Max(fingerMovement, -maxAllowedRightMovement / parallaxSensitivity);
        }
        
        // Wende die erlaubte Bewegung an (invertiert: Finger rechts = Hand links)
        float targetHandOffset = initialHandOffsetForCard - (allowedMovement * parallaxSensitivity * 0.3f);
        
        // Finale Sicherheitsbegrenzung
        const float FIXED_MAX_OFFSET = 250f;
        targetHandOffset = Mathf.Clamp(targetHandOffset, -FIXED_MAX_OFFSET, FIXED_MAX_OFFSET);
        
        // DIRECT UPDATE - no smoothing
        currentHandOffset = targetHandOffset;
        
        // Update container position
        RectTransform containerRect = handContainer.GetComponent<RectTransform>();
        if (containerRect != null)
        {
            Vector3 pos = containerRect.localPosition;
            pos.x = currentHandOffset;
            containerRect.localPosition = pos;
        }
        
        LogInfo($"CARD-AWARE PARALLAX: finger=({position.x:F1}), movement={fingerMovement:F1}, " +
               $"allowed={allowedMovement:F1}, offset={currentHandOffset:F1} (from initial {initialHandOffsetForCard:F1})", 
               logParallaxDetails);
    }
    
    /// <summary>
    /// NEUE LOGIK: Informiere alle Karten über die geänderte lastHoveredCard
    /// </summary>
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
                    // Informiere jede Karte über die neue lastHoveredCard
                    cardUI.OnLastHoveredCardChanged(lastHoveredCard);
                }
            }
        }
        
        Debug.Log($"[HandController] NotifyLastHoveredCardChanged - all cards informed that lastHovered is now: '{lastHoveredName}'");
    }
    
    /// <summary>
    /// Animiert die Hand zurück zur Mitte
    /// </summary>
    private void AnimateHandToCenter()
    {
        // Implement animation to center
        RectTransform containerRect = handContainer.GetComponent<RectTransform>();
        if (containerRect != null)
        {
            LeanTween.moveLocalX(containerRect.gameObject, 0f, 0.3f).setEase(LeanTweenType.easeOutExpo);
            currentHandOffset = 0f;
        }
    }
    
    /// <summary>
    /// Zentriert die Hand nach Drag-Start
    /// </summary>
    private void CenterHandAfterDragStart()
    {
        // Center the hand when drag starts
        RectTransform containerRect = handContainer.GetComponent<RectTransform>();
        if (containerRect != null)
        {
            Vector3 pos = containerRect.localPosition;
            pos.x = 0f;
            containerRect.localPosition = pos;
            currentHandOffset = 0f;
        }
    }
    
    /// <summary>
    /// Überprüft ob eine Karte spielbar ist
    /// </summary>
    private bool IsCardPlayable(TimeCardData cardData)
    {
        if (cardData == null) return false;
        if (RiftTimeSystem.Instance == null) return false;
        
        // Prüfe ob genug Zeit vorhanden ist
        return RiftTimeSystem.Instance.CanPlayCard(cardData.GetScaledTimeCost());
    }
    
    /// <summary>
    /// Gibt die gedraggte Karte zurück zur Hand
    /// </summary>
    private void ReturnDraggedCardToHand()
    {
        if (draggedCardUI == null) return;
        
        Debug.Log($"[HandController] Returning card to hand: {draggedCardUI.GetCardData()?.cardName}");
        
        // Benachrichtige die Karte über Drag-Ende
        draggedCardUI.OnCentralDragEnd();
        
        // Füge Karte zurück zur Hand
        AddCardBackToHand(draggedCardUI.gameObject);
        
        // Reset isPlayingCard nach Delay
        StartCoroutine(ResetPlayingCardFlag());
    }
    
    /// <summary>
    /// Gibt den Gegner unter der Drag-Position zurück
    /// </summary>
    private RiftEnemy GetEnemyUnderDragPosition()
    {
        if (RiftCombatManager.Instance == null) return null;
        
        var activeEnemies = RiftCombatManager.Instance.GetActiveEnemies();
        foreach (var enemy in activeEnemies)
        {
            if (enemy != null && !enemy.IsDead())
            {
                // Prüfe ob die Mausposition über dem Gegner ist
                Vector3 worldPos = Camera.main.ScreenToWorldPoint(lastDragPosition);
                worldPos.z = enemy.transform.position.z;
                
                // Einfache Distanz-Prüfung
                float distance = Vector3.Distance(worldPos, enemy.transform.position);
                if (distance < 1.5f) // Threshold für Treffer
                {
                    return enemy;
                }
            }
        }
        
        return null;
    }
    
    /// <summary>
    /// Spielt die gedraggte Karte auf ein spezifisches Ziel
    /// </summary>
    private void PlayDraggedCardOnTarget(RiftEnemy target)
    {
        if (draggedCardUI == null || target == null) return;
        
        isPlayingCard = true;
        TimeCardData cardData = draggedCardUI.GetCardData();
        
        if (ZeitwaechterPlayer.Instance != null && RiftTimeSystem.Instance.TryPlayCard(cardData.GetScaledTimeCost()))
        {
            Debug.Log($"[HandController] Playing card {cardData.cardName} on target {target.name}");
            
            // Entferne die Karte
            bool cardRemoved = ZeitwaechterPlayer.Instance.PlayCardFromCombat(cardData);
            if (cardRemoved)
            {
                // Führe den Effekt aus
                RiftCombatManager.Instance.ExecuteCardEffectDirect(cardData, ZeitwaechterPlayer.Instance, target);
                
                // Zerstöre das UI-GameObject
                if (activeCardUIs.Contains(draggedCardUI.gameObject))
                {
                    activeCardUIs.Remove(draggedCardUI.gameObject);
                }
                Destroy(draggedCardUI.gameObject);
            }
        }
        else
        {
            // Nicht genug Zeit - Karte zurück zur Hand
            ReturnDraggedCardToHand();
        }
    }
    
    /// <summary>
    /// Stellt sicher, dass alle Karten die korrekte Sibling-Reihenfolge haben
    /// </summary>
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
    
    /// <summary>
    /// Überprüft die Position einer Karte nach einem Frame
    /// </summary>
    private System.Collections.IEnumerator CheckCardPositionAfterFrame(GameObject card, Vector3 expectedPosition, int expectedIndex)
    {
        yield return null; // Warte einen Frame
        
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
    
    /// <summary>
    /// Überwacht Card 3 SiblingIndex
    /// </summary>
    private System.Collections.IEnumerator MonitorCard3SiblingIndex(GameObject card3)
    {
        while (card3 != null)
        {
            int currentIndex = card3.transform.GetSiblingIndex();
            if (currentIndex != 3)
            {
                Debug.LogError($"[HandController] CARD 3 SIBLING INDEX WRONG: {currentIndex} (should be 3)");
            }
            yield return new WaitForSeconds(0.1f);
        }
    }
    
    /// <summary>
    /// Erstellt eine Karten-Vorschau
    /// </summary>
    private void UpdateCardPreview()
    {
        if (!isFanned || hoveredCard == null)
        {
            HideCardPreview();
            return;
        }
        
        // Implementierung der Karten-Vorschau
        // TODO: Implementiere Vorschau-System
    }
    
    /// <summary>
    /// Versteckt die Karten-Vorschau
    /// </summary>
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
'''

def main():
    file_path = "/Users/exqbitmac/TimeBlade/Assets/UI/HandController.cs"
    
    # Lese die aktuelle Datei
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Finde die letzte schließende Klammer der Klasse
    # Wir suchen nach der letzten } in der Datei
    last_brace_index = content.rfind('}')
    
    if last_brace_index == -1:
        print("FEHLER: Konnte keine schließende Klammer finden!")
        return
    
    # Füge die Methoden vor der letzten schließenden Klammer ein
    new_content = content[:last_brace_index] + MISSING_METHODS + "\n" + content[last_brace_index:]
    
    # Erstelle ein Backup
    import datetime
    backup_path = file_path + f".backup_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Backup erstellt: {backup_path}")
    
    # Schreibe die aktualisierte Datei
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"✅ Erfolgreich! {len(MISSING_METHODS.splitlines())} Zeilen Code zu HandController.cs hinzugefügt.")
    print(f"Die fehlenden Methoden wurden am Ende der Klasse eingefügt.")

if __name__ == "__main__":
    main()
