using UnityEngine;

public abstract class CardEffect : ScriptableObject
{
    [TextArea(2, 4)]
    public string effectDescription = "Effect description.";

    public abstract void Execute(Character_Base target);
}

// Placeholder class until the real character system is implemented
public abstract class Character_Base : MonoBehaviour 
{
    public abstract void TakeDamage(int amount);
    public abstract void Heal(int amount);
}