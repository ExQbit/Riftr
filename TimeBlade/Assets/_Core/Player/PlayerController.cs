using UnityEngine;
using System;

// Repräsentiert den Spieler im Kampf.
// Verwaltet Spieler-Statistiken und interagiert mit dem CardManager.
public class PlayerController : MonoBehaviour
{
    [Header("Player Stats")]
    [SerializeField] private int maxHealth = 100;
    private int currentHealth;

    // Event für Gesundheitsänderungen (z.B. für UI)
    public static event Action<int, int> OnHealthChanged; // (currentHealth, maxHealth)

    // Referenz zum CardManager (wird benötigt, um Karten zu spielen)
    private CardManager cardManager;

    // Sound Namen
    private const string PlayerHurtSound = "PlayerHurt"; // Beispielname
    private const string PlayerDeathSound = "PlayerDeath"; // Beispielname
    private const string CardPlaySound = "CardPlay";     // Beispielname

    // Event, wenn der Spieler stirbt
    public event Action OnPlayerDied;
    // Event, wenn eine Karte erfolgreich gespielt wurde
    public event Action<CardData> OnCardPlayedSuccessfully; // Informiert, wenn eine Karte gespielt wurde

    void Start()
    {
        currentHealth = maxHealth;
        OnHealthChanged?.Invoke(currentHealth, maxHealth);

        // Finde den CardManager in der Szene
        cardManager = GameObject.FindFirstObjectByType<CardManager>(); // Einfache Methode, kann bei komplexen Szenen angepasst werden
        if (cardManager == null)
        {
            Debug.LogError("PlayerController could not find CardManager!");
        }

        // TODO: Eventuell an Events vom GameManager anmelden (z.B. für Kampfstart/-ende)
    }

    // Öffentliche Methode, um zu versuchen, eine Karte zu spielen.
    // Wird typischerweise von der UI aufgerufen, wenn der Spieler auf eine Karte klickt/zieht.
    public void RequestPlayCard(CardData card)
    {
        if (cardManager != null)
        {
            // Versuche, die Karte über den CardManager zu spielen
            bool success = cardManager.PlayCard(card, null); // TODO: Implement proper target selection
            if (success)
            {
                Debug.Log($"Player successfully initiated playing {card.cardName}");
                OnCardPlayedSuccessfully?.Invoke(card); // Event auslösen

                // Soundeffekt für das Spielen der Karte
                if (AudioManager.Instance != null)
                { 
                    AudioManager.Instance.PlaySoundEffect(CardPlaySound);
                }
                // Hier könnten weitere Aktionen nach erfolgreichem Spielen folgen
            }
            else
            {
                 Debug.Log($"Player failed to play {card.cardName} (handled by CardManager).");
                 // Eventuell UI-Feedback geben
            }
        }
        else
        {
             Debug.LogError("Cannot play card, CardManager reference is missing!");
        }
    }

    // Methode, um Schaden zu erleiden.
    public void TakeDamage(int amount)
    {
        if (amount < 0) amount = 0; // Kein negativer Schaden

        currentHealth -= amount;
        if (currentHealth < 0) currentHealth = 0;

        Debug.Log($"Player took {amount} damage. Current HP: {currentHealth}/{maxHealth}");
        OnHealthChanged?.Invoke(currentHealth, maxHealth); // UI informieren

        // Soundeffekt abspielen
        if (AudioManager.Instance != null)
        { 
            AudioManager.Instance.PlaySoundEffect(PlayerHurtSound);
        }

        if (currentHealth <= 0)
        {
            Die();
        }
    }

    // Methode, um zu heilen.
    public void Heal(int amount)
    {
        if (amount < 0) amount = 0;

        currentHealth += amount;
        if (currentHealth > maxHealth) currentHealth = maxHealth;

        Debug.Log($"Player healed {amount} HP. Current HP: {currentHealth}/{maxHealth}");
        OnHealthChanged?.Invoke(currentHealth, maxHealth); // UI informieren
    }

    // Was passiert, wenn der Spieler stirbt?
    private void Die()
    {
        Debug.Log("Player has been defeated!");
        OnPlayerDied?.Invoke(); // Event auslösen
        // TODO: Spielende-Logik auslösen (z.B. GameManager benachrichtigen, GameOver-Screen)
        // GameManager.Instance.UpdateState(GameState.GameOver); // Beispiel

        // Todes-Soundeffekt abspielen
        if (AudioManager.Instance != null)
        {
             AudioManager.Instance.PlaySoundEffect(PlayerDeathSound);
        }

        gameObject.SetActive(false); // Einfache Deaktivierung
    }

    // Getter für aktuelle Gesundheit
    public int GetCurrentHealth()
    {
        return currentHealth;
    }

    // Getter für maximale Gesundheit
    public int GetMaxHealth()
    {
        return maxHealth;
    }
}
