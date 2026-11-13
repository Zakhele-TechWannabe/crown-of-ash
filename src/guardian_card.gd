extends PanelContainer
## A contextual record for stone, including the rubble that remains after its last fight.
const UiTheme = preload("res://src/ui_theme.gd")
const Palette = preload("res://src/palette.gd")
const Combat = preload("res://src/combat.gd")
const Law = preload("res://src/law.gd")
var view: Node2D
var guardian: Dictionary = {}
var words: VBoxContainer
var elapsed := 0.0

func setup(ground_view: Node2D) -> void:
	view = ground_view
	view.ui.add_child(self)
	custom_minimum_size.x = 420
	words = VBoxContainer.new()
	add_child(words)
	hide()

func open(record: Dictionary) -> void:
	guardian = record
	view.map.life.selected = -1
	view.map.life.followed = -1
	refresh()
	show()

func _line(text: String, variation: String = "") -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(label)

func _meter(caption: String, value: float, colour: Color) -> void:
	_line("%s · %.0f / 100" % [caption, value])
	var bar := ProgressBar.new()
	bar.value = value
	UiTheme.thin(bar, colour, UiTheme.SPACE_8)
	words.add_child(bar)

func refresh() -> void:
	for child: Node in words.get_children():
		words.remove_child(child)
		child.queue_free()
	_line(Law.title(guardian.name), "Title")
	_line("%s · %s" % [guardian.gate, guardian.state], "Small")
	_meter("Energy", guardian.energy, Palette.JADE)
	var harm := float(guardian.get("harm", 0.0))
	_meter("Harm · " + ("rubble" if guardian.state == "broken" else ("chipped" if harm >= 60 else ("cracked" if harm >= 30 else "weathered"))), harm, Palette.RED)
	var stats := Combat.worn(Combat.beast("stone swordsman"), harm)
	_line("Power %.0f · guard %.0f · speed %.1f · breath %.0f" % [stats.power, stats.guard, stats.speed, stats.breath])
	_line("%d kills · %d driven off · %d fights" % [guardian.kills, guardian.get("driven_off", 0), guardian.get("fights", 0)])
	_line("Last fight · " + (str(guardian.last_fight) if not str(guardian.get("last_fight", "")).is_empty() else "None recorded"), "Small")
	if guardian.state == "broken":
		_line("Broken by %s on day %d" % [guardian.get("broken_by", "unknown"), guardian.get("broken_day", -1)])
	else:
		_line("On its plinth: mends %.0f harm a day. Above %.0f harm it stays home." % [view.map.life.population.society.law.config.mend_per_day, view.map.life.population.society.law.config.retreat_harm], "Small")
	var close := Button.new()
	close.text = "Close"
	close.theme_type_variation = "Chip"
	close.pressed.connect(hide)
	words.add_child(close)
	reset_size()
	position = Vector2(UiTheme.SPACE_16, get_viewport_rect().size.y - size.y - UiTheme.SPACE_16)

func _process(dt: float) -> void:
	if not visible: return
	if not view.active or (view.ledger.visible and not view.ledger.closing) or view.map.life.selected >= 0:
		hide()
		return
	elapsed += dt
	if elapsed >= .5:
		elapsed = 0
		refresh()
