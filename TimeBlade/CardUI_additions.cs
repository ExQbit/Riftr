// TEMPORARY FILE - These methods need to be added to CardUI.cs

// Add these fields to the private section:
private bool isDynamicallySelected = false;

// Add this new method:
/// <summary>
/// Setzt die dynamische Selektion (während Touch-Bewegung)
/// </summary>
public void SetDynamicSelection(bool selected)
{
    if (isDynamicallySelected == selected) return;
    
    isDynamicallySelected = selected;
    
    if (selected)
    {
        // Visuelles Feedback für dynamische Selektion
        if (highlightEffect != null)
            highlightEffect.SetActive(true);
        
        // Leichte Vergrößerung ohne Y-Lift für cleaner Look
        LeanTween.cancel(gameObject);
        LeanTween.scale(gameObject, Vector3.one * 1.1f, hoverAnimDuration * 0.8f)
            .setEase(hoverEaseType);
        
        // Leichter Glow-Effekt ohne Alpha-Änderung
        CanvasGroup cg = GetComponent<CanvasGroup>();
        if (cg == null) cg = gameObject.AddComponent<CanvasGroup>();
        
        // Nach vorne bringen für bessere Sichtbarkeit
        transform.SetAsLastSibling();
        
        Debug.Log($"[CardUI] Dynamically selected: {cardData?.cardName}");
    }
    else
    {
        // Zurück zum Normalzustand
        if (highlightEffect != null)
            highlightEffect.SetActive(false);
        
        LeanTween.scale(gameObject, Vector3.one, hoverAnimDuration * 0.8f)
            .setEase(hoverEaseType);
        
        // Zurück zur ursprünglichen Position in der Reihenfolge
        if (originalSiblingIndex >= 0)
            transform.SetSiblingIndex(originalSiblingIndex);
    }
}

/// <summary>
/// Gibt zurück ob die Karte aktuell dynamisch selektiert ist
/// </summary>
public bool IsDynamicallySelected()
{
    return isDynamicallySelected;
}