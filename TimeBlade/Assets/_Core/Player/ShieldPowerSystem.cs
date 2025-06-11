using UnityEngine;
using System;
using System.Collections;

/// <summary>
/// Schildmacht-System für den Zeitwächter.
/// Kernmechanik: Generierung durch erfolgreiche Blocks, Verfall über Zeit.
/// </summary>
public class ShieldPowerSystem : MonoBehaviour
{
    // Konstanten
    private const int MAX_SHIELD_POWER = 5;
    private const float INACTIVITY_TIMER = 5f; // Nach 5s ohne Block beginnt Verfall
    private const float NORMAL_DECAY_TIME = 10f; // 1 SM alle 10s (0-2 SM)
    private const float SOFT_CAP_DECAY_TIME = 5f; // 1 SM alle 5s (3+ SM)
    
    // Schildbruch-Konstanten
    private const int SHIELD_BREAK_DAMAGE = 15;
    private const float SHIELD_BREAK_TIME_STEAL = 2f;
    
    // Aktuelle Werte
    private int currentShieldPower = 0;
    private float timeSinceLastBlock = 0f;
    private float decayTimer = 0f;
    private bool isDecaying = false;
    
    // Events
    public static event Action<int> OnShieldPowerChanged;
    public static event Action<int> OnShieldPowerGained;
    public static event Action<int> OnShieldPowerLost;
    public static event Action<int, float> OnShieldBreak; // damage, timeSteal
    
    // Passive Boni (kumulativ)
    public float BlockDurationBonus { get; private set; } = 0f;
    public float BlockTimeRewardBonus { get; private set; } = 0f;
    public int AttackDamageBonus { get; private set; } = 0;
    public bool TimeTheftImmunity { get; private set; } = false;
    
    /// <summary>
    /// Initialisiert das Schildmacht-System
    /// </summary>
    public void Initialize()
    {
        currentShieldPower = 0;
        timeSinceLastBlock = 0f;
        decayTimer = 0f;
        isDecaying = false;
        
        UpdatePassiveBonuses();
        OnShieldPowerChanged?.Invoke(currentShieldPower);
        
        Debug.Log("[ShieldPower] System initialisiert");
    }
    
    /// <summary>
    /// Wird aufgerufen wenn ein Block erfolgreich war
    /// </summary>
    public void OnSuccessfulBlock()
    {
        // Reset Inaktivitäts-Timer
        timeSinceLastBlock = 0f;
        isDecaying = false;
        decayTimer = 0f;
        
        // Schildmacht erhöhen
        if (currentShieldPower < MAX_SHIELD_POWER)
        {
            currentShieldPower++;
            // Debug.Log($"[ShieldPower] Block erfolgreich! Schildmacht: {currentShieldPower}/{MAX_SHIELD_POWER}");
            
            OnShieldPowerGained?.Invoke(1);
            OnShieldPowerChanged?.Invoke(currentShieldPower);
            UpdatePassiveBonuses();
            
            // Schildbruch bei Maximum?
            if (currentShieldPower >= MAX_SHIELD_POWER)
            {
                TriggerShieldBreak();
            }
        }
    }
    
    /// <summary>
    /// Update-Loop für Verfall-Mechanik
    /// </summary>
    void Update()
    {
        if (currentShieldPower == 0) return;
        
        // Inaktivitäts-Timer
        timeSinceLastBlock += Time.deltaTime;
        
        // Verfall beginnt nach INACTIVITY_TIMER
        if (timeSinceLastBlock >= INACTIVITY_TIMER && !isDecaying)
        {
            isDecaying = true;
            decayTimer = 0f;
            // Debug.Log($"[ShieldPower] Verfall beginnt nach {INACTIVITY_TIMER}s Inaktivität");
        }
        
        // Verfall-Logik
        if (isDecaying)
        {
            decayTimer += Time.deltaTime;
            
            // Bestimme Verfall-Rate basierend auf aktueller SM
            float decayRate = currentShieldPower >= 3 ? SOFT_CAP_DECAY_TIME : NORMAL_DECAY_TIME;
            
            // Verfall tritt ein?
            if (decayTimer >= decayRate)
            {
                currentShieldPower--;
                decayTimer = 0f;
                
                // Debug.Log($"[ShieldPower] Verfall! Schildmacht: {currentShieldPower}/{MAX_SHIELD_POWER}");
                
                OnShieldPowerLost?.Invoke(1);
                OnShieldPowerChanged?.Invoke(currentShieldPower);
                UpdatePassiveBonuses();
                
                // Verfall stoppt bei 0
                if (currentShieldPower == 0)
                {
                    isDecaying = false;
                }
            }
        }
    }
    
    /// <summary>
    /// Löst Schildbruch aus (bei 5 SM)
    /// </summary>
    private void TriggerShieldBreak()
    {
        // Debug.Log($"[ShieldPower] SCHILDBRUCH! {SHIELD_BREAK_DAMAGE} Schaden + {SHIELD_BREAK_TIME_STEAL}s Zeitraub");
        
        // Event für Schaden und Zeitraub
        OnShieldBreak?.Invoke(SHIELD_BREAK_DAMAGE, SHIELD_BREAK_TIME_STEAL);
        
        // Reset auf 0
        currentShieldPower = 0;
        timeSinceLastBlock = 0f;
        isDecaying = false;
        decayTimer = 0f;
        
        OnShieldPowerChanged?.Invoke(currentShieldPower);
        UpdatePassiveBonuses();
        
        // TODO: VFX und Sound für Schildbruch
    }
    
    /// <summary>
    /// Aktualisiert passive Boni basierend auf Schildmacht-Stufe
    /// </summary>
    private void UpdatePassiveBonuses()
    {
        // Reset
        BlockDurationBonus = 0f;
        BlockTimeRewardBonus = 0f;
        AttackDamageBonus = 0;
        TimeTheftImmunity = false;
        
        // Kumulative Boni
        if (currentShieldPower >= 1)
        {
            BlockDurationBonus = 0.05f; // +5% Blockdauer
        }
        
        if (currentShieldPower >= 2)
        {
            BlockTimeRewardBonus = 0.5f; // +0.5s Zeit bei Block-Karten
        }
        
        if (currentShieldPower >= 3)
        {
            AttackDamageBonus = 1; // +1 Schaden bei Angriffskarten
        }
        
        if (currentShieldPower >= 4)
        {
            TimeTheftImmunity = true; // Immunität gegen nächsten Zeitdiebstahl
        }
        
        // Debug.Log($"[ShieldPower] Passive Boni aktualisiert - " +
        //          $"Block: +{BlockDurationBonus*100}%, " +
        //          $"Zeit: +{BlockTimeRewardBonus}s, " +
        //          $"Schaden: +{AttackDamageBonus}, " +
        //          $"Immunität: {TimeTheftImmunity}");
    }
    
    /// <summary>
    /// Modifiziert Blockdauer basierend auf Schildmacht
    /// </summary>
    public float ModifyBlockDuration(float baseDuration)
    {
        return baseDuration * (1f + BlockDurationBonus);
    }
    
    /// <summary>
    /// Modifiziert Schaden basierend auf Schildmacht
    /// </summary>
    public int ModifyAttackDamage(int baseDamage)
    {
        return baseDamage + AttackDamageBonus;
    }
    
    /// <summary>
    /// Prüft und konsumiert Zeitdiebstahl-Immunität
    /// </summary>
    public bool ConsumeTimeTheftImmunity()
    {
        if (TimeTheftImmunity)
        {
            // Immunität wird verbraucht aber SM bleibt
            TimeTheftImmunity = false;
            Debug.Log("[ShieldPower] Zeitdiebstahl-Immunität verbraucht!");
            return true;
        }
        return false;
    }
    
    // Getter
    public int GetCurrentShieldPower() => currentShieldPower;
    public int GetMaxShieldPower() => MAX_SHIELD_POWER;
    public bool IsDecaying() => isDecaying;
    public float GetDecayProgress() => isDecaying ? decayTimer / (currentShieldPower >= 3 ? SOFT_CAP_DECAY_TIME : NORMAL_DECAY_TIME) : 0f;
    
    /// <summary>
    /// Setzt Schildmacht manuell (für Debugging/Effekte)
    /// </summary>
    public void SetShieldPower(int value)
    {
        currentShieldPower = Mathf.Clamp(value, 0, MAX_SHIELD_POWER);
        OnShieldPowerChanged?.Invoke(currentShieldPower);
        UpdatePassiveBonuses();
        
        if (currentShieldPower >= MAX_SHIELD_POWER)
        {
            TriggerShieldBreak();
        }
    }
}
