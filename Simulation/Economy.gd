extends RefCounted
## Money uses fixed hundredths of a Tuscan lira as its accounting basis.
## Currency reforms change denomination, preserving the value of every obligation.

const STARTING_CASH_CENTS := 10000
const BASE_FOOD_CENTS := 1000
# Wages remain base values in this prototype. Keep a century of food inflation
# below a modest two-person worker household's starting earnings.
const MONTHLY_INFLATION := 0.005 / 12.0

var currency: String = "tuscan_lira"
var cash_cents: int = STARTING_CASH_CENTS
var price_multiplier: float = 1.0
var price_index: float = 1.0
var event_food_multiplier: float = 1.0
var event_income_multiplier: float = 1.0
var ledger: Array[Dictionary] = []
var crisis_started: bool = false


func food_per_person_cents() -> int:
	return purchase_cost(roundi(BASE_FOOD_CENTS * price_index * event_food_multiplier))


func purchase_cost(amount: int) -> int:
	return roundi(amount * price_multiplier)


func budget(people: Dictionary, members: Array) -> Dictionary:
	var income: int = 0
	var residents: int = 0
	var tuition: int = 0
	var contributions: Array[Dictionary] = []
	for person_id in members:
		if not people.has(person_id):
			continue
		var person = people[person_id]
		if not person.alive:
			continue
		residents += 1
		var illness_multiplier := 0.5 if not person.life_state.get("illness", {}).is_empty() else 1.0
		var earnings := maxi(0, roundi(person.monthly_income_cents * event_income_multiplier * illness_multiplier))
		income += earnings
		tuition += purchase_cost(int(person.education.get("study", {}).get("monthly_cost_cents", 0)))
		contributions.append({"name": person.name, "job": person.job, "income_cents": earnings})
	var food := residents * food_per_person_cents()
	# Food takes priority. Unfunded courses pause without charging tuition.
	var training_funded := cash_cents + income - food >= tuition
	var charged_tuition := tuition if training_funded else 0
	return {"income_cents": income, "food_cents": food, "tuition_cents": charged_tuition, "planned_tuition_cents": tuition, "training_funded": training_funded, "net_cents": income - food - charged_tuition, "residents": residents, "contributions": contributions}


func settle_month(date: String, people: Dictionary, members: Array) -> void:
	var entry := budget(people, members)
	entry["date"] = date
	entry["opening_cents"] = cash_cents
	cash_cents += int(entry["net_cents"])
	entry["closing_cents"] = cash_cents
	ledger.append(entry)
	crisis_started = int(entry["opening_cents"]) >= 0 and cash_cents < 0
	price_index *= 1.0 + MONTHLY_INFLATION


static func lire(cents: int) -> String:
	return "%s%d.%02d lire" % ["−" if cents < 0 else "", absi(cents) / 100, absi(cents) % 100]


func money(amount: int) -> String:
	# One stable gameplay currency across the whole run, in the accounting basis.
	if absi(amount) % 100 == 0:
		return "%s%d lire" % ["−" if amount < 0 else "", absi(amount) / 100]
	return lire(amount)
