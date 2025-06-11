using UnityEngine;
using System;

public class TimeManager : MonoBehaviour
{
    // TODO: Add visual feedback for time changes

    [Header("Timer Settings")]
    [SerializeField] private float maxTimeInSeconds = 180.0f; // 3 Minuten für Zeitklingen Rifts
    private float currentTimeInSeconds;
    private bool isTimerRunning = false;

    [Header("Time Manipulation")]
    [SerializeField] [Range(0.1f, 5f)] private float timeScaleFactor = 1.0f; // 1.0 = normal speed

    // Event, um andere Systeme über Zeitänderungen zu informieren (z.B. für UI)
    public static event Action<float> OnTimeChanged;
    public static event Action OnTimerExpired;
    public static event Action OnTimerWarning;    // Ausgelöst, wenn die Zeit einen Warnschwellenwert erreicht
    public static event Action OnTimerCritical;   // Ausgelöst, wenn die Zeit einen kritischen Schwellenwert erreicht

    [Header("Warning Thresholds")]
    [SerializeField] private float warningThreshold = 20.0f; // z.B. 20 Sekunden
    [SerializeField] private float criticalThreshold = 10.0f; // z.B. 10 Sekunden
    private bool warningTriggered = false;
    private bool criticalTriggered = false;

    // Property für einfachen Lesezugriff auf die aktuelle Zeit
    public float CurrentTime => currentTimeInSeconds;
    public float MaxTime => maxTimeInSeconds;

    public static TimeManager Instance { get; private set; }

    private void Awake()
    {
        // Singleton-Pattern Implementierung
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return; 
        }
        Instance = this;
        // Optional: DontDestroyOnLoad(gameObject); - Hängt davon ab, ob der Timer über Szenen bestehen soll.
        // Wenn jede Szene (z.B. Battle) ihren eigenen Timer neu startet, ist es vielleicht nicht nötig.
        // Vorerst weglassen.
    }

    void Start()
    {
        InitializeTimer();
        Debug.Log("TimeManager Initialized");
    }

    void Update()
    {
        if (isTimerRunning && currentTimeInSeconds > 0)
        {            
            currentTimeInSeconds -= Time.deltaTime * timeScaleFactor;
            OnTimeChanged?.Invoke(currentTimeInSeconds);

            // Timer Warnungen prüfen
            if (!warningTriggered && currentTimeInSeconds <= warningThreshold && currentTimeInSeconds > criticalThreshold)
            {
                OnTimerWarning?.Invoke();
                warningTriggered = true;
                Debug.Log("Timer Warning!");
            }
            if (!criticalTriggered && currentTimeInSeconds <= criticalThreshold)
            {
                OnTimerCritical?.Invoke();
                criticalTriggered = true;
                Debug.Log("Timer Critical!");
            }

            if (currentTimeInSeconds <= 0)
            {
                currentTimeInSeconds = 0;
                isTimerRunning = false;
                Debug.Log("Timer Expired!");
                OnTimerExpired?.Invoke();
                // TODO: Handle timer expiration (e.g., end turn, lose battle?)
            }
        }
    }

    private void InitializeTimer()
    {
        currentTimeInSeconds = maxTimeInSeconds;
        isTimerRunning = false;
        warningTriggered = false; // Zurücksetzen für den nächsten Timer-Durchlauf
        criticalTriggered = false; // Zurücksetzen für den nächsten Timer-Durchlauf
        OnTimeChanged?.Invoke(currentTimeInSeconds); // Initialen Wert senden
    }

    // Öffentliche Methoden zur Steuerung des Timers
    public void StartTimer()
    {
        if (currentTimeInSeconds > 0) // Nur starten, wenn Zeit übrig ist
        {
             isTimerRunning = true;
             Debug.Log("Timer Started");
        }
    }

    public void StopTimer()
    {
        isTimerRunning = false;
        Debug.Log("Timer Stopped");
    }

    public void PauseTimer()
    {
        StopTimer(); // PauseTimer ist ein Alias für StopTimer
        Debug.Log("Timer Paused");
    }

    public void ResetTimer()
    {
        InitializeTimer();
        Debug.Log("Timer Reset");
    }

    // Methode zum Verbrauchen von Zeit (z.B. für Kartenkosten)
    public bool ConsumeTime(float amount)
    {
        if (amount <= 0) return true; // Kein Verbrauch bei ungültigem Wert

        if (currentTimeInSeconds >= amount)
        {
            currentTimeInSeconds -= amount;
            OnTimeChanged?.Invoke(currentTimeInSeconds);
            Debug.Log($"Consumed {amount}s time. Remaining: {currentTimeInSeconds}s");
            // Prüfen, ob Timer durch Verbrauch abläuft
            if (currentTimeInSeconds <= 0 && isTimerRunning)
            {
                currentTimeInSeconds = 0;
                isTimerRunning = false;
                Debug.Log("Timer Expired due to consumption!");
                OnTimerExpired?.Invoke();
            }
            return true; // Zeit erfolgreich verbraucht
        }
        else
        {
            Debug.Log($"Not enough time to consume {amount}s. Remaining: {currentTimeInSeconds}s");
            return false; // Nicht genug Zeit vorhanden
        }
    }

    // Methode zum Hinzufügen von Zeit (z.B. durch Effekte oder Belohnungen)
    public void AddTime(float amount)
    {
        if (amount <= 0) return; // Kein Hinzufügen bei ungültigem Wert

        currentTimeInSeconds += amount;
        // Sicherstellen, dass die maximale Zeit nicht überschritten wird
        if (currentTimeInSeconds > maxTimeInSeconds)
        {
            currentTimeInSeconds = maxTimeInSeconds;
        }

        OnTimeChanged?.Invoke(currentTimeInSeconds);
        Debug.Log($"Added {amount}s time. Current: {currentTimeInSeconds}s");

        // Falls der Timer abgelaufen war, aber wieder Zeit hat, muss er ggf. neu gestartet werden
        // (optional, hängt von der Spiellogik ab - wird hier nicht automatisch gemacht)
        // if (!isTimerRunning && currentTimeInSeconds > 0) { // Potentiell Timer wieder aktivieren? }
    }

    // Methode zum Setzen der Zeitmanipulation
    public void SetTimeScale(float newScale)
    {
        // Begrenze den Skalierungsfaktor auf einen sinnvollen Bereich
        timeScaleFactor = Mathf.Clamp(newScale, 0.1f, 5f);
        Debug.Log($"Time scale set to: {timeScaleFactor}");
    }

    // Methode zum Zurücksetzen der Zeitmanipulation auf Normalgeschwindigkeit
    public void ResetTimeScale()
    {
        timeScaleFactor = 1.0f;
        Debug.Log("Time scale reset to normal (1.0)");
    }

    // TODO: Add visual feedback for time changes
}
