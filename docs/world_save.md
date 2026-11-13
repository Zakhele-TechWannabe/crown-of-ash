World persistence
=================

Normal windowed play resumes `user://saves/world.save`. The version 1 envelope contains a timestamp and script-owned simulation state, including every subsystem, RNG seed/state, walkers, staged fights, archive folder, pause/speed and both cameras. Time does not advance while the application is closed.

The world saves after startup, when the population crosses a day boundary, every 120 seconds (including while paused), and on window close or orderly scene teardown. Writes flush a temporary file, rotate the previous save to `world.save.bak`, then rename the temporary file. Loading falls back to the backup if the primary envelope is unreadable or unsupported. If neither file can be loaded, play pauses and both files are preserved until you explicitly choose a new world.

Use `./play.sh --new-world` or the atlas top bar's confirmed **New world** action to replace the current valley. There is one world slot.

Headless runs, `--headless-sim`, `--shot=...` and `--no-save` disable the player slot. The save test explicitly supplies a separate test path. JSON configuration, terrain, textures, spatial/name/statistics caches and route lookup caches are reconstructed from current resources. Missing columns retain fresh defaults and are resized to match the loaded population; unknown fields are ignored. Active walker paths and in-progress simulation cursors are state, so travel and batched days can continue.

Window-manager close and `tools/close_game.sh` both save immediately. The script discovers each non-headless Godot project's user directory and writes `quit.<pid>.request` for each process. The game polls that file once a second, stops simulation, lets an in-progress faction refresh finish, saves atomically, removes the request, and quits. A failed save leaves the game running. The script waits ten seconds before falling back to SIGTERM; an older running executable without the polling code will need that fallback until restarted. SIGTERM, SIGKILL and power loss rely on autosaves.

Childhood interests, hunger damage, talent flags and the current tagging-along day are saved through the childhood subsystem. Care is derived from living parents, presence and child age. Old saves receive fresh childhood columns and under-twelve jobs are migrated to empty duties.

`tools/test_quit.gd` runs the real world and one-second request poll headlessly with an explicit test save path, checks the saved envelope and request removal during tree exit, and leaves the player slot alone. The close script is syntax-checked without running it against the owner's game.

Verification: `python3 tools/run_phase2_checks.py tools/test_save.gd tools/test_law.gd tools/test_village.gd`, then `python3 tools/run_phase2_checks.py`. The save test builds two real villages, checks the complete captured state at day 60, and compares summaries, stocks and RNG after another 30 days. It also writes `out/ui/gate_sheet.png` with both gate orientations and outward-facing guardians.
