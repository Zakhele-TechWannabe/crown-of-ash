extends VBoxContainer
## A fixed-height virtual list. Filtering/sorting builds an ID index once; scrolling
## only materialises the viewport plus two overscan rows, regardless of population.
signal person_selected(person: int)
const ROW_HEIGHT := 42
var population: RefCounted
var ids := PackedInt32Array()
var scroll: ScrollContainer
var surface: Control
var first := -1
var page_build_usec := 0
var buttons: Array[Button] = []

func setup(store: RefCounted, selected_ids: PackedInt32Array) -> void:
	population = store
	ids = selected_ids
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 420
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	surface = Control.new()
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.custom_minimum_size.y = ids.size() * ROW_HEIGHT
	scroll.add_child(surface)
	scroll.get_v_scroll_bar().value_changed.connect(func(_value: float) -> void: build_page())
	scroll.resized.connect(func() -> void: first = -1; build_page())
	build_page()

func build_page(force_first: int = -1) -> void:
	var start := maxi(0, int(scroll.scroll_vertical / ROW_HEIGHT) - 1) if force_first < 0 else force_first
	if start == first: return
	var began := Time.get_ticks_usec()
	first = start
	var count := mini(ids.size() - start, maxi(12, ceili(scroll.size.y / ROW_HEIGHT) + 3))
	while buttons.size() < count:
		var row := Button.new()
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.clip_text = true
		row.theme_type_variation = "Card"
		row.pressed.connect(func() -> void: person_selected.emit(int(row.get_meta("person"))))
		surface.add_child(row)
		buttons.append(row)
	for i in buttons.size():
		var row := buttons[i]
		row.visible = i < count
		if i >= count: continue
		var person := ids[start + i]
		row.set_meta("person", person)
		row.position = Vector2(0, (start + i) * ROW_HEIGHT)
		row.size = Vector2(maxf(100, scroll.size.x - 18), ROW_HEIGHT - 2)
		var best := int(population.best_skill[person])
		var skill_name := str(population.catalogue.nodes[best].name) if best >= 0 else "Untrained"
		row.text = "%s · %d · %s %d · %s" % [population.names[person], population.age(person), population.catalogue.title(population.best_level[person]), population.best_level[person], skill_name]
		row.tooltip_text = "%s\n%s · %s\nMood %.0f%% · Hunger %d" % [row.text, population.jobs[population.job[person]], "female" if population.sex[person] else "male", population.mood[person] * 100, population.hunger[person]]
	page_build_usec = Time.get_ticks_usec() - began
