# People: attributes, skills and growth (design draft)

A villager is never controlled by hand. The simulation decides who does what, and people grow from what they do. The
skill tree can therefore be deep, because the machine manages it, not the player.

## 1. What every person has

**Visible attributes** run from 1 to 20. A typical adult scores 8–12.

| Attribute | Grows from | Used by |
|---|---|---|
| Strength | heavy labour (logs, stone, ore, ploughing) | woodcutting, quarrying, mining, smithing |
| Endurance | long work days, cold and heat, walking | everything (fatigue), farming, hunting |
| Agility | hunting, climbing, martial practice | hunting, fishing, martial |
| Dexterity | fine work (weaving, carving, cooking) | crafts, medicine, archery |
| Perception | hunting, foraging, prospecting | hunting, foraging, mining (finding veins), trade |
| Intellect | reading, bookkeeping, medicine, planning | scholarship, medicine, trade, leadership |
| Willpower | hardship, long practice, meditation | breakthroughs, martial, (later) cultivation |
| Charisma | trade, leading work crews, teaching | trade, leadership, teaching |

**Hidden attributes** are set at birth and only revealed by events or a sect's testing.

- **Potential** is a per-attribute cap of 10–20. Training cannot push an attribute above it.
- **Comprehension** is a talent multiplier from 0.5 to 2.0. It sets how fast the person learns and how likely they
  are to find an insight.
- **Spirit root:**
  - About 97% of mortals have none.
  - The rest have 1–5 elements, a purity value and a grade: Trash, Inferior, Middle, Superior or Heavenly.
  - The 10 root types plug in here.
- **Constitution** is a rare special physique, such as a Stone body or a Cold-yin body. It changes some growth rates.
- **Luck** slightly affects insights, rare finds and accidents.

**Traits:** each person has 1–3, from about 40, rolled at birth. Some are gained through life events.

- **Examples:** Diligent, Lazy, Green thumb, Strong back, Night owl, Patient, Hot-tempered, Curious, Clumsy,
  Born teacher, Stubborn, Animal friend, Keen eye, Iron stomach, Frail, Long-lived.
- **Effect:** each trait changes XP rates, output, mood or job preference. For example, Green thumb gives +30% Farming
  and Gardening XP and +10% crop care.

## 2. The skill tree

**Size:** the full catalogue is **100 domains and 1,500 disciplines**, about 15 per domain. Each discipline has 3–6
specialisations, about 6,000 in all.

- **Format:** everything lives in data files (`data/skills/`), never in code.
- **Order:** the domains the village uses now are fleshed out first, in full detail. Every other domain is named and
  described from the start, with its disciplines and specialisations filled in over time.

**Layers:**

- **Domains** are broad areas, such as Grain farming or Smithing and metalwork.
- **Disciplines** are what a job or activity trains, such as Farming or Blacksmithing.
- **Specialisations** are narrower techniques, such as Paddy rice or Toolmaking. Each one unlocks when its discipline
  reaches a set level (5–30), often with an attribute requirement as well.

Every discipline and every specialisation has its own level from 0 to 50 (see section 3).

**Spheres:** the 100 domains are grouped into ten, about 10 domains each:

| Sphere | Example domains |
|---|---|
| Land | Grain farming, Gardens, Orchards, Husbandry, Irrigation, Forestry |
| Wilds | Game and hunting, Waters and fishing, Wild harvest, Beast lore, Survival |
| Earth and metal | Stone and quarry, Mines and ores, Clay and kilns, Smelting, Smithing and metalwork |
| Craft | Woodworking, Cloth and thread, Hides and leather, Paper and ink, Lacquer |
| Household | Kitchen, Brewing, Healing, Child rearing, Housekeeping |
| Building and works | Masonry, Roads and bridges, Water works, Shipbuilding |
| Society | Commerce, Law, Leadership, Diplomacy, Teaching, Espionage |
| Arts and learning | Letters, Calligraphy, Music, Painting, Astronomy, Geomancy |
| Martial | Unarmed arts, Weapons, Archery, Riding, Tactics, Body tempering |
| Cultivation (locked) | Qi arts, Alchemy, Artifact refining, Formations, Talismans, Beast taming, Soul arts |

Locked domains and nodes are shown greyed out with their condition, so the cultivation path is visible from day one.

**Starting core:** the village's current work uses these, shown with unlock levels on the 0–50 scale:

| Sphere | Discipline | Specialisations (unlock) |
|---|---|---|
| Land | Farming | Paddy rice (Farming 5), Dry grains (10), Irrigation (15, Int 10), Seed selection (25, Int 11), *Spirit fields (locked: spirit root or sect teaching)* |
| | Gardening | Greens, Roots and tubers, Gourds and melons (10), Herb beds (15), Composting (15) |
| | Orcharding | Fruit trees, Grafting (20, Dex 11), Beekeeping (10) |
| | Husbandry | Pigs, Poultry, Draft animals (15), Breeding (25, Int 10), *Spirit beasts (locked)* |
| Wilds | Hunting | Tracking (Per 10), Archery (Dex 10), Trapping, Butchery (10), *Demon-beast hunting (locked)* |
| | Fishing | Net fishing, Line fishing, Pond keeping (15) |
| | Foraging | Mushrooms, Wild herbs (Per 10), Wild fruit, *Spirit herb gathering (locked)* |
| | Woodcutting | Felling (Str 10), Sawing, Charcoal burning (15), Forestry (25) |
| Earth and metal | Quarrying | Stonecutting (Str 11), Masonry (15), Sculpting (30, Dex 13) |
| | Mining | Prospecting (Per 11), Tunnelling (Str 11), Ore sorting, Shoring (20), *Spirit-vein mining (locked)* |
| | Claywork | Pottery, Brick and tile firing (10), Kiln mastery (25) |
| | Smithing | Bloomery, Blacksmithing (10), Toolmaking (15), Weaponsmithing (25, Str 12), *Artifact refining (locked)* |
| Craft | Carpentry | Joinery, Cartwright (15), House building (20), Shipwright (30) |
| | Textiles | Spinning, Weaving (10), Dyeing (15), Tailoring (20, Dex 11), *Spirit silk (locked)* |
| | Leatherwork | Tanning, Leathercraft (10), Armour (25) |
| Household | Cooking | Staples, Preserving (10), Brewing (15), Banquet cooking (30), *Spirit cuisine (locked)* |
| | Medicine | Herbal remedies (Int 10), Bonesetting (10), Midwifery (15), Acupuncture (30, Dex 13), *Alchemy (locked)* |
| Society | Teaching | Apprenticing (10, Cha 10), Child rearing |
| | Trade | Haggling (Cha 10), Bookkeeping (Int 10), Appraisal (20, Per 12) |
| | Leadership | Crew foreman (Cha 10), Planning (Int 11), Village elder (35) |
| Arts and learning | Scholarship | Reading, Writing, Calligraphy (15, Dex 11), Classics (25) |
| Martial | Unarmed and weapons | Fist and palm, Staff, Spear, Blade (each Agi 9), *Body tempering (locked)* |
| *Cultivation (locked)* | *Qi sensing, Meditation, Alchemy, Artifact refining, Formations, Talismans (each a discipline in its own domain)* | *needs a spirit root and sect entry* |

**Perks:** every discipline grants a perk every 5 levels, up to 10 per discipline. Some examples:

- **Farming:**
  - *Reads the weather* (level 10): bad-year loss −25%
  - *Paddy sense* (level 20): +15% care
  - *Hundred-harvest hands* (level 30): +20% yield on any plot they oversee
- **Smithing:**
  - *Steady hammer* (level 10): fewer ruined pieces
  - *Fine edge* (level 20): +1 quality tier on tools
  - *Heart of the forge* (level 30): can attempt masterworks
- **Cooking:**
  - *Stretch the pot* (level 10): −10% food used
  - *Pickle master* (level 20): preserves spoil at half rate
  - *Feast maker* (level 30): mood bonus to the whole village

## 3. Levels and titles

Each discipline and specialisation runs from **level 0 to level 50**, in ten tiers of five levels.

| Levels | Title | Who gets there |
|---|---|---|
| 0 | Untrained | |
| 1–5 | Novice | anyone, in weeks |
| 6–10 | Apprentice | months of work |
| 11–15 | Journeyman | a few years; most working adults stop here |
| 16–20 | Skilled | a decade of dedicated practice |
| 21–25 | Adept | the best hand in a village |
| 26–30 | Expert | known across a district |
| 31–35 | Master | a lifetime and an insight; **the mortal ceiling is 35** |
| 36–40 | Grandmaster | needs qi: cultivators, or mortals fed spirit resources |
| 41–45 | Sage | a sect elder's craft |
| 46–50 | Peerless | legends; perhaps one per generation in a whole region |

**XP needed:**

- **Formula:** XP to the next level is `100 × 1.18^level`, tuned so that 5 levels is roughly one step of life
  commitment.
- **Rough timing:** full-time work reaches Journeyman (11) in about 2–3 years. Master (31) takes about 30 years plus
  the gates.
- **Gate levels:** every tier boundary is a gate (see section 5).

## 4. Gaining experience

**Base rule:** each hour spent on an activity gives XP to the specialisation in use.

- **Spillover:** 40% also goes to its discipline, and 5% to related disciplines. For example, Woodcutting feeds
  Carpentry, Hunting feeds Butchery, and Cooking feeds Medicine.
- **Formula:** `XP/hour = base × attribute × talent × age × mood × teacher × difficulty × tools × traits`

| Factor | Rule |
|---|---|
| attribute | (key attribute / 10). Each specialisation names its 1–2 key attributes. |
| talent | Comprehension, 0.5–2.0 |
| age | under 12: 1.6 (play-learning, only light tasks); 12–17: 1.4; 18–35: 1.0; 36–50: 0.8; 51–65: 0.55; 66+: 0.35 |
| mood | content 1.1, well fed 1.0, plain fare 0.9, hungry 0.6, starving 0 |
| teacher | Working beside someone at least 5 levels higher gives +50%, or +80% with the *Born teacher* trait. Teaching alone can raise a pupil only to the teacher's level − 1. |
| difficulty | Full XP when the task's difficulty is within ±5 of the person's level. Below that it falls to 10%, so you plateau on easy work: gathering firewood can't make you a Master woodcutter, but felling old hardwood can. |
| tools | crude 0.8, common 1.0, fine 1.15, masterwork 1.3 |
| traits | e.g. Diligent +20%, Lazy −25%, Curious +10% on new skills |

**External factors (spirit fruits and the like).** These are planned now and filled in later.

All XP and attribute rates go through one general **modifier** system. A modifier has five parts:

- **source:** a spirit fruit, a pill, a manual, a formation, a place, a festival or an event
- **target:** one skill, a discipline, a whole domain, an attribute, or "all learning"
- **effect:** an XP multiplier, a flat XP grant, a bottleneck bypass, an attribute gain, or a Potential raise
- **duration:** instant, days, years, or permanent
- **stacking:** a rule for combining with other modifiers, with diminishing returns

**Example content for later:**

- **Enlightenment tea:** all XP +30% for 3 days.
- **Spirit peach:** +1 permanent Endurance Potential.
- **Insight incense:** gives a free insight roll.
- **A manual of the Hundred Grains:** Farming XP ×1.5, and lets a reader pass the Expert gate without a master.
- **Qi-rich ground:** XP ×1.1 for work done on it.
- **A Gathering formation:** XP ×1.2 in its area.
- **Spirit resources for mortals:** these are how a mortal breaks the level-35 ceiling.

**Other ways to gain XP:**

- **Firsts:** the first time someone does something (a new crop, a new ore) gives a one-off XP bonus.
- **Failures:** a ruined piece or a poor harvest still gives 50% XP.
- **Watching:** children who spend time near a working parent gain 20% of that XP in the parent's discipline.

## 5. Bottlenecks and breakthroughs (the xianxia flavour)

Some levels are gates. Each gate needs a condition, not only XP. At a full XP bar a person is *stuck* and keeps
banking XP until the condition is met.

Every tier boundary (levels 5, 10, 15 ... 45) is a gate. Gates get harder as you climb. Each discipline sets its
own conditions; Farming is the example:

| Gate | Condition (Farming example) |
|---|---|
| 5 → 6 | 30 days of practice |
| 10 → 11 | a full season cycle with care ≥ 70% |
| 15 → 16 | 3 years of practice, key attribute ≥ 12 |
| 20 → 21 | a milestone (a plot yielding ≥ 120% of base) |
| 25 → 26 | taught by someone at 30+, *or* an insight |
| 30 → 31 | an insight, key attribute ≥ 14, 10+ years of practice |
| 35 → 36 | **qi required**: a cultivator, or a mortal sustained by spirit resources (via modifiers) |
| 40 → 41, 45 → 46 | an insight plus a life-defining work, and cultivation realm requirements (defined later) |

**Insight events:**

- **Chance:** a daily roll while stuck, scaled by Comprehension, Willpower and Luck.
- **Triggers:** a rare event can set one off, such as a storm during the harvest or a festival.
- **Record:** each insight is written to the chronicle, e.g. "Under the autumn storm, Wang Erniu understood the paddies. (Farming: Master)".

**Rust:** an unused skill above Journeyman (level 15) slowly loses XP, but it never drops below the floor of its title.

## 6. Attribute growth and ageing

**How attributes change:**

- **Practice:** each day an attribute gains a little from that day's work, scaled by how close it is to Potential.
- **Age curve:** physical attributes peak between 20 and 35 and decline after 50. Mental attributes peak later and
  decline after 65.
- **Recovery:** hunger and illness slow growth. Good food and a varied diet speed recovery.

**Children:**

- **Inheritance:** attributes and Potential come from the parents, plus some noise.
- **Spirit roots:** a root can very rarely appear from mortal parents. It is much likelier if a parent has one.
- **First job:** around 12, children apprentice into a parent's or a master's job.

## 7. What skills change in the world

**Each person's work is affected in four ways:**

- **Output:** `0.5 + 0.03 × level`, plus perks.
  - **A Journeyman (13)** produces about 0.9×.
  - **A Master (33)** produces about 1.5× an average worker, and 3× an untrained one.
  - **Beyond level 35** it keeps climbing (2× at 50), which is where cultivator craftsmen pull away.
- **Quality:** goods get quality tiers (crude, common, fine, excellent, masterwork) from the skill roll. Fine tools
  then boost other people's work.
- **Speed and waste:** skilled workers finish faster and spoil or break less.
- **Unlocks:** some goods and buildings need a skill level, e.g. bricks need Claywork 10 and iron tools need
  Blacksmithing 15.

**Village-wide:**

- **Jobs are assigned automatically** by aptitude and need. Later, the owner can set priorities.

## 8. Where it shows

**Person card:**

- **Attributes:** shown as eight short bars.
- **Skills:** the top 3 skills with their titles.
- **Traits:** shown as chips.
- **Status:** the current XP activity, and a "stuck at a bottleneck" marker when it applies.

**People tab:**

- **Columns:** a best-skill column and a title column.
- **Sorting:** by any discipline.

**Skills view (a drawer page):**

- **The tree:** shown as inventory-style cards (Domain, then Discipline, then Specialisation), with the village's best
  practitioner and how many people know each one.
- **Click-through:** clicking a person opens their personal tree.

**Chronicle:** level-ups at Skilled (16) and above, insights, firsts, and masterworks.

## 9. Cost on the machine

**How skills are stored:**

- **Layout:** the catalogue of 1,500 disciplines and about 6,000 specialisations is loaded once and shared by
  everyone.
- **Per person:** only the skills a person has actually touched are stored, typically 10–60 entries of level plus XP,
  together with 8 attributes and a few hidden values.
- **Size:** roughly 1 KB per person, so 100,000 people take about 100 MB.

**How often it updates:**

- **Ticks:** the skill update runs once per game day, not per frame.
- **Batching:** it is batched over the day so there are no spikes.
