extends SceneTree

const State = preload("res://Simulation/GameState.gd")
const Clock = preload("res://Simulation/GameClock.gd")
const Save = preload("res://Simulation/SaveGame.gd")
const PATH := "user://events_test.save"


func _initialize() -> void:
	call_deferred("_run")


func _state():
	var state = State.new()
	var skills: Dictionary = {}
	for skill in State.Person.SKILLS:
		skills[skill] = 100.0
	var values: Dictionary = {}
	for value in State.Person.VALUES:
		values[value] = 1.0
	state.initialize({"Giovanni": {"age": 60, "monthly_income_cents": 20000}, "Adult": {"name": "Test Relative", "age": 30, "spouse_id": "Partner", "monthly_income_cents": 7000, "life_state": {"can_be_pregnant": true}, "psychology": {"values": values, "current_state": {"stress": 0.5, "happiness": 0.5, "resentment": 0.1}}, "education": {"level": "secondary"}, "skills": skills}, "Partner": {"age": 30, "spouse_id": "Adult", "monthly_income_cents": 7000}})
	state.events.monthly_chance = 0.0
	state.economy.cash_cents = 1000000
	state.year = 1916
	state.month = 7
	return state


func _resolve_all(state) -> void:
	while not state.events.pending.is_empty():
		var event: Dictionary = state.events.pending[0]
		assert(state.events.resolve(state, event["serial"], event["choices"].size() - 1)["ok"])


func _advance(state, months: int) -> void:
	for index in range(months):
		_resolve_all(state)
		state.advance_month()
	_resolve_all(state)


func _run() -> void:
	var base = _state()
	assert(base.events.catalog.size() == 304)
	var categories: Dictionary = {}
	var ids: Dictionary = {}
	for event in base.events.catalog.values():
		assert(not ids.has(event["id"]) and not str(event["title"]).is_empty() and not str(event["body"]).is_empty())
		ids[event["id"]] = true
		categories[event["category"]] = true
		assert(event["choices"].size() >= 1)
		if event["conditions"].get("automatic_only", false):
			continue
		for choice_index in range(event["choices"].size()):
			var state = _state()
			if event["conditions"].has("historical_date"):
				state.year = int(event["conditions"]["historical_date"]["year"])
				state.month = int(event["conditions"]["historical_date"]["month"])
			if event["conditions"].has("months"):
				state.month = int(event["conditions"]["months"][0])
			var targets: Array = state.events.eligible_targets(state, event)
			assert(not targets.is_empty(), "The authored event can occur in an appropriate context: " + event["id"])
			assert(state.events.trigger(state, event["id"], targets[0]))
			var pending: Dictionary = state.events.pending[0]
			assert("{person}" not in pending["body"] and "{course}" not in pending["body"], "Story placeholders are bound")
			assert(state.events.choice_reason(state, pending, choice_index).is_empty())
			assert(state.events.resolve(state, pending["serial"], choice_index)["ok"])
			assert(state.events.pending.is_empty())
			assert(not state.events.resolve(state, pending["serial"], choice_index)["ok"], "Resolution cannot be replayed")
			assert(state.household["condition"] >= 0 and state.household["condition"] <= 100)
	assert(categories.size() == 24)

	var poor = _state()
	poor.economy.cash_cents = 0
	assert(poor.events.trigger(poor, "repairs_01"))
	var incident: Dictionary = poor.events.pending[0]
	assert(poor.household["condition"] == 74, "House damage happens when the accident is reported")
	assert(not poor.events.resolve(poor, incident["serial"], 0)["ok"])
	assert(poor.events.resolve(poor, incident["serial"], 1)["ok"])
	assert(poor.household["condition"] == 77)

	var expansion = _state()
	expansion.events.trigger(expansion, "expansion_04")
	assert(expansion.events.resolve(expansion, expansion.events.pending[0]["serial"], 0)["ok"])
	assert(expansion.household["capacity"] == 9 and "Second bedroom" in expansion.household["rooms"])

	var drought = _state()
	drought.events.trigger(drought, "drought_01")
	assert(drought.economy.event_food_multiplier > 1.0)
	assert(drought.events.eligible_targets(drought, drought.events.catalog["drought_02"]).is_empty(), "The same crisis cannot stack while active")
	_resolve_all(drought)
	_advance(drought, 3)
	assert(drought.events.active.is_empty() and drought.economy.event_food_multiplier == 1.0, "Shortages end without permanent inflation")

	var sick = _state()
	sick.events.trigger(sick, "illness_01", "Adult")
	assert(sick.people["Adult"].health.begins_with("Ill"))
	var budget: Dictionary = sick.economy.budget(sick.people, sick.household["members"])
	assert(budget["income_cents"] == 30500, "Illness reduces the patient's income without rewriting their wage")
	sick.events.resolve(sick, sick.events.pending[0]["serial"], 0)
	sick.advance_month()
	assert(sick.people["Adult"].health == "Well" and sick.events.pending[0]["id"] == "recovery")
	_resolve_all(sick)

	var pregnancy = _state()
	assert(pregnancy.events.trigger(pregnancy, "pregnancy_01", "Adult"))
	assert(not pregnancy.events.trigger(pregnancy, "pregnancy_02", "Adult"), "Pregnancies cannot overlap")
	_advance(pregnancy, 8)
	assert(pregnancy.people.size() == 3)
	pregnancy.advance_month()
	assert(pregnancy.people.size() == 4 and pregnancy.events.pending[0]["id"] == "birth")
	var child = pregnancy.people.values()[-1]
	assert(child.age == 0 and child.parent_ids == ["Adult", "Partner"] and child.id in pregnancy.household["members"])
	assert(child.branch_id == pregnancy.people["Adult"].branch_id)
	_resolve_all(pregnancy)
	_advance(pregnancy, 2)
	assert(pregnancy.people.size() == 4, "The same pregnancy only produces one birth")
	assert(not pregnancy.events.trigger(pregnancy, "pregnancy_01", "Adult"), "Birth spacing is enforced")

	var invalid = _state()
	invalid.people["Adult"].life_state["can_be_pregnant"] = false
	assert(not invalid.events.trigger(invalid, "pregnancy_01", "Adult"))
	invalid.people["Adult"].life_state["can_be_pregnant"] = true
	invalid.people["Partner"].alive = false
	assert(not invalid.events.trigger(invalid, "pregnancy_01", "Adult"))
	invalid.people["Adult"].alive = false
	assert(not invalid.events.trigger(invalid, "illness_01", "Adult"))

	var niece = _state()
	niece.people["Adult"].age = 12
	niece.events.trigger(niece, "education_01", "Adult")
	assert("parent" in niece.events.choice_reason(niece, niece.events.pending[0], 0), "Funding a child's education respects parental authority")
	niece.people["Adult"].parent_ids = ["Giovanni"]
	assert(niece.events.choice_reason(niece, niece.events.pending[0], 0).is_empty())

	var graduation = _state()
	graduation.careers.apply_request(graduation.people["Adult"], "train:architecture")
	graduation.people["Adult"].education["study"]["progress"] = float(graduation.careers.programs["architecture"]["months"]) - 0.01
	graduation.advance_month()
	assert(graduation.events.pending[0]["id"] == "graduation", "Actual graduations generate notices")
	assert("Architecture" in graduation.events.pending[0]["body"])

	var trade = _state()
	var opening: int = trade.economy.cash_cents
	trade.events.trigger(trade, "trade_01")
	trade.events.resolve(trade, trade.events.pending[0]["serial"], 0)
	assert(trade.economy.cash_cents == opening - 2000 and trade.events.delayed.size() == 1)
	_advance(trade, 3)
	assert(trade.events.delayed.is_empty() and trade.events.transactions[-1]["amount_cents"] == 2666)

	var clock = Clock.new()
	clock.state = _state()
	clock.state.events.monthly_chance = 1.0
	clock.state.elapsed_months = 1
	clock.play()
	clock.advance_time(clock.seconds_per_month() * 10)
	assert(clock.state.elapsed_months == 2 and not clock.is_playing and clock.month_progress == 0.0, "Monthly events interrupt catch-up")
	var stopped: int = clock.state.elapsed_months
	clock.play()
	clock.advance_time(1000)
	clock.state.advance_month()
	assert(clock.state.elapsed_months == stopped and not clock.is_playing, "Pending choices cannot be bypassed")
	clock.state.events.trigger(clock.state, "war_01")
	clock.state.events.trigger(clock.state, "pregnancy_01", "Adult")
	clock.state.events.trigger(clock.state, "illness_01", "Partner")
	assert(Save.save_game(clock, PATH).is_empty())
	var other = Clock.new()
	assert(Save.load_game(other, PATH).is_empty(), "Pending choices and active crises are valid save data")
	assert(other.state.to_save_data() == clock.state.to_save_data())
	_advance(clock.state, 24)
	_advance(other.state, 24)
	assert(other.state.to_save_data() == clock.state.to_save_data(), "RNG, pregnancies, illnesses, crises and choices continue identically")
	var snapshot: Dictionary = other.state.to_save_data()
	var bad: Dictionary = {"format": "TheHouse", "version": 1, "state": snapshot.duplicate(true), "clock": {"speed_level": 3, "month_progress": 0.0}}
	bad["state"]["events"]["active"] = [{"kind": "broken"}]
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_var(bad, false)
	file.close()
	assert(not Save.load_game(other, PATH).is_empty() and other.state.to_save_data() == snapshot, "Malformed event saves leave the family untouched")
	DirAccess.remove_absolute(PATH)
	clock.free()
	other.free()

	var year_run = _state()
	year_run.events.monthly_chance = 1.0
	_advance(year_run, 120)
	assert(year_run.events.last_seen.size() > 30, "A ten-year run draws varied contextual events")
	assert(year_run.events.category_seen.size() >= 15)

	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.monthly_chance = 0.0
	screen.game_clock.state.events.trigger(screen.game_clock.state, "repairs_01")
	screen._show_pending_event()
	assert(screen.event_popup.visible and not screen.game_clock.is_playing and screen.play_button.disabled)
	assert(screen.event_content.get_child(0).get_child(0).text == "Tiles after a windstorm")
	var serial: int = screen.game_clock.state.events.pending[0]["serial"]
	screen._resolve_event(serial, 1)
	assert(not screen.event_popup.visible and not screen.play_button.disabled)
	screen._show_screen("House")
	assert("Condition: 77/100" in screen.house_description.text)
	screen.game_clock.state.events.monthly_chance = 1.0
	screen.game_clock.play()
	screen.game_clock.advance_time(screen.game_clock.seconds_per_month())
	await process_frame
	assert(screen.event_popup.visible and screen.game_clock.state.elapsed_months == 1, "The next-month event opens automatically in the live UI")
	screen.event_popup.hide()
	screen.game_clock.play()
	assert(not screen.game_clock.is_playing, "Read later preserves the decision pause")
	screen._show_screen("Events")
	assert(screen.event_popup.visible, "The Events navigation reopens a deferred decision")
	screen.free()
	print("PASS: all 304 catalog entries and every choice, eligibility, costs, house damage and expansion, shortages, illness, pregnancy and birth, graduation, payouts, event pauses, deterministic saves, ten-year variety, and event UI")
	quit()
