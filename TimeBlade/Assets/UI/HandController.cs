using UnityEngine;

/// <summary>
/// Haupt-HandController Klasse die alle partial classes zusammenführt
/// Diese Datei existiert nur, damit Unity die Komponente korrekt erkennt
/// </summary>
public partial class HandController : MonoBehaviour
{
    // Alle Funktionalität ist in den anderen partial class Dateien:
    // - HandController_Core.cs (Variablen und Start/Update)
    // - HandController_Touch.cs (Touch-Input)
    // - HandController_DragDrop.cs (Drag&Drop)
    // - HandController_Utils.cs (Hilfsmethoden)
}
