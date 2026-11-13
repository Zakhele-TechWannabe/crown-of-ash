# The valley book, cultivation first: redesign spec

**Approved by the owner on 13 November**, from the mockup on the plan page (Interface tab, "The valley book, cultivation first").

The owner's words: the UI is getting complex and less friendly; they want things spaced properly, grouped nicely and easy on the eyes. This is a cultivation world, so cultivation comes first and life skills are supporting.

This spec **includes** docs/person_page.md (attribute numbers, lifespan, the skill graph) and the guardian card from docs/stone_guards.md "Version 1.1" (wear, mending, card). Implement both as part of it.

## Navigation

- Replace the horizontal strip of 11 tabs (village_ledger.gd `TABS`) with a **grouped vertical sidebar** on the left of the book. On narrow windows it collapses into a "Sections" button.
- The groups, in order, use the existing pages, merged or renamed as shown:

| Group | Section | Built from |
|---|---|---|
| **Cultivation** | Cultivators (the default page) | new: the people browser filtered and ordered for cultivation |
| | Paths & realms | the old Tempering page: layers, gates and grades in the valley, plus qi cultivation stats |
| | Medicine & methods | the medicine and method parts of Tempering and the wild supply |
| **Heaven** | The Fifty | a placeholder page: "Raising the Fifty: coming soon" |
| | Laws & guardians | the old Laws page |
| **People** | Everyone | the old People browser |
| | Families & factions | the old Society page |
| | Chronicle | the old Chronicle |
| **The valley** | Overview | the old Overview |
| | Food | the old Food |
| | Materials & work | the old Materials and Work, merged into cards |
| **The wild** | Forest & beasts | the old Forest |
| | Bestiary | the old Bestiary |

- Remember the last section opened. Keyboard shortcut L opens the book (as now).

## One rhythm on every page

1. a **title** (heading font);
2. a **summary row**: 3–5 small number cards (big number, small caption);
3. the **content in cards**, with a heading each.

- **Spacing:** one scale only, 8, 12, 16 and 24 px. Put the constants in ui_theme.gd and use them everywhere: margins, separations, card padding.
- **No horizontal scrolling anywhere.** Grids wrap by the available width.
- **Numbers** are right-aligned in tables. **Every bar is labelled** with its value.
- **Colours and fonts** only through ui_theme.gd and palette.gd. Autowrap labels inside HBoxContainers need SIZE_EXPAND_FILL, or they stack letter by letter (the `_fit_label` pattern).
- Keep the parchment look (the mockup uses the game palette). Lower the visual noise: fewer borders, more whitespace, and group related fields in cards.

## Cultivators: the default page

- **Summary:** how many are tempering, at a gate now, spirit roots revealed, the highest layer or realm in the valley, and qi cultivators.
- **Filters in labelled rows:**
  - **Path:** All / Body Tempering / Qi cultivation / Not yet started.
  - **Stage:** Layers 1–3 / 4–6 / 7–9 / At a gate / Perfect grades. For qi: realm, and layer bands within it.
  - **Also:** Spirit root / Training now / Injured / Has a teacher / More ▾ (Hungry, Unhappy, Elders, Children, Recent insight).
  - **Sort:** Stage / Grade / Talent (comprehension and potential) / Age / Years left.
- **Advanced fold**, collapsed by default: the old free-text query (`age:12-30`, `skill:id>=16`) and the discipline sort, for power use.
- **Rows** (the virtual list stays, for performance):
  - name, with "age · trade · district" as a subtitle;
  - **path and stage** ("Iron Bone · Middle", "Qi Condensation 3", "Not yet tempering");
  - a **lifespan bar** with "17 of ~82 years";
  - **reason tags**.
- **Notable, explained:** `notable_reason` (people_browser.gd) returns only the first reason. Make it return **all** of them. The reasons are:
  - at a gate;
  - spirit root revealed;
  - layer 3+;
  - an insight in the last 90 days;
  - a master of a craft (level 31+);
  - drilling under a teacher;
  - an elder (60+);
  - plus rare talent (top 10% potential or comprehension), injured and training now.
  
  Each tag has a tooltip saying why. A **legend line** under the list explains them. "Worth knowing" (the cards on Everyone) shows all the tags too.

## Everyone

The same list and row design. Its default filters lean on life (trade, household) instead of path, but the path and stage column stays.

## The person page: three tabs instead of six

Merge person_book.gd `TABS` into:

1. **Overview:**
   - the story and recent events;
   - age and the **lifespan bar** with what extends it ("Body Tempering raises it: a Perfected Body lives to 100"; a realm's lifespan for cultivators);
   - path and stage;
   - all the notable tags;
   - the current activity;
   - household.
2. **Cultivation:**
   - the body figure, with layers and grades, the gate and what it needs, method, teacher and medicine;
   - qi, realm and spirit root;
   - then **Body and gifts**: all 8 attributes **with numbers** and potential markers (docs/person_page.md), and a Talents row;
   - then **Supporting skills**: the **skill graph** (docs/person_page.md) with the compact list under it.
3. **Heart & ties:** mind (feelings, urges, goal, recent decisions), the family graph, and the ties graph and grudges, each in its own card.

## The guardian card

Clicking a stone swordsman, or its rubble, opens a small card like the villager card. Follow the HUD conventions: a small contextual card, not a big panel. Include the wear and mending rules from docs/stone_guards.md, Version 1.1.

## Tests

- Update test_ledger_ui.gd and test_people.gd, and add a test for:
  - every section opening from the sidebar;
  - the Cultivators filters selecting the right people (a seeded population with known layers);
  - all reasons appearing as tags;
  - the 8 attribute numbers;
  - the lifespan text and bar;
  - the skill graph building;
  - the guardian card opening;
  - no autowrap label narrower than 40 px (letter stacking).
- Add the test_law.gd wear and mending checks from stone_guards v1.1.
- The full suite passes.

Render the main pages headlessly to out/ui/book_*.png and check them visually for spacing, grouping and nothing cut off.
