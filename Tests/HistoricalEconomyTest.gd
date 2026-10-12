extends SceneTree
const State = preload("res://Simulation/GameState.gd")
const Clock = preload("res://Simulation/GameClock.gd")
const Save = preload("res://Simulation/SaveGame.gd")

func _initialize() -> void:
	call_deferred("_run")

func _state():
	var state = State.new()
	state.initialize({"Giovanni": {"age": 50, "monthly_income_cents": 6000}, "Learner": {"age": 20, "career_id": "builder", "monthly_income_cents": 4000, "education": {"level": "primary"}}})
	state.events.enabled = false
	state.succession.enabled = false
	return state

func _run() -> void:
	var state = _state()
	assert(state.careers.jobs["carpenter"]["monthly_income_cents"] == 4000)
	assert(state.careers.jobs["teacher"]["monthly_income_cents"] == 5600)
	assert(state.careers.programs["primary"]["tuition_cents"] == 0)
	assert(state.careers.programs["primary"]["monthly_cost_cents"] == 50)
	var learner = state.people["Learner"]
	var opening: Dictionary = learner.to_save_data()
	state.economy.cash_cents = 100000
	state.careers.funding_reason(state, learner, "primary")
	assert(learner.to_save_data() == opening, "Pricing a course must not mutate real employment")
	state.careers.apply_request(learner, "train:primary")
	assert(learner.monthly_income_cents == 2000 and learner.career_id == "builder")
	learner.education["study"]["progress"] = 23.99
	state.advance_month()
	assert(learner.education["study"].is_empty() and learner.monthly_income_cents == 4000, "Day lessons resume existing work on completion")
	# Work placements earn while learning, even if another course cannot be funded.
	state = _state()
	learner = state.people["Learner"]
	state.economy.cash_cents = 0
	assert(state.careers.funding_reason(state, learner, "carpentry").is_empty(), "A zero-fee placement that covers bills does not need a tuition reserve")
	state.careers.apply_request(learner, "train:carpentry")
	assert(learner.monthly_income_cents == 600)
	state.economy.cash_cents = -100000
	state.advance_month()
	assert(learner.monthly_income_cents > 600 and learner.education["study"]["progress"] > 0)
	assert(state.economy.ledger[-1]["tuition_cents"] == 0)
	learner.education["study"]["progress"] = 23.99
	state.advance_month()
	assert(learner.monthly_income_cents == 0 and learner.job == "Seeking work", "A completed placement cannot pay a ghost stipend")
	assert("carpentry_apprenticeship" in learner.education["qualifications"])
	# Board reduces household food only when the board bill is paid.
	state = _state()
	state.economy.cash_cents = 100000
	state.careers.apply_request(state.people["Learner"], "train:boarding_secondary")
	var boarding: Dictionary = state.economy.budget(state.people, state.household["members"], state.household)
	assert(boarding["tuition_cents"] == 1850 and boarding["food_cents"] == 1000 and boarding["food_support_cents"] == 1000)
	state.economy.cash_cents = -100000
	var unpaid: Dictionary = state.economy.budget(state.people, state.household["members"], state.household)
	assert(unpaid["tuition_cents"] == 0 and unpaid["food_support_cents"] == 0)
	assert(unpaid["expenses_cents"] == unpaid["food_cents"] + unpaid["essentials_cents"] + unpaid["care_cents"] + unpaid["upkeep_cents"] + unpaid["taxes_cents"])
	# Shared produce cannot be multiplied by adding workers to the same family farm.
	state = _state()
	state.people["Giovanni"].career_id = "farmer"
	var one: Dictionary = state.economy.budget(state.people, state.household["members"], state.household)
	state.people["Learner"].career_id = "farmer"
	var two: Dictionary = state.economy.budget(state.people, state.household["members"], state.household)
	assert(one["food_support_cents"] == 700 and two["food_support_cents"] == 700)
	# Save contracts and reject malformed money; future offers use the new catalogue.
	var clock = Clock.new()
	clock.state = _state()
	clock.state.careers.apply_request(clock.state.people["Learner"], "train:sewing")
	clock.state.economy.cash_cents = 100000
	clock.state.advance_month()
	assert(Save.save_game(clock, "user://historical_economy.save").is_empty())
	var restored = Clock.new()
	assert(Save.load_game(restored, "user://historical_economy.save").is_empty())
	assert(restored.state.to_save_data() == clock.state.to_save_data())
	clock.state.advance_month()
	restored.state.advance_month()
	assert(restored.state.to_save_data() == clock.state.to_save_data())
	var corrupt: Dictionary = clock.state.people["Learner"].education["study"]["terms"].duplicate()
	corrupt["stipend_start_cents"] = -1
	assert(not State.Careers.valid_terms(corrupt))
	var legacy: Dictionary = clock.state.to_save_data()
	legacy["careers"]["jobs"]["carpenter"]["monthly_income_cents"] = 8500
	restored.state.restore_save_data(legacy)
	assert(restored.state.careers.jobs["carpenter"]["monthly_income_cents"] == 4000)
	assert(restored.state.people["Learner"].monthly_income_cents == clock.state.people["Learner"].monthly_income_cents)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://historical_economy.save"))
	clock.free()
	restored.free()
	print("PASS: historical calibration, subsidized lessons, retained work, paid apprenticeships, no ghost pay, funded board, shared produce, contracts and save migration")
	quit()
