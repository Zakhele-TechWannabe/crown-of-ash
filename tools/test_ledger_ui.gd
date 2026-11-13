extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	var world: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var ledger: PanelContainer = world.ground_view.ledger
	world._go_to("Servants' Village", false)
	var icon_hashes: Dictionary = {}
	var contact := Image.create(650, ceili((ledger.life.economy.goods.size() + ledger.life.economy.catalogue.categories.size()) / 13.0) * 50, false, Image.FORMAT_RGBA8)
	contact.fill(Color("e8dfc9"))
	var icon_index := 0
	for id: String in ledger.life.economy.goods:
		var texture: Texture2D = ledger.grain_icon(id, Color(ledger.life.economy.goods[id].colour))
		assert(texture.get_image().get_pixel(0, 0).a == 0.0)
		var fingerprint := texture.get_image().get_data().hex_encode()
		assert(not icon_hashes.has(fingerprint), "Duplicate good icon: " + id)
		icon_hashes[fingerprint] = id
		contact.blit_rect(texture.get_image(), Rect2i(0, 0, 40, 40), Vector2i(icon_index % 13 * 50 + 5, icon_index / 13 * 50 + 5))
		icon_index += 1
	for category: Dictionary in ledger.life.economy.catalogue.categories:
		var texture: Texture2D = ledger.grain_icon(category.id, Color.WHITE)
		assert(texture.get_image().get_used_rect().has_area())
		contact.blit_rect(texture.get_image(), Rect2i(0, 0, 40, 40), Vector2i(icon_index % 13 * 50 + 5, icon_index / 13 * 50 + 5))
		icon_index += 1
	contact.resize(contact.get_width() * 2, contact.get_height() * 2, Image.INTERPOLATE_NEAREST)
	contact.save_png("res://out/food-icons.png")
	var book_width := minf(1320, 1920 - 96)
	for key: String in ledger.TABS:
		ledger.tab_buttons[key].pressed.emit()
		await process_frame
		await process_frame
		assert(ledger.visible and ledger.dim.visible)
		assert(is_equal_approx(ledger.size.x, book_width), "Book is centred at reading width: %s" % ledger.size)
		assert(absf(ledger.get_global_rect().get_center().x - 960) <= 1, "Book is centred")
		assert(ledger.content.size.x > 850)
		assert(ledger.tab_buttons[key].button_pressed)
		ledger.toggle_tab(key)
		await settle(ledger)
		assert(not ledger.visible and not ledger.dim.visible)
	for width: int in [1920, 1366]:
		root.content_scale_size = Vector2i(width, 1080)
		root.size = Vector2i(width, 1080)
		world.life.economy.hungry_count = 2
		ledger.alerts_day = -1
		ledger._refresh_hud()
		await process_frame
		await process_frame
		assert(ledger.top_bar.get_combined_minimum_size().x <= width, "Top bar must fit viewport")
		assert(ledger.top_bar.size.y <= 64, "Top bar must stay one thin row: %s" % ledger.top_bar.size)
		var row: HBoxContainer = ledger.top_bar.get_child(0)
		var previous_right := 0.0
		for child: Control in row.get_children():
			if not child.visible: continue
			assert(child.position.x >= previous_right, "Top bar controls must not overlap")
			previous_right = child.position.x + child.size.x
		assert(previous_right <= width)
		check_text(ledger.top_bar)
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	await process_frame
	var hungry_chip: Button = ledger.alert_row.get_child(0)
	assert(hungry_chip.visible and hungry_chip.text == "2 hungry" and hungry_chip.theme_type_variation == "Hot")
	hungry_chip.pressed.emit()
	assert(ledger.current == "people" and ledger.visible)
	world.life.economy.hungry_count = 0
	ledger.food_chip.pressed.emit()
	assert(ledger.current == "food")
	ledger.people_button.pressed.emit()
	assert(ledger.current == "people")
	assert(ledger.people_button.text.ends_with(" people") and int(ledger.people_button.text) == ledger.living)
	ledger.ledger_button.pressed.emit()
	await settle(ledger)
	assert(not ledger.visible)
	ledger.ledger_button.pressed.emit()
	assert(ledger.visible)
	for index: int in ledger.SPEEDS.size():
		ledger.speed_selector.item_selected.emit(index)
		assert(world.life.speed == ledger.SPEEDS[index])
	world.life.speed = 1
	world.life.paused = true
	ledger._refresh_hud()
	assert(ledger.pause_button.text == "▶")
	ledger.pause_button.pressed.emit()
	assert(not world.life.paused)
	for index: int in 7:
		var speed_key := InputEventKey.new()
		speed_key.pressed = true
		speed_key.keycode = KEY_1 + index
		world.life._input(speed_key)
		ledger._refresh_hud()
		assert(ledger.speed_selector.selected == index)
	world.life.speed = 1
	var space_key := InputEventKey.new()
	space_key.pressed = true
	space_key.keycode = KEY_SPACE
	world.life._input(space_key)
	assert(world.life.paused)
	for index: int in ledger.TABS.size():
		var tab_key := InputEventKey.new()
		tab_key.pressed = true
		tab_key.keycode = KEY_F1 + index
		world.ground_view._unhandled_input(tab_key)
		assert(ledger.current == ledger.TABS.keys()[index])
		await settle(ledger)
	ledger.open_tab("rice")
	assert(ledger.current == "food")
	await settle(ledger)
	ledger.open_tab("food/grains/rice")
	await settle(ledger)
	assert(ledger.food_path == ["food", "grains", "rice"])
	assert(ledger.food_grid.columns >= 3)
	assert(ledger.food_grid.get_child_count() > 0)
	var slot: Button = ledger.food_grid.get_child(0)
	var good_id: String = slot.get_meta("food_id")
	assert(world.life.economy.goods.has(good_id))
	slot.pressed.emit()
	assert(ledger.selected_food == good_id)
	ledger.food_up()
	assert(ledger.selected_food.is_empty())
	assert(ledger.food_path == ["food", "grains"])
	ledger.open_tab("food/grains/rice")
	await settle(ledger)
	ledger.food_grid.get_child(0).pressed.emit()
	await process_frame
	await process_frame
	var scroll_before: int = ledger.drawer_scroll.scroll_vertical
	var before: Vector2 = world.ground_view.cam.zoom
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = ledger.global_position + Vector2(340 if ledger.sidebar.visible else 80, 250)
	root.push_input(wheel)
	await process_frame
	assert(world.ground_view.cam.zoom == before, "Book wheel must not zoom camera")
	assert(ledger.drawer_scroll.scroll_vertical > scroll_before, "Good details scroll in the page")
	var back := InputEventKey.new()
	back.pressed = true
	back.keycode = KEY_BACKSPACE
	root.push_input(back)
	assert(ledger.food_path == ["food", "grains"])
	var right := InputEventMouseButton.new()
	right.pressed = true
	right.button_index = MOUSE_BUTTON_RIGHT
	right.position = wheel.position
	root.push_input(right)
	assert(ledger.food_path == ["food"])
	# While the book is open the world beneath it does not move, even mid-drag.
	world.ground_view.dragging = true
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(30, 300)
	motion.relative = Vector2(30, 20)
	var camera_position: Vector2 = world.ground_view.cam.position
	world.ground_view._unhandled_input(motion)
	assert(not world.ground_view.dragging)
	assert(world.ground_view.cam.position == camera_position)
	ledger.close()
	await settle(ledger)
	assert(ledger.current == "food", "Remember last section")
	# With the book closed the wheel steps through whole-texel zooms only.
	wheel.position = Vector2(960, 600)
	world.ground_view.set_zoom_step(3)
	world.ground_view._unhandled_input(wheel)
	assert(is_equal_approx(world.ground_view.cam.zoom.x, 1.0), "Wheel steps down one zoom: %s" % world.ground_view.cam.zoom)
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	for i in 6: world.ground_view._unhandled_input(wheel)
	assert(is_equal_approx(world.ground_view.cam.zoom.x, 2.0), "Zoom stops at the largest step")
	world.ground_view.set_zoom_step(3)
	# Selecting someone on the map opens their card; the card leads to the book.
	var walker: Dictionary = world.life.people[0]
	var walker_id := int(walker.id)
	assert(world.life.walker_of(walker_id) == 0)
	world.ground_view.show_person(walker_id)
	await process_frame
	await process_frame
	var card: PanelContainer = world.ground_view.villager
	assert(card.visible and card.name_label.text == world.life.population.names[walker_id])
	assert(world.life.followed == 0)
	card.follow_button.pressed.emit()
	assert(world.life.followed == -1, "Follow toggles off")
	card.follow_button.pressed.emit()
	assert(world.life.followed == 0)
	assert(card.get_global_rect().end.y <= 1080 and card.get_global_rect().position.x >= 0)
	check_text(card)
	if not walker.hidden:
		var clicked: int = world.life.pick(world.life.place_of(walker_id) - Vector2(0, 10))
		assert(clicked >= 0, "Clicking a drawn person picks them")
	ledger.open_person(walker_id, "Heart & ties")
	await settle(ledger)
	var browser: VBoxContainer = ledger.people_browser
	assert(browser.person == walker_id and browser.person_tab == "Heart & ties")
	var book: VBoxContainer = browser.get_child(0)
	var header: HBoxContainer = book.get_child(0)
	var show_button: Button = header.get_child(header.get_child_count() - 1)
	assert(show_button.text == "Show on map")
	show_button.pressed.emit()
	await settle(ledger)
	assert(world.life.selected == walker_id and world.life.followed == 0 and not ledger.visible)
	# The contextual guardian record survives the book's closing animation.
	ledger.open_tab("laws")
	await settle(ledger)
	var inspect: Array[Node] = ledger.content.find_children("*", "Button", true, false).filter(func(n: Node) -> bool: return n.text.begins_with("The ") and n.text.contains("swordsman"))
	assert(not inspect.is_empty())
	inspect[0].pressed.emit()
	await settle(ledger)
	assert(world.ground_view.guardian_card.visible, "Guardian inspection stays open after closing the book")
	world.ground_view.guardian_card.hide()
	# Stories lead to the person they are about.
	var society: RefCounted = world.life.population.society
	society.note(walker_id, "tempering", world.life.population.names[walker_id] + " tests the tour of stories.")
	var rail: PanelContainer = world.ground_view.stories
	rail.refresh()
	var story: Button = rail.list.get_child(0)
	assert("tests the tour of stories" in story.text)
	world.life.selected = -1
	story.pressed.emit()
	assert(world.life.selected == walker_id)
	for filter: String in rail.FILTERS:
		rail.filter = filter
		rail.seen = ""
		rail.refresh()
		await process_frame
		check_text(rail)
	rail.filter = "All"
	ledger.open_tab("people")
	browser = ledger.people_browser
	assert(browser.group_mode == "Place")
	browser.path.assign(["Servants' Village", world.life.population.district_name(0), world.life.population.household_name(0)])
	browser.redraw()
	assert(browser.virtual_list.ids.size() == 3)
	browser.virtual_list.person_selected.emit(0)
	assert(browser.person == 0 and browser.person_tab == "Overview" and ledger.visible)
	var groups: Array = world.life.population.society.factions
	var village_name: String = groups[0].name
	var home_name: String = groups[1].name
	groups[0].name = "Shared name"
	groups[1].name = "Shared name"
	browser.group_mode = "Faction"
	browser.path.assign(["faction:1"])
	browser.person = -1
	browser.redraw()
	assert(browser.virtual_list.ids.size() == groups[1].members.size(), "Same-name factions must not merge their member lists")
	groups[0].name = village_name
	groups[1].name = home_name
	browser.group_mode = "Place"
	browser.path.clear()
	browser.redraw()

	for path: String in ["food/vegetables/greens", "food/fruit", "food/meat", "food/fish", "food/pantry"]:
		ledger.open_tab(path)
		await process_frame
		assert(ledger.food_grid.get_child_count() > 0)
		ledger.food_grid.get_child(0).pressed.emit()
		await process_frame
		assert(not ledger.selected_food.is_empty())
		assert(ledger.grain_icon(ledger.selected_food, Color.WHITE) != null)
	assert("Vegetables" in ledger.food_chip.tooltip_text)
	assert("Preserved & pantry" in ledger.food_chip.tooltip_text)
	ledger.show_granary()
	assert(ledger.visible and ledger.current == "food")
	world.life.paused = true
	world.life.minutes = 199 * 1440.0 + 720
	world.life.economy.advance_to(world.life.minutes)
	ledger.set_process(false)
	var tour: Control = world.ground_view.tour
	for resolution: Vector2i in [Vector2i(1920, 1080), Vector2i(1366, 768)]:
		root.content_scale_size = resolution
		root.size = resolution
		ledger._layout()
		ledger._refresh_hud()
		await process_frame
		await process_frame
		var paths: Array[String] = []
		for tab: String in ledger.TABS: paths.append(tab)
		for category: Dictionary in ledger.life.economy.catalogue.categories:
			var ancestry: Array[String] = [category.id]
			var ancestor: String = category.parent
			while not ancestor.is_empty():
				ancestry.push_front(ancestor)
				for entry: Dictionary in ledger.life.economy.catalogue.categories:
					if entry.id == ancestor:
						ancestor = entry.parent
						break
			paths.append("/".join(ancestry))
		for people_path: String in ["people/place", "people/work", "people/life", "people/status", "people/list", "people/skills", "people/skills/land", "people/skills/grain", "people/skills/farming", "people/skills/cultivation"]: paths.append(people_path)
		for tab: String in preload("res://src/person_book.gd").TABS: paths.append("person/" + tab)
		for path: String in paths:
			if path.begins_with("person/"):
				ledger.open_person(walker_id, path.trim_prefix("person/"))
			else:
				ledger.open_tab("people" if path.begins_with("people/") else path)
			if path.begins_with("people/"):
				browser = ledger.people_browser
				if path == "people/work": browser.group_mode = "Work"
				if path == "people/life": browser.group_mode = "Life stage"
				if path == "people/status": browser.group_mode = "Status"
				if path == "people/list": browser.path.assign(["Servants' Village", world.life.population.district_name(0), world.life.population.household_name(0)])
				if path.begins_with("people/skills"):
					browser.catalogue_mode = true
					if path == "people/skills/land": browser.catalogue_path.assign(["land"])
					if path == "people/skills/grain": browser.catalogue_path.assign(["land", "grain_farming"])
					if path == "people/skills/farming": browser.catalogue_path.assign(["land", "grain_farming", "grain_farming.farming"])
					if path == "people/skills/cultivation": browser.catalogue_path.assign(["cultivation"])
				browser.redraw()
			await settle(ledger)
			if path == "person/Cultivation":
				var person_book: VBoxContainer = ledger.people_browser.get_child(0)
				var labels: Array[Node] = person_book.find_children("*", "Label", true, false)
				for a in 8:
					var caption := "%s %.1f" % [str(world.life.population.catalogue.rules.attributes[a]).capitalize(), world.life.population.attributes[walker_id * 8 + a]]
					assert(labels.any(func(n: Node) -> bool: return n.text.begins_with(caption)), "All eight attribute numbers: " + caption)
				var bar: ProgressBar = person_book.find_child("LifeBar", true, false)
				assert(bar != null and bar.max_value == world.life.population.society.lifespan(walker_id) and bar.value == world.life.population.age(walker_id), "Life bar tracks age and lifespan")
				var graphs: Array[Node] = person_book.find_children("*", "Control", true, false).filter(func(n: Node) -> bool: return n.get_script() == preload("res://src/ego_graph.gd"))
				assert(graphs.size() == 1 and graphs[0].mode == "Skills" and not graphs[0].nodes.is_empty(), "Skill graph builds")
				assert(labels.any(func(n: Node) -> bool: return n.text == "Everything they know" or n.text == "No skills practised yet."), "Compact skills list remains")
			check_text(world.ground_view.hud)
			assert(ledger.get_global_rect().end.x <= resolution.x and ledger.get_global_rect().position.x >= 0, "Book must stay on screen: %s %s" % [resolution, path])
			if ledger.current in ["food", "materials"]:
				var goods: Array[String] = []
				for slot_button: Button in ledger.food_grid.get_children():
					var id: String = slot_button.get_meta("food_id")
					if ledger.life.economy.goods.has(id): goods.append(id)
				for id: String in goods:
					ledger.selected_food = id
					ledger.refresh_values()
					await process_frame
					await process_frame
					check_text(world.ground_view.hud)
		var tip_panel := PanelContainer.new()
		tip_panel.theme = world.ground_view.ui.theme
		root.add_child(tip_panel)
		tip_panel.add_child(ledger.food_chip._make_custom_tooltip(ledger.food_chip.tooltip_text))
		await process_frame
		await process_frame
		check_text(tip_panel)
		tip_panel.queue_free()
		ledger.open_tab("work")
		for id: String in ledger.workplaces(ledger.life.economy):
			ledger.selected_work = id
			ledger.refresh_values()
			await process_frame
			await process_frame
			check_text(world.ground_view.hud)
		# Every tour stop explains itself on screen, with its card beside the part it points at.
		ledger.close()
		await settle(ledger)
		for stop: int in tour.STOPS.size():
			tour.go(stop)
			await settle(ledger)
			tour._process(0.0)
			await process_frame
			assert(tour.visible and tour.title.text == tour.STOPS[stop].title)
			var rect: Rect2 = tour.card.get_global_rect()
			assert(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= resolution.x and rect.end.y <= resolution.y, "Tour card on screen: stop %d %s" % [stop + 1, rect])
			check_text(tour.card)
		tour.leave()
		assert(not tour.visible)
		var saved := ConfigFile.new()
		assert(saved.load(tour.SAVE) == OK and int(saved.get_value("tour", "stop")) == tour.STOPS.size() - 1, "Tour resumes where it was left")
		tour.start()
		assert(tour.stop == tour.STOPS.size() - 1)
		tour.finish()
		ledger.close()
		await settle(ledger)
	print("PASS ledger UI: top bar, alerts, centred book, person tabs, villager card, stories, tour, integer zoom; every page fits at 1920x1080 and 1366x768 on day 200")
	quit()

# Heavy chunk workers can span a frame; a wall-clock timer does not imply the
# animation has processed its final callback yet.
func settle(ledger: PanelContainer) -> void:
	await create_timer(0.2).timeout
	if ledger.slide != null and ledger.slide.is_valid() and ledger.slide.is_running():
		await ledger.slide.finished
	await process_frame

# Shape the actual wrapped lines with the inherited font. Check descendants even
# below the scroll fold, since they become visible when scrolled into view.
func check_text(node: Node) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Label or node is Button:
		assert_text(node.global_position.x >= -1 and node.global_position.x + node.size.x <= root.content_scale_size.x + 1, "Text control outside viewport: " + node.text)
		var text: String = node.text
		if not text.is_empty():
			var font: Font = node.get_theme_font("font")
			var px: int = node.get_theme_font_size("font_size")
			var available: float = node.size.x
			var available_height: float = node.size.y
			if node is Button:
				var style: StyleBox = node.get_theme_stylebox("normal")
				available -= style.get_minimum_size().x
				available_height -= style.get_minimum_size().y
				if node.icon: available -= node.icon.get_width() + node.get_theme_constant("h_separation")
			var paragraph := TextParagraph.new()
			paragraph.width = maxf(1, available)
			paragraph.break_flags = TextServer.BREAK_MANDATORY
			if node.autowrap_mode != TextServer.AUTOWRAP_OFF:
				assert_text(available >= 40, "Autowrap must have at least 40px: " + text)
				paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
			paragraph.add_string(text, font, px)
			for line in paragraph.get_line_count():
				assert_text(paragraph.get_line_width(line) <= available + 1, "Text overflow: %s (%s > %s)" % [text, paragraph.get_line_width(line), available])
			assert_text(paragraph.get_size().y <= available_height + 1, "Text height clipped: " + text)
	if node is Button:
		if node.get_parent() is HBoxContainer and node.get_parent().get_parent().has_meta("data") and node.text != "":
			assert_text(node.size_flags_horizontal != Control.SIZE_EXPAND_FILL, "Breadcrumbs stay compact")
		if node.has_meta("work_id"):
			assert_text(is_equal_approx(node.size.x, 264), "Work cards must have consistent widths")
			assert_text(node.size.y <= 160, "Work cards must remain compact")
		for child: Node in node.get_children():
			if child is Container:
				assert_text(child.position.y >= 0 and child.position.y + child.size.y <= node.size.y + 1, "Card content extends beyond button: %s %s child %s %s (minimum %s)" % [node.name, node.size, child.position, child.size, child.get_combined_minimum_size()])
	if node is Tree:
		var item: TreeItem = node.get_root().get_first_child()
		while item:
			for col in node.columns:
				var measured: float = node.get_theme_font("font").get_string_size(item.get_text(col), HORIZONTAL_ALIGNMENT_LEFT, -1, node.get_theme_font_size("font_size")).x
				assert_text(measured <= node.get_column_width(col) - 12, "Table cell clipped: " + item.get_text(col))
			item = item.get_next()
	for child: Node in node.get_children(): check_text(child)

func assert_text(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
	assert(condition, message)
