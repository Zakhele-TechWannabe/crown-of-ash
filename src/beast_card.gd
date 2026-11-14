extends PanelContainer
const UiTheme = preload("res://src/ui_theme.gd")
const Law = preload("res://src/law.gd")
var view: Node2D
var beast: Dictionary = {}
var words: VBoxContainer
func setup(ground_view: Node2D) -> void:
	view = ground_view
	view.ui.add_child(self)
	custom_minimum_size.x = 360
	words = VBoxContainer.new()
	add_child(words)
	hide()
func open(record: Dictionary) -> void:
	beast = record
	view.map.life.selected = -1
	view.map.life.followed = -1
	for child in words.get_children():
		words.remove_child(child)
		child.queue_free()
	var wildlife: RefCounted = view.map.life.population.society.wildlife
	for text: String in [Law.title(beast.name), wildlife.description(beast), "%.1f of ~%.1f years · %.1f× lifespan" % [beast.age,wildlife.lifespan(beast),wildlife.rules.lifespan[int(beast.layer)]], "Roams " + wildlife.place(beast)]:
		var line := Label.new()
		line.text = text
		words.add_child(line)
	var bar := ProgressBar.new()
	bar.max_value = wildlife.lifespan(beast)
	bar.value = beast.age
	UiTheme.thin(bar, preload("res://src/palette.gd").GREEN, UiTheme.SPACE_8)
	words.add_child(bar)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(hide)
	words.add_child(close)
	reset_size()
	position = Vector2(16,get_viewport_rect().size.y-size.y-16)
	show()
func _process(_dt: float) -> void:
	if visible and (not view.active or view.ledger.visible or view.map.life.selected >= 0): hide()
