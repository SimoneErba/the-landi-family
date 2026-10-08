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
	if not _matches_fields(data.get("state"), template.to_save_data()):
		return false
	if not _matches_fields(data.get("clock"), {"speed_level": 1, "month_progress": 0.0}):
		return false
	var timing: Dictionary = data["clock"]
	if timing["speed_level"] < 1 or timing["speed_level"] > 5 or not is_finite(timing["month_progress"]) or timing["month_progress"] < 0.0:
		return false
	var state: Dictionary = data["state"]
	if state["month"] < 1 or state["month"] > 12 or state["elapsed_months"] < 0 or not state["people"].has(state["head_id"]):
		return false
	if state["economy"].get("currency") not in ["tuscan_lira", "tuscan_fiorino", "italian_lira"]:
		return false
	if not _valid_events(state["events"], template, state["people"]):
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
		for field in ["temperament", "values", "learned_tendencies", "current_state", "abilities", "skills", "interests"]:
			if not _matches_fields(person[field], person_template[field]):
				return false
		if person["in_household"] != (person_id in state["household"]["members"]):
			return false
	var seen: Dictionary = {}
	for member in state["household"]["members"]:
		if not member is String or not state["people"].has(member) or seen.has(member):
			return false
		seen[member] = true
	return true


static func _valid_events(events: Variant, template, people: Dictionary) -> bool:
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
	var numbers := ["cash", "cash_loss", "condition", "capacity", "household_stress", "household_happiness", "stress", "happiness", "resentment", "trust", "skill_gain", "illness_months", "shorten_illness", "relief", "delayed_cash", "delay_months"]
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
		else:
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
