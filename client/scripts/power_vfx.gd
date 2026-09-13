extends RefCounted

const SHELL_SHADER := "shader_type spatial;\nrender_mode blend_add, depth_draw_never, cull_back, unshaded;\nuniform vec4 tint : source_color = vec4(0.1,0.9,0.8,1.0);\nuniform float opacity = 0.7;\nvoid fragment(){float rim=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),2.3);float ripples=0.65+0.35*sin(UV.y*55.0-TIME*12.0+sin(UV.x*30.0)*2.0);ALBEDO=tint.rgb;EMISSION=tint.rgb*1.4;ALPHA=opacity*(0.12+rim*0.8)*ripples;}"

static func glow(color: Color, strength: float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * strength
	mat.roughness = 0.3
	return mat

static func sphere(parent: Node3D, radius: float, color: Color, shell: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 24
	mesh.rings = 12
	node.mesh = mesh
	if shell:
		var shader := Shader.new()
		shader.code = SHELL_SHADER
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("tint", color)
		node.material_override = material
	else:
		node.material_override = glow(color, 1.5)
	parent.add_child(node)
	return node

static func ring(parent: Node3D, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius * 0.91
	mesh.outer_radius = radius
	mesh.rings = 36
	mesh.ring_segments = 8
	node.mesh = mesh
	node.material_override = glow(color, 1.7)
	parent.add_child(node)
	return node

static func particles(parent: Node3D, color: Color, count: int = 22, strength: float = 3.0) -> CPUParticles3D:
	var emitter := CPUParticles3D.new()
	emitter.amount = count
	emitter.lifetime = 0.55
	emitter.one_shot = true
	emitter.explosiveness = 1.0
	emitter.direction = Vector3.UP
	emitter.spread = 180
	emitter.initial_velocity_min = strength * 0.3
	emitter.initial_velocity_max = strength
	emitter.gravity = Vector3(0, -3.5, 0)
	emitter.scale_amount_min = 0.3
	emitter.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	emitter.scale_amount_curve = curve
	var mesh := SphereMesh.new()
	mesh.radius = 0.055
	mesh.height = 0.11
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = glow(color, 2)
	emitter.mesh = mesh
	parent.add_child(emitter)
	emitter.emitting = true
	return emitter

static func burst(parent: Node3D, at: Vector3, color: Color, size: float = 1.0) -> Node3D:
	var effect := Node3D.new()
	effect.name = "ImpactVolume"
	parent.add_child(effect)
	effect.global_position = at
	var shell := sphere(effect, 0.3, color, true)
	var torus := ring(effect, 0.4, color)
	torus.rotation = Vector3(0.5, 0.3, 0.5)
	particles(effect, color, 24, size * 4)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.5
	light.omni_range = size * 5
	effect.add_child(light)
	var tween := effect.create_tween().set_parallel(true)
	tween.tween_property(shell, "scale", Vector3.ONE * size * 5, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: float): shell.material_override.set_shader_parameter("opacity", value), 0.7, 0.0, 0.5)
	tween.tween_property(torus, "scale", Vector3.ONE * size * 3.5, 0.35)
	tween.tween_property(torus, "rotation:y", 3.0, 0.45)
	tween.tween_property(light, "light_energy", 0.0, 0.4)
	tween.chain().tween_callback(torus.hide)
	tween.chain().tween_interval(0.3)
	tween.chain().tween_callback(effect.queue_free)
	return effect

static func blink(parent: Node3D, at: Vector3, color: Color) -> void:
	var effect := burst(parent, at + Vector3.UP, color, 1.1)
	for i in range(3):
		var torus := ring(effect, 0.65, color)
		torus.position.y = -0.8 + i * 0.7
		var tween := effect.create_tween()
		tween.tween_property(torus, "scale", Vector3.ONE * 0.02, 0.4 + i * 0.08)

static func aura(parent: Node3D, color: Color, radius: float = 0.9) -> Node3D:
	var effect := Node3D.new()
	effect.name = "PowerAura"
	parent.add_child(effect)
	sphere(effect, radius, color, true)
	for i in range(2):
		var torus := ring(effect, radius * 1.08, color)
		torus.rotation = Vector3(PI * 0.5 * i, 0.5, 0.6)
		var tween := effect.create_tween().set_loops()
		tween.tween_property(torus, "rotation:y", TAU + 0.5, 1.8 + i * 0.5).from(0.5)
	return effect

static func shield(parent: Node3D, at: Vector3) -> Node3D:
	var effect := Node3D.new()
	effect.name = "EnergyShield"
	parent.add_child(effect)
	effect.global_position = at
	var shell := sphere(effect, 1.2, Color("57bbff"), true)
	shell.scale.y = 1.1
	for angle in [0.0, PI / 2]:
		var band := ring(effect, 1.22, Color("57bbff"))
		band.rotation = Vector3(PI / 2, angle, 0)
	var light := OmniLight3D.new()
	light.light_color = Color("57bbff")
	light.light_energy = 0.8
	light.omni_range = 3.5
	effect.add_child(light)
	return effect

static func shockwave(parent: Node3D, at: Vector3, radius: float) -> void:
	var effect := burst(parent, at + Vector3.UP * 0.35, Color("ffaa53"), 1.3)
	var shell := sphere(effect, 1.0, Color("ffaa53"), true)
	shell.scale = Vector3(0.2, 0.2, 0.2)
	var ground_ring := ring(effect, 1.0, Color("ffc576"))
	var tween := effect.create_tween().set_parallel(true)
	tween.tween_property(shell, "scale", Vector3(radius, 1.8, radius), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ground_ring, "scale", Vector3(radius, 1, radius), 0.45)
	tween.tween_method(func(value: float): shell.material_override.set_shader_parameter("opacity", value), 0.7, 0, 0.5)
