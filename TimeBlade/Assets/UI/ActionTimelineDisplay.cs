using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;
using System.Linq;

/// <summary>
/// Zeigt eine vertikale Timeline aller geplanten Gegneraktionen
/// </summary>
public class ActionTimelineDisplay : MonoBehaviour
{
    [Header("UI-Referenzen")]
    [SerializeField] private RectTransform timelineContainer;
    [SerializeField] private GameObject actionItemPrefab; // Prefab für einzelne Aktionen
    [SerializeField] private float timelineRange = 10f; // Zeitbereich in Sekunden
    
    [Header("Visuelle Einstellungen")]
    [SerializeField] private Color timeStealColor = new Color(1f, 0.3f, 0.3f);
    [SerializeField] private Color doubleStrikeColor = new Color(0.8f, 0.2f, 0.2f);
    [SerializeField] private Color defendColor = new Color(0.3f, 0.5f, 1f);
    [SerializeField] private Color buffColor = new Color(0.3f, 1f, 0.3f);
    [SerializeField] private Color specialColor = new Color(1f, 0.8f, 0.2f);
    
    [Header("Update-Einstellungen")]
    [SerializeField] private float updateInterval = 0.1f; // Update alle 100ms
    
    // Tracking von aktiven ActionItems
    private Dictionary<RiftEnemy, ActionTimelineItem> activeItems = new Dictionary<RiftEnemy, ActionTimelineItem>();
    private float lastUpdateTime = 0f;
    
    void Start()
    {
        if (timelineContainer == null)
            timelineContainer = GetComponent<RectTransform>();
            
        // Validiere Container-Setup
        if (timelineContainer != null)
        {
            // Setup für VerticalLayoutGroup Container
            RectTransform rect = timelineContainer;
            
            // Füge VerticalLayoutGroup hinzu falls nicht vorhanden
            VerticalLayoutGroup layoutGroup = rect.GetComponent<VerticalLayoutGroup>();
            if (layoutGroup == null)
            {
                layoutGroup = rect.gameObject.AddComponent<VerticalLayoutGroup>();
                layoutGroup.spacing = 5f;
                layoutGroup.padding = new RectOffset(10, 10, 10, 10);
                layoutGroup.childAlignment = TextAnchor.UpperCenter;
                layoutGroup.childControlHeight = false;
                layoutGroup.childControlWidth = true;
                layoutGroup.childForceExpandHeight = false;
                layoutGroup.childForceExpandWidth = false;
            }
            
            // Prüfe und korrigiere RectTransform-Einstellungen
            // Negative sizeDelta bedeutet, dass die Anchors auf Stretch gesetzt sind
            if (rect.anchorMin == new Vector2(0, 0) && rect.anchorMax == new Vector2(1, 1))
            {
                // Bei Stretch-Anchors: offsetMin/Max steuern die Margins
                // Negative offsetMax-Werte sind korrekt (Abstand vom rechten/oberen Rand)
                // Stelle sicher, dass die Werte positiv für offsetMin sind
                if (rect.offsetMin.x < 0 || rect.offsetMin.y < 0)
                {
                    rect.offsetMin = new Vector2(10, 10);  // 10 Pixel Margin von links/unten
                }
                if (rect.offsetMax.x > -10 || rect.offsetMax.y > -10)
                {
                    rect.offsetMax = new Vector2(-10, -10); // 10 Pixel Margin von rechts/oben
                }
                rect.anchoredPosition = Vector2.zero;
            }
            else
            {
                // Falls keine Stretch-Anchors: Setze sie für korrektes Layout
                rect.anchorMin = new Vector2(0, 0);
                rect.anchorMax = new Vector2(1, 1);
                rect.offsetMin = new Vector2(10, 10);
                rect.offsetMax = new Vector2(-10, -10);
                rect.anchoredPosition = Vector2.zero;
            }
            
            // ContentSizeFitter für automatische Höhenanpassung
            ContentSizeFitter sizeFitter = rect.GetComponent<ContentSizeFitter>();
            if (sizeFitter == null)
            {
                sizeFitter = rect.gameObject.AddComponent<ContentSizeFitter>();
            }
            sizeFitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            sizeFitter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            
            // Force Layout Rebuild
            LayoutRebuilder.ForceRebuildLayoutImmediate(rect);
            
            // Debug-Info zur Kontrolle
            // Debug.Log($"[ActionTimeline] Container Setup: Rect={timelineContainer.rect}, World corners: {GetWorldCorners(rect)}");
            // Debug.Log($"[ActionTimeline] Container Anchors: Min={rect.anchorMin}, Max={rect.anchorMax}");
            // Debug.Log($"[ActionTimeline] Container Offsets: Min={rect.offsetMin}, Max={rect.offsetMax}");
        }
        else
        {
            Debug.LogError("[ActionTimeline] TimelineContainer nicht gefunden!");
        }
            
        // Events abonnieren
        if (EnemyFocusSystem.Instance != null)
        {
            EnemyFocusSystem.OnEnemyAddedToQueue += OnEnemyAdded;
            EnemyFocusSystem.OnEnemyRemovedFromQueue += OnEnemyRemoved;
        }
        
        // Initial Update
        RefreshTimeline();
    }
    
    void Update()
    {
        // Update nur in Intervallen für Performance
        if (Time.time - lastUpdateTime > updateInterval)
        {
            UpdateTimelinePositions();
            lastUpdateTime = Time.time;
        }
    }
    
    /// <summary>
    /// Aktualisiert die gesamte Timeline
    /// </summary>
    void RefreshTimeline()
    {
        // Hole alle aktiven Gegner
        if (EnemyFocusSystem.Instance == null) return;
        
        var allEnemies = new List<RiftEnemy>();
        
        // Füge aktuelles Ziel hinzu
        var currentTarget = EnemyFocusSystem.Instance.GetCurrentTarget();
        if (currentTarget != null && !currentTarget.IsDead())
        {
            allEnemies.Add(currentTarget);
        }
        
        // Füge alle Gegner aus der Queue hinzu
        allEnemies.AddRange(EnemyFocusSystem.Instance.GetEnemyQueue().Where(e => e != null && !e.IsDead()));
        
        // Entferne Duplikate
        allEnemies = allEnemies.Distinct().ToList();
        
        // Aktualisiere oder erstelle Items für jeden Gegner
        foreach (var enemy in allEnemies)
        {
            if (!activeItems.ContainsKey(enemy))
            {
                CreateActionItem(enemy);
            }
        }
        
        // Entferne Items für nicht mehr aktive Gegner
        var enemiesToRemove = activeItems.Keys.Where(e => !allEnemies.Contains(e)).ToList();
        foreach (var enemy in enemiesToRemove)
        {
            RemoveActionItem(enemy);
        }
        
        UpdateTimelinePositions();
    }
    
    /// <summary>
    /// Erstellt ein neues Action-Item für einen Gegner
    /// </summary>
    void CreateActionItem(RiftEnemy enemy)
    {
        if (actionItemPrefab == null) return;
        
        GameObject itemObj = Instantiate(actionItemPrefab, timelineContainer);
        ActionTimelineItem item = itemObj.GetComponent<ActionTimelineItem>();
        
        if (item == null)
        {
            Debug.LogError("[ActionTimelineDisplay] ActionTimelineItem component missing on prefab!");
            Destroy(itemObj);
            return;
        }
        
        // Stelle sicher, dass das Item korrekt als Kind des Containers gesetzt ist
        RectTransform itemRect = itemObj.GetComponent<RectTransform>();
        if (itemRect != null)
        {
            // Reset transform values für LayoutGroup-Kompatibilität
            itemRect.localScale = Vector3.one;
            
            // Für VerticalLayoutGroup: Items brauchen korrekte Anchor-Einstellungen
            // Top-Stretch anchors für volle Breite
            itemRect.anchorMin = new Vector2(0, 1);  // Top-Left
            itemRect.anchorMax = new Vector2(1, 1);  // Top-Right  
            itemRect.pivot = new Vector2(0.5f, 0.5f);  // Center pivot für bessere Skalierung
            
            // Position und Size werden vom LayoutGroup verwaltet
            itemRect.anchoredPosition = Vector2.zero;
            itemRect.sizeDelta = new Vector2(0, 60); // Nur Höhe setzen, Breite wird gestreckt
            
            // Layout Element für präzise Größenkontrolle
            LayoutElement layoutElement = itemObj.GetComponent<LayoutElement>();
            if (layoutElement == null)
            {
                layoutElement = itemObj.AddComponent<LayoutElement>();
            }
            layoutElement.minHeight = 60;
            layoutElement.preferredHeight = 60;
            layoutElement.flexibleWidth = 1f; // Nutze verfügbare Breite
            
            // Stelle sicher, dass das Item aktiv ist
            itemObj.SetActive(true);
        }
        
        item.SetEnemy(enemy);
        item.SetActionColor(GetActionColor(enemy.GetNextAction()));
        
        activeItems[enemy] = item;
        
        // Event abonnieren
        enemy.OnNextActionChanged += OnEnemyActionChanged;
    }
    
    /// <summary>
    /// Entfernt ein Action-Item
    /// </summary>
    void RemoveActionItem(RiftEnemy enemy)
    {
        if (activeItems.ContainsKey(enemy))
        {
            var item = activeItems[enemy];
            if (item != null && item.gameObject != null)
            {
                Destroy(item.gameObject);
            }
            activeItems.Remove(enemy);
            
            // Event abmelden
            enemy.OnNextActionChanged -= OnEnemyActionChanged;
        }
    }
    
    /// <summary>
    /// Aktualisiert die Reihenfolge und Sichtbarkeit der Items auf der Timeline
    /// </summary>
    void UpdateTimelinePositions()
    {
        // Sammle alle Items mit ihrer Zeit
        var itemsWithTime = new List<System.Tuple<ActionTimelineItem, float>>();
        
        foreach (var kvp in activeItems)
        {
            var enemy = kvp.Key;
            var item = kvp.Value;
            
            if (enemy == null || item == null) continue;
            
            float remainingTime = enemy.GetRemainingActionTime();
            
            // Update Item-Anzeige
            item.UpdateDisplay(remainingTime);
            
            // Verstecke Items außerhalb des Zeitbereichs oder wenn Zeit abgelaufen
            bool shouldShow = remainingTime > 0 && remainingTime <= timelineRange;
            item.gameObject.SetActive(shouldShow);
            
            if (shouldShow)
            {
                itemsWithTime.Add(new System.Tuple<ActionTimelineItem, float>(item, remainingTime));
            }
        }
        
        // Sortiere Items nach verbleibender Zeit (niedrigste Zeit = höchste Priorität = oben)
        itemsWithTime.Sort((a, b) => a.Item2.CompareTo(b.Item2));
        
        // Setze Sibling-Index für korrekte Reihenfolge im VerticalLayoutGroup
        for (int i = 0; i < itemsWithTime.Count; i++)
        {
            itemsWithTime[i].Item1.transform.SetSiblingIndex(i);
        }
        
        // Force Layout Rebuild für sofortige Aktualisierung
        LayoutRebuilder.ForceRebuildLayoutImmediate(timelineContainer);
    }
    
    /// <summary>
    /// Gibt die Farbe für einen Aktionstyp zurück
    /// </summary>
    Color GetActionColor(EnemyActionType actionType)
    {
        switch (actionType)
        {
            case EnemyActionType.TimeSteal:
                return timeStealColor;
            case EnemyActionType.DoubleStrike:
                return doubleStrikeColor;
            case EnemyActionType.Defend:
                return defendColor;
            case EnemyActionType.Buff:
                return buffColor;
            case EnemyActionType.Special:
                return specialColor;
            default:
                return Color.white;
        }
    }
    
    /// <summary>
    /// Callback wenn ein Gegner hinzugefügt wird
    /// </summary>
    void OnEnemyAdded(RiftEnemy enemy)
    {
        RefreshTimeline();
    }
    
    /// <summary>
    /// Callback wenn ein Gegner entfernt wird
    /// </summary>
    void OnEnemyRemoved(RiftEnemy enemy)
    {
        RemoveActionItem(enemy);
    }
    
    /// <summary>
    /// Callback wenn sich die Aktion eines Gegners ändert
    /// </summary>
    void OnEnemyActionChanged(EnemyActionType newAction, float remainingTime)
    {
        RefreshTimeline();
    }
    
    /// <summary>
    /// Hilfsmethode um die World-Corners eines RectTransforms zu erhalten
    /// </summary>
    string GetWorldCorners(RectTransform rectTransform)
    {
        Vector3[] corners = new Vector3[4];
        rectTransform.GetWorldCorners(corners);
        return $"BL:{corners[0]}, TL:{corners[1]}, TR:{corners[2]}, BR:{corners[3]}";
    }
    
    void OnDestroy()
    {
        // Events abmelden
        if (EnemyFocusSystem.Instance != null)
        {
            EnemyFocusSystem.OnEnemyAddedToQueue -= OnEnemyAdded;
            EnemyFocusSystem.OnEnemyRemovedFromQueue -= OnEnemyRemoved;
        }
        
        // Alle Enemy-Events abmelden
        foreach (var enemy in activeItems.Keys)
        {
            if (enemy != null)
            {
                enemy.OnNextActionChanged -= OnEnemyActionChanged;
            }
        }
    }
}

