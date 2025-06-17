using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// TEIL 2/4: Touch-Input und Drag&Drop Funktionalität
/// </summary>
public partial class HandController : MonoBehaviour
{
    private void HandleTouchInput()
    {
        if (!enableFanning) return;
        
        // Mobile Touch
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);
            
            if (touch.phase == TouchPhase.Began)
            {
                CardUI.SetIsMouseInput(false);
                HandleTouchStart(touch.position);
            }
            else if (touch.phase == TouchPhase.Moved && isTouching && !isPlayingCard)
            {
                HandleTouchMove(touch.position);
            }
            else if (touch.phase == TouchPhase.Ended || touch.phase == TouchPhase.Canceled)
            {
                HandleTouchEnd();
            }
        }
        // Mouse (für Editor-Testing)
        else
        {
            if (Input.GetMouseButtonDown(0))
            {
                CardUI.SetIsMouseInput(true);
                HandleTouchStart(Input.mousePosition);
            }
            else if (Input.GetMouseButton(0) && isTouching && !isPlayingCard)
            {
                HandleTouchMove(Input.mousePosition);
            }
            else if (Input.GetMouseButtonUp(0))
            {
                HandleTouchEnd();
            }
        }
    }
    
    private void HandleTouchStart(Vector2 position)
    {
        LogInfo($"Touch start at screen position: {position}, input type: {(CardUI.IsMouseInput() ? "Mouse" : "Touch")}", logTouchEvents);
        
        // CRITICAL DEBUG: Log the state of key variables
        Debug.Log($"[PARALLAX DEBUG] HandleTouchStart - enableFanning: {enableFanning}, activeCards: {activeCardUIs.Count}");
        
        // WICHTIG: Stelle sicher, dass die Karten-Liste korrekt sortiert ist
        SortCardUIsByPosition();
        
        // NEUE LOGIK: Zuerst prüfen ob eine Karte getroffen wurde
        CardUI touchedCard = GetCardAtPosition(position);
        
        if (touchedCard == null)
        {
            // Kein Touch auf einer Karte - ignoriere den Touch komplett
            LogInfo($"✗ Touch rejected - no card hit at position {position}", logTouchEvents);
            CardUI.SetTouchStartedOnValidArea(false);
            return;
        }
        
        LogInfo($"✓ Touch on card detected: '{touchedCard.GetCardData()?.cardName}' at position {position}", logTouchEvents);
        
        LogInfo($"=== TOUCH DEBUG - ALL CARDS ===", logTouchEvents && logCardPositions);
        for (int i = 0; i < activeCardUIs.Count; i++)
        {
            if (activeCardUIs[i] != null)
            {
                var cardUI = activeCardUIs[i].GetComponent<CardUI>();
                var cardRect = activeCardUIs[i].GetComponent<RectTransform>();
                string cardName = cardUI?.GetCardData()?.cardName ?? "NULL";
                LogInfo($"Card {i}: {activeCardUIs[i].name} - CardData: {cardName} - LocalPos: {cardRect.localPosition} - WorldPos: {cardRect.position} - SiblingIndex: {activeCardUIs[i].transform.GetSiblingIndex()}", logTouchEvents && logCardPositions);
            }
        }
        LogInfo($"=== END TOUCH DEBUG ===", logTouchEvents && logCardPositions);
        
        // Da wir eine Karte getroffen haben, starten wir den Fanning-Prozess
        LogInfo($"✓ VALID TOUCH ON CARD - Starting fanning process", logTouchEvents);
        
        isTouching = true;
        isFanned = true;
        touchStartTime = Time.time;
        globalTouchActive = true;
        
        LogInfo("GLOBAL TOUCH ACTIVE - All hover events will be blocked", logTouchEvents);
        
        // CRITICAL FIX: Restore all cards to their original sibling indices before layout update
        for (int i = 0; i < activeCardUIs.Count; i++)
        {
            GameObject cardObj = activeCardUIs[i];
            if (cardObj != null)
            {
                var cardUI = cardObj.GetComponent<CardUI>();
                if (cardUI != null)
                {
                    cardUI.ForceDisableHover();
                }
                // Ensure correct sibling index based on position in hand
                cardObj.transform.SetSiblingIndex(i);
            }
        }
        LogInfo("Force disabled hover on ALL cards at touch start and restored sibling indices", logTouchEvents);
        
        CardUI.SetTouchStartedOnValidArea(true);
        
        lastHoveredCard = null;
        isPlayingCard = false;
        
        dragStartPosition = position;
        lastDragPosition = position;
        lastFingerPosition = position;
        startTouchPosition = position;
        isDraggingActive = false;
        draggedCardUI = null;
        
        hasChangedCards = false;
        initialHoveredCard = null;
        
        isHysteresisActive = false;
        lastHoverPosition = position;
        
        lastDragPosition = position;
        isParallaxActive = true;
        
        // Initialisierung erfolgt in InitializeCardAwareParallax
        
        // TouchedCard haben wir bereits am Anfang ermittelt
        
        initiallyTouchedCard = touchedCard;
        touchStartScreenPos = position;
        
        InitializeCardAwareParallax(touchedCard);
        
        // TouchedCard ist garantiert nicht null (wurde oben geprüft)
        LogInfo($"*** TOUCH LOCK INITIALIZED *** Locked to: '{touchedCard.GetCardData()?.cardName}' at position {position}", logTouchEvents);
        
        // Finde den Index der berührten Karte
        for (int i = 0; i < activeCardUIs.Count; i++)
        {
            var cardUI = activeCardUIs[i].GetComponent<CardUI>();
            if (cardUI == touchedCard)
            {
                anchoredCardIndex = i;
                anchoredCardInitialX = activeCardUIs[i].transform.localPosition.x;
                break;
            }
        }
        
        RectTransform touchedCardRect = touchedCard.GetComponent<RectTransform>();
        if (touchedCardRect != null)
        {
            Vector2 cardScreenPos = RectTransformUtility.WorldToScreenPoint(canvasCamera, touchedCardRect.position);
            touchOffsetFromAnchorCard = position - cardScreenPos;
            LogInfo($"Touch on card '{touchedCard.GetCardData()?.cardName}' (index {anchoredCardIndex}) - Touch pos: {position}, Card screen pos: {cardScreenPos}, Offset: {touchOffsetFromAnchorCard}", logTouchEvents);
        }
        
        UpdateCardLayout(forceImmediate: false, isFromCardCreation: false, anchorCard: touchedCard);
        
        foreach (var cardObj in activeCardUIs)
        {
            if (cardObj != null)
            {
                var cardUI = cardObj.GetComponent<CardUI>();
                if (cardUI != null && !cardUI.IsHovering())
                {
                    cardUI.SetInLayoutAnimation(false);
                }
            }
        }
        
        // Setze die berührte Karte als hovered
        hoveredCard = initiallyTouchedCard;
        initiallyTouchedCard.ForceEnterHover();
        lastHoveredCard = initiallyTouchedCard;
        UpdateCardPreview();
        
        LogInfo($"*** INITIAL TOUCH LOCK *** Locked to card: '{initiallyTouchedCard.GetCardData()?.cardName}'", logTouchEvents);
        initialHoveredCard = initiallyTouchedCard;
    }
    
    private void HandleTouchMove(Vector2 position)
    {
        // CRITICAL FIX: Parallax sollte VOR dem Drag-Check ausgeführt werden
        // und auch während des Fanning funktionieren
        if (isFanned && !isDraggingActive)
        {
            UpdateParallaxHandShift(position);
        }
        else if (Time.frameCount % 30 == 0) // Debug warum Parallax nicht aktiv ist
        {
            Debug.Log($"[PARALLAX] NOT ACTIVE - isFanned: {isFanned}, isDraggingActive: {isDraggingActive}");
        }
        
        UpdateCardSelectionAtPosition(position);
        
        if (!isDraggingActive && !isPlayingCard)
        {
            Vector2 dragDelta = position - dragStartPosition;
            
            if (Mathf.Abs(dragDelta.y) > 10f || Mathf.Abs(dragDelta.x) > 10f)
            {
                LogInfo($"Drag detection: delta=({dragDelta.x:F1}, {dragDelta.y:F1}), vertical needed: {minVerticalSwipeForDrag}, horizontal max: {maxHorizontalMovementForDrag}", logTouchEvents);
            }
            
            bool hasUpwardMovement = dragDelta.y > minVerticalSwipeForDrag;
            
            float angle = Mathf.Abs(Mathf.Atan2(dragDelta.y, dragDelta.x) * Mathf.Rad2Deg);
            
            float horizontalAbs = Mathf.Abs(dragDelta.x);
            float verticalAbs = Mathf.Abs(dragDelta.y);
            float movementRatio = horizontalAbs > 0.1f ? verticalAbs / horizontalAbs : float.MaxValue;
            
            bool isPrimarilyVertical = angle > 30f || movementRatio > 0.5f;
            bool hasCardDrift = false; // DEAKTIVIERT
            
            if (Mathf.Abs(dragDelta.y) > 10f || Mathf.Abs(dragDelta.x) > 10f)
            {
                LogInfo($"Movement: delta=({dragDelta.x:F1}, {dragDelta.y:F1}), needed Y={minVerticalSwipeForDrag}, hasUpward={hasUpwardMovement}, isVertical={isPrimarilyVertical}, drift={hasCardDrift}", logTouchEvents);
            }
            
            bool shouldStartDrag = false;
            
            bool isStrongUpwardMovement = dragDelta.y > strongUpwardMovementThreshold;
            
            if (isStrongUpwardMovement)
            {
                shouldStartDrag = true;
                LogInfo($"✓ DRAG TRIGGERED - Strong upward movement: {dragDelta.y:F1}px (ignoring other checks)", logTouchEvents);
            }
            else if (hasUpwardMovement && isPrimarilyVertical && !hasCardDrift)
            {
                shouldStartDrag = true;
                LogInfo($"✓ DRAG TRIGGERED - Vertical swipe: {dragDelta.y:F1}px up, {dragDelta.x:F1}px horizontal, angle={angle:F1}°, ratio={movementRatio:F2}", logTouchEvents);
            }
            else if (hasUpwardMovement && !isPrimarilyVertical)
            {
                LogInfo($"Upward movement BLOCKED - too horizontal: angle={angle:F1}°, ratio={movementRatio:F2} (v:{dragDelta.y:F1}/h:{dragDelta.x:F1})", logTouchEvents);
            }
            else if (hasUpwardMovement && hasCardDrift)
            {
                string initialCardName = initialHoveredCard?.GetCardData()?.cardName ?? "NULL";
                string currentCardName = hoveredCard?.GetCardData()?.cardName ?? "NULL";
                LogInfo($"Upward movement BLOCKED - card drift from '{initialCardName}' to '{currentCardName}'", logTouchEvents);
            }
            
            if (shouldStartDrag)
            {
                StartDragOperation();
            }
        }
        
        if (isDraggingActive && draggedCardUI != null)
        {
            MoveDraggedCardToPosition(position);
        }
        
        lastDragPosition = position;
        lastFingerPosition = position;
    }
    
    private void HandleTouchEnd()
    {
        string hoveredCardName = hoveredCard?.GetCardData()?.cardName ?? "none";
        string lastHoveredCardName = lastHoveredCard?.GetCardData()?.cardName ?? "none";
        LogInfo($"Touch end - was touching: {isTouching}, was fanned: {isFanned}, hovered: {hoveredCardName}, lastHovered: {lastHoveredCardName}, isDragging: {isDraggingActive}", logTouchEvents);
        
        if (isTouching)
        {
            isTouching = false;
            isFanned = false;
            
            anchoredCardIndex = -1;
            anchoredCardInitialX = 0f;
            touchOffsetFromAnchorCard = Vector2.zero;
            
            initiallyTouchedCard = null;
            touchStartScreenPos = Vector2.zero;
            
            if (isDraggingActive)
            {
                EndDragOperation();
            }
            else
            {
                LogInfo($"Touch ended without drag - just hovering, no card play", logTouchEvents);
            }
            
            isFanned = false;
            // Force immediate layout update to ensure all cards return to correct positions
            UpdateCardLayout(true);
            LogInfo("Touch ended - resetting layout from fanned to normal", logTouchEvents);
            
            // CRITICAL FIX: Force exit hover on any currently hovered card BEFORE clearing references
            if (hoveredCard != null)
            {
                LogInfo($"Force exiting hover on card: {hoveredCard.GetCardData()?.cardName}", logTouchEvents);
                hoveredCard.ForceExitHover();
                hoveredCard = null;
            }
            
            if (lastHoveredCard != null && lastHoveredCard != hoveredCard)
            {
                LogInfo($"Force exiting hover on lastHoveredCard: {lastHoveredCard.GetCardData()?.cardName}", logTouchEvents);
                lastHoveredCard.ForceExitHover();
                lastHoveredCard = null;
            }
            else if (lastHoveredCard != null)
            {
                LogInfo($"Clearing lastHoveredCard reference: {lastHoveredCard.GetCardData()?.cardName}", logTouchEvents);
                lastHoveredCard = null;
            }
            
            HideCardPreview();
            
            // CRITICAL FIX: Ensure ALL cards have hover disabled at touch end
            foreach (var cardObj in activeCardUIs)
            {
                if (cardObj != null)
                {
                    var cardUI = cardObj.GetComponent<CardUI>();
                    if (cardUI != null && cardUI.IsHovering())
                    {
                        LogInfo($"Force exiting hover on card during cleanup: {cardUI.GetCardData()?.cardName}", logTouchEvents);
                        cardUI.ForceExitHover();
                    }
                }
            }
            
            if (isParallaxActive)
            {
                isParallaxActive = false;
                AnimateHandToCenter();
            }
        }
        else if (isPlayingCard)
        {
            LogInfo($"Touch end BLOCKED by GUARD - card is already being played", logTouchEvents);
        }
        
        CardUI.SetTouchStartedOnValidArea(false);
        globalTouchActive = false;
        LogInfo("GLOBAL TOUCH INACTIVE - Hover events enabled again", logTouchEvents);
    }
    
    private CardUI GetCardAtPosition(Vector2 screenPosition)
    {
        PointerEventData pointerData = new PointerEventData(EventSystem.current)
        {
            position = screenPosition
        };
        
        List<RaycastResult> results = new List<RaycastResult>();
        EventSystem.current.RaycastAll(pointerData, results);
        
        LogInfo($"GetCardAtPosition - Raycast hits: {results.Count} at screen pos {screenPosition}", logTouchEvents && logCardPositions);
        if (logTouchEvents && logCardPositions)
        {
            foreach (var result in results)
            {
                LogInfo($"Raycast hit: {result.gameObject.name} at depth {result.depth}", true);
            }
        }
        
        // Card order debug entfernt
        
        CardUI bestCard = null;
        float closestDistance = float.MaxValue;
        int bestCardIndex = -1;
        
        foreach (var result in results)
        {
            CardUI cardUI = result.gameObject.GetComponent<CardUI>();
            if (cardUI != null && activeCardUIs.Contains(result.gameObject))
            {
                int cardIndex = activeCardUIs.IndexOf(result.gameObject);
                
                RectTransform cardRect = result.gameObject.GetComponent<RectTransform>();
                Vector2 localPoint;
                RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    cardRect, screenPosition, canvasCamera, out localPoint);
                
                Rect cardBounds = cardRect.rect;
                bool isInBounds = cardBounds.Contains(localPoint);
                
                float distance = localPoint.magnitude;
                
                string cardName = cardUI.GetCardData()?.cardName ?? "UNKNOWN";
                LogInfo($"Card '{cardName}' (index {cardIndex}): localPoint={localPoint}, inBounds={isInBounds}, distance={distance}", logTouchEvents && logCardPositions);
                
                if (isInBounds)
                {
                    int siblingIndex = result.gameObject.transform.GetSiblingIndex();
                    if (bestCard == null || siblingIndex > bestCard.transform.GetSiblingIndex())
                    {
                        closestDistance = distance;
                        bestCard = cardUI;
                        bestCardIndex = cardIndex;
                    }
                }
                else if (bestCard == null)
                {
                    if (distance < closestDistance)
                    {
                        closestDistance = distance;
                        bestCard = cardUI;
                        bestCardIndex = cardIndex;
                    }
                }
            }
        }
        
        if (bestCard != null)
        {
            string cardName = bestCard.GetCardData()?.cardName ?? "UNKNOWN";
            LogInfo($"GetCardAtPosition selected: '{cardName}' (index {bestCardIndex}) at distance {closestDistance}", logTouchEvents && logCardPositions);
        }
        else
        {
            LogInfo("GetCardAtPosition found no card at position", logTouchEvents && logCardPositions);
        }
        
        return bestCard;
    }
    
    private void UpdateCardSelectionAtPosition(Vector2 screenPosition)
    {
        if (isPlayingCard || isDraggingActive)
        {
            Debug.Log($"[HandController] UpdateCardSelectionAtPosition BLOCKED - card is being played or dragged (isPlayingCard={isPlayingCard}, isDraggingActive={isDraggingActive})");
            return;
        }
        
        if (initiallyTouchedCard != null && isTouching)
        {
            float movementDistance = Vector2.Distance(screenPosition, touchStartScreenPos);
            if (movementDistance < touchMovementThreshold)
            {
                if (hoveredCard != initiallyTouchedCard)
                {
                    Debug.Log($"[HandController] *** TOUCH LOCK ACTIVE *** Keeping initially touched card '{initiallyTouchedCard.GetCardData()?.cardName}' (movement: {movementDistance:F1}px < {touchMovementThreshold}px)");
                    
                    if (hoveredCard != null && hoveredCard != initiallyTouchedCard)
                    {
                        hoveredCard.ForceExitHover();
                    }
                    
                    hoveredCard = initiallyTouchedCard;
                    initiallyTouchedCard.ForceEnterHover();
                    lastHoveredCard = initiallyTouchedCard;
                    
                    UpdateCardPreview();
                    initialHoveredCard = initiallyTouchedCard;
                }
                return;
            }
            else if (movementDistance >= touchMovementThreshold && initiallyTouchedCard != null)
            {
                Debug.Log($"[HandController] *** TOUCH LOCK RELEASED *** Movement {movementDistance:F1}px exceeded threshold {touchMovementThreshold}px");
                initiallyTouchedCard = null;
            }
        }
        
        CardUI previousHovered = hoveredCard;
        
        PointerEventData pointerData = new PointerEventData(EventSystem.current)
        {
            position = screenPosition
        };
        
        List<RaycastResult> results = new List<RaycastResult>();
        EventSystem.current.RaycastAll(pointerData, results);
        
        CardUI newHoveredCard = null;
        float closestDistance = float.MaxValue;
        int bestSiblingIndex = -1;
        
        LogInfo($"UpdateCardSelectionAtPosition - Looking for card at {screenPosition}, {results.Count} raycast hits", logTouchEvents && logCardPositions);
        
        List<(CardUI card, float distance, int siblingIndex)> candidateCards = new List<(CardUI, float, int)>();
        
        foreach (var result in results)
        {
            CardUI cardUI = result.gameObject.GetComponent<CardUI>();
            if (cardUI != null && activeCardUIs.Contains(result.gameObject))
            {
                RectTransform cardRect = result.gameObject.GetComponent<RectTransform>();
                int cardIndex = activeCardUIs.IndexOf(result.gameObject);
                int siblingIndex = result.gameObject.transform.GetSiblingIndex();
                
                Vector2 localPoint;
                RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    cardRect, screenPosition, canvasCamera, out localPoint);
                
                Rect cardBounds = cardRect.rect;
                bool isInBounds = cardBounds.Contains(localPoint);
                
                float distance = localPoint.magnitude;
                
                string cardName = cardUI.GetCardData()?.cardName ?? "UNKNOWN";
                LogInfo($"Checking card '{cardName}' (index {cardIndex}, sibling {siblingIndex}): localPoint={localPoint}, inBounds={isInBounds}, distance={distance}", logTouchEvents && logCardPositions);
                
                if (isInBounds)
                {
                    candidateCards.Add((cardUI, distance, siblingIndex));
                }
            }
        }
        
        if (candidateCards.Count > 0)
        {
            candidateCards.Sort((a, b) => b.siblingIndex.CompareTo(a.siblingIndex));
            
            newHoveredCard = candidateCards[0].card;
            closestDistance = candidateCards[0].distance;
            bestSiblingIndex = candidateCards[0].siblingIndex;
            
            string selectedName = newHoveredCard.GetCardData()?.cardName ?? "UNKNOWN";
            LogInfo($"Selected topmost card: '{selectedName}' with sibling index {bestSiblingIndex}", logTouchEvents && logCardPositions);
        }
        else
        {
            foreach (var result in results)
            {
                CardUI cardUI = result.gameObject.GetComponent<CardUI>();
                if (cardUI != null && activeCardUIs.Contains(result.gameObject))
                {
                    RectTransform cardRect = result.gameObject.GetComponent<RectTransform>();
                    Vector2 localPoint;
                    RectTransformUtility.ScreenPointToLocalPointInRectangle(
                        cardRect, screenPosition, canvasCamera, out localPoint);
                    
                    float distance = localPoint.magnitude;
                    
                    if (cardUI == previousHovered)
                    {
                        distance *= 0.7f;
                    }
                    
                    if (distance < closestDistance)
                    {
                        closestDistance = distance;
                        newHoveredCard = cardUI;
                    }
                }
            }
            
            if (newHoveredCard != null)
            {
                string fallbackName = newHoveredCard.GetCardData()?.cardName ?? "UNKNOWN";
                LogInfo($"No card contains touch, using closest: '{fallbackName}' at distance {closestDistance}", logTouchEvents && logCardPositions);
            }
        }
        
        string previousCardName = previousHovered?.GetCardData()?.cardName ?? "none";
        string newCardName = newHoveredCard?.GetCardData()?.cardName ?? "none";
        bool shouldChangeHover = (newHoveredCard != previousHovered);
        
        // ENHANCED: Bessere Hysterese für alle Hover-Wechsel
        if (shouldChangeHover && previousHovered != null)
        {
            float movementSinceLastHover = Vector2.Distance(screenPosition, lastHoverPosition);
            float timeSinceLastHover = Time.time - lastHoverChangeTime;
            
            // Kombiniere Zeit und Distanz für bessere Hysterese
            // Blockiere schnelle Wechsel innerhalb von 100ms UND wenig Bewegung
            if (timeSinceLastHover < 0.1f && movementSinceLastHover < hoverHysteresisDistance)
            {
                LogInfo($"HYSTERESIS: Blocking hover change from '{previousCardName}' to '{newCardName}' (movement: {movementSinceLastHover:F1}px < {hoverHysteresisDistance}px, time: {timeSinceLastHover:F3}s)", logTouchEvents);
                shouldChangeHover = false;
            }
            
            // CRITICAL: Prüfe ob die vorherige Karte noch in einer Hover-Animation ist
            if (previousHovered.IsInHoverAnimation() && timeSinceLastHover < 0.2f)
            {
                LogInfo($"HYSTERESIS: Blocking hover change - previous card still animating", logTouchEvents);
                shouldChangeHover = false;
            }
        }
        
        if (newHoveredCard != previousHovered)
        {
            LogInfo($"HOVER DETECTION: '{previousCardName}' → '{newCardName}' (objects different: True, names different: {previousCardName != newCardName}, allowed: {shouldChangeHover})", logTouchEvents);
        }
        
        if (shouldChangeHover)
        {
            lastHoverChangeTime = Time.time;
            lastHoverPosition = screenPosition;
            
            if (previousHovered != null)
            {
                previousHovered.ForceExitHover();
            }
            
            hoveredCard = newHoveredCard;
            if (hoveredCard != null)
            {
                hoveredCard.ForceEnterHover();
                if (isTouching && !isPlayingCard)
                {
                    lastHoveredCard = hoveredCard;
                    Debug.Log($"[HandController] *** LAST HOVERED UPDATED *** Set lastHoveredCard to: '{lastHoveredCard.GetCardData()?.cardName}'");
                    NotifyLastHoveredCardChanged();
                }
                else
                {
                    Debug.Log($"[HandController] *** LAST HOVERED BLOCKED *** Not updating lastHoveredCard to '{hoveredCard.GetCardData()?.cardName}' - touching:{isTouching}, playing:{isPlayingCard}");
                }
            }
            
            UpdateCardPreview();
            
            string previousName = previousHovered != null ? previousHovered.GetCardData()?.cardName ?? "NULL" : "none";
            string newName = hoveredCard != null ? hoveredCard.GetCardData()?.cardName ?? "NULL" : "none";
            string lastHoveredName = lastHoveredCard != null ? lastHoveredCard.GetCardData()?.cardName ?? "NULL" : "none";
            Debug.Log($"[HandController] *** FINGER TRACKING *** Finger moved from '{previousName}' to '{newName}' (lastHovered: '{lastHoveredName}') at {screenPosition}");
            
            if (initialHoveredCard == null && hoveredCard != null && !hasChangedCards)
            {
                initialHoveredCard = hoveredCard;
                Debug.Log($"[HandController] *** INITIAL CARD SET *** First card touched: '{newName}' - using as drift reference");
            }
            else if (initialHoveredCard != null && hoveredCard != null && hoveredCard != initialHoveredCard && !hasChangedCards)
            {
                bool isDifferentCard = initialHoveredCard.gameObject != hoveredCard.gameObject;
                
                if (isDifferentCard)
                {
                    string initialCardName = initialHoveredCard.GetCardData()?.cardName ?? "NULL";
                    
                    int initialIndex = activeCardUIs.IndexOf(initialHoveredCard.gameObject);
                    int currentIndex = activeCardUIs.IndexOf(hoveredCard.gameObject);
                    Debug.Log($"[HandController] Card drift detected '{initialCardName}' → '{newName}' (but NOT blocking drag anymore)");
                }
            }
        }
    }
}
