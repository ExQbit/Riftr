using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// Spawnt Gegner während eines Rifts basierend auf Fortschritt und Zeit.
/// </summary>
public class RiftEnemySpawner : MonoBehaviour
{
    [Header("Spawn-Einstellungen")]
    [SerializeField] private RectTransform enemySpawnParentUITransform; // UI Parent für Feinde
    [SerializeField] private float spawnDelayMin = 2f;
    [SerializeField] private float spawnDelayMax = 3f;
    
    [Header("Debug Settings")]
    [SerializeField] private bool enableSpawnLogs = true; // Aktiviert für Debug
    
    [Header("Spawn-Limitierung")]
    [Tooltip("Maximale Anzahl sichtbarer Gegner die gleichzeitig angreifen können")]
    [SerializeField] public int maxActiveEnemiesInQueue = 7; // Maximale sichtbare Gegner im EnemyQueueContainer (greifen an)
    
    [Tooltip("Maximale Anzahl unsichtbarer Reserve-Gegner die nachruecken können")]
    [SerializeField] public int maxReserveQueueEnemies = 3; // Maximale Gegner in unsichtbarer Reserve (greifen nicht an)
    
    [Header("Gegner-Prefabs")]
    [SerializeField] private GameObject[] standardEnemyPrefabs;
    [SerializeField] private GameObject[] eliteEnemyPrefabs;
    [SerializeField] private GameObject bossPrefab;
    
    [Header("Spezielle Gegner-Prefabs")]
    [SerializeField] private GameObject rudelEchoPrefab;
    [SerializeField] private GameObject guardianEchoPrefab;
    [SerializeField] private GameObject aggressorEchoPrefab;
    [SerializeField] private GameObject ambushEchoPrefab;
    [SerializeField] private GameObject supporterEchoPrefab;
    [SerializeField] private GameObject eliteZeitJaegerPrefab;
    
    // Tutorial-Gegner
    [Header("Tutorial")]
    [SerializeField] private GameObject tutorialEnemyPrefab;
    
    // Spawn-State
    private bool isSpawning = false;
    private Coroutine spawnCoroutine;
    private RiftTimeSystem.RiftType currentRiftType;
    
    // Spawn-Gewichtung basierend auf Fortschritt
    private int enemiesSpawnedThisRift = 0;
    
    /// <summary>
    /// Startet das Spawning für einen Rift
    /// </summary>
    public void StartSpawning(RiftTimeSystem.RiftType riftType)
    {
        if (isSpawning) return;
        
        currentRiftType = riftType;
        isSpawning = true;
        enemiesSpawnedThisRift = 0;
        
        // Stelle sicher, dass das EnemyFocusSystem die aktuellen Limits kennt
        NotifySpawnLimitsChanged();
        
        Debug.Log($"[EnemySpawner] Starte Spawning für {riftType} Rift");
        
        spawnCoroutine = StartCoroutine(SpawnLoop());
    }
    
    /// <summary>
    /// Stoppt das Spawning
    /// </summary>
    public void StopSpawning()
    {
        isSpawning = false;
        
        if (spawnCoroutine != null)
        {
            StopCoroutine(spawnCoroutine);
            spawnCoroutine = null;
        }
        
        Debug.Log("[EnemySpawner] Spawning gestoppt");
    }
    
    /// <summary>
    /// Haupt-Spawn-Loop
    /// </summary>
    private IEnumerator SpawnLoop()
    {
        // REDUZIERTE initiale Verzögerung für schnelleres Testing
        yield return new WaitForSeconds(0.1f);
        
        // Spawne ersten Gegner sofort für Testing
        Debug.Log("[EnemySpawner] Spawning first enemy immediately for testing");
        SpawnEnemy();
        enemiesSpawnedThisRift++;
        
        while (isSpawning)
        {
            // Spawn-Verzögerung
            float delay = Random.Range(spawnDelayMin, spawnDelayMax);
            yield return new WaitForSeconds(delay);
            
            if (!isSpawning) break;
            
            // Gegner spawnen
            SpawnEnemy();
            
            enemiesSpawnedThisRift++;
        }
    }
    
    /// <summary>
    /// Spawnt einen einzelnen Gegner
    /// </summary>
    private void SpawnEnemy()
    {
        // Prüfe Spawn-Limit
        if (!CanSpawnEnemy())
        {
            if (enableSpawnLogs) Debug.Log($"[EnemySpawner] Spawn-Limit erreicht (Aktive: {GetActiveEnemyCount()}/{maxActiveEnemiesInQueue}, Total: {GetTotalEnemyCount()}/{maxActiveEnemiesInQueue + maxReserveQueueEnemies})");
            return;
        }
        
        GameObject enemyPrefab = SelectEnemyToSpawn();
        
        if (enemyPrefab == null)
        {
            Debug.LogWarning("[EnemySpawner] Kein Gegner-Prefab gefunden!");
            return;
        }
        
        if (enemySpawnParentUITransform == null)
        {
            Debug.LogError("[EnemySpawner] Enemy Spawn Parent UI Transform nicht zugewiesen!");
            return;
        }
        
        // Spawnen als UI-Element
        GameObject enemy = Instantiate(enemyPrefab, enemySpawnParentUITransform);
        
        // Zum Focus System hinzufügen
        RiftEnemy enemyComponent = enemy.GetComponent<RiftEnemy>();
        if (enemyComponent != null && EnemyFocusSystem.Instance != null)
        {
            EnemyFocusSystem.Instance.AddEnemyToQueue(enemyComponent);
        }
        
        Debug.Log($"[EnemySpawner] Gegner gespawnt: {enemy.name} (#{enemiesSpawnedThisRift})");
    }
    
    /// <summary>
    /// Prüft ob ein neuer Gegner gespawnt werden kann
    /// KORRIGIERT: Berücksichtigt nur das Gesamt-Maximum (aktive + reserve)
    /// </summary>
    private bool CanSpawnEnemy(int additionalEnemies = 1)
    {
        if (EnemyFocusSystem.Instance == null) return false;
        
        // Hole aktuelle Gesamtanzahl der Gegner in der Queue
        int totalCount = GetTotalEnemyCount();
        int maxTotal = maxActiveEnemiesInQueue + maxReserveQueueEnemies;
        
        // Prüfe nur das Gesamt-Maximum (aktive + reserve)
        bool canSpawn = (totalCount + additionalEnemies) <= maxTotal;
        
        if (!canSpawn)
        {
            Debug.Log($"[EnemySpawner] Spawn verweigert: Total-Limit erreicht ({totalCount + additionalEnemies}/{maxTotal})");
        }
        else
        {
            // Debug.Log($"[EnemySpawner] Spawn erlaubt: Total={totalCount + additionalEnemies}/{maxTotal}"); // REDUCED LOGGING
        }
        
        return canSpawn;
    }
    
    /// <summary>
    /// Unity Editor Callback für Inspector-Änderungen
    /// </summary>
    void OnValidate()
    {
        // Stelle sicher, dass die Werte sinnvoll sind
        maxActiveEnemiesInQueue = Mathf.Max(1, maxActiveEnemiesInQueue);
        maxReserveQueueEnemies = Mathf.Max(0, maxReserveQueueEnemies);
        
        // Benachrichtige das EnemyFocusSystem über Änderungen (nur zur Laufzeit)
        if (Application.isPlaying)
        {
            NotifySpawnLimitsChanged();
        }
    }
    
    /// <summary>
    /// Zählt aktive Gegner (die angreifen können, im EnemyQueueContainer sichtbar)
    /// </summary>
    private int GetActiveEnemyCount()
    {
        if (EnemyFocusSystem.Instance == null) return 0;
        
        // Nutze die Methode vom EnemyFocusSystem
        return EnemyFocusSystem.Instance.GetActiveEnemyCount();
    }
    
    /// <summary>
    /// Zählt alle Gegner in der Queue (aktive + reserve)
    /// </summary>
    private int GetTotalEnemyCount()
    {
        if (EnemyFocusSystem.Instance == null) return 0;
        
        // Nutze die Methode vom EnemyFocusSystem
        return EnemyFocusSystem.Instance.GetTotalEnemyCount();
    }
    
    /// <summary>
    /// Spawnt spezielle Gegner-Kombination
    /// </summary>
    private void SpawnSpecialCombination()
    {
        float rand = Random.value;
        
        // 20% Chance für Rudel (3 Gegner)
        if (rand < 0.2f && rudelEchoPrefab != null && CanSpawnEnemy(3))
        {
            SpawnRudelGroup();
        }
        // 15% Chance für Elite mit Guardian (2 Gegner)
        else if (rand < 0.35f && eliteZeitJaegerPrefab != null && guardianEchoPrefab != null && CanSpawnEnemy(2))
        {
            SpawnEliteWithGuardian();
        }
        // 10% Chance für Ambush (1 Gegner)
        else if (rand < 0.45f && ambushEchoPrefab != null && CanSpawnEnemy(1))
        {
            SpawnAmbush();
        }
    }
    
    /// <summary>
    /// Spawnt ein Rudel (3 Gegner)
    /// </summary>
    private void SpawnRudelGroup()
    {
        // Nochmal prüfen ob genug Platz ist
        if (!CanSpawnEnemy(3))
        {
            Debug.Log("[EnemySpawner] Nicht genug Platz für Rudel-Spawn");
            return;
        }
        
        Debug.Log("[EnemySpawner] Spawne RUDEL!");
        
        for (int i = 0; i < 3; i++)
        {
            // Prüfe vor jedem einzelnen Spawn
            if (!CanSpawnEnemy())
            {
                Debug.Log($"[EnemySpawner] Rudel-Spawn abgebrochen nach {i} Gegnern (Limit erreicht)");
                break;
            }
            
            GameObject rudelMember = Instantiate(rudelEchoPrefab, enemySpawnParentUITransform);
            RudelEcho echo = rudelMember.GetComponent<RudelEcho>();
            
            if (echo != null && EnemyFocusSystem.Instance != null)
            {
                EnemyFocusSystem.Instance.AddEnemyToQueue(echo);
            }
        }
    }
    
    /// <summary>
    /// Spawnt Elite mit Guardian
    /// </summary>
    private void SpawnEliteWithGuardian()
    {
        // Nochmal prüfen ob genug Platz ist
        if (!CanSpawnEnemy(2))
        {
            Debug.Log("[EnemySpawner] Nicht genug Platz für Elite + Guardian");
            return;
        }
        
        Debug.Log("[EnemySpawner] Spawne ELITE mit GUARDIAN!");
        
        // Erst Elite
        if (!CanSpawnEnemy())
        {
            Debug.Log("[EnemySpawner] Kein Platz mehr für Elite");
            return;
        }
        
        GameObject elite = Instantiate(eliteZeitJaegerPrefab, enemySpawnParentUITransform);
        RiftEnemy eliteEnemy = elite.GetComponent<RiftEnemy>();
        
        if (eliteEnemy != null && EnemyFocusSystem.Instance != null)
        {
            EnemyFocusSystem.Instance.AddEnemyToQueue(eliteEnemy);
        }
        
        // Dann Guardian
        if (!CanSpawnEnemy())
        {
            Debug.Log("[EnemySpawner] Kein Platz mehr für Guardian");
            return;
        }
        
        GameObject guardian = Instantiate(guardianEchoPrefab, enemySpawnParentUITransform);
        GuardianEcho guardianEnemy = guardian.GetComponent<GuardianEcho>();
        
        if (guardianEnemy != null && EnemyFocusSystem.Instance != null)
        {
            guardianEnemy.SetProtectedTarget(eliteEnemy);
            EnemyFocusSystem.Instance.AddEnemyToQueue(guardianEnemy);
        }
    }
    
    /// <summary>
    /// Spawnt Ambush-Gegner
    /// </summary>
    private void SpawnAmbush()
    {
        Debug.Log("[EnemySpawner] AMBUSH!");
        
        GameObject ambush = Instantiate(ambushEchoPrefab, enemySpawnParentUITransform);
        AmbushEcho ambushEnemy = ambush.GetComponent<AmbushEcho>();
        
        if (ambushEnemy != null && EnemyFocusSystem.Instance != null)
        {
            EnemyFocusSystem.Instance.AddEnemyToQueue(ambushEnemy);
        }
    }
    
    /// <summary>
    /// Wählt welcher Gegner gespawnt werden soll
    /// </summary>
    private GameObject SelectEnemyToSpawn()
    {
        // Tutorial-Rift: Nur Tutorial-Gegner
        if (currentRiftType == RiftTimeSystem.RiftType.Tutorial)
        {
            return tutorialEnemyPrefab;
        }
        
        // Fortschritt berechnen
        float riftProgress = RiftPointSystem.Instance.GetProgress();
        
        // 30% Chance für spezielle Kombinationen
        if (Random.value < 0.3f)
        {
            SpawnSpecialCombination();
            return null; // Schon gespawnt
        }
        
        // Elite-Chance steigt mit Fortschritt
        float eliteChance = riftProgress * 0.3f; // Max 30% bei vollem Fortschritt
        
        // Elite spawnen?
        if (Random.value < eliteChance && eliteEnemyPrefabs.Length > 0)
        {
            return eliteEnemyPrefabs[Random.Range(0, eliteEnemyPrefabs.Length)];
        }
        
        // Spezifische Gegner-Typen mit Chance
        float typeRoll = Random.value;
        if (typeRoll < 0.15f && aggressorEchoPrefab != null)
        {
            return aggressorEchoPrefab;
        }
        else if (typeRoll < 0.25f && supporterEchoPrefab != null)
        {
            return supporterEchoPrefab;
        }
        
        // Standard-Gegner
        if (standardEnemyPrefabs.Length > 0)
        {
            return standardEnemyPrefabs[Random.Range(0, standardEnemyPrefabs.Length)];
        }
        
        return null;
    }
    
    /// <summary>
    /// Spawnt den Rift-Boss
    /// </summary>
    public GameObject SpawnBoss()
    {
        if (bossPrefab == null)
        {
            Debug.LogError("[EnemySpawner] Kein Boss-Prefab zugewiesen!");
            return null;
        }
        
        if (enemySpawnParentUITransform == null)
        {
            Debug.LogError("[EnemySpawner] Enemy Spawn Parent UI Transform nicht zugewiesen!");
            return null;
        }
        
        // Boss als UI-Element spawnen
        GameObject boss = Instantiate(bossPrefab, enemySpawnParentUITransform);
        
        // Boss zum Focus System hinzufügen
        RiftBoss bossComponent = boss.GetComponent<RiftBoss>();
        if (bossComponent != null && EnemyFocusSystem.Instance != null)
        {
            EnemyFocusSystem.Instance.AddEnemyToQueue(bossComponent);
        }
        
        Debug.Log("[EnemySpawner] BOSS GESPAWNT!");
        
        // Spawning stoppen
        StopSpawning();
        
        return boss;
    }
    
    /// <summary>
    /// Setzt den UI-Parent für Gegner
    /// </summary>
    public void SetEnemyUIParent(RectTransform uiParent)
    {
        enemySpawnParentUITransform = uiParent;
    }
    
    /// <summary>
    /// Setzt den Spawn-Punkt für Gegner (Kompatibilitätsmethode)
    /// </summary>
    public void SetSpawnPoint(Transform spawnPoint)
    {
        // Konvertiere Transform zu RectTransform wenn möglich
        RectTransform rectTransform = spawnPoint as RectTransform;
        if (rectTransform != null)
        {
            enemySpawnParentUITransform = rectTransform;
        }
        else
        {
            Debug.LogWarning("[EnemySpawner] SetSpawnPoint benötigt ein RectTransform!");
        }
    }
    
    /// <summary>
    /// Benachrichtigt das EnemyFocusSystem über geänderte Spawn-Limits
    /// </summary>
    public void NotifySpawnLimitsChanged()
    {
        if (EnemyFocusSystem.Instance != null)
        {
            EnemyFocusSystem.Instance.RefreshSpawnerSettings();
            Debug.Log($"[EnemySpawner] Spawn-Limits aktualisiert: {maxActiveEnemiesInQueue} aktive, {maxReserveQueueEnemies} reserve");
        }
    }
    
    // Debug-Methoden
    [ContextMenu("Test Spawn Standard Enemy")]
    private void TestSpawnStandard()
    {
        if (standardEnemyPrefabs.Length > 0)
        {
            SpawnEnemy();
        }
    }
    
    [ContextMenu("Test Spawn Boss")]
    private void TestSpawnBoss()
    {
        SpawnBoss();
    }
    
    [ContextMenu("Update Spawn Limits")]
    private void TestUpdateSpawnLimits()
    {
        NotifySpawnLimitsChanged();
    }
}
