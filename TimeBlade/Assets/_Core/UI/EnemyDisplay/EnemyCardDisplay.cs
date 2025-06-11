using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;

/// <summary>
/// UI-Komponente für die große zentrale Gegner-Karten-Anzeige
/// </summary>
public class EnemyCardDisplay : MonoBehaviour
{
    [Header("UI-Referenzen")]
    [SerializeField] private Image cardBackground;
    [SerializeField] private Image enemyPortrait;
    [SerializeField] private TextMeshProUGUI nameText;
    [SerializeField] private TextMeshProUGUI hpText;
    [SerializeField] private Slider hpBar;
    [SerializeField] private TextMeshProUGUI tierText;
    [SerializeField] private TextMeshProUGUI attributeText;
    
    
    [Header("Attribute-Icons")]
    [SerializeField] private GameObject guardianIcon;
    [SerializeField] private GameObject aggressorIcon;
    [SerializeField] private GameObject ambushIcon;
    [SerializeField] private GameObject supporterIcon;
    [SerializeField] private GameObject summonedIcon;
    [SerializeField] private GameObject shieldIcon; // Für Boss-Unverwundbarkeit
    
    [Header("Farben")]
    [SerializeField] private Color standardColor = Color.gray;
    [SerializeField] private Color eliteColor = Color.blue;
    [SerializeField] private Color miniBossColor = new Color(0.5f, 0f, 0.5f); // Lila
    [SerializeField] private Color bossColor = Color.red;
    
    [Header("Effekte")]
    [SerializeField] private GameObject damageFlashEffect;
    [SerializeField] private GameObject targetHighlight;
    [SerializeField] private float updateAnimationSpeed = 0.3f;
    
    private RiftEnemy currentEnemy;
    
    // LOG-SPAM REDUZIERUNG: Tracking für selektive HP-Logs
    private int lastLoggedTotalHP = 0;
    private Coroutine hpAnimationCoroutine;
    private float displayedHP;
    
    // Für Gesamt-HP-Anzeige
    private int totalEnemyHP = 0;
    
    void Awake()
    {
        // Icons initial verstecken
        HideAllAttributeIcons();
        
        if (targetHighlight != null)
            targetHighlight.SetActive(false);
            
        // LeanTween kapazität erhöhen, falls nicht bereits initialisiert
        if (LeanTween.tweensRunning == 0) {
            // Erhöhe die Anzahl der verfügbaren Tween-Slots auf einen höheren Wert
            LeanTween.init(800); 
        }
    }
    
    void OnEnable()
    {
        // Events abonnieren für Gesamt-HP-Updates
        if (EnemyFocusSystem.Instance != null)
        {
            EnemyFocusSystem.OnEnemyAddedToQueue += OnEnemyQueueChanged;
            EnemyFocusSystem.OnEnemyRemovedFromQueue += OnEnemyQueueChanged;
        }
    }
    
    void OnDisable()
    {
        // Events abmelden
        if (EnemyFocusSystem.Instance != null)
        {
            EnemyFocusSystem.OnEnemyAddedToQueue -= OnEnemyQueueChanged;
            EnemyFocusSystem.OnEnemyRemovedFromQueue -= OnEnemyQueueChanged;
        }
    }
    
    /// <summary>
    /// Setzt den anzuzeigenden Gegner
    /// </summary>
    public void SetEnemy(RiftEnemy enemy)
    {
        if (enemy == null)
        {
            gameObject.SetActive(false);
            return;
        }
        
        // Alte Events abmelden
        if (currentEnemy != null)
        {
            currentEnemy.OnHealthChanged -= UpdateHealthDisplay;
            currentEnemy.OnTimeStealAttempt -= ShowTimeStealEffect;
        }
        
        currentEnemy = enemy;
        gameObject.SetActive(true);
        
        // Events abonnieren
        currentEnemy.OnHealthChanged += UpdateHealthDisplay;
        currentEnemy.OnTimeStealAttempt += ShowTimeStealEffect;
        
        // Initial-Anzeige
        UpdateDisplay();
        
        // Spawn-Animation
        PlaySpawnAnimation();
        
        // WICHTIG: Gesamt-HP nach kurzer Verzögerung nochmal berechnen
        // damit alle Gegner in der Queue sind
        StartCoroutine(DelayedTotalHPUpdate());
    }
    
    /// <summary>
    /// Aktualisiert die komplette Anzeige
    /// </summary>
    private void UpdateDisplay()
    {
        if (currentEnemy == null) return;
        
        // Name
        if (nameText != null)
            nameText.text = currentEnemy.name;
        
        // HP
        int currentHP = currentEnemy.GetCurrentHealth();
        int maxHP = currentEnemy.GetMaxHealth();
        displayedHP = currentHP;
        
        // Berechne Gesamt-HP aller Gegner
        CalculateTotalEnemyHP();
        
        if (hpText != null)
        {
            // Format: "Aktuelle HP / Max HP (Gesamt-HP)"
            hpText.text = $"{currentHP}/{maxHP} <color=#888888>({totalEnemyHP})</color>";
        }
        
        if (hpBar != null)
        {
            hpBar.maxValue = maxHP;
            hpBar.value = currentHP;
        }
        
        // Tier-Farbe
        UpdateTierDisplay();
        
        // Attribute-Icon
        UpdateAttributeIcon();
        
        // Boss-Schild bei Unverwundbarkeit
        if (currentEnemy is RiftBoss boss)
        {
            bool isVulnerable = boss.IsDead() || IsVulnerable(boss);
            if (shieldIcon != null)
                shieldIcon.SetActive(!isVulnerable);
        }
        
        // Portrait (TODO: Echte Sprites)
        // if (enemyPortrait != null && currentEnemy.GetPortrait() != null)
        //     enemyPortrait.sprite = currentEnemy.GetPortrait();
    }
    
    /// <summary>
    /// Prüft ob Boss verwundbar ist (Workaround da keine public Property)
    /// </summary>
    private bool IsVulnerable(RiftBoss boss)
    {
        // TODO: Bessere Lösung wenn Boss isVulnerable public macht
        return EnemyFocusSystem.Instance != null && 
               EnemyFocusSystem.Instance.GetEnemyQueue().Count == 0;
    }
    
    /// <summary>
    /// Aktualisiert Tier-Farbe und Text
    /// </summary>
    private void UpdateTierDisplay()
    {
        Color tierColor = standardColor;
        string tierName = "Standard";
        
        switch (currentEnemy.Tier)
        {
            case RiftPointSystem.EnemyTier.Standard:
                tierColor = standardColor;
                tierName = "Standard";
                break;
            case RiftPointSystem.EnemyTier.Elite:
                tierColor = eliteColor;
                tierName = "Elite";
                break;
            case RiftPointSystem.EnemyTier.MiniBoss:
                tierColor = miniBossColor;
                tierName = "Mini-Boss";
                break;
            case RiftPointSystem.EnemyTier.RiftBoss:
                tierColor = bossColor;
                tierName = "RIFT BOSS";
                break;
        }
        
        if (cardBackground != null)
            cardBackground.color = tierColor;
        
        if (tierText != null)
        {
            tierText.text = tierName;
            tierText.color = tierColor;
        }
    }
    
    /// <summary>
    /// Zeigt das passende Attribut-Icon
    /// </summary>
    private void UpdateAttributeIcon()
    {
        HideAllAttributeIcons();
        
        EnemyAttribute attribute = currentEnemy.GetAttribute();
        
        if (attributeText != null)
            attributeText.text = attribute.ToString();
        
        switch (attribute)
        {
            case EnemyAttribute.Guardian:
                if (guardianIcon != null) guardianIcon.SetActive(true);
                break;
            case EnemyAttribute.Aggressor:
                if (aggressorIcon != null) aggressorIcon.SetActive(true);
                break;
            case EnemyAttribute.Ambush:
                if (ambushIcon != null) ambushIcon.SetActive(true);
                break;
            case EnemyAttribute.Supporter:
                if (supporterIcon != null) supporterIcon.SetActive(true);
                break;
            case EnemyAttribute.Summoned:
                if (summonedIcon != null) summonedIcon.SetActive(true);
                break;
        }
    }
    
    /// <summary>
    /// Versteckt alle Attribut-Icons
    /// </summary>
    private void HideAllAttributeIcons()
    {
        if (guardianIcon != null) guardianIcon.SetActive(false);
        if (aggressorIcon != null) aggressorIcon.SetActive(false);
        if (ambushIcon != null) ambushIcon.SetActive(false);
        if (supporterIcon != null) supporterIcon.SetActive(false);
        if (summonedIcon != null) summonedIcon.SetActive(false);
    }
    
    /// <summary>
    /// Health-Änderungs-Animation
    /// </summary>
    private void UpdateHealthDisplay(int currentHP, int maxHP)
    {
        if (hpAnimationCoroutine != null)
            StopCoroutine(hpAnimationCoroutine);
        
        hpAnimationCoroutine = StartCoroutine(AnimateHealthChange(currentHP, maxHP));
        
        // Damage-Flash bei Schaden
        if (currentHP < displayedHP)
        {
            PlayDamageFlash();
        }
    }
    
    /// <summary>
    /// Animiert HP-Änderung
    /// </summary>
    private IEnumerator AnimateHealthChange(int targetHP, int maxHP)
    {
        float startHP = displayedHP;
        float elapsed = 0f;
        
        while (elapsed < updateAnimationSpeed)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / updateAnimationSpeed;
            
            displayedHP = Mathf.Lerp(startHP, targetHP, t);
            
            if (hpText != null)
            {
                // Berechne Gesamt-HP während der Animation
                CalculateTotalEnemyHP();
                hpText.text = $"{Mathf.RoundToInt(displayedHP)}/{maxHP} <color=#888888>({totalEnemyHP})</color>";
            }
            
            if (hpBar != null)
                hpBar.value = displayedHP;
            
            yield return null;
        }
        
        displayedHP = targetHP;
        if (hpText != null)
        {
            CalculateTotalEnemyHP();
            hpText.text = $"{targetHP}/{maxHP} <color=#888888>({totalEnemyHP})</color>";
        }
        if (hpBar != null)
            hpBar.value = targetHP;
    }
    
    /// <summary>
    /// Damage-Flash-Effekt
    /// </summary>
    private void PlayDamageFlash()
    {
        if (damageFlashEffect != null)
        {
            damageFlashEffect.SetActive(true);
            StartCoroutine(DisableAfterDelay(damageFlashEffect, 0.3f));
        }
        
        // Card-Shake
        StartCoroutine(ShakeCard());
    }
    
    /// <summary>
    /// Karten-Shake-Animation
    /// </summary>
    private IEnumerator ShakeCard()
    {
        Vector3 originalPos = transform.localPosition;
        float shakeDuration = 0.2f;
        float shakeAmount = 10f;
        float elapsed = 0f;
        
        while (elapsed < shakeDuration)
        {
            elapsed += Time.deltaTime;
            float x = Random.Range(-shakeAmount, shakeAmount);
            float y = Random.Range(-shakeAmount, shakeAmount);
            transform.localPosition = originalPos + new Vector3(x, y, 0);
            yield return null;
        }
        
        transform.localPosition = originalPos;
    }
    
    /// <summary>
    /// Zeigt Zeitdiebstahl-Effekt
    /// </summary>
    private void ShowTimeStealEffect(float amount)
    {
        // TODO: Zeitdiebstahl-VFX
        Debug.Log($"[EnemyCard] Zeitdiebstahl-Animation: -{amount}s");
    }
    
    /// <summary>
    /// Spawn-Animation
    /// </summary>
    private void PlaySpawnAnimation()
    {
        transform.localScale = Vector3.zero;
        LeanTween.scale(gameObject, Vector3.one, 0.5f)
            .setEaseOutBack();
    }
    
    /// <summary>
    /// Highlight für Targeting
    /// </summary>
    public void SetTargetable(bool targetable)
    {
        if (targetHighlight != null)
            targetHighlight.SetActive(targetable);
        
        // Pulsierender Effekt bei Targetable
        if (targetable)
        {
            LeanTween.scale(gameObject, Vector3.one * 1.05f, 0.5f)
                .setLoopPingPong();
        }
        else
        {
            LeanTween.cancel(gameObject);
            transform.localScale = Vector3.one;
        }
    }
    
    /// <summary>
    /// Berechnet die Gesamt-HP aller aktiven Gegner
    /// </summary>
    private void CalculateTotalEnemyHP()
    {
        totalEnemyHP = 0;
        
        if (EnemyFocusSystem.Instance == null) return;
        
        // LOG-SPAM REDUZIERT: Detaillierte HP-Logs entfernt für bessere Handkarten-Debugging
        var currentTarget = EnemyFocusSystem.Instance.GetCurrentTarget();
        var enemyQueue = EnemyFocusSystem.Instance.GetEnemyQueue();
        
        // Zähle ALLE Gegner in der Queue (OHNE Logs)
        foreach (var enemy in enemyQueue)
        {
            if (enemy != null && !enemy.IsDead())
            {
                int hp = enemy.GetCurrentHealth();
                totalEnemyHP += hp;
            }
        }
        
        // Boss-Spezialbehandlung (Boss ist oft NICHT in der Queue)
        if (EnemyFocusSystem.Instance.IsBossActive())
        {
            if (currentTarget != null && currentTarget is RiftBoss boss && !boss.IsDead())
            {
                // Boss nur addieren wenn er NICHT schon in der Queue war
                if (!enemyQueue.Contains(boss))
                {
                    totalEnemyHP += boss.GetCurrentHealth();
                }
            }
        }
        
        // NUR noch Gesamt-Resultat loggen bei signifikanten Änderungen
        if (Mathf.Abs(totalEnemyHP - lastLoggedTotalHP) > 10 || lastLoggedTotalHP == 0)
        {
            // Debug.Log($"[EnemyCard] Gesamt-HP aller Gegner: {totalEnemyHP} (Änderung von {lastLoggedTotalHP})"); // REDUCED LOGGING
            lastLoggedTotalHP = totalEnemyHP;
        }
    }
    
    /// <summary>
    /// Wird aufgerufen wenn sich die Gegner-Queue ändert
    /// </summary>
    private void OnEnemyQueueChanged(RiftEnemy enemy)
    {
        // Gesamt-HP neu berechnen und Anzeige aktualisieren
        CalculateTotalEnemyHP();
        
        // Nur das HP-Text-Element aktualisieren, nicht die ganze Anzeige
        if (currentEnemy != null && hpText != null)
        {
            int currentHP = currentEnemy.GetCurrentHealth();
            int maxHP = currentEnemy.GetMaxHealth();
            hpText.text = $"{currentHP}/{maxHP} <color=#888888>({totalEnemyHP})</color>";
        }
    }
    
    /// <summary>
    /// Click-Handler für Targeting
    /// </summary>
    void OnMouseDown()
    {
        if (RiftCombatManager.Instance != null && 
            RiftCombatManager.Instance.IsInTargetingMode)
        {
            RiftCombatManager.Instance.EnemyCardClicked(currentEnemy);
        }
    }
    
    /// <summary>
    /// Hilfsmethode: GameObject nach Delay deaktivieren
    /// </summary>
    private IEnumerator DisableAfterDelay(GameObject obj, float delay)
    {
        yield return new WaitForSeconds(delay);
        obj.SetActive(false);
    }
    
    /// <summary>
    /// Verzögerte Gesamt-HP Berechnung
    /// </summary>
    private IEnumerator DelayedTotalHPUpdate()
    {
        // Warte 0.5 Sekunden damit alle Gegner in der Queue sind
        yield return new WaitForSeconds(0.5f);
        
        // Berechne Gesamt-HP nochmal
        CalculateTotalEnemyHP();
        
        // Update Anzeige
        if (currentEnemy != null && hpText != null)
        {
            int currentHP = currentEnemy.GetCurrentHealth();
            int maxHP = currentEnemy.GetMaxHealth();
            hpText.text = $"{currentHP}/{maxHP} <color=#888888>({totalEnemyHP})</color>";
        }
    }
    
    void OnDestroy()
    {
        // Events abmelden
        if (currentEnemy != null)
        {
            currentEnemy.OnHealthChanged -= UpdateHealthDisplay;
            currentEnemy.OnTimeStealAttempt -= ShowTimeStealEffect;
        }
        
        // Alle LeanTween Animationen stoppen
        LeanTween.cancel(gameObject);
    }
    
}
