// FIX: Fehlende Verbindung zwischen HandController und RiftCombatManager
// Diese Methode muss im HandController.cs hinzugefügt oder angepasst werden

// OPTION 1: Integration in das zentrale Drag-System
// Füge diese Methode dem HandController hinzu oder passe die bestehende HandleCentralDragEnd an:

private void HandleCentralDragEnd(CardUI draggedCardUI, Vector2 dropPosition)
{
    // Prüfe ob im Spielbereich gedroppt wurde
    float playAreaY = Screen.height * 0.5f; // Obere Hälfte des Bildschirms
    bool dropSuccessful = dropPosition.y > playAreaY;
    
    if (dropSuccessful && draggedCardUI != null)
    {
        TimeCardData cardData = draggedCardUI.GetCardData();
        if (cardData != null)
        {
            Debug.Log($"[HandController] Karte '{cardData.cardName}' erfolgreich im Spielbereich gedroppt!");
            
            // KRITISCH: Diese Verbindung fehlt aktuell!
            // Informiere den RiftCombatManager über die gespielte Karte
            if (RiftCombatManager.Instance != null && ZeitwaechterPlayer.Instance != null)
            {
                RiftCombatManager.Instance.PlayerWantsToPlayCard(cardData, ZeitwaechterPlayer.Instance);
                Debug.Log($"[HandController] RiftCombatManager informiert über gespielte Karte: {cardData.cardName}");
            }
            else
            {
                Debug.LogError("[HandController] RiftCombatManager oder ZeitwaechterPlayer Instance ist NULL!");
            }
            
            // Play-Animation für die Karte
            // draggedCardUI.PlayCardAnimation(); // Falls implementiert
        }
    }
    else
    {
        Debug.Log("[HandController] Karte wurde zurück zur Hand gedroppt");
        // Return-Animation zur Hand
    }
}

// OPTION 2: Alternative über CardUI Click-Event
// Falls das zentrale Drag-System zu komplex ist, kann auch das Click-Event verwendet werden:

private void HandleCardClick(TimeCardData cardData)
{
    if (cardData == null) 
    {
        Debug.LogError("[HandController] HandleCardClick: cardData ist NULL!");
        return;
    }
    
    Debug.Log($"[HandController] Karte '{cardData.cardName}' wurde geklickt");
    
    // Verbindung zum RiftCombatManager
    if (RiftCombatManager.Instance != null && ZeitwaechterPlayer.Instance != null)
    {
        RiftCombatManager.Instance.PlayerWantsToPlayCard(cardData, ZeitwaechterPlayer.Instance);
        Debug.Log($"[HandController] RiftCombatManager informiert über gespielte Karte: {cardData.cardName}");
    }
    else
    {
        Debug.LogError("[HandController] RiftCombatManager oder ZeitwaechterPlayer Instance ist NULL!");
    }
}

// OPTION 3: Integration in bestehende OnCardDropped Methode (falls vorhanden)
// Suche nach einer Methode die beim Karten-Drop aufgerufen wird und füge dort ein:

// In der Drop-Handler-Methode:
if (dropInPlayArea)
{
    CardUI cardUI = draggedCard.GetComponent<CardUI>();
    if (cardUI != null && cardUI.GetCardData() != null)
    {
        // DIESE ZEILE FEHLT:
        RiftCombatManager.Instance.PlayerWantsToPlayCard(
            cardUI.GetCardData(), 
            ZeitwaechterPlayer.Instance
        );
    }
}

// WICHTIG: Die gewählte Option hängt davon ab, wie das zentrale Drag-System
// im aktuellen HandController implementiert ist. 
// Die Referenz-Implementierung in HandController.cs.fix zeigt Option 2 (Click-Event).