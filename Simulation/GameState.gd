extends RefCounted
## Persistent in-memory simulation data. Time has month precision, never days.

const MONTH_NAMES := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

const Travel = preload("res://Simulation/Travel.gd")
const Activities = preload("res://Simulation/Activities/ActivitySystem.gd")
const Village = preload("res://Simulation/Village/VillageState.gd")
const Legacy = preload("res://Simulation/Legacy.gd")
const Economy = preload("res://Simulation/Economy.gd")
const Person = preload("res://Simulation/Person.gd")
const Influence = preload("res://Simulation/Influence.gd")
const Careers = preload("res://Simulation/Careers.gd")
const EventSystem = preload("res://Simulation/EventSystem.gd")
const DecisionSystem = preload("res://Simulation/DecisionSystem.gd")

var year: int = 1800
var month: int = 1
var elapsed_months: int = 0
var people: Dictionary = {}
var economy = Economy.new()
var legacy = Legacy.new()
var travel = Travel.new()
var activities = Activities.new()
var village = Village.new()
var careers = Careers.new()
var events = EventSystem.new()
var major_event: bool = false
var head_id: String = "Giovanni"
var chronicle: Array = []
var last_requests: Dictionary = {}
var household: Dictionary = {"members": [], "rooms": ["Bedroom", "Kitchen", "Outdoor washroom"], "condition": 80, "capacity": 7}


func initialize(initial_people: Dictionary) -> void:
	village.initialize()
	activities = Activities.new()
	travel = Travel.new()
	people = {}
	for person_id in initial_people:
		people[person_id] = Person.new(person_id, initial_people[person_id], year, month, head_id)
	var resolved: Dictionary = {}
	for person_id in people:
		_resolve_portrait(person_id, initial_people, resolved, {})
	household["members"] = []
	for person_id in people:
		people[person_id].in_household = bool(initial_people[person_id].get("in_household", true))
		if people[person_id].in_household:
			household["members"].append(person_id)
	for person in people.values():
		DecisionSystem.ensure_goals(person)
	chronicle.clear()
	last_requests.clear()


func _resolve_portrait(person_id: String, source: Dictionary, resolved: Dictionary, visiting: Dictionary) -> void:
	if resolved.has(person_id) or visiting.has(person_id):
		return
	visiting[person_id] = true
	var parents: Array = []
	for parent_id in people[person_id].parent_ids:
		if not people.has(parent_id) or visiting.has(parent_id):
			continue
		_resolve_portrait(parent_id, source, resolved, visiting)
		parents.append(people[parent_id].portrait)
	people[person_id].portrait = Person.PortraitIdentity.new(person_id, source[person_id].get("portrait", {}), parents)
	visiting.erase(person_id)
	resolved[person_id] = true


func request(person_id: String, action: String) -> Dictionary:
	var result: Dictionary = Influence.request(self, person_id, action)
	legacy.evaluate(self)
	return result


func add_person(person_id: String, source: Dictionary) -> RefCounted:
	## Entry point for future births, marriages, and arrivals. Parents must exist first.
	if person_id.is_empty() or people.has(person_id):
		return null
	var person = Person.new(person_id, source, year, month, head_id)
	var parents: Array = []
	for parent_id in person.parent_ids:
		if people.has(parent_id):
			parents.append(people[parent_id].portrait)
	person.portrait = Person.PortraitIdentity.new(person_id, source.get("portrait", {}), parents)
	person.in_household = bool(source.get("in_household", true))
	people[person_id] = person
	DecisionSystem.ensure_goals(person)
	if person.in_household:
		household["members"].append(person_id)
	return person


func advance_month() -> void:
	if events.enabled and not events.pending.is_empty():
		return
	major_event = false
	# Settle the month being completed before dating the next month's prices.
	_update_monthly()
	month += 1
	if month > 12:
		month = 1
		year += 1
	elapsed_months += 1
	for person in people.values():
		person.in_household = person.id in household["members"]
		person.advance_month(year, month, economy.cash_cents < 0)
		careers.advance_month(self, person)
		if economy.crisis_started and person.in_household and person.alive:
			person.experience_event("financial_crisis", "The household could not cover its monthly food bill.", date_text(), [head_id], 0.5)

	# Evaluate after all birthdays, learning, and financial pressure are applied.
	for person in people.values():
		DecisionSystem.advance_month(self, person)
	travel.advance_month(self)
	activities.advance_month(self)
	village.advance_month(self)
	events.advance_month(self)
	legacy.evaluate(self)


func _update_monthly() -> void:
	events.prepare_economy(self)
	economy.settle_month(date_text(), people, household["members"])


func date_text() -> String:
	return "%s %d" % [MONTH_NAMES[month - 1], year]


func to_save_data() -> Dictionary:
	var saved_people: Dictionary = {}
	for person_id in people:
		saved_people[person_id] = people[person_id].to_save_data()
	return {
		"year": year, "month": month, "elapsed_months": elapsed_months,
		"people": saved_people, "head_id": head_id, "household": household.duplicate(true),
		"chronicle": chronicle.duplicate(true), "last_requests": last_requests.duplicate(true),
		"travel": travel.to_save_data(), "activities": activities.to_save_data(), "village": village.to_save_data(),
		"legacy": legacy.to_save_data(), "major_event": major_event, "events": events.to_save_data(),
		"economy": {"currency": economy.currency, "cash_cents": economy.cash_cents, "price_index": economy.price_index,
			"event_food_multiplier": economy.event_food_multiplier, "event_income_multiplier": economy.event_income_multiplier,
			"ledger": economy.ledger.duplicate(true), "crisis_started": economy.crisis_started},
		"careers": {"jobs": careers.jobs.duplicate(true), "programs": careers.programs.duplicate(true)},
	}


func restore_save_data(data: Dictionary) -> void:
	travel.restore_save_data(data.get("travel", {}))
	if data.has("village"):
		village.restore_save_data(data["village"])
		if not data["village"].has("development"):
			village.development.initialize(data["year"], data["elapsed_months"])
	else:
		village.initialize()
	activities.restore_save_data(data.get("activities", {}))
	legacy.restore_save_data(data.get("legacy", {}))
	economy.price_multiplier = legacy.price_multiplier()
	year = data["year"]
	month = data["month"]
	elapsed_months = data["elapsed_months"]
	head_id = data["head_id"]
	household = data["household"]
	chronicle = data["chronicle"]
	last_requests = data["last_requests"]
	major_event = data["major_event"]
	people = {}
	for person_id in data["people"]:
		people[person_id] = Person.from_save_data(data["people"][person_id])
	economy.currency = data["economy"].get("currency", "italian_lira")
	economy.cash_cents = data["economy"]["cash_cents"]
	economy.price_index = data["economy"]["price_index"]
	economy.ledger.assign(data["economy"]["ledger"])
	economy.crisis_started = data["economy"]["crisis_started"]
	careers.jobs = data["careers"]["jobs"]
	careers.programs = data["careers"]["programs"]

	events.restore_save_data(data.get("events", {}))
	events.prepare_economy(self)
