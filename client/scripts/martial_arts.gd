extends RefCounted

## Authored in-place poses for the bundled Vitruvian rig. All timings are shared
## by presentation and hit resolution; no animation track applies game damage.
const STRIKES := [
	{"clip": "Jab", "label": "Lead jab", "contact": 0.16, "duration": 0.48},
	{"clip": "Cross", "label": "Rear cross", "contact": 0.20, "duration": 0.56},
	{"clip": "FrontKick", "label": "Front kick", "contact": 0.30, "duration": 0.76},
]
const BUFFER_SECONDS := 0.22
const COMBO_GRACE := 0.65
const GRAPPLES := [
	{"clip": "ForwardThrow", "label": "Forward throw", "contact": 0.34, "duration": 0.82},
	{"clip": "LegSweep", "label": "Leg sweep", "contact": 0.34, "duration": 0.82},
]

static func install(player: AnimationPlayer, skeleton: Skeleton3D) -> void:
	var library := AnimationLibrary.new()
	var path := player.get_node(player.root_node).get_path_to(skeleton)
	var actions := STRIKES + GRAPPLES
	for index in actions.size():
		var strike: Dictionary = actions[index]
		var animation := Animation.new()
		animation.length = strike.duration
		var times := [0.0, strike.contact * 0.55, strike.contact, strike.contact + 0.045, strike.duration * 0.78, strike.duration]
		var poses := [0, 1, 2, 2, 3, 0]
		for bone in skeleton.get_bone_count():
			var bone_path := NodePath("%s:%s" % [path, skeleton.get_bone_name(bone)])
			for type in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
				var track := animation.add_track(type)
				animation.track_set_path(track, bone_path)
		for frame in times.size():
			_pose(skeleton, index, poses[frame])
			for bone in skeleton.get_bone_count():
				animation.position_track_insert_key(bone * 3, times[frame], skeleton.get_bone_pose_position(bone))
				animation.rotation_track_insert_key(bone * 3 + 1, times[frame], skeleton.get_bone_pose_rotation(bone))
				animation.scale_track_insert_key(bone * 3 + 2, times[frame], skeleton.get_bone_pose_scale(bone))
		library.add_animation(strike.clip, animation)
	# A held guard bridges successive strikes without returning to relaxed idle.
	var guard := Animation.new()
	guard.length = 1.0
	guard.loop_mode = Animation.LOOP_LINEAR
	_pose(skeleton, 0, 0)
	for bone in skeleton.get_bone_count():
		var bone_path := NodePath("%s:%s" % [path, skeleton.get_bone_name(bone)])
		var rotation_track := guard.add_track(Animation.TYPE_ROTATION_3D)
		guard.track_set_path(rotation_track, bone_path)
		guard.rotation_track_insert_key(rotation_track, 0, skeleton.get_bone_pose_rotation(bone))
		var position_track := guard.add_track(Animation.TYPE_POSITION_3D)
		guard.track_set_path(position_track, bone_path)
		guard.position_track_insert_key(position_track, 0, skeleton.get_bone_pose_position(bone))
	library.add_animation("Guard", guard)
	player.add_animation_library("martial", library)
	skeleton.reset_bone_poses()

static func _bone(skeleton: Skeleton3D, suffix: String) -> int:
	return skeleton.find_bone("mixamorig_" + suffix)

static func _rotate(skeleton: Skeleton3D, suffix: String, degrees: Vector3) -> void:
	var bone := _bone(skeleton, suffix)
	var rest := skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(bone, rest * Quaternion.from_euler(degrees * PI / 180.0))

## Aim a limb in skeleton space, then convert back through its posed parent.
static func _aim(skeleton: Skeleton3D, suffix: String, child: String, direction: Vector3) -> void:
	var bone := _bone(skeleton, suffix)
	var child_bone := _bone(skeleton, child)
	var rest := skeleton.get_bone_global_rest(bone)
	var rest_direction := (skeleton.get_bone_global_rest(child_bone).origin - rest.origin).normalized()
	var desired := Basis(Quaternion(rest_direction, direction.normalized())) * rest.basis.orthonormalized()
	var parent := skeleton.get_bone_parent(bone)
	var parent_basis := skeleton.get_bone_global_pose(parent).basis.orthonormalized()
	skeleton.set_bone_pose_rotation(bone, (parent_basis.inverse() * desired).get_rotation_quaternion())

static func _pose(skeleton: Skeleton3D, strike: int, phase: int) -> void:
	skeleton.reset_bone_poses()
	var contact := phase == 2
	var chamber := phase == 1 or phase == 3
	var twist := -8.0
	if strike == 0:
		twist = 12.0 if contact else (-16.0 if chamber else -8.0)
	elif strike == 1:
		twist = -25.0 if contact else (14.0 if chamber else -8.0)
	else:
		twist = -5.0
	_rotate(skeleton, "Hips", Vector3(0, twist * 0.35, 0))
	_rotate(skeleton, "Spine", Vector3(-8 if strike == 2 and contact else 3, twist * 0.35, 0))
	_rotate(skeleton, "Spine1", Vector3(0, twist * 0.3, 0))
	_rotate(skeleton, "Head", Vector3(0, -twist * 0.55, 0))
	# Elbows tucked, fists at cheek height, one hand always protecting the head.
	_aim(skeleton, "LeftArm", "LeftForeArm", Vector3(0.12, -0.78, 0.42))
	_aim(skeleton, "LeftForeArm", "LeftHand", Vector3(-0.1, 0.8, 0.38))
	_aim(skeleton, "RightArm", "RightForeArm", Vector3(-0.15, -0.85, 0.3))
	_aim(skeleton, "RightForeArm", "RightHand", Vector3(0.12, 0.9, 0.25))
	# Slight split stance and knee flexion, with no root-motion displacement.
	_aim(skeleton, "LeftUpLeg", "LeftLeg", Vector3(0.07, -1, 0.16))
	_aim(skeleton, "LeftLeg", "LeftFoot", Vector3(0, -1, -0.08))
	_aim(skeleton, "RightUpLeg", "RightLeg", Vector3(-0.08, -1, -0.12))
	_aim(skeleton, "RightLeg", "RightFoot", Vector3(0, -1, -0.05))
	if contact and strike < 2:
		var side := "Left" if strike == 0 else "Right"
		_aim(skeleton, side + "Arm", side + "ForeArm", Vector3(-0.15 if strike == 0 else 0.28, -0.04, 1))
		_aim(skeleton, side + "ForeArm", side + "Hand", Vector3(0, 0.02, 1))
	elif strike == 2 and (chamber or contact):
		_aim(skeleton, "RightUpLeg", "RightLeg", Vector3(-0.12, 0.18 if contact else 0.3, 1))
		_aim(skeleton, "RightLeg", "RightFoot", Vector3(0, 0.08, 1) if contact else Vector3(0, -1, -0.3))
		_aim(skeleton, "RightFoot", "RightToeBase", Vector3(0, 1, 0.1))
	elif strike >= 3:
		# Two-handed clinch, then a turning release or a low reaping leg.
		for side in ["Left", "Right"]:
			_aim(skeleton, side + "Arm", side + "ForeArm", Vector3(0, -0.2, 1))
			_aim(skeleton, side + "ForeArm", side + "Hand", Vector3(0, 0.5 if not contact else -0.3, 1))
		if contact:
			_rotate(skeleton, "Spine", Vector3(18, -30, 0))
			if strike == 4:
				_aim(skeleton, "RightUpLeg", "RightLeg", Vector3(-0.6, -0.6, 0.6))
				_aim(skeleton, "RightLeg", "RightFoot", Vector3(-0.4, -0.3, 1))
	# Keep the wrists aligned with forearms and curl fingers into actual fists.
	for side in ["Left", "Right"]:
		_rotate(skeleton, side + "Hand", Vector3.ZERO)
		for finger in ["Index", "Middle", "Ring", "Pinky"]:
			for joint in range(1, 4):
				_rotate(skeleton, side + "Hand" + finger + str(joint), Vector3(72 if joint == 1 else 85, 0, 0))
		_rotate(skeleton, side + "HandThumb2", Vector3(35, 0, 0))
