using UnityEngine;

[CreateAssetMenu(fileName = "New Heal Effect", menuName = "Zeitklingen/Card Effects/Heal Effect", order = 2)]
public class HealEffect : CardEffect
{
    public int healAmount = 5;

    public override void Execute(Character_Base target)
    {
        if (target != null)
        {
            // Assuming Character_Base has a Heal method similar to TakeDamage
            // If not, this needs to be added to Character_Base
            // For now, let's imagine it exists or add a placeholder call
            target.Heal(healAmount); // Placeholder - Character_Base needs a Heal() method
            Debug.Log($"Applying {healAmount} healing to {target.name}");
        }
        else
        {
            Debug.LogWarning("HealEffect: Target is null.");
        }
    }

    public override string ToString()
    {
        return $"Restores {healAmount} health to the target.";
    }
}
