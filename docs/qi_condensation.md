# Qi Condensation implementation status

Stage 3b functional integration and its requested checks **PASS**. Live practice
is wired and the random ladder is removed. Measurements and material limitations
appear in the Stage 3b section below. The earlier
sections describe the Stage 3 groundwork and detached compiler at their dates;
they are historical, not a verdict on the current live integration. No new body
diagram or screen is included.

The new anatomy definition, `data/cultivation/anatomy.json`, describes the
sixteen human nodes and twenty-four directed channels. Both future centres
are visible in the data but closed. The breath gate connects to the lower
dantian through abdominal and lumbar alternatives. Separate routes reach
both palms and soles and return toward the torso.

`src/meridian_store.gd` holds body state in packed columns. Only qualified
people need a body row; other people have a single slot index. Creating a row
requires nine Body Tempering grades and an awakened root. Each channel uses
its own weighted foundation grades. Keyed width and conductivity variation
does not draw from the population's random stream. Ten root positions map
to the five elemental affinities. Capacity and conductivity remain distinct.

The store reserves columns for node inventories and quality moments, edge
condition and recorded flow, personal reserve, residue, integration work,
arithmetic remainders, certified layer and nine achievement dates. A fresh
body has no qi, no recorded execution, no certifications and no migration
endowment. The inspection adapter reports zeros for unexecuted flow rather
than estimating achievements from potential capacity. It creates a detached
dictionary only when one person is inspected; dictionaries are not stored
per person.

`Society.prepare_meridians(person, day)` explicitly prepares a qualified
body once. `Society.meridian_report(person)` inspects existing state without
creating or changing it. Automatic practice and preparation are not wired.
`WorldSave` includes the store through its explicit save/restore hooks.
Missing older-save columns gain empty slots during column repair. Old
abstract qi and realm records are not converted to physical reserve.

The serial phase-2 runner discovers `tools/test_qi_condensation.gd`. At this
stage that test covers anatomy connectivity, dormant centres, regional grade
weighting, foundation scaling, root mapping, idempotent preparation, packed
memory size, report isolation and actual save recursion. It does **not**
establish progression, live determinism, safety or performance acceptance.

The immediate unresolved dependency is the session compiler. The Stage 2
solver's `finish_quiescent` only batches a stopped session after all mobile
packets have drained. It does not detect and batch the ordinary circulating
steady state. The laboratory documentation says the Stage 2 fixtures used
zero quiescent cycles. Calling that reference solver for every live person
would not satisfy the requested two-millisecond budget. The standalone
`tools/bench_qi_reference.gd` measures fifty reference sessions at the Palace
and checks integer conservation, without changing the world.

Remaining acceptance work includes a bounded session compiler checked against
both Stage 2 anatomies; recorded fill/draw, distribution, mixed-source,
simultaneous-branch and release evidence; all nine dated certifications;
daily field allocation and unused-reservation settlement; personality-driven
route experiments; injury/death and chronicle wiring; removal of the old
random ladder and its Foundation Establishment test expectation; complete
world daily/jump equivalence; text in the existing person book; and the
three-year Palace-versus-elsewhere and before/after performance measurements.
No rulebook laws have been changed to bypass these requirements.

## Measurements, 14 November 2026

The full serial phase-2 invocation passed its 36 existing checks. The newly
added anatomy test was created after that invocation captured its file list;
it passed in a separate invocation of the same runner. Packed column payload
for 250 prepared bodies measured 1,383,000 bytes (about 1.32 MiB).

The exact eight-node reference took 1,507.431 ms for fifty Route A sessions
and 1,986.358 ms for fifty Route B sessions at the Palace. Integer energy
residuals were zero and neither run used a quiescent cycle. These are costs
of the existing reference, not a production-stepper benchmark. They do not
meet the requested 2 ms budget.

`tools/bench_cultivation_world.gd` ran the current world for three years with
lifespan death enabled. At years one, two and three, both Palace and elsewhere
had zero people with completed tempering and an awakened root. Every Qi
Condensation layer count was consequently zero; recorded legacy cultivation
injuries and production cultivation deaths were also zero. This empty cohort
does not establish progression reachability or cultivation safety. Cumulative
simulation costs at the three anniversaries were 25.437, 24.854 and 24.876
ms/day. No production-after measurement exists. Raw results are in
`out/cultivation_world_baseline.txt` and `out/qi_reference_bench.txt`.

## Stage 3a — PASS (15 November 2026)

The detached session compiler meets the requested fixed-route accuracy,
compilation and amortized execution bounds on Godot 4.7.2. `circulation.gd`
remains unchanged. No live-society integration, UI or commit was made.

The first attempt measured normal/B strain 0.292 and 503 recovery days against
0.092 and zero, and cost 395–530 µs/person-day including compilation. Small
residue/pressure errors were amplified by the recovery recurrence: once daily
strain exceeds the 0.10 nightly healing amount, it accumulates across days.
The replacement preserves simultaneous lane allocation and integer operation
rounding in a scalar periodic kernel, records actual peak rates, integrates
quadratic residue exposure across each load ramp, and subdivides time near
recovery thresholds. Split's coordination demand remains part of the gate;
Merge retains the reference's no-transfer semantics. There are no route-specific
strain clamps or fitted fixture multipliers.

Each body owns a transient last-day memo, excluded from reference serialization
and state hashes. It caches absorbed/refined energy, all edge flows, opening,
storage and edge work, lodged/net residue, reserve, dissipation, grounding,
strain/health changes, recovery and settling. Purged residue is derived exactly
as lodged residue minus net residue change. Integer deltas conserve energy on
every replay. Floating reserve quality and fractional remainders retain the
solved outgoing values, avoiding unbounded additive drift.

The compact signature covers the compiled route and complete source/decree
sample, body revision, intake budget, reserve/residue pressure buckets, strain,
reserve purity/stability, purge multiplier and opening phase. Hysteretic bucket
widths are 1% of capacity for reserve and 0.1% for residue. Injury and 0.05
adaptation thresholds revise automatically; anatomical capacity edits use
`set_edge_capacity`, and other external anatomical edits call `invalidate`.
Storage growth is continuous bookkeeping represented in the pressure buckets.
Signature changes, opening/inventory/adaptation boundaries and unhealthy states
force solves; a solve occurs at least every 30 days. Compiled networks are
cached by program/source, anatomical coefficients and revision.

The comparison below is **compiled / exact reference** after 1,095 days.
Energy values are thousands of integer quanta. Usable/work/refined errors are
below 5%; residue errors are below 10%; all retention, strain and recovery
bounds pass, including normal/B's zero recovery days.

| Fixture | Usable | Work | Refined | Residue | Retention day | Maximum strain | Recovery days |
|---|---:|---:|---:|---:|---:|---:|---:|
| normal/A | 681.957 / 673.753 | 681.373 / 673.194 | 705.697 / 696.924 | 1.950 / 1.819 | 775 / 774 | 0.01116 / 0.01087 | 0 / 0 |
| normal/B | 747.683 / 778.760 | 747.066 / 778.067 | 820.729 / 849.265 | 6.179 / 5.959 | 703 / 674 | 0.09836 / 0.09247 | 0 / 0 |
| reversed/A | 993.173 / 983.659 | 992.305 / 982.786 | 1027.767 / 1017.355 | 3.046 / 2.863 | 514 / 511 | 0.02447 / 0.02385 | 0 / 0 |
| reversed/B | 725.219 / 751.335 | 724.486 / 750.643 | 801.678 / 827.679 | 6.770 / 6.743 | 805 / 740 | 0.37186 / 0.31066 | 695 / 627 |

The Palace benchmark uses 50 distinct seeded 16-node bodies × 1,095 days per
route. Compilation below includes initial body adaptation/setup **and lazy
coefficient construction**. Amortized cost is initial setup plus timed execution;
timed execution includes coefficient construction and all cache refreshes.
No warmup is excluded. Every body's integer residual is zero, and an independent
16-node daily/jump replay matches exactly.

| Route | Amortized µs/person-day | Execution µs/person-day | Last-day reuse | Compile ms/body, mean | Compile ms/body, maximum |
|---|---:|---:|---:|---:|---:|
| A | 27.416 | 26.851 | 87.34% | 2.269 | 3.205 |
| B | 38.676 | 37.978 | 85.61% | 6.118 | 7.638 |

Verification passed: `test_session_compiler`, `bench_session_compiler`, and
`python3 tools/run_phase2_checks.py` (**38/38 checks**). Godot processes
ran serially. Tests include four fresh exact comparisons, route reversal,
daily conservation and daily/jump equality, charged grounding safety, bounded
refresh, source/decree invalidation, capacity revision, held-network versus cold
compilation, and injured-state reuse rejection. The session test is included
once by the runner's default glob, with its longer exact-comparison timeout.

Files changed: `src/session_compiler.gd`, `src/meridians.gd`,
`tools/test_session_compiler.gd`, `tools/bench_session_compiler.gd`,
`tools/run_phase2_checks.py`, and this document. Raw evidence:
`out/session_compiler_comparison.txt`, `out/session_compiler_bench.txt`,
`out/phase2_suite.txt`, and `out/phase2/tests.json`.

No requested Stage 3a acceptance item remains unfinished. This is a detached
approximate executor; packed-store writeback, autonomous-policy comparison and
broader precharged 16-node validation remain Stage 3b work before production
integration.

## Stage 3b — functional integration PASS (15 November 2026)

The requested integration and checks are implemented. This is **not** a claim
that live execution meets the detached compiler's performance budget, or that
normal starting bodies have demonstrated layers 2 and 3. Those limitations are
quantified below. Layers 4–9 remain Stage 3c.

### Live execution

`Society.begin_tick` delegates crossed field dates to `qi_practice.gd`. A completed
nine-layer Body Tempering foundation and an awakened/revealed root automatically
prepare a meridian row once and begin practice. No initial qi or certifications
are granted. Starting programs come from the lab's operation-vocabulary data,
with the production topology adapter and the names/default assignments in
`data/cultivation/practice.json`: Still Basin normally, Returning River for Palace
members. Fear, ambition and pride determine initial filtering; curiosity,
restlessness, fear, ambition and pride feed the lab's mutation step, accepted
strain and copied-state scoring. The starting route is held for 90 days, then
selection occurs every 90 days relative to a saved personal policy date.

Requests use authoritative population positions, not the legacy `site` density
multiplier or rendered walkers. A detached compiler prediction bounds each
request by feasible intake and downstream/storage headroom. The field shares
requests by its existing priority/elemental allocation rules. A fully allocated
prediction commits directly; otherwise the opening body is executed with its
actual allocation. Unused reservations return once, reducing net withdrawals.
Every body asserts an integer energy residual of zero. The fixture also checks
that daily net field withdrawals equal the sum of actual body intake.

Travel withdraws no ambient qi until an authoritative arrival location exists,
but stored qi still pays daily integration, leakage, purge and deviation exposure.
Bodies use the actual compiler strain/integrity path. Injuries extend Society's
existing recovery date; structural damage remains in the body, rather than being
converted into an additional permanent abstract damage penalty. Death goes
through `Society.die`, including Fifty and family handling. Certifications,
deviation injuries and death by qi deviation all use `Society.note`.

### Certifications and compatibility

All certification evaluators require the foundation/root qualification, stable
execution, no new injury, and relevant integrity at least 0.85. Layer 1 checks
100 QU capacity, 500 QU paid opening work, 30 settling days, actual retention,
and the 0.10 residue wall. Layer 2 counts days whose minimum recorded flow on
the complete inlet–abdominal–lower–abdominal–lumbar–chest–breath circuit meets
30 QU/hour over the four-hour session; unrelated edge flows are never summed.
The production programs explicitly include the lower return operations.

**Documented layer-3 simplification:** the compiler records actual stored fill,
funded reserve-integration draw, and pre-draw pressure/purity/instability. One
session counts as one controlled fill–draw cycle when fill covers a positive
draw, stored pressure is at least 1.5, purity is at least 0.75 and instability is
at most 0.10, with valid execution. Ten such records certify the layer. A purity
check or volume-work total alone never certifies it. This uses integration as
the controlled draw; it does not implement a separate discharge assay. Layers
4–9 have no evaluator and receive no automatic credit. Achievement dates persist
in the packed store.

`cultivate(person, days)` is now an inert compatibility entry point: weekly mind
calls cannot grant several days of qi or roll breakthroughs. The abstract
`qi_rate`/`qi_cost` formulas and thirteen-layer exception are removed. Foundation
Establishment and higher receive no random advancement. The old manual-driven
Foundation test now explicitly expects that inert behavior. Existing realm text
reads the certified layer; the person book shows the retained route and physical
reserve/residue using its existing controls.

Packed inspection state is written back after sessions. Explicit save hooks save
physical bodies, arithmetic remainders, programs and certification/policy evidence;
compiler networks, periodic tables and last-day memos are rebuilt, never serialized.
The current implementation retains transient object bodies and saves execution
dictionaries alongside the packed inspection columns; it is not a packed-only
executor. Older saves have no physical endowment or achievement inferred from
abstract qi/layers. Recursive restore also rebuilds seasonal task tables and law
sight caches; wall-clock mind profiling is excluded from persistence.

Daily and jump play now visit the same population dates and pre-food-production
midnight boundary. The existing law path finder rejects destinations outside its
village grid, which the actual Palace-position fixture exposed.

### Two-year six-person fixture

Each region has one careful and one greedy person, forced to completed tempering
and a revealed root. Dates below are absolute simulated days; “—” means not
certified by day 730. The fixture uses the ordinary generated anatomy and live
world services, not boosted channel coefficients.

| Location | Layer 1, careful / greedy | Layer 2 | Layer 3 |
|---|---:|---:|---:|
| Palace | 148 / 153 | — | — |
| Sect spring | — / — | — | — |
| Village | 682 / — | — | — |

The greedy/careful sect pair finished with **7,010 / 6,397 integer residue
quanta** and **0.809609 / 0.341569 peak strain**. An explicitly charged unsafe
fixture verifies compiler-produced injury/death and both chronicle entries; a
travelling charged body verifies funded upkeep without ambient intake.

Sealing the Heavenly Origin kept the careful Palace layer-1 day at **148**, but
reduced its two-year permanent work from **4,329,121 to 2,171,466 quanta**
(**49.8% less**). A node seal stops new emission; it does not erase the paid
world-formation ambient endowment. No rulebook decree law was changed to force
an immediate layer delay.

The actual running world, including economy and population, matches daily versus
jump execution over two years. Physical save/load equality, rebuilding body
objects without granting qi, and a seven-day cold-cache continuation also match
exactly. Missing old-save cultivation state loads without stale bodies.

### Full-world fifty-person measurements

The same encoded initial world is restored before each 730-day run. The existing
fifty Palace people are forced to completed Perfect tempering and revealed roots,
then placed 17/17/16 at Palace/sect/village field positions. Their Palace membership
and access to the Returning River starting program remain intact, making these
results distinct from the six-person fixture. Timed work is the full headless
economy/population simulation, including lazy preparation/compilation; scene
construction, save restoration and rendering waits are outside the timer.

| Run | ms per simulated day |
|---|---:|
| Without prepared cohort | 23.404 |
| With 50 prepared people | 262.135 |
| With 50, Heavenly Origin sealed | 255.465 |

| Region | Prepared / living at day 730 | Ever certified layer 1 | Layer-1 days, first–last | Layers 2 / 3 |
|---|---:|---:|---:|---:|
| Palace | 17 / 17 | 17 | 82–721 | 0 / 0 |
| Sect | 17 / 8 | 0 | — | 0 / 0 |
| Village | 16 / 16 | 0 | — | 0 / 0 |

For representative sect people 21 (greedy) and 24 (careful), residue is
**6,639 / 6,382 quanta**, and peak strain **0.788555 / 0.533378**. The nine sect
deaths emerge from the strain/integrity path. Under sealing, all Palace layer-1
dates remain unchanged, but total Palace permanent work drops from **69,804,868
to 25,591,409 quanta (63.3%)**. Sect work also changes through the running
society; the seal is not treated as a direct sect intake multiplier.

**Performance limitation:** the live cohort adds **238.731 ms/day**, far above
the earlier two-millisecond cultivation target. The live prediction/writeback
path and changing body/source signatures do not retain the detached benchmark's
memoized amortization. Functional checks passing must not be read as production
performance acceptance. Further live cache/coordinator optimization is needed.
Normal-cohort layer-2/3 reachability is also **not established** by these runs;
no substitute certifications were manufactured to conceal that result.

### Verification and changed files

`python3 tools/run_phase2_checks.py`: **38/38 PASS**, serially. After the final
starting-policy/travel adjustments, affected reruns also passed:
`test_cultivation`, `test_family`, `test_qi_condensation`, and `bench_qi_live`.
`git diff --check` passes. No commit was made, and no new UI screen was added.

Files changed:

- `src/qi_practice.gd`: live coordinator, policy, evidence, writeback and save hooks.
- `data/cultivation/practice.json`: route names and starting assignments.
- `src/session_compiler.gd`: recorded fill/draw evidence and production return path.
- `src/qi_field.gd`: one-time unused reservation settlement.
- `src/society.gd`: qualification/practice integration, certified labels, ladder removal.
- `src/population.gd`, `src/village_life.gd`: authoritative daily jump boundaries.
- `src/world_save.gd`: physical persistence, old-save projection and cache repair.
- `src/person_book.gd`: actual route, layer and stored qi text.
- `src/law.gd`: out-of-grid path rejection for actual Palace positions.
- `tools/qi_cohort_fixture.gd`, `tools/test_qi_condensation.gd`: prepared live cohorts,
  conservation, safety, travel upkeep, old saves, round trips, decrees and world replay.
- `tools/test_cultivation.gd`: inert legacy-path expectations.
- `tools/bench_qi_live.gd`: complete cohort counts/dates and full-world timings.
- `tools/run_phase2_checks.py`: serial long-running-fixture timeouts/comments.
- `docs/qi_condensation.md`: status and evidence.

Raw final evidence: `out/phase2/tests.json`, `out/phase2/selected_tests.json`,
`out/phase2/test_qi_condensation.gd.log`, `out/phase2/test_session_compiler.gd.log`,
and `out/phase2/bench_qi_live.gd.log`. The earlier exploratory benchmark is saved
separately in `out/qi_live_exploratory.txt` and is not acceptance evidence.
