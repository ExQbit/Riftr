using UnityEngine;
using UnityEngine.Audio; // Für AudioMixer (später)
using System; // Für Serializable
using System.Collections.Generic; // Für Listen/Dictionaries (später)

// Einfache Datenstruktur für Sound-Definitionen
[Serializable]
public class Sound
{
    public string name;
    public AudioClip clip;

    [Range(0f, 1f)]
    public float volume = 1f;
    [Range(.1f, 3f)]
    public float pitch = 1f;

    public bool loop = false;

    [HideInInspector]
    public AudioSource source; // Referenz auf die AudioSource, die diesen Sound spielt (wird zur Laufzeit zugewiesen)
}

public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance { get; private set; }

    [Header("Audio Sources")]
    [SerializeField] private AudioSource musicSource; // Dedizierte Quelle für Musik
    [SerializeField] private AudioSource sfxSource;   // Dedizierte Quelle für einmalige SFX
    // WICHTIG: Die Ausgabe dieser Sources muss im Editor auf die entsprechenden AudioMixer-Gruppen gesetzt werden!

    [Header("Audio Mixer")]
    [SerializeField] private AudioMixer mainMixer; // Referenz zum Haupt-AudioMixer
    // Namen der exponierten Lautstärkeparameter im Mixer
    private const string MASTER_VOLUME_PARAM = "MasterVolume"; 
    private const string MUSIC_VOLUME_PARAM = "MusicVolume";
    private const string SFX_VOLUME_PARAM = "SFXVolume";

    [Header("Sound Definitions")]
    [SerializeField] private Sound[] sounds; // Array zur Definition der Sounds im Inspector

    // Sound Namen (sollten mit den Namen in der 'sounds' Liste übereinstimmen)
    private const string TimerWarningSound = "TimerWarning"; // Beispielname
    private const string TimerCriticalSound = "TimerCritical"; // Beispielname

    // TODO: Implement methods to play music (e.g., PlayMusic(AudioClip clip)) - Teilweise erledigt
    // TODO: Implement methods to play sound effects (e.g., PlaySFX(AudioClip clip, Vector3 position)) - Teilweise erledigt
    // TODO: Volume-Einstellungen laden/speichern (z.B. via SaveManager/PlayerPrefs)

    private void Awake()
    {
        // Singleton-Pattern Implementierung
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return; 
        }
        Instance = this;
        DontDestroyOnLoad(gameObject); // AudioManager sollte über Szenen hinweg bestehen bleiben
    }

    void Start()
    {
        Debug.Log("AudioManager Initialized");
        // TODO: AudioSources hinzufügen/konfigurieren (im Editor!)
        // TODO: Sound Array durchgehen und ggf. initialisieren oder in Dictionary laden für schnellen Zugriff
        SubscribeToTimeManagerEvents();
    }

    void OnDestroy()
    {
        UnsubscribeFromTimeManagerEvents();
    }

    // --- Lautstärkeregelung --- 

    public void SetMasterVolume(float linearVolume)
    {
        // Konvertiert linearen Wert (0-1) in logarithmischen Dezibelwert (-80 bis 0)
        float dbVolume = LinearToDecibel(linearVolume);
        SetMixerVolume(MASTER_VOLUME_PARAM, dbVolume);
    }

    public void SetMusicVolume(float linearVolume)
    {
        float dbVolume = LinearToDecibel(linearVolume);
        SetMixerVolume(MUSIC_VOLUME_PARAM, dbVolume);
    }

    public void SetSFXVolume(float linearVolume)
    {
        float dbVolume = LinearToDecibel(linearVolume);
        SetMixerVolume(SFX_VOLUME_PARAM, dbVolume);
    }

    private void SetMixerVolume(string parameterName, float dbVolume)
    {
         if (mainMixer != null)
        {
            mainMixer.SetFloat(parameterName, dbVolume);
            // Debug.Log($"Set {parameterName} to {dbVolume} dB"); // Optional: Logging
        }
        else
        {
            Debug.LogWarning("Main AudioMixer is not assigned!");
        }
    }

    // Hilfsfunktion: Lineares Volumen (0-1) in Dezibel (-80 bis 0) umwandeln
    // AudioMixer verwendet eine logarithmische Skala
    private float LinearToDecibel(float linear)
    {
        // Sicherstellen, dass der Wert im gültigen Bereich ist und nicht 0 ist (log(0) ist undefiniert)
        linear = Mathf.Clamp(linear, 0.0001f, 1f);
        return Mathf.Log10(linear) * 20f;
    }

    // --- Sound abspielen --- 

    // Beispiel: Platzhalter für Soundeffekt - jetzt mit Sound-Suche
    public void PlaySoundEffect(string soundName)
    {
        Sound s = Array.Find(sounds, sound => sound.name == soundName);
        if (s == null)
        {
            Debug.LogWarning($"Sound effect '{soundName}' not found!");
            return;
        }

        // Spiele den Sound über die SFX Quelle ab
        // sfxSource.clip = s.clip; // Nicht gut, wenn mehrere SFX gleichzeitig spielen sollen
        // Besser: PlayOneShot verwenden
        if(sfxSource != null)
        {
            sfxSource.PlayOneShot(s.clip, s.volume);
            Debug.Log($"Playing sound effect: {soundName}");
        }
        else
        {
             Debug.LogWarning("SFX AudioSource is not assigned!");
        }
       
    }

    // Beispiel: Platzhalter für Musik - jetzt mit Sound-Suche
    public void PlayMusic(string musicName)
    {
        Sound s = Array.Find(sounds, sound => sound.name == musicName);
        if (s == null)
        {   
            Debug.LogWarning($"Music '{musicName}' not found!");
            return;
        }

        if (musicSource != null)
        {
            // Stoppe ggf. aktuelle Musik und spiele neue
            if (musicSource.clip == s.clip && musicSource.isPlaying) return; // Nicht neu starten, wenn schon läuft

            musicSource.clip = s.clip;
            musicSource.volume = s.volume; // Individuelle Lautstärke des Clips (wird durch Mixer weiter moduliert)
            musicSource.pitch = s.pitch;
            musicSource.loop = s.loop; // Wichtig für Musik
            musicSource.Play();
            Debug.Log($"Playing music: {musicName}");
        }
        else
        {
            Debug.LogWarning("Music AudioSource is not assigned!");
        }
    }

    private void SubscribeToTimeManagerEvents()
    {
        // Events sind static, kein Instance Check nötig, aber gute Praxis sie nur einmal zu abonnieren
        // und alte Abonnements zu entfernen, bevor neue hinzugefügt werden.
        TimeManager.OnTimerWarning -= HandleTimerWarning; 
        TimeManager.OnTimerWarning += HandleTimerWarning;

        TimeManager.OnTimerCritical -= HandleTimerCritical;
        TimeManager.OnTimerCritical += HandleTimerCritical;

        // Optional: Wenn auch der Timer-Ablauf einen Sound haben soll.
        // TimeManager.OnTimerExpired -= HandleTimerExpiredSound;
        // TimeManager.OnTimerExpired += HandleTimerExpiredSound; 

        Debug.Log("AudioManager subscribed to TimeManager events.");
    }

    private void UnsubscribeFromTimeManagerEvents()
    {
        // Events sind static
        TimeManager.OnTimerWarning -= HandleTimerWarning;
        TimeManager.OnTimerCritical -= HandleTimerCritical;
        // Optional: TimeManager.OnTimerExpired -= HandleTimerExpiredSound;
        Debug.Log("AudioManager unsubscribed from TimeManager events.");
    }

    private void HandleTimerWarning()
    {
        PlaySoundEffect(TimerWarningSound);
         Debug.Log("Playing Timer Warning Sound");
    }

    private void HandleTimerCritical()
    {
        PlaySoundEffect(TimerCriticalSound);
         Debug.Log("Playing Timer Critical Sound");
    }

    // Optional: Falls der Timer-Ablauf selbst einen Sound auslösen soll
    // private void HandleTimerExpiredSound()
    // {
    //     PlaySFX("TimerExpired"); // Beispielname
    //     Debug.Log("Playing Timer Expired Sound");
    // }
}
