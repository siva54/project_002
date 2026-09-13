extends RefCounted

const SLOT_COUNT := 3
const MAX_ENERGY := 100.0
const REGEN_PER_SECOND := 16.0
const POWER_IDS := ["bolt", "blink", "kinetic", "cloak", "shockwave", "shield"]
const SHOCKWAVE_RADIUS := 6.0
const SHOCKWAVE_DAMAGE := 30.0
const SHIELD_DURATION := 5.0
const POWERS := {
	"bolt": {"name": "Energy Bolt", "cost": 12.0, "cooldown": 0.55, "description": "Cast a traveling energy orb. Strike a target or launch a crate."},
	"blink": {"name": "Blink", "cost": 25.0, "cooldown": 1.2, "description": "Teleport up to 8 metres toward your aim. Solid obstacles stop the jump."},
	"kinetic": {"name": "Telekinesis", "cost": 18.0, "cooldown": 0.5, "description": "Aim at a crate to lift it. Use again to throw it at a target."},
	"cloak": {"name": "Cloak", "cost": 30.0, "cooldown": 6.0, "description": "Conceal yourself for 5 seconds. Attacking reveals you."},
	"shockwave": {"name": "Shockwave", "cost": 35.0, "cooldown": 3.0, "description": "Damage exposed enemies within 6 metres and fling crates outward."},
	"shield": {"name": "Energy Shield", "cost": 30.0, "cooldown": 8.0, "description": "Block incoming energy attacks for 5 seconds. Keep moving and attacking."},
}

static func validate_loadout(ids: Array) -> bool:
	if ids.size() != SLOT_COUNT:
		return false
	var unique: Dictionary = {}
	for id in ids:
		if not POWERS.has(id) or unique.has(id):
			return false
		unique[id] = true
	return true

static func can_activate(id: String, energy: float, cooldown: float) -> bool:
	return POWERS.has(id) and energy >= float(POWERS[id].cost) and cooldown <= 0.0
