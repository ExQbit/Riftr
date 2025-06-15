using UnityEngine;
using System;
using System.Collections;

/// <summary>
/// Verwaltet das zentrale Zeitsystem für Zeitklingen.
/// Zeit ist die einzige Ressource der Spieler - keine HP!
/// Standard-Rifts dauern 180 Sekunden (3 Minuten).
/// </summary>
public class RiftTimeSystem : MonoBehaviour
{
    // Singleton Pattern
    public static RiftTimeSystem Instance { get; private set; }
    
    // Zeit-Konstanten
    private const float STANDARD_RIFT_DURATION = 180f; // 3 Minuten
    private const float TUTORIAL_RIFT_DURATION = 90f;  // 90 Sekunden für Tutorial
    private const float TIME_PRECISION = 0.01f;         // Interne Präzision
    
    // Aktuelle Zeit
    private float currentTime;
    private float maxTime;
    private bool isTimerRunning;
    private bool isRiftActive;
    
    // Rift-Typ
    public enum RiftType { Tutorial, Standard, Elite, Boss }
    private RiftType currentRiftType;
    
    // Events
    public static event Action<float, float> OnTimeChanged; // current, max
    public static event Action OnTimeExpired;
    public static event Action<float> OnTimeGained;
    public static event Action<float> OnTimeStolen;
    public static event Action OnRiftStarted;
    public static event Action OnRiftEnded;
    
    // Zeit-Warnungen
    private bool warning60Triggered = false;
    private bool warning30Triggered = false;
    private bool warning10Triggered = false;
    
    void Awake()
    {
        // Singleton Setup
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
            return;
        }
    }
    
    /// <summary>
    /// Startet einen neuen Rift mit spezifischer Dauer
    /// </summary>
    public void StartRift(RiftType riftType = RiftType.Standard)
    {
        currentRiftType = riftType;
        
        // Setze Zeit basierend auf Rift-Typ
        switch (riftType)
        {
            case RiftType.Tutorial:
                maxTime = TUTORIAL_RIFT_DURATION;
                break;
            case RiftType.Standard:
            case RiftType.Elite:
            case RiftType.Boss:
                maxTime = STANDARD_RIFT_DURATION;
                break;
        }
        
        currentTime = maxTime;
        isRiftActive = true;
        isTimerRunning = true;
        
        // Reset Warnungen
        warning60Triggered = false;
        warning30Triggered = false;
        warning10Triggered = false;
        
        Debug.Log($"[RiftTimeSystem] Rift gestartet! Typ: {riftType}, Zeit: {maxTime}s");
        
        OnRiftStarted?.Invoke();
        OnTimeChanged?.Invoke(currentTime, maxTime);
        
        // Starte Zeit-Countdown
        StartCoroutine(TimeCountdown());
    }
    
    /// <summary>
    /// Beendet den aktuellen Rift
    /// </summary>
    public void EndRift(bool wasSuccessful = false)
    {
        if (!isRiftActive) return;
        
        isTimerRunning = false;
        isRiftActive = false;
        
        Debug.Log($"[RiftTimeSystem] Rift beendet! Erfolg: {wasSuccessful}, Verbleibende Zeit: {currentTime:F2}s");
        
        OnRiftEnded?.Invoke();
        StopAllCoroutines();
    }
    
    /// <summary>
    /// Der Haupt-Countdown
    /// </summary>
    private IEnumerator TimeCountdown()
    {
        float uiUpdateInterval = 0.1f; // UI nur alle 0.1 Sekunden updaten
        float lastUiUpdate = 0f;
        
        while (isTimerRunning && currentTime > 0)
        {
            // FIXED: Use unscaled time to avoid FPS dependency
            float frameTime = 0.02f; // Fixed 50 FPS equivalent
            currentTime -= frameTime;
            
            // Auf Präzision runden
            currentTime = Mathf.Round(currentTime / TIME_PRECISION) * TIME_PRECISION;
            
            // Mindestens 0
            if (currentTime < 0) currentTime = 0;
            
            // UI nur alle 0.1s updaten für bessere Performance
            if (Time.time - lastUiUpdate >= uiUpdateInterval)
            {
                OnTimeChanged?.Invoke(currentTime, maxTime);
                lastUiUpdate = Time.time;
            }
            
            // Warnungen bei bestimmten Schwellen
            CheckTimeWarnings();
            
            // Zeit abgelaufen?
            if (currentTime <= 0)
            {
                TimeExpired();
            }
            
            yield return new WaitForSeconds(0.02f); // 50 FPS statt jeden Frame
        }
    }
    
    /// <summary>
    /// Spieler gewinnt Zeit (z.B. durch DoT, Zeitraub-Karten)
    /// </summary>
    public void AddTime(float amount)
    {
        if (!isRiftActive || amount <= 0) return;
        
        float oldTime = currentTime;
        currentTime += amount;
        
        // "Keine Caps"-Philosophie - Zeit kann über Maximum steigen!
        // Nur das Rift-Ende ist die natürliche Grenze
        
        Debug.Log($"[RiftTimeSystem] Zeit gewonnen: +{amount:F2}s (Neu: {currentTime:F2}s)");
        
        OnTimeGained?.Invoke(amount);
        OnTimeChanged?.Invoke(currentTime, maxTime);
    }
    
    /// <summary>
    /// Gegner stiehlt Zeit vom Spieler (Zeitdiebstahl-Mechanik)
    /// </summary>
    public void StealTime(float amount)
    {
        if (!isRiftActive || amount <= 0) return;
        
        float actualStolen = Mathf.Min(amount, currentTime);
        currentTime -= actualStolen;
        
        // Debug.Log($"[RiftTimeSystem] Zeit gestohlen: -{actualStolen:F2}s (Neu: {currentTime:F2}s)"); // REDUCED LOGGING
        
        OnTimeStolen?.Invoke(actualStolen);
        OnTimeChanged?.Invoke(currentTime, maxTime);
        
        if (currentTime <= 0)
        {
            TimeExpired();
        }
    }
    
    /// <summary>
    /// Berechnet die Zeitkosten einer Karte mit allen Modifikatoren
    /// </summary>
    public float CalculateCardTimeCost(float baseTimeCost, float classModifier = 1f, float situationalModifier = 1f)
    {
        // Interne Berechnung mit voller Präzision
        float finalCost = baseTimeCost * classModifier * situationalModifier;
        
        // Auf 0.01s genau
        finalCost = Mathf.Round(finalCost / TIME_PRECISION) * TIME_PRECISION;
        
        return finalCost;
    }
    
    /// <summary>
    /// Versucht eine Karte zu spielen (prüft Zeitkosten)
    /// </summary>
    public bool TryPlayCard(float timeCost)
    {
        if (!isRiftActive) return false;
        
        // Opportunity Cost System - Karten können gespielt werden solange Zeit vorhanden
        if (timeCost > currentTime)
        {
            Debug.Log($"[RiftTimeSystem] Nicht genug Zeit! Benötigt: {timeCost:F2}s, Verfügbar: {currentTime:F2}s");
            return false;
        }
        
        // Zeit abziehen
        currentTime -= timeCost;
        // Debug.Log($"[RiftTimeSystem] Karte gespielt! Kosten: {timeCost:F2}s, Verbleibend: {currentTime:F2}s"); // REDUCED LOGGING
        
        OnTimeChanged?.Invoke(currentTime, maxTime);
        
        if (currentTime <= 0)
        {
            TimeExpired();
        }
        
        return true;
    }
    
    /// <summary>
    /// Zeit ist abgelaufen - Rift endet
    /// </summary>
    private void TimeExpired()
    {
        if (!isRiftActive) return;
        
        Debug.Log("[RiftTimeSystem] ZEIT ABGELAUFEN! Rift gescheitert.");
        
        OnTimeExpired?.Invoke();
        EndRift(false);
    }
    
    /// <summary>
    /// Prüft Zeit-Warnungen für UI-Feedback
    /// </summary>
    private void CheckTimeWarnings()
    {
        if (!warning60Triggered && currentTime <= 60f)
        {
            warning60Triggered = true;
            Debug.Log("[RiftTimeSystem] Warnung: 60 Sekunden verbleibend!");
            // TODO: UI-Warnung triggern
        }
        
        if (!warning30Triggered && currentTime <= 30f)
        {
            warning30Triggered = true;
            Debug.Log("[RiftTimeSystem] Warnung: 30 Sekunden verbleibend!");
            // TODO: UI pulsiert
        }
        
        if (!warning10Triggered && currentTime <= 10f)
        {
            warning10Triggered = true;
            Debug.Log("[RiftTimeSystem] KRITISCH: 10 Sekunden verbleibend!");
            // TODO: Kritische UI-Animation
        }
    }
    
    // Getter
    public float GetCurrentTime() => currentTime;
    public float GetMaxTime() => maxTime;
    public bool IsRiftActive() => isRiftActive;
    public float GetTimePercentage() => maxTime > 0 ? currentTime / maxTime : 0f;
    public RiftType GetCurrentRiftType() => currentRiftType;
    
    /// <summary>
    /// Formatiert Zeit für UI-Anzeige (IMMER IN SEKUNDEN ohne Dezimalstellen)
    /// </summary>
    public string GetTimeDisplayString()
    {
        // Für sekungengenaue Anzeige: Aufrunden auf ganze Sekunden
        int totalSeconds = Mathf.CeilToInt(currentTime);
        
        // Immer nur Sekunden mit "s" anzeigen, unabhängig von der Dauer
        return string.Format("{0}s", totalSeconds);
    }
    
    /// <summary>
    /// Gibt die exakte Zeit mit voller Präzision zurück (für Detail-Ansicht)
    /// </summary>
    public string GetTimePreciseString()
    {
        int minutes = Mathf.FloorToInt(currentTime / 60f);
        float seconds = currentTime % 60f;
        return string.Format("{0}:{1:00.00}s", minutes, seconds);
    }
}
