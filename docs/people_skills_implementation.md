# People and skills: phase 1 implementation

The approved rules remain in `people_skills.md`. The catalogue is loaded from
`data/skills/`: ten spheres, 100 domains and fifteen disciplines per domain. The
25 village domains have techniques, ten perks and nine gates per discipline.
Deferred disciplines have names and descriptions and explicitly set `detailed: false`.
`rules.json` owns titles, XP thresholds, attribute names and spirit-root types.
`activities.json` maps facilities to techniques and work difficulty.

`src/population.gd` owns people independently of scene objects. A person's ID is
its stable array index. Attributes, birth dates, household/place IDs, inherited
potential, hidden talents, roots, traits and health/comfort are packed columns.
Touched skills form a sparse linked pool; `sparse_skills(id)` materialises a map
only when a record is requested. Job schedules are shared, with at most two
half-day shifts. Cached practice pointers must be refreshed with
`prepare_person(id)` after changing a job. `add_child` derives birth attributes
and potential from parents and increases root inheritance probability.

Daily processing has two batched passes: a frozen snapshot of nearby teachers,
then learning and ageing. Call `begin_day(day)` and repeatedly
`process_batch(256)`; `tick_day(day)` is the synchronous testing/small-village
wrapper. A pending day completes before another can start. Shared calendar
variants train clay digging, hemp harvest, bloomery work and winter maintenance
on their actual days. Youths apprentice to a parent from twelve and inherit the
adult work schedule and full food requirement at eighteen. The existing economy
feeds food and mood into the store and applies the worker's skill output to
production. Work more than five levels below a person gives 10% XP; over-hard work
uses the 50% failure rate.
Assisted practice trains the discipline until the specialisation unlocks.
Unused high skills lose banked XP and can decline within their existing title.
The level-35 gate needs qi; possession of a root alone does not open it.
Higher realm gates remain closed until the approved future realm design exists.

Modifiers are sparse and opt-in. The example consumables/manuals/places in
`modifiers.json` are definitions, with no acquisition route in the village.
Instant effects, expiry in days/years, permanent effects and stacking share
`skill_modifiers.gd`. No consumable is automatically granted to residents.

Walkers are presentation records with population IDs. Existing schedules and
paths for the twenty residents remain in `village_life.gd`. Spatial buckets
select additional nearby records, and at most 100 walkers are drawn. Extra
background views use their stored location; full routes are maintained only for
the original twenty. Follow is available for those twenty; other person records
say “Not nearby”.

People navigation lives in `people_browser.gd`. Place/work/life/status cards
lead to an indexed name list. Status groups overlap; someone hungry with a
spirit root appears in both. People with two trades appear in both work paths.
The name search accepts words, `age:12-30` and
`skill:grain_farming.farming>=16`. Discipline sorting takes a discipline ID.
`people_list.gd` maintains only viewport rows plus overscan; scrolling never
re-filters or sorts the population. Catalogue summaries are cached by day and
skill-pool revision. The drawer periodically refreshes economy values; People
navigation retains its controls and scroll rather than rebuilding each half-second.

Headless checks (run one Godot process at a time):

```
godot --headless --path . -s tools/test_people.gd
godot --headless --path . -s tools/bench_population.gd
godot --headless --path . -s tools/test_ledger_ui.gd
godot --headless --path . --quit-after 120 -- --goto="Servants' Village" --day=200 --ledger=people
godot --headless --path . --quit-after 120 -- --goto="Servants' Village" --day=200 --ledger=people --person=0
godot --headless --path . -- --headless-sim --years=10
```

The benchmark uses 100,000 people, two shifts and ten touched skills each,
including unused Skilled skills for rust. Memory is the Godot static allocation
delta including the shared catalogue and population, separate from full-world
terrain/UI assets. The benchmark also reports total static allocation and the
worst scroll-page build across distant positions in a 100,000-ID list. These
measurements describe that workload, not a bound for arbitrary skill density.
Milestone history is capped at 8,192 records to bound RAM; large-region archival
history requires a future persistent chronicle rather than unlimited live strings.
