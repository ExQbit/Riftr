using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;

/// <summary>
/// UI-Komponente für die kleine Sphären-Darstellung in der Gegner-Warteschlange
/// </summary>
public class EnemySphereDisplay : MonoBehaviour
{
    [Header("UI-Referenzen")]
    [SerializeField] private Image sphereImage;
    [SerializeField] private Image hpFillImage;
    [SerializeField] private Image attributeIcon;
    [SerializeField] private TextMeshProUGUI positionText;
    [SerializeField] private GameObject highlightRing;
    [SerializeField] private GameObject summonedIndicator;
    
    [Header("Attribute-Sprites")]
    [SerializeField] private Sprite guardianSprite;
    [SerializeField] private Sprite aggressorSprite;
    [SerializeField] private Sprite ambushSprite;
    [SerializeField] private Sprite supporterSprite;
    [SerializeField] private Sprite summonedSprite;
    
    [Header("Farben")]
    [SerializeField] private Color standardColor = new Color(0.7f, 0.7f, 0.7f);
    [SerializeField] private Color eliteColor = new Color(0.3f, 0.5f, 1f);
    [SerializeField] private Color miniBossColor = new Color(0.6f, 0.3f, 0.8f);
    [SerializeField] private Color damageColor = new Color(1f, 0.3f, 0.3f);
    
    [Header("Animationen")]
    [SerializeField] private float pulseSpeed = 1f;
    [SerializeField] private float damageFlashDuration = 0.2f;
    
    private RiftEnemy currentEnemy;
    private int queuePosition;
    private bool isHighlighted = false;
    private Coroutine pulseCoroutine;
    
    void Awake()
    {
        if (highlightRing != null)
            highlightRing.SetActive(false);
        
        if (summonedIndicator != null)
            summonedIndicator.SetActive(false);
    }
    
    /// <summary>
    /// Setzt den anzuzeigenden Gegner
    /// </summary>
    public void SetEnemy(RiftEnemy enemy, int position = 0)
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
            currentEnemy.OnDeath -= HandleEnemyDeath;
        }
        
        currentEnemy = enemy;
        queuePosition = position;
        gameObject.SetActive(true);
        
        // Events abonnieren
        currentEnemy.OnHealthChanged += UpdateHealthDisplay;
        currentEnemy.OnDeath += HandleEnemyDeath;
        
        // Initial-Display
        UpdateDisplay();
        
        // Spawn-Animation
        PlaySpawnAnimation();
    }
    
    /// <summary>
    /// Aktualisiert die Anzeige
    /// </summary>
    private void UpdateDisplay()
    {
        if (currentEnemy == null) return;
        
        // Position in Queue
        if (positionText != null)
            positionText.text = (queuePosition + 1).ToString();
        
        // Tier-Farbe
        UpdateSphereColor();
        
        // HP-Anzeige
        UpdateHealthDisplay(currentEnemy.GetCurrentHealth(), currentEnemy.GetMaxHealth());
        
        // Attribut-Icon
        UpdateAttributeDisplay();
        
        // Summoned-Indicator
        if (summonedIndicator != null)
            summonedIndicator.SetActive(currentEnemy.GetAttribute() == EnemyAttribute.Summoned);
    }
    
    /// <summary>
    /// Aktualisiert die Sphären-Farbe basierend auf Tier
    /// </summary>
    private void UpdateSphereColor()
    {
        Color sphereColor = standardColor;
        
        switch (currentEnemy.Tier)
        {
            case RiftPointSystem.EnemyTier.Elite:
                sphereColor = eliteColor;
                break;
            case RiftPointSystem.EnemyTier.MiniBoss:
                sphereColor = miniBossColor;
                break;
        }
        
        if (sphereImage != null)
            sphereImage.color = sphereColor;
    }
    
    /// <summary>
    /// Aktualisiert das Attribut-Icon
    /// </summary>
    private void UpdateAttributeDisplay()
    {
        if (attributeIcon == null) return;
        
        EnemyAttribute attribute = currentEnemy.GetAttribute();
        Sprite iconSprite = null;
        
        switch (attribute)
        {
            case EnemyAttribute.Guardian:
                iconSprite = guardianSprite;
                break;
            case EnemyAttribute.Aggressor:
                iconSprite = aggressorSprite;
                break;
            case EnemyAttribute.Ambush:
                iconSprite = ambushSprite;
                break;
            case EnemyAttribute.Supporter:
                iconSprite = supporterSprite;
                break;
            case EnemyAttribute.Summoned:
                iconSprite = summonedSprite;
                break;
        }
        
        if (iconSprite != null)
        {
            attributeIcon.gameObject.SetActive(true);
            attributeIcon.sprite = iconSprite;
        }
        else
        {
            attributeIcon.gameObject.SetActive(false);
        }
    }
    
    /// <summary>
    /// HP-Update
    /// </summary>
    private void UpdateHealthDisplay(int currentHP, int maxHP)
    {
        if (hpFillImage != null)
        {
            float fillAmount = maxHP > 0 ? (float)currentHP / maxHP : 0f;
            hpFillImage.fillAmount = fillAmount;
            
            // Flash bei Schaden
            if (currentHP < maxHP)
            {
                StartCoroutine(DamageFlash());
            }
        }
    }
    
    /// <summary>
    /// Damage-Flash-Effekt
    /// </summary>
    private IEnumerator DamageFlash()
    {
        if (sphereImage != null)
        {
            Color originalColor = sphereImage.color;
            sphereImage.color = damageColor;
            
            yield return new WaitForSeconds(damageFlashDuration);
            
            sphereImage.color = originalColor;
        }
        
        // Kleine Shake-Animation
        Vector3 originalPos = transform.localPosition;
        float shakeAmount = 5f;
        
        for (int i = 0; i < 3; i++)
        {
            transform.localPosition = originalPos + Random.insideUnitSphere * shakeAmount;
            yield return new WaitForSeconds(0.05f);
        }
        
        transform.localPosition = originalPos;
    }
    
    /// <summary>
    /// Setzt Highlight-Status
    /// </summary>
    public void SetHighlight(bool highlight)
    {
        isHighlighted = highlight;
        
        if (highlightRing != null)
            highlightRing.SetActive(highlight);
        
        // Pulse-Animation starten/stoppen
        if (highlight)
        {
            if (pulseCoroutine != null)
                StopCoroutine(pulseCoroutine);
            pulseCoroutine = StartCoroutine(PulseAnimation());
        }
        else
        {
            if (pulseCoroutine != null)
            {
                StopCoroutine(pulseCoroutine);
                pulseCoroutine = null;
            }
            transform.localScale = Vector3.one;
        }
    }
    
    /// <summary>
    /// Pulsier-Animation für Highlight
    /// </summary>
    private IEnumerator PulseAnimation()
    {
        while (isHighlighted)
        {
            // Scale up
            float elapsed = 0f;
            while (elapsed < pulseSpeed / 2f)
            {
                elapsed += Time.deltaTime;
                float scale = Mathf.Lerp(1f, 1.15f, elapsed / (pulseSpeed / 2f));
                transform.localScale = Vector3.one * scale;
                yield return null;
            }
            
            // Scale down
            elapsed = 0f;
            while (elapsed < pulseSpeed / 2f)
            {
                elapsed += Time.deltaTime;
                float scale = Mathf.Lerp(1.15f, 1f, elapsed / (pulseSpeed / 2f));
                transform.localScale = Vector3.one * scale;
                yield return null;
            }
        }
    }
    
    /// <summary>
    /// Spawn-Animation
    /// </summary>
    private void PlaySpawnAnimation()
    {
        transform.localScale = Vector3.zero;
        LeanTween.scale(gameObject, Vector3.one, 0.3f)
            .setEaseOutBack()
            .setDelay(queuePosition * 0.1f); // Gestaffelte Animation
    }
    
    /// <summary>
    /// Tod-Handler
    /// </summary>
    private void HandleEnemyDeath(RiftEnemy enemy)
    {
        // Death-Animation
        LeanTween.scale(gameObject, Vector3.zero, 0.3f)
            .setEaseInBack()
            .setOnComplete(() => {
                gameObject.SetActive(false);
            });
    }
    
    /// <summary>
    /// Aktualisiert Position in Queue mit Animation
    /// </summary>
    public void UpdateQueuePosition(int newPosition)
    {
        queuePosition = newPosition;
        
        if (positionText != null)
            positionText.text = (queuePosition + 1).ToString();
        
        // Slide-Animation zur neuen Position
        if (GetComponent<RectTransform>() != null)
        {
            Vector2 targetPos = new Vector2(queuePosition * 100f, 0);
            LeanTween.moveLocal(gameObject, targetPos, 0.3f)
                .setEaseOutQuad();
        }
    }
    
    /// <summary>
    /// Click-Handler für Targeting und Details
    /// </summary>
    void OnMouseDown()
    {
        // Prüfe ob Targeting-Modus aktiv ist
        if (RiftCombatManager.Instance != null && 
            RiftCombatManager.Instance.IsInTargetingMode &&
            currentEnemy != null)
        {
            RiftCombatManager.Instance.EnemyCardClicked(currentEnemy);
        }
        else if (currentEnemy != null)
        {
            // Falls kein Targeting-Modus: Zeige Enemy-Details oder fokussiere
            Debug.Log($"[EnemySphere] {currentEnemy.name} angeklickt (kein Targeting-Modus)");
        }
    }
    
    void OnMouseEnter()
    {
        // Hover-Effekt
        if (!isHighlighted)
        {
            transform.localScale = Vector3.one * 1.1f;
        }
    }
    
    void OnMouseExit()
    {
        // Hover-Effekt entfernen
        if (!isHighlighted)
        {
            transform.localScale = Vector3.one;
        }
    }
    
    void OnDestroy()
    {
        // Events abmelden
        if (currentEnemy != null)
        {
            currentEnemy.OnHealthChanged -= UpdateHealthDisplay;
            currentEnemy.OnDeath -= HandleEnemyDeath;
        }
        
        // Animationen stoppen
        if (pulseCoroutine != null)
            StopCoroutine(pulseCoroutine);
        
        LeanTween.cancel(gameObject);
    }
}
