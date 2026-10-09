extends SceneTree
## Repeatable probes: controlled economic scenarios plus seeded autonomous runs.
const State = preload("res://Simulation/GameState.gd")
var results: Dictionary = {"businesses":[], "households":[], "runs":[]}

func _initialize() -> void:
	call_deferred("_run")

func _state(bonus: String = "discount"):
	var state = State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.legacy.choose("wealth", bonus)
	state.events.prepare_economy(state)
	return state

func _businesses() -> void:
	for type in ["farm","workshop","factory","tavern"]:
		for level in [1,3]:
			var state = _state("learning")
			var dev = state.village.development
			var id: String = {"farm":"farm","workshop":"workshop","factory":"workshop","tavern":"tavern"}[type]
			dev.transfer(state,id,"landi")
			dev.buildings[id]["type"] = type
			dev.buildings[id]["level"] = level
			state.people[state.head_id].skills[state.village.business.CATALOG[type]["skill"]] = 50.0
			state.village.business.propose(state,state.head_id,id)
			var annual := 0
			var minimum := 999999
			for month in range(1,13):
				state.month = month
				var estimate: Dictionary = state.village.business.estimate(state,id)
				annual += estimate["net_cents"]
				minimum = mini(minimum,estimate["net_cents"])
			results["businesses"].append({"type":type,"level":level,"annual_net_lire":annual/100.0,"worst_month_lire":minimum/100.0,"capital_payback_years":dev.COST*level/float(annual) if annual>0 else -1})

func _households() -> void:
	for wage in [2000,3500,8000]:
		var state = State.new()
		state.initialize({"Worker":{"monthly_income_cents":wage},"Dependent":{}})
		for months in [0,120,600,1200]:
			state.economy.price_index = pow(1+state.economy.MONTHLY_INFLATION, months)
			var budget: Dictionary = state.economy.budget(state.people,state.household["members"])
			results["households"].append({"base_wage_lire":wage/100.0,"year":months/12,"real_net_lire":budget["net_cents"]/100.0/state.economy.price_index})

func _resolve(state, policy: String) -> void:
	for event in state.events.pending.duplicate():
		var choice := -1
		var best := -INF
		for index in event["choices"].size():
			if not state.events.choice_reason(state,event,index).is_empty():
				continue
			var effects: Dictionary = event["choices"][index]["effects"]
			var score: float = float(effects.get("cash",0))/10000.0
			if policy == "support":
				score = float(effects.get("happiness",0))*10 + float(effects.get("trust",0))*10 - float(effects.get("stress",0))*10 + (1.0 if effects.get("study",false) else 0.0)
			if score > best:
				best = score
				choice = index
		if choice >= 0:
			state.events.resolve(state,event["serial"],choice)

func _run() -> void:
	_businesses()
	_households()
	var seeds := 2
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seeds="):
			seeds = clampi(argument.trim_prefix("--seeds=").to_int(),1,32)
	print("BUSINESSES: " + JSON.stringify(results["businesses"]))
	print("HOUSEHOLDS: " + JSON.stringify(results["households"]))
	for policy in ["save","support"]:
		for seed in range(1,seeds+1):
			var state = _state("fertility" if policy == "support" else "discount")
			state.events.rng.seed = seed
			var first_debt := -1
			var peak_living := 0
			for index in 1200:
				_resolve(state,policy)
				state.advance_month()
				if state.economy.cash_cents < 0 and first_debt < 0:
					first_debt = state.elapsed_months
				var living := 0
				for person in state.people.values():
					if person.alive:
						living += 1
				peak_living = maxi(peak_living,living)
			_resolve(state,policy)
			var poorest := 999999999
			for household in state.village.households.values():
				poorest = mini(poorest,household.cash_cents)
			results["runs"].append({"policy":policy,"seed":seed,"months":state.elapsed_months,"ending_lire":state.economy.cash_cents/100.0,"first_debt_month":first_debt,"peak_living":peak_living,"wealth_goal_fraction":state.economy.cash_cents/state.legacy.WEALTH_TARGET,"poorest_neighbor_lire":poorest/100.0,"buildings":state.village.development.buildings.size()})
			print("RUN: " + JSON.stringify(results["runs"].back()))
			_write_results()
	_write_results()
	print("PASS: balance probes completed: 8 business scenarios, 12 wage scenarios, %d seeded century runs" % (seeds*2))
	quit()

func _write_results() -> void:
	var file = FileAccess.open("res://.godot/balance-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "))
