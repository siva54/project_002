extends SceneTree

const BODY := preload("res://assets/characters/vitruvian/vitruvian_body.glb")
const SOURCE := "res://assets/animations/source/"
const FINGERS := {"Index": "f_index", "Middle": "f_middle", "Ring": "f_ring", "Pinky": "f_pinky", "Thumb": "thumb"}
const UE_NAMES := {"hips": "pelvis", "spine.001": "spine_01", "spine.002": "spine_02", "spine.003": "spine_03", "neck": "neck_01", "head": "Head", "shoulder": "clavicle", "upper_arm": "upperarm", "forearm": "lowerarm", "shin": "calf", "toe": "ball"}
const MAP := {
	"Hips": "hips", "Spine": "spine.001", "Spine1": "spine.002", "Spine2": "spine.003", "Neck": "neck", "Head": "head",
	"LeftShoulder": "shoulder.L", "LeftArm": "upper_arm.L", "LeftForeArm": "forearm.L", "LeftHand": "hand.L",
	"RightShoulder": "shoulder.R", "RightArm": "upper_arm.R", "RightForeArm": "forearm.R", "RightHand": "hand.R",
	"LeftUpLeg": "thigh.L", "LeftLeg": "shin.L", "LeftFoot": "foot.L", "LeftToeBase": "toe.L",
	"RightUpLeg": "thigh.R", "RightLeg": "shin.R", "RightFoot": "foot.R", "RightToeBase": "toe.R",
}
const CMU_MAP := {
	"Hips": "root", "Spine": "lowerback", "Spine1": "upperback", "Spine2": "thorax", "Neck": "lowerneck", "Head": "head",
	"LeftShoulder": "lclavicle", "LeftArm": "lhumerus", "LeftForeArm": "lradius", "LeftHand": "lhand",
	"RightShoulder": "rclavicle", "RightArm": "rhumerus", "RightForeArm": "rradius", "RightHand": "rhand",
	"LeftUpLeg": "lfemur", "LeftLeg": "ltibia", "LeftFoot": "lfoot", "LeftToeBase": "ltoes",
	"RightUpLeg": "rfemur", "RightLeg": "rtibia", "RightFoot": "rfoot", "RightToeBase": "rtoes",
}
var target: Skeleton3D
var target_player: AnimationPlayer
var library := AnimationLibrary.new()
var bone_path: NodePath

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var body := BODY.instantiate()
	root.add_child(body)
	target = body.find_children("*", "Skeleton3D", true, false)[0]
	target_player = body.find_children("*", "AnimationPlayer", true, false)[0]
	target_player.stop()
	bone_path = target_player.get_node(target_player.root_node).get_path_to(target)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] == "study_cmu":
		_bake_cmu("135", args[1], "Study", 0, int(args[2]), 120.0)
		ResourceSaver.save(library, "res://../artifacts/qa/" + args[1] + "-study.res")
		quit()
		return
	if "study" in OS.get_cmdline_user_args():
		_bake_cmu("14", "14_01", "BoxingStudy", 0, 2400, 120.0)
		ResourceSaver.save(library, "res://../artifacts/qa/boxing-study.res")
		quit()
		return
	var mapping := MAP.duplicate()
	for side in ["Left", "Right"]:
		for finger in FINGERS:
			for joint in range(1, 4):
				mapping[side + "Hand" + finger + str(joint)] = "%s.%02d.%s" % [FINGERS[finger], joint, "L" if side == "Left" else "R"]
	_bake_quaternius("quaternius_standard.glb", mapping, {
		"Jab": ["Punch_Jab", false], "Cross": ["Punch_Cross", false],
		"GuardEnter": ["Punch_Enter", false], "Walk": ["Walk_Loop", true],
		"Run": ["Jog_Fwd_Loop", true], "Roll": ["Roll", false],
		"Hit": ["Hit_Chest", false], "HitHead": ["Hit_Head", false], "Down": ["Death01", false],
	})
	_bake_quaternius("quaternius_standard_2.glb", mapping, {
		"Hook": ["Melee_Hook", false], "HookRecover": ["Melee_Hook_Rec", false],
		"Knockback": ["Hit_Knockback", false], "GetUp": ["LayToIdle", false],
	})
	# Actual CMU takes; trim around one action, then play at the authored rate.
	_bake_cmu("135", "135_07", "Roundhouse", 65, 235, 120.0)
	_bake_cmu("87", "87_01", "SpinKick", 194, 338, 60.0)
	_bake_cmu("87", "87_03", "Backflip", 125, 224, 60.0)
	_bake_cmu("135", "135_04", "FrontKick", 515, 685, 120.0)
	_bake_cmu("135", "135_11", "SideKick", 300, 440, 120.0)
	_bake_cmu("135", "135_09", "Lunge", 310, 385, 120.0)
	_bake_cmu("135", "135_02", "KarateSlipRight", 516, 650, 120.0)
	_bake_cmu("135", "135_02", "KarateSlipLeft", 2160, 2280, 120.0)
	_bake_cmu("135", "135_02", "KarateStraight", 1055, 1176, 120.0)
	_bake_cmu("14", "14_01", "BoxHook", 290, 410, 120.0)
	# Frames 0-100 are the relaxed pre-performance pose, not a fighting guard.
	_bake_cmu("14", "14_01", "FightIdle", 480, 520, 120.0)
	_bake_cmu("14", "14_01", "MocapJab", 584, 640, 120.0)
	# The one-two is one performance, with the same heading and a contiguous cut.
	_bake_cmu("14", "14_01", "MocapCross", 623, 688, 120.0)
	_bake_cmu("14", "14_01", "MocapLeadHook", 2355, 2420, 120.0)
	_bake_cmu("14", "14_01", "MocapRearHook", 1388, 1444, 120.0)
	_bake_cmu("14", "14_01", "MocapUppercut", 1588, 1650, 120.0)
	_bake_cmu("14", "14_01", "MocapBodyCross", 1328, 1388, 120.0)
	_redirect_clip("SideKick", "RightFoot", 0.383333)
	_redirect_clip("FrontKick", "LeftFoot", 0.533333)
	_redirect_clip("Roundhouse", "RightFoot", 0.40)
	_redirect_clip("MocapRearHook", "RightHand", 0.20)
	_redirect_clip("KarateStraight", "RightHand", 86.0 / 120.0)
	_redirect_clip("Lunge", "RightHand", 36.0 / 120.0)
	if library.get_animation_list().size() != 30:
		push_error("Incomplete source mapping; refusing to overwrite the combat library.")
		quit(1)
		return
	var guard: Animation = library.get_animation("GuardEnter").duplicate()
	for track in guard.get_track_count():
		var value: Variant
		if guard.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			value = guard.rotation_track_interpolate(track, guard.length - 0.01)
		else:
			value = guard.position_track_interpolate(track, guard.length - 0.01)
		while guard.track_get_key_count(track) > 0:
			guard.track_remove_key(track, 0)
		guard.track_insert_key(track, 0, value)
	guard.length = 1.0
	guard.loop_mode = Animation.LOOP_LINEAR
	# Preserve a real boxing stance, retaining the source fist/finger rotations.
	var stance: Animation = library.get_animation("FightIdle")
	for bone in target.get_bone_count():
		var bone_name := target.get_bone_name(bone)
		if not ("Hand" in bone_name and not bone_name.ends_with("Hand")):
			guard.track_set_key_value(bone, 0, stance.rotation_track_interpolate(bone, 0.30))
	library.add_animation("Guard", guard)
	# The attack controller needs the actual retargeted limb position at impact.
	# A generic center-to-center spacing misses hooks and diagonal kicks.
	var catalog := preload("res://scripts/combat_moves.gd")
	for move_name in catalog.MOVES:
		var move: Dictionary = catalog.MOVES[move_name]
		if not move.get("captured", false):
			continue
		var animation: Animation = library.get_animation(move.clip)
		var at: float = move.contact * move.rate
		target.reset_bone_poses()
		for bone in target.get_bone_count():
			target.set_bone_pose_rotation(bone, animation.rotation_track_interpolate(bone, at))
		var hips := target.find_bone("mixamorig_Hips")
		target.set_bone_pose_position(hips, animation.position_track_interpolate(target.get_bone_count(), at))
		var strike_bone := target.find_bone("mixamorig_" + move.bone)
		animation.set_meta("contact_" + move_name, target.get_bone_global_pose(strike_bone).origin)
	var result := ResourceSaver.save(library, "res://assets/animations/kung_fu_library.res")
	print("Combat library: ", result, " / ", library.get_animation_list())
	quit(0 if result == OK else 1)

func _new_clip(length: float, loop: bool) -> Animation:
	var clip := Animation.new()
	clip.length = length
	clip.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for bone in target.get_bone_count():
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath("%s:%s" % [bone_path, target.get_bone_name(bone)]))
	var track := clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(track, NodePath("%s:mixamorig_Hips" % bone_path))
	return clip

func _record(clip: Animation, time: float) -> void:
	for bone in target.get_bone_count():
		clip.rotation_track_insert_key(bone, time, target.get_bone_pose_rotation(bone))
	clip.position_track_insert_key(target.get_bone_count(), time, target.get_bone_pose_position(target.find_bone("mixamorig_Hips")))

func _set_global(bone: int, basis: Basis) -> void:
	var parent := target.get_bone_parent(bone)
	if parent >= 0:
		basis = target.get_bone_global_pose(parent).basis.inverse() * basis
	target.set_bone_pose_rotation(bone, basis.orthonormalized().get_rotation_quaternion())

func _target_direction(bone: int) -> Vector3:
	var children := target.get_bone_children(bone)
	if children.is_empty():
		return target.get_bone_global_rest(bone).basis.y.normalized()
	return (target.get_bone_global_rest(children[0]).origin - target.get_bone_global_rest(bone).origin).normalized()

func _bake_quaternius(file: String, mapping: Dictionary, clips: Dictionary) -> void:
	var source: Node = load(SOURCE + file).instantiate()
	root.add_child(source)
	var rig: Skeleton3D = source.find_children("*", "Skeleton3D", true, false)[0]
	var player: AnimationPlayer = source.find_children("*", "AnimationPlayer", true, false)[0]
	var pairs := {}
	for bone in target.get_bone_count():
		var suffix := target.get_bone_name(bone).trim_prefix("mixamorig_")
		if mapping.has(suffix):
			var found := rig.find_bone("DEF-" + mapping[suffix])
			if found < 0:
				var converted: String = mapping[suffix]
				for before in UE_NAMES:
					converted = converted.replace(before, UE_NAMES[before])
				converted = converted.replace("f_", "").replace(".L", "_l").replace(".R", "_r").replace(".", "_")
				found = rig.find_bone(converted)
			if found >= 0:
				pairs[bone] = found
	print(file, " mapped ", pairs.size(), " bones")
	for name in clips:
		var info: Array = clips[name]
		var source_name: String = info[0]
		if not player.has_animation(source_name):
			source_name = source_name.trim_suffix("_Loop")
		var original := player.get_animation(source_name)
		var clip := _new_clip(original.length, info[1])
		player.play(source_name)
		var steps := ceili(original.length * 60)
		for frame in range(steps + 1):
			var time := minf(frame / 60.0, original.length)
			player.seek(time, true)
			target.reset_bone_poses()
			for bone in target.get_bone_count():
				if not pairs.has(bone):
					continue
				var sb: int = pairs[bone]
				var rest := rig.get_bone_global_rest(sb)
				var pose := rig.get_bone_global_pose(sb)
				var children := rig.get_bone_children(sb)
				var source_dir := rest.basis.y.normalized()
				if not children.is_empty():
					source_dir = (rig.get_bone_global_rest(children[0]).origin - rest.origin).normalized()
				var align := Basis(Quaternion(_target_direction(bone), source_dir))
				if target.get_bone_name(bone) in ["mixamorig_Hips", "mixamorig_Head"]:
					align = Basis.IDENTITY
				_set_global(bone, pose.basis * rest.basis.inverse() * align * target.get_bone_global_rest(bone).basis)
			var hips := target.find_bone("mixamorig_Hips")
			var source_hips: int = pairs[hips]
			var height := rig.get_bone_global_rest(source_hips).origin.y
			var pos := target.get_bone_rest(hips).origin
			pos.y *= rig.get_bone_global_pose(source_hips).origin.y / height
			target.set_bone_pose_position(hips, pos)
			_record(clip, time)
		library.add_animation(name, clip)
		print(name, " ", clip.length)
	source.free()

func _rotation(values: Vector3) -> Basis:
	# ASF/AMC uses XYZ channel order: column vectors are Rz * Ry * Rx.
	return Basis(Vector3.BACK, deg_to_rad(values.z)) * Basis(Vector3.UP, deg_to_rad(values.y)) * Basis(Vector3.RIGHT, deg_to_rad(values.x))

func _redirect_clip(name: String, limb: String, contact: float) -> void:
	var clip: Animation = library.get_animation(name)
	for bone in target.get_bone_count():
		target.set_bone_pose_rotation(bone, clip.rotation_track_interpolate(bone, contact))
	var hips := target.find_bone("mixamorig_Hips")
	var end := target.find_bone("mixamorig_" + limb)
	var direction := target.get_bone_global_pose(end).origin - target.get_bone_global_pose(hips).origin
	var turn := Basis(Vector3.UP, -atan2(direction.x, direction.z))
	for key in clip.track_get_key_count(hips):
		var rotation: Quaternion = clip.track_get_key_value(hips, key)
		clip.track_set_key_value(hips, key, (turn * Basis(rotation)).get_rotation_quaternion())
	var offsets: PackedVector3Array = clip.get_meta("root_offsets")
	for i in offsets.size():
		offsets[i] = turn * offsets[i]
	clip.set_meta("root_offsets", offsets)
	var original: PackedVector3Array = clip.get_meta("original_root_offsets")
	for i in original.size():
		original[i] = turn * original[i]
	clip.set_meta("original_root_offsets", original)

func _bake_cmu(subject: String, file: String, name: String, start: int, end: int, fps: float) -> void:
	var bones := {"root": {"axis": Basis.IDENTITY, "direction": Vector3.UP, "length": 0.0, "parent": "", "dof": []}}
	var section := ""
	var current := {}
	for raw in FileAccess.get_file_as_string(SOURCE + subject + ".asf").split("\n"):
		var line := raw.strip_edges()
		if line.begins_with(":"):
			section = line
		var fields := line.split(" ", false)
		if fields.is_empty():
			continue
		if section == ":bonedata":
			match fields[0]:
				"begin": current = {"dof": []}
				"name": current.name = fields[1]
				"direction": current.direction = Vector3(float(fields[1]), float(fields[2]), float(fields[3]))
				"length": current.length = float(fields[1])
				"axis": current.axis = _rotation(Vector3(float(fields[1]), float(fields[2]), float(fields[3])))
				"dof": current.dof = Array(fields.slice(1))
				"end": bones[current.name] = current
		elif section == ":hierarchy" and fields.size() > 1:
			for child in fields.slice(1):
				bones[child].parent = fields[0]
	var frames: Array[Dictionary] = []
	for raw in FileAccess.get_file_as_string(SOURCE + file + ".amc").split("\n"):
		var line := raw.strip_edges()
		if line.is_valid_int():
			frames.append({})
		elif not frames.is_empty() and not line.is_empty() and not line.begins_with("#") and not line.begins_with(":"):
			var fields := line.split(" ", false)
			frames[-1][fields[0]] = Array(fields.slice(1)).map(func(v): return float(v))
	var clip := _new_clip((end - start) / fps, false)
	var first_root: Array = frames[start].root
	var heading_root: Array = frames[584].root if name in ["MocapJab", "MocapCross"] else first_root
	var facing := Basis(Vector3.UP, -deg_to_rad(heading_root[4]))
	var left_foot := target.find_bone("mixamorig_LeftFoot")
	var right_foot := target.find_bone("mixamorig_RightFoot")
	var floor_height := minf(target.get_bone_global_rest(left_foot).origin.y, target.get_bone_global_rest(right_foot).origin.y)
	var floor_offset := 0.0
	var root_offsets := PackedVector3Array()
	var foot_samples: Array[PackedVector3Array] = []
	for index in range(start, end + 1):
		var sample: Dictionary = frames[index]
		var rotations := {}
		for source_bone in bones:
			_cmu_global(source_bone, bones, sample, rotations)
		target.reset_bone_poses()
		for bone in target.get_bone_count():
			var suffix := target.get_bone_name(bone).trim_prefix("mixamorig_")
			if not CMU_MAP.has(suffix):
				continue
			var sb: String = CMU_MAP[suffix]
			var rest := target.get_bone_global_rest(bone).basis
			var align := Basis(Quaternion(_target_direction(bone), Vector3(bones[sb].direction).normalized()))
			if sb == "root" or sb == "head":
				align = Basis.IDENTITY
			_set_global(bone, facing * rotations[sb] * align * rest)
		var hips := target.find_bone("mixamorig_Hips")
		var position := target.get_bone_rest(hips).origin
		# Preserve captured elevation; planar displacement is owned by collision movement.
		position.y += (sample.root[1] - first_root[1]) * 0.056444
		target.set_bone_pose_position(hips, position)
		var foot_height := minf(target.get_bone_global_pose(left_foot).origin.y, target.get_bone_global_pose(right_foot).origin.y)
		if index == start or name not in ["SpinKick", "Backflip"]:
			floor_offset = floor_height - foot_height
		# Grounded kicks keep the support foot planted; aerial clips retain elevation.
		position.y += maxf(floor_offset, floor_height - foot_height)
		target.set_bone_pose_position(hips, position)
		_record(clip, (index - start) / fps)
		foot_samples.append(PackedVector3Array([target.get_bone_global_pose(left_foot).origin, target.get_bone_global_pose(right_foot).origin]))
		root_offsets.append(facing * Vector3(sample.root[0] - first_root[0], 0, sample.root[2] - first_root[2]) * 0.056444)
	clip.set_meta("original_root_offsets", root_offsets.duplicate())
	if name not in ["SpinKick", "Backflip", "BoxingStudy"]:
		# Actor proportions differ from the performer. Reconstruct translation from
		# the retargeted supporting foot, not the original actor's stride length.
		var support := 0 if foot_samples[0][0].y < foot_samples[0][1].y else 1
		var supports := PackedInt32Array([support])
		for frame in range(1, foot_samples.size()):
			var other := 1 - support
			if foot_samples[frame][other].y + 0.025 < foot_samples[frame][support].y:
				support = other
			var delta: Vector3 = foot_samples[frame - 1][support] - foot_samples[frame][support]
			delta.y = 0
			root_offsets[frame] = root_offsets[frame - 1] + delta
			supports.append(support)
		clip.set_meta("support_feet", supports)
	clip.set_meta("root_offsets", root_offsets)
	clip.set_meta("source_fps", fps)
	clip.set_meta("source_take", file)
	clip.set_meta("source_start", start)
	library.add_animation(name, clip)
	print(name, " ", clip.length)

func _cmu_global(name: String, bones: Dictionary, sample: Dictionary, result: Dictionary) -> Basis:
	if result.has(name):
		return result[name]
	if name == "root":
		result[name] = _rotation(Vector3(sample.root[3], sample.root[4], sample.root[5]))
	else:
		var data: Dictionary = bones[name]
		var rotation := Vector3.ZERO
		var values: Array = sample.get(name, [])
		for i in values.size():
			rotation[{"rx": 0, "ry": 1, "rz": 2}[data.dof[i]]] = values[i]
		result[name] = _cmu_global(data.parent, bones, sample, result) * data.axis * _rotation(rotation) * data.axis.inverse()
	return result[name]
