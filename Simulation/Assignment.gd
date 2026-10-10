extends RefCounted
## Public reactions describe communication; private commitment governs follow-through.
const RESPONSES := ["enthusiastic", "willing", "reluctant", "refused"]

static func resolve(person, score: float, action: String, activity_id: String = "", self_directed: bool = false) -> Dictionary:
	var private_response := "enthusiastic" if score >= .6 else ("willing" if score >= .3 else ("reluctant" if score >= .12 else "refused"))
	var communicated := private_response
	if private_response == "reluctant" and person.learned_tendencies["conflict_avoidance"] >= .7 and person.values["family_loyalty"] >= .6:
		communicated = "willing"
	var dialogue: String = {
		"enthusiastic": "Yes! I have been hoping for a chance to %s.",
		"willing": "Of course. I will %s.",
		"reluctant": "I will %s, for the family's sake. But this is not what I wanted.",
		"refused": "No. I do not want to %s. I have plans of my own.",
	}[communicated] % action
	if self_directed: dialogue = "You begin to %s." % action
	return {"ok": private_response != "refused", "accepted": private_response != "refused", "action_response": communicated,
		"dialogue_key": "assignment." + communicated, "response": dialogue, "activity_id": activity_id if private_response != "refused" else "",
		"outcome": "accepted" if private_response in ["enthusiastic", "willing"] else private_response,
		"agreement": {"private_response": private_response, "communicated_response": communicated}}

static func unavailable(message: String) -> Dictionary:
	return {"ok": false, "accepted": false, "action_response": "unavailable", "dialogue_key": "assignment.unavailable", "response": message, "activity_id": "", "outcome": "unavailable"}

static func progress(person, agreement: Dictionary) -> float:
	if agreement.get("private_response") != "reluctant": return 1.0
	person.current_state["resentment"] = minf(1.0, float(person.current_state.get("resentment", 0)) + .015)
	person.current_state["stress"] = minf(1.0, float(person.current_state.get("stress", 0)) + .02)
	return .7

static func abandons(person, agreement: Dictionary) -> bool:
	return agreement.get("private_response") == "reluctant" and (float(person.current_state.get("resentment", 0)) >= .8 or (float(person.current_state.get("stress", 0)) >= .9 and float(person.values["independence"]) >= .6))

static func valid(agreement: Variant) -> bool:
	return agreement is Dictionary and (agreement.is_empty() or (agreement.get("private_response") in RESPONSES and agreement.get("communicated_response") in RESPONSES))
