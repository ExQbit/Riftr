using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

/// <summary>
/// TEIL 1/4: Kern-Funktionalität der HandController Klasse
/// Verwaltet die Kartenhand-UI und Basis-Funktionen
/// </summary>
public partial class HandController : MonoBehaviour
{
    [Header("Referenzen")]
    [SerializeField] private Transform handContainer;
    [SerializeField] private GameObject cardUIPrefab;
    
    [Header("Layout-Einstellungen")]
    [SerializeField] private float cardSpacing = 120f;
    [SerializeField] private float maxCardWidth = 120f;
    // [SerializeField] private float fanAngle = 25f; // Nicht mehr verwendet - feste Winkel in ArcLayout
    // [SerializeField] private float curveHeight = 50f; // Nicht mehr verwendet - feste Höhe in ArcLayout
    [SerializeField] private float hoverLift = 50f; // Erhöht für bessere Sichtbarkeit
    [SerializeField] private AnimationCurve layoutCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);
    
    [Header("Touch-Einstellungen")]
    [SerializeField] private bool enableFanning = true;
    [SerializeField] private float fanSpacing = 150f;
    [SerializeField] private float fanAnimationDuration = 0.15f;
    [SerializeField] private LeanTweenType fanEaseType = LeanTweenType.easeOutExpo;
    // [SerializeField] private float touchAreaExtension = 50f; // Nicht mehr verwendet
    
    [Header("Arc Layout Settings")]
    [Tooltip("Radius des Kreises für die Bogenbewegung")]
    [SerializeField] private float arcRadius = 500f;
    [Tooltip("Gesamtwinkel des Bogens in normaler Ansicht (Grad)")]
    [SerializeField] private float arcAngleNormal = 40f;
    [Tooltip("Gesamtwinkel des Bogens beim Fanning (Grad)")]
    [SerializeField] private float arcAngleFanned = 80f;
    [Tooltip("Y-Offset vom Kreismittelpunkt nach oben")]
    [SerializeField] private float arcYOffset = 150f;
    [Tooltip("Kartenbreite für Parallax-Scrolling")]
    [SerializeField] private float parallaxCardWidth = 200f;
    
    [Header("Performance Settings")]
    [Tooltip("Frame-Rate für Animationen (0.016 = 60fps, 0.008 = 120fps)")]
    [SerializeField] private float animationFrameTime = 0.016f;
    [Tooltip("Minimale Bewegung für Updates in Pixel")]
    [SerializeField] private float movementThreshold = 1f;
    
    [Header("Canvas-Einstellungen")]
    [SerializeField] private Canvas parentCanvas;
    [SerializeField] private Camera uiCamera;
    
    [Header("Karten-Vorschau")]
#pragma warning disable 0414
    [SerializeField] private float previewScale = 2.5f;
    [SerializeField] private Vector2 previewOffset = new Vector2(0, 100);
    [SerializeField] private float previewFadeInTime = 0.15f;
    [SerializeField] private float previewFadeOutTime = 0.1f;
#pragma warning restore 0414
    
    [Header("Hover-Hysterese")]
    [SerializeField] private float hoverHysteresisDistance = 80f; // Erhöht für stabileres Hover bei schnellen Bewegungen
    
    [Header("Logging-Einstellungen")]
    [SerializeField] private bool enableDebugLogs = true;
    [Space(5)]
    [SerializeField] private bool logStartup = true;
    [SerializeField] private bool logHandUpdates = false;
    [SerializeField] private bool logTouchEvents = false;
    [SerializeField] private bool logCardPositions = true; // Temporär aktiviert für Rotation-Debug
    [SerializeField] private bool logParallaxDetails = false; // Deaktiviert für weniger Spam
    
    [Header("Parallax Hand-Verschiebung")]
#pragma warning disable 0414
    [SerializeField] private float screenEdgeBuffer = 50f;
    [SerializeField] private float edgeDampingStart = 0.8f;
    [SerializeField] private float edgeDampingStrength = 0.3f;
    [SerializeField] private float returnAnimationDuration = 0.3f;
    [SerializeField] private LeanTweenType returnEaseType = LeanTweenType.easeOutExpo;
#pragma warning restore 0414
    [Tooltip("Parallax-Bewegungsgeschwindigkeit. 1.0 = 1:1 Bewegung, 1.5 = ~167px Finger ergibt 250px Handbewegung")]
    [SerializeField] private float parallaxSensitivity = 1.5f;
    
    [Header("Drag-Schwellenwerte")]
    [SerializeField] public float minVerticalSwipeForDrag = 60f; // Erhöht von 30f
    [SerializeField] public float strongUpwardMovementThreshold = 80f; // Erhöht von 50f
    [SerializeField] public float maxHorizontalMovementForDrag = 150f; // Erhöht von 100f
    
    // Aktive Karten-UI-Elemente
    private List<GameObject> activeCardUIs = new List<GameObject>();
    private bool isFanned = false;
    private bool isTouching = false;
    private CardUI hoveredCard = null;
    private CardUI lastHoveredCard = null;
    private GameObject draggedCard = null;
    private bool isPlayingCard = false;
    
    // Drag-System Variablen
    private bool isDraggingActive = false;
    private Vector2 dragStartPosition;
    private Vector2 lastDragPosition;
    private Vector2 lastFingerPosition;
    private CardUI draggedCardUI = null;
    
    // Horizontale Drift-Erkennung
    private bool hasChangedCards = false;
    private CardUI initialHoveredCard = null;
    
    // Referenz zum Spieler
    private ZeitwaechterPlayer player;
    
    // Canvas-Kamera für Touch-Umrechnung
    private Camera canvasCamera;
    
    // Card Preview System
    private GameObject cardPreview = null;
#pragma warning disable 0414
    private CardUI cardPreviewUI = null;
    private CanvasGroup previewCanvasGroup = null;
#pragma warning restore 0414
    
    // Hover Hysteresis System
    private Vector2 lastHoverPosition;
#pragma warning disable 0414
    private bool isHysteresisActive = false;
#pragma warning restore 0414
    
    // Parallax Hand Shift System
    private float currentHandOffset = 0f;
#pragma warning disable 0414
    private float startHandOffset = 0f;
#pragma warning restore 0414
    private bool isParallaxActive = false;
    private float touchStartTime = 0f;
    private float lastHoverChangeTime = 0f;
    
    // Card-aware parallax variables
    private float initialCardNormalizedPosition = 0.5f;
    private float initialHandOffsetForCard = 0f;
    private float maxAllowedLeftMovement = 0f;
    private float maxAllowedRightMovement = 0f;
    
    // Touch anchor tracking
    private Vector2 touchOffsetFromAnchorCard = Vector2.zero;
    private int anchoredCardIndex = -1;
    private float anchoredCardInitialX = 0f;
    
    // Touch lock variables
    private CardUI initiallyTouchedCard = null;
    private float touchMovementThreshold = 40f;
    private Vector2 touchStartScreenPos = Vector2.zero;
    private Vector2 startTouchPosition = Vector2.zero;
    
    // Global touch state
    private static bool globalTouchActive = false;
    public static bool IsGlobalTouchActive => globalTouchActive;
    
    // Helper-Methoden für Logging mit Kategorien
    private void LogInfo(string message, bool categoryEnabled)
    {
        if (enableDebugLogs && categoryEnabled)
        {
            Debug.Log($"[HandController] {message}");
        }
    }

    private void LogWarning(string message, bool categoryEnabled)
    {
        if (enableDebugLogs && categoryEnabled)
        {
            Debug.LogWarning($"[HandController] {message}");
        }
    }
    
    private void LogError(string message)
    {
        Debug.LogError($"[HandController] {message}");
    }

    void Start()
    {
        LogWarning($"Start - handContainer: {handContainer?.name ?? "NULL"}, cardUIPrefab: {cardUIPrefab?.name ?? "NULL"}", logStartup);
        
        SetupCanvasAndCamera();
        
        if (handContainer == null)
        {
            LogError("handContainer is NULL at Start! Cannot display cards.");
        }
        else
        {
            LogWarning($"HandContainer scale: {handContainer.localScale}", logStartup);
            if (handContainer.localScale != Vector3.one)
            {
                LogError($"WARNING: HandContainer has non-unit scale! This will affect card positions.");
            }
        }
        
        if (cardUIPrefab == null)
        {
            LogError("cardUIPrefab is NULL at Start! Cannot create cards.");
        }
        
        player = ZeitwaechterPlayer.Instance;
        
        if (player != null)
        {
            LogInfo("ZeitwaechterPlayer.Instance found, subscribing to events", logStartup);
            player.OnHandChanged += UpdateHandDisplay;
            LogInfo("Using ONLY OnHandChanged -> UpdateHandDisplay (legacy events DISABLED)", logStartup);
        }
        else
        {
            LogError("ZeitwaechterPlayer.Instance is NULL! Cannot connect to player.");
        }
        
        LogInfo("Calling UpdateHandDisplay from Start", logStartup);
        UpdateHandDisplay();
    }
    
    private void SetupCanvasAndCamera()
    {
        if (parentCanvas == null)
        {
            parentCanvas = GetComponentInParent<Canvas>();
            
            if (parentCanvas == null)
            {
                Canvas[] allCanvases = FindObjectsByType<Canvas>(FindObjectsSortMode.None);
                Debug.Log($"[HandController] Searching for Canvas... found {allCanvases.Length} canvases in scene");
                
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
        
        Canvas rootCanvas = parentCanvas.rootCanvas;
        Debug.Log($"[HandController] Canvas gefunden: {rootCanvas.name}, RenderMode: {rootCanvas.renderMode}");
        
        switch (rootCanvas.renderMode)
        {
            case RenderMode.ScreenSpaceOverlay:
                canvasCamera = null;
                Debug.Log("[HandController] Canvas ist ScreenSpaceOverlay - keine Kamera benötigt");
                break;
                
            case RenderMode.ScreenSpaceCamera:
                canvasCamera = rootCanvas.worldCamera;
                if (canvasCamera == null)
                {
                    canvasCamera = uiCamera;
                    if (canvasCamera == null)
                    {
                        canvasCamera = Camera.main;
                        Debug.LogWarning("[HandController] Canvas.worldCamera ist null! Verwende Camera.main als Fallback");
                    }
                }
                Debug.Log($"[HandController] Canvas ist ScreenSpaceCamera - verwende Kamera: {canvasCamera?.name ?? "NULL"}");
                break;
                
            case RenderMode.WorldSpace:
                canvasCamera = uiCamera ?? Camera.main;
                Debug.Log($"[HandController] Canvas ist WorldSpace - verwende Kamera: {canvasCamera?.name ?? "NULL"}");
                break;
        }
    }
    
    void Update()
    {
        FixCanvasScaleIssues();
        HandleTouchInput();
    }
    
    private void FixCanvasScaleIssues()
    {
        if (handContainer != null)
        {
            Transform current = handContainer.transform;
            while (current != null)
            {
                if (current.localScale == Vector3.zero && current.name.Contains("Canvas"))
                {
                    Debug.LogError($"[HandController] CRITICAL FIX: Canvas '{current.name}' had ZERO scale! Setting to (1,1,1)");
                    current.localScale = Vector3.one;
                }
                current = current.parent;
            }
        }
    }
    
    // Öffentliche Getter-Methoden
    public CardUI GetHoveredCard()
    {
        string hoveredName = hoveredCard != null ? hoveredCard.gameObject.name : "null";
        Debug.Log($"[HandController] GetHoveredCard() called - returning: {hoveredName}");
        return hoveredCard;
    }
    
    public CardUI GetLastHoveredCard()
    {
        if (hoveredCard != null) return hoveredCard;
        
        string lastName = lastHoveredCard != null ? lastHoveredCard.GetCardData()?.cardName : "null";
        Debug.Log($"[HandController] GetLastHoveredCard() returning: {lastName}");
        return lastHoveredCard;
    }
    
    public float GetHoverLift()
    {
        return hoverLift;
    }
    
    public bool IsDragActive()
    {
        bool dragActive = isDraggingActive && draggedCardUI != null;
        
        if (dragActive)
        {
            string draggedCardName = draggedCardUI?.GetCardData()?.cardName ?? "Unknown";
            Debug.Log($"[HandController] IsDragActive() = TRUE - Currently dragging: {draggedCardName}");
        }
        
        return dragActive;
    }
    
    public bool IsTouchActive()
    {
        return isTouching;
    }
    
    public Transform GetHandContainer()
    {
        return handContainer;
    }
}
