using UnityEngine;
using System;
using System.Collections;

/// <summary>
/// Basis-Klasse für alle Rift-Gegner in Zeitklingen.
/// Gegner haben HP und können Zeit stehlen, aber verursachen KEINEN HP-Schaden!
/// </summary>
public abstract class RiftEnemy : MonoBehaviour
{
    [Header("Basis-Stats")]
    [SerializeField] protected int maxHealth = 10;
    [SerializeField] protected RiftPointSystem.EnemyTier tier = RiftPointSystem.EnemyTier.Standard;
    
    [Header("Zeit-Mechaniken")]
    [SerializeField] protected float baseAttackInterval = 3f; // Sekunden zwischen Angriffen
    [SerializeField] protected float baseTimeStealAmount = 1f; // Wie viel Zeit gestohlen wird
    [SerializeField] protected bool canStealTime = true;
    
    [Header("Aktions-System")]
    [SerializeField] protected EnemyActionType currentAction = EnemyActionType.TimeSteal;
    [SerializeField] protected string actionDescription = "Stiehlt Zeit";
    protected EnemyActionType nextAction = EnemyActionType.TimeSteal;
    
    // Aktuelle Werte
    protected int currentHealth;
    protected float attackTimer;
    protected bool isActive = false;
    protected bool isDead = false;
    
    // Spawn-Info
    public float SpawnTime { get; private set; }
    public RiftPointSystem.EnemyTier Tier => tier;
    
    // Enemy Attribute
    [Header("Enemy Focus System")]
    [SerializeField] protected EnemyAttribute attribute = EnemyAttribute.None;
    protected RiftEnemy protectedTarget; // Für Guardian
    
    // Events
    public event Action<RiftEnemy> OnDeath; // Mit Parameter für HandleEnemyDeath
    public event Action<float> OnTimeStealAttempt; // amount
    public event Action<int, int> OnHealthChanged; // current, max
    public event Action<EnemyActionType, float> OnNextActionChanged; // actionType, remainingTime
    
    // Komponenten
    protected Animator animator;
    protected SpriteRenderer spriteRenderer;
    
    protected virtual void Awake()
    {
        animator = GetComponent<Animator>();
        spriteRenderer = GetComponent<SpriteRenderer>();
    }
    
    /// <summary>
    /// Stellt sicher dass ein Collider für Drag-and-Drop Targeting existiert
    /// </summary>
    private void EnsureColliderExists()
    {
        // Prüfe ob bereits ein 2D Collider existiert
        Collider2D col2D = GetComponent<Collider2D>();
        if (col2D == null)
        {
            // Kein 2D Collider - prüfe 3D
            Collider col3D = GetComponent<Collider>();
            if (col3D == null)
            {
                // Gar kein Collider - füge BoxCollider2D hinzu
                BoxCollider2D newCollider = gameObject.AddComponent<BoxCollider2D>();
                
                // Automatische Größe basierend auf Sprite
                if (spriteRenderer != null && spriteRenderer.sprite != null)
                {
                    newCollider.size = spriteRenderer.sprite.bounds.size;
                    Debug.Log($"[RiftEnemy] Auto-added BoxCollider2D to {gameObject.name} with size {newCollider.size}");
                }
                else
                {
                    // Fallback Größe
                    newCollider.size = new Vector2(1f, 1f);
                    Debug.Log($"[RiftEnemy] Auto-added BoxCollider2D to {gameObject.name} with default size");
                }
                
                // Wichtig: isTrigger muss false sein für Raycast!
                newCollider.isTrigger = false;
            }
            else
            {
                Debug.Log($"[RiftEnemy] {gameObject.name} already has 3D Collider: {col3D.GetType().Name}");
            }
        }
        else
        {
            Debug.Log($"[RiftEnemy] {gameObject.name} already has 2D Collider: {col2D.GetType().Name}");
            // Stelle sicher dass isTrigger false ist
            col2D.isTrigger = false;
        }
    }
    
    protected virtual void Start()
    {
        Initialize();
    }
    
    /// <summary>
    /// Initialisiert den Gegner
    /// </summary>
    public virtual void Initialize()
    {
        currentHealth = maxHealth;
        attackTimer = baseAttackInterval;
        isActive = true;
        isDead = false;
        SpawnTime = Time.time;
        
        // COLLIDER AUTO-SETUP für Drag-and-Drop Targeting
        EnsureColliderExists();
        
        // Bei Combat Manager registrieren
        if (RiftCombatManager.Instance != null)
        {
            RiftCombatManager.Instance.RegisterEnemy(this);
        }
        
        OnHealthChanged?.Invoke(currentHealth, maxHealth);
        
        // Debug.Log($"[RiftEnemy] {gameObject.name} initialisiert. HP: {maxHealth}, Tier: {tier}"); // REDUCED LOGGING
    }
    
    protected virtual void Update()
    {
        if (!isActive || isDead) return;
        
        // Attack-Timer
        if (canStealTime)
        {
            attackTimer -= Time.deltaTime;
            
            // Feuere Event für UI-Update
            OnNextActionChanged?.Invoke(nextAction, attackTimer);
            
            if (attackTimer <= 0)
            {
                // Führe die aktuelle Aktion aus
                PerformAction();
                // Wähle nächste Aktion
                SelectNextAction();
                attackTimer = baseAttackInterval;
            }
        }
        
        // Spezifisches Verhalten in Unterklassen
        UpdateBehavior();
    }
    
    /// <summary>
    /// Führt Zeitdiebstahl aus
    /// </summary>
    protected virtual void PerformTimeSteal()
    {
        if (RiftTimeSystem.Instance == null) return;
        
        float stealAmount = CalculateTimeStealAmount();
        
        // Debug.Log($"[RiftEnemy] {gameObject.name} stiehlt {stealAmount:F1}s Zeit!"); // REDUCED LOGGING
        
        // Animation
        if (animator != null)
        {
            animator.SetTrigger("Attack");
        }
        
        // Event für UI/Effekte
        OnTimeStealAttempt?.Invoke(stealAmount);
        
        // Tatsächlich Zeit stehlen
        RiftTimeSystem.Instance.StealTime(stealAmount);
        
        // TODO: VFX für Zeitdiebstahl
    }
    
    /// <summary>
    /// Berechnet wie viel Zeit gestohlen wird (kann modifiziert werden)
    /// </summary>
    protected virtual float CalculateTimeStealAmount()
    {
        // Basis-Wert, kann in Unterklassen modifiziert werden
        return baseTimeStealAmount;
    }
    
    /// <summary>
    /// Nimmt Schaden (von Spieler-Karten)
    /// </summary>
    public virtual void TakeDamage(int damage)
    {
        if (isDead) return;
        
        currentHealth -= damage;
        currentHealth = Mathf.Max(0, currentHealth);
        
        Debug.Log($"[RiftEnemy] {gameObject.name} nimmt {damage} Schaden. HP: {currentHealth}/{maxHealth}");
        
        OnHealthChanged?.Invoke(currentHealth, maxHealth);
        
        // Hit-Reaktion
        if (animator != null)
        {
            animator.SetTrigger("Hit");
        }
        
        // Tot?
        if (currentHealth <= 0)
        {
            Die();
        }
    }
    
    /// <summary>
    /// Gegner stirbt
    /// </summary>
    protected virtual void Die()
    {
        if (isDead) return;
        
        isDead = true;
        isActive = false;
        
        Debug.Log($"[RiftEnemy] {gameObject.name} wurde besiegt!");
        
        // Death-Animation
        if (animator != null)
        {
            animator.SetTrigger("Death");
        }
        
        // Event feuern mit this als Parameter
        OnDeath?.Invoke(this);
        
        // Nach Animation zerstören
        StartCoroutine(DeathSequence());
    }
    
    /// <summary>
    /// Tod-Sequenz mit Animation
    /// </summary>
    protected virtual IEnumerator DeathSequence()
    {
        // Warte auf Death-Animation
        yield return new WaitForSeconds(1f);
        
        // TODO: Loot/Effekte spawnen
        
        // Zerstören
        Destroy(gameObject);
    }
    
    /// <summary>
    /// Despawnt den Gegner (z.B. für Boss-Spawn)
    /// </summary>
    public virtual void Despawn()
    {
        isActive = false;
        
        // Fade-Out Effekt
        if (spriteRenderer != null)
        {
            StartCoroutine(FadeOutAndDestroy());
        }
        else
        {
            Destroy(gameObject);
        }
    }
    
    /// <summary>
    /// Fade-Out Effekt beim Despawn
    /// </summary>
    protected IEnumerator FadeOutAndDestroy()
    {
        float fadeTime = 0.5f;
        float elapsed = 0f;
        Color startColor = spriteRenderer.color;
        
        while (elapsed < fadeTime)
        {
            elapsed += Time.deltaTime;
            float alpha = Mathf.Lerp(1f, 0f, elapsed / fadeTime);
            spriteRenderer.color = new Color(startColor.r, startColor.g, startColor.b, alpha);
            yield return null;
        }
        
        Destroy(gameObject);
    }
    
    /// <summary>
    /// Spezifisches Update-Verhalten (Override in Unterklassen)
    /// </summary>
    protected abstract void UpdateBehavior();
    
    // Getter
    public int GetCurrentHealth() => currentHealth;
    public int GetMaxHealth() => maxHealth;
    public bool IsDead() => isDead;
    public float GetHealthPercentage() => maxHealth > 0 ? (float)currentHealth / maxHealth : 0f;
    public EnemyActionType GetNextAction() => nextAction;
    public float GetActionProgress() => baseAttackInterval > 0 ? 1f - (attackTimer / baseAttackInterval) : 0f;
    public float GetRemainingActionTime() => attackTimer;
    public string GetActionDescription() => GetActionDescription(nextAction);
    
    // Attribute System
    public EnemyAttribute GetAttribute() => attribute;
    public void SetAttribute(EnemyAttribute newAttribute) => attribute = newAttribute;
    
    // Guardian-spezifisch
    public void SetProtectedTarget(RiftEnemy target) 
    { 
        protectedTarget = target;
        if (target != null && attribute == EnemyAttribute.Guardian)
        {
            // Guardian-Buffs anwenden
            ApplyGuardianBuffs();
        }
    }
    
    /// <summary>
    /// Guardian gibt Buffs an geschütztes Ziel
    /// </summary>
    protected virtual void ApplyGuardianBuffs()
    {
        if (protectedTarget == null) return;
        
        // Beispiel: +10% HP, +20% Schaden
        // TODO: Implementiere Buff-System
        Debug.Log($"[Guardian] {name} beschützt {protectedTarget.name} mit Buffs!");
    }
    
    /// <summary>
    /// Führt die aktuelle Aktion aus
    /// </summary>
    protected virtual void PerformAction()
    {
        currentAction = nextAction;
        
        switch (currentAction)
        {
            case EnemyActionType.TimeSteal:
                PerformTimeSteal();
                break;
            case EnemyActionType.DoubleStrike:
                PerformDoubleStrike();
                break;
            case EnemyActionType.Defend:
                PerformDefend();
                break;
            case EnemyActionType.Buff:
                PerformBuff();
                break;
            case EnemyActionType.Special:
                PerformSpecialAction();
                break;
        }
    }
    
    /// <summary>
    /// Wählt die nächste Aktion (kann in Unterklassen überschrieben werden)
    /// </summary>
    protected virtual void SelectNextAction()
    {
        // Standard: Immer Zeitdiebstahl
        nextAction = EnemyActionType.TimeSteal;
        actionDescription = GetActionDescription(nextAction);
    }
    
    /// <summary>
    /// Gibt die Beschreibung für eine Aktion zurück
    /// </summary>
    protected virtual string GetActionDescription(EnemyActionType action)
    {
        switch (action)
        {
            case EnemyActionType.TimeSteal:
                return $"Stiehlt {baseTimeStealAmount:F1}s";
            case EnemyActionType.DoubleStrike:
                return "Doppelschlag";
            case EnemyActionType.Defend:
                return "Verteidigung";
            case EnemyActionType.Buff:
                return "Verstärkung";
            case EnemyActionType.Special:
                return "Spezial";
            default:
                return "???";
        }
    }
    
    // Neue Aktions-Methoden (können in Unterklassen überschrieben werden)
    protected virtual void PerformDoubleStrike()
    {
        // Standard: 2x halber Zeitdiebstahl
        PerformTimeSteal();
        StartCoroutine(DelayedTimeSteal(0.5f));
    }
    
    protected virtual void PerformDefend()
    {
        // Standard: Keine Aktion, bereitet sich auf nächste Runde vor
        Debug.Log($"[RiftEnemy] {name} verteidigt sich.");
    }
    
    protected virtual void PerformBuff()
    {
        // Standard: Erhöht eigenen Zeitdiebstahl
        baseTimeStealAmount *= 1.5f;
        Debug.Log($"[RiftEnemy] {name} verstärkt sich! Zeitdiebstahl: {baseTimeStealAmount:F1}s");
    }
    
    protected virtual void PerformSpecialAction()
    {
        // Muss in Unterklassen implementiert werden
        PerformTimeSteal(); // Fallback
    }
    
    private IEnumerator DelayedTimeSteal(float delay)
    {
        yield return new WaitForSeconds(delay);
        PerformTimeSteal();
    }
}

// Enum für Aktionstypen
public enum EnemyActionType
{
    TimeSteal,      // Standard Zeitdiebstahl
    DoubleStrike,   // Doppelter Zeitdiebstahl
    Defend,         // Verteidigung (keine Aktion)
    Buff,           // Selbstverstärkung
    Special         // Spezialfähigkeit
}
