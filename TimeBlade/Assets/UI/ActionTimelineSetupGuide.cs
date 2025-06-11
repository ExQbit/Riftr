using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Setup-Anleitung für ActionTimelineDisplay
/// Dieses Script dient als Referenz für die korrekte Einrichtung in Unity
/// </summary>
public class ActionTimelineSetupGuide : MonoBehaviour 
{
    /*
    SETUP-ANLEITUNG FÜR ACTIONTIMELINEDISPLAY:
    
    1. HIERARCHIE-STRUKTUR:
       Canvas
       └── ActionTimelinePanel (mit ActionTimelineDisplay.cs)
           └── Container (RectTransform für die Timeline-Items)
    
    2. ACTIONTIMELINEPANEL SETUP:
       - RectTransform:
         * Anchors: Je nach gewünschter Position (z.B. Top-Right für obere rechte Ecke)
         * Width: 300-400 (je nach Design)
         * Height: 600-800 (je nach verfügbarem Platz)
       
       - Komponenten:
         * ActionTimelineDisplay.cs
         * Optional: Image (für Hintergrund)
         * Optional: Mask (für saubere Grenzen)
    
    3. CONTAINER SETUP (WICHTIG!):
       - RectTransform:
         * Anchors: Stretch in beide Richtungen (0,0) bis (1,1)
         * Left/Right/Top/Bottom: 10 (für Padding)
         * Pivot: (0.5, 1) für Top-Center Ausrichtung
       
       - Komponenten (werden automatisch hinzugefügt):
         * VerticalLayoutGroup:
           - Spacing: 5
           - Padding: 10 auf allen Seiten
           - Child Alignment: Upper Center
           - Control Child Size: Width ✓, Height ✗
           - Use Child Scale: ✗
           - Child Force Expand: Width ✗, Height ✗
         
         * ContentSizeFitter:
           - Vertical Fit: Preferred Size
           - Horizontal Fit: Unconstrained
    
    4. ACTIONTIMELINEITEM PREFAB:
       - RectTransform:
         * Width: Wird vom Parent gestreckt
         * Height: 60 (oder nach Bedarf)
       
       - LayoutElement:
         * Min Height: 60
         * Preferred Height: 60
         * Flexible Width: 1
       
       - Struktur:
         * Background (Image)
         * Icon (Image)
         * EnemyNameText (TextMeshProUGUI)
         * ActionNameText (TextMeshProUGUI)
         * TimerText (TextMeshProUGUI)
         * UrgencyIndicator (Image)
    
    5. HÄUFIGE FEHLER UND LÖSUNGEN:
    
       Problem: Items erscheinen am oberen Bildschirmrand
       Lösung: Container hat falsche Anchor-Einstellungen oder negative sizeDelta
       
       Problem: Items werden nicht sichtbar
       Lösung: Prüfe ob Container eine Höhe hat und ob Mask korrekt eingestellt ist
       
       Problem: Items überlappen sich
       Lösung: VerticalLayoutGroup fehlt oder ist falsch konfiguriert
       
       Problem: Items haben falsche Breite
       Lösung: LayoutElement auf Items fehlt oder flexibleWidth nicht gesetzt
    
    6. DEBUG-TIPPS:
       - Aktiviere Gizmos im Scene View um Layout-Grenzen zu sehen
       - Nutze den Layout Properties Window (Window > UI > Layout Properties)
       - Prüfe die Konsole für Debug-Ausgaben von ActionTimelineDisplay
       - Frame Selection (F) auf Container um dessen tatsächliche Größe zu sehen
    */
    
    void Start()
    {
        Debug.Log("Dieses Script dient nur als Setup-Referenz und sollte nicht im Spiel verwendet werden!");
    }
}