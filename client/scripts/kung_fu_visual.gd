extends "res://scripts/avatar_visual.gd"

const COMBAT_LIBRARY := preload("res://assets/animations/kung_fu_library.res")
const Pose := preload("res://scripts/combat_pose.gd")
var motion_data: Dictionary = {}
var motion_time := 0.0
var motion_rate := 1.0
var blend_time := 0.10
var blend_age := 0.0
var previous_rotations: Array[Quaternion] = []
var previous_hip := Vector3.ZERO
var leg_bones: Array[int] = []
var finger_bones: Array[int] = []
var locomotion_phase := 0.0
var locomotion_weight := 0.0
var reaction := ""
var pair_controlled := false
var counter_pose_phase := -1
var counter_phase_time := 0.0
var reaction_duration := 0.43
var strike_has_goal := false
var strike_goal := Vector3.ZERO
var observed_rotations: Array[Quaternion] = []
var angular_velocity: Array[Vector3] = []
var blend_velocity: Array[Vector3] = []
var previous_pair_time := 0.0
var support_locked := false
var support_side := "Left"
var support_anchor := Vector3.ZERO

func _ready() -> void:
	super._ready()
	get_node("TeamPatch").queue_free()
	body_animation.stop()
	body_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for bone in body_skeleton.get_bone_count():
		var name: String = body_skeleton.get_bone_name(bone)
		if "Leg" in name or "Foot" in name or "Toe" in name:
			leg_bones.append(bone)
		if "Hand" in name and not name.ends_with("Hand"):
			finger_bones.append(bone)
	play_clip("FightIdle")
	tick(0)

func configure_fighter(player: bool) -> void:
	for material in clothing_materials:
		material.albedo_color = (Color("a9a08c") if player else Color("63332e")) if material.resource_name == "VitShirt" else Color("171f24")

func _body_material(material_name: String) -> StandardMaterial3D:
	var material := super._body_material(material_name)
	material.resource_name = material_name
	return material

func bone_world(suffix: String) -> Vector3:
	var bone := body_skeleton.find_bone("mixamorig_" + suffix)
	return body_skeleton.to_global(body_skeleton.get_bone_global_pose(bone).origin)

func _remember_pose() -> void:
	previous_rotations.clear()
	blend_velocity = angular_velocity.duplicate()
	for bone in body_skeleton.get_bone_count():
		previous_rotations.append(body_skeleton.get_bone_pose_rotation(bone))
	previous_hip = body_skeleton.get_bone_pose_position(body_skeleton.find_bone("mixamorig_Hips"))
	blend_age = 0

func play_clip(clip: String, speed: float = 1.0, blend: float = 0.12) -> void:
	_remember_pose()
	active_clip = clip
	motion_data = {}
	motion_time = 0
	motion_rate = speed
	blend_time = blend
	reaction = ""
	pair_controlled = false
	counter_pose_phase = -1
	strike_has_goal = false
	previous_pair_time = 0
	support_locked = false

func play_move(data: Dictionary, blend: float = 0.09) -> void:
	if active_clip == "MocapJab" and data.clip == "MocapCross" and motion_time < 0.36:
		blend = 0.035
	play_clip(data.clip, data.rate, blend)
	motion_data = data

func _sample_pose(clip: String, time: float, loop: bool = false) -> void:
	var animation: Animation = COMBAT_LIBRARY.get_animation(clip)
	var at := fposmod(time, animation.length) if loop else clampf(time, 0, animation.length)
	if clip == "FightIdle" and loop:
		# Reflect the subtle guarded weight shift without an end-to-start snap.
		at = fposmod(time * 0.65, animation.length * 2)
		if at > animation.length:
			at = animation.length * 2 - at
	for bone in body_skeleton.get_bone_count():
		body_skeleton.set_bone_pose_rotation(bone, animation.rotation_track_interpolate(bone, at))
	body_skeleton.set_bone_pose_position(body_skeleton.find_bone("mixamorig_Hips"), animation.position_track_interpolate(body_skeleton.get_bone_count(), at))

func tick(delta: float, speed: float = 0.0, travel_angle: float = 0.0) -> void:
	if pair_controlled:
		return
	motion_time += delta
	blend_age += delta
	locomotion_phase += delta * maxf(0.6, speed * 0.48)
	locomotion_weight = move_toward(locomotion_weight, clampf(speed / 2.6, 0, 1), delta * 10)
	var loop := active_clip in ["FightIdle", "Run", "Walk", "Guard"]
	var anticipation: float = motion_data.get("windup", 0.0)
	var strike_time := maxf(0, motion_time - anticipation)
	if anticipation > 0 and motion_time >= anticipation and motion_time - delta < anticipation:
		_remember_pose()
		blend_time = 0.08
	if active_clip == "Rise":
		_sample_pose("GetUp", motion_time * 1.1)
	elif active_clip == "Down":
		_fall_pose(motion_time * motion_rate)
	elif active_clip in ["Hit", "HitHead"] and not reaction.is_empty():
		_reaction_pose()
	else:
		_sample_pose(active_clip, strike_time * motion_rate, loop)
	if not motion_data.is_empty():
		var strike_data := motion_data.duplicate()
		for key in ["contact", "link", "duration"]:
			strike_data[key] -= anticipation
		if motion_time < anticipation:
			_sample_pose("Guard", 0)
			Pose.twist(self, "Spine", Vector3.UP, sin(motion_time / anticipation * PI) * 0.14)
		else:
			if strike_data.shape == "knee":
				_sample_knee_base(strike_data, strike_time)
			if motion_data.get("captured", false):
				_captured_contact(strike_data, strike_time)
			else:
				Pose.strike(self, strike_data, strike_time)
	if (motion_data.is_empty() and loop) or (not motion_data.is_empty() and motion_time < anticipation) or (not motion_data.is_empty() and not motion_data.get("captured", false) and not motion_data.get("preserve_body", false) and not motion_data.shape.ends_with("kick") and motion_data.shape != "knee"):
		var walk: Animation = COMBAT_LIBRARY.get_animation("Run")
		for bone in leg_bones:
			var rotation := walk.rotation_track_interpolate(bone, fposmod(locomotion_phase, walk.length))
			body_skeleton.set_bone_pose_rotation(bone, body_skeleton.get_bone_pose_rotation(bone).slerp(rotation, locomotion_weight))
		for side in ["Left", "Right"]:
			Pose.twist(self, side + "UpLeg", Vector3.UP, clampf(travel_angle, -1.0, 1.0) * locomotion_weight)
	if loop and motion_data.is_empty():
		Pose.twist(self, "Spine", Vector3.UP, sin(motion_time * 2.6) * 0.025)
	if active_clip in ["FightIdle", "Guard"] and motion_data.is_empty():
		_fighting_stance(1.0 - locomotion_weight)
	var recoil := Pose.recoil(motion_time, reaction_duration)
	if reaction in ["left", "right", "head", "body", "leg"]:
		# The source reaction supplies the whole-body recoil; this only directs it.
		var turn := 0.20 if reaction == "left" else (-0.20 if reaction == "right" else 0.0)
		Pose.twist(self, "Spine", Vector3.UP, recoil * turn)
		if reaction == "leg":
			Pose.twist(self, "Hips", Vector3.BACK, recoil * 0.14)
	elif reaction == "evade":
		Pose.twist(self, "Spine", Vector3.RIGHT, sin(clampf(motion_time / 0.38, 0, 1) * PI) * 0.17)
	_close_hands()
	_blend_pose()
	if active_clip not in ["Down", "Rise", "GetUp"]:
		_plant_feet()
	if not motion_data.is_empty() and not motion_data.get("captured", false):
		_support_foot()
	_track_motion(delta)

func _reaction_pose() -> void:
	# Add the source recoil to the pose that was actually struck. Switching to
	# Hit_Head's unrelated standing pose dropped both arms and reset the stance.
	var clip: Animation = COMBAT_LIBRARY.get_animation(active_clip)
	var guard: Animation = COMBAT_LIBRARY.get_animation("Guard")
	var age := clampf(motion_time / reaction_duration, 0, 1)
	# These clips START at impact and end neutral, rather than containing a
	# neutral-to-impact windup. Build into their impact pose, then recover.
	var compression := smoothstep(0, 0.07, motion_time) * (1.0 - smoothstep(0.07, reaction_duration * 0.80, motion_time))
	var response_time := clip.length * (1.0 - compression)
	var recover := smoothstep(0.35, 1.0, age)
	for bone in body_skeleton.get_bone_count():
		var name: String = body_skeleton.get_bone_name(bone)
		var base: Quaternion = previous_rotations[bone].slerp(guard.rotation_track_interpolate(bone, 0), recover)
		if "Spine" in name or "Neck" in name or name.ends_with("Head"):
			var start := clip.rotation_track_interpolate(bone, clip.length)
			var offset := start.inverse() * clip.rotation_track_interpolate(bone, response_time)
			var angle := Quaternion.IDENTITY.angle_to(offset)
			var limit := 0.48 if name.ends_with("Head") else 0.32
			base *= Quaternion.IDENTITY.slerp(offset, minf(0.85, limit / maxf(angle, 0.001)))
		body_skeleton.set_bone_pose_rotation(bone, base)
	var hips := body_skeleton.find_bone("mixamorig_Hips")
	body_skeleton.set_bone_pose_position(hips, previous_hip.lerp(guard.position_track_interpolate(body_skeleton.get_bone_count(), 0), recover))

func _captured_contact(data: Dictionary, time: float) -> void:
	if not strike_has_goal or data.shape in ["elbow", "knee"]:
		return
	var at: float = data.contact
	var weight := smoothstep(at - 0.06, at, time) * (1.0 - smoothstep(at + 0.025, at + 0.11, time))
	var current := bone_world(data.bone)
	# Retain the captured pose. Only bridge a small anatomical reach difference.
	var adjustment := (strike_goal - current).limit_length(0.075)
	var hand: bool = data.bone.ends_with("Hand")
	var pole := to_local(bone_world(data.side + ("ForeArm" if hand else "Leg")))
	Pose.limb(self, data.side, hand, to_local(current + adjustment), pole, weight)

func _sample_knee_base(data: Dictionary, time: float) -> void:
	var chamber := smoothstep(0, data.contact, time) * (1.0 - smoothstep(data.contact + 0.04, data.duration, time))
	_sample_pose("FrontKick", chamber * 0.36)

func root_offset(clip: String, time: float) -> Vector3:
	var animation: Animation = COMBAT_LIBRARY.get_animation(clip)
	var offsets: PackedVector3Array = animation.get_meta("root_offsets", PackedVector3Array())
	if offsets.is_empty():
		return Vector3.ZERO
	var frame := clampf(time * float(animation.get_meta("source_fps", 120.0)), 0, offsets.size() - 1)
	var index := floori(frame)
	return offsets[index].lerp(offsets[mini(index + 1, offsets.size() - 1)], frame - index)

func contact_offset(move_name: String, clip: String) -> Vector3:
	return COMBAT_LIBRARY.get_animation(clip).get_meta("contact_" + move_name, Vector3.ZERO)

func _support_foot() -> void:
	var at: float = motion_data.contact
	var start := at - 0.055
	var end := minf(motion_data.duration, at + 0.16)
	if motion_time < start or motion_time > end:
		return
	if not support_locked:
		if motion_data.shape.ends_with("kick") or motion_data.shape == "knee":
			support_side = "Right" if motion_data.side == "Left" else "Left"
		else:
			support_side = "Left" if bone_world("LeftFoot").y < bone_world("RightFoot").y else "Right"
		support_anchor = bone_world(support_side + "Foot")
		support_locked = true
	var foot := bone_world(support_side + "Foot")
	var correction := (support_anchor - foot).limit_length(0.16)
	var weight := smoothstep(start, at, motion_time) * (1.0 - smoothstep(at + 0.04, end, motion_time))
	Pose.limb(self, support_side, false, to_local(foot + correction), Vector3(0.0, 0.6, 1.0), weight * 0.85)

func _track_motion(delta: float) -> void:
	angular_velocity.clear()
	for bone in body_skeleton.get_bone_count():
		var current := body_skeleton.get_bone_pose_rotation(bone)
		var velocity := Vector3.ZERO
		if observed_rotations.size() == body_skeleton.get_bone_count() and delta > 0:
			var change := observed_rotations[bone].inverse() * current
			var angle := change.get_angle()
			if angle > PI:
				angle -= TAU
			if absf(angle) > 0.0001:
				velocity = (change.get_axis() * angle / delta).limit_length(22)
		angular_velocity.append(velocity)
	observed_rotations.clear()
	for bone in body_skeleton.get_bone_count():
		observed_rotations.append(body_skeleton.get_bone_pose_rotation(bone))

func _fighting_stance(weight: float) -> void:
	if weight < 0.01:
		return
	# The captured idle has both feet spread laterally at nearly the same depth.
	# Place the lead foot forward and the rear foot beneath the hip, then keep
	# one hand in range while the other protects the jaw.
	Pose.twist(self, "Spine", Vector3.UP, 0.10 * weight)
	Pose.twist(self, "Spine", Vector3.RIGHT, 0.06 * weight)
	var lead: Vector3 = to_local(bone_world("LeftFoot"))
	var rear: Vector3 = to_local(bone_world("RightFoot"))
	Pose.limb(self, "Left", false, Vector3(0.17, lead.y, 0.16), Vector3(0.26, 0.79, 0.54), weight)
	Pose.limb(self, "Right", false, Vector3(-0.18, rear.y, -0.34), Vector3(-0.27, 0.77, 0.14), weight)
	Pose.limb(self, "Left", true, Vector3(0.14, 1.39, 0.30), Vector3(0.38, 1.10, 0.03), weight)
	Pose.limb(self, "Right", true, Vector3(-0.16, 1.41, 0.12), Vector3(-0.38, 1.12, -0.02), weight)

func _close_hands() -> void:
	var guard: Animation = COMBAT_LIBRARY.get_animation("Guard")
	for bone in finger_bones:
		body_skeleton.set_bone_pose_rotation(bone, guard.rotation_track_interpolate(bone, 0))

func _blend_pose() -> void:
	if blend_time <= 0 or blend_age >= blend_time or previous_rotations.is_empty():
		return
	var weight := smoothstep(0, blend_time, blend_age)
	for bone in body_skeleton.get_bone_count():
		var outgoing := previous_rotations[bone]
		if blend_velocity.size() > bone and blend_velocity[bone].length() > 0.001:
			var momentum := blend_age * exp(-3.0 * blend_age / blend_time)
			outgoing *= Quaternion(blend_velocity[bone].normalized(), blend_velocity[bone].length() * momentum)
		body_skeleton.set_bone_pose_rotation(bone, outgoing.slerp(body_skeleton.get_bone_pose_rotation(bone), weight))
	var hips := body_skeleton.find_bone("mixamorig_Hips")
	body_skeleton.set_bone_pose_position(hips, previous_hip.lerp(body_skeleton.get_bone_pose_position(hips), weight))

func _plant_feet() -> void:
	var left := body_skeleton.find_bone("mixamorig_LeftFoot")
	var right := body_skeleton.find_bone("mixamorig_RightFoot")
	var base := minf(body_skeleton.get_bone_global_rest(left).origin.y, body_skeleton.get_bone_global_rest(right).origin.y)
	var floor_y := minf(body_skeleton.get_bone_global_pose(left).origin.y, body_skeleton.get_bone_global_pose(right).origin.y)
	var hips := body_skeleton.find_bone("mixamorig_Hips")
	var position := body_skeleton.get_bone_pose_position(hips)
	position.y += base - floor_y
	body_skeleton.set_bone_pose_position(hips, position)

func pair_pose(time: float, kind: String, victim: bool, partner: Node3D) -> void:
	pair_controlled = true
	blend_age = time
	var impact := 0.46 if kind == "knee" else 0.43
	var fall := 0.66 if kind == "knee" else 0.54
	if victim:
		if time < impact:
			_sample_pose("Guard", 0)
			Pose.twist(self, "Spine", Vector3.RIGHT, smoothstep(0, 0.3, time) * 0.28)
		elif time < fall:
			_sample_pose("Hit", (time - impact) * 1.6)
			Pose.twist(self, "Spine", Vector3.RIGHT, 0.20)
		else:
			_fall_pose((time - fall) / (1.28 - fall) * 2.4)
	else:
		_sample_pose("Guard", 0)
		Pose.twist(self, "Spine", Vector3.RIGHT, 0.15 * smoothstep(0, 0.16, time))
		if time > 0.20 and time < 0.90:
			var data: Dictionary = preload("res://scripts/combat_moves.gd").MOVES["Knee" if kind == "knee" else "LowKick"]
			_sample_pose(data.clip, (time - 0.20) * data.rate)
			if kind == "knee":
				_sample_knee_base(data, time - 0.20)
			Pose.strike(self, data, time - 0.20)
			if kind == "sweep":
				_inside_reap(partner, time - 0.20, 0.23, 0.65)
		if time < 0.72:
			Pose.hold(self, partner, smoothstep(0, 0.16, time) * (1.0 - smoothstep(0.58, 0.72, time)))
	_close_hands()
	_blend_pose()
	if not victim or time < fall:
		_plant_feet()

func _inside_reap(partner: Node3D, time: float, contact: float, duration: float) -> void:
	_sample_pose("Guard", 0)
	var weight := smoothstep(0, contact, time) * (1.0 - smoothstep(contact + 0.06, duration, time))
	Pose.twist(self, "Spine", Vector3.UP, weight * -0.25)
	var ankle := to_local(partner.bone_world("LeftFoot")) + Vector3(0, 0.04, 0.02)
	Pose.limb(self, "Right", false, ankle, Vector3(-0.5, 0.9, 0.65), weight)
	Pose.limb(self, "Right", true, Vector3(-0.15, 1.3, 0.2), Vector3(-0.6, 1, 0.2))

func _fall_pose(time: float) -> void:
	_sample_pose("Down", time)
	# Keep the arms engaged: protect the head, then brace against the floor.
	# Death01's wide, airborne arms made even animation-driven falls look limp.
	var hips := to_local(bone_world("Hips"))
	var neck := to_local(bone_world("Neck"))
	var chest := hips.lerp(neck, 0.65)
	var settle := smoothstep(0.7, 1.55, time)
	var left := chest + Vector3(0.12, 0.06, 0.06)
	var right := (chest + Vector3(-0.18, 0.02, 0.08)).lerp(hips + Vector3(-0.32, 0.01, -0.08), settle)
	Pose.limb(self, "Left", true, left, chest + Vector3(0.4, 0.08, 0.20), 0.90)
	Pose.limb(self, "Right", true, right, chest + Vector3(-0.4, 0.02, 0.2), 0.92)

func counter_pose(time: float, kind: String, victim: bool, partner: Node3D, incoming: Dictionary) -> void:
	pair_controlled = true
	var counter := preload("res://scripts/counter_sequences.gd")
	var phase: int = counter.stage_at(time) if victim else (0 if time < counter.STARTS[0] else (1 if time < counter.STARTS[1] else (2 if time < counter.STARTS[2] else (3 if time < counter.ENDS[2] else 4))))
	if phase != counter_pose_phase:
		_remember_pose()
		counter_pose_phase = phase
		counter_phase_time = time
		blend_time = 0.035 if victim and phase > 0 else 0.075
	blend_age = time - counter_phase_time
	strike_has_goal = false
	if victim:
		if phase == 0:
			if not incoming.is_empty():
				var strike_data := incoming.duplicate()
				for key in ["contact", "link", "duration"]:
					strike_data[key] -= incoming.get("windup", 0.0)
				var retract: float = strike_data.contact + maxf(0, time - 0.06) * 1.4
				_sample_pose(strike_data.clip, retract * strike_data.rate)
				if not strike_data.get("captured", false):
					Pose.strike(self, strike_data, retract)
			else:
				_sample_pose("Guard", 0)
			Pose.twist(self, "Spine", Vector3.UP, smoothstep(0.05, 0.3, time) * 0.25)
		elif phase in [1, 2]:
			_sample_pose("Guard", 0)
			var recoil := Pose.recoil(time - counter.CONTACTS[phase - 1], 0.45)
			Pose.twist(self, "Spine", Vector3.RIGHT, recoil * (0.38 if phase == 1 else -0.12))
			Pose.twist(self, "Spine1", Vector3.UP, recoil * (-0.12 if phase == 1 else 0.48))
			Pose.twist(self, "Head", Vector3.UP, recoil * 0.18)
			Pose.limb(self, "Left", true, Vector3(0.18, 1.05, 0.3), Vector3(0.6, 0.95, 0), 0.9)
			Pose.limb(self, "Right", true, Vector3(-0.15, 1.1, 0.27), Vector3(-0.6, 0.95, 0), 0.9)
		else:
			var fall := clampf((time - counter.CONTACTS[2]) / (counter.FALL_END - counter.CONTACTS[2]), 0, 1)
			_fall_pose(pow(fall, 0.85) * 2.4)
	else:
		_sample_pose("Guard", 0)
		if phase in [1, 2, 3]:
			var data: Dictionary = counter.attack(kind, phase - 1)
			var elapsed: float = time - counter.STARTS[phase - 1]
			strike_goal = partner.bone_world("Spine" if phase == 1 or (phase == 3 and kind == "kick_counter") else "Neck")
			strike_has_goal = true
			_sample_pose(data.clip, elapsed * data.rate)
			if data.shape == "knee":
				_sample_knee_base(data, elapsed)
			if data.get("captured", false):
				_captured_contact(data, elapsed)
			else:
				Pose.strike(self, data, elapsed)
			if phase == 3 and kind == "hand_counter":
				_inside_reap(partner, elapsed, data.contact, data.duration)
				var drive := smoothstep(0.98, 1.16, time) * (1.0 - smoothstep(1.3, 1.6, time))
				Pose.twist(self, "Spine", Vector3.RIGHT, drive * 0.28)
				var shoulder := to_local(partner.bone_world("Spine2"))
				Pose.limb(self, "Left", true, shoulder, Vector3(0.5, 1.0, 0.6), drive)
				Pose.limb(self, "Right", true, shoulder + Vector3(-0.12, 0, 0), Vector3(-0.5, 1, 0.6), drive * 0.8)
		if time < 0.30:
			var limb_name: String = incoming.get("bone", "RightHand")
			var intercept := to_local(partner.bone_world(limb_name))
			Pose.limb(self, "Left", true, intercept, Vector3(0.6, 1.0, 0.35), 1.0 - smoothstep(0.16, 0.30, time))
		if kind == "kick_counter" and time > 0.14 and time < 0.46:
			Pose.hold(self, partner, sin((time - 0.14) / 0.32 * PI) * 0.75)
	_close_hands()
	_blend_pose()
	if not victim or time < counter.CONTACTS[2]:
		_plant_feet()
	_track_motion(maxf(0, time - previous_pair_time))
	previous_pair_time = time

func sample(clip: String, time: float) -> void:
	play_clip(clip, 1, 0)
	motion_time = time
	tick(0)
