using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using TMPro;
using System;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// 🃏 HOVER STATE MACHINE CARD UI 🃏
/// 
/// Diese Version implementiert eine robuste State Machine für das Hover-System,
/// um Race Conditions und Animation-Konflikte zu vermeiden.
/// 
/// STATES:
/// - None: Karte ist im Normalzustand
/// - EnteringHover: Animation zum Hover-Zustand läuft
/// - Hovered: Karte ist vollständig im Hover-Zustand
/// - ExitingHover: Animation vom Hover-Zustand zurück läuft
/// 
/// POSITION TRACKING:
/// - layoutTargetPosition: Wo die Karte laut Layout sein sollte
/// - visualPosition: Aktuelle visuelle Position (kann animiert sein)
/// - hoverOffset: Zusätzlicher Offset für Hover-Effekt
/// 
/// ANIMATION MANAGEMENT:
/// - Nur eine Animation pro Karte gleichzeitig
/// - Neue Animationen canceln alte sauber
/// - Warteschlange für Layout-Updates während Hover
/// </summary>
public class CardUI : MonoBehaviour, IPointerClickHandler, IPointerEnterHandler, IPointerExitHandler
{
    // ===== HOVER STATE MACHINE =====
    public enum HoverState
    {
        None,           // Normal state
        EnteringHover,  // Animating to hover
        Hovered,        // Fully hovered
        ExitingHover    // Animating back from hover
    }
    
    private HoverState currentHoverState = HoverState.None;
    private HoverState targetHoverState = HoverState.None;
    
    // ===== POSITION TRACKING =====
    private Vector3 layoutTargetPosition = Vector3.zero;  // Where card should be according to layout
    private Vector3 visualPosition = Vector3.zero;       // Current visual position
    private Vector3 hoverOffset = Vector3.zero;          // Additional offset when hovering
    private bool hasValidLayoutPosition = false;
    
    // ===== ANIMATION TRACKING =====
    private int positionAnimationId = -1;
    private int scaleAnimationId = -1;
    private int rotationAnimationId = -1;
    private bool isAnimating = false;
    
    // ===== SIBLING INDEX TRACKING =====
    private int layoutSiblingIndex = -1;  // The index this card should have in layout
    private bool needsIndexRestore = false;
    
    // ===== DELAYED LAYOUT UPDATE =====
    private Coroutine pendingLayoutUpdate = null;
    private float layoutUpdateDelay = 0f;
    
    [Header("UI-Elemente")]
    [SerializeField] private TextMeshProUGUI nameText;
    [SerializeField] private TextMeshProUGUI costText;
    [SerializeField] private TextMeshProUGUI damageText;
    [SerializeField] private TextMeshProUGUI descriptionText;
    [SerializeField] private Image cardBackground;
    [SerializeField] private Image cardArt;
    [SerializeField] private GameObject highlightEffect;
    [SerializeField] private Image playableBorderFrame;
    
    [Header("Farben")]
    [SerializeField] private Color attackColor = new Color(1f, 0.3f, 0.3f);
    [SerializeField] private Color defenseColor = new Color(0.3f, 0.5f, 1f);
    [SerializeField] private Color timeColor = new Color(0.5f, 1f, 0.5f);
    
    [Header("Animation-Einstellungen")]
    [SerializeField] private float hoverAnimDuration = 0.1f;
    [SerializeField] private float exitAnimDuration = 0.15f;
    [SerializeField] private float layoutAnimDuration = 0.2f;
    [SerializeField] private LeanTweenType hoverEaseType = LeanTweenType.easeOutCubic;
    [SerializeField] private LeanTweenType exitEaseType = LeanTweenType.easeOutQuad;
    [SerializeField] private LeanTweenType layoutEaseType = LeanTweenType.easeOutExpo;
    
    [Header("Hover-Einstellungen")]
    [SerializeField] private float hoverLiftAmount = 50f;
    [SerializeField] private float hoverScaleAmount = 1.15f;
    
    [Header("🔮 Magischer Border-Glow")]
    [SerializeField] private float borderPulseDuration = 0.8f;
    [SerializeField] private float borderMinAlpha = 0.6f;
    [SerializeField] private float borderMaxAlpha = 1.0f;
    [SerializeField] private Color borderColorPrimary = new Color(0.2f, 0.8f, 2.0f, 1.0f);
    [SerializeField] private Color borderColorSecondary = new Color(1.0f, 0.4f, 2.0f, 1.0f);
    [SerializeField] private LeanTweenType borderEaseType = LeanTweenType.easeInOutSine;
    [SerializeField] private float glowIntensity = 4.0f;
    [SerializeField] private float glowSize = 30f;
    [SerializeField] private bool useColorCycling = true;
    
    // Events
    public event Action<TimeCardData> OnCardClicked;
    
    // Daten
    private TimeCardData cardData;
    private bool isPlayable = true;
    
    // Drag & Drop
    private bool isDragging = false;
    private bool isBeingDraggedCentrally = false;
    private Vector3 originalScale;
    private CanvasGroup canvasGroup;
    private HandController handController;
    
    // Border-Pulsation
    private int borderTweenId = -1;
    private bool isBorderPulseActive = false;
    
    // Touch state
    private static bool touchStartedInHandArea = false;
    
    void Awake()
    {
        // Force scale to 1 and disable any animators
        transform.localScale = Vector3.one;
        
        Animator animator = GetComponent<Animator>();
        if (animator != null)
        {
            Debug.LogWarning($"[CardUI] Found Animator on card prefab! Disabling it.");
            animator.enabled = false;
        }
        
        Animation legacyAnim = GetComponent<Animation>();
        if (legacyAnim != null)
        {
            Debug.LogWarning($"[CardUI] Found Animation component on card prefab! Disabling it.");
            legacyAnim.enabled = false;
        }
        
        canvasGroup = GetComponent<CanvasGroup>();
        
        if (playableBorderFrame == null)
        {
            CreatePlayableBorderFrame();
        }
        
        if (playableBorderFrame != null)
        {
            playableBorderFrame.color = new Color(borderColorPrimary.r, borderColorPrimary.g, borderColorPrimary.b, 0f);
            playableBorderFrame.gameObject.SetActive(false);
        }
        
        if (highlightEffect != null)
        {
            highlightEffect.SetActive(false);
        }
        
        // Initialize positions
        layoutTargetPosition = transform.localPosition;
        visualPosition = transform.localPosition;
        hasValidLayoutPosition = true;
    }
    
    void Start()
    {
        // Double-check scale
        if (transform.localScale != Vector3.one)
        {
            Debug.LogWarning($"[CardUI] Scale was not 1 at Start! Was: {transform.localScale}. Fixing...");
            transform.localScale = Vector3.one;
        }
        
        // Cancel any animations
        CancelAllAnimations();
    }
    
    void OnDestroy()
    {
        CancelAllAnimations();
        StopBorderPulsation();
        
        if (pendingLayoutUpdate != null)
        {
            StopCoroutine(pendingLayoutUpdate);
        }
    }
    
    void OnEnable()
    {
        ResetCardState();
    }
    
    /// <summary>
    /// Completely resets the card to a clean state
    /// </summary>
    private void ResetCardState()
    {
        CancelAllAnimations();
        
        // Reset state machine
        currentHoverState = HoverState.None;
        targetHoverState = HoverState.None;
        isAnimating = false;
        
        // Reset positions
        if (hasValidLayoutPosition)
        {
            transform.localPosition = layoutTargetPosition;
            visualPosition = layoutTargetPosition;
        }
        hoverOffset = Vector3.zero;
        
        // Reset visual state
        transform.localScale = Vector3.one;
        transform.localRotation = Quaternion.identity;
        isDragging = false;
        isBeingDraggedCentrally = false;
        
        // Stop border pulsation
        StopBorderPulsation();
        
        // Ensure highlight is off
        if (highlightEffect != null)
            highlightEffect.SetActive(false);
    }
    
    /// <summary>
    /// Cancels all running animations
    /// </summary>
    private void CancelAllAnimations()
    {
        if (positionAnimationId >= 0)
        {
            LeanTween.cancel(positionAnimationId);
            positionAnimationId = -1;
        }
        
        if (scaleAnimationId >= 0)
        {
            LeanTween.cancel(scaleAnimationId);
            scaleAnimationId = -1;
        }
        
        if (rotationAnimationId >= 0)
        {
            LeanTween.cancel(rotationAnimationId);
            rotationAnimationId = -1;
        }
        
        // Also cancel any other tweens on this object
        LeanTween.cancel(gameObject);
        
        isAnimating = false;
    }
    
    /// <summary>
    /// Updates the layout target position (called by HandController)
    /// </summary>
    public void UpdateLayoutTargetPosition(Vector3 newPosition, float animationDuration = 0.2f, bool immediate = false)
    {
        layoutTargetPosition = newPosition;
        hasValidLayoutPosition = true;
        
        // If we're in a hover state, delay the layout update
        if (currentHoverState == HoverState.Hovered || currentHoverState == HoverState.EnteringHover)
        {
            if (pendingLayoutUpdate != null)
            {
                StopCoroutine(pendingLayoutUpdate);
            }
            pendingLayoutUpdate = StartCoroutine(DelayedLayoutUpdate(animationDuration));
            layoutUpdateDelay = animationDuration;
        }
        else if (immediate || animationDuration <= 0f)
        {
            // Immediate update
            ApplyLayoutPosition(true);
        }
        else
        {
            // Animated update
            AnimateToLayoutPosition(animationDuration);
        }
    }
    
    /// <summary>
    /// Special method for parallax updates - only updates X position while maintaining hover
    /// </summary>
    public void UpdateParallaxXPosition(float newX, float duration = 0.05f)
    {
        if (currentHoverState == HoverState.Hovered || currentHoverState == HoverState.EnteringHover)
        {
            // Für hovering Karten: Update nur die X-Position, behalte den Hover-Y-Offset
            Vector3 targetPos = new Vector3(newX, layoutTargetPosition.y + hoverOffset.y, layoutTargetPosition.z);
            
            if (positionAnimationId >= 0)
            {
                LeanTween.cancel(positionAnimationId);
            }
            
            positionAnimationId = LeanTween.moveLocalX(gameObject, targetPos.x, duration)
                .setEase(LeanTweenType.easeOutQuad)
                .setOnComplete(() => {
                    positionAnimationId = -1;
                }).id;
            
            // Update auch die layout target X für spätere Referenz
            layoutTargetPosition.x = newX;
        }
        else
        {
            // Nicht-hovering Karten: Normales X-Update
            layoutTargetPosition.x = newX;
            AnimateToLayoutPosition(duration);
        }
    }
    
    /// <summary>
    /// Special method for parallax updates with arc movement - updates both X and Y
    /// </summary>
    public void UpdateParallaxPositionWithArc(Vector3 newTargetPosition, float duration = 0.05f)
    {
        layoutTargetPosition = newTargetPosition;
        
        if (currentHoverState == HoverState.Hovered || currentHoverState == HoverState.EnteringHover)
        {
            // Für hovering Karten: Neue Position mit Hover-Offset
            Vector3 targetPos = newTargetPosition + hoverOffset;
            
            if (positionAnimationId >= 0)
            {
                LeanTween.cancel(positionAnimationId);
            }
            
            positionAnimationId = LeanTween.moveLocal(gameObject, targetPos, duration)
                .setEase(LeanTweenType.easeOutQuad)
                .setOnComplete(() => {
                    positionAnimationId = -1;
                    visualPosition = targetPos;
                }).id;
        }
        else
        {
            // Nicht-hovering Karten: Normale Position-Update
            AnimateToLayoutPosition(duration);
        }
    }
    
    /// <summary>
    /// Coroutine to delay layout updates during hover
    /// </summary>
    private IEnumerator DelayedLayoutUpdate(float duration)
    {
        // Wait until we're no longer hovering
        while (currentHoverState == HoverState.Hovered || currentHoverState == HoverState.EnteringHover)
        {
            yield return new WaitForSeconds(0.1f);
        }
        
        // Apply the layout update
        AnimateToLayoutPosition(duration);
        pendingLayoutUpdate = null;
    }
    
    /// <summary>
    /// Applies the layout position immediately
    /// </summary>
    private void ApplyLayoutPosition(bool updateVisual = true)
    {
        if (!hasValidLayoutPosition) return;
        
        visualPosition = layoutTargetPosition + hoverOffset;
        
        if (updateVisual && !isAnimating)
        {
            transform.localPosition = visualPosition;
        }
    }
    
    /// <summary>
    /// Animates to the layout position
    /// </summary>
    private void AnimateToLayoutPosition(float duration)
    {
        if (!hasValidLayoutPosition || isAnimating) return;
        
        Vector3 targetPos = layoutTargetPosition + hoverOffset;
        
        if (positionAnimationId >= 0)
        {
            LeanTween.cancel(positionAnimationId);
        }
        
        if (duration <= 0f)
        {
            transform.localPosition = targetPos;
            visualPosition = targetPos;
        }
        else
        {
            positionAnimationId = LeanTween.moveLocal(gameObject, targetPos, duration)
                .setEase(layoutEaseType)
                .setOnComplete(() => {
                    positionAnimationId = -1;
                    visualPosition = targetPos;
                }).id;
        }
    }
    
    /// <summary>
    /// State machine transition
    /// </summary>
    private void TransitionToState(HoverState newState)
    {
        if (currentHoverState == newState) return;
        
        HoverState oldState = currentHoverState;
        currentHoverState = newState;
        
        // Debug-Log nur bei wichtigen Übergängen (optional)
        // Debug.Log($"[CardUI] {cardData?.cardName} State: {oldState} → {newState}");
        
        // Handle state transitions
        switch (newState)
        {
            case HoverState.None:
                OnEnterNoneState();
                break;
                
            case HoverState.EnteringHover:
                OnEnterEnteringHoverState();
                break;
                
            case HoverState.Hovered:
                OnEnterHoveredState();
                break;
                
            case HoverState.ExitingHover:
                OnEnterExitingHoverState();
                break;
        }
    }
    
    /// <summary>
    /// None state entry
    /// </summary>
    private void OnEnterNoneState()
    {
        hoverOffset = Vector3.zero;
        needsIndexRestore = false;
        
        // Cancel any pending layout updates
        if (pendingLayoutUpdate != null)
        {
            StopCoroutine(pendingLayoutUpdate);
            pendingLayoutUpdate = null;
        }
        
        // Apply any pending layout updates immediately
        if (layoutUpdateDelay > 0f)
        {
            AnimateToLayoutPosition(layoutUpdateDelay);
            layoutUpdateDelay = 0f;
        }
    }
    
    /// <summary>
    /// EnteringHover state entry
    /// </summary>
    private void OnEnterEnteringHoverState()
    {
        isAnimating = true;
        
        // Store current sibling index
        layoutSiblingIndex = transform.GetSiblingIndex();
        
        // Bring to front
        transform.SetAsLastSibling();
        needsIndexRestore = true;
        
        // Calculate hover offset
        hoverOffset = Vector3.up * hoverLiftAmount;
        
        // Animate position
        Vector3 targetPos = layoutTargetPosition + hoverOffset;
        
        CancelAllAnimations();
        
        positionAnimationId = LeanTween.moveLocal(gameObject, targetPos, hoverAnimDuration)
            .setEase(hoverEaseType)
            .setOnComplete(() => {
                positionAnimationId = -1;
                visualPosition = targetPos;
                TransitionToState(HoverState.Hovered);
            }).id;
        
        // Animate scale
        scaleAnimationId = LeanTween.scale(gameObject, Vector3.one * hoverScaleAmount, hoverAnimDuration)
            .setEase(hoverEaseType)
            .setOnComplete(() => {
                scaleAnimationId = -1;
            }).id;
    }
    
    /// <summary>
    /// Hovered state entry
    /// </summary>
    private void OnEnterHoveredState()
    {
        isAnimating = false;
        
        // Ensure we're at the correct position
        visualPosition = layoutTargetPosition + hoverOffset;
        transform.localPosition = visualPosition;
        transform.localScale = Vector3.one * hoverScaleAmount;
    }
    
    /// <summary>
    /// ExitingHover state entry
    /// </summary>
    private void OnEnterExitingHoverState()
    {
        isAnimating = true;
        
        // Reset hover offset
        hoverOffset = Vector3.zero;
        
        // Restore sibling index
        if (needsIndexRestore && layoutSiblingIndex >= 0)
        {
            transform.SetSiblingIndex(layoutSiblingIndex);
            needsIndexRestore = false;
        }
        
        // Animate back to layout position
        CancelAllAnimations();
        
        positionAnimationId = LeanTween.moveLocal(gameObject, layoutTargetPosition, exitAnimDuration)
            .setEase(exitEaseType)
            .setOnComplete(() => {
                positionAnimationId = -1;
                visualPosition = layoutTargetPosition;
                TransitionToState(HoverState.None);
            }).id;
        
        // Animate scale
        scaleAnimationId = LeanTween.scale(gameObject, Vector3.one, exitAnimDuration)
            .setEase(exitEaseType)
            .setOnComplete(() => {
                scaleAnimationId = -1;
                transform.localScale = Vector3.one; // Force exact scale
            }).id;
    }
    
    /// <summary>
    /// Public method to set hover state
    /// </summary>
    public void SetHovered(bool hovered)
    {
        // Don't process if being destroyed or inactive
        if (!gameObject.activeInHierarchy) return;
        
        // Protection during initial setup
        if (hovered && Time.time < 3f)
        {
            Debug.LogWarning($"[CardUI] Blocking startup hover for '{cardData?.cardName}'");
            return;
        }
        
        // Block hover during drag
        if (hovered && handController != null && handController.IsDragActive())
        {
            Debug.Log($"[CardUI] Blocking hover during drag for '{cardData?.cardName}'");
            return;
        }
        
        // Determine target state
        targetHoverState = hovered ? HoverState.Hovered : HoverState.None;
        
        // Handle state transitions based on current state
        if (hovered)
        {
            if (currentHoverState == HoverState.None)
            {
                TransitionToState(HoverState.EnteringHover);
            }
            else if (currentHoverState == HoverState.ExitingHover)
            {
                // Reverse the exit animation
                TransitionToState(HoverState.EnteringHover);
            }
        }
        else
        {
            if (currentHoverState == HoverState.Hovered)
            {
                TransitionToState(HoverState.ExitingHover);
            }
            else if (currentHoverState == HoverState.EnteringHover)
            {
                // Reverse the enter animation
                TransitionToState(HoverState.ExitingHover);
            }
        }
    }
    
    /// <summary>
    /// Force immediate hover state without animation
    /// </summary>
    public void ForceEnterHover()
    {
        CancelAllAnimations();
        
        // Set state directly
        currentHoverState = HoverState.Hovered;
        targetHoverState = HoverState.Hovered;
        
        // Apply hover visuals immediately
        layoutSiblingIndex = transform.GetSiblingIndex();
        transform.SetAsLastSibling();
        needsIndexRestore = true;
        
        hoverOffset = Vector3.up * hoverLiftAmount;
        visualPosition = layoutTargetPosition + hoverOffset;
        transform.localPosition = visualPosition;
        transform.localScale = Vector3.one * hoverScaleAmount;
        
        // Force canvas update
        Canvas.ForceUpdateCanvases();
    }
    
    /// <summary>
    /// Force immediate exit from hover
    /// </summary>
    public void ForceExitHover()
    {
        CancelAllAnimations();
        TransitionToState(HoverState.None);
        
        // Apply normal state immediately
        if (needsIndexRestore && layoutSiblingIndex >= 0)
        {
            transform.SetSiblingIndex(layoutSiblingIndex);
            needsIndexRestore = false;
        }
        
        hoverOffset = Vector3.zero;
        visualPosition = layoutTargetPosition;
        transform.localPosition = visualPosition;
        transform.localScale = Vector3.one;
    }
    
    /// <summary>
    /// Force disable hover (used during drag operations)
    /// </summary>
    public void ForceDisableHover()
    {
        CancelAllAnimations();
        
        // Reset to none state
        currentHoverState = HoverState.None;
        targetHoverState = HoverState.None;
        
        // Restore position and scale
        if (needsIndexRestore && layoutSiblingIndex >= 0)
        {
            transform.SetSiblingIndex(layoutSiblingIndex);
            needsIndexRestore = false;
        }
        
        hoverOffset = Vector3.zero;
        
        if (hasValidLayoutPosition)
        {
            transform.localPosition = layoutTargetPosition;
            visualPosition = layoutTargetPosition;
        }
        
        transform.localScale = Vector3.one;
        
        if (highlightEffect != null)
            highlightEffect.SetActive(false);
    }
    
    // ===== ORIGINAL METHODS (adapted to work with new system) =====
    
    public void SetCardData(TimeCardData data)
    {
        if (data == null) return;
        
        cardData = data;
        UpdateDisplay();
    }
    
    public void SetHandController(HandController controller)
    {
        handController = controller;
    }
    
    public void Initialize(TimeCardData cardData, HandController controller, Camera camera)
    {
        SetCardData(cardData);
        SetHandController(controller);
    }
    
    public void InitializeCard(HandController controller, TimeCardData data, Camera canvasCam)
    {
        transform.localScale = Vector3.one;
        CancelAllAnimations();
        
        SetHandController(controller);
        SetCardData(data);
    }
    
    private void UpdateDisplay()
    {
        if (nameText != null)
            nameText.text = cardData.cardName;
        
        if (costText != null)
        {
            float displayCost = cardData.GetDisplayTimeCost();
            costText.text = $"{displayCost:F1}s";
        }
        
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
        
        if (descriptionText != null)
            descriptionText.text = cardData.description;
        
        if (cardArt != null && cardData.cardArt != null)
            cardArt.sprite = cardData.cardArt;
        
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
        
        CheckPlayability();
    }
    
    private void CheckPlayability()
    {
        if (RiftTimeSystem.Instance != null)
        {
            float currentTime = RiftTimeSystem.Instance.GetCurrentTime();
            float cardCost = cardData.GetScaledTimeCost();
            
            isPlayable = currentTime >= cardCost;
            
            if (cardBackground != null)
            {
                Color baseColor = cardBackground.color;
                cardBackground.color = isPlayable ? 
                    baseColor : 
                    new Color(baseColor.r * 0.5f, baseColor.g * 0.5f, baseColor.b * 0.5f, 0.7f);
            }
            
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
    
    public void OnPointerClick(PointerEventData eventData)
    {
        if (!isPlayable || isDragging) return;
        
        if (!isPlayable)
        {
            ShakeCard();
            Debug.Log($"Nicht genug Zeit für {cardData.cardName}!");
            return;
        }
        
        OnCardClicked?.Invoke(cardData);
    }
    
    public void OnPointerEnter(PointerEventData eventData)
    {
        if (HandController.IsGlobalTouchActive) return;
        if (handController != null && handController.IsTouchActive()) return;
        if (Input.touchCount > 0) return;
        if (Time.time < 3f) return;
        if (!Input.mousePresent) return;
        if (handController != null && handController.IsDragActive()) return;
        
        SetHovered(true);
    }
    
    public void OnPointerExit(PointerEventData eventData)
    {
        if (HandController.IsGlobalTouchActive) return;
        if (handController != null && handController.IsTouchActive()) return;
        if (Input.touchCount > 0) return;
        if (isDragging) return;
        if (handController != null && handController.IsDragActive()) return;
        
        SetHovered(false);
    }
    
    private void ShakeCard()
    {
        CancelAllAnimations();
        
        Vector3 originalPos = transform.localPosition;
        LeanTween.moveLocalX(gameObject, originalPos.x + 5f, 0.05f)
            .setEaseShake()
            .setLoopPingPong(2)
            .setOnComplete(() => {
                transform.localPosition = originalPos;
            });
    }
    
    private void StartBorderPulsation()
    {
        if (playableBorderFrame == null || isBorderPulseActive) return;
        
        isBorderPulseActive = true;
        playableBorderFrame.color = new Color(borderColorPrimary.r, borderColorPrimary.g, borderColorPrimary.b, borderMinAlpha);
        playableBorderFrame.gameObject.SetActive(true);
        
        PulseBorder();
    }
    
    private void StopBorderPulsation()
    {
        if (!isBorderPulseActive) return;
        
        isBorderPulseActive = false;
        
        if (borderTweenId >= 0)
        {
            LeanTween.cancel(borderTweenId);
            borderTweenId = -1;
        }
        
        if (playableBorderFrame != null)
        {
            playableBorderFrame.gameObject.SetActive(false);
        }
    }
    
    private void PulseBorder()
    {
        if (!isBorderPulseActive || playableBorderFrame == null) return;
        
        borderTweenId = LeanTween.value(gameObject, borderMinAlpha, borderMaxAlpha, borderPulseDuration / 2f)
            .setEase(borderEaseType)
            .setOnUpdate((float val) => {
                if (playableBorderFrame != null && isBorderPulseActive)
                {
                    Color baseColor = useColorCycling ? 
                        Color.Lerp(borderColorPrimary, borderColorSecondary, (val - borderMinAlpha) / (borderMaxAlpha - borderMinAlpha)) :
                        borderColorPrimary;
                    
                    Color magicalColor = baseColor * glowIntensity;
                    magicalColor.a = val;
                    playableBorderFrame.color = magicalColor;
                }
            })
            .setOnComplete(() => {
                if (isBorderPulseActive)
                {
                    borderTweenId = LeanTween.value(gameObject, borderMaxAlpha, borderMinAlpha, borderPulseDuration / 2f)
                        .setEase(borderEaseType)
                        .setOnUpdate((float val) => {
                            if (playableBorderFrame != null && isBorderPulseActive)
                            {
                                Color baseColor = useColorCycling ? 
                                    Color.Lerp(borderColorSecondary, borderColorPrimary, (val - borderMinAlpha) / (borderMaxAlpha - borderMinAlpha)) :
                                    borderColorPrimary;
                                
                                Color magicalColor = baseColor * glowIntensity;
                                magicalColor.a = val;
                                playableBorderFrame.color = magicalColor;
                            }
                        })
                        .setOnComplete(() => {
                            if (isBorderPulseActive)
                            {
                                PulseBorder();
                            }
                        }).id;
                }
            }).id;
    }
    
    private void CreatePlayableBorderFrame()
    {
        GameObject borderObject = new GameObject("PlayableBorderFrame");
        borderObject.transform.SetParent(transform, false);
        
        playableBorderFrame = borderObject.AddComponent<Image>();
        
        RectTransform borderRect = borderObject.GetComponent<RectTransform>();
        borderRect.anchorMin = Vector2.zero;
        borderRect.anchorMax = Vector2.one;
        borderRect.sizeDelta = Vector2.zero;
        borderRect.anchoredPosition = Vector2.zero;
        
        borderObject.transform.SetAsFirstSibling();
        
        playableBorderFrame.color = Color.clear;
        playableBorderFrame.raycastTarget = false;
        
        CreateBorderSprite();
    }
    
    private void CreateBorderSprite()
    {
        int size = 200;
        Texture2D borderTexture = new Texture2D(size, size);
        Color[] pixels = new Color[size * size];
        
        Vector2 center = new Vector2(size / 2f, size / 2f);
        float maxGlowDistance = glowSize;
        
        for (int x = 0; x < size; x++)
        {
            for (int y = 0; y < size; y++)
            {
                int distFromEdge = Mathf.Min(
                    Mathf.Min(x, size - 1 - x),
                    Mathf.Min(y, size - 1 - y)
                );
                
                Color pixelColor = Color.clear;
                
                if (distFromEdge < maxGlowDistance)
                {
                    float normalizedDist = distFromEdge / maxGlowDistance;
                    
                    if (distFromEdge < 6)
                    {
                        pixelColor = new Color(1f, 1f, 1f, 1f);
                    }
                    else if (distFromEdge < 12)
                    {
                        float innerGlow = 1.0f - ((distFromEdge - 6) / 6.0f);
                        pixelColor = new Color(1f, 1f, 1f, innerGlow * 0.9f);
                    }
                    else
                    {
                        float glowStrength = 1.0f - normalizedDist;
                        float magicalAlpha = Mathf.Pow(glowStrength, 3.0f);
                        
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
        
        Sprite borderSprite = Sprite.Create(
            borderTexture, 
            new Rect(0, 0, size, size), 
            new Vector2(0.5f, 0.5f),
            100,
            0,
            SpriteMeshType.FullRect,
            new Vector4(maxGlowDistance, maxGlowDistance, maxGlowDistance, maxGlowDistance)
        );
        
        if (playableBorderFrame != null)
        {
            playableBorderFrame.sprite = borderSprite;
            playableBorderFrame.type = Image.Type.Sliced;
        }
    }
    
    void Update()
    {
        CheckPlayability();
        
        // Safety check for stuck scales
        if (currentHoverState == HoverState.None && !isDragging && !isBeingDraggedCentrally)
        {
            if (Mathf.Abs(transform.localScale.x - 1f) > 0.01f)
            {
                transform.localScale = Vector3.one;
            }
        }
    }
    
    // ===== DRAG SYSTEM INTEGRATION =====
    
    public void OnCentralDragStart()
    {
        if (!isPlayable) return;
        
        isBeingDraggedCentrally = true;
        isDragging = true;
        
        originalScale = transform.localScale;
        
        Debug.Log($"[CardUI] Central drag start for {cardData?.cardName}");
        
        canvasGroup = GetComponent<CanvasGroup>();
        if (canvasGroup == null)
            canvasGroup = gameObject.AddComponent<CanvasGroup>();
        
        canvasGroup.blocksRaycasts = false;
        
        LeanTween.scale(gameObject, Vector3.one * 1.1f, 0.08f).setEase(LeanTweenType.easeOutExpo);
    }
    
    public void OnCentralDragEnd()
    {
        if (!isBeingDraggedCentrally) return;
        
        isBeingDraggedCentrally = false;
        isDragging = false;
        
        Debug.Log($"[CardUI] Central drag end for {cardData?.cardName}");
        
        CancelAllAnimations();
        
        LeanTween.moveLocal(gameObject, layoutTargetPosition, 0.25f)
            .setEase(LeanTweenType.easeOutBack);
        
        LeanTween.rotateLocal(gameObject, Vector3.zero, 0.25f)
            .setEase(LeanTweenType.easeOutBack);
        
        LeanTween.scale(gameObject, Vector3.one, 0.175f)
            .setEase(hoverEaseType)
            .setOnComplete(() => {
                transform.localScale = Vector3.one;
            });
        
        if (canvasGroup != null)
        {
            canvasGroup.blocksRaycasts = true;
        }
        
        SetHovered(false);
    }
    
    // ===== HELPER METHODS =====
    
    public TimeCardData GetCardData() { return cardData; }
    public bool IsDragging() { return isDragging || isBeingDraggedCentrally; }
    public bool IsHovering() { return currentHoverState == HoverState.Hovered || currentHoverState == HoverState.EnteringHover; }
    public bool IsInHoverAnimation() { return isAnimating; }
    public bool IsBeingDraggedCentrally() { return isBeingDraggedCentrally; }
    
    public void SetInLayoutAnimation(bool inAnimation)
    {
        // This can be used to prevent hover during layout animations if needed
    }
    
    public void EnableHover()
    {
        // Re-enable hover after drag operations
    }
    
    public void SetOriginalRotation(float rotation)
    {
        // Store original rotation if needed
    }
    
    public void UpdateBasePosition(Vector3 newPosition)
    {
        // This is now handled by UpdateLayoutTargetPosition
        UpdateLayoutTargetPosition(newPosition, 0.2f, false);
    }
    
    public static void SetTouchStartedInHandArea(bool valid)
    {
        touchStartedInHandArea = valid;
    }
    
    public static void SetTouchStartedOnValidArea(bool valid)
    {
        touchStartedInHandArea = valid;
    }
    
    public static void SetIsMouseInput(bool isUsingMouse)
    {
        // Static compatibility
    }
    
    public static bool IsMouseInput()
    {
        return Input.mousePresent && Input.touchCount == 0;
    }
}