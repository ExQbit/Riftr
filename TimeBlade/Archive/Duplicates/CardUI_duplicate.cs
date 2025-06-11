using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using TMPro;
using System;

/// <summary>
/// UI-Komponente für eine einzelne Karte in der Hand.
/// Implementiert das Zeitklingen Mobile-Design mit Hover, Drag und Selektion.
/// </summary>
public class CardUI : MonoBehaviour, IPointerEnterHandler, IPointerExitHandler, 
    IPointerDownHandler, IPointerUpHandler, IDragHandler, IBeginDragHandler, IEndDragHandler
{
    [Header("UI-Referenzen")]
    [SerializeField] private Image cardBackground;
    [SerializeField] private Image cardFrame;
    [SerializeField] private TextMeshProUGUI nameText;
    [SerializeField] private TextMeshProUGUI costText;
    [SerializeField] private TextMeshProUGUI descriptionText;
    [SerializeField] private Image elementIcon;
    [SerializeField] private Image typeIcon;
    
    [Header("Farben")]
    [SerializeField] private Color normalColor = new Color(0.2f, 0.2f, 0.3f);
    [SerializeField] private Color playableColor = new Color(0.2f, 0.4f, 0.6f); // Hellblau
    [SerializeField] private Color buffedColor = new Color(0.2f, 0.5f, 0.3f); // Hellgrün
    [SerializeField] private Color debuffedColor = new Color(0.5f, 0.2f, 0.2f); // Rot
    
    [Header("Glow-Effekt")]
    [SerializeField] private Image glowBorder; // Leuchtender Rand
    [SerializeField] private float glowIntensity = 1.5f;
    [SerializeField] private AnimationCurve glowPulse = AnimationCurve.Linear(0, 0.8f, 1, 1.2f);
    
    [Header("Interaktion")]
    [SerializeField] private float dragThreshold = 30f; // Pixel bevor Drag startet
    [SerializeField] private float playZoneY = 200f; // Y-Position ab der Karte gespielt wird
    
    // Karten-Daten
    private TimeCardData cardData;
    private bool isPlayable = false;
    private bool isBuffed = false;
    private bool isDebuffed = false;
    
    // Interaktions-Status
    private bool isHovered = false;
    private bool isDragging = false;
    private Vector3 dragStartPosition;
    private Vector2 dragOffset;
    
    // Events
    public Action<CardUI, bool> OnCardHovered; // card, isHovering
    public Action<CardUI> OnCardClicked;
    public Action<CardUI, Vector2> OnCardDragged; // card, screenPosition
    public Action<CardUI> OnCardPlayed;
    
    // Animation
    private float glowTime = 0f;
    
    void Awake()
    {
        // Stelle sicher dass Canvas-Komponente vorhanden ist
        if (GetComponent<Canvas>() == null)
        {
            gameObject.AddComponent<Canvas>();
            gameObject.AddComponent<GraphicRaycaster>();
        }
    }
    
    void Update()
    {
        // Glow-Animation
        if (isPlayable && glowBorder != null)
        {
            glowTime += Time.deltaTime;
            float glowAlpha = glowPulse.Evaluate(glowTime % 1f);
            Color glowColor = glowBorder.color;
            glowColor.a = glowAlpha;
            glowBorder.color = glowColor;
        }
    }
    
    /// <summary>
    /// Setzt die Kartendaten und aktualisiert die Anzeige
    /// </summary>
    public void SetCardData(TimeCardData data)
    {
        cardData = data;
        UpdateDisplay();
    }
    
    /// <summary>
    /// Aktualisiert die visuelle Darstellung
    /// </summary>
    private void UpdateDisplay()
    {
        if (cardData == null) return;
        
        // Name
        if (nameText != null)
            nameText.text = cardData.cardName;
        
        // Kosten
        if (costText != null)
        {
            float displayCost = cardData.baseTimeCost;
            costText.text = $"{displayCost:F1}s";
            
            // Farbe basierend auf Modifikationen
            if (isBuffed)
                costText.color = Color.green;
            else if (isDebuffed)
                costText.color = Color.red;
            else
                costText.color = Color.white;
        }
        
        // Beschreibung
        if (descriptionText != null)
        {
            descriptionText.text = GetCardDescription();
        }
        
        // Rahmenfarbe basierend auf Spielbarkeit
        UpdateCardState();
    }
    
    /// <summary>
    /// Generiert Kartenbeschreibung basierend auf Typ
    /// </summary>
    private string GetCardDescription()
    {
        string desc = "";
        
        switch (cardData.cardType)
        {
            case TimeCardType.Attack:
                desc = $"Fügt {cardData.baseDamage} Schaden zu";
                if (cardData.isAoE) desc += " (AoE)";
                break;
                
            case TimeCardType.Defense:
                desc = $"Blockt für {cardData.blockDuration:F1}s";
                if (cardData.timeReward > 0) desc += $"\n+{cardData.timeReward:F1}s bei Erfolg";
                break;
                
            case TimeCardType.TimeManipulation:
                if (cardData.timeGain > 0) desc = $"Gewinnt {cardData.timeGain:F1}s Zeit";
                if (cardData.effectDuration > 0) desc += $"\nEffekt: {cardData.effectDuration:F1}s";
                break;
        }
        
        return desc;
    }
    
    /// <summary>
    /// Aktualisiert den Kartenstatus (spielbar, gebufft, etc.)
    /// </summary>
    public void UpdateCardState()
    {
        // Berechne ob Karte spielbar ist
        if (RiftTimeSystem.Instance != null && cardData != null)
        {
            float currentTime = RiftTimeSystem.Instance.GetCurrentTime();
            isPlayable = currentTime >= cardData.baseTimeCost; // Vereinfacht, ohne Modifikatoren
        }
        
        // Setze Rahmenfarbe
        if (glowBorder != null)
        {
            glowBorder.gameObject.SetActive(isPlayable || isBuffed || isDebuffed);
            
            if (isDebuffed)
                glowBorder.color = debuffedColor;
            else if (isBuffed)
                glowBorder.color = buffedColor;
            else if (isPlayable)
                glowBorder.color = playableColor;
        }
        
        // Hintergrundfarbe
        if (cardBackground != null)
        {
            if (!isPlayable)
                cardBackground.color = normalColor * 0.7f; // Dunkler wenn nicht spielbar
            else
                cardBackground.color = normalColor;
        }
    }
    
    // ===== Event Handler =====
    
    public void OnPointerEnter(PointerEventData eventData)
    {
        if (!isDragging)
        {
            isHovered = true;
            OnCardHovered?.Invoke(this, true);
            
            // Zeige große Karten-Vorschau
            ShowCardPreview();
        }
    }
    
    public void OnPointerExit(PointerEventData eventData)
    {
        isHovered = false;
        OnCardHovered?.Invoke(this, false);
        
        // Verstecke Vorschau
        HideCardPreview();
    }
    
    public void OnPointerDown(PointerEventData eventData)
    {
        dragStartPosition = transform.position;
        
        // Markiere als ausgewählt
        OnCardClicked?.Invoke(this);
    }
    
    public void OnPointerUp(PointerEventData eventData)
    {
        if (!isDragging)
        {
            // Normaler Klick - könnte für Detail-Ansicht verwendet werden
        }
    }
    
    public void OnBeginDrag(PointerEventData eventData)
    {
        // Prüfe Drag-Threshold
        if (Vector2.Distance(eventData.position, eventData.pressPosition) > dragThreshold)
        {
            isDragging = true;
            
            // Berechne Offset für smooth dragging
            Vector3 worldPoint;
            RectTransformUtility.ScreenPointToWorldPointInRectangle(
                transform as RectTransform, 
                eventData.position, 
                eventData.pressEventCamera, 
                out worldPoint
            );
            dragOffset = transform.position - worldPoint;
            
            // Visuelle Änderungen
            if (cardBackground != null)
                cardBackground.color = normalColor * 1.2f; // Heller beim Ziehen
            
            transform.localScale = Vector3.one * 1.15f; // Größer beim Ziehen
            
            // Sortierung nach oben
            Canvas canvas = GetComponent<Canvas>();
            if (canvas != null) canvas.sortingOrder = 200;
        }
    }
    
    public void OnDrag(PointerEventData eventData)
    {
        if (isDragging)
        {
            // Bewege Karte mit Maus/Touch
            Vector3 worldPoint;
            RectTransformUtility.ScreenPointToWorldPointInRectangle(
                transform.parent as RectTransform, 
                eventData.position, 
                eventData.pressEventCamera, 
                out worldPoint
            );
            
            transform.position = worldPoint + (Vector3)dragOffset;
            
            // Event für visuelle Feedback
            OnCardDragged?.Invoke(this, eventData.position);
            
            // Prüfe ob in Spielzone
            if (transform.localPosition.y > playZoneY)
            {
                // Visuelles Feedback dass Karte gespielt werden kann
                transform.localScale = Vector3.one * 1.2f;
            }
            else
            {
                transform.localScale = Vector3.one * 1.15f;
            }
        }
    }
    
    public void OnEndDrag(PointerEventData eventData)
    {
        if (isDragging)
        {
            isDragging = false;
            
            // Prüfe ob Karte gespielt werden soll
            if (transform.localPosition.y > playZoneY && isPlayable)
            {
                // Spiele Karte
                PlayCard();
            }
            else
            {
                // Zurück zur Hand
                ReturnToHand();
            }
        }
    }
    
    /// <summary>
    /// Spielt die Karte aus
    /// </summary>
    private void PlayCard()
    {
        if (cardData == null || !isPlayable) 
        {
            ReturnToHand();
            return;
        }
        
        // Versuche Karte zu spielen
        if (ZeitwaechterPlayer.Instance != null)
        {
            bool success = ZeitwaechterPlayer.Instance.PlayCard(cardData);
            
            if (success)
            {
                OnCardPlayed?.Invoke(this);
                
                // Animation für erfolgreiches Spielen
                LeanTween.scale(gameObject, Vector3.zero, 0.3f)
                    .setEaseInBack()
                    .setOnComplete(() => Destroy(gameObject));
            }
            else
            {
                // Fehlgeschlagen - zurück zur Hand
                ReturnToHand();
            }
        }
    }
    
    /// <summary>
    /// Karte zurück zur Hand
    /// </summary>
    private void ReturnToHand()
    {
        // Animation zurück zur ursprünglichen Position
        LeanTween.move(gameObject, dragStartPosition, 0.3f)
            .setEaseOutBack();
        
        LeanTween.scale(gameObject, Vector3.one, 0.2f);
        
        // Reset visuals
        if (cardBackground != null)
            cardBackground.color = normalColor;
    }
    
    /// <summary>
    /// Zeigt große Karten-Vorschau
    /// </summary>
    private void ShowCardPreview()
    {
        // TODO: Implementiere große Karten-Ansicht über der Hand
        // Für jetzt nur Debug
        Debug.Log($"[CardUI] Vorschau: {cardData?.cardName}");
    }
    
    /// <summary>
    /// Versteckt Karten-Vorschau
    /// </summary>
    private void HideCardPreview()
    {
        // TODO: Verstecke große Karten-Ansicht
    }
    
    // Getter
    public TimeCardData GetCardData() => cardData;
    public bool IsPlayable() => isPlayable;
}
