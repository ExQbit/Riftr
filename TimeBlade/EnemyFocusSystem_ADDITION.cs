// ERWEITERUNG für EnemyFocusSystem.cs - Diese Methoden müssen hinzugefügt werden

// Füge diese Konstante/Feld am Anfang der Klasse hinzu:
private const int MAX_VISIBLE_ENEMIES = 7; // Nur die ersten 7 Gegner sind sichtbar und greifen an

// Ändere die UpdateQueueVisualization() Methode:
private void UpdateQueueVisualization()
{
    // Entferne alte Visualisierungen
    ClearVisualizations();
    
    // Erstelle neue Sphären für alle Gegner in der Queue
    var queueList = enemyQueue.ToList();
    for (int i = 0; i < queueList.Count; i++)
    {
        var enemy = queueList[i];
        if (enemy == null || enemy.IsDead()) continue;
        
        // NUR die ersten MAX_VISIBLE_ENEMIES (7) Gegner werden visualisiert
        if (i < MAX_VISIBLE_ENEMIES)
        {
            GameObject sphere = Instantiate(enemySpherePrefab, queueSphereContainer);
            enemyVisuals[enemy] = sphere;
            
            // Setup der Sphere-Komponente
            var sphereDisplay = sphere.GetComponent<EnemySphereDisplay>();
            if (sphereDisplay != null)
            {
                sphereDisplay.SetEnemy(enemy);
            }
            
            Debug.Log($"[EnemyFocusSystem] Visualisiere aktiven Gegner #{i+1}: {enemy.name}");
        }
        else
        {
            // Reserve-Gegner (unsichtbar, nicht angreifend)
            Debug.Log($"[EnemyFocusSystem] Reserve-Gegner #{i+1}: {enemy.name} (unsichtbar, greift nicht an)");
            
            // WICHTIG: Reserve-Gegner dürfen NICHT angreifen
            enemy.SetActive(false);
        }
    }
    
    // Event für Queue-Update
    OnQueueUpdated?.Invoke(GetActiveEnemies());
}

// Neue Hilfsmethode: Gibt nur die aktiven (sichtbaren) Gegner zurück
public List<RiftEnemy> GetActiveEnemies()
{
    var queueList = enemyQueue.ToList();
    var activeEnemies = new List<RiftEnemy>();
    
    for (int i = 0; i < Mathf.Min(queueList.Count, MAX_VISIBLE_ENEMIES); i++)
    {
        if (queueList[i] != null && !queueList[i].IsDead())
        {
            activeEnemies.Add(queueList[i]);
        }
    }
    
    return activeEnemies;
}

// Neue Hilfsmethode: Gibt die Reserve-Gegner zurück
public List<RiftEnemy> GetReserveEnemies()
{
    var queueList = enemyQueue.ToList();
    var reserveEnemies = new List<RiftEnemy>();
    
    for (int i = MAX_VISIBLE_ENEMIES; i < queueList.Count; i++)
    {
        if (queueList[i] != null && !queueList[i].IsDead())
        {
            reserveEnemies.Add(queueList[i]);
        }
    }
    
    return reserveEnemies;
}

// Erweitere HandleEnemyDeath() um Reserve-Nachrücken:
private void HandleEnemyDeath(RiftEnemy enemy)
{
    // ... existierender Code ...
    
    // Nach dem Entfernen des toten Gegners:
    // Prüfe ob ein Reserve-Gegner nachrücken kann
    var queueList = enemyQueue.ToList();
    if (queueList.Count >= MAX_VISIBLE_ENEMIES)
    {
        // Aktiviere den ersten Reserve-Gegner (jetzt an Position MAX_VISIBLE_ENEMIES-1)
        var newActiveEnemy = queueList[MAX_VISIBLE_ENEMIES - 1];
        if (newActiveEnemy != null && !newActiveEnemy.IsActive())
        {
            newActiveEnemy.SetActive(true);
            Debug.Log($"[EnemyFocusSystem] Reserve-Gegner {newActiveEnemy.name} rückt in aktive Queue nach!");
        }
    }
    
    // ... rest des existierenden Codes ...
}