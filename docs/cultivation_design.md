# Crown of Ash
## Qi, Cultivation and the Living Dao
### System Design — Working Notes

---

## 1. Vision and Core Philosophy

Crown of Ash should treat cultivation as a discoverable natural phenomenon governed by consistent laws.

Cultivators do not advance simply because they have accumulated enough experience points. Their advancement emerges from interacting with qi, understanding its behaviour, developing internal pathways, refining energy, and transforming their bodies.

The world should be capable of discovering its own cultivation systems.

No individual cultivation manual needs to be authored by the player or developer. Instead, the simulation provides the underlying physical rules, and characters discover methods of exploiting those rules through observation, experimentation, teaching and inheritance.

This produces five important characteristics:

1. **Cultivation is physical.** Qi moves, accumulates, dissipates, transforms and causes changes.
2. **Knowledge is discovered.** Manuals emerge from experience and experimentation rather than appearing as predefined recipes.
3. **Progression is individual.** Two people practising the same method may achieve different outcomes because their bodies, spirit roots and comprehension differ.
4. **Knowledge evolves.** Techniques can improve, deteriorate, fragment, merge or disappear across generations.
5. **The Heavenly Dao is consequential.** Its interventions influence the world but have costs, risks and limitations.

These principles should extend beyond humans.

Spirit beasts, plants, formations, artifacts and alchemy should eventually interact with the same qi physics, even where their internal structures differ.

The intended result is a world in which cultivation methods can be discovered that neither the player nor the developer explicitly anticipated.

---

## 2. The Nature of Qi

### 2.1 Qi as a resource

Qi is a form of spiritual energy that exists throughout the Seven Stars Continent.

It can be found in the atmosphere, earth, water, living organisms, spiritual veins, minerals and artificially constructed formations.

Qi should not spontaneously appear inside a cultivator simply because the character is meditating.

Instead, cultivation involves drawing energy from an available source and transforming it into a personally usable form.

The foundational energy cycle is:

**Spirit vein → Ambient qi → Absorption → Meridian circulation → Refinement → Dantian storage → Cultivation or expenditure**

Not all energy entering this cycle survives it.

Some is rejected because of elemental incompatibility. Some is lost during circulation. Some dissipates during refinement. Excessive absorption can damage the cultivator.

### 2.2 Qi properties

Every meaningful quantity of qi should carry a set of properties.

| Property | Function |
|---|---|
| Quantity | Amount of available energy |
| Density | Energy concentration within a location |
| Elemental composition | Metal, Wood, Water, Fire and Earth |
| Purity | Proportion of energy that can be effectively refined |
| Polarity | Yin–yang balance |
| Stability | How readily the energy can be controlled |
| Pressure or potential | Determines its tendency to move through a connection |
| Corruption | Harmful impurities or unstable characteristics |

Qi has no universal quality independent of its use.

For example, a location rich in Water qi may be ideal for one cultivation method but poorly suited to another.

High-density qi is desirable, but it may be dangerous to an inexperienced practitioner whose body cannot regulate its intake.

### 2.3 The five elemental phases

The five phases provide the basic composition of natural qi.

The traditional generating and overcoming relationships can inspire how elements interact.

The generating cycle:

**Wood → Fire → Earth → Metal → Water → Wood**

The overcoming cycle:

**Wood → Earth → Water → Fire → Metal → Wood**

These relationships should not automatically create or destroy energy.

They describe compatibility and transformation possibilities.

A method may convert one elemental component into another, but doing so requires a defined process and should introduce a measurable efficiency loss unless some additional source supplies the difference.

Wind, Thunder, Ice, Light and Shadow can be derived characteristics of elemental combinations, environmental conditions and specific techniques, consistent with the existing ten spirit-root categories.

### 2.4 Conservation of energy

A central rule should be:

**Qi cannot be created without a source.**

For every simulation step:

*Initial qi + external supply = remaining qi + stored qi + transformed qi + dissipated qi.*

Transformation must not be counted twice.

A cultivator drawing ten units from a spirit spring removes ten units from the available environmental supply.

If seven units are refined and three dissipate, the cultivator cannot receive ten refined units while the spring also retains its original ten.

This accounting principle becomes essential for formations, cultivation chambers, spirit stones and alchemy.

---

## 3. The Three Treasures: Jing, Qi and Shen

The Three Treasures should serve as a conceptual foundation for living cultivation.

They need not be three interchangeable energy bars.

Instead, each represents a distinct aspect of the cultivator.

### 3.1 Jing — Physical essence

Jing represents the body's material foundation.

It is associated with physical development, vitality, constitution, recovery and the capacity to tolerate spiritual energy.

In Crown of Ash, Jing can be represented through existing attributes and derived bodily properties:

- Strength and endurance.
- Constitution and natural recovery.
- Body Tempering achievements.
- Meridian integrity.
- Physical resilience.
- Age-related deterioration.
- Nutritional condition.

Jing should not simply regenerate whenever qi is available.

A starving, injured cultivator might have abundant spiritual energy but insufficient physical resources to repair bodily damage.

### 3.2 Qi — Spiritual energy

Qi represents the energy that is absorbed, circulated, refined and expended.

Its uses include:

- Cultivation advancement.
- Physical reinforcement.
- Healing assistance.
- Spiritual perception.
- Martial techniques.
- Alchemy.
- Formations.
- Supernatural abilities.

Qi should be limited by the body's ability to absorb, circulate and store it.

### 3.3 Shen — Spirit and consciousness

Shen represents awareness, mental control and spiritual stability.

It connects naturally to the existing character mind system.

Potential influences include:

- Comprehension.
- Willpower.
- Attention and concentration.
- Emotional stability.
- Fear, ambition and impulsiveness.
- Insight.
- Heart demons.
- Ability to recognise circulation errors.

A character with exceptional Shen might accurately control a complicated circulation pattern despite mediocre spiritual roots.

A talented but impulsive character might repeatedly overestimate their abilities and force dangerous breakthroughs.

This establishes a meaningful distinction between **having access to power and being capable of controlling it**.

---

## 4. Cultivator Anatomy

### 4.1 The internal spiritual body

Every cultivator should possess a simulated internal spiritual anatomy.

This structure is based on fictional meridians, energy centres, channels and gates.

The visual representation can draw inspiration from traditional Chinese meridian diagrams and Daoist internal alchemy, without claiming to reproduce real anatomy.

The internal system should be represented as a graph.

**Nodes represent:**
- Dantian.
- Acupoints.
- Meridian junctions.
- Spiritual gates.
- Specialised internal reservoirs.

**Connections represent:**
- Major meridians.
- Secondary channels.
- Extraordinary vessels.
- Newly opened cultivation pathways.
- Damaged or obstructed connections.

Every node and connection has measurable properties.

### 4.2 Meridian properties

Each channel could contain:

| Property | Description |
|---|---|
| Openness | How completely the pathway has developed |
| Capacity | Maximum energy flow |
| Conductivity | Ease of moving qi |
| Resistance | Difficulty of circulation |
| Integrity | Physical or spiritual condition |
| Elemental affinity | Compatibility with different qi compositions |
| Stability | Resistance to uncontrolled flow |
| Adaptation | Permanent improvement through successful practice |
| Scarring | Lasting damage from severe cultivation deviation |

These properties should be individual.

Characters may inherit favourable constitutions, unusual meridian structures or rare compatibility traits.

Their spiritual anatomy also changes during life.

Body Tempering, illness, injuries, cultivation, medicine and unusual encounters may alter the network.

### 4.3 The three dantian

Three energy centres could eventually form part of the character's spiritual anatomy.

**Lower Dantian — Energy reservoir**

The principal reservoir for Qi Condensation.

Stores refined qi, supports circulation and provides energy for techniques.

**Middle Dantian — Vital transformation**

Associated with the interaction between spiritual energy and bodily vitality.

Could become relevant for healing, physical reinforcement, internal alchemy and advanced body cultivation.

**Upper Dantian — Spiritual awareness**

Associated with consciousness, perception, spiritual control and later soul cultivation.

The lower dantian should be the primary focus during early Qi Condensation.

The other centres can exist visually and mechanically without needing to be fully accessible at the beginning.

### 4.4 Body Tempering as preparation

The existing nine Body Tempering layers should remain meaningful.

A person who completes Body Tempering has developed the physical foundation required to withstand deliberate qi circulation.

However, there should be a distinction between:

- Completing all nine layers.
- Completing all nine at Perfect grade.

The first qualifies the body for ordinary Qi Condensation entry.

The second provides a substantially better physical foundation.

Permanent Body Tempering grades may determine initial meridian capacity, stability, injury tolerance and dantian-opening potential.

A Perfect body should therefore remain valuable long after the cultivator advances into higher realms.

---

## 5. Mathematical Meridian Circulation

### 5.1 Qi flows through a network

The meridian graph should behave like a simplified flow network.

Each connection possesses a maximum throughput.

Each node can temporarily contain a quantity of energy.

Flow depends on the available qi, the pathway's conductivity, its restrictions and the pressure difference between connected nodes.

One possible model:

**Flow = min(available qi, conductivity × positive pressure difference, channel capacity)**

This is an invented game-physics abstraction.

The pressure variable represents spiritual potential rather than real fluid pressure.

### 5.2 The weakest channel matters

Suppose a cultivator attempts to circulate twelve qi units through a pathway.

The route includes four channels with capacities:

| Channel | Capacity |
|---|---:|
| A | 15 |
| B | 12 |
| C | 7 |
| D | 10 |

The route can currently sustain only seven units of flow.

Channel C is the bottleneck.

If the cultivator follows the safe circulation rate, only seven units pass through the circuit during the relevant time step.

The cultivator may eventually improve Channel C through controlled circulation, guided treatment or a suitable method.

Alternatively, they may experiment with a route that bypasses it.

This is one reason different cultivation manuals can produce different results.

### 5.3 Movement and refinement

Circulating qi should not automatically result in permanent cultivation progress.

The simulation distinguishes:

**Absorption:** Drawing qi from the environment.

**Circulation:** Moving qi through an internal route.

**Refinement:** Removing or transforming undesirable characteristics.

**Condensation:** Stabilising refined qi in the dantian.

**Integration:** Producing long-term internal development.

A complete cultivation session might proceed as follows:

1. Absorb 12 qi units.
2. Safely circulate 9 units.
3. Reject or dissipate 3 units.
4. Refine the circulated qi with 80% efficiency.
5. Settle 7.2 refined units into the dantian.
6. Allocate part of the successfully processed energy to permanent cultivation development.

Fractional energy units can be retained internally even if the player interface displays rounded quantities.

### 5.4 Safe circulation and forced circulation

A cultivator can choose to exceed the recommended flow through a channel.

This increases immediate throughput but creates strain.

For example:

- Channel safe capacity: 8.
- Attempted forced flow: 12.
- Overload: 50%.

The resulting instability depends on several factors, including channel integrity, constitution, experience, mental control and the method's inherent stability.

Repeated overload can damage the pathway.

A sufficiently extreme failure may cause severe injuries or death.

The relationship should be nonlinear: modest overloading might be manageable, while attempting several times the safe capacity becomes extraordinarily dangerous.

This provides a mathematical basis for reckless cultivation, forbidden methods and breakthroughs achieved at great personal cost.

---

## 6. Cultivation Manuals as Discoverable Algorithms

### 6.1 No fixed catalogue of authored manuals

Cultivation manuals should not be a predetermined list of recipes.

Instead, the developer defines a small vocabulary of **cultivation operations**.

Characters discover ways to combine these operations.

Possible operations include:

| Operation | Behaviour |
|---|---|
| Absorb | Draw qi from an external source |
| Guide | Move qi along a selected meridian |
| Hold | Temporarily retain qi at a junction |
| Split | Divide flow between multiple pathways |
| Merge | Recombine compatible streams |
| Filter | Remove unwanted components |
| Convert | Transform elemental properties |
| Compress | Increase concentration |
| Stabilise | Reduce circulation instability |
| Release | Expel or project energy |
| Ground | Safely dissipate excess energy |
| Resonate | Synchronise qi with a body part, object or formation |

A manual is a combination of these operations, their sequence, parameters and selected internal pathways.

The same engine should support simple breathing techniques, advanced circulation arts and dangerous experimental methods.

### 6.2 A manual's internal representation

A discovered manual might record:

- Its unique identity.
- Discoverer.
- Creation date.
- Source observations.
- Prescribed meridian routes.
- Required operations and their order.
- Elemental preferences.
- Flow targets.
- Circulation timing.
- Known safety limits.
- Required bodily development.
- Known successful applications.
- Observed failures.
- Confidence in the recorded instructions.
- Teacher notes.
- Lineage and historical revisions.

The manual should describe *what to attempt*, not determine the result.

The same technique can succeed for one person and fail for another.

### 6.3 Incomplete manuals

An incomplete manual is not necessarily worthless.

It may contain:

- Missing circulation steps.
- Incorrect flow requirements.
- An undiscovered junction.
- A dangerous assumption.
- An effective but inefficient pathway.
- A partially understood refinement operation.

A disciple might successfully cultivate using an incomplete manual but struggle at a particular bottleneck.

Another may eventually discover the missing steps.

An incomplete manual may even be the foundation of a powerful future technique.

### 6.4 Manual performance is contextual

No technique should automatically dominate every other technique.

A manual may be excellent for:

- Particular spirit roots.
- Certain constitutions.
- Specific environmental conditions.
- Long-term refinement.
- Physical reinforcement.
- Rapid energy recovery.
- High-risk breakthroughs.

A technique that produces exceptional cultivation speed might leave the body unstable.

A slow technique might build extraordinarily strong meridians and a superior foundation.

This makes quality multidimensional rather than a single rate multiplier.

---

## 7. The Discovery Engine

### 7.1 Observation of nature

Characters should learn from the world around them.

The existing nature-observation system provides a starting point.

Possible sources of inspiration include:

**Rivers:** Continuous flow, branching and convergence.

**Waterfalls:** Pressure, acceleration, impact and energy dissipation.

**Trees:** Distribution networks, roots, branching and gradual growth.

**Fire:** Transformation, instability, heat and consumption.

**Storms:** Rapid discharge, accumulation and resonance.

**Animals:** Movement, physical adaptation and specialised anatomy.

**Spirit beasts:** Biological methods of absorbing and circulating spiritual energy.

**Seasons:** Cycles of accumulation, dormancy, renewal and decay.

These observations should not directly grant complete manuals.

Instead, they provide **hypotheses or insights** into particular cultivation operations.

For example, a cultivator observing a river might gain insight into splitting flow between parallel channels.

That insight enables experimentation with an internal branching circulation pattern.

Whether the pattern works depends on the cultivator's actual meridian structure and the underlying qi physics.

### 7.2 Personal experimentation

Not every discoverer needs an external inspiration.

A character may attempt a new circulation route because of curiosity, frustration, ambition, desperation or unusual talent.

Their experimentation may change:

- Route selection.
- Flow rate.
- Elemental composition.
- Timing.
- Compression.
- Refinement strategy.
- Number of circulation loops.

The experimental outcome is determined by running the attempted method through the actual qi model.

Possible outcomes:

1. Nothing useful occurs.
2. Minor improvement.
3. A viable but inefficient method emerges.
4. A new stable circulation route is discovered.
5. An exceptional technique emerges.
6. The cultivator injures themselves.
7. The cultivator develops lasting meridian damage.
8. Severe qi deviation causes death.

The outcome should not be selected merely by rolling a random rarity table.

Randomness can influence experiments, but the underlying mechanics must determine whether a discovery is actually effective.

### 7.3 Personality influences experimentation

The existing mind system should influence the research process.

For example:

**Patient cultivators** may explore slowly, repeat experiments and document results carefully.

**Ambitious cultivators** may pursue difficult methods with greater potential rewards.

**Fearful cultivators** may avoid dangerous experiments.

**Curious cultivators** may explore unusual routes.

**Proud cultivators** may ignore warnings.

**Disciplined cultivators** may be more likely to complete long refinement studies.

These tendencies influence decisions rather than guarantee outcomes.

A cautious researcher can still make a revolutionary discovery.

An impulsive genius can still create a safe and effective technique.

### 7.4 Comprehension and rare insight

Comprehension determines how effectively a person learns from observations and experimental results.

High comprehension should help a cultivator:

- Recognise relationships between observations.
- Infer missing steps.
- Identify circulation inefficiencies.
- Understand why an experiment failed.
- Transfer principles from one technique to another.

Rare insight could allow a cultivator to discover a complex operation without repeating every intermediate experiment.

However, insights must remain compatible with the underlying qi rules.

Exceptional insight can reveal a previously unknown possibility. It should not simply ignore conservation, channel capacity or bodily limitations.

---

## 8. Evolution of Manuals Across Generations

A cultivation method should have a history.

### 8.1 Manual inheritance

A technique can be:

- Taught orally.
- Written into a manual.
- Preserved in a scripture.
- Demonstrated by a master.
- Copied.
- Translated.
- Reconstructed from fragments.
- Lost when its practitioners die.

Transmission should preserve much of the original knowledge without guaranteeing perfect understanding.

### 8.2 Knowledge and execution are different

A disciple may possess an accurate copy of a powerful manual but lack the comprehension or bodily capability to use it.

Conversely, someone may understand a flawed manual well enough to identify and correct its mistakes.

The simulation should distinguish:

**Manual knowledge:** What the instructions actually contain.

**Character understanding:** How accurately a person interprets those instructions.

**Practical mastery:** How reliably they can execute the technique.

This distinction prevents learning a technique from instantly granting its full benefits.

### 8.3 Generational improvement

Suppose the first generation discovers a crude circulation method.

It is inefficient but functional.

The next generation identifies a dangerous bottleneck and modifies the route.

The third generation develops a refinement step that improves purity.

The fourth generation combines that method with an entirely different technique.

The result may be a significantly more advanced inheritance.

The improvement is not automatic.

Some generations may misunderstand the original method.

A technique may become less efficient after a poorly documented modification.

Others may deliberately prioritise speed or combat power over safety.

### 8.4 Historical provenance

Every manual should preserve an evolutionary lineage.

For example:

**Unnamed Breathing Observation**

Discovered by a wandering mortal.

↓ Modified through experimentation

**First River Circulation**

Developed a stable circulation route.

↓ Inherited and corrected

**Nine Streams Method**

Introduced multiple circulation branches.

↓ Combined with another lineage

**Unnamed Advanced Art**

Improved refinement and energy storage.

These names are illustrative examples of what the name-generation system could produce, not predetermined manuals.

Actual techniques should receive generated names based on their history, characteristics and cultural context.

### 8.5 Knowledge must be capable of disappearing

If every discovered manual remains universally accessible forever, cultivation knowledge can only increase.

That would eventually eliminate scarcity and reduce the importance of historical events.

Knowledge should instead be vulnerable to:

- Destruction of libraries.
- Death of teachers.
- Failed apprenticeships.
- War.
- Secrecy.
- Political suppression.
- Deliberate misinformation.
- Incomplete records.
- Forgotten languages.
- Loss of rare materials needed to practise a method.

A future cultivator might rediscover a lost principle independently.

The simulation should recognise this as a distinct historical discovery, even if the underlying mechanism resembles an earlier forgotten technique.

---

## 9. Spiritual Environments and Body Development

Abundant spiritual energy must provide meaningful benefits beyond faster qi accumulation.

However, the benefits should depend on how the environment interacts with the body.

### 9.1 Passive environmental benefits

Living in a spiritually rich environment may gradually improve:

- Recovery from physical exertion.
- Recovery from minor injuries.
- Resistance to certain forms of spiritual damage.
- Long-term meridian development.
- Ability to perform qi-assisted Body Tempering.
- Maintenance of existing spiritual reserves.

A spiritually rich environment should not automatically produce enormous muscles or perfect physical attributes.

Body development still requires physical training, nourishment, rest and adaptation.

### 9.2 Qi-assisted Body Tempering

Body Tempering should remain possible without spiritual roots.

Physical labour, drills, hardship and medicine already provide valid progression.

However, a cultivator with suitable qi access can obtain an additional benefit.

A possible model:

**Body progress = Physical training progress + Qi-assisted adaptation**

The qi-assisted component depends on:

- Actual energy availability.
- Energy compatibility.
- Physical exertion.
- Safe absorption capacity.
- Recovery.
- Body Tempering method.
- Teacher assistance.

This ensures that a disciple raised in a powerful spiritual sanctuary has an advantage without invalidating someone who develops through ordinary physical training.

### 9.3 Spiritual saturation

The body could also possess a long-term spiritual saturation state.

Saturation reflects gradual adaptation to living in a qi-rich environment.

It may improve passive recovery and make future cultivation easier.

But saturation has a natural limit determined by the person's constitution.

Simply remaining inside a heavenly cultivation chamber for fifty years should not automatically produce a peak cultivator.

### 9.4 Environmental danger

Abundant qi may also introduce risks.

A spiritually dense region with unstable or incompatible energy might cause:

- Fatigue.
- Meridian irritation.
- Uncontrolled absorption.
- Spiritual contamination.
- Difficulty resting.
- Increased deviation risk during reckless cultivation.

This creates a reason for formations that regulate environmental qi rather than merely amplify its density.

---

## 10. Why Qi Condensation Cultivators Are Stronger

Qi Condensation should not automatically mean that the person's muscles have become vastly stronger than those of a peak Body Tempering cultivator.

The fundamental distinction should be between **permanent physical development and controllable spiritual reinforcement**.

### 10.1 Physical strength

Body Tempering develops the body's inherent capabilities.

Its benefits remain even when the cultivator has no stored qi.

A peak Body Tempering practitioner may possess extraordinary raw strength, speed, endurance and toughness.

An early Qi Condensation cultivator who barely completed Body Tempering may have inferior natural physical attributes compared with someone who achieved Perfect grades.

### 10.2 Spiritual reinforcement

Qi Condensation introduces the ability to deliberately circulate and deploy refined spiritual energy.

A cultivator may channel qi into muscles, bones, tendons or other tissues.

This temporarily increases effective physical performance.

The enhancement depends on:

- Available refined qi.
- Meridian throughput.
- Control.
- Reinforcement technique.
- Body tolerance.
- Energy expenditure.

A cultivator cannot sustain unlimited reinforcement.

High-output techniques drain reserves and may cause bodily strain.

### 10.3 Combat capabilities

| Capability | Body Tempering | Qi Condensation |
|---|---|---|
| Raw muscular strength | Primary source of power | Depends on existing body foundation |
| Physical resilience | Permanent conditioned toughness | Physical toughness plus qi reinforcement |
| Speed | Physical conditioning and martial skill | Physical ability plus controlled bursts |
| Spiritual perception | Limited or undeveloped | Can develop through qi-based sensing |
| Energy projection | Generally unavailable | Possible through suitable techniques |
| Sustained combat | Physical stamina | Stamina plus available qi and recovery |
| Energy recovery | Rest, food and medicine | Rest, food, ambient qi and refinement |
| Specialized abilities | Martial methods | Spiritual techniques and elemental applications |

### 10.4 Example combat comparison

Consider three hypothetical characters.

**Character A — Perfect Body Tempering 9**

Exceptional permanent physical strength and durability.

No reliable external qi projection.

**Character B — Qi Condensation 1**

Completed Body Tempering at ordinary grades.

Moderate natural strength.

Can temporarily reinforce physical attacks and senses using qi.

**Character C — Qi Condensation 5**

Has developed stronger internal circulation and a larger refined qi reserve.

Can sustain reinforcement longer, circulate qi more efficiently and potentially execute more demanding techniques.

Character B should not necessarily defeat Character A.

Character A could possess superior martial skills, resilience and physical strength.

However, Character C might have enough throughput and technique mastery to make their spiritual abilities decisive.

The actual outcome should remain dependent on combat skill, tactical circumstances and individual capabilities.

### 10.5 Long-term physical transformation

Over time, repeated safe qi reinforcement may produce permanent bodily adaptation.

The body may become more resistant to spiritual pressure and more efficient at conducting qi.

That adaptation should have diminishing returns and meaningful limits.

It should not make Body Tempering irrelevant.

Instead, a superior physical foundation should continue to amplify the value of higher cultivation.

---

## 11. Qi Condensation Progression

Each cultivation layer should represent an internal achievement.

A breakthrough is not simply the accumulation of enough qi.

The simulation should require a change in the cultivator's internal spiritual structure.

### 11.1 Advancement conditions

A layer may require some combination of:

- Dantian capacity.
- Refined qi density.
- Stable circulation cycles.
- Specific meridian openings.
- Control accuracy.
- Internal energy stability.
- Minimum bodily integrity.
- Completion of necessary refinement work.

Not every manual needs to achieve these conditions in the same way.

Different methods may provide different routes toward the same cultivation milestone.

### 11.2 Foundational milestones

The early realm could develop through several major transformations:

**Opening the Dantian**

The character develops the ability to retain refined qi rather than merely circulate or dissipate it.

**Establishing Circulation**

The character successfully moves qi through a complete internal route.

**Stabilising Condensation**

The dantian can retain increasing quantities of refined energy without destabilisation.

**Expanding the Meridian Network**

Previously restricted pathways become suitable for sustained circulation.

**Increasing Throughput**

The body can safely process more energy within a given period.

**Refining Quality**

The character becomes capable of storing purer or more concentrated qi.

**Integrating Multiple Circuits**

The cultivator can coordinate complex circulation patterns.

**Completing the Realm**

The internal network and dantian achieve the stability required for the next fundamental transformation.

These milestones can be distributed across nine or thirteen layers once their mechanical requirements are established.

The number of layers should follow the desired depth of progression rather than determine the anatomy in advance.

### 11.3 Permanent progress and spendable energy

The model should distinguish three quantities:

**Refined qi reserve**

Energy available for techniques and immediate use.

**Permanent cultivation development**

Internal progress that cannot simply be spent in combat.

**Deviation pressure**

Instability accumulated through dangerous or poorly controlled cultivation.

Spending spiritual energy does not automatically erase previously completed meridian development.

Similarly, possessing a large energy reserve does not guarantee that the character can advance.

---

## 12. Qi Deviation and Cultivation Risk

Qi deviation should emerge from the same circulation system used for successful cultivation.

It should not be a disconnected failure table.

### 12.1 Causes of deviation

Possible causes include:

- Excessive circulation pressure.
- Blocked meridians.
- Elemental incompatibility.
- Incorrect circulation direction.
- Failed refinement operations.
- Sudden changes in environmental qi.
- Damaged meridians.
- Unstable mental control.
- Poorly understood manuals.
- Deliberate experimentation beyond safe limits.

### 12.2 Severity

| Severity | Possible consequences |
|---|---|
| Minor | Fatigue, temporary circulation disruption |
| Moderate | Meridian inflammation, reduced efficiency |
| Serious | Internal injury, cultivation setback |
| Severe | Permanent scarring, damaged dantian |
| Critical | Destruction of the cultivation foundation or death |

Death must remain possible.

However, severe outcomes should normally require substantial danger, accumulated instability or an extraordinary event.

The system should not routinely kill careful cultivators performing safe methods in ordinary conditions.

### 12.3 Why risk can be worthwhile

Dangerous cultivation should sometimes lead to unusual achievements.

A cultivator who survives forced circulation might permanently widen a difficult meridian.

Someone experimenting with incompatible elements may discover a new transformation technique.

A disciple who repeatedly pursues dangerous compression might eventually create an exceptionally dense spiritual foundation.

These achievements should have physical explanations in the simulation.

Risk does not guarantee innovation.

Most poorly controlled experiments may produce nothing useful.

This makes extraordinary discoveries rare without relying exclusively on arbitrary rarity rolls.

---

## 13. Visualising Cultivation

The internal-body diagram should become one of the game's most detailed interfaces.

The attached Qi Cultivation infographic establishes the desired artistic direction.

Its parchment background, full-body energy illustration, flowing lines, symbolic presentation and connection between physical and spiritual development are useful references.

However, the game's display should be more anatomically structured, interactive and visually dynamic than a static infographic.

### 13.1 The central illustration

The interface should display a large human figure occupying most of the available vertical space.

Possible layers include:

**Physical body**

A detailed silhouette showing the outline of the body, major physical structures and relevant injuries.

**Primary meridians**

Major pathways extending through the torso, head and limbs.

**Secondary meridians**

Smaller branching channels forming a dense internal network.

**Extraordinary vessels**

Specialised pathways that may support more advanced cultivation.

**Acupoints and junctions**

Distinct points that can open, close, become obstructed or suffer damage.

**Dantian**

Large, visually prominent energy centres with animated internal activity.

**Active circulation**

Glowing pulses travelling through the routes currently used by a technique.

### 13.2 Artistic treatment

The visual design should combine:

- Traditional ink-and-parchment illustration.
- Intricate anatomical linework.
- Glowing elemental colour.
- Animated qi particles.
- Circular and branching spiritual patterns.
- Detailed dantian effects.
- A readable but visually rich cultivation interface.

The character should appear almost like a living spiritual manuscript.

As their cultivation develops, more pathways become visible.

An inexperienced cultivator may have only a few illuminated channels.

An advanced practitioner may possess a dense, interconnected network of circulating energy.

### 13.3 Visual meaning

Different colours or effects should communicate actual state.

| Visual | Meaning |
|---|---|
| Dim grey pathway | Dormant or unopened meridian |
| Blue/cyan pulse | Stable circulation |
| Gold pulse | Successfully refined qi |
| Elemental colour | Qi composition |
| Orange instability | Excess pressure |
| Red fracture | Damaged pathway |
| Darkened junction | Blockage |
| Brightening dantian | Refinement or storage |
| Erratic particles | Uncontrolled or leaking qi |

These visual states should be generated from simulation data.

### 13.4 Manual overlay

The player should be able to inspect both:

**Prescribed circulation**

The pathway described in the character's chosen manual.

**Actual circulation**

The pathway the character successfully follows.

If these differ, the diagram shows exactly where the character's execution diverges.

For example:

*The manual requires qi to pass through the Upper Junction, but the cultivator's flow destabilises before reaching it.*

Selecting that junction could reveal:

- Current capacity.
- Required throughput.
- Stability.
- Damage.
- Relevant experience.
- Likely bottleneck.
- Recent cultivation attempts.

### 13.5 Different viewing modes

A cultivation page could provide several visual modes:

**Anatomy**

Meridians, dantian and bodily condition.

**Circulation**

Animated qi movement during cultivation.

**Manual**

Required pathways and instructions.

**Development**

Permanent internal improvements across time.

**History**

Past injuries, breakthroughs, discoveries and deviations.

The player should not need to inspect every node manually to understand a character's general condition.

A summary should identify major strengths and current bottlenecks.

### 13.6 Performance

The diagram should not require expensive continuous simulation for every person in the world.

The underlying cultivation system can advance using deterministic time steps.

The detailed glowing animation is rendered only for the character being inspected.

The same stored state can generate a static visual summary for other characters.

This makes the design compatible with the existing low-spec development target and large population ambitions.

---

## 14. Applying the Same Physics to Other Systems

### 14.1 Spirit beasts

Beasts should use species-specific spiritual anatomy.

Their qi channels need not resemble human meridians.

A serpent might develop a long circulation path through its body.

A bird might concentrate qi in its wings and respiratory structures.

A turtle-like beast might develop a highly protected internal energy reservoir.

These are fictional adaptations produced by the same underlying energy principles.

Their cultivation abilities should emerge from their anatomy and behaviour.

### 14.2 Spirit plants

Plants should absorb qi through environmental interfaces such as roots, stems and leaves.

Qi can influence growth, resilience and the production of spiritual compounds.

Different species may prefer different elemental compositions.

Overharvesting spirit plants or draining a local vein should affect the surrounding environment.

### 14.3 Formations

A formation can be modelled as an artificial circulation network.

Its components correspond to:

- Energy sources.
- Conductive pathways.
- Junctions.
- Transformation operations.
- Storage reservoirs.
- Control instructions.
- Outputs.

A formation designer is effectively constructing a qi circuit outside the human body.

This means that knowledge discovered through meridian circulation may eventually inspire formation design.

Conversely, studying a successful formation might reveal principles that help a cultivator understand internal energy flow.

### 14.4 Alchemy

Alchemy should be a controlled transformation process.

Ingredients possess physical and spiritual properties.

A furnace controls temperature, pressure, qi exposure and transformation conditions.

An alchemist attempts to manipulate those conditions to obtain a desired substance.

Failures may result from incompatible ingredients, excessive heat, unstable qi reactions or insufficient control.

Successful recipes could eventually be discovered through experimentation and preserved across generations, using a knowledge-evolution system similar to cultivation manuals.

---

## 15. The Heavenly Dao and The Fifty

The Heavenly Dao should influence cultivation without bypassing its underlying laws.

The Fifty provide a means for Heaven to participate in the world through individual cultivators.

### 15.1 Heavenly intervention

Potential interventions include:

- Bestowing an insight.
- Providing rare spiritual resources.
- Improving environmental qi conditions.
- Granting access to a cultivation location.
- Preserving or revealing a forgotten manual.
- Supporting the recovery of an injured Apostle.
- Creating circumstances favourable to discovery.

These interventions alter conditions rather than guarantee outcomes.

### 15.2 Consequences for Heaven

Major interventions should consume resources or create obligations.

Possible costs include Heaven's Will, spirit-stone reserves, restrictions on further intervention and risks to the people through whom Heaven acts.

An Apostle who undertakes a dangerous mission can still suffer irreversible consequences.

The existing restoration mechanic provides a powerful exception, but it should remain limited by its resource requirements.

### 15.3 The Fifty as a living experiment

Each candidate begins with different talents, physical characteristics, personalities and experiences.

Over decades, they should develop unique cultivation histories.

Some may produce excellent physical foundations.

Others may discover unusual techniques.

Some may achieve extraordinary breakthroughs through patience and insight.

Others may be injured or killed by recklessness.

The five Apostle positions therefore become more than ranks.

They represent the survivors and achievers of a long-running experiment conducted under the Heavenly Dao.

The player participates by influencing opportunities and occasionally directing actions, while the candidates remain individuals governed by the same world physics.

---

## 16. Suggested System Architecture

The architecture should separate the laws of qi from the systems that use them.

### 16.1 Qi field

Responsible for:

- Environmental qi distribution.
- Spirit-vein supply.
- Elemental composition.
- Density.
- Depletion.
- Transfer.
- Recovery.

### 16.2 Spiritual anatomy

Responsible for:

- Meridian graphs.
- Dantian properties.
- Channel capacity.
- Permanent development.
- Damage.
- Individual compatibility.

### 16.3 Circulation engine

Responsible for:

- Executing cultivation instructions.
- Flow calculations.
- Refinement.
- Energy loss.
- Pressure.
- Stability.
- Circulation outcomes.

### 16.4 Knowledge and manual engine

Responsible for:

- Observation-derived insights.
- Experimental hypotheses.
- Manual construction.
- Technique inheritance.
- Mutations and combinations.
- Historical provenance.
- Knowledge loss.

### 16.5 Progression engine

Responsible for:

- Internal development milestones.
- Realm requirements.
- Breakthrough conditions.
- Long-term cultivation stability.

### 16.6 Shared energy consumers

Formations, alchemy, artifacts, plants, beasts and combat should access the common qi model rather than maintain unrelated energy systems.

These can be separate Godot modules or responsibilities within existing systems. The distinction is conceptual; a specific class hierarchy should follow the actual implementation.

---

## 17. Simulation Scale and Determinism

Crown of Ash needs to support very long simulated histories.

The system should therefore distinguish between **mechanical detail** and **update frequency**.

A cultivator may possess dozens of internal nodes, but every individual does not need a graphical particle simulation every frame.

A cultivation session can be evaluated mathematically using its prescribed route, the current state of the meridian graph and the available environmental qi.

The engine should store the resulting permanent changes.

When the player inspects that cultivator, those records can drive a detailed visual replay.

For ordinary population members, cultivation can be processed in larger deterministic time intervals where the mathematics permits it.

Important characters, dangerous experiments and breakthrough events may require finer simulation.

A suitable approach should preserve these invariants:

1. Qi is accounted for consistently.
2. A technique's result depends on actual character and environmental state.
3. The order in which characters are updated does not unfairly determine access to shared qi.
4. Saving and loading preserves anatomy, manuals, damage and cultivation history.
5. Higher game speed does not change the underlying rules.
6. The same initial seed and sequence of actions produce reproducible results.

This also gives the Heavenly Dao a reliable historical record of how the world developed.

---

## 18. First Mechanical Experiment

The first experiment should test the entire idea with a single cultivator.

Use:

- One character with an existing Body Tempering foundation.
- A small internal graph of six to eight nodes.
- A lower dantian.
- One environmental qi source.
- A generated cultivation route.
- A limited set of circulation operations.

The character attempts repeated cultivation sessions.

The engine tracks:

- Energy absorbed.
- Energy circulated.
- Energy refined.
- Channel development.
- Dantian changes.
- Stability.
- Failed attempts.
- Injuries.
- Permanent progress.

Introduce a second generated route that differs in its safety and efficiency.

Let the character's decision-making system select between them or experiment further.

After several simulated years, inspect whether the methods have produced meaningfully different results.

The internal diagram should then render the character's actual developed pathways.

A successful experiment would demonstrate that the game can produce a cultivation history through simulation rather than through predetermined experience thresholds.

---

## 19. Design Questions to Keep Open

Several decisions should remain flexible until the underlying system is tested.

**Qi Condensation layers**

Nine or thirteen layers may both be viable. The internal milestones should determine which structure is more meaningful.

**Meridian complexity**

The initial graph should be small. Additional anatomical detail should be introduced when it produces distinct mechanical behaviour.

**Cultivation risk**

Serious injury and death should be possible, but the severity and frequency require long-term simulation testing.

**Manual discovery**

Observation, independent experimentation and inheritance should all be viable. Their relative effectiveness should emerge from balancing rather than assumptions.

**Environmental advantage**

Spiritually rich locations should improve opportunities, recovery and safe cultivation potential without eliminating bodily or knowledge limitations.

**Character autonomy**

Cultivators should be capable of making decisions inconsistent with the player's preferences.

**Heavenly intervention**

The player should possess meaningful power while still facing costs, uncertain outcomes and the possibility of losing important Apostles.

---

## 20. Intended Outcome

The long-term objective is to produce a world in which cultivation knowledge develops historically.

A person may observe a river, experiment with internal circulation, discover an incomplete method, and teach it to a disciple.

That disciple may spend decades correcting the technique.

A later generation may combine it with a method discovered from studying a spirit beast.

The resulting inheritance may become famous.

It may also lead to disaster.

Centuries later, the original manual may be forgotten while a descendant of its discoverer practises a radically improved version.

Throughout this history, the underlying qi physics remains consistent.

The Heavenly Dao can observe these developments, influence their circumstances, empower chosen candidates and witness the consequences.

**Cultivation becomes something the world discovers, not something the developer predetermines.**

And every glowing pathway, every dantian transformation, every failed circulation and every successful breakthrough shown in the game's interface represents an actual event in the simulation.

---

## 21. Owner decisions, 14 November 2026

1. **The engine landscape must be rugged.** Each person has their own meridian graph, and a route is judged on several outcomes (speed, foundation, purity, strain), so no single manual dominates. Characters are the optimisers: an experiment is a small change to a route, run on their own body. Personality sets how large the change is and how much risk they accept. Comprehension sets how much they learn from a failure.
2. **One rulebook for two kinds of manual.** Cultivation manuals (qi circulation) and martial technique manuals (sword, spear/staff, fist/palm, bow, saber) are both evaluated by an engine, and both engines obey the same qi and body physics. This document is to be redrafted so that every system follows the same rules.
3. **The Palace library holds authored manuals that respect the engine.** They are not exempt from the physics; they are simply very good solutions to it. Nothing is permanent: when better manuals are discovered, the world is reset with them inserted.
4. **The Dao's Forge (proposed).** A screen where the Heavenly Dao works the engine directly: pick an envoy, compose a route or technique from the operation vocabulary, see the engine's predicted result on that envoy's own body, and bestow it as a manual.
5. **Codex's qi field (docs/qi_formations_research.md §1) is adopted.** Its absorption formula and flat intake cap are replaced by the circulation engine: the intake limit is the narrowest open channel.
6. **Death is on.** Qi deviation, combat, beasts and age can kill. Careful cultivators following safe methods should rarely die.
7. **The body diagram** is designed without a reference image. The draft is on the plan page.
