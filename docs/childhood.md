# Childhood: design, version 1

Owner rule: **children do nothing productive before 12.** Childhood shapes who they become. Numbers go in data/society/childhood.json.

## Stages

**0–2, infants**
- They have no job duties, no skill practice and no walker on the map (they are "in arms at home").
- **Care cost:** one parent, the mother by default, or the father if the mother has died or is away, works `care_hours_cut` (start at 40%) fewer hours in the child's first year and 20% fewer in the second. Apply it to the parent's practice and output: population task hours, and the economy's labour where it counts workers.
- The activity text reads "an infant, at home with <parent>".

**3–5, little ones**
- No duties. On the map they are a walker that stays near home and the square ("playing near home").
- Family ties grow: weekly familiarity and opinion gains with parents and siblings (ties.event "meal"-like, or a new "family_time" event appended at the end of relationships.json events).
- **Upbringing scars the heart** through mind.scar:
  - a warm home (parents' mood high, no hunger): devotion +, fear −, small;
  - hunger in the household: fear +, ambition +;
  - a parent's death: grief already fires; add fear + spite, small;
  - parents who fight (brawl or a bitter confrontation involving a parent): spite +.

**6–11, children**
- No duties and no skill XP. On the map: playing in **groups** near the square, chasing (walkers moving between nearby points as a cluster).
- **Playmates:** each week, children in the same district have a chance of a play event that builds ties. Familiarity and opinion go up, with occasionally a small negative ("a quarrel"). Childhood friends and rivals carry into adulthood and feed the marriage, confrontation and spar systems naturally.
- **Tagging along:** sometimes (`tag_along_chance` a week) a child follows a parent or neighbour to their workplace for a day. On the map they walk with them and the activity reads "watching <name> at the smithy". It gives **no XP**. It raises the child's **interest** in that trade: a new per-person Dictionary of interest by job, 0–1.
- **Talents show:** once per child between 6 and 11, when one of their attributes or potentials is notably high (top 15% for their age) or comprehension is high, write a story note ("talent"), for example "Li Wei is strong for her age", "the Wu boy remembers everything he hears", "Zhao Lan's hands are quick and sure". Base it on the real hidden values. Put these under the Family filter, or a new "Children" filter in stories_rail.gd.
- **Wandering:** a small weekly chance a child wanders to the forest edge or the stream and comes back with a story ("found a bird's nest", "fell in the stream"). Rarely a scrape (a bruised injury of 2–5 days). Once wildlife exists, use its encounter rules: children flee, and adults nearby intervene.
- **Bodies grow:** attributes grow toward potential with age, as they already do. **Childhood hunger** (household hunger while under 12) permanently lowers potential by a small amount per hungry month, capped, so famines mark a generation.

**At 12, choosing a trade**
Replace "take the parent's job" (society.gd: at 12–18 a "child" takes `store.job[parent]`) with a choice. Score each village job by:
- **interest**, from tagging along;
- **aptitude**, from the job's key attributes against the child's attributes;
- **the village's need** (open places or shortages: the economy and village_life know which trades are short);
- a small **family pull** toward the parent's trade.

Pick the best, with some randomness, and write a note: "At twelve, Li Wei chose the smithy over her mother's paddies."

## Code pointers

- **src/population.gd:**
  - `add_child` registers the "child" job with ["chores"]. Make the child job have no duties.
  - `_tick_person` lets under-12s practise housekeeping (`if years < 12 and task.discipline != "housekeeping.housekeeping"`). Remove all task practice under 12.
- **src/society.gd:** the job-at-12 rule.
- **src/mind.gd:** `scar` and `feel`.
- **src/relationships.gd:** `event`. New event kinds go at the **end** of the events in relationships.json, because grudge causes are stored by index.
- **src/village_life.gd:** walkers, schedules, kind 8 "playing near home and the square". Newborns are not walkers yet. Add walkers for children from 3 when the village has room (WALKER_LIMIT), and make sure births and coming of age update the walkers (`_tend_the_dead` pattern, economy.walkers_changed).
- **src/person_book.gd**, **src/villager_card.gd** and the lists: the activity text for children, and show "interests" on a child's page.
- **Saves:** all new state (interests, care, talent notes given) must go through the save system's hooks.

## Tests (tools/test_childhood.gd)

- Under 12, no skill XP at all over a simulated year; a 12-year-old starts practising.
- An infant's parent works fewer hours in year 1 than a childless peer.
- Play builds ties between children of the same district over a year.
- Tagging along raises interest, not XP.
- Talent notes match the real top attributes.
- Childhood hunger lowers potential; it is capped.
- At 12 the trade choice can differ from the parent's when interest and aptitude point elsewhere. Over many children, there's a mix.
- The full suite passes.
