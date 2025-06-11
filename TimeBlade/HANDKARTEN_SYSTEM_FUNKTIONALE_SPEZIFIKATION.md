# 🎮 Handkarten-System - Funktionale Spezifikation

## Übersicht
Diese Tabelle beschreibt das gewünschte Verhalten des Handkarten-Systems in Zeitklingen, inspiriert vom "Pokémon TCG Pocket" Spielgefühl.

## Funktionale Spezifikation Tabelle

| **Funktionalität** | **Aktuelles Verhalten (FEHLER)** | **Gewünschtes Verhalten** | **Implementierungs-Details** |
|-------------------|----------------------------------|--------------------------|------------------------------|
| **Touch-Erkennung** | Touch an beliebiger Stelle löst Aktionen aus | Touch NUR im HandContainer-Bereich (+50px Extension) löst Fanning aus | `HandleTouchStart()` prüft erweiterten Rect-Bereich |
| **Kartenauswahl beim Fanning** | Erste berührte Karte bleibt für Drag ausgewählt | Karte unter aktuellem Finger wird dynamisch gehovered | `UpdateHoveredCard()` trackt kontinuierlich Position |
| **Drag-Initiierung** | Sofortiges Drag bei jeder Bewegung | Drag startet erst nach 15px Aufwärtsbewegung ODER 30px gewichtete Gesamtbewegung | Schwellenwert-Prüfung in `OnDrag()` |
| **Drag-Kartenauswahl** | Immer die initial berührte Karte | NUR die aktuell gehoverte Karte kann gedraggt werden | `OnBeginDrag()` prüft `handController.GetHoveredCard()` |
| **Fanning-Animation** | Zu langsam oder ruckelig | 0.15s schnelle, snappy Animation | `fanAnimationDuration` mit `easeOutExpo` |
| **Karten-Neuanordnung** | Lücke bleibt bis neue Karte gezogen wird | SOFORTIGE Neuanordnung wenn Karte gespielt wird | `RemoveCardFromHand()` ruft sofort `UpdateHandLayout()` auf |
| **Return-Animation** | Karten überlappen nach Rückkehr | Saubere Rückkehr ohne Überlappungen | Verzögertes Layout-Update + korrekte Sibling-Order |
| **Hover-Effekt** | Funktioniert während Touch/Drag | Hover NUR bei Desktop-Mouse, nicht bei Touch | `OnPointerEnter/Exit` prüft `IsTouchingHandArea()` |
| **Touch-Bereich** | Nur exakter Container | Container + 50px nach unten für Mobile | `expandedRect.yMin -= 50f` |
| **Layout-Kurve** | Flache oder unnatürliche Kurve | Smooth gemischte Sinus/AnimationCurve | `curveSmoothing` Parameter mischt beide Kurven |
| **Transparenz** | Karten werden durchsichtig | KEINE Alpha-Änderungen | Alle `canvasGroup.alpha` Änderungen entfernt |
| **Spielbarkeits-Check** | Einmalig oder verzögert | Kontinuierlich in `Update()` | `CheckPlayability()` jeden Frame |
| **Visuelles Feedback** | Fehlt oder ist unklar | Nicht spielbare Karten dunkler + Shake bei Versuch | Farbe * 0.5 + `ShakeCard()` Animation |
| **Performance** | Viele redundante Updates | Batch-Updates mit Coroutines | `DelayedUpdateLayout()` vermeidet Frame-Spikes |
| **Mobile-Optimierung** | Desktop-fokussiert | Touch-first mit erweiterten Hit-Bereichen | Separate Touch/Mouse-Handling |

## Touch-Flow Diagramm

```
1. TOUCH START (im HandContainer-Bereich)
   ↓
2. FANNING AKTIVIERT (Karten spreizen sich)
   ↓
3. TOUCH MOVE (Finger bewegt sich)
   ↓
4. HOVER UPDATE (Karte unter Finger wird highlighted)
   ↓
5. SWIPE UP DETECTED (15px+ aufwärts)
   ↓
6. DRAG INITIIERT (NUR gehoverte Karte)
   ↓
7. DRAG MOVE (Karte folgt Finger)
   ↓
8. RELEASE IN PLAY ZONE
   ↓
9. KARTE GESPIELT → SOFORTIGE NEUANORDNUNG
```

## Animations-Timing

| **Animation** | **Dauer** | **Easing** | **Zweck** |
|--------------|-----------|------------|-----------|
| Layout Standard | 0.2s | easeOutCubic | Smooth Basis-Bewegungen |
| Fan Animation | 0.15s | easeOutExpo | Snappy Auffächern |
| Hover Lift | 0.1s | easeOutCubic | Schnelle Reaktion |
| Drag Start | 0.08s | easeOutExpo | Sofortiges Feedback |
| Return to Hand | 0.25s | easeOutBack | Charakteristischer Bounce |
| Card Draw | 0.3s | easeOutBack | Dramatischer Eingang |
| Card Play | 0.25s | easeInBack | Schnelles Verschwinden |

## Kritische Regeln

1. **Touch-Priorität**: Touch im Hand-Bereich hat IMMER Priorität über andere UI-Elemente
2. **Hover-Exklusivität**: Nur EINE Karte kann gleichzeitig gehovered sein
3. **Drag-Authentizität**: Nur die AKTUELL gehoverte Karte darf gedraggt werden
4. **Layout-Integrität**: Karten dürfen sich NIE überlappen (außer während Drag)
5. **Sofort-Reaktion**: Alle visuellen Änderungen < 100ms für "snappy" Gefühl

## Test-Szenarien

1. **Touch → Hover → Drag**: 
   - Touch in Hand-Bereich
   - Slide zu Karte X
   - Swipe nach oben
   - ✓ Karte X wird gedraggt (nicht initial berührte)

2. **Schnelles Spielen**:
   - Karte A spielen
   - ✓ Sofortige Neuanordnung
   - Karte B spielen während Animation
   - ✓ Keine Überlappungen

3. **Touch außerhalb**:
   - Touch außerhalb Hand-Bereich
   - Slide in Hand-Bereich
   - ✓ Kein Fanning/Hover aktiviert

4. **Multi-Touch** (Future):
   - Zwei Finger gleichzeitig
   - ✓ Nur erster Touch zählt

## Performance-Ziele

- **Frame-Rate**: Konstante 60 FPS auch bei 10 Karten
- **Touch-Latenz**: < 16ms (1 Frame) Reaktionszeit
- **Animation-Budget**: Max 3 gleichzeitige Tweens pro Karte
- **Memory**: Keine Allocations im Update-Loop