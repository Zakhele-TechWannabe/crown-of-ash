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
		await create_timer(0.2).timeout
		assert(not ledger.visible)
	assert(ledger.rice_chip.get_parent().get_parent().get_combined_minimum_size().x <= 1920, "HUD must fit viewport")
	ledger.open_tab("rice")
	assert(ledger.current == "food")
	await create_timer(0.2).timeout
	var before: Vector2 = world.ground_view.cam.zoom
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	world.ground_view._unhandled_input(wheel)
	assert(world.ground_view.cam.zoom.x > before.x, "World camera remains interactive with drawer open")
	ledger.close()
	await create_timer(0.2).timeout
	assert(ledger.current == "food", "Remember last tab")
	ledger.open_tab("people")
	var person: TreeItem = ledger.tree.get_root().get_first_child()
	person.select(0)
	await create_timer(0.2).timeout
	assert(world.life.followed >= 0 and not ledger.visible)
	ledger.show_granary()
	await process_frame
	assert(ledger.granary_card.visible and ledger.granary_card.size.x >= 460)
	print("PASS ledger UI: all tabs, drawer sizing, same-key close, person follow, granary card")
	quit()
