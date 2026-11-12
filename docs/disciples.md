# Disciples and cultivation (design draft)

Disciples are people. They live in the same population store and use the same attributes, traits, skills, XP,
gates and modifiers as villagers (see `people_skills.md`). What makes them disciples is a spirit root, a place in
the sect, and a **cultivation state**.

## 1. The sect's people

The first sect is small and unranked. Its founding roster is about 24 people, and it grows through recruitment.

| Rank | Count at start | Realm | Role |
|---|---|---|---|
| Sect Master | 1 | Foundation Establishment, early | leads; teaches the core technique; rarely seen |
| Elders | 2 | late Qi Condensation, near Foundation | one runs the Mission Hall and spirit fields, one runs teaching and the Scripture Pavilion |
| Inner disciples | 5 | Qi Condensation 4–7 | personal students of the elders; get the best resources |
| Outer disciples | 16 | Qi Condensation 1–3 or Body Tempering | most of the work: spirit fields, guarding, errands, chores |
| Servants | the village | mortals | unchanged; a servant who awakens a spirit root can enter as an outer disciple |

Promotion runs outer → inner → personal disciple → elder. It is earned with realm, contribution and the elders'
favour, and the simulation decides it.

## 2. Realms

Realms use the classic ladder. Each realm has layers, and every boundary is a bottleneck.

| Realm | Layers | Lifespan | Notes |
|---|---|---|---|
| Body Tempering | 1–9 | 80 | mortal martial path; anyone can start; slow |
| Qi Condensation | 1–9 (13 for geniuses) | 120 | sense and store qi; first spells and techniques |
| Foundation Establishment | early, middle, late, peak | 200 | the dao foundation; a real breakthrough, can fail |
| Core Formation | early, middle, late, peak | 500 | the top of a small sect; legendary here |
| Nascent Soul and above | — | — | defined later; beyond this sect for now |

The realm's layers also unlock skill levels above 35, which matches the qi gate in the skills design. Qi
Condensation lets someone reach level 40, Foundation 45, and Core 50.

## 3. Cultivating (the daily sim)

**Qi gained per day:**

`qi/day = hours meditating × root (grade × purity × element match) × qi density of the place × technique grade × resources × comprehension × modifiers`

- **Hours meditating:** set by the disciple's schedule. Outer disciples spend more hours on chores, inner disciples
  more on cultivation.
- **Qi density:** the summit and the spirit spring are high, the outer tier is medium, and the village is low. Where a
  disciple lives and meditates therefore matters, and housing is a reward.
- **Technique:** each manual has an element, a grade (mortal / yellow / profound / earth / heaven) and a realm cap.
- **Resources:**
  - **Spirit grains:** spirit rice and the other spirit grains finally get eaten. They are a disciple's staple and a
    small qi bonus.
  - **Later:** pills and spirit stones.

**Breakthroughs at each layer and realm:**

- **Conditions:** a full qi bar, plus conditions in the same style as skill gates. These include realm-specific
  requirements such as a Foundation Establishment pill, seclusion, or an insight.
- **Chance:** an attempt has a success chance. A failure means a setback (injury, lost qi, weeks of recovery),
  **never death** unless the owner later asks for it.

**Other activities:**

- **Martial practice and sparring:** build Martial skills and Body Tempering.
- **Lessons:** elders teach. These use the existing teacher rule, and also raise comprehension of the manual being
  taught.
- **Sect duties:** tending spirit fields, guarding the gates, errands to the market city, hunting in the dark forest.
  This is where the Mission Hall and contribution points come in later.

## 4. Recruitment

**The annual recruitment fair, in spring:**

- **Who comes:** youths from the village, the road and the Western Market City are tested at the gate.
- **How they're tested:** a spirit-root stone reveals the hidden root.
- **Who joins:** those with a root and good character traits.

**Rare cases:**

- **Late awakeners:** a servant awakens a root, or a wandering cultivator asks to join.
- **The chronicle** records every entrant, e.g. "Spring fair, Year 3: 41 tested, 2 roots found; Lin Xia (water, middle
  grade) enters the outer court."

## 5. What the sect needs (the economy link)

**Disciples consume:**

- **Food:** spirit grains, plus ordinary food.
- **Supplies:** cloth for robes, wood, iron for weapons, medicine herbs.
- **Later:** pills and spirit stones.

**Disciples produce:**

- **Labour:** care of the spirit fields.
- **Protection:** for the village (later threats).
- **Income:** game and herbs from the dark forest, and missions for the market city.
- **Spirit materials:** finally a reason to have them. Spirit wood, jade and spirit herbs can be gathered only by
  cultivators.

**Village deliveries:** the village sends food and goods up to the sect. These are the "village ↔ sect deliveries"
from the long-term list.

## 6. Places in the sect (already drawn, now given use)

| Place | Use |
|---|---|
| Summit hall | Sect Master's seclusion, ceremonies |
| Elders' courts | elder residences, personal disciples |
| Inner court | inner disciples' rooms; high qi density |
| Outer court dormitories | outer disciples, shared rooms |
| Spirit fields and spring | spirit grains; meditation spots |
| Training grounds | sparring and martial practice |
| Scripture Pavilion | manuals and lessons |
| Mission Hall | tasks and contribution (later) |
| Gates | guard posts |

## 7. UI (same patterns as the rest)

**People tab:**

- **Grouping:** gains a "Sect rank" grouping (Master › Elders › Inner › Outer).
- **Cards:** realm and layer are shown as a coloured badge.

**Person page:**

- **Cultivation section:** a realm and layer bar with the qi progress, the spirit root (once revealed), the technique,
  and any breakthrough attempts.

**A new Sect tab:**

- **Headline numbers:** roster by rank and realm, qi density map, resources (spirit grains days left), and this
  season's breakthroughs.
- **Recruitment:** the next recruitment fair.

**Chronicle:** breakthroughs, failed breakthroughs, promotions, recruitment and insights.

**In the world:**

- **Walking:** disciples walk in the sect like villagers do.
- **Robes:** colours by rank (outer grey-blue, inner white, elders dark).
- **Meditation:** meditators sit at qi spots.

## 8. Build order (after the people and skills run lands)

1. Cultivation state, realms and qi gain, built on the population store. Spirit-root testing. A founding roster of
   24 with history: ages, realms, techniques.
2. Sect places given schedules: disciples walk, meditate, spar, tend the fields and eat spirit grains.
3. Breakthroughs, setbacks and the chronicle. The Sect tab, the rank grouping and the cultivation section of the
   person page.
4. Recruitment fair, village deliveries, and gathering spirit materials.
5. Later: the Mission Hall and contribution, pills and alchemy, threats.
