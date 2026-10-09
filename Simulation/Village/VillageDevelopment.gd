extends RefCounted
## Persistent parcels and structures. The renderer never owns world state.
const TYPES := ["house", "manor", "church", "tavern", "market", "school", "farm", "workshop", "town_hall", "station", "factory"]
const COST := 12000
var parcels: Dictionary = {}
var buildings: Dictionary = {}
var projects: Dictionary = {}
var property_offers: Dictionary = {}
var infrastructure := {"paved_roads": false, "electricity": false, "railway": false}
var public_fund_cents: int = 0
var household_sizes: Dictionary = {}
var next_id: int = 1
var revision: int = 0
var start_year: int = 1800
var origin_month: int = 0
var baseline: Dictionary = {}
var history: Array = []


func initialize(year: int = 1800, elapsed: int = 0) -> void:
	parcels = {}
	buildings = {}
	projects = {}
	property_offers = {}
	infrastructure = {"paved_roads": false, "electricity": false, "railway": false}
	public_fund_cents = 0
	household_sizes = {"rossi": 6, "bianchi": 7, "moretti": 5, "conti": 4, "ricci": 6}
	next_id = 1
	revision = 0
	start_year = year
	origin_month = elapsed
	history = []
	# Forty authored plots; roads, stream and the square remain permanent.
	var points := [Vector2(245,410), Vector2(550,160), Vector2(745,370), Vector2(535,355), Vector2(440,150), Vector2(925,515), Vector2(850,140), Vector2(660,470), Vector2(250,145), Vector2(310,305), Vector2(765,495), Vector2(960,105), Vector2(150,510), Vector2(680,85), Vector2(405,465), Vector2(320,80), Vector2(900,345), Vector2(110,350), Vector2(85,85), Vector2(190,70), Vector2(415,65), Vector2(790,70), Vector2(1050,110), Vector2(180,190), Vector2(380,290), Vector2(740,180), Vector2(880,200), Vector2(1040,335), Vector2(150,425), Vector2(335,390), Vector2(850,430), Vector2(1040,480), Vector2(70,560), Vector2(260,600), Vector2(380,580), Vector2(485,535), Vector2(580,585), Vector2(760,590), Vector2(900,590), Vector2(1030,590)]
	for index in points.size():
		var id := "parcel_%02d" % (index + 1)
		var point: Vector2 = points[index]
		var agricultural := index in [5, 18, 19, 32, 33, 34, 37, 38, 39]
		parcels[id] = {"id": id, "x": point.x, "y": point.y, "width": 90.0, "height": 70.0, "owner_id": "village", "uses": ["farm", "house"] if agricultural else ["house", "workshop", "factory", "station"], "road_access": clampf(1.0 - absf(point.y - 350.0) / 650.0, 0.0, 1.0), "centrality": clampf(1.0 - point.distance_to(Vector2(535,355)) / 650.0, 0.0, 1.0), "desirability": 0.5 + float(index % 4) * 0.1, "fertility": 0.8 if agricultural else 0.3, "value_cents": 4000 + (index % 5) * 1000, "for_sale": index >= 18, "building_id": "", "cultivated": agricultural and index < 18}
	# Keep one plot beside the southern rail corridor for a future station.
	parcels["parcel_40"]["uses"] = ["station"]
	parcels["parcel_40"]["for_sale"] = false
	var starters := [["home","manor","landi"],["church","church","village"],["tavern","tavern","bianchi"],["market","market","village"],["school","school","village"],["farm","farm","rossi"],["workshop","workshop","moretti"],["town_hall","town_hall","village"],["rossi_home","house","rossi"],["bianchi_home","house","bianchi"],["moretti_home","house","moretti"],["conti_home","house","conti"],["ricci_home","house","ricci"],["grain_store","farm","bianchi"],["smithy","workshop","conti"],["olive_farm","farm","ricci"],["mill","workshop","rossi"],["cottager","house","village"]]
	for index in starters.size():
		var entry: Array = starters[index]
		var parcel_id := "parcel_%02d" % (index + 1)
		var record := _building(entry[0], parcel_id, entry[1], entry[2], year - 20 - index)
		record["history"] = [{"month": elapsed, "year": year, "description": "Standing at the beginning of the recorded village history."}]
		buildings[entry[0]] = record
		if entry[1] not in parcels[parcel_id]["uses"]:
			parcels[parcel_id]["uses"].append(entry[1])
		parcels[parcel_id]["building_id"] = entry[0]
		parcels[parcel_id]["owner_id"] = entry[2]
	baseline = _snapshot()


func _building(id: String, parcel_id: String, type: String, owner: String, year: int) -> Dictionary:
	return {"id": id, "parcel_id": parcel_id, "type": type, "built_year": year, "owner_id": owner, "condition": 80.0, "visual_variant": 2 if year >= 1885 else (1 if year >= 1850 else 0), "level": 1, "status": "standing", "address": "Via del Mulino, " + str(int(parcel_id.trim_prefix("parcel_"))), "history": []}


func _snapshot() -> Dictionary:
	return {"parcels": parcels.duplicate(true), "buildings": buildings.duplicate(true), "infrastructure": infrastructure.duplicate(true)}


func view_at(month: int = -1) -> Dictionary:
	if month < 0:
		return _snapshot()
	var view := baseline.duplicate(true)
	for event in history:
		if event["month"] > month:
			break
		for field in ["parcels", "buildings", "infrastructure"]:
			for id in event["changes"].get(field, {}):
				view[field][id] = event["changes"][field][id].duplicate(true) if event["changes"][field][id] is Dictionary else event["changes"][field][id]
	return view


func _record(state, description: String, changed_buildings: Array = [], changed_parcels: Array = [], infra: bool = false) -> void:
	var changes := {"buildings": {}, "parcels": {}, "infrastructure": infrastructure.duplicate(true) if infra else {}}
	for id in changed_buildings:
		buildings[id]["history"].append({"month": state.elapsed_months, "year": state.year, "description": description})
		changes["buildings"][id] = buildings[id].duplicate(true)
	for id in changed_parcels:
		changes["parcels"][id] = parcels[id].duplicate(true)
	history.append({"month": state.elapsed_months, "year": state.year, "description": description, "changes": changes})
	revision += 1
	state.chronicle.append({"date": state.date_text(), "description": description})


func _occupied_project(parcel_id: String) -> bool:
	for project in projects.values():
		if project["parcel_id"] == parcel_id:
			return true
	return false


func eligible(parcel_id: String, type: String, owner: String) -> bool:
	if not parcels.has(parcel_id) or type not in TYPES:
		return false
	var parcel: Dictionary = parcels[parcel_id]
	return type in parcel["uses"] and parcel["building_id"].is_empty() and parcel["owner_id"] in [owner, "village"] and not _occupied_project(parcel_id) and not parcel["cultivated"]


func best_parcel(type: String, owner: String) -> String:
	var best := ""
	var score := -1.0
	for parcel in parcels.values():
		if not eligible(parcel["id"], type, owner):
			continue
		var near := 0.0
		for building in buildings.values():
			if building["owner_id"] == owner and building["status"] == "standing":
				var other: Dictionary = parcels[building["parcel_id"]]
				near = maxf(near, 1.0 - Vector2(parcel["x"], parcel["y"]).distance_to(Vector2(other["x"], other["y"])) / 1000.0)
		var value: float = .4 * parcel["road_access"] + .3 * parcel["centrality"] + .2 * near + .1 * parcel["desirability"]
		if type == "farm":
			value = .6 * parcel["fertility"] + .2 * near + .2 * parcel["road_access"]
		if value > score:
			score = value
			best = parcel["id"]
	return best


func begin_construction(state, parcel_id: String, type: String, owner: String, prepaid: bool = false) -> String:
	if not eligible(parcel_id, type, owner) or (owner != "landi" and not state.village.households.has(owner) and owner != "village"):
		return "This parcel is unavailable for that construction."
	if owner == "landi" and parcels[parcel_id]["owner_id"] != "landi":
		return "Purchase the parcel before building."
	if type == "factory" and state.year < 1870 or type == "station" and state.year < 1845:
		return "This infrastructure is not yet available in the region."
	if not prepaid:
		if owner != "landi":
			return "A household must fund its own construction."
		var cost: int = state.economy.purchase_cost(COST)
		if state.economy.cash_cents < cost:
			return "The family cannot afford this construction."
		state.events._cash(state, -COST, "Village construction")
	var id := "building_%d" % next_id
	next_id += 1
	projects[id] = {"id": id, "kind": "construction", "parcel_id": parcel_id, "building_id": id, "owner_id": owner, "type": type, "remaining": 12, "duration_months": 12, "paid_cents": state.economy.purchase_cost(COST) if owner == "landi" else COST}
	if prepaid and owner == "landi":
		projects[id]["paid_cents"] = 0
	parcels[parcel_id]["owner_id"] = owner
	parcels[parcel_id]["for_sale"] = false
	_record(state, owner.capitalize() + " began constructing a " + type.replace("_", " ") + ".", [], [parcel_id])
	return "Construction started. The building will be ready in 12 months."


func buy_parcel(state, id: String) -> String:
	if not parcels.has(id) or not parcels[id]["for_sale"] or parcels[id]["owner_id"] != "village" or _occupied_project(id):
		return "This land is unavailable for purchase."
	var price: int = state.economy.purchase_cost(parcels[id]["value_cents"])
	if state.economy.cash_cents < price:
		return "The family cannot afford this parcel."
	state.events._cash(state, -parcels[id]["value_cents"], "Purchase village land")
	parcels[id]["owner_id"] = "landi"
	parcels[id]["for_sale"] = false
	_record(state, "The Landi family purchased " + id.replace("_", " ") + ".", [], [id])
	return "The parcel now belongs to the family."


func renovate(state, id: String, prepaid: bool = false) -> String:
	if not buildings.has(id) or buildings[id]["status"] == "demolished" or _occupied_project(buildings[id]["parcel_id"]):
		return "This building cannot be renovated now."
	if not prepaid:
		if buildings[id]["owner_id"] != "landi":
			return "Only the owner can commission a renovation."
		if state.economy.cash_cents < state.economy.purchase_cost(COST):
			return "The family cannot afford this renovation."
		state.events._cash(state, -COST, "Village renovation")
	projects[id] = {"id": id, "kind": "renovation", "parcel_id": buildings[id]["parcel_id"], "building_id": id, "owner_id": buildings[id]["owner_id"], "type": buildings[id]["type"], "remaining": 6, "duration_months": 6, "paid_cents": state.economy.purchase_cost(COST) if buildings[id]["owner_id"] == "landi" else COST}
	if prepaid and buildings[id]["owner_id"] == "landi":
		projects[id]["paid_cents"] = 0
	_record(state, "Renovation began at " + buildings[id]["address"] + ".", [id])
	return "Renovation started. Work takes six months."


func cancellation_refund(id: String) -> int:
	if not projects.has(id):
		return 0
	var project: Dictionary = projects[id]
	return floori(project.get("paid_cents", 0) * float(project["remaining"]) / project.get("duration_months", 12) * .8)

func cancel_project(state, id: String) -> String:
	if not projects.has(id) or projects[id]["owner_id"] != "landi":
		return "Only active family building work can be cancelled."
	var parcel_id: String = projects[id]["parcel_id"]
	var refund := cancellation_refund(id)
	projects.erase(id)
	if refund > 0:
		state.events._cash(state, refund, "Cancelled building work refund", false)
	_record(state, "Cancelled building work; refunded " + state.economy.money(refund) + ".", [id] if buildings.has(id) else [], [parcel_id])
	return "Work cancelled. Land remains yours. Refund: " + state.economy.money(refund) + "."

func transfer(state, id: String, owner: String) -> bool:
	if not buildings.has(id) or buildings[id]["status"] == "demolished" or _occupied_project(buildings[id]["parcel_id"]) or owner not in ["landi", "village"] and not state.village.households.has(owner):
		return false
	buildings[id]["owner_id"] = owner
	var parcel_id: String = buildings[id]["parcel_id"]
	parcels[parcel_id]["owner_id"] = owner
	_record(state, buildings[id]["address"] + " passed to " + owner.capitalize() + ".", [id], [parcel_id])
	return true


func change_use(state, id: String, type: String) -> bool:
	if not buildings.has(id) or type not in TYPES or buildings[id]["status"] != "standing" or _occupied_project(buildings[id]["parcel_id"]) or type not in parcels[buildings[id]["parcel_id"]]["uses"]:
		return false
	buildings[id]["type"] = type
	_record(state, buildings[id]["address"] + " became a " + type.replace("_", " ") + ".", [id])
	return true


func demolish(state, id: String) -> bool:
	if not buildings.has(id) or id in ["home", "church", "market"] or buildings[id]["status"] == "demolished" or _occupied_project(buildings[id]["parcel_id"]):
		return false
	buildings[id]["status"] = "demolished"
	var parcel_id: String = buildings[id]["parcel_id"]
	parcels[parcel_id]["building_id"] = ""
	_record(state, buildings[id]["address"] + " was demolished.", [id], [parcel_id])
	return true


func adopt_infrastructure(state, id: String) -> bool:
	if not infrastructure.has(id) or infrastructure[id]:
		return false
	# Technology unlocks availability; it never automatically creates development.
	if state.year < {"railway": 1845, "paved_roads": 1860, "electricity": 1885}[id] or public_fund_cents < 60000:
		return false
	if id == "railway":
		var parcel_id := "parcel_40" if eligible("parcel_40", "station", "village") else ""
		if parcel_id.is_empty():
			return false
		begin_construction(state, parcel_id, "station", "village", true)
	public_fund_cents -= 60000
	infrastructure[id] = true
	_record(state, "The village invested in " + id.replace("_", " ") + ".", [], [], true)
	return true


func invest(state, owner: String) -> bool:
	# Existing household ambition funds pay for real projects, never decoration by date.
	for project in projects.values():
		if project["owner_id"] == owner:
			return false
	var family = state.village.households[owner]
	var owned: Array = []
	var housing_capacity := 0
	for building in buildings.values():
		if building["owner_id"] == owner and building["status"] != "demolished":
			owned.append(building)
			if building["type"] == "house":
				housing_capacity += 4 * building["level"]
	# Keep three months of productive-property expenses instead of investing
	# the entire purse and immediately starving the business of inputs.
	var reserve := 1200
	for building in owned:
		if building["type"] in state.village.business.CATALOG and building["status"] == "standing":
			var entry: Dictionary = state.village.business.CATALOG[building["type"]]
			reserve += 3 * (entry["upkeep"] + roundi(entry["materials"] * (1.0 + .25 * (building["level"] - 1))))
	if family.cash_cents < COST + reserve:
		return false
	var chosen_type := "house" if household_sizes[owner] > housing_capacity else ("farm" if owner in ["rossi", "ricci"] else "workshop")
	if state.year >= 1870 and family.cash_cents >= 36000 and infrastructure["railway"]:
		for building in owned:
			if building["type"] == "workshop" and building["level"] >= 2 and not _occupied_project(building["parcel_id"]):
				family.cash_cents -= COST
				change_use(state, building["id"], "factory")
				return true
	var parcel_id := best_parcel(chosen_type, owner)
	if household_sizes[owner] > housing_capacity and not parcel_id.is_empty():
		family.cash_cents -= COST
		begin_construction(state, parcel_id, chosen_type, owner, true)
		return true
	for building in owned:
		if building["level"] < 3 or building["condition"] < 65:
			family.cash_cents -= COST
			renovate(state, building["id"], true)
			return true
	if not parcel_id.is_empty() and owned.size() < 6:
		family.cash_cents -= COST
		begin_construction(state, parcel_id, chosen_type, owner, true)
		return true
	return false


func advance_month(state) -> void:
	if buildings["home"]["condition"] != float(state.household["condition"]):
		buildings["home"]["condition"] = float(state.household["condition"])
		_record(state, "The ancestral house condition changed.", ["home"])
	# Construction is prepaid, and only completed projects introduce structures.
	for id in projects.keys():
		var project: Dictionary = projects[id]
		project["remaining"] -= 1
		if project["remaining"] > 0:
			continue
		var parcel_id: String = project["parcel_id"]
		if project["kind"] == "construction":
			buildings[id] = _building(id, parcel_id, project["type"], project["owner_id"], state.year)
			parcels[parcel_id]["building_id"] = id
		else:
			buildings[id]["level"] = mini(3, buildings[id]["level"] + 1)
			buildings[id]["condition"] = 100.0
			buildings[id]["visual_variant"] = mini(2, buildings[id]["visual_variant"] + 1)
			buildings[id]["status"] = "standing"
			if id == "home":
				state.household["condition"] = 100
				state.household["capacity"] += 2
		projects.erase(id)
		_record(state, "Completed " + project["kind"] + " at " + buildings[id]["address"] + ".", [id], [parcel_id])
	if state.elapsed_months % 12 != 0:
		return
	for building in buildings.values():
		if building["status"] == "demolished":
			continue
		var owner: String = building["owner_id"]
		var neglected: bool = state.village.households.has(owner) and state.village.households[owner].cash_cents < 1200
		building["condition"] = maxf(0.0, building["condition"] - (8.0 if neglected else 1.0))
		if building["id"] == "home":
			building["condition"] = float(state.household["condition"])
		if building["condition"] < 25 and building["status"] == "standing" and building["id"] not in ["home", "church", "market"]:
			building["status"] = "abandoned"
			_record(state, building["address"] + " fell into neglect and was abandoned.", [building["id"]])
	# Household counts are an aggregate prototype, separate from named family members.
	for owner in household_sizes:
		var capacity := 0
		for building in buildings.values():
			if building["owner_id"] == owner and building["type"] == "house" and building["status"] == "standing":
				capacity += building["level"] * 4
		var family = state.village.households[owner]
		if family.cash_cents >= 24000 and capacity >= household_sizes[owner] + 2:
			household_sizes[owner] = mini(50, household_sizes[owner] + 1)
		elif family.cash_cents < 1200:
			household_sizes[owner] = maxi(1, household_sizes[owner] - 1)
	# Public revenue depends on occupied private buildings and residents.
	var occupied := 0
	for building in buildings.values():
		if building["status"] == "standing" and building["owner_id"] != "village":
			occupied += 1
	public_fund_cents += occupied * 300
	# Schools and public buildings compete with infrastructure for public savings.
	var residents: int = state.household["members"].size()
	for count in household_sizes.values():
		residents += count
	for building in buildings.values():
		if public_fund_cents < COST:
			break
		var school_pressure: bool = building["type"] == "school" and building["level"] < 3 and residents > building["level"] * 30
		if building["owner_id"] == "village" and building["status"] != "demolished" and not _occupied_project(building["parcel_id"]) and (school_pressure or building["condition"] < 65):
			public_fund_cents -= COST
			renovate(state, building["id"], true)
			break
	for id in ["paved_roads", "railway", "electricity"]:
		adopt_infrastructure(state, id)
	# Persist annual condition changes too: replay must not show today's condition in yesterday's map.
	var changes: Dictionary = {}
	for id in buildings:
		changes[id] = buildings[id].duplicate(true)
	history.append({"month": state.elapsed_months, "year": state.year, "description": "Annual village survey.", "changes": {"buildings": changes}})
	revision += 1


func to_save_data() -> Dictionary:
	return {"parcels": parcels.duplicate(true), "buildings": buildings.duplicate(true), "projects": projects.duplicate(true), "property_offers": property_offers.duplicate(true), "infrastructure": infrastructure.duplicate(true), "public_fund_cents": public_fund_cents, "household_sizes": household_sizes.duplicate(true), "next_id": next_id, "revision": revision, "start_year": start_year, "origin_month": origin_month, "baseline": baseline.duplicate(true), "history": history.duplicate(true)}


func restore_save_data(data: Dictionary) -> void:
	for field in to_save_data():
		var value: Variant = data.get(field, {})
		set(field, value.duplicate(true) if value is Dictionary or value is Array else value)
