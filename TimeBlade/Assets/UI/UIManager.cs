using UnityEngine;
using TMPro; // Für TextMeshPro UI Elemente
using UnityEngine.UI; // Für Standard UI Elemente (z.B. Slider, Image)
using System.Collections.Generic; // Für Kartenliste
using System; // Für Action

// Verwaltet die Haupt-UI-Elemente und reagiert auf Spielzustandsänderungen.
public class UIManager : MonoBehaviour
{
    // --- Referenzen zu UI-Elementen (Müssen im Editor zugewiesen werden!) ---
    [Header("Game State Panels")]
    [SerializeField] private GameObject mainMenuPanel; // Beispiel
    [SerializeField] private GameObject worldMapPanel; // Beispiel
    [SerializeField] private GameObject battleUIPanel;   // Haupt-Panel für Kampf-UI
    [SerializeField] private GameObject pauseMenuPanel;  // Beispiel
    [SerializeField] private GameObject loadingScreen; // Beispiel

    [Header("Battle UI Elements")]
    [SerializeField] private TextMeshProUGUI timerText; // Anzeige für den Countdown
    [SerializeField] private Slider playerHealthSlider; // Lebensanzeige Spieler
    [SerializeField] private TextMeshProUGUI playerHealthText; // Text für HP Spieler
    [SerializeField] private Slider enemyHealthSlider; // Lebensanzeige Gegner (Beispiel für einen Gegner)
    [SerializeField] private TextMeshProUGUI enemyHealthText; // Text für HP Gegner
    [SerializeField] private Transform handContainer; // Layout-Gruppe für Karten auf der Hand
    [SerializeField] private GameObject cardPrefab; // Prefab für eine einzelne Karte in der UI
    // TODO: Referenzen für Gegner-Intention, Ablagestapel-Zähler etc. hinzufügen

    [Header("Time Settings")]
    [SerializeField] private Color warningTimeColor = Color.yellow;
    [SerializeField] private Color criticalTimeColor = Color.red;
    // [SerializeField] private float warningTimeThreshold = 15.0f; // CS0414 Fix: Wert wurde nie verwendet
    // [SerializeField] private float criticalTimeThreshold = 5.0f; // CS0414 Fix: Wert wurde nie verwendet
    private Color defaultTimeColor;

    // --- Abonnements & Lebenszyklus ---

    private void OnEnable()
    {
        SubscribeToEvents();
    }

    private void OnDisable()
    {
        UnsubscribeFromEvents();
    }

    void Start()
    {
        // Standardfarbe des Timers speichern
        if (timerText != null) defaultTimeColor = timerText.color;

        // Initialzustand der UI setzen (basierend auf dem aktuellen GameManager-Status)
        if (GameManager.Instance != null)
        {
            HandleGameStateChanged(GameManager.Instance.CurrentState);
        }
        else
        {
            Debug.LogWarning("UIManager could not find GameManager at Start.");
            // Standardmäßig vielleicht nur MainMenu anzeigen?
            ShowPanel(mainMenuPanel); 
        }
        
        // Initiale UI-Werte setzen (z.B. volle HP)
        // TODO: Besser über Events bei Spielstart lösen
        UpdatePlayerHealthUI(100, 100); // Beispielwerte
        // UpdateEnemyHealthUI(50, 50); // Beispielwerte
    }

    // --- Event (De-)Abonnements --- 
    private void SubscribeToEvents()
    {
        GameManager.OnStateChanged += HandleGameStateChanged;
        TimeManager.OnTimeChanged += UpdateTimerDisplay;  
        TimeManager.OnTimerExpired += HandleTimerExpired;
        TimeManager.OnTimerWarning += HandleTimerWarning; 
        TimeManager.OnTimerCritical += HandleTimerCritical; 
        
        PlayerController.OnHealthChanged += UpdatePlayerHealthUI; 
        
        // Fehler CS0120 und CS0123 für EnemyController.OnHealthChanged
        // Das Event ist nicht static, und UpdateEnemyHealthUI muss die korrekte Signatur haben.
        // Da wir keine sichere enemyController-Instanz hier haben und um Fehler zu isolieren, kommentieren wir es aus.
        // if (enemyController != null) enemyController.OnHealthChanged += UpdateEnemyHealthUI; 

        // Hand.OnHandChanged += UpdateHandUI; // Hand-Klasse/Event ggf. noch nicht implementiert
        Debug.Log("UIManager: Subscribed to events");
    }

    private void UnsubscribeFromEvents()
    {
        GameManager.OnStateChanged -= HandleGameStateChanged;
        TimeManager.OnTimeChanged -= UpdateTimerDisplay; 
        TimeManager.OnTimerExpired -= HandleTimerExpired;
        TimeManager.OnTimerWarning -= HandleTimerWarning; 
        TimeManager.OnTimerCritical -= HandleTimerCritical; 

        PlayerController.OnHealthChanged -= UpdatePlayerHealthUI;

        // Fehler CS0120 und CS0123 für EnemyController.OnHealthChanged
        // if (enemyController != null) enemyController.OnHealthChanged -= UpdateEnemyHealthUI; 
        
        // Hand.OnHandChanged -= UpdateHandUI;
        Debug.Log("UIManager: Unsubscribed from events");
    }

    // --- Event Handler --- 

    private void HandleGameStateChanged(GameState newState)
    {
        Debug.Log($"UIManager received state change: {newState}");
        // Alle Panels erstmal ausblenden (oder spezifische Logik)
        HideAllPanels();

        // Das richtige Panel basierend auf dem Zustand anzeigen
        switch (newState)
        {
            case GameState.MainMenu:
                ShowPanel(mainMenuPanel);
                break;
            case GameState.Battle:
                ShowPanel(battleUIPanel);
                break;
            case GameState.Paused:
                ShowPanel(pauseMenuPanel); 
                // Oft wird das Pause-Menü über das aktuelle Panel gelegt
                // ShowPanel(battleUIPanel); // Battle-UI im Hintergrund sichtbar lassen? 
                break;
            case GameState.Loading:
                ShowPanel(loadingScreen);
                break;
            default:
                Debug.LogWarning("Unhandled GameState in UIManager!");
                break;
        }
    }

    // Korrekte Signatur für TimeManager.OnTimeChanged (Action<float>)
    private void UpdateTimerDisplay(float displayTime) 
    {
        if (timerText != null) timerText.text = $"Time: {Mathf.Max(0, displayTime):00.0}";
    }

    private void HandleTimerExpired()
    {
        Debug.Log("UIManager received Timer Expired event.");
        // TODO: Visuelles Feedback, dass die Zeit abgelaufen ist (z.B. rotes Aufblitzen)
        if (timerText != null) 
        {
            timerText.text = "TIME UP!"; // Deutlichere Nachricht
            timerText.color = criticalTimeColor; // Farbe auf kritisch setzen
        }
    }

    private void HandleTimerWarning()
    {
        if (timerText != null && timerText.color != criticalTimeColor) // Nicht überschreiben, wenn schon kritisch
        {
            timerText.color = warningTimeColor;
            Debug.Log("UIManager: Timer color set to warning.");
        }
    }

    private void HandleTimerCritical()
    {
        if (timerText != null)
        {
            timerText.color = criticalTimeColor;
            Debug.Log("UIManager: Timer color set to critical.");
        }
    }

    // NEU: Handler für Spieler-HP
    // Korrekte Signatur für PlayerController.OnHealthChanged (Action<int, int>)
    // und potenziell EnemyController.OnHealthChanged (Action<int, int>)
    private void UpdatePlayerHealthUI(int currentHealth, int maximumHealth)
    {
        if (playerHealthSlider != null) { playerHealthSlider.maxValue = maximumHealth; playerHealthSlider.value = currentHealth; }
        if (playerHealthText != null) playerHealthText.text = $"Player: {currentHealth} / {maximumHealth}";
    }

    // Korrekte Signatur für EnemyController.OnHealthChanged (Action<int, int>), aber Event-Abo ist auskommentiert
    private void UpdateEnemyHealthUI(int currentHealth, int maximumHealth) 
    {
        if (enemyHealthSlider != null) { enemyHealthSlider.maxValue = maximumHealth; enemyHealthSlider.value = currentHealth; }
        if (enemyHealthText != null) enemyHealthText.text = $"Enemy: {currentHealth} / {maximumHealth}";
    }

    // NEU: Handler für Hand-Änderungen
    private void UpdateHandUI(List<CardData> cards)
    {
        if (handContainer == null || cardPrefab == null) return;

        // 1. Alte Karten-UI-Objekte entfernen
        foreach (Transform child in handContainer)
        {
            Destroy(child.gameObject);
        }

        // 2. Neue Karten-UI-Objekte erstellen
        Debug.Log($"Updating Hand UI with {cards.Count} cards.");
        foreach (CardData cardData in cards)
        {
            GameObject cardObject = Instantiate(cardPrefab, handContainer);
            // TODO: Dem Karten-UI-Objekt die CardData übergeben und UI aktualisieren
            // z.B. über eine Methode wie cardObject.GetComponent<CardUI>().Initialize(cardData);
            // Temporär: Name anzeigen
            TextMeshProUGUI cardText = cardObject.GetComponentInChildren<TextMeshProUGUI>();
            if (cardText != null) cardText.text = cardData.cardName;
            // TODO: Button-Listener hinzufügen, um PlayerController.RequestPlayCard aufzurufen
        }
        // TODO: Layout anpassen (z.B. Karten auffächern)
    }


    // --- Hilfsmethoden --- 

    private void ShowPanel(GameObject panelToShow)
    {
        if (panelToShow != null) panelToShow.SetActive(true);
    }

    private void HideAllPanels()
    {
        // Deaktiviert alle zugewiesenen Haupt-Panels
        if (mainMenuPanel != null) mainMenuPanel.SetActive(false);
        if (worldMapPanel != null) worldMapPanel.SetActive(false);
        if (battleUIPanel != null) battleUIPanel.SetActive(false);
        if (pauseMenuPanel != null) pauseMenuPanel.SetActive(false);
        if (loadingScreen != null) loadingScreen.SetActive(false);
    }

    // --- Öffentliche Methoden für Button-Events (Beispiele) ---

    public void OnEndTurnButtonPressed()
    {
         Debug.Log("End Turn button pressed.");
         // Finde den TurnManager und beende den Spielerzug
         TurnManager turnManager = FindFirstObjectByType<TurnManager>(); 
         if (turnManager != null)
         {   
             turnManager.EndPlayerTurn();
         }
         else
         {
             Debug.LogError("TurnManager not found when trying to end turn!");
         }
    }
    
    // TODO: Methoden für Pause, Optionen etc. hinzufügen
}
