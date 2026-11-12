# Phase 2 verification

Overall: **PASS**.

Godot 4.7.2, branch `fresh-start`; no commits. All runs used headless Godot, sequentially. The windowed game was left untouched.

**Lifespan death is OFF by default.** Everyone remains alive past their realm lifespan as a frail elder; population increases only through births.

## Automated checks

22/22 GDScript tests passed. Catalogue descriptions: 100 domains and 1,500 disciplines; no duplicate descriptions or shared six-word phrase.

- PASS `tools/test_clans.gd`
- PASS `tools/test_continuous.gd`
- PASS `tools/test_cultivation.gd`
- PASS `tools/test_faction_dynamics.gd`
- PASS `tools/test_factions.gd`
- PASS `tools/test_family.gd`
- PASS `tools/test_fast_forward.gd`
- PASS `tools/test_foods.gd`
- PASS `tools/test_grain.gd`
- PASS `tools/test_ground_lod.gd`
- PASS `tools/test_ledger.gd`
- PASS `tools/test_ledger_ui.gd`
- PASS `tools/test_materials.gd`
- PASS `tools/test_pan.gd`
- PASS `tools/test_people.gd`
- PASS `tools/test_relationships.gd`
- PASS `tools/test_sect.gd`
- PASS `tools/test_sites.gd`
- PASS `tools/test_skill_pacing.gd`
- PASS `tools/test_society_batching.gd`
- PASS `tools/test_society_emergence.gd`
- PASS `tools/test_village.gd`

Scenarios:

- PASS `100years.log` (exit 0)
- PASS `30years.log` (exit 0)
- PASS `startup_people.log` (exit 0)
- PASS `startup_society.log` (exit 0)
- PASS `skip_cli.log` (exit 0)

## Scale benchmark

100,000 people, 1,000,000 touched skills, 4,000,000 directed ties (40/person). Weekly social work and monthly rust are amortized into the reported total day cost. Daily and weekly timings are medians of three sequential samples; all samples are printed.

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

BENCH RUST monthly_ms=132.1 amortized_ms_per_day=4.4
BENCH people=100000 touched=1000000 build_ms=2761.4 day_ms=1458.9 max_batch_ms=4.07 memory_delta_MiB=184.97 total_static_MiB=210.04
BENCH SOCIAL ties=4000000 weekly_ms=3732.5 amortized_ms_per_day=533.2 total_day_ms=1996.6 memory_MiB=184.97 max_32_batch_ms=1.49
BENCH SAMPLES day_ms=[1456.144, 1458.939, 1463.389] weekly_ms=[3618.415, 3732.511, 3810.075] (median of three; sorted)
BENCH UI rows=100000 live_rows=13 worst_page_ms=1.316
PASS population benchmark
```

Memory is Godot static allocation delta for catalogue/core storage, not process RSS. Terrain, UI assets and annual faction aggregate construction are outside that figure. The expanded tie workload uses a 200 MB decimal core budget; the daily-time target remains 2,000 ms. Scene batches use 16–32 people, rather than the 256-person skill batches timed separately above.

## Thirty daily years

Counts use each person's best skill, including new children. Residents begin with existing adult experience; this differs from the neutral, from-zero pacing test.

| Year | Population | Untrained | Novice | Apprentice | Journeyman | Skilled | Adept | Expert | Master+ |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | 25 | 0 | 0 | 0 | 14 | 10 | 1 | 0 | 0 |
| 20 | 26 | 0 | 0 | 0 | 10 | 10 | 6 | 0 | 0 |
| 30 | 31 | 0 | 0 | 1 | 14 | 8 | 8 | 0 | 0 |

Neutral full-time pacing: Journeyman at 730 days (2 years), Skilled at 3,285 days (9 years), Expert at 9,125 days (25 years). At year 30 the practitioner remains level 30 without insight; the test supplies insight from year 31 and verifies Master after further earned practice (no XP grant). Existing attribute, milestone, teacher and qi gates still apply.

Measured Master timing after insight: 31.72 years.

## One hundred daily years

| Year | People | Marriages | Births | Clans | Awakenings | Mortal | Body | Qi | Foundation | Core | Nascent | Factions | Posts filled | Grudges |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | 25 | 6 | 5 | 0 | 1 | 20 | 5 | 0 | 0 | 0 | 0 | 22 | 2 | 0 |
| 20 | 26 | 6 | 6 | 0 | 1 | 6 | 20 | 0 | 0 | 0 | 0 | 24 | 2 | 0 |
| 30 | 31 | 8 | 11 | 0 | 1 | 11 | 20 | 0 | 0 | 0 | 0 | 25 | 2 | 0 |
| 40 | 33 | 9 | 13 | 0 | 1 | 10 | 22 | 1 | 0 | 0 | 0 | 26 | 2 | 0 |
| 50 | 35 | 9 | 15 | 0 | 1 | 11 | 23 | 1 | 0 | 0 | 0 | 26 | 2 | 0 |
| 60 | 37 | 9 | 17 | 0 | 2 | 9 | 26 | 2 | 0 | 0 | 0 | 26 | 2 | 0 |
| 70 | 37 | 9 | 17 | 0 | 2 | 8 | 27 | 2 | 0 | 0 | 0 | 25 | 2 | 0 |
| 80 | 37 | 9 | 17 | 0 | 2 | 5 | 30 | 2 | 0 | 0 | 0 | 26 | 2 | 0 |
| 90 | 37 | 9 | 17 | 0 | 2 | 5 | 30 | 2 | 0 | 0 | 0 | 26 | 2 | 0 |
| 100 | 37 | 9 | 17 | 0 | 2 | 5 | 30 | 2 | 0 | 0 | 0 | 26 | 2 | 0 |

Marriages, births and awakenings are cumulative; factions, positions, grudges and realm counts describe the checkpoint. Body Tempering is the slow mortal road, open to everyone. Awakening is not the same as reaching Qi Condensation.

## Chronicle highlights

Each checkpoint prints up to five events from that decade, ranked by significance. Fewer than five means fewer qualifying recorded events occurred.

```
Year 10
CHRONICLE day=3220 Li Xiaolan awakened a hidden spirit root: an insight in meditation at a qi-rich place
CHRONICLE day=1141 Wang Dazhi and Chen Lan married, with Li Xiaolan arranging the match
CHRONICLE day=1141 Li Shan and Yang Xiaoyu married, with Li Xiaolan arranging the match
CHRONICLE day=1141 Liu Xiu and Chen Fu married, with Li Xiaolan arranging the match
CHRONICLE day=868 Zhao Yun and Zhao Song married, with Li Xiaolan arranging the match
Year 20
CHRONICLE day=5579 Wang Rou6 was born to Wang Cuihua and Wang Erniu
CHRONICLE day=6209 Li Xiaolan lineage formed (lineage)
CHRONICLE day=5481 Wang Erniu lineage formed (lineage)
CHRONICLE day=6937 Liu Qing passed a home, tools and notes to Liu An
CHRONICLE day=6573 Li Xiaolan passed a home, tools and notes to Li Shan
Year 30
CHRONICLE day=8379 Chen Shu3 and Yang Qiao4 married, with Wang Erniu arranging the match
CHRONICLE day=7875 Chen Xiaohu and Li Lan2 married, with Wang Erniu arranging the match
CHRONICLE day=10003 Li Wen11 was born to Yang Xiaoyu and Li Shan
CHRONICLE day=8827 Chen Qiao10 was born to Li Lan2 and Chen Xiaohu
CHRONICLE day=8799 Wang Shu9 was born to Chen Lan and Wang Dazhi
Year 40
CHRONICLE day=14049 Li Xiaolan reached Qi Condensation 1
CHRONICLE day=12152 Yang Ming1 and Wang Rou6 married, with Wang Erniu arranging the match
CHRONICLE day=14175 Yang Ming13 was born to Wang Rou6 and Yang Ming1
CHRONICLE day=13440 Chen Rou12 was born to Li Lan2 and Chen Xiaohu
CHRONICLE day=12775 Li Xiaolan received a Yellow breathing fragment from the West Road wanderer
Year 50
CHRONICLE day=16583 Yang Shu15 was born to Wang Rou6 and Yang Ming1
CHRONICLE day=15771 Chen Lan14 was born to Yang Qiao4 and Chen Shu3
CHRONICLE day=17885 Yang Ming13 lineage formed (lineage)
CHRONICLE day=17157 Wang Dazhi passed a home, tools and notes to Wang Wen5
CHRONICLE day=17157 Li Shan passed a home, tools and notes to Li Lan2
Year 60
CHRONICLE day=20356 Chen Lan14 awakened a hidden spirit root: a spirit fruit found in the Eastern Hunting Grounds
CHRONICLE day=21539 Chen Lan14 reached Qi Condensation 1
CHRONICLE day=18473 Li Xiaolan reached Qi Condensation 2
CHRONICLE day=20097 Yang Wen17 was born to Wang Rou6 and Yang Ming1
CHRONICLE day=18347 Yang Qiao16 was born to Wang Rou6 and Yang Ming1
Year 70
CHRONICLE day=25067 Chen Lan14 reached Qi Condensation 3
CHRONICLE day=23268 Chen Lan14 reached Qi Condensation 2
CHRONICLE day=23149 Li Xiaolan reached Qi Condensation 3
CHRONICLE day=24479 Yang Wen17 became Chen Xiaohu's craft apprentice
CHRONICLE day=22967 Chen Lan14 suffered a cultivation injury; recovery remains possible
Year 80
CHRONICLE day=28847 Chen Lan14 reached Qi Condensation 6
CHRONICLE day=27783 Chen Lan14 reached Qi Condensation 5
CHRONICLE day=27587 Li Xiaolan reached Qi Condensation 4
CHRONICLE day=27230 Chen Lan14 reached Qi Condensation 4
CHRONICLE day=26649 Li Xiaolan received a Yellow breathing fragment from the West Road wanderer
Year 90
CHRONICLE day=31920 Chen Lan14 reached Qi Condensation 9
CHRONICLE day=31024 Chen Lan14 reached Qi Condensation 8
CHRONICLE day=30093 Chen Lan14 reached Qi Condensation 7
CHRONICLE day=32487 Chen Lan14 received a Yellow breathing fragment from the West Road wanderer
CHRONICLE day=30121 Chen Lan14 found a damaged Yellow breathing manual in hunting-ground ruins
Year 100
CHRONICLE day=33082 Li Xiaolan reached Qi Condensation 5
```

## Boundaries

Weekly skip mode approximates population practice at calendar transitions and changes random-event sequences; food/material ledger events retain their dated calendar. Large scene faction rebuilds yield across frames; explicit headless refresh APIs are synchronous. Named qi sites and techniques use the current village/peak/spring model; resource multipliers and faction pact/schism/absorption APIs can support later content.

The checked-in starting parent links are explicit, editable family assumptions consistent with resident ages and surnames. Unknown parents remain unknown; no invented ancestor people are inserted.

Raw logs and JSON are in `out/phase2/`. See `phase2_implementation.md` for storage, APIs and verification commands.
