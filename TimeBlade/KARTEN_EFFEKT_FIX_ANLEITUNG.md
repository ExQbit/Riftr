# Anleitung: Karten-Effekt-Problem beheben

## Das Problem
Karten werden visuell gespielt, haben aber keine Wirkung auf Gegner, weil die Verbindung zwischen UI (HandController) und Spiellogik (RiftCombatManager) fehlt.

## Die Lösung

### Schritt 1: Finde die Drop-Handler-Methode im HandController

Suche im `HandController.cs` nach einer dieser Methoden:
- `HandleCentralDragEnd`
- `OnPointerUp` 
- `EndDrag`
- Eine Methode die prüft ob `dropSuccessful` oder im `playArea`

### Schritt 2: Füge die fehlende Verbindung hinzu

An der Stelle wo festgestellt wird, dass eine Karte erfolgreich gespielt wurde, füge hinzu:

```csharp
// Beispiel: In der Drop-Handler-Methode
if (dropSuccessful && draggedCard != null)
{
    // Hole die CardUI Komponente
    CardUI cardUI = draggedCard.GetComponent<CardUI>();
    if (cardUI != null && cardUI.GetCardData() != null)
    {
        // KRITISCH: Diese Zeilen fehlen!
        if (RiftCombatManager.Instance != null && ZeitwaechterPlayer.Instance != null)
        {
            // Informiere den CombatManager über die gespielte Karte
            RiftCombatManager.Instance.PlayerWantsToPlayCard(
                cardUI.GetCardData(), 
                ZeitwaechterPlayer.Instance
            );
            
            Debug.Log($"[HandController] Karte '{cardUI.GetCardData().cardName}' an RiftCombatManager übergeben!");
        }
        else
        {
            Debug.LogError("[HandController] RiftCombatManager oder Player Instance ist NULL!");
        }
    }
}
```

### Schritt 3: Alternative - Click-basiertes System

Falls das Drag-System zu komplex ist, kann auch ein einfacher Click-Handler verwendet werden (wie in HandController.cs.fix):

```csharp
private void HandleCardClick(TimeCardData cardData)
{
    if (player != null && RiftCombatManager.Instance != null)
    {
        // Versuche Karte zu spielen
        RiftCombatManager.Instance.PlayerWantsToPlayCard(cardData, player);
    }
}
```

Und in `CreateCardUI`:
```csharp
cardUIComponent.OnCardClicked += HandleCardClick;
```

## Was passiert dann?

Nach dieser Änderung wird folgender Flow ablaufen:

1. **Spieler spielt Karte** (Drag & Drop oder Click)
2. **HandController** ruft `RiftCombatManager.PlayerWantsToPlayCard()` auf
3. **RiftCombatManager**:
   - Prüft ob genug Zeit vorhanden ist
   - Zieht Zeit ab
   - Ruft `ExecuteCardEffect()` auf
4. **ExecuteCardEffect**:
   - Bei Angriffskarten: `target.TakeDamage(damage)`
   - Bei Verteidigungskarten: Block aktivieren
   - Bei Zeitkarten: Zeit manipulieren
5. **RiftEnemy.TakeDamage()**:
   - HP reduzieren
   - Animation abspielen
   - Bei 0 HP: Gegner stirbt

## Debug-Logs zum Testen

Nach der Implementierung sollten folgende Logs erscheinen:

```
[HandController] Karte 'Schwertschlag' an RiftCombatManager übergeben!
[RiftCombat] Führe Schwertschlag aus. Ziel: TutorialEnemy
[RiftCombat] Schwertschlag fügt 3 Schaden zu!
[RiftEnemy] TutorialEnemy nimmt 3 Schaden. HP: 7/10
```

## Wichtige Dateien

- **HandController.cs** - Hier muss die Änderung gemacht werden
- **RiftCombatManager.cs** - Zeile 364: `PlayerWantsToPlayCard()` (bereits implementiert)
- **RiftEnemy.cs** - Zeile 147: `TakeDamage()` (bereits implementiert)
- **HandController.cs.fix** - Zeile 177: Referenz-Implementierung

## Zusammenfassung

Die gesamte Karten-Effekt-Kette ist bereits implementiert, es fehlt nur der eine Aufruf von `RiftCombatManager.Instance.PlayerWantsToPlayCard()` im HandController nach einem erfolgreichen Karten-Drop oder Click.