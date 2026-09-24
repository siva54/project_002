extends RefCounted

# Times are simulation seconds. Every strike has its own contact, recovery link,
# limb trajectory and reaction; input branches are independent of animation names.
const MOVES := {
	"Jab": {"label": "JAB", "clip": "MocapJab", "rate": 1.08, "contact": 0.2, "link": 0.3, "duration": 0.45, "damage": 9.0, "bone": "LeftHand", "shape": "straight", "side": "Left", "height": 1.36, "spacing": 0.66, "reaction": "head", "cost": 3.0, "captured": true},
	"Cross": {"label": "CROSS", "clip": "MocapCross", "rate": 1.08, "contact": 0.2315, "link": 0.35, "duration": 0.51, "damage": 12.0, "bone": "RightHand", "shape": "straight", "side": "Right", "height": 1.38, "spacing": 0.64, "reaction": "head", "cost": 4.0, "captured": true},
	"LeadHook": {"label": "LEAD HOOK", "clip": "MocapLeadHook", "rate": 1.05, "contact": 0.214, "link": 0.35, "duration": 0.52, "damage": 14.0, "bone": "LeftHand", "shape": "hook", "side": "Left", "height": 1.36, "spacing": 0.65, "reaction": "left", "cost": 5.0, "captured": true},
	"RearHook": {"label": "REAR HOOK", "clip": "MocapRearHook", "rate": 1.0, "contact": 0.2, "link": 0.32, "duration": 0.47, "damage": 17.0, "bone": "RightHand", "shape": "hook", "side": "Right", "height": 1.36, "spacing": 0.65, "reaction": "right", "cost": 6.0, "captured": true},
	"BodyPunch": {"label": "SHOVEL HOOK", "clip": "MocapUppercut", "rate": 1.1, "contact": 0.165, "link": 0.34, "duration": 0.48, "damage": 12.0, "bone": "RightHand", "shape": "body", "side": "Right", "height": 1.06, "spacing": 0.63, "reaction": "body", "cost": 4.0, "captured": true},
	"Uppercut": {"label": "RISING UPPERCUT", "clip": "MocapUppercut", "rate": 1.05, "contact": 0.25, "link": 0.37, "duration": 0.5, "damage": 20.0, "bone": "RightHand", "shape": "uppercut", "side": "Right", "height": 1.4, "spacing": 0.64, "reaction": "head", "cost": 8.0, "captured": true},
	"Backfist": {"label": "CRANE STRAIGHT", "clip": "KarateStraight", "rate": 1.6, "contact": 0.448, "link": 0.56, "duration": 0.64, "damage": 18.0, "bone": "RightHand", "shape": "straight", "side": "Right", "height": 1.32, "spacing": 0.66, "reaction": "body", "cost": 7.0, "captured": true},
	"Elbow": {"label": "CLOSE ELBOW", "clip": "MocapRearHook", "rate": 0.91, "preserve_body": true, "contact": 0.22, "link": 0.36, "duration": 0.55, "damage": 19.0, "bone": "RightForeArm", "shape": "elbow", "side": "Right", "height": 1.30, "spacing": 0.60, "reaction": "left", "cost": 7.0},
	"LungePunch": {"label": "STEPPING KARATE STRAIGHT", "clip": "Lunge", "rate": 1.15, "contact": 0.261, "link": 0.43, "duration": 0.56, "damage": 17.0, "bone": "RightHand", "shape": "straight", "side": "Right", "height": 1.23, "spacing": 0.7, "reaction": "body", "cost": 6.0, "captured": true},
	"FrontKick": {"label": "FRONT KICK", "clip": "FrontKick", "rate": 1.45, "contact": 0.368, "link": 0.77, "duration": 0.98, "damage": 17.0, "bone": "LeftFoot", "shape": "front_kick", "side": "Left", "height": 1.05, "spacing": 0.88, "reaction": "body", "cost": 7.0, "captured": true},
	"LowKick": {"label": "LOW ROUND KICK", "clip": "Roundhouse", "rate": 2.4, "contact": 0.23, "link": 0.37, "duration": 0.60, "damage": 13.0, "bone": "RightFoot", "shape": "low_kick", "side": "Right", "height": 0.43, "spacing": 0.93, "reaction": "leg", "cost": 5.0},
	"Roundhouse": {"label": "HIGH ROUNDHOUSE", "clip": "Roundhouse", "rate": 1.65, "contact": 0.243, "link": 0.68, "duration": 0.86, "damage": 23.0, "bone": "RightFoot", "shape": "round_kick", "side": "Right", "height": 1.3, "spacing": 0.96, "reaction": "right", "cost": 9.0, "captured": true},
	"SideKick": {"label": "SIDE KICK", "clip": "SideKick", "rate": 1.4, "contact": 0.274, "link": 0.67, "duration": 0.84, "damage": 24.0, "bone": "RightFoot", "shape": "side_kick", "side": "Right", "height": 1.05, "spacing": 1.02, "reaction": "body", "cost": 10.0, "captured": true},
	"Knee": {"label": "DRIVING KNEE", "clip": "FrontKick", "rate": 1.3, "preserve_body": true, "contact": 0.26, "link": 0.41, "duration": 0.62, "damage": 20.0, "bone": "LeftLeg", "shape": "knee", "side": "Left", "height": 0.98, "spacing": 0.60, "reaction": "body", "cost": 8.0},
}

# A mixed input sequence deliberately takes a different route from repeated punches.
const PUNCH_NEXT := {"Jab": "Cross", "Cross": "LeadHook", "LeadHook": "RearHook", "RearHook": "Uppercut", "Uppercut": "Backfist", "Backfist": "Elbow", "Elbow": "Jab", "BodyPunch": "Uppercut", "LowKick": "BodyPunch", "FrontKick": "Cross", "Roundhouse": "Backfist", "SideKick": "LungePunch", "Knee": "Elbow", "LungePunch": "LeadHook"}
const KICK_NEXT := {"Jab": "LowKick", "Cross": "Knee", "LeadHook": "Roundhouse", "RearHook": "SideKick", "Uppercut": "FrontKick", "Backfist": "Roundhouse", "Elbow": "Knee", "BodyPunch": "LowKick", "LowKick": "Roundhouse", "FrontKick": "SideKick", "Roundhouse": "FrontKick", "SideKick": "LowKick", "Knee": "SideKick", "LungePunch": "FrontKick"}

static func next_move(previous: String, kind: String, moving: bool) -> String:
	if kind == "heavy" or kind == "kick":
		return KICK_NEXT.get(previous, "FrontKick")
	return PUNCH_NEXT.get(previous, "LungePunch" if moving else "Jab")
