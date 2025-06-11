# 🎯 Zentrale Drag-System Dokumentation

## 📋 Übersicht

Das Drag-System wurde komplett umgebaut, um ein wichtiges UX-Problem zu lösen:

**Problem:** Unity's Event System sendet `OnBeginDrag/OnDrag/OnEndDrag` Events immer an die Karte, wo der Touch **begonnen** hat - nicht an die Karte, über der sich der Finger **aktuell** befindet.

**Lösung:** Vollständig zentralisiertes Drag-System im `HandController`, das die Karte unter dem aktuellen Finger verfolgt und diese korrekt draggt.

---

## 🔄 Workflow Vergleich

### ❌ Altes System (Problem)
1. Finger auf **Karte A** (Schildschlag)
2. Finger zu **Karte B** bewegen (Schwertschlag) 
3. Nach oben ziehen
4. **Resultat:** Karte A wird visuell gezogen, aber Karte B wird gespielt → Verwirrend!

### ✅ Neues System (Lösung)
1. Finger auf **Karte A** (Schildschlag)
2. Finger zu **Karte B** bewegen (Schwertschlag)
3. Nach oben ziehen  
4. **Resultat:** Karte B wird visuell gezogen UND gespielt → Korrekt!

---

## 🏗️ Architektur

### HandController.cs - Zentrale Verwaltung
**Neue Variablen:**
```csharp
private bool isDraggingActive = false;        // Zentrales Drag-Flag
private Vector2 dragStartPosition;            // Wo der Touch begann (für Schwellenwert)
private Vector2 lastDragPosition;             // Letzte bekannte Drag-Position  
private CardUI draggedCardUI = null;          // Die aktuell gedraggte Karte (CardUI Referenz)
private float dragThreshold = 30f;            // Pixel für Drag-Erkennung
private float minVerticalSwipe = 15f;         // Minimale vertikale Bewegung
```

**Zentrale Methoden:**
- `HandleTouchMove()` - Kontinuierliche Finger-Verfolgung
- `StartDragOperation()` - Startet Drag mit der gehöverten Karte  
- `MoveDraggedCardToPosition()` - Bewegt gedraggte Karte zum Finger
- `EndDragOperation()` - Entscheidet Spielen vs. Zurück-zur-Hand
- `PlayDraggedCard()` - Spielt die gedraggte Karte
- `ReturnDraggedCardToHand()` - Gibt Karte zur Hand zurück

### CardUI.cs - Vereinfacht
**Entfernt:**
- `IBeginDragHandler, IDragHandler, IEndDragHandler` Interfaces
- Komplexe eigene Drag-Schwellenwert-Logik
- Eigene Positions-Verfolgung  
- Direkte Karten-Spiel-Logik

**Hinzugefügt:**
```csharp
public void OnCentralDragStart()              // Wird vom HandController aufgerufen
public void OnCentralDragEnd()                // Wird vom HandController aufgerufen  
public bool IsBeingDraggedCentrally()         // Status-Abfrage
```

**Legacy Events werden ignoriert:**
```csharp
// Diese Events werden nicht mehr verwendet da Interfaces entfernt:
// public void OnBeginDrag() → ENTFERNT
// public void OnDrag()      → ENTFERNT  
// public void OnEndDrag()   → ENTFERNT
```

---

## ⚙️ Detaillierter Ablauf

### 1. Touch Start (`HandleTouchStart`)
```csharp
// Erfasse Start-Position für Schwellenwert-Berechnung
dragStartPosition = position;
lastDragPosition = position;

// Bestimme Karte unter dem Finger
UpdateCardSelectionAtPosition(position);
```

### 2. Touch Move (`HandleTouchMove`) 
```csharp
// Kontinuierliche Finger-Verfolgung
UpdateCardSelectionAtPosition(position);

// Prüfe Drag-Schwellenwert
Vector2 dragDelta = position - dragStartPosition;
bool isUpwardSwipe = dragDelta.y < -minVerticalSwipe;
bool exceedsThreshold = dragDelta.magnitude >= dragThreshold;

if (isUpwardSwipe || exceedsThreshold) {
    StartDragOperation(); // Mit der AKTUELLEN Karte unter dem Finger!
}
```

### 3. Drag Active (`MoveDraggedCardToPosition`)
```csharp
// Bewege die gedraggte Karte zum Finger
RectTransformUtility.ScreenPointToWorldPointInRectangle(
    draggedCardUI.transform.parent as RectTransform,
    screenPosition, camera, out worldPoint);
    
draggedCardUI.transform.position = worldPoint;

// Visuelles Feedback je nach Zone
if (überSpielzone) {
    draggedCardUI.transform.localScale = Vector3.one * 1.2f;
} else {
    draggedCardUI.transform.localScale = Vector3.one * 1.1f;
}
```

### 4. Touch End (`EndDragOperation`)
```csharp
// Prüfe End-Position
float playZoneY = Screen.height * 0.5f;

if (endPosition.y > playZoneY) {
    PlayDraggedCard();      // In Spielzone → Karte spielen
} else {
    ReturnDraggedCardToHand(); // In Hand-Bereich → Zurück zur Hand  
}
```

---

## 🎯 Kritische Design-Entscheidungen

### Warum Zentral im HandController?
**Problem:** Unity's Event System ist nicht flexibel genug für unseren Use Case
**Lösung:** Eigene Touch-Behandlung mit vollständiger Kontrolle über Karten-Auswahl

### Warum lastHoveredCard vs. draggedCard?
```csharp
// WICHTIG: Diese Logik ermöglicht Finger-Bewegung vor Drag
CardUI cardToDrag = hoveredCard ?? lastHoveredCard;

// hoveredCard = Aktuell unter Finger (kann null sein wenn außerhalb)
// lastHoveredCard = Letzte bekannte Karte (bleibt gesetzt)
// → Robuste Karten-Auswahl auch bei schneller Finger-Bewegung
```

### Warum Schwellenwerte?
```csharp
// Verhindert ungewolltes Draggen bei leichtem Finger-Zittern
bool isUpwardSwipe = dragDelta.y < -minVerticalSwipe;  // Unity: -Y ist oben
bool exceedsThreshold = dragDelta.magnitude >= dragThreshold;

// Beide Bedingungen erlauben Drag:
// 1. Deutliche Aufwärtsbewegung (Spieler-Intention klar)
// 2. Allgemeine Bewegung über Schwellenwert (für andere Drag-Richtungen)
```

---

## 🔧 Wartung & Debugging

### Wichtige Log-Nachrichten
```csharp
\"[HandController] StartDragOperation with card: {cardName}\"
\"[HandController] Playing dragged card: {cardName}\"  
\"[HandController] Returning dragged card to hand: {cardName}\"
\"[CardUI] OnCentralDragStart for {cardName}\"
```

### Häufige Probleme & Lösungen

**Problem:** Karte folgt nicht dem Finger
**Lösung:** Prüfe `MoveDraggedCardToPosition()` - Camera-Referenz korrekt?

**Problem:** Falsche Karte wird gespielt  
**Lösung:** Prüfe `UpdateCardSelectionAtPosition()` - wird lastHoveredCard korrekt gesetzt?

**Problem:** Karten bleiben auf dem Bildschirm
**Lösung:** Prüfe `PlayDraggedCard()` - wird `Destroy(draggedCardUI.gameObject)` aufgerufen?

### Performance-Überlegungen
```csharp
// MoveDraggedCardToPosition wird in Update() aufgerufen
// → Nur wenn isDraggingActive == true
// → Minimale Performance-Impact wenn kein Drag aktiv
```

---

## 🚀 Zukünftige Erweiterungen

### Mögliche Verbesserungen
1. **Multi-Touch Support** - Mehrere Karten gleichzeitig draggen
2. **Drag-Vorschau** - Zeige Ziel-Position während Drag
3. **Haptic Feedback** - Vibrationen bei Drag-Start/Ende
4. **Animierte Übergänge** - Smoothere Karten-Bewegungen

### Code-Erweiterungspunkte
```csharp
// In StartDragOperation():
// TODO: Haptic Feedback hinzufügen
// TODO: Sound-Effekte für Drag-Start

// In MoveDraggedCardToPosition():  
// TODO: Drag-Schatten/Vorschau implementieren

// In EndDragOperation():
// TODO: Multi-Target Support (verschiedene Drop-Zonen)
```

---

## ✅ Testing Checklist

- [ ] Finger auf Karte A, zu Karte B bewegen, hochziehen → Karte B wird gespielt
- [ ] Schnelle Finger-Bewegung über mehrere Karten → Letzte Karte wird gedraggt  
- [ ] Drag in Hand-Bereich → Karte kehrt zurück
- [ ] Drag in Spiel-Bereich → Karte wird gespielt und entfernt
- [ ] Drag abbrechen (Finger von Screen) → Karte kehrt zurück
- [ ] Mehrfache schnelle Drags → Kein Lag oder Fehler

---

---

## 📝 Implementation Summary

### Geänderte Dateien:
1. **HandController.cs** 
   - ➕ Zentrale Drag-Verwaltung hinzugefügt
   - ➕ Neue Variablen: `isDraggingActive`, `draggedCardUI`, etc.
   - ➕ Neue Methoden: `StartDragOperation()`, `MoveDraggedCardToPosition()`, etc.
   - 🔄 `HandleTouchMove()` erweitert für Drag-Schwellenwert-Erkennung

2. **CardUI.cs**
   - ➖ Drag-Interfaces entfernt: `IBeginDragHandler`, `IDragHandler`, `IEndDragHandler`  
   - ➖ Komplexe Drag-Logik entfernt
   - ➕ Zentrale Integration: `OnCentralDragStart()`, `OnCentralDragEnd()`
   - 🔄 Vereinfachte Verantwortungen

3. **DRAG_SYSTEM_DOCUMENTATION.md**
   - ➕ Vollständige Dokumentation erstellt
   - ➕ Architektur-Erklärung und Workflow-Diagramme
   - ➕ Debugging-Guide und Testing-Checklist

### Code-Qualität Verbesserungen:
- 📋 **Ausführliche Kommentare** in allen kritischen Methoden
- 🎯 **Klare Verantwortungstrennung** zwischen HandController und CardUI  
- 🔍 **Debugging-freundliche Logs** mit eindeutigen Prefixes
- ⚡ **Performance-optimiert** durch zentrale Verwaltung
- 🛡️ **Robuste Fehlerbehandlung** mit null-Checks und Validierung

### Nächste Schritte:
1. ✅ **System testen** - Finger-Bewegung zwischen Karten
2. ✅ **Performance prüfen** - Smooth Drag-Animation  
3. ✅ **Edge Cases testen** - Schnelle Bewegungen, Touch-Cancel
4. 📈 **Monitoring** - Log-Analyse für weitere Optimierungen

---

*Dokumentiert am: $(date)*  
*Autor: Claude AI*  
*System Version: Zentrale Drag-Architektur v1.0*  
*Status: Implementiert ✅ | Dokumentiert ✅ | Bereit für Testing ✅*