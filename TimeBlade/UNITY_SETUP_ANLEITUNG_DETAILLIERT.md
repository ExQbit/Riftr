# 🎮 Detaillierte Unity-Einrichtungsanleitung für Zeitklingen

## 📋 Übersicht
Diese Anleitung führt dich Schritt für Schritt durch alle notwendigen Unity-Editor-Einstellungen nach den Code-Änderungen.

---

## 🎯 Teil 1: Kartenhand-System einrichten

### 1.1 HandController Komponente konfigurieren

1. **Öffne die TestBattle Scene**
   - Im Project-Fenster: `Assets > TestBattle.unity` doppelklicken

2. **Finde den HandContainer**
   - In der Hierarchy: `HUDCanvas > HandContainer` anklicken
   - Der Inspector zeigt dir die HandController-Komponente

3. **Stelle folgende Werte im Inspector ein:**

   **Layout-Einstellungen:**
   - ✅ **Card Spacing**: `80` (Abstand zwischen Karten)
   - ✅ **Max Card Width**: `120` (Maximale Kartenbreite)
   - ✅ **Fan Angle**: `25` (Fächer-Winkel)
   - ✅ **Curve Height**: `50` (Höhe des Bogens)
   - ✅ **Hover Lift**: `20` (Anhebung bei Hover)
   - ✅ **Invert Fan Angle**: ☑️ (Häkchen setzen!)
   - ✅ **Curve Smoothing**: `0.8` (Weichheit des Bogens)

   **Touch-Einstellungen:**
   - ✅ **Enable Fanning**: ☑️ (Häkchen setzen!)
   - ✅ **Fan Spacing**: `150` (Abstand beim Auffächern)

4. **Animation Curve einstellen:**
   - Klicke auf das kleine Kurven-Symbol neben "Layout Curve"
   - Ein Kurven-Editor öffnet sich
   - Stelle sicher, dass die Kurve so aussieht:
     - Startpunkt (links): Bei Position (0, 0)
     - Mittelpunkt: Bei Position (0.5, 1) 
     - Endpunkt (rechts): Bei Position (1, 0)
   - Rechtsklick auf jeden Punkt → "Smooth" auswählen für weiche Übergänge

### 1.2 Card Prefab konfigurieren

1. **Finde das Karten-Prefab**
   - Im Project-Fenster: `Assets > Cards > PreFabs > CardUIPrefab_Root`
   - Doppelklick zum Öffnen im Prefab-Editor

2. **CardUI Komponente einstellen:**
   - Im Inspector findest du die CardUI-Komponente
   - Unter "Drag-Einstellungen" stelle ein:
     - ✅ **Drag Threshold**: `30` (Pixel für Drag-Erkennung)
     - ✅ **Vertical Drag Bias**: `1.5` (Vertikale Bewegung zählt mehr)
     - ✅ **Min Vertical Swipe**: `15` (Minimale Aufwärtsbewegung)

3. **Speichere das Prefab**
   - Oben links im Prefab-Editor auf "Save" klicken
   - Oder Strg+S (Windows) / Cmd+S (Mac)

---

## 🎯 Teil 2: ActionPanel Timeline-System einrichten

### 2.1 UI-Struktur erstellen

1. **Prüfe ob ActionTimelinePanel existiert**
   - In der Hierarchy: Schaue unter `HUDCanvas`
   - Falls `ActionTimelinePanel` bereits existiert, weiter zu Schritt 2.3

2. **Falls nicht vorhanden, erstelle die Struktur:**
   
   a) **Rechtsklick auf HUDCanvas** → UI → Empty Object
      - Benenne es um zu: `ActionTimelinePanel`
   
   b) **ActionTimelinePanel auswählen** und im Inspector:
      - Klicke "Add Component" → UI → Image
      - Farbe: Weiß mit 20% Alpha (für leichten Hintergrund)
      - RectTransform einstellen:
        - **Anchors**: Rechts-Mitte (klicke das Anchor-Preset-Fenster)
        - **Position X**: `-150`
        - **Position Y**: `0`
        - **Width**: `250`
        - **Height**: `600`

3. **TimelineContainer erstellen:**
   
   a) **Rechtsklick auf ActionTimelinePanel** → UI → Empty Object
      - Benenne es um zu: `TimelineContainer`
   
   b) **TimelineContainer auswählen** und im Inspector:
      - Klicke "Add Component" → Layout → Vertical Layout Group
      - Einstellungen:
        - ✅ **Spacing**: `5`
        - ✅ **Child Force Expand Width**: ☑️
        - ☐ **Child Force Expand Height**: ☐ (kein Häkchen!)
        - ✅ **Child Control Size Width**: ☑️
        - ☐ **Child Control Size Height**: ☐ (kein Häkchen!)
      
      - RectTransform einstellen:
        - **Anchors**: Stretch-Stretch (Alt+Shift und das rechte untere Preset)
        - **Left**: `10`
        - **Right**: `10`
        - **Top**: `10`
        - **Bottom**: `10`

### 2.2 ActionTimelineDisplay Script hinzufügen

1. **TimelineContainer auswählen**

2. **Script hinzufügen:**
   - Klicke "Add Component" → Scripts → ActionTimelineDisplay
   - Falls nicht in der Liste: "Add Component" → Suchfeld → "ActionTimelineDisplay" eingeben

3. **Script konfigurieren:**
   - **Action Item Prefab**: 
     - Klicke auf den kleinen Kreis rechts
     - Wähle `ActionTimelineItem` aus der Liste
     - WICHTIG: Falls nicht vorhanden, siehe Abschnitt 2.4
   - **Timeline Height**: `500`
   - **Timeline Range**: `10`
   - **Update Interval**: `0.1`
   
   - **Farben einstellen** (klicke auf die Farbfelder):
     - **Time Steal Color**: Rot (255, 77, 77)
     - **Double Strike Color**: Dunkelrot (204, 51, 51)
     - **Defend Color**: Blau (77, 128, 255)
     - **Buff Color**: Grün (77, 255, 77)
     - **Special Color**: Gold (255, 204, 51)

### 2.3 ActionTimelineItem Prefab verwenden

Da die Meta-Datei gelöscht wurde, musst du Unity kurz aktualisieren:

1. **Unity-Editor fokussieren**
   - Klicke einfach irgendwo im Unity-Editor
   - Unity erstellt automatisch eine neue Meta-Datei

2. **Prefab zuweisen:**
   - Gehe zurück zum TimelineContainer
   - In der ActionTimelineDisplay Komponente
   - Klicke auf den Kreis neben "Action Item Prefab"
   - Wähle `ActionTimelineItem` aus

### 2.4 Falls ActionTimelineItem fehlt

Falls das Prefab nicht gefunden wird:

1. **Im Project-Fenster:**
   - Navigiere zu `Assets > UI`
   - Suche nach `ActionTimelineItem.prefab`

2. **Falls vorhanden:**
   - Ziehe es per Drag & Drop auf das "Action Item Prefab" Feld

3. **Falls nicht vorhanden:**
   - Die Datei wurde erstellt, Unity hat sie aber noch nicht erkannt
   - Rechtsklick im Project-Fenster → "Reimport All"
   - Oder: Unity neu starten

---

## 🎯 Teil 3: Testen und Fehlersuche

### 3.1 Kartenhand testen

1. **Starte das Spiel** (Play-Button)

2. **Teste folgende Features:**
   - **Hover**: Fahre über Karten → sie sollten sich leicht vergrößern
   - **Drag**: Ziehe eine Karte nach oben → erst nach 15 Pixel Aufwärtsbewegung
   - **Fanning**: Berühre den Handbereich → Karten sollten sich auffächern
   - **Return**: Lass eine Karte los → sie sollte sauber zurückkehren

3. **Bei Problemen prüfe:**
   - Console-Fenster (Window → General → Console) für Fehlermeldungen
   - Sind alle Werte korrekt eingestellt?
   - Ist das CardUIPrefab korrekt zugewiesen?

### 3.2 Timeline testen

1. **Im Play-Mode:**
   - Rechts sollte das ActionTimelinePanel sichtbar sein
   - Wenn Gegner spawnen, erscheinen ihre Aktionen in der Timeline

2. **Bei Problemen:**
   - Ist ActionTimelineDisplay auf TimelineContainer?
   - Ist das ActionItem Prefab zugewiesen?
   - Gibt es Fehler in der Console?

---

## 📝 Häufige Probleme und Lösungen

### Problem: "Can't find ActionTimelineItem prefab"
**Lösung:**
1. Project-Fenster → Rechtsklick → Reimport All
2. Warte bis Unity fertig ist
3. Versuche erneut das Prefab zuzuweisen

### Problem: "Karten überlappen sich"
**Lösung:**
1. HandContainer → HandController → "Curve Height" erhöhen (z.B. auf 70)
2. "Card Spacing" erhöhen (z.B. auf 100)

### Problem: "Touch funktioniert nicht"
**Lösung:**
1. HandContainer sollte eine RectTransform haben die groß genug ist
2. Im Inspector: Width = 800, Height = 200
3. "Enable Fanning" muss aktiviert sein

### Problem: "Timeline ist nicht sichtbar"
**Lösung:**
1. ActionTimelinePanel → Image Component → Color Alpha auf 0.2-0.4
2. Position anpassen falls außerhalb des Bildschirms

---

## ✅ Abschluss-Checkliste

- [ ] HandController: Alle Werte korrekt eingestellt?
- [ ] CardUIPrefab: Drag-Einstellungen konfiguriert?
- [ ] Animation Curve: Smooth und mit Peak in der Mitte?
- [ ] ActionTimelinePanel: Erstellt und positioniert?
- [ ] TimelineContainer: Vertical Layout Group konfiguriert?
- [ ] ActionTimelineDisplay: Script hinzugefügt und konfiguriert?
- [ ] ActionItem Prefab: Zugewiesen?
- [ ] Play-Test: Alles funktioniert?

---

## 🆘 Weitere Hilfe

Falls etwas nicht funktioniert:
1. Schicke mir einen Screenshot der Console-Fehler
2. Beschreibe genau was passiert vs. was erwartet wird
3. Zeige mir deine Inspector-Einstellungen

Viel Erfolg! 🎮✨