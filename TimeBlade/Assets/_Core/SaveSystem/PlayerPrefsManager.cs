using UnityEngine;

public class PlayerPrefsManager : MonoBehaviour
{
    // Singleton Instance
    public static PlayerPrefsManager Instance { get; private set; }

    // Keys for PlayerPrefs
    private const string MASTER_VOLUME_KEY = "MasterVolume";
    private const string MUSIC_VOLUME_KEY = "MusicVolume";
    private const string SFX_VOLUME_KEY = "SfxVolume";

    // Default values
    private const float DEFAULT_VOLUME = 0.8f;

    void Awake()
    {
        // Singleton Pattern
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

    // --- Master Volume ---
    public void SetMasterVolume(float volume)
    {
        PlayerPrefs.SetFloat(MASTER_VOLUME_KEY, Mathf.Clamp01(volume));
        PlayerPrefs.Save(); // Immediately save PlayerPrefs
        // TODO: Apply volume to an AudioManager or directly to AudioMixer group
        Debug.Log($"Master Volume set to: {volume}");
    }

    public float GetMasterVolume()
    {
        return PlayerPrefs.GetFloat(MASTER_VOLUME_KEY, DEFAULT_VOLUME);
    }

    // --- Music Volume ---
    public void SetMusicVolume(float volume)
    {
        PlayerPrefs.SetFloat(MUSIC_VOLUME_KEY, Mathf.Clamp01(volume));
        PlayerPrefs.Save();
        // TODO: Apply volume
        Debug.Log($"Music Volume set to: {volume}");
    }

    public float GetMusicVolume()
    {
        return PlayerPrefs.GetFloat(MUSIC_VOLUME_KEY, DEFAULT_VOLUME);
    }

    // --- SFX Volume ---
    public void SetSfxVolume(float volume)
    {
        PlayerPrefs.SetFloat(SFX_VOLUME_KEY, Mathf.Clamp01(volume));
        PlayerPrefs.Save();
        // TODO: Apply volume
        Debug.Log($"SFX Volume set to: {volume}");
    }

    public float GetSfxVolume()
    {
        return PlayerPrefs.GetFloat(SFX_VOLUME_KEY, DEFAULT_VOLUME);
    }

    // Example: Call this at game start to apply loaded settings
    public void ApplyAllSoundSettings()
    {
        float masterVol = GetMasterVolume();
        // TODO: audioManager.SetMasterVolume(masterVol);
        float musicVol = GetMusicVolume();
        // TODO: audioManager.SetMusicVolume(musicVol);
        float sfxVol = GetSfxVolume();
        // TODO: audioManager.SetSfxVolume(sfxVol);
        Debug.Log("Applied all sound settings from PlayerPrefs.");
    }
}
