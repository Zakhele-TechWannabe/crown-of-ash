# Qi and Formations: Research and Design for *Crown of Ash*

## 1. What qi is in this world

### Definition and genre basis

**Qi is a renewable, locally exhaustible spiritual resource that living things absorb and refine, and formations redirect or consume.** Ambient **lingqi** (灵气, spiritual qi), refined personal qi, beast essence, and qi stored in spirit stones share an energy accounting system, but differ in accessibility, purity, and storage.

Spirit veins—**lingmai** (灵脉)—supply ambient qi. They make certain mountains, forests, lakes, and estates valuable. A formation organizes qi; it does not create it.

This follows the resource geography of *A Record of a Mortal’s Journey to Immortality* (《凡人修仙传》), **Wang Yu / 忘语**: spiritual veins and mines support sect power, while mines can be exhausted. Its sequel also depicts abundant ambient spiritual qi and depleted spirit stones. These are genre precedents; **all units, formulas, grades, and numerical balances below are proposed game rules**. Sources: [original novel, chapter 1203](https://www.wuxiaworld.com/novel/rmji/rmji-chapter-1203/?mobile-app=true&theme=wiki), [Immortal Realm, chapter 29](https://spa-prod.wuxiaworld.com/novel/rmjiir/rmjiir-chapter-29).

### Units and map scale

Use:

| Quantity | Meaning |
|---|---|
| **QU** | One qi unit; common accounting unit |
| **Density \(D\)** | QU per standard ambient volume |
| **Atlas-cell volume** | 2,000 standard volumes |
| **Cell qi mass \(M\)** | \(2,000D\) QU |
| **Throughput** | QU/day |
| **Purity** | Usable fraction, 0–1 |
| **Yin–yang balance \(Y\)** | −1 fully yin, +1 fully yang |

The existing atlas is **360×240 cells**, or 86,400 cells. `ground_terrain.gd` samples atlas coordinates using approximately:

```text
atlas_position = (ground_tile + 0.5) / 16
atlas_cell = floor(atlas_position)
```

Therefore one atlas cell covers **16×16 ground tiles**. `world_map.gd` labels an atlas cell as ten li across. Keep physical qi volume an explicit simulation convention rather than deriving it from cubic li.

A ground tile represents \(2,000/256 = 7.8125\) standard volumes. This permits formations and herb beds smaller than one atlas cell.

Suggested descriptions:

| Density | Book description |
|---:|---|
| <0.25 | Spiritually barren |
| 0.25–<1 | Thin qi |
| 1–<2 | Ordinary ambient qi |
| 2–<8 | Qi-rich |
| 8–<32 | Abundant spiritual qi |
| 32–<128 | A spiritual sanctuary |
| ≥128 | Immortal-estate concentration |

**Density is concentration, not daily production.** A dense chamber can still be depleted if its occupants consume more than its source supplies.

### Elemental composition, yin and yang

Store five conserved elemental masses:

```text
Metal, Wood, Water, Fire, Earth
```

Preserve the ten spirit-root bit positions already defined in `data/society/cultivation.json`. The other five roots describe affinities to combinations or conditions, rather than requiring five additional world fields:

| Existing root | Ambient affinity |
|---|---|
| Wind | 60% Wood + 40% Water |
| Thunder | 50% Wood + 50% Fire |
| Ice | Water with yin preference |
| Light | Fire with yang preference |
| Shadow | Water with yin preference |

Ice and Shadow initially share an environmental preference but should differ through techniques and future effects.

Yin and yang are **qualities of qi, not additional substances**. They influence compatibility, refinement safety, plants, and formation recipes. Corruption is another independent quality; yin is not evil, and yang is not automatically pure.

Use the traditional cycles:

- **Generating:** Wood → Fire → Earth → Metal → Water → Wood.
- **Overcoming:** Wood → Earth → Water → Fire → Metal → Wood.

These sequences are supported by Chinese sources, including [Shandong University’s five-phase diagram](https://zhouyi.sdu.edu.cn/__local/9/74/0E/3E35BD86B56241FC219550818F0_8CC52E88_EF784.pdf). Their numerical application here is a game design choice.

Do not make the field spontaneously convert through these cycles. A generating formation can convert **1 QU of the parent element into 0.8 QU of the child element**; 0.2 QU dissipates. Overcoming governs interference: equal opposing flows reduce effective output by 20% unless a suitable recipe stabilizes them.

### Terrain and biomes

Read the existing atlas `biome`, `water`, height, river, and feature data once during qi generation. Do not require rendered ground chunks.

Suggested background densities:

| Existing biome | Background \(D\) | Dominant character |
|---|---:|---|
| Deep/shallow sea | 0.5 / 0.7 | Water |
| Lake | 1.2 | Water, mildly yin |
| Sand shore | 0.5 | Earth/Water |
| Grassland/steppe | 1.0 / 0.7 | Wood/Earth |
| Forest/bamboo grove | 1.3 / 1.6 | Wood |
| Spirit forest | 3.0 | Wood, high purity |
| Desert | 0.25 | Earth/Fire, yang |
| Marsh | 1.2 | Water/Wood, yin |
| Highlands | 1.2 | Earth/Metal |
| Bare rock | 0.6 | Metal/Earth |
| Snow peaks/tundra | 0.6 / 0.4 | Water/Metal, yin |
| Frozen sea | 0.4 | Water, yin |

Composition starts with weight 1 for each element, then adds:

```text
forest/bamboo: Wood +5
lake/river/marsh: Water +5
highlands: Earth +3, Metal +2
bare rock: Metal +4, Earth +2
desert: Earth +3, Fire +3
snow/ice: Water +4, Metal +2
```

Normalize to five fractions summing to one. Blended terrain combines weights.

Mountains favor **vein placement and retention**, not universally high density. A barren summit should remain barren without a source. Lakes retain water qi; rivers connect favorable source locations. A feature named “Blood Ridge” must not become corrupted merely because of its name.

### Spirit veins and ley lines

A vein is a seeded graph:

- Nodes: springs, spirit eyes, mineral chambers, mountain roots.
- Edges: subterranean channels, presented to the player as ley lines.
- Each node has an outlet location, elemental composition, regeneration, and finite reserve.
- Each edge has throughput and integrity.
- Tapping an upstream channel reduces downstream supply.

Use six mortal-world grades, plus a special Palace origin:

| Vein grade | Name | Maximum output, QU/day | Full reserve | Outlet target bonus |
|---:|---|---:|---:|---:|
| 1 | Faint | 20 | 7,300 | +1 \(D\) |
| 2 | Lesser | 80 | 29,200 | +2 \(D\) |
| 3 | Established | 320 | 116,800 | +4 \(D\) |
| 4 | Superior | 1,280 | 467,200 | +8 \(D\) |
| 5 | Great | 5,120 | 1,868,800 | +16 \(D\) |
| 6 | Peerless | 20,480 | 7,475,200 | +64 \(D\) |

Reserve equals one year of rated output. Healthy regeneration is **rated output/day**, capped by reserve capacity. Emergency extraction may reach twice rated output and therefore drains reserve. Structural damage reduces regeneration proportionally.

For a daily step:

```text
reserve_available = min(capacity, reserve + regeneration)
emitted = min(requested_output, outlet_limit, reserve_available)
reserve_next = reserve_available - emitted
```

Ambient outlets emit only enough to approach their target. Unused production stays underground. Direct formation taps share the same outlet limits and reserve.

Distribute outlet supply with a compact kernel:

```text
weight(distance) = max(0, 1 - distance / 2)^2
target_density = background_density + vein_bonus × weight
```

Distance is in atlas cells. Normalize emitted elemental mass across underfilled receiving cells; never assign the whole output independently to each cell.

Background qi is renewed through an explicit world source: restore **1% of the deficit to background mass per day**, separately for each element. Above-target ambient qi loses **0.5% of excess/day** to dispersion beyond the modeled local volume. Record both flows in the qi ledger.

Do not add full fluid simulation initially. Vein edges and formation conduits provide meaningful movement without a world-sized diffusion solver.

### Placement in this repository

The Palace’s current `heaven.json` center is ground `[2625,902]`, approximately atlas `[164.1,56.4]`, matching **Heavenly Ridge**. Resolve this from the site file at generation time; do not hard-code the coordinates while the estate is being edited.

Recommended generation:

1. Place the Palace’s unique **Heavenly Origin**, with grade-6 output and balanced five-element qi beneath its resolved estate center.
2. Place a grade-3 outlet at the existing sect’s spirit spring, resolved through the sect layout.
3. Place grade-1/2 branches in the Eastern Hunting Grounds.
4. Generate approximately 48 additional veins from mountain, lake, river, and spirit-forest candidates using a dedicated seed.
5. Ordinary sect founding sites begin at grades 1–3. Grade-4/5 wilderness sites are rare prizes.
6. Every seed reserves the unique highest-quality, balanced source for the Palace.

The Heavenly Origin has **indestructible integrity and guaranteed regeneration**, but finite daily throughput. Its superiority comes from supply, purity, and excellent infrastructure rather than an invisible cultivation multiplier.

### Time effects

For the first release:

- Daily total supply is constant.
- No seasonal density multiplier.
- Terrain provides persistent yin–yang character.
- Night favors yin and day favors yang only in descriptions until cultivation schedules explicitly model those periods.

Later, use two fixed half-day phases with \(Y\) shifted by −0.15 at night and +0.15 by day. Both daily and jump simulation must evaluate both phases. Avoid sampling the current rendered clock during a multi-day jump.

### Player presentation

Add a **Qi** atlas layer:

- Density heatmap, logarithmic scale.
- Element filter.
- Vein graph and outlet icons.
- Depletion warnings.
- Formation footprints when that system ships.

The Heavenly Dao sees all sources. NPC knowledge remains separate.

Extend `world_map.gd::_info()` with:

> Abundant spiritual qi · density 18.4 · Wood 46%, Water 28% · Superior vein, reserve 81%.

The book should explain qi, local supply versus demand, and Palace advantages. Person pages should show actual meditation location, affinity, absorbed qi, refining efficiency, and bottleneck.

### Proposed `data/qi/*.json` shape

Separate rules from generated state:

```json
{
  "schema_version": 1,
  "atlas_size": [360, 240],
  "ground_tiles_per_cell": 16,
  "volume_per_atlas_cell": 2000,
  "quanta_per_qu": 1000,
  "elements": ["Metal", "Wood", "Water", "Fire", "Earth"],
  "background_deficit_recovery": 0.01,
  "excess_dispersion": 0.005,
  "seasonal_density_enabled": false
}
```

Suggested files:

| File | Contents |
|---|---|
| `data/qi/rules.json` | Units, stepping, recovery, dispersion |
| `data/qi/biomes.json` | Density, composition, polarity, purity |
| `data/qi/vein_grades.json` | Grade table and depletion rules |
| `data/qi/worldgen.json` | Seed salt, vein counts, terrain weights, site anchors |
| `data/qi/affinities.json` | Ten root mappings and compatibility rules |

Example world-generation anchor:

```json
{
  "id": "heavenly_origin",
  "anchor": {"site": "heaven.json", "offset_ground_tiles": [0, 0]},
  "grade": 6,
  "composition": [0.2, 0.2, 0.2, 0.2, 0.2],
  "purity": 1.0,
  "yin_yang": 0.0,
  "indestructible": true,
  "exclusive_owner": "heavenly_dao_palace"
}
```

Resolved vein graphs, reserves, ambient depletion, and timestamps belong in saves.

## 2. How people and beasts use qi

### Existing behavior to replace

`src/society.gd` already implements qi accumulation and realm progression:

- `qi_rate()` multiplies root count, purity, technique, comprehension, resources, damage, teachers, companions, and a synthetic density.
- Density currently comes from `rules.density[site[p]]`, whose values are **1, 2, 4**.
- `_tick_person()` can randomly change `site[p]` without moving the person.
- `cultivate()` adds `rate × days` and attempts at most one breakthrough per invocation.
- An unready body may accumulate up to the first 2,000-point gate.
- `layer_cap()` currently gives most people nine Qi Condensation layers and exceptional roots thirteen.

These are useful prototypes, but they do not yet represent a shared, exhaustible environment.

The layered accumulation model also has genre precedent in **Er Gen / 耳根’s *Renegade Immortal* (《仙逆》)**; its early chapters distinguish accumulated spiritual energy and Qi Condensation layers. See [chapter 27](https://www.wuxiaworld.com/novel/renegade-immortal/rge-chapter-27).

### Absorption and refining

Keep **ambient withdrawal** and **refined progress** separate.

For a person requesting qi during one day:

```text
requested_QU =
    2 × D × root_speed × purity_factor × affinity
      × method_rate × practice_fraction × support

purity_factor = 0.5 + 0.7 × root_purity / 100
practice_fraction = meditation_hours / 4
```

Preserve existing root speeds:

```text
effective root count: 1,   2,   3,  4,   5+
root_speed:          3.0, 1.8, 1, 0.6, 0.35
```

Initially retain the existing effective-count treatment for mutated roots to avoid an unrelated balance rewrite.

For root element \(e\), define its environmental representation \(c_e\) from the five-element field or mapped combination:

```text
element_affinity(e) = clamp(c_e / 0.2, 0, 2)
person_affinity = maximum affinity among possessed roots
```

A technique tied to an element uses that element’s affinity instead. A mismatched technique retains the existing **0.6 multiplier**. Yin/yang specialization may add a bounded 0.8–1.2 compatibility factor later.

`support` contains comprehension, age, physiology, injury, teacher, companion, and relevant skill modifiers. Preserve their present meanings, but **remove synthetic density and Palace qi-resource bonuses from it**.

Allocate actual elemental withdrawals from compatible channels. If demand exceeds available qi, scale all same-priority requests proportionally. A practitioner cannot consume Fire qi merely because total density is high when their method requires Water.

Refining:

```text
efficiency = clamp(
    0.60 + 0.20 × method_control
         + 0.10 × meridian_quality
         - 0.30 × local_corruption,
    0.20, 0.95
)

refined_gain = actual_withdrawal × efficiency
```

`method_control` and `meridian_quality` are normalized 0–1. Initially, meridian quality derives from forged body grades. Inefficiency dissipates qi; it does not return immediately to the source.

**Example:** single-root, purity-100 practitioner, matching balanced qi, complete lineage art (`rate=1.6`), four hours/day, all other support factors 1:

| Location | \(D\) | Requested QU/day | Refined at 80% |
|---|---:|---:|---:|
| Ordinary countryside | 1 | 11.52 | 9.22 |
| Sect spring | 4 | 46.08 | 36.86 |
| Palace estate | 64 | 737.28 | 589.82 |

High density therefore requires a **body/method intake limit**; otherwise the Palace trivializes progression.

Suggested maximum ambient intake:

```text
before body layer 8: 10 + 2 × body_layer QU/day
body layers 8–9, before Qi Condensation: 40 QU/day
Qi Condensation layer L: 40 × 1.25^(L−1) QU/day
```

Actual request is the smaller of the formula and intake limit. The Palace guarantees plentiful, compatible supply; progress still needs practice, safe refining, and breakthroughs.

### Extending body tempering

`body_tempering.gd::rate()` currently multiplies drills and labor by a spirit-root factor and `fifty.training_factor()`.

Keep:

- Nine body layers and existing medicine gates.
- Physical labor through the early layers.
- Methods, teachers, will, age, strain, polishing, and permanent grades.
- The rule that anyone can temper a body.

Replace the unconditional root speed bonus with a **qi-assisted supplement**:

```text
daily_tempering =
    physical_tempering
    + drill_tempering × 0.30 × min(1, allocated_body_qi / 10)
```

No qi is required for physical progress. A hidden root receives half the assisted benefit; a revealed root receives the full benefit. Rootless people can receive half benefit through guided medicine or a suitable tempering formation.

Use one shared per-person intake budget. Someone drilling and meditating must not receive two independent full allocations.

The revealed-root grade contribution may remain. The existing Palace teaching and polishing advantages should remain teaching and polishing advantages; do not duplicate them as environmental qi bonuses.

### Body tempering into Qi Condensation

Distinguish **Perfected Body**, meaning nine completed layers, from **Perfect-grade body**, meaning all nine layers graded Perfect. The existing `body_ready()` requires the former.

Recommended progression:

1. **Living Blood, layer 6:** preserve the existing possibility of revealing a hidden root.
2. **Open Meridians, layer 8:** permit deliberate circulation training.
3. **Perfected Body, layer 9:** permit dantian opening.
4. **Dantian opening:** 90 valid practice days, revealed root, breathing method, and 500 QU refined opening work.
5. **Qi Condensation layer 1:** stabilize the first personal reserve.

Before layer 8, qi assistance is consumed by tempering; it does not accumulate indefinitely in a nonexistent dantian.

Keep three separate quantities:

| State | Purpose |
|---|---|
| Opening/layer progress | Long-term cultivation investment |
| Personal qi reserve | Spendable refined qi |
| Deviation pressure | Instability from unsafe practice |

Do not use a single `society.qi` value as both lifetime progress and a rechargeable combat battery.

**Recommend thirteen Qi Condensation layers for everyone**, with techniques and bottlenecks limiting access. This replaces the current innate nine-versus-thirteen cap. Thirteen layers are associated with *A Record of a Mortal’s Journey to Immortality*; this choice is an adaptation rather than a universal xianxia rule. See the [novel’s realm overview](https://en.wikipedia.org/wiki/A_Record_of_Mortal%27s_Journey_to_Immortality).

Suggested costs:

```text
entry into layer 1: 2,000 refined QU after dantian opening
entry into layer L≥2: round(2,000 × 1.2^(L−1))
personal reserve capacity at L: round(100 × 1.35^(L−1))
```

A configurable fraction of daily refined gain fills reserve; the remainder advances cultivation. Default: **25% reserve until full, then all toward progress**.

Bottlenecks:

| Gate | Requirement |
|---|---|
| Layers 1–3 | Basic breathing art, 30 stabilization days/layer |
| Layer 4 | 90 stabilization days and demonstrated meridian control |
| Layer 7 | Complete art or equivalent instruction; 180 days |
| Layer 10 | Advanced art; 365 days |
| Layer 13 | Complete circulation; 365 days |
| Foundation Establishment | Separate later design |

The Palace possesses all relevant teaching and methods. Existing `techniques[].cap` controls major realms, so add explicit layer/control fields rather than silently changing that field’s meaning.

### Qi deviation

Use pressure accumulation rather than a new random injury roll on every API invocation:

```text
pressure_gain/day =
    0.04 × max(0, chosen_intake / safe_intake − 1)
    + 0.02 × corruption
    + 0.01 × elemental_mismatch
    + 0.01 × heart_demons

pressure_recovery/day =
    0.02 while resting
    0.01 during safe supervised practice
```

Pressure is clamped to 0–1. A safe method automatically stops drawing at the intake limit; exceeding it requires an explicit reckless regimen.

At pressure 1:

- Lose 20% of current uncommitted layer progress.
- Empty 50% of personal reserve.
- Receive 30 injury days.
- Reset pressure to 0.4.
- Record a setback.

Reuse `injury_until`, `damage`, and `heart_demons()` where appropriate. Lasting meridian damage should require repeated deviation, not an unavoidable Palace-density hazard.

### Beast cultivation

`wildlife.gd` currently has:

- A 16×12 ecology grid with 32-ground-tile cells.
- Hard-coded exposure categories at cells 36–39.
- Annual awakening hazards based on exposure.
- Persistent beasts whose `work` rises with condition only when they have a claim.
- Monthly breakthroughs requiring minimum age, work, practice, claim, method, medicine, and health.
- Instinctive catalyst acquisition using exposure.
- Spirit/demonic path state, purity, resentment, and instability.

Replace **exposure as the underlying resource** with sampled qi. Keep it temporarily as a derived UI/debug category.

Each ecology cell spans approximately **2×2 atlas cells**. Sample those cells once per day for cohort awakening; persistent beasts sample their actual position or occupied den.

Suggested awakening hazard:

```text
annual_hazard =
    min(0.005,
        0.00001 × species_awakening_affinity × min(D, 100))

probability_over_t_years = 1 − exp(−annual_hazard × t)
```

This reproduces the existing approximate hazard orders at densities 1, 10, and 100. Allocate awakening to the existing capped persistent population.

For awakened beast body cultivation:

```text
requested_QU/day =
    min(2 × 1.3^layer,
        2 × D × species_affinity × condition × instinct_rate)

work_gain/day = refined_QU / 730
```

Keep existing `minimum_years[layer]` as a biological minimum and require `work >= minimum_years[layer]`. At 2 refined QU/day, one work-year takes 365 days.

A claim gives reliable access and less disturbance, not the sole ability to cultivate. Replace the hard `claim >= 0` breakthrough requirement with enough accumulated work and an appropriate stable practice site.

Keep medicine, practice, health, age, path, combat scaling, and harvest quality. Replace the duplicated purity term in breakthrough quality with **local compatibility**.

Do not let qi alone create bark, herbs, and marrow. Until the plant system exists, preserve the current catalyst abstraction behind a clearly named temporary supply adapter. Later, consume actual plant or carcass stock.

### Determinism and span invariance

**`rate × days` is insufficient when density, depletion, injuries, or bottlenecks change inside the span.**

Use one authoritative day cursor. Advancing from day 100 to 130 must execute the same logical days as thirty single-day calls.

For each day:

1. Apply dated arrivals, location changes, maintenance, and source regeneration.
2. Route vein supply and formation gathering.
3. Collect people, beast, and plant requests against that day’s field.
4. Allocate resource budgets.
5. Commit refining, tempering assistance, deviation, and dated breakthroughs.
6. Resolve scheduled encounters and formation charges.
7. Commit depletion, decay, and reports.

Use stable IDs and explicit ordering. Daily output cannot depend on which person is processed first or whether ground walkers are visible.

Preserve the existing seven-day social schedule, but process every crossed boundary at its original date. Newly added qi work must not sample a later endpoint state for earlier days.

## 3. Foundation for spirit plants and spirit stones

### Spirit plants

A plant needs a small contract from qi:

```text
sample(position, day):
    total_density
    elemental_densities[5]
    purity
    yin_yang
    corruption

request_qi(consumer_id, position, elemental_demand):
    actual_allocation
```

A future plant definition should specify:

- Minimum and ideal total density.
- Required elemental densities.
- Yin–yang tolerance.
- Daily QU demand.
- Maximum safe concentration.
- Maturity work and accumulated spiritual essence.
- Ordinary water, soil, temperature, and light needs.

Example **seven-leaf herb**:

```text
minimum D: 2
ideal D: 8
minimum Wood density: 0.8
minimum Water density: 0.4
yin–yang tolerance: −0.5 to +0.3
maximum uptake: 0.5 QU/day
maturity: 365 successful growth-days
```

Growth is limited by the scarcest requirement and actual allocation:

```text
growth/day =
    min(density_sufficiency,
        Wood_sufficiency,
        Water_sufficiency,
        allocated_QU / 0.5,
        ordinary_habitat_sufficiency,
        1)
```

No growth below minimum conditions; stop above the safe concentration unless acclimatized. The Palace can provide tuned beds rather than flooding every species with maximum qi.

`nature.gd` already catalogs species and sightings; retain that role. `wild_supply.gd` currently regenerates medicinal stock from global richness. Replace that regeneration with spatial plant production in the later plant release, preserving `units()` and medicine inventory interfaces.

`fifty.provision()` currently refills medicine directly. Preserve this existing entitlement during qi and formations work. When plants ship, back it with Palace production/import accounts and reserve stock, so the transition does not silently remove promised provision.

### Spirit stones

Separate **spirit-vein flow** from **spirit-stone ore**. The novel treats veins and mines as related strategic resources but not interchangeable unlimited supplies. See [*A Record of a Mortal’s Journey to Immortality*, chapter 1203](https://www.wuxiaworld.com/novel/rmji/rmji-chapter-1203/?mobile-app=true&theme=wiki).

Proposed capacities:

| Stone grade | Stored QU | Standard full-stone value |
|---|---:|---:|
| Low | 100 | 1 low-stone unit |
| Middle | 10,000 | 100 |
| High | 1,000,000 | 10,000 |
| Supreme | 100,000,000 | 1,000,000 |

Capacity ratios are initial balancing rules. Market prices may diverge through scarcity and discharge power.

Each stone lot records grade, element, purity, count, and charge. A spent stone has negligible currency value. Recharging requires suitable crystal material and loses 20% of input qi; it creates no free currency.

Begin with finite ore deposits and explicit Palace stock. Natural crystallization can remain a later process.

`fifty.gd` already has `stone` and `will` restoration accounts. **Do not reinterpret its annual one-stone income as physical spirit stones without an explicit migration and design decision.** Rename its presentation to distinguish divine restoration resources from traded qi-bearing stones.

## 4. Formations: a simulable model

### Components and grades

A formation—**zhenfa / 阵法**—is a persistent spatial machine with:

- **Eye/core, 阵眼:** control and primary vulnerability.
- **Flags, 阵旗:** portable anchors.
- **Plate, 阵盘:** recipe/control interface.
- **Conduits:** links carrying qi.
- **Power source:** vein tap, stones, or personal qi.
- **Buffer:** stored operating energy.
- **Footprint and access policy:** where and to whom effects apply.

Flags, plates, and formations that can be breached are established conventions in Wang Yu’s novel; representative examples are indexed in the [chapter 699 synopsis](https://rmji.wiki/chapters/699/) and [Xuan Le’s mine-defense formation](https://rmji.wiki/characters/xuan-le/).

Use formation grades **1–6**, corresponding to increasingly complex mortal arrays, and a separate **Heavenly** provenance for Palace arrays. Formation grade is not cultivator realm or material grade.

| Grade | Typical anchor count | Default maximum radius, ground tiles | Maximum throughput, QU/day |
|---:|---:|---:|---:|
| 1 | 4 | 16 | 40 |
| 2 | 6 | 32 | 160 |
| 3 | 8 | 64 | 640 |
| 4 | 12 | 128 | 2,560 |
| 5 | 16 | 256 | 10,240 |
| 6 | 24 | 512 | 40,960 |

Heavenly arrays use explicit recipe limits. Their provenance grants stability and access privileges; they still account for power.

### Power, footprint, and stacking

Daily operating cost:

```text
upkeep =
    recipe_base × (radius / 16)^2 × (0.5 + 0.5 × intensity)
```

Use recipe-specific exceptions for small chambers and linear conduits. Never charge a ten-tile meditation chamber as a whole atlas cell.

```text
available = allocated_source + min(buffer, discharge_limit)
paid_upkeep = min(available, upkeep)
effective_intensity = paid_upkeep / upkeep × integrity × alignment
```

One-time damage, repairs, and transport consume additional energy. Protection may consume its charged shield after source loss; an unpowered concealment effect stops.

Priority:

1. Safety and occupied transport completion.
2. Protection and guardian recovery.
3. Concealment and wards.
4. Cultivation and gardens.
5. Reserve charging.

Same-priority consumers share proportionally. All arrays drawing from one outlet share its throughput.

For overlapping effects:

- Gathering transfers add only within source and conduit limits.
- Concealment uses the strongest effect.
- Illusion uses the strongest relevant effect.
- Multiple shields each spend their own charge in a fixed order.
- Generic modifiers have named caps; they do not multiply indefinitely.

### Effects

| Formation | Concrete behavior |
|---|---|
| **Spirit-gathering** | Pumps qi from a defined catchment or vein tap into a smaller volume; 80% transfer efficiency |
| **Protection** | Stores shield charge; spends 5 QU per prevented combat harm point |
| **Concealment** | Reduces unapproved site-discovery probability |
| **Illusion** | Imposes bounded navigation delay and perception interference |
| **Killing array** | Makes a paid attack through combat resolution |
| **Guardian mending** | Converts qi into guardian energy and structural repair |
| **Beast ward** | Checks approaching beasts’ resolve against paid ward strength |
| **Transport** | Moves authorized occupants between linked prepared endpoints |

**Gathering:** a grade-3 recipe may move 200 QU/day for 10 QU/day upkeep, delivering 160 QU/day. It cannot draw its own output back through its catchment.

Track chamber volumes separately from their parent atlas cell. A chamber occupies a carved-out fraction of the cell’s volume; subtract that volume and mass from the exterior representation. Overlapping gathering footprints use one shared compartment or are rejected.

This permits a Palace chamber at density 256 inside an estate averaging 64 without pretending the entire ten-li atlas cell is equally concentrated.

**Protection:** a basic barrier holds 500 QU and prevents up to 100 cumulative harm points. Intercept incoming harm once, before `Combat._hurt()` or structural damage. Breakage exposes the core; it does not retroactively erase wounds.

**Concealment and pilgrimage:** `fifty.gd::_process_journeys()` currently computes discovery from `find_rate`, saved fate, attributes, and luck. Preserve that personal calculation, but expose concealment:

```text
unapproved_find_chance =
    personal_search_score × (1 − concealment_strength)
```

For a new design, use base `find_rate=1.0` and Palace concealment 0.78, recovering the current approximate 0.22 factor while making its cause explicit.

An invitation or Heavenly call can grant a path token bypassing concealment. Admission remains a separate test. Decide whether a general call reveals the route or merely permits a fate-based search.

**Illusion:** a failed check adds seven journey days, at most three times per journey. Store outcomes by journey and attempt ID. It must never create an infinite pilgrimage.

**Killing arrays:** begin with a recipe that spends 50 QU per attack and has a one-day cooldown per target. Use an explicit combat profile, access rules, and incident records. Palace boundary arrays default to restraint; lethal mode responds to hostile assault.

**Guardian recovery:** `law.gd::advance()` currently restores 10 energy/day and mends 2 harm/day for eligible guardians without charging a source. Preserve those service rates:

```text
2 QU per restored energy
20 QU per repaired harm
maximum full daily demand per guardian = 60 QU
```

A guardian needing neither spends no recovery qi. Recovery remains tied to its plinth and valid state. Broken rubble requires a separate reconstruction recipe and materials; routine mending does not resurrect it.

Extend `guardian_card.gd` to show connected array, allocated power, recharge, and expected repair time.

**Beast warding:** evaluate at an attempted entry or raid:

```text
repel_score =
    ward_grade + 2 × effective_intensity
    − beast_layer / 3
    − hunger_pressure
    − resentment
```

Repel when positive; otherwise conduct one stable seeded resistance check. Repeated attempts require a cooldown. Connect this to `wildlife.gd::raid()` and site approach events rather than deleting beasts inside a visual circle.

**Transport:** require two active endpoints and mutual authorization:

```text
cost = 100 + 0.1 × ground_tile_distance QU/person
```

Reserve the full cost before departure. Place the person through authoritative location and journey APIs. A missing endpoint cancels before charging. Introduce transport after the other formation effects stabilize.

### Builders, skill, failure, and decay

**The catalogue already contains a formations domain.** `data/skills/domains/formations.json` includes geometry, flags, conduits, gathering, wards, illusion, killing, transport, maintenance, breaking, landform arrays, and design. They currently have `detailed: false`, so `skill_catalogue.gd` does not register them as active detailed skills.

Activate `formations.formations` first, with specializations for setup, gathering, wards, and maintenance. Expand existing disciplines when they need independent progression.

Proposed formation-master ranks:

| Skill level | Rank | Build permission |
|---:|---|---|
| 1–5 | Apprentice | Operate prepared grade-1 plates |
| 6–10 | First-rank master | Grade 1 |
| 11–20 | Second-rank master | Grade 2 |
| 21–30 | Third-rank master | Grade 3 |
| 31–40 | Fourth-rank master | Grade 4 |
| 41–45 | Fifth-rank master | Grade 5 |
| 46–50 | Sixth-rank master | Grade 6 |

These ranks are game terminology, not a universal novel standard. Realm limits personal qi and spiritual control; skill governs geometry and craftsmanship. A trained mortal can replace flags and stones but cannot personally energize an advanced design.

Construction requires recipe, materials, valid geometry, and work:

```text
construction_days = 5 × grade² / max(0.5, builder_efficiency)
alignment = clamp(0.8 + 0.02 × (skill_level − required_level), 0.2, 1)
```

Reject invalid geometry. Sample construction mishaps once per project, keyed by project ID, rather than once per progress call.

Ordinary integrity decays **0.0005/day**, plus damage and overload. Below 0.5 integrity, halve throughput; below 0.2, shut down. Maintenance spends material stock and work. Palace Heavenly cores do not age; replaceable anchors and overloaded conduits can still be damaged.

### Palace and sect starting infrastructure

**The Palace should be the best place an envoy has ever lived, including for those without exceptional roots.** Give every candidate excellent conditions; tournament rewards improve an already exceptional baseline.

| Infrastructure | Heavenly Dao Palace | Existing local sect |
|---|---|---|
| Source | Unique balanced Heavenly Origin | Grade-3 spring outlet |
| Estate density | Target 64 | Target around 4–5 near spring |
| General practice | Regulated density 128 | Shared density 6 chamber |
| Top-ten chambers | Regulated density 256 | No equivalent initially |
| Element matching | Five tuned practice chambers | Natural local composition |
| Protection | Heavenly barrier, 100,000-QU shield | Grade-2 barrier, 2,000-QU shield |
| Concealment | Strength 0.78; authorized paths | Strength 0.25 |
| Illusion | Safe admission/training courts | Small warning maze |
| Recovery | Supervised meridian-calming facilities | Basic recovery room |
| Guardians | Dedicated recovery network where installed | Powered Mountain Gate plinths |
| Beast ward | Strong boundary ward | Grade-2 livestock/site ward |
| Gardens | Powered, tuned bed infrastructure | One modest prepared bed |
| Transport | Prepared dormant endpoint | None |

Guardian swordsmen currently belong to the Mountain Gate system; do not relocate them to the Palace as part of formations work.

Budget the Palace suite at **at most 6,000 QU/day sustained operation**, with a **1,000,000-QU reserve** and additional replenishment after combat. Its 20,480-QU/day source leaves headroom for cultivation, gardens, and recovery. Exact chamber counts and volumes must pass a supply calculation against the final estate layout.

The sect receives a separate ring-fenced recovery allocation for its actual guardian count. If its grade-3 source cannot cover peak repairs, use a finite stone reserve and report the deficit.

Palace arrays may be seeded as divine infrastructure without inventing a living high-realm builder. NPC-built arrays still require skill, materials, and time.

### Map presentation

Atlas: core icon, selected footprint, source connections, and operating state.

Ground: flags, engraved plates, plinth conduits, restrained boundary effects. Rendering is cosmetic; headless simulation uses the same footprint and power state.

Book entry:

> Five-Element Gathering Court · Heavenly provenance · 128 density target · 384 QU/day delivered · source healthy · intake regulated for novice bodies.

## 5. Integration plan in this repo

### Stage A: qi field first

Add:

- `src/qi_field.gd`: field sampling, requests, allocation, mass ledger.
- `src/qi_worldgen.gd`: terrain-derived background and vein graph generation.
- `data/qi/*.json`: definitions above.
- Later test scripts `tools/test_qi.gd` and `tools/test_qi_spans.gd`.

Change:

| Existing file | Integration |
|---|---|
| `society.gd` | Own qi service; adapt `qi_rate()`; replace synthetic density lookups |
| `body_tempering.gd` | Consume allocated qi for bounded assistance |
| `wildlife.gd` | Sample field; replace hard-coded exposure as resource; drive work with qi |
| `world_map.gd` | Qi overlay and `_info()` |
| `person_book.gd` | Location, affinity, absorption, and refining explanation |
| `world_save.gd` | Capture/restore qi state and repair missing data |
| `data/society/cultivation.json` | Remove density as authority; add explicit compatibility/version settings |
| `data/society/dao.json` | Retire `qi_bonus` as an environmental multiplier |

Keep the current cultivation progression rules initially behind the new absorption adapter. **Do not implement the full proposed dantian/thirteen-layer redesign in the qi-field release.** It belongs after spirit plants and alchemy, as requested.

This first release should deliver an inspectable field, veins, depletion, real absorption, and beast integration. No new formation, plant, or alchemy gameplay is necessary.

### Stage B: formations second

Add:

- `src/formations.gd`: instances, spatial index, upkeep, effects, decay.
- `data/formations/recipes.json`.
- `data/formations/grades.json`.
- `data/formations/starting_sites.json`.
- `tools/test_formations.gd` and `tools/test_formation_spans.gd`.

Change:

- Activate the existing formations skill definitions and associated activities.
- `law.gd`: charge guardian recovery through formation allocation.
- `guardian_card.gd`: explain power and repairs.
- `fifty.gd`: concealment and authorization in pilgrimage discovery.
- `combat.gd`: one authoritative shield interception and array attack integration.
- `wildlife.gd`: ward checks for raids and site entry.
- `sites_ground.gd`/ground presentation: resolve anchors and display components.
- `world_save.gd`: formation state and migrations.

Implement in order: power network → gathering → guardian recovery → protection → concealment/wards → illusion/killing. Transport follows once journeys and endpoint accounting are verified.

Reference site IDs and semantic anchor names rather than editing estate geometry. This avoids coupling the proposal to the concurrent Palace-layout work.

### Save and repair implications

`world_save.gd` uses reflected script variables and explicit `CHILDREN` traversal. Underscore-prefixed fields are omitted; configuration is reloaded. Its envelope currently accepts exactly version 1.

Required changes:

1. Add qi and formation services to `CHILDREN`.
2. Keep rebuildable spatial indexes and visual caches underscore-prefixed.
3. Save generated vein graph, reserves, active field deviations, compartment masses, formation integrity, buffers, project IDs, and simulation day.
4. Save fixed-point remainders and event counters.
5. Add any new person columns to `repair_columns()` and allocation paths.
6. Use subsystem schema versions, or introduce envelope migration that explicitly accepts version 1. Simply incrementing `VERSION` would reject old saves.
7. Repair missing qi at the save’s current day, following `repair_wildlife()`’s no-retroactive-replay principle.
8. Seed starting formations only once, using stable IDs and a saved seed marker.
9. Validate array lengths, finite values, source IDs, anchor validity, and nonnegative charge.

Existing `society.qi` is abstract progress. Preserve it as legacy progress during the adapter release; do not withdraw equivalent historical mass from newly created veins. Convert progress and personal reserves only when the later cultivation redesign ships.

### Deterministic scheduling

`wildlife.advance()` already replays days, but `society.begin_tick()` and `body_tempering.weekly()` use broader social spans. Existing `tools/test_wildlife_spans.gd` compares daily calls with seven-day calls; it does not establish invariance for arbitrary jumps across all systems.

Introduce one coordinator for qi and dependent consumers. Do not independently advance wildlife through an entire span and then make people consume the endpoint field.

Requirements:

- Replay every crossed day and social boundary.
- Apply location/technique changes at dated boundaries.
- Key new random events by world seed, subsystem, stable entity ID, event date, and attempt ID.
- Avoid Godot’s process-dependent string hash as a persistent identity contract.
- Allocate fairly using stable sorting and deterministic remainder distribution.
- Prevent double-stepping when both the main loop and social tick call an advance method.

Represent qi as **integer thousandths of a QU**, with 64-bit totals and saved rounding residuals. Integer accounting makes conservation and save comparisons straightforward.

Full society-wide span invariance also requires auditing existing invocation-based random learning, yearly checks, and breakthrough attempts. Do not claim that the qi field alone fixes those.

### Low-RAM performance

Keep the **360×240 atlas as the authoritative ambient resolution**. It is small enough for packed storage; avoid a dictionary per cell.

Five `PackedInt64Array` mass channels occupy approximately **3.3 MiB**. Composition/background tables and a small overlay should keep the qi subsystem within a proposed **12 MiB incremental budget**, excluding existing world rendering.

Optimization:

- Derive untouched background cells lazily.
- Maintain a sorted active set for outlets, depleted cells, occupied sites, and formation catchments.
- Update only active cells daily.
- Use explicit small compartments for chambers and herb beds.
- Cache wildlife ecology-cell samples once per day.
- Reuse request buffers; avoid per-consumer dictionaries in hot paths.
- Parse `body.json` once for wildlife; `try_breakthrough()` currently reparses it.
- Rebuild the atlas qi texture only when visible and dirty.
- Never instantiate qi nodes or particles per tile.
- Never depend on chunk visits or walker animation for absorption.
- Bound diagnostics and retain daily history only for selected sites.

For a future optimization, analytically advance an unobserved, unused cell through constant recovery/decay intervals. Establish exact daily-reference tests first.

### Tests to add later

No tests or Godot processes were run for this research.

**Qi release:**

- Coordinate conversion at cell boundaries and site centers.
- Identical vein graph for the same seed; Palace superiority across ten seeds.
- Five elemental masses sum to total mass.
- Conservation: opening mass + sources − withdrawals − losses = closing mass.
- No negative mass under competing requests.
- Equal consumers receive equal allocations, independent of insertion order.
- Root affinity and mismatched technique behavior.
- Rootless physical tempering remains possible.
- Beast advancement responds to density; zero available qi produces no qi-work.
- Save/load preserves reserves, depletion, dates, and rounding.
- Legacy repair does not replay past centuries or duplicate sources.
- Compare daily stepping with irregular partitions such as 1, 6, 37, and 365 days.

**Formations release:**

- Gathering depletes its source and cannot feed itself.
- Chambers neither duplicate volume nor ambient mass.
- Shared-source arrays respect aggregate throughput.
- Underpowering reduces effects consistently.
- Guardian repair consumes exact power and preserves rubble semantics.
- Shields intercept damage once.
- Invited travelers bypass concealment without bypassing admission.
- Wards affect entry/raids without changing beast population counts.
- Decay, maintenance, and construction survive save/load.
- Headless and visible worlds produce identical authoritative state.
- Power loss, depletion, and overlapping formations remain span-invariant.

Run these only when the machine is available; this proposal requires no engine execution now.

## 6. Open questions for the owner

1. **Qi Condensation structure:** adopt thirteen layers for everyone, with technique gates, or retain nine ordinary layers plus four exceptional layers?
2. **Palace permanence:** should its source remain permanently supreme, or can a future player-created estate surpass it?
3. **Heavenly calls:** do they reveal a safe route, or authorize pilgrims who must still discover the Palace?
4. **Rootless candidates:** may Palace infrastructure eventually open an artificial qi path, or is their progression limited to body cultivation?
5. **Spirit stones:** should traded stones remain separate from the existing Apostle-restoration `stone` resource?
6. **Power shortages:** should the Palace automatically spend reserved stones to maintain candidate services, or visibly ration lower-priority facilities?