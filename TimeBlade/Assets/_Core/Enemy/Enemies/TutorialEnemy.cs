using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Tutorial-Gegner - Demonstriert verschiedene Aktionstypen für den Spieler
/// </summary>
public class TutorialEnemy : RiftEnemy
{
    [Header("Tutorial-Spezifisch")]
    [SerializeField] private bool showActionHints = true;
    [SerializeField] private int actionPattern = 0; // 0 = Zufällig, 1 = Nur Zeitdiebstahl, 2 = Abwechselnd
    
    private List<EnemyActionType> actionSequence;
    private int currentActionIndex = 0;
    
    /// <summary>
    /// Überschreibt die Initialisierung um Tutorial-spezifische Werte zu setzen
    /// </summary>
    public override void Initialize()
    {
        // Tutorial Stats - WICHTIG: Diese Werte überschreiben Prefab-Einstellungen
        maxHealth = 15; // Tutorial-Gegner haben 15 HP (nicht 10 wie im Basis-Prefab)
        baseAttackInterval = 4f; // Langsamer für Tutorial
        baseTimeStealAmount = 0.5f; // Weniger Zeitdiebstahl als Standard (1.0)
        tier = RiftPointSystem.EnemyTier.Standard;
        
        // Initialisiere Aktions-Sequenz
        InitializeActionSequence();
        
        // Rufe base.Initialize() auf - NACHDEM wir maxHealth gesetzt haben
        base.Initialize();
        
        // Debug.Log($"[TutorialEnemy] Korrekt initialisiert: HP={GetCurrentHealth()}/{maxHealth}"); // REDUCED LOGGING
    }
    
    /// <summary>
    /// Initialisiert die Aktions-Sequenz basierend auf Pattern
    /// </summary>
    private void InitializeActionSequence()
    {
        actionSequence = new List<EnemyActionType>();
        
        switch (actionPattern)
        {
            case 0: // Zufällig
                // Wird in SelectNextAction() gehandhabt
                break;
                
            case 1: // Nur Zeitdiebstahl
                actionSequence.Add(EnemyActionType.TimeSteal);
                break;
                
            case 2: // Abwechselnd (zeigt verschiedene Aktionen)
                actionSequence.Add(EnemyActionType.TimeSteal);
                actionSequence.Add(EnemyActionType.Defend);
                actionSequence.Add(EnemyActionType.DoubleStrike);
                actionSequence.Add(EnemyActionType.Buff);
                break;
        }
    }
    
    protected override void UpdateBehavior()
    {
        // Tutorial-spezifisches Verhalten
        if (showActionHints && RiftCombatManager.Instance != null)
        {
            // Könnte Hinweise für den Spieler anzeigen
        }
    }
    
    /// <summary>
    /// Wählt die nächste Aktion basierend auf dem Pattern
    /// </summary>
    protected override void SelectNextAction()
    {
        if (actionPattern == 0) // Zufällig
        {
            // Gewichtete Zufallsauswahl
            float rand = Random.Range(0f, 1f);
            
            if (rand < 0.5f)
            {
                nextAction = EnemyActionType.TimeSteal;
            }
            else if (rand < 0.7f)
            {
                nextAction = EnemyActionType.DoubleStrike;
            }
            else if (rand < 0.85f)
            {
                nextAction = EnemyActionType.Defend;
            }
            else
            {
                nextAction = EnemyActionType.Buff;
            }
        }
        else if (actionSequence.Count > 0) // Sequenz-basiert
        {
            nextAction = actionSequence[currentActionIndex];
            currentActionIndex = (currentActionIndex + 1) % actionSequence.Count;
        }
        else
        {
            nextAction = EnemyActionType.TimeSteal; // Fallback
        }
        
        actionDescription = GetActionDescription(nextAction);
        
        if (showActionHints)
        {
            // Debug.Log($"[Tutorial] {name} plant: {actionDescription}"); // REDUCED LOGGING
        }
    }
    
    /// <summary>
    /// Überschreibt Aktions-Beschreibungen für Tutorial-Klarheit
    /// </summary>
    protected override string GetActionDescription(EnemyActionType action)
    {
        switch (action)
        {
            case EnemyActionType.TimeSteal:
                return $"Zeitdiebstahl: -{baseTimeStealAmount:F1}s";
            case EnemyActionType.DoubleStrike:
                return $"Doppelschlag: 2x{baseTimeStealAmount/2:F1}s";
            case EnemyActionType.Defend:
                return "Verteidigung aufbauen";
            case EnemyActionType.Buff:
                return "Selbstverstärkung";
            default:
                return base.GetActionDescription(action);
        }
    }
    
    /// <summary>
    /// Tutorial-spezifische Implementierung von Verteidigung
    /// </summary>
    protected override void PerformDefend()
    {
        base.PerformDefend();
        
        if (showActionHints)
        {
            Debug.Log($"[Tutorial] {name} verteidigt sich. Nächster Angriff wird stärker!");
        }
        
        // Nach Verteidigung: Nächster Angriff ist stärker
        baseTimeStealAmount *= 1.3f;
    }
    
    /// <summary>
    /// Tutorial-spezifische Implementierung von Buff
    /// </summary>
    protected override void PerformBuff()
    {
        float oldSteal = baseTimeStealAmount;
        base.PerformBuff();
        
        if (showActionHints)
        {
            Debug.Log($"[Tutorial] {name} verstärkt sich! Zeitdiebstahl: {oldSteal:F1}s → {baseTimeStealAmount:F1}s");
        }
    }
    
    /// <summary>
    /// Tutorial-Gegner gibt Feedback beim Tod
    /// </summary>
    protected override void Die()
    {
        if (showActionHints)
        {
            Debug.Log($"[Tutorial] Gut gemacht! {name} wurde besiegt!");
        }
        
        base.Die();
    }
}
