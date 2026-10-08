extends RefCounted
## Deterministic personal planning. Scores and unexpressed goals stay private.

const FIRST_REVIEW_MONTH := 6
const NOTICE_MONTHS := 2
const ACTION_COOLDOWN := 3


static func ensure_goals(person) -> void:
	if not person.alive:
		return
	for goal in person.goals:
		if not goal.has("status"):
			goal["status"] = "active"
	var motives: Array = []
	if person.age >= 18 and person.values["independence"] >= 0.75 and person.spouse_id.is_empty():
		motives.append({"kind": "independent_life", "description": "Build a life in a home of my own", "weight": person.values["independence"]})
	if person.age >= 6 and person.values["achievement"] >= 0.7 and (person.age < 18 or person.interests["academic"] >= 70.0):
		motives.append({"kind": "education", "description": "Develop my abilities through further education", "weight": person.values["achievement"]})
	if person.age >= 18 and person.values["security"] >= 0.65:
		motives.append({"kind": "financial_security", "description": "Find dependable work and protect my future", "weight": person.values["security"]})
	if person.age >= 18 and person.values["family_loyalty"] >= 0.65:
		motives.append({"kind": "family_cohesion", "description": "Support relatives when they are under strain", "weight": person.values["family_loyalty"]})
	if person.age >= 18 and person.values["wealth"] >= 0.7:
		motives.append({"kind": "career", "description": "Build a better paid career", "weight": person.values["wealth"]})
	if person.age >= 18 and person.spouse_id.is_empty() and person.values["romance"] >= 0.75:
		motives.append({"kind": "seek_marriage", "description": "Find a partner of my own choosing", "weight": person.values["romance"]})
	motives.sort_custom(func(a, b): return float(a["weight"]) > float(b["weight"]))
	for motive in motives:
		if person.goals.size() >= 3:
			break
		if not _has_kind(person, motive["kind"], false):
			person.goals.append({"kind": motive["kind"], "description": motive["description"], "status": "active", "origin": "values"})
	if person.goals.is_empty():
		person.goals.append({"kind": "education" if person.age < 18 else "financial_security", "description": "Prepare for my future", "status": "active", "origin": "circumstances"})

	for goal in person.goals:
		if goal.get("kind") == "education" and not goal.has("target_rank"):
			goal["target_rank"] = mini(4, person.EDUCATION_LEVELS.find(person.education["level"]) + 1)


static func _has_kind(person, kind: String, active_only: bool = true) -> bool:
	for goal in person.goals:
		if goal.get("kind") == kind and (not active_only or goal.get("status") == "active"):
			return true
	return false


static func advance_month(state, person) -> void:
	ensure_goals(person)
	if not person.alive or person.id == state.head_id:
		return
	_update_goals(state, person)
	if state.elapsed_months < FIRST_REVIEW_MONTH:
		return
	if int(state.last_requests.get(person.id, -1)) >= state.elapsed_months - 1:
		return # A recent conversation through a request deserves time to take effect.
	var best: Dictionary = _choose(state, person)
	var plan: Dictionary = person.decision_state.get("plan", {})
	if not plan.is_empty():
		if best.is_empty() or best["action"] != plan["action"]:
			person.decision_state["plan"] = {}
			_record(state, person, "reconsidered", person.name + " has set aside the plan to " + plan["description"] + ".", false)
			return
		if plan["action"].begins_with("funding:"):
			var interim: Dictionary = _choose(state, person, false)
			if not interim.is_empty() and interim["action"] in ["help", "practice"] and state.elapsed_months - int(person.decision_state.get("last_action_month", 0)) >= ACTION_COOLDOWN:
				_apply(state, person, interim)
			return # Only the head can commit the shared purse to a new course.
		if state.elapsed_months >= int(plan["due_month"]):
			person.decision_state["plan"] = {}
			_apply(state, person, best)
		return
	if state.elapsed_months - int(person.decision_state.get("last_action_month", 0)) < ACTION_COOLDOWN or best.is_empty():
		return
	if best["action"] in ["help", "practice"]:
		_apply(state, person, best)
		return
	best["due_month"] = state.elapsed_months + NOTICE_MONTHS
	person.decision_state["plan"] = best.duplicate(true)
	var wording: String = person.name + " plans to " + best["description"] + ". " + best["reason"]
	if best["action"].begins_with("funding:"):
		wording += " They ask the family head to arrange funding through Education & careers."
	elif person.learned_tendencies["conflict_avoidance"] >= 0.7:
		wording = person.name + " has been quietly preparing to " + best["description"] + ". " + best["reason"]
	_record(state, person, "intention", wording, true)


static func _choose(state, person, include_funding: bool = true) -> Dictionary:
	var choices: Array = []
	var studying: bool = not person.education["study"].is_empty()
	var loyalty: float = person.values["family_loyalty"]
	var security: float = person.values["security"]
	var achievement: float = person.values["achievement"]
	var bond: Dictionary = person.relationships.get(state.head_id, {})
	var resentment: float = maxf(float(person.current_state.get("resentment", 0.0)), float(bond.get("resentment", 0.0)))
	if person.age >= 18 and not studying:
		var current_interest := 0.5
		var current_status := 0.0
		if state.careers.jobs.has(person.career_id):
			current_interest = float(person.interests[state.careers.jobs[person.career_id]["interest"]]) / 100.0
			current_status = float(state.careers.jobs[person.career_id]["education_level"])
		for job_id in state.careers.jobs:
			if job_id == person.career_id or not state.careers.job_assessment(person, job_id)["eligible"]:
				continue
			var job: Dictionary = state.careers.jobs[job_id]
			var interest_gain: float = float(person.interests[job["interest"]]) / 100.0 - current_interest
			var income_gain: float = clampf(float(int(job["monthly_income_cents"]) - person.monthly_income_cents) / maxf(person.monthly_income_cents, 4000), -1.0, 1.0)
			var score: float = interest_gain * (0.35 + achievement * 0.4) + income_gain * (float(person.values["wealth"]) * 0.4 + security * 0.2)
			score -= security * 0.15 if person.monthly_income_cents > 0 else -0.3
			score += float(person.values["status"]) * maxf(0.0, float(job["education_level"]) - current_status) * 0.1
			if person.career_id in ["shop_assistant", "shopkeeper"]:
				score -= float(person.values["tradition"]) * 0.1
			if _has_kind(person, "independent_career") and job_id != "shop_assistant":
				score += float(person.values["independence"]) * 0.2
			if _has_kind(person, "career") or _has_kind(person, "financial_security") or _has_kind(person, "child_security"):
				score += maxf(0.0, income_gain) * 0.15
			_offer(choices, "work:" + job_id, "take work as " + str(job["name"]), "The work offers a future closer to what they value.", score)
	if person.age >= 18 and person.spouse_id.is_empty() and not studying:
		if person.in_household and (_has_kind(person, "independent_life") or _has_kind(person, "independent_career")):
			var dependents := false
			for relative in state.people.values():
				if relative.alive and relative.age < 18 and person.id in relative.parent_ids:
					dependents = true
			if not dependents and person.monthly_income_cents >= state.economy.food_per_person_cents() * 2 and state.elapsed_months >= int(person.decision_state.get("stay_until", 0)):
				var score: float = float(person.values["independence"]) * 0.85 + float(person.learned_tendencies["need_for_autonomy"]) * 0.2 + resentment * 0.3 - loyalty * 0.5 - security * 0.2 - float(bond.get("affection", 0.4)) * 0.15 - float(person.values["tradition"]) * 0.1
				_offer(choices, "leave", "move into a home of their own", "They want independence and have an income to support the move.", score)
		elif not person.in_household and _has_kind(person, "family_cohesion") and state.economy.cash_cents >= 0:
			var score: float = loyalty * 0.7 + security * 0.2 + float(bond.get("affection", 0.4)) * 0.2 - float(person.values["independence"]) * 0.5 - resentment * 0.5
			_offer(choices, "join", "return to the ancestral home", "Being close to family matters more than living apart.", score)
	if include_funding and person.in_household and person.age >= 6 and not studying and _has_kind(person, "education"):
		for program_id in state.careers.programs:
			if not state.careers.program_reason(person, program_id).is_empty():
				continue
			var program: Dictionary = state.careers.programs[program_id]
			var score: float = float(person.interests[program["interest"]]) / 100.0 * 0.4 + achievement * 0.4 - security * 0.15 - float(person.current_state.get("stress", 0.0)) * 0.15
			if person.monthly_income_cents > 0:
				score -= security * 0.2
			_offer(choices, "funding:" + program_id, "study " + str(program["name"]), "They want to develop their abilities, but need agreement on the fees.", score)
	if person.in_household and float(person.current_state.get("stress", 0.0)) < 0.75 and (_has_kind(person, "family_cohesion") or _has_kind(person, "child_security") or _has_kind(person, "shared_ownership")):
		for relative_id in person.relationships:
			if not state.people.has(relative_id):
				continue
			var relative = state.people[relative_id]
			if relative.alive and relative.in_household and relative.id != person.id:
				var stress: float = relative.current_state.get("stress", 0.0)
				var affection: float = person.relationships[relative_id].get("affection", 0.4)
				if stress >= 0.3:
					_offer(choices, "help", "help " + relative.name + " with household responsibilities", "They have noticed a relative struggling.", loyalty * affection * stress, {"target_id": relative_id})
	if not studying and person.age >= 6 and (_has_kind(person, "education") or _has_kind(person, "independent_career") or _has_kind(person, "career")):
		var interest_name := "academic"
		for key in person.interests:
			if person.interests[key] > person.interests[interest_name]:
				interest_name = key
		var skill_map := {"academic": "literacy", "technical": "technical", "commercial": "commerce", "artistic": "art", "social": "persuasion", "practical": "craft"}
		var skill: String = skill_map[interest_name]
		if person.skills[skill] < 50.0:
			_offer(choices, "practice", "practice " + skill, "They spend spare time on an interest of their own.", achievement * float(person.interests[interest_name]) / 100.0 * 0.4, {"skill": skill})
	if person.age >= 18 and person.spouse_id.is_empty():
		for goal in person.goals:
			if goal.get("kind") == "seek_marriage" and goal.get("status") == "active" and not goal.get("pursuit_started", false):
				var score: float = float(person.values["romance"]) * 0.6 + float(person.values["tradition"]) * 0.2 - float(person.values["independence"]) * 0.15
				if studying or _has_kind(person, "education"):
					score -= achievement * 0.3
				_offer(choices, "seek_partner", "look for a partner of their own choosing", "Companionship is becoming a priority for them.", score)
	if choices.is_empty():
		return {}
	choices.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
	return choices[0]


static func _offer(choices: Array, action: String, description: String, reason: String, score: float, extra: Dictionary = {}) -> void:
	if score < 0.2:
		return
	var choice := {"action": action, "description": description, "reason": reason, "score": score}
	choice.merge(extra)
	choices.append(choice)


static func _apply(state, person, choice: Dictionary) -> void:
	var action: String = choice["action"]
	if action.begins_with("work:"):
		state.careers.apply_request(person, action)
		_complete(person, "independent_career", state)
		_complete(person, "career", state)
	elif action == "leave":
		state.household["members"].erase(person.id)
		person.in_household = false
		_complete(person, "independent_life", state)
	elif action == "join":
		if person.id not in state.household["members"]:
			state.household["members"].append(person.id)
		person.in_household = true
	elif action == "help":
		var relative = state.people[choice["target_id"]]
		relative.current_state["stress"] = maxf(0.0, float(relative.current_state.get("stress", 0.0)) - 0.08)
		var bond: Dictionary = relative.relationships.get(person.id, {}).duplicate(true)
		bond["trust"] = minf(1.0, float(bond.get("trust", 0.4)) + 0.03)
		relative.relationships[person.id] = bond
		person.current_state["stress"] = minf(1.0, float(person.current_state.get("stress", 0.0)) + 0.03)
	elif action == "seek_partner":
		for goal in person.goals:
			if goal.get("kind") == "seek_marriage" and goal.get("status") == "active":
				goal["pursuit_started"] = true
	elif action == "practice":
		person.skills[choice["skill"]] = minf(50.0, float(person.skills[choice["skill"]]) + 1.5)
	person.current_state["happiness"] = minf(1.0, float(person.current_state.get("happiness", 0.6)) + 0.03)
	person.decision_state["last_action_month"] = state.elapsed_months
	_record(state, person, "decision", person.name + " chose to " + choice["description"] + ". " + choice["reason"], action not in ["help", "practice"])


static func _update_goals(state, person) -> void:
	for goal in person.goals:
		if goal.get("status") != "active":
			continue
		if goal.get("kind") == "education":
			if not goal.has("target_rank"):
				goal["target_rank"] = mini(4, state.careers.education_rank(person) + 1)
			if state.careers.education_rank(person) >= int(goal["target_rank"]):
				_complete(person, "education", state)
		elif goal.get("kind") == "independent_life" and not person.in_household:
			_complete(person, "independent_life", state)
		elif goal.get("kind") == "seek_marriage" and not person.spouse_id.is_empty():
			_complete(person, "seek_marriage", state)


static func _complete(person, kind: String, state) -> void:
	for goal in person.goals:
		if goal.get("kind") == kind and goal.get("status") == "active":
			goal["status"] = "completed"
			goal["completed_date"] = state.date_text()


static func _record(state, person, kind: String, description: String, major: bool) -> void:
	person.memories.append({"kind": kind, "date": state.date_text(), "description": description})
	state.chronicle.append({"date": state.date_text(), "description": description})
	# Distant relatives retain private decisions; household plans are observable.
	if person.in_household or kind == "decision":
		person.decision_state["observation"] = description
		if person.knowledge.has(state.head_id):
			person.knowledge[state.head_id]["evidence"].append(state.date_text() + " — " + description)
	state.major_event = state.major_event or major
