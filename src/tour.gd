extends Control
## The guided tour: ten stops, each pointing at the part of the screen it explains.
## Where no example exists yet, the tour can let time run until one appears. Progress is kept in user://tour.cfg.
const Palette = preload("res://src/palette.gd")
const UiTheme = preload("res://src/ui_theme.gd")
const SAVE := "user://tour.cfg"
const STOPS: Array[Dictionary] = [
	{"title": "The valley and time", "text": "This is the Servants' Village. Everyone here lives on their own: they farm, haul, marry, quarrel and grow old without orders. The bar at the top is the whole control panel: the date, anything that needs a look, pause [Space], speed [1–7] or a skip of whole years, and the valley book [L]."},
	{"title": "A villager", "text": "Click anyone in the lanes to open their card. It says who they are, what they are doing now and what they want. Follow keeps the camera on them; Open book shows their whole page.", "wait": "anyone walking the lanes"},
	{"title": "Stories", "text": "The rail on the left is the valley's news, newest first. Every story is about someone: click it to find them. The chips filter by kind, so you can follow only tempering, family, cultivation or conflict."},
	{"title": "Body tempering", "text": "Before anyone can cultivate, they harden the body through nine layers, from Copper Skin to Perfected Body. Hard labour carries people through the first two; after that they need a method, daily drills and, higher up, medicine from the forest. The figure lights up layer by layer.", "wait": "someone who has begun tempering"},
	{"title": "Grades", "text": "Each layer is forged at a grade: Low, Middle, High or Perfect. The grade is fixed once the layer forms. A better method, a teacher, talent and patience raise it; rushing lowers it. Perfect needs perfect layers all the way up, so it is rare.", "wait": "someone with two forged layers"},
	{"title": "At the gate", "text": "When a layer's progress is full, the person waits at its gate until they have what it asks for: a better method, drills, or a dose of medicine. The top bar counts how many are waiting; their card says what they lack.", "wait": "someone waiting at a gate"},
	{"title": "The forest", "text": "Medicine comes from the wild, and the wild is finite. Iron-bark regrows slowly in six patches, the herd can be over-hunted, and seven-leaf herbs grow a few a year at the spirit spring. When too many want the same thing, the top bar says it is tight."},
	{"title": "Heart and mind", "text": "Every villager feels and wants things. Urges such as pride, longing or curiosity drive their choices; anger, grief, joy and fear colour them. Recent choices show what they did and why.", "wait": "an adult"},
	{"title": "Family and lineage", "text": "Marriages, children, masters and disciples link the valley together. The family graph is clickable: pick anyone in it to open their page.", "wait": "someone with a family of their own"},
	{"title": "The Book of Lives", "text": "Every run is written to an archive as it plays. The Book of Lives opens it in your browser (only on this computer), so you can read any life from birth to death, even after the game is closed. That is the tour: open the valley book [L] whenever you want the details."},
]
var view: Node2D
var life: Node2D
var stop := -1
var example := 0
var waiting := false
var saved_speed := 1.0
var poll := 0.0
var target := Rect2()
var card: PanelContainer
var title: Label
var words: Label
var status: Label
var another: Button
var back: Button
var next: Button
var wait_button: Button
var archive_button: Button


func setup(ground_view: Node2D) -> void:
	view = ground_view
	life = view.map.life
	view.ui.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	card = PanelContainer.new()
	card.custom_minimum_size.x = 460
	card.size.x = 460
	add_child(card)
	var column := VBoxContainer.new()
	card.add_child(column)
	status = Label.new()
	status.theme_type_variation = "Small"
	column.add_child(status)
	title = Label.new()
	title.theme_type_variation = "Title"
	column.add_child(title)
	words = Label.new()
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.custom_minimum_size.x = 430
	column.add_child(words)
	var extra := HBoxContainer.new()
	column.add_child(extra)
	another = _button(extra, "Show me another", "Chip", func() -> void: example += 1; _apply())
	wait_button = _button(extra, "Let time run", "Chip", _toggle_wait)
	archive_button = _button(extra, "Open the Book of Lives", "Chip", _open_archive)
	var row := HBoxContainer.new()
	column.add_child(row)
	back = _button(row, "Back", "Chip", func() -> void: go(stop - 1))
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)
	_button(row, "Leave tour", "Chip", leave)
	next = _button(row, "Next", "", func() -> void:
		if stop + 1 >= STOPS.size(): finish()
		else: go(stop + 1))
	hide()
	var offered := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tour="):
			offered = true
			get_tree().create_timer(1.0).timeout.connect(func() -> void: go(clampi(int(arg.trim_prefix("--tour=")) - 1, 0, STOPS.size() - 1)))
	# Offer the tour once, the first time the game is played for real.
	if not offered and DisplayServer.get_name() != "headless" and view.map.shot_path.is_empty() and not FileAccess.file_exists(SAVE):
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			if view.active and stop < 0: go(0))


func _button(parent: Node, text: String, variation: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.pressed.connect(action)
	parent.add_child(button)
	return button


## Resumes where the owner left off, or starts again after a finished tour.
func start() -> void:
	var config := ConfigFile.new()
	var at := 0
	if config.load(SAVE) == OK and not config.get_value("tour", "done", false):
		at = int(config.get_value("tour", "stop", 0))
	go(at)


func go(index: int) -> void:
	_stop_waiting()
	stop = clampi(index, 0, STOPS.size() - 1)
	example = 0
	show()
	_save(false)
	_apply()


func leave() -> void:
	_stop_waiting()
	_save(false)
	stop = -1
	hide()


func finish() -> void:
	_stop_waiting()
	_save(true)
	stop = -1
	hide()
	view.ledger.close()


func _save(done: bool) -> void:
	var config := ConfigFile.new()
	config.set_value("tour", "stop", 0 if done else maxi(0, stop))
	config.set_value("tour", "done", done)
	config.save(SAVE)


## Everyone who could illustrate a stop, best first.
func candidates(index: int) -> Array[int]:
	var population: RefCounted = life.population
	var society: RefCounted = population.society
	var temper: RefCounted = society.temper
	var found: Array[int] = []
	match index:
		1:
			for p: Dictionary in life.people:
				if int(p.kind) != 8 and not p.hidden: found.append(int(p.id))
		3, 4, 5:
			if temper == null: return found
			for p in population.size():
				if not society.alive[p]: continue
				if index == 3 and (temper.body_layer[p] > 0 or temper.training(p, population.day)): found.append(p)
				if index == 4 and temper.body_layer[p] >= 2: found.append(p)
				if index == 5 and temper.at_gate(p): found.append(p)
		7:
			for p in population.size():
				if society.alive[p] and population.age(p) >= 16: found.append(p)
				if found.size() >= 40: break
		8:
			for p in population.size():
				if society.alive[p] and (society.spouse[p] >= 0 or not society.children(p).is_empty()): found.append(p)
				if found.size() >= 40: break
	return found


func _needs_person(index: int) -> bool:
	return STOPS[index].has("wait")


## Puts the screen into the state the stop talks about.
func _apply() -> void:
	var entry: Dictionary = STOPS[stop]
	status.text = "Tour · stop %d of %d" % [stop + 1, STOPS.size()]
	title.text = entry.title
	words.text = entry.text
	back.disabled = stop == 0
	next.text = "Finish" if stop + 1 >= STOPS.size() else "Next: %s →" % STOPS[stop + 1].title.to_lower()
	archive_button.visible = stop == STOPS.size() - 1
	var found := candidates(stop)
	another.visible = found.size() > 1
	wait_button.visible = _needs_person(stop) and found.is_empty()
	if wait_button.visible:
		words.text += "\n\nNo one in the valley has got this far yet. Let time run and the tour will stop as soon as someone does."
	var person: int = found[example % found.size()] if not found.is_empty() else -1
	var ledger: PanelContainer = view.ledger
	match stop:
		0, 2, 9:
			ledger.close()
			if stop == 2: view.stories.set_collapsed(false)
		1:
			ledger.close()
			if person >= 0: view.show_person(person)
		3, 4, 5:
			if person >= 0: ledger.open_person(person, "Body & cultivation")
			else: ledger.open_tab("tempering")
		6:
			ledger.open_tab("forest")
		7:
			if person >= 0: ledger.open_person(person, "Heart & mind")
		8:
			if person >= 0: ledger.open_person(person, "Family & lineage")


func _target() -> Rect2:
	match stop:
		0: return view.ledger.top_bar.get_global_rect()
		1: return view.villager.get_global_rect() if view.villager.visible else Rect2()
		2: return view.stories.get_global_rect()
		9: return Rect2()
	return view.ledger.get_global_rect() if view.ledger.visible else Rect2()


func _toggle_wait() -> void:
	if waiting:
		_stop_waiting()
		_apply()
		return
	waiting = true
	saved_speed = life.speed
	life.speed = 1024
	life.paused = false
	wait_button.text = "Stop waiting"


func _stop_waiting() -> void:
	if not waiting:
		return
	waiting = false
	life.speed = saved_speed
	wait_button.text = "Let time run"


func _open_archive() -> void:
	var script := ProjectSettings.globalize_path("res://tools/archive_viewer.sh")
	OS.create_process("bash", [script])


func _process(dt: float) -> void:
	if stop < 0:
		return
	visible = view.active
	if waiting:
		poll += dt
		status.text = "Tour · stop %d of %d · waiting… %s" % [stop + 1, STOPS.size(), life.clock_text().get_slice(" · ", 0)]
		if poll >= 0.5:
			poll = 0.0
			if not candidates(stop).is_empty():
				_stop_waiting()
				_apply()
	target = _target()
	_place_card()
	queue_redraw()


## The card sits beside what it explains, never on top of it if there is room.
func _place_card() -> void:
	var screen := get_viewport_rect().size
	card.reset_size()
	var card_size := card.size
	var at := screen - card_size - Vector2(24, 24)
	if target.has_area():
		if target.end.x + 24 + card_size.x <= screen.x:
			at = Vector2(target.end.x + 24, clampf(target.get_center().y - card_size.y / 2.0, 72, screen.y - card_size.y - 16))
		elif target.position.x - 24 - card_size.x >= 0:
			at = Vector2(target.position.x - 24 - card_size.x, clampf(target.get_center().y - card_size.y / 2.0, 72, screen.y - card_size.y - 16))
		elif target.end.y + 16 + card_size.y <= screen.y:
			at = Vector2(clampf(target.get_center().x - card_size.x / 2.0, 16, screen.x - card_size.x - 16), target.end.y + 16)
	else:
		at = (screen - card_size) / 2.0
	card.position = at.round()


func _draw() -> void:
	if not target.has_area():
		return
	var screen := get_viewport_rect().size
	var shade := Color(Palette.INK, 0.4)
	# The book brings its own shade; the tour only adds the frame around it.
	if not view.ledger.visible:
		draw_rect(Rect2(0, 0, screen.x, target.position.y), shade)
		draw_rect(Rect2(0, target.end.y, screen.x, screen.y - target.end.y), shade)
		draw_rect(Rect2(0, target.position.y, target.position.x, target.size.y), shade)
		draw_rect(Rect2(target.end.x, target.position.y, screen.x - target.end.x, target.size.y), shade)
	draw_rect(target.grow(3), Palette.GOLD, false, 3)
