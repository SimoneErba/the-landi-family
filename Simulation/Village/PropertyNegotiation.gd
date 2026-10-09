extends RefCounted
## Households bargain over assets; no acceptance odds are exposed to the player.

static func unavailable(state, parcel_id: String) -> String:
	var dev = state.village.development
	if not dev.parcels.has(parcel_id):
		return "This parcel is unavailable."
	var plot: Dictionary = dev.parcels[parcel_id]
	if not state.village.households.has(plot["owner_id"]):
		return "There is no neighboring owner to negotiate with."
	if dev._occupied_project(parcel_id):
		return "The owner has already committed this land to building work."
	var building: Dictionary = dev.buildings.get(plot["building_id"], {})
	if not building.is_empty() and building["type"] == "house" and building["status"] != "demolished":
		var capacity := 0
		for other in dev.buildings.values():
			if other["id"] != building["id"] and other["owner_id"] == plot["owner_id"] and other["type"] == "house" and other["status"] == "standing":
				capacity += other["level"] * 4
		if capacity < dev.household_sizes[plot["owner_id"]]:
			return "They refuse to sell a home their household still needs."
	return ""

static func valuation(state, parcel_id: String) -> int:
	var dev = state.village.development
	var plot: Dictionary = dev.parcels[parcel_id]
	var price: int = plot["value_cents"]
	var building: Dictionary = dev.buildings.get(plot["building_id"], {})
	if not building.is_empty() and building["status"] != "demolished":
		price += roundi(dev.COST * .5 * building["level"] * (.5 + building["condition"] / 200.0))
	return price

static func _asking_price(state, parcel_id: String) -> int:
	var plot: Dictionary = state.village.development.parcels[parcel_id]
	var family = state.village.households[plot["owner_id"]]
	var bond: Dictionary = family.relationships["landi"]
	var multiplier: float = 1.15 + bond["resentment"] * .35 - bond["trust"] * .1
	var building: Dictionary = state.village.development.buildings.get(plot["building_id"], {})
	if not building.is_empty() and building["type"] in ["farm", "workshop", "factory"]:
		multiplier += .15
	if family.cash_cents < 12000 or family.debt_cents > family.cash_cents:
		multiplier -= .2
	return maxi(1, roundi(valuation(state, parcel_id) * multiplier))

static func propose(state, parcel_id: String, amount: int) -> Dictionary:
	var reason := unavailable(state, parcel_id)
	if not reason.is_empty():
		return {"ok": false, "response": reason, "outcome": "refused"}
	if amount <= 0 or state.economy.cash_cents < amount:
		return {"ok": false, "response": "The shared purse cannot cover this offer.", "outcome": "unavailable"}
	var dev = state.village.development
	var owner: String = dev.parcels[parcel_id]["owner_id"]
	for offer in dev.property_offers.values():
		if offer["owner_id"] == owner and offer["month"] == state.elapsed_months:
			return {"ok": false, "response": "Give this household time before making another offer this month.", "outcome": "unavailable"}
	var asking := _asking_price(state, parcel_id)
	var stage := "accepted" if amount >= asking else ("counteroffer" if amount >= roundi(asking * .7) else "refused")
	var family = state.village.households[owner]
	var response: String
	match stage:
		"accepted": response = "The " + family.name + " accepted your offer."
		"counteroffer": response = "The " + family.name + " would consider selling for " + state.economy.money(asking) + "."
		_: response = "The " + family.name + " refused: the property is worth more to us."
	dev.property_offers[parcel_id] = {"owner_id": owner, "month": state.elapsed_months, "amount_cents": amount, "asking_cents": asking, "stage": stage, "response": response}
	if stage == "accepted":
		_execute(state, parcel_id, amount, owner)
	else:
		state.chronicle.append({"date": state.date_text(), "description": response})
		family.history.append({"date": state.date_text(), "description": response})
	return {"ok": stage == "accepted", "response": response, "outcome": stage}

static func accept_counteroffer(state, parcel_id: String) -> Dictionary:
	var dev = state.village.development
	var offer: Dictionary = dev.property_offers.get(parcel_id, {})
	if offer.is_empty() or offer["stage"] != "counteroffer":
		return {"ok": false, "response": "There is no counteroffer to accept."}
	if state.elapsed_months - offer["month"] > 2 or dev.parcels[parcel_id]["owner_id"] != offer["owner_id"]:
		return {"ok": false, "response": "This offer has expired or the property changed hands."}
	var reason := unavailable(state, parcel_id)
	if not reason.is_empty():
		return {"ok": false, "response": reason}
	if state.economy.cash_cents < offer["asking_cents"]:
		return {"ok": false, "response": "The shared purse cannot cover the counteroffer."}
	_execute(state, parcel_id, offer["asking_cents"], offer["owner_id"])
	return {"ok": true, "response": "The purchase is complete. The agreed price was paid to the seller."}

static func _execute(state, parcel_id: String, amount: int, owner: String) -> void:
	var dev = state.village.development
	var plot: Dictionary = dev.parcels[parcel_id]
	# Pay the exact agreement. A purchase bonus cannot short-change a private seller.
	state.events._cash(state, -amount, "Negotiated property purchase", false)
	var family = state.village.households[owner]
	family.cash_cents += amount
	plot["owner_id"] = "landi"
	plot["for_sale"] = false
	var building_id: String = plot["building_id"]
	if not building_id.is_empty():
		dev.buildings[building_id]["owner_id"] = "landi"
	dev.property_offers[parcel_id]["stage"] = "accepted"
	var description: String = "The Landi family purchased " + parcel_id.replace("_", " ") + " from the " + family.name + " for " + state.economy.money(amount) + "."
	family.history.append({"date": state.date_text(), "description": description})
	dev._record(state, description, [building_id] if not building_id.is_empty() else [], [parcel_id])
