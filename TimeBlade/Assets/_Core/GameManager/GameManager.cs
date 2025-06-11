using System;
using UnityEngine;
using UnityEngine.SceneManagement; // Falls Szenenwechsel benötigt wird

// Enum für die verschiedenen Spielzustände
// Kann auch in einer eigenen Datei liegen, wenn von vielen Skripten verwendet
public enum GameState
{
    MainMenu,
    Loading,
    Map,
    Battle,
    Paused,
    GameOver,
    Victory
    // Weitere Zustände nach Bedarf (z.B. WorldMap, Cutscene, Shop)
}

// Verantwortlich für die Verwaltung des globalen Spielzustands und die Koordination anderer Manager.
public class GameManager : MonoBehaviour
{
    // Globale Zustandsvariablen
    public GameState CurrentState { get; private set; } = GameState.MainMenu; // Startzustand setzen
    private GameData currentGameData; // Hält die Daten des aktuellen Spiels

    // Singleton-Instanz
    public static GameManager Instance { get; private set; }

    // Events
    public static event Action<GameState> OnStateChanged;

    void Awake()
    {
        // Singleton Pattern Implementierung
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject); // Stellt sicher, dass der GameManager nicht zerstört wird, wenn eine neue Szene geladen wird
        }
        else
        {
            Debug.LogWarning("Duplicate GameManager instance detected. Destroying new instance.");
            Destroy(gameObject);
            return; // Wichtig: Verhindert weiteren Code-Ausführung in dieser Instanz
        }

        // FindManagers() Methode wird nicht mehr benötigt.
    }

    void Start() // Unity's Start method
    {
        // Spiel-Daten laden oder neu erstellen
        // Abonnieren des OnDataLoaded-Events, bevor LoadGame aufgerufen wird
        SaveManager.OnDataLoaded += HandleDataLoaded;
        SaveManager.Instance.LoadGame(); // Löst OnDataLoaded aus, wenn fertig
        Debug.Log("GameManager: Subscribed to OnDataLoaded and initiated game load.");

        // Setze den initialen Zustand beim Spielstart (kann auch in Awake erfolgen)
        // Wichtig: Stelle sicher, dass andere Manager bereit sind, bevor Zustandslogik ausgeführt wird.
        // ChangeState(GameState.MainMenu); // Wird jetzt durch den Default-Wert oben gesetzt
        Debug.Log($"GameManager started in state: {CurrentState}");
        // Löst das Event für den initialen Zustand aus, falls nötig
        OnStateChanged?.Invoke(CurrentState);
        HandleEnterState(CurrentState); // Führe Enter-Logik für den Startzustand aus
    }

    private void OnDestroy()
    {
        // Wichtig: Events abbestellen, um Memory Leaks zu vermeiden
        SaveManager.OnDataLoaded -= HandleDataLoaded;        
        TimeManager.OnTimerExpired -= HandleTimeExpiredInBattle; // Ist static, keine Instanzprüfung nötig
        Debug.Log("GameManager destroyed, events unsubscribed.");
    }

    // Wird aufgerufen, wenn der SaveManager die Daten geladen hat
    private void HandleDataLoaded(GameData loadedData)
    {   
        currentGameData = loadedData;
        if (currentGameData == null) // Fallback, falls etwas schiefgeht
        {   
            Debug.LogWarning("GameManager: Loaded data was null, creating new GameData.");
            currentGameData = new GameData();
        }
        // Setze den anfänglichen Zustand basierend auf geladenen Daten oder Standard
        ChangeState(currentGameData.currentGameState); 
        Debug.Log($"GameManager: GameData loaded, initial state set to {CurrentState}");
    }

    // Methode, die aufgerufen wird, wenn der Timer im Kampf abläuft
    private void HandleTimeExpiredInBattle()
    {
        if (CurrentState == GameState.Battle)
        {
            Debug.Log("GameManager: Timer expired during battle! Implementing consequences...");
            // TODO: Logik für das Ende des Spielerzugs oder andere Konsequenzen implementieren
            // z.B. TurnManager.Instance.EndPlayerTurnByTimeout();
        }
    }

    // Methode zum Speichern der Spieldaten (Beispiel)
    public void SaveGameData()
    {
        if (currentGameData == null) 
        {
            Debug.LogWarning("GameManager: currentGameData is null, cannot save.");
            return;
        }
        // Den aktuellen Zustand vor dem Speichern in die GameData schreiben
        currentGameData.currentGameState = CurrentState;
        // Hier könnten weitere Daten gesammelt werden, z.B. Spielerposition, Inventar etc.
        SaveManager.Instance.SaveGame(); 
        Debug.Log("Game data saved.");
    }

    // Hauptmethode zur Zustandsänderung
    public void ChangeState(GameState newState)
    {
        if (CurrentState == newState) return; // Nichts tun, wenn der Zustand gleich bleibt

        // Aktionen beim Verlassen des alten Zustands
        HandleExitState(CurrentState);

        GameState previousState = CurrentState;
        CurrentState = newState;
        Debug.Log($"Game State changed from {previousState} to {CurrentState}");

        // Aktionen beim Betreten des neuen Zustands
        HandleEnterState(CurrentState);

        // Event auslösen, um andere Systeme zu informieren
        OnStateChanged?.Invoke(CurrentState);
    }

    // Logik, die ausgeführt wird, wenn ein Zustand VERLASSEN wird
    private void HandleExitState(GameState exitingState)
    {
        switch (exitingState)
        {
            case GameState.MainMenu:
                Debug.Log("Exiting MainMenu State...");
                // Logik zum Verlassen des Hauptmenüs (z.B. UI-Elemente ausblenden)
                break;
            case GameState.Loading:
                Debug.Log("Exiting Loading State...");
                // Logik zum Verlassen des Ladezustands
                break;
            case GameState.Map:
                Debug.Log("Exiting Map State...");
                // TODO: Logik zum Verlassen des Kartenzustands
                break;
            case GameState.Battle:
                Debug.Log("Exiting Battle State...");
                // Direkter Zugriff über Singleton Instanz
                if (TurnManager.Instance != null)
                {
                    TurnManager.Instance.TerminateBattle();
                }
                // Direkter Zugriff über Singleton Instanz
                if (TimeManager.Instance != null) TimeManager.Instance.StopTimer();
                TimeManager.OnTimerExpired -= HandleTimeExpiredInBattle; 
                break;
            case GameState.Paused:
                // Wenn Pause verlassen wird, Timer fortsetzen?
                // Hängt davon ab, wohin wir gehen. Sicherer ist es im EnterState des Zielzustands zu regeln.
                Debug.Log("Exiting Paused State...");
                // Beispiel: Time.timeScale = 1f; // Wieder normal laufen lassen (könnte auch im EnterState des Ziels sein)
                break;
            // Füge hier Logik für andere Zustände hinzu, die beim Verlassen Aufräumarbeiten benötigen.
        }
    }

    // Logik, die ausgeführt wird, wenn ein Zustand BETRETEN wird
    private void HandleEnterState(GameState enteringState)
    {
         switch (enteringState)
        {
            case GameState.MainMenu:
                Debug.Log("Entering MainMenu State...");
                // Lade Hauptmenü-Szene, stoppe Timer etc.
                // Direkter Zugriff über Singleton Instanz
                if (TimeManager.Instance != null) TimeManager.Instance.StopTimer();
                // TODO: Lade ggf. die Hauptmenü-Szene (z.B. SceneManager.LoadScene("MainMenuScene");)
                break;
            case GameState.Loading:
                Debug.Log("Entering Loading State...");
                // Zeige Ladebildschirm an
                // TODO: Implementiere Ladebildschirm-Logik
                break;
            case GameState.Map:
                Debug.Log("Entering Map State...");
                // TODO: Lade Kartenszene, initialisiere Kartenlogik etc.
                // Beispiel: if (TimeManager.Instance != null) TimeManager.Instance.StopTimer(); // Timer stoppen, falls auf Karte nicht gebraucht
                // TODO: Lade ggf. die Karten-Szene (z.B. SceneManager.LoadScene("MapScene");)
                break;
            case GameState.Battle:
                Debug.Log("Entering Battle State...");
                // Starte Kampfsequenz und Timer
                // Direkter Zugriff über Singleton Instanz
                if (TurnManager.Instance != null)
                {
                    TurnManager.Instance.InitiateBattle();
                } else { Debug.LogWarning("TurnManager.Instance is null when entering Battle State!");}
                 // Direkter Zugriff über Singleton Instanz
                 if (TimeManager.Instance != null)
                 {
                    TimeManager.Instance.ResetTimer();
                    TimeManager.Instance.StartTimer();
                 } else { Debug.LogWarning("TimeManager.Instance is null when entering Battle State!");}
                TimeManager.OnTimerExpired -= HandleTimeExpiredInBattle; 
                TimeManager.OnTimerExpired += HandleTimeExpiredInBattle; 
                Debug.Log("Entered Battle State. Timer (re)started and subscribed to OnTimerExpired.");
                // TODO: Lade ggf. die Kampf-Szene (z.B. SceneManager.LoadScene("BattleScene");)
                break;
            case GameState.Paused:
                Debug.Log("Entering Paused State...");
                // Pausiere das Spiel, zeige Pause-Menü
                // Direkter Zugriff über Singleton Instanz
                if (TimeManager.Instance != null) TimeManager.Instance.PauseTimer();
                // Optional: Spiel anhalten (wenn nicht schon durch PauseTimer erledigt)
                // Time.timeScale = 0f;
                break;
            case GameState.GameOver:
                Debug.Log("Entering GameOver State...");
                // Zeige Game Over Bildschirm, stoppe Timer
                // Direkter Zugriff über Singleton Instanz
                if (TimeManager.Instance != null) TimeManager.Instance.StopTimer();
                // TODO: Zeige GameOver UI / Lade GameOver Szene
                break;
            case GameState.Victory:
                 Debug.Log("Entering Victory State...");
                 // Zeige Siegessbildschirm, stoppe Timer
                 // Direkter Zugriff über Singleton Instanz
                 if (TimeManager.Instance != null) TimeManager.Instance.StopTimer();
                 // TODO: Zeige Victory UI / Lade Victory Szene
                 break;
        }
    }

    private void OnApplicationPause(bool pauseStatus)
    {
        if (pauseStatus)
        {
            Debug.Log("GameManager: Application is pausing. Saving game data...");
            SaveGameData();
        }
    }

    private void OnApplicationQuit()
    {
        Debug.Log("GameManager: Application is quitting. Saving game data...");
        SaveGameData();
    }
}