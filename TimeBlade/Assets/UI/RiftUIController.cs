using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;

/// <summary>
/// Basis-UI-Controller für das Rift-System.
/// Zeigt Zeit, Punkte und Schildmacht an.
/// </summary>
public class RiftUIController : MonoBehaviour
{
    [Header("Zeit-Anzeige")]
    [SerializeField] private TextMeshProUGUI timeText;
    [SerializeField] private TextMeshProUGUI timePreciseText; // Für Detail-Ansicht
    [SerializeField] private Image timeBar;
    [SerializeField] private GameObject timeWarningEffect;
    
    [Header("Punkte-Anzeige")]
    [SerializeField] private TextMeshProUGUI pointsText;
    [SerializeField] private Image pointsBar;
    [SerializeField] private GameObject bossThresholdIndicator;
    
    [Header("Schildmacht-Anzeige")]
    [SerializeField] private GameObject[] shieldPowerIcons; // 5 Icons für 0-5 SM
    [SerializeField] private TextMeshProUGUI shieldPowerText;
    
    [Header("Effekte")]
    [SerializeField] private Color normalTimeColor = Color.white;
    [SerializeField] private Color warningTimeColor = Color.yellow;
    [SerializeField] private Color criticalTimeColor = Color.red;
    
    // Referenzen
    private RiftTimeSystem timeSystem;
    private RiftPointSystem pointSystem;
    private ShieldPowerSystem shieldPower;
    
    // State
    private bool isShowingPreciseTime = false;
    private Coroutine timePulseCoroutine;
    
    void Start()
    {
        // Systeme finden
        timeSystem = RiftTimeSystem.Instance;
        pointSystem = RiftPointSystem.Instance;
        
        var player = ZeitwaechterPlayer.Instance;
        if (player != null)
        {
            shieldPower = player.GetComponent<ShieldPowerSystem>();
        }
        
        // Events abonnieren
        RegisterEventListeners();
        
        // Initial Update
        UpdateAllUI();
    }
    
    /// <summary>
    /// Events abonnieren
    /// </summary>
    private void RegisterEventListeners()
    {
        // Zeit-Events
        if (timeSystem != null)
        {
            RiftTimeSystem.OnTimeChanged += UpdateTimeDisplay;
            RiftTimeSystem.OnTimeGained += ShowTimeGainEffect;
            RiftTimeSystem.OnTimeStolen += ShowTimeStealEffect;
        }
        
        // Punkte-Events
        if (pointSystem != null)
        {
            RiftPointSystem.OnPointsChanged += UpdatePointsDisplay;
            RiftPointSystem.OnPointsGained += ShowPointsGainEffect;
            RiftPointSystem.OnBossThresholdReached += ShowBossReadyEffect;
        }
        
        // Schildmacht-Events
        if (shieldPower != null)
        {
            ShieldPowerSystem.OnShieldPowerChanged += UpdateShieldPowerDisplay;
            ShieldPowerSystem.OnShieldBreak += ShowShieldBreakEffect;
        }
    }
    
    /// <summary>
    /// Aktualisiert alle UI-Elemente
    /// </summary>
    private void UpdateAllUI()
    {
        if (timeSystem != null)
        {
            UpdateTimeDisplay(timeSystem.GetCurrentTime(), timeSystem.GetMaxTime());
        }
        
        if (pointSystem != null)
        {
            UpdatePointsDisplay(pointSystem.GetCurrentPoints(), pointSystem.GetTargetPoints());
        }
        
        if (shieldPower != null)
        {
            UpdateShieldPowerDisplay(shieldPower.GetCurrentShieldPower());
        }
    }
    
    /// <summary>
    /// Aktualisiert die Zeit-Anzeige
    /// </summary>
    private void UpdateTimeDisplay(float current, float max)
    {
        // Text-Anzeige
        if (timeText != null)
        {
            timeText.text = timeSystem.GetTimeDisplayString();
            
            // Farbe basierend auf verbleibender Zeit
            if (current <= 10f)
            {
                timeText.color = criticalTimeColor;
                StartTimePulse();
            }
            else if (current <= 30f)
            {
                timeText.color = warningTimeColor;
            }
            else
            {
                timeText.color = normalTimeColor;
                StopTimePulse();
            }
        }
        
        // Präzise Anzeige (wenn aktiviert)
        if (timePreciseText != null && isShowingPreciseTime)
        {
            timePreciseText.text = timeSystem.GetTimePreciseString();
        }
        
        // Zeit-Balken
        if (timeBar != null)
        {
            timeBar.fillAmount = timeSystem.GetTimePercentage();
            timeBar.color = timeText.color;
        }
    }
    
    /// <summary>
    /// Aktualisiert die Punkte-Anzeige
    /// </summary>
    private void UpdatePointsDisplay(int current, int target)
    {
        // Text
        if (pointsText != null)
        {
            pointsText.text = pointSystem.GetPointsDisplayString();
        }
        
        // Fortschritts-Balken
        if (pointsBar != null)
        {
            pointsBar.fillAmount = pointSystem.GetProgress();
        }
        
        // Boss-Schwelle erreicht?
        if (bossThresholdIndicator != null)
        {
            bossThresholdIndicator.SetActive(current >= target);
        }
    }
    
    /// <summary>
    /// Aktualisiert die Schildmacht-Anzeige
    /// </summary>
    private void UpdateShieldPowerDisplay(int current)
    {
        // Icons
        if (shieldPowerIcons != null)
        {
            for (int i = 0; i < shieldPowerIcons.Length; i++)
            {
                if (shieldPowerIcons[i] != null)
                {
                    shieldPowerIcons[i].SetActive(i < current);
                }
            }
        }
        
        // Text
        if (shieldPowerText != null)
        {
            shieldPowerText.text = $"{current}/5";
            
            // Farbe bei Maximum
            if (current >= 5)
            {
                shieldPowerText.color = warningTimeColor;
            }
            else
            {
                shieldPowerText.color = normalTimeColor;
            }
        }
    }
    
    /// <summary>
    /// Zeigt Zeitgewinn-Effekt
    /// </summary>
    private void ShowTimeGainEffect(float amount)
    {
        // TODO: Floating Text "+X.Xs"
        Debug.Log($"[UI] Zeit gewonnen: +{amount:F1}s");
    }
    
    /// <summary>
    /// Zeigt Zeitverlust-Effekt
    /// </summary>
    private void ShowTimeStealEffect(float amount)
    {
        // TODO: Roter Flash-Effekt
        // Debug.Log($"[UI] Zeit gestohlen: -{amount:F1}s"); // REDUCED LOGGING
        
        // Screen-Shake bei großem Verlust
        if (amount >= 2f)
        {
            // TODO: Camera Shake
        }
    }
    
    /// <summary>
    /// Zeigt Punktegewinn-Effekt
    /// </summary>
    private void ShowPointsGainEffect(int amount)
    {
        // TODO: Floating Points
        Debug.Log($"[UI] Punkte erhalten: +{amount}");
    }
    
    /// <summary>
    /// Boss-Bereit-Effekt
    /// </summary>
    private void ShowBossReadyEffect()
    {
        // TODO: Dramatischer Effekt
        Debug.Log("[UI] BOSS-SCHWELLE ERREICHT!");
    }
    
    /// <summary>
    /// Schildbruch-Effekt
    /// </summary>
    private void ShowShieldBreakEffect(int damage, float timeSteal)
    {
        // TODO: Explosion-Effekt
        Debug.Log($"[UI] SCHILDBRUCH! {damage} Schaden + {timeSteal}s Zeitraub!");
    }
    
    /// <summary>
    /// Startet Zeit-Pulsieren bei kritischer Zeit
    /// </summary>
    private void StartTimePulse()
    {
        if (timePulseCoroutine == null)
        {
            timePulseCoroutine = StartCoroutine(TimePulseEffect());
        }
    }
    
    /// <summary>
    /// Stoppt Zeit-Pulsieren
    /// </summary>
    private void StopTimePulse()
    {
        if (timePulseCoroutine != null)
        {
            StopCoroutine(timePulseCoroutine);
            timePulseCoroutine = null;
        }
        
        if (timeWarningEffect != null)
        {
            timeWarningEffect.SetActive(false);
        }
    }
    
    /// <summary>
    /// Pulsier-Effekt für kritische Zeit
    /// </summary>
    private IEnumerator TimePulseEffect()
    {
        while (true)
        {
            if (timeWarningEffect != null)
            {
                timeWarningEffect.SetActive(true);
            }
            
            yield return new WaitForSeconds(0.5f);
            
            if (timeWarningEffect != null)
            {
                timeWarningEffect.SetActive(false);
            }
            
            yield return new WaitForSeconds(0.5f);
        }
    }
    
    /// <summary>
    /// Toggle für präzise Zeit-Anzeige (Mobile: Touch-Hold)
    /// </summary>
    public void TogglePreciseTimeDisplay()
    {
        isShowingPreciseTime = !isShowingPreciseTime;
        
        if (timePreciseText != null)
        {
            timePreciseText.gameObject.SetActive(isShowingPreciseTime);
        }
    }
    
    void OnDestroy()
    {
        // Events abmelden
        if (timeSystem != null)
        {
            RiftTimeSystem.OnTimeChanged -= UpdateTimeDisplay;
            RiftTimeSystem.OnTimeGained -= ShowTimeGainEffect;
            RiftTimeSystem.OnTimeStolen -= ShowTimeStealEffect;
        }
        
        if (pointSystem != null)
        {
            RiftPointSystem.OnPointsChanged -= UpdatePointsDisplay;
            RiftPointSystem.OnPointsGained -= ShowPointsGainEffect;
            RiftPointSystem.OnBossThresholdReached -= ShowBossReadyEffect;
        }
        
        if (shieldPower != null)
        {
            ShieldPowerSystem.OnShieldPowerChanged -= UpdateShieldPowerDisplay;
            ShieldPowerSystem.OnShieldBreak -= ShowShieldBreakEffect;
        }
    }
}
