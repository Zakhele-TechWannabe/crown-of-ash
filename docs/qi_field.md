# Qi field contract (Stage 1)

`Society.qi_field` owns the environmental field. It does not change legacy cultivation, tempering, combat, wildlife, or Fifty decisions. Definitions are in `data/qi/`; the atlas seed is the default seed, with a dedicated stable FNV-derived RNG stream. No scene, rendered chunk, or walker supplies field state.

## Positions, units, and scheduling

- Positions are ground-tile coordinates. Cell coordinates are `floor((position + 0.5) / 16)`, clamped to the atlas bounds. All cell inventories use integer thousandths of QU in Metal, Wood, Water, Fire, Earth order.
- `sample(position, day)` reads the current authoritative date; it does not advance time or invent historical/future samples. The optional date must equal `field.day`.
- `request(stable_consumer_id, position, PackedInt64Array([metal, wood, water, fire, earth]), priority)` queues independent elemental demands for the next crossed day. Lower priorities settle first. Submit once per consumer per step. These are component budgets, not an atomic mixed-element recipe operation.
- `advance(date)` regenerates, recovers backgrounds, disperses excess, emits sources, and settles requests on each crossed day. A queued request executes once, on the first crossed date. Later systems must schedule their dated requests at daily boundaries, rather than submit one request for an entire jump.
- Read `allocations[consumer_id]` immediately after the step. Allocations are already withdrawn exactly once. Future consumers must bound requests by usable headroom; this API does not yet implement cancellable body-flow reservations or recipe execution.
- Same-priority sharing uses exact integer proportional shares and largest fractional remainders. Stable date/cell/element/consumer keys break ties. Multiplication/division has an overflow-safe path for large demands.

The last step's ledger includes opening/closing field and reserve totals, actual reserve regeneration, source output, background recovery, withdrawals, dispersion, and residual. Source output is an internal transfer, not another external creation. Five elemental field residuals and each source's elemental reserve accounting are also checked. History is bounded to the last ledger.

## Sources and initial conditions

Vein roots have finite five-element reserves, capacities, composition, quality, grade, and integrity. Their serial outlet edges have finite throughput and integrity. Upstream emission spends the shared budget before downstream emission. `damage_source(node_index, thousandths)` and `damage_edge(edge_index, thousandths)` affect regeneration/delivery; the Heavenly Origin is indestructible. `set_emergency_output(node_index, enabled)` raises the shared daily release ceiling to twice rated output, while regeneration stays at the ordinary rate; validation demonstrates reserve drain. It supplies ambient deficits, rather than bypassing the field into a consumer. No gameplay system enables it in this stage.

A source emits only toward elemental deficits inside its compact kernel. Emission is divided among receiving cells, never copied into every cell. Unused elemental output remains underground. Daily source and background inputs mix energy-weighted integer quality moments. Dispersion samples the opening mixture; recovery adds terrain qualities. Separate saved recovery/dispersion remainders prevent rounding drift when an element crosses background.

Generation represents already existing geological sources: initial outlet footprints are charged **from their finite reserves**, recorded by the `generated prehistory` ledger. Initial density is therefore paid source inventory, rather than a Palace coordinate multiplier. It does not claim the entire Palace estate is density 64. Estate-wide gathering and carved practice chambers belong to formations; no compartments or duplicate volumes exist here.

The Palace anchor comes from `data/sites/heaven.json`; the spring is the named building's center in the sect layout; hunting branches use the actual destination in the sites manifest; village reporting uses its kitchen anchor. The generated graph adds 48 terrain-weighted wilderness veins. Wilderness generation excludes grade 6.

## Persistence and performance

WorldSave captures a subsystem schema, seed, date, finite elemental reserves, damage, sparse changed cell inventories, quality moments, rounding remainders, pending requests, and the last ledger/allocation receipts. Graph topology, terrain templates, indexes, and textures regenerate. Invalid shapes fall back to generation at the saved date; missing legacy fields are initialized there without historical replay. Old abstract cultivation points do not become environmental mass.

Packed masses, cached totals, four quality moments, two rounding channels per element, terrain IDs, flags, active indices, and serialized graph payload measure approximately **10.29 MiB** in the fixture. Godot tracked allocations measured **10.66 MiB** for a generated field, including its containers and configuration. Neither number is whole-process RSS. Generation timing and payload bytes are printed by `tools/test_qi_field.gd` on each run.

Only active cells advance. Long jumps may skip a *witnessed exact repeated complete state*, using a bounded SHA-256 cycle cache, with no pending requests. This preserves the daily reference state and final ledger; it does not assume a floating-point equilibrium or an approximate exponential decay.

The century-long family fixture has a 900-second guard for its 36,500 authoritative field steps; other fixtures retain the 300-second guard. Assertions are unchanged.

The existing phase-2 runner discovers `tools/test_*.gd`, including the qi acceptance test. Open the atlas's **Qi · log density** toggle and element selector; inspect outlets, ley lines, the Heavenly Origin, and the hover text. Open **The valley → Qi** in the valley book for local samples and supply/use accounting.
