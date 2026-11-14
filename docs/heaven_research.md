# Heaven's Terrace research

Research only, 14 November 2026. No implementation or simulation. Local evidence: `src/fifty.gd`, `src/body_tempering.gd`, `src/population.gd`, `src/skill_catalogue.gd`, `src/combat.gd`, `src/village_life.gd`, ground scripts, and the named data/docs. All proposed multipliers, durations, fantasy species and layout allocations below are **design choices**, not measured scientific effects. Agricultural quantities are annual steady-state planning budgets, not promises of instant harvests.

## 1. Food, nutrition and work

### Existing integration

`fifty.provision()` repeatedly sets hunger to zero, sets method 3, renews three daily drill hours, and fills every medicine inventory; `join()` also clears hunger. The disciple job has an empty schedule. Thus simply drawing crops creates neither production nor eating. Keep Heaven's stocks separate from village stocks (settlement 50), while sharing population identities and nutrition logic. Medicine is a separate gate resource: ordinary pork or carp must not silently become `beast_marrow`, nor vegetables become `seven_leaf`.

`population._practise()` already reduces learning when hungry (0.6 for hunger 1–3, zero at 4); `grain_economy.EFFECT` is [1, .85, .6, .35, .2]. Body tempering's `rate()` currently ignores hunger/nutrition. Its three hours × method rate 1.4 × constant teacher 1.5 × Heaven rate 1.6 produces 10.08 progress/day at willpower 10, age factor 1 and no spirit root, before top-ten ×1.3. Food should condition that progress rather than add another permanent super-multiplier.

### Human requirement and menu

Adolescent requirements vary with body mass, growth and workload. The Canadian Paediatric Society review gives age/sex baseline energy requirements and explicitly requires extra energy for sport and growth; it also emphasizes iron, calcium, vitamin D and hydration. Use 2,800–3,600 kcal/day for ordinary training, rising toward 4,000 for larger, very active candidates, rather than a universal biological requirement. [Sport nutrition for young athletes](https://pmc.ncbi.nlm.nih.gov/articles/PMC3805623/).

For game planning choose **3,200 kcal and 100 g protein per person/day**: 160,000 kcal and 5 kg protein/day for 50; 58.4 million kcal and 1,825 kg protein/year. A 1.2–1.6 g/kg/day protein range gives 60–112 g for 50–70 kg trainees; 100 g is a generous provision target, adjustable for size, not a prescription for every twelve-year-old. [NSCA youth-athlete guidance](https://dxpprod.nsca.com/education/articles/nsca-coach/feeding-the-youth-athlete-three-key-messages/).

Illustrative daily basket per person (dry grain/beans, edible meat/fish, fresh produce): 450 g rice, 150 g millet, 80 g soy/beans, 500 g vegetables, 300 g fruit, one egg, 100 g fish, 100 g mixed pork/poultry, 250 ml milk, and 35 g oil. Rounded food-composition arithmetic gives about 3,200–3,400 kcal and 115–125 g protein, depending on meat cuts and crops. Offer seconds to need; do not force identical intake. Nutrient values should ultimately use ingredient records from [USDA FoodData Central](https://fdc.nal.usda.gov/), not the rounded basket as a food database. Dairy is optional: tofu, greens and fortified spirit foods can replace it in-world.

### Crops and land accounting

Adopt **1 tile = 1 m² for food accounting only**; the repo's 32-pixel tile and map's 16:1 coordinate conversion do not establish a physical metre. One hectare then means 10,000 tiles. If art later declares a 2 m tile, divide agricultural tile requirements by four, keeping kilograms unchanged.

Xianxia names can be jade spirit rice, golden-bead millet (already present in the sect data), cloud greens, marrow beans, longevity peaches, jade-feather hens, cloud goats, ironback pigs and silver-scaled carp. These are genre-compatible inventions; no universal xianxia canon specifies their yields. Use qi-rich soil to explain **4× annual crop output and 2× pond output**, not both 4× harvest size and 4× harvest frequency. Animal output stays mundane; spirit forage supplies abundant feed.

Conservative planning baselines: rice 4 t paddy/ha/year × 0.65 milling recovery; millet 2 t harvested grain × 0.8 cleaning/hulling; vegetables 20 t fresh/ha/year; mature fruit 15 t/ha/year; beans 2 t dry/ha/year; oilseed 1 t recovered oil/ha/year. These are scenario assumptions within broad agricultural practice, not site-specific yield predictions. FAO gives rice/millet suitability ranges; UF/IFAS documents about 70% milled rice recovery, so 65% allows a less efficient mill. Vegetable extension tables show why crop and spacing matter. [FAO crop yield ranges](https://www.fao.org/4/w0078e/w0078e05.htm), [UF/IFAS rice processing](https://ask.ifas.ufl.edu/publication/ag438), [MSU vegetable yields](https://www.canr.msu.edu/resources/yields_of_michigan_vegetable_crops_e1565), [Penn State orchard management](https://extension.psu.edu/apple-production).

| Allocation | Tiles | Annual output with stated spirit factor | Annual human basket demand |
|---|---:|---:|---:|
| Rice | 12,000 | 12,480 kg milled | 8,213 kg |
| Millet | 6,000 | 3,840 kg cleaned | 2,738 kg |
| Beans | 3,000 | 2,400 kg dry | 1,460 kg |
| Vegetables | 2,000 | 16,000 kg fresh | 9,125 kg |
| Mature orchard | 2,000 | 12,000 kg fruit | 5,475 kg |
| Oilseed | 2,500 | 1,000 kg oil | 639 kg |
| Dedicated feed grain/legumes | 12,000 | 14,400 kg dry at 3 t/ha ×4 | animal feed below |
| Pasture/fodder | 30,000 | 72,000 kg usable dry matter at 6 t/ha ×4 | approximately 15–20 t goat forage |
| Fish ponds | 10,000 | 6,000 kg live; 3,000 kg edible at 50% | 1,825 kg edible |
| Pens, coop, dairy, quarantine | 3,000 | see stocking budget | — |
| **Total productive footprint** | **82,500** | excludes paths, waterworks, compost, mills | — |

Rice's 12,480 kg follows 1.2 ha ×4,000 ×.65 ×4. Each human crop clears its basket demand even after a separate 15% seed/storage/spoilage allowance. Do not apply that loss twice. Reserve another 17,500 tiles for water, stores and service access: **100,000 tiles all-in**, about 5% of the proposed estate.

Without spirit multipliers the same output requires about **308,000 productive tiles** (4× the 69,500 crop/fodder tiles, 2× 10,000 pond tiles, 3,000 pens), plus services: approximately 350,000 tiles all-in. This is a rescaled equivalent-output budget, not a universal minimum. Surplus fodder deliberately covers replacement stock, rotation and bad seasons. Stagger vegetable beds and preserve grain/fruit; qi-stabilized seasons permit year-round sowing but still require growth time. Start with mature orchards and one season's stock if Heaven is already established.

### Protein husbandry and hidden inputs

- **80 laying hens**, budget 250 eggs/hen/year = 20,000 eggs, versus 18,250 needed. Allow about 0.19 kg feed/hen/day, approximately 5.5 t/year; add replacements and calcium/mineral grit. This feed estimate follows UMN's roughly 3 lb/week for a 6 lb hen; 250 eggs is a small-flock planning rate, not guaranteed production. [UMN hens](https://extension.umn.edu/agriculture/animals-and-livestock/poultry/raising-chickens-for-eggs), [CSU feeding tables](https://extension.colostate.edu/resource/practical-feeding-methods-for-small-poultry-flocks/).
- **24 finished pigs/year**, about 55 kg usable meat each = 1,320 kg; budget 300 kg feed/finished pig = 7.2 t/year. These are conservative scenario coefficients including substantial processing losses. Keep breeding/replacement pens or account for purchased piglets; select puppet-managed breeding with an extra 1 t/year feed reserve. Pasture and scraps supplement a balanced ration; pigs do not turn grass into free pork. [Penn State swine systems](https://extension.psu.edu/swine-production).
- **300 meat birds/year**, 2 kg edible/bird = 600 kg; budget 6 kg feed/bird = 1.8 t. With pigs this covers the 1,825 kg annual meat basket. Together hens, pigs, meat birds and breeding allowance need approximately 15.5 t feed: 14.4 t dedicated grain plus at least 1.1 t food-grade milling by-products/bean surplus. Allocate **2 t/year** safe by-products, leaving margin; husks are bedding, not nutritious grain. These poultry/meat coefficients are explicit gameplay budgets.
- **16 dairy does**, stagger breeding so roughly 10 are milking on average; 2 L/milking doe/day gives about 7,300 L/year versus 4,563 L needed. Kids, bucks, dry periods and winter forage need stock capacity, not sixteen perpetually lactating animals. Milk requires clean handling and heating; supplement grain from the remaining crop surplus and reserve at least 2 t/year for the dairy herd. Penn State identifies quality forage and production-linked grain needs. [Dairy goat production](https://extension.psu.edu/dairy-goat-production).
- **Two 5,000-tile carp ponds**, alternating harvests: baseline 3 t live/ha/year, spirit ×2. Edible recovery 50% is a planning assumption. FAO reports 2.8–3.5 t/ha pond production in one surveyed system and describes carp integrated culture. Supply clean water, oxygen, safe pond fertilization and approximately 3 t/year supplementary feed from remaining rice/bean surplus; keep manure treatment separate from drinking water. [FAO pond production](https://www.fao.org/4/ag184e/AG184E06.htm), [FAO carp systems](https://www.fao.org/fishery/docs/CDrom/aquaculture/I1129m/file/en/en_commoncarp.htm).

After 15% losses, rice/millet/bean surplus totals about 3.5 t/year; oilseed cake and other feed-crop by-products provide additional feed. The 2 t dairy + 3 t pond supplementation therefore needs an explicit **additional 2,000-tile feed reserve** at the same 4× yield (2.4 t/year). Put it inside the 17,500 service/reserve allocation: productive planted area becomes 84,500, while the all-in food zone remains 100,000. This closes the feed budget without counting human rations as animal food. Keep feed protein/minerals as recipe constraints; kilograms alone do not ensure a balanced ration.

### Meal loop and nutrition effects

Use authoritative simulation states: `hungry → reserve harvest → walk to plot → pick → walk to wash/kitchen → prepare/cook → eat → clear reservation`. Hungry candidates collect greens/fruit or a marked ripe-grain bundle; puppets thresh/mill cereals and process fish/meat. A rice head is not a ready meal. Group cooking can use preserved pantry ingredients plus the candidate's freshly picked component.

Three meals at approximately 06:30, 12:00, 18:00 plus a training snack. Per meal: 5 minutes picking, 15 active minutes preparation, 15 minutes eating, plus travel; batch hearths can take 30 elapsed minutes while only 15 require attention. Provide ten preparation stations with five-person staggered cohorts over 75 minutes. Reserve ingredients on pickup, consume raw stock once at cooking and cooked stock once at eating; record nutrition only at eating. Cancel/release reservations on death, interruption or departure. An empty plot routes to another ripe bed or pantry, never an infinite wait.

Keep rolling seven-day calorie/protein adequacy `N = min(1, kcal/need, protein/need)` and hunger 0–4 as a daily deficit severity, not a minute-by-minute meal timer. Proposed body progress multiplier: `N × EFFECT[hunger]`, capped at 1.0; zero at starvation hunger 4. Avoid multiplying population's existing hunger XP penalty again. At N < .8 reduce planned drills and increase recovery time; do not create irreversible Low-grade layers from one missed lunch. Defer breakthroughs while seven-day N < .9. Balanced nutrition permits existing quality; optionally add at most +0.10 quality points after 30 adequate days, never a new grade cap. Medicine and polishing requirements still apply.

Candidates do **30 minutes/day of rotating chores** (25 person-hours/day total) and their own meal preparation. Four spirit puppets supply up to 8 work-hours each/day (32 puppet-hours) for irrigation, fodder, harvesting, milling, sanitation and livestock care, plus explicit seasonal harvest overtime. This is a magical labour assumption, not a real-world staffing estimate for 8.45 ha. All labour draws tasks from stocks/seasonal needs; no care means reduced output. Credit only actual chore hours to outer-layer labour tempering, not the existing eight-hour labour default. Keep total hard training near four hours/day: three tempering hours plus one weapon hour; meals, chores, reading, rest and sleep have separate budgets.

**Recommendation**

- Build a 100,000-tile, stock-accounted food zone with 4× spirit crops, 2× fish, mundane animal reproduction and explicit feed costs.
- Replace hunger clearing with real meals, persistent nutritional adequacy and shared headless/visible state transitions; use puppets for heavy work.

```json
{"people":50,"kcal_person_day":3200,"protein_g_person_day":100,"food_zone_tiles":100000,"productive_tiles":84500,"crop_yield_multiplier":4,"pond_yield_multiplier":2,"hens":80,"pigs_finished_year":24,"meat_birds_year":300,"dairy_does":16,"pond_tiles":10000,"puppets":4,"chore_minutes_day":30,"pantry_reserve_days":90,"nutrition_window_days":7}
```

## 2. Five weapon paths and the free library

### Real technique, fictional combat balance

Chinese jian (劍/剑) is a double-edged straight sword; dao (刀) is a single-edged saber; qiang (槍/枪) is spear, gun (棍) staff, quan/zhang (拳/掌) fist/palm, gong (弓) bow. Modern IWUF taolu preserves named technique vocabularies and forms, not evidence that one weapon has a quantified combat advantage. Its rules distinguish straight-sword thrusts/cuts, saber chopping/wrapping and spear/staff actions. Use this for animation/technique identity; the numerical balance below is invented. [IWUF descriptions](https://iwuf.org/en/sport-wushu/competitive-wushu/taolu/), [IWUF technical rules](https://iwuf.org/wp-content/uploads/2021/09/EN-IWUF-Wushu-Taolu-Competition-Rules-Judging-Methods-Excerpt-2019.pdf).

| Path | Fundamentals → applied progression | Attribute emphasis from the existing eight | Proposed power / speed / guard; reach |
|---|---|---|---|
| Jian, Clear Stream Sword | grip, aligned thrust (ci), point control → intercept, deflect, cut → partner timing and counter-thrust | dexterity; agility, perception secondary | 1.00 / 1.10 / 1.05; 2 tiles |
| Qiang/gun, Coiling Dragon Pole | stable stance, staff grip and recovery → spear lan/na/zha (outward/inward parry/thrust), staff sweeps and pokes → maintain distance, recover when crowded | endurance; strength, perception secondary | spear 1.05 / .95 / 1.10; 3 tiles; staff .95 / 1.00 / 1.15; 3 tiles |
| Quan/zhang, Mountain Root | stance, breath and safe alignment → fist/palm combinations, blocking, stepping → balance breaking, controlled close sparring | strength; endurance, willpower secondary | .95 / 1.15 / 1.10; 1 tile |
| Gong, Returning Goose | posture, light draw, repeatable anchor/release → aiming/range judging → moving targets, wind, pressure | perception; dexterity, strength secondary | ranged 1.05 / .80 / .80; 12 tiles; fallback fist .85 / 1.00 / .90 |
| Dao, Thunder Saber | safe edge alignment and cut recovery → chop (pi), uppercut (liao), thrust, wrap/cover → committed combinations and recovery under counters | strength; agility, endurance secondary | 1.15 / 1.00 / .95; 2 tiles |

Thumb draw is a plausible Chinese bow tradition but not the only Chinese technique; provide a matching thumb ring and avoid presenting a single historical school as universal. The Met's Qing archery objects document the material tradition; draw strength should increase gradually, with accuracy prerequisites rather than forced heavy bows. [Met archer's ring](https://www.metmuseum.org/art/collection/search?q=archer%27s%20ring).

Eight stored attributes, in order: strength, endurance, agility, dexterity, perception, intellect, willpower, charisma (`data/skills/rules.json`). Intellect supports reading/technique analysis, willpower tempering and practice adherence, charisma peer teaching. None should be mandatory for access. Attribute lean means practice requirements/learning weights, not pretending agility is the sword's only real-world determinant. Suggested XP weights: primary .5, two secondary .25 each; leave weapon-independent base combat strength/endurance/agility effects intact.

`Combat.person()` currently uses strength for power, endurance for guard/breath, agility for speed and willpower for yielding; `martial_level()` returns the best level across weapon/unarmed/hunting/archery prefixes. There is no distance, equipment or selected path. Add `equipped_path`, weapon-specific skill and `reach` to fighter profiles; replace best-any-skill with equipped weapon proficiency (and explicit fallback). A hunter's trapping level must not grant expert sword power.

Keep event-driven fights. Add opening separation (6 tiles for tournament), closing speed in tiles/second (proposed 2), reach and ammunition. Long weapons act when distance first enters their reach; shorter weapons must close further. After entry, use the existing strike clock with the table modifiers. On a successful close by an unarmed fighter, polearm power ×.85 until distance is regained; one reposition attempt per 3 seconds prevents permanent free reach attacks.

Bow gets **at most one opening shot**, only with ammunition, line of sight and initial gap ≥4 tiles; melee closes during a proposed 1.5-second draw. Charge real elapsed time and allow interruption, then switch to a separately trained unarmed fallback when crowded. Both archers can shoot; no guaranteed hit or automatic win, and no free shot in a close surprise. Reuse `strike` damage/guard and spar caps; do not reuse the existing ambush bonus (1.5 power plus opponent delay). Forest blocks the shot unless a clear lane exists. Preserve `time_limit`, wound, escape and non-lethal tournament semantics; padded arrows and practice weapons change harm profile, not just flavour.

### Catalogue and manuals

The weapon/unarmed/archery IDs in the table already exist as **discipline declarations**: `weapons.straight_sword`, `weapons.spear`, `weapons.staff`, `weapons.blade`, `unarmed_arts.fist_and_palm`, `archery.aiming`, `archery.drawing`, `archery.release`. However all are `detailed:false`. `skill_catalogue.gd` only calls `_add_skill()` for detailed disciplines, so `population.touch()` cannot currently learn them. Merely adding a manual pointing at these IDs will assert. Promote selected disciplines with the same detailed schema as existing farming/hunting entries, valid specialisations, key attributes, related disciplines and activities.

Proposed specialisations (new IDs): `weapons.straight_sword.thrust`, `weapons.spear.thrust`, `weapons.staff.control`, `weapons.blade.cutting`, `unarmed_arts.fist_and_palm.alignment`, `archery.aiming.target_shooting`. Add supporting forms/distance-control and drawing/release disciplines progressively. An activity grants 100% its specialisation XP, parent spillover .4 and related spillover .05 through existing practice machinery; split the one weapon hour across activities rather than grant full hours to every supporting skill. Use `touch()` and `_gain()`/normal gates, not a parallel manual-level system. Normal learning is 2.5 base XP/hour before comprehension, attributes, age, hunger, traits, tools and level rates; preserve practice-year gates at levels 11/16/21/26/31 and mortal ceiling policy.

All manuals are freely readable, including the best ones. Separate **access** from effective execution:

| Manual tier | Suggested weapon study band | Tempering companion method | Method grade cap |
|---|---|---|---|
| Foundation | levels 0–5; posture, grip, breath | folk drills, method 1 | Middle (1) |
| Inner form | levels 6–15; combinations and partners | tempering manual, method 2 | High (2) |
| Complete inheritance | levels 16+; tactics, refinement, teaching | complete method, method 3 | Perfect (3) |

These are curriculum bands, not new hard XP ceilings or an override of practice years. **For the Fifty retain method 3 from day one**, supplied by the freely available complete body manual, as their current promise requires. Weapon learning starts with foundation exercises while the complete body method sets the cap. Sword mastery must not be required before the first Perfect skin layer. `method_grade_cap=[0,1,2,3]` limits possibility, never guarantees grade; the existing previous-layer and Perfect-chain conditions remain.

Offer 14 days of supervised sampling, then choose a primary path through preference, aptitude and recent enjoyment. Give 30 minutes library time/day, within free study time. Switching is allowed at any time: retain all learned XP and body grades; spend 14 days adapting with selected-path practice XP ×.8 and transfer only shared supporting disciplines. No invented 50% copying of sword XP into archery, no loss of existing body method. Secondary weapon practice must use real allocated hours. Record choice, active manual, proficiency and switch date in saves.

**Recommendation**

- Make five detailed skill curricula with freely accessible manuals; keep complete body-method access independent of weapon rank.
- Add equipped-path proficiency, small profile modifiers and event-based reach; give bows one conditional opening shot with a trained fallback.

```json
{"path_trial_days":14,"weapon_hours_day":1,"library_minutes_day":30,"switch_adaptation_days":14,"switch_xp_multiplier":0.8,"heaven_body_method":3,"method_grade_caps":[0,1,2,3],"reach_tiles":{"fist":1,"jian":2,"dao":2,"pole":3,"bow":12},"tournament_gap_tiles":6,"bow_opening_shots_max":1,"bow_draw_seconds":1.5,"closing_tiles_second":2}
```

## 3. Quarterly mentoring by the Will of Heaven

Cognitive apprenticeship supports demonstration, coached attempts, scaffolding, explanation and reflection; teaching should gradually withdraw support as competence grows. Deliberate practice emphasizes specific weaknesses, repetition and informative feedback, rather than passive time served. Neither establishes a quarterly optimum or a supernatural percentage bonus. [Collins, Brown and Holum](https://www.aft.org/ae/winter1991/collins_brown_holum), [Ericsson et al., original 1993 paper](https://blogs.ischool.berkeley.edu/i225s14/files/2014/04/Ericsson-1993-article.pdf).

A controlled complex motor-learning study supports feedback during early acquisition. Spacing evidence varies by task; quarterly correction should be supplemented by daily practice and weekly peer review, not sold as scientifically superior to frequent coaching. [Wulf et al. complex motor feedback experiment](https://pubmed.ncbi.nlm.nih.gov/20037033/), [motor-practice spacing experiment](https://pubmed.ncbi.nlm.nih.gov/42177224/).

Schedule **one individual 90-minute session per living candidate per calendar quarter**: 15 minutes demonstrate/diagnose, 45 minutes corrected attempts, 15 minutes retest, 15 minutes prescribe and explain the next practice plan. Fifty candidates require 75 mentor-hours/quarter, spread across 15 days at five hours/day. Five daily appointments stagger summit arrivals. Meet on calendar days 0, 91, 182 and 273 relative to the year; calendar quarters are 91/91/91/92 days, avoiding drift from repeating an integer 90-day interval. Attendance consumes the day's normal weapon/practice budget, not extra unbounded training time.

Proposed effects, all tunable gameplay values:

- The active martial activity receives normal XP for its actual 1.5 hours, with session XP ×1.5. Follow-up **target-skill XP ×1.15 for 28 days**, contingent on prescribed practice. Apply through modifiers and existing gates/level rates; no free levels.
- Tempering receives **progress ×1.10 for 28 days** while following the corrected regimen; no lump-sum percentage of layer cost. At three hours, method 3, willpower 10, no roots, Heaven rate 1.6 and no continuous teacher factor, baseline is 6.72/day; extra progress is at most 18.816 over 28 eligible days before other bonuses, not 10% of the very expensive ninth layer.
- Add **+0.10 grade-quality points** if a breakthrough occurs during the 28-day plan. Quality is measured in grade units, then floored, so +0.10 does not mean a 10% Perfect probability or +one grade. No retroactive edits to forged layers; method and Perfect-chain caps still govern.
- One **5% insight roll/session**, conditional on completing the corrected attempts; success adds 25 base XP to the practiced specialisation via normal gain logic. Existing insight/gate mechanics still check prerequisites; never skip years-of-practice gates. No reroll on reload.
- A weekly 20-minute peer check and short daily self-retest keep the coaching plan alive. They consume study/practice time and carry no separate magical multiplier.

**Do not stack these onto the present constant master treatment.** Replace Heaven's always-on teacher rate 1.5 with 1.0 outside sessions; retain training_rate 1.6 as environmental quality. Replace constant `teacher_grade=1.5` with a persistent **library/method guidance quality 1.40** plus conditional coaching +.10; retain `grade_bonus=.85`. Rename the persistent component so it does not imply daily personal instruction. Thus an attended coaching window recovers the previous 1.50 guidance contribution, while missing one has a small effect. Keep reduced strain .7 as safe prescribed drills, separate from teacher presence. This remains a proposal needing later short seeded checks: the current +1.5 and +.85 are major contributors to Perfect bodies, so deleting both without replacement would change the Apostle premise dramatically.

Tournament remains every five years, with top ten receiving their existing medicine/training/qi rewards until expiry. Add quarterly extra slots for the same reward term: champion +3; runner-up +2; ranks 3–10 +1 each. That is **13 extra sessions/quarter**, 19.5 mentor-hours, 94.5 hours total. Everyone retains the baseline appointment. Place extra sessions roughly 21–28 days apart, not all on tournament day; champion total four sessions/quarter, runner-up three, others two. If awards occur mid-quarter, grant only slots with valid remaining dates; no accumulated debt after five years.

For extras, session XP and insight rolls occur normally, but follow-up XP/progress multipliers **refresh expiry only, never multiply or add**; grade coaching remains at +.10 maximum. The champion's gain is more sustained correction and practice time, not exponential multipliers. Insight chance from four independent sessions is 1−.95⁴ ≈18.5% per quarter, versus 5% for one. Postpone injured candidates' physical sessions and give diagnosis/study alternatives; do not force training through tournament wounds. Default scope is candidates; envoys/Apostles need an explicit later policy rather than consuming candidate entitlements.

**Recommendation**

- Use individual 90-minute quarterly appointments with 28-day practice plans; replace the constant teacher fiction and preserve Perfect-capable guidance.
- Award +3/+2/+1 quarterly slots by rank, with bounded refresh-only bonuses and saved attendance/insight outcomes.

```json
{"quarter_day_offsets":[0,91,182,273],"session_minutes":90,"session_xp_multiplier":1.5,"plan_days":28,"plan_skill_xp_multiplier":1.15,"plan_tempering_multiplier":1.1,"coaching_grade_points":0.1,"library_guidance_grade_points":1.4,"continuous_teacher_rate":1,"insight_chance":0.05,"insight_base_xp":25,"extra_slots":{"rank_1":3,"rank_2":2,"ranks_3_10":1},"maximum_sessions_quarter":4}
```

## 4. Ten times the sect: layout, placement and engine cost

### Area and map compatibility

`sect_ground.BOUNDS = Rect2i(-160,-210,320,620)` means **198,400 tiles**, so the exact target is **1,984,000 tiles**. This compares bounding estate area, not the much smaller irregular paved terraces. Heaven today is 7,744 tiles; the target is about **256.2× present Heaven**, though only 10× the sect bounds.

The world JSON is 360×240 coarse cells; `world_map.gd` and ground samplers use 16 terrain tiles per cell, giving **5760×3840 terrain tiles**. The configured center [2625,902] matches Heavenly Ridge's feature anchor (approximately [2625.49,901.89]). A centered 1000×2000 rectangle has y = −98…1902 and fails world bounds. Recommend **1984×1000**, local bounds `[-992,-500,1984,1000]`: global half-open rectangle **[1633,402) to [3617,1402)**. The notation means x in [1633,3617), y in [402,1402).

Static rectangle checks against the actual data:

| Existing footprint | Global extent / relation |
|---|---|
| Unnamed Sect | x [1205,1525), y [2076,2696): disjoint |
| City | x [450,770), y [2110,2330): disjoint |
| Hunting sampled region | x [1376,2225), y [1976,2645): disjoint |
| Original Heaven | contained in the new estate |
| Hidden Lake feature anchor | approximately [2605.73,1413.50], just south, **but its water extends inside** |
| Profound Lake feature anchor | approximately [3508.70,1091.43], inside the estate |

**It does not fit as an uninterrupted dry plateau without overlapping natural features.** A read-only Python decode of `world.water` counted intersecting coarse cells and weighted their exact rectangle intersections: dry 1,532,878 tile-equivalents (77.26%); sea 73,938 (3.73%); lake 377,184 (19.01%). This is coarse-mask coverage, not a fine shore survey: ground `_sea()` interpolates and adds noise, and rivers require separate sampling. The rectangle touches 7,875 coarse cells. No simulation was needed. Major terrain includes tundra and bare rock; ordinary agronomy there needs the explicit warm spirit microclimate.

Preserve water as estate lakes and shores, with floating/bridged terraces where needed; claim the rectangle as **estate area**, while buildings and food occupy a dry connected subset. That meets the area goal without erasing Hidden/Profound Lakes. If the owner means 1,984,000 tiles of continuous built ground, the current center cannot honestly be certified safe: it requires deliberate terrain changes or a newly surveyed location. Do not flatten water invisibly. Before implementation, run a bounded fine-tile terrain/road/building intersection survey, preserve existing roads and water, and generate level-safe connections. Existing `sites_ground.gd` chunk buckets supply the right site lookup boundary.

### Zoned plan

Keep a **320×360 daily core** near the current summit, with dormitory, kitchen/harvest access, library and practice within roughly 150 walking tiles by route. The full estate is landscape, not a compulsory 2,000-tile commute. The following allocations sum to the exact estate area; they are budgets for non-overlapping polygons clipped against terrain, not already surveyed building rectangles.

| Zone | Tile budget | Placement/function |
|---|---:|---|
| Five-level core terraces | 80,000 | central spine: residences, kitchen, baths, stores and sheltered courtyards; about 60 beds |
| Library pavilion and reading gardens | 15,000 | uphill/north of dormitories; all five curricula, no payment/access gates |
| Mentoring summit and five Apostle pedestals | 15,000 | north core; five appointment waiting places; restoration seam protected |
| Spirit fields, orchard, ranch and ponds | 100,000 | dry southeast/east terraces close to kitchen; water/field/pasture budgets from section 1 |
| Training grounds | 35,000 | west core; separate safe bow lane, pole court and sparring rings |
| Tournament arena/spectator terraces | 25,000 | south core, buffered from bow lane and dormitories |
| Seclusion caves and quiet grove | 30,000 | northern slopes; 50 bookable chambers, no forced exile |
| Gates, stairs, bridges, paths and service space | 100,000 | southern entry, accessible contour routes, waterworks and puppet depot |
| Hidden pilgrimage approach | 100,000 | winding southwest wooded ravine, concealed final gate and admission court |
| Preserved lakes, ridge, orchards/woodland and wild landscape | 1,484,000 | remainder, including existing natural water and room for later expansion |
| **Total** | **1,984,000** | exactly ten sect bounding areas |

Use modest level differences with explicit stair/bridge portals; do not multiply current terrace heights by the area scale. Pilgrim search remains `fifty._process_journeys()` with its existing 30–365-day search and fate/admission checks. Display the final approach only after a successful find; a walker touching the estate boundary must not bypass that decision. Owner visibility and pilgrim knowledge are separate states.

### Honest engine budget

- Dense `sect_ground` arrays cost **14 bytes/tile** before allocator overhead: no_trees 1, surfaces 1, levels 4, heights 4, art 4. At 1,984,000 tiles that is **27,776,000 bytes = 26.49 MiB**. At 64² chunks, one equivalent payload is 56 KiB. Immutable arrays are currently shared by bakers; do not duplicate per worker. Chunk them lazily if startup or total RSS demands it; analytic empty landscape is cheaper still.
- Packed masks are manageable; dictionaries are the hazard. `grounds`, `plinth`, `standing_tiles`, ramps and boundary art must not acquire one dictionary entry per estate tile. Store legal estate bounds/polygons analytically or in bitsets, with building-local entries only. One byte mask is 1.89 MiB; one bit mask 0.237 MiB. A hypothetical RGBA8 full-resolution mask is 7.57 MiB; avoid pixel-scale masks for the whole estate.
- `sect_ground.setup()` currently scans tiers only until `min(160,bounds.end.y)` and assigns envelopes only for y <156; buildings with y≥156 enter village relocation logic. Those sect-specific assumptions will break a broad Heaven layout. Add site-defined tier extents and relocation policy before enlarging JSON. `_paint` and legal-boundary construction also need auditing for full-footprint loops. Enlarging bounds alone does not build correct terraces.
- The existing walker grid covers **320×620 =198,400 cells**. A full Heaven `AStarGrid2D` would add 1,984,000 cells; making one rectangle spanning both settlements wastes more. Exact native cell memory is version/build-dependent; **64–128 bytes/cell as a sizing hypothesis** would mean 121–242 MiB for Heaven alone, not a measured Godot fact. Official API docs establish region/update and solid-point behaviour, not bytes/cell. `update()` rebuilds grid state, so apply solid/weight overrides after it. [Godot AStarGrid2D API](https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html).
- Use a coarse portal graph for estate routes and **128×128 local walk grids**, initially at most eight active Heaven chunks (131,072 cells). Build only around the core/active routes; route across edges and explicit stair portals. Keep pond interiors solid and allow bank access. Evict unused grids; do not run `_link_levels()` across two million cells or auto-carve ramps through protected cliffs. For the compact core a bounded standalone grid is an interim option, but remote destinations still require portals.
- Baking is already 64×64 tiles, image width 1024 with vertical overflow; `ground_paint` shares texture/edge code and per-bake samples. The proposed rectangle intersects **32×16 =512 aligned chunks**. At the supplied approximately .86 seconds/detail chunk, eager work is **440 seconds of serial bake time**; two workers give a theoretical floor near 220 seconds, with real overhead and contention. This is an extrapolation from the supplied timing, not a new benchmark.
- A 1024² RGBA8 texture is 4 MiB before overflow/mipmaps. All 512 would take at least **2 GiB of texture payload**, with worker images/cropping/upload buffers adding CPU peaks. `bake()` allocates overflow and crops with `get_region()`, so temporary source and cropped images can coexist. Never retain every detail texture.
- `ground_terrain.gd` already uses worker tasks (maximum two), near-detail upgrades, far LOD and `LIMIT=128`. On low RAM prefer **16 detailed chunks globally**, a 96 MiB detail-byte cap including overflow, 128 far chunks (64² RGBA8 ≈2 MiB total), at most one in-flight bake in low-memory mode, and LRU eviction. GPU copies and driver allocations are additional; no total-RSS guarantee follows from these payload sums. Far-first loading and one-chunk lookahead keep the view usable while details arrive.
- Preserve chunk-local `GroundPaint` caches and immutable shared site snapshots. Place structures into chunk buckets and cull standing buildings/trees/walkers by viewport. Do not represent every plant or fish as a Node. Simulate harvests, animal cohorts and distant residents as records; no per-tile crop tick.

Suggested future acceptance checks, not run here: cold start/first-frame latency; peak RSS plus renderer memory on the actual low-RAM machine; pan between both settlements with bounded caches; record worst bake and upload time; verify pond/cliff path blockers and portal reachability. Budget Heaven-specific resident metadata/navigation below roughly 64 MiB, plus global rendering caps, and measure native allocations before claiming it fits.

**Recommendation**

- Use an exact 1984×1000 estate at the current anchor, preserving lakes and a compact daily core; do not claim the footprint is naturally dry or entirely buildable.
- Require site-specific terrain setup, lazy local navigation and byte-bounded detail baking before expanding the site data.

```json
{"center":[2625,902],"bounds":[-992,-500,1984,1000],"estate_tiles":1984000,"daily_core_tiles":[320,360],"food_zone_tiles":100000,"terrain_chunk_side":64,"intersected_chunks":512,"walk_chunk_side":128,"active_heaven_walk_chunks_max":8,"detail_chunks_global_max":16,"detail_cache_mib_max":96,"far_chunks_max":128,"low_ram_bake_workers":1}
```

## 5. Walking the Fifty in a second settlement

`village_life.gd` is a single-settlement view/controller: one `sect`, one grid, village-specific founders, facilities, granary and square. `WALKER_LIMIT=100` and settlement==0 filters in setup/refresh/death handling exclude Heaven. `_tend_the_dead()` currently removes living people after they leave settlement 0; later population refresh also adds only settlement 0. Changing just the limit would neither add the Fifty nor route them correctly.

Refactor its settlement-dependent inputs into contexts: settlement id, ground provider, navigation/portal set, facilities, homes, schedule provider, population membership and visible walkers. Instantiate Heaven context with id 50 and all living resident Fifty, including envoys/Apostles who have not departed; exclude dead/restoring people and journey settlements −50. Keep unique person IDs, shared mind/ties/body/combat/save state, and never seed another set of fifty for the renderer. Arrival changes membership once; restoration reactivates the existing person/walker. A pool of **100 village +50 Heaven walkers** is a deliberate separate quota, not whichever settlement fills a global 100 first.

Current `_refresh()` sets activity text and targets from time of day, with hunger-driven harvest/forage detours; these are not authoritative cooking/eating actions. It caches 512 routes using `Vector4i(start,target)`, clearing the whole cache when full. Movement runs at `elapsed*1.5*EFFECT[hunger]`; speed≥64 teleports to scheduled targets and schedule ticks become half-days. Preserve that visual acceleration, but move production/meal completion and nutrition to shared simulation events. A meal must finish identically in headless mode, at 1×, at 64× and during week/year skipping; no nutrients credited just because a view snaps someone to the kitchen.

Proposed Heaven weekday: 8.5–9 hours sleep; breakfast/chores around 06:00–08:00; tempering 08:00–09:30; rest/study; weapon work 10:00–11:00; lunch; tempering 14:00–15:30; reading/peer practice, supper, relationships and evening rest. This yields three body hours plus one weapon hour. Sampling, mentoring, tournament bouts and recovery replace scheduled blocks rather than stack extra hours. Use queues/reservations at plots, hearths, library practice spaces, summit and arena. Candidate traits may shift preferred slots; hunger and injury override drills. Keep food paths short and nursery/animal paths clear of archery lanes.

Specific changes needed when implementation is authorized:

1. Parameterize setup, `nearest`, `_refresh`, `_tend_the_dead`, `_refresh_population_views`, `walker_of` and `place_of` by context; replace settlement==0 assumptions with membership checks. Do not point Heaven walkers at village law posts, shrine or granary.
2. Supply persistent dorm bed/door and work anchors instead of reusing center [2625,902] for all fifty. `population.locations` represents coarse presence today; choose one authority for movement and prevent schedule sync from overwriting real positions mid-action.
3. Queue at most **two new path requests/frame**, target 2 ms main-thread navigation budget with measured overruns, and stagger fifty schedule changes across 5 in-game minutes. A request cap is not a proof one A* call fits 2 ms; bound grids and measure. Never share a mutable AStar object between threads.
4. Include settlement, navigation generation and chunk/portal IDs in route keys. Use an LRU of about 128 routes/context rather than clearing 512 at once. Invalidate routes on terrain changes and failed portal checks; empty paths must trigger retry/alternative targets rather than repeat every frame.
5. Tick needs/actions at minute resolution while active; draw/interpolate nearby walkers each frame. Aggregate offscreen daily routine and simulate exact due meal/session/harvest events on fast-forward, so a weekly tick does not skip a coaching expiry or apply a hunger factor retroactively to the whole week. Avoid copying or advancing the shared population once per context.
6. Cull rendering/hit-testing/tree/building queries to visible contexts/chunks, while leaving simulation active. Distinguish a restoring Apostle's pedestal representation from an alive walking person. Pilgrims use coarse journey records until their admitted arrival, with optional final-approach animation.
7. Save meal/action phase, reserved ingredients, inventory, path choice/manual, coaching plan/attendance, home anchor and settlement membership. Rebuild disposable routes/walker sprites after load; do not serialize AStar grids or baked textures.

Later verification can be small, deterministic checks: exactly 50 eligible Heaven walkers alongside the existing village quota; no cross-settlement facility destinations; death/departure/restoration membership; one meal consumes one ration; equivalent nutrition/progress across normal and skipped time; reachable gate/library/fields/arena; route cache remains bounded. No long sim is necessary to establish those contracts.

**Recommendation**

- Introduce settlement contexts with independent 100/50 visual quotas and a shared simulation clock; make actions authoritative and walkers their presentation.
- Stagger schedules/pathfinding, preserve offscreen nutrition/coaching events and use compact local navigation with portal routes.

```json
{"settlement":50,"walker_quotas":{"village":100,"heaven":50},"new_path_requests_frame_max":2,"navigation_budget_ms_target":2,"route_cache_per_context":128,"schedule_stagger_minutes":5,"active_action_tick_minutes":1,"body_training_hours_day":3,"weapon_training_hours_day":1,"sleep_hours_day":9,"weekly_peer_review_minutes":20}
```
