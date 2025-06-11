using UnityEngine;
using System.IO;

public class SaveManager : MonoBehaviour
{
    public static SaveManager Instance { get; private set; }

    private GameData currentGameData; // Hält die aktuell geladenen/neuen Daten

    // Event, um andere Systeme über das Laden von Daten zu informieren
    public static event System.Action<GameData> OnDataLoaded;

    private void Awake()
    {
        // Singleton-Pattern Implementierung
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject); // SaveManager sollte über Szenen hinweg bestehen bleiben
        }
        else
        {
            Destroy(gameObject); // Verhindert doppelte Instanzen
        }
    }

    void Start()
    {
        Debug.Log("SaveManager Initialized");
        // Standardmäßig versuchen, beim Start zu laden
        LoadGame();
    }

    // Beispiel für eine Speicherfunktion (Platzhalter)
    public void SaveGame()
    {
        // Beispiel: Hier würden Daten aus dem Spiel in currentGameData gesammelt
        if (currentGameData == null) 
        {
           currentGameData = new GameData(); // Erstelle neue Daten, falls keine geladen
        }
        // Beispiel-Daten aktualisieren (später durch echte Spielwerte ersetzen)
        currentGameData.score += 10;
        currentGameData.playerHealth = Random.Range(50f, 100f); 

        try 
        {
            string json = JsonUtility.ToJson(currentGameData, true); // true für pretty print
            File.WriteAllText(GetSavePath(), json);
            Debug.Log($"Game Saved Successfully to {GetSavePath()} with score {currentGameData.score}");
        }
        catch (System.Exception e)
        {
            Debug.LogError($"Failed to save game: {e.Message}");
        }
    }

    // Beispiel für eine Ladefunktion (Platzhalter)
    public void LoadGame()
    {
        string path = GetSavePath();
        if (File.Exists(path))
        {
            try
            {
                string json = File.ReadAllText(path);
                currentGameData = JsonUtility.FromJson<GameData>(json);
                Debug.Log($"Game Loaded Successfully from {path}. Score: {currentGameData.score}");

                // Andere Systeme über geladene Daten informieren
                OnDataLoaded?.Invoke(currentGameData); 
            }
            catch (System.Exception e)
            {
                Debug.LogError($"Failed to load game from {path}: {e.Message}");
                currentGameData = new GameData(); // Fallback auf neue Daten
                OnDataLoaded?.Invoke(currentGameData); // Auch hier informieren
            }
        }
        else
        {
            Debug.Log("No save file found. Starting with default data.");
            currentGameData = new GameData(); // Keine Datei, also neue Daten erstellen
            OnDataLoaded?.Invoke(currentGameData); // Informieren, dass (neue) Daten bereit sind
        }
    }

    // Hilfsmethode, um den Speicherpfad zu bekommen (Beispiel)
    private string GetSavePath()
    {
        return Path.Combine(Application.persistentDataPath, "savegame.json");
    }
}

// Beispiel für eine Datenstruktur zum Speichern (muss [System.Serializable] sein)
[System.Serializable]
public class GameData
{
    // Standardwerte definieren, falls keine Datei geladen werden kann
    public int score = 0;
    public float playerHealth = 100f;
    public GameState currentGameState = GameState.MainMenu; // Stellt sicher, dass dieses Feld vorhanden ist.
    // Füge hier alle Daten hinzu, die gespeichert werden sollen
}
