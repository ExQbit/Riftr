using UnityEngine;

[CreateAssetMenu(fileName = "New Damage Effect", menuName = "Zeitklingen/Card Effects/Damage Effect", order = 1)]
public class DamageEffect : CardEffect
{
    public int damageAmount = 5;

    public override void Execute(Character_Base target)
    {
        if (target != null)
        {
            Debug.Log($"Applying {damageAmount} damage to {target.name}");
            target.TakeDamage(damageAmount);
        }
        else
        {
            Debug.LogWarning("DamageEffect: Target is null.");
        }
    }

    public override string ToString()
    {
        return $"Deals {damageAmount} damage to the target.";
    }
}