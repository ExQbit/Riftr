using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;

/// <summary>
/// UI-Controller für die Zeit-Anzeige im Rift-System.
/// Zeigt die verbleibende Zeit mit flüssiger Animation.
/// </summary>
public class RiftTimeDisplay : MonoBehaviour
{
    [Header("UI-Referenzen")]
    [SerializeField] private TextMeshProUGUI timeText;
    [SerializeField] private Slider timeBar;
    [SerializeField] private Image timeBarFill;
    
    [Header("Farben")]
    [SerializeField] private Color normalColor = new Color(0.2f, 0.6f, 1f);
    [SerializeField] private Color warningColor = new Color(1f, 0.8f, 0.2f);
    [SerializeField] private Color criticalColor = new Color(1f, 0.2f, 0.2f);
    [SerializeField] private Gradient timeGradient; // Alternative zu einzelnen Farben
    
    [Header("Warnungen")]
    [SerializeField] private float warningThreshold = 60f; // Sekunden
    [SerializeField] private float criticalThreshold = 30f; // Sekunden
    [SerializeField] private float pulseSpeed = 2f; // Puls-Geschwindigkeit bei kritisch
    
    [Header("Animation")]
    [SerializeField] private bool smoothTimer = true; // Flüssige Animation
    [SerializeField] private float updateInterval = 0.1f; // Wie oft Text aktualisiert wird
    
    // Interne Variablen
    private float displayedTime = 0f;
    private float lastTextUpdate = 0f;
    private Coroutine pulseCoroutine;
    
    void OnEnable()
    {
        // Events abonnieren
        RiftTimeSystem.OnTimeChanged += UpdateTimeDisplay;
        RiftTimeSystem.OnTimeGained += OnTimeGained;
        RiftTimeSystem.OnTimeStolen += OnTimeStolen;
    }
    
    void OnDisable()
    {
        // Events abmelden
        RiftTimeSystem.OnTimeChanged -= UpdateTimeDisplay;
        RiftTimeSystem.OnTimeGained -= OnTimeGained;
        RiftTimeSystem.OnTimeStolen -= OnTimeStolen;
        
        if (pulseCoroutine != null)
        {
            StopCoroutine(pulseCoroutine);
        }
    }
    
    /// <summary>
    /// Aktualisiert die Zeit-Anzeige
    /// </summary>
    private void UpdateTimeDisplay(float currentTime, float maxTime)
    {
        // Smooth interpolation für flüssige Anzeige
        if (smoothTimer)
        {
            displayedTime = Mathf.Lerp(displayedTime, currentTime, Time.deltaTime * 10f);
        }
        else
        {
            displayedTime = currentTime;
        }
        
        // Update Slider (immer smooth)
        if (timeBar != null)
        {
            timeBar.maxValue = maxTime;
            timeBar.value = displayedTime;
        }
        
        // Update Text (mit Update-Interval für Performance)
        if (Time.time - lastTextUpdate >= updateInterval)
        {
            UpdateTimeText(displayedTime);
            lastTextUpdate = Time.time;
        }
        
        // Update Farbe basierend auf verbleibender Zeit
        UpdateTimeColor(displayedTime);
        
        // Warnungs-Effekte
        HandleWarningEffects(displayedTime);
    }
    
    /// <summary>
    /// Aktualisiert den Zeit-Text
    /// </summary>
    private void UpdateTimeText(float time)
    {
        if (timeText == null) return;
        
        // Format: MM:SS.S (mit einer Dezimalstelle für flüssigeres Gefühl)
        int minutes = Mathf.FloorToInt(time / 60f);
        float seconds = time % 60f;
        
        // Verschiedene Formate je nach verbleibender Zeit
        if (time < criticalThreshold)
        {
            // Kritisch: Zeige Dezimalstelle
            timeText.text = string.Format("{0}:{1:00.0}", minutes, seconds);
        }
        else
        {
            // Normal: Ganze Sekunden
            timeText.text = string.Format("{0}:{1:00}", minutes, seconds);
        }
    }
    
    /// <summary>
    /// Aktualisiert die Farbe basierend auf Zeit
    /// </summary>
    private void UpdateTimeColor(float time)
    {
        Color targetColor = normalColor;
        
        if (timeGradient != null && timeGradient.colorKeys.Length > 0)
        {
            // Nutze Gradient wenn vorhanden
            float t = 1f - (time / RiftTimeSystem.Instance.GetMaxTime());
            targetColor = timeGradient.Evaluate(t);
        }
        else
        {
            // Nutze diskrete Farben
            if (time <= criticalThreshold)
                targetColor = criticalColor;
            else if (time <= warningThreshold)
                targetColor = warningColor;
            else
                targetColor = normalColor;
        }
        
        // Setze Farben
        if (timeText != null)
            timeText.color = targetColor;
        
        if (timeBarFill != null)
            timeBarFill.color = targetColor;
    }
    
    /// <summary>
    /// Behandelt Warnungs-Effekte
    /// </summary>
    private void HandleWarningEffects(float time)
    {
        if (time <= criticalThreshold && time > 0)
        {
            // Starte Puls-Effekt wenn noch nicht aktiv
            if (pulseCoroutine == null)
            {
                pulseCoroutine = StartCoroutine(PulseEffect());
            }
        }
        else
        {
            // Stoppe Puls-Effekt
            if (pulseCoroutine != null)
            {
                StopCoroutine(pulseCoroutine);
                pulseCoroutine = null;
                
                // Reset Scale
                if (timeText != null)
                    timeText.transform.localScale = Vector3.one;
            }
        }
    }
    
    /// <summary>
    /// Puls-Effekt für kritische Zeit
    /// </summary>
    private IEnumerator PulseEffect()
    {
        while (true)
        {
            if (timeText != null)
            {
                // Pulsiere Größe
                float scale = 1f + Mathf.Sin(Time.time * pulseSpeed * Mathf.PI) * 0.1f;
                timeText.transform.localScale = Vector3.one * scale;
            }
            
            yield return null;
        }
    }
    
    /// <summary>
    /// Visueller Effekt wenn Zeit gewonnen wird
    /// </summary>
    private void OnTimeGained(float amount)
    {
        // Grüner Flash
        if (timeText != null)
        {
            StartCoroutine(FlashColor(Color.green, 0.5f));
        }
        
        // Popup-Text
        ShowTimePopup($"+{amount:F1}s", Color.green);
    }
    
    /// <summary>
    /// Visueller Effekt wenn Zeit gestohlen wird
    /// </summary>
    private void OnTimeStolen(float amount)
    {
        // Roter Flash
        if (timeText != null)
        {
            StartCoroutine(FlashColor(Color.red, 0.5f));
        }
        
        // Screen Shake
        StartCoroutine(ShakeTimer());
        
        // Popup-Text
        ShowTimePopup($"-{amount:F1}s", Color.red);
    }
    
    /// <summary>
    /// Flash-Effekt für Farbe
    /// </summary>
    private IEnumerator FlashColor(Color flashColor, float duration)
    {
        if (timeText == null) yield break;
        
        Color originalColor = timeText.color;
        float elapsed = 0f;
        
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / duration;
            
            // Flash und zurück
            if (t < 0.5f)
                timeText.color = Color.Lerp(originalColor, flashColor, t * 2f);
            else
                timeText.color = Color.Lerp(flashColor, originalColor, (t - 0.5f) * 2f);
            
            yield return null;
        }
        
        timeText.color = originalColor;
    }
    
    /// <summary>
    /// Shake-Effekt bei Zeitverlust
    /// </summary>
    private IEnumerator ShakeTimer()
    {
        if (timeText == null) yield break;
        
        Vector3 originalPos = timeText.transform.localPosition;
        float shakeDuration = 0.3f;
        float shakeAmount = 10f;
        float elapsed = 0f;
        
        while (elapsed < shakeDuration)
        {
            elapsed += Time.deltaTime;
            
            float x = Random.Range(-shakeAmount, shakeAmount);
            float y = Random.Range(-shakeAmount, shakeAmount);
            
            timeText.transform.localPosition = originalPos + new Vector3(x, y, 0);
            
            yield return null;
        }
        
        timeText.transform.localPosition = originalPos;
    }
    
    /// <summary>
    /// Zeigt Popup für Zeit-Änderungen
    /// </summary>
    private void ShowTimePopup(string text, Color color)
    {
        // TODO: Implementiere floating text popup
        // Für jetzt nur Debug
        Debug.Log($"[TimeDisplay] Popup: {text}");
    }
}
