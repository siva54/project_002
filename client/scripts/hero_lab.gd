extends Node3D

const Catalog = preload("res://scripts/power_catalog.gd")
const Hero = preload("res://scripts/hero_controller.gd")
const Sentinel = preload("res://scripts/sentinel_controller.gd")
const Avatar = preload("res://scripts/avatar_visual.gd")
const Surfaces = preload("res://scripts/surface_library.gd")
const VFX = preload("res://scripts/power_vfx.gd")
const Projectile = preload("res://scripts/energy_projectile.gd")
const COLORS := [Color("46dec6"), Color("eeaa55"), Color("ae9bff"), Color("f26b86")]
const POWER_IDS := Catalog.POWER_IDS
const MAX_HOSTILE_PROJECTILES := 3
const SIGHT_REFRESH_SECONDS := 0.12

var hero: CharacterBody3D
var arena: Node3D
var effects: Node3D
var loadout: Array = []
var energy := 100.0
var health := 100.0
var cooldowns: Dictionary = {}
var cloak_time := 0.0
var color_index := 0
var held_prop: RigidBody3D
var kinetic_aura: Node3D
var cloak_aura: Node3D
var shield_aura: Node3D
var shield_time := 0.0
var melee_cooldown := 0.0
var melee_windup := 0.0
var score := 0
var relay: StaticBody3D
var relay_core: Node3D
var relay_label: Label3D
var relay_charge := 0.0
var relay_complete := false
var pickup_total := 0
var pickups_collected := 0
var sight_refresh := 0.0
var sight_cache: Dictionary = {}
var running := false
var notice_time := 0.0
var menu: Control
var hud: Control
var energy_bar: ProgressBar
var health_bar: ProgressBar
var notice: Label
var score_label: Label
var status_label: Label
var start_button: Button
var power_buttons: Dictionary = {}
var power_titles: Dictionary = {}
var build_slots: Array[Label] = []
var slot_labels: Array[Label] = []

func _ready() -> void:
	_register_input()
	_build_world()
	hero = Hero.new()
	add_child(hero)
	hero.position = Vector3(0, 0.05, 10)
	hero.power_requested.connect(activate_slot)
	hero.menu_requested.connect(show_menu)
	hero.melee_requested.connect(melee_attack)
	_build_ui()
	reset_arena()
	show_menu()

func _register_input() -> void:
	var mappings := {
		"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A,
		"move_right": KEY_D, "jump": KEY_SPACE, "sprint": KEY_SHIFT,
		"melee": KEY_F, "pause_lab": KEY_ESCAPE, "power_0": KEY_1, "power_1": KEY_2, "power_2": KEY_3,
	}
	for action in mappings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = mappings[action]
			InputMap.action_add_event(action, event)

func _material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	if glow > 0:
		material.emission_enabled = true
		material.emission = color * glow
	return material

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = true, glow: float = 0) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	parent.add_child(node)
	node.position = at
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = Surfaces.pbr("concrete", color.lightened(0.42)) if solid else _material(color, glow)
	node.add_child(mesh)
	if solid:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		node.add_child(shape)
	return node

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("070b11")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("9cadb8")
	settings.ambient_light_energy = 0.26
	settings.fog_enabled = true
	settings.fog_light_color = Color("101820")
	settings.fog_density = 0.006
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -25, 0)
	sun.light_color = Color("dbe7f1")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	arena = Node3D.new()
	add_child(arena)
	effects = Node3D.new()
	add_child(effects)
	_box(self, Vector3(0, -0.5, 0), Vector3(44, 1, 44), Color("1c2b3e"))
	for x in range(-20, 21, 4):
		_box(self, Vector3(x, 0.008, 0), Vector3(0.025, 0.01, 44), Color("31465b"), false)
	for z in range(-20, 21, 4):
		_box(self, Vector3(0, 0.008, z), Vector3(44, 0.01, 0.025), Color("31465b"), false)
	for x in [-22, 22]:
		_box(self, Vector3(x, 2, 0), Vector3(1, 4, 45), Color("243449"))
		_box(self, Vector3(x, 4.02, 0), Vector3(1.05, 0.06, 45), COLORS[0], false, 1)
	for z in [-22, 22]:
		_box(self, Vector3(0, 2, z), Vector3(45, 4, 1), Color("243449"))
		_box(self, Vector3(0, 4.02, z), Vector3(45, 0.06, 1.05), COLORS[0], false, 1)
	_box(self, Vector3(-9, 1.5, -3), Vector3(7, 3, 9), Color("30475b"))
	_box(self, Vector3(-9, 3.02, -3), Vector3(7.05, 0.05, 9.05), Color("446c7f"))
	for i in range(6):
		_box(self, Vector3(-9, 0.25 * (i + 1), 7 - i), Vector3(3, 0.5 * (i + 1), 1), Color("385467"))
	_box(self, Vector3(8, 1.1, -3), Vector3(5, 2.2, 2), Color("344b62"))
	for x in [-17, 17]:
		for z in [-15, 15]:
			_box(self, Vector3(x, 3, z), Vector3(2, 6, 2), Color("263e56"))
			_box(self, Vector3(x, 6.05, z), Vector3(2.1, 0.15, 2.1), COLORS[0], false, 1)
	var sign := Label3D.new()
	sign.text = "H E R O   L A B\nP O W E R   P L A Y G R O U N D"
	sign.position = Vector3(0, 6, -21.4)
	sign.font_size = 70
	sign.pixel_size = 0.012
	sign.modulate = Color("6aa7bc")
	add_child(sign)
	# Raised loading door, steel deck plates, and crate frames give the lab scale.
	var gate := _box(self, Vector3(0, 2.0, -21.35), Vector3(7, 4, 0.18), Color.WHITE, false)
	gate.get_child(0).material_override = Surfaces.pbr("metal", Color("718595"), 0.6)
	for x in [-3.8, 3.8]:
		_box(self, Vector3(x, 2.2, -21.1), Vector3(0.5, 4.4, 0.5), Color("354453"))
	_box(self, Vector3(0, 4.4, -21.1), Vector3(8.1, 0.4, 0.5), Color("354453"))
	for z in [6, 10, 14]:
		var deck := _box(self, Vector3(0, 0.012, z), Vector3(4, 0.015, 3.7), Color.WHITE, false)
		deck.get_child(0).material_override = Surfaces.pbr("metal", Color("687b88"), 0.7)
	for x in [-17, 17]:
		for z in [-15, 15]:
			var band := _box(self, Vector3(x, 0.5, z), Vector3(2.05, 0.35, 2.05), Color("b59a48"), false)
			band.get_child(0).material_override = Surfaces.pbr("metal", Color("c4a057"), 1.0)

func reset_arena() -> void:
	_end_shield()
	_clear_aura("kinetic")
	_clear_aura("cloak")
	melee_cooldown = 0
	melee_windup = 0
	held_prop = null
	relay = null
	relay_core = null
	relay_label = null
	relay_charge = 0
	relay_complete = false
	pickup_total = 0
	pickups_collected = 0
	sight_refresh = 0
	sight_cache.clear()
	for child in arena.get_children():
		arena.remove_child(child)
		child.queue_free()
	for child in effects.get_children():
		child.queue_free()
	for at in [Vector3(-3, 1, 3), Vector3(3, 1, 4), Vector3(5, 1, -6), Vector3(-3, 1, -8)]:
		_create_prop(at)
	_create_relay(Vector3(0, 0, -10.5))
	_create_pickup(Vector3(-15, 0.7, 10), "energy")
	_create_pickup(Vector3(15, 0.7, 10), "vitality")
	_create_pickup(Vector3(-16, 0.7, -12), "energy")
	_create_pickup(Vector3(16, 0.7, -12), "vitality")
	var sentinel_spawns := [Vector3(0, 0, -3), Vector3(9, 0, -12), Vector3(-3, 0, -15), Vector3(-10, 3, -5), Vector3(14, 0, 4)]
	for index in sentinel_spawns.size():
		_create_target(sentinel_spawns[index], index)
	hero.position = Vector3(0, 0.05, 10)
	hero.velocity = Vector3.ZERO
	hero.attack_lock = 0
	hero.yaw = 0
	hero.pitch = -0.12
	hero._update_camera()
	hero.visual.reset_pose()
	hero.visual.rotation.y = PI
	energy = Catalog.MAX_ENERGY
	health = 100
	cooldowns.clear()
	cloak_time = 0
	score = 0
	hero.set_appearance(COLORS[color_index], false)
	if not running:
		for target in get_tree().get_nodes_in_group("targets"):
			target.set_frozen(true)
	_update_hud()

func _create_prop(at: Vector3) -> void:
	var body := RigidBody3D.new()
	body.collision_layer = 4
	body.collision_mask = 7
	body.mass = 2
	body.contact_monitor = true
	body.max_contacts_reported = 4
	body.continuous_cd = true
	body.add_to_group("props")
	arena.add_child(body)
	body.position = at
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 1.1
	mesh.mesh = box
	mesh.material_override = Surfaces.pbr("metal", Color("bf9656"), 1.2)
	body.add_child(mesh)
	for x in [-0.43, 0.43]:
		var band := _box(body, Vector3(x, 0, 0), Vector3(0.12, 1.13, 1.13), Color.WHITE, false)
		band.get_child(0).material_override = Surfaces.pbr("metal", Color("404951"), 1.0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * 1.1
	collision.shape = shape
	body.add_child(collision)
	body.body_entered.connect(_prop_contact.bind(body))

func _create_relay(at: Vector3) -> void:
	relay = StaticBody3D.new()
	relay.name = "PowerRelay"
	relay.add_to_group("relay")
	arena.add_child(relay)
	relay.position = at
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.35
	shape.height = 3.0
	collision.shape = shape
	collision.position.y = 1.5
	relay.add_child(collision)
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.2
	base_mesh.bottom_radius = 1.55
	base_mesh.height = 0.75
	base.mesh = base_mesh
	base.position.y = 0.38
	base.material_override = Surfaces.pbr("metal", Color("526979"), 1.1)
	relay.add_child(base)
	var tower := MeshInstance3D.new()
	var tower_mesh := CylinderMesh.new()
	tower_mesh.top_radius = 0.34
	tower_mesh.bottom_radius = 0.68
	tower_mesh.height = 2.2
	tower.mesh = tower_mesh
	tower.position.y = 1.5
	tower.material_override = Surfaces.pbr("metal", Color("405466"), 0.8)
	relay.add_child(tower)
	relay_core = Node3D.new()
	relay_core.name = "RelayCore"
	relay.add_child(relay_core)
	relay_core.position.y = 1.7
	VFX.sphere(relay_core, 0.45, Color("4ebccf"), true)
	var core_ring := VFX.ring(relay_core, 0.64, Color("4ebccf"))
	core_ring.rotation.x = PI * 0.5
	var light := OmniLight3D.new()
	light.name = "CoreLight"
	light.light_color = Color("4ebccf")
	light.light_energy = 1.2
	light.omni_range = 5.0
	relay_core.add_child(light)
	relay_label = Label3D.new()
	relay_label.name = "RelayLabel"
	relay_label.position.y = 3.4
	relay_label.font_size = 27
	relay_label.pixel_size = 0.009
	relay_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	relay.add_child(relay_label)
	_refresh_relay()

func _create_pickup(at: Vector3, kind: String) -> void:
	var pickup := Node3D.new()
	pickup.name = "EnergyCell" if kind == "energy" else "VitalCell"
	pickup.add_to_group("pickups")
	pickup.set_meta("kind", kind)
	pickup.set_meta("base_y", at.y)
	arena.add_child(pickup)
	pickup.position = at
	var color := Color("54e8d0") if kind == "energy" else Color("ff8e9c")
	var crystal := MeshInstance3D.new()
	var crystal_mesh := PrismMesh.new()
	crystal_mesh.left_to_right = 0.45
	crystal_mesh.size = Vector3(0.55, 0.95, 0.55)
	crystal.mesh = crystal_mesh
	crystal.material_override = VFX.glow(color, 2.0)
	pickup.add_child(crystal)
	VFX.ring(pickup, 0.55, color)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.7
	light.omni_range = 3.0
	pickup.add_child(light)
	var label := Label3D.new()
	label.text = "ENERGY +30" if kind == "energy" else "VITALITY +25"
	label.position.y = 1.25
	label.font_size = 22
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	pickup.add_child(label)
	pickup_total += 1

func _create_target(at: Vector3, index: int) -> void:
	var body := Sentinel.new()
	body.name = "Sentinel_%d" % (index + 1)
	body.add_to_group("targets")
	arena.add_child(body)
	var patrol := [at + Vector3(-2.2, 0, 0.8), at + Vector3(2.2, 0, -0.8)]
	if index == 3:
		patrol = [at + Vector3(-1.5, 0, 0), at + Vector3(1.5, 0, 0)]
	body.setup(at, patrol, 1.5 + index * 0.35)
	body.projectile_requested.connect(_sentinel_projectile)
	body.alerted.connect(_sentinel_alerted)

func _prop_contact(other: Node, prop: RigidBody3D) -> void:
	if not prop.get_meta("thrown", false):
		return
	prop.set_meta("thrown", false)
	VFX.burst(effects, prop.position, COLORS[color_index], 0.9)
	if other.is_in_group("targets"):
		_damage_target(other, 60.0)
		_broadcast_noise(prop.position, 15.0, other)
		_message("KINETIC IMPACT  /  Target disabled")
	elif other.is_in_group("relay"):
		_energize_relay(45.0, "KINETIC IMPACT")

func _update_pickups(delta: float) -> void:
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup.is_queued_for_deletion():
			continue
		pickup.rotation.y += delta * 2.2
		pickup.position.y = float(pickup.get_meta("base_y")) + sin(Time.get_ticks_msec() * 0.004 + pickup.position.x) * 0.12
		if hero.position.distance_to(pickup.position) > 1.4:
			continue
		var kind: String = pickup.get_meta("kind")
		var color := Color("54e8d0") if kind == "energy" else Color("ff8e9c")
		if kind == "energy":
			energy = minf(Catalog.MAX_ENERGY, energy + 30.0)
			_message("ENERGY CELL  /  +30 energy")
		else:
			health = minf(100.0, health + 25.0)
			_message("VITAL CELL  /  +25 vitality")
		pickups_collected += 1
		VFX.burst(effects, pickup.position + Vector3.UP * 0.35, color, 0.8)
		pickup.queue_free()

func _update_relay(delta: float) -> void:
	if not is_instance_valid(relay_core):
		return
	relay_core.rotation.y += delta * (0.75 + relay_charge * 0.02)
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.05
	relay_core.scale = Vector3.ONE * pulse * (1.0 + relay_charge * 0.0015)

func _energize_relay(amount: float, source: String) -> void:
	if relay_complete or not is_instance_valid(relay):
		return
	var before := relay_charge
	relay_charge = minf(100.0, relay_charge + amount)
	if is_equal_approx(before, relay_charge):
		return
	VFX.burst(effects, relay.position + Vector3.UP * 1.7, Color("70e8e0"), 0.9 + amount * 0.01)
	_broadcast_noise(relay.position, 16.0)
	if relay_charge >= 100.0:
		relay_complete = true
	_refresh_relay()
	if relay_complete:
		energy = Catalog.MAX_ENERGY
		health = minf(100.0, health + 30.0)
		VFX.burst(effects, relay.position + Vector3.UP * 1.7, Color("c4ff86"), 2.0)
		_message("POWER RELAY ONLINE  /  Energy restored. +30 vitality.", 6.0)
	else:
		_message("%s  /  Relay charge %d%%" % [source, int(relay_charge)])

func _refresh_relay() -> void:
	if not is_instance_valid(relay):
		return
	relay.set_meta("charge", relay_charge)
	relay.set_meta("complete", relay_complete)
	if is_instance_valid(relay_label):
		relay_label.text = "POWER RELAY  /  ONLINE" if relay_complete else "POWER RELAY  /  %d%%" % int(relay_charge)
		relay_label.modulate = Color("c4ff86") if relay_complete else Color("72dce2")
	if is_instance_valid(relay_core):
		var light: OmniLight3D = relay_core.get_node("CoreLight")
		light.light_color = Color("c4ff86") if relay_complete else Color("4ebccf")
		light.light_energy = 1.2 + relay_charge * 0.018

func _physics_process(delta: float) -> void:
	if not running:
		return
	melee_cooldown = maxf(0, melee_cooldown - delta)
	if melee_windup > 0:
		melee_windup -= delta
		if melee_windup <= 0:
			_resolve_melee()
	energy = minf(Catalog.MAX_ENERGY, energy + delta * Catalog.REGEN_PER_SECOND)
	if shield_time > 0:
		shield_time = maxf(0, shield_time - delta)
		if shield_time <= 0:
			_end_shield()
		elif is_instance_valid(shield_aura):
			shield_aura.global_position = hero.position + Vector3.UP
	for id in cooldowns:
		cooldowns[id] = maxf(0.0, cooldowns[id] - delta)
	if cloak_time > 0:
		cloak_time = maxf(0, cloak_time - delta)
		hero.set_appearance(COLORS[color_index], cloak_time > 0)
		if cloak_time <= 0:
			_clear_aura("cloak")
	if is_instance_valid(held_prop):
		var hold_origin: Vector3 = hero.position + Vector3.UP * 1.6
		var query := PhysicsShapeQueryParameters3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3.ONE * 1.15
		query.shape = shape
		query.collision_mask = 5
		query.transform = Transform3D(Basis.IDENTITY, hold_origin)
		query.motion = hero.aim_direction() * 2.5
		var fraction := get_world_3d().direct_space_state.cast_motion(query)
		held_prop.global_position = hold_origin + query.motion * fraction[0]
	if is_instance_valid(kinetic_aura) and is_instance_valid(held_prop):
		kinetic_aura.global_position = held_prop.global_position
	if is_instance_valid(cloak_aura):
		cloak_aura.global_position = hero.position + Vector3.UP
	_update_pickups(delta)
	_update_relay(delta)
	_update_sentinels(delta)
	notice_time -= delta
	if notice_time <= 0:
		notice.text = ""
	_update_hud()

func activate_slot(slot: int) -> bool:
	if not running or slot < 0 or slot >= loadout.size():
		return false
	var id: String = loadout[slot]
	if id == "kinetic" and is_instance_valid(held_prop):
		_throw_prop()
		return true
	if not Catalog.can_activate(id, energy, cooldowns.get(id, 0.0)):
		_message("Power recovering" if cooldowns.get(id, 0.0) > 0 else "Energy recharging")
		return false
	var success := false
	match id:
		"bolt":
			success = _fire_bolt()
		"missiles":
			success = _fire_missiles()
		"blink":
			success = _blink()
		"kinetic":
			success = _grab_prop()
		"shockwave":
			success = _shockwave()
		"shield":
			success = _shield()
		"cloak":
			cloak_time = 5.0
			_clear_aura("cloak")
			cloak_aura = VFX.aura(effects, Color("819cff"), 0.85)
			cloak_aura.position = hero.position + Vector3.UP
			hero.play_attack()
			hero.set_appearance(COLORS[color_index], true)
			_message("CLOAK  /  Contact lost. Attacking reveals your position.")
			success = true
	if success:
		energy -= float(Catalog.POWERS[id].cost)
		cooldowns[id] = float(Catalog.POWERS[id].cooldown)
	return success

func _shield() -> bool:
	_end_shield()
	shield_time = Catalog.SHIELD_DURATION
	shield_aura = VFX.shield(effects, hero.position + Vector3.UP)
	hero.play_attack()
	_message("ENERGY SHIELD  /  Incoming energy blocked for 5 seconds")
	return true

func _end_shield() -> void:
	shield_time = 0
	if is_instance_valid(shield_aura):
		shield_aura.queue_free()
	shield_aura = null

func _shockwave() -> bool:
	_reveal()
	hero.play_attack()
	var origin: Vector3 = hero.position + Vector3.UP
	VFX.shockwave(effects, hero.position, Catalog.SHOCKWAVE_RADIUS)
	_broadcast_noise(hero.position, 18.0)
	for group in ["targets", "props"]:
		for body in get_tree().get_nodes_in_group(group):
			if body.is_queued_for_deletion() or body == held_prop:
				continue
			var center: Vector3 = body.position + (Vector3.UP if group == "targets" else Vector3.ZERO)
			var offset := center - origin
			if offset.length() > Catalog.SHOCKWAVE_RADIUS:
				continue
			var ray := PhysicsRayQueryParameters3D.create(origin, center, 5)
			var hit := get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty() and hit.collider == body:
				if group == "targets":
					_damage_target(body, Catalog.SHOCKWAVE_DAMAGE)
				else:
					body.apply_central_impulse(offset.normalized() * 22 + Vector3.UP * 7)
	if not relay_complete and is_instance_valid(relay):
		var relay_center := relay.position + Vector3.UP * 1.5
		if origin.distance_to(relay_center) <= Catalog.SHOCKWAVE_RADIUS:
			var relay_ray := PhysicsRayQueryParameters3D.create(origin, relay_center, 5)
			var relay_hit := get_world_3d().direct_space_state.intersect_ray(relay_ray)
			if not relay_hit.is_empty() and relay_hit.collider == relay:
				_energize_relay(30.0, "SHOCKWAVE")
	_message("SHOCKWAVE  /  Exposed enemies hit. Nearby crates launched.")
	return true

func _reveal() -> void:
	_clear_aura("cloak")
	cloak_time = 0
	hero.set_appearance(COLORS[color_index], false)

func _fire_bolt() -> bool:
	_reveal()
	hero.play_attack()
	var origin: Vector3 = hero.muzzle_position()
	var query := PhysicsRayQueryParameters3D.create(hero.position + Vector3.UP * 1.25, origin, 5)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		origin = hero.position + Vector3.UP * 1.25
	VFX.cast(effects, origin, COLORS[color_index])
	_launch_orb(origin, hero.aim_point(), COLORS[color_index], false, hero)
	_broadcast_noise(origin, 13.0)
	return true

func _fire_missiles() -> bool:
	_reveal()
	var origin: Vector3 = hero.muzzle_position()
	var targets := _visible_homing_targets(origin)
	if targets.is_empty():
		_message("SEEKER MISSILES  /  No exposed sentinel in range")
		return false
	hero.play_attack()
	VFX.cast(effects, origin, Color("f6b85d"))
	for index in range(3):
		var target: Node3D = targets[index % targets.size()]
		var spread: Vector3 = Basis(Vector3.UP, (float(index) - 1.0) * 0.16) * hero.aim_direction()
		var missile: Node3D = _launch_orb(origin + Vector3.UP * 0.08 + Vector3(float(index - 1) * 0.18, 0, 0), target.position + Vector3.UP, Color("f6b85d"), false, hero, true, target, index * 0.13)
		missile.direction = spread.normalized()
		missile.speed = 20.0
	_broadcast_noise(origin, 16.0)
	_message("SEEKER VOLLEY  /  %d exposed target%s acquired" % [targets.size(), "s" if targets.size() > 1 else ""])
	return true

func _visible_homing_targets(origin: Vector3) -> Array:
	var candidates: Array = []
	for target in get_tree().get_nodes_in_group("targets"):
		if target.is_queued_for_deletion() or target.position.distance_to(origin) > 26.0:
			continue
		var ray := PhysicsRayQueryParameters3D.create(origin, target.position + Vector3.UP, 5)
		ray.exclude = [hero.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider == target:
			candidates.append(target)
	candidates.sort_custom(func(a: Node3D, b: Node3D): return a.position.distance_squared_to(origin) < b.position.distance_squared_to(origin))
	return candidates

func _launch_orb(origin: Vector3, endpoint: Vector3, color: Color, hostile: bool, owner_body: CollisionObject3D, is_missile: bool = false, homing_target: Node3D = null, launch_delay: float = 0.0) -> Node3D:
	if hostile:
		var hostile_count := 0
		for projectile in get_tree().get_nodes_in_group("projectiles"):
			if projectile.get_meta("hostile", false):
				hostile_count += 1
		if hostile_count >= MAX_HOSTILE_PROJECTILES:
			return null
	var orb := Projectile.new()
	orb.set_meta("hostile", hostile)
	orb.is_missile = is_missile
	orb.homing_target = homing_target
	orb.launch_delay = launch_delay
	orb.tint = color
	orb.direction = (endpoint - origin).normalized()
	orb.speed = 11.0 if hostile else 24.0
	orb.collision_mask = 7 if hostile else 5
	orb.excluded = [owner_body.get_rid()]
	orb.impacted.connect(_orb_impact.bind(hostile, color, orb.direction))
	effects.add_child(orb)
	orb.global_position = origin
	return orb

func _orb_impact(body: Node, at: Vector3, hostile: bool, color: Color, direction: Vector3) -> void:
	VFX.burst(effects, at, color, 0.75)
	if hostile:
		if body == hero:
			if shield_time > 0:
				VFX.burst(effects, at, Color("57bbff"), 0.9)
				_message("SHIELD BLOCK  /  %.1fs remaining" % shield_time)
				return
			health = maxf(0, health - 6)
			if health <= 0:
				show_menu()
				status_label.text = "Hero down. Reset the arena to try a new combination."
	elif body.is_in_group("relay"):
		_energize_relay(25.0, "ENERGY BOLT")
	elif body.is_in_group("targets"):
		_damage_target(body, 30)
	elif body is RigidBody3D:
		body.apply_central_impulse(direction * 18)

func melee_attack() -> bool:
	if not running or melee_cooldown > 0:
		return false
	_reveal()
	hero.play_attack()
	melee_cooldown = 0.65
	melee_windup = 0.18
	_message("MELEE  /  Close-range punch")
	return true

func _resolve_melee() -> void:
	var origin: Vector3 = hero.position + Vector3.UP
	var forward: Vector3 = hero.aim_direction()
	forward.y = 0
	forward = forward.normalized()
	VFX.burst(effects, origin + forward * 1.0, COLORS[color_index], 0.55)
	_broadcast_noise(origin, 7.0)
	for target in get_tree().get_nodes_in_group("targets"):
		var offset: Vector3 = target.position + Vector3.UP - origin
		if offset.length() > 2.3 or offset.normalized().dot(forward) < 0.45:
			continue
		var ray := PhysicsRayQueryParameters3D.create(origin, target.position + Vector3.UP, 5)
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider == target:
			_damage_target(target, 30)
	if not relay_complete and is_instance_valid(relay):
		var relay_offset: Vector3 = relay.position + Vector3.UP - origin
		if relay_offset.length() <= 2.7 and relay_offset.normalized().dot(forward) >= 0.45:
			var relay_ray := PhysicsRayQueryParameters3D.create(origin, relay.position + Vector3.UP, 5)
			var relay_hit := get_world_3d().direct_space_state.intersect_ray(relay_ray)
			if not relay_hit.is_empty() and relay_hit.collider == relay:
				_energize_relay(12.0, "MELEE STRIKE")

func _clear_aura(kind: String) -> void:
	var aura: Node3D = kinetic_aura if kind == "kinetic" else cloak_aura
	if is_instance_valid(aura):
		aura.queue_free()
	if kind == "kinetic":
		kinetic_aura = null
	else:
		cloak_aura = null

func _blink() -> bool:
	var origin: Vector3 = hero.position
	var destination := find_blink_destination(origin, hero.aim_direction(), 8.0)
	if destination.distance_to(origin) < 0.8:
		_message("BLINK BLOCKED  /  Aim toward clear space")
		return false
	hero.position = destination
	hero.velocity = Vector3.ZERO
	VFX.blink(effects, origin, Color("ae9bff"))
	VFX.blink(effects, destination, Color("ae9bff"))
	_broadcast_noise(destination, 5.0)
	_message("BLINK  /  Position shifted")
	return true

func find_blink_destination(origin: Vector3, direction: Vector3, distance: float) -> Vector3:
	var space := get_world_3d().direct_space_state
	# Looking at the ground should still offer useful travel along the floor.
	direction.y = maxf(0, direction.y)
	direction = direction.normalized()
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	query.shape = capsule
	query.collision_mask = 5
	query.exclude = [hero.get_rid()]
	query.transform = Transform3D(Basis.IDENTITY, origin + Vector3.UP * 0.94)
	# Sweep the whole body: a clear endpoint alone could teleport through a wall.
	query.motion = direction.normalized() * distance
	var fractions := space.cast_motion(query)
	var safe_distance := distance * float(fractions[0])
	var candidate := origin + direction.normalized() * maxf(0, safe_distance - 0.08)
	candidate.x = clampf(candidate.x, -20.8, 20.8)
	candidate.z = clampf(candidate.z, -20.8, 20.8)
	candidate.y = maxf(0.05, candidate.y)
	query.motion = Vector3.ZERO
	query.transform.origin = candidate + Vector3.UP * 0.94
	if not space.intersect_shape(query, 1).is_empty():
		return origin
	return candidate

func _grab_prop() -> bool:
	var query := PhysicsRayQueryParameters3D.create(hero.camera.global_position, hero.camera.global_position + hero.aim_direction() * 60, 5)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit.collider.is_in_group("props") or hero.position.distance_to(hit.collider.position) > 12:
		_message("TELEKINESIS  /  Aim at an amber crate within 12 metres")
		return false
	hero.play_attack()
	_clear_aura("kinetic")
	kinetic_aura = VFX.aura(effects, COLORS[color_index], 0.9)
	held_prop = hit.collider
	kinetic_aura.position = held_prop.position
	held_prop.freeze = true
	held_prop.collision_layer = 0
	held_prop.collision_mask = 0
	_message("CRATE HELD  /  Use Telekinesis again to throw")
	return true

func _throw_prop() -> void:
	_clear_aura("kinetic")
	hero.play_attack()
	_reveal()
	var prop := held_prop
	held_prop = null
	prop.collision_layer = 4
	prop.collision_mask = 7
	prop.freeze = false
	prop.set_meta("thrown", true)
	prop.linear_velocity = (hero.aim_point() - prop.position).normalized() * 28
	_broadcast_noise(prop.position, 12.0)
	_message("TELEKINESIS  /  Crate launched")

func _drop_prop() -> void:
	_clear_aura("kinetic")
	if is_instance_valid(held_prop):
		held_prop.collision_layer = 4
		held_prop.collision_mask = 7
		held_prop.freeze = false
		held_prop.linear_velocity = Vector3.ZERO
		held_prop = null

func _damage_target(target: Node3D, amount: float) -> void:
	if target.is_queued_for_deletion():
		return
	var destroyed: bool = target.take_damage(amount, hero.position)
	var remaining: float = target.health
	if destroyed:
		score += 1
		VFX.burst(effects, target.position + Vector3.UP, Color("f6bb66"), 1.5)
		_broadcast_noise(target.position, 18.0, target)
		var shutdown := create_tween()
		shutdown.tween_interval(0.55)
		shutdown.tween_callback(target.queue_free)
		if score == 5:
			_message("ALL FIVE DISABLED  /  Charge the power relay or Esc to change your build", 60)
	else:
		_broadcast_noise(target.position, 16.0, target)
		_message("TARGET HIT  /  %d vitality remaining" % int(remaining))

func _update_sentinels(delta: float) -> void:
	sight_refresh -= delta
	if sight_refresh <= 0:
		sight_refresh = SIGHT_REFRESH_SECONDS
		sight_cache.clear()
		for target in get_tree().get_nodes_in_group("targets"):
			if not target.is_queued_for_deletion():
				sight_cache[target.get_instance_id()] = _sentinel_can_see(target)
	for target in get_tree().get_nodes_in_group("targets"):
		if target.is_queued_for_deletion():
			continue
		target.update_brain(hero, sight_cache.get(target.get_instance_id(), false), delta)

func _sentinel_can_see(target: CharacterBody3D) -> bool:
	if cloak_time > 0 or target.position.distance_to(hero.position) > 18.0:
		return false
	var origin := target.position + Vector3.UP * 1.45
	var destination := hero.position + Vector3.UP
	var ray := PhysicsRayQueryParameters3D.create(origin, destination, 7)
	ray.exclude = [target.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and hit.collider == hero

func _sentinel_projectile(origin: Vector3, destination: Vector3, source: CollisionObject3D) -> void:
	_launch_orb(origin, destination, Color("ff778f"), true, source)

func _sentinel_alerted(position: Vector3, radius: float, source: Node) -> void:
	_broadcast_noise(position, radius, source)

func _broadcast_noise(at: Vector3, radius: float, source: Node = null) -> void:
	for target in get_tree().get_nodes_in_group("targets"):
		if target == source or target.is_queued_for_deletion():
			continue
		target.hear_noise(at, radius)

func _panel_style(color: Color, border: Color = Color("294154")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _label(text: String, size: int, color: Color = Color("e2eaf3")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _panel_style(Color("152638")))
	button.add_theme_stylebox_override("hover", _panel_style(Color("233c4e"), COLORS[0]))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0, 0, 0, 0), Color("f2bb6b")))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("31545d"), COLORS[0]))
	return button

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.035, 0.06, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	menu.add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	margin.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 700
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)
	left.add_child(_label("P R O J E C T   0 0 2     /     P R O T O T Y P E   0 5", 13, COLORS[0]))
	left.add_child(_label("Choose your three powers.", 34))
	left.add_child(_label("Seven powers. Three slots. Build your own combination.", 16, Color("a2b7c9")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	left.add_child(grid)
	for id in POWER_IDS:
		var data: Dictionary = Catalog.POWERS[id]
		var button := _button("")
		button.name = "Choose_" + id
		button.custom_minimum_size.y = 96 if POWER_IDS.size() > 6 else 112
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_toggle_power.bind(id))
		button.tooltip_text = data.name + ": " + data.description
		grid.add_child(button)
		power_buttons[id] = button
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 14
		content.offset_right = -14
		content.offset_top = 10
		content.offset_bottom = -10
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", 3)
		button.add_child(content)
		var title := _label("", 19)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(title)
		power_titles[id] = title
		var cost := _label("%d energy  ·  %.1fs cooldown" % [int(data.cost), float(data.cooldown)], 12, Color("91a9bc"))
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(cost)
		var description := _label(data.description, 13, Color("b7c9d7"))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(description)
	left.add_child(_label("YOUR LOADOUT  /  Assigned in the order you choose", 13, COLORS[0]))
	var preview := HBoxContainer.new()
	preview.add_theme_constant_override("separation", 8)
	left.add_child(preview)
	for slot in range(3):
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _panel_style(Color("102331")))
		preview.add_child(panel)
		var label := _label("", 13)
		panel.add_child(label)
		build_slots.append(label)
	status_label = _label("", 13, Color("f2bb6b"))
	left.add_child(status_label)
	start_button = _button("Enter the playground   →")
	start_button.custom_minimum_size.y = 44
	start_button.pressed.connect(start_play)
	left.add_child(start_button)
	var reset_button := _button("Reset arena & restore hero")
	reset_button.pressed.connect(func():
		reset_arena()
		_update_loadout_ui()
	)
	left.add_child(reset_button)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 18)
	columns.add_child(right)
	right.add_child(_label("H E R O   L A B", 30, COLORS[0]))
	right.add_child(_label("A place to discover your build.", 18))
	right.add_child(_label("SIGNATURE COLOR", 13, COLORS[0]))
	var colors := HBoxContainer.new()
	colors.add_theme_constant_override("separation", 6)
	right.add_child(colors)
	var names := ["Jade", "Solar", "Violet", "Coral"]
	for i in range(COLORS.size()):
		var button := _button(names[i])
		button.modulate = COLORS[i]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func():
			color_index = i
			hero.set_appearance(COLORS[i], cloak_time > 0)
		)
		colors.add_child(button)
	var description := _label("Choose exactly three powers before entering.\nClick a selected power to remove it.\n\nTry Shield + Shockwave + Blink to close the gap, protect yourself, and hit a group.", 17, Color("a2b7c9"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(description)
	right.add_child(_label("FIELD CONTROLS", 13, COLORS[0]))
	right.add_child(_label("W A S D     Move\nMouse        Look & aim\nSpace          Jump\nShift             Sprint\n1 / 2 / 3      Use equipped power\nLeft click    Use first power\nF                   Melee punch\nEsc               Edit build / pause", 18))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)
	var note := _label("EARLY PLAYABLE\nAnimated rig · textured training arena.\nYour selections last for this session.", 14, Color("7d93aa"))
	right.add_child(note)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var header := VBoxContainer.new()
	header.position = Vector2(28, 24)
	header.add_theme_constant_override("separation", 8)
	hud.add_child(header)
	header.add_child(_label("HERO LAB   /   POWER PLAYGROUND", 18, COLORS[0]))
	score_label = _label("", 15)
	header.add_child(score_label)
	header.add_child(_label("ENERGY", 11, Color("9bb0c2")))
	energy_bar = _bar(COLORS[color_index])
	header.add_child(energy_bar)
	header.add_child(_label("VITALITY", 11, Color("9bb0c2")))
	health_bar = _bar(Color("ed6d82"))
	header.add_child(health_bar)
	var help := _label("ESC  Build / pause    •    F  Punch    •    SHIFT  Sprint", 14, Color("b9c8d8"))
	help.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	help.position = Vector2(-490, 28)
	hud.add_child(help)
	var crosshair := _label("+", 28, Color.WHITE)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-9, -20)
	hud.add_child(crosshair)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.position = Vector2(-410, -112)
	bottom.custom_minimum_size.x = 820
	bottom.add_theme_constant_override("separation", 12)
	hud.add_child(bottom)
	notice = _label("", 15, Color("f2bb6b"))
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(notice)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 12)
	bottom.add_child(slots)
	for i in range(3):
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _panel_style(Color("101e30")))
		slots.add_child(panel)
		var label := _label("", 15)
		panel.add_child(label)
		slot_labels.append(label)

func _bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(250, 8)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _panel_style(Color("142339")))
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _toggle_power(id: String) -> void:
	if not Catalog.POWERS.has(id):
		return
	if loadout.has(id):
		loadout.erase(id)
		if id == "shield":
			_end_shield()
		elif id == "cloak":
			_reveal()
	elif loadout.size() < Catalog.SLOT_COUNT:
		loadout.append(id)
	else:
		status_label.text = "Remove one selected power to make room for another."
		return
	_update_loadout_ui()

func _update_loadout_ui() -> void:
	for id in POWER_IDS:
		var slot := loadout.find(id)
		var data: Dictionary = Catalog.POWERS[id]
		power_titles[id].text = "%s  %s" % ["[%d]" % (slot + 1) if slot >= 0 else "[ + ]", data.name]
		power_titles[id].add_theme_color_override("font_color", COLORS[0] if slot >= 0 else Color("dce7ef"))
		power_buttons[id].add_theme_stylebox_override("normal", _panel_style(Color("193e43") if slot >= 0 else Color("152638"), COLORS[0] if slot >= 0 else Color("294154")))
	for slot in range(build_slots.size()):
		build_slots[slot].text = "[%d]  %s" % [slot + 1, Catalog.POWERS[loadout[slot]].name if slot < loadout.size() else "Choose a power"]
	start_button.disabled = not Catalog.validate_loadout(loadout) or health <= 0
	status_label.text = "%d / 3 selected  ·  %s" % [loadout.size(), "Ready. Your selection order sets keys 1, 2, 3." if loadout.size() == 3 else "Choose exactly three powers to enter."]

func show_menu() -> void:
	running = false
	hero.enabled = false
	hero.visual.set_frozen(true)
	effects.process_mode = Node.PROCESS_MODE_DISABLED
	for target in get_tree().get_nodes_in_group("targets"):
		target.set_frozen(true)
	_drop_prop()
	for prop in get_tree().get_nodes_in_group("props"):
		prop.freeze = true
	menu.show()
	hud.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_loadout_ui()
	if start_button.disabled:
		power_buttons[POWER_IDS[0]].grab_focus()
	else:
		start_button.grab_focus()

func start_play() -> void:
	if not Catalog.validate_loadout(loadout) or health <= 0:
		return
	for prop in get_tree().get_nodes_in_group("props"):
		prop.freeze = false
	running = true
	effects.process_mode = Node.PROCESS_MODE_INHERIT
	hero.visual.set_frozen(false)
	for target in get_tree().get_nodes_in_group("targets"):
		target.set_frozen(false)
	hero.enabled = true
	menu.hide()
	hud.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_message("DISABLE FIVE SENTINELS  /  Collect cells and charge the power relay.", 6)

func _message(text: String, duration: float = 3.0) -> void:
	notice.text = text
	notice_time = duration

func _update_hud() -> void:
	if not is_instance_valid(energy_bar):
		return
	energy_bar.value = energy
	health_bar.value = health
	score_label.text = "%d / 5 SENTINELS DISABLED   ·   RELAY %s   ·   CELLS %d / %d%s" % [score, "ONLINE" if relay_complete else "%d%%" % int(relay_charge), pickups_collected, pickup_total, "   ·   CLOAKED %.1fs" % cloak_time if cloak_time > 0 else ""]
	if shield_time > 0:
		score_label.text += "   ·   SHIELD %.1fs" % shield_time
	for i in range(slot_labels.size()):
		if i >= loadout.size():
			slot_labels[i].text = "Empty slot"
			continue
		var id: String = loadout[i]
		var remaining: float = cooldowns.get(id, 0)
		var state := "READY" if remaining <= 0 else "%.1fs" % remaining
		if id == "kinetic" and is_instance_valid(held_prop):
			state = "THROW"
		elif id == "shield" and shield_time > 0:
			state = "PROTECTED %.1fs" % shield_time
		slot_labels[i].text = "[%d]  %s\n%s" % [i + 1, Catalog.POWERS[id].name, state]
