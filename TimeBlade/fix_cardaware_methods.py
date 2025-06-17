#!/usr/bin/env python3
"""
Fixes für Card-Aware Parallax System - fügt die fehlenden Methoden hinzu
"""

import re
import shutil
from datetime import datetime

def fix_cardaware_methods():
    file_path = '/Users/exqbitmac/TimeBlade/Assets/UI/HandController.cs'
    backup_path = f'{file_path}.backup_methods_{datetime.now().strftime("%Y%m%d_%H%M%S")}'
    
    print("=== Card-Aware Parallax Method Fixer ===")
    print(f"Target file: {file_path}")
    print(f"Creating backup: {backup_path}")
    
    # Backup erstellen
    shutil.copy2(file_path, backup_path)
    print("✓ Backup created")
    
    # Datei einlesen
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Prüfe ob InitializeCardAwareParallax bereits existiert
    if "InitializeCardAwareParallax" in content and "private void InitializeCardAwareParallax" in content:
        print("✓ InitializeCardAwareParallax method already exists")
        return
    
    # Die neuen Methoden
    new_methods = '''
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
'''

    # Finde eine geeignete Stelle zum Einfügen (nach NotifyLastHoveredCardChanged)
    insert_after = "NotifyLastHoveredCardChanged();"
    insert_index = content.find(insert_after)
    
    if insert_index > 0:
        # Finde das Ende der Methode
        method_end = content.find("}", insert_index)
        if method_end > 0:
            # Füge nach der schließenden Klammer ein
            insert_pos = method_end + 1
            content = content[:insert_pos] + "\n" + new_methods + content[insert_pos:]
            print("✓ Added InitializeCardAwareParallax method")
        else:
            print("✗ Could not find suitable insertion point")
    else:
        # Alternative: Suche nach UpdateCardPreview
        update_preview = "private void UpdateCardPreview()"
        preview_index = content.find(update_preview)
        if preview_index > 0:
            # Finde das Ende der UpdateCardPreview Methode
            brace_count = 0
            in_method = False
            for i in range(preview_index, len(content)):
                if content[i] == '{':
                    brace_count += 1
                    in_method = True
                elif content[i] == '}':
                    brace_count -= 1
                    if in_method and brace_count == 0:
                        # Gefunden!
                        content = content[:i+1] + "\n" + new_methods + content[i+1:]
                        print("✓ Added InitializeCardAwareParallax method after UpdateCardPreview")
                        break
    
    # Jetzt UpdateParallaxHandShift ersetzen
    new_update_method = '''    /// <summary>
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
    }'''
    
    # Finde und ersetze UpdateParallaxHandShift
    if "SIMPLE PARALLAX" in content:
        # Finde den Anfang der Methode
        start_pattern = r'/// <summary>\s*\n\s*/// NEUE METHODE: Aktualisiert die Parallax-Verschiebung.*?\n\s*/// Uses SIMPLE ABSOLUTE PARALLAX.*?\n\s*/// </summary>\s*\n\s*private void UpdateParallaxHandShift'
        
        match = re.search(start_pattern, content, re.DOTALL)
        if match:
            # Finde das Ende der Methode
            method_start = match.start()
            brace_count = 0
            in_method = False
            method_end = -1
            
            for i in range(match.end(), len(content)):
                if content[i] == '{':
                    brace_count += 1
                    in_method = True
                elif content[i] == '}':
                    brace_count -= 1
                    if in_method and brace_count == 0:
                        method_end = i + 1
                        break
            
            if method_end > 0:
                content = content[:method_start] + new_update_method + content[method_end:]
                print("✓ Replaced UpdateParallaxHandShift with card-aware version")
            else:
                print("✗ Could not find end of UpdateParallaxHandShift method")
        else:
            print("✗ Could not find UpdateParallaxHandShift pattern")
    
    # Datei speichern
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("\n✓ Methods fixed successfully!")
    print("\nThe card-aware parallax system should now compile without errors.")
    print("\nNext steps:")
    print("1. Return to Unity")
    print("2. Wait for compilation to complete")
    print("3. Set 'Log Parallax Details' to true in HandController Inspector")
    print("4. Test the card-aware parallax system")

if __name__ == "__main__":
    try:
        fix_cardaware_methods()
    except Exception as e:
        print(f"\n✗ Error: {e}")
        print("\nPlease use the manual instructions in:")
        print("/Users/exqbitmac/TimeBlade/manual_patch_instructions.sh")
