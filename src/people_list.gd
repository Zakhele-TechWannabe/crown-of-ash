extends VBoxContainer
## A fixed-height virtual list. Filtering/sorting builds an ID index once; scrolling
## only materialises the viewport plus two overscan rows, regardless of population.
signal person_selected(person: int)
const UiTheme = preload("res://src/ui_theme.gd")
const Palette = preload("res://src/palette.gd")
const PersonBook = preload("res://src/person_book.gd")
const ROW_HEIGHT := 150
var row_summary := Callable()
var reason_source: VBoxContainer
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
		for child: Node in row.get_children():
			row.remove_child(child)
			child.queue_free()
		row.text = ""
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.position = Vector2(UiTheme.SPACE_16, UiTheme.SPACE_8)
		box.size = Vector2(row.size.x - UiTheme.SPACE_16 * 2, ROW_HEIGHT - UiTheme.SPACE_16)
		row.add_child(box)
		var name_label := Label.new()
		name_label.text = population.names[person] + " · " + PersonBook.path_stage(population, person)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.clip_text = true
		box.add_child(name_label)
		var subtitle := Label.new()
		subtitle.theme_type_variation = "Small"
		subtitle.text = row_summary.call(person) if row_summary.is_valid() else "%d · %s · %s" % [population.age(person), population.jobs[population.job[person]], population.district_name(person)]
		box.add_child(subtitle)
		var years: int = population.society.lifespan(person)
		var life_label := Label.new()
		life_label.theme_type_variation = "Small"
		life_label.text = "%d of ~%d years" % [population.age(person), years]
		box.add_child(life_label)
		var bar := ProgressBar.new()
		bar.max_value = years
		bar.value = population.age(person)
		UiTheme.thin(bar, Palette.RED if years - population.age(person) <= 5 else Palette.GREEN, UiTheme.SPACE_8)
		box.add_child(bar)
		var tags := HFlowContainer.new()
		box.add_child(tags)
		if is_instance_valid(reason_source): reason_source.tags(tags, person)
		for child: Control in box.get_children(): child.mouse_filter = Control.MOUSE_FILTER_PASS
		row.tooltip_text = "%s · %s" % [population.names[person], PersonBook.path_stage(population, person)]

	page_build_usec = Time.get_ticks_usec() - began
