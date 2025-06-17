#!/usr/bin/env python3
"""
Simpler Ansatz: Fügt die fehlenden Methoden am Ende der HandController Klasse ein
"""

import shutil
from datetime import datetime

def add_missing_methods():
    file_path = '/Users/exqbitmac/TimeBlade/Assets/UI/HandController.cs'
    backup_path = f'{file_path}.backup_simple_{datetime.now().strftime("%Y%m%d_%H%M%S")}'
    
    print("=== Simple Method Adder for Card-Aware Parallax ===")
    
    # Backup erstellen
    shutil.copy2(file_path, backup_path)
    print("✓ Backup created")
    
    # Datei einlesen
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Prüfe ob die Methoden bereits existieren
    if "private void InitializeCardAwareParallax" in content:
        print("✓ Methods already exist!")
        return
    
    # Die fehlenden Methoden
    methods_to_add = '''
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

    // REPLACEMENT FOR UpdateParallaxHandShift - DELETE THE OLD ONE AND USE THIS
    /// <summary>
    /// NEUE METHODE: Aktualisiert die Parallax-Verschiebung der Hand basierend auf Finger-Position
    /// Verwendet CARD-AWARE PARALLAX: Berücksichtigt welche Karte initial berührt wurde
    /// </summary>
    private void UpdateParallaxHandShift_CardAware(Vector2 position)
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
'''
    
    # Finde die letzte schließende Klammer der HandController Klasse
    last_brace = content.rfind("}")
    if last_brace > 0:
        # Füge die Methoden vor der letzten Klammer ein
        content = content[:last_brace] + methods_to_add + "\n" + content[last_brace:]
        print("✓ Added missing methods to HandController")
    else:
        print("✗ Could not find insertion point")
        return
    
    # Jetzt müssen wir noch den Aufruf von UpdateParallaxHandShift ändern
    # Suche nach dem Aufruf in HandleTouchMove
    old_call = "UpdateParallaxHandShift(position);"
    new_call = "UpdateParallaxHandShift_CardAware(position);"
    
    if old_call in content:
        content = content.replace(old_call, new_call)
        print("✓ Updated method call to use card-aware version")
    
    # Datei speichern
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("\n✓ All changes applied successfully!")
    print("\nIMPORTANT: You still need to:")
    print("1. Delete or rename the old UpdateParallaxHandShift method")
    print("2. Rename UpdateParallaxHandShift_CardAware to UpdateParallaxHandShift")
    print("\nOr simply replace the content of the old method with the new one.")

if __name__ == "__main__":
    try:
        add_missing_methods()
    except Exception as e:
        print(f"\n✗ Error: {e}")
