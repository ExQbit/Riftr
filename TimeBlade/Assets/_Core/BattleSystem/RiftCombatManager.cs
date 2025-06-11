using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

/// <summary>
/// Verwaltet den echtzeitbasierten Kampfablauf in Zeitklingen.
/// Ersetzt das rundenbasierte System durch kontinuierlichen Zeitfluss.
/// </summary>
public class RiftCombatManager : MonoBehaviour
{
    // Singleton
    public static RiftCombatManager Instance { get; private set; }
    
    // Combat States
    public enum CombatState 
    { 
        Inactive,
        RiftStarting,
        InCombat,
        BossPhase,
        RiftEnding,
        Victory,
        Defeat
    }
    
    private CombatState currentState = CombatState.Inactive;
    
    // Events
    public static event Action<CombatState> OnCombatStateChanged;
    public static event Action OnRiftVictory;
    public static event Action OnRiftDefeat;
    public static event Action<int> OnEnemyDefeated; // enemyID
    
    // Referenzen zu Core-Systemen
    private RiftTimeSystem timeSystem;
    private RiftPointSystem pointSystem;
    private RiftEnemySpawner enemySpawner;
    private ZeitwaechterPlayer player;
    private EnemyFocusSystem focusSystem;
    
    // Targeting System
    public bool IsInTargetingMode { get; private set; } = false;
    private TimeCardData currentCardBeingPlayed;
    
    // Aktive Gegner
    private List<RiftEnemy> activeEnemies = new List<RiftEnemy>();
    private RiftBoss currentBoss = null;
    
    // Kampf-Statistiken
    private float combatStartTime;
    private int totalEnemiesSpawned = 0;
    private int totalEnemiesDefeated = 0;
    
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
    
    void Start()
    {
        // Core-Systeme finden
        timeSystem = RiftTimeSystem.Instance;
        pointSystem = RiftPointSystem.Instance;
        enemySpawner = FindAnyObjectByType<RiftEnemySpawner>();
        player = FindAnyObjectByType<ZeitwaechterPlayer>();
        focusSystem = EnemyFocusSystem.Instance;
        
        // Events abonnieren
        RegisterEventListeners();
    }
    
    /// <summary>
    /// Startet einen neuen Rift-Kampf
    /// </summary>
    public void StartRift(RiftTimeSystem.RiftType riftType = RiftTimeSystem.RiftType.Standard)
    {
        if (currentState != CombatState.Inactive)
        {
            Debug.LogWarning("[RiftCombat] Kann keinen neuen Rift starten - bereits aktiv!");
            return;
        }
        
        Debug.Log($"[RiftCombat] Starte {riftType} Rift...");
        
        ChangeState(CombatState.RiftStarting);
        StartCoroutine(RiftStartSequence(riftType));
    }
    
    /// <summary>
    /// Rift-Start-Sequenz mit Animationen
    /// </summary>
    private IEnumerator RiftStartSequence(RiftTimeSystem.RiftType riftType)
    {
        // Reset Statistiken
        combatStartTime = Time.time;
        totalEnemiesSpawned = 0;
        totalEnemiesDefeated = 0;
        activeEnemies.Clear();
        currentBoss = null;
        
        // Initialisiere Systeme
        timeSystem.StartRift(riftType);
        pointSystem.InitializeRift();
        
        // Spieler vorbereiten
        if (player != null)
        {
            player.PrepareForCombat();
        }
        
        // UI einblenden
        // TODO: Rift-Portal-Animation
        yield return new WaitForSeconds(1.5f);
        
        // Kampf beginnt!
        ChangeState(CombatState.InCombat);
        
        // Ersten Gegner spawnen
        if (enemySpawner != null)
        {
            enemySpawner.StartSpawning(riftType);
        }
        
        Debug.Log("[RiftCombat] Kampf läuft!");
    }
    
    /// <summary>
    /// Beendet den aktuellen Rift
    /// </summary>
    public void EndRift(bool victory)
    {
        if (currentState == CombatState.Inactive || currentState == CombatState.RiftEnding)
            return;
        
        ChangeState(CombatState.RiftEnding);
        StartCoroutine(RiftEndSequence(victory));
    }
    
    /// <summary>
    /// Rift-Ende-Sequenz
    /// </summary>
    private IEnumerator RiftEndSequence(bool victory)
    {
        // Spawning stoppen
        if (enemySpawner != null)
        {
            enemySpawner.StopSpawning();
        }
        
        // Zeit stoppen
        timeSystem.EndRift(victory);
        
        // Kurze Pause für Effekte
        yield return new WaitForSeconds(0.5f);
        
        // Finale State setzen
        ChangeState(victory ? CombatState.Victory : CombatState.Defeat);
        
        // Events feuern
        if (victory)
        {
            OnRiftVictory?.Invoke();
            Debug.Log("[RiftCombat] SIEG! Boss wurde besiegt!");
        }
        else
        {
            OnRiftDefeat?.Invoke();
            Debug.Log("[RiftCombat] NIEDERLAGE! Zeit abgelaufen.");
        }
        
        // Belohnungen berechnen
        CalculateRewards(victory);
        
        // Nach 3 Sekunden zurück zu Inactive
        yield return new WaitForSeconds(3f);
        ChangeState(CombatState.Inactive);
    }
    
    /// <summary>
    /// Registriert einen neuen Gegner im System
    /// </summary>
    public void RegisterEnemy(RiftEnemy enemy)
    {
        if (!activeEnemies.Contains(enemy))
        {
            activeEnemies.Add(enemy);
            totalEnemiesSpawned++;
            
            // Event-Listener für Gegner-Tod
            enemy.OnDeath += HandleEnemyDeath;
            
            Debug.Log($"[RiftCombat] Gegner registriert: {enemy.name} (Total: {activeEnemies.Count})");
        }
    }
    
    /// <summary>
    /// Behandelt den Tod eines Gegners
    /// </summary>
    private void HandleEnemyDeath(RiftEnemy enemy)
    {
        if (activeEnemies.Contains(enemy))
        {
            activeEnemies.Remove(enemy);
            totalEnemiesDefeated++;
            
            // Punkte hinzufügen
            float killTime = Time.time - enemy.SpawnTime;
            pointSystem.AddPointsForEnemy(enemy.Tier, killTime);
            
            OnEnemyDefeated?.Invoke(enemy.GetInstanceID());
            
            Debug.Log($"[RiftCombat] Gegner besiegt: {enemy.name} " +
                      $"(Verbleibend: {activeEnemies.Count}, Kill-Zeit: {killTime:F1}s)");
            
            // War das der Boss?
            if (enemy == currentBoss)
            {
                HandleBossDefeat();
            }
        }
    }
    
    /// <summary>
    /// Spawnt den Rift-Boss
    /// </summary>
    public void SpawnBoss()
    {
        if (currentState != CombatState.InCombat || currentBoss != null)
            return;
        
        Debug.Log("[RiftCombat] BOSS-PHASE BEGINNT!");
        
        ChangeState(CombatState.BossPhase);
        
        // Alle normalen Gegner entfernen
        StartCoroutine(ClearEnemiesForBoss());
    }
    
    /// <summary>
    /// Entfernt normale Gegner vor Boss-Spawn
    /// </summary>
    private IEnumerator ClearEnemiesForBoss()
    {
        // 3-Sekunden Warnung
        Debug.Log("[RiftCombat] Boss erscheint in 3 Sekunden!");
        // TODO: UI-Warnung
        
        yield return new WaitForSeconds(2f);
        
        // Focus System räumt Gegner
        if (focusSystem != null)
        {
            focusSystem.ClearForBoss();
        }
        
        activeEnemies.Clear();
        
        yield return new WaitForSeconds(1f);
        
        // Boss spawnen
        if (enemySpawner != null)
        {
            GameObject bossObj = enemySpawner.SpawnBoss();
            if (bossObj != null)
            {
                currentBoss = bossObj.GetComponent<RiftBoss>();
                RegisterEnemy(currentBoss);
            }
        }
    }
    
    /// <summary>
    /// Boss wurde besiegt
    /// </summary>
    private void HandleBossDefeat()
    {
        Debug.Log("[RiftCombat] BOSS BESIEGT!");
        currentBoss = null;
        
        // Rift erfolgreich beenden
        EndRift(true);
    }
    
    /// <summary>
    /// Berechnet Belohnungen basierend auf Performance
    /// </summary>
    private void CalculateRewards(bool victory)
    {
        float combatDuration = Time.time - combatStartTime;
        float timeEfficiency = timeSystem.GetTimePercentage();
        
        Debug.Log($"[RiftCombat] Kampf-Statistiken:");
        Debug.Log($"- Dauer: {combatDuration:F1}s");
        Debug.Log($"- Gegner besiegt: {totalEnemiesDefeated}/{totalEnemiesSpawned}");
        Debug.Log($"- Zeit-Effizienz: {timeEfficiency*100:F0}%");
        Debug.Log($"- Punkte: {pointSystem.GetCurrentPoints()}/{pointSystem.GetTargetPoints()}");
        
        // TODO: Tatsächliche Belohnungsberechnung und -vergabe
    }
    
    /// <summary>
    /// Ändert den Combat-State
    /// </summary>
    private void ChangeState(CombatState newState)
    {
        if (currentState == newState) return;
        
        CombatState oldState = currentState;
        currentState = newState;
        
        Debug.Log($"[RiftCombat] State: {oldState} → {newState}");
        OnCombatStateChanged?.Invoke(newState);
    }
    
    /// <summary>
    /// Event-Listener registrieren
    /// </summary>
    private void RegisterEventListeners()
    {
        // Zeit-System
        if (timeSystem != null)
        {
            RiftTimeSystem.OnTimeExpired += HandleTimeExpired;
        }
        
        // Punkte-System
        if (pointSystem != null)
        {
            RiftPointSystem.OnBossThresholdReached += SpawnBoss;
        }
    }
    
    /// <summary>
    /// Zeit abgelaufen - Niederlage
    /// </summary>
    private void HandleTimeExpired()
    {
        if (currentState == CombatState.InCombat || currentState == CombatState.BossPhase)
        {
            Debug.Log("[RiftCombat] Zeit abgelaufen!");
            EndRift(false);
        }
    }
    
    // Getter
    public CombatState GetCurrentState() => currentState;
    public List<RiftEnemy> GetActiveEnemies() => new List<RiftEnemy>(activeEnemies);
    public bool IsBossActive() => currentBoss != null;
    public int GetEnemiesDefeated() => totalEnemiesDefeated;
    
    /// <summary>
    /// Findet den ersten verfügbaren Gegner für Auto-Targeting
    /// </summary>
    private RiftEnemy GetFirstAvailableEnemy()
    {
        Debug.Log($"[RiftCombat] GetFirstAvailableEnemy: Checking {activeEnemies.Count} enemies");
        foreach (RiftEnemy enemy in activeEnemies)
        {
            if (enemy != null && !enemy.IsDead())
            {
                Debug.Log($"[RiftCombat] Found available enemy: {enemy.name}");
                return enemy;
            }
        }
        Debug.Log("[RiftCombat] No available enemies found!");
        return null;
    }
    
    /// <summary>
    /// Spieler möchte eine Karte spielen
    /// </summary>
    public void PlayerWantsToPlayCard(TimeCardData cardData, ZeitwaechterPlayer player)
    {
        // Prüfe ob genug Zeit vorhanden
        if (!RiftTimeSystem.Instance.TryPlayCard(cardData.GetScaledTimeCost()))
        {
            Debug.Log("[RiftCombat] Nicht genug Zeit für diese Karte!");
            return;
        }
        
        // Braucht die Karte ein Ziel?
        if (cardData.requiresTarget)
        {
            // Auto-Target: Nimm ersten verfügbaren Gegner als Fallback
            RiftEnemy autoTarget = GetFirstAvailableEnemy();
            if (autoTarget != null)
            {
                Debug.Log($"[RiftCombat] AUTO-TARGET: {cardData.cardName} → {autoTarget.name}");
                ExecuteCardEffect(cardData, player, autoTarget);
            }
            else
            {
                Debug.Log($"[RiftCombat] Kein Ziel verfügbar für {cardData.cardName}! Zeit zurückerstattet.");
                // Zeit zurückgeben da bereits abgezogen
                RiftTimeSystem.Instance.AddTime(cardData.GetScaledTimeCost());
            }
        }
        else
        {
            // Karte ohne Ziel ausführen
            ExecuteCardEffect(cardData, player, null);
        }
    }
    
    /// <summary>
    /// Gegner-Karte wurde geklickt
    /// </summary>
    public void EnemyCardClicked(RiftEnemy targetEnemy)
    {
        if (IsInTargetingMode && currentCardBeingPlayed != null)
        {
            Debug.Log($"[RiftCombat] Ziel gewählt: {targetEnemy.name} für {currentCardBeingPlayed.cardName}");
            
            // Ziel gewählt, Karteneffekt ausführen
            ExecuteCardEffect(currentCardBeingPlayed, player, targetEnemy);
            
            // Zielmodus beenden
            IsInTargetingMode = false;
            currentCardBeingPlayed = null;
        }
        else
        {
            // Keine Zielauswahl aktiv - Info anzeigen?
            Debug.Log($"[RiftCombat] Gegner {targetEnemy.name} geklickt (kein Zielmodus)");
        }
    }
    
    /// <summary>
    /// Führt Karteneffekt direkt aus (für Drag-and-Drop, umgeht Targeting-Mode)
    /// </summary>
    public void ExecuteCardEffectDirect(TimeCardData card, ZeitwaechterPlayer caster, RiftEnemy target)
    {
        Debug.Log($"[RiftCombat] ExecuteCardEffectDirect: {card.cardName} on {target?.name}");
        
        // WICHTIG: Die Karte wird bereits im HandController entfernt!
        // Wir führen hier nur noch den Effekt aus
        ExecuteCardEffectOnly(card, caster, target);
    }
    
    /// <summary>
    /// Führt nur den Karteneffekt aus (ohne Karte zu entfernen)
    /// </summary>
    private void ExecuteCardEffectOnly(TimeCardData card, ZeitwaechterPlayer caster, RiftEnemy target)
    {
        // Automatisches Targeting wenn kein Ziel aber benötigt
        if (target == null && card.requiresTarget && focusSystem != null)
        {
            target = focusSystem.GetCurrentTarget();
        }
        
        if (target == null && card.requiresTarget)
        {
            Debug.LogWarning($"[RiftCombat] Karte {card.cardName} benötigt ein Ziel, aber keins verfügbar!");
            return;
        }
        
        // Karteneffekt ausführen
        Debug.Log($"[RiftCombat] Führe {card.cardName} aus. Ziel: {(target != null ? target.name : "Kein Ziel")}");
        
        // Kartentyp-basierte Effekte
        switch (card.cardType)
        {
            case TimeCardType.Attack:
                // Schaden zufügen
                if (card.baseDamage > 0 && target != null)
                {
                    int baseDmg = card.baseDamage;
                    float scaledDmg = card.GetScaledDamage();
                    int finalDamage = Mathf.RoundToInt(scaledDmg);
                    
                    // Schildmacht-Bonus anwenden
                    var shieldPower = caster.GetComponent<ShieldPowerSystem>();
                    int shieldBonus = 0;
                    if (shieldPower != null && shieldPower.GetCurrentShieldPower() >= 3)
                    {
                        shieldBonus = 1; // +1 Bonus-Schaden bei 3+ Schildmacht
                        finalDamage += shieldBonus;
                    }
                    
                    Debug.Log($"[RiftCombat] Schadensberechnung: {card.cardName} - Base: {baseDmg}, Scaled: {scaledDmg}, Shield Bonus: {shieldBonus}, Final: {finalDamage}");
                    Debug.Log($"[RiftCombat] Angriff: {card.cardName} verursacht {finalDamage} Schaden an {target.name}");
                    target.TakeDamage(finalDamage);
                    
                    // Visuelles Feedback
                    Debug.Log($"[RiftCombat] {card.cardName} fügt {finalDamage} Schaden zu!");
                }
                break;
                
            case TimeCardType.Defense:
                // Block aktivieren
                if (card.blockDuration > 0)
                {
                    caster.ActivateBlock(card.blockDuration, card.timeReward);
                    Debug.Log($"[RiftCombat] Block für {card.blockDuration}s aktiviert!");
                }
                break;
                
            case TimeCardType.TimeManipulation:
                // Zeit-Effekte
                if (card.timeGain > 0)
                {
                    RiftTimeSystem.Instance.AddTime(card.timeGain);
                    Debug.Log($"[RiftCombat] {card.cardName} gewährt {card.timeGain}s Zeit!");
                }
                
                if (card.enemyDelay > 0 && target != null)
                {
                    // TODO: Gegner-Verzögerungs-Mechanik
                    Debug.Log($"[RiftCombat] {card.cardName} verzögert {target.name} um {card.enemyDelay}s!");
                }
                break;
        }
        
        // Event auslösen
        // OnCardPlayed?.Invoke(card, target); // TODO: Event implementieren wenn benötigt
    }

    /// <summary>
    /// Führt Karteneffekt aus
    /// </summary>
    private void ExecuteCardEffect(TimeCardData card, ZeitwaechterPlayer caster, RiftEnemy target)
    {
        // Automatisches Targeting wenn kein Ziel aber benötigt
        if (target == null && card.requiresTarget && focusSystem != null)
        {
            target = focusSystem.GetCurrentTarget();
        }
        
        if (target == null && card.requiresTarget)
        {
            Debug.LogWarning("[RiftCombat] Kein gültiges Ziel!");
            // Zeit zurückgeben wenn Karte nicht gespielt werden kann
            RiftTimeSystem.Instance.AddTime(card.GetScaledTimeCost());
            return;
        }
        
        // Karteneffekt ausführen
        Debug.Log($"[RiftCombat] Führe {card.cardName} aus. Ziel: {(target != null ? target.name : "Kein Ziel")}");
        
        // KRITISCH: Zeit wurde bereits in PlayerWantsToPlayCard abgezogen!
        // Verwende spezielle Combat-Methode (verhindert doppelte Zeit-Abzüge)
        bool cardRemoved = caster.PlayCardFromCombat(card);
        if (!cardRemoved)
        {
            Debug.LogError($"[RiftCombat] Konnte Karte '{card.cardName}' nicht aus Hand entfernen!");
            return;
        }
        
        // Kartentyp-basierte Effekte
        switch (card.cardType)
        {
            case TimeCardType.Attack:
                // Schaden zufügen
                if (card.baseDamage > 0 && target != null)
                {
                    int scaledDamage = Mathf.RoundToInt(card.GetScaledDamage());
                    
                    // Schildmacht-Bonus anwenden
                    var shieldPower = caster.GetComponent<ShieldPowerSystem>();
                    if (shieldPower != null && shieldPower.GetCurrentShieldPower() >= 3)
                    {
                        scaledDamage += 1; // +1 Bonus-Schaden bei 3+ Schildmacht
                    }
                    
                    target.TakeDamage(scaledDamage);
                    
                    // Visuelles Feedback
                    Debug.Log($"[RiftCombat] {card.cardName} fügt {scaledDamage} Schaden zu!");
                }
                break;
                
            case TimeCardType.Defense:
                // Block aktivieren
                if (card.blockDuration > 0)
                {
                    caster.ActivateBlock(card.blockDuration, card.timeReward);
                    Debug.Log($"[RiftCombat] Block für {card.blockDuration}s aktiviert!");
                }
                break;
                
            case TimeCardType.TimeManipulation:
                // Zeitmanipulation
                if (card.timeGain > 0)
                {
                    RiftTimeSystem.Instance.AddTime(card.timeGain);
                    Debug.Log($"[RiftCombat] +{card.timeGain}s Zeit gewonnen!");
                }
                
                if (card.enemyDelay > 0 && target != null)
                {
                    // TODO: Gegner-Verzögerung implementieren
                    Debug.Log($"[RiftCombat] Gegner um {card.enemyDelay}s verzögert!");
                }
                break;
        }
    }
    
    /// <summary>
    /// Bricht den Zielmodus ab
    /// </summary>
    public void CancelTargetingMode()
    {
        IsInTargetingMode = false;
        currentCardBeingPlayed = null;
        Debug.Log("[RiftCombat] Zielmodus abgebrochen");
    }
    
    void OnDestroy()
    {
        // Events abmelden
        if (timeSystem != null)
        {
            RiftTimeSystem.OnTimeExpired -= HandleTimeExpired;
        }
        
        if (pointSystem != null)
        {
            RiftPointSystem.OnBossThresholdReached -= SpawnBoss;
        }
    }
}
