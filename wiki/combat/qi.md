# Qi in combat by layer

Body Tempering builds the weapon; Qi Condensation fuels and steers it. Empty reserves grant no free realm-based qi power or speed. Paid energy leaves the reserve and is accounted as dissipated qi.

| Certified layer | Ability | Current effect and cost |
|---|---|---|
| 1 | Qi sense | Lower-or-equal presences' ambush power ×0.5 |
| 1 | Reinforced strike or guard | Delivered useful qi adds score; tissue tolerance caps the benefit |
| 2 | Second wind | 1 QU restores breath once per fight |
| 3 | All-in strike | One burst per fight using a 0.05-QU local hand buffer |
| 4 | Qi-step | Speed ×1.15; 0.002 QU/second |
| 5 | Qi armour | 0.01 QU/second upkeep; adds capped guard score while upkeep is paid |
| 6 | Difficult-qi foundation | No separate layer-6 combat action found in the current fight engine; ambient combat admission and elemental arts remain design goals |
| 7 | Guard and strike together | Earlier layers choose one reinforcement per exchange; holds a personal shell |
| 8 | Projection | Opening ranged packet, 0.10 QU; range parameter 3 tiles, coherence limits useful delivery |
| 8 | Projected shell | May raise another shell once during a real fight |
| 8 | Sword pulse | Current implementation pays 0.10 QU per escape check (two seconds at 0.05 QU/second), multiplying the runner’s escape chance by 0.6 |
| 9 | Integration | Earlier paid functions together; no free flat power bonus |

## Delivery and quality

The ordinary hand buffer is **0.02 QU**, with **0.6 seconds** wind-up. Useful delivery is reduced by purity squared and execution control; the live combat profile also includes stability. **1 useful QU = 1,000 score**. A completed ordinary body's reinforcement tolerance starts at **0.5 × physical power**, rising to **1.0 × physical power** for a Perfect body.

In recorded tests a real Perfect palm route carried about **0.021 QU/second**, giving roughly **12** extra score during wind-up. That explains why an impressive reserve alone does not guarantee victory.

## Personal shells

| Shell parameter | Value |
|---|---:|
| Raise cost | 5 QU |
| Maximum charge | 40 QU |
| Minimum reserve to attempt shell | 50 QU |
| Absorption price | 2 QU per harm point |
| Leakage | 2% per second |

A full shell absorbs about **20 harm points** before leakage. It is held before a real fight rather than a friendly spar. Shells are brief and expensive; they do not substitute for planned formation barriers.

## Recorded comparisons

The 21 November notes report 1,000 seeded fights per comparison: a layer-1 novice won **10%** against a Perfect mortal; layer 5 won **92%** against an equal mortal and **42%** against a Perfect mortal. These are fixture outcomes, not general win probabilities.

!!! note "Unverified"
    The design calls for combat channel strain, but the implementation-status section explicitly lists it as not yet built. Paid qi settlement and the listed phase-1 abilities are implemented; elemental arts, local qi phenomena and full martial programmes remain [planned](planned.md). Weapons and reach are built; see [fight resolution](resolution.md).

See [fight resolution](resolution.md) and [layer certifications](../cultivation/qi-condensation.md).

!!! note "Unverified"
    The armour design describes delivered interception, but current code adds up to **10 guard score**, capped by physical guard × tissue tolerance × **0.5**, while upkeep is paid. The fight engine does not implement the proposed layer-6 ambient admission. Sword pulse currently modifies escape chance after payment rather than simulating a complete thrown-blade journey. These descriptions follow code rather than the broader ability promises in the design.
