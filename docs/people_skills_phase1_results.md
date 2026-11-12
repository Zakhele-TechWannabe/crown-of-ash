# Phase 1 people and skills verification

Branch: `fresh-start`. Changes are uncommitted. Verification used headless Godot 4.7.2; the windowed game was left alone.

## Catalogue

| Content | Count |
|---|---:|
| Spheres | 10 |
| Domains | 100 |
| Disciplines | 1,500 |
| Fully detailed disciplines in 25 village domains | 375 |
| Named and described disciplines awaiting detail | 1,125 |
| Specialisations | 1,501 |
| Discipline perks | 3,750 |
| Traits | 40 |

Every sphere has ten domains; every domain has fifteen disciplines. The loader checks IDs, parent ownership and spillover/activity references. Titles and XP thresholds follow the approved design. Village elder retains the design's explicit level-35 unlock.

## Scale benchmark

100,000 people, two daily activities, ten touched skills each (1,000,000 sparse skill entries).

| Measurement | Result | Target |
|---|---:|---:|
| Population construction | 2,554.8 ms | Report only |
| Full daily update, both batched passes | 1,727.1 ms | <2,000 ms |
| Largest 256-person batch | 6.74 ms | Spread over frames |
| Catalogue + population allocation delta | 83.60 MiB | <150 MB |
| Total Godot static allocation | 108.48 MiB | Report only |
| Worst 100,000-person list scroll-page build | 1.165 ms | <100 ms |
| Live row controls in that list | 13 | Viewport + overscan |

Memory is Godot static allocation, not process RSS. This measures the stated ten-skills/person workload; higher skill density costs more. No world terrain assets are loaded by this benchmark.

## Ten simulated years

Tier counts below use each person's best skill. Banked XP can produce several level-ups when a gate finally opens. The raw run also prints `SKILL_ENTRIES` counts for every touched discipline and specialisation, plus annual insights and notable level-ups.

Starting population: 4 Journeyman, 7 Apprentice, 7 Skilled, 2 Novice.

| Year | Apprentice | Journeyman | Skilled | Adept | Expert+ | Insights | Notable level-ups |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 2 | 11 | 7 | 0 | 0 | 0 | 10 |
| 2 | 0 | 11 | 9 | 0 | 0 | 1 | 18 |
| 3 | 0 | 11 | 8 | 1 | 0 | 0 | 14 |
| 4 | 0 | 11 | 8 | 1 | 0 | 2 | 6 |
| 5 | 0 | 9 | 8 | 3 | 0 | 2 | 41 |
| 6 | 0 | 8 | 7 | 5 | 0 | 1 | 16 |
| 7 | 0 | 8 | 7 | 5 | 0 | 1 | 6 |
| 8 | 0 | 8 | 6 | 6 | 0 | 3 | 4 |
| 9 | 0 | 8 | 6 | 6 | 0 | 2 | 1 |
| 10 | 0 | 7 | 6 | 6 | 1 | 3 | 17 |

Total: **15 insights and 133 level-ups at Skilled or above**, across disciplines and specialisations. All twenty residents remained fed. Both youths apprenticed and became adult workers; no one reached Master or qi-dependent levels.

| Person | Final age | Best title and level | Best-level gain | Best technique/practice |
|---|---:|---|---:|---|
| Wang Erniu | 45 | Adept 23 | +11 | Paddy rice |
| Wang Cuihua | 38 | Journeyman 15 | +5 | Housekeeping basics |
| Wang Dazhi | 33 | Journeyman 15 | +6 | Housekeeping basics |
| Li Xiaolan | 62 | Skilled 19 | +3 | Paddy rice |
| Li Shan | 33 | Journeyman 15 | +6 | Housekeeping basics |
| Li Mei | 67 | Skilled 19 | +2 | Paddy rice |
| Zhang Yong | 30 | Journeyman 15 | +7 | Housekeeping basics |
| Zhang Lian | 70 | Skilled 19 | +1 | Paddy rice |
| Zhang Bao | 30 | Expert 26 | +18 | Greens |
| Liu Qing | 61 | Adept 22 | +6 | Stonecutting |
| Liu An | 38 | Skilled 20 | +10 | Fruit trees |
| Liu Xiu | 40 | Adept 23 | +12 | Pigs |
| Chen Fu | 46 | Journeyman 15 | +3 | Ore sorting |
| Chen Lan | 28 | Adept 21 | +13 | Pond keeping |
| Yang Ping | 69 | Adept 23 | +5 | Trapping |
| Yang Hua | 49 | Skilled 19 | +6 | Preserving |
| Zhao Song | 63 | Adept 21 | +5 | Tanning |
| Zhao Yun | 68 | Skilled 20 | +2 | Weaving |
| Chen Xiaohu | 22 | Journeyman 15 | +13 | Foraging |
| Yang Xiaoyu | 25 | Journeyman 15 | +13 | Cooking |

Full-population annual food summary, in internal ration units:

```
Year 10: stock 63454.15 | harvest 23519.70 | consumed 7300.00 | spoilage 8386.57 | balance +4489.74 | minimum 55712.79 | hungry 0
```

Final distribution of all touched skills: 28 Skilled, 9 Adept, 34 Apprentice, 42 Journeyman, 1 Expert, 15 Novice, 2 Untrained.

## Checks

**PASS: all 12 tests; 100,000-person performance/list targets; ten-year simulation; day-200 People startup and drill paths.**

The twelve `tools/test_*.gd` tests cover terrain continuity/LOD/sites, pan budget, villagers, grain/food/material balances, ledger instrumentation and UI, plus catalogue validation, gates, modifiers, qi, batched determinism, inheritance, spatial limits, rust floors and over-hard learning. Materials compare daily stepping with time jumps using identical seeded populations and check stocks, flows, chronicle, skill XP/levels and attributes.

The extended ledger UI check exercises Place/Work/Life stage/Status, household name lists, person pages and Follow, sphere/domain/discipline/locked catalogue paths, and wrapped text at 1920×1080 and 1366×768. Additional headless startup checks use day 200, People, person 0 and a household drill path.

Raw output and machine-readable results are in `out/people-verification/` (ignored generated artifacts). `all_tests.json` is the combined latest test result; `ten_years.log` includes every annual distribution and the complete twenty-person skill records.

## Implementation boundaries

Only the twenty existing residents have full path-following schedules. Additional population entries render as capped nearby views at stored locations and show “Not nearby” for Follow. Modifiers are implemented but example resources have no acquisition route. Cultivation/realm gates remain locked as designed. Live milestone history is capped at 8,192 records; regional archival history needs persistent storage. See `people_skills_implementation.md` for APIs, query syntax and benchmark details.
