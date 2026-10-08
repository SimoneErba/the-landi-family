extends RefCounted
## Money uses fixed hundredths of a Tuscan lira as its accounting basis.
## Currency reforms change denomination, preserving the value of every obligation.

const STARTING_CASH_CENTS := 10000
const BASE_FOOD_CENTS := 1000
const MONTHLY_INFLATION := 0.02 / 12.0

var currency: String = "tuscan_lira"
var cash_cents: int = STARTING_CASH_CENTS
var price_index: float = 1.0
var event_food_multiplier: float = 1.0
var event_income_multiplier: float = 1.0
var ledger: Array[Dictionary] = []
var crisis_started: bool = false


func food_per_person_cents() -> int:
	return roundi(BASE_FOOD_CENTS * price_index * event_food_multiplier)


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
		tuition += int(person.education.get("study", {}).get("monthly_cost_cents", 0))
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
	var sign_text := "−" if amount < 0 else ""
	if currency == "tuscan_lira":
		var denari := roundi(absi(amount) * 2.4)
		var text := "%s%d lire toscane" % [sign_text, denari / 240]
		if denari % 240 != 0:
			text += ", %ds %dd" % [(denari % 240) / 12, denari % 12]
		return text
	if currency == "tuscan_fiorino":
		var quattrini := roundi(absi(amount) * 0.6)
		return "%s%d.%02d fiorini" % [sign_text, quattrini / 100, quattrini % 100]
	var centesimi := roundi(absi(amount) * 0.84)
	return "%s%d.%02d lire italiane" % [sign_text, centesimi / 100, centesimi % 100]
