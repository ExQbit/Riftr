using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using System;

/// <summary>
/// Enemy Focus System für Zeitklingen.
/// Verwaltet die Warteschlange der Feinde und bestimmt, welcher Feind aktuell fokussiert ist.
/// </summary>
public class EnemyFocusSystem : MonoBehaviour
{
    // Singleton
    public static EnemyFocusSystem Instance { get; private set; }
    
    // Enemy Queue
    private Queue<RiftEnemy> enemyQueue = new Queue<RiftEnemy>();
    private RiftEnemy currentFocusedEnemy = null;
    private RiftBoss currentBoss = null;
    
    // Dynamic references to spawner settings
    private RiftEnemySpawner enemySpawner;
    
    // Cached values for performance
    private int maxActiveEnemies = 7;
    private int maxReserveEnemies = 3;
    
    // Summoned Enemies tracking
    private List<RiftEnemy> summonedEnemies = new List<RiftEnemy>();
    
    // LOG-SPAM REDUZIERUNG: Debug-Level Control
    [Header("Debug Settings")]
    [SerializeField] private bool enableDetailedLogs = false; // Standard: false für weniger Spam
    
    // Events
    public static event Action<RiftEnemy> OnFocusChanged;
    public static event Action<RiftEnemy> OnEnemyAddedToQueue;
    public static event Action<RiftEnemy> OnEnemyRemovedFromQueue;
    public static event Action<List<RiftEnemy>> OnQueueUpdated;
    
    // UI References
    [Header("UI Setup")]
    [SerializeField] private Transform centralCardPosition; // Wo die große Karte angezeigt wird
    [SerializeField] private Transform queueSphereContainer; // Container für kleine Sphären
    [SerializeField] private GameObject enemyCardPrefab; // Große Karten-Darstellung
    [SerializeField] private GameObject enemySpherePrefab; // Kleine Sphären-Darstellung
    
    // Visual tracking
    private Dictionary<RiftEnemy, GameObject> enemyVisuals = new Dictionary<RiftEnemy, GameObject>();
    private GameObject currentCentralCard = null;
    
    void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }
    
    void Start()
    {
        // Find the RiftEnemySpawner and cache its values
        enemySpawner = FindFirstObjectByType<RiftEnemySpawner>();
        if (enemySpawner != null)
        {
            maxActiveEnemies = enemySpawner.maxActiveEnemiesInQueue;
            maxReserveEnemies = enemySpawner.maxReserveQueueEnemies;
            // Debug.Log($"[EnemyFocus] Using spawner settings: {maxActiveEnemies} active, {maxReserveEnemies} reserve");
        }
        else
        {
            Debug.LogWarning("[EnemyFocus] RiftEnemySpawner not found! Using default values.");
        }
    }
    
    /// <summary>
    /// Fügt einen neuen Feind zur Warteschlange hinzu
    /// </summary>
    public void AddEnemyToQueue(RiftEnemy enemy)
    {
        if (enemy == null) return;
        
        // Boss-Spezialbehandlung
        if (enemy is RiftBoss boss)
        {
            HandleBossSpawn(boss);
            return;
        }
        
        // Neue Gegner werden zunächst zur Queue hinzugefügt
        // Die Aktiv/Reserve-Logik wird später in UpdateEnemyActiveStates() angewendet
        
        // Prüfe Feind-Attribute
        EnemyAttribute attribute = enemy.GetAttribute();
        
        switch (attribute)
        {
            case EnemyAttribute.Aggressor:
                // Aggressor wird sofort zum Fokus
                AddToFront(enemy);
                break;
                
            case EnemyAttribute.Guardian:
                // Guardian spawnt vor dem zu schützenden Feind
                AddGuardian(enemy);
                break;
                
            case EnemyAttribute.Ambush:
            case EnemyAttribute.Supporter:
            default:
                // Standard: Hinten anfügen
                AddToBack(enemy);
                break;
        }
        
        // Event für Tod registrieren
        enemy.OnDeath += delegate { HandleEnemyDeath(enemy); };
        
        // WICHTIG: Aktiv/Reserve-Status aller Gegner aktualisieren
        UpdateEnemyActiveStates();
        
        UpdateFocus();
        OnEnemyAddedToQueue?.Invoke(enemy);
        UpdateQueueVisualization();
    }
    
    /// <summary>
    /// Boss-Spawn-Behandlung
    /// </summary>
    private void HandleBossSpawn(RiftBoss boss)
    {
        currentBoss = boss;
        boss.OnDeath += delegate { HandleBossDeath(); };
        boss.OnEnemySummoned += HandleSummonedEnemy;
        
        // Boss wird immer als zentrale Karte angezeigt
        ShowCentralCard(boss);
        
        // Debug.Log($"[EnemyFocus] BOSS gespawnt: {boss.name}");
    }
    
    /// <summary>
    /// Behandelt vom Boss beschworene Feinde
    /// </summary>
    private void HandleSummonedEnemy(RiftEnemy summoned)
    {
        summonedEnemies.Add(summoned);
        summoned.SetAttribute(EnemyAttribute.Summoned);
        
        // Summoned Enemies werden direkt hinter dem Boss eingefügt
        enemyQueue = new Queue<RiftEnemy>(enemyQueue.Where(e => e != summoned));
        var tempList = enemyQueue.ToList();
        tempList.Insert(0, summoned); // An den Anfang (Boss ist nicht in Queue)
        enemyQueue = new Queue<RiftEnemy>(tempList);
        
        summoned.OnDeath += delegate {
            summonedEnemies.Remove(summoned);
            HandleEnemyDeath(summoned);
            CheckBossVulnerability();
        };
        
        UpdateFocus();
        UpdateQueueVisualization();
    }
    
    /// <summary>
    /// Prüft ob der Boss verwundbar ist (alle Summoned tot)
    /// </summary>
    private void CheckBossVulnerability()
    {
        if (currentBoss != null && summonedEnemies.Count == 0)
        {
            currentBoss.SetVulnerable(true);
            if (enableDetailedLogs) Debug.Log("[EnemyFocus] Boss ist jetzt verwundbar!");
            // TODO: Visuelles Feedback (Schild-Icon entfernen)
        }
    }
    
    /// <summary>
    /// Fügt Feind vorne an (Aggressor)
    /// </summary>
    private void AddToFront(RiftEnemy enemy)
    {
        var tempList = enemyQueue.ToList();
        tempList.Insert(0, enemy);
        enemyQueue = new Queue<RiftEnemy>(tempList);
        
        // Debug.Log($"[EnemyFocus] Aggressor {enemy.name} an die Spitze!");
        
        // Wenn Aggressor an die Spitze springt, müssen wir sicherstellen,
        // dass nur die ersten maxActiveEnemies aktiv bleiben
        UpdateEnemyActiveStates();
    }
    
    /// <summary>
    /// Fügt Feind hinten an (Standard)
    /// </summary>
    private void AddToBack(RiftEnemy enemy)
    {
        enemyQueue.Enqueue(enemy);
        
        // // Debug.Log($"[EnemyFocus] {enemy.name} hinten angefügt"); // REDUCED LOGGING
    }
    
    /// <summary>
    /// Fügt Guardian vor geschütztem Feind ein
    /// </summary>
    private void AddGuardian(RiftEnemy guardian)
    {
        // Finde Elite oder Boss zum Schützen
        var tempList = enemyQueue.ToList();
        int insertIndex = 0;
        
        for (int i = 0; i < tempList.Count; i++)
        {
            if (tempList[i].Tier == RiftPointSystem.EnemyTier.Elite || 
                tempList[i].Tier == RiftPointSystem.EnemyTier.MiniBoss)
            {
                insertIndex = i;
                guardian.SetProtectedTarget(tempList[i]);
                break;
            }
        }
        
        tempList.Insert(insertIndex, guardian);
        enemyQueue = new Queue<RiftEnemy>(tempList);
        
        // Debug.Log($"[EnemyFocus] Guardian {guardian.name} schützt jetzt einen Elite-Feind");
        
        // Sicherstellen, dass nur die ersten maxActiveEnemies aktiv sind
        UpdateEnemyActiveStates();
    }
    
    /// <summary>
    /// Behandelt den Tod eines Feindes
    /// </summary>
    private void HandleEnemyDeath(RiftEnemy enemy)
    {
        // Aus Queue entfernen
        enemyQueue = new Queue<RiftEnemy>(enemyQueue.Where(e => e != enemy));
        
        // Visuals entfernen
        if (enemyVisuals.ContainsKey(enemy))
        {
            Destroy(enemyVisuals[enemy]);
            enemyVisuals.Remove(enemy);
        }
        
        OnEnemyRemovedFromQueue?.Invoke(enemy);
        
        // WICHTIG: Reserve-Gegner nachrücken lassen
        PromoteReserveEnemies();
        
        UpdateFocus();
        UpdateQueueVisualization();
    }
    
    /// <summary>
    /// Boss-Tod-Behandlung
    /// </summary>
    private void HandleBossDeath()
    {
        Debug.Log("[EnemyFocus] BOSS BESIEGT!");
        currentBoss = null;
        
        if (currentCentralCard != null)
        {
            Destroy(currentCentralCard);
            currentCentralCard = null;
        }
    }
    
    /// <summary>
    /// Aktualisiert den aktuellen Fokus
    /// </summary>
    private void UpdateFocus()
    {
        // Boss-Phase: Fokus ist immer auf Summoned oder Boss
        if (currentBoss != null && currentBoss.gameObject.activeInHierarchy)
        {
            if (summonedEnemies.Count > 0 && enemyQueue.Count > 0)
            {
                // Erstes Summoned in Queue ist Ziel
                currentFocusedEnemy = enemyQueue.Peek();
            }
            else
            {
                // Boss ist direkt angreifbar
                currentFocusedEnemy = currentBoss;
            }
        }
        else if (enemyQueue.Count > 0)
        {
            // Normaler Kampf: Erster in Queue
            currentFocusedEnemy = enemyQueue.Peek();
            ShowCentralCard(currentFocusedEnemy);
        }
        else
        {
            currentFocusedEnemy = null;
            if (currentCentralCard != null && currentBoss == null)
            {
                Destroy(currentCentralCard);
                currentCentralCard = null;
            }
        }
        
        OnFocusChanged?.Invoke(currentFocusedEnemy);
    }
    
    /// <summary>
    /// Zeigt die große zentrale Karte
    /// </summary>
    private void ShowCentralCard(RiftEnemy enemy)
    {
        if (currentCentralCard != null && currentBoss == null) // Boss-Karte bleibt!
        {
            Destroy(currentCentralCard);
        }
        
        if (enemy != null && centralCardPosition != null && enemyCardPrefab != null)
        {
            currentCentralCard = Instantiate(enemyCardPrefab, centralCardPosition);
            
            // Konfiguriere die Karten-Anzeige
            var cardDisplay = currentCentralCard.GetComponent<EnemyCardDisplay>();
            if (cardDisplay != null)
            {
                cardDisplay.SetEnemy(enemy);
                
                // Bei Boss: Shield-Status anzeigen
                if (enemy is RiftBoss)
                {
                    // Boss ist verwundbar wenn keine Summoned Enemies da sind
                    bool isVulnerable = summonedEnemies.Count == 0;
                    // TODO: cardDisplay.ShowBossShield(!isVulnerable);
                }
            }
        }
    }
    
    /// <summary>
    /// Aktualisiert die visuelle Darstellung der Queue
    /// </summary>
    private void UpdateQueueVisualization()
    {
        // Alte Sphären entfernen
        foreach (var visual in enemyVisuals.Values)
        {
            if (visual != null)
                Destroy(visual);
        }
        enemyVisuals.Clear();
        
        if (queueSphereContainer == null || enemySpherePrefab == null) return;
        
        // Neue Sphären erstellen (nur für AKTIVE Gegner sichtbar!)
        int index = 0;
        int visualIndex = 0; // Separate Zählung für Sphären-Positionen
        
        foreach (var enemy in enemyQueue)
        {
            bool isActive = index < maxActiveEnemies;
            
            if (isActive)
            {
                // Aktive Gegner: Sichtbar, können angreifen und bekommen eine Sphäre
                enemy.gameObject.SetActive(true);
                
                GameObject sphere = Instantiate(enemySpherePrefab, queueSphereContainer);
                
                // Position in der Queue (nur für sichtbare Sphären)
                var rectTransform = sphere.GetComponent<RectTransform>();
                if (rectTransform != null)
                {
                    rectTransform.anchoredPosition = new Vector2(visualIndex * 100f, 0); // 100 Pixel Abstand
                }
                
                // Konfiguriere Sphäre
                var sphereDisplay = sphere.GetComponent<EnemySphereDisplay>();
                if (sphereDisplay != null)
                {
                    sphereDisplay.SetEnemy(enemy, visualIndex);
                    
                    // Highlight wenn aktuelles Ziel
                    if (enemy == currentFocusedEnemy && currentBoss != null)
                    {
                        sphereDisplay.SetHighlight(true);
                    }
                }
                
                enemyVisuals[enemy] = sphere;
                visualIndex++; // Nur für aktive Gegner erhöhen
            }
            else
            {
                // Reserve-Gegner: Komplett unsichtbar und können NICHT angreifen
                enemy.gameObject.SetActive(false);
                // if (enableDetailedLogs) Debug.Log($"[EnemyFocus] {enemy.name} ist in Reserve (Position {index + 1})");
            }
            
            index++; // Gesamt-Index für alle Gegner
        }
        
        OnQueueUpdated?.Invoke(enemyQueue.ToList());
    }
    
    /// <summary>
    /// Gibt den aktuell fokussierten Feind zurück
    /// </summary>
    public RiftEnemy GetCurrentTarget()
    {
        return currentFocusedEnemy;
    }
    
    /// <summary>
    /// Gibt die aktuelle Queue zurück
    /// </summary>
    public List<RiftEnemy> GetEnemyQueue()
    {
        return enemyQueue.ToList();
    }
    
    /// <summary>
    /// Prüft ob ein Boss aktiv ist
    /// </summary>
    public bool IsBossActive()
    {
        return currentBoss != null && currentBoss.gameObject.activeInHierarchy;
    }
    
    /// <summary>
    /// Räumt alle Feinde für Boss-Spawn
    /// </summary>
    public void ClearForBoss()
    {
        foreach (var enemy in enemyQueue)
        {
            if (enemy != null && enemy.gameObject != null)
            {
                enemy.Despawn();
            }
        }
        
        enemyQueue.Clear();
        summonedEnemies.Clear();
        
        foreach (var visual in enemyVisuals.Values)
        {
            if (visual != null)
                Destroy(visual);
        }
        enemyVisuals.Clear();
        
        UpdateQueueVisualization();
    }
    
    /// <summary>
    /// Lässt Reserve-Gegner nachrücken wenn aktive Plätze frei werden
    /// </summary>
    private void PromoteReserveEnemies()
    {
        UpdateEnemyActiveStates();
    }
    
    /// <summary>
    /// Aktualisiert die Aktiv/Reserve-Status aller Gegner basierend auf ihrer Position
    /// </summary>
    private void UpdateEnemyActiveStates()
    {
        var queueList = enemyQueue.ToList();
        
        for (int i = 0; i < queueList.Count; i++)
        {
            if (queueList[i] == null || queueList[i].gameObject == null) continue;
            
            bool shouldBeActive = i < maxActiveEnemies;
            bool isCurrentlyActive = queueList[i].gameObject.activeSelf;
            
            if (shouldBeActive && !isCurrentlyActive)
            {
                // Aktiviere Reserve-Gegner
                queueList[i].gameObject.SetActive(true);
                // if (enableDetailedLogs) Debug.Log($"[EnemyFocus] {queueList[i].name} wird aktiviert (Position {i + 1})");
            }
            else if (!shouldBeActive && isCurrentlyActive)
            {
                // Deaktiviere überzählige Gegner
                queueList[i].gameObject.SetActive(false);
                // if (enableDetailedLogs) Debug.Log($"[EnemyFocus] {queueList[i].name} wird in Reserve verschoben (Position {i + 1})");
            }
        }
    }
    
    /// <summary>
    /// Gibt die Anzahl der aktiven Gegner zurück (sichtbar und können angreifen)
    /// KORRIGIERT: Zählt nur die ersten maxActiveEnemies aus der Queue
    /// </summary>
    public int GetActiveEnemyCount()
    {
        return Mathf.Min(enemyQueue.Count, maxActiveEnemies);
    }
    
    /// <summary>
    /// Gibt die Gesamtanzahl aller Gegner zurück (aktive + reserve)
    /// </summary>
    public int GetTotalEnemyCount()
    {
        return enemyQueue.Count;
    }
    
    /// <summary>
    /// Aktualisiert die Spawn-Limits vom RiftEnemySpawner (falls sich Werte ändern)
    /// </summary>
    public void RefreshSpawnerSettings()
    {
        if (enemySpawner != null)
        {
            maxActiveEnemies = enemySpawner.maxActiveEnemiesInQueue;
            maxReserveEnemies = enemySpawner.maxReserveQueueEnemies;
            // Debug.Log($"[EnemyFocus] Settings refreshed: {maxActiveEnemies} active, {maxReserveEnemies} reserve");
            
            // Aktualisiere die aktiven/reserve Status basierend auf neuen Werten
            UpdateEnemyActiveStates();
            UpdateQueueVisualization();
        }
    }
    
    /// <summary>
    /// Gibt die aktuellen Spawn-Limits zurück
    /// </summary>
    public (int maxActive, int maxReserve) GetSpawnLimits()
    {
        return (maxActiveEnemies, maxReserveEnemies);
    }
}

/// <summary>
/// Feind-Attribute für Queue-Positionierung
/// </summary>
public enum EnemyAttribute
{
    None,
    Guardian,   // Spawnt vor geschütztem Feind
    Ambush,     // Spawnt am Ende
    Aggressor,  // Geht sofort an die Spitze
    Supporter,  // Spawnt am Ende, gibt Buffs
    Summoned    // Vom Boss beschworen
}
