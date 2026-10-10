extends RefCounted
## Abstract monthly travel; costs and durations are prototype balance values.

const Assignment = preload("res://Simulation/Assignment.gd")
const CITIES := {
	"turin": {"name": "Turin", "position": Vector2(0.159959, 0.244450), "months": 2, "fare": 1800, "skill": "technical", "description": "Technical study and commercial opportunities in Piedmont."},
	"milan": {"name": "Milan", "position": Vector2(0.263029, 0.211954), "months": 2, "fare": 1600, "skill": "commerce", "description": "Commerce, practical training and paid work in Lombardy."},
	"venice": {"name": "Venice", "position": Vector2(0.477349, 0.213884), "months": 2, "fare": 1800, "skill": "art", "description": "Artistic study and contacts with merchants."},
	"genoa": {"name": "Genoa", "position": Vector2(0.246318, 0.299288), "months": 2, "fare": 1400, "skill": "commerce", "description": "A port destination for trade contacts and work."},
	"bologna": {"name": "Bologna", "position": Vector2(0.410635, 0.291921), "months": 1, "fare": 1000, "skill": "science", "description": "Academic study and practical employment."},
	"florence": {"name": "Florence", "position": Vector2(0.404683, 0.351758), "months": 1, "fare": 600, "skill": "medicine", "description": "Study and professional contacts close to the Tuscan home."},
	"rome": {"name": "Rome", "position": Vector2(0.489753, 0.505769), "months": 2, "fare": 1600, "skill": "law", "description": "Legal study, professional introductions and city work."},
	"naples": {"name": "Naples", "position": Vector2(0.611241, 0.592477), "months": 3, "fare": 2200, "skill": "medicine", "description": "Study, commerce and work in a large southern city."},
	"bari": {"name": "Bari", "position": Vector2(0.789787, 0.570589), "months": 3, "fare": 2400, "skill": "commerce", "description": "Adriatic trade contacts and practical work."},
	"palermo": {"name": "Palermo", "position": Vector2(0.549074, 0.818205), "months": 4, "fare": 3200, "skill": "agriculture", "description": "Agricultural study, trade and work in Sicily."},
	"cagliari": {"name": "Cagliari", "position": Vector2(0.258345, 0.726787), "months": 4, "fare": 3000, "skill": "commerce", "description": "Island trade contacts and paid work in Sardinia."},
}
const PURPOSES := {
	"study": {"name": "Study", "months": 6, "cost": 900, "interest": "academic", "description": "Develop the city's featured skill. This short placement does not award a qualification."},
	"trade": {"name": "Trade contacts", "months": 3, "cost": 600, "interest": "commercial", "description": "Develop commerce and persuasion, then bring home 20 Tuscan lire from the arrangement."},
	"work": {"name": "Paid work", "months": 6, "cost": 500, "interest": "practical", "description": "Take a temporary placement, practice commerce and bring home 60 Tuscan lire on return."},
}
const ACTIVE := ["outbound", "staying", "returning"]
var journeys: Dictionary = {}
var next_id: int = 1


func current(person_id: String) -> Dictionary:
	for journey in journeys.values():
		if journey["person_id"] == person_id and journey["status"] in ACTIVE:
			return journey
	return {}


func cost(state, city_id: String, purpose_id: String) -> int:
	var city: Dictionary = CITIES[city_id]
	var purpose: Dictionary = PURPOSES[purpose_id]
	return state.economy.purchase_cost(city["fare"] * 2 + purpose["cost"] * purpose["months"])


func reason(state, person_id: String, city_id: String, purpose_id: String) -> String:
	if not CITIES.has(city_id) or not PURPOSES.has(purpose_id) or not state.people.has(person_id):
		return "Choose a city, purpose and family member."
	var person = state.people[person_id]
	var disruption: String = state.events.travel_disruption(state)
	if not disruption.is_empty():
		return disruption
	if state.events.needs_family_care(state,person):
		return "They need time for childbirth and family care at home."
	if person_id == state.head_id:
		return "The family head must remain home to lead the household."
	if not state.people[state.head_id].alive or not person.alive or person.age < 18:
		return "A living adult relative must take the journey."
	if not current(person_id).is_empty():
		return "They already have a journey underway."
	if person_id not in state.household["members"]:
		return "Only residents can be sent from the family home."
	if not state.village.business.commitment(person_id).is_empty():
		return "Arrange a replacement business manager before travelling."
	if state.activities.commitment(person_id) != null or not person.education["study"].is_empty():
		return "Finish or cancel their current project or course first."
	if not person.life_state.get("illness", {}).is_empty() or not person.life_state.get("pregnancy", {}).is_empty():
		return "Their health or pregnancy needs care at home."
	for relative in state.people.values():
		if relative.alive and relative.age < 18 and person_id in relative.parent_ids:
			return "They have dependent children; family travel arrangements are not available yet."
	if state.last_requests.get(person_id, -1) == state.elapsed_months:
		return "You have already made a request this month."
	if state.economy.cash_cents < cost(state, city_id, purpose_id):
		return "The shared purse cannot cover return travel and the full stay."
	return ""


func propose(state, person_id: String, city_id: String, purpose_id: String) -> Dictionary:
	var unavailable := reason(state, person_id, city_id, purpose_id)
	if not unavailable.is_empty():
		return Assignment.unavailable(unavailable)
	var person = state.people[person_id]
	state.last_requests[person_id] = state.elapsed_months
	var bond: Dictionary = person.relationships.get(state.head_id, {})
	var score: float = person.interests[PURPOSES[purpose_id]["interest"]] / 100.0 * 0.45 + person.values["independence"] * 0.2 + float(bond.get("trust", 0.4)) * 0.2
	score -= person.values["security"] * 0.15 + person.current_state["resentment"] * 0.3 + person.current_state["stress"] * 0.15
	var result: Dictionary = Assignment.resolve(person, score, "visit " + CITIES[city_id]["name"])
	if result["outcome"] == "reluctant": person.current_state["resentment"] = minf(1.0, person.current_state["resentment"] + 0.05)
	_record(state, person, result["response"], false)
	if not result["accepted"]: return result
	# Reserve the full stay and both journeys so loss of income cannot strand them.
	state.events._cash(state, -cost(state, city_id, purpose_id), "Journey to " + CITIES[city_id]["name"], false)
	var id := "journey_%d" % next_id
	next_id += 1
	journeys[id] = {"id": id, "person_id": person_id, "city_id": city_id, "purpose_id": purpose_id,
		"status": "outbound", "remaining_months": int(CITIES[city_id]["months"]),
		"agreement": result["agreement"].duplicate(true), "progress": 0.0, "started_month": state.elapsed_months, "recalled": false, "outcome": ""}
	state.household["members"].erase(person_id)
	person.in_household = false
	person.decision_state["plan"] = {}
	result["activity_id"] = id
	return result


func recall(state, journey_id: String) -> Dictionary:
	if not journeys.has(journey_id) or journeys[journey_id]["status"] not in ["outbound", "staying"]:
		return Assignment.unavailable("This journey cannot be recalled.")
	var journey: Dictionary = journeys[journey_id]
	var person = state.people[journey["person_id"]]
	if not person.alive or not state.people[state.head_id].alive:
		return Assignment.unavailable("Only living people can discuss a return.")
	if state.last_requests.get(person.id, -1) == state.elapsed_months:
		return Assignment.unavailable("You have already made a request this month.")
	state.last_requests[person.id] = state.elapsed_months
	var bond: Dictionary = person.relationships.get(state.head_id, {})
	var score: float = person.values["family_loyalty"] * .6 + float(bond.get("trust", .4)) * .25 - person.values["independence"] * .3 - person.learned_tendencies["need_for_autonomy"] * .2 - person.current_state["resentment"] * .3
	var result: Dictionary = Assignment.resolve(person, score, "return home early", journey_id)
	_record(state, person, result["response"], false)
	if not result["accepted"]: return result
	journey["status"] = "returning"
	journey["remaining_months"] = int(CITIES[journey["city_id"]]["months"])
	journey["recalled"] = true
	_record(state, state.people[journey["person_id"]], "The family requested an early return from " + CITIES[journey["city_id"]]["name"] + ". The placement ends without its reward.")
	return result


func advance_month(state) -> void:
	for journey in journeys.values():
		if journey["status"] not in ACTIVE:
			continue
		var person = state.people[journey["person_id"]]
		var city: Dictionary = CITIES[journey["city_id"]]
		if not person.alive:
			journey["status"] = "failed"
			journey["outcome"] = person.name + " died while away in " + city["name"] + "."
			_record(state, person, journey["outcome"])
			state.major_event = true
			continue
		if journey["status"] == "staying":
			if not person.life_state.get("illness", {}).is_empty():
				continue
			var step: float = state.legacy.learning_multiplier() if journey["purpose_id"] == "study" else 1.0
			if journey["progress"] >= 1 and Assignment.abandons(person, journey.get("agreement", {})):
				journey["recalled"] = true
				journey["status"] = "returning"
				journey["remaining_months"] = int(city["months"])
				_record(state, person, person.name + " abandoned the placement in " + city["name"] + " and is returning without its reward.")
				continue
			step *= Assignment.progress(person, journey.get("agreement", {}))
			journey["progress"] = minf(PURPOSES[journey["purpose_id"]]["months"], journey["progress"] + step)
			if journey["progress"] >= PURPOSES[journey["purpose_id"]]["months"]:
				journey["status"] = "returning"
				journey["remaining_months"] = int(city["months"])
				_record(state, person, person.name + " finished the placement in " + city["name"] + " and is returning home.")
			continue
		var disruption: String = state.events.travel_disruption(state,true)
		if not disruption.is_empty():
			if journey.get("interruption_reason","") != disruption:
				_record(state,person,person.name+" must wait on the journey. "+disruption)
			journey["interruption_reason"] = disruption
			continue
		if not journey.get("interruption_reason","").is_empty():
			journey["interruption_reason"] = ""
			_record(state,person,person.name+" can resume the journey.")
		journey["remaining_months"] -= 1
		if journey["remaining_months"] > 0:
			continue
		if journey["status"] == "outbound":
			journey["status"] = "staying"
			_record(state, person, person.name + " arrived in " + city["name"] + ".")
		else:
			journey["status"] = "completed"
			if person.id not in state.household["members"]:
				state.household["members"].append(person.id)
			person.in_household = true
			person.decision_state["last_action_month"] = state.elapsed_months
			if not journey["recalled"]:
				if journey["purpose_id"] == "study":
					person.skills[city["skill"]] = minf(100.0, person.skills[city["skill"]] + 15.0)
				else:
					person.skills["commerce"] = minf(100.0, person.skills["commerce"] + 8.0)
					if journey["purpose_id"] == "trade":
						person.skills["persuasion"] = minf(100.0, person.skills["persuasion"] + 5.0)
					state.events._cash(state, 2000 if journey["purpose_id"] == "trade" else 6000, "Proceeds from " + city["name"])
			journey["outcome"] = person.name + " returned home from " + city["name"] + (" early." if journey["recalled"] else " after completing the placement.")
			_record(state, person, journey["outcome"])


func location_text(person_id: String) -> String:
	var journey := current(person_id)
	if journey.is_empty():
		return ""
	var city: String = CITIES[journey["city_id"]]["name"]
	return {"outbound": "Traveling to " + city, "staying": "Staying in " + city, "returning": "Returning from " + city}[journey["status"]] + (" · " + journey["interruption_reason"] if not journey.get("interruption_reason","").is_empty() else "")


func _record(state, person, description: String, notification: bool = true) -> void:
	if notification: state.notify(description, person.id)
	state.chronicle.append({"date": state.date_text(), "description": description})
	person.memories.append({"kind": "travel", "date": state.date_text(), "description": description})
	if notification: person.decision_state["observation"] = description


func to_save_data() -> Dictionary:
	return {"journeys": journeys.duplicate(true), "next_id": next_id}


func restore_save_data(data: Dictionary) -> void:
	journeys = data.get("journeys", {}).duplicate(true)
	next_id = data.get("next_id", 1)
