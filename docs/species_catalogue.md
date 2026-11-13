# Species catalogue

`data/wild/species.json` holds every species the valley can contain: 6,562 real species recorded in the wild in the Qinling mountains (33.3–34.3° N, 106.5–109.5° E), plus the village animals.

## Where it comes from

- **Species list:** GBIF occurrence records in that box, faceted by species. Fossils, zoo and garden specimens, and microbes are left out. Every species keeps its GBIF key (`id`) and its record count (`records`), which is used as a rough sign of how common it is.
- **Names and taxonomy:** the GBIF Backbone Taxonomy, licensed CC BY 4.0. Cite it as "GBIF.org, GBIF Backbone Taxonomy, https://www.gbif.org". The raw download is in `data/wild/source/gbif_qinling.json`, so a rebuild needs no network unless `--refresh` is passed.
- **Traits:** `data/wild/trait_rules.json` gives starting traits for each taxon: group, diet, mass, activity, habitat, active or flowering months, danger and use. The most specific rule wins, from family down to kingdom. These are broad defaults, not measurements.
- **Field numbers:** `data/wild/curated.json` overrides the rules for the animals that matter most. It covers food per day, gestation, litter size, range, speed and stamina, using the figures from `docs/wildlife_research.md`. It also adds species the records miss, such as the tiger, leopard, brown bear and the livestock.

## Tiers

| Tier | Rule | Count |
|---|---|---|
| individual | curated, or a mammal of 5 kg or more | 22 |
| population | other vertebrates | 535 |
| guild | plants, fungi, insects and other invertebrates | 6,005 |

## Rebuild

```
python3 tools/build_species_catalogue.py            # from the saved download
python3 tools/build_species_catalogue.py --refresh  # fetch again from GBIF
```

## Known rough edges

- GBIF has a few misidentified records, such as a North American pocket gopher. Rare vertebrates with a single record are worth reviewing.
- Rule traits are coarse at the family level. Tune them in `trait_rules.json`, or promote a species to `curated.json`.
