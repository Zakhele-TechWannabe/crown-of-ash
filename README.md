# Crown of Ash

A medieval colony sim against the undead. You don't control anyone: you set jobs, rules and works,
and your villagers live their lives. Retake the realm one village at a time, then burn the Black Crypt.

## Run

    ./play.sh              # windowed game
    ./play.sh --fast       # start at 4x
    godot --headless --path . -s res://tools/test_realm.gd   # 10-day balance test

## How it plays

- **Days and nights.** By day your people farm, chop, forage, build and train. At dusk they shelter
  in their village hall. At night the dead walk out of the graveyards and the crypt towards a hall you hold.
- **The dead hunt by sense.** They see light and movement and they hear noise (axes, fighting, the bell).
  Hearths kept burning and open windows draw them in; shutters and a dark hall keep you hidden.
- **Jobs.** Click someone to give them a job: farm, chop, forage, build, guard, soldier or rest.
  Traits (Quiet, Strong, Skilled, Keen-eyed) make some people better at some jobs.
- **Rules** (top left): hearths at night, rations, shut the gate.
- **Works** (bottom cards): every village you hold has nine buildings: palisade gate, shutters,
  straw beds, mill, fletcher, chapel, watchtower, barracks and bell. Builders raise them over time.
- **The realm** (right): click a village the dead hold to send the warband (your soldiers). When no dead
  remain and your soldiers stand there, it's yours. Move villagers in to work its fields.
- **Victory:** take the Black Crypt and destroy its altar. **Defeat:** everyone dies.

Controls: drag or WASD to pan, wheel to zoom, Space to pause, 1/2/3 for speed, click the minimap to jump.
