extends RefCounted
## Append-only life archive on disk, one folder per run. Read by tools/archive_index.py and docs/archive_viewer.html.
## Layout: meta.json, then year_NNNN/{events,decisions,people,factions}.jsonl.gz (standard gzip, one JSON object per line).
const VERSION := 1
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/society/archive.json"))
var store_ref: WeakRef
var root := ""
var pending: Dictionary = {}
var pending_decisions: Dictionary = {}
var last_snapshot_year := -1

func _init(store: RefCounted, seed_value: int) -> void:
	store_ref = weakref(store)
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "").replace(" ", "_").replace("-", "")
	root = "user://archive/run_%s" % stamp
	DirAccess.make_dir_recursive_absolute(root)
	var meta := {"version": VERSION, "run": root.get_file(), "started": Time.get_datetime_string_from_system(false, true), "seed": seed_value, "start_day": store.day, "people": store.size()}
	_write_text(root + "/meta.json", JSON.stringify(meta, "  "))
	var latest := FileAccess.open("user://archive/latest.txt", FileAccess.WRITE)
	if latest: latest.store_string(root.get_file())
	print("ARCHIVE %s" % ProjectSettings.globalize_path(root))

func event(day: int, person: int, kind: String, text: String) -> void:
	var year := day / 365
	if not pending.has(year): pending[year] = PackedStringArray()
	pending[year].append(JSON.stringify({"day": day, "person": person, "kind": kind, "text": text}))

func decision(record: Dictionary) -> void:
	var year: int = int(record.day) / 365
	if not pending_decisions.has(year): pending_decisions[year] = PackedStringArray()
	pending_decisions[year].append(JSON.stringify(record))

## Called once as a game year closes: flushes its events and, on cadence, snapshots everyone.
func year_end(year: int) -> void:
	var store: RefCounted = store_ref.get_ref()
	if store == null: return
	_flush_events(func(y: int) -> bool: return y <= year)
	var every := int(config.snapshot_every_years) if store.size() <= int(config.large_population) else int(config.large_snapshot_every_years)
	if last_snapshot_year < 0 or year - last_snapshot_year >= every:
		last_snapshot_year = year
		_snapshot(year)

## Flushes everything still buffered, for a run that stops mid-year.
func close() -> void:
	_flush_events(func(_y: int) -> bool: return true)

func _flush_events(due: Callable) -> void:
	for kind: String in ["events", "decisions"]:
		var buffers: Dictionary = pending if kind == "events" else pending_decisions
		for year: int in buffers.keys():
			if not due.call(year): continue
			var lines: PackedStringArray = buffers[year]
			buffers.erase(year)
			var path := "%s/year_%04d/%s.jsonl.gz" % [root, year, kind]
			# A run never reopens a closed year, but a mid-year close then year_end may both write; keep both.
			if FileAccess.file_exists(path): path = path.replace(kind + ".jsonl", "%s_%d.jsonl" % [kind, Time.get_ticks_msec()])
			_write_gz(path, lines)

func _snapshot(year: int) -> void:
	var store: RefCounted = store_ref.get_ref()
	var society: RefCounted = store.society
	var people := PackedStringArray()
	var top_skills := int(config.top_skills)
	var top_ties := int(config.top_ties)
	for p in store.size():
		var skills: Array = []
		var e: int = store.head[p]
		while e >= 0:
			skills.append([store.catalogue.ids[store.skill_id[e]], store.skill_level[e], snappedf(store.skill_xp[e], .1)])
			e = store.skill_next[e]
		skills.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1] or (a[1] == b[1] and a[2] > b[2]))
		if skills.size() > top_skills: skills.resize(top_skills)
		var ties: Array = []
		for row: Dictionary in society.ties.rows(p):
			if ties.size() >= top_ties: break
			ties.append([row.person, snappedf(row.opinion, .1), row.trust, row.bonds])
		var groups: Array = []
		if society.memberships.has(p):
			for id: int in society.memberships[p]: groups.append(id)
		people.append(JSON.stringify({
			"id": p, "name": store.names[p], "sex": store.sex[p], "born": store.birth_day[p], "alive": society.alive[p],
			"home": store.household[p], "job": store.jobs[store.job[p]], "mother": store.parent_id[p], "father": society.father[p],
			"spouse": society.spouse[p], "master": society.master[p], "realm": society.realm[p], "layer": society.layer[p],
			"realm_label": society.realm_label(p), "qi": snappedf(society.qi[p], .1), "root": society.root_label(p),
			"reputation": snappedf(society.reputation[p], .1), "mood": snappedf(store.mood[p], .1),
			"skills": skills, "ties": ties, "factions": groups}))
	_write_gz("%s/year_%04d/people.jsonl.gz" % [root, year], people)
	var factions := PackedStringArray()
	var limit := int(config.faction_member_limit)
	for f: Dictionary in society.factions:
		var members: PackedInt32Array = f.members
		factions.append(JSON.stringify({"id": f.id, "type": f.type, "name": f.name, "leader": f.leader, "size": members.size(),
			"members": Array(members.slice(0, limit)), "cohesion": f.cohesion, "reputation": f.reputation, "absorbed_into": f.absorbed_into}))
	_write_gz("%s/year_%04d/factions.jsonl.gz" % [root, year], factions)

func _write_gz(path: String, lines: PackedStringArray) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Archive could not write %s" % path)
		return
	file.store_buffer(("\n".join(lines) + "\n").to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))

func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file: file.store_string(text)
