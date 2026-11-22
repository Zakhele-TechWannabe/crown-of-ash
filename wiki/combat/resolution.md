# How fights resolve

Fights run blow by blow. Each fighter has power, guard, speed, breath and will. Faster fighters strike more often; heavy blows stagger; winded fighters become slower and weaker. Motive affects when a fighter yields or runs, so a parent defending young can behave differently from a fearful animal.

People's attributes, martial skills, tempering, age and injuries shape their physical profile. People and beasts use the same resolution system. Qi assists only when a real reserve can pay through a usable route.

| Accumulated harm | Wound |
|---:|---|
| 0–<15 | Unhurt |
| 15–<35 | Bruised |
| 35–<60 | Hurt |
| 60–<100 | Badly hurt |
| ≥100 | Dying |

| Fight rule | Value |
|---|---:|
| Base strike interval | 12 seconds ÷ speed |
| Time limit | 180 seconds |
| Stagger harm | 22 |
| Nonlethal brawl harm cap | 95 |
| Bruised healing range | 2–6 days |
| Hurt healing range | 10–30 days |
| Badly hurt healing range | 45–120 days |

A spar or tournament can stop earlier than a lethal fight. Injuries still affect subsequent activity. Reaching dying can kill; it is not an ordinary recovery tier.

A large [qi reserve](../cultivation/vessel.md) does not instantly pass through a narrow wrist. See [qi abilities](qi.md), [hunting](hunting.md) and [guardians](guardians.md).

## Weapons and technique

The current fighter selects the weapon matching the person's highest positive weapon skill, otherwise bare hands. This is a skill-based choice, rather than a verified inventory/equipment system. Longer reach can hold a shorter fighter off until they step inside; long weapons lose power when crowded. Tempo changes time between blows. Skill can enable parries, ripostes and feints. A compatible free hand plus shield skill provides a shield guard bonus.

| Weapon | Power multiplier | Reach (metres) | Tempo multiplier | Parry factor |
|---|---:|---:|---:|---:|
| Unarmed | 1.0 | 0.7 | 0.85 | 0.5 |
| Staff | 1.15 | 2.0 | 1.0 | 1.2 |
| Spear | 1.3 | 2.4 | 1.1 | 0.8 |
| Blade | 1.35 | 1.0 | 0.95 | 1.0 |
| Straight sword | 1.3 | 1.1 | 0.9 | 1.2 |
| Axe | 1.45 | 0.9 | 1.2 | 0.6 |
| Hammer | 1.55 | 0.9 | 1.3 | 0.5 |
| Polearm | 1.45 | 2.6 | 1.25 | 0.8 |
| Twin weapons | 1.2 | 0.9 | 0.75 | 1.0 |
| Chain weapons | 1.2 | 2.0 | 1.1 | 0.4 |

A smaller tempo multiplier means shorter intervals. A shield multiplies guard by **1.25**. Footwork helps the shorter fighter close distance.

!!! note "Unverified"
    The combat notes still call weapons and reach future phase-2 work. The current working-tree code and JSON already implement the rules above. This wiki follows that code; no runtime check was run for this documentation task.
