extends RefCounted
## Leadership and an equal-share cash will are separate. No arbitrary disinheritance.
var enabled := true
var pending := false
var ended := false
var nominated_id := ""
var deceased_head_id := ""
var history: Array = []
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 1847

func children(state, parent_id: String) -> Array:
	var ids: Array = []
	for person in state.people.values():
		if person.alive and parent_id in person.parent_ids: ids.append(person.id)
	return ids

func candidates(state) -> Array:
	var result: Array = []
	var parent_id: String = deceased_head_id if pending else state.head_id
	result.append_array(children(state, parent_id))
	var spouse: String = state.people[parent_id].spouse_id
	if state.people.has(spouse) and state.people[spouse].alive and spouse not in result: result.append(spouse)
	for person in state.people.values():
		if person.alive and person.id != parent_id and person.id not in result: result.append(person.id)
	return result

func nominate(state, id: String) -> String:
	if pending or ended: return "Succession is already in progress."
	if id not in candidates(state): return "Choose a living relative."
	nominated_id = id
	state.chronicle.append({"date": state.date_text(), "description": state.people[state.head_id].name + " named " + state.people[id].name + " as the next family head. Every child's inheritance share is preserved."})
	return ""

func disinherit(_state, _id: String) -> String:
	return "Children's inheritance is protected. This equal-share will cannot disinherit a child."

func default_successor(state) -> String:
	var options := candidates(state)
	if nominated_id in options: return nominated_id
	for id in options:
		if state.people[id].age >= 18: return id
	return str(options[0]) if not options.is_empty() else ""

func advance_month(state) -> void:
	if not enabled: return
	for person in state.people.values():
		if not person.alive or person.age < 55: continue
		var annual := 0.005 if person.age < 65 else (0.02 if person.age < 75 else (0.07 if person.age < 85 else 0.20))
		if not person.life_state.get("illness", {}).is_empty(): annual *= 1.5
		if person.age >= 95 or rng.randf() < 1.0 - pow(1.0 - annual, 1.0 / 12.0): die(state, person.id)
	if pending and candidates(state).is_empty(): ended = true

func die(state, id: String) -> bool:
	if not state.people.has(id) or not state.people[id].alive: return false
	var person = state.people[id]
	person.alive = false
	person.health = "Deceased"
	person.in_household = false
	state.household["members"].erase(id)
	person.education["study"] = {}
	person.decision_state["plan"] = {}
	person.life_state.erase("pregnancy")
	var description: String = person.name + " died at age " + str(person.age) + "."
	person.life_state["death_date"] = state.date_text()
	state.chronicle.append({"date": state.date_text(), "description": description})
	state.notify(description, id)
	state.major_event = true
	for relative in state.people.values():
		if relative.alive and (relative.relationships.has(id) or id in relative.parent_ids):
			relative.experience_event("bereavement", description, state.date_text(), [id], 0.6)
	if id == state.head_id:
		pending = true
		deceased_head_id = id
		if candidates(state).is_empty(): ended = true
	else:
		var personal: int = person.life_state.get("personal_cash_cents", 0)
		if personal > 0:
			person.life_state["personal_cash_cents"] = 0
			var duty: int = state.Laws.estate_duty(state, personal)
			personal -= duty
			if duty > 0:
				state.chronicle.append({"date": state.date_text(), "description": person.name + "'s personal cash estate paid " + state.economy.money(duty) + " in inheritance duties."})
			var shares := descendant_shares(state, id, personal)
			if shares.is_empty() and state.people.has(person.spouse_id) and state.people[person.spouse_id].alive: shares[person.spouse_id] = personal
			for heir_id in shares:
				var heir = state.people[heir_id]
				if heir.id == state.head_id and heir.alive: state.economy.cash_cents += int(shares[heir_id])
				else: heir.life_state["personal_cash_cents"] = int(heir.life_state.get("personal_cash_cents", 0)) + int(shares[heir_id])
			if shares.is_empty():
				person.life_state["unsettled_estate_cents"] = personal
				state.chronicle.append({"date": state.date_text(), "description": person.name + " left a personal estate with no known descendant or spouse beneficiary. It remains outside the shared purse."})
	return true

func reserved_dowry(state) -> int:
	var amount := 0
	for union in state.marriage.unions.values():
		if union["held_at_home"]: amount += int(union["capital_cents"])
	return amount

func preview(state) -> Dictionary:
	var parent_id: String = deceased_head_id if pending else state.head_id
	var net := maxi(0, state.economy.cash_cents - state.loans.principal_cents() - state.loans.accrued_cents() - reserved_dowry(state))
	var duty: int = state.Laws.estate_duty(state, net)
	net -= duty
	var shares := descendant_shares(state, parent_id, net)
	return {"estate_cents": net, "shares": shares, "inheritance_tax_cents": duty, "dowry_reserved_cents": reserved_dowry(state)}

func descendant_shares(state, parent_id: String, amount: int, visited: Dictionary = {}) -> Dictionary:
	if visited.has(parent_id): return {}
	var path := visited.duplicate()
	path[parent_id] = true
	var branches: Array = []
	for person in state.people.values():
		if parent_id in person.parent_ids and (person.alive or not descendant_shares(state, person.id, 0, path).is_empty()): branches.append(person.id)
	var shares: Dictionary = {}
	for index in branches.size():
		var share: int = amount / branches.size() + (1 if index < amount % branches.size() else 0)
		var person = state.people[branches[index]]
		if person.alive: shares[person.id] = share
		else:
			var descendants := descendant_shares(state, person.id, share, path)
			for id in descendants: shares[id] = int(shares.get(id, 0)) + int(descendants[id])
	return shares

func continue_as(state, id: String) -> String:
	if not pending or ended: return "No succession choice is available."
	if id not in candidates(state): return "Choose a living relative."
	state.loans.settle_estate(state)
	var dowry := mini(maxi(0, state.economy.cash_cents), reserved_dowry(state))
	var estate := maxi(0, state.economy.cash_cents - dowry)
	var duty: int = state.Laws.estate_duty(state, estate)
	if duty > 0:
		state.events._cash(state, -duty, "Inheritance registration duty", false)
		estate -= duty
	var shares := descendant_shares(state, deceased_head_id, estate)
	# An equal-share will names children; if there are none, the continuing relative inherits.
	if shares.is_empty(): shares[id] = estate
	for heir_id in shares:
		var heir = state.people[heir_id]
		heir.life_state["personal_cash_cents"] = int(heir.life_state.get("personal_cash_cents", 0)) + int(shares[heir_id])
	state.economy.cash_cents -= estate
	var successor = state.people[id]
	state.economy.cash_cents += int(successor.life_state.get("personal_cash_cents", 0))
	successor.life_state["personal_cash_cents"] = 0
	var previous: String = state.head_id
	state.people[previous].roles.erase("Family head")
	state.head_id = id
	if "Family head" not in successor.roles: successor.roles.append("Family head")
	# The next head returns to Landi House; a placement ends without an invented reward.
	for journey in state.travel.journeys.values():
		if journey["person_id"] == id and journey["status"] in state.travel.ACTIVE:
			journey["status"] = "failed"
			journey["outcome"] = "Returned to Landi House to lead the family."
	if id not in state.household["members"]: state.household["members"].append(id)
	successor.in_household = true
	successor.decision_state["plan"] = {}
	for relative in state.people.values():
		var label := "Relative"
		if relative.id == previous: label = "Former family head"
		elif relative.id == successor.spouse_id: label = "Spouse"
		elif relative.id in successor.parent_ids: label = "Parent"
		elif successor.id in relative.parent_ids: label = "Child"
		else:
			for parent in relative.parent_ids:
				if parent in successor.parent_ids: label = "Sibling"
		relative._profile["relationship"] = label
	# The new observer keeps their own knowledge instead of inheriting the old head's mind.
	var description: String = successor.name + " became family head after " + state.people[previous].name + ". " + state.economy.money(estate) + " was divided under the equal-share will."
	state.chronicle.append({"date": state.date_text(), "description": description})
	history.append({"date": state.date_text(), "previous_head_id": previous, "head_id": id, "estate_cents": estate, "shares": shares})
	pending = false
	deceased_head_id = ""
	nominated_id = ""
	state.major_event = true
	state.legacy.evaluate(state)
	return ""

func to_save_data() -> Dictionary:
	return {"enabled": enabled, "pending": pending, "ended": ended, "nominated_id": nominated_id, "deceased_head_id": deceased_head_id, "history": history.duplicate(true), "rng_seed": rng.seed, "rng_state": rng.state}

func restore_save_data(data: Dictionary) -> void:
	enabled = data.get("enabled", true)
	pending = data.get("pending", false)
	ended = data.get("ended", false)
	nominated_id = data.get("nominated_id", "")
	deceased_head_id = data.get("deceased_head_id", "")
	history = data.get("history", []).duplicate(true)
	rng.seed = data.get("rng_seed", 1847)
	rng.state = data.get("rng_state", rng.state)

static func valid(data: Variant, people: Dictionary, head_id: String) -> bool:
	if not data is Dictionary: return false
	for field in ["enabled", "pending", "ended"]:
		if not data.get(field) is bool: return false
	for field in ["nominated_id", "deceased_head_id"]:
		if not data.get(field) is String or (not data[field].is_empty() and not people.has(data[field])): return false
	if not data.get("rng_seed") is int or not data.get("rng_state") is int or not data.get("history") is Array: return false
	if data["ended"] and not data["pending"]: return false
	if not data["pending"] and not data["deceased_head_id"].is_empty(): return false
	if data["pending"] and (data["deceased_head_id"] != head_id or people[head_id]["alive"]): return false
	for entry in data["history"]:
		if not entry is Dictionary or not entry.get("date") is String or not entry.get("estate_cents") is int or entry["estate_cents"] < 0 or not entry.get("shares") is Dictionary: return false
		if not people.has(entry.get("previous_head_id")) or not people.has(entry.get("head_id")): return false
		var total := 0
		for id in entry["shares"]:
			if not people.has(id) or not entry["shares"][id] is int or entry["shares"][id] < 0: return false
			total += entry["shares"][id]
		if total != entry["estate_cents"]: return false
	return true
