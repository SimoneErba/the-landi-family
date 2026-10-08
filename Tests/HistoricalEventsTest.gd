extends SceneTree

const State = preload("res://Simulation/GameState.gd")
const Clock = preload("res://Simulation/GameClock.gd")
const Save = preload("res://Simulation/SaveGame.gd")
const PATH := "user://historical_events_test.save"

func _initialize() -> void:
	call_deferred("_run")

func _state():
	var state = State.new()
	state.initialize({"Giovanni": {"age": 45, "name": "Giovanni Landi", "monthly_income_cents": 20000}})
	state.events.monthly_chance = 0.0
	return state

func _run() -> void:
	var state = _state()
	assert(state.date_text() == "January 1800")
	assert(state.economy.money(10000) == "100 lire toscane")
	assert(state.economy.money(5) == "0 lire toscane, 1s 0d")
	assert(state.economy.money(-10000) == "−100 lire toscane")
	assert(state.events.eligible_targets(state, state.events.catalog["celebration_04"]).is_empty(), "No photographs in 1800")
	assert(state.events.eligible_targets(state, state.events.catalog["rural_01"]).is_empty(), "Olive harvest waits for autumn")
	assert(state.events.is_wartime(1800, 6) and not state.events.is_wartime(1830, 6))
	assert(not state.events.is_wartime(1914, 8) and state.events.is_wartime(1915, 5), "Italian neutrality precedes entry into WWI")
	# Every fixed event is delivered on its authored month, even with random chance zero.
	var history_count := 0
	for entry in state.events.catalog.values():
		if not entry["conditions"].has("historical_date"):
			continue
		history_count += 1
		var date: Dictionary = entry["conditions"]["historical_date"]
		var isolated = _state()
		isolated.year = int(date["year"])
		isolated.month = int(date["month"]) - 1
		if isolated.month == 0:
			isolated.month = 12
			isolated.year -= 1
		assert(not isolated.events.trigger(isolated, entry["id"]), "No historical news before its date")
		isolated.advance_month()
		assert(isolated.events.pending.any(func(event): return event["id"] == entry["id"]))
		assert(isolated.major_event)
		assert(not isolated.events.trigger(isolated, entry["id"]), "Dated events cannot be repeated")
	assert(history_count == 37)

	var clock = Clock.new()
	clock.state = _state()
	clock.state.year = 1825
	clock.state.month = 12
	clock.play()
	clock.advance_time(clock.seconds_per_month() * 3)
	assert(clock.state.date_text() == "January 1826" and not clock.is_playing)
	assert(clock.state.events.pending[0]["id"] == "history_fiorino")
	assert(clock.state.economy.currency == "tuscan_lira", "Accounts change when the reform is acknowledged")
	assert(Save.save_game(clock, PATH).is_empty())
	var loaded = Clock.new()
	assert(Save.load_game(loaded, PATH).is_empty())
	assert(loaded.state.to_save_data() == clock.state.to_save_data(), "An outstanding currency reform survives reload")
	var cash: int = loaded.state.economy.cash_cents
	assert(loaded.state.events.resolve(loaded.state, loaded.state.events.pending[0]["serial"], 0)["ok"])
	assert(loaded.state.economy.currency == "tuscan_fiorino" and loaded.state.economy.cash_cents == cash)
	assert(loaded.state.economy.money(10000) == "60.00 fiorini")
	assert(loaded.state.economy.money(1000) == "6.00 fiorini")
	loaded.state.year = 1859
	loaded.state.month = 11
	assert(loaded.state.events.trigger(loaded.state, "history_italian_lira"))
	assert(loaded.state.events.resolve(loaded.state, loaded.state.events.pending[0]["serial"], 0)["ok"])
	assert(loaded.state.economy.money(10000) == "84.00 lire italiane")
	assert(loaded.state.economy.money(-10000) == "−84.00 lire italiane")
	assert(loaded.state.economy.money(1000) == "8.40 lire italiane")
	assert(loaded.state.people["Giovanni"].monthly_income_cents == 20000, "Wage value is preserved with the balance")
	assert(Save.save_game(loaded, PATH).is_empty())
	assert(Save.load_game(clock, PATH).is_empty() and clock.state.to_save_data() == loaded.state.to_save_data())
	# A legacy Italian-lira save keeps its value after rebasing the shared accounting unit.
	var legacy: Dictionary = {"format": "TheHouse", "version": 1, "state": loaded.state.to_save_data(), "clock": {"speed_level": 3, "month_progress": 0.0}}
	legacy["state"]["economy"].erase("currency")
	legacy["state"]["economy"]["cash_cents"] = 10000
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_var(legacy, false)
	file.close()
	assert(Save.load_game(clock, PATH).is_empty())
	assert(clock.state.economy.money(clock.state.economy.cash_cents) == "100.00 lire italiane")
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	assert(screen.get_node("TopBar").find_child("Title", true, false).text == "The Landi family")
	screen.free()
	DirAccess.remove_absolute(PATH)
	clock.free()
	loaded.free()
	print("PASS: 1800 Tuscany, 37 fixed events, technology and seasonal gates, Italian wartime periods, currency reforms, pause, save continuation, and legacy money")
	quit()
