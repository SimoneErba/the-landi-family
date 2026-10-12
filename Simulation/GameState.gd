extends RefCounted
## Persistent in-memory simulation data. Time has month precision, never days.

const MONTH_NAMES := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

const Marriage = preload("res://Simulation/Marriage.gd")
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
const Succession = preload("res://Simulation/Succession.gd")
const Loans = preload("res://Simulation/Loans.gd")
const Laws = preload("res://Simulation/Laws.gd")
const SocialLife = preload("res://Simulation/SocialLife.gd")

var year: int = 1800
var month: int = 1
var elapsed_months: int = 0
var people: Dictionary = {}
var economy = Economy.new()
var legacy = Legacy.new()
var marriage = Marriage.new()
var travel = Travel.new()
var activities = Activities.new()
var village = Village.new()
var careers = Careers.new()
var events = EventSystem.new()
var succession = Succession.new()
var loans = Loans.new()
var social = SocialLife.new()
var major_event: bool = false
var head_id: String = "Giovanni"
var chronicle: Array = []
var notifications: Array = []
var last_requests: Dictionary = {}
var household: Dictionary = {"members": [], "rooms": ["Bedroom", "Kitchen", "Outdoor washroom"], "condition": 80, "capacity": 7}


func initialize(initial_people: Dictionary) -> void:
	succession = Succession.new()
	loans = Loans.new()
	social = SocialLife.new()
	village.initialize()
	marriage = Marriage.new()
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
	notifications.clear()
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
	if succession.pending or succession.ended: return
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
	Laws.advance_month(self)
	loans.advance_month(self)
	for person in people.values():
		person.in_household = person.id in household["members"]
		person.advance_month(year, month, economy.cash_cents < 0)
		if person.in_household and person.alive and economy.ledger.back().get("economizing", false):
			person.current_state["happiness"] = maxf(0.0, float(person.current_state.get("happiness", 0.6)) - 0.01)
		careers.advance_month(self, person)
		if economy.crisis_started and person.in_household and person.alive:
			person.experience_event("financial_crisis", "The household could not cover its essential monthly bills.", date_text(), [head_id], 0.5)

	succession.advance_month(self)
	# Evaluate after all birthdays, learning, financial pressure and deaths.
	for person in people.values():
		DecisionSystem.advance_month(self, person)
	travel.advance_month(self)
	activities.advance_month(self)
	village.advance_month(self)
	marriage.advance_month(self)
	social.advance_month(self)
	events.advance_month(self)
	legacy.evaluate(self)


func tax_property_assessment() -> int:
	# Stable authored capital is a proxy for assessed rental capacity. Do not use
	# speculative sale prices or tax the same parcel again as a business expense.
	var assessed := 0
	for parcel in village.development.parcels.values():
		if parcel["owner_id"] == "landi": assessed += int(parcel["value_cents"])
	for building in village.development.buildings.values():
		if building["owner_id"] != "landi" or building["status"] == "demolished": continue
		assessed += village.development.COST * village.development.PROPERTY_VALUE_MULTIPLIER * int(building["level"])
		if building["id"] == "home": assessed += maxi(0, household["rooms"].size() - 3) * 20000
	return assessed


func _update_monthly() -> void:
	events.prepare_economy(self)
	economy.settle_month(date_text(), people, household["members"], household, year, month, tax_property_assessment())


func date_text() -> String:
	return "%s %d" % [MONTH_NAMES[month - 1], year]


func notify(description: String, person_id: String = "") -> void:
	notifications.append({"date": date_text(), "description": description, "person_id": person_id, "read": false})
	if notifications.size() > 100: notifications.pop_front()


func to_save_data() -> Dictionary:
	var saved_people: Dictionary = {}
	for person_id in people:
		saved_people[person_id] = people[person_id].to_save_data()
	return {
		"year": year, "month": month, "elapsed_months": elapsed_months,
		"people": saved_people, "head_id": head_id, "household": household.duplicate(true),
		"notifications": notifications.duplicate(true), "chronicle": chronicle.duplicate(true), "last_requests": last_requests.duplicate(true),
		"marriage": marriage.to_save_data(), "travel": travel.to_save_data(), "activities": activities.to_save_data(), "village": village.to_save_data(),
		"legacy": legacy.to_save_data(), "major_event": major_event, "events": events.to_save_data(),
		"succession": succession.to_save_data(), "loans": loans.to_save_data(),
		"social": social.to_save_data(),
		"economy": {"currency": economy.currency, "cash_cents": economy.cash_cents, "price_index": economy.price_index,
			"event_food_multiplier": economy.event_food_multiplier, "event_income_multiplier": economy.event_income_multiplier,
			"ledger": economy.ledger.duplicate(true), "crisis_started": economy.crisis_started},
		"careers": {"jobs": careers.jobs.duplicate(true), "programs": careers.programs.duplicate(true)},
	}


func restore_save_data(data: Dictionary) -> void:
	social.restore_save_data(data.get("social", {}))
	succession.restore_save_data(data.get("succession", {}))
	loans.restore_save_data(data.get("loans", {}))
	marriage.restore_save_data(data.get("marriage", {}))
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
	notifications = data.get("notifications", []).duplicate(true)
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
	# New offers use the current catalogue; ongoing pay and stored course contracts
	# stay with the person. Preserve additional save-authored/custom entries.
	var current_catalog = Careers.new()
	careers.jobs.merge(current_catalog.jobs, true)
	careers.programs.merge(current_catalog.programs, true)

	events.restore_save_data(data.get("events", {}))
	events.prepare_economy(self)
