using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

/// <summary>
/// TEIL 3/4: Drag&Drop Operationen und Karten-Layout
/// </summary>
public partial class HandController : MonoBehaviour
{
    private void StartDragOperation()
    {
        CardUI cardToDrag = hoveredCard ?? lastHoveredCard;
        
        if (cardToDrag == null && initialHoveredCard != null)
        {
            cardToDrag = initialHoveredCard;
            Debug.LogWarning($"[HandController] StartDragOperation - using initialHoveredCard as fallback: {cardToDrag.GetCardData()?.cardName}");
        }
        
        if (cardToDrag == null)
        {
            Debug.LogError("[HandController] StartDragOperation - no card to drag (hoveredCard, lastHoveredCard, and initialHoveredCard all null!)");
            return;
        }
        
        if (!cardToDrag.GetCardData() || !IsCardPlayable(cardToDrag.GetCardData()))
        {
            Debug.Log($"[HandController] StartDragOperation - card {cardToDrag.GetCardData()?.cardName} not playable");
            return;
        }
        
        isDraggingActive = true;
        draggedCardUI = cardToDrag;
        draggedCard = cardToDrag.gameObject;
        
        Debug.Log($"[HandController] ✓ DRAG STARTED for card: {cardToDrag.GetCardData()?.cardName}");
        
        // Fanning beenden beim Drag-Start
        if (isFanned)
        {
            Debug.Log($"[HandController] Closing fan due to drag start");
            isFanned = false;
        }
        
        cardToDrag.OnCentralDragStart();
        RemoveCardForDrag(cardToDrag.gameObject);
        DisableAllHoverEffects();
        
        HideCardPreview();
        isParallaxActive = false;
        CenterHandAfterDragStart();
        
        cardToDrag.transform.SetAsLastSibling();
        LeanTween.rotateLocal(cardToDrag.gameObject, Vector3.zero, 0.08f).setEase(LeanTweenType.easeOutExpo);
    }
    
    private void MoveDraggedCardToPosition(Vector2 screenPosition)
    {
        if (draggedCardUI == null) return;
        
        foreach (var cardObj in activeCardUIs)
        {
            if (cardObj != null && cardObj != draggedCard)
            {
                var cardUI = cardObj.GetComponent<CardUI>();
                if (cardUI != null && cardUI.gameObject != draggedCardUI.gameObject)
                {
                    cardUI.ForceDisableHover();
                }
            }
        }
        
        Vector3 worldPoint;
        RectTransformUtility.ScreenPointToWorldPointInRectangle(
            draggedCardUI.transform.parent as RectTransform,
            screenPosition,
            canvasCamera,
            out worldPoint
        );
        
        draggedCardUI.transform.position = worldPoint;
        
        float screenHeight = Screen.height;
        float playZoneY = screenHeight * 0.5f;
        
        if (screenPosition.y > playZoneY)
        {
            draggedCardUI.transform.localScale = Vector3.one * 1.2f;
        }
        else
        {
            draggedCardUI.transform.localScale = Vector3.one * 1.1f;
        }
    }
    
    private void EndDragOperation()
    {
        if (!isDraggingActive || draggedCardUI == null)
        {
            Debug.Log("[HandController] EndDragOperation - no active drag");
            return;
        }
        
        RiftEnemy targetEnemy = GetEnemyUnderDragPosition();
        TimeCardData cardData = draggedCardUI.GetCardData();
        
        Debug.Log($"[HandController] EndDragOperation - targetEnemy: {(targetEnemy != null ? targetEnemy.name : "NULL")}, lastDragPosition: {lastDragPosition}");
        
        if (targetEnemy != null)
        {
            Debug.Log($"[HandController] *** DRAG-AND-DROP *** Card {cardData.cardName} dropped on enemy: {targetEnemy.name}");
            PlayDraggedCardOnTarget(targetEnemy);
        }
        else
        {
            float screenHeight = Screen.height;
            float playZoneY = screenHeight * 0.5f;
            
            if (lastDragPosition.y > playZoneY)
            {
                Debug.Log($"[HandController] Playing dragged card in play zone: {draggedCardUI.GetCardData()?.cardName}");
                PlayDraggedCard();
            }
            else
            {
                Debug.Log($"[HandController] Returning dragged card to hand: {draggedCardUI.GetCardData()?.cardName}");
                ReturnDraggedCardToHand();
            }
        }
        
        isDraggingActive = false;
        draggedCardUI = null;
        draggedCard = null;
        draggedCardOriginalIndex = -1; // Reset index nach Drag-Ende
        
        EnableAllHoverEffects();
    }
    
    private void PlayDraggedCard()
    {
        if (draggedCardUI == null) return;
        
        isPlayingCard = true;
        TimeCardData cardData = draggedCardUI.GetCardData();
        
        Debug.Log($"[HandController] *** CENTRALIZED CARD PLAY *** Playing: {cardData?.cardName}");
        Debug.Log($"[HandController] Card requiresTarget: {cardData.requiresTarget}, cardType: {cardData.cardType}");
        
        if (cardData.cardType == TimeCardType.Attack && RiftCombatManager.Instance != null)
        {
            var activeEnemies = RiftCombatManager.Instance.GetActiveEnemies();
            RiftEnemy target = null;
            
            foreach (var enemy in activeEnemies)
            {
                if (enemy != null && !enemy.IsDead())
                {
                    target = enemy;
                    break;
                }
            }
            
            Debug.Log($"[HandController] Attack card - found target: {(target != null ? target.name : "NULL")} (from {activeEnemies.Count} active enemies)");
            
            if (target != null)
            {
                if (ZeitwaechterPlayer.Instance != null)
                {
                    if (RiftTimeSystem.Instance.TryPlayCard(cardData.GetScaledTimeCost()))
                    {
                        Debug.Log($"[HandController] *** DIRECT ATTACK *** {cardData.cardName} → {target.name}");
                        
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
                        else
                        {
                            Debug.LogError($"[HandController] Failed to remove card {cardData.cardName} from player hand");
                            ReturnDraggedCardToHand();
                        }
                    }
                    else
                    {
                        Debug.Log($"[HandController] Not enough time to play {cardData.cardName}");
                        ReturnDraggedCardToHand();
                    }
                }
            }
            else
            {
                Debug.Log("[HandController] No valid target for attack card - returning to hand");
                ReturnDraggedCardToHand();
            }
        }
        else
        {
            Debug.Log($"[HandController] Non-attack card or no targeting needed: {cardData.cardName}");
            
            if (RiftCombatManager.Instance != null)
            {
                RiftCombatManager.Instance.PlayerWantsToPlayCard(cardData, player);
                
                if (activeCardUIs.Contains(draggedCardUI.gameObject))
                {
                    activeCardUIs.Remove(draggedCardUI.gameObject);
                }
                Destroy(draggedCardUI.gameObject);
            }
        }
        
        StartCoroutine(ResetPlayingCardFlag());
    }
    
    public void UpdateCardLayout(bool forceImmediate = false, bool isFromCardCreation = false, CardUI anchorCard = null)
    {
        // NEU: Verwende das Arc-basierte Layout-System
        UpdateCardLayoutArc(forceImmediate, isFromCardCreation, anchorCard);
    }
    
    public void DisableAllHoverEffects()
    {
        Debug.Log($"[HandController] *** DISABLING ALL HOVER EFFECTS *** Drag is active, preventing hover on all cards except dragged card");
        
        foreach (var cardObj in activeCardUIs)
        {
            if (cardObj != null && cardObj != draggedCard)
            {
                var cardUI = cardObj.GetComponent<CardUI>();
                if (cardUI != null)
                {
                    string cardName = cardUI.GetCardData()?.cardName ?? "Unknown";
                    Debug.Log($"[HandController] Force disabling hover on card: {cardName}");
                    cardUI.ForceDisableHover();
                }
            }
        }
    }
    
    public void EnableAllHoverEffects()
    {
        Debug.Log($"[HandController] *** RE-ENABLING ALL HOVER EFFECTS *** Drag ended, restoring normal hover behavior");
        
        foreach (var cardObj in activeCardUIs)
        {
            if (cardObj != null)
            {
                var cardUI = cardObj.GetComponent<CardUI>();
                if (cardUI != null)
                {
                    string cardName = cardUI.GetCardData()?.cardName ?? "Unknown";
                    Debug.Log($"[HandController] Re-enabling hover on card: {cardName}");
                    cardUI.EnableHover();
                }
            }
        }
    }
    
    private int draggedCardOriginalIndex = -1;
    
    public void RemoveCardForDrag(GameObject card)
    {
        draggedCard = card;
        // WICHTIG: Index speichern BEVOR wir die Karte entfernen!
        draggedCardOriginalIndex = activeCardUIs.IndexOf(card);
        activeCardUIs.Remove(card);
        // Beim Drag das Fanning beibehalten
        UpdateCardLayout(true, false, null);
    }
    
    public void AddCardBackToHand(GameObject card)
    {
        Debug.Log($"[HandController] AddCardBackToHand - Processing card: {card?.name}");
        
        if (!activeCardUIs.Contains(card))
        {
            // KRITISCH: Karte an der ursprünglichen Position einfügen!
            if (draggedCardOriginalIndex >= 0 && draggedCardOriginalIndex <= activeCardUIs.Count)
            {
                activeCardUIs.Insert(draggedCardOriginalIndex, card);
                Debug.Log($"[HandController] Inserted card back at original index: {draggedCardOriginalIndex}");
            }
            else
            {
                // Fallback: Am Ende hinzufügen
                activeCardUIs.Add(card);
                Debug.Log($"[HandController] Added card at end (original index invalid: {draggedCardOriginalIndex})");
            }
        }
        else
        {
            Debug.Log($"[HandController] Card already in activeCardUIs list");
        }
        
        draggedCard = null;
        draggedCardOriginalIndex = -1; // Reset index
        
        LeanTween.cancel(card);
        
        card.transform.SetParent(handContainer, false);
        card.transform.localScale = Vector3.one;
        card.transform.localRotation = Quaternion.identity;
        
        // ENTFERNT: Sort zerstört die Synchronisation mit player.hand!
        // Die Reihenfolge in activeCardUIs MUSS mit player.hand übereinstimmen!
        /*
        activeCardUIs.Sort((a, b) => 
        {
            if (a == null || b == null) return 0;
            float xA = a.GetComponent<RectTransform>().anchoredPosition.x;
            float xB = b.GetComponent<RectTransform>().anchoredPosition.x;
            return xA.CompareTo(xB);
        });
        */
        
        Debug.Log($"[HandController] Calling UpdateCardLayout for card return - force immediate");
        
        isFanned = false;
        isTouching = false;
        
        UpdateCardLayout(true);
        
        Debug.Log($"[HandController] AddCardBackToHand completed successfully");
    }
}
