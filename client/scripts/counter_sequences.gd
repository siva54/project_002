extends RefCounted

const Catalog := preload("res://scripts/combat_moves.gd")
const CONTACTS := [0.34, 0.68, 1.16]
const STARTS := [0.12, 0.46, 0.88]
const ENDS := [0.52, 0.94, 1.62]
const DAMAGE := [15.0, 20.0, 65.0]
const LANDING := 1.64
const FALL_END := 1.92
const DURATION := 2.08
const HAND_MOVES := ["BodyPunch", "Elbow", "LowKick"]
const KICK_MOVES := ["Knee", "Backfist", "SideKick"]

static func attack(kind: String, index: int) -> Dictionary:
	var names: Array = KICK_MOVES if kind == "kick_counter" else HAND_MOVES
	var data: Dictionary = Catalog.MOVES[names[index]].duplicate()
	data.rate *= data.contact / (CONTACTS[index] - STARTS[index])
	data.contact = CONTACTS[index] - STARTS[index]
	data.duration = ENDS[index] - STARTS[index]
	data.damage = DAMAGE[index]
	return data

static func stage_at(time: float) -> int:
	var stage := 0
	for contact in CONTACTS:
		if time >= contact:
			stage += 1
	return stage
