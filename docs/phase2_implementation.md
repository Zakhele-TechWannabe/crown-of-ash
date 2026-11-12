# Society, lineage and cultivation

The approved source is `the-long-road.html`. `disciples.md` is superseded. The
population starts as villagers, with no sect, manual, awakened root or sect post.
Lay leadership represents an experienced starting villager. Sect formation is
conditional, never dated or forced.

## Storage and updates

`population.gd` owns stable person IDs and the skill pool. Its `society` owns packed
columns for the second parent, spouse, master, entry day, root revelation, realm,
layer, qi, body practice, technique, injury, foundation damage, reputation and
life state. The existing `parent_id` column is the mother link. Children,
siblings, ancestry, master ancestry and seniority are derived on request.
Temporary weekly master-slot counts and an annual child index avoid repeated
whole-population scans; these indexes are rebuilt from the authoritative links. Starting parent links consistent with the residents' surnames and ages are specified in `data/society/families.json`.

`relationships.gd` stores directed adjacency lists in packed pools: target, next,
opinion, familiarity, trust and bond bits. The cap is 48 outgoing ties. At the
cap a weak tie is reused; marriage, sworn and master bonds receive retention
priority. Only notable ties allocate packed memory/grudge pool slots, reached through
sparse indexes. UI dictionaries are materialised on demand. At most three
memories survive, ranked by decaying weight. All-pairs population scans are not
used for weekly acquaintance formation: each person samples one contact.

Daily skill batches and weekly social batches share `process_batch`. Social work
can be resumed with `begin_tick` and `process_tick`. Scene processing uses small
batches inside a two-millisecond work budget. Large scene populations also yield during annual faction and position rebuilding.
Individual ledger events can still exceed that budget; this is not a strict
frame-time guarantee. Standalone synchronous APIs remain available to tests and
headless runs. The benchmark reports actual costs. Unused skill rust is checked
monthly with elapsed-time scaling. Active practice and gates remain daily.

Factions are aggregate records rather than objects per person. Membership lists
are packed IDs; a sparse membership index supports navigation. Household names
are cached by day. Society displays 25 faction cards per page and at most twelve
member links per card; the full member list uses the virtual People browser.
Annual faction rebuilding is separate from the normal weekly benchmark workload.

## Rules and APIs

- `data/society/relationships.json`: event deltas, trust, familiarity, bonds and
  asymmetric trait compatibility.
- `events.json`: discovery, visitor, birth and awakening rates.
- `cultivation.json`: ten elements, root speeds, place densities, techniques,
  realm costs, chances and lifespans.
- `positions.json`: each post's existence and holding conditions.
- `data/skills/rules.json`: tier practice floors and learning multipliers.

Marriage uses a soft cultivation preference: mixed mortal/qi couples need mutual
opinion 70 instead of 50. The default kin policy excludes lineal, sibling and
avuncular matches; cousins remain eligible with mutual consent and parental
approval. Set `extended_kin_exclusion` in `events.json` to also exclude shared
ancestors within three generations. These explicit demographic rules keep the
closed starting population configurable without adding immigrant residents.

`social_event` applies harm, reputation/gossip and nonlethal revenge consequences.
`swear_oath`, `marry`, `accept`, `betray`, `pass_legacy`, `pact`, `schism` and
`absorb` expose checked transitions. Work, household meals, festival insults,
hunger assistance, teaching and elder support feed the weekly update. Parents
contribute 30% of their mean opinion to a newborn; inheritable grudges and debts
can persist. Master acceptance checks aptitude, opinion, competence and slots;
techniques pass to qualifying spiritual disciples. Craft pupils change trade.

Roots exist at birth but remain unknown until a childhood sign, meditation
insight at a qi site, hunting-ground fruit or a West Road visitor reveals them.
A root alone supplies no qi and unlocks no skill ceiling. Broken manuals can
also reveal a hidden root through study. Rare complete Profound finds permit
the first Foundation breakthrough; Yellow fragments stop at Qi Condensation. Cultivation begins at
0.1 technique efficiency. Qi uses root count/purity, element match, site density,
comprehension, age at awakening, teaching, companionship, resources, physique,
foundation condition and modifiers. Failed breakthroughs lose qi and cause
recoverable injury. Grudges and guilt impede breakthroughs.

Village, household, guild, clan and craft lineage formation precede halls and
sects. A sect needs Foundation, a complete technique, five lineage cultivators,
a grade-2-or-better site and a year's food stores. Other faction types and
conditional positions are available as the relevant social state emerges.
No war or killing is introduced.

## Lifespan death

`simulation/lifespan_death_enabled` in `project.godot` defaults to **false**.
People outliving their realm's lifespan remain alive as frail elders. Population
therefore grows only through births under the default rules. Turning the setting
on enables old-age life-state transitions; default verification leaves it off.

## Skipping

The speed menu offers Skip 1/10/100 years, progress and Cancel skip. Walkers stay
frozen. Cancellation completes at most the current week, preserving calendar
consistency. Population practice, ageing and social work use weekly spans.
Food/material accounting retains its dated half-day calendar events, spread
across frames; harvests and stocks are not approximated as seven identical days.
Weekly population practice is approximate at seasonal/job transitions and is not
expected to reproduce daily random-event sequences exactly.

Headless: `godot --headless --path . -- --headless-sim --years=100`, or add
`--skip-years=100` for weekly population stepping. `--skip-years=N` runs and exits by itself under `--headless`; in the windowed
game it starts an interactive skip.

## Verification

`python3 tools/run_phase2_checks.py` runs every `test_*.gd` sequentially and only
terminates processes it created. `tools/bench_population.gd` measures 100,000
people, one million skill entries and four million ties, including amortized
weekly social work and monthly rust. Daily and weekly timings use the median of
three sequential samples, with all samples printed to expose host-load variation. Its explicit thresholds are 2,000 ms/day,
200 MB decimal for core/catalogue storage, and 100 ms for a virtual list page.
The memory threshold accounts for the new four-million-tie workload, unlike the
phase-1 no-tie benchmark's 150 MB limit. Annual aggregate faction construction,
terrain and UI assets are outside that core memory measurement.

`python3 tools/check_skill_descriptions.py` verifies all 100 domain and 1,500
discipline descriptions, rejecting duplicate text and shared six-word phrases.
Results and raw output go to `out/phase2/`; measured results are recorded in
`phase2_results.md`.
