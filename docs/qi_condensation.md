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
