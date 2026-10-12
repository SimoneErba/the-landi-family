extends RefCounted
## First monthly activity slice: consent, one commitment, funding and interruption.

const Assignment = preload("res://Simulation/Assignment.gd")
const Plan = preload("res://Simulation/Activities/ActivityPlan.gd")
const CATALOG := {
	"study": {"name": "Independent study", "months": 6, "cost": 300, "interest": "academic", "location": "school", "description": "Practice literacy for six months. Improves skills without awarding a qualification."},
	"repair": {"name": "Repair the family house", "months": 4, "cost": 500, "interest": "practical", "location": "home", "description": "Repair the house over four months. Completion restores 15 condition."},
	"visit": {"name": "Build village ties", "months": 3, "cost": 300, "interest": "social", "location": "tavern", "description": "Visit a neighboring family for three months. Their response depends on rapport and your representative's persuasion."},
}
var plans: Dictionary = {}
var next_id: int = 1


func commitment(person_id: String):
	for plan in plans.values():
		if person_id in plan.accepted_participant_ids and (plan.status in ["active", "interrupted"] or (plan.status == "paused" and plan.started_month >= 0)):
			return plan
	return null


func reason(state, person_id: String, activity_id: String, target_id: String = "") -> String:
	if not CATALOG.has(activity_id) or not state.people.has(person_id):
		return "This activity is unavailable."
	if not state.people.has(state.head_id) or not state.people[state.head_id].alive:
		return "A living family head must propose the activity."
	var person = state.people[person_id]
	if not person.alive or person_id not in state.household["members"]:
		return "A living resident must take part."
	if person.age < 18:
		return "These activities need an adult representative."
	if not state.travel.current(person_id).is_empty():
		return "They are away on a journey."
	if commitment(person_id) != null:
		return "They already have a family activity."
	if not state.village.business.commitment(person_id).is_empty():
		return "Release their business responsibility first."
	if not person.education["study"].is_empty():
		return "Their current course needs their time."
	if not person.life_state.get("illness", {}).is_empty():
		return "They need time to recover."
	if state.events.needs_family_care(state,person):
		return "They need time for childbirth and family care."
	if person_id != state.head_id and state.last_requests.get(person_id, -1) == state.elapsed_months:
		return "You have already made a request this month."
	if activity_id == "visit" and not state.village.households.has(target_id):
		return "Choose a neighboring family."
	if state.economy.cash_cents < state.economy.purchase_cost(CATALOG[activity_id]["cost"]):
		return "The shared purse cannot cover the first month."
	return ""


func propose(state, person_id: String, activity_id: String, target_id: String = "") -> Dictionary:
	var unavailable := reason(state, person_id, activity_id, target_id)
	if not unavailable.is_empty():
		return Assignment.unavailable(unavailable)
	var person = state.people[person_id]
	var entry: Dictionary = CATALOG[activity_id]
	var score := 1.0
	if person_id != state.head_id:
		state.last_requests[person_id] = state.elapsed_months
		var bond: Dictionary = person.relationships.get(state.head_id, {})
		score = person.interests[entry["interest"]] / 100.0 * 0.4 + person.values["family_loyalty"] * 0.25 + float(bond.get("trust", 0.4)) * 0.2
		score -= person.current_state["resentment"] * 0.4 + person.current_state["stress"] * 0.15 + person.learned_tendencies["need_for_autonomy"] * 0.15
	var result: Dictionary = Assignment.resolve(person, score, {"study":"study independently", "repair":"repair Landi House", "visit":"visit the " + state.village.households[target_id].name if state.village.households.has(target_id) else "visit our neighbors"}[activity_id], "", person_id == state.head_id)
	var response: String = result["response"]
	if result["outcome"] == "reluctant": person.current_state["resentment"] = minf(1.0, person.current_state["resentment"] + 0.05)
	person.memories.append({"kind": "activity_request", "date": state.date_text(), "description": response})
	if result["accepted"]: person.decision_state["observation"] = entry["name"] + " is now a family commitment."
	state.chronicle.append({"date": state.date_text(), "description": response, "category": "project", "person_id": person_id})
	if not result["accepted"]:
		return result
	var plan = Plan.new()
	plan.id = "activity_%d" % next_id
	next_id += 1
	plan.activity_id = activity_id
	plan.proposer_id = state.head_id
	plan.participant_ids = [person_id]
	plan.accepted_participant_ids = [person_id]
	plan.target_household_id = target_id
	plan.location_id = entry["location"]
	plan.status = "active"
	plan.proposed_month = state.elapsed_months
	plan.started_month = state.elapsed_months
	plan.duration_months = entry["months"]
	plan.monthly_cost_cents = entry["cost"]
	plan.agreement = result["agreement"].duplicate(true)
	plans[plan.id] = plan
	result["plan_id"] = plan.id
	result["activity_id"] = plan.id
	return result


func cancel(state, plan_id: String) -> void:
	if not plans.has(plan_id) or plans[plan_id].status not in ["active", "interrupted", "queued", "paused"]:
		return
	var plan = plans[plan_id]
	plan.status = "cancelled"
	plan.interruption_reason = ""
	var description: String = CATALOG[plan.activity_id]["name"] + " was cancelled. Earlier expenses are not refunded."
	plan.outcome = {"description":description}
	state.people[plan.accepted_participant_ids[0]].decision_state["observation"] = description
	state.chronicle.append({"date":state.date_text(), "description":state.people[plan.participant_ids[0]].name + " · " + description, "category": "project", "person_id": plan.participant_ids[0]})


func advance_month(state) -> void:
	_start_queues(state)
	for plan in plans.values():
		if plan.status in ["queued", "paused"]:
			var participant = state.people[plan.participant_ids[0]]
			if not participant.alive or participant.id not in state.household["members"]:
				plan.status = "failed"
				plan.outcome = {"description": participant.name + " is no longer available."}
				_record(state, plan, plan.outcome["description"])
		if plan.status not in ["active", "interrupted"]:
			continue
		var person = state.people[plan.accepted_participant_ids[0]]
		if not person.alive or person.id not in state.household["members"]:
			plan.status = "failed"
			plan.interruption_reason = ""
			plan.outcome = {"description": "The participant is no longer available."}
			_record(state, plan, plan.outcome["description"])
			continue
		var interruption := ""
		if not person.life_state.get("illness", {}).is_empty():
			interruption = "Recovering from illness"
		elif state.events.needs_family_care(state,person,true):
			interruption = "Childbirth and family care"
		elif not person.education["study"].is_empty():
			interruption = "Current course takes priority"
		elif state.economy.cash_cents < state.economy.purchase_cost(plan.monthly_cost_cents):
			interruption = "Needs funding after household bills"
		if not interruption.is_empty():
			if plan.status != "interrupted" or plan.interruption_reason != interruption:
				_record(state, plan, interruption)
			plan.status = "interrupted"
			plan.interruption_reason = interruption
			continue
		if plan.progress_months >= 1 and Assignment.abandons(person, plan.agreement):
			plan.status = "failed"
			plan.outcome = {"description": person.name + " abandoned " + CATALOG[plan.activity_id]["name"].to_lower() + ": this responsibility has become too much."}
			person.memories.append({"kind": "activity", "date": state.date_text(), "description": plan.outcome["description"]})
			person.decision_state["observation"] = plan.outcome["description"]
			_record(state, plan, plan.outcome["description"])
			continue
		if plan.status == "interrupted": _record(state, plan, person.name + ": resumed after interruption.")
		plan.status = "active"
		plan.interruption_reason = ""
		state.events._cash(state, -plan.monthly_cost_cents, CATALOG[plan.activity_id]["name"])
		var step: float = state.legacy.learning_multiplier() if plan.activity_id == "study" else 1.0
		plan.progress_months = minf(plan.duration_months, plan.progress_months + step * Assignment.progress(person, plan.agreement))
		person.current_state["stress"] = minf(1.0, person.current_state["stress"] + 0.015)
		if plan.progress_months < plan.duration_months:
			continue
		plan.status = "completed"
		var description := ""
		match plan.activity_id:
			"study":
				person.skills["literacy"] = minf(100.0, person.skills["literacy"] + 12.0)
				description = person.name + " completed independent study and improved their literacy."
			"repair":
				state.household["condition"] = mini(100, state.household["condition"] + 15)
				description = person.name + " completed the house repairs."
			"visit":
				var neighbor = state.village.households[plan.target_household_id]
				var bond: Dictionary = neighbor.relationships["landi"]
				var rapport: float = bond["trust"] + person.skills["persuasion"] / 100.0 * 0.4 - bond["resentment"]
				if rapport >= 0.35:
					bond["trust"] = minf(1.0, bond["trust"] + 0.12)
					description = person.name + " built warmer ties with the " + neighbor.name + "."
				else:
					bond["resentment"] = minf(1.0, bond["resentment"] + 0.04)
					description = "Visits to the " + neighbor.name + " met a cool reception."
				neighbor.history.append({"date": state.date_text(), "description": description})
		plan.outcome = {"description": description}
		person.memories.append({"kind": "activity", "date": state.date_text(), "description": description})
		person.decision_state["observation"] = description
		_record(state, plan, description)


func _record(state, plan, description: String, notify_user := true) -> void:
	state.chronicle.append({"date": state.date_text(), "description": state.people[plan.participant_ids[0]].name + " · " + CATALOG[plan.activity_id]["name"] + " — " + description, "category": "project", "person_id": plan.participant_ids[0]})
	if notify_user: state.notify(CATALOG[plan.activity_id]["name"] + " — " + description, plan.accepted_participant_ids[0])


func to_save_data() -> Dictionary:
	var saved: Dictionary = {}
	for plan_id in plans:
		saved[plan_id] = plans[plan_id].to_save_data()
	return {"plans": saved, "next_id": next_id}


func restore_save_data(data: Dictionary) -> void:
	plans = {}
	next_id = data.get("next_id", 1)
	for plan_id in data.get("plans", {}):
		var plan = Plan.new()
		plan.restore_save_data(data["plans"][plan_id])
		plans[plan_id] = plan


func enqueue(state, person_id: String, activity_id: String, target_id: String = "") -> String:
	if not CATALOG.has(activity_id) or not state.people.has(person_id): return ""
	if not state.people.has(state.head_id) or not state.people[state.head_id].alive: return ""
	var person = state.people[person_id]
	if not person.alive or person_id not in state.household["members"] or person.age < 18: return ""
	if activity_id == "visit" and not state.village.households.has(target_id): return ""
	var plan = Plan.new()
	plan.id = "activity_%d" % next_id
	plan.queue_order = next_id
	next_id += 1
	plan.activity_id = activity_id
	plan.proposer_id = state.head_id
	plan.participant_ids = [person_id]
	# Intended participant; agreement remains empty until they consent at the start.
	plan.accepted_participant_ids = [person_id]
	plan.target_household_id = target_id
	plan.location_id = CATALOG[activity_id]["location"]
	plan.duration_months = CATALOG[activity_id]["months"]
	plan.monthly_cost_cents = CATALOG[activity_id]["cost"]
	plan.proposed_month = state.elapsed_months
	plan.status = "queued"
	plans[plan.id] = plan
	_record(state, plan, person.name + ": added to their queue; agreement will be sought when they are available.", false)
	return plan.id


func queue_for(person_id: String) -> Array:
	var result: Array = []
	for plan in plans.values():
		if person_id in plan.participant_ids and plan.started_month < 0 and plan.status in ["queued", "paused"]: result.append(plan)
	result.sort_custom(func(a, b): return a.queue_order < b.queue_order)
	return result


func move(plan_id: String, direction: int) -> void:
	if not plans.has(plan_id): return
	var queue := queue_for(plans[plan_id].participant_ids[0])
	var index := queue.find(plans[plan_id])
	var other := index + direction
	if index < 0 or other < 0 or other >= queue.size(): return
	var old: int = queue[index].queue_order
	queue[index].queue_order = queue[other].queue_order
	queue[other].queue_order = old


func pause_plan(state, plan_id: String) -> void:
	if not plans.has(plan_id): return
	var plan = plans[plan_id]
	if plan.status == "paused":
		plan.status = "queued" if plan.started_month < 0 else "active"
		plan.interruption_reason = ""
		_record(state, plan, "Resumed by the family head.", false)
	elif plan.status in ["queued", "active", "interrupted"]:
		plan.status = "paused"
		plan.interruption_reason = "Paused by the family head"
		_record(state, plan, plan.interruption_reason, false)


func queue_reason(state, plan) -> String:
	if plan.status == "paused": return "Paused by the family head"
	var queue := queue_for(plan.participant_ids[0])
	if not queue.is_empty() and queue[0] != plan: return "Waiting for earlier plans"
	return reason(state, plan.participant_ids[0], plan.activity_id, plan.target_household_id)


func _start_queues(state) -> void:
	for person_id in state.household["members"]:
		var queue := queue_for(person_id)
		if queue.is_empty(): continue
		var pending = queue[0]
		if not queue_reason(state, pending).is_empty(): continue
		var result := propose(state, person_id, pending.activity_id, pending.target_household_id)
		if result.get("accepted", false):
			var started = plans[result["plan_id"]]
			plans.erase(started.id)
			started.id = pending.id
			started.queue_order = pending.queue_order
			started.proposed_month = pending.proposed_month
			plans[pending.id] = started
			_record(state, started, state.people[person_id].name + ": started after agreement.")
		else:
			pending.status = "failed"
			pending.outcome = {"description": result.get("response", "They did not agree to start.")}
