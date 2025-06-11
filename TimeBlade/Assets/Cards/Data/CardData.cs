using UnityEngine;
using System.Collections.Generic;

public enum CardType
{
    Attack,
    Defense,
    Utility,
    TimeManipulation
}

public enum CardRarity
{
    Common,
    Uncommon,
    Rare,
    Epic,
    Legendary
}

[CreateAssetMenu(fileName = "New Card", menuName = "Zeitklingen/Card Data", order = 1)]
public class CardData : ScriptableObject
{
    public string cardName;
    public string description;
    public Sprite cardArt;
    public CardType cardType;
    public CardRarity rarity;
    public int timeCost;
    public int level;
    public int maxLevel;
    public CardData evolvesInto;
    public string[] evolutionMaterialNamesPlaceholder;
    public int[] evolutionMaterialQuantitiesPlaceholder;
    public List<CardEffect> effects;
}