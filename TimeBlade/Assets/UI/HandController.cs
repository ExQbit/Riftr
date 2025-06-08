using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// Verwaltet die Kartenhand-UI und Drag&Drop
/// </summary>
public class HandController : MonoBehaviour
{
    [Header("Referenzen")]
    [SerializeField] private Transform handContainer;
    [SerializeField] private GameObject cardUIPrefab;
    
    [Header("Layout-Einstellungen")]
    [SerializeField] private float cardSpacing = 80f; // Basis-Abstand zwischen Karten
    [SerializeField] private float maxCardWidth = 120f; // Maximale Breite einer Karte
    [SerializeField] private float fanAngle = 25f; // Maximaler Winkel für Fächer-Effekt
    [SerializeField] private float curveHeight = 30f; // Höhe der Bogen-Kurve
    [SerializeField] private float hoverLift = 20f; // Anhebung bei Hover
    [SerializeField] private AnimationCurve layoutCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);
    
    [Header("Touch-Einstellungen")]
    [SerializeField] private bool enableFanning = true; // Auffächern bei Touch
    [SerializeField] private float fanSpacing = 150f; // Abstand beim Auffächern
    [SerializeField] private float fanAnimationDuration = 0.15f; // Per Spec: Snappy Animation
    [SerializeField] private LeanTweenType fanEaseType = LeanTweenType.easeOutExpo; // Per Spec
    [SerializeField] private float touchAreaExtension = 50f; // Touch-Bereich-Erweiterung
    
    [Header("Canvas-Einstellungen")]
    [SerializeField] private Canvas parentCanvas; // Canvas für korrekte Touch-Umrechnung
    [SerializeField] private Camera uiCamera; // UI-Kamera (optional, abhängig vom Canvas-Modus)
    
    [Header("Karten-Vorschau")]
    [SerializeField] private float previewScale = 2.5f; // Skalierung der Vorschau-Karte
    [SerializeField] private Vector2 previewOffset = new Vector2(0, 100); // Offset vom Bildschirm-Zentrum
    [SerializeField] private float previewFadeInTime = 0.15f; // Einblend-Zeit
    [SerializeField] private float previewFadeOutTime = 0.1f; // Ausblend-Zeit
    
    [Header("Hover-Hysterese")]
    [SerializeField] private float hoverHysteresisDistance = 20f; // Pixel-Abstand für stabilen Kartenwechsel
    
    // Aktive Karten-UI-Elemente
    private List<GameObject> activeCardUIs = new List<GameObject>();
    private bool isFanned = false;
    private bool isTouching = false;
    private CardUI hoveredCard = null; // Aktuell gehoverte Karte
    private CardUI lastHoveredCard = null; // Letzte gehoverte Karte (bleibt auch wenn Finger Hand verlässt)
    private GameObject draggedCard = null; // Karte die gerade gezogen wird
    private bool isPlayingCard = false; // GUARD: Verhindert mehrfaches Kartenspielen
    
    // ====== ZENTRALES DRAG-SYSTEM ======
    // Ersetzt Unity's OnBeginDrag/OnDrag/OnEndDrag System, welches Events immer an die
    // Start-Karte sendet, nicht an die Karte unter dem aktuellen Finger.
    // 
    // PROBLEM: Finger auf Karte A → Finger zu Karte B → Unity draggt Karte A (falsch!)
    // LÖSUNG: HandController trackt Finger-Position und draggt die aktuelle Karte B (richtig!)
    
    private bool isDraggingActive = false;    // Master-Flag: Ist gerade ein Drag aktiv?
    private Vector2 dragStartPosition;        // Screen-Position wo Touch begann (für Schwellenwert)
    private Vector2 lastDragPosition;         // Letzte Finger-Position (für Bewegungs-Tracking)  
    private CardUI draggedCardUI = null;      // Die Karte die AKTUELL gedraggt wird (nicht Start-Karte!)
    
    // Drag-Schwellenwerte (NUR Aufwärtsbewegung löst Drag aus!)
    private float minVerticalSwipe = 30f;     // Erhöht auf 30f - verhindert zu leichtes Auslösen
    private float maxHorizontalForDrag = 100f; // Erhöht auf 100f - erlaubt diagonale Bewegung
    
    // NEU: Horizontale Drift-Erkennung (verhindert Drag während Kartengliding)
    private bool hasChangedCards = false;     // Flag: Hat der Finger zwischen verschiedenen Karten gewechselt?
    private CardUI initialHoveredCard = null;// Die erste Karte unter dem Touch (Referenz für Drift-Erkennung)
    
    // Referenz zum Spieler
    private ZeitwaechterPlayer player;
    
    // Canvas-Kamera für Touch-Umrechnung
    private Camera canvasCamera;
    
    // Card Preview System
    private GameObject cardPreview = null; // Vorschau-GameObject
    private CardUI cardPreviewUI = null; // UI-Component der Vorschau
    private CanvasGroup previewCanvasGroup = null; // Für Fade-In/Out
    
    // Hover Hysteresis System
    private Vector2 lastHoverPosition; // Letzte Position beim Hover-Wechsel
    private bool isHysteresisActive = false; // Ist Hysterese aktiv?
    
    void Start()
    {
        Debug.LogWarning($"[HandController] Start - handContainer: {handContainer?.name ?? "NULL"}, cardUIPrefab: {cardUIPrefab?.name ?? "NULL"}");
        
        // Canvas und Kamera Setup
        SetupCanvasAndCamera();
        
        // Verify critical references
        if (handContainer == null)
        {
            Debug.LogError("[HandController] handContainer is NULL at Start! Cannot display cards.");
        }
        else
        {
            // Check handContainer scale
            Debug.LogWarning($"[HandController] HandContainer scale: {handContainer.localScale}");
            if (handContainer.localScale != Vector3.one)
            {
                Debug.LogError($"[HandController] WARNING: HandContainer has non-unit scale! This will affect card positions.");
            }
            
            // CRITICAL: Check parent Canvas scales
            Transform canvasParent = handContainer.parent;
            while (canvasParent != null)
            {
                if (canvasParent.localScale == Vector3.zero)
                {
                    Debug.LogError($"[HandController] CRITICAL: Parent '{canvasParent.name}' has ZERO scale! This will break all card positioning.");
                    Debug.LogError($"[HandController] Attempting to fix by temporarily setting scale to (1,1,1)...");
                    canvasParent.localScale = Vector3.one;
                }
                canvasParent = canvasParent.parent;
            }
        }
        
        if (cardUIPrefab == null)
        {
            Debug.LogError("[HandController] cardUIPrefab is NULL at Start! Cannot create cards.");
        }
        
        player = ZeitwaechterPlayer.Instance;
        
        if (player != null)
        {
            Debug.Log("[HandController] ZeitwaechterPlayer.Instance found, subscribing to events");
            
            // Only subscribe to OnHandChanged - NO LEGACY EVENTS
            player.OnHandChanged += UpdateHandDisplay;
            
            Debug.Log("[HandController] Using ONLY OnHandChanged -> UpdateHandDisplay (legacy events DISABLED)");
        }
        else
        {
            Debug.LogError("[HandController] ZeitwaechterPlayer.Instance is NULL! Cannot connect to player.");
        }
        
        // Initial Hand anzeigen
        Debug.Log("[HandController] Calling UpdateHandDisplay from Start");
        UpdateHandDisplay();
    }
    
    /// <summary>
    /// Ermittelt Canvas und Kamera für korrekte Touch-Koordinaten-Umrechnung
    /// </summary>
    private void SetupCanvasAndCamera()
    {
        // Versuche Canvas zu finden, falls nicht zugewiesen
        if (parentCanvas == null)
        {
            // Zuerst in Parent-Hierarchie suchen
            parentCanvas = GetComponentInParent<Canvas>();
            
            // Falls nicht gefunden, suche alle Canvas-Objekte in der Szene
            if (parentCanvas == null)
            {
                Canvas[] allCanvases = FindObjectsByType<Canvas>(FindObjectsSortMode.None);
                Debug.Log($"[HandController] Searching for Canvas... found {allCanvases.Length} canvases in scene");
                
                // Finde das Canvas das unseren HandContainer enthält
                foreach (Canvas canvas in allCanvases)
                {
                    if (handContainer.IsChildOf(canvas.transform))
                    {
                        parentCanvas = canvas;
                        Debug.Log($"[HandController] Found parent canvas: {canvas.name}");
                        break;
                    }
                }
            }
            
            if (parentCanvas == null)
            {
                Debug.LogError("[HandController] Kein Canvas in der Hierarchie gefunden! Touch-Umrechnung wird fehlschlagen.");
                return;
            }
        }
        
        // Finde den Root-Canvas (wichtig für korrekte Kamera-Ermittlung)
        Canvas rootCanvas = parentCanvas.rootCanvas;
        Debug.Log($"[HandController] Canvas gefunden: {rootCanvas.name}, RenderMode: {rootCanvas.renderMode}");
        
        // Bestimme die korrekte Kamera basierend auf Canvas-RenderMode
        switch (rootCanvas.renderMode)
        {
            case RenderMode.ScreenSpaceOverlay:
                // Overlay-Canvas benötigt keine Kamera
                canvasCamera = null;
                Debug.Log("[HandController] Canvas ist ScreenSpaceOverlay - keine Kamera benötigt");
                break;
                
            case RenderMode.ScreenSpaceCamera:
                // Verwende die Canvas-Kamera
                canvasCamera = rootCanvas.worldCamera;
                if (canvasCamera == null)
                {
                    // Fallback auf zugewiesene UI-Kamera
                    canvasCamera = uiCamera;
                    if (canvasCamera == null)
                    {
                        // Letzter Fallback auf Main Camera
                        canvasCamera = Camera.main;
                        Debug.LogWarning("[HandController] Canvas.worldCamera ist null! Verwende Camera.main als Fallback");
                    }
                }
                Debug.Log($"[HandController] Canvas ist ScreenSpaceCamera - verwende Kamera: {canvasCamera?.name ?? "NULL"}");
                break;
                
            case RenderMode.WorldSpace:
                // World Space Canvas benötigt Event Camera
                canvasCamera = uiCamera ?? Camera.main;
                Debug.Log($"[HandController] Canvas ist WorldSpace - verwende Kamera: {canvasCamera?.name ?? "NULL"}");
                break;
        }
    }
    
    void Update()
    {
        HandleTouchInput();
    }
    
    /// <summary>
    /// Handle Touch-Input für Auffächern
    /// </summary>
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
    
    /// <summary>
    /// Touch/Click beginnt
    /// </summary>
    private void HandleTouchStart(Vector2 position)
    {
        Debug.Log($"[HandController] Touch start at screen position: {position}, input type: {(CardUI.IsMouseInput() ? "Mouse" : "Touch")}");
        
        // DEBUG: Zeige alle Karten und ihre Positionen beim Touch
        Debug.Log($"[HandController] === TOUCH DEBUG - ALL CARDS ===");
        for (int i = 0; i < activeCardUIs.Count; i++)
        {
            if (activeCardUIs[i] != null)
            {
                var cardUI = activeCardUIs[i].GetComponent<CardUI>();
                var cardRect = activeCardUIs[i].GetComponent<RectTransform>();
                string cardName = cardUI?.GetCardData()?.cardName ?? "NULL";
                Debug.Log($"[HandController] Card {i}: {activeCardUIs[i].name} - CardData: {cardName} - LocalPos: {cardRect.localPosition} - WorldPos: {cardRect.position} - SiblingIndex: {activeCardUIs[i].transform.GetSiblingIndex()}");
            }
        }
        Debug.Log($"[HandController] === END TOUCH DEBUG ===");
        
        // Prüfe ob Touch im Handkarten-Bereich ist
        RectTransform rect = handContainer.GetComponent<RectTransform>();
        if (rect == null)
        {
            Debug.LogError("[HandController] handContainer has no RectTransform!");
            return;
        }
        
        Vector2 localPoint;
        
        // KRITISCH: Verwende die korrekte Kamera für die Koordinaten-Umrechnung
        bool hitDetected = RectTransformUtility.ScreenPointToLocalPointInRectangle(
            rect, position, canvasCamera, out localPoint);
            
        Debug.Log($"[HandController] Container hit detection: {hitDetected}, local point: {localPoint}, using camera: {canvasCamera?.name ?? "NULL"}");
        
        if (hitDetected)
        {
            // VEREINFACHUNG: Alle Touches im Container sind gültig + erweiterte Touch-Area
            Rect expandedRect = rect.rect;
            expandedRect.yMin -= touchAreaExtension; // Erweitere nach unten für bessere Touch-Erkennung
            expandedRect.yMax += touchAreaExtension / 2f; // Leichte Erweiterung nach oben
            expandedRect.xMin -= touchAreaExtension / 2f; // Seitliche Erweiterung
            expandedRect.xMax += touchAreaExtension / 2f;
            
            bool isInValidArea = expandedRect.Contains(localPoint);
            
            Debug.Log($"[HandController] Touch area validation - original rect: {rect.rect}");
            Debug.Log($"[HandController] Expanded rect: {expandedRect}");
            Debug.Log($"[HandController] Local point: {localPoint}, in valid area: {isInValidArea}");
            
            if (isInValidArea)
            {
                Debug.Log($"[HandController] ✓ VALID TOUCH DETECTED - Starting fanning process");
                
                isTouching = true;
                isFanned = true;
                
                // WICHTIG: Setze Flag für alle Karten
                CardUI.SetTouchStartedOnValidArea(true);
                
                // Reset lastHoveredCard bei neuem Touch für sauberen Zustand
                lastHoveredCard = null;
                isPlayingCard = false; // GUARD: Reset auch bei neuem Touch
                
                // NEUES DRAG-SYSTEM: Speichere Start-Position
                dragStartPosition = position;
                lastDragPosition = position;
                isDraggingActive = false;
                draggedCardUI = null;
                
                // NEU: Reset Drift-Erkennung
                hasChangedCards = false;
                initialHoveredCard = null;
                
                // Reset Hover-Hysterese
                isHysteresisActive = false;
                lastHoverPosition = position;
                
                // Bestimme welche Karte unter dem Touch ist
                UpdateCardSelectionAtPosition(position);
                
                // NEU: Speichere die initial berührte Karte für Drift-Erkennung
                initialHoveredCard = hoveredCard;
                
                // IMMEDIATE Fan Animation (0.15s easeOutExpo per spec)
                UpdateCardLayout();
            }
            else
            {
                Debug.Log($"[HandController] ✗ Touch outside valid area - rejecting touch");
                // Touch außerhalb des gültigen Bereichs
                CardUI.SetTouchStartedOnValidArea(false);
            }
        }
        else
        {
            Debug.Log($"[HandController] Touch missed container completely - rejecting touch");
            // Touch außerhalb des Containers
            CardUI.SetTouchStartedOnValidArea(false);
        }
    }
    
    /// <summary>
    /// NEUE METHODE: Behandelt Touch-Bewegung (Drag-Detection und Card-Following)
    /// </summary>
    private void HandleTouchMove(Vector2 position)
    {
        // Update der Kartenauswahl unter dem Finger
        UpdateCardSelectionAtPosition(position);
        
        // Prüfe ob Drag gestartet werden soll
        if (!isDraggingActive && !isPlayingCard)
        {
            Vector2 dragDelta = position - dragStartPosition;
            
            // DEBUG: Log every frame to understand why drag isn't triggering
            if (Mathf.Abs(dragDelta.y) > 10f || Mathf.Abs(dragDelta.x) > 10f)
            {
                Debug.Log($"[HandController] Drag detection: delta=({dragDelta.x:F1}, {dragDelta.y:F1}), vertical needed: {minVerticalSwipe}, horizontal max: {maxHorizontalForDrag}");
            }
            
            // INTELLIGENTE DRAG-ERKENNUNG: Verhindert versehentliches Draggen beim Durchgleiten
            bool hasUpwardMovement = dragDelta.y > minVerticalSwipe; // Positives Y = Aufwärts
            
            // NEU: Winkel-basierte Erkennung
            // Berechne den Winkel der Bewegung (0° = horizontal, 90° = vertikal)
            float angle = Mathf.Abs(Mathf.Atan2(dragDelta.y, dragDelta.x) * Mathf.Rad2Deg);
            
            // NEU: Verhältnis von vertikaler zu horizontaler Bewegung
            float horizontalAbs = Mathf.Abs(dragDelta.x);
            float verticalAbs = Mathf.Abs(dragDelta.y);
            float movementRatio = horizontalAbs > 0.1f ? verticalAbs / horizontalAbs : float.MaxValue;
            
            // Drag nur wenn:
            // 1. Genug Aufwärtsbewegung UND
            // 2. Bewegung ist einigermaßen vertikal (Winkel > 30° ODER Verhältnis > 0.5)
            bool isPrimarilyVertical = angle > 30f || movementRatio > 0.5f;
            
            // Card-Drift prüfen - ABER NUR wenn zu einer ANDEREN Karte gewechselt wird
            // Drift zu NULL (Finger außerhalb Karten) wird IGNORIERT
            bool hasCardDrift = hasChangedCards && hoveredCard != null;
            
            // Debug Info
            if (hasUpwardMovement && Mathf.Abs(dragDelta.x) > 10f)
            {
                Debug.Log($"[HandController] Movement analysis: angle={angle:F1}°, ratio={movementRatio:F2}, drift={hasCardDrift}, vertical={isPrimarilyVertical}");
            }
            
            bool shouldStartDrag = false;
            
            // VEREINFACHTER MODUS für Testing: Wenn große Aufwärtsbewegung, ignoriere andere Checks
            bool isStrongUpwardMovement = dragDelta.y > 50f; // Starke Aufwärtsbewegung
            
            if (isStrongUpwardMovement)
            {
                // Bei starker Aufwärtsbewegung (>50px) IMMER Drag erlauben
                shouldStartDrag = true;
                Debug.Log($"[HandController] ✓ DRAG TRIGGERED - Strong upward movement: {dragDelta.y:F1}px (ignoring other checks)");
            }
            else if (hasUpwardMovement && isPrimarilyVertical && !hasCardDrift)
            {
                // Normale Bedingungen: primär vertikal ohne Kartenwechsel
                shouldStartDrag = true;
                Debug.Log($"[HandController] ✓ DRAG TRIGGERED - Vertical swipe: {dragDelta.y:F1}px up, {dragDelta.x:F1}px horizontal, angle={angle:F1}°, ratio={movementRatio:F2}");
            }
            else if (hasUpwardMovement && !isPrimarilyVertical)
            {
                // Zu horizontal → KEIN Drag
                Debug.Log($"[HandController] Upward movement BLOCKED - too horizontal: angle={angle:F1}°, ratio={movementRatio:F2} (v:{dragDelta.y:F1}/h:{dragDelta.x:F1})");
            }
            else if (hasUpwardMovement && hasCardDrift)
            {
                // Kartenwechsel erkannt → KEIN Drag (außer Drift zu NULL)
                string initialCardName = initialHoveredCard?.GetCardData()?.cardName ?? "NULL";
                string currentCardName = hoveredCard?.GetCardData()?.cardName ?? "NULL";
                Debug.Log($"[HandController] Upward movement BLOCKED - card drift from '{initialCardName}' to '{currentCardName}'");
            }
            else
            {
                // Keine ausreichende Aufwärtsbewegung
                if (Mathf.Abs(dragDelta.y) > 10f || Mathf.Abs(dragDelta.x) > 10f)
                {
                    // Log nur signifikante Bewegungen
                    // Debug.Log($"[HandController] No drag: insufficient upward movement. Delta=({dragDelta.x:F1}, {dragDelta.y:F1}), needed Y < -{minVerticalSwipe}");
                }
            }
            
            if (shouldStartDrag)
            {
                StartDragOperation();
            }
        }
        
        // Wenn Drag aktiv ist, bewege die gedraggte Karte
        if (isDraggingActive && draggedCardUI != null)
        {
            MoveDraggedCardToPosition(position);
        }
        
        lastDragPosition = position;
    }
    
    /// <summary>
    /// Touch/Click endet
    /// </summary>
    private void HandleTouchEnd()
    {
        string hoveredCardName = hoveredCard?.GetCardData()?.cardName ?? "none";
        string lastHoveredCardName = lastHoveredCard?.GetCardData()?.cardName ?? "none";
        Debug.Log($"[HandController] Touch end - was touching: {isTouching}, was fanned: {isFanned}, hovered: {hoveredCardName}, lastHovered: {lastHoveredCardName}, isDragging: {isDraggingActive}");
        
        if (isTouching && !isPlayingCard) // GUARD: Verhindere mehrfaches Ausführen
        {
            // KRITISCH: Setze isTouching SOFORT auf false um weitere hover Updates zu verhindern
            isTouching = false;
            isFanned = false;
            
            // NEUES DRAG-SYSTEM: Behandle Drag-Ende
            if (isDraggingActive)
            {
                EndDragOperation();
            }
            else
            {
                Debug.Log($"[HandController] Touch ended without drag - just hovering, no card play");
                // Nur Hover, keine Karte spielen!
            }
            
            // CRITICAL: Force unfanning and immediate layout to prevent hanging
            isFanned = false;
            UpdateCardLayout(true); // true = force immediate (already calls ForceDisableHover on all cards)
            
            // CRITICAL: Reset hover references after touch end (but no explicit ForceExitHover to avoid race condition)
            if (hoveredCard != null)
            {
                Debug.Log($"[HandController] Clearing hoveredCard reference: {hoveredCard.GetCardData()?.cardName}");
                hoveredCard = null; // Just clear reference, UpdateCardLayout already handled hover reset
            }
            
            if (lastHoveredCard != null)
            {
                Debug.Log($"[HandController] Clearing lastHoveredCard reference: {lastHoveredCard.GetCardData()?.cardName}");
                lastHoveredCard = null; // Just clear reference, UpdateCardLayout already handled hover reset
            }
            
            // Hide card preview
            HideCardPreview();
        }
        else if (isPlayingCard)
        {
            Debug.Log($"[HandController] Touch end BLOCKED by GUARD - card is already being played");
        }
        
        // Reset touch validation flag
        CardUI.SetTouchStartedOnValidArea(false);
    }
    
    /// <summary>
    /// Aktualisiert die komplette Hand-Anzeige INTELLIGENT (nur Änderungen)
    /// </summary>
    private void UpdateHandDisplay()
    {
        if (player == null)
        {
            Debug.LogError("[HandController] UpdateHandDisplay - player is NULL!");
            return;
        }
        
        var hand = player.GetHand();
        Debug.LogWarning($"[HandController] UpdateHandDisplay START - Player has {hand.Count} cards, existing UI: {activeCardUIs.Count}");
        
        // OPTIMIZATION: If we're just adding cards (common case when drawing), don't destroy everything
        if (hand.Count > activeCardUIs.Count && activeCardUIs.Count > 0)
        {
            // Check if existing cards are still the same
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
                // Just add the new cards
                Debug.Log($"[HandController] Adding {hand.Count - activeCardUIs.Count} new cards to existing hand");
                for (int i = activeCardUIs.Count; i < hand.Count; i++)
                {
                    CreateCardUI(hand[i]);
                }
                Debug.LogWarning($"[HandController] UpdateHandDisplay END - Added new cards. Total: {activeCardUIs.Count}");
                return;
            }
        }
        
        // Prüfe ob sich die Hand tatsächlich geändert hat
        if (hand.Count == activeCardUIs.Count)
        {
            // Gleiche Anzahl - prüfe ob es die gleichen Karten sind
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
                Debug.Log($"[HandController] Hand unchanged - skipping refresh");
                return;
            }
        }
        
        // Hand hat sich geändert - vollständige Erneuerung
        Debug.Log($"[HandController] Hand changed - performing full refresh (cards: {hand.Count} vs UI: {activeCardUIs.Count})");
        
        // SCALING FIX: Cancel all tweens before destroying
        foreach (var cardUIGameObject in activeCardUIs)
        {
            if (cardUIGameObject != null)
            {
                LeanTween.cancel(cardUIGameObject);
            }
        }
        
        // Alte Karten entfernen
        foreach (var cardUIGameObject in activeCardUIs)
        {
            if (cardUIGameObject != null)
            {
                Debug.Log($"[HandController] Destroying card UI: {cardUIGameObject.name}");
                Destroy(cardUIGameObject);
            }
        }
        activeCardUIs.Clear();
        hoveredCard = null;
        lastHoveredCard = null;
        draggedCard = null;
        isPlayingCard = false; // GUARD: Reset beim Hand-Update
        
        // Neue Karten erstellen
        Debug.Log($"[HandController] Creating UI for {hand.Count} cards from player hand");
        
        foreach (var card in hand)
        {
            CreateCardUI(card);
        }
        
        Debug.LogWarning($"[HandController] UpdateHandDisplay END - Created {activeCardUIs.Count} card UIs");
        
        // Debug: Zeige finale Positionen aller Karten
        StartCoroutine(DebugCardPositions());
    }
    
    /// <summary>
    /// Debug-Coroutine um Karten-Positionen nach Layout zu zeigen
    /// </summary>
    private System.Collections.IEnumerator DebugCardPositions()
    {
        yield return new WaitForSeconds(0.5f); // Warte bis Animationen fertig sind
        
        Debug.Log("[HandController] === CARD POSITIONS DEBUG ===");
        for (int i = 0; i < activeCardUIs.Count; i++)
        {
            if (activeCardUIs[i] != null)
            {
                RectTransform rect = activeCardUIs[i].GetComponent<RectTransform>();
                Debug.Log($"[HandController] Card {i}: {activeCardUIs[i].name} - LocalPos: {rect.localPosition}, AnchoredPos: {rect.anchoredPosition}, WorldPos: {rect.position}");
            }
        }
        Debug.Log("[HandController] === END POSITIONS DEBUG ===");
    }
    
    /// <summary>
    /// Erstellt UI für eine Karte
    /// </summary>
    private void CreateCardUI(TimeCardData cardData)
    {
        Debug.Log($"[HandController] Attempting to create CardUI for card data: {cardData?.cardName ?? "NULL"}");
        
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
        // KRITISCH: Setze Sibling Index basierend auf Position in der Hand
        int targetSiblingIndex = activeCardUIs.Count; // Neue Karte sollte hinten stehen
        cardUI.transform.SetSiblingIndex(targetSiblingIndex);
        
        Debug.Log($"[HandController] Created CardUI GameObject: {cardUI.name}, Active: {cardUI.activeInHierarchy}, Parent: {cardUI.transform.parent?.name ?? "NONE"}, SiblingIndex: {cardUI.transform.GetSiblingIndex()}");
        
        // Check RectTransform immediately
        RectTransform cardRect = cardUI.GetComponent<RectTransform>();
        if (cardRect != null)
        {
            // KRITISCH: Stelle sicher, dass Pivot und Anchors korrekt sind
            // Karten sollten zentrierten Pivot haben für korrekte Rotation
            if (cardRect.pivot != Vector2.one * 0.5f)
            {
                Debug.LogWarning($"[HandController] Card has non-centered pivot: {cardRect.pivot}. Correcting to (0.5, 0.5)");
                cardRect.pivot = Vector2.one * 0.5f;
            }
            
            // Anchors sollten zentriert sein für absolute Positionierung
            if (cardRect.anchorMin != Vector2.one * 0.5f || cardRect.anchorMax != Vector2.one * 0.5f)
            {
                Debug.LogWarning($"[HandController] Card has non-centered anchors. Correcting to (0.5, 0.5)");
                cardRect.anchorMin = Vector2.one * 0.5f;
                cardRect.anchorMax = Vector2.one * 0.5f;
            }
            
            // Reset position für sauberen Start
            cardRect.anchoredPosition = Vector2.zero;
            cardRect.localRotation = Quaternion.identity;
            cardRect.localScale = Vector3.one;
        }
        
        // CardUI Komponente finden und konfigurieren
        var cardUIComponent = cardUI.GetComponent<CardUI>();
        if (cardUIComponent != null)
        {
            // ROBUSTE LÖSUNG: Verwende InitializeCard() für direkte HandController-Referenz
            cardUIComponent.InitializeCard(this, cardData, canvasCamera);
            cardUIComponent.OnCardClicked += HandleCardClick;
            Debug.Log($"[HandController] CardUI component initialized with direct controller reference and canvas camera for {cardData.cardName}");
        }
        else
        {
            Debug.LogError($"[HandController] No CardUI component found on {cardUI.name}!");
        }
        
        activeCardUIs.Add(cardUI);
        Debug.Log($"[HandController] Added {cardUI.name} to activeCardUIs. Total cards: {activeCardUIs.Count}");
        
        // SCALING FIX: Set layout animation flag BEFORE layout to prevent hover during layout
        if (cardUIComponent != null)
        {
            cardUIComponent.SetInLayoutAnimation(true); // Prevent hover during initial layout
            Debug.Log($"[HandController] Set layout animation flag for Card {activeCardUIs.Count-1} during creation");
        }
        
        // Layout mit sofortiger Positionierung aktualisieren (verhindert initiale Überlappung)
        Debug.Log($"[HandController] Calling UpdateCardLayout. Card count: {activeCardUIs.Count}. Force immediate: true");
        UpdateCardLayout(true, true);
        
        // CRITICAL FIX: ForceDisableHover AFTER layout so basePosition is set correctly
        if (cardUIComponent != null)
        {
            cardUIComponent.ForceDisableHover();
            Debug.LogError($"[HandController] FORCED Card {activeCardUIs.Count-1} to disable hover AFTER layout");
            
            // CRITICAL: Re-enable hover only AFTER ForceDisableHover to prevent race condition
            cardUIComponent.SetInLayoutAnimation(false);
            Debug.Log($"[HandController] Re-enabled hover for Card {activeCardUIs.Count-1} AFTER ForceDisableHover");
        }
        
        // CRITICAL: Check the position immediately after layout
        if (activeCardUIs.Count == 2) // Card 1 just added
        {
            Vector3 finalPos = cardRect.localPosition;
            Debug.LogError($"[HandController] CARD 1 FINAL POSITION after UpdateCardLayout: {finalPos}");
        }
        
        // SCALING FIX: Schedule a scale check after creation
        StartCoroutine(CheckCardScaleAfterCreation(cardUI, 0.1f));
        
        // CRITICAL DEBUG: Add immediate SiblingIndex monitoring for Card 3
        if (activeCardUIs.Count == 5) // All 5 cards are now present, monitor Card 3 (index 3)
        {
            GameObject card3 = activeCardUIs[3]; // Card 3 is at index 3
            StartCoroutine(MonitorCard3SiblingIndex(card3));
            Debug.LogError($"[HandController] Started monitoring Card 3: {card3.name}");
        }
        
        // CRITICAL DEBUG: Check if this is Card 1 being created with wrong position
        if (activeCardUIs.Count == 2) // This would be Card 1 (2nd card)
        {
            Debug.LogError($"[HandController] CARD 1 CREATION CHECK - Position: {cardRect.localPosition}, Scale: {cardUI.transform.localScale}");
            if (Mathf.Abs(cardRect.localPosition.y - 12.5f) > 0.1f)
            {
                Debug.LogError($"[HandController] WARNING: Card 1 created with wrong Y position! Expected ~12.5, got {cardRect.localPosition.y}");
            }
        }
    }
    
    /// <summary>
    /// Checks and fixes card scale after creation animations
    /// </summary>
    private System.Collections.IEnumerator CheckCardScaleAfterCreation(GameObject card, float delay)
    {
        // Store the index when coroutine starts to track the right card
        int cardIndex = activeCardUIs.IndexOf(card);
        CardUI cardUI = card?.GetComponent<CardUI>();
        string originalCardName = cardUI?.GetCardData()?.cardName ?? "Unknown";
        
        yield return new WaitForSeconds(delay);
        
        if (card != null && card.transform.localScale != Vector3.one)
        {
            // Get current info for debugging
            int siblingIndex = card.transform.GetSiblingIndex();
            Vector3 position = card.transform.localPosition;
            
            Debug.LogWarning($"[HandController] Card {cardIndex} '{originalCardName}' (SiblingIndex: {siblingIndex}, Position: {position}) has incorrect scale {delay}s after creation: {card.transform.localScale}. Fixing...");
            card.transform.localScale = Vector3.one;
        }
    }
    
    /// <summary>
    /// Aktualisiert das gebogene Layout aller Karten
    /// </summary>
    public void UpdateCardLayout(bool forceImmediate = false, bool isFromCardCreation = false)
    {
        Debug.Log($"[HandController] Layout update - card count: {activeCardUIs.Count}, is fanned: {isFanned}, is touching: {isTouching}, force immediate: {forceImmediate}");
        
        int cardCount = activeCardUIs.Count;
        if (cardCount == 0)
        {
            Debug.Log("[HandController] UpdateCardLayout - No cards to layout, returning");
            return;
        }
        
        // CRITICAL: Disable all hover effects during layout to prevent elevation issues
        foreach (var cardObj in activeCardUIs)
        {
            if (cardObj != null)
            {
                var cardUI = cardObj.GetComponent<CardUI>();
                if (cardUI != null)
                {
                    cardUI.ForceDisableHover();
                    cardUI.SetInLayoutAnimation(true);
                    // CRITICAL: Ensure scale is correct before layout
                    cardObj.transform.localScale = Vector3.one;
                }
            }
        }
        
        RectTransform containerRect = handContainer.GetComponent<RectTransform>();
        if (containerRect == null)
        {
            Debug.LogError("[HandController] UpdateCardLayout - handContainer has no RectTransform!");
            return;
        }
        
        float containerWidth = Mathf.Abs(containerRect.rect.width); // WICHTIG: Abs() für negative Breiten von Stretch-Anchors
        
        // Berechne Spacing basierend auf Kartenanzahl
        float totalSpacing = isFanned ? fanSpacing : cardSpacing;
        float actualSpacing = totalSpacing;
        
        // Bei vielen Karten: Dynamisch anpassen
        if (cardCount > 3)
        {
            float maxWidth = (cardCount - 1) * totalSpacing + maxCardWidth;
            if (maxWidth > containerWidth * 0.9f)
            {
                actualSpacing = (containerWidth * 0.9f - maxCardWidth) / (cardCount - 1);
            }
        }
        
        // Berechne Start-Position (zentriert)
        float totalWidth = (cardCount - 1) * actualSpacing;
        float startX = -totalWidth / 2f;
        
        // Debug.Log($"[HandController] Layout calculation - total width: {totalWidth}, spacing used: {actualSpacing}");
        
        // Positioniere jede Karte
        for (int i = 0; i < cardCount; i++)
        {
            GameObject card = activeCardUIs[i];
            
            if (card == null)
            {
                Debug.LogError($"[HandController] Card at index {i} is NULL in UpdateCardLayout loop!");
                continue;
            }
            
            if (card == draggedCard)
            {
                Debug.Log($"[HandController] Skipping dragged card at index {i}");
                continue;
            }
            
            RectTransform cardRect = card.GetComponent<RectTransform>();
            if (cardRect == null)
            {
                Debug.LogError($"[HandController] Card {card.name} has no RectTransform!");
                continue;
            }
            
            CardUI cardUI = card.GetComponent<CardUI>();
            if (cardUI == null)
            {
                Debug.LogError($"[HandController] Card {card.name} has no CardUI component!");
            }
            
            // X-Position
            float x = startX + i * actualSpacing;
            
            // Y-Position (Bogen-Kurve) - FIXED: Perfekter Handbogen
            float normalizedPos = cardCount > 1 ? (float)i / (cardCount - 1) : 0.5f;
            float curveT = (normalizedPos - 0.5f) * 2f; // -1 bis 1
            float curveMultiplier = isFanned ? 2.2f : 1f; // Beim Fanning: SEHR starke Kurve für ausgeprägten Bogen
            
            // OPTIMIZED: Verschiedene Kurven für Fanning vs. Normal
            float curveValue;
            float absT = Mathf.Abs(curveT); // 0 bis 1 (für Debug-Log)
            float angle = 0f; // Für Debug-Log
            
            if (isFanned)
            {
                // Beim Fanning: Cosinus-Kurve für perfekten Bogen
                angle = absT * Mathf.PI * 0.5f; // 0 bis π/2
                curveValue = Mathf.Cos(angle); // 1 bis 0, perfekte Bogen-Form
            }
            else
            {
                // Normal: Einfache Kurve für bessere Performance
                float curveInput = 1f - absT;
                curveValue = layoutCurve.Evaluate(curveInput);
            }
            
            float y = curveValue * curveHeight * curveMultiplier;
            
            // CRITICAL: Clamp Y values to prevent extreme positions - increased for stronger fanning
            float maxY = curveHeight * 2.5f; // Allow extra for stronger fanning arc (2.2x multiplier)
            y = Mathf.Clamp(y, 0, maxY);
            
            // CRITICAL DEBUG: Check current position before setting
            if (i == 1 && cardCount == 5)
            {
                Vector3 currentPos = cardRect.localPosition;
                Debug.LogError($"[HandController] CARD 1 POSITION CHECK - Before: {currentPos}, Target Y: {y}");
                
                // Check if position is already multiplied
                if (Mathf.Abs(currentPos.y - y) > 0.1f && Mathf.Abs(currentPos.y / y - 5f) < 0.1f)
                {
                    Debug.LogError($"[HandController] CRITICAL: Card 1 Y position appears to be 5x the target! Current: {currentPos.y}, Target: {y}");
                    Debug.LogError($"[HandController] This suggests the curve is being applied multiple times or there's a scale issue.");
                }
                
                // Check for scale issues on parent transforms
                Transform current = card.transform;
                while (current != null)
                {
                    if (current.localScale != Vector3.one)
                    {
                        Debug.LogError($"[HandController] WARNING: Transform '{current.name}' has non-unit scale: {current.localScale}");
                        
                        // CRITICAL: If we find zero scale on Canvas, this breaks all positioning
                        if (current.localScale == Vector3.zero && current.name.Contains("Canvas"))
                        {
                            Debug.LogError($"[HandController] CRITICAL: Canvas '{current.name}' has ZERO scale! This breaks all card positioning!");
                            Debug.LogError($"[HandController] IMMEDIATELY FIXING Canvas scale to (1,1,1)!");
                            current.localScale = Vector3.one;
                            Debug.LogError($"[HandController] Canvas '{current.name}' scale fixed to: {current.localScale}");
                        }
                    }
                    current = current.parent;
                }
                
                // CRITICAL FIX: If Y is wrong, force correct it
                if (Mathf.Abs(cardRect.localPosition.y - y) > 0.1f)
                {
                    Debug.LogError($"[HandController] FORCING Card 1 to correct Y position: {y}");
                    cardRect.localPosition = new Vector3(cardRect.localPosition.x, y, cardRect.localPosition.z);
                }
            }
            
            // DEBUG: Log curve calculation for all cards when fanned
            if (isFanned && i <= 4)
            {
                Debug.Log($"[HandController] CURVE DEBUG Card {i}: normalizedPos={normalizedPos:F3}, curveT={curveT:F3}, absT={absT:F3}, angle={angle:F3}, curveValue={curveValue:F3}, final Y={y:F3}");
            }
            
            // Rotation (Fächer-Effekt)
            float rotation = 0f;
            if (cardCount > 1)
            {
                if (isFanned)
                {
                    // Beim Fanning: Angepasste Rotation für den stärkeren Bogen (2.2f curve)
                    // Erhöhte Rotation um dem stärkeren Y-Bogen zu folgen, aber nicht zu extrem
                    float rotationT = (normalizedPos - 0.5f) * 2f; // -1 bis 1
                    float curveFactor = Mathf.Pow(Mathf.Abs(rotationT), 0.7f) * Mathf.Sign(rotationT); // Sanftere Kurve
                    rotation = curveFactor * fanAngle * 0.6f; // ERHÖHT von 0.3f auf 0.6f für stärkeren Bogen
                }
                else
                {
                    // Normaler Zustand: Subtiler Bogen mit weniger Rotation
                    rotation = Mathf.Lerp(-fanAngle * 0.5f, fanAngle * 0.5f, normalizedPos);
                }
            }
            
            if (cardUI != null)
            {
                cardUI.SetOriginalRotation(rotation);
            }
            
            Vector3 targetPosition = new Vector3(x, y, 0);
            Vector3 targetRotation = new Vector3(0, 0, rotation);
            
            // Debug-Log für Positionierung
            string cardName = "UNKNOWN";
            if (cardUI != null && cardUI.GetCardData() != null)
            {
                cardName = cardUI.GetCardData().cardName;
            }
            // Debug.Log($"[HandController] Positioning card {i}: {card.name} (CardData: {cardName}) at position ({x:F1}, {y:F1}) with rotation {rotation:F1}");
            
            // KRITISCH: Sibling Index für korrekte Überlappung
            // Links (alte Karten) = hinten, Rechts (neue Karten) = vorne
            // Higher SiblingIndex = rendered on top
            // So: Card 0 (left) gets index 0, Card 4 (right) gets index 4
            card.transform.SetSiblingIndex(i);
            
            // DEBUG: Log the sibling index assignment
            Debug.Log($"[HandController] Card {i} ({cardName}) set to SiblingIndex {i} (total cards: {cardCount})");
            
            // SCALING FIX: Ensure correct scale before positioning
            if (cardUI != null && !cardUI.IsDragging() && !cardUI.IsBeingDraggedCentrally())
            {
                // If card is not being interacted with, ensure it has correct scale
                if (Mathf.Abs(card.transform.localScale.x - 1f) > 0.01f)
                {
                    Debug.LogWarning($"[HandController] Fixing scale during layout for {cardUI.GetCardData()?.cardName}: {card.transform.localScale}");
                    card.transform.localScale = Vector3.one;
                }
            }
            
            // Setze Position und Rotation (sofort oder animiert)
            if (forceImmediate || draggedCard != null) // Auch instant während Drag
            {
                cardRect.localPosition = targetPosition;
                cardRect.localEulerAngles = targetRotation;
                // Debug.Log($"[HandController] Applied immediate position to {card.name}: {cardRect.localPosition}");
                
                // CRITICAL: Update base position for hover calculations
                if (cardUI != null)
                {
                    cardUI.UpdateBasePosition(targetPosition);
                }
                
                // CRITICAL DEBUG: Check for stuck hover states on ANY card
                Vector3 actualPos = cardRect.localPosition;
                bool hasWrongPosition = Mathf.Abs(actualPos.y - targetPosition.y) > 0.1f;
                bool hasWrongScale = Mathf.Abs(card.transform.localScale.x - 1f) > 0.01f;
                int currentSiblingIndex = card.transform.GetSiblingIndex();
                bool hasWrongSiblingIndex = currentSiblingIndex != i;
                
                if (hasWrongPosition || hasWrongScale || hasWrongSiblingIndex)
                {
                    Debug.LogError($"[HandController] CARD {i} ({cardName}) STUCK IN HOVER STATE!");
                    Debug.LogError($"[HandController] Position: expected {targetPosition}, got {actualPos}");
                    Debug.LogError($"[HandController] Scale: expected 1.0, got {card.transform.localScale.x}");
                    Debug.LogError($"[HandController] SiblingIndex: expected {i}, got {currentSiblingIndex}");
                    
                    // CRITICAL: Fix all hover-related issues
                    if (hasWrongSiblingIndex)
                    {
                        Debug.LogError($"[HandController] FIXING Card {i} SiblingIndex! Was: {currentSiblingIndex}, setting to: {i}");
                        card.transform.SetSiblingIndex(i);
                    }
                    
                    if (cardUI != null)
                    {
                        cardUI.ForceDisableHover();
                        Debug.LogError($"[HandController] Force disabled hover on Card {i} after positioning");
                    }
                    
                    // Schedule monitoring for this card
                    StartCoroutine(CheckCardPositionAfterFrame(card, targetPosition, i));
                }
            }
            else
            {
                // Verwende spezielle Fan-Animation wenn Fanning aktiv
                float duration = isFanned ? fanAnimationDuration : 0.2f;
                LeanTweenType easing = isFanned ? fanEaseType : LeanTweenType.easeOutCubic;
                
                // Sanfte Animation
                LeanTween.cancel(card);
                
                // SCALING FIX: Ensure scale is correct before animating position
                if (Mathf.Abs(card.transform.localScale.x - 1f) > 0.01f)
                {
                    Debug.LogWarning($"[HandController] Card scale incorrect before animation: {card.transform.localScale}. Forcing to 1.");
                    card.transform.localScale = Vector3.one;
                }
                
                LeanTween.moveLocal(card, targetPosition, duration).setEase(easing)
                    .setOnComplete(() => {
                        // Update base position after animation
                        if (cardUI != null)
                        {
                            cardUI.UpdateBasePosition(targetPosition);
                        }
                    });
                LeanTween.rotateLocal(card, targetRotation, duration).setEase(easing)
                    .setOnComplete(() => {
                        // Re-enable hover after animation completes
                        if (cardUI != null)
                        {
                            cardUI.SetInLayoutAnimation(false);
                        }
                    });
            }
        }
        
        // Re-enable hover for all cards if this is NOT from card creation
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
            // CRITICAL: Ensure all cards have correct SiblingIndex after layout
            EnsureCorrectSiblingOrder();
            
            // REMOVED: FixCard3IfStuckInHover was causing incorrect position resets
            // The coroutine had hardcoded Y=12.5f which is only correct for non-fanned state
            // This was overriding correct fanned positions (Y=38.89f for Card 3)
        }
    }
    
    /// <summary>
    /// Karte wurde angeklickt
    /// </summary>
    private void HandleCardClick(TimeCardData cardData)
    {
        if (player != null && RiftCombatManager.Instance != null)
        {
            // PLAY-CHAIN LOG: Karte wird gespielt
            Debug.Log($"[HandController] Card '{cardData.cardName}' clicked successfully, informing CombatManager");
            
            // Versuche Karte zu spielen
            RiftCombatManager.Instance.PlayerWantsToPlayCard(cardData, player);
        }
        else
        {
            Debug.LogError($"[HandController] Cannot play card '{cardData.cardName}' - Player: {player != null}, CombatManager: {RiftCombatManager.Instance != null}");
        }
    }
    
    /// <summary>
    /// Gibt die aktuell gehoverte Karte zurück
    /// </summary>
    public CardUI GetHoveredCard()
    {
        string hoveredName = hoveredCard != null ? hoveredCard.gameObject.name : "null";
        Debug.Log($"[HandController] GetHoveredCard() called - returning: {hoveredName}");
        return hoveredCard;
    }
    
    /// <summary>
    /// Gibt die letzte gehöverte Karte zurück (für visuelles Dragging)
    /// </summary>
    public CardUI GetLastHoveredCard()
    {
        // Wenn aktuell eine Karte gehovert wird, verwende diese
        if (hoveredCard != null) return hoveredCard;
        
        // Ansonsten verwende die letzte gehöverte Karte
        string lastName = lastHoveredCard != null ? lastHoveredCard.GetCardData()?.cardName : "null";
        Debug.Log($"[HandController] GetLastHoveredCard() returning: {lastName}");
        return lastHoveredCard;
    }
    
    /// <summary>
    /// Gibt die Höhe für Hover-Lift zurück
    /// </summary>
    public float GetHoverLift()
    {
        return hoverLift;
    }
    
    /// <summary>
    /// Prüft ob gerade eine Karte gedraggt wird
    /// </summary>
    public bool IsDragActive()
    {
        bool dragActive = isDraggingActive && draggedCardUI != null;
        
        // Detailed logging for debugging hover issues
        if (dragActive)
        {
            string draggedCardName = draggedCardUI?.GetCardData()?.cardName ?? "Unknown";
            Debug.Log($"[HandController] IsDragActive() = TRUE - Currently dragging: {draggedCardName}");
        }
        
        return dragActive;
    }
    
    /// <summary>
    /// Gibt den Hand-Container zurück (für CardUI Drag-Validation)
    /// </summary>
    public Transform GetHandContainer()
    {
        return handContainer;
    }
    
    /// <summary>
    /// Deaktiviert alle Hover-Effekte (während Drag)
    /// </summary>
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
    
    /// <summary>
    /// Aktiviert alle Hover-Effekte wieder
    /// </summary>
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
    
    /// <summary>
    /// Entfernt Karte aus Layout für Drag (SOFORTIGE Neuanordnung)
    /// </summary>
    public void RemoveCardForDrag(GameObject card)
    {
        draggedCard = card;
        // Entferne aus der Liste für saubere Neuanordnung
        activeCardUIs.Remove(card);
        
        // SOFORTIGES Layout-Update ohne Animation für lückenlose Anordnung
        UpdateCardLayout(true); // true = instant update
    }
    
    /// <summary>
    /// Fügt Karte zurück zur Hand nach Drag
    /// </summary>
    public void AddCardBackToHand(GameObject card)
    {
        Debug.Log($"[HandController] AddCardBackToHand - Processing card: {card?.name}");
        
        if (!activeCardUIs.Contains(card))
        {
            activeCardUIs.Add(card);
            Debug.Log($"[HandController] Added card back to activeCardUIs list");
        }
        else
        {
            Debug.Log($"[HandController] Card already in activeCardUIs list");
        }
        
        // CRITICAL: Reset drag state immediately to prevent hanging
        draggedCard = null;
        
        // CRITICAL: Cancel any active tweens on this card that might cause hanging
        LeanTween.cancel(card);
        
        // CRITICAL: Force card back to parent and reset transform
        card.transform.SetParent(handContainer, false);
        card.transform.localScale = Vector3.one;
        card.transform.localRotation = Quaternion.identity;
        
        // Sortiere die Karten nach ihrer X-Position für korrekte Reihenfolge
        activeCardUIs.Sort((a, b) => 
        {
            if (a == null || b == null) return 0;
            float xA = a.GetComponent<RectTransform>().anchoredPosition.x;
            float xB = b.GetComponent<RectTransform>().anchoredPosition.x;
            return xA.CompareTo(xB);
        });
        
        Debug.Log($"[HandController] Calling UpdateCardLayout for card return - force immediate");
        
        // CRITICAL: Force immediate layout update AND disable fanning to prevent hanging
        isFanned = false;
        isTouching = false;
        
        // Sofortiges Layout-Update für saubere Rückkehr
        UpdateCardLayout(true); // true = instant update
        
        Debug.Log($"[HandController] AddCardBackToHand completed successfully");
    }
    
    /// <summary>
    /// Bestimmt welche Karte unter der Touch/Mouse-Position ist
    /// CRITICAL: Kontinuierliches Tracking für korrekte Kartenauswahl
    /// </summary>
    private void UpdateCardSelectionAtPosition(Vector2 screenPosition)
    {
        // KRITISCH: Keine Updates wenn wir gerade eine Karte spielen ODER draggen
        if (isPlayingCard || isDraggingActive)
        {
            Debug.Log($"[HandController] UpdateCardSelectionAtPosition BLOCKED - card is being played or dragged (isPlayingCard={isPlayingCard}, isDraggingActive={isDraggingActive})");
            return;
        }
        
        // Debug: Vorheriger Zustand
        CardUI previousHovered = hoveredCard;
        
        // Finde Karte unter der Position
        PointerEventData pointerData = new PointerEventData(EventSystem.current)
        {
            position = screenPosition
        };
        
        List<RaycastResult> results = new List<RaycastResult>();
        EventSystem.current.RaycastAll(pointerData, results);
        
        CardUI newHoveredCard = null;
        float closestDistance = float.MaxValue;
        
        // Suche nach CardUI in den Ergebnissen
        foreach (var result in results)
        {
            CardUI cardUI = result.gameObject.GetComponent<CardUI>();
            if (cardUI != null && activeCardUIs.Contains(result.gameObject))
            {
                // Berechne Distanz zum Kartenzentrum für präzisere Auswahl
                RectTransform cardRect = result.gameObject.GetComponent<RectTransform>();
                Vector2 localPoint;
                RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    cardRect, screenPosition, canvasCamera, out localPoint);
                
                float distance = localPoint.magnitude;
                if (distance < closestDistance)
                {
                    closestDistance = distance;
                    newHoveredCard = cardUI;
                }
            }
        }
        
        // HYSTERESE-LOGIK: Verhindere Flackern an Kartengrenzen
        bool shouldChangeHover = false;
        
        if (newHoveredCard != previousHovered)
        {
            // Wenn keine vorherige Karte gehovert war, wechsle sofort
            if (previousHovered == null)
            {
                shouldChangeHover = true;
                isHysteresisActive = false;
            }
            // Wenn neue Karte null ist (Finger außerhalb aller Karten), wechsle sofort
            else if (newHoveredCard == null)
            {
                shouldChangeHover = true;
                isHysteresisActive = false;
            }
            // Ansonsten prüfe Hysterese
            else
            {
                // Berechne Distanz seit letztem Hover-Wechsel
                float distanceFromLastHover = Vector2.Distance(screenPosition, lastHoverPosition);
                
                // Wenn Hysterese aktiv ist, prüfe ob Schwellenwert überschritten
                if (isHysteresisActive)
                {
                    if (distanceFromLastHover >= hoverHysteresisDistance)
                    {
                        shouldChangeHover = true;
                        isHysteresisActive = false;
                        Debug.Log($"[HandController] Hysteresis threshold reached: {distanceFromLastHover:F1}px >= {hoverHysteresisDistance}px");
                    }
                    else
                    {
                        // Bleibe bei aktueller Karte
                        Debug.Log($"[HandController] Hysteresis active: {distanceFromLastHover:F1}px < {hoverHysteresisDistance}px - staying on {previousHovered.GetCardData()?.cardName}");
                    }
                }
                else
                {
                    // Erste Bewegung zu neuer Karte - aktiviere Hysterese
                    shouldChangeHover = true;
                    isHysteresisActive = true;
                }
            }
        }
        
        // Führe Hover-Wechsel nur aus wenn erlaubt
        if (shouldChangeHover && newHoveredCard != previousHovered)
        {
            // Speichere Position für nächste Hysterese-Berechnung
            lastHoverPosition = screenPosition;
            
            // Alte Karte dehovern
            if (previousHovered != null)
            {
                previousHovered.ForceExitHover();
            }
            
            // Neue Karte hovern (kann auch null sein)
            hoveredCard = newHoveredCard;
            if (hoveredCard != null)
            {
                hoveredCard.ForceEnterHover();
                // KRITISCH: Setze lastHoveredCard NUR wenn wir aktiv touchen und nicht schon am spielen sind
                if (isTouching && !isPlayingCard)
                {
                    lastHoveredCard = hoveredCard;
                    Debug.Log($"[HandController] *** LAST HOVERED UPDATED *** Set lastHoveredCard to: '{lastHoveredCard.GetCardData()?.cardName}'");
                    
                    // NEUE LOGIK: Informiere alle Karten über die Änderung
                    NotifyLastHoveredCardChanged();
                }
                else
                {
                    Debug.Log($"[HandController] *** LAST HOVERED BLOCKED *** Not updating lastHoveredCard to '{hoveredCard.GetCardData()?.cardName}' - touching:{isTouching}, playing:{isPlayingCard}");
                }
            }
            
            // Update Card Preview
            UpdateCardPreview();
            
            string previousName = previousHovered != null ? previousHovered.GetCardData()?.cardName ?? "NULL" : "none";
            string newName = hoveredCard != null ? hoveredCard.GetCardData()?.cardName ?? "NULL" : "none";
            string lastHoveredName = lastHoveredCard != null ? lastHoveredCard.GetCardData()?.cardName ?? "NULL" : "none";
            Debug.Log($"[HandController] *** FINGER TRACKING *** Finger moved from '{previousName}' to '{newName}' (lastHovered: '{lastHoveredName}') at {screenPosition}");
            
            // NEU: Drift-Erkennung - Hat sich der Finger von der ursprünglichen Karte wegbewegt?
            // WICHTIG: Wenn keine Karte initial berührt wurde (initialHoveredCard == null), 
            // dann setze die erste berührte Karte als Referenz
            if (initialHoveredCard == null && hoveredCard != null && !hasChangedCards)
            {
                // Erste Karte berührt - setze als Referenz
                initialHoveredCard = hoveredCard;
                Debug.Log($"[HandController] *** INITIAL CARD SET *** First card touched: '{newName}' - using as drift reference");
            }
            else if (initialHoveredCard != null && hoveredCard != null && hoveredCard != initialHoveredCard && !hasChangedCards)
            {
                // WICHTIG: Prüfe ob es wirklich verschiedene Karten-Objekte sind
                // (nicht nur verschiedene Referenzen auf das gleiche Objekt)
                bool isDifferentCard = initialHoveredCard.gameObject != hoveredCard.gameObject;
                
                if (isDifferentCard)
                {
                    // Drift erkannt - Finger hat von initialHoveredCard zu einer anderen Karte gewechselt
                    hasChangedCards = true;
                    string initialCardName = initialHoveredCard.GetCardData()?.cardName ?? "NULL";
                    
                    // DEBUG: Zusätzliche Informationen für Fehlersuche
                    int initialIndex = activeCardUIs.IndexOf(initialHoveredCard.gameObject);
                    int currentIndex = activeCardUIs.IndexOf(hoveredCard.gameObject);
                    Debug.Log($"[HandController] *** CARD DRIFT DETECTED *** Finger moved away from initial card '{initialCardName}' (index: {initialIndex}) to '{newName}' (index: {currentIndex}) - DRAG WILL BE BLOCKED");
                    
                    // Extra debug for same-name cards
                    if (initialCardName == newName)
                    {
                        Debug.LogError($"[HandController] WARNING: Drift detected between cards with same name! Initial obj: {initialHoveredCard.gameObject.GetInstanceID()}, Current obj: {hoveredCard.gameObject.GetInstanceID()}");
                    }
                }
            }
        }
    }
    
    /// <summary>
    /// LEGACY: Fügt eine Karte zur Hand hinzu (wird von alten Events aufgerufen)
    /// </summary>
    private void AddCardToHand(TimeCardData cardData)
    {
        Debug.Log($"[HandController] LEGACY AddCardToHand called for: {cardData?.cardName}");
        // Ignorieren - UpdateHandDisplay kümmert sich darum
    }
    
    /// <summary>
    /// LEGACY: Entfernt eine Karte aus der Hand (wird von alten Events aufgerufen)
    /// </summary>
    private void RemoveCardFromHand(TimeCardData cardData)
    {
        Debug.Log($"[HandController] LEGACY RemoveCardFromHand called for: {cardData?.cardName}");
        // Ignorieren - UpdateHandDisplay kümmert sich darum
    }
    
    /// <summary>
    /// LEGACY: Wird von alten CardUI-Implementierungen aufgerufen - jetzt ignoriert
    /// </summary>
    public void PlayCardFromDrag(CardUI cardUI)
    {
        Debug.LogWarning($"[HandController] PlayCardFromDrag LEGACY call ignored for {cardUI?.GetCardData()?.cardName} - using centralized drag system");
        // Diese Methode wird nicht mehr verwendet - das neue zentralisierte System übernimmt
    }
    
    /// <summary>
    /// Coroutine um das isPlayingCard Flag nach einer kurzen Delay zurückzusetzen
    /// </summary>
    private System.Collections.IEnumerator ResetPlayingCardFlag()
    {
        yield return new WaitForSeconds(1.0f); // LÄNGERE Delay um Endlosschleife zu verhindern
        isPlayingCard = false;
        Debug.Log($"[HandController] GUARD RESET - isPlayingCard flag cleared after 1 second");
    }
    
    /// <summary>
    /// ⭐ ZENTRALE DRAG-START METHODE ⭐
    /// 
    /// Startet eine Drag-Operation mit der Karte, die sich AKTUELL unter dem Finger befindet.
    /// Dies ist der Kern des neuen Systems: Anstatt die Karte zu draggen, wo der Touch begann,
    /// draggen wir die Karte, über der sich der Finger JETZT befindet.
    /// 
    /// ABLAUF:
    /// 1. Bestimme Ziel-Karte (hoveredCard = aktuell, lastHoveredCard = Fallback)
    /// 2. Validiere Karte (existiert, ist spielbar)
    /// 3. Aktiviere Drag-Modus und setze Flags
    /// 4. Bereite Karte visuell vor (aus Layout entfernen, Effekte deaktivieren)
    /// 5. Starte Hover-Animation auf Ziel-Karte
    /// </summary>
    private void StartDragOperation()
    {
        // KRITISCH: Wähle die Karte unter dem AKTUELLEN Finger, nicht dem Start-Finger!
        // hoveredCard = Karte direkt unter Finger (kann null sein wenn außerhalb Karten)
        // lastHoveredCard = Letzte bekannte Karte (bleibt gesetzt, robuster Fallback)
        CardUI cardToDrag = hoveredCard ?? lastHoveredCard;
        
        // EXTRA FALLBACK: Wenn beide null sind, versuche die initialHoveredCard
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
        
        // Benachrichtige die Karte über Drag-Start
        cardToDrag.OnCentralDragStart();
        
        // Entferne Karte aus Layout
        RemoveCardForDrag(cardToDrag.gameObject);
        DisableAllHoverEffects();
        
        // Hide card preview when dragging starts
        HideCardPreview();
        
        // Visuelle Anpassungen
        cardToDrag.transform.SetAsLastSibling();
        LeanTween.rotateLocal(cardToDrag.gameObject, Vector3.zero, 0.08f).setEase(LeanTweenType.easeOutExpo);
    }
    
    /// <summary>
    /// NEUE METHODE: Bewegt die gedraggte Karte zur angegebenen Position
    /// </summary>
    private void MoveDraggedCardToPosition(Vector2 screenPosition)
    {
        if (draggedCardUI == null) return;
        
        // CRITICAL: Continuously ensure all other cards have hover disabled during drag
        foreach (var cardObj in activeCardUIs)
        {
            if (cardObj != null && cardObj != draggedCard)
            {
                var cardUI = cardObj.GetComponent<CardUI>();
                if (cardUI != null && cardUI.gameObject != draggedCardUI.gameObject)
                {
                    // Force disable hover on any card that isn't the dragged card
                    cardUI.ForceDisableHover();
                }
            }
        }
        
        // Konvertiere Screen-Position zu World-Position
        Vector3 worldPoint;
        RectTransformUtility.ScreenPointToWorldPointInRectangle(
            draggedCardUI.transform.parent as RectTransform,
            screenPosition,
            canvasCamera,
            out worldPoint
        );
        
        draggedCardUI.transform.position = worldPoint;
        
        // Visuelles Feedback basierend auf Position
        float screenHeight = Screen.height;
        float playZoneY = screenHeight * 0.5f;
        
        if (screenPosition.y > playZoneY)
        {
            // In der Spielzone - größer machen
            draggedCardUI.transform.localScale = Vector3.one * 1.2f;
        }
        else
        {
            // In der Hand - normale Drag-Größe
            draggedCardUI.transform.localScale = Vector3.one * 1.1f;
        }
    }
    
    /// <summary>
    /// NEUE METHODE: Beendet die Drag-Operation
    /// </summary>
    private void EndDragOperation()
    {
        if (!isDraggingActive || draggedCardUI == null)
        {
            Debug.Log("[HandController] EndDragOperation - no active drag");
            return;
        }
        
        float screenHeight = Screen.height;
        float playZoneY = screenHeight * 0.5f;
        
        if (lastDragPosition.y > playZoneY)
        {
            // Karte in Spielzone gedraggt - spiele sie
            Debug.Log($"[HandController] Playing dragged card: {draggedCardUI.GetCardData()?.cardName}");
            PlayDraggedCard();
        }
        else
        {
            // Karte zurück zur Hand
            Debug.Log($"[HandController] Returning dragged card to hand: {draggedCardUI.GetCardData()?.cardName}");
            ReturnDraggedCardToHand();
        }
        
        // Reset Drag-State
        isDraggingActive = false;
        draggedCardUI = null;
        draggedCard = null;
        
        EnableAllHoverEffects();
    }
    
    /// <summary>
    /// NEUE METHODE: Spielt die gedraggte Karte
    /// </summary>
    private void PlayDraggedCard()
    {
        if (draggedCardUI == null) return;
        
        isPlayingCard = true;
        TimeCardData cardData = draggedCardUI.GetCardData();
        
        Debug.Log($"[HandController] *** CENTRALIZED CARD PLAY *** Playing: {cardData?.cardName}");
        
        // Spiele die Karte über das Combat-System
        if (RiftCombatManager.Instance != null && ZeitwaechterPlayer.Instance != null)
        {
            RiftCombatManager.Instance.PlayerWantsToPlayCard(cardData, ZeitwaechterPlayer.Instance);
        }
        
        // Entferne die Karte aus der Hand
        if (activeCardUIs.Contains(draggedCardUI.gameObject))
        {
            activeCardUIs.Remove(draggedCardUI.gameObject);
        }
        
        // Zerstöre das GameObject
        Destroy(draggedCardUI.gameObject);
        
        // Reset Referenzen
        hoveredCard = null;
        lastHoveredCard = null;
        
        // Reset Guard nach Delay
        StartCoroutine(ResetPlayingCardFlag());
    }
    
    /// <summary>
    /// NEUE METHODE: Gibt die gedraggte Karte zur Hand zurück
    /// </summary>
    private void ReturnDraggedCardToHand()
    {
        if (draggedCardUI == null) return;
        
        Debug.Log($"[HandController] ReturnDraggedCardToHand - Starting return process for {draggedCardUI.GetCardData()?.cardName}");
        
        // CRITICAL: Cancel all active tweens on the dragged card first to prevent hanging
        LeanTween.cancel(draggedCardUI.gameObject);
        
        // Reset card scale and rotation immediately to prevent visual glitches
        draggedCardUI.transform.localScale = Vector3.one;
        draggedCardUI.transform.localRotation = Quaternion.identity;
        
        // CRITICAL: Reset any drag-related states immediately to prevent hanging
        draggedCardUI.SetInLayoutAnimation(false);
        
        // Benachrichtige die Karte über Drag-Ende
        draggedCardUI.OnCentralDragEnd();
        
        // Füge die Karte zurück zum Layout hinzu
        AddCardBackToHand(draggedCardUI.gameObject);
        
        Debug.Log($"[HandController] ReturnDraggedCardToHand - Completed return process");
    }
    
    /// <summary>
    /// NEUE METHODE: Prüft ob eine Karte spielbar ist
    /// </summary>
    private bool IsCardPlayable(TimeCardData cardData)
    {
        if (cardData == null) return false;
        
        if (RiftTimeSystem.Instance != null)
        {
            float currentTime = RiftTimeSystem.Instance.GetCurrentTime();
            float cardCost = cardData.GetScaledTimeCost();
            return currentTime >= cardCost;
        }
        
        return true; // Fallback wenn TimeSystem nicht verfügbar
    }
    
    /// <summary>
    /// Benachrichtigt alle Karten, dass sich die lastHoveredCard geändert hat
    /// </summary>
    private void NotifyLastHoveredCardChanged()
    {
        // Diese Methode wird aufgerufen wenn sich die lastHoveredCard ändert
        // Karten können dann ihr Drag-Verhalten anpassen
        Debug.Log($"[HandController] Notifying all cards about lastHoveredCard change");
    }
    
    /// <summary>
    /// Aktualisiert die Karten-Vorschau basierend auf der aktuell gehoverten Karte
    /// </summary>
    private void UpdateCardPreview()
    {
        if (hoveredCard != null && isTouching && !isDraggingActive)
        {
            // Show or update preview
            ShowCardPreview(hoveredCard);
        }
        else
        {
            // Hide preview
            HideCardPreview();
        }
    }
    
    /// <summary>
    /// Zeigt die Karten-Vorschau für die angegebene Karte
    /// </summary>
    private void ShowCardPreview(CardUI card)
    {
        if (card == null || card.GetCardData() == null) return;
        
        // Create preview if it doesn't exist
        if (cardPreview == null)
        {
            CreateCardPreview();
        }
        
        if (cardPreview == null) return;
        
        // Update preview content
        if (cardPreviewUI != null)
        {
            cardPreviewUI.SetCardData(card.GetCardData());
        }
        
        // Position preview in center of screen with offset
        RectTransform previewRect = cardPreview.GetComponent<RectTransform>();
        if (previewRect != null)
        {
            previewRect.anchoredPosition = previewOffset;
        }
        
        // Show with fade in
        if (previewCanvasGroup != null)
        {
            cardPreview.SetActive(true);
            LeanTween.cancel(cardPreview);
            LeanTween.alphaCanvas(previewCanvasGroup, 1f, previewFadeInTime).setEase(LeanTweenType.easeOutQuad);
        }
        
        Debug.Log($"[HandController] Showing card preview for: {card.GetCardData().cardName}");
    }
    
    /// <summary>
    /// Versteckt die Karten-Vorschau
    /// </summary>
    private void HideCardPreview()
    {
        if (cardPreview == null || !cardPreview.activeSelf) return;
        
        if (previewCanvasGroup != null)
        {
            LeanTween.cancel(cardPreview);
            LeanTween.alphaCanvas(previewCanvasGroup, 0f, previewFadeOutTime)
                .setEase(LeanTweenType.easeOutQuad)
                .setOnComplete(() => {
                    cardPreview.SetActive(false);
                });
        }
        else
        {
            cardPreview.SetActive(false);
        }
        
        Debug.Log("[HandController] Hiding card preview");
    }
    
    /// <summary>
    /// Erstellt das Vorschau-GameObject
    /// </summary>
    private void CreateCardPreview()
    {
        if (cardUIPrefab == null || parentCanvas == null) return;
        
        // Create preview as child of canvas (not handContainer)
        Transform canvasTransform = parentCanvas.transform;
        cardPreview = Instantiate(cardUIPrefab, canvasTransform);
        cardPreview.name = "CardPreview";
        
        // Setup RectTransform
        RectTransform previewRect = cardPreview.GetComponent<RectTransform>();
        if (previewRect != null)
        {
            // Center anchors
            previewRect.anchorMin = Vector2.one * 0.5f;
            previewRect.anchorMax = Vector2.one * 0.5f;
            previewRect.pivot = Vector2.one * 0.5f;
            
            // Apply scale
            previewRect.localScale = Vector3.one * previewScale;
            
            // Ensure it's on top
            cardPreview.transform.SetAsLastSibling();
        }
        
        // Get CardUI component
        cardPreviewUI = cardPreview.GetComponent<CardUI>();
        if (cardPreviewUI != null)
        {
            // Disable interactions on preview
            cardPreviewUI.enabled = false; // Disable all hover/click functionality
        }
        
        // Add CanvasGroup for fading
        previewCanvasGroup = cardPreview.GetComponent<CanvasGroup>();
        if (previewCanvasGroup == null)
        {
            previewCanvasGroup = cardPreview.AddComponent<CanvasGroup>();
        }
        previewCanvasGroup.alpha = 0f;
        previewCanvasGroup.interactable = false;
        previewCanvasGroup.blocksRaycasts = false;
        
        // Start hidden
        cardPreview.SetActive(false);
        
        Debug.Log("[HandController] Created card preview GameObject");
    }
    
    void OnDestroy()
    {
        if (player != null)
        {
            // Instanz-Event abmelden
            player.OnHandChanged -= UpdateHandDisplay;
        }
        
        // Clean up card preview
        if (cardPreview != null)
        {
            Destroy(cardPreview);
        }
        
        // NO LEGACY EVENTS to unsubscribe
    }
    
    /// <summary>
    /// Debug coroutine to check any card position after a frame
    /// </summary>
    private System.Collections.IEnumerator CheckCardPositionAfterFrame(GameObject card, Vector3 expectedPosition, int cardIndex)
    {
        yield return null; // Wait one frame
        
        if (card != null)
        {
            Vector3 actualPosition = card.transform.localPosition;
            if (Mathf.Abs(actualPosition.y - expectedPosition.y) > 0.1f)
            {
                Debug.LogError($"[HandController] CARD {cardIndex} POSITION CHANGED! Expected: {expectedPosition}, Actual: {actualPosition}");
                
                // Check for animator
                Animator animator = card.GetComponent<Animator>();
                if (animator != null && animator.enabled)
                {
                    Debug.LogError($"[HandController] FOUND ACTIVE ANIMATOR on Card {cardIndex}! This could be overriding positions.");
                }
                
                // Check all components
                Component[] components = card.GetComponents<Component>();
                foreach (var comp in components)
                {
                    if (comp != null && !(comp is Transform) && !(comp is RectTransform))
                    {
                        Debug.LogError($"[HandController] Card {cardIndex} has component: {comp.GetType().Name}");
                    }
                }
                
                // CRITICAL FIX: Force correct the position and disable hover
                Debug.LogError($"[HandController] FORCING Card {cardIndex} back to expected position!");
                card.transform.localPosition = expectedPosition;
                card.transform.localScale = Vector3.one;
                
                // CRITICAL: Ensure SiblingIndex is correct
                int currentSiblingIndex = card.transform.GetSiblingIndex();
                if (currentSiblingIndex != cardIndex)
                {
                    Debug.LogError($"[HandController] Also fixing Card {cardIndex} SiblingIndex! Was: {currentSiblingIndex}, setting to: {cardIndex}");
                    card.transform.SetSiblingIndex(cardIndex);
                }
                
                CardUI cardUI = card.GetComponent<CardUI>();
                if (cardUI != null)
                {
                    cardUI.ForceDisableHover();
                    cardUI.SetInLayoutAnimation(false);
                    // Update base position to prevent further drift
                    cardUI.UpdateBasePosition(expectedPosition);
                }
                
                // AGGRESSIVE FIX: Monitor for additional position changes
                StartCoroutine(MonitorCardPosition(card, expectedPosition, cardIndex, 5)); // Monitor for 5 more frames
            }
        }
    }
    
    /// <summary>
    /// Aggressively monitors any card position to prevent drift
    /// </summary>
    private System.Collections.IEnumerator MonitorCardPosition(GameObject card, Vector3 expectedPosition, int cardIndex, int framesToMonitor)
    {
        Debug.LogError($"[HandController] Starting aggressive monitoring of Card {cardIndex} position for {framesToMonitor} frames");
        
        for (int frame = 0; frame < framesToMonitor; frame++)
        {
            yield return null; // Wait one frame
            
            if (card != null)
            {
                Vector3 currentPosition = card.transform.localPosition;
                if (Mathf.Abs(currentPosition.y - expectedPosition.y) > 0.1f)
                {
                    Debug.LogError($"[HandController] FRAME {frame}: Card {cardIndex} position drifted again! Expected: {expectedPosition}, Actual: {currentPosition}");
                    Debug.LogError($"[HandController] FORCING Card {cardIndex} back to correct position (Frame {frame})!");
                    
                    // Force correct position immediately
                    card.transform.localPosition = expectedPosition;
                    card.transform.localScale = Vector3.one;
                    
                    // CRITICAL: Ensure SiblingIndex is correct 
                    int currentSiblingIndex = card.transform.GetSiblingIndex();
                    if (currentSiblingIndex != cardIndex)
                    {
                        Debug.LogError($"[HandController] FRAME {frame}: Also fixing Card {cardIndex} SiblingIndex! Was: {currentSiblingIndex}, setting to: {cardIndex}");
                        card.transform.SetSiblingIndex(cardIndex);
                    }
                    
                    // Cancel any active tweens that might be causing this
                    LeanTween.cancel(card);
                    
                    CardUI cardUI = card.GetComponent<CardUI>();
                    if (cardUI != null)
                    {
                        cardUI.ForceDisableHover();
                        cardUI.SetInLayoutAnimation(false);
                        cardUI.UpdateBasePosition(expectedPosition);
                    }
                }
            }
        }
        
        Debug.LogError($"[HandController] Finished monitoring Card {cardIndex} position for {framesToMonitor} frames");
    }
    
    /// <summary>
    /// CRITICAL DEBUG: Monitor Card 3's SiblingIndex changes in real-time
    /// </summary>
    private System.Collections.IEnumerator MonitorCard3SiblingIndex(GameObject card)
    {
        if (card == null) yield break;
        
        Debug.LogError($"[HandController] === STARTING CARD 3 SIBLINGINDEX MONITORING ===");
        
        int expectedIndex = 3;
        CardUI cardUI = card.GetComponent<CardUI>();
        string cardName = cardUI?.GetCardData()?.cardName ?? "Unknown";
        
        // Monitor every frame for 2 seconds
        float totalTime = 2f;
        float elapsedTime = 0f;
        int lastSiblingIndex = card.transform.GetSiblingIndex();
        
        Debug.LogError($"[HandController] Card 3 ({cardName}) initial SiblingIndex: {lastSiblingIndex}");
        
        while (elapsedTime < totalTime)
        {
            yield return null; // Wait one frame
            elapsedTime += Time.deltaTime;
            
            if (card != null)
            {
                int currentSiblingIndex = card.transform.GetSiblingIndex();
                
                // Log any changes
                if (currentSiblingIndex != lastSiblingIndex)
                {
                    Debug.LogError($"[HandController] CARD 3 SIBLINGINDEX CHANGED! Time: {elapsedTime:F3}s, From: {lastSiblingIndex} To: {currentSiblingIndex}");
                    Debug.LogError($"[HandController] Card 3 position: {card.transform.localPosition}, scale: {card.transform.localScale}");
                    
                    // Check if hover state is involved
                    if (cardUI != null)
                    {
                        Debug.LogError($"[HandController] Card 3 hover-related state at time of SiblingIndex change");
                    }
                    
                    lastSiblingIndex = currentSiblingIndex;
                }
                
                // Check for wrong SiblingIndex and fix it
                if (currentSiblingIndex != expectedIndex)
                {
                    Debug.LogError($"[HandController] FIXING Card 3 wrong SiblingIndex at {elapsedTime:F3}s! Was: {currentSiblingIndex}, setting to: {expectedIndex}");
                    card.transform.SetSiblingIndex(expectedIndex);
                }
            }
        }
        
        Debug.LogError($"[HandController] === FINISHED CARD 3 SIBLINGINDEX MONITORING ===");
    }
    
    /// <summary>
    /// CRITICAL: Checks if Card 3 is stuck in hover state and fixes it
    /// </summary>
    private System.Collections.IEnumerator FixCard3IfStuckInHover()
    {
        yield return new WaitForSeconds(0.2f); // Wait for layout to complete
        
        if (activeCardUIs.Count >= 4) // Ensure Card 3 exists
        {
            GameObject card3 = activeCardUIs[3];
            if (card3 != null)
            {
                CardUI cardUI = card3.GetComponent<CardUI>();
                int siblingIndex = card3.transform.GetSiblingIndex();
                Vector3 scale = card3.transform.localScale;
                Vector3 position = card3.transform.localPosition;
                
                // Check if Card 3 is stuck in hover state
                bool wrongSiblingIndex = siblingIndex != 3;
                bool wrongScale = Mathf.Abs(scale.x - 1f) > 0.01f;
                bool wrongYPosition = Mathf.Abs(position.y - 12.5f) > 1f; // Allow small variance
                
                if (wrongSiblingIndex || wrongScale || wrongYPosition)
                {
                    string cardName = cardUI?.GetCardData()?.cardName ?? "Unknown";
                    Debug.LogError($"[HandController] *** CARD 3 STUCK IN HOVER STATE DETECTED ***");
                    Debug.LogError($"[HandController] Card 3 ({cardName}) - SiblingIndex: {siblingIndex} (should be 3), Scale: {scale} (should be 1), Position: {position}");
                    
                    // FORCE FIX Card 3
                    Debug.LogError($"[HandController] *** FORCE FIXING CARD 3 ***");
                    
                    // Fix SiblingIndex
                    if (wrongSiblingIndex)
                    {
                        card3.transform.SetSiblingIndex(3);
                        Debug.LogError($"[HandController] Fixed Card 3 SiblingIndex from {siblingIndex} to 3");
                    }
                    
                    // Fix Scale
                    if (wrongScale)
                    {
                        card3.transform.localScale = Vector3.one;
                        Debug.LogError($"[HandController] Fixed Card 3 scale from {scale} to (1,1,1)");
                    }
                    
                    // Fix Position (recalculate correct position)
                    if (wrongYPosition)
                    {
                        // Recalculate Card 3 position (index 3 of 5 cards)
                        float normalizedPos = 3f / 4f; // 0.75
                        float curveT = (normalizedPos - 0.5f) * 2f; // 0.5
                        float curveInput = 1f - Mathf.Abs(curveT); // 0.5
                        float curveValue = layoutCurve.Evaluate(curveInput); // Should be 0.5
                        float correctY = curveValue * curveHeight; // Should be 12.5
                        
                        Vector3 correctPosition = new Vector3(position.x, correctY, position.z);
                        card3.transform.localPosition = correctPosition;
                        Debug.LogError($"[HandController] Fixed Card 3 position from {position} to {correctPosition}");
                        
                        // Update base position in CardUI
                        if (cardUI != null)
                        {
                            cardUI.UpdateBasePosition(correctPosition);
                        }
                    }
                    
                    // Force disable hover to reset internal state
                    if (cardUI != null)
                    {
                        cardUI.ForceDisableHover();
                        Debug.LogError($"[HandController] Force disabled hover on Card 3 after fixing");
                    }
                }
                else
                {
                    Debug.Log($"[HandController] Card 3 position check: looks correct (SiblingIndex: {siblingIndex}, Scale: {scale.x}, Y: {position.y})");
                }
            }
        }
    }
    
    /// <summary>
    /// Ensures all cards have the correct SiblingIndex (Card i = SiblingIndex i)
    /// This is a FALLBACK for when hover restoration fails, not the primary mechanism
    /// Cards should still SetAsLastSibling() during hover for better visibility!
    /// </summary>
    private void EnsureCorrectSiblingOrder()
    {
        Debug.Log($"[HandController] Ensuring correct SiblingIndex order for all {activeCardUIs.Count} cards");
        
        bool foundIssues = false;
        for (int i = 0; i < activeCardUIs.Count; i++)
        {
            if (activeCardUIs[i] != null)
            {
                int currentSiblingIndex = activeCardUIs[i].transform.GetSiblingIndex();
                if (currentSiblingIndex != i)
                {
                    foundIssues = true;
                    var cardUI = activeCardUIs[i].GetComponent<CardUI>();
                    string cardName = cardUI?.GetCardData()?.cardName ?? "Unknown";
                    
                    // Check if this card is currently being hovered
                    bool isCurrentlyHovered = cardUI != null && cardUI.gameObject == hoveredCard?.gameObject;
                    
                    if (!isCurrentlyHovered)
                    {
                        Debug.LogError($"[HandController] FIXING SiblingIndex: Card {i} ({cardName}) had SiblingIndex {currentSiblingIndex}, setting to {i}");
                        activeCardUIs[i].transform.SetSiblingIndex(i);
                        
                        // Inform CardUI that we reset its SiblingIndex
                        if (cardUI != null)
                        {
                            cardUI.GetType().GetField("originalSiblingIndex", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance)?.SetValue(cardUI, -1);
                        }
                    }
                    else
                    {
                        Debug.Log($"[HandController] Skipping SiblingIndex fix for Card {i} ({cardName}) - currently being hovered");
                    }
                }
            }
        }
        
        if (!foundIssues)
        {
            Debug.Log($"[HandController] All cards have correct SiblingIndex order");
        }
        else
        {
            Debug.LogError($"[HandController] Fixed SiblingIndex issues - cards should now render in correct order");
        }
    }
}