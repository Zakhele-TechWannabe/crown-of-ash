# Wildlife implementation status

`src/wildlife.gd` owns monthly age-class cohorts, daily persistent animals, two independent random streams, cultivation records, population history, and events. It is owned by Society and serialized by WorldSave. Missing wildlife state is initialized at the loaded date without replaying historical days or altering villagers. No player save is used by verification.

The curated `start` values describe the local catalogue sample. `ecology.json` explicitly scales nonzero samples to regional cohorts; species with zero starts remain absent. Predation uses configured diet tags, local and neighbouring cells, saturating attack success, and a cover refuge. Predators' condition and mortality respond to prey availability. This is a provisional ecology calibration rather than a completed spatial model.

Forest & beasts retains bark patches, spirit herbs, hunting supply and yearly harvest figures, followed by population counts, roles and ten-year trends. Bestiary starts with one entry per present species, then awakened records and at most five notable ordinary individuals. Individual records use sentence case, distinct physical traits, place names, and labelled age bars. Chronological age and cumulative biological age are separate; layer completion slows future biological aging. The displayed expected lifespan is the species scale times the completed layer multiplier, not a guaranteed remaining life.

Still incomplete against wildlife.md:

- Ground-sampled habitat cells and actual spring, peak, and spirit-tree sites; cells currently use configured terrain proxies and provisional site cells.
- Wolf pack aggregation, detailed energy/biomass budgets, water seeking, territory/marking, travel avoiding buildings, threat recognition, route planning, and request understanding.
- Encounters sample forest/meadow workers and wandering school-age children, with daily persistent and monthly temporary population stories. Quiet meetings flee, mothers and wounded/starving beasts may fight through Combat; both outcomes use map scenes. Workplaces and the forest edge come from the live village registry and must lie inside the animal’s configured roaming range; staged meetings travel there. Exact route-distance checks, defended kills and habituation remain incomplete.
- A shared domestic animal model linked to livestock production. Pen raids decrement the wildlife livestock inventory and food stock, but production does not yet depend on that inventory.
- Instinctive methods now improve through years at a claimed site and rare monthly learning rolls. Rare compatible site forage supplies gate catalysts; carnivores and omnivores can consume unharvested fallen cores. Human-equivalent gates and minimum years still apply. Site locations and resource competition remain provisional.
- Complete essence-to-medicine processing, purification, core assimilation limits, anatomy-specific products, and nonlethal harvests. One-time essence allocation exists; human medicine integration is provisional.
- Map cards now open for awakened individuals and the notable wolf leader. Silhouettes distinguish major anatomy groups; detailed species forms, high-layer aura and wound rendering remain incomplete.
- Extraction of every tuning number into the data files, all research test families, and the 50-year whole-world performance comparison.

Villager deaths are permitted by wildlife.md; no injury-only fallback is applied. No initial awakened animal is guaranteed and no zero-population species is respawned to manufacture an event.

## Second round verification — 14 November 2026

- Ran the full serial `python3 tools/run_phase2_checks.py`: 30/31 initially passed. The childhood talent fixture lost a comparison child to the newly enabled wildlife encounters; that isolated unit fixture now disables wildlife. Its targeted recheck passes, as do the final ledger UI and wildlife rechecks (all 31 checks pass after rechecks).
- Ledger UI checks exercise the forest sections, catalogue-before-awakened ordering, empty and populated awakened states, formatted age text, ordinary leader and awakened map picking, and the contextual card. No script or formatting errors remain in the final UI log.
- Wildlife checks include unique names, distinct present-group art, distant-workplace rejection, 193 encounters and 2 deaths in a seeded worker decade, forced natural acquisition past layer 3, and the 50-year ecology/persistence checks.
- The requested 20-year headless simulation exited successfully with no save or archive, and no script errors. Encounter counts: **174 in years 1–10; 110 in years 11–20** (284 total). Wildlife killed **0 villagers**, including hunting deaths. Eleven awakenings occurred; six awakened animals survive: **layer 0: 3; layer 1: 1; layer 2: 1; layer 6: 1**. All six are spirit-path beasts; no demonic beasts. A natural layer-4 beast was already present at year 10.

Year-20 wildlife populations (32,470 total):

| Species | Count |
| --- | ---: |
| Asiatic black bear | 525 |
| Common pheasant | 8,588 |
| Giant panda | 261 |
| Golden snub-nosed monkey | 4,966 |
| Grey wolf | 1,408 |
| Hare | 1,837 |
| Malayan porcupine | 1,222 |
| Red fox | 1,377 |
| Reeves's muntjac | 855 |
| Siberian roe deer | 2,880 |
| Sika deer | 2,201 |
| Takin | 1,055 |
| Wild boar | 5,295 |

All other curated wild species remain absent. Domestic inventories are separate from these wild population totals. Full measurements: `out/wildlife_round2_report.json`; simulation log: `out/wildlife_round2_20y.log`.

The requested windowed render command was attempted, but this sandbox has no accessible X11 or Wayland display. Pixel captures remain for the owner to render; both headless UI viewport sizes pass. Render failure log: `out/wildlife_round2_render.log`.
