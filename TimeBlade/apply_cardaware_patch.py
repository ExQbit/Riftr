#!/usr/bin/env python3
"""
Automatisches Patch-Script für Card-Aware Parallax System
"""

import re
import shutil
from datetime import datetime

def apply_cardaware_patch():
    file_path = '/Users/exqbitmac/TimeBlade/Assets/UI/HandController.cs'
    backup_path = f'{file_path}.backup_{datetime.now().strftime("%Y%m%d_%H%M%S")}'
    
    print("=== Card-Aware Parallax Auto-Patcher ===")
    print(f"Target file: {file_path}")
    print(f"Creating backup: {backup_path}")
    
    # Backup erstellen
    shutil.copy2(file_path, backup_path)
    print("✓ Backup created")
    
    # Datei einlesen
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Neue Variablen hinzufügen
    parallax_vars = """    private float touchStartTime = 0f; // Time when touch started (for reduced parallax sensitivity)
    private float lastHoverChangeTime = 0f; // Time of last hover change (for throttling)"""
    
    new_vars = """    private float touchStartTime = 0f; // Time when touch started (for reduced parallax sensitivity)
    private float lastHoverChangeTime = 0f; // Time of last hover change (for throttling)
    
    // Card-aware parallax variables
    private float initialCardNormalizedPosition = 0.5f; // 0=left, 1=right
    private float initialHandOffsetForCard = 0f; // The offset the hand should have for the touched card
    private float maxAllowedLeftMovement = 0f; // How much the hand can move left from initial
    private float maxAllowedRightMovement = 0f; // How much the hand can move right from initial"""
    
    if "// Card-aware parallax variables" not in content:
        content = content.replace(parallax_vars, new_vars)
        print("✓ Added card-aware parallax variables")
    else:
        print("- Card-aware parallax variables already exist")
    
    # 2. InitializeCardAwareParallax Aufruf hinzufügen
    touch_init = """                touchStartScreenPos = position;"""
    touch_init_new = """                touchStartScreenPos = position;
                
                // CARD-AWARE PARALLAX: Initialize based on touched card position
                InitializeCardAwareParallax(touchedCard);"""
    
    if "InitializeCardAwareParallax(touchedCard)" not in content:
        content = content.replace(touch_init, touch_init_new)
        print("✓ Added InitializeCardAwareParallax call")
    else:
        print("- InitializeCardAwareParallax call already exists")
    
    # 3. Neue Methoden einfügen (vor UpdateParallaxHandShift)
    new_methods = """
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
    """
    
    # 4. UpdateParallaxHandShift ersetzen
    # Finde die alte Methode
    old_method_pattern = r'/// <summary>\s*\n\s*/// NEUE METHODE: Aktualisiert die Parallax-Verschiebung.*?\n.*?private void UpdateParallaxHandShift\(Vector2 position\).*?\n\s*\{[^}]*LogInfo\(\$"SIMPLE PARALLAX:.*?\}\s*\n\s*\}'
    
    new_method = """/// <summary>
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
    }"""
    
    # Suche nach UpdateParallaxHandShift und füge InitializeCardAwareParallax davor ein
    if "InitializeCardAwareParallax" not in content:
        # Finde UpdateParallaxHandShift
        update_parallax_index = content.find("private void UpdateParallaxHandShift(Vector2 position)")
        if update_parallax_index > 0:
            # Gehe zurück zum Anfang der Methoden-Dokumentation
            doc_start = content.rfind("/// <summary>", 0, update_parallax_index)
            # Füge neue Methode davor ein
            content = content[:doc_start] + new_methods + "\n\n    " + content[doc_start:]
            print("✓ Added InitializeCardAwareParallax method")
        else:
            print("✗ Could not find UpdateParallaxHandShift method")
    
    # Ersetze die alte UpdateParallaxHandShift Methode
    matches = list(re.finditer(old_method_pattern, content, re.DOTALL | re.MULTILINE))
    if matches:
        print(f"Found {len(matches)} occurrences of old UpdateParallaxHandShift")
        # Ersetze von hinten nach vorne, um Indizes nicht zu verschieben
        for match in reversed(matches):
            content = content[:match.start()] + new_method + content[match.end():]
        print("✓ Replaced UpdateParallaxHandShift with card-aware version")
    else:
        print("✗ Could not find old UpdateParallaxHandShift pattern")
        print("  Trying simpler replacement...")
        
        # Vereinfachter Ansatz
        if "SIMPLE PARALLAX" in content:
            # Finde die Methode durch Suche nach charakteristischen Strings
            simple_start = content.find("/// NEUE METHODE: Aktualisiert die Parallax-Verschiebung")
            if simple_start > 0:
                # Finde das Ende der Methode
                method_start = content.find("private void UpdateParallaxHandShift", simple_start)
                if method_start > 0:
                    # Finde die schließende geschweifte Klammer
                    brace_count = 0
                    in_method = False
                    for i in range(method_start, len(content)):
                        if content[i] == '{':
                            brace_count += 1
                            in_method = True
                        elif content[i] == '}':
                            brace_count -= 1
                            if in_method and brace_count == 0:
                                # Gefunden!
                                content = content[:simple_start] + new_method + content[i+1:]
                                print("✓ Replaced UpdateParallaxHandShift (simple method)")
                                break
    
    # Datei speichern
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("\n✓ Patch applied successfully!")
    print("\nNext steps:")
    print("1. Open Unity")
    print("2. In HandController Inspector, set 'Log Parallax Details' to true")
    print("3. Test the card-aware parallax system")
    print("\nExpected behavior:")
    print("- Touch right card + swipe right = NO movement (already at max)")
    print("- Touch left card + swipe left = NO movement (already at max)")
    print("- Touch middle card = symmetric movement in both directions")

if __name__ == "__main__":
    try:
        apply_cardaware_patch()
    except Exception as e:
        print(f"\n✗ Error: {e}")
        print("\nPlease apply the patch manually using the instructions in:")
        print("/Users/exqbitmac/TimeBlade/apply_cardaware_patch.sh")
