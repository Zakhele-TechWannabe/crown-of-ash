# Combat: body tempering and qi condensation

Design of record for combat in the valley. Read with [the Dao's laws](daos_laws.md) §11–12
(reinforcement, projection, reach and counters), [cultivation design](cultivation_design.md) §10,
and `src/combat.gd`. Owner decisions are dated; numbers are fiction-balance starting points.

## Owner decisions (2026-11-21)

- **Flying swords wait for Foundation Establishment.** Qi Condensation gets only the tethered *sword pulse* at layer 8.
- **Barriers: both.** Small personal shells (hold at layer 7, project at layer 8) and formation barriers.
- **Phenomena, not weather** (owner 2026-11-21: "it's a phenomenon"). A cultivator's released elemental qi produces a local **qi phenomenon** (mist, a gust, frost, heat shimmer) around them; it does not control the weather. Large **heavenly phenomena** (gathering clouds at a breakthrough, tribulation) and valley weather belong to the Heavenly Dao, formations and higher realms.
- **Combat comes before the Foundation Establishment walls.**

## The core rule

**Body Tempering builds the weapon. Qi Condensation fuels and steers it.** Qi never adds power for free:

- it must travel down a real channel to the fist, sole, skin or blade before the action lands;
- what a strike can carry is capped by the tissue (tolerance 0.5 × physical power for an ordinary completed body, 1.0 for Perfect);
- every unit spent leaves the reserve and enters the dissipation ledger, so integer conservation holds.

A cultivator with an empty reserve fights as a mortal with their tempered body. A Perfect Body Tempering master can beat a clumsy layer-1 cultivator; a layer-5 cultivator with wide arm channels usually beats them.

Today `Combat.person()` adds a flat `qi_power` by realm and layer. That breaks the law above ("an empty reserve receives no realm-based qi power or speed") and is the first thing this design replaces.

## Units

- Reserve and costs are in QU (1 QU = 1,000 quanta in `MeridianStore`). A layer-3 reserve is roughly 1,000–1,500 QU.
- **Harm score:** 1 useful QU = 1,000 harm-score units (laws §11). Harm score adds to a strike's *power*, or is absorbed by a *guard*, on the same scale as `combat.json`'s power and guard (a villager is about 10, a tempered fighter 30–60).
- `useful = delivered × purity² × execution` where execution = 1 − control error.
- **Delivery is the binding limit, not the reserve.** A 0.02 QU/s wrist route loads 0.012 QU in 0.6 s, which is about 12 harm score. The reserve matters for upkeep (armour, shells, sword pulse) and long fights.

## Abilities by certified layer

Each layer is something the body has *proven* (the certification evidence), not a stat bonus.

| Layer | Proven | Combat ability | Rule |
|---|---|---|---|
| 1 | Opened dantian | **Qi sense** | Can't be fully ambushed by a lower-or-equal presence: ambush power ×0.5. Feels cultivators and awakened beasts nearby. |
| 1 | — | **Reinforced strike** | Before each strike, load the striking palm through the shoulder→palm route for the strike's wind-up. Power += min(useful × 1000, power × tolerance). |
| 2 | Circuit | **Second wind** | When winded, spend qi to restore breath: 1 QU buys back the lungs once per fight, if the reserve can pay. |
| 3 | Full vessel | **All-in strike** | One burst per fight drawing the hand buffer to its limit (0.05 QU local buffer), at +20% strain. |
| 4 | Palms and soles | **Qi-step** | Reinforce the soles: speed +15% while the reserve pays 0.002 QU/s; also improves escape and chase. |
| 5 | Sustained output | **Qi armour** | Whole-body interception: 0.01 QU/s upkeep, absorbs incoming harm score at 1,000 per QU, delivery-limited by the trunk routes. |
| 6 | Difficult qi | **Fight anywhere** | Ambient admission continues during a fight in poor ground; elemental arts unlock (see Arts). |
| 7 | Two circuits | **Guard and strike together** | Before layer 7, each exchange the cultivator reinforces *either* the strike *or* the guard. From layer 7 both. **Personal shell held** while acting. |
| 8 | Controlled release | **Projection, shell, sword pulse** | Sword qi and palm wind at range (laws §11 projection with coherence length); personal shell projected; tethered sword pulse. |
| 9 | Integrated | All together | Doorway to Foundation Establishment. |

### Personal shell (layers 7–8)

A thin sphere of projected qi. Layer 7 holds one cast before a real fight (never in a friendly spar): 5 QU to raise plus up to 40 QU of charge. It absorbs wound harm at 2 QU per harm point (so a full shell stops about 20 harm, two good blows), leaks 2% a second, and breaks when empty. Layer 8 can project a new one once mid-fight. Small, short and expensive: real defence is **formation barriers**, which are external graphs fed by veins or spirit stones (`docs/qi_formations_research.md`, "Protection": 500 QU charge, 5 QU per harm point prevented).

### Sword pulse (layer 8) and flying swords (Foundation)

- **Sword pulse:** qi floods a conductive blade, which is thrown and pulled back along a qi thread within the coherence length (1 + 4 × release mastery tiles). It costs 0.05 QU per second the blade is away plus the strike's packet. Iron conducts poorly (×0.3), spirit steel well (×1.0). This gives the cultivator a reach advantage: they strike before a spear or fist can close.
- **Flying swords:** not in Qi Condensation. They need Foundation Establishment's spiritual sense. They are the realm's first taste of immortality and are designed with the Foundation walls.

## Stamina

Stamina stays physical (the fight's `breath`): food and rest restore it. From layer 2 a cultivator can spend qi to buy it back, so they outlast mortals, but it comes out of the same reserve that powers armour and shells. Draining the reserve below 10% in a fight adds strain; overdrawing it risks qi deviation, using the existing deviation rules.

## Arts and martial arts

Manuals are already step programs (stance, wait, parry, step, thrust). Physical arts work for anyone. **Qi arts** are the same sequences with qi branches, such as "reinforce the right palm 0.3 s before contact". Two cultivators with the same art differ in channel width and in understanding, and that is where genius shows. Elemental arts (from layer 6) colour the packet:

| Element | Strike | Qi phenomenon (layer 6+) |
|---|---|---|
| Water | Soaking palm: lowers the target's speed | Mist around self: cover ×1.3 for escape, costs 0.5 QU/min |
| Fire | Burning palm: harm over time | Dries the air; quenches mist |
| Wind | Palm wind: knockback, opens the guard | A gust within reach: disrupts arrows and projections |
| Earth | Heavy palm: stagger more easily | Firm footing: resists knockback |
| Wood/thunder | Later | Later |

A qi phenomenon is a few metres and a few minutes, paid from the reserve like any release. Heavenly phenomena, such as clouds gathering over a breakthrough, are the Dao's signs and not a cultivator's art.

## Fight resolution changes

The blow-by-blow engine in `combat.gd` stays (event-driven, a few steps per blow). The new elements are:

1. `Combat.person()` drops the flat `qi_power` and `qi_speed` and adds a `qi` block: layer, reserve (QU), purity, control error, tolerance, palm-route capacity (QU/s), sole-route capacity, trunk capacity, element, release mastery.
2. Each fighter carries a fight-local reserve and spends it through the abilities above; the fight returns `qi_spent` per side.
3. After the fight, the spent quanta are debited from the reserve and added to `DISSIPATED` (conservation), and strain is added to the palm/sole edges used.
4. Stories mention what happened: "her shell broke", "he ran dry", "the sword pulse struck first".

## Build order

The rulebook's Stage 4 (physical martial techniques: weapons, reach, tempo, parries, feints) is a larger rebuild. This design builds qi into the current engine first, so the owner sees cultivators fight like cultivators sooner:

1. **Qi combat (this doc):** reinforcement, qi sense, second wind, qi-step, armour, guard/strike split, shell, projection and sword pulse, with the reserve debit. Tests: an empty reserve fights as a mortal; Perfect BT 9 beats a layer-1 novice most of the time; layer 5 beats an ordinary BT 9; a shell absorbs and breaks; conservation residual 0.
2. **Martial techniques (Stage 4):** weapons and equipment, reach and tempo, parries and feints, so weapons matter and the sword pulse's reach is earned.
3. **Arts and elements:** qi arts as manual branches, elemental effects, qi phenomena.
4. **Formations:** barrier and killing arrays through the same interception path.
5. **Foundation Establishment:** spiritual sense, flying swords, and the walls.

## Implementation status (2026-11-21)

Phase 1 is built in `src/combat.gd` with constants in `data/society/combat.json` → `qi`, tested by `tools/test_qi_combat.gd`:
qi profile from the real body (layer, reserve, purity, stability, control error, tolerance, palm and sole routes,
coherence, blade skill); paid reinforcement of strike and guard (one at a time before layer 7); qi sense against ambush;
second wind; all-in burst; qi-step; qi armour; shells; opening projection; sword pulse against a fleeing enemy;
`Combat.settle_qi` / `spend_qi` debit the reserve into `dissipated` (residual stays 0). The old flat `qi_power` is gone.

Measured (1,000 seeded fights, BT9 bodies): layer-1 novice vs Perfect mortal 10% / 90%; layer 5 vs equal mortal 92%;
layer 5 vs Perfect mortal 42%; layer 8 vs tiger 100% (about 84 QU of shells a fight) where an ordinary mortal wins 33%.
A real Perfect body's palm route carries about 0.021 QU/s, so a reinforced blow adds about 12 to a power of 53–69.

Not yet: channel strain from combat, elemental arts and qi phenomena, weapons and reach (phase 2), formations.
