extends RefCounted
## Shared time builds observer-specific beliefs; reports remain secondhand.
const Assignment = preload("res://Simulation/Assignment.gd")
const KINDS := {"work": "Household work together", "social": "Spend social time together"}
const TRAITS := {
	"temperament.conscientiousness": ["Often leaves tasks unfinished", "Works steadily", "Methodical and persistent"],
	"temperament.agreeableness": ["Challenges others readily", "Balances compromise and firmness", "Often seeks compromise"],
	"temperament.extraversion": ["Prefers quiet company", "Enjoys company and solitude", "Seeks out company"],
	"temperament.openness": ["Prefers familiar routines", "Sometimes tries new approaches", "Curious about new experiences"],
	"values.family_loyalty": ["Family duties are not their first priority", "Balances family with other priorities", "Strongly values family loyalty"],
	"values.independence": ["Comfortable relying on family", "Values some independence", "Strongly values independence"],
	"values.security": ["Tolerates uncertainty", "Values some stability", "Strongly values security"],
	"learned_tendencies.risk_tolerance": ["Usually avoids risks", "Takes considered risks", "Comfortable taking risks"],
}
const CONTEXTS := {
	"home": ["values.family_loyalty", "values.security", "temperament.agreeableness"],
	"work": ["temperament.conscientiousness", "learned_tendencies.risk_tolerance", "temperament.agreeableness"],
	"social": ["temperament.extraversion", "temperament.openness", "values.independence", "values.family_loyalty"],
	"conversation": ["values.independence", "values.security", "temperament.openness"],
}
var plans: Dictionary = {}
var next_id := 1
var last_reports: Dictionary = {}

func commitment(person_id: String) -> Dictionary:
	for plan in plans.values():
		if person_id in plan["participants"] and plan["status"] in ["active", "interrupted"]:
			return plan
	return {}

func available(state, id: String) -> bool:
	return state.people.has(id) and state.people[id].alive and id in state.household["members"] and state.travel.current(id).is_empty()

func reason(state, first: String, second: String, kind: String) -> String:
	if state.succession.pending or state.succession.ended:
		return "Choose the next family head first."
	if not KINDS.has(kind) or first == second:
		return "Choose two different relatives and an activity."
	for id in [first, second]:
		if not available(state, id): return "Both people need to be home."
		var person = state.people[id]
		if person.age < (18 if kind == "work" else 6): return "Household work needs adults; social time is available from age six."
		if person.age < 18 and state.head_id not in person.parent_ids: return "Their parent must arrange a child's shared time."
		if not commitment(id).is_empty(): return person.name + " already has shared time planned."
		if not person.life_state.get("illness", {}).is_empty(): return person.name + " needs time to recover."
		if kind == "work" and (state.activities.commitment(id) != null or not person.education["study"].is_empty() or not state.village.business.commitment(id).is_empty()):
			return person.name + " has another responsibility taking priority."
		if id != state.head_id and state.last_requests.get(id, -1) == state.elapsed_months: return person.name + " has already considered a request this month."
	return ""

func propose(state, first: String, second: String, kind: String) -> Dictionary:
	var blocked := reason(state, first, second, kind)
	if not blocked.is_empty(): return Assignment.unavailable(blocked)
	var agreements: Dictionary = {}
	var replies: Array[String] = []
	var accepted := true
	var result: Dictionary = {}
	var public_response := "enthusiastic"
	# Ask both, including the second person when the first refuses; no work begins
	# unless both agree. Their responses and request cooldowns remain meaningful.
	for id in [first, second]:
		var person = state.people[id]
		var partner = state.people[second if id == first else first]
		var bond: Dictionary = person.relationships.get(state.head_id, {})
		var rapport: Dictionary = person.relationships.get(partner.id, {})
		var interest: float = person.interests["practical" if kind == "work" else "social"] / 100.0
		var score: float = 0.25 + interest * 0.25 + person.values["family_loyalty"] * 0.2 + float(bond.get("trust", 0.4)) * 0.15 + float(rapport.get("affection", 0.4)) * 0.15
		score -= person.current_state["resentment"] * 0.4 + person.current_state["stress"] * 0.2 + person.learned_tendencies["need_for_autonomy"] * 0.15
		if id == state.head_id: score = 1.0
		result = Assignment.resolve(person, score, KINDS[kind].to_lower() + " with " + partner.name, "", id == state.head_id)
		if id != state.head_id: state.last_requests[id] = state.elapsed_months
		accepted = accepted and result["accepted"]
		if Assignment.RESPONSES.find(result["action_response"]) > Assignment.RESPONSES.find(public_response): public_response = result["action_response"]
		agreements[id] = result["agreement"].duplicate(true)
		replies.append(person.name + ": " + result["response"])
		person.memories.append({"date": state.date_text(), "kind": "shared_time", "participants": [first, second, state.head_id], "description": replies.back()})
	result["accepted"] = accepted
	result["ok"] = accepted
	result["response"] = "\n".join(replies)
	result["action_response"] = public_response
	state.chronicle.append({"date": state.date_text(), "description": result["response"], "category": "project", "person_id": first, "participant_ids": [first, second]})
	if not accepted:
		result["action_response"] = "refused"
		result["outcome"] = "refused"
		return result
	var id := "shared_%d" % next_id
	next_id += 1
	plans[id] = {"id": id, "participants": [first, second], "kind": kind, "status": "active", "months": 0.0, "agreements": agreements, "reason": ""}
	result["activity_id"] = id
	return result

func cancel(state, id: String) -> void:
	if plans.has(id) and plans[id]["status"] in ["active", "interrupted"]:
		plans[id]["status"] = "cancelled"
		_record(state, plans[id], "Shared time cancelled.")

func _record(state, plan: Dictionary, description: String) -> void:
	var pair: Array = plan["participants"]
	var names: String = state.people[pair[0]].name + " and " + state.people[pair[1]].name
	state.chronicle.append({"date": state.date_text(), "description": names + " · " + description, "category": "project", "person_id": pair[0], "participant_ids": pair.duplicate()})
	state.notify(names + " · " + description, pair[0])

func understanding(person, observer: String) -> Dictionary:
	if not person.knowledge.has(observer): person.knowledge[observer] = {}
	var known: Dictionary = person.knowledge[observer]
	for layer in person.LAYERS:
		if not known.has(layer): known[layer] = {"known": [], "suspected": [], "unknown": []}
	for field in ["evidence", "experiences"]:
		if not known.has(field): known[field] = []
	if not known.has("social_observations"): known["social_observations"] = {}
	return known

func observe(state, subject_id: String, observer_id: String, context: String, points: float) -> void:
	if subject_id == observer_id: return
	var subject = state.people[subject_id]
	var known := understanding(subject, observer_id)
	var records: Dictionary = known["social_observations"]
	for key in CONTEXTS[context]:
		var record: Dictionary = records.get(key, {"points": 0.0, "finding": ""})
		if record["points"] >= 6.0: continue
		var parts: PackedStringArray = key.split(".")
		var score: float = subject.get(parts[0])[parts[1]]
		var finding: String = TRAITS[key][0 if score < 0.34 else (2 if score > 0.66 else 1)]
		var old_points: float = record["points"]
		record["points"] = minf(6.0, old_points + points)
		record["finding"] = finding
		records[key] = record
		var layer: Dictionary = known[parts[0]]
		if record["points"] >= 6.0 and finding not in layer["known"]:
			layer["suspected"].erase(finding)
			layer["known"].append(finding)
			_evidence(state, subject, observer_id, "Repeated " + context + " time: " + finding + ".")
		elif record["points"] >= 2.0 and finding not in layer["known"] and finding not in layer["suspected"]:
			layer["suspected"].append(finding)
			_evidence(state, subject, observer_id, "From " + context + " time, you suspect: " + finding + ".")
		return

func _evidence(state, subject, observer: String, description: String) -> void:
	understanding(subject, observer)["evidence"].append(state.date_text() + " — " + description)
	if observer == state.head_id: state.notify("You learned about " + subject.name + ": " + description, subject.id)

func advance_month(state) -> void:
	var residents: Array = []
	for id in state.household["members"]:
		if available(state, id) and state.people[id].age >= 6: residents.append(id)
	for observer in residents:
		for subject in residents:
			if observer == subject: continue
			observe(state, subject, observer, "home", 0.25)
			var first = state.people[observer]
			var second = state.people[subject]
			# Only the family farm is a shared workplace; matching job titles alone
			# do not prove that two relatives work together.
			if first.career_id in ["farmer", "farm_laborer", "farm_manager"] and second.career_id in ["farmer", "farm_laborer", "farm_manager"] and first.monthly_income_cents > 0 and second.monthly_income_cents > 0 and first.education["study"].is_empty() and second.education["study"].is_empty() and first.life_state.get("illness", {}).is_empty() and second.life_state.get("illness", {}).is_empty():
				observe(state, subject, observer, "work", 0.5)
	for plan in plans.values():
		if plan["status"] not in ["active", "interrupted"]: continue
		var pair: Array = plan["participants"]
		if not available(state, pair[0]) or not available(state, pair[1]):
			plan["status"] = "cancelled"
			plan["reason"] = "A participant is no longer at home."
			_record(state, plan, "Shared time ended: a participant is no longer at home.")
			continue
		var interrupted := false
		for id in pair:
			var person = state.people[id]
			if not person.life_state.get("illness", {}).is_empty() or state.events.needs_family_care(state, person, true): interrupted = true
			if plan["kind"] == "work" and (state.activities.commitment(id) != null or not person.education["study"].is_empty() or not state.village.business.commitment(id).is_empty()): interrupted = true
		if interrupted:
			if plan["status"] != "interrupted": _record(state, plan, "Shared time interrupted by recovery or another responsibility.")
			plan["status"] = "interrupted"
			plan["reason"] = "Recovery or another responsibility needs their time."
			continue
		var abandoned := false
		for id in pair:
			if Assignment.abandons(state.people[id], plan["agreements"][id]): abandoned = true
		if abandoned:
			plan["status"] = "cancelled"
			_record(state, plan, "A relative stopped taking part in shared time.")
			continue
		if plan["status"] == "interrupted": _record(state, plan, "Shared time resumed.")
		plan["status"] = "active"
		plan["reason"] = ""
		var progress := 1.0
		for id in pair:
			progress = minf(progress, Assignment.progress(state.people[id], plan["agreements"][id]))
		if plan["kind"] == "social":
			for id in pair:
				var partner_id: String = pair[1] if id == pair[0] else pair[0]
				var person = state.people[id]
				if not person.relationships.has(partner_id): person.relationships[partner_id] = {"trust": 0.4, "affection": 0.4, "respect": 0.4, "resentment": 0.0}
				var bond: Dictionary = person.relationships[partner_id]
				bond["affection"] = minf(1.0, float(bond.get("affection", 0.4)) + 0.01 * progress)
		plan["months"] = minf(3.0, plan["months"] + progress)
		observe(state, pair[0], pair[1], plan["kind"], 2.0 * progress)
		observe(state, pair[1], pair[0], plan["kind"], 2.0 * progress)
		if plan["months"] >= 3:
			plan["status"] = "completed"
			if plan["kind"] == "work": state.household["condition"] = mini(100, state.household["condition"] + 3)
			_record(state, plan, "Finished three months of shared " + plan["kind"] + " time.")

func ask_about(state, reporter_id: String, subject_id: String) -> String:
	if reporter_id == state.head_id or reporter_id == subject_id or subject_id == state.head_id or not state.people.has(subject_id): return "Choose a relative to ask about someone else."
	if not available(state, reporter_id) or state.succession.pending or state.succession.ended: return "They are not available to talk now."
	var cooldown: String = state.head_id + ":" + reporter_id
	if last_reports.get(cooldown, -1) == state.elapsed_months: return "You already asked them for their impressions this month."
	last_reports[cooldown] = state.elapsed_months
	var reporter = state.people[reporter_id]
	var subject = state.people[subject_id]
	var bond: Dictionary = reporter.relationships.get(state.head_id, {})
	if float(bond.get("trust", 0.4)) < 0.2 or reporter.current_state["resentment"] > 0.8: return reporter.name + " does not want to confide in you."
	var source: Dictionary = subject.knowledge.get(reporter_id, {})
	var destination := understanding(subject, state.head_id)
	for layer_id in ["temperament", "values", "learned_tendencies"]:
		var layer: Dictionary = source.get(layer_id, {})
		for certainty in ["known", "suspected"]:
			for finding in layer.get(certainty, []):
				if finding in destination[layer_id]["known"] or finding in destination[layer_id]["suspected"]: continue
				destination[layer_id]["suspected"].append(finding)
				var reply: String = reporter.name + " says of " + subject.name + ": “" + finding + ".” This is their impression, not yet confirmed by you."
				destination["evidence"].append(state.date_text() + " — " + reply)
				reporter.memories.append({"date": state.date_text(), "kind": "conversation", "participants": [state.head_id, subject_id], "description": reply})
				return reply
	return reporter.name + " has no new impressions of " + subject.name + " to share."

func to_save_data() -> Dictionary:
	return {"plans": plans.duplicate(true), "next_id": next_id, "last_reports": last_reports.duplicate()}

func restore_save_data(data: Dictionary) -> void:
	plans = data.get("plans", {}).duplicate(true)
	next_id = data.get("next_id", 1)
	last_reports = data.get("last_reports", {}).duplicate()

static func valid(data: Dictionary, people: Dictionary, month: int) -> bool:
	if not data.get("plans") is Dictionary or not data.get("last_reports") is Dictionary or not data.get("next_id") is int or data["next_id"] < 1: return false
	var occupied: Dictionary = {}
	for id in data["plans"]:
		var plan: Variant = data["plans"][id]
		if not plan is Dictionary or not plan.get("participants") is Array or plan["participants"].size() != 2 or not plan.get("agreements") is Dictionary: return false
		if not id is String or not id.begins_with("shared_") or not id.trim_prefix("shared_").is_valid_int() or int(id.trim_prefix("shared_")) < 1 or int(id.trim_prefix("shared_")) >= data["next_id"]: return false
		if plan.get("id") != id or plan.get("kind") not in KINDS or plan.get("status") not in ["active", "interrupted", "cancelled", "completed"] or not plan.get("reason") is String: return false
		var progress: Variant = plan.get("months")
		if not (progress is int or progress is float) or not is_finite(progress) or progress < 0 or progress > 3: return false
		if plan["participants"][0] == plan["participants"][1]: return false
		for person_id in plan["participants"]:
			if not person_id is String or not people.has(person_id) or not Assignment.valid(plan["agreements"].get(person_id, null)): return false
			if plan["status"] in ["active", "interrupted"]:
				if occupied.has(person_id): return false
				occupied[person_id] = true
	for value in data["last_reports"].values():
		if not value is int or value < 0 or value > month: return false
	return true

static func valid_knowledge(knowledge: Variant) -> bool:
	if not knowledge is Dictionary: return false
	for observer in knowledge.values():
		if not observer is Dictionary: return false
		for layer_id in ["temperament", "values", "learned_tendencies", "current_state"]:
			var layer: Variant = observer.get(layer_id)
			if not layer is Dictionary: return false
			for certainty in ["known", "suspected", "unknown"]:
				if not layer.get(certainty) is Array: return false
				for finding in layer[certainty]:
					if not finding is String: return false
		for field in ["evidence", "experiences"]:
			if not observer.get(field) is Array: return false
		var observations: Variant = observer.get("social_observations", {})
		if not observations is Dictionary: return false
		for key in observations:
			var record: Variant = observations[key]
			if key not in TRAITS or not record is Dictionary or not record.get("finding") is String: return false
			var points: Variant = record.get("points")
			if not (points is float or points is int) or not is_finite(points) or points < 0 or points > 6: return false
	return true
