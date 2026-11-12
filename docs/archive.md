# The archive (Book of Lives)

Every run of the game writes an append-only record of its people to
`~/.local/share/godot/app_userdata/Crown of Ash/archive/run_<date>_<time>/`:

| File | Contents |
|---|---|
| `meta.json` | run name, start time, world seed, starting population |
| `year_NNNN/events.jsonl.gz` | every chronicle event that year: day, person, kind, text |
| `year_NNNN/people.jsonl.gz` | year-end snapshot of everyone: family, spouse, master, realm, root, top skills, strongest ties, factions |
| `year_NNNN/factions.jsonl.gz` | year-end factions: type, leader, members, cohesion, reputation |

Files are standard gzip with one JSON object per line. Settings live in `data/society/archive.json`:
snapshots are yearly up to 5,000 people and every 10 years above that. `--no-archive` turns it off for one run.

**Reading it:** `tools/archive_viewer.sh` indexes new files into `archive.sqlite` (next to the runs) and opens
`docs/archive_viewer.html` at http://127.0.0.1:8765/. The server listens on loopback only and only reads the archive.
`python3 tools/archive_serve.py --index-only` just builds the index.

The viewer has an overview with population and cultivation curves, a sortable people table, a life-story page per
person, a knowledge graph (family, spouses, masters, friendships and enmities, with a year slider and focus), a
filterable timeline and a factions table.
