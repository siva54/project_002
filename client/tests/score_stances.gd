extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var take: String = OS.get_cmdline_user_args()[0]
	var bank: AnimationLibrary = load("res://../artifacts/qa/" + take + "-study.res")
	var source: Animation = bank.get_animation(bank.get_animation_list()[0])
	var visual_class := preload("res://scripts/kung_fu_visual.gd")
	visual_class.COMBAT_LIBRARY.add_animation("Study", source)
	var visual := visual_class.new()
	root.add_child(visual)
	var scores := []
	for sample in range(0, floori(source.length * 10)):
		var at := sample / 10.0
		visual._sample_pose("Study", at)
		var head: Vector3 = visual.to_local(visual.bone_world("Head"))
		var left_hand: Vector3 = visual.to_local(visual.bone_world("LeftHand"))
		var right_hand: Vector3 = visual.to_local(visual.bone_world("RightHand"))
		var left_foot: Vector3 = visual.to_local(visual.bone_world("LeftFoot"))
		var right_foot: Vector3 = visual.to_local(visual.bone_world("RightFoot"))
		var feet_gap := absf(left_foot.z - right_foot.z)
		var sideways := absf(left_foot.x - right_foot.x)
		var hand_height := minf(left_hand.y, right_hand.y)
		var score := hand_height * 2.0 + minf(feet_gap, 0.6) - maxf(0, sideways - 0.45) * 2.0 - absf(head.y - 1.45)
		scores.append({"at": at, "score": score, "hands": Vector2(left_hand.y, right_hand.y), "feet": Vector2(feet_gap, sideways)})
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	for i in mini(25, scores.size()):
		print(scores[i])
	quit()
