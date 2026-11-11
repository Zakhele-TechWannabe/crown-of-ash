# Materials validation

PASS — Godot 4.7.2, headless only, one process at a time. No commits.

## Checks

- test_continuous: PASS
- test_foods: PASS
- test_grain: PASS
- test_ground_lod: PASS
- test_ledger: PASS
- test_ledger_ui: PASS
- test_materials: PASS
- test_pan: PASS
- test_sect: PASS
- test_sites: PASS
- test_village: PASS
- sim: PASS
- day200-materials: PASS
- day200-work: PASS
- bench-after: PASS

The materials test checks three years of deterministic daily versus jump accounting, every mortal reserve growing, all spirit reserves remaining zero, food above 90 days throughout, no hunger or deaths, ingredient limits, winter mine/quarry idling, and dry, separate, reachable worksite footprints. The UI test checks every inventory category and good, work details, navigation, and text fit at 1920×1080 and 1366×768.

## Chunk bake benchmark

Three chunks per region. Foreground materials never enter chunk baking. Milliseconds per chunk.

| Region | Detailed before | Detailed after | Far before | Far after |
|---|---:|---:|---:|---:|
| ordinary | 454.84 | 445.38 | 65.38 | 63.90 |
| forest | 581.03 | 566.29 | 80.68 | 79.15 |

## Drawn sites

Offsets are from the sect centre (1365, 2286). Full footprints contain 24 dry tiles and avoid roads, paddies, buildings and food decorations.

| Site | Offset | Footprint levels |
|---|---|---|
| woodcutting | (95, 267) | 7–7 |
| kiln | (93, 282) | 7–7 |
| quarry | (-96, 57) | 7–9 |
| clay | (65, 285) | 8–8 |
| mine | (-68, -100) | 13–15 |
| smith | (25, 262) | 8–8 |
| weaver | (-35, 267) | 8–8 |
| tanner | (95, 310) | 7–8 |

The wood camp has stumps, log piles and a sawhorse. The kiln yard has a dark charcoal kiln and a fired-clay kiln. The quarry has cut faces, dressed blocks and a lifting tripod; the adit has a timber-dark opening and ore carts. The village bloomery has glowing furnace mouths. Hemp rows and a loom sit beside the weaver’s shed, and drying frames mark the outlying tannery. The clay pit is about 48 tiles from natural water.

## Day-200 mortal stocks

At the start of day 200 in each year; quantities use each good’s declared unit.

| Good | Unit | Year 1 | Year 2 | Year 3 |
|---|---|---:|---:|---:|
| Firewood | jin | 1107.94 | 2461.04 | 3814.14 |
| Pine logs | pieces | 342.70 | 999.20 | 1655.70 |
| Hardwood logs | pieces | 696.12 | 2000.86 | 3305.60 |
| Bamboo | jin | 299.00 | 791.60 | 1284.20 |
| Planks | pieces | 229.10 | 557.60 | 886.10 |
| Charcoal | jin | 267.31 | 665.89 | 1064.47 |
| Fieldstone | jin | 288.80 | 616.40 | 944.00 |
| Cut stone | jin | 288.80 | 616.40 | 944.00 |
| Granite | jin | 288.80 | 616.40 | 944.00 |
| Clay | jin | 481.83 | 905.88 | 1329.93 |
| Sand | jin | 288.80 | 616.40 | 944.00 |
| Lime | jin | 276.86 | 582.56 | 888.26 |
| Bricks | pieces | 288.80 | 726.80 | 1164.80 |
| Roof tiles | pieces | 229.10 | 557.60 | 886.10 |
| Iron ore | jin | 177.36 | 236.16 | 294.96 |
| Copper ore | jin | 193.28 | 345.68 | 498.08 |
| Tin | jin | 274.47 | 575.79 | 877.11 |
| Coal | jin | 288.80 | 616.40 | 944.00 |
| Iron ingots | jin | 214.77 | 516.99 | 819.21 |
| Copper | jin | 96.17 | 180.85 | 265.53 |
| Bronze | jin | 97.76 | 185.36 | 272.96 |
| Tools | pieces | 87.81 | 157.16 | 226.51 |
| Hemp | jin | 565.38 | 661.68 | 757.98 |
| Cotton | jin | 288.80 | 726.80 | 1164.80 |
| Silk cocoons | jin | 288.80 | 726.80 | 1164.80 |
| Cloth | jin | 219.15 | 529.40 | 839.65 |
| Hides | jin | 89.80 | 116.80 | 143.80 |
| Leather | jin | 109.70 | 219.20 | 328.70 |
| Rope | jin | 209.20 | 501.20 | 793.20 |
| Lamp oil | jin | 299.00 | 791.60 | 1284.20 |
| Wax | jin | 299.00 | 791.60 | 1284.20 |
| Common herbs | jin | 299.00 | 791.60 | 1284.20 |
| Resin | jin | 299.00 | 791.60 | 1284.20 |

## Spirit catalogue

All stocks remain zero in all three years; shown dimmed with a glow border, tier, and “not gathered yet”.

- Wood: Spirit-ironwood, Thunder-struck peach wood, Ghost-willow, Cloud-pine heartwood.
- Stone & earth: Jade-vein stone, Spirit jade (raw), Star-iron sand.
- Ores & metal: Cold iron, Black gold ore, Meteoric iron, Spirit copper.
- Fibre & hide: Spirit silk, Demon-beast hide.
- Other: Spirit herbs (low grade).

Salt remains in the pantry.

## Yearly food and material group summaries

```text
Year 1 grains: stored 24254.27 jin | produced 23465.85 | eaten 6935.00 | processed 32.85 | spoiled 1243.73
Year 1 vegetables: stored 607.38 jin | produced 9696.96 | eaten 4161.00 | processed 5098.72 | spoiled 2229.87
Year 1 fruit: stored 48.20 jin | produced 2722.72 | eaten 1109.60 | processed 1090.51 | spoiled 1794.41
Year 1 meat: stored 444.22 jin | produced 2402.40 | eaten 741.76 | processed 259.23 | spoiled 1917.20
Year 1 fish: stored 200.45 jin | produced 1638.00 | eaten 367.84 | processed 683.67 | spoiled 986.04
Year 1 pantry: stored 6644.24 jin | produced 5943.83 | eaten 657.73 | processed 0.91 | spoiled 680.96
Year 1 wood: stored 5084.02 jin / pieces | produced 6952.10 | eaten 0.00 | processed 2418.08 | spoiled 0.00
Year 1 earth: stored 3206.65 jin / pieces | produced 3496.50 | eaten 0.00 | processed 689.85 | spoiled 0.00
Year 1 metal: stored 1783.97 jin / pieces | produced 2151.20 | eaten 0.00 | processed 767.23 | spoiled 0.00
Year 1 fibre: stored 2251.05 jin / pieces | produced 2342.50 | eaten 0.00 | processed 631.45 | spoiled 0.00
Year 1 other_materials: stored 2170.40 jin / pieces | produced 1970.40 | eaten 0.00 | processed 0.00 | spoiled 0.00
Year 1: stock 14468.10 | harvest 21799.41 | consumed 6935.00 | spoilage 4373.83 | balance +6908.10 | minimum 4500.00 | hungry 0
Year 2 grains: stored 38262.46 jin | produced 23316.04 | eaten 6935.00 | processed 32.85 | spoiled 2340.01
Year 2 vegetables: stored 606.59 jin | produced 9696.96 | eaten 4161.00 | processed 3956.85 | spoiled 1579.90
Year 2 fruit: stored 43.13 jin | produced 2722.72 | eaten 1109.60 | processed 624.94 | spoiled 993.24
Year 2 meat: stored 414.38 jin | produced 2402.40 | eaten 741.76 | processed 111.92 | spoiled 1578.55
Year 2 fish: stored 200.44 jin | produced 1638.00 | eaten 367.84 | processed 307.23 | spoiled 962.94
Year 2 pantry: stored 9117.22 jin | produced 4238.89 | eaten 657.73 | processed 0.91 | spoiled 1107.27
Year 2 wood: stored 9618.04 jin / pieces | produced 6952.10 | eaten 0.00 | processed 2418.08 | spoiled 0.00
Year 2 earth: stored 6013.30 jin / pieces | produced 3496.50 | eaten 0.00 | processed 689.85 | spoiled 0.00
Year 2 metal: stored 3167.94 jin / pieces | produced 2151.20 | eaten 0.00 | processed 767.23 | spoiled 0.00
Year 2 fibre: stored 3962.10 jin / pieces | produced 2342.50 | eaten 0.00 | processed 631.45 | spoiled 0.00
Year 2 other_materials: stored 4140.80 jin / pieces | produced 1970.40 | eaten 0.00 | processed 0.00 | spoiled 0.00
Year 2: stock 21701.82 | harvest 20879.05 | consumed 6935.00 | spoilage 4193.43 | balance +7233.72 | minimum 13050.58 | hungry 0
Year 3 grains: stored 51327.81 jin | produced 23384.77 | eaten 6935.00 | processed 32.85 | spoiled 3351.57
Year 3 vegetables: stored 606.59 jin | produced 9696.96 | eaten 4161.00 | processed 3956.47 | spoiled 1579.50
Year 3 fruit: stored 43.12 jin | produced 2722.72 | eaten 1109.60 | processed 623.46 | spoiled 989.68
Year 3 meat: stored 412.36 jin | produced 2402.40 | eaten 741.76 | processed 106.90 | spoiled 1555.77
Year 3 fish: stored 200.44 jin | produced 1638.00 | eaten 367.84 | processed 307.23 | spoiled 962.93
Year 3 pantry: stored 11231.71 jin | produced 4233.38 | eaten 657.73 | processed 0.91 | spoiled 1460.24
Year 3 wood: stored 14152.06 jin / pieces | produced 6952.10 | eaten 0.00 | processed 2418.08 | spoiled 0.00
Year 3 earth: stored 8819.95 jin / pieces | produced 3496.50 | eaten 0.00 | processed 689.85 | spoiled 0.00
Year 3 metal: stored 4551.91 jin / pieces | produced 2151.20 | eaten 0.00 | processed 767.23 | spoiled 0.00
Year 3 fibre: stored 5673.15 jin / pieces | produced 2342.50 | eaten 0.00 | processed 631.45 | spoiled 0.00
Year 3 other_materials: stored 6111.20 jin / pieces | produced 1970.40 | eaten 0.00 | processed 0.00 | spoiled 0.00
Year 3: stock 28333.34 | harvest 20907.44 | consumed 6935.00 | spoilage 4827.47 | balance +6631.52 | minimum 19964.35 | hungry 0
```

## Commands

```sh
godot --headless --path . --script tools/test_materials.gd
godot --headless --path . -- --headless-sim --years=3
godot --headless --path . --quit-after 3 -- --goto="Servants' Village" --day=200 --ledger=materials
godot --headless --path . --quit-after 3 -- --goto="Servants' Village" --day=200 --ledger=work
godot --headless --path . --script tools/bench_bake.gd -- --n=3
```

All `tools/test*.gd` scripts were run separately and serially. Test logs are in `out/materials-validation/`.
