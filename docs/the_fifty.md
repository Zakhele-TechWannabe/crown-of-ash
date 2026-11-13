# The Fifty of the Dao: design, version 1

The owner is the Heavenly Dao. Heaven does not start with hands: it raises them. The village keeps growing on its own; the owner's own project is training the Fifty. Read with docs/stone_guards.md (patterns for a new law-like system), src/combat.gd (fights), src/body_tempering.gd (the path), src/mind.gd (people decide).

## Heaven's Terrace

- A hidden platform on **Heavenly Ridge** (the configured site; keep the location in data so it can move). It is a new site in the sites system (data/sites/, sites_ground.gd). It has:
  - a training ground;
  - dormitories, drawn as standing BuildingArt;
  - five Apostle pedestals;
  - a seam of heaven-stone in the rock.
- Nobody in the valley knows where it is. On the world map the owner sees it, marked as heaven's.
- The Fifty live there. They are **people in the same population** as the villagers: give them their own settlement and household ids, so mind, ties, tempering, combat, injuries, ageing and death all just work. Heaven provisions them, so they are outside the village food economy (they draw no rice). village_life does not walk them in v1; they live in the book. A terrace walk view can come later.

## The candidates

- **50 at the start:** age 12, random sex. Attributes, potential, comprehension, luck, traits and heart (the mind's inherited network) are all randomly generated through the usual population path, so personalities differ.
- **They join the population with nothing:** layer 0, no skills beyond what a 12-year-old has.
- **The same conditions for everyone:**
  - every candidate gets the best tempering method (grade cap Perfect);
  - a teacher (the terrace counts as a master teacher);
  - an unlimited basic stipend of the medicine each gate needs.
  - The difference comes from talent, temperament, choices and luck.
- **Their days:** drills (body_tempering regimen), rest, meditation, and spars with each other (the training spar already exists in mind.gd). Rivalries, friendships, envy and love form through ties.
- **A data file**, data/society/dao.json, holds every number below.

## The tournament (every 5 years)

- On the first day of spring every 5th year, all current **candidates** (not envoys or Apostles) fight a **single-elimination bracket**. The seeding is by the last ranking; the first tournament is random. Byes go to the top seeds.
- **Bouts** use Combat.fight between Combat.person fighters, stopping at **badly hurt**. Add an option to combat.gd, `stop_at` (a wound index: spar = 2; tournament = 3). The non-lethal cap applies. Wounds, healing time and crippling follow through `_hurt` as usual. Deaths should be essentially impossible (the cap stays under dying).
- **Ranking:**
  - champion 1, runner-up 2;
  - semi-final losers 3–4, ordered by harm dealt in the bout they lost;
  - quarter-final losers 5–8, then round-of-16 losers 9–16, in the same way.
- **The top 10 get better resources for the next 5 years:**
  - double medicine doses (faster gates);
  - training rate ×1.3;
  - first claim on the terrace's qi seat (a meditation bonus).
- **Stories:** the bracket, the champion, upsets (a lower seed beats a higher) and injuries. The candidates' minds feel it: winners gain joy and pride; losers who feel envy get spite toward those who beat them (ties event "beaten" exists).

## The peak

When a candidate completes **layer 9** of Body Tempering:
- **every layer Perfect, and fewer than 5 Apostles:** they become a **Divine Apostle** and take a pedestal;
- **every layer Perfect, but the seats are full:** their mind decides whether to **challenge** an Apostle. Ambition and pride push for it; fear holds back. The challenge is a bout to badly hurt against the Apostle they choose (the weakest by power). The loser becomes an envoy; the winner holds the seat. A Perfect peak who doesn't challenge becomes an envoy and may challenge later, at most once a year;
- **not every layer Perfect:** they become an **envoy**.

Candidates who become envoys or Apostles leave the candidate pool. The Fifty stay at 50 people in total (candidates + envoys + Apostles + those being restored).

## Death and return

- **Envoys** die for good.
- **Apostles** who die enter *restoration* on their pedestal and return after **10 years**. It costs:
  - **10 heaven-stone** (the seam yields 1 a year; the stock is shared);
  - **30 Heaven's Will**.
  
  If the stone or Will runs short, the restoration waits.
  
  A restored Apostle comes back at the same layer and grades, with the same memories and ties, and has aged nothing while restored.
- **Heaven's Will (v1 meter):** +6 a year from the heavens; spent on restorations. Reverence income and orders come later, with the envoy orders system.

## Recruiting from the mortal world

An empty place (envoy death, a candidate's death, or before the first 50 fill) can be filled two ways.

1. **The owner picks a mortal.** Add an "Invite to the Dao" button on a person's page in the valley book, shown only while there's a free place.
   - The person's mind decides. Reverence or devotion, ambition and curiosity push toward going; spouse, children and fear hold back.
   - If they accept, they leave the village: a note, family grief (lighter than death), and their walker is removed.
   - They travel to the terrace for days set by the distance, then take the **admission tests**.
   - If they pass, they join as a candidate at their current layer. If they fail, they go home with a story.
2. **A call to heaven.** A button on the Dao page, with a cooldown of 1 year.
   - Each living adult or adolescent (age 10–30) in the valley weighs it: curiosity, ambition, devotion and restlessness push; ties hold back. Some set out on a **pilgrimage**, leaving home.
   - Each pilgrim searches for 1–12 months. The chance to arrive comes from perception, willpower and luck, times a hidden per-person **fate** (random 0–1, rolled once, never shown). Most turn back. A few die on the road (falls, beasts, cold; small, configurable). Those who find the terrace "have a fate with the Dao" and take the tests.
   - If more pass than there are places, the best scores join and the rest go home honoured. (Their story says heaven saw them.)

**Admission tests** are a general, reusable module (src/admission.gd), so future sects use it too. There are four trials, each scored 0–100:
- **talent:** comprehension, potential and luck;
- **body:** strength, endurance, agility and tempering layer;
- **will:** the willpower attribute, the mind's fear and devotion;
- **character:** traits. Cruelty or treachery lower it. The Dao may still take a hard person, but it shows.

A weighted total against a threshold (in data) decides; the record is kept per person. Age limit 10–30 for the Dao.

## The Dao page

A "Heavenly Dao" tab in the valley book (or its own panel if the book is crowded; follow the ui_theme patterns and the HUD conventions):
- **header:** Heaven's Will, heaven-stone, the next tournament (date and countdown), open places;
- **the Fifty:** a sortable list of name, age, layer and grades, last rank, resource tier (top 10 or not), status (candidate, envoy, Apostle, restoring or dead) and a one-word temperament. Clicking a name opens their person page;
- **the Apostle seats:** five cards (empty, held or restoring with years left);
- **the last tournament bracket:** a compact tree or a ranked list with the results;
- **buttons:** Call to heaven, and recent Dao stories (kind "dao").

## Later, not in v1

- **Orders:** hunt, protect, destroy, with walking journeys and Will costs.
- Envoys and Apostles acting in the valley.
- Reverence and defiance in the village.
- **Playing an Apostle** as a character (the owner wants this).
- Terrace walkers.
- Higher realms.

## Tests (tools/test_dao.gd)

- 50 candidates are created: age 12, varied personalities (heart weights differ), outside the food economy, Perfect-capable method.
- The tournament:
  - the bracket covers every candidate;
  - ranks are 1..N, unique;
  - the top 10 get the bonus for 5 years;
  - no deaths in 50 tournaments with seeded candidates;
  - injuries are applied.
- The peak:
  - all Perfect with a free seat makes an Apostle;
  - not all Perfect makes an envoy;
  - Perfect with the seats full leads to a challenge, which resolves the seat and the envoy;
  - the total stays at 50.
- Death:
  - an envoy's death frees a place;
  - an Apostle's death means restoration, which waits for stone and Will, then returns after 10 years at the same layer.
- Recruiting:
  - an invite can be refused or accepted by mind;
  - acceptance removes them from the village;
  - the tests score and record;
  - a call to heaven produces pilgrims, arrivals ≪ pilgrims, and admission fills only the open places.
- Saves: the Dao state survives save and load (use the save system's hooks).
- A 40-year headless sim: print candidates by layer, Apostles, envoys, deaths and tournaments. Report how many years the first Apostle took (expect decades). Tune dao.json so it's plausible: the first envoys in roughly 15–30 years and the first Apostle later.
