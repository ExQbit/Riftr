using UnityEngine;
using System.Collections;

/// <summary>
/// Rudel-Echos - Basis-Gegner, die in Gruppen auftreten
/// </summary>
public class RudelEcho : RiftEnemy
{
    [Header("Rudel-Echo Stats")]
    [SerializeField] private int rudelSize = 3;
    [SerializeField] private float groupTimeStealBonus = 0.5f; // Bonus pro lebendes Rudel-Mitglied
    
    private int rudelMembersAlive;
    
    protected override void Start()
    {
        // Standard-Stats für Rudel-Echo - Ausgewogen für Gruppenkämpfe
        maxHealth = 18;
        baseAttackInterval = 4f;
        baseTimeStealAmount = 0.5f;
        tier = RiftPointSystem.EnemyTier.Standard;
        
        // Rudel-Tracking
        rudelMembersAlive = rudelSize;
        
        base.Start();
    }
    
    protected override void UpdateBehavior()
    {
        // Rudel-Verhalten: Schnellere Angriffe wenn mehr Mitglieder leben
        // (Wird durch den Timer in der Basis-Klasse gehandhabt)
    }
    
    protected override float CalculateTimeStealAmount()
    {
        // Mehr Zeitdiebstahl wenn mehr Rudel-Mitglieder leben
        float totalSteal = baseTimeStealAmount;
        
        // Bonus für jedes lebende Rudel-Mitglied
        if (rudelMembersAlive > 1)
        {
            totalSteal += groupTimeStealBonus * (rudelMembersAlive - 1);
        }
        
        return totalSteal;
    }
    
    public void NotifyRudelMemberDeath()
    {
        rudelMembersAlive--;
        Debug.Log($"[RudelEcho] Rudel-Mitglied gefallen. Verbleibend: {rudelMembersAlive}");
        
        // Angriffe werden langsamer wenn Rudel schrumpft
        baseAttackInterval *= 1.2f;
    }
}

/// <summary>
/// Guardian Echo - Beschützt Elite-Gegner
/// </summary>
public class GuardianEcho : RiftEnemy
{
    [Header("Guardian Stats")]
    [SerializeField] private float damageReductionForProtected = 0.5f; // 50% Schadensreduktion
    [SerializeField] private float healAmount = 5f;
    [SerializeField] private float healInterval = 10f;
    
    private float healTimer;
    
    protected override void Start()
    {
        // Guardian Stats - Höhere HP zum Schutz der Elites
        maxHealth = 35;
        baseAttackInterval = 5f;
        baseTimeStealAmount = 0.5f; // Standardisiert auf 0.5f wie angefordert
        tier = RiftPointSystem.EnemyTier.Standard;
        attribute = EnemyAttribute.Guardian;
        
        healTimer = healInterval;
        
        base.Start();
    }
    
    protected override void UpdateBehavior()
    {
        // Heile geschütztes Ziel
        if (protectedTarget != null && !protectedTarget.IsDead())
        {
            healTimer -= Time.deltaTime;
            
            if (healTimer <= 0)
            {
                HealProtectedTarget();
                healTimer = healInterval;
            }
        }
    }
    
    private void HealProtectedTarget()
    {
        if (protectedTarget == null) return;
        
        Debug.Log($"[Guardian] {name} heilt {protectedTarget.name} um {healAmount} HP!");
        
        // TODO: Heal-Mechanik implementieren wenn RiftEnemy Heal-Methode hat
        // protectedTarget.Heal(healAmount);
        
        // Heal-VFX
        if (animator != null)
        {
            animator.SetTrigger("Heal");
        }
    }
    
    protected override void ApplyGuardianBuffs()
    {
        base.ApplyGuardianBuffs();
        
        // TODO: Schadensreduktion auf geschütztes Ziel anwenden
        Debug.Log($"[Guardian] Gewährt {protectedTarget.name} {damageReductionForProtected*100}% Schadensreduktion!");
    }
}

/// <summary>
/// Aggressor Echo - Drängt sich an die Spitze
/// </summary>
public class AggressorEcho : RiftEnemy
{
    [Header("Aggressor Stats")]
    [SerializeField] private float enrageTimeStealMultiplier = 2f;
    [SerializeField] private float enrageHealthThreshold = 0.3f; // Bei 30% HP
    
    private bool isEnraged = false;
    
    protected override void Start()
    {
        // Aggressor Stats - Mittlere HP, aber aggressiv
        maxHealth = 25;
        baseAttackInterval = 3f;
        baseTimeStealAmount = 0.5f; // Standardisiert auf 0.5f wie angefordert
        tier = RiftPointSystem.EnemyTier.Standard;
        attribute = EnemyAttribute.Aggressor;
        
        base.Start();
    }
    
    protected override void UpdateBehavior()
    {
        // Enrage bei niedrigen HP
        if (!isEnraged && GetHealthPercentage() <= enrageHealthThreshold)
        {
            TriggerEnrage();
        }
    }
    
    private void TriggerEnrage()
    {
        isEnraged = true;
        
        Debug.Log($"[Aggressor] {name} wird WÜTEND!");
        
        // Verdoppelt Angriffstempo und Zeitdiebstahl
        baseAttackInterval *= 0.5f;
        baseTimeStealAmount *= enrageTimeStealMultiplier;
        
        // Visuelle Änderung
        if (spriteRenderer != null)
        {
            spriteRenderer.color = Color.red;
        }
        
        // TODO: Enrage-VFX
    }
    
    protected override float CalculateTimeStealAmount()
    {
        float amount = base.CalculateTimeStealAmount();
        
        // Bonus-Schaden wenn an der Spitze
        if (EnemyFocusSystem.Instance != null && 
            EnemyFocusSystem.Instance.GetCurrentTarget() == this)
        {
            amount *= 1.5f; // 50% mehr wenn fokussiert
        }
        
        return amount;
    }
}

/// <summary>
/// Ambush Echo - Erscheint unerwartet
/// </summary>
public class AmbushEcho : RiftEnemy
{
    [Header("Ambush Stats")]
    [SerializeField] private float ambushDuration = 3f;
    [SerializeField] private float ambushTimeStealBonus = 2f;
    
    private bool isAmbushing = true;
    private float ambushTimer;
    
    protected override void Start()
    {
        // Ambush Stats - Niedrigere HP, aber Überraschungsangriffe
        maxHealth = 22;
        baseAttackInterval = 2f; // Schnelle Angriffe während Ambush
        baseTimeStealAmount = 0.5f; // Standardisiert auf 0.5f wie angefordert
        tier = RiftPointSystem.EnemyTier.Standard;
        attribute = EnemyAttribute.Ambush;
        
        ambushTimer = ambushDuration;
        
        base.Start();
    }
    
    protected override void UpdateBehavior()
    {
        // Ambush-Phase
        if (isAmbushing)
        {
            ambushTimer -= Time.deltaTime;
            
            if (ambushTimer <= 0)
            {
                EndAmbush();
            }
        }
    }
    
    private void EndAmbush()
    {
        isAmbushing = false;
        
        Debug.Log($"[Ambush] {name} Überraschungsangriff endet!");
        
        // Normalisiere Angriffstempo
        baseAttackInterval = 4f;
        
        // Visuelle Änderung
        if (spriteRenderer != null)
        {
            spriteRenderer.color = Color.white;
        }
    }
    
    protected override float CalculateTimeStealAmount()
    {
        float amount = base.CalculateTimeStealAmount();
        
        // Bonus während Ambush
        if (isAmbushing)
        {
            amount += ambushTimeStealBonus;
        }
        
        return amount;
    }
    
    public override void Initialize()
    {
        base.Initialize();
        
        // Start-Effekt für Ambush
        if (spriteRenderer != null)
        {
            spriteRenderer.color = new Color(1f, 1f, 1f, 0.5f); // Halb-transparent
            StartCoroutine(AmbushAppearEffect());
        }
    }
    
    private IEnumerator AmbushAppearEffect()
    {
        // Fade-In Effekt
        float fadeTime = 0.5f;
        float elapsed = 0f;
        
        while (elapsed < fadeTime)
        {
            elapsed += Time.deltaTime;
            float alpha = Mathf.Lerp(0.5f, 1f, elapsed / fadeTime);
            
            if (spriteRenderer != null)
            {
                Color c = spriteRenderer.color;
                c.a = alpha;
                spriteRenderer.color = c;
            }
            
            yield return null;
        }
    }
}

/// <summary>
/// Supporter Echo - Bufft andere Gegner
/// </summary>
public class SupporterEcho : RiftEnemy
{
    [Header("Supporter Stats")]
    [SerializeField] private float buffRadius = 5f;
    // [SerializeField] private float attackSpeedBuff = 0.8f; // 20% schneller // TODO: Buff-System implementieren
    [SerializeField] private float buffInterval = 6f;
    
    private float buffTimer;
    
    protected override void Start()
    {
        // Supporter Stats - Geringe HP, Fokus auf Unterstützung
        maxHealth = 15;
        baseAttackInterval = 6f; // Langsame eigene Angriffe
        baseTimeStealAmount = 0.5f; // Standardisiert auf 0.5f wie angefordert
        tier = RiftPointSystem.EnemyTier.Standard;
        attribute = EnemyAttribute.Supporter;
        
        buffTimer = buffInterval;
        
        base.Start();
    }
    
    protected override void UpdateBehavior()
    {
        // Buff nahegelegene Gegner
        buffTimer -= Time.deltaTime;
        
        if (buffTimer <= 0)
        {
            ApplyAreaBuff();
            buffTimer = buffInterval;
        }
    }
    
    private void ApplyAreaBuff()
    {
        // Finde alle Gegner in Reichweite
        Collider2D[] nearbyEnemies = Physics2D.OverlapCircleAll(transform.position, buffRadius, LayerMask.GetMask("Enemy"));
        
        int buffedCount = 0;
        foreach (var collider in nearbyEnemies)
        {
            RiftEnemy enemy = collider.GetComponent<RiftEnemy>();
            if (enemy != null && enemy != this && !enemy.IsDead())
            {
                // TODO: Buff-System implementieren
                Debug.Log($"[Supporter] {name} bufft {enemy.name}!");
                buffedCount++;
            }
        }
        
        if (buffedCount > 0)
        {
            Debug.Log($"[Supporter] {buffedCount} Verbündete gebufft!");
            
            // Buff-Animation
            if (animator != null)
            {
                animator.SetTrigger("Buff");
            }
        }
    }
    
    // Supporter stirbt -> Debuff für alle
    protected override void Die()
    {
        Debug.Log($"[Supporter] {name} stirbt - Buffs enden!");
        
        // TODO: Entferne alle Buffs die dieser Supporter gegeben hat
        
        base.Die();
    }
}

/// <summary>
/// Elite Zeit-Jäger - Stärkerer Gegner
/// </summary>
public class EliteZeitJaeger : RiftEnemy
{
    [Header("Elite Stats")]
    // [SerializeField] private int phasesCount = 2; // TODO: Multi-Phasen-System implementieren
    [SerializeField] private float phase2HealthThreshold = 0.5f;
    
    private int currentPhase = 1;
    
    protected override void Start()
    {
        // Elite Stats - Höchste HP für Elite-Tier
        maxHealth = 50;
        baseAttackInterval = 3.5f;
        baseTimeStealAmount = 0.5f; // Standardisiert auf 0.5f wie angefordert
        tier = RiftPointSystem.EnemyTier.Elite;
        
        base.Start();
    }
    
    protected override void UpdateBehavior()
    {
        // Phasenwechsel prüfen
        if (currentPhase == 1 && GetHealthPercentage() <= phase2HealthThreshold)
        {
            TransitionToPhase2();
        }
    }
    
    private void TransitionToPhase2()
    {
        currentPhase = 2;
        
        Debug.Log($"[Elite] {name} erreicht PHASE 2!");
        
        // Verstärkte Angriffe in Phase 2
        baseAttackInterval *= 0.7f; // 30% schneller
        baseTimeStealAmount *= 1.5f; // 50% mehr Zeitdiebstahl
        
        // Spawn Guardian
        if (EnemyFocusSystem.Instance != null)
        {
            Debug.Log($"[Elite] {name} ruft einen Guardian!");
            // TODO: Guardian spawnen der diesen Elite schützt
        }
        
        // Visuelle Änderung
        if (spriteRenderer != null)
        {
            spriteRenderer.color = new Color(0.8f, 0.5f, 1f); // Lila
        }
    }
    
    protected override void PerformTimeSteal()
    {
        base.PerformTimeSteal();
        
        // Elite hat Chance auf Doppel-Angriff in Phase 2
        if (currentPhase == 2 && Random.Range(0f, 1f) < 0.3f)
        {
            StartCoroutine(DoubleStrike());
        }
    }
    
    private IEnumerator DoubleStrike()
    {
        yield return new WaitForSeconds(0.5f);
        
        Debug.Log($"[Elite] {name} DOPPELSCHLAG!");
        base.PerformTimeSteal();
    }
}
