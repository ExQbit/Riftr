using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using TMPro;
using System;
using System.Collections.Generic;

/// <summary>
/// 🃏 UI-KOMPONENTE FÜR EINZELNE HANDKARTE 🃏
/// 
/// WICHTIGE ARCHITEKTUR-ÄNDERUNG:
/// Diese Klasse implementiert KEIN eigenes Drag-System mehr!
/// Stattdessen wird sie vom HandController zentral verwaltet.
/// 
/// WARUM?
/// Unity's IBeginDragHandler/IDragHandler/IEndDragHandler sendet Events immer an die
/// Karte wo der Touch BEGANN, nicht wo sich der Finger AKTUELL befindet.
/// → Das führte zu verwirrenden UX wo Karte A visuell gedraggt wird aber Karte B gespielt wird.
/// 
/// NEUE VERANTWORTUNGEN:
/// ✅ Karteninhalt anzeigen (Name, Kosten, etc.)
/// ✅ Hover-Effekte (von HandController gesteuert)  
/// ✅ Click-Events für direkte Kartenspiel
/// ✅ Zentrale Drag-Integration (OnCentralDragStart/End)
/// 
/// ENTFERNTE VERANTWORTUNGEN:
/// ❌ Eigene Drag-Event-Behandlung (jetzt zentral)
/// ❌ Schwellenwert-Erkennung (jetzt im HandController)
/// ❌ Drag-Position-Tracking (jetzt zentral)
/// ❌ Spielbereich-Erkennung (jetzt zentral)
/// 
/// INTERFACES:
/// - IPointerClickHandler ✅ (für direkte Clicks)
/// - IPointerEnterHandler ✅ (für Hover-Start) 
/// - IPointerExitHandler ✅ (für Hover-Ende)
/// - IBeginDragHandler ❌ ENTFERNT (jetzt zentral)
/// - IDragHandler ❌ ENTFERNT (jetzt zentral)  
/// - IEndDragHandler ❌ ENTFERNT (jetzt zentral)
/// </summary>
public class CardUI : MonoBehaviour, IPointerClickHandler, IPointerEnterHandler, IPointerExitHandler
{
    [Header("UI-Elemente")]
    [SerializeField] private TextMeshProUGUI nameText;
    [SerializeField] private TextMeshProUGUI costText;
    [SerializeField] private TextMeshProUGUI damageText;
    [SerializeField] private TextMeshProUGUI descriptionText;
    [SerializeField] private Image cardBackground;
    [SerializeField] private Image cardArt;
    [SerializeField] private GameObject highlightEffect;
    
    [Header("Farben")]
    [SerializeField] private Color attackColor = new Color(1f, 0.3f, 0.3f);
    [SerializeField] private Color defenseColor = new Color(0.3f, 0.5f, 1f);
    [SerializeField] private Color timeColor = new Color(0.5f, 1f, 0.5f);
    
    // Events
    public event Action<TimeCardData> OnCardClicked;
    
    // Daten
    private TimeCardData cardData;
    private bool isPlayable = true;
    
    // Drag & Drop - VEREINFACHT für zentralisiertes System
    private bool isDragging = false;
    private Vector3 originalPosition;
    private Vector3 originalRotation;
    private Vector3 originalScale;
    private CanvasGroup canvasGroup;
    private HandController handController;
    
    // Für Click-Erkennung
    private Vector2 pointerStartPosition;
    private int originalSiblingIndex = -1; // Für korrekte Wiederherstellung nach Hover
    
    // Zentralisiertes Drag-System (keine eigenen Drag-Events mehr)
    private bool isBeingDraggedCentrally = false;
    
    // LEGACY: Diese Drag-Parameter werden NICHT MEHR VERWENDET!
    // Das neue zentrale Drag-System läuft über HandController.
    // Diese Felder bleiben nur zur Kompatibilität erhalten.
    [Header("🚫 LEGACY Drag-Einstellungen (NICHT VERWENDET)")]
    [SerializeField] public float dragThreshold = 30f; // LEGACY - wird ignoriert
    [SerializeField] public float verticalDragBias = 1.5f; // LEGACY - wird ignoriert  
    [SerializeField] public float minVerticalSwipe = 15f; // LEGACY - wird ignoriert
    
    [Header("Animation-Einstellungen (NEUE FELDER)")]
    [SerializeField] public float hoverAnimDuration = 0.1f; // Schnellere Hover-Animation
    [SerializeField] public float dragAnimDuration = 0.08f; // Sehr schnelle Drag-Animation
    [SerializeField] public float returnAnimDuration = 0.25f; // Smooth Return
    [SerializeField] public LeanTweenType hoverEaseType = LeanTweenType.easeOutCubic;
    [SerializeField] public LeanTweenType dragEaseType = LeanTweenType.easeOutExpo;
    [SerializeField] public LeanTweenType returnEaseType = LeanTweenType.easeOutBack;
    
    // Hover-State
    private bool isHovered = false;
    private static bool touchStartedInHandArea = false;
    
    // Scaling fix tracking
    private int activeTweenId = -1; // Track active scale tween to cancel it properly
    private bool isInLayoutAnimation = false; // Prevent hover during layout animations
    
    // CRITICAL: Store base position for hover calculations
    private Vector3 basePosition = Vector3.zero; // Position without any hover lift
    private bool hasBasePosition = false;
    
    void Awake()
    {
        // SCALING FIX: FORCE scale to 1 immediately, before any other component runs
        transform.localScale = Vector3.one;
        
        // CRITICAL FIX: Disable any Animator that might be setting scale
        Animator animator = GetComponent<Animator>();
        if (animator != null)
        {
            Debug.LogWarning($"[CardUI] Found Animator on card prefab! Disabling it to prevent scale issues.");
            animator.enabled = false;
        }
        
        // Check for any Animation component (legacy)
        Animation legacyAnim = GetComponent<Animation>();
        if (legacyAnim != null)
        {
            Debug.LogWarning($"[CardUI] Found Animation component on card prefab! Disabling it.");
            legacyAnim.enabled = false;
        }
        
        // Get CanvasGroup if it exists
        canvasGroup = GetComponent<CanvasGroup>();
    }
    
    void Start()
    {
        // SCALING FIX: Double-check scale after all initialization
        if (transform.localScale != Vector3.one)
        {
            Debug.LogWarning($"[CardUI] Scale was not 1 at Start! Was: {transform.localScale}. Fixing...");
            transform.localScale = Vector3.one;
        }
        
        // CRITICAL: Cancel any animations that might be running from prefab
        LeanTween.cancel(gameObject);
    }
    
    void OnDestroy()
    {
        // SCALING FIX: Clean up any running tweens when destroyed
        if (activeTweenId >= 0)
        {
            LeanTween.cancel(activeTweenId);
        }
        LeanTween.cancel(gameObject);
    }
    
    void OnEnable()
    {
        // SCALING FIX: Reset state when card becomes active
        ResetCardState();
    }
    
    /// <summary>
    /// Completely resets the card to a clean state
    /// </summary>
    private void ResetCardState()
    {
        // Cancel ALL animations
        LeanTween.cancel(gameObject);
        
        // Force scale to 1
        transform.localScale = Vector3.one;
        
        // Reset flags
        isHovered = false;
        isDragging = false;
        isBeingDraggedCentrally = false;
        activeTweenId = -1;
        
        // Ensure highlight is off
        if (highlightEffect != null)
            highlightEffect.SetActive(false);
    }
    
    /// <summary>
    /// Setzt die Kartendaten und aktualisiert die Anzeige
    /// </summary>
    public void SetCardData(TimeCardData data)
    {
        if (data == null) return;
        
        cardData = data;
        UpdateDisplay();
    }
    
    /// <summary>
    /// Setzt die Referenz zum HandController
    /// </summary>
    public void SetHandController(HandController controller)
    {
        handController = controller;
    }
    
    /// <summary>
    /// Initialize method for compatibility with HandController
    /// </summary>
    public void Initialize(TimeCardData cardData, HandController controller, Camera camera)
    {
        SetCardData(cardData);
        SetHandController(controller);
    }
    
    /// <summary>
    /// InitializeCard method for compatibility
    /// </summary>
    public void InitializeCard(HandController controller, TimeCardData data, Camera canvasCam)
    {
        // SCALING FIX: Ensure clean state on initialization
        transform.localScale = Vector3.one;
        isHovered = false;
        activeTweenId = -1;
        
        // Cancel any existing tweens on this object (in case of pooling/reuse)
        LeanTween.cancel(gameObject);
        
        SetHandController(controller);
        SetCardData(data);
    }
    
    /// <summary>
    /// IsMouseInput static method for compatibility
    /// </summary>
    public static bool IsMouseInput()
    {
        return Input.mousePresent && Input.touchCount == 0;
    }
    
    /// <summary>
    /// Aktualisiert alle UI-Elemente basierend auf den Kartendaten
    /// </summary>
    private void UpdateDisplay()
    {
        // Name
        if (nameText != null)
            nameText.text = cardData.cardName;
        
        // Zeitkosten (gerundet für Anzeige)
        if (costText != null)
        {
            float displayCost = cardData.GetDisplayTimeCost();
            costText.text = $"{displayCost:F1}s";
        }
        
        // Schaden (nur für Angriffskarten)
        if (damageText != null)
        {
            if (cardData.baseDamage > 0)
            {
                damageText.gameObject.SetActive(true);
                damageText.text = cardData.baseDamage.ToString();
            }
            else
            {
                damageText.gameObject.SetActive(false);
            }
        }
        
        // Beschreibung
        if (descriptionText != null)
            descriptionText.text = cardData.description;
        
        // Karten-Art
        if (cardArt != null && cardData.cardArt != null)
            cardArt.sprite = cardData.cardArt;
        
        // Hintergrundfarbe basierend auf Kartentyp
        if (cardBackground != null)
        {
            switch (cardData.cardType)
            {
                case TimeCardType.Attack:
                    cardBackground.color = attackColor;
                    break;
                case TimeCardType.Defense:
                    cardBackground.color = defenseColor;
                    break;
                case TimeCardType.TimeManipulation:
                    cardBackground.color = timeColor;
                    break;
            }
        }
        
        // Spielbarkeit prüfen
        CheckPlayability();
    }
    
    /// <summary>
    /// Prüft ob die Karte spielbar ist (genug Zeit vorhanden)
    /// </summary>
    private void CheckPlayability()
    {
        if (RiftTimeSystem.Instance != null)
        {
            float currentTime = RiftTimeSystem.Instance.GetCurrentTime();
            float cardCost = cardData.GetScaledTimeCost();
            
            isPlayable = currentTime >= cardCost;
            
            // Visuelles Feedback
            if (cardBackground != null)
            {
                Color baseColor = cardBackground.color;
                cardBackground.color = isPlayable ? 
                    baseColor : 
                    new Color(baseColor.r * 0.5f, baseColor.g * 0.5f, baseColor.b * 0.5f, 0.7f);
            }
        }
    }
    
    /// <summary>
    /// Karte wurde angeklickt
    /// </summary>
    public void OnPointerClick(PointerEventData eventData)
    {
        if (!isPlayable || isDragging) return;
        
        // Vereinfacht: Da wir zentrales Drag-System verwenden, gilt jeder Click als direkt
        {
            // Visuelles Feedback für nicht spielbare Karte
            if (!isPlayable)
            {
                ShakeCard();
                Debug.Log($"Nicht genug Zeit für {cardData.cardName}!");
                return;
            }
            
            OnCardClicked?.Invoke(cardData);
        }
    }
    
    /// <summary>
    /// Shake-Animation für nicht spielbare Karte
    /// </summary>
    private void ShakeCard()
    {
        LeanTween.cancel(gameObject);
        
        Vector3 originalPos = transform.localPosition;
        LeanTween.moveLocalX(gameObject, originalPos.x + 5f, 0.05f)
            .setEaseShake()
            .setLoopPingPong(2)
            .setOnComplete(() => {
                transform.localPosition = originalPos;
            });
    }
    
    /// <summary>
    /// Maus über Karte (nur für Desktop)
    /// </summary>
    public void OnPointerEnter(PointerEventData eventData)
    {
        // KRITISCH: Verhindere Phantom-Hover während Startup und Touch-Input
        if (Input.touchCount > 0) return;
        
        // KRITISCH: Verhindere EventSystem-Phantom-Hover während der ersten Sekunden
        if (Time.time < 3f)
        {
            Debug.LogError($"[CardUI] *** PHANTOM HOVER BLOCKED *** OnPointerEnter for '{cardData?.cardName}' blocked during startup! Time: {Time.time}");
            return;
        }
        
        // KRITISCH: Nur bei tatsächlicher Mausbewegung (nicht EventSystem-Artifact)
        if (!Input.mousePresent)
        {
            Debug.LogError($"[CardUI] *** PHANTOM HOVER BLOCKED *** No mouse present, ignoring OnPointerEnter for '{cardData?.cardName}'");
            return;
        }
        
        // CRITICAL: Verhindere Hover während einer aktiven Drag-Operation
        if (handController != null && handController.IsDragActive())
        {
            Debug.Log($"[CardUI] *** BLOCKING ONPOINTERENTER DURING DRAG *** Preventing OnPointerEnter on '{cardData?.cardName}' while another card is being dragged");
            return;
        }
        
        SetHovered(true);
    }
    
    /// <summary>
    /// Maus verlässt Karte (nur für Desktop)
    /// </summary>
    public void OnPointerExit(PointerEventData eventData)
    {
        // Behalte Hover wenn wir draggen
        if (isDragging) return;
        
        // CRITICAL: Verhindere Hover-Änderungen während einer aktiven Drag-Operation
        if (handController != null && handController.IsDragActive())
        {
            Debug.Log($"[CardUI] *** BLOCKING ONPOINTEREXIT DURING DRAG *** Preventing OnPointerExit on '{cardData?.cardName}' while another card is being dragged");
            return;
        }
        
        SetHovered(false);
    }
    
    /// <summary>
    /// Setzt den Hover-Status der Karte
    /// </summary>
    public void SetHovered(bool hovered)
    {
        // SCALING FIX: Don't process if being destroyed
        if (!gameObject.activeInHierarchy) return;
        
        // SCALING FIX: Don't allow hover changes during layout animations
        if (isInLayoutAnimation && hovered)
        {
            Debug.Log($"[CardUI] Hover blocked during layout animation for {cardData?.cardName}");
            return;
        }
        
        // CRITICAL: Protection for ALL cards during initial setup
        if (hovered && Time.time < 3f) // First 3 seconds after scene start
        {
            Debug.LogError($"[CardUI] *** BLOCKING STARTUP HOVER *** Preventing hover during initial setup for '{cardData?.cardName}' at SiblingIndex {transform.GetSiblingIndex()}! Time: {Time.time}");
            return;
        }
        
        // CRITICAL: Verhindere Hover während einer aktiven Drag-Operation
        if (hovered && handController != null && handController.IsDragActive())
        {
            Debug.Log($"[CardUI] *** BLOCKING HOVER DURING DRAG *** Preventing hover on '{cardData?.cardName}' while another card is being dragged");
            return;
        }
        
        if (isHovered == hovered) return;
        
        isHovered = hovered;
        
        if (highlightEffect != null)
            highlightEffect.SetActive(hovered);
        
        // CRITICAL FIX: Cancel any existing scale tween before starting new one
        if (activeTweenId >= 0)
        {
            LeanTween.cancel(activeTweenId);
            activeTweenId = -1;
        }
        
        if (hovered)
        {
            // Speichere Original-Index für korrekte Wiederherstellung
            originalSiblingIndex = transform.GetSiblingIndex();
            
            // Nach vorne bringen (für bessere Sichtbarkeit beim Hover)
            Debug.LogError($"[CardUI] HOVER ENTER: {cardData?.cardName} SetAsLastSibling! Original: {originalSiblingIndex} -> New: will be highest");
            transform.SetAsLastSibling();
            int newSiblingIndex = transform.GetSiblingIndex();
            Debug.LogError($"[CardUI] HOVER ENTER: {cardData?.cardName} now has SiblingIndex: {newSiblingIndex}");
            
            // CRITICAL: Track when Card 3 specifically gets promoted
            if (cardData?.cardName == "Schwertschlag" && originalSiblingIndex == 3)
            {
                Debug.LogError($"[CardUI] *** CARD 3 PROMOTION DETECTED *** Schwertschlag moved from SiblingIndex 3 to {newSiblingIndex}!");
                Debug.LogError($"[CardUI] Position: {transform.localPosition}, Scale: {transform.localScale}");
            }
            
            // Hover-Animation
            if (handController != null)
            {
                // CRITICAL FIX: Store base position if not set
                if (!hasBasePosition)
                {
                    basePosition = transform.localPosition;
                    hasBasePosition = true;
                    Debug.Log($"[CardUI] Stored base position for {cardData?.cardName}: {basePosition}");
                }
                
                float lift = handController.GetHoverLift();
                // CRITICAL FIX: Use base position, not current position
                Vector3 targetPos = basePosition;
                targetPos.y += lift;
                
                // SCALING FIX: Force immediate scale reset before animating
                transform.localScale = Vector3.one;
                
                // Start scale animation and track the tween ID
                activeTweenId = LeanTween.scale(gameObject, Vector3.one * 1.15f, hoverAnimDuration)
                    .setEase(hoverEaseType)
                    .setOnComplete(() => {
                        activeTweenId = -1; // Clear ID when complete
                    }).id;
                    
                LeanTween.moveLocal(gameObject, targetPos, hoverAnimDuration).setEase(hoverEaseType);
            }
        }
        else
        {
            // SCALING FIX: Return to normal scale with robust completion handling
            activeTweenId = LeanTween.scale(gameObject, Vector3.one, hoverAnimDuration * 1.2f)
                .setEase(hoverEaseType)
                .setOnComplete(() => {
                    // CRITICAL: Force scale to exactly 1
                    transform.localScale = Vector3.one;
                    activeTweenId = -1; // Clear ID
                }).id;
            
            // CRITICAL FIX: Return to base position
            if (hasBasePosition)
            {
                LeanTween.moveLocal(gameObject, basePosition, hoverAnimDuration).setEase(hoverEaseType);
            }
            
            // Stelle Original-Index wieder her (KRITISCH für korrekte Reihenfolge)
            if (!isDragging && originalSiblingIndex >= 0)
            {
                Debug.LogError($"[CardUI] HOVER EXIT: {cardData?.cardName} restoring SiblingIndex from {transform.GetSiblingIndex()} to {originalSiblingIndex}");
                transform.SetSiblingIndex(originalSiblingIndex);
                int finalSiblingIndex = transform.GetSiblingIndex();
                Debug.LogError($"[CardUI] HOVER EXIT: {cardData?.cardName} final SiblingIndex: {finalSiblingIndex}");
                
                // CRITICAL: Track when Card 3 specifically gets restored (or fails to)
                if (cardData?.cardName == "Schwertschlag" && originalSiblingIndex == 3)
                {
                    if (finalSiblingIndex != 3)
                    {
                        Debug.LogError($"[CardUI] *** CARD 3 RESTORATION FAILED *** Expected SiblingIndex 3, got {finalSiblingIndex}!");
                    }
                    else
                    {
                        Debug.LogError($"[CardUI] *** CARD 3 RESTORATION SUCCESS *** Correctly restored to SiblingIndex 3");
                    }
                }
            }
            else
            {
                Debug.LogError($"[CardUI] HOVER EXIT FAILED: {cardData?.cardName} could not restore SiblingIndex! isDragging={isDragging}, originalIndex={originalSiblingIndex}");
                
                // CRITICAL: Track Card 3 failures specifically
                if (cardData?.cardName == "Schwertschlag")
                {
                    Debug.LogError($"[CardUI] *** CARD 3 HOVER EXIT FAILURE *** Cannot restore SiblingIndex!");
                }
            }
            
            // Layout-Update - simplified for compatibility
            // Debug.Log($"[CardUI] Layout update needed after hover end"); // Removed to reduce log spam
        }
    }
    
    /// <summary>
    /// Gibt die Kartendaten zurück
    /// </summary>
    public TimeCardData GetCardData()
    {
        return cardData;
    }
    
    /// <summary>
    /// Gibt zurück ob die Karte gerade gezogen wird (zentral oder legacy)
    /// </summary>
    public bool IsDragging()
    {
        return isDragging || isBeingDraggedCentrally;
    }
    
    /// <summary>
    /// Wird vom HandController aufgerufen wenn ein Touch im gültigen Bereich beginnt
    /// </summary>
    public static void SetTouchStartedInHandArea(bool valid)
    {
        touchStartedInHandArea = valid;
    }
    
    /// <summary>
    /// Compatibility method for HandController
    /// </summary>
    public static void SetTouchStartedOnValidArea(bool valid)
    {
        touchStartedInHandArea = valid;
        Debug.Log($"[CardUI] SetTouchStartedOnValidArea called with: {valid}");
    }
    
    /// <summary>
    /// Compatibility method for HandController
    /// </summary>
    public static void SetIsMouseInput(bool isUsingMouse)
    {
        // Static compatibility - not needed for this implementation
    }
    
    /// <summary>
    /// Compatibility method for HandController
    /// </summary>
    public void ForceEnterHover()
    {
        // SCALING FIX: Always ensure clean state before hover
        if (activeTweenId >= 0)
        {
            LeanTween.cancel(activeTweenId);
            activeTweenId = -1;
        }
        transform.localScale = Vector3.one;
        SetHovered(true);
    }
    
    /// <summary>
    /// Compatibility method for HandController
    /// </summary>
    public void ForceExitHover()
    {
        // SCALING FIX: Force immediate scale normalization on exit
        if (activeTweenId >= 0)
        {
            LeanTween.cancel(activeTweenId);
            activeTweenId = -1;
        }
        SetHovered(false);
    }
    
    /// <summary>
    /// Compatibility method for HandController
    /// </summary>
    public void ForceDisableHover()
    {
        // CRITICAL: Cancel ALL tweens on this card, not just the active one
        // This prevents hover-exit animations from overriding layout positions
        LeanTween.cancel(gameObject);
        activeTweenId = -1;
        
        // Force immediate scale reset
        transform.localScale = Vector3.one;
        
        // CRITICAL: Restore position to base position if we have one
        if (hasBasePosition)
        {
            transform.localPosition = basePosition;
            Debug.Log($"[CardUI] ForceDisableHover restored position for {cardData?.cardName}: {basePosition}");
        }
        
        // CRITICAL: Restore SiblingIndex if we were hovering
        if (isHovered && originalSiblingIndex >= 0)
        {
            transform.SetSiblingIndex(originalSiblingIndex);
            Debug.Log($"[CardUI] ForceDisableHover restored SiblingIndex for {cardData?.cardName}: {originalSiblingIndex}");
            originalSiblingIndex = -1; // Reset to prevent double-restoration
        }
        
        // Force hover state to false
        isHovered = false;
        if (highlightEffect != null)
            highlightEffect.SetActive(false);
    }
    
    /// <summary>
    /// Compatibility method for HandController
    /// </summary>
    public void EnableHover()
    {
        // Allow hover again - simplified implementation
    }
    
    /// <summary>
    /// Compatibility method for HandController
    /// </summary>
    public void SetOriginalRotation(float rotation)
    {
        // Store original rotation - simplified implementation
    }
    
    /// <summary>
    /// Sets whether the card is currently in a layout animation
    /// </summary>
    public void SetInLayoutAnimation(bool inAnimation)
    {
        isInLayoutAnimation = inAnimation;
        
        // If animation is ending and we have wrong scale, fix it
        if (!inAnimation && Mathf.Abs(transform.localScale.x - 1f) > 0.01f)
        {
            Debug.LogWarning($"[CardUI] Scale incorrect after layout animation: {transform.localScale}. Fixing...");
            transform.localScale = Vector3.one;
        }
    }
    
    void Update()
    {
        // Spielbarkeit regelmäßig prüfen
        CheckPlayability();
        
        // SCALING FIX: Safety check to prevent stuck scales
        if (!isHovered && !isDragging && !isBeingDraggedCentrally)
        {
            // If we're not in any special state but scale is wrong, fix it
            if (Mathf.Abs(transform.localScale.x - 1f) > 0.01f)
            {
                Debug.LogWarning($"[CardUI] Detected stuck scale on {cardData?.cardName}: {transform.localScale}. Resetting to 1.");
                transform.localScale = Vector3.one;
            }
        }
    }
    
    // ===== NEUES ZENTRALISIERTES DRAG-SYSTEM =====
    // Drag-Events werden jetzt vom HandController verwaltet!
    
    /// <summary>
    /// NEUE METHODE: Wird vom HandController aufgerufen wenn zentraler Drag startet
    /// </summary>
    public void OnCentralDragStart()
    {
        if (!isPlayable) return;
        
        isBeingDraggedCentrally = true;
        isDragging = true;
        
        // Speichere ursprüngliche Werte
        originalPosition = transform.localPosition;
        originalRotation = transform.localEulerAngles;
        originalScale = transform.localScale;
        
        Debug.Log($"[CardUI] *** CENTRAL DRAG START *** for {cardData?.cardName}");
        
        // Canvas Group für Raycast-Blocking
        canvasGroup = GetComponent<CanvasGroup>();
        if (canvasGroup == null)
            canvasGroup = gameObject.AddComponent<CanvasGroup>();
        
        canvasGroup.blocksRaycasts = false;
        
        // Visueller Start-Effekt
        LeanTween.scale(gameObject, Vector3.one * 1.1f, dragAnimDuration).setEase(dragEaseType);
    }
    
    /// <summary>
    /// NEUE METHODE: Wird vom HandController aufgerufen wenn zentraler Drag endet
    /// </summary>
    public void OnCentralDragEnd()
    {
        if (!isBeingDraggedCentrally) return;
        
        isBeingDraggedCentrally = false;
        isDragging = false;
        
        Debug.Log($"[CardUI] *** CENTRAL DRAG END *** for {cardData?.cardName}");
        
        // SCALING FIX: Cancel any active tweens before starting new ones
        if (activeTweenId >= 0)
        {
            LeanTween.cancel(activeTweenId);
            activeTweenId = -1;
        }
        LeanTween.cancel(gameObject);
        
        // Position
        LeanTween.moveLocal(gameObject, originalPosition, returnAnimDuration)
            .setEase(returnEaseType);
        
        // Rotation
        LeanTween.rotateLocal(gameObject, originalRotation, returnAnimDuration)
            .setEase(returnEaseType);
        
        // Skalierung - CRITICAL: Ensure we return to exactly 1.0 scale
        LeanTween.scale(gameObject, Vector3.one, returnAnimDuration * 0.7f)
            .setEase(hoverEaseType)
            .setOnComplete(() => {
                // SCALING FIX: Force exact scale after animation
                transform.localScale = Vector3.one;
            });
        
        // Stelle sicher dass Raycasts wieder funktionieren
        if (canvasGroup != null)
        {
            canvasGroup.blocksRaycasts = true;
        }
        
        // Hover zurücksetzen
        SetHovered(false);
    }
    
    /// <summary>
    /// Updates the base position after layout changes
    /// </summary>
    public void UpdateBasePosition(Vector3 newPosition)
    {
        basePosition = newPosition;
        hasBasePosition = true;
        // If not hovered, ensure we're at base position
        if (!isHovered && !isDragging)
        {
            transform.localPosition = basePosition;
        }
    }
    
    // ===== 🚫 LEGACY DRAG-EVENTS (ENTFERNT/IGNORIERT) 🚫 =====
    // 
    // WARUM ENTFERNT?
    // Unity's Drag-Events werden immer an die Karte gesendet, wo der Touch BEGANN.
    // Wenn der Finger sich zu einer anderen Karte bewegt, bekommt immer noch die 
    // ursprüngliche Karte die Events → falsche Karte wird gedraggt!
    // 
    // BEISPIEL DES PROBLEMS:
    // 1. Touch auf Karte A (Schildschlag)
    // 2. Finger zu Karte B (Schwertschlag) 
    // 3. Drag nach oben
    // 4. Unity sendet OnDrag an Karte A → Schildschlag wird visuell gedraggt
    // 5. Aber Spieler wollte Schwertschlag draggen → Verwirrend!
    //
    // LÖSUNG: 
    // Interfaces IBeginDragHandler/IDragHandler/IEndDragHandler wurden aus der
    // Klassen-Deklaration entfernt. Diese Methoden existieren nur noch als
    // Dokumentation und werden nie aufgerufen.
    
    // Diese Methoden werden NICHT MEHR AUFGERUFEN da Interfaces entfernt:
    // public void OnBeginDrag() → DEAD CODE
    // public void OnDrag()      → DEAD CODE  
    // public void OnEndDrag()   → DEAD CODE
    
    /// <summary>
    /// VEREINFACHT: Gibt zurück ob die Karte gerade zentral gedraggt wird
    /// </summary>
    public bool IsBeingDraggedCentrally()
    {
        return isBeingDraggedCentrally;
    }
    
    /// <summary>
    /// VEREINFACHT: Legacy-Methode für Kompatibilität
    /// </summary>
    private void PlayCard()
    {
        // Diese Methode sollte nicht mehr direkt aufgerufen werden
        // Alle Karten-Spiele werden jetzt über den HandController verwaltet
        Debug.LogWarning($"[CardUI] PlayCard() called directly - should use HandController instead for {cardData?.cardName}");
    }
}