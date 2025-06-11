using UnityEngine;
using UnityEngine.SceneManagement;

/// <summary>
/// Test-Controller zum Starten des Gameplay-Loops.
/// Ermöglicht einfaches Testen der Kern-Mechaniken.
/// </summary>
public class RiftTestController : MonoBehaviour
{
    [Header("Test-Einstellungen")]
    [SerializeField] private bool autoStartRift = true;
    [SerializeField] private RiftTimeSystem.RiftType testRiftType = RiftTimeSystem.RiftType.Tutorial;
    [SerializeField] private float autoStartDelay = 2f;
    
    [Header("Debug-Anzeige")]
    [SerializeField] private bool showDebugInfo = true;
    
    // Systeme
    private RiftTimeSystem timeSystem;
    private RiftPointSystem pointSystem;
    private RiftCombatManager combatManager;
    private ZeitwaechterPlayer player;
    
    void Start()
    {
        Debug.Log("=== ZEITKLINGEN GAMEPLAY-LOOP TEST ===");
        Debug.Log("Zeit-basiertes Kampfsystem - Spieler haben KEINE HP!");
        Debug.Log("=====================================");
        
        // Systeme initialisieren
        InitializeSystems();
        
        // Auto-Start?
        if (autoStartRift)
        {
            Invoke(nameof(StartTestRift), autoStartDelay);
        }
    }
    
    /// <summary>
    /// Initialisiert alle benötigten Systeme
    /// </summary>
    private void InitializeSystems()
    {
        // Core-Systeme finden oder erstellen
        timeSystem = FindOrCreateSystem<RiftTimeSystem>("RiftTimeSystem");
        pointSystem = FindOrCreateSystem<RiftPointSystem>("RiftPointSystem");
        combatManager = FindOrCreateSystem<RiftCombatManager>("RiftCombatManager");
        
        // Spieler finden oder erstellen
        player = FindAnyObjectByType<ZeitwaechterPlayer>();
        if (player == null)
        {
            GameObject playerObj = new GameObject("Zeitwaechter_Player");
            player = playerObj.AddComponent<ZeitwaechterPlayer>();
            Debug.Log("[Test] Zeitwächter-Spieler erstellt");
        }
        
        // Enemy Spawner
        var spawner = FindAnyObjectByType<RiftEnemySpawner>();
        if (spawner == null)
        {
            GameObject spawnerObj = new GameObject("RiftEnemySpawner");
            spawner = spawnerObj.AddComponent<RiftEnemySpawner>();
            
            // Standard Spawn-Point
            GameObject spawnPoint = new GameObject("EnemySpawnPoint");
            spawnPoint.transform.position = new Vector3(5f, 0f, 0f);
            spawner.SetSpawnPoint(spawnPoint.transform);
            
            Debug.Log("[Test] Enemy Spawner erstellt");
        }
        
        // UI Controller
        var uiController = FindAnyObjectByType<RiftUIController>();
        if (uiController == null)
        {
            Debug.LogWarning("[Test] Kein UI Controller gefunden - UI wird nicht aktualisiert!");
        }
        
        Debug.Log("[Test] Alle Systeme initialisiert");
    }
    
    /// <summary>
    /// Hilfsmethode zum Finden oder Erstellen von Singleton-Systemen
    /// </summary>
    private T FindOrCreateSystem<T>(string systemName) where T : MonoBehaviour
    {
        T system = FindAnyObjectByType<T>();
        if (system == null)
        {
            GameObject systemObj = new GameObject(systemName);
            system = systemObj.AddComponent<T>();
            Debug.Log($"[Test] {systemName} erstellt");
        }
        return system;
    }
    
    /// <summary>
    /// Startet einen Test-Rift
    /// </summary>
    [ContextMenu("Start Test Rift")]
    public void StartTestRift()
    {
        if (combatManager == null)
        {
            Debug.LogError("[Test] Combat Manager nicht gefunden!");
            return;
        }
        
        Debug.Log($"[Test] Starte {testRiftType} Rift...");
        combatManager.StartRift(testRiftType);
    }
    
    /// <summary>
    /// Debug-Info im Editor
    /// </summary>
    void OnGUI()
    {
        if (!showDebugInfo) return;
        
        GUIStyle style = new GUIStyle(GUI.skin.box);
        style.alignment = TextAnchor.UpperLeft;
        style.fontSize = 14;
        
        string debugText = "=== ZEITKLINGEN DEBUG ===\n";
        
        // Zeit-Info
        if (timeSystem != null && timeSystem.IsRiftActive())
        {
            debugText += $"Zeit: {timeSystem.GetTimeDisplayString()} ({timeSystem.GetTimePreciseString()})\n";
            debugText += $"Rift-Typ: {timeSystem.GetCurrentRiftType()}\n";
        }
        else
        {
            debugText += "Rift: INAKTIV\n";
        }
        
        // Punkte-Info
        if (pointSystem != null)
        {
            debugText += $"Punkte: {pointSystem.GetPointsDisplayString()}\n";
            debugText += $"Gegner besiegt: {pointSystem.GetEnemiesDefeated()}\n";
            debugText += $"Boss: {(pointSystem.IsBossSpawned() ? "AKTIV" : "Noch nicht")}\n";
        }
        
        // Spieler-Info
        if (player != null)
        {
            debugText += $"\nSPIELER:\n";
            debugText += $"Schildmacht: {player.GetShieldPower()}/5\n";
            debugText += $"Hand: {player.GetHand().Count} Karten\n";
            debugText += $"Deck: {player.GetDeckCount()} | Ablage: {player.GetDiscardCount()}\n";
            debugText += $"Blockt: {(player.IsBlocking() ? "JA" : "NEIN")}\n";
        }
        
        // Combat-Info
        if (combatManager != null)
        {
            debugText += $"\nKAMPF:\n";
            debugText += $"Status: {combatManager.GetCurrentState()}\n";
            debugText += $"Aktive Gegner: {combatManager.GetActiveEnemies().Count}\n";
        }
        
        // Controls
        debugText += "\n--- CONTROLS ---\n";
        debugText += "R - Neuen Rift starten\n";
        debugText += "T - Tutorial-Rift\n";
        debugText += "S - Standard-Rift\n";
        debugText += "ESC - Test beenden\n";
        
        GUI.Box(new Rect(10, 10, 400, 400), debugText, style);
    }
    
    /// <summary>
    /// Input-Handling
    /// </summary>
    void Update()
    {
        // Test-Controls
        if (Input.GetKeyDown(KeyCode.R))
        {
            StartTestRift();
        }
        
        if (Input.GetKeyDown(KeyCode.T))
        {
            testRiftType = RiftTimeSystem.RiftType.Tutorial;
            StartTestRift();
        }
        
        if (Input.GetKeyDown(KeyCode.S))
        {
            testRiftType = RiftTimeSystem.RiftType.Standard;
            StartTestRift();
        }
        
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Debug.Log("[Test] Test beendet");
            #if UNITY_EDITOR
                UnityEditor.EditorApplication.isPlaying = false;
            #else
                Application.Quit();
            #endif
        }
        
        // Debug-Cheats
        if (Input.GetKeyDown(KeyCode.F1))
        {
            // Zeit hinzufügen
            if (timeSystem != null)
            {
                timeSystem.AddTime(10f);
                Debug.Log("[Cheat] +10s Zeit");
            }
        }
        
        if (Input.GetKeyDown(KeyCode.F2))
        {
            // Punkte hinzufügen
            if (pointSystem != null)
            {
                pointSystem.AddPointsForEnemy(RiftPointSystem.EnemyTier.Elite, 2f);
                Debug.Log("[Cheat] +20-30 Punkte");
            }
        }
        
        if (Input.GetKeyDown(KeyCode.F3))
        {
            // Schildmacht erhöhen
            if (player != null)
            {
                var sp = player.GetComponent<ShieldPowerSystem>();
                if (sp != null)
                {
                    sp.OnSuccessfulBlock();
                    Debug.Log("[Cheat] +1 Schildmacht");
                }
            }
        }
    }
}
