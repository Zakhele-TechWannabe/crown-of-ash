extends PanelContainer
## The left rail: the valley's newest stories, each one a way to meet the person it is about.
const Palette = preload("res://src/palette.gd")
const FILTERS := {
	"All": [],
	"Tempering": ["tempering_method", "tempering_gate", "tempering", "gathering", "hunt", "injury"],
	"Family": ["pregnancy", "birth", "marriage", "old_age", "legacy", "apprenticeship"],
	"Cultivation": ["awakening", "breakthrough", "technique", "manual", "setback", "absorption", "formation", "harvested"],
	"Conflict": ["confrontation", "fight", "killed", "schism", "betrayal", "reconciliation", "oath"],
}
const WIDTH := 300.0
const SHOWN := 30
var view: Node2D
var life: Node2D
var filter := "All"
var list: VBoxContainer
var scroll: ScrollContainer
var body: VBoxContainer
var toggle: Button
var collapsed := false
var seen := ""
var timer := 0.0


func setup(ground_view: Node2D) -> void:
	view = ground_view
	life = view.map.life
	view.ui.add_child(self)
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = 16
	offset_right = 16 + WIDTH
	offset_top = 76
	offset_bottom = -16
	var column := VBoxContainer.new()
	add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	var title := Label.new()
	title.text = "Stories"
	title.theme_type_variation = "Title"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	toggle = Button.new()
	toggle.theme_type_variation = "Chip"
	toggle.text = "‹"
	toggle.tooltip_text = "Fold the stories away"
	toggle.pressed.connect(func() -> void: set_collapsed(not collapsed))
	top.add_child(toggle)
	body = VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var chips := HFlowContainer.new()
	body.add_child(chips)
	var group := ButtonGroup.new()
	for key: String in FILTERS:
		var chip := Button.new()
		chip.text = key
		chip.theme_type_variation = "Chip"
		chip.toggle_mode = true
		chip.button_group = group
		chip.set_pressed_no_signal(key == filter)
		chip.pressed.connect(func() -> void: filter = key; seen = ""; refresh())
		chips.add_child(chip)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)


func set_collapsed(value: bool) -> void:
	collapsed = value
	body.visible = not collapsed
	toggle.text = "›" if collapsed else "‹"
	toggle.tooltip_text = "Show the stories" if collapsed else "Fold the stories away"
	offset_right = offset_left + (150.0 if collapsed else WIDTH)
	_fit()


## The rail stops above the villager card when someone is selected.
func _fit() -> void:
	var card: Control = view.villager
	offset_bottom = -16.0 if collapsed or not card.visible else -(card.size.y + 28.0)
	# Only as tall as its stories, up to the space it has.
	var room := get_viewport_rect().size.y + offset_bottom
	var wanted := offset_top + get_combined_minimum_size().y + (0.0 if collapsed else list.get_combined_minimum_size().y)
	anchor_bottom = 0.0
	offset_bottom = minf(room, wanted)


func _process(dt: float) -> void:
	visible = view.active
	if not visible:
		return
	_fit()
	timer += dt
	if timer < 0.5:
		return
	timer = 0.0
	refresh()


func _season(day: int) -> String:
	return "Y%d %s" % [day / 365 + 1, ["Spring", "Summer", "Autumn", "Winter"][mini(3, (day % 365) / 91)]]


func refresh() -> void:
	var chronicle: Array = life.population.society.chronicle
	var stamp := "%d:%s:%s" % [chronicle.size(), str(chronicle[-1].day) if not chronicle.is_empty() else "", str(chronicle[-1].text) if not chronicle.is_empty() else ""]
	if stamp == seen:
		return
	seen = stamp
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var kinds: Array = FILTERS[filter]
	var count := 0
	for i in range(chronicle.size() - 1, -1, -1):
		var entry: Dictionary = chronicle[i]
		if not kinds.is_empty() and not str(entry.kind) in kinds:
			continue
		var person := int(entry.person)
		var card := Button.new()
		card.theme_type_variation = "Card"
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.text = "%s · %s\n%s" % [_season(int(entry.day)), str(entry.kind).replace("_", " "), entry.text]
		card.tooltip_text = "Select them in the valley" if person >= 0 else ""
		card.disabled = person < 0
		card.pressed.connect(func() -> void: view.show_person(person, false))
		list.add_child(card)
		count += 1
		if count >= SHOWN:
			break
	if count == 0:
		var quiet := Label.new()
		quiet.text = "Nothing of this kind has happened yet."
		quiet.theme_type_variation = "Small"
		quiet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		quiet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(quiet)
