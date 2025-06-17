## PARALLAX BOGEN-BEWEGUNG DEBUG PLAN

### Problem:
- Karten bewegen sich beim horizontalen Gleiten nur horizontal
- Y-Position der Karten folgt nicht dem Bogen
- Karten sollten auf einem imaginären Bogen gleiten

### Bereits implementierte Fixes:
1. **UpdateParallaxOffsetOnly** berechnet jetzt volle Bogen-Position (X und Y)
2. **UpdateParallaxPositionWithArc** in CardUI.cs für korrekte Hover-Updates
3. **HandleTouchMove** ruft UpdateParallaxHandShift auf wenn gefächert
4. Drag-Schwellenwerte erhöht (60f/80f/150f)

### Debug-Schritte:
1. **Prüfe ob enableFanning = true** im Inspector
2. **Teste mit langsamer horizontaler Bewegung** (ohne Drag auszulösen)
3. **Beobachte die Console** für [PARALLAX] Logs

### Erwartete Logs:
```
[PARALLAX DEBUG] HandleTouchStart - enableFanning: True, activeCards: 5
[PARALLAX] UpdateParallaxHandShift called! pos: (x,y), isFanned: True
[PARALLAX] Offset updated to X.X (finger moved Y.Y px)
[PARALLAX] UpdateParallaxOffsetOnly - offset: X.X, cards: 5
```

### Falls keine PARALLAX Logs erscheinen:
- enableFanning ist false → Im Inspector auf true setzen
- Drag wird zu früh ausgelöst → Noch langsamer horizontal bewegen
- Touch wird nicht erkannt → Prüfe ob Karte getroffen wird

### Test-Anleitung:
1. Starte das Spiel
2. Öffne die Unity Console (Strg/Cmd + Shift + C)
3. Berühre eine Karte (Fächer öffnet sich)
4. Bewege den Finger SEHR LANGSAM horizontal (NICHT nach oben!)
5. Beobachte die Console für [PARALLAX] Logs

### Was du sehen solltest:
- Beim Touch: `[PARALLAX DEBUG] HandleTouchStart - enableFanning: True`
- Beim Bewegen: `[PARALLAX] UpdateParallaxHandShift called!`
- Offset-Updates: `[PARALLAX] Offset updated to X.X`
- Layout-Updates: `[PARALLAX] UpdateParallaxOffsetOnly`

### Wenn du siehst: `[PARALLAX] NOT ACTIVE`
- Bewege den Finger noch langsamer
- Bewege NUR horizontal, nicht nach oben
- Der Drag wird zu früh ausgelöst

### Weitere Debug-Optionen:
- Setze "Enable Debug Logs" = true im HandController Inspector
- Setze "Log Parallax Details" = true für mehr Details
- Reduziere "Min Vertical Swipe For Drag" noch weiter (z.B. auf 100)
