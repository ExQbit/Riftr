using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Collections;

/// <summary>
/// Controller für die Handkarten-Darstellung nach Zeitklingen Mobile-Design.
/// Implementiert das gebogene Layout am unteren Bildschirmrand.
/// </summary>
public class HandController : MonoBehaviour
{
    [Header("Layout-Einstellungen")]
    [SerializeField] private float cardSpacing = 80f; // Basis-Abstand zwischen Karten
    [SerializeField] private float maxCardWidth = 120f; // Maximale Breite einer Karte
    [SerializeField] private float fanAngle = 25f; // Maximaler Winkel für Fächer-Effekt
    [SerializeField] private float curveHeight = 30f; // Höhe der Bogen-Kurve
    [SerializeField] private float hoverLift = 20f; // Anhebung bei Hover
    [SerializeField] private float hoverScale = 1.1f; // Vergrößerung bei Hover
    
    [Header("Animation")]
    [SerializeField] private float animationDuration = 0.3f; // Dauer für Karten-Bewegungen
    [SerializeField] private AnimationCurve animationCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);
    
    [Header("Interaktion")]
    [SerializeField] private bool enableFanning = true; // Auffächern bei Touch
    [SerializeField] private float fanSpacing = 150f; // Abstand beim Auffächern
    
    // Karten-Verwaltung
    private List<CardUI> cards = new List<CardUI>();
    private Dictionary<CardUI, Vector2> targetPositions = new Dictionary<CardUI, Vector2>();
    private Dictionary<CardUI, float> targetRotations = new Dictionary<CardUI, float>();
    private CardUI hoveredCard = null;
    private CardUI selectedCard = null;
    private bool isFanned = false;
    
    // Touch-Handling
    private bool isTouching = false;
    private Vector2 touchStartPosition;
    
    void Start()
    {
        // Registriere bei Spieler-Events
        if (ZeitwaechterPlayer.Instance != null)
        {
            ZeitwaechterPlayer.Instance.OnHandChanged += RefreshHandDisplay;
        }
    }
    
    void Update()
    {
        HandleTouchInput();
        UpdateCardPositions();
    }
    
    /// <summary>
    /// Fügt eine neue Karte zur Hand hinzu
    /// </summary>
    public void AddCard(CardUI card)
    {
        if (!cards.Contains(card))
        {
            cards.Add(card);
            card.transform.SetParent(transform);
            card.OnCardHovered += HandleCardHover;
            card.OnCardClicked += HandleCardClick;
            
            // Initiale Position außerhalb des Bildschirms
            card.transform.localPosition = new Vector3(Screen.width, 0, 0);
            
            UpdateCardLayout();
        }
    }
    
    /// <summary>
    /// Entfernt eine Karte aus der Hand
    /// </summary>
    public void RemoveCard(CardUI card)
    {
        if (cards.Contains(card))
        {
            cards.Remove(card);
            targetPositions.Remove(card);
            targetRotations.Remove(card);
            
            card.OnCardHovered -= HandleCardHover;
            card.OnCardClicked -= HandleCardClick;
            
            if (hoveredCard == card) hoveredCard = null;
            if (selectedCard == card) selectedCard = null;
            
            UpdateCardLayout();
        }
    }
    
    /// <summary>
    /// Aktualisiert die komplette Hand-Anzeige
    /// </summary>
    public void RefreshHandDisplay()
    {
        // Entferne alle alten Karten-UI
        foreach (var card in cards.ToArray())
        {
            Destroy(card.gameObject);
        }
        cards.Clear();
        targetPositions.Clear();
        targetRotations.Clear();
        
        // Erstelle neue Karten-UI basierend auf Spieler-Hand
        if (ZeitwaechterPlayer.Instance != null)
        {
            var hand = ZeitwaechterPlayer.Instance.GetHand();
            for (int i = 0; i < hand.Count; i++)
            {
                CreateCardUI(hand[i], i);
            }
        }
        
        UpdateCardLayout();
    }
    
    /// <summary>
    /// Erstellt eine neue Karten-UI
    /// </summary>
    private void CreateCardUI(TimeCardData cardData, int index)
    {
        // Hole Prefab von ZeitwaechterPlayer
        var player = ZeitwaechterPlayer.Instance;
        if (player == null) return;
        
        // Nutze Reflection um das cardPrefab zu bekommen (oder mache es public)
        var cardPrefabField = typeof(ZeitwaechterPlayer).GetField("cardPrefab", 
            System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
        
        if (cardPrefabField != null)
        {
            GameObject prefab = cardPrefabField.GetValue(player) as GameObject;
            if (prefab != null)
            {
                GameObject cardGO = Instantiate(prefab, transform);
                CardUI cardUI = cardGO.GetComponent<CardUI>();
                if (cardUI != null)
                {
                    cardUI.SetCardData(cardData);
                    AddCard(cardUI);
                }
            }
        }
    }
    
    /// <summary>
    /// Berechnet das Layout für alle Karten
    /// </summary>
    private void UpdateCardLayout()
    {
        int cardCount = cards.Count;
        if (cardCount == 0) return;
        
        float containerWidth = GetComponent<RectTransform>().rect.width;
        
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
        
        // Positioniere jede Karte
        for (int i = 0; i < cardCount; i++)
        {
            CardUI card = cards[i];
            
            // X-Position
            float x = startX + i * actualSpacing;
            
            // Y-Position (Bogen-Kurve)
            float normalizedPos = cardCount > 1 ? (float)i / (cardCount - 1) : 0.5f;
            float curveT = (normalizedPos - 0.5f) * 2f; // -1 bis 1
            float y = -Mathf.Pow(curveT, 2) * curveHeight + curveHeight;
            
            // Rotation (Fächer-Effekt)
            float rotation = 0f;
            if (!isFanned && cardCount > 1)
            {
                rotation = Mathf.Lerp(-fanAngle, fanAngle, normalizedPos);
            }
            
            // Bei Hover: Anheben
            if (card == hoveredCard)
            {
                y += hoverLift;
                rotation = 0f; // Gerade ausrichten
            }
            
            targetPositions[card] = new Vector2(x, y);
            targetRotations[card] = rotation;
        }
    }
    
    /// <summary>
    /// Aktualisiert die Positionen aller Karten (smooth)
    /// </summary>
    private void UpdateCardPositions()
    {
        foreach (var card in cards)
        {
            if (targetPositions.ContainsKey(card))
            {
                // Position
                Vector2 targetPos = targetPositions[card];
                Vector2 currentPos = card.transform.localPosition;
                card.transform.localPosition = Vector2.Lerp(currentPos, targetPos, 
                    Time.deltaTime / animationDuration);
                
                // Rotation
                float targetRot = targetRotations[card];
                float currentRot = card.transform.localEulerAngles.z;
                if (currentRot > 180) currentRot -= 360;
                float newRot = Mathf.Lerp(currentRot, targetRot, Time.deltaTime / animationDuration);
                card.transform.localEulerAngles = new Vector3(0, 0, newRot);
                
                // Scale bei Hover
                float targetScale = (card == hoveredCard) ? hoverScale : 1f;
                float currentScale = card.transform.localScale.x;
                float newScale = Mathf.Lerp(currentScale, targetScale, Time.deltaTime / animationDuration);
                card.transform.localScale = Vector3.one * newScale;
                
                // Z-Order (gehobene Karte oben)
                int sortOrder = cards.IndexOf(card);
                if (card == hoveredCard) sortOrder = 100;
                if (card == selectedCard) sortOrder = 101;
                
                Canvas canvas = card.GetComponent<Canvas>();
                if (canvas != null) canvas.sortingOrder = sortOrder;
            }
        }
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
                HandleTouchStart(touch.position);
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
                HandleTouchStart(Input.mousePosition);
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
        RectTransform rect = GetComponent<RectTransform>();
        Vector2 localPoint;
        
        if (RectTransformUtility.ScreenPointToLocalPointInRectangle(
            rect, position, null, out localPoint))
        {
            if (rect.rect.Contains(localPoint))
            {
                isTouching = true;
                touchStartPosition = position;
                
                // Starte Auffächern
                StartCoroutine(FanCards());
            }
        }
    }
    
    /// <summary>
    /// Touch/Click endet
    /// </summary>
    private void HandleTouchEnd()
    {
        if (isTouching)
        {
            isTouching = false;
            
            // Beende Auffächern
            StartCoroutine(UnfanCards());
        }
    }
    
    /// <summary>
    /// Fächert Karten auf
    /// </summary>
    private IEnumerator FanCards()
    {
        isFanned = true;
        UpdateCardLayout();
        yield return new WaitForSeconds(0.1f); // Kurze Verzögerung für smoothen Übergang
    }
    
    /// <summary>
    /// Karten wieder zusammenrücken
    /// </summary>
    private IEnumerator UnfanCards()
    {
        yield return new WaitForSeconds(0.1f); // Kurze Verzögerung
        
        if (!isTouching) // Nur wenn nicht wieder berührt
        {
            isFanned = false;
            UpdateCardLayout();
        }
    }
    
    /// <summary>
    /// Karte wird gehovert
    /// </summary>
    private void HandleCardHover(CardUI card, bool isHovering)
    {
        if (isHovering)
        {
            hoveredCard = card;
        }
        else if (hoveredCard == card)
        {
            hoveredCard = null;
        }
        
        UpdateCardLayout();
    }
    
    /// <summary>
    /// Karte wird angeklickt
    /// </summary>
    private void HandleCardClick(CardUI card)
    {
        selectedCard = card;
        
        // Animation für Auswahl
        StartCoroutine(AnimateCardSelection(card));
    }
    
    /// <summary>
    /// Animiert Karten-Auswahl
    /// </summary>
    private IEnumerator AnimateCardSelection(CardUI card)
    {
        // Hebe Karte an
        Vector2 originalPos = targetPositions[card];
        targetPositions[card] = originalPos + Vector2.up * 50f;
        
        yield return new WaitForSeconds(0.2f);
        
        // Setze zurück
        targetPositions[card] = originalPos;
        selectedCard = null;
        UpdateCardLayout();
    }
    
    void OnDestroy()
    {
        // Events abmelden
        if (ZeitwaechterPlayer.Instance != null)
        {
            ZeitwaechterPlayer.Instance.OnHandChanged -= RefreshHandDisplay;
        }
    }
}
