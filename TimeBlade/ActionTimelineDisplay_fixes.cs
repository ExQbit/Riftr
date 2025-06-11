// TEMPORARY FILE - ActionTimelineDisplay container width fix

// Replace the container validation in Start() method:

// Validiere Container-Setup
if (timelineContainer != null)
{
    // Bei Stretch-Anchors ist sizeDelta irrelevant für die Größe
    // Container wird automatisch durch Parent und Margins dimensioniert
    
    // Stelle sicher, dass das Container eine minimale Größe hat
    RectTransform rect = timelineContainer;
    if (rect.rect.width <= 0 || rect.rect.height <= 0)
    {
        Debug.LogWarning("[ActionTimeline] Container hat negative oder null Größe, setze Fallback-Werte");
        
        // Fallback-Werte für Container-Größe
        rect.anchorMin = new Vector2(0, 0);
        rect.anchorMax = new Vector2(1, 1);
        rect.offsetMin = new Vector2(10, 10);
        rect.offsetMax = new Vector2(-10, -10);
        
        // Force Layout Rebuild
        LayoutRebuilder.ForceRebuildLayoutImmediate(rect);
    }
    
    // Debug-Info zur Kontrolle
    // Debug.Log($"[ActionTimeline] Container Setup: Size={timelineContainer.sizeDelta}, Rect={timelineContainer.rect.size}");
    // Debug.Log($"[ActionTimeline] Container Position: {timelineContainer.anchoredPosition}");
    // Debug.Log($"[ActionTimeline] Container Anchors: Min={timelineContainer.anchorMin}, Max={timelineContainer.anchorMax}");
}
else
{
    Debug.LogError("[ActionTimeline] TimelineContainer nicht gefunden!");
}