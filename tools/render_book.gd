extends SceneTree
## Offscreen book captures: a private viewport, isolated from the running player's world.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Pixel capture requires a rendering display driver; use a private virtual X display with --windowed --no-save.")
		quit(1)
		return
	root.hide()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world: Node2D = load("res://world_map.tscn").instantiate()
	viewport.add_child(world)
	await process_frame
	world.life.set_process(false)
	world.life.paused = true
	world._go_to("Servants' Village", false)
	var ledger: PanelContainer = world.ground_view.ledger
	ledger.set_process(false)
	var store: RefCounted = world.life.population
	var temper: RefCounted = store.society.temper
	temper.body_layer[0] = 4
	temper.method[0] = 2
	store.spirit_root[0] = 1
	store.root_purity[0] = 100
	store.society.revealed[0] = 1
	temper.start_regimen(0, 2, store.day)
	store.touch(0, "grain_farming.farming", 20, 800)
	DirAccess.make_dir_recursive_absolute("res://out/ui")
	for section: String in ledger.TABS:
		ledger.open_tab(section)
		await capture(viewport, ledger, section)
	for tab: String in preload("res://src/person_book.gd").TABS:
		ledger.open_person(0, tab)
		await capture(viewport, ledger, "person_" + tab.to_lower().replace(" & ", "_").replace(" ", "_"))
		if tab == "Cultivation":
			ledger.drawer_scroll.scroll_vertical = 650
			await capture(viewport, ledger, "person_attributes")
			ledger.drawer_scroll.scroll_vertical = 1100
			await capture(viewport, ledger, "person_skills")
	world.free()
	quit()

func capture(viewport: SubViewport, ledger: PanelContainer, file: String) -> void:
	await create_timer(.3).timeout
	if ledger.slide != null and ledger.slide.is_running(): await ledger.slide.finished
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	assert(picture != null and not picture.is_empty())
	picture.save_png("res://out/ui/book_" + file + ".png")
	print("RENDER book_", file)
