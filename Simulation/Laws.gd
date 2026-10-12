extends RefCounted
## Calendar-derived rules: dates are historical; amounts are scenario estimates.
const REFORMS := [
	{"year": 1809, "month": 1, "title": "French fiscal reorganization", "effect": "The Tuscan household macinato assessment ends. French property contributions replace the earlier system; personal, openings and trade taxes are summarized rather than fully reconstructed."},
	{"year": 1816, "month": 9, "title": "Restored Tuscan property assessments", "effect": "Prediale and dazio comunitativo assess immovable property. The earlier household macinato assessment is not automatically reinstated."},
	{"year": 1861, "month": 3, "title": "The Kingdom of Italy", "effect": "National government replaces ducal rule. Existing property assessments continue; proclamation alone does not impose a new tax rate."},
	{"year": 1862, "month": 4, "title": "National inheritance duties", "effect": "Cash estates now pay a modeled 2% registration duty after loans and reserved dowries, before heirs receive their shares."},
	{"year": 1864, "month": 7, "title": "Ricchezza mobile", "effect": "A modeled 6% levy on non-agricultural earnings and positive non-farm business profits reduces disposable income."},
	{"year": 1866, "month": 1, "title": "The unified civil code", "effect": "Sons and daughters have equal descendant succession rights; children collectively reserve half the estate. Your equal-share cash will continues to meet this protection."},
	{"year": 1869, "month": 1, "title": "Italian milling duty", "effect": "The new national macinato is charged on cereals milled, not on a Tuscan household income class. Estimated wheat consumption now carries the duty in the food bill."},
	{"year": 1884, "month": 1, "title": "Milling duty abolished", "effect": "The national macinato duty ends. The food bill no longer includes this charge; the simulation does not assume every other food cost falls."},
	{"year": 1898, "month": 7, "title": "Voluntary old-age insurance", "effect": "A voluntary workers' insurance fund is founded. Without modeled enrollment or contributions, this household receives no automatic pension."},
]

static func reached(year: int, month: int, target_year: int, target_month: int) -> bool:
	return year > target_year or (year == target_year and month >= target_month)

static func rules(year: int, month: int) -> Dictionary:
	return {
		"national": reached(year, month, 1861, 3),
		"civil_code": year >= 1866,
		"household_macinato": year < 1809,
		"milling_duty": year >= 1869 and year < 1884,
		"property_name": "Italian property / community assessment" if reached(year, month, 1861, 3) else ("Dazio dei possidenti / community assessment" if year < 1809 else ("Contribuzione fondiaria" if year < 1814 else ("Prediale / dazio comunitativo" if reached(year, month, 1816, 9) else "Restored property assessment"))),
		"income_rate": 0.06 if reached(year, month, 1864, 7) else 0.0,
		"estate_rate": 0.02 if reached(year, month, 1862, 4) else 0.0,
	}

# Eight paying classes plus separately recognized destitution. Thresholds and amounts are estimates,
# not a transcription of a municipality's historical dazzaiolo.
const MEANS_CLASSES := [
	[800, 0, 0], [1200, 8, 15], [1600, 7, 20], [2400, 6, 25], [3600, 5, 35],
	[5200, 4, 45], [7200, 3, 60], [10000, 2, 80],
]
const DEFAULT_PROPERTY_ASSESSMENT := 184000
const IMPUTED_RENTAL_YIELD := 0.05
const PROPERTY_ASSESSMENT_RATE := 0.10
# Two Italian lire per 100 kg of wheat; one base Tuscan lira = 0.84 Italian lire.
const WHEAT_DUTY_BASE_CENTS_PER_KG := 200.0 / 0.84 / 100.0

static func assessment(ruleset: Dictionary, income: int, mouths: int, cereal_consumers: float, property_basis: int, cash: int, price_index: float) -> Dictionary:
	var rental := property_basis * IMPUTED_RENTAL_YIELD / 12.0
	var property_tax := roundi(rental * PROPERTY_ASSESSMENT_RATE * price_index)
	# Means include earnings and estimated capacity from property/savings; being in
	# debt alone is not a certified poverty exemption. Monthly reassessment is a proxy.
	var means := (income / price_index + rental + maxi(0, cash) / price_index * 0.03 / 12.0) / maxi(1, mouths)
	var tax_class := 1
	var mouth_charge := 100
	for row in MEANS_CLASSES:
		if means < row[0]:
			tax_class = row[1]
			mouth_charge = row[2]
			break
	var household_tax := roundi(mouths * mouth_charge * price_index) if ruleset["household_macinato"] else 0
	# Salt/other duties are an estimated component of purchase prices, separately
	# disclosed here so they are charged exactly once. Wheat uses estimated volume.
	var salt_duty := roundi(cereal_consumers * 2.0 * price_index)
	var cereal_kg := cereal_consumers * 10.0
	var milling_tax := roundi(cereal_kg * WHEAT_DUTY_BASE_CENTS_PER_KG) if ruleset["milling_duty"] else 0
	return {"property_tax_cents": property_tax, "property_assessment_cents": property_basis,
		"household_tax_cents": household_tax, "household_tax_class": tax_class,
		"taxable_mouths": mouths, "salt_duty_cents": salt_duty,
		"milling_tax_cents": milling_tax, "estimated_cereal_kg": cereal_kg}

static func regime(year: int, month: int) -> String:
	if reached(year, month, 1861, 3): return "Kingdom of Italy" if year < 1946 or (year == 1946 and month < 6) else "Italian Republic"
	if year >= 1860: return "Tuscany · annexation to Sardinia"
	if year >= 1859: return "Tuscan provisional government"
	if year >= 1814: return "Grand Duchy of Tuscany"
	if year >= 1808: return "Tuscany under French rule"
	if year >= 1801: return "Kingdom of Etruria"
	return "Grand Duchy of Tuscany"

static func estate_duty(state, amount: int) -> int:
	return roundi(maxi(0, amount) * float(rules(state.year, state.month)["estate_rate"]))

static func advance_month(state) -> void:
	for reform in REFORMS:
		if state.year == reform["year"] and state.month == reform["month"]:
			var description: String = reform["title"] + ". " + reform["effect"]
			state.chronicle.append({"date": state.date_text(), "description": description})
			state.notify(description)
			state.major_event = true
