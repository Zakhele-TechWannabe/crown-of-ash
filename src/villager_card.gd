extends PanelContainer
## The small card for whoever is selected: who they are, what they are doing, what they want.
const Palette = preload("res://src/palette.gd")
const UiTheme = preload("res://src/ui_theme.gd")
const WIDTH := 420.0
var view: Node2D
var life: Node2D
var figure: TextureRect
var name_label: Label
var facts: Label
var body_line: Label
var now_line: Label
var want_line: Label
var follow_button: Button
var shown := -2
var timer := 0.0


func setup(ground_view: Node2D) -> void:
	view = ground_view
	life = view.map.life
	view.ui.add_child(self)
	custom_minimum_size.x = WIDTH
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	figure = TextureRect.new()
	figure.custom_minimum_size = Vector2(72, 72)
	figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	figure.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	figure.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(figure)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 3)
	row.add_child(words)
	var top := HBoxContainer.new()
	words.add_child(top)
	name_label = _line(top, "Title")
	var close := Button.new()
	close.text = "✕"
	close.theme_type_variation = "Chip"
	close.tooltip_text = "Deselect [Esc]"
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.pressed.connect(func() -> void: life.selected = -1; life.followed = -1)
	top.add_child(close)
	facts = _line(words, "Small")
	body_line = _line(words, "")
	now_line = _line(words, "")
	want_line = _line(words, "")
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	words.add_child(actions)
	follow_button = _button(actions, "Follow", func() -> void:
		var walker: int = life.walker_of(life.selected)
		if life.followed >= 0 and life.followed == walker:
			life.followed = -1
		else:
			view.show_person(life.selected))
	_button(actions, "Open book", func() -> void: view.ledger.open_person(life.selected, "Story"))
	_button(actions, "Ties", func() -> void: view.ledger.open_person(life.selected, "Ties"))
	hide()


func _line(parent: Node, variation: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _button(parent: Node, words: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = words
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _process(dt: float) -> void:
	var id: int = life.selected
	var valid: bool = id >= 0 and id < life.population.size() and view.active
	visible = valid
	if not valid:
		shown = -2
		return
	timer += dt
	if id == shown and timer < 0.5:
		_place()
		return
	timer = 0.0
	shown = id
	refresh()


func refresh() -> void:
	var id: int = life.selected
	var population: RefCounted = life.population
	var society: RefCounted = population.society
	var walker: int = life.walker_of(id)
	var child: bool = population.age(id) < 18
	figure.texture = (life.child_art if child else life.person_art)[0]
	figure.modulate = life.people[walker].tint if walker >= 0 else Palette.PAPER
	name_label.text = population.names[id]
	facts.text = "%d · %s · %s" % [population.age(id), population.jobs[population.job[id]], population.household_name(id)]
	var temper: RefCounted = society.temper
	var state: Dictionary = temper.describe(id) if temper else {}
	body_line.visible = temper != null and (int(state.layer) > 0 or state.training)
	if body_line.visible:
		body_line.text = ("%s · %s overall" % [state.name, state.grade]) if int(state.layer) > 0 else "Untempered · learning %s" % state.method
		if society.revealed[id]:
			body_line.text += " · " + society.realm_label(id)
	var now := ""
	if population.age(id) < 12:
		now = society.childhood.activity(id)
	elif temper and not str(state.gate).is_empty():
		now = "waiting at the gate of %s" % temper.layer_name(int(state.layer) + 1)
	elif temper and state.training and walker < 0:
		now = "drilling %d h a day%s" % [state.hours, (" under " + str(state.teacher)) if not str(state.teacher).is_empty() else ""]
	elif walker >= 0:
		now = life.activity_text(life.people[walker])
		if temper and state.training:
			now += " · drills %d h a day%s" % [state.hours, (" under " + str(state.teacher)) if not str(state.teacher).is_empty() else ""]
	else:
		now = "about the valley, out of sight"
	now_line.text = "Now: " + now
	want_line.text = ""
	if temper:
		var medicine: String = temper.wanted_medicine(id)
		if not str(state.gate).is_empty():
			want_line.text = "Wants: %s for %s" % [state.gate, temper.layer_name(int(state.layer) + 1)]
		elif not medicine.is_empty():
			want_line.text = "Wants: %s for %s (has %d of %d)" % [temper.config.medicine_names[medicine], temper.layer_name(int(state.layer) + 1), temper.medicine[medicine][id], temper.wild.units(medicine)]
	if want_line.text.is_empty() and society.mind:
		var goal := str(society.mind.describe(id).goal)
		if not goal.is_empty():
			want_line.text = "Wants: to " + goal
	want_line.visible = not want_line.text.is_empty()
	follow_button.text = "Stop following" if walker >= 0 and life.followed == walker else ("Follow" if walker >= 0 else "Show")
	follow_button.tooltip_text = "Keep the camera on them" if walker >= 0 else "Centre the view where they are"
	_place()


## Bottom-left corner, growing upward with its contents.
func _place() -> void:
	reset_size()
	position = Vector2(16, get_viewport_rect().size.y - size.y - 16).round()
