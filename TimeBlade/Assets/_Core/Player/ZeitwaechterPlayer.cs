using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// Zeitwächter-Spieler-Controller.
/// WICHTIG: Spieler haben KEINE HP! Nur Zeit als Ressource.
/// </summary>
public class ZeitwaechterPlayer : MonoBehaviour
{
    // Singleton
    public static ZeitwaechterPlayer Instance { get; private set; }
    
    [Header("Klassen-Mechaniken")]
    private ShieldPowerSystem shieldPower;
    private PhaseSystem phaseSystem;
    
    [Header("Deck-System")]
    [SerializeField] private List<TimeCardData> starterDeck = new List<TimeCardData>();
    private List<TimeCardData> currentDeck = new List<TimeCardData>();
    private List<TimeCardData> hand = new List<TimeCardData>();
    private List<TimeCardData> discardPile = new List<TimeCardData>();
    
    [Header("Hand UI Setup")]
    [SerializeField] private Transform handTransform; // Container für Handkarten
    [SerializeField] private GameObject cardPrefab; // Karten-UI-Prefab
    
    private const int MAX_HAND_SIZE = 5;
    private const int INITIAL_DRAW = 5;
    
    // Block-System
    private bool isBlocking = false;
    private float blockEndTime = 0f;
    private Action onBlockSuccess = null;
    
    // Events
    public event Action OnHandChanged; // Instanz-Event für UI
    public static event Action<TimeCardData> OnCardPlayed;
    public static event Action<TimeCardData> OnCardDrawn;
    public static event Action OnDeckShuffled;
    public static event Action<bool> OnBlockStateChanged; // isBlocking
    
    // Komponenten
    private Animator animator;
    
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
            return;
        }
        
        // Komponenten
        animator = GetComponent<Animator>();
        shieldPower = GetComponent<ShieldPowerSystem>();
        if (shieldPower == null)
        {
            shieldPower = gameObject.AddComponent<ShieldPowerSystem>();
        }
        
        phaseSystem = GetComponent<PhaseSystem>();
        if (phaseSystem == null)
        {
            phaseSystem = gameObject.AddComponent<PhaseSystem>();
        }
    }
    
    void Start()
    {
        InitializePlayer();
    }
    
    /// <summary>
    /// Initialisiert den Spieler
    /// </summary>
    private void InitializePlayer()
    {
        // Schildmacht initialisieren
        shieldPower.Initialize();
        
        // Deck vorbereiten
        SetupStarterDeck();
        
        Debug.Log("[Zeitwächter] Spieler initialisiert!");
    }
    
    /// <summary>
    /// Bereitet das Starter-Deck vor
    /// </summary>
    private void SetupStarterDeck()
    {
        currentDeck.Clear();
        hand.Clear();
        discardPile.Clear();
        
        // Starter-Karten aus Factory erstellen
        starterDeck = ZeitwaechterCardFactory.CreateStarterDeck();
        
        // Ins aktuelle Deck kopieren
        currentDeck.AddRange(starterDeck);
        
        // Debug.Log($"[Zeitwächter] Starter-Deck geladen: {currentDeck.Count} Karten");
        
        // Deck mischen
        ShuffleDeck();
    }
    
    /// <summary>
    /// Bereitet den Spieler für den Kampf vor
    /// </summary>
    public void PrepareForCombat()
    {
        // Reset Systeme
        shieldPower.Initialize();
        phaseSystem.Reset();
        
        // Hand zurücksetzen
        hand.Clear();
        discardPile.Clear();
        
        // Deck mischen
        ShuffleDeck();
        
        // Starthand ziehen mit normaler DrawCard Methode
        for (int i = 0; i < INITIAL_DRAW; i++)
        {
            DrawCard();
        }
        
        // Debug.Log($"[Zeitwächter] Bereit für Kampf! {hand.Count} Karten auf der Hand. OnHandChanged einmalig ausgelöst.");
    }
    
    /// <summary>
    /// Zieht eine Karte vom Deck
    /// </summary>
    public TimeCardData DrawCard()
    {
        if (hand.Count >= MAX_HAND_SIZE)
        {
            Debug.LogWarning("[Zeitwächter] Hand ist voll!");
            return null;
        }
        
        // Deck leer? Ablagestapel mischen
        if (currentDeck.Count == 0)
        {
            if (discardPile.Count == 0)
            {
                Debug.LogWarning("[Zeitwächter] Keine Karten mehr zum Ziehen!");
                return null;
            }
            
            // Ablagestapel ins Deck
            currentDeck.AddRange(discardPile);
            discardPile.Clear();
            ShuffleDeck();
        }
        
        // Karte ziehen
        TimeCardData drawnCard = currentDeck[0];
        currentDeck.RemoveAt(0);
        hand.Add(drawnCard);
        
        OnCardDrawn?.Invoke(drawnCard);
        
        // PLAY-CHAIN LOG: Neue Karte gezogen, UI aktualisieren
        // Debug.Log($"[Zeitwächter] Karte gezogen: '{drawnCard.cardName}', löse OnHandChanged aus (sollte Hand mit N Karten anzeigen)");
        
        OnHandChanged?.Invoke(); // UI aktualisieren
        
        return drawnCard;
    }
    
    /// <summary>
    /// Zieht eine Karte vom Deck OHNE Events auszulösen (für Initial Draw)
    /// STRATEGIE A: Verhindert mehrfache OnHandChanged Events beim Spielstart
    /// </summary>
    private TimeCardData DrawCardSilent()
    {
        if (hand.Count >= MAX_HAND_SIZE)
        {
            Debug.LogWarning("[Zeitwächter] Hand ist voll!");
            return null;
        }
        
        // Deck leer? Ablagestapel mischen
        if (currentDeck.Count == 0)
        {
            if (discardPile.Count == 0)
            {
                Debug.LogWarning("[Zeitwächter] Keine Karten mehr zum Ziehen!");
                return null;
            }
            
            // Ablagestapel ins Deck
            currentDeck.AddRange(discardPile);
            discardPile.Clear();
            ShuffleDeck();
        }
        
        // Karte ziehen
        TimeCardData drawnCard = currentDeck[0];
        currentDeck.RemoveAt(0);
        hand.Add(drawnCard);
        
        // KEINE Events auslösen!
        // Debug.Log($"[Zeitwächter] Karte gezogen (silent): {drawnCard.cardName}");
        
        return drawnCard;
    }
    
    /// <summary>
    /// Spielt eine Karte aus
    /// </summary>
    public bool PlayCard(TimeCardData card, RiftEnemy target = null)
    {
        if (!hand.Contains(card))
        {
            Debug.LogWarning("[Zeitwächter] Karte nicht auf der Hand!");
            return false;
        }
        
        // Zeitkosten berechnen (mit Klassen-Modifikatoren)
        float timeCost = CalculateCardTimeCost(card);
        
        // Kann die Karte gespielt werden?
        if (!RiftTimeSystem.Instance.TryPlayCard(timeCost))
        {
            Debug.Log("[Zeitwächter] Nicht genug Zeit für diese Karte!");
            return false;
        }
        
        // PLAY-CHAIN LOG: Karte wird ausgeführt
        // Debug.Log($"[Zeitwächter] Karte '{card.cardName}' wird ausgeführt");
        
        // Karte ausspielen
        ExecuteCardEffect(card, target);
        
        // PLAY-CHAIN LOG: Von Hand entfernen
        // Debug.Log($"[Zeitwächter] Entferne Karte '{card.cardName}' aus Hand, löse OnHandChanged aus");
        
        // Von Hand auf Ablagestapel
        hand.Remove(card);
        discardPile.Add(card);
        
        OnCardPlayed?.Invoke(card);
        OnHandChanged?.Invoke(); // UI aktualisieren (sollte Hand mit N-1 Karten anzeigen)
        
        phaseSystem.OnCardPlayed(card.cardType);
        
        // Animation
        if (animator != null)
        {
            animator.SetTrigger("PlayCard");
        }
        
        // PLAY-CHAIN LOG: Neue Karte ziehen
        // Debug.Log($"[Zeitwächter] Ziehe neue Karte nach Spielen von '{card.cardName}'");
        
        // Neue Karte ziehen
        DrawCard();
        
        return true;
    }
    
    /// <summary>
    /// Berechnet die finalen Zeitkosten einer Karte
    /// </summary>
    private float CalculateCardTimeCost(TimeCardData card)
    {
        float baseCost = card.baseTimeCost;
        float modifier = 1f;
        
        // Schildmacht-Modifikator für Verteidigungskarten
        if (card.cardType == TimeCardType.Defense && shieldPower.GetCurrentShieldPower() >= 2)
        {
            modifier *= 0.85f; // -15% Kosten
        }
        
        // Phasen-Bonus
        modifier *= phaseSystem.GetCostModifier(card.cardType);
        
        return RiftTimeSystem.Instance.CalculateCardTimeCost(baseCost, modifier);
    }
    
    /// <summary>
    /// Führt den Effekt einer Karte aus
    /// </summary>
    private void ExecuteCardEffect(TimeCardData card, RiftEnemy target)
    {
        switch (card.cardType)
        {
            case TimeCardType.Attack:
                ExecuteAttackCard(card, target);
                break;
                
            case TimeCardType.Defense:
                ExecuteDefenseCard(card);
                break;
                
            case TimeCardType.TimeManipulation:
                ExecuteTimeCard(card, target);
                break;
        }
    }
    
    /// <summary>
    /// Führt eine Angriffskarte aus
    /// </summary>
    private void ExecuteAttackCard(TimeCardData card, RiftEnemy target)
    {
        if (target == null)
        {
            // Automatisches Targeting (vorderstes/nächstes Ziel)
            var enemies = RiftCombatManager.Instance.GetActiveEnemies();
            if (enemies.Count > 0)
            {
                target = enemies[0];
            }
        }
        
        if (target != null)
        {
            // Schaden berechnen (mit Schildmacht-Bonus)
            int damage = card.baseDamage;
            damage = shieldPower.ModifyAttackDamage(damage);
            damage = Mathf.RoundToInt(damage * phaseSystem.GetDamageModifier());
            
            // Schaden zufügen
            target.TakeDamage(damage);
            
            // Debug.Log($"[Zeitwächter] {card.cardName} fügt {damage} Schaden zu!");
        }
    }
    
    /// <summary>
    /// Führt eine Verteidigungskarte aus
    /// </summary>
    private void ExecuteDefenseCard(TimeCardData card)
    {
        // Block aktivieren
        float blockDuration = card.blockDuration;
        blockDuration = shieldPower.ModifyBlockDuration(blockDuration);
        
        StartBlock(blockDuration, () => {
            // Block erfolgreich
            shieldPower.OnSuccessfulBlock();
            
            // Zeitbonus?
            float timeReward = card.timeReward + shieldPower.BlockTimeRewardBonus;
            if (timeReward > 0)
            {
                RiftTimeSystem.Instance.AddTime(timeReward);
                // Debug.Log($"[Zeitwächter] Block erfolgreich! +{timeReward}s Zeit");
            }
        });
        
        // Debug.Log($"[Zeitwächter] {card.cardName} aktiviert für {blockDuration}s!");
    }
    
    /// <summary>
    /// Führt eine Zeitmanipulations-Karte aus
    /// </summary>
    private void ExecuteTimeCard(TimeCardData card, RiftEnemy target)
    {
        // Zeitgewinn
        if (card.timeGain > 0)
        {
            float bonus = phaseSystem.GetTimeBonus();
            RiftTimeSystem.Instance.AddTime(card.timeGain + bonus);
            // Debug.Log($"[Zeitwächter] {card.cardName} gibt +{card.timeGain + bonus}s Zeit!");
        }
        
        // Weitere Effekte je nach Karte...
    }
    
    /// <summary>
    /// Aktiviert einen Block (öffentliche Schnittstelle)
    /// </summary>
    public void ActivateBlock(float duration, float timeReward = 0f)
    {
        Action onSuccess = null;
        
        // Bei erfolgreichem Block: Zeit zurückgewinnen
        if (timeReward > 0)
        {
            onSuccess = () => {
                RiftTimeSystem.Instance.AddTime(timeReward);
                // Debug.Log($"[Zeitwächter] Block erfolgreich! +{timeReward}s Zeit zurückgewonnen!");
            };
        }
        
        StartBlock(duration, onSuccess);
    }
    
    /// <summary>
    /// Startet einen Block
    /// </summary>
    private void StartBlock(float duration, Action onSuccess)
    {
        isBlocking = true;
        blockEndTime = Time.time + duration;
        onBlockSuccess = onSuccess;
        
        OnBlockStateChanged?.Invoke(true);
        
        // Animation
        if (animator != null)
        {
            animator.SetBool("IsBlocking", true);
        }
        
        StartCoroutine(BlockCoroutine(duration));
    }
    
    /// <summary>
    /// Block-Coroutine
    /// </summary>
    private IEnumerator BlockCoroutine(float duration)
    {
        yield return new WaitForSeconds(duration);
        
        // Block endet
        isBlocking = false;
        onBlockSuccess = null;
        
        OnBlockStateChanged?.Invoke(false);
        
        if (animator != null)
        {
            animator.SetBool("IsBlocking", false);
        }
    }
    
    /// <summary>
    /// Wird aufgerufen wenn ein Gegner versucht Zeit zu stehlen
    /// </summary>
    public bool AttemptTimeTheft(float amount)
    {
        // Schildmacht-Immunität?
        if (shieldPower.ConsumeTimeTheftImmunity())
        {
            Debug.Log("[Zeitwächter] Zeitdiebstahl durch Schildmacht-Immunität verhindert!");
            return false;
        }
        
        // Block aktiv?
        if (isBlocking && Time.time < blockEndTime)
        {
            Debug.Log("[Zeitwächter] Zeitdiebstahl geblockt!");
            
            // Block-Erfolg
            if (onBlockSuccess != null)
            {
                onBlockSuccess.Invoke();
                onBlockSuccess = null;
            }
            
            return false;
        }
        
        // Zeit wird gestohlen
        return true;
    }
    
    /// <summary>
    /// Mischt das Deck
    /// </summary>
    private void ShuffleDeck()
    {
        int n = currentDeck.Count;
        System.Random rng = new System.Random();
        
        while (n > 1)
        {
            n--;
            int k = rng.Next(n + 1);
            var temp = currentDeck[k];
            currentDeck[k] = currentDeck[n];
            currentDeck[n] = temp;
        }
        
        OnDeckShuffled?.Invoke();
    }
    
    // Getter
    public List<TimeCardData> GetHand() => new List<TimeCardData>(hand);
    public List<TimeCardData> GetHandDirect() => hand; // DIREKTE Referenz für RiftCombatManager
    public List<TimeCardData> GetDiscardPile() => discardPile; // DIREKTE Referenz für RiftCombatManager
    public System.Action GetHandChangedEvent() => OnHandChanged; // Event-Zugriff für RiftCombatManager
    
    /// <summary>
    /// Öffentliche Methode um OnCardPlayed Event auszulösen (für RiftCombatManager)
    /// </summary>
    public void TriggerCardPlayedEvent(TimeCardData card)
    {
        OnCardPlayed?.Invoke(card);
    }
    
    /// <summary>
    /// Spezielle Methode für RiftCombatManager - entfernt Karte und zieht neue OHNE Zeit-Abzug
    /// (Zeit wurde bereits im Combat Manager abgezogen)
    /// </summary>
    public bool PlayCardFromCombat(TimeCardData card)
    {
        if (!hand.Contains(card))
        {
            Debug.LogWarning("[Zeitwächter] PlayCardFromCombat - Karte nicht auf der Hand!");
            return false;
        }
        
        // Debug.Log($"[Zeitwächter] PlayCardFromCombat - entferne '{card.cardName}' und ziehe neue Karte");
        
        // Von Hand auf Ablagestapel (OHNE Zeit-Abzug!)
        hand.Remove(card);
        discardPile.Add(card);
        
        // Events auslösen
        OnCardPlayed?.Invoke(card);
        
        // Neue Karte ziehen
        DrawCard();
        
        // EXPLIZIT: OnHandChanged nochmal auslösen um sicherzustellen dass UI aktualisiert wird
        // Debug.Log($"[Zeitwächter] PlayCardFromCombat - triggere OnHandChanged für UI-Update");
        OnHandChanged?.Invoke();
        
        return true;
    }
    public int GetDeckCount() => currentDeck.Count;
    public int GetDiscardCount() => discardPile.Count;
    public bool IsBlocking() => isBlocking;
    public int GetShieldPower() => shieldPower.GetCurrentShieldPower();
}

/// <summary>
/// Phasenwechsel-System für Zeitwächter
/// </summary>
public class PhaseSystem : MonoBehaviour
{
    private enum Phase { Neutral, PostAttack, PostDefense }
    private Phase currentPhase = Phase.Neutral;
    
    public void OnCardPlayed(TimeCardType cardType)
    {
        if (cardType == TimeCardType.Attack)
        {
            currentPhase = Phase.PostAttack;
        }
        else if (cardType == TimeCardType.Defense)
        {
            currentPhase = Phase.PostDefense;
        }
    }
    
    public float GetDamageModifier()
    {
        return currentPhase == Phase.PostDefense ? 1.15f : 1f; // +15% nach Verteidigung
    }
    
    public float GetTimeBonus()
    {
        return currentPhase == Phase.PostAttack ? 1f : 0f; // +1s nach Angriff
    }
    
    public float GetCostModifier(TimeCardType cardType)
    {
        // Keine Kosten-Modifikation im Phasensystem
        return 1f;
    }
    
    public void Reset()
    {
        currentPhase = Phase.Neutral;
    }
}

