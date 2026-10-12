extends RefCounted
## Money uses fixed hundredths of a Tuscan lira as its accounting basis.
## Currency reforms change denomination, preserving the value of every obligation.

const STARTING_CASH_CENTS := 10000
const BASE_FOOD_CENTS := 1000
const ESSENTIALS_PER_ADULT_CENTS := 500
const BASE_UPKEEP_CENTS := 400
const UPKEEP_PER_ROOM_CENTS := 200
# Wages remain base values in this prototype. Keep a century of food inflation
# below a modest two-person worker household's starting earnings.
const MONTHLY_INFLATION := 0.005 / 12.0
const Laws = preload("res://Simulation/Laws.gd")

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


static func work_capacity(age: int) -> float:
	# Reduced work, not a state pension. Earnings end by 95 in this prototype.
	if age <= 60: return 1.0
	if age < 85: return lerpf(1.0, 0.5, float(age - 60) / 25.0)
	return maxf(0.0, 0.5 * (95.0 - age) / 10.0)


func earnings(person) -> int:
	if not person.alive: return 0
	var illness := 0.5 if not person.life_state.get("illness", {}).is_empty() else 1.0
	return maxi(0, roundi(person.monthly_income_cents * work_capacity(person.age) * event_income_multiplier * illness))


static func total_expenses(entry: Dictionary) -> int:
	# Old saves retain their original ledger entries, which only had food/tuition.
	return int(entry.get("expenses_cents", int(entry.get("food_cents", 0)) + int(entry.get("tuition_cents", 0))))


func _farm_food_share(people: Dictionary, members: Array) -> float:
	# One shared farm feeds the household once, even when several residents farm.
	var share := 0.0
	for id in members:
		if not people.has(id):
			continue
		var producer = people[id]
		if not producer.alive or producer.career_id != "farmer" or producer.monthly_income_cents <= 0:
			continue
		var study: Dictionary = producer.education.get("study", {})
		var availability := 1.0
		if not study.is_empty() and not study.get("suspended", false):
			availability = float(study.get("terms", {}).get("retained_income_fraction", 1.0))
		var health_factor := 0.5 if not producer.life_state.get("illness", {}).is_empty() else 1.0
		var output := float(producer.life_state.get("farm_food_share", 0.35))
		share = maxf(share, output * availability * work_capacity(producer.age) * health_factor)
	return share


static func _food_share(age: int) -> float:
	return 0.65 if age < 13 else (0.85 if age < 18 else 1.0)


static func _supplied_board(person, study: Dictionary) -> float:
	var supplied := float(person.life_state.get("food_support_fraction", 0.0))
	if not study.is_empty() and not study.get("suspended", false):
		var terms: Dictionary = study.get("terms", {})
		supplied = maxf(
			supplied * float(terms.get("retained_income_fraction", 0.0)),
			float(terms.get("food_support_fraction", 0.0))
		)
	return supplied


func _unfunded_board_cost(people: Dictionary, members: Array, farm_share: float, economizing: bool) -> int:
	# Unpaid course board supplies no meals. Restore food costs before settlement.
	var cost := 0
	for id in members:
		if not people.has(id) or not people[id].alive:
			continue
		var resident = people[id]
		var study: Dictionary = resident.education.get("study", {})
		if study.get("suspended", false):
			continue
		var board := float(study.get("terms", {}).get("food_support_fraction", 0.0))
		if board <= 0:
			continue
		var normal_bill := roundi(food_per_person_cents() * _food_share(resident.age) * (0.85 if economizing else 1.0))
		cost += roundi(normal_bill * maxf(0.0, board - farm_share))
	return cost


## Forecast only: returns the same account fields used by settlement and the UI.
## Does not spend cash, advance inflation, or modify course contracts.
func budget(people: Dictionary, members: Array, household: Dictionary = {}, year: int = 1800, month: int = 1, property_assessment: int = Laws.DEFAULT_PROPERTY_ASSESSMENT) -> Dictionary:
	var rules := Laws.rules(year, month)
	var taxable_income := 0
	var income: int = 0
	var residents: int = 0
	var mouths := 0
	var cereal_consumers := 0.0
	var tuition: int = 0
	var food := 0
	var food_before_support := 0
	var essentials := 0
	var care := 0
	var economizing := cash_cents < 0
	var contributions: Array[Dictionary] = []
	var farm_share := _farm_food_share(people, members)
	for person_id in members:
		if not people.has(person_id):
			continue
		var person = people[person_id]
		if not person.alive:
			continue
		residents += 1
		if person.age >= 3:
			mouths += 1
		var wages := earnings(person)
		income += wages
		# Smallholder/farm earnings are covered by the property levy in this model.
		if person.career_id not in ["farmer", "farm_laborer", "farm_manager"]:
			taxable_income += wages
		var study: Dictionary = person.education.get("study", {})
		if not study.get("suspended", false):
			tuition += purchase_cost(int(study.get("monthly_cost_cents", 0)))
		var food_share := _food_share(person.age)
		cereal_consumers += food_share * (0.85 if economizing else 1.0) if person.age >= 3 else 0.0
		var food_bill := roundi(food_per_person_cents() * food_share * (0.85 if economizing else 1.0))
		food_before_support += food_bill
		var supplied_board := _supplied_board(person, study)
		food += roundi(food_bill * (1.0 - clampf(maxf(farm_share, supplied_board), 0.0, 1.0)))
		essentials += purchase_cost(roundi(ESSENTIALS_PER_ADULT_CENTS * price_index * (0.5 if person.age < 18 else 1.0) * (0.5 if economizing else 1.0)))
		care += purchase_cost(roundi(price_index * (150 if person.age < 6 else (400 if person.age >= 70 else 0))))
		contributions.append({"name": person.name, "job": person.job, "income_cents": wages, "work_capacity": work_capacity(person.age)})
	var rooms: int = household.get("rooms", ["Bedroom", "Kitchen", "Washroom"]).size()
	var upkeep := purchase_cost(roundi((BASE_UPKEEP_CENTS + UPKEEP_PER_ROOM_CENTS * rooms) * price_index * (0.5 if economizing else 1.0))) if residents > 0 else 0
	var assessment := Laws.assessment(rules, income, mouths, cereal_consumers, property_assessment, cash_cents, price_index)
	var property_tax: int = assessment["property_tax_cents"]
	var income_tax := roundi(taxable_income * float(rules["income_rate"]))
	var taxes: int = property_tax + income_tax + assessment["household_tax_cents"] + assessment["salt_duty_cents"] + assessment["milling_tax_cents"]
	var living_costs := food + essentials + care + upkeep + taxes
	# Essential bills take priority. Full-time training cannot deepen a debt.
	var training_funded := cash_cents + income - living_costs >= tuition
	var charged_tuition := tuition if training_funded else 0
	if not training_funded:
		var restored_food := _unfunded_board_cost(people, members, farm_share, economizing)
		food += restored_food
		living_costs += restored_food
	var result := {
		"income_cents": income,
		"food_cents": food,
		"essentials_cents": essentials,
		"care_cents": care,
		"upkeep_cents": upkeep,
		"taxes_cents": taxes,
		"property_tax_cents": property_tax,
		"income_tax_cents": income_tax,
		"living_costs_cents": living_costs,
		"expenses_cents": living_costs + charged_tuition,
		"economizing": economizing,
		"tuition_cents": charged_tuition,
		"planned_tuition_cents": tuition,
		"training_funded": training_funded,
		"net_cents": income - living_costs - charged_tuition,
		"residents": residents,
		"contributions": contributions,
	}
	result.merge(assessment, true)
	result["food_support_cents"] = maxi(0, food_before_support - food)
	return result


func settle_month(date: String, people: Dictionary, members: Array, household: Dictionary = {}, year: int = 1800, month: int = 1, property_assessment: int = Laws.DEFAULT_PROPERTY_ASSESSMENT) -> void:
	var entry := budget(people, members, household, year, month, property_assessment)
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
