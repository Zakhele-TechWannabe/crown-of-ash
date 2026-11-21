# The Dao's Laws: one rulebook for cultivation and martial techniques

## 1. Authority and design decision

The owner’s cultivation design, especially section 21, governs this rulebook. The adopted qi field remains the environmental foundation. Its earlier absorption formula, flat intake caps and proposed progression costs are replaced here. The earlier Palace weapon multipliers are also replaced.

There are two engines:

- **Cultivation executes an algorithm through a person’s spiritual anatomy.**
- **Martial combat executes an algorithm through a person’s body, spiritual anatomy and equipment.**

Both use the same resources, channels, pressure, control, damage and recovery rules. A manual supplies instructions; it never supplies a hidden power multiplier.

All numerical constants below are proposed starting values. They define a concrete experiment, not a claim that balance has already been established.

## 2. The laws every system obeys

| Law | Consequence |
|---|---|
| Energy requires a source | Absorption withdraws environmental qi. Reinforcement withdraws personal qi. Formations withdraw supplied or stored qi. |
| Every transfer has a path | An unopened channel cannot deliver qi to a hand, leg, weapon or dantian. |
| Throughput and storage are different | A large reserve cannot pass instantly through a narrow wrist channel. |
| Pressure moves qi | Conductivity, direction, gates and pressure differences determine actual movement. |
| Work has a cost | Refinement, conversion, compression, reinforcement and permanent development consume energy or time. |
| Material foundations matter | Attributes, tempering grades, nutrition, injuries and equipment constrain execution. |
| Control is finite | More simultaneous branches, tighter timing and unfamiliar operations increase execution error. |
| Damage follows exposure | Overpressure, unstable mixtures and physical overload cause injury through shared rules. |
| Development follows actual practice | Only the channels and tissues successfully exercised adapt. |
| Knowledge is situated | A successful method on one body is evidence, not universal truth. |
| Heaven changes conditions | Bestowal grants instructions. It does not open channels, fill reserves or guarantee survival. |
| Time has one authority | Rendering, call frequency and fast-forward never change authoritative outcomes. |

Jing is the material foundation: body, food, recovery and structural integrity. Qi is conserved spiritual energy. Shen is awareness and control, drawing on comprehension, willpower, emotion and practical learning.

They are not interchangeable currencies.

## 3. Units and energy accounting

Use QU for qi quantity. Store energy as integer thousandths of a QU, with 64-bit totals and saved arithmetic remainders.

Display cultivation throughput in QU/hour. Internally use QU/second so combat and cultivation share the same channel capacities.

```text
1 QU = 1,000 energy quanta
1 QU/second = 3,600 QU/hour

opening stored energy + external supply
  = closing stored energy
  + energy transferred outside the accounting boundary
  + dissipated energy
  + energy committed to irreversible work
```

Transfers between field, body nodes, dantian and weapon buffers cancel when considering the whole system. They are not additional production.

Permanent development records completed work and structural change. It is not an energy reservoir that can later be spent in combat.

Physical exertion uses stamina supported by food and recovery. Qi can assist exertion, but neither stamina nor qi regenerates merely because a combat function was called.

### Qi composition and qualities

Every storage compartment carries:

- Five elemental masses: Metal, Wood, Water, Fire and Earth.
- Purity, polarity, stability and corruption.
- Quantity and effective volume, from which concentration and pressure are derived.

Qualities mix using energy-weighted moments. Store those moments rather than repeatedly averaging rounded display values.

Purity measures refinable fraction. Corruption measures harmful contamination; it is independent of purity and yin–yang polarity.

Wind, Thunder, Ice, Light and Shadow remain derived affinities and technique behaviours. Preserve the existing ten root positions.

```text
Wind affinity:   60% Wood + 40% Water
Thunder:         50% Wood + 50% Fire
Ice:             Water, yin preference
Light:           Fire, yang preference
Shadow:          Water, yin preference
```

Ice and Shadow can share environmental preferences while using different operations.

## 4. The adopted qi field

The field follows section 1 of the earlier research.

| Property | Rule |
|---|---|
| Atlas | 360 × 240 cells |
| Ground mapping | 16 × 16 ground tiles per atlas cell |
| Ambient volume | 2,000 standard volumes per atlas cell |
| Cell mass | `2,000 × density` QU |
| Background recovery | Restore 1% of each elemental deficit per day |
| Excess dispersion | Remove 0.5% of above-background excess per day |
| World diffusion | None initially |
| Sources | Seeded vein graphs with finite reserves and limited outlets |

Background recovery is an explicit world source. Dispersion is an explicit ledger outflow.

### Terrain background

| Terrain | Density | Main character |
|---|---:|---|
| Deep sea / shallow sea | 0.5 / 0.7 | Water |
| Lake | 1.2 | Water, mildly yin |
| Sand shore | 0.5 | Earth/Water |
| Grassland / steppe | 1.0 / 0.7 | Wood/Earth |
| Forest / bamboo | 1.3 / 1.6 | Wood |
| Spirit forest | 3.0 | Wood, high purity |
| Desert | 0.25 | Earth/Fire, yang |
| Marsh | 1.2 | Water/Wood, yin |
| Highlands | 1.2 | Earth/Metal |
| Bare rock | 0.6 | Metal/Earth |
| Snow peaks / tundra | 0.6 / 0.4 | Water/Metal |
| Frozen sea | 0.4 | Water, yin |

Start elemental weights at one each. Add the adopted terrain weights, then normalise:

```text
forest/bamboo: Wood +5
lake/river/marsh: Water +5
highlands: Earth +3, Metal +2
bare rock: Metal +4, Earth +2
desert: Earth +3, Fire +3
snow/ice: Water +4, Metal +2
```

Mountains favour vein placement and retention. They do not automatically contain abundant qi.

### Veins

| Grade | Output QU/day | Reserve QU | Outlet density bonus |
|---|---:|---:|---:|
| Faint | 20 | 7,300 | +1 |
| Lesser | 80 | 29,200 | +2 |
| Established | 320 | 116,800 | +4 |
| Superior | 1,280 | 467,200 | +8 |
| Great | 5,120 | 1,868,800 | +16 |
| Peerless | 20,480 | 7,475,200 | +64 |

Healthy regeneration equals rated daily output, bounded by reserve capacity. Emergency extraction up to twice rated output drains reserves. Upstream taps reduce downstream availability.

```text
available = min(reserve_capacity, reserve + regeneration)
emission = min(request, outlet_limit, available)
reserve_next = available - emission

outlet_weight(distance_in_atlas_cells) = max(0, 1 - distance/2)^2
target_density = background + bonus × outlet_weight
```

Distribute emission among underfilled receiving cells using normalised weights. Do not duplicate an outlet’s output across its footprint.

The Palace receives its unique balanced Heavenly Origin at the resolved estate anchor, with grade-6 output, perfect source purity and indestructible source integrity. Its throughput remains finite. Resolve the sect spring and hunting branches from their actual locations; generate approximately 48 additional veins.

Small chambers carve volume and mass out of their parent cell. They do not overlay duplicate ambient inventories. Palace density targets of 64 across the estate and 128/256 in regulated practice spaces require actual supply and finite chamber volumes.

The field’s earlier root-speed absorption formula and realm-based intake caps are retired. Density provides pressure and available energy; the body determines admission.

### Heavenly Dao decrees

The Dao may open, throttle (75%, 50%, or 25%), or seal a vein node or a region of atlas cells. Vein decrees scale ambient emission; withheld qi remains in the finite, regenerating reserve. Direct outlet requests with `tap = true` can still withdraw that reserve. They share by priority and proportional elemental demand, and record consumer, day, quantity, and node in a bounded theft log. Region decrees scale ambient consumer demands; reserves and other stores are unaffected.

`set_decree(target, level)` accepts a node index/name or `{id, cells}` region and a level of 1, .75, .5, .25, or 0. `decrees()` and `thefts()` return copies. Decrees, payment anniversaries, auto-pay preference, and theft records persist in saves. Payment is due every 365 days after enactment, using the existing Fifty Heaven's Will account and dated annual income. Unpaid decrees reopen with a dated story note. Seals cost Faint/Lesser/Established/Superior/Great 1/2/4/8/16 Will yearly; Peerless and Heavenly Origin cost zero; regions cost 3. Throttles cost half. Authoritative costs and the theft-log bound live in `data/qi/decrees.json`.

At world formation, geological source regeneration explicitly pays for the initial ambient footprints and replenishes reserves before play begins. That endowment is separate from today's operating flows. Taps appear separately from ambient emission in the conservation ledger.

## 5. Spiritual anatomy

### First production graph

Use a shared human anatomical template with **16 nodes and approximately 24 edges**. Individual state makes each person’s effective graph different.

| Nodes | Purpose |
|---|---|
| Breath gate, left/right palm gates, left/right sole gates | Environmental interfaces |
| Lower dantian | Refined storage |
| Abdominal junction, lumbar junction, chest junction | Core circulation and refinement sites |
| Left/right shoulder junctions | Arm distribution |
| Left/right hip junctions | Leg distribution |
| Head gate | Sensing and control practice |
| Middle and upper centres | Visible, dormant future structures |

Edges connect interfaces, torso junctions, limbs and the lower dantian, including alternative torso and limb-return paths.

The middle and upper centres are not usable reservoirs during the initial Qi Condensation implementation.

Every person has seeded differences in edge width, conductivity, affinity, obstruction and symmetry. Rare constitutions can add a small number of valid alternate edges. An obstructed or dormant edge remains in the diagram but is absent from usable routes.

Do not generate arbitrary anatomy so disconnected that ordinary cultivation becomes impossible without warning.

### Node and edge state

| Node state | Edge state |
|---|---|
| Elemental inventory and quality moments | Endpoints and allowed directions |
| Effective volume and pressure | Openness |
| Safe pressure and integrity | Safe throughput |
| Local instability | Conductivity |
| Permanent storage development | Integrity and scarring |
| Tissue reinforcement buffer | Affinity and accumulated practice |

Openness, integrity and scarring range from zero to one.

Integrity is recoverable condition. Scarring reduces long-term structural potential. Openness is developed access; it is not a substitute for either.

### Body Tempering seeds the graph

Preserve all nine permanent grades:

1. Copper Skin.
2. Dense Flesh.
3. Steel Sinew.
4. Iron Bone.
5. Jade Marrow.
6. Living Blood.
7. Five Viscera.
8. Open Meridians.
9. Perfected Body.

Use weighted grades for each anatomical region instead of averaging the whole body into every channel.

```text
g_region = weighted mean of relevant forged grades / 3

C_seed(edge) =
    0.020 × anatomical_width
          × individual_width
          × (0.70 + 0.60 × g_region) QU/second

G_seed(edge) =
    0.010 × anatomical_conductivity
          × individual_conductivity
          × (0.80 + 0.40 × g_region) QU/(second·pressure)

individual_width, individual_conductivity: seeded 0.75–1.25
ordinary anatomical_width: 0.7–1.4

safe_pressure_seed = 1.0 + 0.5 × g_region
```

For otherwise identical channels, an all-Perfect foundation starts with approximately 1.86 times the throughput of an all-Low foundation.

Skin chiefly supports interface tolerance; sinew and bone support limbs; blood and viscera support core refinement; layers eight and nine strongly influence opening and storage.

Before layer eight, ordinary deliberate meridian circulation is unavailable. Physical tempering remains available to everyone. Living Blood retains its existing hidden-root awakening opportunity.

Layer eight permits controlled circulation preparation. Layer nine permits lower-dantian opening. Completing nine layers qualifies; nine Perfect grades provide a better foundation.

Rootless people retain full physical martial access. Artificial root creation is outside this first rulebook. External medicine or formations may assist their tempering without granting personal qi control.

## 6. Flow, pressure and admission

### One flow law

```text
C_safe =
    C_seed × openness × integrity × (1 - 0.60 × scar)
           × (1 + adaptation)

G =
    G_seed × openness² × integrity
           × (1 - 0.50 × scar)
           × affinity_factor

pressure(node) =
    node_quantity / max(node_volume, minimum_volume)

desired_transfer(edge) =
    G × gate × max(0, pressure_from - pressure_to) × duration

ordinary_transfer_limit = C_safe × duration
forced_transfer_limit   = 2 × C_safe × duration

candidate_transfer =
    min(desired_transfer, selected_transfer_limit)
```

A gate ranges from zero to one. Guidance changes gates, direction and compression; it does not create an unpriced pressure bonus.

For every simultaneous flow slice:

1. Calculate all candidates from the opening state.
2. Scale competing outflows so they cannot exceed source inventory.
3. Scale ordinary inflows to destination safe headroom.
4. Commit all transfers together.
5. Evaluate forced overpressure and damage.

This prevents edge iteration order from moving the same energy repeatedly through a chain in one slice.

Ordinary valves close at the pressure limit. Forced practice may exceed it and accept damage.

### Environmental admission

Treat the environmental interface as an ordinary graph edge. Its external pressure is:

```text
ambient_pressure = density / 8
```

A healthy suction cycle alternates intake, internal transfer and release. It cannot pull into an already full interface node.

For a serial route, sustainable admission is bounded by its narrowest open channel. For branches, it is bounded by the usable network cut and each branch’s capacity. Two branches can share intake; they cannot each claim the entire shared inlet.

Actual admission is also limited by pressure, available elemental mass, downstream storage, refinement and control.

A Palace novice with a narrow chest return does not absorb unlimited qi. Their intake closes when downstream pressure rises.

### Body timescales

An unadapted 0.020 QU/second channel carries at most 72 QU/hour. Four hours at a 40 QU/hour operating target admit at most 160 QU before losses and interruptions.

The same channel can deliver at most 0.012 QU during a 0.6-second combat preparation. A martial burst must therefore begin early, use prepared local buffers or accept a smaller reinforcement.

There is no separate combat throughput exemption.

## 7. The shared operation vocabulary

A manual is a bounded program. It contains sequences, parameters, routes, limited repetitions and branches on observable conditions.

Every operation declares duration, source, destination, control demand, resource cost and abort behaviour.

### Qi operations

| Operation | Meaning and starting cost |
|---|---|
| Absorb | Open an environmental interface; ordinary pressure and allocation apply |
| Guide | Set channel direction and gate |
| Hold | Retain energy at a node; concentration and leakage continue |
| Split / Merge | Allocate branch gates or recombine streams; shared capacities still apply |
| Filter | Remove contaminants and incompatible fractions; loses useful qi and time |
| Convert | One generating-cycle step delivers 0.8 QU per QU transformed |
| Compress | Reduce effective storage volume; spends 5% of handled energy per 25% compression |
| Stabilise | Spend 2% of handled energy and time to reduce instability |
| Integrate | Spend refined energy on a specified developed structure |
| Reinforce | Route and consume qi at a named tissue or weapon endpoint |
| Release | Discharge a bounded packet through an opened terminal route |
| Ground | Safely discharge energy into a declared receiving sink |

Conversion’s 20% loss and compression’s cost enter the ledger. Compression reduces effective volume by at most 50% in early Qi Condensation.

A release can be a harmless vent, a weapon coating or an external projection depending on its terminal geometry. Projection requires a stabilised personal reserve, an opened release route and learned control.

### Physical operations

| Operation | Parameters and consequences |
|---|---|
| Stance | Width, weight distribution, facing; trades stability against movement |
| Step | Direction, distance, acceleration; costs time and stamina |
| Strike | Thrust, cut, chop, sweep, fist, palm or impact; trajectory and commitment |
| Guard | Covered line, duration and commitment; occupies limb or weapon |
| Parry | Interception line and timing; redirects within physical limits |
| Feint | False line and investment; spends time and can provoke a response |
| Aim / Draw / Loose | Bow preparation, draw fraction, hold and release |
| Recover | Return balance, weapon and breath to a usable state |
| Wait | Timing window and observable trigger |

Reach is derived from body, weapon, grip and posture. A manual can change grip or extension; it cannot declare arbitrary reach.

Timing controls overlap only when body resources permit it. One hand cannot simultaneously perform incompatible guards, attacks and bow draws.

### Program limits

Initially permit at most 32 operations, four concurrent lanes and eight bounded repetitions per execution. Longer cultivation sessions repeat a compiled cycle.

Missing or illegal instructions produce a diagnostic or an incomplete attempt. They never fall back to a generous default.

## 8. Refinement, storage and permanent development

### Refinement is a process

Filtering, conversion, stabilisation and settling occur at anatomically suitable nodes. A manual chooses their order.

```text
Filter intensity f: 0–1

retained_quantity = input_quantity × (1 - 0.15 × f)
purity_next = purity + 0.60 × f × (1 - purity)
corruption_next = corruption × (1 - 0.70 × f)

stabilisation:
    retained_quantity *= 0.98
    instability_next = instability × 0.60
```

These are transformations with losses, not free quality adjustments. Filtering has a processing throughput of 70% of that node’s safe connected throughput, making additional filtering slower.

An unstabilised overcoming mixture contributes up to 0.20 local instability at equal opposing proportions. Stabilisation can reduce interference, but costs time and energy. It does not delete an element without accounting for it.

Root affinities change conductivity and refinement difficulty rather than multiplying all intake:

```text
affinity_factor =
    clamp(0.65 + 0.50 × compatibility, 0.65, 1.15)

compatibility: 0–1 from roots, node affinity and mixture
```

Root purity affects controllable separation and retained purity. Comprehension affects learning and interpretation, rather than directly multiplying every QU gained.

### Lower dantian

The lower dantian stores only successfully settled energy. Raw qi can pass through a developing abdominal reservoir but cannot masquerade as refined reserve.

```text
usable_storage =
    developed_volume × safe_pressure
    × integrity × (1 - 0.60 × scar)

daily_storage_loss =
    reserve × 0.002 × (1 - storage_stability)
```

A candidate’s first developed lower-dantian capacity is approximately 100 QU. It grows through paid integration, not through receiving a layer number.

If full, the manual must consume energy in development, stop intake or ground surplus. It cannot credit both reserve and permanent work.

```text
settled input =
    reserve increase
    + integration expenditure
    + subsequent losses
```

### Adaptation and integration

Safe flow produces use evidence. Permanent enlargement additionally requires nutrition, recovery and integration energy.

```text
u = actual_flow / C_safe

training_stimulus =
    clamp((u - 0.25)/0.35, 0, 1)
    × clamp((1.05 - u)/0.25, 0, 1)

edge_adaptation_gain/day =
    0.001 × training_stimulus
          × recovery
          × min(1, assigned_integration_QU/2)
          × (1 - adaptation/adaptation_ceiling)

initial adaptation_ceiling = 2.0
```

An edge can eventually reach three times its seeded throughput through this adaptation term. Wider opportunities require later structural transformations.

Flow below useful loading teaches control but yields little enlargement. Repeated overload injures rather than automatically accelerating growth.

**Owner decision 2026-11-16 — a vessel is tempered only when it is filled.** Measure `fill = (reserve + residue) / capacity` at the day's peak pressure point. The enlargement factor is `g = clamp((fill - 0.60) / 0.30, 0, 1)`. Daily addition is bounded by `g × 0.5% × capacity` and costs 20 QU of integration work per additional QU of uncompressed storage capacity. Below 60% fill there is no enlargement; at or above 90% the full existing rate is available. Integration qi allocated to enlargement but blocked by this gate stays in reserve, unspent and with its qualities retained. The daily reserve integration assignment is subject to the fill-first floor below. Scarring and constitution constrain the ceiling.

**Owner decision 2026-11-17 — fill first.** Set `F = 0.70`. Daily
reserve integration assigns `floor(0.50 × max(0, reserve - ceil(F × capacity)))`
integer quanta. The protected reserve does not fund integration; residue does
not substitute for that reserve floor. The existing fill-gated enlargement can
withhold more of this assignment, never spend the protected reserve. Apply the
same rule in reference and production practice. Mortals and non-practitioners
have no reserve integration and are unaffected. Enlargement rates, costs,
pressure/flow laws and certification thresholds remain unchanged.

Overfill beyond safe pressure still injures under section 6. Pressure, gates, conductance, certification thresholds, edge adaptation, purity and residue laws are unchanged.

**Owner decision 2026-11-19 — guided circulation.** Ambient pressure alone can never fill the dantian past the surrounding qi, and refined return qi always sits below a full dantian, so no circuit could form (Stage 3c measurements). The new `Circulate` operation lets the cultivator use the dantian as a pump:

```text
head = h × p(dantian)            h = 2.8   (data/cultivation/operations.json)
lane flow = min(capacity, conductance × gate × max(0, Δp + head))
```

- Every Circulate lane gains the head, so qi climbs back into a fuller dantian. A fuller dantian pumps harder: the circuit opens with fill.
- Lanes leaving the dantian withdraw stored reserve as mobile qi. Reserve and its quality moments are debited atomically and never double-counted; residue never moves. Qi that returns keeps the reserve's own quality; only refinement losses on the way are dissipated.
- Climbing against adverse pressure strains the channel: `edge strain += 0.0005 × adverse Δp × QU moved`. Overpressure, headroom, gates, conductance, capacity and safety stops are unchanged.
- Calibration (reference solver, Returning River): the layer-2 circuit (30 QU/hour) opens at 65% fill for a Perfect foundation, 85% for an average one, and never at safe fill for a poor one without improvement.
- Manuals are revision 3: the old serial return Guide becomes a Circulate ring (Still Basin `[0,1,2,5,6,7,8]`, Returning River `[0,3,4,5,6,7,8]`, 80 s per cycle). Still Basin's narrow chest–abdominal channel caps its circuit below 30 QU/hour on the fixture bodies; it remains the gentler village manual.
- Practice only runs while ambient intake is funded, so a cultivator in a qi-dead place cannot circulate (known simplification).

These limits make time, foundation and route choice consequential even at the Palace.

### Qi-assisted tempering

Keep existing physical drills, labour limits, medicine gates, polishing and permanent grades.

Replace unconditional root-based progress speed with assistance paid from actual routed qi:

```text
tempering =
    physical_progress
    + drill_progress × 0.30 × min(1, qi_spent_on_tempering/10)
```

The supplement needs actual drills and recovery. It cannot exceed 30% of drill progress. Before deliberate circulation, guided medicine or formations can supply the local tissue treatment.

Rich environments support safe access and recovery. They do not automatically grant permanent muscle or Perfect grades.

## 9. Nine Qi Condensation layers

Use **nine layers for everyone**.

Nine supports nine distinct capabilities: retention, return circulation, condensation, distribution, sustained output, purification, coordination, discharge control and complete integration. Thirteen would currently divide the same changes into additional throughput or storage increments without four additional mechanics.

There is no innate nine-versus-thirteen cap.

A layer is a certified internal achievement. It grants no automatic combat multiplier or reserve refill. Spending reserve does not remove it. Serious structural injury can disable its associated capability and must be shown separately.

All certifications require a completed Body Tempering foundation, an awakened root, no critical injuries and stable execution. The stated throughput is measured on the qualifying circuit, not the sum of every edge.

| Layer | Achievement | Concrete certification |
|---|---|---|
| 1 | Open lower dantian | Retain 100 QU capacity; complete 500 QU opening work; 30 valid settling days |
| 2 | Establish return circulation | One complete inlet–refinement–dantian–return circuit sustains 30 QU/hour for 30 practice days |
| 3 | Stabilise condensation | Store at 1.5 pressure; purity ≥0.75; instability ≤0.10 through ten controlled fill–draw cycles |
| 4 | Distribute through the body | Both arms and both legs have usable routes; deliver 0.02 QU to each terminal in separate tests without injury |
| 5 | Sustain output | Qualifying circuit sustains 90 QU/hour for one hour; capacity ≥400 QU; repeat on 30 days |
| 6 | Refine difficult qi | Convert/filter a declared mixed source to purity ≥0.90, corruption ≤0.02; account for at least 1,000 QU processed |
| 7 | Coordinate circuits | Two useful branches operate simultaneously, each delivering ≥25 QU/hour; control error ≤0.08 for 30 days |
| 8 | Control discharge | Deliver and recover from ten 0.10-QU release tests; ≥70% controlled delivery at one tile; no overpressure |
| 9 | Complete the realm | Capacity ≥1,000 QU; core circuit ≥150 QU/hour; 90 valid integrated practice days with all earlier functions intact |

A valid practice day means at least two hours of the relevant work, with minimum relevant integrity 0.85 and no injury-producing overload.

The release operation becomes possible at layer 1 when its physical prerequisites exist. Layer 8 certifies reliable substantial discharge; it is not an arbitrary spell unlock.

The table describes minimum evidence. It does not prescribe one route or one elemental school. Different anatomies can achieve the same performance through different circuits.

Foundation Establishment remains a separate future transformation. The old random realm breakthrough ladder must not continue silently above this redesign.

## 10. Deviation, scarring and death

Deviation emerges from failed flow and control.

```text
overload = max(0, actual_flow/C_safe - 1)
overpressure = max(0, node_pressure/safe_pressure - 1)

danger =
    overload²
    + overpressure²
    + corruption × exposure
    + max(0, local_instability - 0.20)²
    + control_error² × forced_commitment
    + (residue / capacity)²  # lower dantian, while residue remains lodged

strain_next =
    max(0, strain + danger × exposure_hours - recovery)

integrity_loss =
    0.02 × max(0, strain - 0.50) × exposure_hours

scar_gain =
    0.10 × max(0, integrity_loss - 0.01)
```

Exposure hours are actual exposure, not the entire day around a short session. Integrate dangerous changes on fixed short slices so stopping after a pressure spike matters.

Control error alone in an ordinary regulated method usually reduces output or triggers a stop. It becomes damaging when combined with unsafe pressure, contamination or a forced instruction.

### Impurity — owner decision 14 Nov 2026

Only the pure fraction of settled qi performs permanent work. Every opening,
volume, edge or reserve integration expenditure partitions its quantity into
`quantity × purity` work and an impure remainder lodged in the lower dantian as
integer `residue`. A saved arithmetic remainder prevents repeated rounding loss.
Residue is a conserved inventory, occupies dantian volume, raises pressure and
reduces admission and reserve headroom. It cannot be spent again as work.

Residue purges into dissipated energy at `residue_purge_per_day = 0.01`, with a
saved remainder. A treatment multiplier defaults to one; later pills and
seclusion may accelerate this explicitly funded treatment. During actual
exposure, add `(residue / capacity)²` to dantian danger. Lodged residue remains
in living tissue between sessions, so this term also applies during those
hours; with no transfers its constant danger is integrated analytically. Existing strain,
recovery, integrity, injury and death rules apply without random rolls.

Layer 1 cannot certify while `residue / capacity > residue_wall = 0.10`;
once opening work and settling-day requirements are complete, dates above the
wall count as wall days (recovery may also prevent certification). Layers 3 and 6 retain their
purity walls of 0.75 and 0.90. Meeting a purity check alone does not certify a
layer's other required tests.

Martial techniques draw reserve with purity squared efficiency:
`technique power = reserve × purity²`. Impurity leaks on projection and must
enter the future martial engine's outflow ledger; the cultivation lab reports
potential power without executing or charging a projection.

Autonomous experiments value permanent work gained, subtract residue added
weighted by personality fear, and subtract current strain. Greed can accept
contamination and recovery costs; low filtering is never free development.

### Safety behaviour

Ordinary manuals can specify:

```text
close intake at 90% safe pressure
reduce flow above strain 0.20
abort above strain 0.35
ground through the declared safe route
```

A blocked grounding route is a real failure. A recorded safety instruction is not a magical escape.

| Condition | Consequence |
|---|---|
| Strain 0.20–0.50 | Fatigue, stop or reduce practice |
| Integrity below 0.80 | Inflammation, reduced throughput, recovery requirement |
| Integrity below 0.50 | Serious injury and foundation damage |
| Rupture in a core node or vital route | Internal harm and possible death |
| Dantian pressure above twice safe pressure | Rapid rupture exposure; immediate emergency |

Ruptures add bodily harm through the same injury/death authority used by combat. Death is recorded once. Severe wounds can also kill later if untreated.

Recovery restores integrity slowly and requires rest and nourishment. Scarring does not vanish through ordinary rest. Treatment can reduce some scars at explicit material, time and qi cost.

**Careful-practice acceptance target:** under ordinary stable conditions, regulated manuals should produce fewer than one cultivation death per 10,000 practitioner-years, and preferably none in the baseline fixture. This is a later validation target, not an asserted measured rate.

Combat, beasts and age remain lethal. Apostle restoration is a separately funded intervention after death, preserving its existing delay and resource requirements.

## 11. Martial techniques obey the same body

### Physical foundation

Use the existing attributes in their stored order:

Strength, endurance, agility, dexterity, perception, intellect, willpower and charisma.

Strength supplies force; endurance supplies sustained effort; agility supplies movement; dexterity supplies alignment; perception supplies reading and reaction. Intellect supports analysis, willpower supports control and adherence, charisma supports teaching.

Retain the current body contribution as the initial physical calibration:

```text
body_factor =
    1 + body_layers × 0.6 × (0.8 + 0.1 × mean_forged_grade)

physical_power =
    10 × (0.5 + strength/20) × body_factor

physical_guard =
    10 × (0.5 + endurance/20) × body_factor

physical_speed =
    5 × (0.6 + agility/25) × (1 + 0.07 × body_layers)
```

Keep age, wounds and exhaustion effects. Replace broad “best martial skill” bonuses with proficiency in the actual operation and equipped weapon.

A skilled trapper does not receive expert sword execution.

### Weapon properties

These are starting game values in ground-tile combat units, not historical measurements.

| Equipment | Reach | Mass index | Edge | Main constraint |
|---|---:|---:|---:|---|
| Fist/palm | 0.8 | 0.2 | 0 | Limb exposure against weapons |
| Jian | 1.8 | 1.0 | 0.8 | Alignment and recovery |
| Spear | 2.8 | 1.5 | 0.9 point | Crowding and turn radius |
| Staff | 2.6 | 1.4 | 0 | Blunt transfer and leverage |
| Saber | 1.7 | 1.3 | 1.0 | Committed cutting recovery |
| Bow | 12 useful range | 1.0 | Arrow-specific | Draw strength, time, ammunition and clear line |

Also store balance, stiffness, durability, minimum comfortable distance and qi conductivity. A wooden staff and metal spearhead need different terminal routing.

### Effort and timing

Each attack chooses commitment `e` from 0.3 to 1.0.

```text
preparation_seconds =
    base_operation_time
    × (1 + 0.25 × weapon_mass)
    / sqrt(physical_speed/5)
    × (1 + 0.30 × execution_error)

recovery_seconds =
    base_recovery × (0.5 + commitment)
    × (1 + 0.35 × weapon_mass)

attack_score =
    physical_power × commitment × alignment
    × leverage × execution_quality
    + delivered_qi_harm

stamina_cost =
    2 × commitment² × (1 + weapon_mass)
```

Starting operation times:

| Operation | Preparation | Recovery |
|---|---:|---:|
| Fist/palm | 0.35 s | 0.45 s |
| Thrust | 0.45 s | 0.55 s |
| Cut | 0.60 s | 0.70 s |
| Committed chop | 0.85 s | 1.00 s |
| Sweep | 0.75 s | 0.90 s |
| Bow draw | 1.50 s | 0.60 s to reset |

Feints spend at least 0.25 seconds and 20% of the corresponding stamina cost. Recovering, turning and changing grip consume time.

A broad stance gives greater resistance to displacement while reducing step acceleration. Extended reach increases recovery and exposes the forward limb. These are operation consequences, not path bonuses.

### Qi reinforcement

Qi reinforcement must reach the relevant endpoint before the action resolves.

```text
delivered =
    actual terminal qi available and consumed during action

useful_qi =
    delivered × purity² × stability × compatibility × execution_quality

reinforcement_harm =
    min(1,000 × useful_qi,
        physical_power × tissue_reinforcement_tolerance)
```

Start tissue reinforcement tolerance at 0.5 for an ordinary completed body and 1.0 for a Perfect foundation. Exceeding it creates local overload rather than free damage.

Defensive reinforcement similarly adds a paid interception budget: 1,000 harm-score units per useful QU, constrained by the guarded tissue and route.

These are combat score conversions, not joules. The same qi cannot reinforce attack, guard and footwork simultaneously unless it is divided among them.

Local buffers allow preparation. A hand may hold 0.05 QU initially, but retaining it creates pressure, leakage and instability. Loading that buffer through a narrow wrist takes time.

A practitioner with an empty reserve receives no realm-based qi power or speed. A Perfect body can defeat an inexperienced Qi Condensation practitioner who cannot deliver reinforcement reliably.

### Projection

```text
controlled_packet =
    released_QU × purity² × stability × execution_quality

delivered_packet_at_distance =
    controlled_packet × exp(-distance / coherence_length)

initial coherence_length =
    1 + 4 × release_mastery tiles
```

Under the owner decision of 14 Nov 2026, impurity leaks on projection; the
portion lost to purity squared efficiency enters the dissipation ledger.
Projection costs the released packet whether it hits or misses. It has preparation, direction, travel and interception. Broad projection divides energy over a larger target area.

Weapon coatings are short-range terminal reinforcement. They are not simultaneously free projectiles.

## 12. Reach, tempo and guard produce counters

Combat maintains separation, facing, balance, active guards, committed actions and recoveries. Step events change separation; attacks only resolve if their trajectories can reach.

```text
hit_probability =
    clamp(attack_accuracy /
          (attack_accuracy + effective_defence), 0.05, 0.95)

harm =
    9 × (attack_score / max(1, effective_guard))^0.8
      × contact_fraction × weapon_harm_profile
```

Use keyed variation for contact and damage, preserving the existing combat’s uncertain exchanges. An out-of-range attack has zero contact, not a minimum hit chance.

A guard covers a line. A thrust can attack another line; a sweep can displace a narrow stance; a parry can redirect a committed thrust; a feint can draw that parry early.

| Situation | Advantage | Counter or cost |
|---|---|---|
| Spear keeps an approaching fist outside reach | First threat and distance control | Close during recovery, deflect or use cover |
| Fist gets inside spear’s comfortable range | Short attack path | Spear retreats, shortens grip or changes to shaft impact |
| Saber commits against a rigid guard | Strong displacement | Miss or angled parry leaves long recovery |
| Jian intercepts a committed attack | Timing and line control | Feint, disengage or attack a second line |
| Bow has distance and a clear lane | Threat before melee contact | Closing, terrain, interruption and ammunition |
| Reinforced guard withstands a burst | Paid protection | Feint to drain reserve or redirect to another region |

These are conditional advantages. No rule says “spear beats fist” regardless of body, timing or terrain.

Archers receive no scripted free opening shot. They draw while opponents move. At a six-tile opening gap, a fast closer may interrupt a 1.5-second draw. Additional shots are possible only if actual time and separation permit them.

### Event-driven resolution

Keep the current event-driven approach. Jump between preparation completion, movement contact, parry windows, projectile arrival, recovery and surrender events.

Resolve truly simultaneous contacts from the same opening state so side zero does not always win exchanges.

Ordinary bouts use the existing 180-second limit. Exhaustion affects movement and execution; escape and yielding remain motive-dependent.

Practice weapons, restraint and stopping rules reduce harm. The current tournament hard stop remains an explicit supervised-bout rule. A live weapon is lethal equipment; “sparring” alone must not make it harmless.

## 13. Manuals, understanding and mastery

### Manual representation

```json
{
  "id": "manual:clear_stream:3",
  "kind": "martial",
  "author": "palace_library",
  "parents": ["manual:clear_stream:2"],
  "laws_version": 1,
  "requirements": {
    "equipment": "jian",
    "optional_qi_route": ["lower", "chest", "right_shoulder", "right_palm"]
  },
  "program": [],
  "safety": {"abort_strain": 0.35},
  "evidence": [],
  "provenance": {"created_day": 0, "observations": []}
}
```

Route references use semantic node and edge IDs. A compiler resolves them against the individual anatomy and reports missing or unsuitable connections.

Manuals are immutable versions. Corrections, fragments and merged works receive new identities.

### Three separate records

| Record | Meaning | How it changes |
|---|---|---|
| Knowledge | Instructions accessible or remembered | Reading, copying, teaching, forgetting and destruction |
| Understanding | Beliefs about why instructions work | Explanation, comparison, observation and failure analysis |
| Mastery | Reliable execution of operations and transitions | Actual practice under relevant conditions |

A reader can accurately copy a technique they cannot execute. A master can execute an old method while misunderstanding why it fails on a different disciple.

Understanding is stored per relevant principle; mastery uses existing detailed skills plus a small transition-familiarity record. Do not build a second universal XP ladder named “manual level.”

```text
execution_error =
    clamp(
      0.25 × (1 - operation_mastery)
      + 0.20 × (1 - relevant_understanding)
      + 0.10 × unfamiliar_transition
      + 0.15 × emotional_disruption
      + 0.10 × fatigue
      - 0.10 × control_capacity,
      0, 0.60
    )
```

Error affects timing, gate precision and alignment. Safe defaults reduce output before producing catastrophic mistakes.

Practising a technique awards skill learning only for actual time. Preserve the existing 2.5 base XP/hour, discipline spillover 0.4, related spillover 0.05 and practice-year gates.

## 14. Characters discover methods through local search

Characters are the optimisers. Their bodies are the experimental environments.

### Cultivators sense danger — owner decision 15 Nov 2026

Cultivators perceive their own residue load, strain trend and recent injuries.
Fear, ambition, pride, curiosity, restlessness and diligence shape their response:
pause, filter more strongly, shorten intake, or seek a purer reachable local
practice cell. Proud or greedy people may ignore warnings. Decisions are keyed
per person/day, recorded with a reason and day, and notable warnings are chronicled
sparingly. A wish for purer qi persists for future Envoy/Dao features; this does
not authorize travel between sites. These are autonomous behaviours, not changes
to section 10: lodged residue still strains resting tissue and purges normally.

### Choosing an experiment

Use existing mind urges, emotions, traits and goals. Do not train or replace the inherited heart network.

```text
parameter_step =
    clamp(0.02 + 0.12×curiosity + 0.10×restlessness
          - 0.08×fear, 0.01, 0.20)

accepted_strain =
    clamp(0.10 + 0.35×ambition + 0.25×pride
          - 0.30×fear, 0.05, 0.60)
```

Patient or diligent traits favour repetitions and small edits. Impulsiveness permits larger edits. Emotional shocks can alter immediate risk appetite.

A typical experiment changes one item:

- One edge or branch ratio.
- One gate or pressure target.
- Filter placement.
- Hold duration.
- Compression or grounding.
- Strike commitment.
- Closing step or guard line.
- Reinforcement timing or destination.
- One conditional transition.

Most experiments are small. Rare insights suggest a more distant candidate; the candidate still runs through the same engine.

### Nature supplies hypotheses

Keep `nature.gd` as the species and sighting authority. Add observation tags rather than letting its scalar insight value directly create complete manuals.

| Observation | Candidate hypothesis |
|---|---|
| Branching roots or streams | Split around a bottleneck |
| River bend | Gradual redirection wastes less control |
| Hawk holding position | Stable stance with minimal movement |
| Snake strike | Longer preparation followed by brief commitment |
| Flexible branch | Yielding parry and return |
| Fire or storm | Conversion, accumulation or timed release |

Environmental observations need their own dated records; the existing species catalogue does not already represent rivers, storms and seasons.

### Learning from failure

```text
belief_update_fraction =
    clamp(0.05 × comprehension
          × (1 + intellect/20)
          × observation_quality, 0.02, 0.35)
```

A failure records where pressure rose, where timing failed and what resources were spent. Comprehension determines how much the character extracts from that evidence.

Characters do not receive the Forge’s omniscient state unless taught or able to sense it. Their estimates may be wrong.

### Individual, multi-objective fitness

Cultivation evaluates:

```text
[usable reserve/hour,
 permanent development/hour,
 retained purity,
 strain,
 resource consumption,
 recovery time]
```

Martial techniques evaluate:

```text
[harm dealt,
 harm received,
 time to effective contact,
 stamina spent,
 qi spent,
 escape reliability,
 injury risk]
```

Keep up to six non-dominated candidates per active researcher. A candidate is dominated only if another is at least as good on every relevant measured objective and better on one.

Personality and life goals choose among the frontier. They do not redefine physical results.

A cautious parent may retain the slower safe method; an ambitious duellist may favour limb throughput; a Water-rooted healer may favour purification. Different scars and weapons produce different optima.

Keep a small validation set of previous conditions and opponents. A method successful against one partner is not immediately declared universally superior.

### Inheritance, mutation, merging and loss

Teaching transfers instructions and evidence, then helps understanding through demonstration. It does not copy mastery.

Mutation creates a new version. Merging splices compatible subroutines and requires new interface checks: pressure, timing, mixture, stance and resource reservations.

Copies can lose steps or annotations. Oral lineages can diverge. Libraries can burn; teachers can die; languages and equipment can disappear.

Historical provenance may remain in the owner’s archive without making the lost instructions available to NPCs.

The Palace contains authored starting solutions. When better methods justify a future world reset, insert the improved versions into the next world’s starting library. No automatic reset occurs during a living campaign.

## 15. The Palace library

All five paths are freely readable. Access does not require aptitude or rank. Advanced execution still requires its physical prerequisites.

Keep the complete Body Tempering method available from arrival, independently of weapon proficiency. Reading a sword manual must not be required for a Perfect skin layer.

Each path has foundation exercises, applied combinations and an integrated inheritance. These are teaching sequences, not fixed power/speed/guard tiers.

### Five authored martial paths

The following compact encodings use the common vocabulary. Times and routes are instructions; actual execution may be slower or weaker.

| Path | Example authored sequence | Why it is excellent | Limitation |
|---|---|---|---|
| **Clear Stream Sword** | Narrow stance → wait for committed line, ≤0.4 s → parry outside → step 0.4 tile diagonally → thrust at commitment 0.55 → recover | Preserves balance and exploits interception | Can be drawn by feints or crowded |
| **Coiling Dragon Pole** | Rooted stance → guard centre → retreat 0.5 tile if crowded → outside parry → thrust 0.65; staff variant uses sweep 0.55 | Maintains useful reach and includes a recovery branch | Needs space and leg endurance |
| **Mountain Root Fist and Palm** | Compact stance → guard high → close 0.8 tile during opponent recovery → palm 0.60 → short fist 0.45 if balance remains → recover | Efficient close sequence with limited commitment | Entry against an active point is dangerous |
| **Returning Goose Bow** | Bow stance → nock → draw to comfortable strength over ≥1.5 s → aim 0.4 s → loose → retreat; switch to compact guard below three tiles | Respects draw strength, timing and pressure | Clear lane, ammunition and escape space |
| **Thunder Saber** | Mobile stance → feint high 0.25 s → step 0.5 tile → diagonal cut 0.75 if guard moves → cover on recovery | Links a real opening to a strong cut | Costly if the opponent refuses the feint |

### Example martial encoding

```yaml
name: Clear Stream — Returning Point
equipment: jian

sequence:
  - stance: {width: 0.35, forward_weight: 0.45}
  - wait: {trigger: incoming_committed_high, timeout_s: 0.4}
  - parry: {line: outside_high, commitment: 0.45}
  - step: {direction: diagonal_outside, distance_tiles: 0.4}
  - parallel:
      - guide:
          route: [lower, abdominal, chest, right_shoulder, right_palm]
          target_QU: 0.02
          mode: safe
      - strike: {type: thrust, line: exposed_centre, commitment: 0.55}
  - reinforce:
      endpoint: weapon_edge
      consume_available_QU: 0.02
      deadline: thrust_contact
  - recover: {guard: centre}

fallback:
  no_qi: execute_physical_sequence
  missed_parry: cover_and_retreat
  blocked_route: stop_qi_branch
```

The optional qi branch only contributes what arrives by contact. A disciple with a weak right shoulder may prefer a physical counter or a different routing variant.

### Breathing and circulation series

| Manual | Program emphasis | Trade-off |
|---|---|---|
| **Still Basin Breathing** | Low-pressure admission, single return, grounding | Slow, simple and safe |
| **Returning River Circulation** | Continuous return with filtering before settlement | Better reserve replenishment, moderate control |
| **Twin Tributaries** | Parallel torso branches around a narrow return | More throughput on suitable anatomy, more coordination |
| **Five Chambers Refinement** | Element selection, generating conversion, staged filtering | High purity at greater loss and time |
| **Deep Basin Condensation** | Stabilise, compress, settle, integrate storage | Dense reserve with stricter pressure control |

These are excellent solutions for their stated purposes. They are not a universal sequence in which each book makes the previous one obsolete.

```yaml
name: Still Basin Breathing
cycle_minutes: 10

sequence:
  - absorb:
      interface: breath_gate
      gate: 0.35
      stop_pressure_fraction: 0.80
  - guide:
      route: [breath_gate, chest, abdominal, lumbar]
      target_QU_hour: 30
      mode: safe
  - filter: {node: abdominal, intensity: 0.5}
  - stabilise: {node: lumbar, duration_s: 30}
  - guide: {route: [lumbar, lower], mode: safe}
  - integrate:
      target: weakest_used_edge
      QU: 2
      only_if: reserve_above_50_percent
  - ground:
      route: [lumbar, left_hip, left_sole]
      condition: pressure_above_90_percent

safety:
  reduce_flow_strain: 0.20
  abort_strain: 0.35
```

```yaml
name: Twin Tributaries
sequence:
  - absorb: {interface: breath_gate, mode: safe}
  - split:
      node: chest
      branches:
        - {route: [chest, abdominal, lower], share: 0.45}
        - {route: [chest, lumbar, lower], share: 0.55}
  - filter: {node: abdominal, intensity: 0.35}
  - stabilise: {node: lumbar, duration_s: 20}
  - merge: {node: lower, require_instability_below: 0.15}
  - integrate: {target: used_core_edges, QU: 4}

safety:
  abort_if_branch_pressure_difference_above: 0.50
  abort_strain: 0.35
```

The second route may outperform the first on a body with a narrow abdominal return and strong lumbar branch. It may be worse on someone with lumbar scarring or poor branch control.

## 16. The Dao’s Forge

The Forge is a workbench for the Heavenly Dao.

### Player flow

1. Select a living envoy.
2. Select cultivation or martial composition.
3. Choose a library starting point or an empty program.
4. Connect routes and arrange operations.
5. Inspect the prediction on that envoy’s present body.
6. Compare variants and simulated opponents.
7. Bestow the selected version as a manual.

The envoy retains autonomy over practice. Bestowal grants accurate instructions and a recorded origin, not immediate understanding or mastery.

### Controls

| Control | Player-facing meaning |
|---|---|
| Route drawing | Choose actual channels on the body |
| Flow slider | Requested QU/hour; mark the safe bottleneck |
| Gate and branch sliders | Divide admission and internal flow |
| Pressure slider | Storage concentration and compression |
| Filter/stabilise cards | Quality gained, time spent and energy lost |
| Sequence timeline | Preparation, simultaneous actions and recovery |
| Footwork controls | Distance, direction and timing |
| Attack controls | Type, line and commitment |
| Guard controls | Covered line and duration |
| Reinforcement controls | Source, route, endpoint, amount and deadline |
| Safety controls | Throttle, abort and grounding conditions |

The interface exposes equations as readable substitutions:

```text
Right shoulder capacity:
72 × 0.85 openness × 0.92 integrity × 0.94 scar factor
   × 1.20 adaptation
= 63.5 QU/hour

Requested route: 80 QU/hour
Bottleneck: right shoulder, 63.5 QU/hour
Safe execution: throttled
Forced execution: 26% overload
```

Prediction separates requested, physically feasible and likely executed performance.

### Result panel

Show:

- Environmental withdrawal and refined delivery.
- Reserve gain and permanent work separately.
- Bottleneck and unused parallel capacity.
- Peak pressure, strain and likely recovery.
- Operation timing and reinforcement arriving too late.
- Stamina and qi consumption.
- Purity and losses.
- Differences from the currently used manual.

For combat, compare against four explicit references:

| Reference | Purpose |
|---|---|
| Perfect Body Tempering close fighter | Tests reliance on qi against superior physical foundation |
| Ordinary spear practitioner | Tests reach and entry |
| Defensive sword practitioner | Tests feint, timing and recovery |
| Same-tier qi practitioner with different limb development | Tests routing and endurance |

Use current equipment, opening distance and terrain as visible inputs. Run eight fixed seeds per reference initially. Display wins, draws, average harm and reserve spent; eight trials do not establish a precise population win probability.

Predictions use a copy of state. They consume no world qi, award no learning and inflict no real injuries. NPC experimentation remains a real activity with real consequences.

Recalculate after relevant body, equipment, environment or laws-version changes.

### Heaven’s Will

```text
bestowal_cost =
    2
    + ceil(operation_count / 8)
    + number_of_distinct_qi_routes
    + 2 if the program includes projection
```

A 12-operation technique with one route costs five Will. A 20-operation, two-route projection manual costs nine.

Previewing is free. Bestowal debits the existing Will account atomically and creates the manual copy once. Failed validation does not charge.

This competes with the existing 30-Will Apostle restoration cost and six-Will annual income. Ordinary copying and teaching need time and materials, not additional divine Will.

## 17. Body diagram data contract

The diagram reads authoritative state. It does not calculate a second version of cultivation.

### Static anatomy definition

```text
AnatomyDefinition
  schema_version
  species_id
  nodes[]:
    id, kind, body_region, diagram_position
    volume_seed, safe_pressure_seed, terminal_capabilities
  edges[]:
    id, from_id, to_id, permitted_directions
    diagram_polyline
    seed_width, seed_conductivity, affinity[5]
    relevant_tempering_weights[9]
```

### Person state

```text
AnatomyState
  person_id, day, anatomy_revision, laws_version
  nodes[]:
    elemental_quanta[5]
    purity_moment, polarity_moment, stability_moment, corruption_moment
    developed_volume, integrity, scar, instability
  edges[]:
    openness, adaptation, integrity, scar
    opening_work, integration_work, practice_evidence
  reserve:
    usable_quanta, usable_capacity, storage_stability
  progression:
    certified_layer, disabled_capabilities[], milestone_evidence[]
```

### Execution and prediction overlay

```text
ExecutionReport
  manual_id, execution_id, start_time, duration
  prescribed_routes[]
  actual_transfers[]:
    edge_id, requested, delivered, peak_rate, peak_pressure
    strain_added, loss, failure_reason
  operations[]:
    requested_start, actual_start, outcome
  bottlenecks[]
  energy_ledger
  injuries[], development_changes[], milestone_changes[]
```

Forge predictions use the same report shape with `predicted=true` and a source-state revision.

### Visual meaning

| Visual | State |
|---|---|
| Grey channel | Dormant or closed |
| Cyan pulse | Stable actual flow |
| Gold pulse | Refined flow |
| Element colours | Composition |
| Orange glow | Pressure or strain approaching limits |
| Red fracture | Integrity damage |
| Dark segment | Obstruction or scarring |
| Dashed route | Manual prescription |
| Solid route | Actual execution |

Use the parchment body illustration with selectable anatomy, circulation, manual, development and history modes. No reference image is required.

Only the selected person receives detailed animation. Pulses interpolate recorded transfers; they do not simulate individual qi particles.

## 18. Determinism and shared allocation

### One dated coordinator

Advancing from day 100 to day 130 executes the same authoritative dates as thirty daily calls.

```text
for each crossed day:
    apply dated arrivals, deaths, expiries and location changes
    regenerate sources and update field recovery
    execute scheduled resource phases:
        gather requests from the same opening snapshot
        allocate shared source and elemental budgets
        execute sessions and encounters at their scheduled times
        commit transfers, losses, damage and development
    certify completed milestones
    apply recovery and dated social decisions
    save daily ledger and bounded summaries
```

Events within a day use fixed timestamps and phase boundaries. A noon fight cannot consume tomorrow’s reserve, and an evening arrival cannot cultivate at that morning’s location.

Mind decisions schedule practice; they do not directly call a three-day cultivation credit. Visibility and walker positions never determine attendance or absorption.

### Order-independent qi allocation

For each source, priority and elemental component:

```text
allocation_i =
    request_i × min(1, available / sum(requests))
```

Round with integer arithmetic. Assign remaining quanta using largest fractional remainders, with ties broken by a stable hash of date, source and consumer ID.

Mixed-element operations declare whether inputs are substitutes or a required recipe. Required ratios use progressive allocation: scale the complete bundle by its scarcest component, then redistribute unused allocations. A consumer cannot remove unusable excess and still claim unmet demand.

Admission requests are bounded by the compiled route’s feasible intake and downstream headroom. If a state change reduces use, return the unused reservation before final settlement.

Reserve energy once. Settlement withdraws actual use once. Reordering the population array or request insertion must leave allocations unchanged.

### Numerical execution

Use fixed flow slices for transient operations: initially ten seconds during active cultivation and fixed timestamped action boundaries in combat. Dangerous pressure transitions subdivide on a globally defined one-second grid.

For safe repeating cycles, compile a conservative transfer operator and batch repetitions only while state, gates and limits remain unchanged. Stop batching at depletion, fullness, injury, adaptation or milestone boundaries.

Batching is an optimisation of the reference solver. It cannot replace it with a different daily-average law.

Use keyed random values:

```text
random_key =
    world_seed, subsystem, stable_entity_or_encounter_id,
    absolute_event_time, attempt_id, draw_slot
```

Save attempts and residual arithmetic. Do not use process-dependent string hashes or shared RNG consumption order as the identity contract.

The existing society, tempering, mind and Fifty scheduling also need auditing. Making the qi subsystem invariant does not make invocation-based legacy systems invariant automatically.

## 19. Low-RAM operation for approximately 250 people

Use records and packed arrays, not a scene node per channel.

| Component | Proposed bound |
|---|---|
| Human anatomy | 16 nodes, approximately 24 edges/person |
| Ambient field | Packed 360 × 240 storage; active-cell daily processing |
| Manuals | Shared immutable programs; maximum 32 operations |
| Research frontier | Six candidates per active researcher |
| Recent experiment details | Eight/person; older records summarised |
| Forge sparring | One reference batch at a time |
| Detailed diagram | One selected person |
| Qi field incremental memory | Approximately 12 MiB target |
| Anatomy, compiled programs and bounded working records | Under 8 MiB target |

Five packed 64-bit ambient mass arrays require approximately 3.3 MiB. Anatomy is small; unbounded dictionaries and histories pose greater risk than the graph itself.

An unbatched four-hour session at ten-second slices gives 1,440 slices. Across 250 people and 24 edges, that is approximately 8.64 million edge evaluations per day. This is a reference workload, not an acceptable assumption about centuries of runtime.

Compile common safe cycles, cache topology, reuse buffers and process dormant people cheaply. Invalidate cached coefficients when anatomy or health changes. Keep detailed transient simulation for experiments, unstable practice and combat.

Stagger research decisions across dated weeks. A CPU budget may spread processing across frames, but cannot cancel scheduled experiments or change simulated results.

Initial performance targets are under 50 ms per ordinary simulated day after safe-cycle batching and bounded memory during ten-year advances. Measure on the owner’s machine later; these are targets, not benchmark results.

Do not introduce world fluid dynamics, graphical body simulation for everyone, all-pairs sparring or a world-sized detailed navigation dependency.

## 20. Migration from the current code

| Current system | Keep | Replace or extend |
|---|---|---|
| `src/combat.gd` | Event-driven fights, harm thresholds, motives, yielding, escape, story records | Scalar strike loop becomes operation events with distance, guards, equipment and paid qi |
| `Combat.person()` | Attributes, physical tempering, age and injury calibration | Remove automatic realm qi power/speed and realm breath scaling |
| `martial_level()` | Hunting skill for hunting-specific tasks | Replace best-any-prefix combat proficiency with equipped operation skills |
| `hunt()` | Encounter and prey consequences | Replace free `hunter_weapon` power with actual equipment; bound ambush effects through opening state |
| `data/society/combat.json` | Initial harm scale, time limit and wound calibration | Retire `qi_power`, `qi_speed` and per-layer spiritual bonuses |
| `src/body_tempering.gd` | Nine layers, permanent grades, medicine gates, polishing, Perfect chain and attribute gifts | Seed anatomy from grades; replace root progress multiplier and abstract `qi_bonus()` with paid assistance and structural effects |
| `src/skill_catalogue.gd` | Validated catalogue and normal progression machinery | Activate selected martial and qi disciplines using complete detailed schemas |
| `data/skills` | Existing IDs and discipline organisation | Add specialisations, activities, attributes and valid related disciplines |
| `src/mind.gd` | Heart, urges, emotions, goals and decision explanations | Add research options and schedule actual practice instead of immediate multi-day credits |
| `src/nature.gd` | Species, sightings and habitat pools | Add observation evidence and hypotheses; retire direct complete-manual creation |
| `src/fifty.gd` | Membership, admission, seats, five-year tournaments and restoration accounts | Manuals and real practice locations replace synthetic qi seats/resources bonuses |
| Legacy cultivation | Root identities and relevant character history | Replace `qi_rate × days`, random site changes and innate nine/thirteen caps |
| Save system | Stable people and historical records | Persist anatomy, manuals, dated actions, residuals and subsystem versions |

The martial disciplines currently declare `detailed:false`. Simply pointing a manual at `weapons.straight_sword` or `archery.aiming` does not make it learnable. Complete their detailed definitions before activities call catalogue indices.

Current `Combat.person()` treats realm index 1 as its special per-layer qi branch, while the cultivation data labels realm 1 Body Tempering and realm 2 Qi Condensation. Remove this ambiguity through named realm identities and explicit capability queries.

Keep the Fifty’s complete tempering method from day one. Do not silently remove current teaching, polishing or medicine entitlements during the qi conversion. Environmental qi multipliers are retired when actual field delivery replaces them; physical teaching benefits require separate calibration.

The existing restoration `stone` account remains divine restoration material, distinct from tradable qi-bearing spirit stones. Forge bestowals use the existing Will account.

### Old saves

Do not reinterpret old abstract cultivation points as newly created physical qi.

At migration:

- Preserve Body Tempering grades and seed anatomy deterministically.
- Preserve legacy progress in a named historical field.
- Convert existing higher cultivation through explicit compatibility fixtures.
- Initialise personal reserve without retroactively draining centuries of environmental qi.
- Record any reserve granted by migration as an external migration endowment.
- Start new field history at the save’s present date.
- Seed Palace manuals and sources once.

For the first full cultivation release, a fresh world is the preferred balance baseline. Compatibility saves must be labelled until their mapping has been validated.

## 21. Staged build plan

### Stage 1 — The qi field

Implement the adopted environmental field, generation, source reserves, locations, sampling, request allocation and conservation ledger.

Use synthetic consumers for validation. Do not ship the superseded flat intake formula as a new permanent adapter.

Acceptance:

- Identical generation from identical seed.
- Nonnegative elemental inventories.
- Source output and regeneration reconcile exactly.
- Consumers share independently of insertion order.
- Daily and irregular multi-day partitions match.
- Small compartments do not duplicate volume or energy.
- Palace superiority comes from actual source and infrastructure.

No formations gameplay, martial rewrite or new progression is required for this stage.

### Stage 2 — One cultivator, two routes

Build section 18’s experiment as a **standalone headless command-line tool**, preferably using a small pure-data reference implementation that does not launch Godot or load scenes.

Use eight nodes:

```text
breath gate
chest junction
abdominal refinement node
lumbar return node
lower dantian
left branch junction
right branch junction
grounding gate
```

Include alternative chest-to-dantian paths, a narrow abdominal edge and a viable lumbar bypass.

Load one actual nine-layer Body Tempering foundation. Generate two route variants deterministically from the operation vocabulary:

- **Route A:** conservative serial filtering and stabilisation.
- **Route B:** split circulation with reduced filtering and higher coordination demand.

Run each from an identical cloned initial state for three simulated years. Also run an autonomous character who can select, modify and retain routes. Report fixed-route results separately from autonomous decisions.

```text
report:
  absorbed, circulated, refined and dissipated QU
  reserve and paid permanent work
  capacity, conductivity and openness by edge
  dantian development
  purity and instability
  maximum strain and recovery days
  failed operations, injuries, scars and deaths
  selected mutations and reasons
  conservation residual
  daily-versus-jump state hash
```

The tool must print a clear verdict:

```text
MEANINGFULLY DIFFERENT
or
NOT YET MEANINGFULLY DIFFERENT
```

A meaningful difference requires at least one of:

- At least 15% difference in usable refined output.
- At least 15% difference in relevant permanent development.
- At least 0.05 difference in retained purity.
- At least 20% difference in recovery burden where the baseline burden is nonzero.
- A structural milestone achieved at least 90 days apart.

A numerical difference alone is insufficient. The report must identify the responsible path, bottleneck or operation.

Add a second anatomical fixture with reversed branch quality. At least one route ranking should reverse on a relevant objective, or the report should flag that the landscape is still too uniform.

Safety checks include a cautious fixture, an intentionally overloaded fixture and a damaged grounding route. The unsafe fixture must reveal danger through pressure and damage, not an unrelated death roll.

This stage is the decision gate. If routes differ only by arbitrary authored coefficients, revise the laws before expanding the game.

### Stage 3 — Production anatomy and progression

Expand to the bounded human graph, implement storage, integration, nine milestone certifications, injury and save contracts.

Connect the body diagram to real execution reports.

Implementation status: Stage 3c is implemented: layers 4–9 have execution-evidence
checks and dated trials; the practice coordinator appends distribution and split
drills; paid release assays and the plain-text person-book evidence readout are
present. Stage 3 acceptance remains incomplete: the ten-year Perfect Palace
fixture does not reach layers 2–3 (or their successors), and performance and
verification findings are recorded in `docs/qi_condensation.md`. The legacy
random ladder is removed. No certification law was relaxed to claim reachability.

The live `Release` operation is available from certified layer 1. Its bounded
transient sends a paid 0.10-QU mobile pulse along the real lower-to-palm route,
with normal capacity/conductance/headroom limits. At one tile, purity squared, stability, execution quality and the section-11
coherence attenuation reduce controlled delivery. Release uses the current
shared operation mastery until detailed per-operation skills are integrated. All spent pulse energy is recorded
as dissipated, including delivery and the remaining diffuse pulse; it is not
usable qi returned to a field cell. This closes the body energy ledger without
inventing recoverable ambient emission. Layer 8 measures ten reliable tests,
not first access to release.

### Stage 4 — Physical martial techniques

Activate detailed skills and equipment. Implement stance, steps, strikes, guards, parries, feints, recovery and bow actions.

Verify reach and tempo counters before adding qi reinforcement.

### Stage 5 — Shared qi combat

Add reinforcement, local buffers, weapon conduction and projection through the existing circulation service.

Verify that exhausted reserve, blocked channels and late delivery change outcomes correctly.

### Stage 6 — Library, discovery and the Forge

Seed authored Palace programs, introduce local search and provenance, then expose the owner’s composition screen.

Use the same evaluator for predictions, practice, NPC experiments and actual combat.

### Stage 7 — Other users of the laws

Extend the resource and operation contracts to formations, beasts, plants, artifacts and alchemy.

A formation is an external graph. A beast has species anatomy. A plant has interfaces and growth work. An artifact has conductivity and storage. None receives a separate law allowing free qi.

## 22. What establishes that the design works

The design succeeds when the engine can explain an outcome in physical terms:

> This envoy’s lumbar return carries more than their abdominal route, so splitting improves throughput. Their poor branch control initially wastes that advantage. After practice, the method replenishes reserve faster but develops the abdominal foundation less.

And in martial terms:

> This swordswoman can read the saber’s commitment and intercept it, but her narrow wrist route cannot deliver the requested reinforcement before contact. Reducing the qi branch and stepping earlier improves survival against the saber, while weakening her answer to a patient spear.

Those explanations must come from executed operations, measured resources and individual state.

The Dao supplies the laws. Bodies, choices and inherited knowledge produce the history.
