extends RefCounted
## Requests express the head's wishes. Private motives determine the response.

const ACTIONS := {"stay": "Ask to stay", "leave": "Ask to leave", "join": "Ask to join the house", "marry": "Ask to marry"}


static func unavailable_reason(state, person_id: String, action: String) -> String:
	var career_action := action.begins_with("train:") or action.begins_with("work:")
	if (not ACTIONS.has(action) and not career_action) or not state.people.has(person_id):
		return "This request is unavailable."
	var person = state.people[person_id]
	if person_id == state.head_id:
		return "You cannot make a request of yourself."
	if not person.alive or not state.people[state.head_id].alive:
		return "Only living people can take part."
	if person.age < 18:
		if not action.begins_with("train:"):
			return "They are still a child; these requests are for adults."
		if person.age < 6:
			return "They are too young for this training."
		if state.head_id not in person.parent_ids:
			return "Discuss their education with their parent first."
	var resident: bool = person_id in state.household["members"]
	if action in ["stay", "leave"] and not resident:
		return "They already live elsewhere."
	if action == "join" and resident:
		return "They already live in the house."
	if action == "marry":
		if not person.spouse_id.is_empty():
			return "They are already married."
		for goal in person.goals:
			if goal.get("kind") == "seek_marriage" and goal.get("status") == "active":
				return "They have already agreed to pursue marriage."
	if int(state.last_requests.get(person_id, -1)) == state.elapsed_months:
		return "You have already made a request this month. Give them time."
	if career_action:
		return state.careers.request_reason(state, person, action)
	return ""


static func action_label(state, action: String) -> String:
	return ACTIONS[action] if ACTIONS.has(action) else state.careers.request_label(action)


static func request(state, person_id: String, action: String) -> Dictionary:
	var reason := unavailable_reason(state, person_id, action)
	if not reason.is_empty():
		return {"outcome": "unavailable", "response": reason}
	var person = state.people[person_id]
	state.last_requests[person_id] = state.elapsed_months
	var bond: Dictionary = person.relationships.get(state.head_id, {}).duplicate(true)
	var affection := float(bond.get("affection", 0.4))
	var respect := float(bond.get("respect", 0.4))
	var trust := float(bond.get("trust", 0.4))
	var resentment := maxf(float(bond.get("resentment", 0.0)), float(person.current_state.get("resentment", 0.0)))
	var independence := float(person.values["independence"])
	var loyalty := float(person.values["family_loyalty"])
	var security := float(person.values["security"])
	var autonomy := float(person.learned_tendencies["need_for_autonomy"])
	# Authority is strongest over dependent children, weaker over other branches.
	var authority := respect * (0.18 if state.head_id in person.parent_ids else 0.04)
	if person.monthly_income_cents == 0 and person_id in state.household["members"]:
		authority += 0.08
	var rapport := affection * 0.12 + trust * 0.14 + authority - resentment * 0.4
	var score := rapport
	var explanation := ""
	match action:
		"leave":
			score += independence * 0.65 + autonomy * 0.18 - loyalty * 0.35 - security * 0.22
			if person.monthly_income_cents == 0:
				score -= 0.25
			explanation = "I want a place of my own." if score >= 0.3 else "This is my home too. I am not ready to leave."
		"join", "stay":
			score += loyalty * 0.5 + security * 0.15 - independence * 0.4 - autonomy * 0.2
			for goal in person.goals:
				if goal.get("kind") == "independent_career" and goal.get("status") == "active":
					score -= 0.18
			if state.economy.cash_cents < 0:
				score -= security * 0.2
			explanation = "Being close to the family matters to me." if score >= 0.3 else "I need room to build my own life."
		"marry":
			score += float(person.values["romance"]) * 0.5 + float(person.values["tradition"]) * 0.2 - independence * 0.2 - autonomy * 0.15
			for goal in person.goals:
				if goal.get("kind") in ["education", "independent_career"] and goal.get("status") == "active":
					score -= float(person.values["achievement"]) * 0.3
			explanation = "I would like to find someone, but the choice must be mine." if score >= 0.3 else "I have other plans right now. Marriage must be my choice."
		_:
			score += state.careers.willingness(person, action)
			explanation = "This could be a future I want." if score >= 0.3 else "That is not the future I want for myself."
	var outcome := "accepted" if score >= 0.3 else ("reluctant" if score >= 0.12 else "refused")
	var response := explanation
	if outcome == "reluctant":
		response = "I will %s, for your sake. But I am not happy about being asked." % {"stay": "stay", "leave": "move out", "join": "come home", "marry": "consider finding a partner"}.get(action, "try this path")
	elif outcome == "accepted":
		response = "Yes. " + explanation
	else:
		response = "No. " + explanation
	# Rejection and reluctant compliance have lasting costs, even without a move.
	var hurt := 0.1 if action == "leave" else (0.07 if outcome == "reluctant" else 0.03)
	if outcome == "accepted" and action != "leave":
		hurt = 0.0
	bond["resentment"] = clampf(float(bond.get("resentment", 0.0)) + hurt, 0.0, 1.0)
	bond["trust"] = clampf(trust + (0.02 if hurt == 0.0 else -hurt * 0.5), 0.0, 1.0)
	person.relationships[state.head_id] = bond
	person.current_state["resentment"] = clampf(float(person.current_state.get("resentment", 0.0)) + hurt, 0.0, 1.0)
	if outcome != "refused":
		if action == "stay":
			person.decision_state["stay_until"] = state.elapsed_months + (12 if outcome == "accepted" else 4)
			person.decision_state["plan"] = {}
		elif action == "leave":
			state.household["members"].erase(person_id)
			person.in_household = false
		elif action == "join":
			state.household["members"].append(person_id)
			person.in_household = true
		elif action == "marry":
			person.goals.append({"kind": "seek_marriage", "description": "Find a partner of my own choosing", "status": "active"})
		elif action.begins_with("train:") or action.begins_with("work:"):
			state.careers.apply_request(person, action)
		if action != "marry":
			person.decision_state["plan"] = {}
		person.decision_state["last_action_month"] = state.elapsed_months
	var description: String = "%s — %s: %s" % [action_label(state, action), person.name, response]
	person.decision_state["observation"] = description
	person.memories.append({"kind": "request", "date": state.date_text(), "description": description, "participants": [state.head_id, person_id], "outcome": outcome})
	if person.knowledge.has(state.head_id):
		person.knowledge[state.head_id]["evidence"].append(state.date_text() + " — " + description)
	state.chronicle.append({"date": state.date_text(), "description": description})
	return {"outcome": outcome, "response": response}
