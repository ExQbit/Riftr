#!/bin/bash
# Manuelles Patch-Skript für card-aware parallax

echo "=== Manuelle Anleitung zum Hinzufügen der Card-Aware Parallax Methoden ==="
echo ""
echo "WICHTIG: Die Variablen wurden bereits hinzugefügt, aber die Methoden fehlen noch."
echo ""
echo "Öffne /Users/exqbitmac/TimeBlade/Assets/UI/HandController.cs in deinem Editor"
echo ""
echo "SCHRITT 1: Finde die Zeile mit 'UpdateCardPreview()' (ca. Zeile 2470)"
echo ""
echo "SCHRITT 2: Füge NACH der UpdateCardPreview() Methode folgende zwei Methoden ein:"
echo ""
echo "================================ KOPIERE AB HIER ================================"
cat << 'EOF'
    
    /// <summary>
    /// Initialisiert das card-aware Parallax System basierend auf der berührten Karte
    /// </summary>
    private void InitializeCardAwareParallax(CardUI touchedCard)
    {
        const float FIXED_MAX_OFFSET = 250f;
        
        if (touchedCard == null || activeCardUIs.Count == 0)
        {
            // Fallback: Kein Karten-Kontext, verwende symmetrisches System
            initialCardNormalizedPosition = 0.5f;
            initialHandOffsetForCard = 0f;
            maxAllowedLeftMovement = FIXED_MAX_OFFSET;
            maxAllowedRightMovement = FIXED_MAX_OFFSET;
            LogInfo("CARD-AWARE PARALLAX: No card touched, using symmetric limits", logParallaxDetails);
            return;
        }
        
        // Finde die Position der berührten Karte im Fächer (0=links, 1=rechts)
        int touchedCardIndex = -1;
        for (int i = 0; i < activeCardUIs.Count; i++)
        {
            var cardUI = activeCardUIs[i].GetComponent<CardUI>();
            if (cardUI == touchedCard)
            {
                touchedCardIndex = i;
                break;
            }
        }
        
        if (touchedCardIndex == -1)
        {
            // Fallback
            initialCardNormalizedPosition = 0.5f;
            initialHandOffsetForCard = 0f;
            maxAllowedLeftMovement = FIXED_MAX_OFFSET;
            maxAllowedRightMovement = FIXED_MAX_OFFSET;
            return;
        }
        
        // Berechne normalisierte Position (0=ganz links, 1=ganz rechts)
        int cardCount = activeCardUIs.Count;
        initialCardNormalizedPosition = cardCount > 1 ? (float)touchedCardIndex / (cardCount - 1) : 0.5f;
        
        // Berechne den initialen Hand-Offset basierend auf Kartenposition
        // Linke Karte (0) → Hand sollte rechts sein (+maxOffset)
        // Rechte Karte (1) → Hand sollte links sein (-maxOffset)
        initialHandOffsetForCard = Mathf.Lerp(FIXED_MAX_OFFSET, -FIXED_MAX_OFFSET, initialCardNormalizedPosition);
        
        // Berechne erlaubte Bewegungsgrenzen
        // Wenn wir die rechte Karte berühren (Hand ist links), können wir nur nach rechts
        // Wenn wir die linke Karte berühren (Hand ist rechts), können wir nur nach links
        maxAllowedLeftMovement = initialHandOffsetForCard - (-FIXED_MAX_OFFSET); // Wie viel nach links möglich
        maxAllowedRightMovement = FIXED_MAX_OFFSET - initialHandOffsetForCard; // Wie viel nach rechts möglich
        
        // Setze die Hand sofort auf die korrekte Position für die berührte Karte
        currentHandOffset = initialHandOffsetForCard;
        RectTransform containerRect = handContainer.GetComponent<RectTransform>();
        if (containerRect != null)
        {
            Vector3 pos = containerRect.localPosition;
            pos.x = currentHandOffset;
            containerRect.localPosition = pos;
        }
        
        LogInfo($"CARD-AWARE PARALLAX INIT: Card {touchedCardIndex}/{cardCount-1} (norm={initialCardNormalizedPosition:F2}), " +
               $"initial offset={initialHandOffsetForCard:F1}, allowed movement: left={maxAllowedLeftMovement:F1}, right={maxAllowedRightMovement:F1}", 
               logParallaxDetails);
    }
EOF
echo "================================ KOPIERE BIS HIER ================================"
echo ""
echo "SCHRITT 3: Finde die UpdateParallaxHandShift Methode (suche nach 'SIMPLE PARALLAX')"
echo ""
echo "SCHRITT 4: ERSETZE die KOMPLETTE UpdateParallaxHandShift Methode mit dieser Version:"
echo ""
echo "================================ KOPIERE AB HIER ================================"
cat << 'EOF'
    /// <summary>
    /// NEUE METHODE: Aktualisiert die Parallax-Verschiebung der Hand basierend auf Finger-Position
    /// Verwendet CARD-AWARE PARALLAX: Berücksichtigt welche Karte initial berührt wurde
    /// </summary>
    private void UpdateParallaxHandShift(Vector2 position)
    {
        if (!isParallaxActive || !isFanned) return;
        
        // CARD-AWARE PARALLAX
        // Berechne Finger-Bewegung vom Start
        float fingerMovement = position.x - startTouchPosition.x;
        
        // Bestimme erlaubte Bewegung basierend auf Richtung
        float allowedMovement = 0f;
        
        if (fingerMovement > 0) 
        {
            // Finger bewegt sich nach rechts → Hand soll nach links
            // Aber nur wenn wir noch nicht am linken Limit sind
            allowedMovement = Mathf.Min(fingerMovement, maxAllowedLeftMovement / parallaxSensitivity);
        }
        else 
        {
            // Finger bewegt sich nach links → Hand soll nach rechts
            // Aber nur wenn wir noch nicht am rechten Limit sind
            allowedMovement = Mathf.Max(fingerMovement, -maxAllowedRightMovement / parallaxSensitivity);
        }
        
        // Wende die erlaubte Bewegung an (invertiert: Finger rechts = Hand links)
        float targetHandOffset = initialHandOffsetForCard - (allowedMovement * parallaxSensitivity * 0.3f);
        
        // Finale Sicherheitsbegrenzung
        const float FIXED_MAX_OFFSET = 250f;
        targetHandOffset = Mathf.Clamp(targetHandOffset, -FIXED_MAX_OFFSET, FIXED_MAX_OFFSET);
        
        // DIRECT UPDATE - no smoothing
        currentHandOffset = targetHandOffset;
        
        // Update container position
        RectTransform containerRect = handContainer.GetComponent<RectTransform>();
        if (containerRect != null)
        {
            Vector3 pos = containerRect.localPosition;
            pos.x = currentHandOffset;
            containerRect.localPosition = pos;
        }
        
        LogInfo($"CARD-AWARE PARALLAX: finger=({position.x:F1}), movement={fingerMovement:F1}, " +
               $"allowed={allowedMovement:F1}, offset={currentHandOffset:F1} (from initial {initialHandOffsetForCard:F1})", 
               logParallaxDetails);
    }
EOF
echo "================================ KOPIERE BIS HIER ================================"
echo ""
echo "SCHRITT 5: Speichere die Datei und kehre zu Unity zurück"
echo ""
echo "Die Fehler sollten jetzt verschwunden sein!"
