extends RefCounted
## Isolated, deterministic century simulations; never reads/writes player saves.
const State = preload("res://Simulation/GameState.gd")
const Player = preload("res://Simulation/Testing/SimulatedPlayer.gd")
const DEFAULTS := {"years":100,"seeds":3,"seed_start":1,"strategies":["passive","frugal","education","enterprise","family"],"bonus":"discount","objective":"wealth"}

static func validate(config: Dictionary) -> String:
	for field in ["years","seeds","seed_start"]:
		if not config.get(field) is int:
			return field+" must be an integer."
	if config["years"] < 1 or config["years"] > 100 or config["seeds"] < 1 or config["seeds"] > 100 or config["seed_start"] < 0:
		return "Use 1–100 years, 1–100 seeds and a nonnegative starting seed."
	if not config.get("strategies") is Array or config["strategies"].is_empty():
		return "Choose at least one strategy."
	var seen: Dictionary = {}
	for strategy in config["strategies"]:
		if strategy not in Player.STRATEGIES or seen.has(strategy):
			return "Unknown or repeated strategy: " + str(strategy)
		seen[strategy] = true
	if config.get("bonus") not in State.Legacy.BONUSES or config.get("objective") not in State.Legacy.OBJECTIVES:
		return "Unknown bonus or objective."
	return ""

static func snapshot(state) -> Dictionary:
	var living := 0
	var stress := 0.0
	var resentment := 0.0
	var graduates := 0
	var influential := 0
	var old := 0
	var marriage_goals := 0
	var births := 0
	for person in state.people.values():
		if person.id.begins_with("Child_"):
			births += 1
		if not person.alive:
			continue
		living += 1
		stress += person.current_state["stress"]
		resentment += person.current_state["resentment"]
		if person.age > 100:
			old += 1
		if state.careers.education_rank(person) >= 3:
			graduates += 1
		if person.career_id in state.legacy.INFLUENTIAL_CAREERS and person.skills["leadership"] >= 50 and person.skills["persuasion"] >= 50:
			influential += 1
		for goal in person.goals:
			if goal.get("kind") == "seek_marriage" and goal.get("status") == "active":
				marriage_goals += 1
	var assets := 0
	var businesses := 0
	for building in state.village.development.buildings.values():
		if building["owner_id"] == "landi" and building["status"] != "demolished":
			assets += 1
			if building["type"] in state.village.business.CATALOG:
				businesses += 1
	return {"month":state.elapsed_months,"year":state.year,"cash_basis_cents":state.economy.cash_cents,"cash_italian_lire":state.economy.cash_cents*.84/100.0,"real_cash_starting_lire":state.economy.cash_cents/100.0/state.economy.price_index,"living":living,"residents":state.household["members"].size(),"births":births,"graduates":graduates,"influential":influential,"stress":stress/maxi(1,living),"resentment":resentment/maxi(1,living),"house_condition":state.household["condition"],"house_capacity":state.household["capacity"],"family_properties":assets,"family_businesses":businesses,"village_buildings":state.village.development.buildings.size(),"living_over_100":old,"unfulfilled_marriage_goals":marriage_goals,"wealth_fraction":state.economy.cash_cents/state.legacy.WEALTH_TARGET,"population_fraction":living/100.0,"objective_completed":state.legacy.completed}

static func run_one(config: Dictionary, strategy: String, seed: int) -> Dictionary:
	var error := validate(config)
	if not error.is_empty() or strategy not in config["strategies"]:
		return {"status":"invalid","error":error if not error.is_empty() else "Strategy not configured."}
	var state = State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.legacy.choose(config["objective"],config["bonus"])
	state.events.prepare_economy(state)
	state.events.rng.seed = seed
	var player = Player.new(strategy)
	var checkpoints: Array = [snapshot(state)]
	var peak_living: int = checkpoints[0]["living"]
	var min_cash: int = state.economy.cash_cents
	var debt_months := 0
	var first_debt := -1
	var pauses := 0
	var total_business_net := 0
	var completed_month := -1
	var status := "completed"
	var failure := ""
	for month_index in config["years"]*12:
		failure = player.resolve_events(state)
		if not failure.is_empty():
			status = "stalled"
			break
		player.step(state)
		var previous: int = state.elapsed_months
		state.advance_month()
		if state.elapsed_months != previous+1:
			status = "stalled"
			failure = "Month did not advance."
			break
		if state.major_event or not state.events.pending.is_empty():
			pauses += 1
		failure = player.resolve_events(state)
		if not failure.is_empty():
			status = "stalled"
			break
		min_cash = mini(min_cash,state.economy.cash_cents)
		if state.economy.cash_cents < 0:
			debt_months += 1
			if first_debt < 0:
				first_debt = state.elapsed_months
		if state.legacy.completed and completed_month < 0:
			completed_month = state.elapsed_months
		for row in state.village.business.reports.back()["rows"]:
			if row["owner_id"] == "landi":
				total_business_net += row["net_cents"]
		# Count peak population monthly; retain compact yearly history.
		var living := 0
		for person in state.people.values():
			if person.alive:
				living += 1
		peak_living = maxi(peak_living,living)
		if state.elapsed_months % 12 == 0:
			checkpoints.append(snapshot(state))
	var final := snapshot(state)
	if checkpoints.back()["month"] != final["month"]:
		checkpoints.append(final)
	var warnings: Array[String] = []
	if final["living_over_100"] > 0:
		warnings.append("People over 100 remain alive: mortality and succession are incomplete.")
	if final["unfulfilled_marriage_goals"] > 0:
		warnings.append("Accepted marriage requests remain goals; new partners are not generated.")
	return {"strategy":strategy,"seed":seed,"status":status,"error":failure,"months_simulated":state.elapsed_months,"first_debt_month":first_debt,"debt_months":debt_months,"minimum_cash_cents":min_cash,"peak_living":peak_living,"major_pause_months":pauses,"objective_completed_month":completed_month,"business_net_basis_cents":total_business_net,"decisions":player.counts,"last_100_decisions":player.decisions,"checkpoints":checkpoints,"final":final,"warnings":warnings}

static func summarize(runs: Array) -> Dictionary:
	var groups: Dictionary = {}
	for run in runs:
		if not groups.has(run["strategy"]):
			groups[run["strategy"]] = []
		groups[run["strategy"]].append(run)
	var summary: Dictionary = {}
	for strategy in groups:
		var rows: Array = groups[strategy]
		var metrics: Dictionary = {}
		for field in ["cash_italian_lire","living","graduates","influential","stress","resentment","family_businesses","wealth_fraction"]:
			var values: Array = []
			for run in rows:
				values.append(run["final"][field])
			values.sort()
			var middle: int = values.size()/2
			var median: float = values[middle] if values.size()%2 else (values[middle-1]+values[middle])/2.0
			metrics[field] = {"min":values.front(),"median":median,"max":values.back()}
		var completed := 0
		var wins := 0
		var debt := 0
		for run in rows:
			completed += 1 if run["status"] == "completed" else 0
			wins += 1 if run["final"]["objective_completed"] else 0
			debt += 1 if run["debt_months"] > 0 else 0
		summary[strategy] = {"runs":rows.size(),"completed_runs":completed,"objective_wins":wins,"runs_with_debt":debt,"metrics":metrics}
	return summary
