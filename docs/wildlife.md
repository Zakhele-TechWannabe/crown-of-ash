# Living wildlife and beast cultivation: design, version 1

Animals live in the valley: they eat, breed, hunt, mark territory, fight, raid the pens, meet people, and, very rarely, awaken and cultivate into spirit or demonic beasts, up to the equivalent of Body Tempering. **No manufactured disasters:** danger comes from context, as in nature.

**Sources of truth:**
- **docs/wildlife_research.md**: ecology (food, hunger, stamina, territory, breeding, predator–prey).
- **docs/beast_cultivation_research.md**: awakening hazards, the nine beast layers, gates, grades, spirit and demonic paths, combat scaling, cores, per-species forms and the test list.

Follow their numbers unless this file says otherwise. Every number goes in data (data/wild/ecology.json and data/wild/beasts.json, plus fields on data/wild/curated.json), not in code.

## Two tiers of animals (cost first)

1. **Populations** are the many:
   - per species and per **range cell** (a coarse grid over the valley region, about 32×32 tiles; the cells know their habitat mix from the ground sampler: biome, forest weight, water, the qi sites);
   - each holds age classes (young, adult, old), mean condition (fed to starving) and counts;
   - a **monthly tick** covers food by season and habitat, grazing pressure, predation (a functional response from predator to prey counts in the same and neighbouring cells), births in the species' season with its gestation and litter size, deaths (age, starvation, predation, hunting), and dispersal to neighbouring cells when crowded or hungry;
   - all the curated individual-tier species, plus a few population-tier ones that matter for food webs (hare, pheasant, rodents as a pool).
2. **Individuals** are the few, persistent named animals with a position:
   - large predators: tigers, leopards, bears, plus one record per wolf pack (pack size as a number);
   - any **awakened beast**;
   - any animal in a story right now: a raider of the pens, a wounded boar, a mother with cubs met on a path.
   
   They tick **daily**: hunger, stamina, where they go (home range and territory, marking, patrol), hunting (draw kills from the cell's prey population), resting, denning in winter for bears. Cap the live individuals at about 150. Beyond that, promotion waits; never delete a named animal for performance.

**Promotion and demotion:** a population member is promoted to an individual when it awakens or enters a story. A non-awakened individual returns to its population when its story ends and nobody is watching it. Conservation: the counts always add up, with no duplicates and no losses.

## Encounters with people

Danger comes **from context**:
- surprise at close range;
- a mother with young;
- a kill being defended;
- cornered or wounded;
- rut;
- starving and habituated to the village.

Each species has a flight distance. Most encounters end with the animal leaving.

- **Where encounters happen:** where people actually go, meaning workers at the forest edge, foragers, woodcutters, the herd pens, hunters and pilgrims. Check daily per individual near those places, and monthly per population cell for the rest (a cheap hazard roll).
- **Fights** use **Combat.fight**. Add base combat profiles (power, guard, speed, breath and will) for every curated species to data/society/combat.json, following the calibration table in the beast research (an ordinary tiger is 50/30/7/8/2). Motives come from context: "young" for a mother, "hunger" when starving, and so on.
- **Villager deaths to animals are allowed but rare.** Tune so that an ordinary decade has 0–2. Log them; the owner judges the difficulty.
- **Raids on the pens:** wolves, leopards, foxes and bears can take livestock from the village herd (the economy's herd and food). The village responds in v1 with stories and fear. Watch dogs and fences can come later.
- **Hunting** (wild_supply.gd and Combat.hunt) now draws real animals. The beast a hunter finds comes from the deer and boar in the cells around the Eastern Hunting Grounds, so hunting thins them and they recover by breeding. The old abstract herd number goes away (keep the ledger stats working).
- **Flight from people:** heavily hunted cells make animals warier (longer flight distance), and quiet years make them bolder.

## Beast cultivation (rare)

Follow beast_cultivation_research.md sections 2–4.

- **Awakening hazards** per animal-year:
  - 1 in 100,000 in ordinary land;
  - 1 in 10,000 with regular access to a weak qi site;
  - 1 in 1,000 at a strong site;
  - a separate one-time 0.5% trial for an exceptional event (a spirit fruit eaten, a qi storm survived);
  - all times the species' affinity, capped as in the report.
  
  The **qi sites** are the spirit spring, the peak and spirit-tree groves in the forest (the ground's spirit-tree decoration), each with a finite capacity. Population members get their exposure from their cell's sites.
- **Nine beast layers** with the human layer names and the report's bodily effects. Each has minimum years, gates and Low-to-Perfect grades stamped for life (quality Q as proposed). The **lifespan multiplier** slows ageing from that point and never rejuvenates.
- **Combat scaling:** use the report's formula. Layer 0 must equal the base profile.
- **Paths:** latent, spirit or demonic. Purity P and resentment R update monthly as proposed. Ordinary carnivory or a single kill never makes a beast demonic on its own. Demonic needs a sustained loop, and recovery needs hysteresis.
- **Intelligence tiers** (layers 1–3, 4–6, 7–9) change behaviour: hazard memory and recognising particular people; then guarding resources and planning routes; then understanding simple requests. There's no speech in v1.
- **Remains:** layers 1–3 give infused materials; 4–6 a fragile core seed; 7–9 a stable beast core. Essence is conserved across products. Village hunters who kill an awakened beast bring back materials that count toward tempering medicine: layer-4 bone toward iron-bark recipes, marrow toward layers 5–6. Cores are an optional extra for layers 7–9, with seven-leaf still required. Demonic goods need purifying and lose yield.
- **Awakened beasts in the world:** they claim a qi site in their range and defend it. Spirit beasts tolerate familiar people at a distance. Demonic ones may hunt people or target a remembered attacker. Stories name them as villagers would: "the white-browed deer of the spring", "the scarred boar".

## On the map (2.2D)

- A small code-drawn sprite set (src/beast_art.gd: cached textures, palette colours, ink outline, top-left light, soft shadow, sorted by feet with walkers and trees), at the right scale against a 1-tile villager:
  - deer (sika, roe, musk), boar, wolf, tiger, leopard, black and brown bear, fox, goral, takin, golden monkey, panda, muntjac, porcupine, hare and pheasant;
  - sheep, goat, cattle, pig and chicken for the pens if the art pass hasn't covered them;
  - two frames to walk; a lying or eating pose is optional.
- **Individuals** in view are drawn at their position, moving along simple paths: off the walk grid is fine in forest and fields, and they avoid buildings.
- **Populations:** a few **ambient animals**, consistent with the counts in the cells in view, wander there (visual only, generated deterministically from the cell and day). A crowded meadow shows more deer.
- **Awakened beasts** show their layer signs subtly: a glossier tint, a pale or golden sheen, eyes that glint, and at layers 8–9 a faint aura while moving. Demonic beasts get a darker or reddish undertone and a slight shimmer. Keep it readable, not loud.
- Encounters with villagers play as fight scenes, reusing the stages in village_life.gd: they stand, harm floats up, then one flees or falls.

## The Wild tab and the Bestiary

Extend the existing Wild tab and Bestiary in village_ledger.gd:
- species **populations over time** (a small chart per species, monthly samples), with the current count and trend;
- **notable animals:** named individuals with species, age, layer and grade, path, and last seen;
- the **awakened beasts list** and this year's wildlife events (births, raids, encounters, kills, awakenings, breakthroughs).

Stories go under a "Wild" filter in stories_rail.gd.

## Saves

All wildlife state (populations, individuals, beast cultivation, RNG) must save and load through the save system (follow how other subsystems implement it).

## Performance

- The monthly population tick must stay cheap: cells × species. Individuals tick daily (≤150). Ambient animals are drawn only in view.
- Measure a 50-year headless sim, with and without wildlife, and keep the slowdown under about 25%.

## Tests (tools/test_wildlife.gd)

Use the test families in beast_cultivation_research.md §6. At minimum:
- Populations stay bounded and don't crash to zero over 50 years without hunting. Hunting pressure lowers deer near the lodge, and they recover.
- Predators eat prey: the counts respond.
- Conservation: promotion and demotion keep the counts exact.
- Encounters:
  - most end with the animal leaving;
  - a mother with young fights;
  - villager deaths are within the tuned range over a seeded decade.
- Awakening:
  - 0 with no exposure;
  - observed rates match the hazards statistically;
  - layers need their minimum years;
  - grades are immutable;
  - L0 combat equals base.
- Paths: one kill doesn't make a beast demonic; sustained corruption does; recovery needs hysteresis.
- Remains: essence is conserved; demonic goods yield less.
- Save and load round-trips the wildlife exactly (run both worlds 30 days and compare).
- Full suite passes.

## Existing worlds

The owner's world will be running when this ships (the last reset happens after the Fifty). Wildlife must **initialise inside an existing save**: when a save has no wildlife state, seed the populations and individuals as for a new world, at the save's current date. **Never reset the world.** Add this case to the save test.
