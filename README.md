# Crown of Ash

A medieval colony sim against the undead. You don't control anyone: you set jobs, rules and works,
and your villagers live their lives. Retake the realm one village at a time, then burn the Black Crypt.

## Run

    ./play.sh              # windowed game
    ./play.sh --fast       # start at 4x
    godot --headless --path . -s res://tools/test_realm.gd -- --days=8   # balance test, ~5 min (--one: one realm)

## How it plays

- **Days and nights.** A day lasts five minutes. By day your people farm, chop, forage, build and train. At dusk
  they shelter in their village hall. At night the dead walk out of the graveyards and the crypt towards a village
  you hold.
- **The dead hunt by sense.** They see light and movement and they hear noise (axes, building, fighting, gates).
  Hearths kept burning and open windows draw them in; shutters and a dark hall keep you hidden. The dead lurking
  in a village come as a pack once one of them finds someone.
- **Jobs.** Click someone to give them a job: farm, chop, forage, build, guard, soldier or rest. Traits (Quiet,
  Strong, Skilled, Keen-eyed) make some people better at some jobs. Health bars show over every head and under
  every name in the list.
- **Rules** (top left): hearths at night, rations, shut the gates behind you.
- **Works** (bottom cards) are prebuilt plots you order built, per village:
  - **Palisade:** the wall ring is marked out around every village; builders raise it a stake at a time, paying
    wood as they go. There's a gate on every side. The dead batter walls and gates; builders mend them.
  - **Towers:** four corner towers, one at a time. Guards take the towers first and see and shoot much further.
  - Hall door bars, shutters, straw beds, mill, fletcher, chapel, barracks, bell.
- **Soldiers** have standing orders: **Escort**, **Guard fields** (patrol the farmers and woodcutters) or
  **Warband**. They only fight what threatens their people, and fall back onto the walls when outnumbered.
- **Foraging parties.** Outside your own villages a forager only goes out with at least 2 soldiers on Escort
  (up to 3). The party moves quietly in formation, one scouting ahead. They pick only houses with few dead
  nearby, knife a lone unaware one from behind without raising the alarm, and turn away from anywhere busier.
  If they're spotted they withdraw instead of fighting; the dead of a village won't follow far past it. If the
  party drops below 2, the forager heads home and waits for another.
- **Healing.** Anyone badly hurt (under half health) goes home and rests in bed till they're mended (about half
  a day). Bed rest heals far faster than standing about; herbs patch the worst wounds and the chapel doubles healing.
- **Barracks** train soldiers who live there: spearmen (reach), archers (shoot from range, use arrows) and
  men-at-arms (heavy armour).
- **The realm** (right): click a village to pick it. Yours shows its works; one the dead hold shows **Send the
  warband**, which marches the soldiers with the Warband order (it needs at least 3). When no dead remain and they stand there,
  it's yours. Move villagers in to work its fields.
- **Victory:** take the Black Crypt and destroy its altar. **Defeat:** everyone dies.

Controls: drag or WASD to pan, wheel to zoom, Space to pause, 1/2/3 for speed, click the minimap to jump.
