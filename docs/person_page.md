# Person page: real numbers, lifespan, and a skill graph

These changes are to src/person_book.gd in the valley book. Follow src/ui_theme.gd and src/palette.gd: no literal colours or font sizes. Godot autowrap labels inside HBoxContainers need SIZE_EXPAND_FILL.

## Attributes show their numbers

"Body and gifts" today shows words only ("Strength · below most"). Show the real value **and** the word, for example "Strength 8.3 · below most", along with:
- the bar;
- the person's **potential** for that attribute as a faint marker on the bar (population.potential);
- the tooltip "8.3 now, potential 14 (of 20)".

Show all 8 attributes: strength, endurance, agility, dexterity, perception, intellect, willpower and charisma. Today only some are visible in the screenshot, and the grid gets cut off. Make sure all 8 fit at the book's width: 2 or 4 columns that wrap properly.

Also add **comprehension**, **luck**, **constitution** and the **spirit root** (when revealed) as a small "Talents" row with numbers.

## Lifespan

On the Story tab header and on Body & cultivation, show:
- "Age 12 · expected lifespan 70";
- what extends it: "Body Tempering raises it: Perfected Body lives to 100";
- for cultivators, the realm's lifespan.

Use society.lifespan(p) and the body.json and cultivation rules for the "raises it" line.

Add a thin **life bar** (age ÷ lifespan) beside it. Warn in red when within 5 years of the end.

## Skills as a graph

The Skills tab becomes a **graph**, like the skill tree on the plan page and in the same visual language as the Ties and Family graphs. Reuse src/ego_graph.gd if it fits, or make src/skill_graph.gd as a Control.

- **Nodes:** sphere → domain → discipline → skill, only for what the person has (plus, faintly, the next skills they could unlock in those disciplines). Node size or colour shows the **level and title**.
- **Edges:** parent to child, plus "related_disciplines" spillovers as faint dashed links.
- **Interaction:** hover a node for its name, level, title, XP to the next level and practice days. Click to focus a branch. The person's best skills are labelled by default.
- **The list stays** below the graph, compact, so nothing is lost.

## Tests

Extend tools/test_ledger_ui.gd or add tools/test_person_page.gd:
- the 8 attribute labels contain their numbers;
- the lifespan line exists and the life bar is right;
- the skills graph builds nodes for a person with skills, and the list still exists;
- no label renders letter-per-line (width check on the autowrap labels).
