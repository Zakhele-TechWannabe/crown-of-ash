extends SceneTree
const Save = preload("res://src/world_save.gd")
const PATH := "user://tests/quit-world.save"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var map: Node2D = load("res://world_map.tscn").instantiate()
	root.add_child(map)
	map.life.set_process(false)
	map.quit_save_path = PATH
	map.quit_request_path = "user://tests/quit.request"
	DirAccess.make_dir_recursive_absolute(PATH.get_base_dir())
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(PATH)
	var request := FileAccess.open(map.quit_request_path, FileAccess.WRITE)
	request.close()
	# The same one-second poll as windowed play must save before SceneTree quits.
	root.tree_exiting.connect(func() -> void:
		assert(not Save.read_envelope(PATH).is_empty())
		assert(not FileAccess.file_exists(map.quit_request_path))
		print("PASS graceful quit: request polled, world saved, request removed, tree exited"))
