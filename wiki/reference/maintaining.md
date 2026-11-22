# Maintaining this wiki

This is the maintainer guide for Claude and future editors. Player pages describe observed implementation, not every idea present in a design document. Keep one topic per page and use relative links to related pages.

## Update rules

1. Read the affected source files, including the final dated sections. In `qi_condensation.md`, the opening status and many earlier failures are historical.
2. When notes disagree with executable behaviour, inspect the current code. Code wins over older notes. Add an `!!! note "Unverified"` box explaining a remaining discrepancy; do not silently average competing numbers.
3. Mark designed-but-unbuilt content with an `!!! admonition "Planned"` box. A data entry or a named skill does not prove a playable system.
4. Keep numbers in tables where helpful. For JSON tables, record the source and selection rule below. Regenerate counts and rows together when the data changes. Retain GBIF attribution for catalogue-derived information.
5. Preserve fixture provenance: date, prepared foundation, duration, identities and whether days are absolute. Do not present a seeded comparison as a universal progression timer or win chance.
6. Update cross-links, explicit navigation and this map when adding or renaming a page. Add substantive mechanic changes to [the changelog](changelog.md).

## Page-to-source map

Paths below are repository-relative source references, not website links. Wildcards identify a configuration family; inspect the specific changed members.

| Wiki page | Authoritative sources / update hints |
|---|---|
| [index.md](../index.md) | docs/cultivation_design.md; docs/valley_book.md; docs/daos_eye.md |
| [world/valley.md](../world/valley.md) | docs/qi_field.md; docs/valley_book.md; data/sites/index.json; data/qi/field.json |
| [world/places.md](../world/places.md) | data/sites/index.json; data/sites/heaven.json; data/sects/first_sect.json; docs/disciples.md; docs/stone_guards.md |
| [world/qi.md](../world/qi.md) | docs/qi_field.md; docs/qi_formations_research.md §1; data/qi/*.json; docs/wildlife_implementation.md |
| [world/time.md](../world/time.md) | docs/world_save.md; docs/materials.md; data/wild/ecology.json; docs/qi_condensation.md |
| [people/society.md](../people/society.md) | docs/people_skills.md; data/society/mind.json; data/society/relationships.json; docs/childhood.md; docs/stone_guards.md; src/society.gd |
| [people/childhood.md](../people/childhood.md) | docs/childhood.md; docs/world_save.md; data/society/childhood.json; src/childhood.gd |
| [people/skills.md](../people/skills.md) | docs/people_skills.md; docs/people_skills_implementation.md; docs/people_skills_phase1_results.md; data/skills/rules.json; data/skills/domains/*.json |
| [people/law.md](../people/law.md) | docs/stone_guards.md; data/society/law.json; src/law.gd |
| [people/fifty.md](../people/fifty.md) | docs/the_fifty.md; docs/disciples.md; data/society/dao.json; src/fifty.gd; src/admission.gd |
| [people/death.md](../people/death.md) | src/society.gd lifespan; src/body_tempering.gd lifespan; project.godot simulation setting (read only); data/society/cultivation.json; data/society/body.json; docs/disciples.md; docs/world_save.md |
| [cultivation/overview.md](../cultivation/overview.md) | docs/cultivation_design.md; docs/qi_condensation.md (latest dated sections); src/qi_certification.gd; src/qi_practice.gd; data/society/cultivation.json |
| [cultivation/body-tempering.md](../cultivation/body-tempering.md) | data/society/body.json; src/body_tempering.gd; docs/qi_condensation.md; docs/the_fifty.md |
| [cultivation/qi-condensation.md](../cultivation/qi-condensation.md) | src/qi_certification.gd; src/qi_practice.gd release/distribution trials; docs/qi_condensation.md final sections dated 2026-11-21/22 |
| [cultivation/vessel.md](../cultivation/vessel.md) | data/cultivation/lab.json; src/qi_practice.gd vessel_ceiling/FULL_VESSEL_LAYERS; docs/qi_condensation.md vessel ceiling, floor and final layer-9 sections; src/circulation.gd; src/session_compiler.gd |
| [cultivation/meridians.md](../cultivation/meridians.md) | docs/qi_condensation.md; data/cultivation/anatomy.json; data/cultivation/operations.json; data/cultivation/practice.json; src/circulation.gd; src/qi_practice.gd |
| [cultivation/programmes.md](../cultivation/programmes.md) | src/qi_practice.gd select_program/HABITUATION_CAP/INTEGRATED_FILTER; docs/qi_condensation.md programme-choice fix and guided circulation |
| [cultivation/foundation-tiers.md](../cultivation/foundation-tiers.md) | src/qi_certification.gd VESSEL_TIERS/vessel_tier; docs/qi_condensation.md owner decision 2026-11-19 |
| [cultivation/walls.md](../cultivation/walls.md) | docs/qi_condensation.md latest 2026-11-19/21/22 sections; src/qi_certification.gd; src/qi_practice.gd |
| [cultivation/foundation-establishment.md](../cultivation/foundation-establishment.md) | docs/combat.md; docs/qi_condensation.md layer-9 change; src/qi_practice.gd; docs/cultivation_design.md |
| [combat/resolution.md](../combat/resolution.md) | src/combat.gd; data/society/combat.json; docs/combat.md |
| [combat/qi.md](../combat/qi.md) | docs/combat.md latest implementation status; data/society/combat.json qi; src/combat.gd |
| [combat/hunting.md](../combat/hunting.md) | data/society/combat.json beasts; docs/wildlife.md; docs/wildlife_implementation.md; data/wild/ecology.json; src/combat.gd |
| [combat/guardians.md](../combat/guardians.md) | docs/stone_guards.md including v1.1; data/society/law.json; data/society/combat.json; src/law.gd |
| [combat/planned.md](../combat/planned.md) | docs/combat.md build order and implementation status; docs/qi_formations_research.md; docs/daos_laws.md |
| [wildlife/ecosystem.md](../wildlife/ecosystem.md) | docs/wildlife.md; docs/wildlife_implementation.md; data/wild/ecology.json; data/wild/beasts.json; src/wildlife.gd |
| [wildlife/species.md](../wildlife/species.md) | data/wild/species.json (all counts and eligible rows); data/wild/curated.json; data/wild/trait_rules.json; docs/species_catalogue.md |
| [wildlife/cultivation.md](../wildlife/cultivation.md) | docs/beast_cultivation_research.md; docs/wildlife.md; docs/wildlife_implementation.md; data/wild/beasts.json; data/wild/species.json; src/wildlife.gd |
| [materials/goods.md](../materials/goods.md) | data/goods.json material rows; docs/materials.md; docs/materials-validation.md |
| [materials/medicine.md](../materials/medicine.md) | data/society/body.json; data/skills/domains/alchemy.json; docs/materials.md; docs/wildlife_implementation.md; docs/cultivation_design.md §14.4; docs/the_fifty.md; src/wild_supply.gd |
| [the-dao/role.md](../the-dao/role.md) | docs/cultivation_design.md §21; docs/daos_laws.md; docs/the_fifty.md; docs/daos_eye.md |
| [the-dao/decrees.md](../the-dao/decrees.md) | src/qi_field.gd set_decree/_pay_decrees/_region_level; data/qi/decrees.json; docs/daos_eye.md; docs/qi_condensation.md sealing fixtures |
| [the-dao/eye.md](../the-dao/eye.md) | docs/daos_eye.md; docs/valley_book.md; docs/archive.md |
| [reference/glossary.md](glossary.md) | docs/daos_laws.md; docs/qi_condensation.md; docs/qi_field.md; src/qi_certification.gd; src/qi_practice.gd; docs/the_fifty.md |
| [reference/units.md](units.md) | docs/daos_laws.md §3; data/qi/field.json; data/society/combat.json; docs/materials.md; docs/qi_condensation.md; data/wild/beasts.json |
| [reference/changelog.md](changelog.md) | docs/qi_condensation.md final 2026-11-21/22 sections; src/qi_certification.gd; src/qi_practice.gd |
| [reference/maintaining.md](maintaining.md) | All source files mapped below; mkdocs.yml; .github/workflows/wiki.yml |

## Derived tables and conflict watchlist

| Page | Derivation or watchpoint |
|---|---|
| Qi Condensation | Read evaluator thresholds in `src/qi_certification.gd`, pulse success in `src/qi_practice.gd`; dates from the final “Programme choice remembers strain” section of `docs/qi_condensation.md` |
| Vessel tiers | Code uses 1.333; prose often rounds to 1.33. Held full pressure, not potential alone, determines the distinction |
| Layer-9 readout | Evaluator uses 35 QU/hour while one progress line still targets 75; remove the caveat only when the source discrepancy is resolved |
| Death | Society delegates below-Qi lifespan to Body Tempering, overriding the realm JSON's 80-year tempering entry; Foundation JSON says 250, older draft says 200 |
| Wildlife species | Count every entry's `tier`; eligible table selects `cultivation_eligible == true` from `data/wild/species.json` |
| Combat hunting | Base rows from `data/society/combat.json` → `beasts`, excluding stone swordsman; condition and cultivation are additional effects |
| Materials | Select goods whose `category_path` contains `materials`; copy name, final category, grade, unit and source |
| Qi geography | Vein rows from `data/qi/veins.json` → `grades`; density ranges from `data/qi/field.json` |
| Beast progression | Minimum years and completed-layer lifespan multipliers from `data/wild/beasts.json`; do not confuse chronological age with biological age |
| Combat status | Current working-tree code also implements weapon/reach phase 2, ahead of the final status in `docs/combat.md`; armour is a guard-score bonus and sword pulse modifies escape chance. No layer-6 ambient admission is present |
| Eye and decrees | Simulation decree support exists; phase-1 Eye mutation workflows remain unavailable |

## Build and validation

The site uses MkDocs Material **9.5.39**. In an environment with dependencies installed, run `mkdocs build --strict`. Navigation includes every wiki page explicitly. Before publishing, check every navigation target and relative Markdown page link (including fragments when added).

The Pages workflow builds pushes to `fresh-start` affecting `wiki/**` or `mkdocs.yml`, or manual dispatch. It builds strictly, uploads `site/`, then deploys the Pages artifact. Repository Pages must use GitHub Actions as its source; no branch-publishing command is needed. Workflow-only edits do not automatically trigger the configured path filter.

If dependencies cannot be installed, validate navigation and relative file targets with a temporary Python script outside the repository. Report that this does not replace a rendered strict build. Never run the game just to check wiki links.
