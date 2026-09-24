extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var visual := preload("res://scripts/kung_fu_visual.gd").new()
	root.add_child(visual)
	for clip in {"MocapJab": "LeftHand", "MocapCross": "RightHand", "MocapLeadHook": "LeftHand", "MocapRearHook": "RightHand", "MocapUppercut": "RightHand", "MocapBodyCross": "RightHand", "FrontKick": "LeftFoot", "Roundhouse": "RightFoot", "SideKick": "RightFoot", "Lunge": "RightHand"}:
		var bone: String = {"MocapJab": "LeftHand", "MocapCross": "RightHand", "MocapLeadHook": "LeftHand", "MocapRearHook": "RightHand", "MocapUppercut": "RightHand", "MocapBodyCross": "RightHand", "FrontKick": "LeftFoot", "Roundhouse": "RightFoot", "SideKick": "RightFoot", "Lunge": "RightHand"}[clip]
		var animation: Animation = visual.COMBAT_LIBRARY.get_animation(clip)
		var reach := -100.0
		var peak := 0.0
		var point := Vector3.ZERO
		for index in ceili(animation.length * 120):
			visual._sample_pose(clip, index / 120.0)
			var at: Vector3 = visual.to_local(visual.bone_world(bone))
			if at.z > reach:
				reach = at.z
				peak = index / 120.0
				point = at
		print(clip, " peak=", peak, " duration=", animation.length, " reach=", point, " root_end=", animation.get_meta("root_offsets", PackedVector3Array([Vector3.ZERO]))[-1])
	quit()
