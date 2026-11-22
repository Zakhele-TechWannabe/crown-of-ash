# Qi Condensation implementation status

Stage 3c evaluators, live drills, release assays and person-book readout are
implemented. **Stage 3 acceptance remains incomplete**: the ten-year Perfect
Palace fixture fails to reach layers 2–3; successors are blocked upstream.
See the Stage 3c section for measured reachability, verification and timings.
Earlier status sections below are historical.

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

## Stage 3b performance investigation — 15 November 2026 (in progress)

Baseline instrumentation was added before changing execution: coordinator timers
separate detached prediction (including cloning), request submission, field advance/
allocation, allocation-mismatch execution, packed writeback, and certification/
notes. Compiler counters separately measure signature construction, lazy periodic
coefficient construction, network misses and day-memo misses. Compiler timings
are nested within coordinator timings and must not be added twice. The same
730-day full-world benchmark is running serially; results will be recorded here
before optimization. Inspection found exact sample `day`, `quantity`, `elements`
and body adaptation in JSON network keys; cloned predictions have no DayMemo.

### Measured pre-optimization profile (recorded before optimization)

Instrumented baseline: **23.776 ms/day**; 50-person cohort: **263.601 ms/day**;
added cost **239.825 ms/day**. Timers over 730 days (ms/day):

| Phase | ms/day |
|---|---:|
| Detached prediction, cloning and solve | 203.665 |
| Field request submission | 0.641 |
| Field advance/allocation (includes baseline field work) | 8.030 |
| Recompute after allocation mismatch | 0.000 |
| Packed writeback | 7.538 |
| Certifications and chronicle notes | 0.504 |
| Other full-world work, policy trials, sampling and preparation | 43.223 |

Nested compiler costs: signature construction **12.319 ms/day**; periodic
coefficient construction **154.963 ms/day**. There were **32,797 day misses,
zero day hits**, and **32,219 network misses / 578 hits (1.76% hits)**.
No allocation-mismatch recomputation occurred in this workload: the principal
problem is the cold cloned prediction and coefficient rebuilding, rather than
an observed second solve. The pre-change cohort still has Palace layer-1 dates
82–721, 17 certifications, nine sect deaths, and no layers 2/3. Raw evidence:
`out/qi_live_profile_before.txt` (captured after the open cohort).

### First structural pass (measurement pending)

Removed detached prediction from the live coordinator: expected intake is a
saved packed `expected_intake` column, with a 2% request allowance; actual grants
fund one scalar solve. No approximate integer delta is scaled across a nonlinear
pressure or injury boundary. Networks use canonical 1% density, 0.005 quality,
0.05 adaptation and 0.01 integrity/scar buckets, excluding sample dates, quantity
and metadata. Canonical values also build the coefficients, making cold-cache
continuation independent of the cache's history. Daily pressure/residue and
health are still solved every day (a stronger refresh bound than 30 days).

Co-located people share one field sample. Individual elemental requests remain
in the field's existing per-cell batch allocator to preserve priority and stable
remainder ties; replacing them by one aggregate consumer would change those
rules. Request dictionaries are reused, allocation ranking uses arrays, refunds
close the ledger once per batch, and writeback directly addresses packed columns
with a fixed production-node mapping. These are implementation notes, not yet a
performance or accuracy acceptance claim.

First-pass measurement: baseline **23.762**, cohort **49.468**, added
**25.706 ms/day**. Network hits **32,125 / 33,177 = 96.83%**. Daily solves remain
31,472, with no day replays. Coordinator solve/compile 11.546 ms/day, requests
0.458, field 7.664, direct packed writeback 3.036, certification/notes 0.495;
nested signature construction 1.945 and total coefficients (including policy
trials) 5.487 ms/day. This is a useful reduction but **fails the 5 ms target**.
Palace layer-1 dates shift from 82–721 to 81–721, still 17 certifications;
nine sect deaths and no layers 2/3 remain. Further work is in progress.

The expanded first-pass profile isolates policy at **6.007 ms/day**, preparation/
sampling at **0.712**, and settlement/conservation at **1.332**. Policy was
running `mind.urges` before its 90-day due-date guard. The next pass moves that
guard first, mutates packed columns inside their owning store, reuses held
canonical networks until source/revision changes, and restores bounded day
replay. Replay arithmetic is now saved as execution state; periodic tables remain
transient. This is required for exact warm/cold continuation once live replay
is enabled. Canonical lower-dantian kernel volume is fixed at initial capacity,
with actual daily storage pressure handled by the existing interpolation.

An exploratory 16-cycle production kernel failed its coefficient accuracy gate;
it was **not** adopted. A 32-cycle candidate is being checked against the original
48-cycle kernel. No laboratory kernel relaxation has been changed.

The 32-cycle candidate also failed the coefficient gate, so the production
kernel retains its original 48 cycles. The exploratory test was removed; no
shorter-kernel optimization is part of the final implementation.

### Stage 3b follow-up — diagnosis in progress

The committed policy guard, owning-store packed mutation, held canonical networks
and bounded replay are already present in `51e0ab3`; they are not pending edits.
Inspection of the executed danger path finds only dantian overpressure and lodged
residue exposure in `session_compiler`: regulated network transfers cap flows,
and the compiler does not feed elemental interference into its storage hazard.
Thus Wood composition cannot explain these deaths in the current executor.
Numerical day-level exposure tracing is being added to the live benchmark before
any change to the physical laws. No law or difficulty parameter has been changed.

Measured committed-state rerun: baseline **24.027 ms/day**, cohort **42.815**
(**+18.788**), sealed **89.743** (**+65.716**). The sealed run has **10,026
network misses** versus **1,053** normally; nested coefficient construction is
**48.141 ms/day** sealed versus **5.594** normal. Allocation-mismatch time is
zero. Sealing changes the source trajectory, repeatedly invalidating density/
quality-keyed periodic tables; this is not an allocator second solve.
Raw profile: `out/qi_followup_profile_before.txt`.

This rerun's committed-state outcomes are eight sect deaths (nine survivors),
careful person 24 peak strain **0.495818**, greedy person 21 **0.785138**;
Palace 17/17 certifications, dates 81–721 (sealed 82–721), village 16/16 living.
These differ from the owner's nine deaths / 0.53 peak, so before/after evidence
will use the locally reproduced fixture and will not silently claim identity
with the owner's earlier run.

### Sect death diagnosis — completed before performance edits

Trace at each representative's peak-strain day (strain increments, before the
fixed 0.10 daily recovery):

| Person | Day | Opening strain | Residue, 4h session | Residue, 20h rest | Overpressure | Peak strain |
|---|---:|---:|---:|---:|---:|---:|
| 21, greedy sect | 75 | 0.678196259 | 0.017803600 | 0.089137952 | 0 | 0.785137811 |
| 24, careful sect | 172 | 0.395710004 | 0.016670702 | 0.083437362 | 0 | 0.495818067 |
| 22, careful village | 685 | 0 | 0.008444304 | 0.042651848 | 0 | 0.051096152 |

All have capacity 100,000. Residue just before purge: **6,676 / 6,459 /
4,618** quanta respectively. Overload, corruption×exposure, instability beyond
0.20, and forced-commitment terms contribute **zero** in this executed path:
periodic transfers are capped, corruption is zero, sampled stability is 1.0,
and the program is regulated. The production compiler currently transports
scalar quality rather than explicit elemental interference; Wood 60% therefore
cannot be the cause of these deaths. This is a limitation of that approximation,
not evidence that elemental interference was measured and found harmless.

Both sect representatives are at **(1415, 2250), cell 50488**, correctly sampling
**Sect spring**, Established, density **5.28294 / 5.29196**, purity **0.75**,
stability **1**, corruption **0**, and ~60% Wood. Village person 22 samples cell
56247 at density **2.20167**, purity **0.90**, stability **1**, corruption **0**.
All are still Palace members and start route **B / Returning River**; region
placement does not assign sect membership or route A. Careful sect policy picks
filter 0.25 at its 90-day review, and remains there. The greedy person dies before
that first review. There is no location sampling bug or allocation mismatch.

The spring supplies enough impure work expenditure to maintain residue near the
recovery balance **sqrt(0.10/24) = 6.45497% of capacity**. Above that balance,
small daily excesses accumulate strain; above strain 0.50 integrity erodes.
Stopping intake does not remove existing lodged residue. The village load stays
below the balance and fully recovers each day. The careful sect person remains
just below damaging strain in this local rerun; greedy person 21 exhausts
integrity. **These deaths follow the existing residue/recovery law; no law or
difficulty changes were made.** Raw trace: `out/qi_followup_diagnosis.txt`.

Diagnostic rerun physical totals exactly match the timed cohort (including eight
sect deaths). Palace certification dates vary between separately constructed
worlds, despite equal cultivation work; these also depend on society health and
injury eligibility. Do not compare different-world dates as a compiler-only
accuracy measurement.

### Moving-source coefficient reuse (under verification)

The next implementation keeps canonical 1% source identity and body revisions,
but shares fluid-response tables across source qualities and neighbouring density
bands. Source purity/stability/corruption have affine responses because packet
transport and filter losses do not depend on those moments. Basis moments
(purity 0, stability 0, corruption 1) reconstruct actual qualities. Density
interpolation uses a fixed 10% geometric grid; the original 48-cycle kernel
builds every endpoint. Tables remain transient and bounded. This is a compiler
approximation, not a change to the physical laws, and requires both direct
coefficient checks and the full three-year accuracy gate.

Policy candidates now skip exact duplicates and use a direct anatomy clone for
the lumped solver. Packed writeback skips unchanged packet columns on this path;
the generic full-writeback API remains available. Strained storage never allowed
replay already; it now bypasses construction of unusable replay journals while
preserving adaptation/integrity revision boundaries. Verification pending.

The first 10% interpolation candidate passed `test_session_compiler.gd`, including
all four three-year reference comparisons, but the additional moving-source
coefficient sweep found **5.83% admission error** at density 15. It is rejected
as an acceptance candidate. The grid is narrowed to **5%** for the next pass.
The new sweep checks main coefficients within 5%; negligible side flows use an
absolute 0.00025 qu/cycle floor rather than unstable relative error at zero.

The 5% grid passes the moving-source sweep (**2.6636%** worst normalized error).
Its intermediate full-world measurement is baseline **23.931**, cohort **40.847**
(**+16.916**), sealed **56.182 ms/day** (**+32.251**). Sealed coefficient cost is
**16.457 ms/day**, down from **48.141**, but this still fails the 5 ms/day target.
Raw intermediate evidence: `out/qi_followup_grid5.txt`. This is before the final
policy rejection guard and local kernel geometry bindings, so is not final.

A conservative policy guard now proves when all trials must fail: lodged residue
cannot purge before today's exposure, storage can grow by at most the funded
0.5% daily ceiling, and all other danger terms are nonnegative. Therefore
`opening_dantian_strain + 24*(opening_residue / maximum_today_capacity)^2`
is a lower bound on every candidate's peak strain. When it already exceeds the
person's accepted strain, skip trials but record the same retained choice/review
date. A test checks this lower bound against both routes and three filters, as
well as trial clone isolation/conservation. No physical execution is skipped.
The kernel also binds read-only geometry arrays once outside its inner slices;
its cycle count and arithmetic are unchanged.

Operational note: a duplicate diagnostic benchmark was briefly launched while
an earlier benchmark still ran, then immediately interrupted. Subsequent Godot
runs are serial. This was a process-overlap mistake, not an accepted workflow.

For completeness, the reference interference function also gives **~0.040** for
the observed 60/10/10/10/10 mixture (`0.40 * largest opposing minimum / total`),
below the danger formula's **0.20** threshold even before Stabilise. Thus the
sample's Wood share does not hide a positive instability term in this diagnosis.

Source snapshots in the diagnostic log are sampled after that day's field
settlement; the solve uses the preceding field sample with canonical density/
quality buckets. The reported strain contributions are instrumented inside the
actual solve, not inferred from that post-settlement snapshot. Cell/source,
purity 0.75/0.90, stability 1 and corruption 0 are unchanged across this boundary.

### Full-suite regression and correction

The full suite exposed a regression in `test_qi_condensation.gd`: the six-person
fixture's greedy sect residue became 6,533 versus careful 6,669, violating its
existing ordering check (strain ordering still held). The direct coefficient
and three-year aggregate gates did not detect this nonlinear threshold effect.
The assertion is retained. At canonical density <=8 (source pressure <=1), the
compiler now uses the original exact-density kernel and shares only its affine
quality response; interpolation remains restricted to higher densities. This
sacrifices some speed to preserve low-density integer-flow/residue behaviour.
Verification and final timing are pending this correction.

After the low-density correction, the full three-year `test_session_compiler.gd`
passes all four reference comparisons, including strain/recovery/retention and
warm/cold integer replay. The moving-source/clone/rejection-bound check also
passes. Reversed-B canonical peak strain is **0.373488**, versus reference
**0.310664**, within the existing 25% gate; no gate was loosened. Main work,
usable/refined qi and residue checks retain their original 5%/10% tolerances.

The first low-density corrective rerun still failed the six-person ordering.
A direct committed/current executor comparison isolated the remaining cause:
the journal shortcut incorrectly assumed opening strain forbids the following
day's replay. A person can recover to zero *today*, leaving a valid journal for
tomorrow. Discarding that journal changed the bounded approximation trajectory.
The shortcut is now limited to `injuries > 0`, which permanently forbade replay
already. A transient-strain journal regression check is added.

With this correction, the independent six-person comparison matches committed
execution exactly at printed precision: greedy **6,533 residue / 0.761116 peak
strain**, careful **5,661 / 0.339680**. Raw comparisons:
`out/qi_bisect_committed.txt`, `out/qi_bisect_journal.txt`. Temporary baseline
scripts were removed. All physical laws and existing assertions remain intact.

Final corrective checks pass: `test_qi_condensation.gd` (including two-year full
running-world daily/jump, physical save/load, cold continuation and conservation),
`test_session_compiler.gd`, and `test_session_sources.gd` (including the transient
strain journal regression). Latest status is **39/39 PASS**: the full suite had
38 passes and the one ordering failure, then that failing test and both compiler
checks were rerun successfully after correction. No existing assertion was
weakened. The first full-run results are preserved separately in
`out/phase2/qi_followup_first_suite.json`; latest per-test results and rerun
provenance are in `out/phase2/qi_followup_final_checks.json`. Final live benchmark
is running serially after these checks.

### Final follow-up result — correctness PASS, performance FAIL

| Run | Local before, ms/day | Final, ms/day | Final added over baseline |
|---|---:|---:|---:|
| Baseline | 24.027 | 23.410 | — |
| 50-person cohort | 42.815 | 38.445 | **15.035** |
| Cohort, Heavenly Origin sealed | 89.743 | 63.909 | **40.499** |

Added cost before was **18.788 / 65.716 ms/day** locally; the owner's before
measurement was **17.9 / 65.6**. Both final cases **FAIL the <=5 ms/day target**.
The sealed pathology is reduced, not fully resolved. Canonical network misses
remain **1,036 normal / 9,903 sealed**. Nested coefficient time is **4.185 /
24.205 ms/day** (sealed previously 48.141). There are no allocation-mismatch
re-solves. Daily replay hits/misses are **24,160 / 7,513** normal and **14,985 /
15,675** sealed. Remaining moving-source coefficients and policy trial work need
further optimization; this pass must not be described as performance acceptance.

Coordinator phases, ms/day (coefficient/signature timings are nested):

| Phase | Normal | Sealed |
|---|---:|---:|
| Execution/compilation | 6.464 | 30.481 |
| Policy | 3.025 | 4.251 |
| Packed writeback | 1.301 | 1.243 |
| Settlement/conservation | 1.270 | 1.290 |

**Outcome comparison:** normal regional permanent work totals match the local
committed benchmark exactly: Palace **69,886,059**, sect **4,337,305**, village
**5,113,404**. Sealed sect/village work also match exactly; sealed Palace work is
**25,344,606**, versus **25,344,804** before (198 quanta less, **0.000781%**).
All regional survival/certification counts and first/last certification dates
match the local before-run in both modes: Palace **17/17 living and layer 1**,
normal dates **81–721**, sealed **82–721**; sect **9/17 living**, no certifications;
village **16/16 living**, no certifications. Thus there remain **eight local sect
deaths**, already present before this follow-up, versus nine in the owner's
measurement. No layer 2/3 certifications were obtained. No difficulty law changed.

Verification: **39/39 latest checks PASS**, including all 38 original checks and
the new source/journal/clone/bound check, after the documented corrective reruns.
`tools/bench_qi_live.gd` completes successfully; its timing target still fails.
`git diff --check` passes. No commit was made. Final raw benchmark:
`out/qi_followup_final.txt`; complete check/rerun provenance:
`out/phase2/qi_followup_final_checks.json` (the initial failed full-run record is
preserved, not overwritten with a fabricated passing run).

Final changed files:

- `src/session_compiler.gd`: shared affine-quality fluid kernels, bounded high-density
  interpolation, exact low-density coefficients, direct policy-body cloning,
  safe injury-only journal shortcut, local geometry/opcode dispatch, diagnostic trace.
- `src/qi_practice.gd`: duplicate trial elimination, proven rejection bound,
  specialized clone and unchanged-packet writeback path.
- `src/meridian_store.gd`: optional unchanged-packet writeback fast path.
- `src/qi_field.gd`: full-consumption refund shortcut, zero-return/duplicate-cell work removal.
- `tools/bench_qi_live.gd`: opt-in per-person danger tracing and cohort-only diagnosis.
- `tools/test_session_sources.gd`: moving-source coefficient accuracy, policy clone
  isolation, rejection-bound conservation and transient-strain journal regression.
- `docs/qi_condensation.md`: diagnosis, rejected candidates, corrections and final evidence.

Unfinished: the **<=5 ms/day added** performance requirement in both modes.

## Danger sense — owner decision 15 November 2026 (implementation in progress)

Daily personal observations now precede allocation: lodged residue fraction,
change in recovered dantian strain, and injuries since the last observation.
Keyed person/day perception noise consumes no world RNG. The inherited fear,
ambition, pride, curiosity and restlessness urges, plus the diligent trait,
choose caution or ignoring the warning. No future source or physical trial is
used by danger sense. Careful people pause 7–14 days, retain strong filtering,
shorten subsequent sessions to a quarter or half, and record a wish for purer qi.
They inspect four cells within 24 world units of their current site; a strictly
purer cell can change the practice position without relocating the person.
Decisions retain day, reason and observed signals; aggregate response counters
persist, recent explanations are bounded to 16, and notes are at least 90 days
apart. Existing danger, residue purge and recovery laws remain unchanged.

Acceptance added for the actual 50 Palace-member fixture over 730 days: careful
sect deaths <=1 of eight (>=87.5% survive), total sect deaths <8, Palace/village
survival 17/17 and 16/16, all 17 Palace layer-1 certifications by day 730
(baseline latest 721, allowance nine days), and both caution and ignoring observed.
These thresholds are stated before final measurement. The existing six-person
ordering, conservation, daily/jump and cold-save checks remain in place.

Performance work so far skips fluid coefficient construction when funded intake
is zero, while still executing all session/rest exposure and reserve upkeep.
A danger-driven retained recovery policy also suppresses conflicting 90-day route
experiments. Full accuracy, suite and timing results follow below when available.

First exploratory benchmark (before the final decision refinement/reachability
check) completed: baseline 20.255, cohort 33.371, sealed 55.469 ms/day. It kept
all eight careful sect people alive, with unchanged Palace/village survival and
Palace dates, but all nine greedy sect people died. Total deaths therefore rose
from eight to nine through the changed shared-field trajectory. That candidate
is not claimed as acceptance. Greedy people now retain a small keyed chance to
heed a warning, influenced by curiosity/restlessness, rather than invariably
ignoring it. Final measurement must establish the resulting deaths and cost.
The local-spot selector now requires an actual available walking path; where
there is no navigation context it records the desire without assuming reachability.

Shortened sessions now scale the actual number of paid route cycles and the
session exposure duration; all remaining hours still expose lodged residue.
Local practice offsets expire when the person's authoritative location changes.
Compiler-key dictionaries are replaced before policy edits rather than mutated
in place. The periodic kernel also skips zero-quantity moment updates after
preserving the transfer remainder; cycle count, nonzero arithmetic and source
quantization remain unchanged. The benchmark includes an `unaware` control from
the identical initial world, overriding danger behaviour only, to measure the
historical personality death split directly. The suite additionally checks the
sealed 50-person cohort against the same survival/certification thresholds.

Verification is running serially via the requested full phase-2 command. Early
body/childhood/clan/combat/continuous/cultivation/lab/faction checks pass; the
century-long family check is still running at this point. No second Godot
process has been launched alongside it. Final results below supersede this
progress note; no performance acceptance is inferred from partial checks.

The full-suite qi test exposed a missing-context error in local-spot search:
standalone Population fixtures have no law/navigation service. The search now
checks the service as well as its grid, retaining `wants_purer_qi` without
inventing reachability. The suite continues serially; qi will be rerun after it.

The requested complete serial invocation finished with **38/39 PASS**; its only
failure is the missing-navigation-service qi error described above (fixed).
All four three-year compiler comparisons and `test_session_sources` passed with
unchanged accuracy tolerances. The initial full-run JSON is preserved in
`out/phase2/danger_first_full_suite.json`; the qi failure log is preserved in
`out/danger_navigation_failure.txt`. The corrected complete qi test is rerunning
serially before the final benchmark. Do not read the partial result as all-pass.

The corrected qi rerun exposed an obsolete autonomous-policy assumption, rather
than a physical accuracy failure: the six-person greedy sect person now eventually
heeds danger and ends with **1,206 residue / 0.278371 peak strain**, versus the
careful person's **1,906 / 0.061133**. Final residue ordering can legitimately
reverse after late caution. That assertion is replaced with stronger relevant
behaviour checks: greedy peak strain exceeds careful, careful peak stays <0.20,
the greedy pause is recorded, and both ending residue fractions are <0.045.
No compiler/reference tolerance is changed. The failed assertion and values are
preserved in `out/danger_old_ordering_failure.txt`.

A subsequent world-loading attempt was blocked by concurrent unrelated edits:
`ground_view.gd` began loading a new `daos_eye.gd`, whose inferred `left` and
`key` variables fail parsing (lines 214/235 at the time of inspection). Those
files and `data/laws.json` were not changed by this task. To continue without
reverting another task's work, `/tmp/crown-danger-verification` snapshots this
task's sources/resources and restores only `ground_view.gd` from HEAD. Corrected
qi and final benchmark evidence from that snapshot is explicitly isolated;
it does not certify integration with the concurrent unfinished UI changes.

### Corrected qi verification — PASS in isolated snapshot

The complete qi test passes, including keyed/cold-save danger decisions with no
shared RNG consumption, six-person physics/conservation and cold continuation,
50-person two-year daily/jump equality, and both normal/sealed acceptance gates.
Normal: **0 careful / 5 greedy sect deaths**, Palace **17/17 living and certified**,
village **16/16 living**; **13 pauses/filter increases/shortened sessions/purer-qi
wishes** and **39 ignored warnings**. Sealed: the same survival/certification
counts, **12 cautious responses** and **8 ignored warnings**. No reachable purer
spot was selected in this fixture's navigation context. Certification dates vary
between separately constructed worlds; final benchmark uses one saved initial
world for control/normal/sealed comparison. Raw corrected test:
`out/danger_qi_final.txt`; result: `out/phase2/danger_qi_isolated_final.json`.
Thus all 39 checks have passing affected/latest evidence, with the full-invocation
failure and isolated-rerun limitation preserved above. This is not a clean full
39/39 rerun against the concurrently edited UI.

The first control-inclusive benchmark is rejected: `WorldSave.restore` assigns
supplied dictionaries, so repeated restoration from the same mutable snapshot
allowed an earlier mode to alter later modes' Fifty/person context. The added
unaware control made this visible (dead-before-qualification reports). Benchmark
and world-cohort fixtures now deep-copy each input snapshot per restoration,
including economy, outside timing. Production save semantics are unchanged.
The contaminated log is retained in `out/danger_rejected_aliased_bench.txt`;
its 8/8 death comparison and timings are not final evidence. Both affected qi
and benchmark fixtures are being rerun with independent snapshot inputs.

The independent-snapshot qi rerun passes completely. Normal and sealed each
have **0 careful / 5 greedy sect deaths**, Palace **17/17 living and layer 1**,
village **16/16 living**, **13 pauses/filter increases/shortened sessions/purer
qi wishes**, **39 ignored warnings**, and no selected local spot. Latest Palace
certification is day **151 normal / 153 sealed** in this test world. The previous
sealed day 495 and 12/8 response counts above came from the aliased initial
snapshot and are superseded. `out/danger_qi_final.txt` now contains the corrected
independent-input run. Two-year full-world daily/jump equality still passes.

### Final independent-snapshot benchmark — behaviour PASS, performance FAIL

All modes now restore independent deep copies of the same saved initial world.
The unaware control disables danger behaviour only; it reproduces the owner's
baseline eight sect deaths. Normal and sealed danger-aware runs agree on the
personality split and response counts:

| Sect personality | Before | After normal | After sealed |
|---|---:|---:|---:|
| Careful (8 people) | 0 deaths | 0 deaths | 0 deaths |
| Greedy/proud (9 people) | 8 deaths | 5 deaths | 5 deaths |

Each aware run records **13 pauses, 13 stronger-filter decisions, 13 shortened
sessions, 13 purer-qi wishes, 39 ignored warnings, zero local-spot changes**.
Palace remains **17/17 living and certified**; village remains **16/16 living**.
Normal Palace layer-1 dates are **87–151 in both control and aware runs**;
sealed dates are **88–153**. Palace normal permanent work is unchanged at
**69,886,059**, village at **5,113,404**. Sect work changes from **4,337,305**
to **3,439,735** as safer people practise less and three more survive.
Sealed Palace work is **25,344,606**. No layer-2/3 certifications are granted.
The old day-721 latest date was an artefact of reused mutable fixture snapshots;
this correction changes measurement isolation, not certification law.

| Run | ms/day | Added over baseline |
|---|---:|---:|
| Baseline | 24.631 | — |
| Unaware control, same optimized physical executor | 41.373 | 16.742 |
| Danger-aware normal | 40.692 | **16.061** |
| Danger-aware sealed | 67.626 | **42.995** |

Both aware runs **FAIL the <=5 ms/day target**. No overall speed acceptance or
improvement over the owner's +15.0/+40.5 measurement is claimed: initial-world
isolation was corrected and more people now survive. The exact zero-transfer
shortcuts preserve the accuracy gates but do not remove the remaining bottleneck.
Normal/sealed nested coefficients cost **4.274 / 25.027 ms/day**, with **1,032 /
9,920 network misses**; policy costs **3.075 / 4.416 ms/day**. Moving-source fluid
coefficients and policy trials remain unfinished optimization work. Kernel cycles,
source precision and physical laws were not relaxed to manufacture a timing pass.

Verification: the complete requested serial invocation had **38/39 PASS**, with
the documented missing-navigation qi defect. Corrected qi (including all new
normal/sealed acceptance, conservation, save/cold continuation and two-year
50-person daily/jump checks) and the completed benchmark both pass in the isolated
snapshot. All **39 checks have latest passing evidence**, but there was **no clean
full-suite rerun against the concurrently edited UI**, which introduced unrelated
Dao's Eye parse errors. Both compiler tests passed their unchanged accuracy gates
in the full invocation. No Godot processes launched by this task overlapped.
`git diff --check` passes; no commit was made.

Final evidence: `out/danger_qi_final.txt`, `out/danger_bench_final.txt`, and
`out/phase2/danger_final_checks.json`. Source files in the snapshot match this
task's final workspace sources byte-for-byte; only concurrent ground-view UI
integration is excluded from that snapshot. Changed by this task:
`src/qi_practice.gd`, `src/session_compiler.gd`, `tools/qi_cohort_fixture.gd`,
`tools/test_qi_condensation.gd`, `tools/bench_qi_live.gd`, and both qi/laws documents.
Unfinished: <=5 ms/day performance and full verification with the concurrent UI.

## Stage 3c — implementation in progress (15 November 2026)

Certifications 4–9 now have recorded-execution evaluators in
`src/qi_certification.gd`; dates continue to use the meridian store's nine
achievement columns. Live drills append limb routes and concurrent split work
on keyed weekly dates after layer 3. Mixed-source declarations copy the actual
local elemental sample. The compiler measures simultaneous committed transfers,
not the sum of serial edge flows. Trials consume their executed practice date;
failed trials are recorded and add 0.005 strain without random rolls.

Reachability concern under investigation: Perfect storage has safe pressure
exactly 1.5, so a strict 1.5-pressure fill/draw test may remain unattainable under
ordinary admission/backpressure and paid daily draws. No threshold, anatomy seed,
conductivity or growth law is being adjusted to hide this.

Release is a paid 100-integer-quantum pulse through the actual lower-to-palm
route, available from certified layer 1; autonomous reliability drills start at
layer 7. The bounded transient uses existing pressure, conductance, capacity and
integer packet transfer. Controlled delivery uses purity squared, stability, execution quality and
`exp(-1 / (1 + 4 × release_mastery))` attenuation at one tile. The assay uses
the existing shared operation mastery (0.75) for Release mastery; it does not
grant a separate skill level. All spent qi enters `dissipated`, including the
controlled target delivery: a short projected pulse disperses as unusable energy,
not recoverable ambient field inventory. Leftover pulse energy also dissipates;
no field deposit or extra ambient emission is claimed. Layer 8 requires ten
successful recorded tests and no overpressure. This is a cultivation assay, not
a new combat engine.

First ten-year fixture result (two Perfect Palace people, ordinary coordinator,
initial A/B manuals): layer 1 on days **147 / 135**; layers 2–9 unachieved.
Maximum qualifying core rate **0 QU/hour** (at least one required return edge
never transfers), maximum recorded fill pressure **0.159544**, ending capacities
**1355.2 / 1177.5 QU**, reserve **7.4 / 6.4 QU**, purity **1.00**. Thus capacity
alone reaches realm-completion size but does not buy the missing circulation
capability. This does **not** establish plausible layer-2/3 reachability; it
records their physical bottleneck rather than tuning seed laws or granting dates.


Pre-change benchmark from a separate immutable copy of the initial workspace,
using independent saved initial worlds and `tools/bench_qi_live.gd`:

| Mode | Before, ms/day | After, ms/day | Difference |
|---|---:|---:|---:|
| Baseline | 30.107 | pending | pending |
| Unaware control | 49.583 | pending | pending |
| Normal cohort | 50.623 | pending | pending |
| Sealed cohort | 90.206 | pending | pending |

Raw baseline output: `/tmp/qi_3c_before_clean.txt` (to be copied into `out/`).
The full phase-2 suite is running serially. No Godot processes overlap.

“Unreached” is a result for this seeded fixture, not a proof that every legal
manual/anatomy fails. All-Perfect is the highest ordinary foundation grade;
there is no out-of-range grade, free reserve, widened edge or lowered threshold.
The two people retain the ordinary autonomous policy after their initial A/B
assignments. The current manuals and pressure/headroom law fail the return
circuit gate before any later certification can be attempted naturally. The
new evaluator boundary tests and explicitly charged release assay must not be
read as natural progression results. Layer 7 also retains the declared Split
control demand: the current shared control/understanding/mastery coefficients
produce error **0.1325**, above its **0.08** certification ceiling. Neither that
coefficient nor the threshold has been changed.

The release assay follows section 11's full projection loss, including stability
and coherence attenuation. Its bounded transient also executes section 10's
pulse corruption/instability/pressure exposure and commits resulting health;
ordinary safety stops at excessive strain. The daily kernel has already charged
24 hours of background residue exposure, so the extra transient adds pulse
exposure without charging those background hours twice. The actual route's
transferred integer quantities are recorded separately from four-hour circuit
flow, so a release cannot inflate sustained-output evidence.

The charged release boundary assay is **not a reachability success**. From a
full, pure, stable Perfect dantian it spends exactly 100 quanta; the five route
edges transfer **100 / 87 / 76 / 68 / 62** quanta during the bounded 100-minute
assay. Projection at one tile leaves **46 controlled quanta (46%)**, below the
70% certification requirement. With purity 0.50 it delivers **11** controlled
quanta. Both have zero overpressure and zero integer residual. This separately
exposes a layer-8 transport/coherence bottleneck for that seeded body, in
addition to the upstream layer-2 block. The protocol has not been lengthened,
and no conductance, mastery or certification threshold was tuned to turn this
failed assay into a pass.


### Stage 3c reachability, final functional fixture

The expanded Qi test passes, including the running-world two-year daily/jump
comparison, cold-cache continuation, save/load, failed-trial determinism and
purity/residue walls. Normal/sealed worlds retain 0 careful / 5 greedy sect
deaths and all 17 Palace and 16 village survivors. Raw functional evidence:
`out/qi_3c_checks.txt`. Run only the ten-year fixture with
`godot --headless --path . -s tools/test_qi_condensation.gd -- --long-only`.

| Layer | First fixture day reached, or recorded bottleneck by day 3650 |
|---|---|
| 1 | **135** (the other person: 147) |
| 2 | Unreached: qualifying core **0/30 QU/hour**; lower→abdominal, lumbar→chest and chest→breath each record zero transfer throughout the fixture (section 6 pressure/gate law, section 9 circuit test). |
| 3 | Unreached: upstream layer 2; peak pre-draw retained pressure **0.159544/1.5**. The fixed 50% daily reserve integration and existing inlet/manual throughput do not fill the safe reservoir to the condensation wall. |
| 4 | Unreached: layers 2–3 block entry; live terminal drills start at layer 3, so no natural four-terminal test records exist. |
| 5 | Unreached: upstream block; recorded core **0/90 QU/hour**, despite capacities eventually exceeding 400 QU. |
| 6 | Unreached: upstream layer 5; no layer-6 date is inferred from pure reserve or processing totals alone. |
| 7 | Unreached: upstream block; the current Split instruction's error **0.1325** also exceeds **0.08** (shared mastery/control plus the declared coordination demand). |
| 8 | Unreached: upstream block; separately charged full/pure assay delivers **46/70 required controlled quanta** at one tile under actual transport and section-11 coherence loss. |
| 9 | Unreached: upstream functions; core **0/150 QU/hour**, **0/90** integrated days. Capacity alone is sufficient (**1355.2 / 1177.5 QU** at ten years). |

Peak inlet delivery is 9.606 QU per four-hour session. These are measured limits
of the two seeded bodies and present manuals, not an exhaustive impossibility
proof across all legal programs. Layers 2–3 have **not** been established within
a plausible span, even in this favourable ten-year fixture. Natural progression
acceptance therefore remains **FAIL**; no laws or seed coefficients were tuned.

The person book uses its existing text styles, with no new screen or diagram.
An actual fixture readout is:

```text
Qi Condensation layer 1 · day 135
Purity 1.00 · reserve 6.4/1177.5 QU
Residue 0.0% · strain 0.000
Danger sense: quiet
Toward layer 2
- [missing] circuit sustains 30 QU/hour: 0.0/30.0 days
- [met] no injury through the span: clean
```


The first full serial phase-2 invocation completed **39/39 PASS**. After the
additional active-coordinator replay and release-strain cache bookkeeping,
Qi Condensation plus both affected compiler suites are being rerun. The focused
assay already passes: a completely unstable pulse produces **0** controlled
quanta, stops safely at **0.350222** non-dantian strain, conserves all integer
energy, and recovers through exactly **two** invalid practice days. Its saved
limb-strain marker refreshes the memo as those nodes heal; certification also
checks the recorded pre-recovery stable-execution flag. This prevents an old
recovery-day journal from being replayed after the arm is healthy. Ordinary
bodies incur no additional node scan for this bookkeeping.

Layer 9 checks current integrated fill/draw, filtering and simultaneous branch
execution alongside the recorded earlier proofs and sound routes/storage.
The existing 1.5-pressure certification remains valid as capacity grows while
safe pressure and structure remain sound; spending reserve preserves that
capability, as section 9 requires. The latest release assay must still be a
success for integrated-day credit. No certification thresholds changed.


Final affected reruns: **Qi Condensation, session compiler, and session sources
all PASS** (`out/qi_3c_affected_checks.json`). The expanded Qi test additionally
runs a separate, explicitly injected layer-3/layer-7 coordinator fixture in the
actual world: **10 drill-days**, **five release records with at least 400 quanta
spent**, and exact population/economy daily-versus-jump equality after restoring
the day-18 checkpoint through day 35. Prior opening work and reserve charges
are included in its intake ledger. These injected flags and charges are solely
integration-test witnesses, excluded from the natural reachability table.

The final benchmark is now running serially. Its ordinary 50-person cohort
remains at layers 0–1; its regression result cannot establish a performance
bound for a naturally mature layer-3+ population, which the fixture has not
produced. No absolute two-/five-millisecond live-performance claim is made.


The first unpinned after-run measured baseline/unaware/normal/sealed at
**35.607 / 58.014 / 58.671 / 97.553 ms/day**, versus
**30.107 / 49.583 / 50.623 / 90.206** initially. It **fails** the raw +1 ms/day
comparison. Even the unchanged unprepared baseline slowed by 5.500 ms/day;
field and policy timings also shifted, so that separated pair is not a clean
estimate of patch cost. Raw output is `out/qi_3c_bench_uncontrolled.txt`.
A fresh, consecutive before/after pair will pin both processes to CPU 15;
all world, foundation, source and numerical parameters remain unchanged.

Layer 5 now records complete one-hour circuit windows from actual committed
phase transfers, retaining the best single complete circuit instead of adding
branches or combining incompatible hours. The adversarial window checks pass:
a genuine qualifying hour counts despite a low daily mean; transfers on
different hours cannot be combined; partial hours fail; the alternative complete
circuit qualifies; two 45-QU/hour branches cannot claim one 90-QU/hour circuit.
Hourly recording begins with output trials at layer 4. Immutable source
mix declarations are shared per occupied cell/day, and early certifications
avoid constructing irrelevant later trial state while preserving common
processing, coordination and release evidence. No physical solver constants or
certification thresholds changed. Final affected checks are rerunning.


Terminal distribution now has finite funded execution as well as the appended
limb operations: periodic warmup alone cannot certify a dead-end terminal's
initial fill. Each declared drill sends a 100-quantum mobile pulse along the
actual selected lower-to-palm/sole path, records terminal arrival, and requires
at least 20 quanta delivered with stable, injury-free execution. Terminal qi and
remaining assay qi disperse as dissipated energy, with no field deposit or
permanent work granted. These are internal deliveries, so projection losses
apply only to the separate one-tile release test. All pulse transfers and health
exposure use the same bounded executor and stay outside sustained circuit
counters. Autonomous assays respect practice pauses and the two-hour minimum.

Certification scheduling now requires the recorded quota to be complete before
its physical trial; actual changed conditions can still fail a quota-ready
attempt. It no longer knowingly retries an impossible 25/30-day or 3/4-terminal
quota. The deterministic failed-attempt boundary fixture uses complete historical
terminal evidence with a currently blocked route. The active coordinator replay
uses the explicitly labelled danger-unaware physical control so safety-policy
pauses do not hide the paths it is intended to verify; natural-cohort danger
behaviour remains separately checked.


Finite transport uses the reference's ordinary candidate/commit primitives,
without its laboratory-only node-7 grounding rule: node 7 is a sole in the
production anatomy. The standalone accounted-charge assay now verifies all
four actual terminal deliveries. The final active-world replay records healthy
actor deliveries of **68 / 38 / 100 / 99** quanta to the four terminals (31 on
the repeated first terminal), certifies its fourth layer from those records,
and matches daily/jump physical state after cold restoration. The reckless
actor executes every terminal route too, but its existing injury recovery date
123 excludes 28 practice days; no certification evidence is granted for those
invalid dates. This component fixture remains excluded from natural reachability.

`WorldSave` now applies the qi coordinator's existing custom codec through its
script inheritance chain. The explicit unaware-control subclass previously
fell through generic serialization, losing body/memo snapshots and including
wall-clock profile fields. The corrected control replay passes using the same
physical codec as the production coordinator (`out/qi_3c_active.txt`). Default
Qi and whole-save checks are being rerun after this adapter correction.


The first CPU-15 pair measured baseline/unaware/normal/sealed at
**20.545 / 33.163 / 33.667 / 55.228** before and
**20.473 / 33.883 / 34.195 / 56.457** after. Normal passes (+0.528 ms/day), but
sealed **fails** at +1.229 ms/day. Raw data are retained in
`out/qi_3c_bench_paired_before.txt` and `out/qi_3c_bench_paired_first_after.txt`.
The sealed profile identified redundant health scans and repeated instruction
error calculation. Immutable instruction error is now cached independently of
source density. A matching body-revision execution health proof avoids a second
whole-body scan; pulses and external anatomical invalidation require a fresh
check. The focused proof-invalidation test passes. Physical constants, source
precision, kernel cycles, thresholds and fixture settings are unchanged; final
correctness reruns and the final same-CPU after-measurement are pending.


## Fill-gated enlargement — owner decision 2026-11-16

The owner-approved rule is recorded in `docs/daos_laws.md`, Adaptation and
integration: `fill = (reserve + residue) / capacity` at the day's peak dantian
pressure; `g = clamp((fill - 0.60) / 0.30, 0, 1)`. Funded enlargement is bounded
by `g × 0.5% × capacity`, still at 20 QU integration work per QU of capacity.
Both solvers share the factor, work ceiling and reserve-allocation helper.
Blocked storage work retains the corresponding original mixed qi before
refinement, preserving its qualities. Funding already below the new ceiling
is usable; the difference between ceilings alone is not a withheld payment.
The ordinary 50% reserve assignment otherwise remains unchanged.

The reference samples the current day's pressure, rather than the lifetime
maximum. Production samples its storage-pressure trajectory. Growing days and
days within the fill ramp resolve normally; low-fill memo reuse has a bound
against crossing 60%, including the existing 100-quantum budget bucket margin.
The exact opening factor and retained-strain mode are part of memo signatures.
No new persistent body columns or save migration are required.

### Ten-year reachability

The requested `--long-only` run passes its integer accounting and save round
trip (`out/fill_long.txt`). The final post-accuracy rerun is queued behind the
clean full suite. Both capacities stay **100 QU**. Ending reserves are
**24.126 / 24.363 QU**, residue **0 / 0**, purity **1.00**, strain **0**, integer
residual **0 / 0**. Peak recorded retained pressure increases from **0.159544**
to **0.446775**; core circulation stays **0 QU/hour**. All three required return
edges remain dry. Peak inlet admission remains **9.606 QU/session**.

| Layer | Before | After fill-gated enlargement |
|---|---|---|
| 1 | Day 135 (other 147) | Day 135 (other 147) |
| 2 | Core 0/30 QU/hour; lower→abdominal, lumbar→chest, chest→breath dry | Same circuit bottleneck; same three dry edges |
| 3 | Upstream layer 2; pressure 0.159544/1.5 | Upstream layer 2; pressure 0.446775/1.5 |
| 4 | Upstream layers 2–3; no natural terminal trial | Same upstream block |
| 5 | Upstream block; core 0/90 | Same; capacity now also 100/400 QU |
| 6 | Upstream layer 5 | Same upstream block |
| 7 | Upstream block; Split error 0.1325 > 0.08 | Same upstream block; control law unchanged |
| 8 | Upstream block; separate charged assay 46/70 quanta | Same; full/pure charged assay still 46/70 |
| 9 | Core 0/150; 0/90 integrated days; capacity 1355.2/1177.5 QU | Same functional block; capacity now also 100/1000 QU |

Measured **g = 0 throughout**. Reconstructed pre-draw fill peaks at **29.876%**;
effective daily draw peaks at **4.892 QU**. Last recorded draws are
**4.486 / 3.763 QU**. Reconstructed fill uses retained reserve plus recorded
draw; the existing memo's pressure and reconstructed-fill extrema need not
refer to the same exact replay state.

**Next bottleneck:** at 100 QU capacity, the old storage allocation is 10 QU of
work per day. Below 60% fill this allocation stays in reserve, but the part of
the existing 50% assignment above 10 QU still funds other integration work.
Together with present inlet/manual throughput, it establishes a low-fill
balance before return pressure can form a circuit. No integration fraction,
intake coefficient, gate, conductance, seed or certification threshold was tuned.
This is the result for these two bodies/manuals, not a universal impossibility
proof. Ordinary, unprepared Palace and prepared live-cohort two-year counts
will be recorded with the benchmark below.

### Accuracy and verification

The new low-work state exposed numerical approximations that the old larger
residue inventory concealed. The existing accuracy tolerances are unchanged.

- Resolve residue below 1 QU instead of replaying a rounded purge delta with
  the old fractional remainder; the 200-day warm/cold regression checks exact
  residue, remainder, dissipation and zero residual.
- Converge quality moments in the longer eight-node laboratory bypass:
  384 cycles (352 warmup + 32 measured). At pressure 0.082, purity converges
  from 0.912205 at 96 cycles to 0.918007 at 384 and 0.918032 at 768.
  Live sixteen-node kernels retain 48 cycles (32 warmup + 16 measured).
- Apply retained tissue strain from phase one. Coefficient profiles execute
  the reference's existing strain guidance error and half environmental
  admission, keeping internal transfers/refinement active. Profiles share
  immutable geometry and source-basis caches, keyed by their control context.
  The original 24 pressure bins and four time phases remain unchanged.

These implement existing rules more accurately; purity processing, residue
hazards/purge, overpressure injury, adaptation and certification formulas retain
their coefficients. Pressure-grid, allocation and extra-time-phase experiments
were discarded. No new cultivation law was introduced beyond the fill gate.

The complete four-case, three-year compiler comparison **PASS**. Maximum
regular closing-residue error is **4.08%**; canonical residue also passes.
Regular/reference residue is **83/83, 90/89, 9/9, 153/147 quanta** for normal
A/B and reversed A/B; canonical values are **82, 88, 9, 151**. Regular/reference
retention dates are **775/774, 676/674, 514/511, 735/729**. Intake, work,
refinement, strain, recovery, ranking/reversal, conservation, daily/jump,
warm/cold and saved reuse contracts pass. Evidence:
`out/fill_accuracy_final.txt`, `out/fill_accuracy_results.json` and
`out/fill_moment_probe.txt`.

Only one existing numeric expectation changes: `test_cultivator_lab.gd`'s
impure 1-QU reserve case now retains **1 QU instead of 0.5 QU**, with no new
work/residue (previously **0.25 QU work / 0.248 QU post-purge residue**).
Its opening work stays 500 QU. New compiler tests cover 59%, 60%, 75%, 90%,
100% fill, full-rate work, retained reserve, residue-supported fill, underfunded
partial enlargement, mixed purity with a saved remainder, and changing g inside
the former one-percent reuse bucket. No accuracy bound was relaxed.

The first full sweep passed 37/39: compiler residue accuracy and the unrelated
site-export timeout were the two failures. Accuracy is now corrected as above.
`test_sites.gd` now receives the runner's existing **900-second** allowance
instead of 300 seconds on this low-RAM machine; all its assertions are unchanged.
A clean `python3 tools/run_phase2_checks.py` invocation is running. The final
long-only fixture and CPU-15 paired before/after `bench_qi_live.gd` runs follow
serially; ordinary Palace measurement and the **+1 ms/day** regression result
remain pending. No commit has been made.

## Fill first — owner task 2026-11-17: STOP at measurement

**The conditional stop applies: there is no circuit-opening fill at or below
0.80. No reserve floor F has been selected and no law/runtime change has been
made.** In fact these retained manuals cannot meet the layer-2 hourly circuit
threshold at any safe fill. Rounding/capping an absent opening value to 0.80
would conceal the failed prerequisite.

Reproduce with `XDG_DATA_HOME=/tmp/crown-godot godot --headless --path . -s
tools/measure_qi_opening.gd`. Final successful output is saved in
`out/fill_first_opening.txt`. This diagnostic uses `long_prepare`'s two actual
Perfect Palace bodies and retained production A/B manuals (filter 1), the
reference solver with fast paths disabled, and the actual Palace source sample.
Each trial clones fresh anatomy, accounts 500 QU of prior opening work and a
pure/stable reserve charge as prior absorption, then executes one ordinary day
under the existing laws. This injected charge is an assay, not reachability.
The reference's eight-entry scratch arrays require removing the unused tail
nodes from the clone; both manuals use only core nodes 0–4. Nodes 5–7 remain
empty, including the reference's legacy grounding slot. No graph coefficients,
core nodes, instructions, pressure limits or transfer arithmetic are changed.

The 0%, 5%, …, 100% opening-fill sweep corresponds to opening dantian pressures
0, 0.075, …, 1.500. All 42 trials have integer residual zero. For A all three
return edges transfer **0 quanta/day** throughout. For B, lower→abdominal
transfers at most **267 quanta/day (0.267 QU)** (15% initial fill); lumbar→chest
and chest→breath remain zero. At 80% (pressure 1.200) and 100% (pressure 1.500),
all three edges transfer zero for both manuals. Since even whole-day totals
are below 30 QU, no hour in those trials can qualify. The sweep alone is not
an exhaustive continuous threshold search; the following bounds exclude the
entire safe interval independently of sweep spacing.

For a complete hour, overestimate each valve's active time as
`(floor(3600 / cycle_seconds) + 1) × active_seconds_per_cycle`. Set gate=1,
destination pressure=0 and source pressure=1.5, ignoring capacity, available
inventory, control error and downstream competition. This deliberately generous
upper bound still misses 30 QU/hour. Conversely, dividing 30 QU by conductance
and that overestimated active time gives a necessary pressure-difference lower
bound; it is **not** an achievable opening threshold.

| Manual | Edge | Cycle / active seconds | Necessary pressure difference, lower bound | Equivalent fill lower bound at safe pressure 1.5 | Safe hourly transfer upper bound |
|---|---|---:|---:|---:|---:|
| A | lower→abdominal | 120 / 10 | 9.525505 | 635.034% | 4.724159 QU |
| A | lumbar→chest | 120 / 10 | 10.117303 | 674.487% | 4.447826 QU |
| A | chest→breath | 120 / **0** | No finite value | No finite value | **0 QU** |
| B | lower→abdominal | 150 / 10 | 11.191502 | 746.100% | 4.020908 QU |
| B | lumbar→chest | 150 / 10 | 12.409929 | 827.329% | 3.626129 QU |
| B | chest→breath | 150 / **0** | No finite value | No finite value | **0 QU** |

Thus the measured qualifying opening pressure/fill for **each** edge is
**unreachable within safe pressure/fill** on both bodies/manuals; the circuit
has no finite opening value because chest→breath is never scheduled. The
lumbar/chest figures concern their own source pressure, not a claim that raising
dantian pressure produces that pressure upstream. Actual gates and inventory
limits can only reduce these generous bounds.

### Binding executor/manual limits

`production_program` inserts Guide edges 5, 6, 7 before Integrate. It only
replaces an existing Guide [7] with [8]; neither underlying sequence contains
that Guide, so neither resulting manual opens edge 8 (chest→breath). It removes
the Ground operation instead. In addition, return-valve duty time and ordinary
conductance/safe pressure already exclude 30 QU/hour on edges 5 and 7.

Stored reserve contributes dantian backpressure but is not mobile node mass:
`flow_model` bounds outflow by `total(source)`, whereas `pressure` also includes
`stored_quanta`. `settle_model` removes the mobile dantian packet into opening
work/reserve. Increasing retained reserve therefore does not by itself provide
spendable return-flow inventory. These are independent obstacles to the proposed
causal explanation; none has been tuned or repaired in this measurement task.

### Conditional downstream work

Per the explicit “if … exceeds 0.80, stop and report” instruction, steps 2–3
were not executed. The 50% integration draw and enlargement constants 0.60/0.30
remain unchanged; mortals/non-practising people are unaffected. There is no new
floor to test, no changed test expectation, no after-law benchmark and no
performance-regression claim. The full phase-2 suite and ten-year fixture were
not rerun for this diagnostic-only stop. The reference assay above passed.

| Layer | Before fill first (existing ten-year evidence above) | After fill first |
|---|---|---|
| 1 | Day 135 (other 147) | Not run: conditional stop |
| 2 | Unreachable; core 0/30 QU/hour | Not run |
| 3 | Upstream layer 2; pressure 0.446775/1.5 | Not run |
| 4 | Upstream layers 2–3 | Not run |
| 5 | Upstream block; core 0/90; capacity 100/400 QU | Not run |
| 6 | Upstream layer 5 | Not run |
| 7 | Upstream block; Split error 0.1325/0.08 | Not run |
| 8 | Upstream block; charged assay 46/70 quanta | Not run |
| 9 | Upstream block; core 0/150; capacity 100/1000 QU | Not run |

No new ordinary Palace two-year measurement was run after this stop; no after-law
layer-2/3 count or ms/day result exists. No commit was made.


## Channels widened — owner recalibration 2026-11-17: opening targets FAIL

**Opening-target acceptance: FAIL.** Complete manual data, save migration and the
70% floor are implemented. No successful anatomy recalibration is selected.
All 41 regression checks pass across the full sweep and affected reruns. The
final CPU-15 benchmark passes +1 ms/day (normal +0.552, sealed +0.852).
The 70%/85% layer-2 openings remain unmet; no anatomy multiplier is adopted.
The records below distinguish final results, experiments and unimplemented proposals.

Baseline: the retained A/B manuals omit chest→breath and have only ten seconds
per cycle on each return valve. The existing Perfect assay finds no safe opening
through 100% fill. Grade-specific and widened-clone assays and before/after live benchmarks are
complete. No successful factor or opening at the requested fill is claimed.

The critical distinction remains: pressure includes stored reserve, whereas
transfer availability excludes it. Widening conductance cannot make unavailable
reserve mobile. If this prevents the targets, the owner requested a proposed
law repair only; the physical transfer law will stay unchanged.


### First recalibration evidence

The before-change live benchmark completed: baseline **30.537**, unaware
**56.939**, normal prepared cohort **54.576**, sealed **86.573 ms/day**.
Ordinary Palace: **0/50 qualified; 0 layer 2, 0 layer 3** by day 730.
Prepared Palace subgroup: **17/17 layer 1; 0 layer 2/3**. These are distinct
qualification workloads, not estimates from the injected opening assay.
Raw evidence is `/tmp/channels_bench_before.txt` (to be copied to `out`).

The complete-schedule, widened-clone assay gives each return valve 30 seconds
per cycle (A 210 seconds, B 220 seconds). Multiplying both capacity and
conductance by **1,000,000** on lower→abdominal, abdominal→lumbar,
lumbar→chest and chest→breath still produces **zero complete core flow** for
Perfect A and B throughout 0–100% fill, including 70% and 85%. Every trial has
integer residual zero. This is an exclusion experiment, not a selected seed
factor or proof that arbitrary manual schedules cannot work. Other binding
edges and the mobile-inventory restriction are being checked next.


### Final authored schedules and floor implementation

The final production manual data gives A/B a complete primary core route,
refinement before storage, and a four-lane 40-second return phase before
Integrate. Both cycles are 110 seconds. B prioritises the qualifying abdominal
core rather than splitting its inlet into an unfinished alternative; it retains
its own default filtering and two-node processing instruction. No operation,
flow, pressure, purity or adaptation equation changes. Reference assays and
production consume the same compiled instruction dictionary. JSON target indices
are explicitly normalised to integers instead of depending on float-array versus
integer-array equality in the old graph-remapping code. The laboratory
manuals retain their separate eight-node graph and schedules.

The shared integration helper now assigns **half the surplus above 70% reserve
capacity**, rounded in integer quanta. It does not assign half of the protected
reserve, and residue cannot substitute for the protected reserve. The existing
fill gate can withhold further spending. A floor value in memo signatures
invalidates old accounting deltas; the existing conservative <60% reuse bound
cannot cross the new 70% threshold. Old authored A/B schedules migrate lazily
to manual revision 2, preserving personal filtering, physical state, adaptation
and dated achievements, and invalidate both execution reuse and intake forecasts.
Anatomy coefficients are unchanged, so no coefficient migration is necessary.
The floor/migration test passes, including exact save round trip.

**Target obstruction in the fully widened assay:** grade 2 has safe pressure
4/3. After full-packet Filter and Stabilise, even an abdominal node initially
filled to its full safe headroom
retains at most `(4/3) × 0.85 × 0.98 = 1.110667 QU`. Its volume is one, so
that is also its maximum refined pressure. At 85% lower fill, lower pressure
is `0.85 × 4/3 = 1.133333`. No such fully refined packet can enter the lower dantian.
Stored reserve supplies pressure but no transferable inventory. Further widening
of these already-wide channels cannot change either constraint. The full-packet refined-pressure ceiling is
83.3% of safe pressure, independently of grade; this is a pressure bound, not
an opening threshold. At smaller coefficients partial processing must be measured
separately; this is not a proof excluding every nonuniform coefficient choice. In the fully widened clone the fresh packet is smaller
still: ordinary admission is limited to 90% of safe breath pressure, and its
post-refinement ceiling corresponds to 74.97% lower fill. Accumulation can
change that fresh-packet figure, so it is not a universal bound.
These bounds concern the completed manuals' refinement order, not every possible
data-authored sequence. A tested refinement-after-lower variant still failed
grade 2 (peak 25.206/28.330 QU/hour with feed ×1000, lower return ×10,
other returns ×1000). It is not adopted.

**No permanent anatomy multiplier is selected:** there is no measured factor
meeting both opening targets, so reporting a smallest successful factor would
be false. Return-only ×1,000,000 and whole-core ×1,000,000 are diagnostic clone
overrides, not seeded coefficients. Opening-target ±5-point acceptance remains
failed; regression checks do not certify that acceptance.

**Proposed law fix, NOT implemented:** an explicit return withdrawal must make
stored reserve available to a guided lower-dantian outflow. Atomically debit
reserve and its proportional elemental/quality moments as the packet becomes
mobile or transfers; never count it twice in pressure or the energy ledger.
Keep residue immobile and retain the existing gate, conductance, capacity,
destination headroom, exposure and simultaneous-allocation constraints. Both
executors would need the same funded withdrawal and compiler inventory model.
The current execution body has reserve quality moments but no maintained
five-bin reserve elemental inventory (`MeridianStore.reserve_mass` is currently
unused by coordinator/compiler). A correct implementation must retain elemental
composition on settlement and withdrawal and define old-save composition
migration, not fabricate an element from the root. The compiler also currently
short-circuits transport when ambient budget is exhausted: reserve-funded
transport must have its own conserved funding path, rather than being scaled by
ambient admission. This requires owner approval as a law change. Recalibrate only after its exact
semantics are approved and measured; it is not claimed to guarantee the targets.


### Changed expectations (quantities below in QU)

`test_session_compiler.gd`, empty-source pure-reserve cases:

| Starting fill | Old draw → new draw | Old storage work → new storage work |
|---|---:|---:|
| 59% | 19.5 → 0 | 0 → 0 |
| 60% | 20 → 0 | 0 → 0 |
| 75% | 32.5 → 2.5 | 5 → 2.5 |
| 90% | 45 → 10 | 10 → 10 |
| 100% | 50 → 15 | 10 → 10 |

The 2-QU reserve + 73-QU residue case now expects **0 draw**, previously
1 QU; residue still produces a 5-QU enlargement-work ceiling at 75% total fill.
The mixed-purity fixture changes from 20 QU reserve + 55 QU residue to 95 QU
reserve + zero residue so it exercises spending above the new floor: expected
draw **12.5 QU**, pure work **8.750 QU** with the saved 0.9-quantum remainder,
instead of the former 5-QU pure-work target. A new 70% no-draw case is added.
These are law-dependent expectations; the 5%/10% accuracy bounds, strain and
recovery tolerances, conservation and deterministic replay assertions are
unchanged. `test_cultivator_lab.gd` needs no expectation change for this floor.


### Per-grade opening sweep

Each entry tests both actual A/B fixture individuals, fresh clones at
0%, 5%, …, 100% reserve fill, with full prior opening work and an accounted
pure/stable reserve charge. “None” means no qualifying daily core rate in the
safe sweep, not a rounded or capped opening value. Average uses the laboratory's
normal grade-2 foundation; grade 1 was also measured after the change.

| Foundation | Before opening fill A/B | After opening fill A/B | After maximum core A/B (QU/hour) |
|---|---|---|---:|
| Poor, grade 0 | None / None | None / None | 0 / 0 |
| Average fixture, grade 2 | None / None | None / None | 0 / 0 |
| Perfect, grade 3 | None / None | None / None | 0 / 0 |

The additional grade-1 after sweep also has no opening. Every trial conserves
integer energy exactly. Raw before/after and extreme-width sweeps are retained
under `out/channels_widened/`. In the final whole-core ×1,000,000 diagnostic,
maximum daily core rates for grades 0/1/2/3 are approximately
24.35 / 28.43 / 32.46 / 36.53 QU/hour; grade 2 nevertheless has zero lower
return at 85% fill. These are capacity diagnostics, not natural achievements.


### Fresh before-change ten-year fixture

The requested serial `-- --long-only` baseline completed with exact integer
accounting and save round trip. Layer 1 dates are A **147**, B **135**;
layers 2–9 remain unachieved. Peak core **0 QU/hour**, retained pressure
**0.443550**, reconstructed fill **29.639%**, draw **4.785 QU**. Both capacities
are **100 QU**; ending reserves A/B **24.070 / 23.783 QU**, residue **0 / 0**,
residual **0 / 0**. This fresh baseline supersedes the small numeric differences
in the older historical runs above. Final after-change long-only and live
benchmark results follow once the serial suite finishes.


The first full suite reached a changed-law expectation in
`test_qi_condensation.gd:deviation_handling`: travel with 50 QU reserve previously
funded integration. That reserve is now protected. Its explicit accounted
travel-upkeep charge is updated **50 → 90 QU**, preserving the assertion that
funded upkeep can execute without ambient intake. Separate floor tests require
no integration below 70%. No safety, conservation or accuracy assertion is
removed. The first sweep is continuing to find any further affected expectations.


### Accuracy after the floor

Both compiler suites **PASS** with unchanged bounds. Four three-year regular
compiler/reference cases have usable/refined errors below **0.3%**; maximum
closing-residue error is **4.08%**, within 10%. Normal A/B residue is **83/83,
90/89** quanta; reversed A/B **9/9, 153/147**. Retention dates regular/reference:
**775/774, 676/674, 514/511, 735/729**. Reversed/B recovery **628/616** days
and strain **0.318286/0.310664** remain within existing tolerances. Canonical
comparisons, integer conservation, daily/jump, reuse and cold-save checks pass.
Moving-source coefficient worst error is **2.9319%**, below the unchanged 5%
bound. No additional solver approximation or tolerance change was necessary.


The first affected rerun passed the corrected travel case and the six-person
safety/save/daily-jump checks, then exposed the second floor-dependent expectation:
open/sealed Palace work is now **500/500 QU**, rather than strictly less work
under sealing. Neither body draws the protected reserve. Sealing still delays
layer 1 **245 → 249 days**. The assertion now requires that strict retention delay
and `sealed_work <= open_work`; it no longer assumes protected reserve must be
spent. No source law, threshold or accuracy tolerance changed.


### Ten-year before / after table

The embedded after-run and final explicit `-- --long-only` invocation both
confirm the following table, including integer conservation and save round trip. No later-layer tuning
has been applied.

| Layer | Fresh before | After complete manuals + F = 0.70 |
|---|---|---|
| 1 | A day 147; B day 135 | A day 245; B day 213 |
| 2 | Core 0/30 QU/hour | Core 0/30 QU/hour |
| 3 | Upstream layer 2; pressure 0.443550/1.5 | Upstream layer 2; pressure 0.437730/1.5 |
| 4 | Upstream layers 2–3 | Same; no natural distribution trial |
| 5 | Core 0/90; capacity 100/400 QU | Same |
| 6 | Upstream layer 5 | Same |
| 7 | Upstream block; Split error 0.1325 > 0.08 | Same untuned control limit |
| 8 | Upstream block; charged assay 46/70 quanta | Same; current assay again delivers 46 |
| 9 | Core 0/150; capacity 100/1000 QU; 0/90 integrated days | Same |

After ending reserves A/B are **20.854 / 29.182 QU**, capacities **100 / 100 QU**,
residue **0 / 0**, integer residual **0 / 0**. Peak fill **29.182%**, draw **0**,
enlargement factor **0**. The floor is respected but never reached naturally.
All three required return channels remain nonqualifying: peak daily lower return
is only **8 quanta**, lumbar→chest and chest→breath remain dry. This is a failed
recalibration result, not successful layer-2 reachability.


### Final regression verification

The default `python3 tools/run_phase2_checks.py` sweep completed **40/41 PASS**;
its sole failure was the obsolete below-floor travel expectation. The affected
Qi rerun then exposed the obsolete strict sealing-work comparison. Both
expectations are corrected as listed above, and the full affected Qi suite now
**PASS**, including two-year physical population/economy daily/jump replay,
sealed safety, paid terminal/release trials, and cold continuation.

A stronger old-save regression then caught a genuine transient-cache mismatch:
revision 1 versus 0 after cold restoration when an obsolete manual had no
execution journal. Migration now discards the obsolete journal **and resets its
transient revision**, rather than bumping an otherwise unpersisted counter.
It preserves the charged **75 QU** reserve, quality moments, **500 QU** opening
work, **0.1** scar and **0.2** adaptation. Its saved daily/jump continuation is
now exactly equal. The final `test_qi_fill_first.gd` rerun **PASS**.

**All 41 regression checks pass across the full sweep and affected reruns**;
this is not a claim that the first sweep was clean. Provenance and final results:
`out/channels_widened/final_checks.json`, `initial_suite.json`, `qi_rerun.json`,
`floor_rerun.json`, `qi_final.txt`, and `floor_contracts.txt`. No tolerance was
relaxed. Opening-target acceptance remains FAIL independently of regression
success. The explicit final long-only run also PASS; its numbers match the table above.
The final live benchmark and grade sweeps are complete; final timings appear below.


### Final unpinned live benchmark and ordinary cohort

The final unpinned benchmark completed all four 730-day modes:

| Mode | Before ms/day | After ms/day | Raw delta |
|---|---:|---:|---:|
| Unprepared baseline | 30.537 | 38.000 | +7.463 |
| Prepared, danger-unaware control | 56.939 | 70.830 | +13.891 |
| Prepared, ordinary danger response | 54.576 | 77.434 | +22.858 |
| Prepared, sealed | 86.573 | 125.600 | +39.027 |

This raw pair **fails +1 ms/day**. The no-qi baseline itself slowed **24.4%**;
this does not isolate patch cost. A consecutive CPU-15 pinned pair was run,
using an isolated `git archive HEAD` baseline under `/tmp` with a private copy
of import caches, followed by the current workspace. No git/worktree mutation
or parallel Godot process is used. Environmental sources, seeds, workloads, world dates,
accuracy and fixture parameters are unchanged between those comparison modes.

**Ordinary Palace at two world years: nobody reaches layer 2 or 3; 0/50 even
qualify for a physical qi body**, before and after. This is the ordinary
unprepared population, not the injected opening assay. In the separately
prepared Palace subgroup **17/17 reach layer 1; 0 reach layer 2/3**, both normal
and sealed. The current full-world normal run's last layer-1 date is **295**;
sealed **364**. Raw output is `out/channels_widened/bench_after.txt` and
`channels_bench_before.txt` in that directory. Final pinned timings follow.


### Sealed performance investigation

The first CPU-15 pair measured baseline/unaware/normal/sealed at
**52.213 / 93.264 / 62.558 / 72.298** before and
**24.319 / 46.363 / 46.711 / 74.492 ms/day** after. Normal is faster, but
sealed **fails** the literal +1 bound at **+2.194 ms/day**. Baseline drift is
large; sealed phase profiling nevertheless identifies coefficient solving as
an actionable cost (19.836 → 22.558 seconds over 730 days).

A geometry-proved one-to-one simultaneous-flow path now skips allocation-sum
arrays when every lane has a unique source and destination. Cross-linked
chains still sample every packet and moment before committing. Shared sources
or destinations keep the original generic allocator. Crucially the fast path
keeps the original divide/multiply/floor rounding, rather than substituting
`min()`. No pressure, conductance, capacity, processing, time grid, warmup,
quality or certification equation changes.

`test_session_sources.gd` compares optimized and retained generic kernels in
**288 bit-exact cases** across laboratory/production anatomies, A/B and an
extra coordination instruction, regular/canonical compilation, simple/mixed
qualities, low/high density, pressure endpoints/midpoints and health contexts.
All comparisons pass; existing source accuracy remains **2.9319%**. The full
three-year compiler and floor suites are rerunning before a final timed pair.
This is an execution optimization only; it does not widen seeds or solve the
opening-target failure.


The optimized full three-year compiler, source and strengthened floor suites
all **PASS**. Comparison metrics remain identical to the pre-optimization
results quoted above; 288 generic/optimized kernel comparisons remain bit-exact.
`optimized_checks.json` and the three `*.gd.final.log` files retain the rerun
provenance, and `final_checks.json` now reflects those latest results. All 41
checks pass across the full sweep and affected reruns. A final consecutive
CPU-15 reference/current benchmark pair is running after these checks.


### Final performance result — PASS

The final consecutive CPU-15 pair uses the isolated original tracked source
and current optimized workspace, with every Godot process serial:

| Mode | Before ms/day | After ms/day | Delta |
|---|---:|---:|---:|
| Unprepared baseline | 25.433 | 24.849 | -0.584 |
| Prepared, danger-unaware | 48.007 | 46.371 | -1.636 |
| Prepared, ordinary danger response | 45.364 | 45.916 | +0.552 |
| Prepared, sealed | 70.441 | 71.293 | +0.852 |

All four measured deltas satisfy **≤ +1 ms/day**. The closer unprepared
baselines make this final pair more useful than the earlier noisy pairs; no
absolute performance guarantee beyond this workload/machine is claimed.
Raw logs: `bench_pinned_final_before.txt`, `bench_pinned_final_after.txt`;
structured results: `final_benchmark.json`, all under `out/channels_widened/`.
The unoptimized and optimized runs' deterministic cohort summaries, ordinary
Palace counts and danger-response summaries are **identical**. The optimization
changes execution cost, not physical results.

**Final verdict: FAIL for the owner's opening/reachability target.** Manuals,
F=0.70 floor, old-save migration, conservation, determinism, accuracy and final
performance checks are implemented/verified. No calibrated seeded widening is
adopted, and natural layers 2–9 remain unreachable in the requested fixture.
The proposed funded reserve withdrawal and elemental inventory change above
is **not implemented**. Split error **0.1325 > 0.08** and release **46/70**
remain untuned downstream limits. No commit was made.


### Diagnostic duty-count correction

The final before sweeps were reproduced against the isolated original source,
using the updated read-only measurement tool. Duty counting now casts JSON
numeric targets to integer indices, and equivalent fill divides by each grade's
actual safe pressure. This exposes an instrumentation error in the historical
bound table: legacy float-target Guide instructions were omitted from its duty
count. Actual lumbar→chest duty is **20 seconds** for A/B, and B lower→abdominal
also has **20 seconds** (A lower remains 10). Corrected Perfect necessary-pressure
lower bounds are A/B lower **9.525505 / 5.595751**, lumbar **5.058651 / 6.204965**.
Chest→breath remains unscheduled, with no finite opening. Thus the old 6–8×
claim is overstated for those duplicated instructions; the failed safe circuit
and zero opening-flow results are unchanged. Final raw before/after grade
sweeps are error-free and every one of their 42 trials per grade has residual 0.
The physical flow law and original before-state instructions were not changed.

## Guided circulation — implemented by Claude (19 November 2026)

Owner-approved law (docs/daos_laws.md, "guided circulation"): a `Circulate`
operation (code 8) pumps every lane with head `2.8 × p(dantian)`, draws stored
reserve as mobile qi for lanes leaving the dantian, and charges channel strain
for qi pushed against adverse pressure. Both executors implement it: the
reference slice solver (`circulate_model`) and the production periodic kernel,
which tracks withdrawn reserve as a tracer so returned qi keeps the reserve's
own quality; only losses on the way leave the reserve. Integer residual is 0
in every probe and fixture.

- **Opened dantian first.** Circulation unlocks with layer 1 (`retention`);
  beginners keep the revision-2 serial schedule (`practice.json` `sequences`),
  opened cultivators switch to `opened_sequences`. Without this a greedy
  beginner pumped impure Sect qi and died by day 14.
- **Danger sense** now feels channel strain as well as dantian strain.
- **Layer 3 standard (owner, 2026-11-19):** a full vessel is 97.5% of the
  body's own safe pressure (`vessel_limit`, per person, default 0.975, for
  future treasures). The pressure actually held is kept as a distinction:
  ordinary < 1.33 ≤ genius < 1.5 ≤ heavenly-gifted.
- Opening fill (reference, Returning River): Perfect 65%, average 85%, poor never.
- Changed expectations: `test_qi_fill_first` (Circulate counts as return duty;
  migrated manual revision 3); `test_session_sources` (uphill-work columns use a
  10% gate; they only drive channel strain).

Ten-year Perfect fixture: layer 1 day 213, 2 day 246, **3 day 421, 4 day 455**.
The second fixture person reaches layer 2 (day 246) and holds about 70% fill:
the daily integration draw above the floor keeps their vessel short of 97.5%.

### Walls found (for the owner)
- **Layer 5, one hour at 90 QU/hour:** the best circuit reaches about 44 QU/hour.
  The narrowest core channels carry roughly 100 QU/hour even fully open, so this
  needs a dedicated circulation hour plus channel growth (adaptation can triple
  capacity). Average bodies cannot reach it without wider channels.
- **Layer 7, coordination error ≤0.08:** the shared control coefficients give 0.1325.
- **Layer 8, release ≥70% at one tile:** a full, pure, Perfect release delivers 46%.
- **Layer 9 requires safe pressure ≥1.5:** heavenly-gifted vessels only, as written.

## Vessel ceiling and filling (owner decisions 2026-11-21)

- Layer 5 standard: 35 QU/hour (best single hour on the core circuit, 30 days). 40 and above remain distinctions.
- **Vessel ceiling:** `initial capacity × dantian safe pressure × 1.5^(layer pursued) × 10^(realm − 1)`
  (`data/cultivation/lab.json` → `vessel_ceiling`, `QiPractice.vessel_ceiling`). Work the ceiling refuses
  goes to the channels like any other surplus. An ordinary vessel tops out near 3,800 QU at peak Qi Condensation.
- **Choosing to fill:** before layers 3 and 9 a cultivator stops enlarging until 97.5% full and draws only the
  overflow (`milestones.filling`). Not before layer 5: a full dantian pushes back on the returning circuit,
  and measured output fell from about 38 to 17–30 QU/hour.
- Thirty-year Perfect fixture: layers 1–4 on days 213, 246, 273, 307; both vessels reach the 1,139-QU layer-4
  ceiling. **Layer-5 wall:** the best hourly core output is about 39 QU/hour and channel adaptation (about ×2)
  does not raise it; the drive, not channel width, is the limit. Proposed to the owner: 35 QU/hour.

## Layer 7 unblocked (2026-11-22)

- The weekly split drill's lumbar lane never moved: lumbar sits at about 1.05 pressure, just below a filling
  dantian's back-pressure (about 1.06), so a passive Guide had no gradient and the simultaneous minimum was always 0.
  The drill now drives the pair `[2,4]` with guided Circulate (the dantian head pumps both lanes; uphill strain applies).
- The branch rate is QU/hour while both lanes run (`simultaneous_seconds`), not averaged over the four-hour session;
  days without the drill keep the last drilled rate. Standard unchanged: ≥25 QU/hour, error ≤0.15.
- Perfect fixture, 30 years: layers 1–8 on days 213, 246, 273, 307, 818, 825, 832, 902. Drilled branch rates about
  110 and 64 QU/hour. Both stop at layer 9 ("integrated practice, earlier functions intact").

## Layer 9 unblocked (2026-11-22)

- The second vessel fill moved from layer 9 to Foundation (`FULL_VESSEL_LAYERS = [3, 10]`): nothing at layer 9 reads the
  held fill, and a full dantian pushes back on the circuit layer 9 needs. Days with a 35 QU/hour hour at layer 8 rose
  from 15 to 1,082 (of 1,869).
- Integrated practice no longer needs every function on one day: draw, a 35 QU/hour hour, mixed qi and a successful
  release each count when last shown within 7 days (`INTACT_DAYS`). Release is only tested weekly.
- Owner decision: layer 9 core standard 35 QU/hour daily average (`CORE_RATE`); 75 is the distinction, 150 legendary.
  The best daily core seen is about 40.
- Perfect fixture, 30 years: one cultivator reaches layer 9 on day 2380 (about 6.5 years); the other stays at layer 8,
  its core rarely holding 35.
