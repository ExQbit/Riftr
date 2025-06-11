// TEMPORARY FILE - These methods need to be added to HandController.cs

// Add these fields to the private section:
private CardUI currentlySelectedCard = null;
private bool isSelectingCard = false;

// Replace the existing HandleTouchInput method:
private void HandleTouchInput()
{
    // Mobile Touch
    if (Input.touchCount > 0)
    {
        Touch touch = Input.GetTouch(0);
        
        if (touch.phase == TouchPhase.Began)
        {
            HandleTouchStart(touch.position);
        }
        else if (touch.phase == TouchPhase.Moved && isSelectingCard)
        {
            // Update Kartenauswahl basierend auf aktueller Touch-Position
            UpdateCardSelectionAtPosition(touch.position);
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
            HandleTouchStart(Input.mousePosition);
        }
        else if (Input.GetMouseButton(0) && isSelectingCard)
        {
            // Update Kartenauswahl basierend auf aktueller Mouse-Position
            UpdateCardSelectionAtPosition(Input.mousePosition);
        }
        else if (Input.GetMouseButtonUp(0))
        {
            HandleTouchEnd();
        }
    }
}

// Add these new methods:
private void UpdateCardSelectionAtPosition(Vector2 screenPosition)
{
    if (!isSelectingCard) return;
    
    CardUI closestCard = null;
    float closestDistance = float.MaxValue;
    
    // Finde die nächste Karte zur Touch-Position
    foreach (var cardUI in activeCardUIs)
    {
        if (cardUI == null) continue;
        
        RectTransform cardRect = cardUI.GetComponent<RectTransform>();
        if (cardRect == null) continue;
        
        // Konvertiere Karten-Position zu Screen-Position
        Vector3 cardScreenPos = RectTransformUtility.WorldToScreenPoint(
            Camera.main, cardRect.position);
        
        // Berechne Distanz zur Touch-Position
        float distance = Vector2.Distance(screenPosition, new Vector2(cardScreenPos.x, cardScreenPos.y));
        
        if (distance < closestDistance)
        {
            closestDistance = distance;
            closestCard = cardUI.GetComponent<CardUI>();
        }
    }
    
    // Update Selektion
    if (closestCard != currentlySelectedCard)
    {
        // Deselektiere vorherige Karte
        if (currentlySelectedCard != null)
        {
            currentlySelectedCard.SetDynamicSelection(false);
        }
        
        // Selektiere neue Karte
        currentlySelectedCard = closestCard;
        if (currentlySelectedCard != null)
        {
            currentlySelectedCard.SetDynamicSelection(true);
            Debug.Log($"[HandController] Selected card: {currentlySelectedCard.GetCardData()?.cardName}");
        }
    }
}

public CardUI GetCurrentlySelectedCard()
{
    return currentlySelectedCard;
}

// Update HandleTouchStart to include card selection:
// Add after isFanned = true; lastTouchPosition = position;
isSelectingCard = true;
UpdateCardSelectionAtPosition(position);

// Update HandleTouchEnd to include card deselection:
// Add after isFanned = false;
isSelectingCard = false;
if (currentlySelectedCard != null)
{
    currentlySelectedCard.SetDynamicSelection(false);
    currentlySelectedCard = null;
}