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
	for key: String in ledger.TABS:
		ledger.open_tab(key)
		await process_frame
		await process_frame
		assert(ledger.visible)
		assert(is_equal_approx(ledger.size.x, 960))
		assert(ledger.content.size.x > 500)
		ledger.toggle_tab(key)
		await settle(ledger)
		assert(not ledger.visible)
	assert(ledger.kpi_cards.size() == 4)
	assert(ledger.kpi_cards.year.label.text == "after harvest")
	assert(ledger.kpi_cards.year.value.text.ends_with(" d"))
	assert("Next harvest" in ledger.kpi_cards.year.button.tooltip_text)
	for width: int in [1920, 1366]:
		root.content_scale_size = Vector2i(width, 1080)
		root.size = Vector2i(width, 1080)
		ledger._refresh_hud()
		await process_frame
		await process_frame
		assert(ledger.hud_panel.get_combined_minimum_size().x <= width, "HUD must fit viewport")
		assert(ledger.hud_panel.size.y <= 64, "HUD must stay one thin row")
		var row: HBoxContainer = ledger.hud_panel.get_child(0)
		var previous_right := 0.0
		for child: Control in row.get_children():
			assert(child.position.x >= previous_right, "HUD controls must not overlap")
			previous_right = child.position.x + child.size.x
			if child is Button:
				assert(child.text not in ["Overview", "Food", "People", "Work", "Chronicle"])
		assert(previous_right <= width)
	for definition: Dictionary in ledger.KPIS:
		ledger.kpi_cards[definition.id].button.pressed.emit()
		assert(ledger.current == definition.tab and ledger.visible)
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
	world.life.economy.day = 300
	ledger._refresh_hud()
	assert(ledger.kpi_cards.harvest.label.text == "planting in 66 d")
	world.life.economy.day = 1
	world.life.economy.hungry_count = 2
	ledger._refresh_hud()
	assert(ledger.kpi_cards.people.label.text == "2 hungry")
	assert(ledger.kpi_cards.people.value.get_theme_color("font_color") == Color("a23522"))
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
	wheel.position = ledger.global_position + Vector2(80, 250)
	root.push_input(wheel)
	await process_frame
	assert(world.ground_view.cam.zoom == before, "Drawer wheel must not zoom camera")
	assert(ledger.drawer_scroll.scroll_vertical > scroll_before, "Good details scroll in the outer container")
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
	# Exercise the camera guard directly, including a drag crossing into the drawer.
	world.ground_view.dragging = true
	var motion := InputEventMouseMotion.new()
	motion.position = wheel.position
	motion.relative = Vector2(30, 20)
	var camera_position: Vector2 = world.ground_view.cam.position
	world.ground_view._unhandled_input(motion)
	assert(not world.ground_view.dragging)
	assert(world.ground_view.cam.position == camera_position)
	wheel.position = Vector2(30, 300)
	world.ground_view._unhandled_input(wheel)
	assert(world.ground_view.cam.zoom.x < before.x, "World area remains interactive")
	ledger.open_tab("food")
	assert(ledger.food_path == ["food"] and ledger.selected_food.is_empty())
	ledger.close()
	await settle(ledger)
	assert(ledger.current == "food", "Remember last tab")
	ledger.open_tab("people")
	var person: TreeItem = ledger.tree.get_root().get_first_child()
	person.select(0)
	await settle(ledger)
	assert(world.life.followed >= 0 and not ledger.visible)
	for path: String in ["food/vegetables/greens", "food/fruit", "food/meat", "food/fish", "food/pantry"]:
		ledger.open_tab(path)
		await process_frame
		assert(ledger.food_grid.get_child_count() > 0)
		ledger.food_grid.get_child(0).pressed.emit()
		await process_frame
		assert(not ledger.selected_food.is_empty())
		assert(ledger.grain_icon(ledger.selected_food, Color.WHITE) != null)
	assert("Vegetables" in ledger.kpi_cards.food.button.tooltip_text)
	assert("Preserved & pantry" in ledger.kpi_cards.food.button.tooltip_text)
	ledger.show_granary()
	await process_frame
	assert(ledger.granary_card.visible and ledger.granary_card.size.x >= 460)
	world.life.paused = true
	world.life.minutes = 199 * 1440.0 + 720
	world.life.economy.advance_to(world.life.minutes)
	ledger.set_process(false)
	for resolution: Vector2i in [Vector2i(1920, 1080), Vector2i(1366, 768)]:
		root.content_scale_size = resolution
		root.size = resolution
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
		for path: String in paths:
			ledger.open_tab(path)
			await settle(ledger)
			check_text(world.ground_view.hud)
			assert(ledger.size.x <= resolution.x / 2.0 + 1, "Drawer must remain half width: %s %s %s min %s" % [resolution, path, ledger.size, ledger.get_combined_minimum_size()])
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
		for definition: Dictionary in ledger.KPIS:
			var tip_panel := PanelContainer.new()
			tip_panel.theme = ledger.theme
			root.add_child(tip_panel)
			tip_panel.add_child(ledger.kpi_cards[definition.id].button._make_custom_tooltip(ledger.kpi_cards[definition.id].button.tooltip_text))
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
	print("PASS ledger UI: navigation, controls, camera isolation, follow, granary; all tabs, food paths/goods and work details fit at 1920x1080 and 1366x768 on day 200")
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
				paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
			paragraph.add_string(text, font, px)
			for line in paragraph.get_line_count():
				assert_text(paragraph.get_line_width(line) <= available + 1, "Text overflow: %s (%s > %s)" % [text, paragraph.get_line_width(line), available])
			assert_text(paragraph.get_size().y <= available_height + 1, "Text height clipped: " + text)
	if node is Button:
		if node.has_meta("work_id"):
			assert_text(is_equal_approx(node.size.x, 176), "Work cards must have consistent widths")
		for child: Node in node.get_children():
			if child is Container:
				assert_text(child.position.y >= 0 and child.position.y + child.size.y <= node.size.y + 1, "Card content extends beyond button")
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
