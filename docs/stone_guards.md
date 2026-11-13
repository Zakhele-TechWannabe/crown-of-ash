# Stone swordsmen: design, version 1

The first law of the valley, and its enforcers. Read with docs/combat (src/combat.gd) and the "Law & combat" tab of the plan page.

## The law

**No one enters the sect grounds without an invitation.** There is no sect yet, so for now nobody holds an invitation. The only lawful way in is a **work pass**:

- A servant whose workplace is inside the grounds (the plaza, the canteen, the barracks, the shrine) may be inside **during their working hours** (the same hours village_life already uses for "work").
- Anywhere else inside, or inside outside working hours, is **trespass**. The same goes for anyone without a pass.
- Breaking the law is not a crime until someone is caught. **Only those who are seen are hunted.**

**The grounds** are the built sect: the terraces, halls, plaza, stairs, the spirit spring, the peak and the seclusion caves, inside the gates. The Servants' Village, its lanes, the fields outside, the West Road and the Hunters' Lodge are **outside**. Build this as one mask (a Dictionary or a PackedByteArray over the sect bounds) in sect_ground.gd, and draw it in a debug screenshot to check it.

## The guardians

A pair of stone swordsmen stands at **every gate into the grounds**: the gate buildings (`kind == "gate"`) whose doorway leads into the mask. Find them in the sect and site data, including the West Gate and East Gate on the west road. Each pair stands on two plinths, one either side of the gateway, facing out.

- **Never replaced.** A broken swordsman is gone for good. A future sect may only support them.
- **Fighter:** the `stone swordsman` row, the same numbers as the combat page. Power 66, guard 70, speed 9, breath 30, will NEVER (never yields or runs), lethal. Put it in data/society/combat.json beside the beasts.
- **Names:** "the north swordsman of the West Gate" and so on, for the stories.

### How they look (code-drawn, in the 2.2D style)

The tallest figures in the valley: about **1.4 tiles** (22–24 texels) against a villager's one. They stand up as sprites, sorted with walkers, trees and buildings, with an ink outline, top-left light and a soft shadow, like BuildingArt and TreeArt. Make a small `src/guardian_art.gd` with cached textures.

- **Body:** weathered grey stone (Palette.STONE darkened), lit from the left. Simple robe folds, a topknot, a blank calm face with two carved eye lines. Moss patches (Palette.GREEN darkened) on the shoulders and at the hem. A thin crack or two.
- **Sword:** a long straight jian held point-down in front, both hands on the pommel. That's the guard pose.
- **Plinth:** a square stone block one tile wide and half a tile high, with a carved band and a dark seam where it sits in the ground. It stays when its swordsman leaves.
- **States** (one texture each, no animation in v1):
  - **guarding:** on the plinth, sword down, eye lines faintly jade.
  - **pursuing:** sword raised to the shoulder, eye lines bright jade. It glides: stone does not bob like walkers.
  - **frozen:** sword down, no glow, greyer, with extra lichen. It stands wherever it froze.
  - **broken:** a low pile of grey rubble, with the sword's hilt sticking out.

## Sight: only if caught

Distance does not hide you. **Walls, buildings, trees and darkness do.**

- Precompute, once, a **visibility map** for each guardian post: the grounds tiles it can see in daylight. Use a line of sight on the tile grid (Bresenham) from the post, blocked by standing buildings, walls, `standing_tiles`, tree tiles (the ground's `trees_in_block`) and terrace drops of 2 or more levels toward the viewer. Cap it at 60 tiles.
- **At night** (from the evening hour until dawn, as village_life already defines) a guardian sees only within **6 tiles** of its post, still blocked the same way.
- A trespasser's **exposure** is the share of their route inside the grounds that any guardian can see at that hour. Chance of being seen = exposure × 0.9 by day, or exposure × 0.25 at night. Subtract 0.1 per 5 levels of the trespasser's best stealth or hunting skill (scent masking, mountain ambush, trail reading), with a floor of 0.

## When trespass happens

The sim decides, and the map shows it, exactly as fights already work (society decides at the day boundary, village_life stages a scene in daylight or at night).

1. **The mind weighs the risk.** Options whose place is inside the grounds:
   - CULTIVATE at the spring or the peak (`site` ≥ 1);
   - GATHER seven-leaf at the spring;
   - a servant wandering in the evening (a new small case: none in v1).
   
   These get a new question, `["safe from the guardians", 1 − danger × caution]`. Danger is the person's expected chance of being seen (by day or at night, whichever they would pick). Caution is `0.5 + 0.5 × AFRAID`, lowered by ambition, need or spite. **A cautious trespasser goes at night**; a desperate or proud one may go by day. Store the choice (`trip` = day or night).
2. **The trip is resolved** in a new `src/law.gd` (RefCounted, preloaded, no class_name), for example `Law.trespass(society, p, place, at_night) -> Dictionary`:
   - roll seen / unseen from exposure;
   - unseen: the action happens as now (meditation, herb picked) and the note says nobody saw, for example "Zhang Dazhi slipped into the grounds by night and meditated at the spring until dawn. Nobody saw.";
   - seen: the nearest awake guardian pursues. It is a **chase**: speed 9 against the trespasser's running speed (combat.gd's `running`). The trespasser escapes only by **breaking the line of sight**: reaching a building, trees, the gate and out of sight, or water. Model this as a chance from the share of escape cover within reach of the spot where they were seen, times their speed ratio. Caught means **Combat.fight(stone, person, {lethal})**. Mortals almost always die; a tempered body may survive or even break the stone (see "Breaking a swordsman").
   - record a `law` record (day, person, place, seen, outcome, guardian) in `society.breaches`, the same pattern as `society.fights`.
3. **The map stages it** (village_life, like fight stages). The trespasser walks in through the gate or over the wall line at the chosen hour (night scenes are fine: the clock passes through night). If seen, the swordsman steps off its plinth into the pursuing state and glides after them. Then it's a fight scene (harm floats up, as for villager fights), or the runner vanishes into cover. The swordsman walks back and steps onto its plinth.

## The hunt list

Every **seen escape** is written down: `law.hunt_list`, one entry per person, `{person, priority, day, offences}`.

- **Priority** = offence weight × recency × repeat.
  - Offence weights: stealing from the spring 1.0, fighting a guardian 1.0, meditating at the peak 0.7, meditating at the spring 0.6, straying off a work pass 0.2.
  - Recency is `0.5^(days_since / 30)`.
  - Repeat is `1 + 0.5 × earlier offences`.
- **The trail goes cold.** After **21 days** without being seen again, the entry can no longer be tracked and is dropped, with a note: "The trail went cold; the swordsmen stopped looking for X."

## Energy

Each swordsman has **energy 0–100**:

- **On its plinth:** +10 a day (the formation recharges it), up to 100.
- **Walking inside the grounds:** −0.5 a tile. **Outside the grounds:** −1.5 a tile (three times faster).
- **A fight:** −10.
- **Below 25** it turns for home. **At 0 it freezes** where it stands. It stays frozen in v1 (a future sect can carry it home). The village notices: "A stone swordsman stands frozen in the rice paddies."

## Pursuit into the village

Once a day, for the top entry of the hunt list, a swordsman goes only if:

- its partner is on its plinth (at least one of each pair always stays home);
- it has the energy for the round trip plus the fight, with 25 in reserve. The trip length is the walk distance (the village grid path) from its gate to the person's home or workplace.

It walks out (stage it; at high speed resolve it without staging) and finds them by the trail, fights them (`Combat.fight`, lethal), and walks home. Outcomes are noted in the stories.

**Their family can stand with them (v1, simple).** Adults in the same household with body layer ≥ 3 may join. Model it as one combined fighter: sum their power and guard; speed is the slowest. The defenders' harm is split across the joiners afterwards, so each can be wounded or die. Kin who lose someone gain grief and a **grudge** against no person: use a new mind scar on fear and spite. A guardian is stone, not a person, so there's no ties grudge.

### Breaking a swordsman

When a fight's harm on the stone reaches 100, the swordsman is **broken** for good: a rubble sprite, removed from the list of guardians, its gate down to one. That is a great event, noted as an "oath"-level story. The fighter (or fighters) gain renown (+15 reputation) and the village's mood shifts. Some cheer, some fear what comes next; a mind JOY or AFRAID split by a coin flip is fine in v1.

## The Laws page

Add a **"Laws"** tab to the valley book (village_ledger.gd TABS, following the existing page patterns):

- The law in one line, who it binds, who enforces it, and the punishment.
- **The swordsmen:** each with its gate, state (guarding, pursuing, frozen or broken), an energy bar, and kills and breaks.
- **This year:** breaches, seen, escaped, killed, and swordsmen broken.
- **The hunt list:** name, offence, days since, priority, and whether the trail is cold soon.
- **Recent breaches:** the last 10 law records as one line each.

## Stories

New note kinds:
- `trespass`: unseen breaches, under the Conflict filter;
- `guardian`: seen, chased, killed, escaped, a pursuit into the village, frozen, broken.

Death uses `society.die(p, "killed", "...was cut down by the north swordsman of the West Gate")`, with killer -1. Stone is nobody's kin, and there's no ties grudge.

## Not in version 1

- No invitations or jade tokens: there is no sect yet.
- No disciples on watch.
- No formation masters strengthening the plinths.
- No mind approval of the law.
- No stealth skill tree beyond the skills listed above.
- No animations beyond the state textures and gliding movement.

## Tests (tools/test_law.gd)

- The grounds mask includes the plaza and the spring, and excludes the Servants' Village and the West Road.
- Every gate into the grounds has a pair on plinths.
- The visibility map: a tile behind a hall is not visible from the posts; the open plaza in front of a gate is. Night sight is 6 tiles or less.
- A servant inside during their work hours, going to their own workplace, is not trespassing. The same servant there at night is trespassing.
- 1,000 trespasses by an untempered villager at the open plaza by day: most are seen, and most of those seen die. At night far fewer are seen.
- Escapes go on the hunt list. Recency halves priority every 30 days. A trail older than 21 days is dropped.
- Energy: a swordsman never leaves when its partner is out. One without energy for the round trip stays. At 0 it freezes.
- A Perfected Body (layer 9) beats a swordsman about half the time. A broken swordsman stays broken and leaves its gate with one guardian.
- Over a 10-year headless sim (`--headless-sim --years=10`): print breaches, seen, killed, escaped, pursuits, frozen and broken counts. The valley must not be wiped out: at least half the founders' line is still alive.
- Run the full suite. ground_lod, village and sect must still pass.

## Version 1.1: wear, mending, and a card

- **Harm persists.** Each guardian keeps a `harm` value (0–100) between fights, and a fight starts from it: pass the starting harm into Combat.fight with a `start_harm: [a, b]` option, applied before the first blow. Breaking still happens at 100.
- **Cracks show.** The guarding and pursuing textures get crack overlays at harm ≥ 30 and ≥ 60, plus a chip or two missing at ≥ 60.
- **Mending.** Only on its plinth, the old formation beneath the grounds mends a guardian by `mend_per_day` (law.json, start at 2 harm a day). Nothing mends off the plinth, and rubble never mends. A guardian with harm above `retreat_harm` (law.json, 60) won't start a pursuit. Formations (later) will multiply mending and recharge.
- **Clicking a guardian** (or its rubble) opens a small card in the same style and place as the villager card (src/villager_card.gd), following the HUD conventions: a small contextual card, not a big panel. It shows:
  - its name and gate, and its state;
  - an energy bar, and a harm bar labelled by the crack level;
  - power, guard, speed and breath, adjusted for the current harm;
  - kills, trespassers driven off, and fights;
  - its last fight in one line;
  - for rubble: who broke it, and when.
  
  Hover shows its name.
- **Tests (add to test_law.gd):**
  - harm carries between fights;
  - mending only on the plinth, never for rubble;
  - no pursuit when harm is above retreat_harm;
  - the card opens for a guardian and for rubble.
