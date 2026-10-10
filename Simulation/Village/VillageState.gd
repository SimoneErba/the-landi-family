extends RefCounted
## Small village prototype: public locations and autonomous neighboring households.

const Development = preload("res://Simulation/Village/VillageDevelopment.gd")
var development = Development.new()
const Business = preload("res://Simulation/Village/VillageBusiness.gd")
var business = Business.new()

const Household = preload("res://Simulation/Village/VillageHousehold.gd")

# Globally unique household IDs -> VillageHousehold records.
var households: Dictionary = {}
# Location IDs -> authored records; property IDs -> ownership records.
# Records use the location and ownership fields validated by SaveGame.
var locations: Dictionary = {}
var properties: Dictionary = {}


func initialize() -> void:
	development.initialize()
	business = Business.new()
	households = {}
	locations = {}
	properties = {}
	for entry in [["home", "Landi House"], ["church", "Church"], ["tavern", "Tavern"], ["market", "Market"], ["school", "School"], ["farm", "Fields"], ["workshop", "Workshop"], ["town_hall", "Town hall"]]:
		locations[entry[0]] = {"id": entry[0], "name": entry[1]}
	var starters := [
		["rossi", "Rossi family", "Improve the neighboring fields", 24000, "farm"],
		["bianchi", "Bianchi family", "Expand the grain trade", 50000, "market"],
		["moretti", "Moretti family", "Establish a workshop", 18000, "workshop"],
		["conti", "Conti family", "Gain a voice in village affairs", 36000, "town_hall"],
		["ricci", "Ricci family", "Educate the next generation", 20000, "school"],
	]
	for entry in starters:
		var family = Household.new()
		family.id = entry[0]
		family.name = entry[1]
		family.cash_cents = entry[3]
		family.ambitions = [entry[2]]
		family.relationships = {"landi": {"trust": 0.3, "resentment": 0.1}}
		var property_id: String = family.id + "_holding"
		family.property_ids = [property_id]
		properties[property_id] = {"id": property_id, "name": family.name + " holding", "owner_id": family.id, "location_id": entry[4]}
		households[family.id] = family


func advance_month(state) -> void:
	development.advance_month(state)
	business.advance_month(state)
	# Household-level economy only; individual NPC lives remain a later phase.
	for family in households.values():
		family.cash_cents += 300
		if state.elapsed_months % 12 == 0 and development.invest(state, family.id):
			family.history.append({"date": state.date_text(), "description": "Invested in village property to pursue: " + family.ambitions[0].to_lower() + "."})



func to_save_data() -> Dictionary:
	var saved_households: Dictionary = {}
	for household_id in households:
		saved_households[household_id] = households[household_id].to_save_data()
	return {
		"development": development.to_save_data(),
		"business": business.to_save_data(),
		"households": saved_households,
		"locations": locations.duplicate(true),
		"properties": properties.duplicate(true),
	}


func restore_save_data(data: Dictionary) -> void:
	business.restore_save_data(data.get("business", Business.new().to_save_data()))
	# SaveGame validates the complete village before restore.
	if data.has("development"):
		development.restore_save_data(data["development"])
	else:
		development.initialize()
	households = {}
	for household_id in data.get("households", {}):
		var household = Household.new()
		household.restore_save_data(data["households"][household_id])
		households[household_id] = household
	locations = data.get("locations", {}).duplicate(true)
	properties = data.get("properties", {}).duplicate(true)
