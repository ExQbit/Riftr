using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

// Verwaltet den Ablauf der Kampfrunden und Züge.
public class TurnManager : MonoBehaviour
{
    // Singleton Instanz
    public static TurnManager Instance { get; private set; }

    // Enum zur Definition der aktuellen Phase im Kampf
    public enum TurnState { PlayerTurn, EnemyTurn, BetweenTurns, BattleStart, BattleEnd }

    private TurnState currentTurnState = TurnState.BattleStart;

    // Event, das den Wechsel des Zustands signalisiert
    public static event Action<TurnState> OnTurnStateChanged;

    // Referenzen zu den beteiligten Controllern
    private PlayerController playerController;
    private List<EnemyController> enemyControllers = new List<EnemyController>(); // Kann mehrere Gegner geben
    private CardManager cardManager;

    // Sound Namen
    private const string PlayerTurnStartSound = "PlayerTurnStart"; // Beispielname
    private const string EnemyTurnStartSound = "EnemyTurnStart"; // Beispielname

    void Awake()
    {
        // Singleton Pattern Implementierung
        if (Instance == null)
        {
            Instance = this;
            // Optional: DontDestroyOnLoad(gameObject); // Nur wenn der TurnManager über Szenen hinweg bestehen soll
        }
        else
        {
            Debug.LogWarning("Duplicate TurnManager instance detected. Destroying new instance.");
            Destroy(gameObject);
        }
    }

    void Start()
    {
        // Finde die notwendigen Controller
        playerController = FindFirstObjectByType<PlayerController>(); // CS0618 Fix
        enemyControllers = FindObjectsByType<EnemyController>(FindObjectsSortMode.None).Where(e => e != null && e.gameObject.activeInHierarchy).ToList(); // CS0618 Fix
        cardManager = FindFirstObjectByType<CardManager>(); // CS0618 Fix

        // Initialisierung hier, aber Kampfstart erfolgt erst durch InitiateBattle()
        ChangeTurnState(TurnState.BattleStart); // Initialzustand, aber noch nicht aktiv
        Debug.Log("TurnManager Initialized. Waiting for InitiateBattle().");
    }

    // Wird vom GameManager aufgerufen, wenn der Battle State betreten wird.
    public void InitiateBattle()
    {
        // Erneute Prüfung der Referenzen, falls sie dynamisch geladen werden
        if (playerController == null)
        {
            // Sollte jetzt über eine andere Methode zugewiesen werden (z.B. Registrierung)
            // Vorerst lassen wir FindObjectOfType als Fallback
            playerController = FindFirstObjectByType<PlayerController>(); // CS0618 Fix
        }
        if(enemyControllers.Count == 0)
        { 
            // Gegner sollten sich vielleicht beim TurnManager registrieren?
            // Vorerst lassen wir FindObjectOfType als Fallback
            enemyControllers = FindObjectsByType<EnemyController>(FindObjectsSortMode.None).Where(e => e != null && e.gameObject.activeInHierarchy).ToList(); // CS0618 Fix
        }
        if (cardManager == null)
        {
            // CardManager könnte auch ein Singleton sein oder anders referenziert werden.
            // Vorerst lassen wir FindObjectOfType als Fallback
            cardManager = FindFirstObjectByType<CardManager>(); // CS0618 Fix
        }

        if (playerController == null || cardManager == null || enemyControllers.Count == 0)
        {   
            Debug.LogError("TurnManager could not find required controllers (Player, CardManager, or Enemies) on InitiateBattle! Battle cannot proceed correctly.");
            ChangeTurnState(TurnState.BattleEnd);
            return;
        }

        Debug.Log("Initiating Battle...");
        // Hier Listener registrieren
        RegisterEventListeners();

        // Starte die Kampfsequenz
        StartCoroutine(StartBattleSequence());
    }

    // Wird vom GameManager aufgerufen, wenn der Battle State verlassen wird.
    public void TerminateBattle()
    {
        Debug.Log("Terminating Battle...");
        ChangeTurnState(TurnState.BattleEnd);
        StopAllCoroutines(); // Alle laufenden Zug-Coroutinen stoppen
        // Hier Listener deregistrieren
        UnregisterEventListeners();
        // Weitere Aufräumarbeiten?
    }

    private IEnumerator StartBattleSequence()
    {
        Debug.Log("Battle Starting...");
        ChangeTurnState(TurnState.BattleStart);
        // TODO: Initiale Animationen, UI-Einblendungen etc.
        yield return new WaitForSeconds(1.0f); // Kurze Startverzögerung

        // Spieler beginnt
        StartPlayerTurn();
    }

    private void ChangeTurnState(TurnState newState)
    {
        if (currentTurnState == newState) return;

        TurnState previousState = currentTurnState;
        currentTurnState = newState;
        Debug.Log($"Turn state changed from {previousState} to {newState}");

        // Soundeffekt für Zugbeginn
        if (AudioManager.Instance != null)
        { 
            if (newState == TurnState.PlayerTurn)
            {
                AudioManager.Instance.PlaySoundEffect(PlayerTurnStartSound);
            }
            else if (newState == TurnState.EnemyTurn)
            {
                AudioManager.Instance.PlaySoundEffect(EnemyTurnStartSound);
            }
        }

        // Optional: Event auslösen, wenn sich der Zugstatus ändert
        OnTurnStateChanged?.Invoke(newState); 
    }

    public void StartPlayerTurn()
    {
        ChangeTurnState(TurnState.PlayerTurn);
        Debug.Log("--- Player Turn START ---");
        // TODO: Spieler-spezifische Start-of-Turn Effekte (z.B. Block entfernen)
        
        // Dem CardManager signalisieren, Karten zu ziehen etc.
        if (cardManager != null)
        {
            cardManager.StartPlayerTurn(); 
        }
        // UI aktivieren für Spieleraktionen
        // TimeManager ggf. anpassen (z.B. Zeit gutschreiben?)
    }

    // Wird aufgerufen, wenn der Spieler seinen Zug beendet (z.B. durch Button-Klick)
    public void EndPlayerTurn()
    {
        if (currentTurnState != TurnState.PlayerTurn) return;

        Debug.Log("--- Player Turn END ---");
        ChangeTurnState(TurnState.BetweenTurns); // Übergangsphase
        // TODO: End-of-Turn Effekte für Spieler (z.B. Gift-Schaden)
        // TODO: Hand abwerfen? (Je nach Spielregeln)
        // cardManager.DiscardHand(); // Beispiel

        StartCoroutine(EnemyTurnSequence());
    }

    private IEnumerator EnemyTurnSequence()
    {
        ChangeTurnState(TurnState.EnemyTurn);
        Debug.Log("--- Enemy Turn START ---");

        // Alle aktiven Gegner führen nacheinander ihren Zug aus
        foreach (EnemyController enemy in enemyControllers)
        {
            if (enemy != null && enemy.GetCurrentHealth() > 0)
            {
                // TODO: Verfeinern - Warten bis Aktion des Gegners abgeschlossen ist
                enemy.StartTurn(); // Sagt dem Gegner, dass er dran ist
                // Warten, bis der Gegner fertig ist (benötigt Rückmeldung vom EnemyController)
                // yield return new WaitUntil(() => !enemy.IsActing()); // Beispiel für später
                yield return new WaitForSeconds(2.5f); // Einfache feste Wartezeit
            }
        }

        Debug.Log("--- Enemy Turn END ---");
        ChangeTurnState(TurnState.BetweenTurns);
        // TODO: End-of-Turn Effekte für Gegner

        // Nächsten Spielerzug starten
        StartPlayerTurn(); 
    }

    // Methode, um zu prüfen, ob der Kampf vorbei ist
    // (Sollte nach jeder Gesundheitsänderung aufgerufen werden)
    public void CheckForBattleEnd()
    {
        if (currentTurnState == TurnState.BattleEnd) return; // Bereits beendet

        // Spieler besiegt?
        if (playerController.GetCurrentHealth() <= 0)
        {
            EndBattle(false); // Spieler hat verloren
            return;
        }

        // Alle Gegner besiegt?
        bool allEnemiesDefeated = true;
        foreach (EnemyController enemy in enemyControllers)
        {
            if (enemy != null && enemy.GetCurrentHealth() > 0)
            {
                allEnemiesDefeated = false;
                break;
            }
        }

        if (allEnemiesDefeated)
        {
            EndBattle(true); // Spieler hat gewonnen
        }
    }

    private void EndBattle(bool playerWon)
    {
        ChangeTurnState(TurnState.BattleEnd);
        Debug.Log($"--- Battle END --- Player {(playerWon ? "WON" : "LOST")} ---");
        // TODO: Belohnungen anzeigen / GameOver-Screen / Zurück zur WorldMap
        // GameManager.Instance.UpdateState(playerWon ? GameState.WorldMap : GameState.MainMenu); // Beispiel
        
        // Eventuell Listener für Gesundheitsänderungen entfernen, um Fehler nach Kampfende zu vermeiden
    }

    private void RegisterEventListeners()
    {
        // Melde dich für Gesundheitsänderungen an, um das Kampfende zu prüfen
        if (playerController != null) 
        { 
            // playerController.OnHealthChanged += HandlePlayerHealthChange; // TODO: Implementieren
        } 
        foreach(var enemy in enemyControllers)
        {
            if (enemy != null)
            {
                // enemy.OnHealthChanged += HandleEnemyHealthChange; // TODO: Implementieren
                // enemy.OnDefeated += HandleEnemyDefeated; // TODO: Implementieren
            }
        }
        // TimeManager Event abonnieren
        TimeManager.OnTimerExpired += HandleTimerExpired;
        Debug.Log("TurnManager subscribed to TimeManager.OnTimerExpired.");
    }

    private void UnregisterEventListeners()
    {
        // Events abmelden, um Memory Leaks zu vermeiden
        TimeManager.OnTimerExpired -= HandleTimerExpired;
        Debug.Log("TurnManager unsubscribed from TimeManager.OnTimerExpired.");
    }

    private void OnEnable()
    {
        // Das Registrieren passiert jetzt in InitiateBattle()
    }

    private void OnDisable()
    {
        // Das Deregistrieren passiert jetzt in TerminateBattle()
        // Es ist aber gut, es hier trotzdem zu tun, falls das Objekt deaktiviert wird,
        // während ein Kampf läuft.
        UnregisterEventListeners();
    }

    // Beispiel-Handler für Gesundheitsänderungen
    // private void HandleHealthChange(int current, int max)
    // {
    //     CheckForBattleEnd();
    // }
    // private void HandleHealthChange(EnemyController enemy, int current, int max)
    // {
    //      CheckForBattleEnd();
    // }

    // Wird aufgerufen, wenn der TimeManager meldet, dass die Zeit abgelaufen ist.
    private void HandleTimerExpired()
    {
        Debug.Log("Timer Expired! Checking turn state...");
        // Nur handeln, wenn der Spieler gerade am Zug ist
        if (currentTurnState == TurnState.PlayerTurn)
        {   
            Debug.Log("Timer expired during Player's turn. Forcing end of turn.");
            // Spielerzug sofort beenden
            ChangeTurnState(TurnState.BetweenTurns); // Wechsel in den Übergangszustand
            StartCoroutine(EnemyTurnSequence()); // Starte direkt den Gegnerzug
            // Optional: Strafe für Zeitablauf? (z.B. Karte abwerfen, Schaden nehmen)
        }
        else
        {
            Debug.Log($"Timer expired during {currentTurnState}, no action taken by TurnManager.");
        }
    }
}
