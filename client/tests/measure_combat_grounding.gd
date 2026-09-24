extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var visual := preload("res://scripts/kung_fu_visual.gd").new()
	root.add_child(visual)
	for name in ["MocapJab", "MocapCross", "MocapLeadHook", "FrontKick", "Roundhouse", "SideKick"]:
		var clip: Animation = visual.COMBAT_LIBRARY.get_animation(name)
		var previous := [Vector3.ZERO, Vector3.ZERO]
		var slide := [0.0, 0.0]
		var planted_frames := [0, 0]
		var lowest := [100.0, 100.0]
		for frame in ceili(clip.length * 120):
			visual._sample_pose(name, frame / 120.0)
			for side in 2:
				var foot: Vector3 = visual.to_local(visual.bone_world("LeftFoot" if side == 0 else "RightFoot"))
				lowest[side] = minf(lowest[side], foot.y)
		for frame in ceili(clip.length * 120):
			visual._sample_pose(name, frame / 120.0)
			for side in 2:
				var foot: Vector3 = visual.to_local(visual.bone_world("LeftFoot" if side == 0 else "RightFoot")) + visual.root_offset(name, frame / 120.0)
				if frame > 0 and foot.y < lowest[side] + 0.025:
					var offset: Vector3 = foot - previous[side]
					offset.y = 0
					slide[side] += offset.length()
					planted_frames[side] += 1
				previous[side] = foot
		print(name, " planted-foot travel=", slide, " frames=", planted_frames)
	var skeleton: Skeleton3D = visual.body_skeleton
	for clip_name in ["Hit", "HitHead"]:
		var clip: Animation = visual.COMBAT_LIBRARY.get_animation(clip_name)
		for step in 6:
			visual._sample_pose(clip_name, clip.length * step / 5.0)
			print(clip_name, " ", step / 5.0, " torso=", visual.bone_world("Neck") - visual.bone_world("Hips"))
	visual._sample_pose("FrontKick", 0.5333)
	print("Front kick contact root=", visual.root_offset("FrontKick", 0.5333), " foot=", visual.to_local(visual.bone_world("LeftFoot")))
	visual._sample_pose("MocapJab", 0.3 * 1.08)
	var outgoing := []
	for bone in skeleton.get_bone_count():
		outgoing.append(skeleton.get_bone_pose_rotation(bone))
	visual._sample_pose("MocapCross", 0)
	for name in ["Hips", "Spine", "LeftUpLeg", "RightUpLeg", "LeftArm", "RightArm"]:
		var bone := skeleton.find_bone("mixamorig_" + name)
		print("Jab-cross ", name, " jump degrees=", rad_to_deg(outgoing[bone].angle_to(skeleton.get_bone_pose_rotation(bone))))
	quit()
