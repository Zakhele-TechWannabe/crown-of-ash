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
