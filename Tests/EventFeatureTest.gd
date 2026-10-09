extends SceneTree
const State = preload("res://Simulation/GameState.gd")
const Save = preload("res://Simulation/SaveGame.gd")
func _initialize() -> void:
	call_deferred("_run")
func _state():
	var state = State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.events.monthly_chance = 0.0
	state.economy.cash_cents = 1000000
	state.village.development.transfer(state,"farm","landi")
	state.village.development.transfer(state,"workshop","landi")
	return state
func _valid(state) -> bool:
	return Save._valid_save({"state":state.to_save_data(),"clock":{"speed_level":1,"month_progress":0.0}})
func _clear(state) -> void:
	while not state.events.pending.is_empty():
		var event: Dictionary = state.events.pending[0]
		assert(state.events.resolve(state,event["serial"],event["choices"].size()-1)["ok"])
func _run() -> void:
	var state = _state()
	var business = state.village.business
	assert(business.propose(state,"Giovanni","farm")["ok"])
	state.month = 7
	var before: Dictionary = business.estimate(state,"farm")
	var workshop_before: Dictionary = business.estimate(state,"workshop")
	assert(state.events.trigger(state,"drought_01"))
	assert(business.estimate(state,"farm")["revenue_cents"] < before["revenue_cents"])
	assert(business.estimate(state,"workshop")["revenue_cents"] == workshop_before["revenue_cents"])
	assert(_valid(state), "New crisis factors survive validation")
	_clear(state)
	var duration: int = state.events.active[0]["months"]
	for month in range(1,duration+1):
		state.elapsed_months = month
		assert(state.events.business_multiplier(state,"farm_multiplier",true) == .65, "Every completed drought month affects production")
	assert(state.events.business_multiplier(state,"farm_multiplier") == 1.0, "Current estimates recover when the crisis expires")
	state = _state()
	var traveler = state.people["Carlo"]
	traveler.values["independence"] = 1.0
	traveler.values["security"] = 0.0
	traveler.current_state["resentment"] = 0.0
	traveler.current_state["stress"] = 0.0
	traveler.interests["practical"] = 100.0
	assert(state.travel.propose(state,"Carlo","milan","work")["ok"])
	var journey: Dictionary = state.travel.current("Carlo")
	assert(state.events.trigger(state,"war_01"))
	assert(not state.events.travel_disruption(state).is_empty())
	assert(state.village.business.estimate(state,"workshop")["cost_cents"] > 100)
	_clear(state)
	var opening: int = state.economy.cash_cents
	for month in [1,2]:
		state.elapsed_months = month
		state.travel.advance_month(state)
		assert(journey["remaining_months"] == 2)
	assert(not journey["interruption_reason"].is_empty() and state.economy.cash_cents == opening, "War delays prepaid travel without charging another fare")
	assert(_valid(state))
	var restored = State.new()
	restored.restore_save_data(state.to_save_data())
	assert(restored.to_save_data() == state.to_save_data())
	state.elapsed_months = 3
	state.travel.advance_month(state)
	assert(journey["remaining_months"] == 1 and journey["interruption_reason"].is_empty())
	state.elapsed_months = 4
	state.travel.advance_month(state)
	assert(journey["status"] == "staying")
	assert(state.events.trigger(state,"illness_01","Carlo"), "Illness can reach an active traveler")
	assert("News from Milan" in state.events.pending[0]["body"])
	_clear(state)
	state.travel.advance_month(state)
	assert(journey["progress"] == 0, "Illness pauses the placement")
	state = _state()
	var dev = state.village.development
	assert(state.events.trigger(state,"property_repairs_01"))
	var incident: Dictionary = state.events.pending[0]
	var building_id: String = incident["building_id"]
	assert(incident["person_id"].is_empty() and "{property}" not in incident["body"])
	assert(dev.buildings[building_id]["condition"] == 68.0 and dev.view_at(0)["buildings"][building_id]["condition"] == 68.0)
	assert(_valid(state))
	opening = state.economy.cash_cents
	var damaged_save := {"state":state.to_save_data(),"clock":{"speed_level":1,"month_progress":0.0}}
	damaged_save["state"]["village"]["development"]["buildings"] = "invalid"
	assert(not Save._valid_save(damaged_save), "Malformed saved property references fail cleanly")
	assert(state.events.resolve(state,incident["serial"],0)["ok"])
	assert(dev.buildings[building_id]["condition"] == 80.0 and state.economy.cash_cents == opening-2000)
	assert(not state.events.resolve(state,incident["serial"],0)["ok"])
	assert(state.events.trigger(state,"repairs_01"))
	assert(dev.buildings["home"]["condition"] == float(state.household["condition"]), "Home damage updates the map immediately")
	_clear(state)
	assert(_valid(state))
	assert(state.events.trigger(state,"property_repairs_01"))
	incident = state.events.pending[0]
	assert(dev.transfer(state,incident["building_id"],"rossi"))
	assert(not state.events.choice_reason(state,incident,0).is_empty(), "No paid repair after the property is sold")
	assert(state.events.resolve(state,incident["serial"],2)["ok"], "A stale property event retains a legal resolution")
	state = _state()
	for building in state.village.development.buildings.values():
		if building["owner_id"] == "landi" and building["type"] in ["farm","workshop"]:
			building["condition"] = 5.0
	assert(state.events.trigger(state,"property_repairs_01"))
	incident = state.events.pending[0]
	assert(state.events.resolve(state,incident["serial"],0)["ok"])
	assert(state.village.development.buildings[incident["building_id"]]["condition"] == 5.0, "Incident repairs restore only the condition actually lost")
	state = _state()
	var mother = state.people["Maria"]
	mother.age = 30
	mother.birth_year = 1770
	mother.interests["practical"] = 100.0
	mother.values["family_loyalty"] = 1.0
	mother.current_state["resentment"] = 0.0
	mother.current_state["stress"] = 0.0
	assert(state.village.business.propose(state,"Maria","workshop")["ok"])
	assert(state.events.trigger(state,"pregnancy_01","Maria"))
	_clear(state)
	state.elapsed_months = 7
	assert(state.village.business.estimate(state,"workshop")["status"] == "Manager on family care leave")
	state.elapsed_months = 9
	state.events.advance_month(state)
	assert(mother.life_state["recovery_until_month"] == 12 and mother.life_state["pregnancy"].is_empty())
	assert(state.people.size() == 8 and state.household["members"].size() == 8)
	assert(state.village.business.commitment("Maria") == "workshop", "Leave preserves the management assignment")
	assert(_valid(state))
	_clear(state)
	for month in [10,11,12]:
		state.elapsed_months = month
		assert(state.village.business.estimate(state,"workshop",99,true)["revenue_cents"] == 0)
	state.elapsed_months = 13
	assert(state.village.business.estimate(state,"workshop",99,true)["revenue_cents"] > 0)
	state.village.business.release(state,"workshop")
	mother.life_state["recovery_until_month"] = 16
	assert(not state.activities.reason(state,"Maria","repair").is_empty())
	mother.life_state["recovery_until_month"] = 13
	assert(state.activities.propose(state,"Maria","repair")["ok"])
	var plan = state.activities.commitment("Maria")
	mother.life_state["recovery_until_month"] = 16
	opening = state.economy.cash_cents
	state.activities.advance_month(state)
	assert(plan.status == "interrupted" and plan.progress_months == 0 and state.economy.cash_cents == opening)
	var invalid := {"state":state.to_save_data(),"clock":{"speed_level":1,"month_progress":0.0}}
	invalid["state"]["people"]["Maria"]["life_state"]["recovery_until_month"] = "invalid"
	assert(not Save._valid_save(invalid))
	print("PASS: drought farm yields and expiry, wartime inputs and travel delays, illness away, persistent property damage and stale ownership, childbirth leave and save validation")
	quit()
