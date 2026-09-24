extends RefCounted

# Two-bone constraints keep strike arcs connected to the character's proportions.
static func aim(rig: Skeleton3D, bone: int, child: int, at: Vector3) -> void:
	var pose := rig.get_bone_global_pose(bone)
	var current := rig.get_bone_global_pose(child).origin - pose.origin
	var desired := at - pose.origin
	if current.length_squared() < 0.00001 or desired.length_squared() < 0.00001:
		return
	var basis := Basis(Quaternion(current.normalized(), desired.normalized())) * pose.basis
	var parent := rig.get_bone_parent(bone)
	if parent >= 0:
		basis = rig.get_bone_global_pose(parent).basis.inverse() * basis
	rig.set_bone_pose_rotation(bone, basis.orthonormalized().get_rotation_quaternion())

static func limb(visual: Node3D, side: String, arm: bool, endpoint: Vector3, pole: Vector3, weight: float = 1.0) -> void:
	var rig: Skeleton3D = visual.body_skeleton
	var a := rig.find_bone("mixamorig_" + side + ("Arm" if arm else "UpLeg"))
	var b := rig.find_bone("mixamorig_" + side + ("ForeArm" if arm else "Leg"))
	var c := rig.find_bone("mixamorig_" + side + ("Hand" if arm else "Foot"))
	var start := rig.get_bone_global_pose(a).origin
	var middle := rig.get_bone_global_pose(b).origin
	var finish := rig.get_bone_global_pose(c).origin
	var end_basis := rig.get_bone_global_pose(c).basis
	var goal := finish.lerp(rig.to_local(visual.to_global(endpoint)), clampf(weight, 0, 1))
	var pole_point := rig.to_local(visual.to_global(pole))
	var length_a := start.distance_to(middle)
	var length_b := middle.distance_to(finish)
	var direction := (goal - start).normalized()
	var distance := clampf(start.distance_to(goal), absf(length_a - length_b) + 0.002, length_a + length_b - 0.002)
	var bend := pole_point - start
	bend -= direction * bend.dot(direction)
	if bend.length_squared() < 0.00001:
		bend = direction.cross(Vector3.RIGHT)
	bend = bend.normalized()
	var along := (length_a * length_a - length_b * length_b + distance * distance) / (2 * distance)
	var high := sqrt(maxf(0, length_a * length_a - along * along))
	aim(rig, a, b, start + direction * along + bend * high)
	aim(rig, b, c, start + direction * distance)
	var end_parent := rig.get_bone_parent(c)
	rig.set_bone_pose_rotation(c, (rig.get_bone_global_pose(end_parent).basis.inverse() * end_basis).orthonormalized().get_rotation_quaternion())

static func twist(visual: Node3D, suffix: String, axis: Vector3, angle: float) -> void:
	var rig: Skeleton3D = visual.body_skeleton
	var bone := rig.find_bone("mixamorig_" + suffix)
	var global_basis := Basis(axis, angle) * rig.get_bone_global_pose(bone).basis
	var parent := rig.get_bone_parent(bone)
	if parent >= 0:
		global_basis = rig.get_bone_global_pose(parent).basis.inverse() * global_basis
	rig.set_bone_pose_rotation(bone, global_basis.orthonormalized().get_rotation_quaternion())

static func arc(a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	return a * (1 - t) * (1 - t) + b * 2 * t * (1 - t) + c * t * t

static func recoil(time: float, duration: float) -> float:
	# Fast compression at contact, followed by a longer controlled recovery.
	return smoothstep(0, 0.035, time) * (1.0 - smoothstep(0.045, duration, time))

static func strike(visual: Node3D, data: Dictionary, time: float) -> void:
	var contact: float = data.contact
	var phase := clampf(time / contact, 0, 1)
	var hand: bool = data.bone.ends_with("Hand") or data.shape == "elbow"
	var recover := smoothstep(contact + 0.025, minf(data.duration, contact + 0.19) if hand else float(data.duration), time)
	var weight := smoothstep(0, 0.065, time) * (1.0 - recover)
	# Accelerate through the target, then withdraw. Smoothstep at the endpoint
	# made the hand visibly decelerate to zero before every previous impact.
	var travel := pow(phase, 1.65) if time <= contact else 1.0 + minf((time - contact) * 2.0, 0.12)
	var side: String = data.side
	var sign_side := 1.0 if side == "Left" else -1.0
	var shape: String = data.shape
	if hand:
		var drive := sin(phase * PI * 0.65) * weight
		twist(visual, "Hips", Vector3.UP, sign_side * -0.10 * drive)
		twist(visual, "Spine1", Vector3.UP, sign_side * -0.16 * drive)
	if shape == "knee":
		var hips: int = visual.body_skeleton.find_bone("mixamorig_Hips")
		var hip_position: Vector3 = visual.body_skeleton.get_bone_pose_position(hips)
		hip_position.z += weight * 0.10
		visual.body_skeleton.set_bone_pose_position(hips, hip_position)
	if shape in ["body", "elbow"]:
		twist(visual, "Spine", Vector3.RIGHT, (0.26 if shape == "elbow" else 0.17) * weight)
	var end := Vector3(sign_side * 0.06, data.height, 0.66)
	if data.bone.ends_with("Hand") or shape == "elbow":
		var start := Vector3(sign_side * 0.22, 1.29, 0.17)
		var middle := Vector3(sign_side * 0.22, data.height, 0.32)
		match shape:
			"hook":
				start = Vector3(sign_side * 0.40, 1.27, 0.04)
				middle = Vector3(sign_side * 0.58, 1.40, 0.54)
				end.x = -sign_side * 0.08
			"uppercut":
				start = Vector3(sign_side * 0.22, 0.87, 0.15)
				middle = Vector3(sign_side * 0.16, 0.90, 0.70)
				end.z = 0.51
			"body":
				start.y = 1.04
				middle.y = 0.97
			"backfist":
				start = Vector3(-sign_side * 0.25, 1.42, 0.08)
				middle = Vector3(-sign_side * 0.47, 1.47, 0.52)
				end.x = sign_side * 0.12
			"elbow":
				start = Vector3(0.04, 1.51, 0.14)
				middle = Vector3(0.30, 1.48, 0.25)
				end = Vector3(0.20, 1.50, 0.26)
		if shape in ["hook", "backfist", "elbow"]:
			twist(visual, "Spine", Vector3.UP, sign_side * sin(phase * PI) * 0.35 * weight)
		if visual.strike_has_goal and shape != "elbow":
			var goal: Vector3 = visual.to_local(visual.strike_goal)
			end = end.lerp(Vector3(clampf(goal.x, -0.3, 0.3), clampf(goal.y, 0.9, 1.5), clampf(goal.z, 0.35, 0.80)), 0.88)
		var target := arc(start, middle, end, travel)
		var pole := Vector3(sign_side * 0.6, 1.06, 0.15)
		if shape == "elbow":
			pole = Vector3(-0.08, 1.28, 1.2)
		limb(visual, side, true, target, pole, weight)
		limb(visual, "Right" if side == "Left" else "Left", true, Vector3(-sign_side * 0.18, 1.37, 0.17), Vector3(-sign_side * 0.6, 1.02, 0), 0.75)
	else:
		var start := Vector3(sign_side * 0.14, 0.35, 0.04)
		var middle := Vector3(sign_side * 0.2, 0.8, 0.18)
		end = Vector3(sign_side * 0.07, data.height, 0.80)
		if shape in ["round_kick", "low_kick"]:
			start.x = sign_side * 0.5
			middle.x = sign_side * 0.75
			middle.z = 0.65
		if shape == "side_kick":
			middle = Vector3(sign_side * 0.3, 0.98, 0.1)
			end.z = 0.85
		if shape == "knee":
			var rig: Skeleton3D = visual.body_skeleton
			var thigh := rig.find_bone("mixamorig_" + side + "UpLeg")
			var shin := rig.find_bone("mixamorig_" + side + "Leg")
			var foot := rig.find_bone("mixamorig_" + side + "Foot")
			var knee_goal: Vector3 = visual.to_local(visual.bone_world(side + "Leg")).lerp(Vector3(0.02, 1.03, 0.65), weight * smoothstep(0, 1, phase))
			aim(rig, thigh, shin, rig.to_local(visual.to_global(knee_goal)))
			var folded: Vector3 = visual.to_local(visual.bone_world(side + "Leg")) + Vector3(0, -0.32, -0.16)
			aim(rig, shin, foot, rig.to_local(visual.to_global(folded)))
			return
		if visual.strike_has_goal:
			var goal: Vector3 = visual.to_local(visual.strike_goal)
			end = end.lerp(Vector3(clampf(goal.x, -0.25, 0.25), clampf(goal.y, 0.3, 1.4), clampf(goal.z, 0.5, 1.05)), 0.75)
		limb(visual, side, false, arc(start, middle, end, travel), Vector3(0, 1.4, 1.5), weight)

static func hold(visual: Node3D, victim: Node3D, weight: float) -> void:
	var neck := visual.to_local(victim.bone_world("Neck"))
	var arm := visual.to_local(victim.bone_world("RightArm"))
	limb(visual, "Left", true, neck + Vector3(0, -0.05, 0), Vector3(0.65, 1.05, 0.35), weight)
	limb(visual, "Right", true, arm, Vector3(-0.6, 1.0, 0.4), weight)
