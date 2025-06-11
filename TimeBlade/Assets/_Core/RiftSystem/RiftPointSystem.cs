using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// Verwaltet das Rift-Punkte-System.
/// Spieler sammeln Punkte durch besiegte Gegner.
/// Bei 100 Punkten spawnt der Rift-Boss.
/// </summary>
public class RiftPointSystem : MonoBehaviour
{
    // Singleton
    public static RiftPointSystem Instance { get; private set; }
    
    // Konstanten
    private const int BOSS_SPAWN_THRESHOLD = 100;
    private const float QUICK_KILL_TIME = 5f; // Kills unter 5s geben Bonus
    
    // Punkte-Werte nach Gegnertyp
    public enum EnemyTier
    {
        Standard,   // 10-15 Punkte
        Elite,      // 20-30 Punkte
        MiniBoss,   // 30-40 Punkte
        RiftBoss    // 0 Punkte (beendet Rift)
    }
    
    // Aktuelle Werte
    private int currentPoints = 0;
    private int targetPoints = BOSS_SPAWN_THRESHOLD;
    private bool bossSpawned = false;
    private float lastKillTime = 0f;
    private int comboCount = 0;
    
    // Statistiken
    private int enemiesDefeated = 0;
    private float totalTimeForKills = 0f;
    
    // Events
    public static event Action<int, int> OnPointsChanged; // current, target
    public static event Action<int> OnPointsGained;
    public static event Action OnBossThresholdReached;
    public static event Action<float> OnComboMultiplier; // Multiplikator
    
    void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }
    
    /// <summary>
    /// Initialisiert das Punkte-System für einen neuen Rift
    /// </summary>
    public void InitializeRift(int customTargetPoints = BOSS_SPAWN_THRESHOLD)
    {
        currentPoints = 0;
        targetPoints = customTargetPoints;
        bossSpawned = false;
        lastKillTime = Time.time;
        comboCount = 0;
        enemiesDefeated = 0;
        totalTimeForKills = 0f;
        
        Debug.Log($"[RiftPointSystem] Rift initialisiert. Ziel: {targetPoints} Punkte für Boss-Spawn");
        
        OnPointsChanged?.Invoke(currentPoints, targetPoints);
    }
    
    /// <summary>
    /// Fügt Punkte für einen besiegten Gegner hinzu
    /// </summary>
    public void AddPointsForEnemy(EnemyTier tier, float timeToKill)
    {
        if (bossSpawned)
        {
            Debug.LogWarning("[RiftPointSystem] Boss bereits gespawnt - keine weiteren Punkte!");
            return;
        }
        
        // Basis-Punkte nach Tier
        int basePoints = CalculateBasePoints(tier);
        
        // Multiplikatoren berechnen
        float speedMultiplier = CalculateSpeedMultiplier(timeToKill);
        float comboMultiplier = CalculateComboMultiplier();
        
        // Finale Punkte
        int finalPoints = Mathf.RoundToInt(basePoints * speedMultiplier * comboMultiplier);
        
        // Punkte hinzufügen
        int oldPoints = currentPoints;
        currentPoints = Mathf.Min(currentPoints + finalPoints, targetPoints);
        
        // Statistiken
        enemiesDefeated++;
        totalTimeForKills += timeToKill;
        
        Debug.Log($"[RiftPointSystem] +{finalPoints} Punkte! " +
                  $"(Basis: {basePoints}, Speed: x{speedMultiplier:F1}, Combo: x{comboMultiplier:F1}) " +
                  $"Total: {currentPoints}/{targetPoints}");
        
        OnPointsGained?.Invoke(finalPoints);
        OnPointsChanged?.Invoke(currentPoints, targetPoints);
        
        // Boss-Spawn prüfen
        if (currentPoints >= targetPoints && !bossSpawned)
        {
            TriggerBossSpawn();
        }
    }
    
    /// <summary>
    /// Berechnet Basis-Punkte nach Gegner-Tier
    /// </summary>
    private int CalculateBasePoints(EnemyTier tier)
    {
        switch (tier)
        {
            case EnemyTier.Standard:
                return UnityEngine.Random.Range(10, 16); // 10-15
                
            case EnemyTier.Elite:
                return UnityEngine.Random.Range(20, 31); // 20-30
                
            case EnemyTier.MiniBoss:
                return UnityEngine.Random.Range(30, 41); // 30-40
                
            case EnemyTier.RiftBoss:
                return 0; // Boss gibt keine Punkte
                
            default:
                return 10;
        }
    }
    
    /// <summary>
    /// Berechnet Speed-Multiplikator für schnelle Kills
    /// </summary>
    private float CalculateSpeedMultiplier(float timeToKill)
    {
        if (timeToKill < QUICK_KILL_TIME)
        {
            // Je schneller, desto mehr Bonus (max 1.5x)
            float ratio = 1f - (timeToKill / QUICK_KILL_TIME);
            return 1f + (ratio * 0.5f); // 1.0x bis 1.5x
        }
        
        return 1f; // Kein Bonus
    }
    
    /// <summary>
    /// Berechnet Combo-Multiplikator für schnelle aufeinanderfolgende Kills
    /// </summary>
    private float CalculateComboMultiplier()
    {
        float timeSinceLastKill = Time.time - lastKillTime;
        
        // Combo fortsetzen wenn Kill innerhalb von 3 Sekunden
        if (timeSinceLastKill <= 3f)
        {
            comboCount++;
        }
        else
        {
            comboCount = 0;
        }
        
        lastKillTime = Time.time;
        
        // Combo-Multiplikator (max 1.5x bei 5+ Combo)
        float multiplier = 1f + (Mathf.Min(comboCount, 5) * 0.1f);
        
        if (comboCount > 0)
        {
            OnComboMultiplier?.Invoke(multiplier);
        }
        
        return multiplier;
    }
    
    /// <summary>
    /// Löst den Boss-Spawn aus
    /// </summary>
    private void TriggerBossSpawn()
    {
        bossSpawned = true;
        
        Debug.Log("[RiftPointSystem] BOSS-SCHWELLE ERREICHT! Boss wird gespawnt.");
        
        OnBossThresholdReached?.Invoke();
        
        // TODO: Tatsächlichen Boss spawnen über RiftEnemySpawner
    }
    
    /// <summary>
    /// Gibt die durchschnittliche Kill-Zeit zurück
    /// </summary>
    public float GetAverageKillTime()
    {
        if (enemiesDefeated == 0) return 0f;
        return totalTimeForKills / enemiesDefeated;
    }
    
    /// <summary>
    /// Berechnet Effizienz-Score (Punkte pro Sekunde)
    /// </summary>
    public float GetEfficiencyScore()
    {
        if (totalTimeForKills == 0) return 0f;
        return currentPoints / totalTimeForKills;
    }
    
    // Getter
    public int GetCurrentPoints() => currentPoints;
    public int GetTargetPoints() => targetPoints;
    public bool IsBossSpawned() => bossSpawned;
    public int GetComboCount() => comboCount;
    public int GetEnemiesDefeated() => enemiesDefeated;
    public float GetProgress() => (float)currentPoints / targetPoints;
    
    /// <summary>
    /// Formatiert Punkte für UI-Anzeige
    /// </summary>
    public string GetPointsDisplayString()
    {
        return $"{currentPoints}/{targetPoints}";
    }
    
    /// <summary>
    /// Gibt detaillierte Statistiken zurück
    /// </summary>
    public Dictionary<string, object> GetRiftStatistics()
    {
        return new Dictionary<string, object>
        {
            { "TotalPoints", currentPoints },
            { "EnemiesDefeated", enemiesDefeated },
            { "AverageKillTime", GetAverageKillTime() },
            { "EfficiencyScore", GetEfficiencyScore() },
            { "BossSpawned", bossSpawned },
            { "MaxCombo", comboCount }
        };
    }
}
