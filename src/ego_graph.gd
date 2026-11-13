extends Control
## Small knowledge graph around one person: relationships, family, lineage or skills.
## Laid out once when built (at most ~60 nodes), then only redrawn; clicking a person node calls `opened`.
signal opened(person: int)
const Palette = preload("res://src/palette.gd")
const EDGE_COLORS := {"parent": Palette.BRASS, "spouse": Palette.PLUM, "sibling": Palette.GOLD, "master": Palette.JADE,
	"disciple": Palette.JADE, "friend": Palette.BLUE, "enemy": Palette.RED, "skill": Palette.INK_SOFT, "branch": Palette.LINE}
const REALM_COLORS := [Palette.INK_SOFT, Palette.BRASS, Palette.JADE, Palette.BLUE, Palette.PLUM, Palette.GOLD]
const MAX_NODES := 60
var population: RefCounted
var center := -1
var mode := "Relationships"
var nodes: Array[Dictionary] = []
var edges: Array[Dictionary] = []
var hovered := -1
var index: Dictionary = {}
var labels_above := false

func build(store: RefCounted, person: int, view: String) -> void:
	population = store
	center = person
	mode = view
	nodes.clear()
	edges.clear()
	index.clear()
	match view:
		"Relationships": _relationships()
		"Family": _family()
		"Lineage": _lineage()
		"Skills": _skills()
	labels_above = view == "Skills"
	if view == "Relationships": _layout()
	else: _layered_layout(view == "Skills")
	queue_redraw()

func _node(key: String, label: String, person: int = -1, color: Color = Palette.INK_SOFT, radius: float = 7.0) -> int:
	if index.has(key): return index[key]
	if nodes.size() >= MAX_NODES: return -1
	index[key] = nodes.size()
	nodes.append({"key": key, "label": label, "person": person, "color": color, "r": radius, "pos": Vector2.ZERO, "v": Vector2.ZERO, "dim": false})
	return nodes.size() - 1

func _person_node(p: int) -> int:
	var society: RefCounted = population.society
	var radius := 9.0 if p == center else 6.0 + clampf(society.reputation[p] / 20.0, 0, 4)
	return _node("person:%d" % p, population.names[p], p, REALM_COLORS[mini(society.realm[p], REALM_COLORS.size() - 1)], radius)

func _edge(a: int, b: int, kind: String, label: String = "") -> void:
	if a < 0 or b < 0 or a == b: return
	for e: Dictionary in edges:
		if (e.a == a and e.b == b) or (e.a == b and e.b == a): return
	edges.append({"a": a, "b": b, "kind": kind, "label": label})

func _relationships() -> void:
	var society: RefCounted = population.society
	var me := _person_node(center)
	var rows: Array = society.ties.rows(center)
	var shown: Array[int] = []
	for row: Dictionary in rows.slice(0, 24):
		var other := _person_node(row.person)
		shown.append(row.person)
		_edge(me, other, _tie_kind(row.opinion, row.bonds), "%+.0f" % row.opinion)
	# Ties among the people shown make the clusters (friend groups, feuds) visible.
	for p: int in shown:
		var e: int = society.ties.head[p]
		while e >= 0:
			var q: int = society.ties.target[e]
			if q in shown and absf(society.ties.opinion[e]) >= 40: _edge(_person_node(p), _person_node(q), _tie_kind(society.ties.opinion[e], society.ties.bonds[e]))
			e = society.ties.next[e]

func _tie_kind(opinion: float, bonds: int) -> String:
	var ties: RefCounted = population.society.ties
	if bonds & (ties.SPOUSE | ties.ROMANCE): return "spouse"
	if bonds & (ties.MASTER | ties.DISCIPLE): return "master"
	if opinion < 0 or bonds & (ties.RIVAL | ties.ENEMY): return "enemy"
	return "friend"

func _family() -> void:
	var society: RefCounted = population.society
	var me := _person_node(center)
	for parent: int in society.parents(center):
		if parent < 0: continue
		var pn := _person_node(parent)
		_edge(pn, me, "parent")
		for grand: int in society.parents(parent):
			if grand >= 0: _edge(_person_node(grand), pn, "parent")
	for sibling: int in society.siblings(center): _edge(me, _person_node(sibling), "sibling")
	if society.spouse[center] >= 0: _edge(me, _person_node(society.spouse[center]), "spouse")
	for child: int in society.children(center):
		var cn := _person_node(child)
		_edge(me, cn, "parent")
		if society.spouse[child] >= 0: _edge(cn, _person_node(society.spouse[child]), "spouse")
		for grandchild: int in society.children(child): _edge(cn, _person_node(grandchild), "parent")

func _lineage() -> void:
	var society: RefCounted = population.society
	var chain: PackedInt32Array = society.lineage_ancestors(center)
	var root: int = chain[-1] if not chain.is_empty() else center
	var queue: Array[int] = [root]
	_person_node(root)
	while not queue.is_empty() and nodes.size() < MAX_NODES:
		var p: int = queue.pop_front()
		for d: int in society.disciples(p):
			_edge(_person_node(p), _person_node(d), "master")
			queue.append(d)

func _skills() -> void:
	var catalogue: RefCounted = population.catalogue
	var skills: Dictionary = population.sparse_skills(center)
	var ordered: Array = skills.keys()
	ordered.sort_custom(func(a: String, b: String) -> bool: return int(skills[a].level) > int(skills[b].level))
	var me := _person_node(center)
	for id: String in ordered.slice(0, 12):
		var domain: Dictionary = catalogue.domains[catalogue.domain_for(id)]
		var discipline: String = catalogue.discipline_for(id)
		var sphere := _node("sphere:" + str(domain.sphere), str(catalogue.spheres[domain.sphere].name), -1, Palette.INK_SOFT, 8)
		_edge(me, sphere, "skill")
		var dn := _node("domain:" + str(domain.id), str(domain.name), -1, Palette.BRASS, 7)
		_edge(sphere, dn, "skill")
		var level: int = int(skills.get(discipline, {"level": 0}).level)
		var di := _node(discipline, "%s %d" % [catalogue.disciplines[discipline].name, level], -1, Palette.JADE, 5 + level / 6.0)
		_edge(dn, di, "skill")
		if id != discipline:
			_edge(di, _node(id, "%s %d" % [catalogue.skills[id].name, skills[id].level], -1, Palette.BLUE, 5 + int(skills[id].level) / 6.0), "skill")
		# Branches within reach: specialisations unlocking up to five levels above current competency.
		for spec: Dictionary in catalogue.disciplines[discipline].get("specialisations", []):
			if skills.has(spec.id) or int(spec.unlock_level) > level + 5: continue
			var sn := _node(spec.id, "%s (at %d)" % [spec.name, spec.unlock_level], -1, Palette.LINE, 4)
			if sn >= 0:
				nodes[sn].dim = true
				_edge(di, sn, "branch")

# Trees read better in layers: generations as rows (family, lineage), the skill tree as columns.
# Directed edges (parent, master, skill, branch) step one layer; spouse and sibling stay level.
func _layered_layout(columns: bool) -> void:
	if nodes.is_empty(): return
	var layer: Dictionary = {0: 0}
	var queue: Array[int] = [0]
	while not queue.is_empty():
		var at: int = queue.pop_front()
		for e: Dictionary in edges:
			var step := 0 if e.kind in ["spouse", "sibling"] else 1
			var other: int = -1
			if e.a == at: other = e.b
			elif e.b == at:
				other = e.a
				step = -step
			if other >= 0 and not layer.has(other):
				layer[other] = layer[at] + step
				queue.append(other)
	var rows: Dictionary = {}
	for i in nodes.size():
		var l: int = layer.get(i, 0)
		if not rows.has(l): rows[l] = []
		rows[l].append(i)
	var keys: Array = rows.keys()
	keys.sort()
	var placed: Dictionary = {}
	for l: int in keys:
		var row: Array = rows[l]
		# Order each layer by where its already placed neighbours sit, which keeps lines from crossing.
		var weight: Dictionary = {}
		for i: int in row:
			var total := 0.0
			var count := 0
			for e: Dictionary in edges:
				var other: int = e.b if e.a == i else (e.a if e.b == i else -1)
				if other >= 0 and placed.has(other):
					total += placed[other]
					count += 1
			weight[i] = total / count if count else float(i)
		row.sort_custom(func(a: int, b: int) -> bool: return weight[a] < weight[b])
		for k in row.size():
			var spread := (k - (row.size() - 1) / 2.0) * (34.0 if columns else 120.0)
			placed[row[k]] = spread
			nodes[row[k]].pos = Vector2(l * 170.0, spread) if columns else Vector2(spread, l * 70.0)

func _layout() -> void:
	var count := nodes.size()
	for i in count:
		var angle := i * 2.39996
		nodes[i].pos = Vector2(cos(angle), sin(angle)) * (20.0 + 6.0 * i)
	var me := -1
	for i in count:
		if nodes[i].person == center: me = i
	for step in 220:
		for i in count:
			for j in range(i + 1, count):
				var delta: Vector2 = nodes[j].pos - nodes[i].pos
				var d2 := maxf(delta.length_squared(), 1.0)
				var push := delta / sqrt(d2) * (900.0 / d2)
				nodes[i].v -= push
				nodes[j].v += push
		for e: Dictionary in edges:
			var a: Dictionary = nodes[e.a]
			var b: Dictionary = nodes[e.b]
			var delta: Vector2 = b.pos - a.pos
			var d := maxf(delta.length(), .01)
			var want := 34.0 if e.kind == "spouse" else 60.0
			var pull := delta / d * (d - want) * .03
			a.v += pull
			b.v -= pull
		var heat := 1.0 - step / 240.0
		for i in count:
			nodes[i].v -= nodes[i].pos * .004
			if i != me: nodes[i].pos += nodes[i].v * heat
			nodes[i].v *= .6
	if me >= 0:
		var offset: Vector2 = nodes[me].pos
		for i in count: nodes[i].pos -= offset

func _transform() -> Transform2D:
	if nodes.is_empty(): return Transform2D(0, size / 2)
	var bounds := Rect2(nodes[0].pos, Vector2.ZERO)
	for n: Dictionary in nodes: bounds = bounds.expand(n.pos)
	# Labels run right of (or centred above) their nodes, so reserve room on that side.
	bounds = bounds.grow_individual(40 if labels_above else 14, 24 if labels_above else 14, 60 if labels_above else 14, 14)
	var label_room := 0.0 if labels_above else 110.0
	var scale_by := minf(minf((size.x - 24 - label_room) / maxf(bounds.size.x, 1), (size.y - 24) / maxf(bounds.size.y, 1)), 2.2)
	return Transform2D(0, Vector2(scale_by, scale_by), 0, size / 2 - Vector2(label_room / 2, 0) - bounds.get_center() * scale_by)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.PAPER_LIGHT)
	draw_rect(Rect2(Vector2.ZERO, size), Palette.LINE, false, 1)
	if nodes.is_empty():
		draw_string(get_theme_default_font(), Vector2(12, 24), "Nothing to show yet", HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL, Palette.INK_SOFT)
		return
	var t := _transform()
	var font := get_theme_default_font()
	var lit: Dictionary = {}
	if hovered >= 0:
		lit[hovered] = true
		for e: Dictionary in edges:
			if e.a == hovered: lit[e.b] = true
			if e.b == hovered: lit[e.a] = true
	for e: Dictionary in edges:
		var color: Color = EDGE_COLORS.get(e.kind, Color.GRAY)
		if hovered >= 0 and not (lit.has(e.a) and lit.has(e.b)): color.a = .15
		var a: Vector2 = t * nodes[e.a].pos
		var b: Vector2 = t * nodes[e.b].pos
		if e.kind in ["enemy", "branch"]: draw_dashed_line(a, b, color, 1.5, 5)
		else: draw_line(a, b, color, 2.5 if e.kind == "spouse" else 1.6, true)
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		var at: Vector2 = t * n.pos
		var fade := hovered >= 0 and not lit.has(i)
		var color: Color = n.color
		if n.dim: color.a = .55
		if fade: color.a = .25
		draw_circle(at, n.r, color)
		if n.person == center: draw_arc(at, n.r + 3, 0, TAU, 24, Palette.INK, 2, true)
		var ink := Color(Palette.INK, .3 if fade else (.6 if n.dim else 1.0))
		if labels_above:
			var width := font.get_string_size(n.label, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL).x
			draw_string(font, at + Vector2(-width / 2, -n.r - 4), n.label, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL, ink)
		else: draw_string(font, at + Vector2(n.r + 3, 4), n.label, HORIZONTAL_ALIGNMENT_LEFT, -1, Palette.SMALL, ink)

func _node_at(point: Vector2) -> int:
	var t := _transform()
	for i in range(nodes.size() - 1, -1, -1):
		if (t * nodes[i].pos).distance_to(point) <= nodes[i].r + 4: return i
	return -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var under := _node_at(event.position)
		if under != hovered:
			hovered = under
			tooltip_text = nodes[under].label if under >= 0 else ""
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if under >= 0 and nodes[under].person >= 0 else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var under := _node_at(event.position)
		if under >= 0 and nodes[under].person >= 0 and nodes[under].person != center:
			accept_event()
			opened.emit(int(nodes[under].person))

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and hovered >= 0:
		hovered = -1
		queue_redraw()
	if what == NOTIFICATION_RESIZED: queue_redraw()
