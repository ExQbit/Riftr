# 🎮 HANDKARTEN-SYSTEM KONTROLLFLUSS-DIAGRAMM
## Implementierung gemäß HANDKARTEN_SYSTEM_FUNKTIONALE_SPEZIFIKATION.md

---

## 📱 **USER-AKTION 1: TOUCH START IM HANDCONTAINER**

```
USER: Touch/Click im HandContainer-Bereich
  ↓
HandController.HandleTouchInput()
  ├─ Input.touchCount > 0 OR Input.GetMouseButtonDown(0)
  ↓
HandController.HandleTouchStart(Vector2 position)
  ├─ CardUI.SetIsMouseInput(bool) [Global State Setting]
  ├─ RectTransformUtility.ScreenPointToLocalPointInRectangle()
  ├─ PRÜFUNG: expandedRect.Contains(localPoint) [+50px Extension]
  │
  ├─ ✅ VALID AREA:
  │   ├─ isTouching = true
  │   ├─ isFanned = true
  │   ├─ CardUI.SetTouchStartedOnValidArea(true) [Global Flag]
  │   ├─ UpdateCardSelectionAtPosition(position)
  │   │   ├─ EventSystem.RaycastAll() [Find card under finger]
  │   │   ├─ hoveredCard?.ForceExitHover() [Clear old]
  │   │   └─ newCard?.ForceEnterHover() [Set new]
  │   └─ UpdateCardLayout() [IMMEDIATE Fan Animation: 0.15s easeOutExpo]
  │
  └─ ❌ INVALID AREA:
      └─ CardUI.SetTouchStartedOnValidArea(false) [REJECT completely]
```

---

## 👆 **USER-AKTION 2: TOUCH MOVE ÜBER KARTEN (HOVER TRACKING)**

```
USER: Finger/Mouse bewegt sich über Karten
  ↓
HandController.HandleTouchInput()
  ├─ touch.phase == TouchPhase.Moved OR Input.GetMouseButton(0)
  ├─ IF (isTouching == true)
  ↓
HandController.UpdateCardSelectionAtPosition(position)
  ├─ hoveredCard?.ForceExitHover() [Remove previous hover]
  ├─ EventSystem.RaycastAll(pointerData)
  ├─ FOREACH result in results:
  │   ├─ CardUI cardUI = result.gameObject.GetComponent<CardUI>()
  │   ├─ IF (cardUI != null && activeCardUIs.Contains(cardUI))
  │   └─ hoveredCard = cardUI; cardUI.ForceEnterHover(); BREAK
  │
CardUI.ForceEnterHover() [Only if !isDragging && !hoverDisabled]
  ├─ isHovering = true
  ├─ originalSiblingIndex = transform.GetSiblingIndex()
  ├─ transform.SetAsLastSibling() [Bring to front]
  ├─ highlightEffect?.SetActive(true)
  └─ LeanTween.moveLocal() [Hover Lift: 0.1s easeOutCubic]
```

**KRITISCHE REGEL**: Nur die Karte unter dem aktuellen Finger wird gehovered!

---

## 🔄 **USER-AKTION 3: AUFWÄRTS-SWIPE ZUM DRAGGEN**

```
USER: Swipe nach oben auf gehoverter Karte
  ↓
CardUI.OnBeginDrag(PointerEventData eventData)
  ├─ PRÜFUNG 1: !isPlayable? 
  │   └─ ❌ ShakeCard() + eventData.pointerDrag = null + RETURN
  ├─ PRÜFUNG 2: controller.GetHoveredCard() != this?
  │   └─ ❌ eventData.pointerDrag = null + RETURN
  ├─ ✅ APPROVED:
      ├─ currentlyDraggedCard = this [Global State]
      ├─ pointerStartPosition = eventData.position
      ├─ dragStartPosition = transform.position
      ├─ isDragging = true
      └─ dragInitiated = false [Wait for threshold]
  ↓
CardUI.OnDrag(PointerEventData eventData)
  ├─ IF (!dragInitiated):
  │   ├─ dragDelta = eventData.position - pointerStartPosition
  │   ├─ isUpwardSwipe = dragDelta.y > minVerticalSwipe [15px]
  │   ├─ weightedDistance = |dragDelta.x| + |dragDelta.y| * verticalDragBias [1.5x]
  │   ├─ shouldStartDrag = isUpwardSwipe OR (weightedDistance > dragThreshold [30px] AND vertical > horizontal)
  │   │
  │   ├─ ✅ THRESHOLD REACHED:
  │   │   └─ InitiateDrag(eventData)
  │   │       ├─ dragInitiated = true
  │   │       ├─ controller.RemoveCardForDrag(this) [SOFORTIGE Neuanordnung]
  │   │       ├─ controller.DisableAllHoverEffects()
  │   │       ├─ transform.SetParent(originalParent.parent, true) [Top level]
  │   │       ├─ LeanTween.scale() [1.1x: 0.08s easeOutExpo]
  │   │       ├─ LeanTween.rotateLocal() [Reset rotation: 0.08s easeOutExpo]
  │   │       └─ transform.position = eventData.position
  │   │
  │   └─ ❌ THRESHOLD NOT REACHED:
  │       └─ RETURN [Stay in hover mode]
  │
  └─ IF (dragInitiated):
      └─ transform.position = eventData.position [Follow pointer]
```

**KRITISCHE REGEL**: Layout wird SOFORT beim Drag-Start aktualisiert, nicht erst beim Ausspielen!

---

## 🎯 **USER-AKTION 4: KARTE LOSLASSEN (PLAY ODER RETURN)**

```
USER: Loslassen der Karte
  ↓
CardUI.OnEndDrag(PointerEventData eventData)
  ├─ isDragging = false
  ├─ currentlyDraggedCard = null [Global Reset]
  │
  ├─ IF (dragInitiated):
  │   └─ HandleDragEnd(eventData)
  │       └─ TryPlayCard(eventData)
  │           ├─ RectTransformUtility.ScreenPointToLocalPointInRectangle()
  │           ├─ overHand = handRect.rect.Contains(localPoint)
  │           │
  │           ├─ ✅ OUTSIDE HAND (PLAY CARD):
  │           │   ├─ RiftCombatManager.PlayerWantsToPlayCard()
  │           │   └─ RETURN true [Card gets destroyed by game system]
  │           │
  │           └─ ❌ OVER HAND (RETURN):
  │               └─ ReturnToHand()
  │                   ├─ transform.SetParent(originalParent, true)
  │                   ├─ controller.AddCardBackToHand(this)
  │                   ├─ controller.EnableAllHoverEffects()
  │                   ├─ LeanTween.scale() [Back to 1.0: 0.25s easeOutBack]
  │                   └─ UpdateCardLayout(true) [INSTANT repositioning]
  │
  └─ IF (!dragInitiated):
      └─ ResetToOriginalPosition() [0.25s easeOutBack to dragStartPosition]
```

---

## 🚫 **USER-AKTION 5: TOUCH START AUSSERHALB + SLIDE ÜBER KARTEN**

```
USER: Touch außerhalb HandContainer, dann Gleiten über Karten
  ↓
HandController.HandleTouchStart(position)
  ├─ RectTransformUtility.ScreenPointToLocalPointInRectangle()
  ├─ !expandedRect.Contains(localPoint) OR !hitDetected
  ↓
CardUI.SetTouchStartedOnValidArea(false) [Global Rejection Flag]
  ↓
USER: Gleitet über Karten
  ↓
CardUI.OnPointerEnter(PointerEventData eventData)
  ├─ PRÜFUNG: !isMouseInput && !touchStartedOnValidArea?
  └─ ❌ RETURN [COMPLETE REJECTION - No hover effects]
```

**KRITISCHE REGEL**: Karten reagieren NICHT auf Touch-Events wenn Touch außerhalb begann!

---

## 🖱️ **DESKTOP MOUSE VS TOUCH UNTERSCHEIDUNG**

```
MOUSE INPUT:
HandController.HandleTouchInput()
  ├─ Input.GetMouseButtonDown(0)
  ├─ CardUI.SetIsMouseInput(true)
  └─ Standard Mouse Hover via OnPointerEnter/Exit funktioniert

TOUCH INPUT:
HandController.HandleTouchInput()
  ├─ Input.touchCount > 0
  ├─ CardUI.SetIsMouseInput(false)
  └─ Hover nur via ForceEnterHover() durch UpdateCardSelectionAtPosition()

CardUI.OnPointerEnter()
  ├─ IF (!isMouseInput && !touchStartedOnValidArea): RETURN
  ├─ IF (currentlyDraggedCard != null && != this): RETURN
  ├─ IF (hoverDisabled): RETURN
  └─ StartHover()
```

---

## 🔄 **ZUSTANDSMANAGEMENT**

### HandController States:
```
isTouching: false → true [HandleTouchStart] → false [HandleTouchEnd]
isFanned: false → true [HandleTouchStart] → false [HandleTouchEnd]
hoveredCard: null → CardUI [UpdateCardSelectionAtPosition] → null [HandleTouchEnd]
draggedCard: null → GameObject [RemoveCardForDrag] → null [AddCardBackToHand]
```

### CardUI States:
```
isHovering: false → true [StartHover] → false [EndHover]
isDragging: false → true [OnBeginDrag] → false [OnEndDrag]
dragInitiated: false → true [InitiateDrag] → false [OnEndDrag]
hoverDisabled: false → true [ForceDisableHover] → false [EnableHover]
```

### Global Static States:
```
touchStartedOnValidArea: SetTouchStartedOnValidArea(bool)
isMouseInput: SetIsMouseInput(bool)
currentlyDraggedCard: CardUI reference [Only ONE card can drag at a time]
```

---

## ⚡ **PERFORMANCE & ANIMATION TIMINGS (Per Spezifikation)**

```
Layout Standard:     0.2s easeOutCubic    [UpdateCardLayout]
Fan Animation:       0.15s easeOutExpo    [Snappy fanning]
Hover Lift:          0.1s easeOutCubic    [Quick response]
Drag Start:          0.08s easeOutExpo    [Immediate feedback]
Return to Hand:      0.25s easeOutBack    [Characteristic bounce]
Card Draw:           0.3s easeOutBack     [Dramatic entrance]
Card Play:           0.25s easeInBack     [Fast disappear]
```

---

## 🎯 **KRITISCHE VALIDIERUNGEN IM FLUSS**

1. **Touch Area Validation**: `expandedRect.Contains(localPoint)` [+50px extension]
2. **Playability Check**: `RiftTimeSystem.Instance.CanPlayCard(cardData)` [Continuous in Update()]
3. **Hover Exclusivity**: `controller.GetHoveredCard() == this` [Only hovered card can drag]
4. **Drag Threshold**: `isUpwardSwipe OR weightedDistance > threshold` [15px vertical OR 30px weighted]
5. **Touch Origin**: `!isMouseInput && !touchStartedOnValidArea` [Reject invalid touch origins]

---

## 🔄 **SOFORTIGE LAYOUT-UPDATES (Kritisch für Spezifikation)**

```
WANN INSTANT LAYOUT UPDATES:
1. CreateCardUI() → UpdateCardLayout(true) [Prevent initial overlap]
2. RemoveCardForDrag() → UpdateCardLayout(true) [Immediate gap closure]
3. AddCardBackToHand() → UpdateCardLayout(true) [Instant repositioning]
4. RemoveCardFromHand() → UpdateCardLayout(true) [Immediate reorder after play]

WANN ANIMIERTE UPDATES:
1. HandleTouchStart() → UpdateCardLayout() [Fan animation: 0.15s]
2. HandleTouchEnd() → UpdateCardLayout() [Unfan animation: 0.2s]
3. EndHover() → UpdateCardLayout() [Layout correction: 0.2s]
```

**RESULTAT**: Pokémon TCG Pocket-ähnliches, flüssiges und responsives Handkarten-System ohne visuelle Glitches oder falsche Kartenauswahl.