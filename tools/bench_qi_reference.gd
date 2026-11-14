extends SceneTree
## Cost of the current exact reference, before any production session compiler.
## Run only when the serial check runner has finished.
const Anatomy = preload("res://src/meridians.gd")
const Circulation = preload("res://src/circulation.gd")
const Field = preload("res://src/qi_field.gd")

func _initialize() -> void:
	var field := Field.new()
	field.seed(0,"production-budget-probe")
	var sample: Dictionary = field.sample(field.landmarks.Palace)
	var solver := Circulation.new()
	for route: String in ["A","B"]:
		var bodies: Array = []
		for person in 50: bodies.append(Anatomy.Cultivator.from_dictionary(Anatomy.create()))
		var program := solver.manual(route)
		var started := Time.get_ticks_usec()
		for body: Anatomy.Cultivator in bodies:
			solver.simulate_day_model(body,program,sample,int(sample.quantity))
			assert(solver.residual_model(body) == 0)
		var elapsed := (Time.get_ticks_usec() - started) / 1000.0
		print("Exact eight-node reference route=%s 50_sessions_ms=%.3f budget_ms=2.000 conserved=true quiescent_cycles=%d" % [route,elapsed,solver.quiescent_cycles])
	quit()
