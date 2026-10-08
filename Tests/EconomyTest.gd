extends SceneTree

const State = preload("res://Simulation/GameState.gd")
const Clock = preload("res://Simulation/GameClock.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state = State.new()
	state.initialize({"Resident": {"monthly_income_cents": 0}})
	state.events.enabled = false
	assert(state.date_text() == "January 1800")
	assert(state.economy.cash_cents == 10000)
	state.advance_month()
	assert(state.economy.cash_cents == 9000)
	assert(state.economy.ledger[0]["date"] == "January 1800")
	assert(state.economy.food_per_person_cents() == 1002)
	state.advance_month()
	assert(state.economy.cash_cents == 7998, "Inflated second bill is 10.02 lire")
	for index in range(10):
		state.advance_month()
	assert(state.date_text() == "January 1801")
	assert(is_equal_approx(state.economy.price_index, pow(1.0 + 0.02 / 12.0, 12)))
	assert(state.economy.ledger.size() == 12)

	var household = State.new()
	household.initialize({"Worker": {"monthly_income_cents": 2000}, "Dependent": {}, "Away": {"monthly_income_cents": 7000}})
	household.events.enabled = false
	household.household["members"] = ["Worker", "Dependent"]
	household.advance_month()
	assert(household.economy.cash_cents == 10000, "Two residents cost 20 lire; only resident income contributes")
	household.household["members"].erase("Worker")
	household.advance_month()
	assert(household.economy.cash_cents == 8998, "Departed worker no longer earns or eats at home")
	household.people["Dependent"].monthly_income_cents = 3000
	household.advance_month()
	assert(household.economy.ledger[-1]["income_cents"] == 3000, "Job changes affect next settlement")

	var clock = Clock.new()
	clock.state.initialize({"Resident": {}})
	clock.state.events.enabled = false
	clock.play()
	clock.advance_time(clock.seconds_per_month() * 20)
	assert(not clock.is_playing and clock.state.elapsed_months == 10, "First unpaid bill interrupts catch-up")
	assert(clock.state.economy.cash_cents < 0)
	clock.free()

	root.size = Vector2i(1920, 1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen.game_clock.state.events.enabled = false
	screen._show_screen("Finances")
	assert(screen.cash_label.text == "100 lire toscane")
	assert(screen.finance_content.find_child("BalanceValue", true, false).text == "100 L.")
	screen.game_clock.play()
	screen.game_clock.advance_time(15)
	assert(screen.cash_label.text == "315 lire toscane")
	assert(screen.finance_content.find_child("BalanceValue", true, false).text == "315 L.")
	assert(screen.game_clock.state.economy.ledger[0]["food_cents"] == 7000)
	screen._show_screen("House")
	screen.game_clock.advance_time(15)
	assert(screen.cash_label.text == "529 lire toscane, 17s 2d")
	screen._show_screen("Finances")
	assert(screen.finance_content.find_child("BalanceValue", true, false).text == "529 L., 17s 2d")
	screen.free()
	print("PASS: monthly bills, inflation compounding, earnings, membership, job changes, crisis pause, ledger, and live finances UI")
	quit()
