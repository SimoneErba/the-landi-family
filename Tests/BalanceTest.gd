extends SceneTree
const State = preload("res://Simulation/GameState.gd")
func _initialize() -> void:
	call_deferred("_run")
func _state():
	var state = State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.events.enabled = false
	state.economy.cash_cents = 10000000
	return state
func _run() -> void:
	var household = State.new()
	household.initialize({"Worker":{"monthly_income_cents":3500},"Dependent":{}})
	household.economy.price_index = pow(1+household.economy.MONTHLY_INFLATION,1200)
	assert(household.economy.budget(household.people,household.household["members"])["net_cents"] > 0, "A modest working couple must not be forced into losses purely by a century of inflation")
	household.people["Worker"].monthly_income_cents = 0
	assert(household.economy.budget(household.people,household.household["members"])["net_cents"] < 0, "Dependents still need funded support")
	var state = _state()
	state.village.development.buildings["workshop"]["type"] = "factory"
	var business = state.village.business
	var factory: Dictionary = business.estimate(state,"workshop",2)
	assert(factory["net_cents"] > 0, "A baseline adequately staffed factory must cover its inputs")
	assert(business.estimate(state,"workshop",1)["revenue_cents"] == 0, "Factories still require twice the labor")
	state.village.development.buildings["workshop"]["condition"] = 25.0
	assert(business.estimate(state,"workshop",2)["net_cents"] < 0, "Neglected production still creates a financial reason to repair")
	var investment = _state()
	var neighbor = investment.village.households["rossi"]
	var reserve := 1200 + 3 * (290 + 500)
	neighbor.cash_cents = investment.village.development.COST + 1500
	assert(not investment.village.development.invest(investment,"rossi"), "Building work must not consume operating funds")
	neighbor.cash_cents = investment.village.development.COST + reserve
	assert(investment.village.development.invest(investment,"rossi"))
	assert(neighbor.cash_cents == reserve, "Affordable development retains the three-month operating reserve")
	for type in ["farm","workshop","tavern","factory"]:
		state = _state()
		var id: String = {"farm":"farm","workshop":"workshop","factory":"workshop","tavern":"tavern"}[type]
		state.village.development.transfer(state,id,"landi")
		state.village.development.buildings[id]["type"] = type
		state.people[state.head_id].skills[state.village.business.CATALOG[type]["skill"]] = 50.0
		state.village.business.propose(state,state.head_id,id)
		var annual := 0
		for month in range(1,13):
			state.month = month
			annual += state.village.business.estimate(state,id)["net_cents"]
		var years: float = state.village.development.COST / float(annual)
		assert(years > 1 and years < 6, "A healthy moderately skilled business should repay construction over several years, not a few months or a generation: " + type)
	for employed in [true,false]:
		state = _state()
		state.village.development.transfer(state,"workshop","landi")
		var manager = state.people[state.head_id]
		manager.current_state["stress"] = .2
		manager.monthly_income_cents = 8000 if employed else 0
		state.village.business.propose(state,state.head_id,"workshop")
		for index in 60:
			state.elapsed_months += 1
			manager.advance_month(state.year,state.month,false)
			state.village.business.advance_month(state)
		assert(manager.current_state["stress"] < .7, "Five years of ordinary management must not guarantee maximum stress")
		if not employed:
			assert(manager.current_state["stress"] < .2, "Full-time management leaves room for recovery")
	print("PASS: century food affordability, business payback, factory labor and margins, neglect losses, sustainable management workload")
	quit()
