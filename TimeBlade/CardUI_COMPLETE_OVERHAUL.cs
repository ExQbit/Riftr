// KOMPLETTE ÜBERARBEITUNG des CardUI.cs - Ersetze die gesamte Datei mit diesem Code

using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using TMPro;
using System;

/// <summary>
/// UI-Komponente für eine einzelne Karte in der Hand
/// Implementiert korrektes Touch-basiertes Drag&Drop wo die gehoverte Karte gezogen wird
/// </summary>
public class CardUI : MonoBehaviour, IPointerClickHandler, IPointerEnterHandler, IPointerExitHandler,
    IBeginDragHandler, IDragHandler, IEndDragHandler
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
    
    // Drag & Drop
    private bool isDragging = false;
    private bool canStartDrag = false;
    private Vector3 dragStartPosition;
    private Vector2 pointerStartPosition;
    private Transform originalParent;
    private int originalSiblingIndex;
    private CanvasGroup canvasGroup;
    private HandController handController;
    
    // Drag-Schwellenwerte (NEUE FELDER)
    [Header("Drag-Einstellungen")]
    [SerializeField] public float dragThreshold = 30f; // Pixel für Drag-Erkennung
    [SerializeField] public float verticalDragBias = 1.5f; // Vertikale Bewegung wird stärker gewichtet
    [SerializeField] public float minVerticalSwipe = 15f; // Minimale vertikale Bewegung für Drag
    
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
        
        // Nur direkte Clicks (kein Drag)
        if (Vector2.Distance(eventData.position, pointerStartPosition) < 5f)
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
        // Hover nur wenn kein Touch aktiv ist
        if (handController != null && handController.IsTouchingHandArea()) return;
        
        SetHovered(true);
    }
    
    /// <summary>
    /// Maus verlässt Karte (nur für Desktop)
    /// </summary>
    public void OnPointerExit(PointerEventData eventData)
    {
        // Behalte Hover wenn wir draggen
        if (isDragging) return;
        
        SetHovered(false);
    }
    
    /// <summary>
    /// Setzt den Hover-Status der Karte
    /// </summary>
    public void SetHovered(bool hovered)
    {
        if (isHovered == hovered) return;
        
        isHovered = hovered;
        
        if (highlightEffect != null)
            highlightEffect.SetActive(hovered);
        
        if (hovered)
        {
            // Speichere Original-Index
            originalSiblingIndex = transform.GetSiblingIndex();
            
            // Nach vorne bringen
            transform.SetAsLastSibling();
            
            // Hover-Animation
            if (handController != null)
            {
                float lift = handController.GetHoverLift();
                Vector3 targetPos = transform.localPosition;
                targetPos.y += lift;
                
                LeanTween.cancel(gameObject);
                LeanTween.scale(gameObject, Vector3.one * 1.15f, hoverAnimDuration).setEase(hoverEaseType);
                LeanTween.moveLocal(gameObject, targetPos, hoverAnimDuration).setEase(hoverEaseType);
            }
        }
        else
        {
            // Zurück zur Normalgröße
            LeanTween.scale(gameObject, Vector3.one, hoverAnimDuration * 1.2f).setEase(hoverEaseType);
            
            // Stelle Original-Index wieder her
            if (!isDragging && originalSiblingIndex >= 0)
            {
                transform.SetSiblingIndex(originalSiblingIndex);
            }
            
            // Layout-Update
            if (handController != null)
            {
                handController.UpdateHandLayout();
            }
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
    /// Gibt zurück ob die Karte gerade gezogen wird
    /// </summary>
    public bool IsDragging()
    {
        return isDragging;
    }
    
    /// <summary>
    /// Wird vom HandController aufgerufen wenn ein Touch im gültigen Bereich beginnt
    /// </summary>
    public static void SetTouchStartedInHandArea(bool valid)
    {
        touchStartedInHandArea = valid;
    }
    
    void Update()
    {
        // Spielbarkeit regelmäßig prüfen
        CheckPlayability();
    }
    
    // ===== Drag & Drop Implementation =====
    
    public void OnBeginDrag(PointerEventData eventData)
    {
        if (!isPlayable || !touchStartedInHandArea) return;
        
        // WICHTIG: Nur die gehoverte Karte kann gedraggt werden!
        if (handController != null)
        {
            var hoveredCard = handController.GetHoveredCard();
            if (hoveredCard != this)
            {
                Debug.Log($"[CardUI] Drag abgelehnt - nicht die gehoverte Karte. Hovered: {hoveredCard?.GetCardData()?.cardName}, This: {cardData?.cardName}");
                return;
            }
        }
        
        // Speichere Start-Position für Schwellenwert-Prüfung
        pointerStartPosition = eventData.position;
        dragStartPosition = transform.position;
        originalParent = transform.parent;
        originalSiblingIndex = transform.GetSiblingIndex();
        
        // Noch nicht wirklich draggen - warten auf Schwellenwert
        canStartDrag = true;
    }
    
    public void OnDrag(PointerEventData eventData)
    {
        if (!canStartDrag) return;
        
        // Prüfe ob Drag-Schwellenwert überschritten wurde
        if (!isDragging)
        {
            Vector2 dragDelta = eventData.position - pointerStartPosition;
            
            // Prüfe ob es eine deutliche Aufwärtsbewegung ist
            bool isUpwardSwipe = dragDelta.y > minVerticalSwipe;
            
            // Berechne gewichtete Distanz (vertikale Bewegung zählt mehr)
            float horizontalComponent = Mathf.Abs(dragDelta.x);
            float verticalComponent = Mathf.Abs(dragDelta.y) * verticalDragBias;
            float weightedDistance = horizontalComponent + verticalComponent;
            
            // Drag nur starten wenn:
            // 1. Deutliche Aufwärtsbewegung ODER
            // 2. Gesamtdistanz über Schwellenwert
            if (!isUpwardSwipe && weightedDistance < dragThreshold)
            {
                return; // Noch nicht genug Bewegung
            }
            
            // Drag initiieren
            isDragging = true;
            
            // Informiere HandController
            if (handController != null)
            {
                handController.OnCardStartDrag(this);
            }
            
            // Canvas Group für Raycast-Blocking
            canvasGroup = GetComponent<CanvasGroup>();
            if (canvasGroup == null)
                canvasGroup = gameObject.AddComponent<CanvasGroup>();
            
            canvasGroup.blocksRaycasts = false;
            
            // Karte nach vorne bringen
            transform.SetAsLastSibling();
            
            // Rotation zurücksetzen
            LeanTween.rotateLocal(gameObject, Vector3.zero, dragAnimDuration).setEase(dragEaseType);
            
            Debug.Log($"[CardUI] Drag gestartet für: {cardData?.cardName}");
        }
        
        // Folge dem Mauszeiger/Touch
        Vector3 worldPoint;
        RectTransformUtility.ScreenPointToWorldPointInRectangle(
            transform.parent as RectTransform,
            eventData.position,
            eventData.pressEventCamera,
            out worldPoint
        );
        
        transform.position = worldPoint;
        
        // Visual Feedback wenn über Spielzone
        float screenHeight = Screen.height;
        float playZoneY = screenHeight * 0.5f; // Obere Hälfte des Bildschirms
        
        if (eventData.position.y > playZoneY)
        {
            transform.localScale = Vector3.one * 1.2f;
        }
        else
        {
            transform.localScale = Vector3.one * 1.1f;
        }
    }
    
    public void OnEndDrag(PointerEventData eventData)
    {
        if (!canStartDrag) return;
        
        canStartDrag = false;
        
        // Wenn Drag nie wirklich gestartet wurde
        if (!isDragging)
        {
            // Behandle es als Click
            OnPointerClick(eventData);
            return;
        }
        
        isDragging = false;
        
        // Prüfe ob Karte gespielt werden soll
        float screenHeight = Screen.height;
        float playZoneY = screenHeight * 0.5f;
        
        if (eventData.position.y > playZoneY && isPlayable)
        {
            // Versuche Karte zu spielen
            PlayCard();
        }
        else
        {
            // Zurück zur Hand
            ReturnToHand();
        }
        
        // Informiere HandController
        if (handController != null)
        {
            handController.OnCardEndDrag(this);
        }
    }
    
    /// <summary>
    /// Spielt die Karte aus
    /// </summary>
    private void PlayCard()
    {
        if (ZeitwaechterPlayer.Instance != null && RiftCombatManager.Instance != null)
        {
            Debug.Log($"[CardUI] Spiele Karte: {cardData?.cardName}");
            
            // Versuche Karte zu spielen
            RiftCombatManager.Instance.PlayerWantsToPlayCard(cardData, ZeitwaechterPlayer.Instance);
            
            // Die Karte wird durch Events aus der Hand entfernt wenn erfolgreich
        }
    }
    
    /// <summary>
    /// Karte zurück zur Hand
    /// </summary>
    private void ReturnToHand()
    {
        // Animiere zurück zur ursprünglichen Position
        LeanTween.cancel(gameObject);
        
        // Position
        LeanTween.move(gameObject, dragStartPosition, returnAnimDuration)
            .setEase(returnEaseType);
        
        // Skalierung
        LeanTween.scale(gameObject, Vector3.one, returnAnimDuration * 0.7f)
            .setEase(hoverEaseType);
        
        // Rotation wird durch Layout-Update gehandhabt
        
        if (canvasGroup != null)
        {
            canvasGroup.blocksRaycasts = true;
        }
        
        // Hover zurücksetzen
        SetHovered(false);
    }
}