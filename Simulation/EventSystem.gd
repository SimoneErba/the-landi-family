extends RefCounted
## Monthly, contextual story events. All random state and unresolved choices are saved.

const CATALOG_PATH := "res://Data/events.json"
# Italian campaigns affecting Tuscany; bounds use year * 12 + month.
const WAR_PERIODS := [[1800, 1, 1801, 2], [1805, 9, 1805, 12], [1806, 10, 1814, 4], [1815, 3, 1815, 6], [1848, 3, 1849, 4], [1859, 4, 1859, 8], [1866, 6, 1866, 10], [1911, 9, 1912, 10], [1915, 5, 1918, 11], [1940, 6, 1945, 4]]
var catalog: Dictionary = {}
var enabled: bool = true
var monthly_chance: float = 0.7
var rng := RandomNumberGenerator.new()
var pending: Array = []
var active: Array = []
var delayed: Array = []
var last_seen: Dictionary = {}
var category_seen: Dictionary = {}
var transactions: Array = []
var next_serial: int = 1


func _init() -> void:
	rng.seed = 1800
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	for entry in source["events"]:
		catalog[entry["id"]] = entry


func prepare_economy(state) -> void:
	state.economy.price_multiplier = state.legacy.price_multiplier()
	active = active.filter(func(effect): return int(effect["until_month"]) > state.elapsed_months)
	state.economy.event_food_multiplier = 1.0
	state.economy.event_income_multiplier = 1.0
	for effect in active:
		state.economy.event_food_multiplier *= float(effect.get("food_multiplier", 1.0))
		state.economy.event_income_multiplier *= float(effect.get("income_multiplier", 1.0))
	state.economy.event_food_multiplier = clampf(state.economy.event_food_multiplier, 0.5, 3.0)
	state.economy.event_income_multiplier = clampf(state.economy.event_income_multiplier, 0.25, 1.5)


func advance_month(state) -> void:
	if not enabled:
		return
	prepare_economy(state)
	var residents: int = state.economy.budget(state.people, state.household["members"])["residents"]
	var pressure := maxf(0.0, (50.0 - float(state.household.get("condition", 80))) / 1000.0)
	pressure += maxf(0.0, float(residents - int(state.household.get("capacity", 7)))) * 0.01
	for resident in state.people.values():
		if resident.alive and resident.in_household and pressure > 0:
			resident.current_state["stress"] = minf(1.0, float(resident.current_state.get("stress", 0.0)) + pressure)
	for payment in delayed.duplicate():
		if int(payment["due_month"]) <= state.elapsed_months:
			_cash(state, int(payment["amount"]), str(payment["description"]))
			state.chronicle.append({"date": state.date_text(), "description": payment["description"]})
			delayed.erase(payment)
	for person in state.people.values().duplicate():
		if not person.alive:
			continue
		var illness: Dictionary = person.life_state.get("illness", {})
		if not illness.is_empty() and int(illness["until_month"]) <= state.elapsed_months:
			person.health = str(illness.get("previous_health", "Well"))
			person.life_state["illness"] = {}
			queue_milestone(state, "recovery", person.id)
		var pregnancy: Dictionary = person.life_state.get("pregnancy", {})
		if not pregnancy.is_empty() and int(pregnancy["due_month"]) <= state.elapsed_months:
			_birth(state, person, pregnancy)
	# Fixed history is independent of random incident probability and category cooldowns.
	# Queue behind births/recoveries instead of losing a dated event to another notice.
	for entry in catalog.values():
		if entry["conditions"].has("historical_date") and not eligible_targets(state, entry).is_empty():
			trigger(state, entry["id"])
	if not pending.is_empty() or state.elapsed_months < 1 or rng.randf() >= monthly_chance:
		return
	var candidates: Array = []
	var total := 0.0
	for entry in catalog.values():
		if float(entry["weight"]) <= 0 or entry["conditions"].get("automatic_only", false):
			continue
		if state.elapsed_months - int(last_seen.get(entry["id"], -1000)) < int(entry["cooldown_months"]):
			continue
		if state.elapsed_months - int(category_seen.get(entry["category"], -1000)) < 4:
			continue
		var targets: Array = eligible_targets(state, entry)
		if targets.is_empty():
			continue
		var weight: float = float(entry["weight"]) * (state.legacy.fertility_multiplier() if entry["category"] == "pregnancy" else 1.0)
		total += weight
		candidates.append({"entry": entry, "targets": targets, "weight": weight})
	if candidates.is_empty():
		return
	var draw := rng.randf() * total
	for candidate in candidates:
		draw -= float(candidate["weight"])
		if draw <= 0.0:
			var targets: Array = candidate["targets"]
			trigger(state, candidate["entry"]["id"], targets[rng.randi_range(0, targets.size() - 1)])
			return


func eligible_targets(state, entry: Dictionary) -> Array:
	var rules: Dictionary = entry["conditions"]
	if rules.get("automatic_only", false) or state.year < int(rules.get("min_year", 0)):
		return []
	if rules.has("historical_date"):
		var date: Dictionary = rules["historical_date"]
		if state.year != int(date["year"]) or state.month != int(date["month"]) or last_seen.has(entry["id"]):
			return []
	if rules.get("wartime_only", false) and not is_wartime(state.year, state.month):
		return []
	if rules.has("months") and not rules["months"].any(func(value): return int(value) == state.month):
		return []
	if int(state.household.get("capacity", 7)) >= int(rules.get("max_capacity", 100000)):
		return []
	if entry["category"] in ["war", "drought", "famine"]:
		for effect in active:
			if effect["kind"] == entry["category"]:
				return []
	if not rules.has("target"):
		return [""]
	if rules["target"] == "family_property":
		return [""] if not property_targets(state, rules).is_empty() else []
	var targets: Array = []
	for person in state.people.values():
		var available: bool = person.in_household or (rules.get("allow_travel",false) and not state.travel.current(person.id).is_empty())
		if not person.alive or not available or person.age < int(rules.get("min_age", 0)) or person.age > int(rules.get("max_age", 200)):
			continue
		if rules["target"] == "relative" and person.id == state.head_id:
			continue
		if rules.has("value") and float(person.values[rules["value"]]) < float(rules["min_value"]):
			continue
		if float(person.current_state.get("stress", 0.0)) < float(rules.get("min_stress", 0.0)):
			continue
		if rules.get("needs_program", false) and preferred_program(state, person).is_empty():
			continue
		if rules["target"] == "healthy" and (person.health != "Well" or not person.life_state.get("illness", {}).is_empty()):
			continue
		if rules["target"] == "pregnancy":
			if not person.life_state.get("can_be_pregnant", false) or not person.life_state.get("pregnancy", {}).is_empty():
				continue
			if not state.people.has(person.spouse_id):
				continue
			var spouse = state.people[person.spouse_id]
			if not spouse.alive or not spouse.in_household or spouse.age < 18 or needs_family_care(state,person):
				continue
			if state.elapsed_months < int(person.life_state.get("next_pregnancy_month", 0)):
				continue
		targets.append(person.id)
	return targets

func property_targets(state, rules: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for building in state.village.development.buildings.values():
		if building["owner_id"] == "landi" and building["status"] == "standing" and building["type"] in rules.get("building_types",[]) and not state.village.development._occupied_project(building["parcel_id"]):
			ids.append(building["id"])
	return ids

func business_multiplier(state, key: String, completed_month: bool = false) -> float:
	var multiplier := 1.0
	var month: int = state.elapsed_months-1 if completed_month else state.elapsed_months
	for effect in active:
		if effect["until_month"] > month:
			multiplier *= float(effect.get(key,1.0))
	return clampf(multiplier,.25,3.0)

func travel_disruption(state, completed_month: bool = false) -> String:
	var month: int = state.elapsed_months-1 if completed_month else state.elapsed_months
	for effect in active:
		if effect.get("travel_until_month",-1) > month:
			return "Regional transport is disrupted by " + str(effect["kind"]) + "."
	return ""

func needs_family_care(state, person, completed_month: bool = false) -> bool:
	var pregnancy: Dictionary = person.life_state.get("pregnancy",{})
	var month: int = state.elapsed_months-1 if completed_month else state.elapsed_months
	return (not pregnancy.is_empty() and pregnancy["due_month"] <= month+2) or person.life_state.get("recovery_until_month",-1) > month


func is_wartime(year: int, month: int) -> bool:
	var date := year * 12 + month
	for period in WAR_PERIODS:
		if date >= period[0] * 12 + period[1] and date <= period[2] * 12 + period[3]:
			return true
	return false


func preferred_program(state, person) -> String:
	var best := ""
	var interest := -1.0
	for program_id in state.careers.programs:
		if not state.careers.program_reason(person, program_id).is_empty():
			continue
		var entry: Dictionary = state.careers.programs[program_id]
		var score: float = person.interests[entry["interest"]]
		if score > interest:
			interest = score
			best = program_id
	return best


func trigger(state, event_id: String, person_id: String = "") -> bool:
	if not enabled or not catalog.has(event_id):
		return false
	var entry: Dictionary = catalog[event_id]
	if person_id not in eligible_targets(state, entry):
		return false
	var event: Dictionary = _instance(state, entry, person_id)
	if entry["conditions"].get("target","") == "family_property":
		var ids := property_targets(state,entry["conditions"])
		event["building_id"] = ids[rng.randi_range(0,ids.size()-1)]
		event["condition_before"] = float(state.village.development.buildings[event["building_id"]]["condition"])
		event["body"] = event["body"].replace("{property}",state.village.development.buildings[event["building_id"]]["address"])
	if entry["conditions"].get("needs_program", false):
		event["program_id"] = preferred_program(state, state.people[person_id])
		event["body"] = event["body"].replace("{course}", str(state.careers.programs[event["program_id"]]["name"]))
	pending.append(event)
	last_seen[event_id] = state.elapsed_months
	category_seen[entry["category"]] = state.elapsed_months
	_effects(state, event, entry["on_trigger"])
	if entry["category"] == "illness" and state.people.has(person_id):
		var traveler: Dictionary = state.travel.current(person_id)
		if not traveler.is_empty():
			event["body"] += "\nNews from " + state.travel.CITIES[traveler["city_id"]]["name"] + ": illness pauses an active placement until recovery."
		if not state.village.business.commitment(person_id).is_empty():
			event["body"] += "\nTheir family business cannot produce while its manager is ill; upkeep still falls due."
	if entry["category"] == "pregnancy":
		event["body"] += "\nLate pregnancy and three months of recovery after birth pause family activities and business management. Regular wages continue, and courses can continue."
	prepare_economy(state)
	state.chronicle.append({"date": state.date_text(), "description": event["title"] + " — " + event["body"]})
	state.major_event = true
	return true


func _instance(state, entry: Dictionary, person_id: String) -> Dictionary:
	var event := entry.duplicate(true)
	event["serial"] = next_serial
	next_serial += 1
	event["date"] = state.date_text()
	event["person_id"] = person_id
	event["body"] = str(event["body"]).replace("{person}", state.people[person_id].name if state.people.has(person_id) else "A relative")
	return event


func queue_milestone(state, event_id: String, person_id: String, details: Dictionary = {}) -> void:
	if not enabled:
		return
	var event := _instance(state, catalog[event_id], person_id)
	for key in details:
		event["body"] = event["body"].replace("{" + key + "}", str(details[key]))
	if event_id == "birth":
		event["body"] += "\nThe parent has three months of recovery; family activities and business management pause during this leave."
		if state.household["members"].size() > state.household["capacity"]:
			event["body"] += "\nThe household now has %d residents for %d places; overcrowding adds pressure." % [state.household["members"].size(),state.household["capacity"]]
	pending.append(event)
	state.major_event = true


func choice_reason(state, event: Dictionary, index: int) -> String:
	if index < 0 or index >= event["choices"].size():
		return "Unknown choice."
	var effects: Dictionary = event["choices"][index]["effects"]
	if effects.get("property_condition",0) > 0:
		var building: Dictionary = state.village.development.buildings.get(event.get("building_id",""),{})
		if building.is_empty() or building["owner_id"] != "landi" or building["status"] != "standing":
			return "This property no longer belongs to the family or cannot be repaired."
		if state.village.development._occupied_project(building["parcel_id"]):
			return "Building work already covers this property."
	if int(effects.get("cash", 0)) < 0 and state.economy.cash_cents < state.economy.purchase_cost(-int(effects["cash"])):
		return "The shared purse cannot cover this expense."
	if effects.get("study", false):
		if not state.people.has(event["person_id"]) or not state.people[event["person_id"]].alive:
			return "The person is no longer available to study."
		var person = state.people[event["person_id"]]
		if person.age < 18 and state.head_id not in person.parent_ids:
			return "Discuss their education with their parent first."
		var reason: String = state.careers.request_reason(state, person, "train:" + str(event.get("program_id", "")))
		if not reason.is_empty():
			return reason
		# Reserve the first month's food and all tuition; commitments affect future wages.
		var budget: Dictionary = state.economy.budget(state.people, state.household["members"])
		var tuition: int = state.economy.purchase_cost(int(state.careers.programs[event["program_id"]]["monthly_cost_cents"]))
		if state.economy.cash_cents + int(budget["income_cents"]) - person.monthly_income_cents - int(budget["food_cents"]) < int(budget["planned_tuition_cents"]) + tuition:
			return "There is not enough funding after the household's food and existing courses."
	return ""


func resolve(state, serial: int, index: int) -> Dictionary:
	for event in pending:
		if int(event["serial"]) != serial:
			continue
		var reason := choice_reason(state, event, index)
		if not reason.is_empty():
			return {"ok": false, "message": reason}
		var choice: Dictionary = event["choices"][index]
		_effects(state, event, choice["effects"])
		prepare_economy(state)
		var description: String = event["title"] + " — " + choice["label"] + ": " + choice["result"]
		state.chronicle.append({"date": state.date_text(), "description": description})
		if state.people.has(event["person_id"]):
			var person = state.people[event["person_id"]]
			person.memories.append({"kind": "monthly_event", "date": state.date_text(), "description": description})
			person.decision_state["observation"] = description
			if person.knowledge.has(state.head_id):
				person.knowledge[state.head_id]["evidence"].append(state.date_text() + " — " + description)
		pending.erase(event)
		state.legacy.evaluate(state)
		return {"ok": true, "message": choice["result"]}
	return {"ok": false, "message": "This event has already been resolved."}


func _cash(state, amount: int, description: String, purchase: bool = true) -> void:
	if purchase and amount < 0:
		amount = -state.economy.purchase_cost(-amount)
	state.economy.cash_cents += amount
	transactions.append({"date": state.date_text(), "amount_cents": amount, "description": description})


func _effects(state, event: Dictionary, effects: Dictionary) -> void:
	var person = state.people.get(event["person_id"])
	if effects.has("currency"):
		state.economy.currency = str(effects["currency"])
	if effects.has("cash"):
		_cash(state, int(effects["cash"]), event["title"])
	if effects.has("cash_loss"):
		_cash(state, -mini(maxi(0, state.economy.cash_cents), int(effects["cash_loss"])), event["title"], false)
	if effects.has("condition"):
		state.household["condition"] = clampi(int(state.household.get("condition", 80)) + int(effects["condition"]), 0, 100)
		var dev = state.village.development
		dev.buildings["home"]["condition"] = float(state.household["condition"])
		dev._record(state,event["title"]+" changed the ancestral house condition.",["home"])
	if effects.has("property_condition"):
		var dev = state.village.development
		var id: String = event.get("building_id","")
		if dev.buildings.has(id) and dev.buildings[id]["owner_id"] == "landi" and dev.buildings[id]["status"] == "standing":
			var change: float = effects["property_condition"]
			if change > 0:
				change = minf(change,maxf(0,float(event.get("condition_before",100.0))-dev.buildings[id]["condition"]))
			dev.buildings[id]["condition"] = clampf(dev.buildings[id]["condition"]+change,0,100)
			dev._record(state,event["title"]+" changed the building condition.",[id])
	if effects.has("room"):
		state.household["rooms"].append(str(effects["room"]))
		state.household["capacity"] = int(state.household.get("capacity", 7)) + int(effects.get("capacity", 0))
	if effects.has("crisis"):
		var crisis: Dictionary = effects["crisis"].duplicate(true)
		crisis["months"] = int(crisis["months"])
		crisis["until_month"] = state.elapsed_months + int(crisis["months"])
		crisis["event_serial"] = event["serial"]
		if crisis.has("travel_delay_months"):
			crisis["travel_until_month"] = state.elapsed_months+int(crisis["travel_delay_months"])
		active.append(crisis)
	if effects.has("relief"):
		for crisis in active:
			if int(crisis["event_serial"]) == int(event["serial"]):
				crisis["food_multiplier"] = maxf(1.0, float(crisis["food_multiplier"]) - float(effects["relief"]))
	if effects.has("delayed_cash"):
		delayed.append({"due_month": state.elapsed_months + int(effects["delay_months"]), "amount": int(effects["delayed_cash"]), "description": event["title"] + " — the arrangement has paid out."})
	for resident in state.people.values():
		if resident.alive and resident.in_household:
			for key in ["stress", "happiness"]:
				if effects.has("household_" + key):
					resident.current_state[key] = clampf(float(resident.current_state.get(key, 0.0)) + float(effects["household_" + key]), 0.0, 1.0)
	if person == null or not person.alive:
		return
	for key in ["stress", "happiness", "resentment"]:
		if effects.has(key):
			person.current_state[key] = clampf(float(person.current_state.get(key, 0.0)) + float(effects[key]), 0.0, 1.0)
	if effects.has("trust"):
		var bond: Dictionary = person.relationships.get(state.head_id, {}).duplicate(true)
		bond["trust"] = clampf(float(bond.get("trust", 0.4)) + float(effects["trust"]), 0.0, 1.0)
		person.relationships[state.head_id] = bond
	if effects.has("skill"):
		person.skills[effects["skill"]] = clampf(float(person.skills[effects["skill"]]) + float(effects["skill_gain"]) * state.legacy.learning_multiplier(), 0.0, 100.0)
	if effects.get("stay_release", false):
		person.decision_state["stay_until"] = state.elapsed_months
	if effects.get("study", false):
		state.careers.apply_request(person, "train:" + str(event["program_id"]))
		person.decision_state["plan"] = {}
		person.decision_state["last_action_month"] = state.elapsed_months
	if effects.has("illness_months"):
		person.life_state["illness"] = {"until_month": state.elapsed_months + int(effects["illness_months"]), "previous_health": person.health}
		person.health = "Ill — " + str(event["title"])
	if effects.has("shorten_illness") and not person.life_state.get("illness", {}).is_empty():
		person.life_state["illness"]["until_month"] = maxi(state.elapsed_months + 1, int(person.life_state["illness"]["until_month"]) - int(effects["shorten_illness"]))
	if effects.get("pregnancy", false):
		person.life_state["pregnancy"] = {"due_month": state.elapsed_months + 9, "other_parent": person.spouse_id}


func _birth(state, person, pregnancy: Dictionary) -> void:
	var child_id := "Child_%d" % next_serial
	while state.people.has(child_id):
		next_serial += 1
		child_id = "Child_%d" % next_serial
	var parents: Array = [person.id]
	if state.people.has(pregnancy["other_parent"]):
		parents.append(pregnancy["other_parent"])
	var can_be_pregnant := rng.randf() < 0.5
	var names := ["Elena", "Rosa", "Teresa", "Paola", "Chiara", "Ada", "Lina"] if can_be_pregnant else ["Marco", "Luca", "Enzo", "Bruno", "Matteo", "Nino", "Paolo"]
	var given_name: String = names[rng.randi_range(0, names.size() - 1)]
	var surname: String = person.name.get_slice(" ", 1)
	if surname.is_empty():
		surname = "Family"
	var child = state.add_person(child_id, {"name": given_name + " " + surname, "birth": {"year": state.year, "month": state.month}, "parent_ids": parents, "branch_id": person.branch_id, "in_household": person.in_household, "relationship": "New child", "life_state": {"can_be_pregnant": can_be_pregnant}, "portrait": {"appearance": {"presentation": "feminine" if can_be_pregnant else "masculine"}}})
	person.life_state["pregnancy"] = {}
	person.life_state["recovery_until_month"] = state.elapsed_months+3
	person.life_state["next_pregnancy_month"] = state.elapsed_months + 18
	for parent_id in parents:
		child.relationships[parent_id] = {"affection": 0.8, "trust": 0.8}
		state.people[parent_id].relationships[child_id] = {"affection": 0.8, "trust": 0.8}
	queue_milestone(state, "birth", person.id, {"child": child.name})
	state.chronicle.append({"date": state.date_text(), "description": child.name + " was born to " + person.name + "."})


func to_save_data() -> Dictionary:
	return {"enabled": enabled, "monthly_chance": monthly_chance, "rng_state": rng.state, "pending": pending.duplicate(true), "active": active.duplicate(true), "delayed": delayed.duplicate(true), "last_seen": last_seen.duplicate(true), "category_seen": category_seen.duplicate(true), "transactions": transactions.duplicate(true), "next_serial": next_serial}


func restore_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	for key in ["enabled", "monthly_chance", "pending", "active", "delayed", "last_seen", "category_seen", "transactions", "next_serial"]:
		set(key, data[key])
	rng.state = data["rng_state"]
