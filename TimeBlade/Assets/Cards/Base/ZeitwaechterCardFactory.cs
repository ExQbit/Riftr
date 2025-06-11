using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Factory-Klasse zum Erstellen der Zeitwächter-Starterkarten.
/// Erstellt die Karten zur Laufzeit für den Prototyp.
/// </summary>
public static class ZeitwaechterCardFactory
{
    /// <summary>
    /// Erstellt das komplette Zeitwächter-Starterdeck
    /// </summary>
    public static List<TimeCardData> CreateStarterDeck()
    {
        List<TimeCardData> deck = new List<TimeCardData>();
        
        // 4x Schwertschlag
        for (int i = 0; i < 4; i++)
        {
            deck.Add(CreateSchwertschlag());
        }
        
        // 2x Schildschlag
        for (int i = 0; i < 2; i++)
        {
            deck.Add(CreateSchildschlag());
        }
        
        // 2x Zeitblock
        for (int i = 0; i < 2; i++)
        {
            deck.Add(CreateZeitblock());
        }
        
        return deck;
    }
    
    /// <summary>
    /// Schwertschlag - Basis-Angriffskarte
    /// </summary>
    public static TimeCardData CreateSchwertschlag()
    {
        TimeCardData card = ScriptableObject.CreateInstance<TimeCardData>();
        
        card.cardName = "Schwertschlag";
        card.cardID = "CARD-WAR-SWORDSLASH";
        card.description = "Füge 5 Schaden zu. Profitiert von Schildmacht-Boni.";
        card.cardType = TimeCardType.Attack;
        card.rarity = CardRarity.Common;
        
        // Zeit & Effekte
        card.baseTimeCost = 1.5f;
        card.baseDamage = 5;
        
        return card;
    }
    
    /// <summary>
    /// Schildschlag - Angriff mit Zeitschutz
    /// </summary>
    public static TimeCardData CreateSchildschlag()
    {
        TimeCardData card = ScriptableObject.CreateInstance<TimeCardData>();
        
        card.cardName = "Schildschlag";
        card.cardID = "CARD-WAR-SHIELDSLASH";
        card.description = "Füge 5 Schaden zu. Reduziert Zeitdiebstahl für 2s um 15%.";
        card.cardType = TimeCardType.Attack;
        card.rarity = CardRarity.Common;
        
        // Zeit & Effekte
        card.baseTimeCost = 1.5f;
        card.baseDamage = 5;
        // TODO: Zeitdiebstahlschutz-Effekt implementieren
        
        return card;
    }
    
    /// <summary>
    /// Zeitblock - Basis-Verteidigungskarte
    /// </summary>
    public static TimeCardData CreateZeitblock()
    {
        TimeCardData card = ScriptableObject.CreateInstance<TimeCardData>();
        
        card.cardName = "Zeitblock";
        card.cardID = "CARD-WAR-TIMESHIELD";
        card.description = "Blocke den nächsten Angriff für 4s. Bei Erfolg: +0.5s Zeit, +1 Schildmacht.";
        card.cardType = TimeCardType.Defense;
        card.rarity = CardRarity.Uncommon;
        
        // Zeit & Effekte
        card.baseTimeCost = 1.5f;
        card.blockDuration = 4f;
        card.timeReward = 0.5f;
        
        return card;
    }
    
    /// <summary>
    /// Erstellt weitere Zeitwächter-Karten für Tests
    /// </summary>
    public static Dictionary<string, TimeCardData> CreateAllZeitwaechterCards()
    {
        var cards = new Dictionary<string, TimeCardData>();
        
        // Basis-Karten
        cards["schwertschlag"] = CreateSchwertschlag();
        cards["schildschlag"] = CreateSchildschlag();
        cards["zeitblock"] = CreateZeitblock();
        
        // Zeitmanipulation
        cards["tempobindung"] = CreateTempobindung();
        cards["vorlauf"] = CreateVorlauf();
        
        // Signaturkarten
        cards["zeitparade"] = CreateZeitparade();
        cards["temporale_bastion"] = CreateTemporaleBastion();
        
        return cards;
    }
    
    /// <summary>
    /// Tempobindung - Gegner-Verzögerung
    /// </summary>
    private static TimeCardData CreateTempobindung()
    {
        TimeCardData card = ScriptableObject.CreateInstance<TimeCardData>();
        
        card.cardName = "Tempobindung";
        card.cardID = "CARD-WAR-TIMEFETTER";
        card.description = "Verzögere den nächsten Gegnerangriff um 3s. Trade-off: +0.5s Kosten für defensive Spezialisierung.";
        card.cardType = TimeCardType.TimeManipulation;
        card.rarity = CardRarity.Uncommon;
        
        card.baseTimeCost = 3.0f; // Opportunity Cost
        card.enemyDelay = 3f;
        
        return card;
    }
    
    /// <summary>
    /// Vorlauf - Kartenkosten-Reduktion
    /// </summary>
    private static TimeCardData CreateVorlauf()
    {
        TimeCardData card = ScriptableObject.CreateInstance<TimeCardData>();
        
        card.cardName = "Vorlauf";
        card.cardID = "CARD-WAR-TEMPORALEFFICIENCY";
        card.description = "Die nächste Verteidigungskarte kostet 1.0s weniger Zeit.";
        card.cardType = TimeCardType.TimeManipulation;
        card.rarity = CardRarity.Rare;
        
        card.baseTimeCost = 3.0f;
        // TODO: Kosten-Reduktions-Effekt
        
        return card;
    }
    
    /// <summary>
    /// Zeitparade - Legendäre Reflexionskarte
    /// </summary>
    private static TimeCardData CreateZeitparade()
    {
        TimeCardData card = ScriptableObject.CreateInstance<TimeCardData>();
        
        card.cardName = "Zeitparade";
        card.cardID = "CARD-WAR-TEMPORALCOUNTER";
        card.description = "Reflektiere den nächsten Zeitdiebstahl und füge 6 Schaden zu.";
        card.cardType = TimeCardType.Defense;
        card.rarity = CardRarity.Legendary;
        
        card.baseTimeCost = 4.0f;
        card.blockDuration = 5f; // Fenster für Reflexion
        card.baseDamage = 6; // Reflexionsschaden
        
        return card;
    }
    
    /// <summary>
    /// Temporale Bastion - Ultimate Verteidigung
    /// </summary>
    private static TimeCardData CreateTemporaleBastion()
    {
        TimeCardData card = ScriptableObject.CreateInstance<TimeCardData>();
        
        card.cardName = "Temporale Bastion";
        card.cardID = "CARD-WAR-TIMEFORTRESS";
        card.description = "+4s Zeit, 30% weniger Zeitdiebstahl für 6s, +1 Karte ziehen. Trade-off: Hohe Kosten.";
        card.cardType = TimeCardType.TimeManipulation;
        card.rarity = CardRarity.Legendary;
        
        card.baseTimeCost = 5.0f; // Sehr teuer
        card.timeGain = 4f;
        // TODO: Zeitdiebstahl-Reduktion & Kartenzieh-Effekt
        
        return card;
    }
}

/// <summary>
/// Beispiel-Evolutionen für Schwertschlag
/// </summary>
public static class SchwertschlagEvolutions
{
    /// <summary>
    /// Feuer-Evolution: Flammenschlag
    /// </summary>
    public static TimeCardData CreateFlammenschlag()
    {
        TimeCardData card = ScriptableObject.CreateInstance<TimeCardData>();
        
        card.cardName = "Flammenschlag";
        card.cardID = "CARD-WAR-FLAMESLASH";
        card.description = "Füge 4 Schaden zu + 2 DoT (Schwach). Zeitgewinn: +0.5s bei jedem Tick.";
        card.cardType = TimeCardType.Attack;
        card.rarity = CardRarity.Uncommon;
        card.evolutionPath = EvolutionPath.Fire;
        card.evolutionStage = 1;
        
        card.baseTimeCost = 2.5f;
        card.baseDamage = 4;
        // TODO: DoT-Effekt mit Zeitgewinn
        
        return card;
    }
    
    /// <summary>
    /// Eis-Evolution: Eisschlag
    /// </summary>
    public static TimeCardData CreateEisschlag()
    {
        TimeCardData card = ScriptableObject.CreateInstance<TimeCardData>();
        
        card.cardName = "Eisschlag";
        card.cardID = "CARD-WAR-ICESLASH";
        card.description = "Füge 4 Schaden zu. Verlangsame Gegner um 15%.";
        card.cardType = TimeCardType.Attack;
        card.rarity = CardRarity.Uncommon;
        card.evolutionPath = EvolutionPath.Ice;
        card.evolutionStage = 1;
        
        card.baseTimeCost = 2.5f;
        card.baseDamage = 4;
        // TODO: Verlangsamungs-Effekt
        
        return card;
    }
    
    /// <summary>
    /// Blitz-Evolution: Blitzschlag
    /// </summary>
    public static TimeCardData CreateBlitzschlag()
    {
        TimeCardData card = ScriptableObject.CreateInstance<TimeCardData>();
        
        card.cardName = "Blitzschlag";
        card.cardID = "CARD-WAR-STORMSLASH";
        card.description = "Füge 4 Schaden zu. Die nächste Verteidigungskarte kostet 0.5s weniger.";
        card.cardType = TimeCardType.Attack;
        card.rarity = CardRarity.Uncommon;
        card.evolutionPath = EvolutionPath.Lightning;
        card.evolutionStage = 1;
        
        card.baseTimeCost = 2.0f; // Schneller!
        card.baseDamage = 4;
        // TODO: Kosten-Reduktions-Buff
        
        return card;
    }
}
