using UnityEngine;
using System;
using System.Collections;

/// <summary>
/// Basis-Klasse für Rift-Bosse.
/// Bosse erscheinen bei 100 Rift-Punkten und beenden den Rift bei Sieg.
/// </summary>
public class RiftBoss : RiftEnemy
{
    protected override void UpdateBehavior()
    {
        // Standard-Bossverhalten (leer)
    }
    [Header("Boss-Eigenschaften")]
    [SerializeField] protected int phaseCount = 3;
    [SerializeField] protected float enrageTimeLimit = 60f; // Sekunden bis Enrage
    
    protected int currentPhase = 1;
    protected float combatTime = 0f;
    protected bool isEnraged = false;
    
    // Boss-spezifische Events
    public static event Action<int> OnBossPhaseChanged; // newPhase
    public static event Action OnBossEnraged;
    public event Action<RiftEnemy> OnEnemySummoned; // Für Summoned Enemies
    
    // Vulnerability System
    protected bool isVulnerable = false;
    
    protected override void Start()
    {
        // Boss-Werte
        tier = RiftPointSystem.EnemyTier.RiftBoss; // Gibt 0 Punkte
        
        base.Start();
        
        // Boss-Intro
        StartCoroutine(BossIntroSequence());
    }
    
    /// <summary>
    /// Boss-Intro-Sequenz
    /// </summary>
    protected virtual IEnumerator BossIntroSequence()
    {
        isActive = false; // Noch nicht angreifbar
        
        Debug.Log($"[BOSS] {gameObject.name} ERSCHEINT!");
        
        // TODO: Dramatische Spawn-Animation
        yield return new WaitForSeconds(2f);
        
        isActive = true;
        Debug.Log($"[BOSS] Kampf beginnt! Phase 1/{phaseCount}");
        
        OnBossPhaseChanged?.Invoke(currentPhase);
    }
    
    protected override void Update()
    {
        if (!isActive || isDead) return;
        
        // Combat-Timer
        combatTime += Time.deltaTime;
        
        // Enrage-Check
        if (!isEnraged && combatTime >= enrageTimeLimit)
        {
            TriggerEnrage();
        }
        
        base.Update();
    }
    
    /// <summary>
    /// Boss nimmt nur Schaden wenn verwundbar
    /// </summary>
    public override void TakeDamage(int damage)
    {
        base.TakeDamage(CalculateDamage(damage));
    }
    
    /// <summary>
    /// Prüft ob eine neue Phase beginnen sollte
    /// </summary>
    protected virtual void CheckPhaseTransition()
    {
        float healthPercent = GetHealthPercentage();
        int expectedPhase = 1;
        
        if (phaseCount >= 3)
        {
            if (healthPercent <= 0.33f)
                expectedPhase = 3;
            else if (healthPercent <= 0.66f)
                expectedPhase = 2;
        }
        else if (phaseCount >= 2)
        {
            if (healthPercent <= 0.5f)
                expectedPhase = 2;
        }
        
        if (expectedPhase > currentPhase)
        {
            TransitionToPhase(expectedPhase);
        }
    }
    
    /// <summary>
    /// Wechselt zu einer neuen Phase
    /// </summary>
    protected virtual void TransitionToPhase(int newPhase)
    {
        currentPhase = newPhase;
        
        Debug.Log($"[BOSS] PHASE {currentPhase}/{phaseCount} BEGINNT!");
        
        OnBossPhaseChanged?.Invoke(currentPhase);
        
        // Phase-spezifische Änderungen
        ApplyPhaseModifiers();
        
        // Kurze Unverwundbarkeit während Übergang
        StartCoroutine(PhaseTransitionSequence());
    }
    
    /// <summary>
    /// Wendet phasenbasierte Modifikatoren an
    /// </summary>
    protected virtual void ApplyPhaseModifiers()
    {
        // Angriffe werden schneller pro Phase
        float speedMultiplier = 1f - (0.2f * (currentPhase - 1));
        baseAttackInterval *= speedMultiplier;
        
        // Mehr Zeitdiebstahl pro Phase
        baseTimeStealAmount += 0.5f * (currentPhase - 1);
        
        Debug.Log($"[BOSS] Phase {currentPhase} - Angriffe alle {baseAttackInterval}s, " +
                  $"Zeitdiebstahl: {baseTimeStealAmount}s");
    }
    
    /// <summary>
    /// Phasenübergangs-Sequenz
    /// </summary>
    protected virtual IEnumerator PhaseTransitionSequence()
    {
        isActive = false;
        
        // TODO: Phase-Übergangs-Animation
        yield return new WaitForSeconds(1.5f);
        
        isActive = true;
    }
    
    /// <summary>
    /// Boss wird wütend (Enrage)
    /// </summary>
    protected virtual void TriggerEnrage()
    {
        isEnraged = true;
        
        Debug.Log($"[BOSS] ENRAGE! Zeit überschritten!");
        
        // Dramatische Erhöhung
        baseAttackInterval *= 0.5f; // Doppelt so schnell
        baseTimeStealAmount *= 2f; // Doppelter Zeitdiebstahl
        
        OnBossEnraged?.Invoke();
        
        // TODO: Visuelle Enrage-Effekte
    }
    
    protected override void Die()
    {
        Debug.Log($"[BOSS] {gameObject.name} WURDE BESIEGT!");
        
        // Boss-Tod triggert Rift-Sieg
        base.Die();
    }
    
    /// <summary>
    /// Setzt Boss-Verwundbarkeit
    /// </summary>
    public void SetVulnerable(bool vulnerable)
    {
        isVulnerable = vulnerable;
        
        if (vulnerable)
        {
            Debug.Log($"[BOSS] {name} ist jetzt VERWUNDBAR!");
            // TODO: Visuelles Feedback (Schild entfernen)
        }
        else
        {
            Debug.Log($"[BOSS] {name} ist GESCHÜTZT durch beschworene Feinde!");
            // TODO: Schild-Effekt anzeigen
        }
    }
    
    /// <summary>
    /// Berechnet den effektiven Schaden basierend auf dem geschützten Zustand
    /// </summary>
    protected int CalculateDamage(int damage)
    {
        if (!isVulnerable)
        {
            // Reduzierter Schaden wenn geschützt
            damage = Mathf.RoundToInt(damage * 0.2f); // 80% Schadensreduktion
            Debug.Log($"[BOSS] Geschützt! Nur {damage} Schaden (20%).");
        }
        
        return damage;
    }
    
    /// <summary>
    /// Beschwört einen Feind
    /// </summary>
    protected void SummonEnemy(GameObject enemyPrefab)
    {
        if (enemyPrefab == null) return;
        
        // Spawn-Position neben dem Boss
        Vector3 spawnPos = transform.position + new Vector3(2f, 0, 0);
        GameObject summonedObj = Instantiate(enemyPrefab, spawnPos, Quaternion.identity);
        
        RiftEnemy summonedEnemy = summonedObj.GetComponent<RiftEnemy>();
        if (summonedEnemy != null)
        {
            summonedEnemy.SetAttribute(EnemyAttribute.Summoned);
            OnEnemySummoned?.Invoke(summonedEnemy);
            
            // Boss ist geschützt solange Summoned leben
            SetVulnerable(false);
            
            Debug.Log($"[BOSS] {name} beschwört {summonedEnemy.name}!");
        }
    }
}

/// <summary>
/// Tempus-Verschlinger - Tutorial-Boss
/// </summary>
public class TempusVerschlinger : RiftBoss
{
    [Header("Tempus-Verschlinger")]
    [SerializeField] private float echoWaveInterval = 8f;
    [SerializeField] private int echoWaveCount = 3;
    [SerializeField] private GameObject summonedEchoPrefab; // Zeit-Echo zum Beschwören
    
    private float echoWaveTimer;
    private bool hasSummonedMinions = false;
    
    protected override void Start()
    {
        // Tutorial-Boss Stats
        maxHealth = 60;
        baseAttackInterval = 5f;
        baseTimeStealAmount = 1.5f;
        phaseCount = 2; // Nur 2 Phasen für Tutorial
        enrageTimeLimit = 90f; // Großzügig für Tutorial
        
        echoWaveTimer = echoWaveInterval;
        
        base.Start();
    }
    
    protected override void UpdateBehavior()
    {
        // Spezial-Attacke: Echo-Welle
        if (currentPhase >= 2)
        {
            echoWaveTimer -= Time.deltaTime;
            
            if (echoWaveTimer <= 0)
            {
                StartCoroutine(EchoWaveAttack());
                echoWaveTimer = echoWaveInterval;
            }
        }
    }
    
    /// <summary>
    /// Echo-Wellen-Angriff - Multiple kleine Zeitdiebstähle
    /// </summary>
    private IEnumerator EchoWaveAttack()
    {
        Debug.Log("[BOSS] Tempus-Verschlinger bereitet ECHO-WELLE vor!");
        
        // Warnung
        // TODO: Visuelle Warnung
        yield return new WaitForSeconds(1f);
        
        // Mehrere kleine Zeitdiebstähle
        for (int i = 0; i < echoWaveCount; i++)
        {
            if (isDead) break;
            
            RiftTimeSystem.Instance.StealTime(0.3f);
            Debug.Log($"[BOSS] Echo-Welle {i+1}/{echoWaveCount}!");
            
            yield return new WaitForSeconds(0.3f);
        }
    }
    
    protected override void ApplyPhaseModifiers()
    {
        base.ApplyPhaseModifiers();
        
        if (currentPhase == 2)
        {
            Debug.Log("[BOSS] Phase 2: Echo-Wellen-Angriff aktiviert!");
            
            // In Phase 2 beschwört der Boss Minions
            if (!hasSummonedMinions)
            {
                StartCoroutine(SummonMinions());
                hasSummonedMinions = true;
            }
        }
    }
    
    /// <summary>
    /// Beschwört Echo-Minions
    /// </summary>
    private IEnumerator SummonMinions()
    {
        Debug.Log("[BOSS] Tempus-Verschlinger BESCHWÖRT MINIONS!");
        
        // Animation/Warnung
        yield return new WaitForSeconds(1f);
        
        // 2 Zeit-Echos beschwören
        for (int i = 0; i < 2; i++)
        {
            if (summonedEchoPrefab != null)
            {
                SummonEnemy(summonedEchoPrefab);
            }
            yield return new WaitForSeconds(0.5f);
        }
    }
}
