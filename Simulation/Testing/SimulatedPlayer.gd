extends RefCounted
## Deterministic policies use public game commands; consent is never bypassed.
const STRATEGIES := ["passive", "frugal", "education", "enterprise", "family"]
var strategy := "passive"
var cooldowns: Dictionary = {}
var counts: Dictionary = {}
var decisions: Array = []

func _init(selected: String = "passive") -> void:
	strategy = selected

func _record(state, kind: String, target: String, outcome: String, response: String) -> void:
	counts[kind] = int(counts.get(kind,0)) + 1
	counts["outcome:"+outcome] = int(counts.get("outcome:"+outcome,0)) + 1
	decisions.append({"month":state.elapsed_months,"kind":kind,"target":target,"outcome":outcome,"response":response})
	if decisions.size() > 100:
		decisions.pop_front()

func _ready_for(state, key: String, interval: int = 12) -> bool:
	if state.elapsed_months < cooldowns.get(key,-interval) + interval:
		return false
	cooldowns[key] = state.elapsed_months
	return true

func resolve_events(state) -> String:
	# Drain milestones too, with a bound that detects an unexpected event cycle.
	for round_index in 100:
		if state.events.pending.is_empty():
			return ""
		var event: Dictionary = state.events.pending[0]
		var chosen := -1
		var best := -INF
		for index in event["choices"].size():
			if not state.events.choice_reason(state,event,index).is_empty():
				continue
			var effect: Dictionary = event["choices"][index]["effects"]
			var score: float = _event_score(effect)
			if score > best:
				best = score
				chosen = index
		if chosen < 0:
			return "No legal choice for " + event["id"]
		var result: Dictionary = state.events.resolve(state,event["serial"],chosen)
		if not result["ok"]:
			return result["message"]
		_record(state,"event",event["id"],"resolved",event["choices"][chosen]["label"])
	return "Event queue exceeded the safety limit."

func _event_score(effect: Dictionary) -> float:
	if strategy == "passive":
		return 0.0 # First legal choice, including consequences and expenses.
	var score: float = float(effect.get("cash",0))/10000.0 + float(effect.get("delayed_cash",0))/20000.0 - float(effect.get("cash_loss",0))/10000.0
	score += float(effect.get("shorten_illness",0))*.3 + float(effect.get("condition",0))*.03 + float(effect.get("property_condition",0))*.03
	if strategy in ["education","family"]:
		score += float(effect.get("happiness",0))*10 + float(effect.get("trust",0))*10 - float(effect.get("stress",0))*10 - float(effect.get("resentment",0))*10
		score += float(effect.get("household_happiness",0))*15 - float(effect.get("household_stress",0))*15
	if strategy == "education":
		score += 3.0 if effect.get("study",false) else 0.0
		score += float(effect.get("skill_gain",0))*.2
	if strategy == "family":
		score += float(effect.get("capacity",0))*.4
	return score

func reserve(state) -> int:
	var budget: Dictionary = state.economy.budget(state.people,state.household["members"])
	return 6 * (budget["food_cents"] + budget["planned_tuition_cents"])

func step(state) -> void:
	if strategy == "passive" or state.elapsed_months % 3 != 0:
		return
	if strategy in ["family","enterprise"] and _house(state):
		return
	if strategy == "enterprise" and _business(state):
		return
	if strategy == "family" and _relationships(state):
		return
	if _employment(state):
		return
	if strategy == "education":
		_education(state)

func _request(state, id: String, action: String) -> bool:
	if not state.Influence.unavailable_reason(state,id,action).is_empty() or not _ready_for(state,id+":"+action,24):
		return false
	var result: Dictionary = state.request(id,action)
	_record(state,"request",id+":"+action,result["outcome"],result["response"])
	return true

func _employment(state) -> bool:
	for id in state.household["members"]:
		var person = state.people[id]
		if id == state.head_id or not person.education["study"].is_empty():
			continue
		var best := ""
		var income: int = person.monthly_income_cents
		for job in state.careers.jobs.values():
			if job["monthly_income_cents"] > income and state.careers.job_assessment(person,job["id"])["eligible"]:
				best = job["id"]
				income = job["monthly_income_cents"]
		if not best.is_empty() and _request(state,id,"work:"+best):
			return true
	return false

func _education(state) -> bool:
	for id in state.household["members"]:
		var person = state.people[id]
		if id == state.head_id:
			continue
		var best := ""
		var score := -INF
		for program in state.careers.programs.values():
			var action: String = "train:"+program["id"]
			if not state.Influence.unavailable_reason(state,id,action).is_empty():
				continue
			var fees: int = state.economy.purchase_cost(program["monthly_cost_cents"])
			var budget: Dictionary = state.economy.budget(state.people,state.household["members"])
			if state.economy.cash_cents < reserve(state)+fees*12 or budget["net_cents"]-person.monthly_income_cents-fees < 0:
				continue
			# Rank progression first, then cheaper/shorter courses; never retries
			# the same refused proposal more often than every two years.
			if state.elapsed_months < cooldowns.get(id+":"+action,-24)+24:
				continue
			var value: float = state.careers.education_rank(person)*-1.0 + person.EDUCATION_LEVELS.find(program["education_level"])*10.0 - float(program["months"])*.02 - fees/10000.0
			if value > score:
				score = value
				best = action
		if not best.is_empty() and _request(state,id,best):
			return true
	return false

func _house(state) -> bool:
	if state.village.development._occupied_project("parcel_01"):
		return false
	if state.household["members"].size() > state.household["capacity"] or state.household["condition"] < 50:
		if state.economy.cash_cents >= reserve(state)+state.economy.purchase_cost(state.village.development.COST) and _ready_for(state,"house",12):
			var response: String = state.village.development.renovate(state,"home")
			_record(state,"renovation","home","commissioned",response)
			return true
	return false

func _relationships(state) -> bool:
	for person in state.people.values():
		if not person.alive or person.id == state.head_id or person.age < 18:
			continue
		var plan: Dictionary = person.decision_state.get("plan",{})
		if person.in_household and plan.get("action","") == "leave" and _request(state,person.id,"stay"):
			return true
		if not person.in_household and state.household["members"].size() < state.household["capacity"] and _request(state,person.id,"join"):
			return true
		if person.in_household and person.spouse_id.is_empty() and _request(state,person.id,"marry"):
			return true
	return false

func _business(state) -> bool:
	var dev = state.village.development
	var business = state.village.business
	var owned := 0
	for building in dev.buildings.values():
		if building["owner_id"] != "landi" or building["type"] not in business.CATALOG or building["status"] == "demolished":
			continue
		owned += 1
		if not business.assignments.has(building["id"]):
			for id in state.household["members"]:
				if business.reason(state,id,building["id"]).is_empty() and _ready_for(state,id+":manage",24):
					var result: Dictionary = business.propose(state,id,building["id"])
					_record(state,"manager",id+":"+building["id"],"accepted" if result["ok"] else "refused",result["response"])
					return true
		if (building["level"] < 3 or building["condition"] < 60) and not dev._occupied_project(building["parcel_id"]) and state.economy.cash_cents > reserve(state)+state.economy.purchase_cost(dev.COST) and _ready_for(state,building["id"]+":upgrade",24):
			_record(state,"renovation",building["id"],"commissioned",dev.renovate(state,building["id"]))
			return true
	for project in dev.projects.values():
		if project["owner_id"] == "landi" and project["kind"] == "construction":
			owned += 1
	if owned >= 3:
		return false
	var type: String = "farm" if owned == 0 else "workshop"
	for parcel in dev.parcels.values():
		if not dev.eligible(parcel["id"],type,"landi") or parcel["owner_id"] == "village" and not parcel["for_sale"]:
			continue
		var land: int = parcel["value_cents"] if parcel["owner_id"] == "village" else 0
		if state.economy.cash_cents <= reserve(state)+state.economy.purchase_cost(dev.COST+land):
			continue
		if land > 0:
			_record(state,"land",parcel["id"],"purchased",dev.buy_parcel(state,parcel["id"]))
		_record(state,"construction",parcel["id"],"commissioned",dev.begin_construction(state,parcel["id"],type,"landi"))
		return true
	return false
