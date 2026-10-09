extends RefCounted
const Development = preload("res://Simulation/Village/VillageDevelopment.gd")

static func fields(value: Variant, example: Dictionary) -> bool:
	if not value is Dictionary:
		return false
	for key in example:
		if not value.has(key) or typeof(value[key]) != typeof(example[key]):
			return false
	return true

static func owner(id: Variant, village: Dictionary) -> bool:
	return id is String and (id in ["landi", "village"] or village["households"].has(id))

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value >= low and value <= high

static func parcel(value: Variant, id: String, village: Dictionary) -> bool:
	if not fields(value, {"id":"", "x":0.0, "y":0.0, "width":0.0, "height":0.0, "owner_id":"", "uses":[], "road_access":0.0, "centrality":0.0, "desirability":0.0, "fertility":0.0, "value_cents":0, "for_sale":false, "building_id":"", "cultivated":false}) or value["id"] != id or not owner(value["owner_id"], village):
		return false
	if not number(value["x"], 0, 1100) or not number(value["y"], 0, 650) or not number(value["width"], 1, 200) or not number(value["height"], 1, 150) or value["value_cents"] < 0 or value["uses"].is_empty():
		return false
	for field in ["road_access", "centrality", "desirability", "fertility"]:
		if not number(value[field], 0, 1):
			return false
	for type in value["uses"]:
		if type not in Development.TYPES:
			return false
	return not value["for_sale"] or value["owner_id"] == "village"

static func building(value: Variant, id: String, parcels: Dictionary, village: Dictionary, elapsed: int) -> bool:
	if not fields(value, {"id":"", "parcel_id":"", "type":"", "built_year":0, "owner_id":"", "condition":0.0, "visual_variant":0, "level":0, "status":"", "address":"", "history":[]}) or value["id"] != id or not parcels.has(value["parcel_id"]) or not owner(value["owner_id"], village):
		return false
	if value["type"] not in Development.TYPES or value["type"] not in parcels[value["parcel_id"]]["uses"] or not number(value["condition"], 0, 100) or value["level"] < 1 or value["level"] > 3 or value["visual_variant"] < 0 or value["visual_variant"] > 2 or value["status"] not in ["standing", "abandoned", "demolished"]:
		return false
	var last := -1
	for entry in value["history"]:
		if not fields(entry, {"month":0,"year":0,"description":""}) or entry["month"] < last or entry["month"] > elapsed:
			return false
		last = entry["month"]
	return true

static func snapshot(value: Variant, village: Dictionary, elapsed: int) -> bool:
	if not fields(value, {"parcels":{},"buildings":{},"infrastructure":{}}) or value["parcels"].size() != 40 or not fields(value["infrastructure"], {"paved_roads":false,"railway":false,"electricity":false}):
		return false
	for id in value["parcels"]:
		if not id is String or not parcel(value["parcels"][id], id, village):
			return false
	var occupied: Dictionary = {}
	for id in value["buildings"]:
		if not id is String or not building(value["buildings"][id], id, value["parcels"], village, elapsed):
			return false
		var record: Dictionary = value["buildings"][id]
		if record["status"] == "demolished":
			continue
		var plot: Dictionary = value["parcels"][record["parcel_id"]]
		if occupied.has(plot["id"]) or plot["building_id"] != id or plot["owner_id"] != record["owner_id"]:
			return false
		occupied[plot["id"]] = true
	for plot in value["parcels"].values():
		if not plot["building_id"].is_empty() and not occupied.has(plot["id"]):
			return false
	return value["buildings"].has("home") and value["buildings"].has("church") and value["buildings"].has("market")

static func valid(data: Variant, village: Dictionary, state: Dictionary) -> bool:
	if not fields(data, Development.new().to_save_data()) or data["next_id"] < 1 or data["revision"] < 0 or data["public_fund_cents"] < 0 or data["origin_month"] < 0 or data["origin_month"] > state["elapsed_months"]:
		return false
	if not snapshot(data, village, state["elapsed_months"]) or not snapshot(data["baseline"], village, state["elapsed_months"]):
		return false
	for id in village["households"]:
		if not data["household_sizes"].has(id) or not data["household_sizes"][id] is int or data["household_sizes"][id] < 1 or data["household_sizes"][id] > 50:
			return false
	for parcel_id in data["property_offers"]:
		var offer: Variant = data["property_offers"][parcel_id]
		if not parcel_id is String or not data["parcels"].has(parcel_id) or not fields(offer, {"owner_id":"", "month":0, "amount_cents":0, "asking_cents":0, "stage":"", "response":""}) or not village["households"].has(offer["owner_id"]) or offer["month"] < 0 or offer["month"] > state["elapsed_months"] or offer["amount_cents"] < 1 or offer["asking_cents"] < 1 or offer["stage"] not in ["accepted", "counteroffer", "refused"]:
			return false
	var reserved: Dictionary = {}
	for id in data["projects"]:
		var record: Variant = data["projects"][id]
		if not id is String or not fields(record, {"id":"","kind":"","parcel_id":"","building_id":"","owner_id":"","type":"","remaining":0}) or record["id"] != id or record["building_id"] != id or record["kind"] not in ["construction","renovation"] or not data["parcels"].has(record["parcel_id"]) or record["remaining"] < 1 or record["remaining"] > 12 or not owner(record["owner_id"], village) or record["type"] not in Development.TYPES:
			return false
		var plot: Dictionary = data["parcels"][record["parcel_id"]]
		if not record.get("paid_cents") is int or record["paid_cents"] < 0 or record["paid_cents"] > Development.COST or not record.get("duration_months") is int or record["duration_months"] != (12 if record["kind"] == "construction" else 6) or record["remaining"] > record["duration_months"]:
			return false
		if reserved.has(plot["id"]) or record["owner_id"] != plot["owner_id"] or record["type"] not in plot["uses"]:
			return false
		if record["kind"] == "construction" and (not plot["building_id"].is_empty() or data["buildings"].has(id)):
			return false
		if record["kind"] == "renovation" and (plot["building_id"] != id or not data["buildings"].has(id)):
			return false
		reserved[plot["id"]] = true
	var last: int = data["origin_month"]
	var view: Dictionary = data["baseline"].duplicate(true)
	for event in data["history"]:
		if not fields(event, {"month":0,"year":0,"description":"","changes":{}}) or event["month"] < last or event["month"] > state["elapsed_months"]:
			return false
		last = event["month"]
		for field in event["changes"]:
			if field not in ["buildings","parcels","infrastructure"] or not event["changes"][field] is Dictionary:
				return false
			for id in event["changes"][field]:
				view[field][id] = event["changes"][field][id]
		if not snapshot(view, village, state["elapsed_months"]):
			return false
	# Ensure current state and replay agree; reject edited or truncated histories.
	for field in ["buildings", "parcels", "infrastructure"]:
		if view[field] != data[field]:
			return false
	for id in data["parcels"]:
		for field in ["x", "y", "width", "height"]:
			if data["parcels"][id][field] != data["baseline"]["parcels"][id][field]:
				return false
	for id in data["buildings"].keys() + data["projects"].keys():
		if str(id).begins_with("building_") and (not str(id).trim_prefix("building_").is_valid_int() or int(str(id).trim_prefix("building_")) >= data["next_id"]):
			return false
	return true
