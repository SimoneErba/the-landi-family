extends SceneTree

const State = preload("res://Simulation/GameState.gd")
const Clock = preload("res://Simulation/GameClock.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")
const PATH := "user://economy_balance_test.save"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state = State.new()
	state.initialize({"Giovanni": {"age": 30, "monthly_income_cents": 8000}, "Student": {"age": 25, "monthly_income_cents": 4000, "job": "Farm worker", "parent_ids": ["Giovanni"]}, "Child": {"age": 3}, "Elder": {"age": 75, "monthly_income_cents": 4000}})
	state.events.enabled = false
	var budget: Dictionary = state.economy.budget(state.people, state.household["members"], state.household)
	assert(budget["food_cents"] == 3650)
	assert(budget["essentials_cents"] == 1750 and budget["care_cents"] == 550 and budget["upkeep_cents"] == 1000)
	assert(budget["income_cents"] == 14800, "Older workers earn reduced pay")
	assert(budget["taxable_mouths"] == 4 and budget["household_tax_class"] == 4)
	assert(budget["expenses_cents"] == 7214 and budget["net_cents"] == 7586)
	var expanded: Dictionary = state.household.duplicate(true)
	expanded["rooms"].append("Nursery")
	assert(state.economy.budget(state.people, state.household["members"], expanded)["upkeep_cents"] == 1200)
	state.people["Elder"].age = 95
	assert(state.economy.earnings(state.people["Elder"]) == 0)
	state.people["Student"].life_state["illness"] = {"until_month": 12}
	assert(state.economy.earnings(state.people["Student"]) == 2000)
	state.people["Student"].life_state.clear()
	state.economy.cash_cents = -1000
	var frugal: Dictionary = state.economy.budget(state.people, state.household["members"], state.household)
	assert(frugal["economizing"] and frugal["living_costs_cents"] < budget["living_costs_cents"])
	assert(frugal["care_cents"] == budget["care_cents"], "Necessary care is not cut in debt")
	assert(state.economy.total_expenses({"food_cents": 1000, "tuition_cents": 500}) == 1500, "Old ledgers remain readable")
	var student = state.people["Student"]
	state.economy.cash_cents = 0
	assert(not state.careers.request_reason(state, student, "train:primary").is_empty(), "One fee is not enough to commit to a course")
	state.economy.cash_cents = 1000000
	assert(state.careers.request_reason(state, student, "train:primary").is_empty())
	state.careers.apply_request(student, "train:primary")
	student.education["study"]["progress"] = 4.0
	student.monthly_income_cents = 0
	state.people["Giovanni"].monthly_income_cents = 0
	state.economy.cash_cents = 0
	for month in 3: state.advance_month()
	assert(student.education["study"]["suspended"] and student.education["study"]["progress"] == 4.0)
	assert(student.monthly_income_cents == 4000 and student.job == "Farm worker", "Unfunded adults return to their previous paid work")
	assert(state.economy.budget(state.people, state.household["members"])["planned_tuition_cents"] == 0)
	var clock = Clock.new()
	clock.state = state
	assert(SaveGame.save_game(clock, PATH).is_empty())
	var restored = Clock.new()
	assert(SaveGame.load_game(restored, PATH).is_empty())
	assert(restored.state.people["Student"].education["study"] == student.education["study"], "Suspended progress and previous employment survive a save")
	state.economy.cash_cents = 1000000
	state.careers.apply_request(student, "train:primary")
	assert(not student.education["study"]["suspended"] and student.education["study"]["progress"] == 4.0)
	assert(student.monthly_income_cents == 2000, "Resuming day lessons retains half of paid work")
	clock.free()
	restored.free()
	DirAccess.remove_absolute(PATH)
	print("PASS: recurring costs, dependent care, aging/illness earnings, debt economies, protected study funding, suspended work recovery and save compatibility")
	quit()
