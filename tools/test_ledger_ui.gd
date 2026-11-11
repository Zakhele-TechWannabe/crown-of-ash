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
		assert(ledger.size.x > 1000 and ledger.size.x < 1500)
		assert(ledger.content.size.x > 500)
		ledger.toggle_tab(key)
		assert(not ledger.visible)
	assert(ledger.rice_chip.get_parent().get_parent().get_combined_minimum_size().x <= 1920, "HUD must fit viewport")
	ledger.open_tab("people")
	var person: TreeItem = ledger.tree.get_root().get_first_child()
	person.select(0)
	assert(world.life.followed >= 0 and not ledger.visible)
	ledger.show_granary()
	await process_frame
	assert(ledger.granary_card.visible and ledger.granary_card.size.x >= 460)
	print("PASS ledger UI: all tabs, centered sizing, same-key close, person follow, granary card")
	quit()
