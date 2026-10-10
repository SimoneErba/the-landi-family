extends RefCounted
## Marriage opens relationships. Dowry remains an obligation to the couple.
const Person = preload("res://Simulation/Person.gd")
const FAMILIES := {
	"rossi": {"occupation": "Farmers", "prestige": 0, "dowry": 10000, "skill": "agriculture", "favor": "Seasonal help", "description": "Help in the fields: develop agriculture and receive seasonal earnings."},
	"bianchi": {"occupation": "Merchants", "prestige": 1, "dowry": 50000, "skill": "commerce", "favor": "Trade introduction", "description": "An introduction to buyers: develop commerce and earn from a small trade."},
	"moretti": {"occupation": "Artisans", "prestige": 0, "dowry": 18000, "skill": "craft", "favor": "Repair assistance", "description": "Repair Landi House and teach practical craft."},
	"conti": {"occupation": "Landowners", "prestige": 3, "dowry": 150000, "skill": "persuasion", "favor": "Recommendation to notables", "description": "A landowner's recommendation: develop persuasion and family standing."},
	"ricci": {"occupation": "Educated family", "prestige": 1, "dowry": 25000, "skill": "literacy", "favor": "Private tutoring", "description": "Tutor a relative in literacy and open a professional contact."},
}
var offers: Dictionary = {}
var unions: Dictionary = {}
var alliances: Dictionary = {}
var prestige: int = 0
var next_id: int = 1

func role(person) -> String:
	# Explicit convention, separate from appearance. Legacy data uses its existing reproductive flag.
	return str(person.life_state.get("dowry_role", "bride" if person.life_state.get("can_be_pregnant", false) else "groom"))

func reason(state, person_id: String) -> String:
	if not state.people.has(person_id): return "This relative is unavailable."
	var person = state.people[person_id]
	if not person.alive or not state.people[state.head_id].alive: return "Only living people can marry."
	if person.age < 18: return "Marriage proposals are for adults."
	if not person.spouse_id.is_empty(): return "They are already married."
	if not state.travel.current(person_id).is_empty(): return "Wait until they return from their journey."
	if state.activities.commitment(person_id) != null or not state.village.business.commitment(person_id).is_empty(): return "Resolve their current family responsibility before arranging a marriage."
	return ""

func proposals(state, person_id: String) -> Array:
	if not reason(state, person_id).is_empty(): return []
	var result: Array = []
	for family_id in FAMILIES:
		var offer_id: String = person_id + ":" + family_id
		if not offers.has(offer_id) or state.elapsed_months - int(offers[offer_id]["month"]) > 12:
			var entry: Dictionary = FAMILIES[family_id]
			var person = state.people[person_id]
			var bride: bool = role(person) == "groom"
			var given_name: String = {"rossi": ["Maria", "Giovanni"], "bianchi": ["Rosa", "Lorenzo"], "moretti": ["Teresa", "Pietro"], "conti": ["Beatrice", "Alessandro"], "ricci": ["Elena", "Antonio"]}[family_id][0 if bride else 1]
			var source := {"name": given_name + " " + str(family_id).capitalize(), "birth": {"year": state.year - clampi(person.age + (2 if not bride else -2) + int(entry["prestige"]), 18, 40), "month": 1}, "in_household": false, "branch_id": person.branch_id, "relationship": "Relative by marriage", "job": entry["occupation"], "monthly_income_cents": 1800 + int(entry["prestige"]) * 800, "life_state": {"can_be_pregnant": bride, "dowry_role": "bride" if bride else "groom"}, "psychology": {"values": {"independence": 0.35 + float(entry["prestige"]) * 0.12, "family_loyalty": 0.8 - float(entry["prestige"]) * 0.12, "romance": 0.65, "status": 0.3 + float(entry["prestige"]) * 0.2}}, "portrait": {"appearance": {"presentation": "feminine" if bride else "masculine"}}}
			offers[offer_id] = {"person_id": person_id, "family_id": family_id, "source": source, "month": state.elapsed_months, "dowry_cents": int(entry["dowry"]), "last_negotiation": -1, "last_proposal": -1}
		result.append({"id": offer_id, "offer": offers[offer_id].duplicate(true), "family": FAMILIES[family_id].duplicate(true)})
	return result

func unavailable(state, offer_id: String, residence: String) -> String:
	if not offers.has(offer_id) or residence not in ["home", "elsewhere"]: return "This proposal is unavailable."
	var offer: Dictionary = offers[offer_id]
	var blocked := reason(state, offer["person_id"])
	if not blocked.is_empty(): return blocked
	if state.elapsed_months - int(offer["month"]) > 12: return "This proposal has expired. Browse new proposals."
	var person = state.people[offer["person_id"]]
	if int(state.last_requests.get(person.id, -1)) == state.elapsed_months: return "Give them time before another request this month."
	if FAMILIES[offer["family_id"]]["prestige"] >= 3 and prestige < 1: return "This family asks for a recommendation. Earn standing through an allied family's favor first."
	if role(person) == "bride" and state.economy.cash_cents < int(offer["dowry_cents"]): return "The shared purse cannot cover the dowry."
	if role(person) == "groom" and state.village.households[offer["family_id"]].cash_cents < int(offer["dowry_cents"]): return "The bride's family cannot fund this dowry at present."
	if residence == "home":
		var needed := 1 if person.in_household else 2
		if state.household["members"].size() + needed > int(state.household["capacity"]): return "There is not enough space for this couple. Expand the house or choose a separate home."
	if residence == "elsewhere" and person.id == state.head_id: return "The family head must retain Landi House."
	return ""

func negotiate(state, offer_id: String, amount: int) -> Dictionary:
	if not offers.has(offer_id) or amount <= 0: return _result(false, "unavailable", "Enter a positive dowry.")
	var offer: Dictionary = offers[offer_id]
	var blocked := reason(state, offer["person_id"])
	if not blocked.is_empty(): return _result(false, "unavailable", blocked)
	if state.elapsed_months - int(offer["month"]) > 12: return _result(false, "unavailable", "This proposal has expired.")
	if int(offer["last_negotiation"]) == state.elapsed_months: return _result(false, "unavailable", "This family has already discussed this proposal this month.")
	offer["last_negotiation"] = state.elapsed_months
	var family = state.village.households[offer["family_id"]]
	var bond: Dictionary = family.relationships["landi"]
	var base: int = FAMILIES[offer["family_id"]]["dowry"]
	var bride: bool = role(state.people[offer["person_id"]]) == "bride"
	var limit := roundi(base * (1.0 - float(bond["trust"]) * 0.25 + float(bond["resentment"]) * 0.2)) if bride else mini(family.cash_cents, roundi(base * (0.85 + float(bond["trust"]) * 0.4 - float(bond["resentment"]) * 0.2)))
	var accepted: bool = amount >= limit if bride else amount <= limit
	if accepted: offer["dowry_cents"] = amount
	elif (bride and amount >= roundi(limit * .7)) or (not bride and amount <= roundi(limit * 1.3)):
		offer["dowry_cents"] = maxi(1, limit)
		return _result(false, "counteroffer", "They propose a dowry of %s. The proposal now shows these terms; no money has moved." % state.economy.money(offer["dowry_cents"]))
	return _result(accepted, "accepted" if accepted else "refused", "The family agreed to the new terms." if accepted else "The family refused those terms. The earlier proposal remains available.")

func propose(state, offer_id: String, residence: String) -> Dictionary:
	var blocked := unavailable(state, offer_id, residence)
	if not blocked.is_empty(): return _result(false, "unavailable", blocked)
	var offer: Dictionary = offers[offer_id]
	var person = state.people[offer["person_id"]]
	var partner = Person.new("candidate", offer["source"], state.year, state.month, state.head_id)
	state.last_requests[person.id] = state.elapsed_months
	offer["last_proposal"] = state.elapsed_months
	var compatibility := _compatibility(person, partner)
	var own_score := _willingness(person, compatibility, residence, state.head_id)
	var partner_score := _willingness(partner, compatibility, residence, "")
	var score := minf(own_score, partner_score)
	var outcome := "accepted" if score >= .3 else ("reluctant" if score >= .12 else "refused")
	var response := "We want to build a life together." if outcome == "accepted" else ("I will try, for the family's sake. I am giving up plans of my own." if outcome == "reluctant" else "This is not the life I want. Please listen to me.")
	if outcome != "accepted":
		person.current_state["resentment"] = minf(1.0, float(person.current_state.get("resentment", 0.0)) + (.09 if outcome == "reluctant" else .03))
		var bond: Dictionary = person.relationships.get(state.head_id, {}).duplicate(true)
		bond["trust"] = maxf(0.0, float(bond.get("trust", .4)) - .04)
		person.relationships[state.head_id] = bond
	_record(state, person.name + " considered marriage with " + partner.name + ": " + response)
	person.memories.append({"date": state.date_text(), "kind": "marriage", "description": response, "participants": [state.head_id]})
	if outcome == "refused": return _result(false, outcome, response)
	var union_id := "marriage_%d" % next_id
	next_id += 1
	var source: Dictionary = offer["source"].duplicate(true)
	source["in_household"] = residence == "home"
	var spouse = state.add_person(union_id + "_spouse", source)
	person.spouse_id = spouse.id
	spouse.spouse_id = person.id
	var couple: Array = [person.id, spouse.id]
	var dowry: int = offer["dowry_cents"]
	var incoming: bool = role(person) == "groom"
	var family = state.village.households[offer["family_id"]]
	if incoming: family.cash_cents -= dowry
	else: state.events._cash(state, -dowry, "Dowry for " + person.name, false)
	if incoming and residence == "home": state.events._cash(state, dowry, "Couple's dowry received for " + person.name, false)
	unions[union_id] = {"couple": couple, "family_id": family.id, "dowry_cents": dowry, "incoming": incoming, "held_at_home": incoming and residence == "home", "residence": residence, "capital_cents": dowry, "settled": false, "month": state.elapsed_months}
	for member in [person, spouse]:
		member.life_state["marriage_id"] = union_id
		member.life_state["village_family_id"] = family.id
		member.in_household = residence == "home"
		member.decision_state["plan"] = {}
		if member.in_household and member.id not in state.household["members"]: state.household["members"].append(member.id)
		elif not member.in_household: state.household["members"].erase(member.id)
		for goal in member.goals:
			if goal.get("kind") == "seek_marriage": goal["status"] = "completed"
		member.relationships[member.spouse_id] = {"affection": compatibility, "trust": .6, "resentment": .08 if outcome == "reluctant" else 0.0}
	if not alliances.has(family.id): alliances[family.id] = {"last_favor": -24, "obligation_cents": 0, "strength": .5}
	family.relationships["landi"]["trust"] = minf(1.0, float(family.relationships["landi"]["trust"]) + .15)
	_record(state, "%s married %s. Dowry: %s. %s A relationship with the %s opens requests for favors." % [person.name, spouse.name, state.economy.money(dowry), "The couple stays in Landi House." if residence == "home" else "The couple forms a nearby household, with its own dowry capital.", family.name])
	state.legacy.evaluate(state)
	return _result(true, outcome, response)

func relocate(state, person_id: String, at_home: bool) -> String:
	var blocked := relocation_reason(state, person_id, at_home)
	if not blocked.is_empty(): return blocked
	var union_id: String = state.people[person_id].life_state.get("marriage_id", "")
	if not unions.has(union_id): return ""
	var union: Dictionary = unions[union_id]
	if union["residence"] == ("home" if at_home else "elsewhere") and state.people[union["couple"][0]].in_household == at_home and state.people[union["couple"][1]].in_household == at_home: return ""
	var members: Array = union["couple"].duplicate()
	for child in state.people.values():
		if child.alive and child.age < 18 and (members[0] in child.parent_ids or members[1] in child.parent_ids): members.append(child.id)
	for id in members:
		var member = state.people[id]
		if not member.alive: continue
		member.in_household = at_home
		if at_home and id not in state.household["members"]: state.household["members"].append(id)
		elif not at_home: state.household["members"].erase(id)
	if union["incoming"] and not union["settled"]:
		if union["held_at_home"] and not at_home:
			state.events._cash(state, -int(union["capital_cents"]), "Dowry follows departing couple", false)
		elif not union["held_at_home"] and at_home:
			state.events._cash(state, int(union["capital_cents"]), "Returning couple's dowry capital", false)
		union["held_at_home"] = at_home
	union["residence"] = "home" if at_home else "elsewhere"
	_record(state, state.people[person_id].name + "'s couple and dependent children " + ("returned home." if at_home else "moved to their nearby household. Their dowry follows them; a spent dowry becomes a shortfall in the shared purse."))
	return ""

func relocation_reason(state, person_id: String, at_home: bool) -> String:
	var union_id: String = state.people[person_id].life_state.get("marriage_id", "")
	if not unions.has(union_id): return ""
	var union: Dictionary = unions[union_id]
	for id in union["couple"]:
		if not state.travel.current(id).is_empty(): return "Wait until both spouses are home from travel."
		if not at_home and id == state.head_id: return "The family head must stay at Landi House."
	if at_home:
		var needed := 0
		for member in state.people.values():
			if member.alive and not member.in_household and (member.id in union["couple"] or (member.age < 18 and (union["couple"][0] in member.parent_ids or union["couple"][1] in member.parent_ids))): needed += 1
		if state.household["members"].size() + needed > state.household["capacity"]: return "There is not enough room for the couple and their children."
	return ""

func favor(state, family_id: String, beneficiary_id: String) -> Dictionary:
	if not alliances.has(family_id) or not FAMILIES.has(family_id) or not state.people.has(beneficiary_id): return _result(false, "unavailable", "A marriage alliance and a living beneficiary are required.")
	var person = state.people[beneficiary_id]
	var alliance: Dictionary = alliances[family_id]
	if not person.alive: return _result(false, "unavailable", "Choose a living relative.")
	if alliance["obligation_cents"] > 0: return _result(false, "unavailable", "Repay the previous favor before asking again.")
	if state.elapsed_months - int(alliance["last_favor"]) < 12: return _result(false, "unavailable", "Give this family a year before asking another favor.")
	alliance["last_favor"] = state.elapsed_months
	var family = state.village.households[family_id]
	var bond: Dictionary = family.relationships["landi"]
	var score: float = float(bond["trust"]) - float(bond["resentment"]) + float(alliance["strength"]) * .2
	if score < .35:
		_record(state, family.name + " declined a request for a favor. The marriage does not guarantee their help.")
		return _result(false, "refused", "Our own household comes first. We cannot help you now.")
	var entry: Dictionary = FAMILIES[family_id]
	person.skills[entry["skill"]] = minf(100.0, float(person.skills[entry["skill"]]) + 8.0 * state.legacy.learning_multiplier())
	var known: Dictionary = person.career_knowledge.get(state.head_id, {"skills": []})
	if not known.has("skills"): known["skills"] = []
	if entry["skill"] not in known["skills"]: known["skills"].append(entry["skill"])
	person.career_knowledge[state.head_id] = known
	if family_id == "moretti": state.household["condition"] = mini(100, int(state.household["condition"]) + 10)
	elif family_id in ["rossi", "bianchi"]:
		var payment := mini(family.cash_cents, 2000)
		family.cash_cents -= payment
		state.events._cash(state, payment, entry["favor"], false)
	elif family_id == "ricci" and "institution" not in person.career_access: person.career_access.append("institution")
	prestige = mini(5, prestige + 1)
	alliance["strength"] = minf(1.0, float(alliance["strength"]) + .05)
	alliance["obligation_cents"] = 1500 if score < .65 else 0
	_record(state, family.name + " granted " + entry["favor"].to_lower() + " for " + person.name + (". They expect 15 lire in return." if alliance["obligation_cents"] > 0 else ". No repayment was requested."))
	if family_id == "moretti": state.village.development.buildings["home"]["condition"] = float(state.household["condition"])
	if family_id == "moretti": state.village.development._record(state, "Repairs from marriage allies", ["home"])
	return _result(true, "reciprocal" if alliance["obligation_cents"] > 0 else "accepted", "The favor was granted." + (" They expect 15 lire in return." if alliance["obligation_cents"] > 0 else ""))

func repay(state, family_id: String) -> Dictionary:
	if not alliances.has(family_id): return _result(false, "unavailable", "No such alliance.")
	var amount: int = alliances[family_id]["obligation_cents"]
	if amount <= 0 or state.economy.cash_cents < amount: return _result(false, "unavailable", "There is no payable obligation, or the purse cannot cover it.")
	state.events._cash(state, -amount, "Marriage favor repayment", false)
	state.village.households[family_id].cash_cents += amount
	alliances[family_id]["obligation_cents"] = 0
	state.village.households[family_id].relationships["landi"]["trust"] = minf(1.0, float(state.village.households[family_id].relationships["landi"]["trust"]) + .08)
	return _result(true, "accepted", "The obligation has been repaid.")

func advance_month(state) -> void:
	for family_id in alliances:
		var alliance: Dictionary = alliances[family_id]
		if alliance["obligation_cents"] > 0 and state.elapsed_months - int(alliance["last_favor"]) > 12:
			var bond: Dictionary = state.village.households[family_id].relationships["landi"]
			bond["resentment"] = minf(1.0, float(bond["resentment"]) + .005)
	for union in unions.values():
		var first = state.people[union["couple"][0]]
		var second = state.people[union["couple"][1]]
		var family = state.village.households[union["family_id"]]
		if not first.alive or not second.alive:
			if not union["settled"]:
				if union["held_at_home"]: state.events._cash(state, -int(union["capital_cents"]), "Dowry released after a spouse's death", false)
				union["held_at_home"] = false
				union["settled"] = true
				_record(state, "A marriage ended in death. Its dowry is reserved for the survivor or descendants; the family connection remains.")
			continue
		# Reconcile moves from other systems as well as direct requests.
		if union["residence"] == "home" and state.travel.current(first.id).is_empty() and state.travel.current(second.id).is_empty() and (not first.in_household or not second.in_household): relocate(state, first.id, false)
		var friction := absf(float(first.values["independence"]) - float(second.values["independence"])) * .01
		var stress := (float(first.current_state.get("stress", 0)) + float(second.current_state.get("stress", 0))) * .005
		for member in [first, second]:
			var bond: Dictionary = member.relationships[member.spouse_id]
			bond["affection"] = clampf(float(bond["affection"]) + .004 - friction - stress, 0, 1)
			bond["resentment"] = clampf(float(bond["resentment"]) + stress - .003, 0, 1)
		var affection: float = first.relationships[second.id]["affection"]
		alliances[family.id]["strength"] = clampf(float(alliances[family.id]["strength"]) + (affection - .5) * .01, .05, 1)
		if state.elapsed_months % 12 == 0:
			var previous_trust: float = family.relationships["landi"]["trust"]
			family.relationships["landi"]["trust"] = clampf(previous_trust + (affection - .5) * .04, 0, 1)
			if previous_trust >= .35 and family.relationships["landi"]["trust"] < .35:
				var description: String = "Relations with the " + family.name + " have cooled as the marriage comes under strain."
				state.chronicle.append({"date":state.date_text(), "description":description})
				state.notify(description, first.id)
		# Nearby branches keep having children using the existing pregnancy/birth system.
		if state.events.enabled and union["residence"] == "elsewhere":
			for mother in [first, second]:
				if mother.life_state.get("can_be_pregnant", false) and mother.age >= 18 and mother.age <= 42 and mother.health == "Well" and mother.life_state.get("pregnancy", {}).is_empty() and state.elapsed_months >= int(mother.life_state.get("next_pregnancy_month", 0)) and affection >= .25:
					if state.events.rng.randf() < .015 * state.legacy.fertility_multiplier():
						mother.life_state["pregnancy"] = {"due_month": state.elapsed_months + 9, "other_parent": mother.spouse_id}
						_record(state, mother.name + " is expecting a child in the nearby branch household.")

static func _compatibility(first, second) -> float:
	var difference := 0.0
	for value in ["family_loyalty", "independence", "tradition", "romance", "achievement"]: difference += absf(float(first.values[value]) - float(second.values[value]))
	return clampf(1.0 - difference / 5.0, 0.0, 1.0)

static func _willingness(person, compatibility: float, residence: String, head_id: String) -> float:
	var bond: Dictionary = person.relationships.get(head_id, {})
	var score := compatibility * .35 + float(person.values["romance"]) * .3 + float(person.values["tradition"]) * .12 + float(bond.get("trust", .4)) * .1 - float(person.current_state.get("resentment", 0)) * .4 - float(person.learned_tendencies["need_for_autonomy"]) * .2
	score += (float(person.values["family_loyalty"]) * .2 - float(person.values["independence"]) * .25) if residence == "home" else (float(person.values["independence"]) * .15 - float(person.values["family_loyalty"]) * .12)
	if not person.education["study"].is_empty(): score -= float(person.values["achievement"]) * .3
	if not str(person.life_state.get("preferred_spouse", "")).is_empty(): score -= .25
	return score

static func _result(ok: bool, outcome: String, response: String) -> Dictionary:
	return {"ok": ok, "outcome": outcome, "response": response}

func _record(state, description: String) -> void:
	state.major_event = true
	state.chronicle.append({"date": state.date_text(), "description": description})

func to_save_data() -> Dictionary:
	return {"offers": offers.duplicate(true), "unions": unions.duplicate(true), "alliances": alliances.duplicate(true), "prestige": prestige, "next_id": next_id}

func restore_save_data(data: Dictionary) -> void:
	for field in to_save_data():
		if data.has(field): set(field, data[field].duplicate(true) if data[field] is Dictionary else data[field])

static func valid(data: Variant, state: Dictionary) -> bool:
	if not data is Dictionary: return false
	for field in ["offers", "unions", "alliances"]:
		if not data.get(field) is Dictionary: return false
	if not data.get("next_id") is int or data["next_id"] < 1 or not data.get("prestige") is int or data["prestige"] < 0 or data["prestige"] > 5: return false
	for id in data["offers"]:
		var offer: Variant = data["offers"][id]
		if not id is String or not offer is Dictionary: return false
		if not offer.get("person_id") is String or not state["people"].has(offer["person_id"]) or not offer.get("family_id") is String or not FAMILIES.has(offer["family_id"]) or not state["village"]["households"].has(offer["family_id"]): return false
		if id != offer["person_id"] + ":" + offer["family_id"]: return false
		for field in ["month", "last_negotiation", "last_proposal", "dowry_cents"]:
			if not offer.get(field) is int: return false
		if offer["month"] < 0 or offer["month"] > state["elapsed_months"] or offer["dowry_cents"] <= 0: return false
		for field in ["last_negotiation", "last_proposal"]:
			if offer[field] < -1 or offer[field] > state["elapsed_months"]: return false
		var source: Variant = offer.get("source")
		if not source is Dictionary: return false
		for field in ["name", "branch_id", "relationship", "job"]:
			if not source.get(field) is String: return false
		if not source.get("monthly_income_cents") is int or source["monthly_income_cents"] < 0 or not source.get("in_household") is bool: return false
		if not source.get("birth") is Dictionary or not source["birth"].get("year") is int or not source["birth"].get("month") is int or source["birth"]["month"] < 1 or source["birth"]["month"] > 12: return false
		if not source.get("life_state") is Dictionary or not source["life_state"].get("can_be_pregnant") is bool or source["life_state"].get("dowry_role") not in ["bride", "groom"]: return false
		if not source.get("psychology") is Dictionary or not source["psychology"].get("values") is Dictionary: return false
		for key in source["psychology"]["values"]:
			var value: Variant = source["psychology"]["values"][key]
			if key not in Person.VALUES or not value is float or not is_finite(value) or value < 0 or value > 1: return false
		if not source.get("portrait") is Dictionary or not source["portrait"].get("appearance") is Dictionary or source["portrait"]["appearance"].get("presentation") not in ["feminine", "masculine"]: return false
	var seen: Dictionary = {}
	for id in data["unions"]:
		var union: Variant = data["unions"][id]
		if not id is String or not id.begins_with("marriage_") or not id.trim_prefix("marriage_").is_valid_int() or int(id.trim_prefix("marriage_")) < 1 or int(id.trim_prefix("marriage_")) >= data["next_id"] or not union is Dictionary: return false
		if not union.get("family_id") is String or not data["alliances"].has(union["family_id"]) or not FAMILIES.has(union["family_id"]): return false
		if not union.get("couple") is Array or union["couple"].size() != 2 or union["couple"][0] == union["couple"][1]: return false
		for member in union["couple"]:
			if not member is String or not state["people"].has(member) or seen.has(member): return false
			seen[member] = id
			var person: Dictionary = state["people"][member]
			if person["spouse_id"] not in union["couple"] or person["spouse_id"] == member or person["life_state"].get("marriage_id") != id: return false
			if not person["relationships"].has(person["spouse_id"]): return false
			var bond: Variant = person["relationships"][person["spouse_id"]]
			if not bond is Dictionary: return false
			for key in ["affection", "trust", "resentment"]:
				if not bond.get(key) is float or not is_finite(bond[key]) or bond[key] < 0 or bond[key] > 1: return false
		for field in ["incoming", "held_at_home", "settled"]:
			if not union.get(field) is bool: return false
		for field in ["dowry_cents", "capital_cents", "month"]:
			if not union.get(field) is int or union[field] < 0: return false
		if union["month"] > state["elapsed_months"] or union["capital_cents"] != union["dowry_cents"] or union["dowry_cents"] <= 0 or union.get("residence") not in ["home", "elsewhere"]: return false
		if union["held_at_home"] != (union["incoming"] and union["residence"] == "home" and not union["settled"]): return false
	for person_id in state["people"]:
		var union_id: Variant = state["people"][person_id]["life_state"].get("marriage_id", "")
		if not union_id is String or (not union_id.is_empty() and seen.get(person_id) != union_id): return false
	for family_id in data["alliances"]:
		if not FAMILIES.has(family_id) or not state["village"]["households"].has(family_id): return false
		var alliance: Variant = data["alliances"][family_id]
		if not alliance is Dictionary or not alliance.get("last_favor") is int or alliance["last_favor"] < -24 or alliance["last_favor"] > state["elapsed_months"] or not alliance.get("obligation_cents") is int or alliance["obligation_cents"] < 0: return false
		if not alliance.get("strength") is float or not is_finite(alliance["strength"]) or alliance["strength"] < 0 or alliance["strength"] > 1: return false
	return true
