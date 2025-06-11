// KOMPLETTE ÜBERARBEITUNG des HandController.cs - Ersetze die gesamte Datei mit diesem Code

using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections.Generic;
using System.Collections;

/// <summary>
/// Verwaltet die Kartenhand-UI mit korrektem Touch-basierten Drag&Drop
/// </summary>
public class HandController : MonoBehaviour
{
    [Header("Referenzen")]
    [SerializeField] private Transform handContainer;
    [SerializeField] private GameObject cardUIPrefab;
    
    [Header("Layout-Einstellungen")]
    [SerializeField] public float cardSpacing = 80f; // Basis-Abstand zwischen Karten
    [SerializeField] public float maxCardWidth = 120f; // Maximale Breite einer Karte
    [SerializeField] public float fanAngle = 25f; // Maximaler Winkel für Fächer-Effekt
    [SerializeField] public float curveHeight = 50f; // Höhe der Bogen-Kurve
    [SerializeField] public float hoverLift = 20f; // Anhebung bei Hover
    [SerializeField] public AnimationCurve layoutCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);
    [SerializeField] public bool invertFanAngle = true; // Kehrt die Fächer-Richtung um
    [SerializeField] public float curveSmoothing = 0.8f; // Glättungsfaktor für weicheren Bogen
    
    [Header("Touch-Einstellungen")]
    [SerializeField] public bool enableFanning = true; // Auffächern bei Touch 
    [SerializeField] public float fanSpacing = 150f; // Abstand beim Auffächern
    [SerializeField] public float touchDetectionRadius = 100f; // Radius für Touch-Detection
    
    [Header("Animation-Einstellungen (NEUE FELDER)")]
    [SerializeField] public float layoutAnimationDuration = 0.2f; // Schnellere Layout-Animation
    [SerializeField] public LeanTweenType layoutEaseType = LeanTweenType.easeOutCubic; // Snappier Easing
    [SerializeField] public float fanAnimationDuration = 0.15f; // Sehr schnelles Auffächern
    [SerializeField] public LeanTweenType fanEaseType = LeanTweenType.easeOutExpo; // Extra snappy für Fan
    
    // Aktive Karten-UI-Elemente
    private List<GameObject> activeCardUIs = new List<GameObject>();
    private bool isFanned = false;
    private bool isTouching = false;
    
    // Touch-Tracking für dynamische Kartenauswahl
    private Vector2 lastTouchPosition;
    private CardUI currentlyHoveredCard = null; // Karte unter dem Finger beim Fanning
    private CardUI draggedCard = null; // Tatsächlich gezogene Karte
    private bool isDraggingCard = false;
    
    // Referenz zum Spieler
    private ZeitwaechterPlayer player;
    
    // Layout-Update-Queue für smooth transitions
    private Coroutine layoutUpdateCoroutine;
    
    void Start()
    {
        player = ZeitwaechterPlayer.Instance;
        
        if (player != null)
        {
            // Instanz-Event abonnieren
            player.OnHandChanged += UpdateHandDisplay;
            
            // Statische Events abonnieren
            ZeitwaechterPlayer.OnCardDrawn += AddCardToHand;
            ZeitwaechterPlayer.OnCardPlayed += RemoveCardFromHand;
        }
        
        // Initial Hand anzeigen
        UpdateHandDisplay();
    }
    
    void Update()
    {
        // Nur Touch-Input verarbeiten wenn Fanning aktiviert ist
        if (enableFanning)
        {
            HandleTouchInput();
        }
    }
    
    /// <summary>
    /// Handle Touch-Input für Auffächern und dynamische Kartenauswahl
    /// </summary>
    private void HandleTouchInput()
    {
        // Mobile Touch
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);
            
            switch (touch.phase)
            {
                case TouchPhase.Began:
                    HandleTouchStart(touch.position);
                    break;
                case TouchPhase.Moved:
                    HandleTouchMove(touch.position);
                    break;
                case TouchPhase.Ended:
                case TouchPhase.Canceled:
                    HandleTouchEnd();
                    break;
            }
        }
        // Mouse (für Editor-Testing)
        else
        {
            if (Input.GetMouseButtonDown(0))
            {
                HandleTouchStart(Input.mousePosition);
            }
            else if (Input.GetMouseButton(0))
            {
                HandleTouchMove(Input.mousePosition);
            }
            else if (Input.GetMouseButtonUp(0))
            {
                HandleTouchEnd();
            }
        }
    }
    
    /// <summary>
    /// Touch/Click beginnt
    /// </summary>
    private void HandleTouchStart(Vector2 position)
    {
        // Prüfe ob Touch im Handkarten-Bereich ist
        RectTransform rect = handContainer.GetComponent<RectTransform>();
        
        // WICHTIG: Verwende die korrekte Camera für UI-Raycast
        Camera uiCamera = null;
        Canvas canvas = handContainer.GetComponentInParent<Canvas>();
        if (canvas != null && canvas.renderMode != RenderMode.ScreenSpaceOverlay)
        {
            uiCamera = canvas.worldCamera;
        }
        
        Vector2 localPoint;
        if (RectTransformUtility.ScreenPointToLocalPointInRectangle(
            rect, position, uiCamera, out localPoint))
        {
            // Erweitere den Touch-Bereich etwas nach unten für bessere Mobile-Bedienung
            Rect expandedRect = rect.rect;
            expandedRect.yMin -= 50f; // 50 Pixel mehr nach unten
            
            if (expandedRect.Contains(localPoint))
            {
                Debug.Log($"[HandController] Touch detected at local point: {localPoint}");
                isTouching = true;
                isFanned = true;
                lastTouchPosition = position;
                
                // Informiere alle Karten dass ein gültiger Touch begonnen hat
                CardUI.SetTouchStartedInHandArea(true);
                
                // Finde die Karte unter dem Touch
                UpdateHoveredCard(position);
                
                UpdateHandLayout();
            }
            else
            {
                // Touch außerhalb des gültigen Bereichs
                CardUI.SetTouchStartedInHandArea(false);
            }
        }
        else
        {
            // Touch außerhalb des gültigen Bereichs
            CardUI.SetTouchStartedInHandArea(false);
        }
    }
    
    /// <summary>
    /// Touch/Click bewegt sich
    /// </summary>
    private void HandleTouchMove(Vector2 position)
    {
        if (!isTouching) return;
        
        lastTouchPosition = position;
        
        // Update welche Karte unter dem Finger ist
        UpdateHoveredCard(position);
    }
    
    /// <summary>
    /// Touch/Click endet
    /// </summary>
    private void HandleTouchEnd()
    {
        if (isTouching)
        {
            isTouching = false;
            isFanned = false;
            
            // Deselektiere hover
            if (currentlyHoveredCard != null)
            {
                currentlyHoveredCard.SetHovered(false);
                currentlyHoveredCard = null;
            }
            
            UpdateHandLayout();
        }
        
        // Reset Touch-Status
        CardUI.SetTouchStartedInHandArea(false);
    }
    
    /// <summary>
    /// Bestimmt welche Karte unter der aktuellen Touch-Position ist
    /// </summary>
    private void UpdateHoveredCard(Vector2 screenPosition)
    {
        CardUI closestCard = null;
        float closestDistance = float.MaxValue;
        
        // Finde die nächste Karte zur Touch-Position
        foreach (var cardUI in activeCardUIs)
        {
            if (cardUI == null) continue;
            
            var cardComponent = cardUI.GetComponent<CardUI>();
            if (cardComponent == null || cardComponent.IsDragging()) continue; // Skip dragging cards
            
            RectTransform cardRect = cardUI.GetComponent<RectTransform>();
            if (cardRect == null) continue;
            
            // Konvertiere Karten-Position zu Screen-Position
            Camera cam = null;
            Canvas canvas = cardRect.GetComponentInParent<Canvas>();
            if (canvas != null && canvas.renderMode != RenderMode.ScreenSpaceOverlay)
            {
                cam = canvas.worldCamera;
            }
            
            Vector3 cardScreenPos = RectTransformUtility.WorldToScreenPoint(cam, cardRect.position);
            
            // Berechne Distanz zur Touch-Position
            float distance = Vector2.Distance(screenPosition, new Vector2(cardScreenPos.x, cardScreenPos.y));
            
            if (distance < touchDetectionRadius && distance < closestDistance)
            {
                closestDistance = distance;
                closestCard = cardComponent;
            }
        }
        
        // Update Hover-Status
        if (closestCard != currentlyHoveredCard)
        {
            // Deselektiere vorherige Karte
            if (currentlyHoveredCard != null)
            {
                currentlyHoveredCard.SetHovered(false);
            }
            
            // Selektiere neue Karte
            currentlyHoveredCard = closestCard;
            if (currentlyHoveredCard != null)
            {
                currentlyHoveredCard.SetHovered(true);
                Debug.Log($"[HandController] Hovering over: {currentlyHoveredCard.GetCardData()?.cardName}");
            }
        }
    }
    
    /// <summary>
    /// Wird von CardUI aufgerufen wenn eine Karte zu draggen beginnt
    /// </summary>
    public void OnCardStartDrag(CardUI card)
    {
        if (draggedCard != null && draggedCard != card)
        {
            Debug.LogWarning("[HandController] Already dragging a card!");
            return;
        }
        
        draggedCard = card;
        isDraggingCard = true;
        
        // Die gedraggte Karte sollte die sein, die gerade gehovered wird
        if (currentlyHoveredCard != null && currentlyHoveredCard == card)
        {
            Debug.Log($"[HandController] Started dragging hovered card: {card.GetCardData()?.cardName}");
        }
        else
        {
            Debug.LogWarning($"[HandController] Dragging card that wasn't hovered: {card.GetCardData()?.cardName}");
        }
    }
    
    /// <summary>
    /// Wird von CardUI aufgerufen wenn Drag endet
    /// </summary>
    public void OnCardEndDrag(CardUI card)
    {
        if (draggedCard == card)
        {
            draggedCard = null;
            isDraggingCard = false;
            
            // Sofortiges Layout-Update für saubere Rückkehr
            UpdateHandLayout(true);
        }
    }
    
    /// <summary>
    /// Aktualisiert die Kartenhand-Anzeige
    /// </summary>
    public void UpdateHandDisplay()
    {
        if (player == null) return;
        
        // Hole aktuelle Hand
        var cards = player.GetHand();
        
        // Entferne alte Karten
        foreach (var card in activeCardUIs)
        {
            if (card != null)
                Destroy(card);
        }
        activeCardUIs.Clear();
        
        // Erstelle neue Karten
        foreach (var card in cards)
        {
            CreateCardUI(card);
        }
        
        // Layout aktualisieren
        UpdateHandLayout(true); // Force immediate
    }
    
    /// <summary>
    /// Erstellt ein UI-Element für eine Karte
    /// </summary>
    private GameObject CreateCardUI(TimeCardData cardData)
    {
        if (handContainer == null || cardUIPrefab == null) return null;
        
        // Instanziiere Karten-UI
        GameObject cardUI = Instantiate(cardUIPrefab, handContainer);
        
        // Setze Karten-Daten
        CardUI cardUIComponent = cardUI.GetComponent<CardUI>();
        if (cardUIComponent != null)
        {
            cardUIComponent.SetCardData(cardData);
            cardUIComponent.SetHandController(this);
            cardUIComponent.OnCardClicked += HandleCardClick;
        }
        
        // Füge zur aktiven Liste hinzu
        activeCardUIs.Add(cardUI);
        
        return cardUI;
    }
    
    /// <summary>
    /// Aktualisiert das Layout der Kartenhand
    /// </summary>
    public void UpdateHandLayout(bool immediate = false)
    {
        if (layoutUpdateCoroutine != null)
        {
            StopCoroutine(layoutUpdateCoroutine);
        }
        
        if (immediate || !Application.isPlaying)
        {
            DoUpdateLayout();
        }
        else
        {
            layoutUpdateCoroutine = StartCoroutine(DelayedUpdateLayout());
        }
    }
    
    /// <summary>
    /// Verzögertes Layout-Update für smooth transitions
    /// </summary>
    private IEnumerator DelayedUpdateLayout()
    {
        // Warte einen Frame für Transform-Updates
        yield return null;
        DoUpdateLayout();
        layoutUpdateCoroutine = null;
    }
    
    /// <summary>
    /// Führt das eigentliche Layout-Update durch
    /// </summary>
    private void DoUpdateLayout()
    {
        int cardCount = activeCardUIs.Count;
        if (cardCount == 0) return;
        
        // Berechne Gesamtbreite der Hand
        float totalWidth = (isFanned && isTouching) ? 
            fanSpacing * (cardCount - 1) : 
            Mathf.Min(cardSpacing * (cardCount - 1), maxCardWidth * cardCount);
        
        // Startposition (zentriert)
        float startX = -totalWidth / 2f;
        
        // Positioniere jede Karte
        for (int i = 0; i < cardCount; i++)
        {
            GameObject card = activeCardUIs[i];
            if (card == null) continue;
            
            var cardComponent = card.GetComponent<CardUI>();
            bool isThisCardDragging = cardComponent != null && cardComponent.IsDragging();
            
            // Skip positioning for dragging cards
            if (isThisCardDragging) continue;
            
            // Berechne Position basierend auf Kurve und Fächer
            float normalizedPosition = cardCount > 1 ? (float)i / (cardCount - 1) : 0.5f;
            float curveValue = layoutCurve.Evaluate(normalizedPosition);
            
            // Verbesserte Kurvenberechnung mit Glättung
            float sinCurve = Mathf.Sin(normalizedPosition * Mathf.PI);
            float animCurve = curveValue;
            float blendedCurve = Mathf.Lerp(animCurve, sinCurve, curveSmoothing);
            float curveOffset = blendedCurve * curveHeight;
            
            // Subtile Edge-Lift
            float edgeFactor = 1f - Mathf.Abs(2f * normalizedPosition - 1f);
            float edgeLift = (1f - edgeFactor) * curveHeight * 0.15f;
            curveOffset += edgeLift;
            
            // X-Position mit Abstand
            float xPos = startX + ((isFanned && isTouching) ? fanSpacing * i : cardSpacing * i);
            
            // Rotation für Fächer-Effekt
            float angle = 0f;
            if (cardCount > 1)
            {
                angle = Mathf.Lerp(-fanAngle, fanAngle, normalizedPosition);
                if (invertFanAngle) angle = -angle;
            }
            
            // Setze Position und Rotation mit Animation
            Vector3 targetPosition = new Vector3(xPos, curveOffset, 0);
            Quaternion targetRotation = Quaternion.Euler(0, 0, angle);
            
            // Prüfe ob dies eine neue Position ist
            bool shouldAnimate = Vector3.Distance(card.transform.localPosition, targetPosition) > 0.1f ||
                               Quaternion.Angle(card.transform.localRotation, targetRotation) > 1f;
            
            if (shouldAnimate && Application.isPlaying)
            {
                float animDuration = (isFanned && isTouching) ? fanAnimationDuration : layoutAnimationDuration;
                LeanTweenType easeType = (isFanned && isTouching) ? fanEaseType : layoutEaseType;
                
                LeanTween.cancel(card);
                LeanTween.moveLocal(card, targetPosition, animDuration).setEase(easeType);
                LeanTween.rotateLocal(card, targetRotation.eulerAngles, animDuration).setEase(easeType);
            }
            else
            {
                card.transform.localPosition = targetPosition;
                card.transform.localRotation = targetRotation;
            }
            
            // Setze korrekte Sibling-Order
            card.transform.SetSiblingIndex(i);
        }
    }
    
    /// <summary>
    /// Karte wurde angeklickt
    /// </summary>
    private void HandleCardClick(TimeCardData cardData)
    {
        if (player != null && RiftCombatManager.Instance != null)
        {
            // Versuche Karte zu spielen
            RiftCombatManager.Instance.PlayerWantsToPlayCard(cardData, player);
        }
    }
    
    /// <summary>
    /// Fügt eine Karte zur Hand hinzu (mit Animation)
    /// </summary>
    private void AddCardToHand(TimeCardData cardData)
    {
        GameObject newCard = CreateCardUI(cardData);
        
        if (newCard != null)
        {
            // Start-Animation
            newCard.transform.localScale = Vector3.zero;
            newCard.transform.localPosition = new Vector3(0, -100, 0);
            
            // Animate in
            LeanTween.scale(newCard, Vector3.one, 0.3f).setEaseOutBack();
            
            // Update Layout nach Animation
            UpdateHandLayout();
        }
    }
    
    /// <summary>
    /// Entfernt eine Karte aus der Hand
    /// </summary>
    private void RemoveCardFromHand(TimeCardData cardData)
    {
        // Finde die entsprechende UI-Karte
        for (int i = activeCardUIs.Count - 1; i >= 0; i--)
        {
            var cardUI = activeCardUIs[i];
            if (cardUI != null)
            {
                var cardUIComponent = cardUI.GetComponent<CardUI>();
                if (cardUIComponent != null && cardUIComponent.GetCardData() == cardData)
                {
                    // Entferne aus der Liste
                    activeCardUIs.RemoveAt(i);
                    
                    // Play-Animation
                    float animDuration = 0.25f;
                    
                    // Animiere Karte nach oben und fade out
                    LeanTween.moveLocalY(cardUI, cardUI.transform.localPosition.y + 100f, animDuration)
                        .setEaseOutQuad();
                    LeanTween.scale(cardUI, Vector3.zero, animDuration)
                        .setEaseInBack()
                        .setDestroyOnComplete(true);
                    
                    // WICHTIG: Sofortiges Layout-Update für sauberes Zusammenrücken
                    UpdateHandLayout(false); // Mit Animation
                    break;
                }
            }
        }
    }
    
    /// <summary>
    /// Gibt den Hover-Lift-Wert zurück
    /// </summary>
    public float GetHoverLift()
    {
        return hoverLift;
    }
    
    /// <summary>
    /// Gibt zurück ob Touch im Hand-Bereich aktiv ist
    /// </summary>
    public bool IsTouchingHandArea()
    {
        return isTouching;
    }
    
    /// <summary>
    /// Gibt die aktuell gehoverte Karte zurück
    /// </summary>
    public CardUI GetHoveredCard()
    {
        return currentlyHoveredCard;
    }
    
    void OnDestroy()
    {
        if (player != null)
        {
            // Instanz-Event abmelden
            player.OnHandChanged -= UpdateHandDisplay;
            
            // Statische Events abmelden
            ZeitwaechterPlayer.OnCardDrawn -= AddCardToHand;
            ZeitwaechterPlayer.OnCardPlayed -= RemoveCardFromHand;
        }
        
        if (layoutUpdateCoroutine != null)
        {
            StopCoroutine(layoutUpdateCoroutine);
        }
    }
}