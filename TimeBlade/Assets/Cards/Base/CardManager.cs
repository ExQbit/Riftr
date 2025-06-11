using UnityEngine;
using System.Collections.Generic;
using System;

public class CardManager : MonoBehaviour
{
    // Singleton-Instanz
    public static CardManager Instance { get; private set; }

    // Karten-Collections
    private List<CardData> deck = new List<CardData>();
    private List<CardData> hand = new List<CardData>();
    private List<CardData> discardPile = new List<CardData>();

    // Events
    public event Action<CardData> OnCardDrawn;
    public event Action<CardData> OnCardPlayed;
    public event Action<CardData> OnCardDiscarded;
    public event Action OnDeckShuffled;

    // Maximale Handkartenzahl
    public int maxHandSize = 5;

    private void Awake()
    {
        // Singleton-Pattern
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

    // Initialisiere das Deck mit Karten
    public void InitializeDeck(List<CardData> cards)
    {
        deck.Clear();
        hand.Clear();
        discardPile.Clear();
        
        if (cards != null)
        {
            deck.AddRange(cards);
            ShuffleDeck();
        }
        
        Debug.Log($"Deck initialized with {deck.Count} cards");
    }

    // Mische das Deck
    public void ShuffleDeck()
    {
        int n = deck.Count;
        System.Random rng = new System.Random();
        
        while (n > 1)
        {
            n--;
            int k = rng.Next(n + 1);
            CardData value = deck[k];
            deck[k] = deck[n];
            deck[n] = value;
        }
        
        OnDeckShuffled?.Invoke();
        Debug.Log("Deck shuffled");
    }

    // Ziehe eine Karte vom Deck in die Hand
    public CardData DrawCard()
    {
        if (hand.Count >= maxHandSize)
        {
            Debug.LogWarning("Hand is full, cannot draw more cards");
            return null;
        }
        
        if (deck.Count == 0)
        {
            if (discardPile.Count == 0)
            {
                Debug.LogWarning("No cards left to draw");
                return null;
            }
            
            // Wenn das Deck leer ist, mische den Ablagestapel ins Deck
            deck.AddRange(discardPile);
            discardPile.Clear();
            ShuffleDeck();
        }
        
        CardData drawnCard = deck[0];
        deck.RemoveAt(0);
        hand.Add(drawnCard);
        
        OnCardDrawn?.Invoke(drawnCard);
        Debug.Log($"Drew card: {drawnCard.cardName}");
        
        return drawnCard;
    }

    // Spiele eine Karte aus der Hand
    public bool PlayCard(CardData card, Character_Base target)
    {
        if (!hand.Contains(card))
        {
            Debug.LogWarning($"Card {card.cardName} is not in hand");
            return false;
        }
        
        // Hier würde man prüfen, ob genug Zeit/Ressourcen vorhanden sind
        // Für jetzt nehmen wir an, dass die Karte gespielt werden kann
        
        // Effekte der Karte ausführen
        if (card.effects != null)
        {
            foreach (CardEffect effect in card.effects)
            {
                if (effect != null)
                {
                    effect.Execute(target);
                }
            }
        }
        
        // Karte aus der Hand entfernen und auf den Ablagestapel legen
        hand.Remove(card);
        discardPile.Add(card);
        
        OnCardPlayed?.Invoke(card);
        Debug.Log($"Played card: {card.cardName}");
        
        return true;
    }

    // Wirf eine Karte ab
    public bool DiscardCard(CardData card)
    {
        if (!hand.Contains(card))
        {
            Debug.LogWarning($"Card {card.cardName} is not in hand");
            return false;
        }
        
        hand.Remove(card);
        discardPile.Add(card);
        
        OnCardDiscarded?.Invoke(card);
        Debug.Log($"Discarded card: {card.cardName}");
        
        return true;
    }

    public void StartPlayerTurn()
    {
        int initialHandCount = hand.Count;
        int cardsDrawnThisTurn = 0;
        // Attempt to draw cards until hand is full or no more cards can be drawn
        while (hand.Count < maxHandSize)
        {
            CardData drawnCard = DrawCard(); // DrawCard handles deck empty (reshuffle) and returns null if truly no cards or hand full
            if (drawnCard == null)
            {
                break; // Stop if no card could be drawn (e.g., deck/discard empty, or hand became full)
            }
            cardsDrawnThisTurn++;
        }
        Debug.Log($"Player turn started. Drew {cardsDrawnThisTurn} cards. Hand: {hand.Count}/{maxHandSize}. Deck: {deck.Count}, Discard: {discardPile.Count}");
    }

    // Getter für die aktuellen Karten
    public List<CardData> GetDeck() { return new List<CardData>(deck); }
    public List<CardData> GetHand() { return new List<CardData>(hand); }
    public List<CardData> GetDiscardPile() { return new List<CardData>(discardPile); }
}
