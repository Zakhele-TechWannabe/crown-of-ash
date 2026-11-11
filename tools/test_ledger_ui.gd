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
	for index: int in 5:
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
	ledger.show_granary()
	await process_frame
	assert(ledger.granary_card.visible and ledger.granary_card.size.x >= 460)
	print("PASS ledger UI: tabs, KPI navigation/states, 1920/1366 layout, speed/keyboard controls, inventory paths/selection/back, wheel scrolling/camera isolation, follow, granary")
	quit()

# Heavy chunk workers can span a frame; a wall-clock timer does not imply the
# animation has processed its final callback yet.
func settle(ledger: PanelContainer) -> void:
	await create_timer(0.2).timeout
	if ledger.slide != null and ledger.slide.is_valid() and ledger.slide.is_running():
		await ledger.slide.finished
	await process_frame
