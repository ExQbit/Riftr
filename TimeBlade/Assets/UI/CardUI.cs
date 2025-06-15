using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using TMPro;
using System;
using System.Collections;
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
    [SerializeField] private Image playableBorderFrame; // Separater pulsierender Rahmen für Spielbarkeit
    
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
    
    [Header("🔮 Magischer Border-Glow")]
    [SerializeField] public float borderPulseDuration = 0.8f; // Magische Pulsation
    [SerializeField] public float borderMinAlpha = 0.6f; // Immer gut sichtbar
    [SerializeField] public float borderMaxAlpha = 1.0f; // Voll leuchtend
    [SerializeField] public Color borderColorPrimary = new Color(0.2f, 0.8f, 2.0f, 1.0f); // Helles Cyan
    [SerializeField] public Color borderColorSecondary = new Color(1.0f, 0.4f, 2.0f, 1.0f); // Magenta für Farbwechsel
    [SerializeField] public LeanTweenType borderEaseType = LeanTweenType.easeInOutSine; // Smooth magische Bewegung
    [SerializeField] public float glowIntensity = 4.0f; // Starker magischer Glow
    [SerializeField] public float glowSize = 30f; // Größe des Glow-Effekts
    [SerializeField] public bool useColorCycling = true; // Farbwechsel-Effekt
    
    // Hover-State
    private bool isHovered = false;
    private static bool touchStartedInHandArea = false;
    
    // Scaling fix tracking
    private int activeTweenId = -1; // Track active scale tween to cancel it properly
    private bool isInLayoutAnimation = false; // Prevent hover during layout animations
    
    // CRITICAL: Store base position for hover calculations
    private Vector3 basePosition = Vector3.zero; // Position without any hover lift
    private bool hasBasePosition = false;
    
    // Border-Pulsation tracking (getrennt von Hover-System)
    private int borderTweenId = -1; // Track active border animation
    private bool isBorderPulseActive = false; // Is border pulse animation running?
    
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
        
        // Initialize playable border frame (create if not assigned)
        if (playableBorderFrame == null)
        {
            CreatePlayableBorderFrame();
        }
        
        if (playableBorderFrame != null)
        {
            // Set border color and hide initially
            playableBorderFrame.color = new Color(borderColorPrimary.r, borderColorPrimary.g, borderColorPrimary.b, 0f);
            playableBorderFrame.gameObject.SetActive(false);
        }
        
        // Initialize hover effect (separate from border system)
        if (highlightEffect != null)
        {
            highlightEffect.SetActive(false);
        }
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
        
        // Stop border pulsation before destruction
        StopBorderPulsation();
        
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
        
        // Stop border pulsation
        StopBorderPulsation();
        
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
            
            // Border-Pulsation für spielbare Karten
            if (isPlayable && !isBorderPulseActive)
            {
                StartBorderPulsation();
            }
            else if (!isPlayable && isBorderPulseActive)
            {
                StopBorderPulsation();
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
    /// Startet die Border-Pulsation für spielbare Karten
    /// </summary>
    private void StartBorderPulsation()
    {
        if (playableBorderFrame == null || isBorderPulseActive) return;
        
        isBorderPulseActive = true;
        
        // Make border visible and set initial color
        playableBorderFrame.color = new Color(borderColorPrimary.r, borderColorPrimary.g, borderColorPrimary.b, borderMinAlpha);
        playableBorderFrame.gameObject.SetActive(true);
        
        // Start pulsing animation
        PulseBorder();
        
        // Debug.Log($"[CardUI] Started border pulsation for {cardData?.cardName}"); // REDUCED LOGGING
    }
    
    /// <summary>
    /// Stoppt die Border-Pulsation
    /// </summary>
    private void StopBorderPulsation()
    {
        if (!isBorderPulseActive) return;
        
        isBorderPulseActive = false;
        
        // Cancel active border tween
        if (borderTweenId >= 0)
        {
            LeanTween.cancel(borderTweenId);
            borderTweenId = -1;
        }
        
        // Hide border frame
        if (playableBorderFrame != null)
        {
            playableBorderFrame.gameObject.SetActive(false);
        }
        
        // Debug.Log($"[CardUI] Stopped border pulsation for {cardData?.cardName}"); // REDUCED LOGGING
    }
    
    /// <summary>
    /// Führt eine Border-Pulsation aus (rekursiv für kontinuierliche Animation)
    /// </summary>
    private void PulseBorder()
    {
        if (!isBorderPulseActive || playableBorderFrame == null) return;
        
        // Animate from min to max alpha with magical color cycling
        borderTweenId = LeanTween.value(gameObject, borderMinAlpha, borderMaxAlpha, borderPulseDuration / 2f)
            .setEase(borderEaseType)
            .setOnUpdate((float val) => {
                if (playableBorderFrame != null && isBorderPulseActive)
                {
                    // Choose color based on cycling preference
                    Color baseColor = useColorCycling ? 
                        Color.Lerp(borderColorPrimary, borderColorSecondary, (val - borderMinAlpha) / (borderMaxAlpha - borderMinAlpha)) :
                        borderColorPrimary;
                    
                    // Apply HDR intensity for magical glow
                    Color magicalColor = baseColor * glowIntensity;
                    magicalColor.a = val;
                    playableBorderFrame.color = magicalColor;
                }
            })
            .setOnComplete(() => {
                // Animate back from max to min alpha
                if (isBorderPulseActive)
                {
                    borderTweenId = LeanTween.value(gameObject, borderMaxAlpha, borderMinAlpha, borderPulseDuration / 2f)
                        .setEase(borderEaseType)
                        .setOnUpdate((float val) => {
                            if (playableBorderFrame != null && isBorderPulseActive)
                            {
                                // Choose color based on cycling preference (reverse cycle on fade)
                                Color baseColor = useColorCycling ? 
                                    Color.Lerp(borderColorSecondary, borderColorPrimary, (val - borderMinAlpha) / (borderMaxAlpha - borderMinAlpha)) :
                                    borderColorPrimary;
                                
                                // Apply HDR intensity for magical glow
                                Color magicalColor = baseColor * glowIntensity;
                                magicalColor.a = val;
                                playableBorderFrame.color = magicalColor;
                            }
                        })
                        .setOnComplete(() => {
                            // Recursively continue pulsing
                            if (isBorderPulseActive)
                            {
                                PulseBorder();
                            }
                        }).id;
                }
            }).id;
    }
    
    /// <summary>
    /// Erstellt automatisch ein Border-Frame Element falls keines zugewiesen ist
    /// </summary>
    private void CreatePlayableBorderFrame()
    {
        // Create a new GameObject for the border
        GameObject borderObject = new GameObject("PlayableBorderFrame");
        borderObject.transform.SetParent(transform, false);
        
        // Add Image component
        playableBorderFrame = borderObject.AddComponent<Image>();
        
        // Configure RectTransform to cover the entire card area
        RectTransform borderRect = borderObject.GetComponent<RectTransform>();
        borderRect.anchorMin = Vector2.zero;
        borderRect.anchorMax = Vector2.one;
        borderRect.sizeDelta = Vector2.zero;
        borderRect.anchoredPosition = Vector2.zero;
        
        // Set as first child so it appears behind card content
        borderObject.transform.SetAsFirstSibling();
        
        // Configure border appearance
        playableBorderFrame.color = Color.clear; // Start transparent
        playableBorderFrame.raycastTarget = false; // Don't block raycasts
        
        // Try to create a simple border sprite programmatically
        CreateBorderSprite();
        
        Debug.Log("[CardUI] Auto-created PlayableBorderFrame");
    }
    
    /// <summary>
    /// Erstellt einen magischen, leuchtenden Border mit starkem Glow-Effekt
    /// </summary>
    private void CreateBorderSprite()
    {
        // Create a much larger texture for dramatic glow effect
        int size = 200;
        Texture2D borderTexture = new Texture2D(size, size);
        Color[] pixels = new Color[size * size];
        
        Vector2 center = new Vector2(size / 2f, size / 2f);
        float maxGlowDistance = glowSize; // Use configurable glow size
        
        // Create a magical glowing border pattern
        for (int x = 0; x < size; x++)
        {
            for (int y = 0; y < size; y++)
            {
                // Calculate distance from edge for glow effect
                int distFromEdge = Mathf.Min(
                    Mathf.Min(x, size - 1 - x),
                    Mathf.Min(y, size - 1 - y)
                );
                
                Color pixelColor = Color.clear;
                
                if (distFromEdge < maxGlowDistance) // Large glow area
                {
                    float normalizedDist = distFromEdge / maxGlowDistance;
                    
                    if (distFromEdge < 6) // Very thin solid border
                    {
                        // Bright solid core
                        pixelColor = new Color(1f, 1f, 1f, 1f);
                    }
                    else if (distFromEdge < 12) // Inner glow
                    {
                        // Strong inner glow
                        float innerGlow = 1.0f - ((distFromEdge - 6) / 6.0f);
                        pixelColor = new Color(1f, 1f, 1f, innerGlow * 0.9f);
                    }
                    else // Outer magical glow
                    {
                        // Magical falloff curve - more dramatic than quadratic
                        float glowStrength = 1.0f - normalizedDist;
                        float magicalAlpha = Mathf.Pow(glowStrength, 3.0f); // Cubic falloff for dramatic effect
                        
                        // Add some sparkle variation
                        float sparkle = 1.0f + 0.2f * Mathf.Sin((x + y) * 0.3f) * Mathf.Sin(x * 0.7f) * Mathf.Sin(y * 0.5f);
                        magicalAlpha *= sparkle;
                        
                        pixelColor = new Color(1f, 1f, 1f, Mathf.Clamp01(magicalAlpha));
                    }
                }
                
                pixels[y * size + x] = pixelColor;
            }
        }
        
        borderTexture.SetPixels(pixels);
        borderTexture.Apply();
        
        // Create sprite from texture
        Sprite borderSprite = Sprite.Create(
            borderTexture, 
            new Rect(0, 0, size, size), 
            new Vector2(0.5f, 0.5f),
            100,
            0,
            SpriteMeshType.FullRect,
            new Vector4(maxGlowDistance, maxGlowDistance, maxGlowDistance, maxGlowDistance)
        );
        
        // Apply to Image component
        if (playableBorderFrame != null)
        {
            playableBorderFrame.sprite = borderSprite;
            playableBorderFrame.type = Image.Type.Sliced;
            
            Debug.Log($"[CardUI] Created magical border sprite with glow size: {glowSize}");
        }
    }
    
    /// <summary>
    /// Maus über Karte (nur für Desktop)
    /// </summary>
    public void OnPointerEnter(PointerEventData eventData)
    {
        // ENHANCED: Use global touch state for more robust blocking
        if (HandController.IsGlobalTouchActive)
        {
            Debug.LogError($"[CardUI] *** BLOCKING ONPOINTERENTER - GLOBAL TOUCH ACTIVE *** for '{cardData?.cardName}'");
            return;
        }
        
        // CRITICAL FIX: Block ALL OnPointerEnter events when HandController is managing touch
        if (handController != null && handController.IsTouchActive())
        {
            Debug.LogError($"[CardUI] *** BLOCKING ONPOINTERENTER DURING TOUCH *** HandController is managing touch for '{cardData?.cardName}'");
            return;
        }
        
        // KRITISCH: Verhindere Phantom-Hover während Startup und Touch-Input
        if (Input.touchCount > 0) 
        {
            Debug.LogError($"[CardUI] *** BLOCKING ONPOINTERENTER *** Touch count: {Input.touchCount} for '{cardData?.cardName}'");
            return;
        }
        
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
        
        Debug.LogError($"[CardUI] *** ONPOINTERENTER ALLOWED *** Mouse hover on '{cardData?.cardName}'");
        SetHovered(true);
    }
    
    /// <summary>
    /// Maus verlässt Karte (nur für Desktop)
    /// </summary>
    public void OnPointerExit(PointerEventData eventData)
    {
        // ENHANCED: Use global touch state for more robust blocking
        if (HandController.IsGlobalTouchActive)
        {
            Debug.LogError($"[CardUI] *** BLOCKING ONPOINTEREXIT - GLOBAL TOUCH ACTIVE *** for '{cardData?.cardName}'");
            return;
        }
        
        // CRITICAL FIX: Block ALL OnPointerExit events when HandController is managing touch
        if (handController != null && handController.IsTouchActive())
        {
            Debug.LogError($"[CardUI] *** BLOCKING ONPOINTEREXIT DURING TOUCH *** HandController is managing touch for '{cardData?.cardName}'");
            return;
        }
        
        // KRITISCH: Verhindere Phantom-Hover während Touch-Input
        if (Input.touchCount > 0) 
        {
            Debug.LogError($"[CardUI] *** BLOCKING ONPOINTEREXIT *** Touch count: {Input.touchCount} for '{cardData?.cardName}'");
            return;
        }
        
        // Behalte Hover wenn wir draggen
        if (isDragging) return;
        
        // CRITICAL: Verhindere Hover-Änderungen während einer aktiven Drag-Operation
        if (handController != null && handController.IsDragActive())
        {
            Debug.Log($"[CardUI] *** BLOCKING ONPOINTEREXIT DURING DRAG *** Preventing OnPointerExit on '{cardData?.cardName}' while another card is being dragged");
            return;
        }
        
        Debug.LogError($"[CardUI] *** ONPOINTEREXIT ALLOWED *** Mouse exit on '{cardData?.cardName}'");
        SetHovered(false);
    }
    
    /// <summary>
    /// Setzt den Hover-Status der Karte
    /// </summary>
    public void SetHovered(bool hovered)
    {
        // SCALING FIX: Don't process if being destroyed
        if (!gameObject.activeInHierarchy) return;
        
        // REMOVED: Layout animation blocking was preventing touch hover from working
        // The hover animation should be allowed even during layout animation
        
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
        
        // CRITICAL FIX: Prevent unnecessary animation restarts
        // If we're already hovered and trying to hover again, AND we have an active animation, skip
        if (isHovered == hovered) 
        {
            if (hovered && activeTweenId >= 0)
            {
                Debug.LogError($"[CardUI] *** SKIPPING REDUNDANT HOVER *** Card {cardData?.cardName} already hovered with active animation (Tween ID: {activeTweenId})");
                return; // Don't restart animation if already running
            }
            else if (!hovered)
            {
                return; // Skip false->false transitions
            }
            // Allow true->true if no active animation (animation might have been cancelled)
        }
        
        Debug.LogError($"[CardUI] *** SETTING HOVERED STATE *** Card: {cardData?.cardName}, Old State: {isHovered}, New State: {hovered}");
        isHovered = hovered;
        
        // HOVER SYSTEM DEAKTIVIERT - nur Border-Pulsation wird verwendet
        // if (highlightEffect != null)
        //     highlightEffect.SetActive(hovered);
        
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
                
                // CRITICAL FIX: Cancel any existing animations before starting new ones
                LeanTween.cancel(gameObject);
                activeTweenId = -1;
                
                // SCALING FIX: Force immediate scale reset before animating
                transform.localScale = Vector3.one;
                
                // CRITICAL DEBUG: Log animation start details
                Debug.LogError($"[CardUI] *** STARTING HOVER ANIMATION *** Card: {cardData?.cardName}, BasePos: {basePosition}, TargetPos: {targetPos}, Lift: {lift}");
                
                // Start BOTH animations with the same timing to ensure they're synchronized
                // Scale animation
                activeTweenId = LeanTween.scale(gameObject, Vector3.one * 1.15f, hoverAnimDuration)
                    .setEase(hoverEaseType)
                    .setOnComplete(() => {
                        activeTweenId = -1; // Clear ID when complete
                        Debug.Log($"[CardUI] Hover scale animation complete for {cardData?.cardName}");
                    }).id;
                
                // Position animation - use the same duration and easing
                LeanTween.moveLocal(gameObject, targetPos, hoverAnimDuration)
                    .setEase(hoverEaseType)
                    .setOnComplete(() => {
                        Debug.Log($"[CardUI] Hover position animation complete for {cardData?.cardName}, Final Pos: {transform.localPosition}");
                    });
                
                Debug.Log($"[CardUI] Started hover animations for {cardData?.cardName} - Scale to 1.15, Move to {targetPos}");
            }
        }
        else
        {
            // CRITICAL FIX: Cancel any existing animations before starting new ones
            LeanTween.cancel(gameObject);
            
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
                Debug.LogError($"[CardUI] HOVER EXIT: {cardData?.cardName} returning to basePosition: {basePosition} (current: {transform.localPosition})");
                LeanTween.moveLocal(gameObject, basePosition, hoverAnimDuration)
                    .setEase(hoverEaseType)
                    .setOnComplete(() => {
                        Debug.Log($"[CardUI] Hover exit complete for {cardData?.cardName}, Final Pos: {transform.localPosition}");
                        // Don't reset base position flag - keep it for future hover operations
                    });
            }
            else
            {
                // If no base position stored, log error but don't move
                Debug.LogError($"[CardUI] HOVER EXIT ERROR: No base position stored for {cardData?.cardName}!");
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
        
        // CRITICAL FIX: Force immediate visual update
        Canvas.ForceUpdateCanvases();
        
        SetHovered(true);
        
        // ADDITIONAL FIX: Force another canvas update after hover animation starts
        StartCoroutine(ForceCanvasUpdateNextFrame());
    }
    
    /// <summary>
    /// Forces canvas update on the next frame to ensure visual changes are visible
    /// </summary>
    private System.Collections.IEnumerator ForceCanvasUpdateNextFrame()
    {
        yield return null; // Wait one frame
        Canvas.ForceUpdateCanvases();
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
            // Debug.Log($"[CardUI] ForceDisableHover restored position for {cardData?.cardName}: {basePosition}"); // REDUCED LOGGING
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
        
        // CRITICAL FIX: Don't reset scale if card is hovered or being dragged
        // Only fix scale for cards that should be at normal scale
        if (!inAnimation && Mathf.Abs(transform.localScale.x - 1f) > 0.01f)
        {
            if (isHovered || isDragging || isBeingDraggedCentrally || activeTweenId >= 0)
            {
                Debug.Log($"[CardUI] Skipping scale fix for {cardData?.cardName} - hovered:{isHovered}, dragging:{isDragging}, activeTween:{activeTweenId}");
            }
            else
            {
                Debug.LogWarning($"[CardUI] Scale incorrect after layout animation: {transform.localScale}. Fixing...");
                transform.localScale = Vector3.one;
            }
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
                // Silently fix the scale without spamming the log
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
        // CRITICAL FIX: Don't update base position if card is hovered
        // This prevents storing the lifted position as the base
        if (isHovered)
        {
            Debug.Log($"[CardUI] Skipping base position update for {cardData?.cardName} - card is hovered");
            return;
        }
        
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