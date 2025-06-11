using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;

/// <summary>
/// Einzelnes Item auf der Action-Timeline
/// Verwaltet die Anzeige einer einzelnen Gegneraktion
/// </summary>
public class ActionTimelineItem : MonoBehaviour
{
    [Header("UI-Elemente")]
    [SerializeField] private Image background;
    [SerializeField] private Image icon;
    [SerializeField] private TextMeshProUGUI enemyNameText;
    [SerializeField] private TextMeshProUGUI actionNameText;
    [SerializeField] private TextMeshProUGUI timerText;
    [SerializeField] private Image urgencyIndicator;
    
    private RiftEnemy trackedEnemy;
    private Color actionColor;
    private float pulseStartTime;
    private bool isPulsing = false;
    
    /// <summary>
    /// Setzt den zu trackenden Gegner
    /// </summary>
    public void SetEnemy(RiftEnemy enemy)
    {
        trackedEnemy = enemy;
        
        if (enemyNameText != null)
            enemyNameText.text = enemy.name;
            
        if (actionNameText != null)
            actionNameText.text = enemy.GetActionDescription();
    }
    
    /// <summary>
    /// Setzt die Aktionsfarbe
    /// </summary>
    public void SetActionColor(Color color)
    {
        actionColor = color;
        
        if (background != null)
        {
            background.color = new Color(color.r, color.g, color.b, 0.7f);
        }
        
        if (icon != null)
        {
            icon.color = color;
        }
    }
    
    /// <summary>
    /// Aktualisiert die Anzeige
    /// </summary>
    public void UpdateDisplay(float remainingTime)
    {
        // Timer
        if (timerText != null)
        {
            timerText.text = $"{remainingTime:F1}s";
            
            // Farbe basierend auf Dringlichkeit
            if (remainingTime < 1f)
            {
                timerText.color = Color.red;
            }
            else if (remainingTime < 3f)
            {
                timerText.color = Color.yellow;
            }
            else
            {
                timerText.color = Color.white;
            }
        }
        
        // Dringlichkeits-Indikator
        if (urgencyIndicator != null)
        {
            if (remainingTime < 2f)
            {
                urgencyIndicator.gameObject.SetActive(true);
                
                // Starte Pulsierung wenn noch nicht aktiv
                if (!isPulsing)
                {
                    isPulsing = true;
                    pulseStartTime = Time.time;
                    StartCoroutine(PulseUrgencyIndicator());
                }
            }
            else
            {
                urgencyIndicator.gameObject.SetActive(false);
                isPulsing = false;
            }
        }
        
        // Skalierung basierend auf Nähe
        // HINWEIS: Bei VerticalLayoutGroup sollte Skalierung vermieden werden
        // da sie das Layout durcheinander bringen kann
        // Stattdessen nutzen wir visuelle Hervorhebung durch Farben und Effekte
        
        // Optional: Leichte Skalierung nur für den Inhalt, nicht das ganze Transform
        /*
        float scale = 1f;
        if (remainingTime < 3f)
        {
            scale = 1f + (3f - remainingTime) * 0.1f; // Bis zu 30% größer
        }
        transform.localScale = Vector3.one * scale;
        */
    }
    
    /// <summary>
    /// Pulsierender Effekt für den Dringlichkeits-Indikator
    /// </summary>
    private IEnumerator PulseUrgencyIndicator()
    {
        while (isPulsing && urgencyIndicator != null)
        {
            float elapsed = Time.time - pulseStartTime;
            float pulse = Mathf.PingPong(elapsed * 3f, 1f);
            urgencyIndicator.color = new Color(1f, 0f, 0f, pulse);
            yield return null;
        }
    }
    
    void OnDestroy()
    {
        // Stelle sicher dass alle Coroutines gestoppt werden
        StopAllCoroutines();
    }
}