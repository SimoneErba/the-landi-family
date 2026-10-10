extends RefCounted
## Versioned, data-only save file. Never deserialize executable objects.

const State = preload("res://Simulation/GameState.gd")
const SAVE_PATH := "user://current_game.save"
const VERSION := 1


static func save_game(clock, path: String = SAVE_PATH) -> String:
	clock._update_real_time()
	var data := {"format": "TheHouse", "version": VERSION,
		"state": clock.state.to_save_data(),
		"clock": {"speed_level": clock.speed_level, "month_progress": clock.month_progress}}
	# Write beside the destination, then replace it only after a successful write.
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "Could not save the game: " + error_string(FileAccess.get_open_error())
	file.store_var(data, false)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary)
		return "Could not finish saving: " + error_string(write_error)
	var rename_error := DirAccess.rename_absolute(temporary, path)
	if rename_error != OK:
		DirAccess.remove_absolute(temporary)
		return "Could not replace the saved game: " + error_string(rename_error)
	return ""


static func load_game(clock, path: String = SAVE_PATH) -> String:
	if not FileAccess.file_exists(path):
		return "No saved game yet. Use Save to record the current family."
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Could not open the saved game: " + error_string(FileAccess.get_open_error())
	var data: Variant = file.get_var(false)
	file.close()
	if not data is Dictionary or data.get("format") != "TheHouse":
		return "This saved game is damaged or is not a Landi family save."
	if data.get("version") != VERSION:
		return "This saved game uses an unsupported version."
	if not _valid_save(data):
		return "This saved game is incomplete or damaged."
	# Construct first; a failed validation leaves the running family untouched.
	var restored = State.new()
	restored.restore_save_data(data["state"])
	clock.is_playing = false
	clock.state = restored
	clock.speed_level = data["clock"]["speed_level"]
	clock.month_progress = data["clock"]["month_progress"]
	clock._last_tick_usec = Time.get_ticks_usec()
	return ""


static func _matches_fields(data: Variant, template: Dictionary) -> bool:
	if not data is Dictionary:
		return false
	for key in template:
		if not data.has(key) or typeof(data[key]) != typeof(template[key]):
			return false
	return true


static func _valid_save(data: Dictionary) -> bool:
	var template = State.new()
	if not data.get("state") is Dictionary:
		return false
	var saved_state: Dictionary = data["state"]
	if not saved_state.has("notifications"):
		saved_state["notifications"] = []
	if not saved_state.has("marriage"):
		saved_state["marriage"] = template.marriage.to_save_data()
	if not saved_state.has("travel"):
		saved_state["travel"] = template.travel.to_save_data()
	if not saved_state.has("activities"):
		saved_state["activities"] = template.activities.to_save_data()
	if not saved_state.has("legacy"):
		saved_state["legacy"] = template.legacy.to_save_data()
	if not saved_state.has("events"):
		saved_state["events"] = template.events.to_save_data()
	if saved_state.get("economy") is Dictionary:
		# Legacy saves stored Italian centesimi; normalize all money together.
		if not saved_state["economy"].has("currency"):
			_normalize_legacy_money(saved_state)
		for field in ["event_food_multiplier", "event_income_multiplier"]:
			if not saved_state["economy"].has(field):
				saved_state["economy"][field] = 1.0
	if saved_state.get("household") is Dictionary:
		if not saved_state["household"].has("condition"):
			saved_state["household"]["condition"] = 80
		if not saved_state["household"].has("capacity"):
			saved_state["household"]["capacity"] = 7
	if not saved_state.has("village"):
		template.village.initialize()
		saved_state["village"] = template.village.to_save_data()
	if saved_state.get("village") is Dictionary and not saved_state["village"].has("development"):
		var development = State.Village.Development.new()
		development.initialize(int(saved_state.get("year", 1800)), int(saved_state.get("elapsed_months", 0)))
		saved_state["village"]["development"] = development.to_save_data()
	if saved_state.get("village") is Dictionary and saved_state["village"].get("development") is Dictionary:
		if not saved_state["village"].has("business"):
			saved_state["village"]["business"] = State.Village.Business.new().to_save_data()
		for project in saved_state["village"]["development"].get("projects", {}).values():
			if project is Dictionary and not project.has("paid_cents"):
				project["paid_cents"] = 0
				project["duration_months"] = 12 if project.get("kind") == "construction" else 6
		if not saved_state["village"]["development"].has("property_offers"):
			saved_state["village"]["development"]["property_offers"] = {}
	if not _matches_fields(data.get("state"), template.to_save_data()):
		return false
	if not _matches_fields(data.get("clock"), {"speed_level": 1, "month_progress": 0.0}):
		return false
	var legacy: Variant = saved_state["legacy"]
	if not _matches_fields(legacy, template.legacy.to_save_data()):
		return false
	if legacy["objective_id"] != "" and not State.Legacy.OBJECTIVES.has(legacy["objective_id"]):
		return false
	if legacy["bonus_id"] != "" and not State.Legacy.BONUSES.has(legacy["bonus_id"]):
		return false
	if legacy["objective_id"].is_empty() != legacy["bonus_id"].is_empty() or (legacy["completed"] and legacy["objective_id"].is_empty()):
		return false
	var timing: Dictionary = data["clock"]
	if timing["speed_level"] < 1 or timing["speed_level"] > 5 or not is_finite(timing["month_progress"]) or timing["month_progress"] < 0.0:
		return false
	var state: Dictionary = data["state"]
	if state["month"] < 1 or state["month"] > 12 or state["elapsed_months"] < 0 or not state["people"].has(state["head_id"]):
		return false
	if state["economy"].get("currency") not in ["tuscan_lira", "tuscan_fiorino", "italian_lira"]:
		return false
	if not _valid_events(state["events"], template, state["people"],state["village"]):
		return false
	if not _valid_gameplay(state, template):
		return false
	if not _valid_travel(state, template):
		return false
	var baseline: Dictionary = template.to_save_data()
	for field in ["economy", "household", "careers"]:
		if not _matches_fields(state[field], baseline[field]):
			return false
	if state["household"]["condition"] < 0 or state["household"]["condition"] > 100 or state["household"]["capacity"] < 1:
		return false
	for room in state["household"]["rooms"]:
		if not room is String:
			return false
	if not is_finite(state["economy"]["price_index"]) or state["economy"]["price_index"] <= 0.0:
		return false
	for entry in state["economy"]["ledger"]:
		if not entry is Dictionary:
			return false
	var person_template = State.Person.new("", {}, 1800, 1, "").to_save_data()
	for person_id in state["people"]:
		var person: Variant = state["people"][person_id]
		# Version 1 saves predating autonomous decisions have no planning state.
		if person is Dictionary:
			for field in ["decision_state", "life_state"]:
				if not person.has(field):
					person[field] = {}
		if not person_id is String or not _matches_fields(person, person_template) or person["id"] != person_id:
			return false
		if not _matches_fields(person["portrait"], person_template["portrait"]) or not _matches_fields(person["education"], person_template["education"]):
			return false
		for field in ["illness", "pregnancy"]:
			if person["life_state"].has(field):
				var condition: Variant = person["life_state"][field]
				if not condition is Dictionary:
					return false
				if not condition.is_empty():
					var key := "until_month" if field == "illness" else "due_month"
					if not condition.get(key) is int or (field == "pregnancy" and not condition.get("other_parent") is String):
						return false
		if person["birth_month"] < 1 or person["birth_month"] > 12:
			return false
		if person["life_state"].has("recovery_until_month") and (not person["life_state"]["recovery_until_month"] is int or person["life_state"]["recovery_until_month"] < 0):
			return false
		for field in ["temperament", "values", "learned_tendencies", "current_state", "abilities", "skills", "interests"]:
			if not _matches_fields(person[field], person_template[field]):
				return false
		var assignment = preload("res://Simulation/Assignment.gd")
		if not assignment.valid(person["education"]["study"].get("agreement", {})) or not assignment.valid(person["life_state"].get("job_agreement", {})): return false
		if person["in_household"] != (person_id in state["household"]["members"]):
			return false
	var seen: Dictionary = {}
	for member in state["household"]["members"]:
		if not member is String or not state["people"].has(member) or seen.has(member):
			return false
		seen[member] = true
	if state["notifications"].size() > 100: return false
	for notice in state["notifications"]:
		if not _matches_fields(notice, {"date":"", "description":"", "person_id":"", "read":false}): return false
		if not notice["person_id"].is_empty() and not state["people"].has(notice["person_id"]): return false
	return State.Marriage.valid(state["marriage"], state)


static func _valid_travel(state: Dictionary, template) -> bool:
	var travel: Variant = state["travel"]
	if not _matches_fields(travel, template.travel.to_save_data()) or travel["next_id"] < 1:
		return false
	var seen: Dictionary = {}
	for journey_id in travel["journeys"]:
		var journey: Variant = travel["journeys"][journey_id]
		if journey is Dictionary and journey.has("interruption_reason") and not journey["interruption_reason"] is String:
			return false
		if journey is Dictionary and not preload("res://Simulation/Assignment.gd").valid(journey.get("agreement", {})): return false
		if not journey_id is String or not _matches_fields(journey, {"id": "", "person_id": "", "city_id": "", "purpose_id": "", "status": "", "remaining_months": 1, "progress": 0.0, "started_month": 0, "recalled": false, "outcome": ""}) or journey["id"] != journey_id:
			return false
		if not journey_id.begins_with("journey_") or not journey_id.trim_prefix("journey_").is_valid_int() or int(journey_id.trim_prefix("journey_")) < 1 or int(journey_id.trim_prefix("journey_")) >= travel["next_id"]:
			return false
		if not state["people"].has(journey["person_id"]) or not State.Travel.CITIES.has(journey["city_id"]) or not State.Travel.PURPOSES.has(journey["purpose_id"]):
			return false
		if journey["status"] not in ["outbound", "staying", "returning", "completed", "failed"] or journey["remaining_months"] < 0 or journey["remaining_months"] > State.Travel.CITIES[journey["city_id"]]["months"]:
			return false
		if not is_finite(journey["progress"]) or journey["progress"] < 0 or journey["progress"] > State.Travel.PURPOSES[journey["purpose_id"]]["months"] or journey["started_month"] < 0 or journey["started_month"] > state["elapsed_months"]:
			return false
		if journey["status"] in State.Travel.ACTIVE:
			if seen.has(journey["person_id"]) or journey["person_id"] in state["household"]["members"] or journey["person_id"] == state["head_id"]:
				return false
			seen[journey["person_id"]] = true
			for plan in state["activities"]["plans"].values():
				if plan["status"] in ["active", "interrupted"] and journey["person_id"] in plan["accepted_participant_ids"]:
					return false
	return true


static func _valid_gameplay(state: Dictionary, template) -> bool:
	var village: Variant = state["village"]
	if not _matches_fields(village, template.village.to_save_data()):
		return false
	# Every loaded village must retain the locations used by the activity catalog.
	for location in ["home", "school", "tavern"]:
		if not village["locations"].has(location):
			return false
	for location_id in village["locations"]:
		var location: Variant = village["locations"][location_id]
		if not location_id is String or not _matches_fields(location, {"id": "", "name": ""}) or location["id"] != location_id:
			return false
	if village["households"].is_empty():
		return false
	for family_id in village["households"]:
		var family: Variant = village["households"][family_id]
		if not family_id is String or not _matches_fields(family, State.Village.Household.new().to_save_data()) or family["id"] != family_id:
			return false
		if family["cash_cents"] < 0 or family["debt_cents"] < 0 or family["ambitions"].is_empty():
			return false
		for ambition in family["ambitions"]:
			if not ambition is String:
				return false
		var bond: Variant = family["relationships"].get("landi")
		if not _matches_fields(bond, {"trust": 0.0, "resentment": 0.0}):
			return false
		for value in bond.values():
			if not value is float or not is_finite(value) or value < 0 or value > 1:
				return false
		for property_id in family["property_ids"]:
			if not property_id is String or not village["properties"].has(property_id) or not village["properties"][property_id] is Dictionary or village["properties"][property_id].get("owner_id") != family_id:
				return false
		for entry in family["history"]:
			if not _matches_fields(entry, {"date": "", "description": ""}):
				return false
	for property_id in village["properties"]:
		var property: Variant = village["properties"][property_id]
		if not property_id is String or not _matches_fields(property, {"id": "", "name": "", "owner_id": "", "location_id": ""}) or property["id"] != property_id:
			return false
		if not village["households"].has(property["owner_id"]) or not village["locations"].has(property["location_id"]):
			return false
	if not preload("res://Simulation/Village/VillageDevelopmentValidation.gd").valid(village["development"], village, state):
		return false
	if not State.Village.Business.valid(village["business"], state):
		return false
	var activities: Variant = state["activities"]
	if not _matches_fields(activities, template.activities.to_save_data()) or activities["next_id"] < 1:
		return false
	var committed: Dictionary = {}
	for plan_id in activities["plans"]:
		var plan: Variant = activities["plans"][plan_id]
		if plan is Dictionary and not plan.has("agreement"): plan["agreement"] = {}
		if not plan_id is String or not _matches_fields(plan, State.Activities.Plan.new().to_save_data()) or plan["id"] != plan_id:
			return false
		if not preload("res://Simulation/Assignment.gd").valid(plan["agreement"]): return false
		if not State.Activities.CATALOG.has(plan["activity_id"]) or plan["status"] not in State.Activities.Plan.STATUSES:
			return false
		if not plan_id.begins_with("activity_") or not plan_id.trim_prefix("activity_").is_valid_int() or int(plan_id.trim_prefix("activity_")) < 1 or int(plan_id.trim_prefix("activity_")) >= activities["next_id"]:
			return false
		if not state["people"].has(plan["proposer_id"]) or plan["participant_ids"].size() != 1 or plan["accepted_participant_ids"] != plan["participant_ids"]:
			return false
		var person_id: Variant = plan["participant_ids"][0]
		if not person_id is String or not state["people"].has(person_id):
			return false
		if plan["status"] in ["active", "interrupted"]:
			if committed.has(person_id):
				return false
			committed[person_id] = true
		if plan["duration_months"] < 1 or not is_finite(plan["progress_months"]) or plan["progress_months"] < 0 or plan["progress_months"] > plan["duration_months"] or plan["monthly_cost_cents"] < 0 or plan["upfront_cost_cents"] < 0:
			return false
		if plan["proposed_month"] < 0 or plan["proposed_month"] > state["elapsed_months"] or plan["started_month"] < 0 or plan["started_month"] > state["elapsed_months"]:
			return false
		if not village["locations"].has(plan["location_id"]) or (plan["activity_id"] == "visit" and not village["households"].has(plan["target_household_id"])):
			return false
		if not plan["outcome"].is_empty() and not _matches_fields(plan["outcome"], {"description": ""}):
			return false
	return true


static func _valid_events(events: Variant, template, people: Dictionary, village: Dictionary) -> bool:
	if not _matches_fields(events, template.events.to_save_data()):
		return false
	if not is_finite(events["monthly_chance"]) or events["monthly_chance"] < 0 or events["monthly_chance"] > 1 or events["next_serial"] < 1:
		return false
	var serials: Dictionary = {}
	for event in events["pending"]:
		if not event is Dictionary or not event.get("id") is String or not template.events.catalog.has(event["id"]):
			return false
		if not _matches_fields(event, template.events.catalog[event["id"]]):
			return false
		if not event.get("serial") is int or event["serial"] < 1 or event["serial"] >= events["next_serial"] or serials.has(event["serial"]) or not event.get("person_id") is String or not event.get("date") is String:
			return false
		if not event["person_id"].is_empty() and not people.has(event["person_id"]):
			return false
		if event["conditions"].get("target","") == "family_property":
			if not village.get("development") is Dictionary or not village["development"].get("buildings") is Dictionary:
				return false
			if not event.get("building_id") is String or not village["development"]["buildings"].has(event["building_id"]):
				return false
		if event.has("condition_before") and (not (event["condition_before"] is int or event["condition_before"] is float) or not is_finite(float(event["condition_before"])) or event["condition_before"] < 0 or event["condition_before"] > 100):
			return false
		if not _valid_effects(event["on_trigger"]):
			return false
		serials[event["serial"]] = true
		if event["choices"].is_empty():
			return false
		for choice in event["choices"]:
			if not _matches_fields(choice, {"label": "", "result": "", "effects": {}}) or not _valid_effects(choice["effects"]):
				return false
			if choice["effects"].get("study", false) and (not event.get("program_id") is String or not template.careers.programs.has(event["program_id"])):
				return false
	for entry in events["active"]:
		if not _matches_fields(entry, {"kind": "", "months": 1, "until_month": 1, "event_serial": 1, "food_multiplier": 1.0, "income_multiplier": 1.0}):
			return false
		if not is_finite(entry["food_multiplier"]) or entry["food_multiplier"] <= 0 or not is_finite(entry["income_multiplier"]) or entry["income_multiplier"] <= 0:
			return false
		if not _valid_crisis(entry):
			return false
		if entry.has("travel_until_month") and (not entry["travel_until_month"] is int or entry["travel_until_month"] < 0 or entry["travel_until_month"] > entry["until_month"]):
			return false
	for entry in events["delayed"]:
		if not _matches_fields(entry, {"due_month": 1, "amount": 1, "description": ""}):
			return false
	for entry in events["transactions"]:
		if not _matches_fields(entry, {"date": "", "amount_cents": 1, "description": ""}):
			return false
	for field in ["last_seen", "category_seen"]:
		for key in events[field]:
			if not key is String or not events[field][key] is int:
				return false
	return true


static func _valid_effects(effects: Dictionary) -> bool:
	if effects.has("skill") and not effects.has("skill_gain"):
		return false
	if effects.has("delayed_cash") and (not effects.has("delay_months") or not (effects["delay_months"] is int or effects["delay_months"] is float) or float(effects["delay_months"]) <= 0):
		return false
	var numbers := ["cash", "cash_loss", "condition", "property_condition", "capacity", "household_stress", "household_happiness", "stress", "happiness", "resentment", "trust", "skill_gain", "illness_months", "shorten_illness", "relief", "delayed_cash", "delay_months"]
	for key in effects:
		var value: Variant = effects[key]
		if key in numbers:
			if not (value is int or value is float) or not is_finite(float(value)):
				return false
		elif key in ["study", "pregnancy", "stay_release"]:
			if not value is bool:
				return false
		elif key == "currency":
			if value not in ["tuscan_lira", "tuscan_fiorino", "italian_lira"]:
				return false
		elif key in ["room", "skill"]:
			if not value is String or (key == "skill" and value not in State.Person.SKILLS):
				return false
		elif key == "crisis":
			if not _valid_crisis(value):
				return false
		else:
			return false
	return true

static func _valid_crisis(value: Variant) -> bool:
	if not value is Dictionary or not value.get("kind") is String:
		return false
	for field in ["months","food_multiplier","income_multiplier"]:
		if not (value.get(field) is int or value.get(field) is float) or not is_finite(float(value[field])) or value[field] <= 0:
			return false
	if value["months"] > 36:
		return false
	for field in ["farm_multiplier","business_cost_multiplier"]:
		if value.has(field) and (not (value[field] is int or value[field] is float) or not is_finite(float(value[field])) or value[field] < .25 or value[field] > 3):
			return false
	if value.has("travel_delay_months") and (not (value["travel_delay_months"] is int or value["travel_delay_months"] is float) or not is_finite(float(value["travel_delay_months"])) or value["travel_delay_months"] < 0 or value["travel_delay_months"] > mini(6,int(value["months"]))):
		return false
	return true


static func _normalize_legacy_money(state: Dictionary) -> void:
	# Rebase old Italian-lira amounts without changing their displayed value.
	_rebase_money(state)
	state["economy"]["currency"] = "italian_lira"
	if state["economy"].get("price_index") is float:
		state["economy"]["price_index"] /= 0.84


static func _rebase_money(value: Variant) -> void:
	if value is Dictionary:
		for key in value:
			if (str(key).ends_with("_cents") or key in ["cash", "cash_loss", "delayed_cash", "amount"]) and (value[key] is int or value[key] is float):
				value[key] = roundi(float(value[key]) / 0.84)
			else:
				_rebase_money(value[key])
	elif value is Array:
		for item in value:
			_rebase_money(item)
