// COMPLETE HAND SYSTEM FIX - HandController.cs
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections.Generic;
using System.Linq;

/// <summary>
/// Complete HandController implementation with robust card management
/// Fixes: Card removal, draw logic, fan layout, touch interactions
/// </summary>
public class HandController : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private Transform handContainer;
    [SerializeField] private GameObject cardUIPrefab;
    
    [Header("Layout Settings")]
    [SerializeField] private float cardSpacing = 80f;
    [SerializeField] private float fanSpacing = 150f;
    [SerializeField] private float fanAngle = 15f;
    [SerializeField] private float curveHeight = 30f;
    [SerializeField] private AnimationCurve fanCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);
    
    [Header("Touch Settings")]
    [SerializeField] private float hoverLift = 20f;
    [SerializeField] private bool enableFanning = true;
    
    // Card Management
    private List<CardUI> activeCards = new List<CardUI>();
    private CardUI hoveredCard = null;
    private CardUI draggedCard = null;
    private bool isFanned = false;
    private bool isTouching = false;
    
    // Player Reference
    private ZeitwaechterPlayer player;
    private Camera uiCamera;
    
    void Start()
    {
        Debug.Log("[HandController] Starting initialization");
        
        // Find player and camera
        player = ZeitwaechterPlayer.Instance;
        SetupCamera();
        
        if (player != null)
        {
            // Subscribe to hand changes ONLY
            player.OnHandChanged += RebuildHand;
            Debug.Log("[HandController] Subscribed to OnHandChanged");
        }
        else
        {
            Debug.LogError("[HandController] ZeitwaechterPlayer.Instance is NULL!");
        }
        
        // Initial hand display
        RebuildHand();
    }
    
    void Update()
    {
        HandleTouchInput();
    }
    
    #region Touch Input Handling
    
    private void HandleTouchInput()
    {
        if (!enableFanning) return;
        
        // Mobile touch
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);
            HandleTouchPhase(touch.position, touch.phase);
        }
        // Editor mouse
        else if (Application.isEditor)
        {
            if (Input.GetMouseButtonDown(0))
                HandleTouchPhase(Input.mousePosition, TouchPhase.Began);
            else if (Input.GetMouseButton(0) && isTouching)
                HandleTouchPhase(Input.mousePosition, TouchPhase.Moved);
            else if (Input.GetMouseButtonUp(0))
                HandleTouchPhase(Input.mousePosition, TouchPhase.Ended);
        }
    }
    
    private void HandleTouchPhase(Vector2 screenPos, TouchPhase phase)
    {
        switch (phase)
        {
            case TouchPhase.Began:
                if (IsPositionInHandArea(screenPos))
                {
                    isTouching = true;
                    isFanned = true;
                    UpdateHoverAtPosition(screenPos);
                    UpdateLayout(true); // Immediate fan
                }
                break;
                
            case TouchPhase.Moved:
                if (isTouching)
                {
                    UpdateHoverAtPosition(screenPos);
                }
                break;
                
            case TouchPhase.Ended:
            case TouchPhase.Canceled:
                if (isTouching)
                {
                    isTouching = false;
                    isFanned = false;
                    ClearHover();
                    UpdateLayout(); // Animated unfan
                }
                break;
        }
    }
    
    private bool IsPositionInHandArea(Vector2 screenPos)
    {
        if (handContainer == null) return false;
        
        RectTransform containerRect = handContainer.GetComponent<RectTransform>();
        Vector2 localPoint;
        
        bool hit = RectTransformUtility.ScreenPointToLocalPointInRectangle(
            containerRect, screenPos, uiCamera, out localPoint);
            
        if (!hit) return false;
        
        // Expand touch area slightly below container
        Rect expandedRect = containerRect.rect;
        expandedRect.yMin -= 50f;
        
        bool inArea = expandedRect.Contains(localPoint);
        Debug.Log($"[HandController] Touch at {screenPos} -> local {localPoint}, inArea: {inArea}");
        
        return inArea;
    }
    
    #endregion
    
    #region Hover Management
    
    private void UpdateHoverAtPosition(Vector2 screenPos)
    {
        CardUI newHovered = FindCardAtPosition(screenPos);
        
        if (newHovered != hoveredCard)
        {
            // Clear old hover
            if (hoveredCard != null)
            {
                hoveredCard.SetHovered(false);
            }
            
            // Set new hover
            hoveredCard = newHovered;
            if (hoveredCard != null)
            {
                hoveredCard.SetHovered(true);
            }
            
            Debug.Log($"[HandController] Hover changed to: {hoveredCard?.name ?? "none"}");
        }
    }
    
    private CardUI FindCardAtPosition(Vector2 screenPos)
    {
        // Use Unity's raycasting system for accurate detection
        PointerEventData pointerData = new PointerEventData(EventSystem.current)
        {
            position = screenPos
        };
        
        List<RaycastResult> results = new List<RaycastResult>();
        EventSystem.current.RaycastAll(pointerData, results);
        
        foreach (var result in results)
        {
            CardUI card = result.gameObject.GetComponent<CardUI>();
            if (card != null && activeCards.Contains(card))
            {
                return card;
            }
        }
        
        return null;
    }
    
    private void ClearHover()
    {
        if (hoveredCard != null)
        {
            hoveredCard.SetHovered(false);
            hoveredCard = null;
        }
    }
    
    #endregion
    
    #region Hand Management
    
    /// <summary>
    /// CRITICAL: Complete hand rebuild - called when player hand changes
    /// </summary>
    private void RebuildHand()
    {
        if (player == null)
        {
            Debug.LogError("[HandController] Player is null in RebuildHand!");
            return;
        }
        
        var playerHand = player.GetHand();
        Debug.Log($"[HandController] RebuildHand: Player has {playerHand.Count} cards, UI has {activeCards.Count} cards");
        
        // STEP 1: Destroy all existing UI cards
        DestroyAllCards();
        
        // STEP 2: Create new UI cards for current hand
        foreach (var cardData in playerHand)
        {
            CreateCard(cardData);
        }
        
        // STEP 3: Update layout
        UpdateLayout(true); // Immediate positioning
        
        Debug.Log($"[HandController] RebuildHand complete: Created {activeCards.Count} UI cards");
    }
    
    private void DestroyAllCards()
    {
        foreach (var card in activeCards)
        {
            if (card != null && card.gameObject != null)
            {
                Destroy(card.gameObject);
            }
        }
        
        activeCards.Clear();
        hoveredCard = null;
        draggedCard = null;
    }
    
    private void CreateCard(TimeCardData cardData)
    {
        if (cardUIPrefab == null || handContainer == null)
        {
            Debug.LogError("[HandController] Missing prefab or container!");
            return;
        }
        
        GameObject cardObj = Instantiate(cardUIPrefab, handContainer);
        CardUI cardUI = cardObj.GetComponent<CardUI>();
        
        if (cardUI != null)
        {
            // Initialize card with data and references
            cardUI.Initialize(cardData, this, uiCamera);
            cardUI.OnCardPlayed += HandleCardPlayed;
            
            activeCards.Add(cardUI);
            Debug.Log($"[HandController] Created card: {cardData.cardName}");
        }
        else
        {
            Debug.LogError($"[HandController] No CardUI component on {cardObj.name}!");
            Destroy(cardObj);
        }
    }
    
    #endregion
    
    #region Layout System
    
    /// <summary>
    /// Updates the visual layout of cards with proper fan curve
    /// </summary>
    public void UpdateLayout(bool immediate = false)
    {
        int cardCount = activeCards.Count;
        if (cardCount == 0) return;
        
        float spacing = isFanned ? fanSpacing : cardSpacing;
        float containerWidth = GetContainerWidth();
        
        // Calculate actual spacing based on container width
        float totalWidth = (cardCount - 1) * spacing;
        if (totalWidth > containerWidth * 0.9f && cardCount > 1)
        {
            spacing = (containerWidth * 0.9f) / (cardCount - 1);
        }
        
        float startX = -totalWidth * 0.5f;
        
        Debug.Log($"[HandController] UpdateLayout: {cardCount} cards, spacing: {spacing:F1}, fanned: {isFanned}");
        
        for (int i = 0; i < cardCount; i++)
        {
            if (activeCards[i] == null) continue;
            
            // Skip dragged card
            if (activeCards[i] == draggedCard) continue;
            
            // Calculate position
            float normalizedPos = cardCount > 1 ? (float)i / (cardCount - 1) : 0.5f;
            float x = startX + i * spacing;
            
            // Fan curve for Y position
            float curveValue = fanCurve.Evaluate(1f - Mathf.Abs(normalizedPos - 0.5f) * 2f);
            float y = curveValue * curveHeight;
            
            // Rotation only when NOT fanned
            float rotation = 0f;
            if (!isFanned && cardCount > 1)
            {
                rotation = Mathf.Lerp(-fanAngle, fanAngle, normalizedPos);
            }
            
            // Apply position and rotation
            PositionCard(activeCards[i], new Vector2(x, y), rotation, immediate);
        }
    }
    
    private void PositionCard(CardUI card, Vector2 position, float rotation, bool immediate)
    {
        RectTransform rectTransform = card.GetComponent<RectTransform>();
        if (rectTransform == null) return;
        
        Vector3 targetPos = new Vector3(position.x, position.y, 0);
        Vector3 targetRot = new Vector3(0, 0, rotation);
        
        if (immediate)
        {
            rectTransform.localPosition = targetPos;
            rectTransform.localEulerAngles = targetRot;
        }
        else
        {
            // Animate to position
            LeanTween.cancel(card.gameObject);
            LeanTween.moveLocal(card.gameObject, targetPos, 0.3f).setEase(LeanTweenType.easeOutCubic);
            LeanTween.rotateLocal(card.gameObject, targetRot, 0.3f).setEase(LeanTweenType.easeOutCubic);
        }
    }
    
    private float GetContainerWidth()
    {
        if (handContainer == null) return 800f;
        
        RectTransform rect = handContainer.GetComponent<RectTransform>();
        return rect != null ? Mathf.Abs(rect.rect.width) : 800f;
    }
    
    #endregion
    
    #region Card Events
    
    private void HandleCardPlayed(TimeCardData cardData)
    {
        Debug.Log($"[HandController] Card played: {cardData.cardName}");
        
        if (player != null)
        {
            // Tell player to play the card - this will trigger OnHandChanged
            bool success = player.PlayCard(cardData);
            if (!success)
            {
                Debug.LogWarning($"[HandController] Failed to play card: {cardData.cardName}");
            }
        }
    }
    
    #endregion
    
    #region Drag Support
    
    public CardUI GetHoveredCard()
    {
        return hoveredCard;
    }
    
    public bool CanDragCard(CardUI card)
    {
        return hoveredCard == card && activeCards.Contains(card);
    }
    
    public void StartDrag(CardUI card)
    {
        if (CanDragCard(card))
        {
            draggedCard = card;
            // Remove from layout temporarily
            UpdateLayout(true);
        }
    }
    
    public void EndDrag(CardUI card, bool wasPlayed)
    {
        if (draggedCard == card)
        {
            draggedCard = null;
            
            if (!wasPlayed)
            {
                // Return to hand
                UpdateLayout();
            }
        }
    }
    
    #endregion
    
    #region Setup
    
    private void SetupCamera()
    {
        Canvas canvas = GetComponentInParent<Canvas>();
        if (canvas != null)
        {
            if (canvas.renderMode == RenderMode.ScreenSpaceCamera)
            {
                uiCamera = canvas.worldCamera;
            }
            else if (canvas.renderMode == RenderMode.WorldSpace)
            {
                uiCamera = Camera.main;
            }
            // ScreenSpaceOverlay uses null camera
        }
        
        Debug.Log($"[HandController] UI Camera: {uiCamera?.name ?? "null (overlay)"}");
    }
    
    #endregion
    
    void OnDestroy()
    {
        if (player != null)
        {
            player.OnHandChanged -= RebuildHand;
        }
    }
}