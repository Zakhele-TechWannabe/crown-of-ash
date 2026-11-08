# Crown of Ash

A living empire against the undead. You don't control anyone: a hundred people live in the capital and get on
with their lives (farming, building, keeping watch, fighting, cultivating) while you set jobs, rules and works.
Only the capital, Ala Kambara, still stands. Retake the empire city by city, then break the Black Crypt in the
Nyoka peaks. (Every name is a placeholder until the owner names the empire.)

## The empire

Top-down, laid out after the owner's map of Kambara: Ala Kambara walled in the middle; the Nyoka Mountains across
the north (the crypt hides in them); the Kambara River down the west, over the upper falls and Kambara Falls,
bridged where the highways cross; Kiranga Citadel on its plateau to the north-east; Kambara Port and its piers on
the Golden Coast; the agricultural belt between the capital and Mabele City; and Tenga, Ilanga, Savu, Kifaru and
Mabele cities around. Province names are written across the land. Water and rock can't be crossed.

The look follows the owner's mockup: every palisade runs round an octagon with gatehouses and corner towers; the
capital is paved, with gardens, a red-and-gold palace and townhouses; cities wear name plaques (a crown for the
capital, blue for ours, red for the dead's). Roofs fade when you zoom in close, so you can see inside. The HUD is
a framed ledger: rules, tasks and citizens on the left, the realm under the minimap, the build bar along the
bottom. The ground is drawn once and only redrawn when the land changes.

## Run

    ./play.sh              # windowed game
    ./play.sh --fast       # start at 4x
    godot --headless --path . -s res://tools/test_realm.gd -- --days=3 --one   # balance test, ~4 min

## How it plays

- **Days and nights.** A day lasts five minutes. By day your people farm, chop, forage, build, cultivate and
  fight. At dusk they go home to bed: everyone has a bed in the palace or a townhouse. At night packs of the dead
  rise from the graveyards and the crypt and march on a city you hold.
- **The dead are numbers.** The map is cut into blocks of 4x4 cells and each block holds a count of the dead, so
  there can be millions. Packs on the march have a red edge. Anyone out in the open in a block with the dead is
  fighting them: up to three of the dead can reach each person, and each person cuts them down by their strength.
  Behind an unbroken door you're safe. The dead batter palisades and doors; a broken wall or open gate lets them in.
  Packs that are still out at dawn stand where they are.
- **Cultivation: Body Refinement.** Everyone has a talent, and climbs nine layers of Body Refinement. Cultivators
  (the Cultivate job) temper their bodies full-time; labour, patrols and fighting give a little. Each layer adds
  health, harder blows, faster work and quicker healing, and costs a bit more food. From the third layer anyone
  stands and fights instead of running. Cultivated people wear an aura.
- **Jobs.** The citizens panel counts each job; click one to look at its people in turn. Click someone to change
  their job: farm, chop, forage, build, guard, soldier, cultivate or rest. Traits (Quiet, Strong, Skilled,
  Keen-eyed) change how well they do.
- **Rules** (top left): hearths at night, rations, shut the gates behind you.
- **Works** (bottom cards) are prebuilt plots you order built, per village:
  - **Palisade:** the wall ring is marked out around every village; builders raise it a stake at a time, paying
    wood as they go. There's a gate on every side. The dead batter walls and gates; builders mend them.
  - **Towers:** four corner towers, one at a time. Guards take the towers first and see and shoot much further.
  - Hall door bars, shutters, straw beds, mill, fletcher, chapel, barracks, bell.
- **Soldiers** have standing orders: **Clear near home** (go after small groups of the dead near home by day,
  keep watch at night) or **Warband**.
- **Foragers** search houses in our cities, and beyond them any house where none of the dead stand. Everyone but
  soldiers walks round the blocks where the dead are.
- **Healing.** Anyone badly hurt (under half health) goes home and rests in bed till they're mended . Bed rest heals far faster than standing about; herbs patch the worst wounds and the chapel doubles healing.
- **Barracks** train soldiers who live there: spearmen (reach), archers (shoot from range, use arrows) and
  men-at-arms (heavy armour).
- **The realm** (right): click a village to pick it. Yours shows its works; one the dead hold shows **Send the
  warband**, which marches the soldiers with the Warband order (it needs at least 3). When no dead remain and they stand there,
  it's yours. Move villagers in to work its fields.
- **Victory:** take the Black Crypt and destroy its altar. **Defeat:** everyone dies.

Controls: drag or WASD to pan, wheel to zoom, Space to pause, 1/2/3 for speed, click the minimap to jump.
