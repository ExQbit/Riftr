using UnityEngine;
using System.Collections.Generic;
using System;
using System.Collections; // Für Coroutinen

// Repräsentiert einen Gegner im Kampf.
// Verwaltet Gegner-Statistiken und führt Aktionen aus (Basis für KI).
public class EnemyController : MonoBehaviour
{
    [Header("Enemy Stats")]
    [SerializeField] private string enemyName = "Grunt";
    [SerializeField] private int maxHealth = 50;
    private int currentHealth;
    [SerializeField] private int baseDamage = 10;

    // Optional: Widerstände, Schwächen, etc.

    // Event für Gesundheitsänderungen (z.B. für UI)
    public event Action<int, int> OnHealthChanged; // (currentHealth, maxHealth)
    // Event, wenn der Gegner besiegt wurde
    public event Action<EnemyController> OnDefeated;

    // Referenz zum Ziel (normalerweise der Spieler)
    private PlayerController playerTarget;

    [Header("AI Behavior")]
    [SerializeField] private float actionDelay = 2.0f; // Zeit zwischen Aktionen
    private bool isActing = false; // Verhindert überlappende Aktionen

    // TODO: Verfeinern mit Intentions-Anzeige

    // Sound Namen
    private const string EnemyHurtSound = "EnemyHurt"; // Beispielname
    private const string EnemyDeathSound = "EnemyDeath"; // Beispielname

    void Start()
    {
        currentHealth = maxHealth;
        OnHealthChanged?.Invoke(currentHealth, maxHealth);

        // Finde den Spieler in der Szene
        playerTarget = FindFirstObjectByType<PlayerController>(); // CS0618 Fix
        if (playerTarget == null)
        {
            Debug.LogError($"{enemyName} could not find PlayerController!");
        }
    }

    // Wird vom GameManager (oder einer anderen Kontrollinstanz) aufgerufen, 
    // wenn der Gegner am Zug ist.
    public void StartTurn()
    {
        if (currentHealth > 0 && !isActing)
        {
            StartCoroutine(PerformActionSequence());
        }
    }

    // Beispielhafte Aktionssequenz (sehr einfache KI)
    private IEnumerator PerformActionSequence()
    {
        isActing = true;
        Debug.Log($"{enemyName}'s turn begins.");

        // TODO: Intention anzeigen (z.B. "Wird angreifen")
        yield return new WaitForSeconds(actionDelay / 2); // Kurze Pause für Intention

        // Aktion ausführen (z.B. Angriff)
        AttackPlayer();

        yield return new WaitForSeconds(actionDelay / 2); // Pause nach Aktion

        Debug.Log($"{enemyName}'s turn ends.");
        isActing = false;
        // TODO: Signal an GameManager, dass der Zug beendet ist
        // GameManager.Instance.EndEnemyTurn(); // Beispiel
    }

    // Einfache Angriffsaktion
    protected virtual void AttackPlayer()
    {
        if (playerTarget != null && playerTarget.GetCurrentHealth() > 0)
        {
            Debug.Log($"{enemyName} attacks {playerTarget.name} for {baseDamage} damage.");
            playerTarget.TakeDamage(baseDamage);
        }
        else
        {
             Debug.Log($"{enemyName} tries to attack, but target is invalid or defeated.");
        }
    }

    // Methode, um Schaden zu erleiden.
    public void TakeDamage(int amount)
    {
        if (amount < 0) amount = 0;
        if (currentHealth <= 0) return; // Bereits besiegt

        currentHealth -= amount;
        if (currentHealth < 0) currentHealth = 0;

        Debug.Log($"{enemyName} took {amount} damage. Current HP: {currentHealth}/{maxHealth}");
        OnHealthChanged?.Invoke(currentHealth, maxHealth); // UI informieren

        // Soundeffekt abspielen
        if (AudioManager.Instance != null)
        { 
             AudioManager.Instance.PlaySoundEffect(EnemyHurtSound);
        }

        if (currentHealth <= 0)
        {
            Die();
        }
    }

    // Was passiert, wenn der Gegner stirbt?
    protected virtual void Die()
    {
        Debug.Log($"{enemyName} has been defeated!");

        // Todes-Soundeffekt abspielen
        if (AudioManager.Instance != null)
        { 
            AudioManager.Instance.PlaySoundEffect(EnemyDeathSound);
        }

        OnDefeated?.Invoke(this); // Andere Systeme informieren (z.B. Belohnungen)
        // TODO: Visuelle Effekte, Sound
        Destroy(gameObject, 1.0f); // Objekt mit kleiner Verzögerung zerstören
    }

    // Getter
    public int GetCurrentHealth() => currentHealth;
    public int GetMaxHealth() => maxHealth;
    public string GetName() => enemyName;
}
