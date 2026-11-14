# Cultivator laboratory

Run `godot --headless --path . --script tools/cultivator_lab.gd` from the project root. It loads no scenes and writes `out/cultivator_lab.txt`. Run `godot --headless --path . --script tools/test_cultivator_lab.gd` for focused checks. `python3 tools/run_phase2_checks.py` discovers that test with the others and runs them serially. Let each Godot process finish before starting another on a low-memory machine.

A and B start with identical nine High Body Tempering grades loaded through BodyTempering. A follows the narrow abdominal path with full filtering. B splits between that path and the lumbar bypass, filters less, and coordinates more operations. JSON defines the graph, foundation, operation vocabulary and deterministic program sequences. The second fixture exchanges abdominal and bypass channel quality. Each run owns a fresh deterministic qi field and withdraws actual qi at the sect spring on each authoritative date.

Nodes retain five elemental inventories and energy-weighted quality moments. Ten-second phases calculate competing edge candidates from the same opening state, limit them by available supply and safe destination headroom, then commit them together. Opposing elements add local instability when newly mixed. Transfers preserve prior stabilisation. Filtering and stabilisation consume qi. The admission forecast runs the same engine; the field withdraws that bounded demand once. If supply is short, execution is recalculated with the actual allocation. No scene or society clock supplies cultivation credit.

Quantities are QU. “Refined” is settled delivery before reserve storage and permanent work; “usable” weights delivery by purity. Circulated counts traversed edges, so it is not new energy. Work is irreversible expenditure, not a second reserve. Refined storage contributes to dantian pressure and admission headroom. Both manuals assign half the closing reserve to daily integration, which consumes it; dantian development costs 20 QU per added QU of capacity and respects the daily growth limit. Retained purity refers to stored reserve; instability is weighted by settled delivery. A zero residual means every withdrawn quantum is in a node, stored, lodged as residue, spent, dissipated or grounded. Equal state hashes mean daily calls and a three-year jump produced identical body records.

Autonomous results are separate: every 90 days a copied-state experiment compares retaining its manual, switching paths, and changing filtering. It selects permanent work gained minus residue added weighted by personality fear and a current-strain penalty. These tests are predictions and consume no resources or learning. The character uses a simple laboratory objective rather than the live mind system. Program changes and reasons appear in the report.

Safety fixtures start with an explicitly charged chest (0.8 QU cautious, 40 QU overloaded). The damaged fixture uses the same charge and a grounding edge at 2% integrity. They use the same graph and damage functions on a one-second grid. Pressure and blocked discharge create exposure and injury; death follows exhausted structural integrity, with no random death roll. They are extreme engineering fixtures, not estimates of population mortality.

The final line applies the Stage 2 thresholds. Read it together with the identified operations and actual edge measurements. If no ranking reverses, the report explicitly flags a uniform landscape. No route receives an output multiplier. Execution error uses section 13's coefficients, with the additional branch counted as an unfamiliar transition. This mapping and the fixed ten-second operation durations are explicit experiment assumptions requiring calibration. Only retention is certified here: the fixture has no four-limb distribution or controlled projection tests, so it does not award later layers from throughput alone.

The owner decision of 14 Nov 2026 partitions all permanent expenditure into pure
work and impure residue, including opening and reserve integration. Residue
shares lower-dantian volume and adds squared residue/capacity danger during
practice and while it remains lodged between sessions. Its data-defined daily purge flows into dissipation; `purge_multiplier`
is the later treatment hook. Retention reports dates stalled above the residue
wall. Layer 3/6 purity checks report their first qualifying reserve date without
awarding either layer; the report also gives closing purity and potential
technique power (reserve × purity²).

Definition JSON and compiled instructions are cached in static dictionaries.
Typed internal compartments, edges and cultivator accounting avoid repeated
dynamic dictionary work; public state adapters and explicit serialization keep
replay and trial copies independent. Forecast rollback copies only mutable
anatomy, quality moments and current accounting, sharing read-only instructions,
foundation and choice history. Integer split and interference caches are bounded.

Effective channel rates and processing limits are cached for each session, then
invalidated before adaptation can affect the next session. Single-edge transfers
fuse packet removal/admission. Two lanes with distinct destinations and no
intermediate chain keep opening-state candidates and the reference allocation
order without temporary packet queues. Whole-node refinement preserves the
general solver's moment arithmetic. Cached split packets are immutable; only
owned node inventories are copied for mutation. Exposure caches invalidate whenever inventory changes.
Empty, unstrained nodes avoid zero-danger arithmetic; quality boundary cases
still execute the complete danger formula.

A stopped session with no mobile packets can advance remaining cycles using
only the return valve's fractional rotation and the dantian's exact scalar strain
recurrence, provided no injury threshold can be crossed. It preserves repeated
floating additions rather than substituting a rounded multiplication. General
sessions retain their ten-second slices: continuous quality moments and saved
transfer remainders do not justify approximate steady-state detection. Tests
compare both routes and the quiescent shortcut against the general solver.

With the impurity laws, the unchanged reversed anatomy reverses usable output,
permanent work and retention day: its wider abdominal path benefits careful A,
while B's poorer bypass and lower filtering incur residue backpressure and
recovery. The baseline anatomy still favours B on delivery and permanent work.

The lab executes independent experiments on at most four worker threads inside
one Godot process (bounded by available CPUs). Set `CROWN_LAB_WORKERS=1` to
force serial execution. At most four field instances exist at once. Workers share
read-only parsed definitions and initial templates; each owns a solver instance,
mutable caches, field and body. Results are joined and reported in a fixed order.
The daily replay remains an independent body/field execution, never a cached
copy of the jump result. Other Godot tests still run serially.

Call the solver through `preload("res://src/circulation.gd").new()`; parsed JSON
stays static, while simulation caches and counters belong to that instance.

Measured on 14 Nov 2026: the owner's reported full-run baseline was about
960 seconds; the completed optimized command took 187.49 seconds (about 5.1×
faster), including engine startup. The four-worker run peaked at 206,352 KiB
(201.5 MiB) RSS. Its daily and jump hashes matched the serial run exactly, and
all conservation residuals were zero. The fixture did not reach the narrowly
eligible quiescent state, so zero cycles used that shortcut; the measured gain
comes from cached definitions/rates, fewer allocations, typed state and bounded
parallel experiments, without approximate convergence.
