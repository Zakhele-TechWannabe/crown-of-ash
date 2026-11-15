# Qi Condensation implementation status

Stage 3 is **incomplete**. The live game still uses the legacy cultivation
ladder. It must not be treated as implementing the rulebook's certifications.
No production sessions or new body diagram have been enabled by this change.

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
