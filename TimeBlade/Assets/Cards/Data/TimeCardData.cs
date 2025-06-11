using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// ScriptableObject für Zeitklingen-Karten.
/// Basiert auf dem Zeit-als-Ressource-System.
/// </summary>
[CreateAssetMenu(fileName = "NewTimeCard", menuName = "Zeitklingen/Time Card Data")]
public class TimeCardData : ScriptableObject
{
    [Header("Basis-Information")]
    public string cardName = "Neue Karte";
    public string cardID = "CARD-XXX-NEWCARD";
    [TextArea(3, 5)]
    public string description = "Kartenbeschreibung";
    public Sprite cardArt;
    
    [Header("Karten-Typ")]
    public TimeCardType cardType = TimeCardType.Attack;
    public CardRarity rarity = CardRarity.Common;
    
    [Header("Zeit-System")]
    [Tooltip("Basis-Zeitkosten in Sekunden (wird auf 0.5s gerundet für UI)")]
    public float baseTimeCost = 1.0f;
    
    [Header("Effekte")]
    [Tooltip("Basis-Schaden für Angriffskarten")]
    public int baseDamage = 0;
    
    [Tooltip("Benötigt diese Karte einen Ziel-Gegner?")]
    public bool requiresTarget = false;
    
    [Tooltip("Block-Dauer in Sekunden für Verteidigungskarten")]
    public float blockDuration = 0f;
    
    [Tooltip("Zeit-Belohnung bei erfolgreichem Block")]
    public float timeReward = 0f;
    
    [Tooltip("Direkter Zeitgewinn")]
    public float timeGain = 0f;
    
    [Tooltip("Verzögerung für Gegner-Angriffe")]
    public float enemyDelay = 0f;
    
    [Header("Progression")]
    public int currentLevel = 1;
    public int maxLevel = 50;
    
    [Header("Evolution")]
    public EvolutionPath evolutionPath = EvolutionPath.None;
    public int evolutionStage = 0; // 0 = Basis, 1-3 = Evolutionsstufen
    
    [Header("Evolution-Optionen")]
    public TimeCardData fireEvolution;
    public TimeCardData iceEvolution;
    public TimeCardData lightningEvolution;
    
    /// <summary>
    /// Berechnet die skalierten Werte basierend auf Level
    /// </summary>
    public float GetScaledDamage()
    {
        // +3% bis +7% pro Level je nach Level-Bereich
        float scalingFactor = CalculateScalingFactor();
        return baseDamage * scalingFactor;
    }
    
    public float GetScaledTimeCost()
    {
        // Zeitkosten können durch Evolution reduziert werden
        float costReduction = evolutionPath == EvolutionPath.Lightning ? 0.9f : 1f;
        return baseTimeCost * costReduction;
    }
    
    private float CalculateScalingFactor()
    {
        float totalScaling = 1f;
        
        // Level 1-10: +3% pro Level
        if (currentLevel <= 10)
        {
            totalScaling += 0.03f * (currentLevel - 1);
        }
        // Level 11-20: +4% pro Level
        else if (currentLevel <= 20)
        {
            totalScaling += 0.3f; // Aus Level 1-10
            totalScaling += 0.04f * (currentLevel - 10);
        }
        // Level 21-30: +5% pro Level
        else if (currentLevel <= 30)
        {
            totalScaling += 0.7f; // Aus Level 1-20
            totalScaling += 0.05f * (currentLevel - 20);
        }
        // Level 31-40: +6% pro Level
        else if (currentLevel <= 40)
        {
            totalScaling += 1.2f; // Aus Level 1-30
            totalScaling += 0.06f * (currentLevel - 30);
        }
        // Level 41-50: +7% pro Level
        else
        {
            totalScaling += 1.8f; // Aus Level 1-40
            totalScaling += 0.07f * (currentLevel - 40);
        }
        
        return totalScaling;
    }
    
    /// <summary>
    /// Gibt die UI-freundliche Zeitkosten-Anzeige zurück (gerundet auf 0.5s)
    /// </summary>
    public float GetDisplayTimeCost()
    {
        float scaledCost = GetScaledTimeCost();
        return Mathf.Round(scaledCost * 2f) / 2f; // Auf 0.5s runden
    }
    
    /// <summary>
    /// Prüft ob die Karte evolviert werden kann
    /// </summary>
    public bool CanEvolve()
    {
        // Evolution bei Level 9, 25, 35
        if (evolutionStage == 0 && currentLevel >= 9) return true;
        if (evolutionStage == 1 && currentLevel >= 25) return true;
        if (evolutionStage == 2 && currentLevel >= 35) return true;
        return false;
    }
    
    /// <summary>
    /// Gibt die nächste Evolutionsstufe zurück
    /// </summary>
    public TimeCardData GetEvolution(EvolutionPath path)
    {
        switch (path)
        {
            case EvolutionPath.Fire:
                return fireEvolution;
            case EvolutionPath.Ice:
                return iceEvolution;
            case EvolutionPath.Lightning:
                return lightningEvolution;
            default:
                return null;
        }
    }
}

public enum EvolutionPath
{
    None,
    Fire,      // Reflexion und DoT
    Ice,       // Defensive und Zeitrückgewinnung
    Lightning  // Effizienz und Tempo
}

public enum TimeCardType
{
    Attack,
    Defense,
    TimeManipulation
}
