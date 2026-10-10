extends RefCounted
## Monthly property production, with consent and limited management/labor.
const Assignment = preload("res://Simulation/Assignment.gd")
const CATALOG := {
	"farm": {"revenue": 1100, "materials": 220, "upkeep": 70, "skill": "agriculture", "interest": "practical", "labor": 1},
	"workshop": {"revenue": 1250, "materials": 400, "upkeep": 100, "skill": "craft", "interest": "practical", "labor": 1},
	"factory": {"revenue": 2800, "materials": 1100, "upkeep": 250, "skill": "technical", "interest": "commercial", "labor": 2},
	"tavern": {"revenue": 1000, "materials": 350, "upkeep": 80, "skill": "commerce", "interest": "social", "labor": 1},
}
var assignments: Dictionary = {}
var last_month: int = -1
var reports: Array = []

func commitment(person_id: String) -> String:
	for building_id in assignments:
		if assignments[building_id]["person_id"] == person_id:
			return building_id
	return ""

func reason(state, person_id: String, building_id: String) -> String:
	var building: Dictionary = state.village.development.buildings.get(building_id,{})
	if building.is_empty() or building["owner_id"] != "landi" or building["type"] not in CATALOG or building["status"] != "standing":
		return "Choose a working business owned by the family."
	if assignments.has(building_id):
		return "This business already has a manager."
	if not state.people.has(person_id):
		return "Choose a family member."
	var person = state.people[person_id]
	if not person.alive or person.age < 18 or person_id not in state.household["members"]:
		return "A living adult resident must manage the business."
	if not commitment(person_id).is_empty():
		return "They already manage a business."
	if state.activities.commitment(person_id) != null or not person.education["study"].is_empty():
		return "Finish their activity or course before adding this responsibility."
	if not person.life_state.get("illness",{}).is_empty():
		return "They need time to recover."
	if state.events.needs_family_care(state,person):
		return "They need time for childbirth and family care."
	if not state.travel.current(person_id).is_empty():
		return "They must finish their journey first."
	if person_id != state.head_id and state.last_requests.get(person_id,-1) == state.elapsed_months:
		return "You have already made a request this month."
	return ""

func propose(state, person_id: String, building_id: String) -> Dictionary:
	var unavailable := reason(state,person_id,building_id)
	if not unavailable.is_empty():
		return Assignment.unavailable(unavailable)
	var person = state.people[person_id]
	var building: Dictionary = state.village.development.buildings[building_id]
	var entry: Dictionary = CATALOG[building["type"]]
	var score := 1.0
	if person_id != state.head_id:
		state.last_requests[person_id] = state.elapsed_months
		var bond: Dictionary = person.relationships.get(state.head_id,{})
		score = person.interests[entry["interest"]]/100.0*.4 + person.values["family_loyalty"]*.3 + float(bond.get("trust",.3))*.2 - person.current_state["resentment"]*.4 - person.current_state["stress"]*.2 - person.learned_tendencies["need_for_autonomy"]*.15
	var result: Dictionary = Assignment.resolve(person, score, "manage " + building["address"], building_id, person_id == state.head_id)
	var response: String = result["response"]
	if result["outcome"] == "reluctant": person.current_state["resentment"] = minf(1.0, person.current_state["resentment"] + .05)
	if result["accepted"]:
		assignments[building_id] = {"person_id":person_id,"started_month":state.elapsed_months,"agreement":result["agreement"].duplicate(true)}
	person.memories.append({"kind":"business_request","date":state.date_text(),"description":response,"participants":[state.head_id]})
	state.chronicle.append({"date":state.date_text(),"description":response})
	return result

func release(state, building_id: String, explanation: String = "The management responsibility ended.") -> void:
	if not assignments.has(building_id):
		return
	var person = state.people[assignments[building_id]["person_id"]]
	assignments.erase(building_id)
	var description: String = person.name + " stopped managing " + building_id + ". " + explanation
	state.chronicle.append({"date":state.date_text(),"description":description})
	person.memories.append({"kind":"business","date":state.date_text(),"description":description,"participants":[state.head_id]})

func estimate(state, building_id: String, available_labor: int = 99, completed_month: bool = false) -> Dictionary:
	var dev = state.village.development
	var building: Dictionary = dev.buildings[building_id]
	var row := {"building_id":building_id,"owner_id":building["owner_id"],"revenue_cents":0,"cost_cents":0,"net_cents":0,"status":"Not a business"}
	if building["type"] not in CATALOG or building["owner_id"] == "village" or building["status"] != "standing":
		row["status"] = building["status"].capitalize()
		return row
	var entry: Dictionary = CATALOG[building["type"]]
	var managed := true
	var skill := .65
	row["cost_cents"] = entry["upkeep"]
	if building["owner_id"] == "landi":
		if not assignments.has(building_id):
			managed = false
			row["status"] = "Needs a manager"
		else:
			var person = state.people[assignments[building_id]["person_id"]]
			managed = person.alive and person.id in state.household["members"] and person.life_state.get("illness",{}).is_empty() and person.education["study"].is_empty() and state.activities.commitment(person.id) == null
			skill = .6 + person.skills[entry["skill"]]/100.0*.6
			if not managed:
				row["status"] = "Manager unavailable"
			elif state.events.needs_family_care(state,person,completed_month):
				managed = false
				row["status"] = "Manager on family care leave"
	elif available_labor < entry["labor"]:
		managed = false
		row["status"] = "Not enough household labor"
	if dev._occupied_project(building["parcel_id"]):
		managed = false
		row["status"] = "Closed for building work"
	if managed:
		var factor: float = (1.0 + .35*(building["level"]-1)) * building["condition"]/100.0 * skill
		var same_type := 0
		for other in dev.buildings.values():
			if other["type"] == building["type"] and other["status"] == "standing":
				same_type += 1
		factor /= 1.0 + .05*maxi(0,same_type-1)
		if building["type"] == "farm":
			factor *= .5 + dev.parcels[building["parcel_id"]]["fertility"]
			factor *= 1.7 if state.month in [6,7,8,9] else .7
		if dev.infrastructure["railway"]:
			factor *= 1.1
		if dev.infrastructure["paved_roads"]:
			factor *= 1.05
		if dev.infrastructure["electricity"] and building["type"] in ["workshop","factory"]:
			factor *= 1.1
		row["revenue_cents"] = maxi(0,roundi(entry["revenue"] * factor * state.economy.event_income_multiplier))
		if building["type"] == "farm":
			row["revenue_cents"] = roundi(row["revenue_cents"]*state.events.business_multiplier(state,"farm_multiplier",completed_month))
		row["cost_cents"] += roundi(entry["materials"]*(1.0+.25*(building["level"]-1)))
		row["status"] = "Operating"
	row["cost_cents"] = roundi(row["cost_cents"]*state.events.business_multiplier(state,"business_cost_multiplier",completed_month))
	if building["owner_id"] == "landi":
		row["cost_cents"] = state.economy.purchase_cost(row["cost_cents"])
	row["net_cents"] = row["revenue_cents"]-row["cost_cents"]
	return row

func advance_month(state) -> void:
	if last_month == state.elapsed_months:
		return
	last_month = state.elapsed_months
	for building_id in assignments.keys():
		var building: Dictionary = state.village.development.buildings.get(building_id,{})
		var person = state.people[assignments[building_id]["person_id"]]
		if building.is_empty() or building["owner_id"] != "landi" or building["status"] != "standing" or building["type"] not in CATALOG or not person.alive or person.id not in state.household["members"]:
			release(state,building_id,"The business or its manager is no longer available.")
		elif person.id != state.head_id and (person.current_state["resentment"] >= .8 or (person.current_state["stress"] >= .9 and person.values["independence"] > .6)):
			release(state,building_id,"They refused to continue under this pressure.")
			state.notify(person.name + " stopped managing the business under pressure.", person.id)
	var labor: Dictionary = {}
	for owner in state.village.households:
		labor[owner] = maxi(1,state.village.development.household_sizes[owner]/2)
	var rows: Array = []
	for building in state.village.development.buildings.values():
		if building["type"] not in CATALOG or building["owner_id"] == "village":
			continue
		var owner: String = building["owner_id"]
		var row := estimate(state,building["id"],int(labor.get(owner,99)),true)
		var cash: int = state.economy.cash_cents if owner == "landi" else state.village.households[owner].cash_cents
		if cash < row["cost_cents"]:
			row["revenue_cents"] = 0
			row["cost_cents"] = 0
			row["net_cents"] = 0
			row["status"] = "Needs operating funds"
		elif owner == "landi":
			state.events._cash(state,-row["cost_cents"],"Business costs · " + building["address"],false)
			if row["revenue_cents"] > 0:
				state.events._cash(state,row["revenue_cents"],"Business sales · " + building["address"],false)
		else:
			state.village.households[owner].cash_cents += row["net_cents"]
		if row["status"] == "Operating":
			if owner == "landi":
				var person = state.people[assignments[building["id"]]["person_id"]]
				# Managing alongside paid work creates sustained pressure; managing
				# full time leaves room for the ordinary monthly recovery.
				var pressure := .016 if person.monthly_income_cents > 0 else .008
				person.current_state["stress"] = minf(1,person.current_state["stress"]+pressure)
				Assignment.progress(person, assignments[building["id"]].get("agreement", {}))
				var skill: String = CATALOG[building["type"]]["skill"]
				person.skills[skill] = minf(100,person.skills[skill]+.4*state.legacy.learning_multiplier())
			else:
				labor[owner] -= CATALOG[building["type"]]["labor"]
		rows.append(row)
	reports.append({"month":state.elapsed_months,"date":state.date_text(),"rows":rows})
	if reports.size() > 24:
		reports.pop_front()

func to_save_data() -> Dictionary:
	return {"assignments":assignments.duplicate(true),"last_month":last_month,"reports":reports.duplicate(true)}

func restore_save_data(data: Dictionary) -> void:
	assignments = data.get("assignments",{}).duplicate(true)
	last_month = data.get("last_month",-1)
	reports = data.get("reports",[]).duplicate(true)

static func valid(data: Variant, state: Dictionary) -> bool:
	if not data is Dictionary or not data.get("assignments") is Dictionary or not data.get("last_month") is int or not data.get("reports") is Array or data["last_month"] < -1 or data["last_month"] > state["elapsed_months"] or data["reports"].size() > 24:
		return false
	var seen: Dictionary = {}
	var buildings: Dictionary = state["village"]["development"]["buildings"]
	for id in data["assignments"]:
		var assignment: Variant = data["assignments"][id]
		if not id is String or not buildings.has(id) or not assignment is Dictionary or not assignment.get("person_id") is String or not assignment.get("started_month") is int or not state["people"].has(assignment["person_id"]) or seen.has(assignment["person_id"]) or assignment["started_month"] < 0 or assignment["started_month"] > state["elapsed_months"]:
			return false
		if not Assignment.valid(assignment.get("agreement", {})): return false
		seen[assignment["person_id"]] = true
	var previous := -1
	for report in data["reports"]:
		if not report is Dictionary or not report.get("month") is int or not report.get("date") is String or not report.get("rows") is Array or report["month"] <= previous or report["month"] > data["last_month"]:
			return false
		previous = report["month"]
		for row in report["rows"]:
			if not row is Dictionary or not row.get("building_id") is String or not buildings.has(row["building_id"]) or not row.get("owner_id") is String or row["owner_id"] != "landi" and not state["village"]["households"].has(row["owner_id"]) or not row.get("status") is String:
				return false
			for field in ["revenue_cents","cost_cents","net_cents"]:
				if not row.get(field) is int:
					return false
			if row["revenue_cents"] < 0 or row["cost_cents"] < 0 or row["net_cents"] != row["revenue_cents"]-row["cost_cents"]:
				return false
	return true
