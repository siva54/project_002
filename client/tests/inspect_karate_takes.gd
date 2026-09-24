extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var take := OS.get_cmdline_user_args()[0]
	var source: AnimationLibrary = load("res://../artifacts/qa/" + take + "-study.res")
	var visual := preload("res://scripts/kung_fu_visual.gd").new()
	root.add_child(visual)
	visual.COMBAT_LIBRARY.add_animation("Study", source.get_animation("Study"))
	if take == "135_02":
		for at in [4.3, 8.15, 9.0, 18.0, 19.0, 20.0, 27.0, 36.0]:
			print("Root movement ", at, ": ", visual.root_offset("Study", at + 1.1) - visual.root_offset("Study", at))
	var samples := []
	var animation: Animation = source.get_animation("Study")
	for frame in ceili(animation.length * 120):
		visual._sample_pose("Study", frame / 120.0)
		var sample := {}
		for joint in ["LeftHand", "RightHand", "LeftForeArm", "RightForeArm", "LeftFoot", "RightFoot", "Head", "Hips"]:
			var point: Vector3 = visual.to_local(visual.bone_world(joint))
			sample[joint] = [snappedf(point.x, 0.001), snappedf(point.y, 0.001), snappedf(point.z, 0.001)]
		samples.append(sample)
	FileAccess.open("res://../artifacts/qa/" + take + "-points.json", FileAccess.WRITE).store_string(JSON.stringify(samples))
	quit()
