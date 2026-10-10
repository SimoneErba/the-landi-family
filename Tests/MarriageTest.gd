extends SceneTree
const State = preload("res://Simulation/GameState.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")
func _initialize() -> void: call_deferred("_run")
func _state():
	var state = State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.events.enabled = false
	state.economy.cash_cents = 200000
	state.household["capacity"] = 12
	return state
func _adult(state, bride: bool = false):
	var person = state.add_person("TestRelative", {"name": "Maria Landi" if bride else "Mario Landi", "age": 20, "parent_ids": [state.head_id], "life_state": {"can_be_pregnant": bride, "dowry_role": "bride" if bride else "groom"}})
	person.values["romance"] = .8
	person.values["family_loyalty"] = .8
	person.values["independence"] = .3
	person.learned_tendencies["need_for_autonomy"] = .2
	return person
func _valid(state) -> bool:
	return SaveGame._valid_save({"state": state.to_save_data(), "clock": {"speed_level": 1, "month_progress": 0.0}})
func _run() -> void:
	var state = _state()
	var person = _adult(state, true)
	assert(state.marriage.proposals(state,person.id).size() == 5)
	assert(state.marriage.unavailable(state,person.id+":conti","elsewhere").contains("recommendation"))
	var before: int = state.economy.cash_cents
	assert(state.marriage.negotiate(state,person.id+":rossi",8000)["outcome"] == "counteroffer")
	assert(state.economy.cash_cents == before)
	assert(state.marriage.negotiate(state,person.id+":rossi",10000)["outcome"] == "unavailable")
	var agreed: int = state.marriage.offers[person.id+":rossi"]["dowry_cents"]
	state.economy.cash_cents = agreed-1
	assert(not state.marriage.propose(state,person.id+":rossi","elsewhere")["ok"])
	state.economy.cash_cents = before
	assert(state.marriage.propose(state,person.id+":rossi","elsewhere")["ok"])
	assert(state.economy.cash_cents == before-agreed and not person.in_household)
	assert(state.people[person.spouse_id].spouse_id == person.id and not state.people[person.spouse_id].in_household)
	assert(not state.marriage.propose(state,person.id+":rossi","elsewhere")["ok"])
	assert(not person.converse(state.head_id,0,state.date_text()).contains("not here"))
	assert(_valid(state))
	assert(state.marriage.favor(state,"rossi",person.id)["ok"])
	assert(state.marriage.prestige == 1 and state.marriage.alliances["rossi"]["obligation_cents"] == 1500)
	assert(not state.marriage.favor(state,"rossi",person.id)["ok"])
	var cash: int = state.village.households["rossi"].cash_cents
	assert(state.marriage.repay(state,"rossi")["ok"])
	assert(state.village.households["rossi"].cash_cents == cash+1500)
	assert(not state.marriage.repay(state,"rossi")["ok"])
	state.elapsed_months = 12
	state.village.households["rossi"].relationships["landi"] = {"trust": .1, "resentment": .8}
	assert(state.marriage.favor(state,"rossi",person.id)["outcome"] == "refused")
	assert(_valid(state))
	var restored = State.new()
	restored.restore_save_data(state.to_save_data())
	assert(restored.to_save_data() == state.to_save_data())
	for i in 24:
		state.advance_month()
		restored.advance_month()
	assert(restored.to_save_data() == state.to_save_data(), "Continuation remains deterministic")
	state = _state()
	person = _adult(state)
	state.marriage.proposals(state,person.id)
	state.household["capacity"] = state.household["members"].size()
	assert(state.marriage.unavailable(state,person.id+":bianchi","home").contains("space"))
	state.household["capacity"] += 1
	before = state.economy.cash_cents
	cash = state.village.households["bianchi"].cash_cents
	assert(state.marriage.propose(state,person.id+":bianchi","home")["ok"])
	assert(state.economy.cash_cents == before+50000 and state.village.households["bianchi"].cash_cents == cash-50000)
	assert(state.household["members"].has(person.spouse_id))
	state.economy.cash_cents = 100
	state.marriage.relocate(state,person.id,false)
	assert(state.economy.cash_cents == -49900 and not state.people[person.spouse_id].in_household)
	state.marriage.relocate(state,person.id,false)
	assert(state.economy.cash_cents == -49900, "Capital follows the couple once")
	state.marriage.relocate(state,person.id,true)
	assert(state.economy.cash_cents == 100)
	assert(_valid(state))
	state.people[person.spouse_id].alive = false
	state.marriage.advance_month(state)
	assert(state.economy.cash_cents == -49900)
	state.marriage.advance_month(state)
	assert(state.economy.cash_cents == -49900 and _valid(state), "Death releases the obligation once")
	state = _state()
	person = _adult(state)
	state.marriage.proposals(state,person.id)
	before = state.economy.cash_cents
	assert(state.marriage.propose(state,person.id+":rossi","elsewhere")["ok"])
	assert(state.economy.cash_cents == before, "External son's dowry never enters the shared purse")
	var mother = state.people[person.spouse_id]
	mother.life_state["pregnancy"] = {"due_month": 1, "other_parent": person.id}
	state.events.enabled = true
	state.events.monthly_chance = 0.0
	state.advance_month()
	var children: Array = []
	for child in state.people.values():
		if mother.id in child.parent_ids: children.append(child)
	assert(children.size() == 1 and not children[0].in_household and person.id in children[0].parent_ids)
	assert(_valid(state), "Nearby births preserve parentage and household membership")
	state = _state()
	person = _adult(state)
	person.current_state["resentment"] = 1.0
	person.values["romance"] = 0.0
	person.values["tradition"] = 0.0
	person.values["family_loyalty"] = 0.0
	person.values["independence"] = 1.0
	person.learned_tendencies["need_for_autonomy"] = 1.0
	state.marriage.proposals(state,person.id)
	before = state.economy.cash_cents
	assert(state.marriage.propose(state,person.id+":rossi","home")["outcome"] == "refused")
	assert(person.spouse_id.is_empty() and state.economy.cash_cents == before and state.marriage.alliances.is_empty())
	var saved := {"state":state.to_save_data(),"clock":{"speed_level":1,"month_progress":0.0}}
	saved["state"].erase("marriage")
	assert(SaveGame._valid_save(saved), "Earlier saves migrate")
	saved["state"]["marriage"]["unions"] = {"bad":{}}
	assert(not SaveGame._valid_save(saved), "Broken marriage records are rejected")
	# Every allied occupation produces its concrete consequence, rather than a passive bonus.
	for family_id in ["moretti", "ricci", "conti"]:
		state = _state()
		person = _adult(state, true)
		state.marriage.prestige = 1
		state.marriage.proposals(state, person.id)
		assert(state.marriage.propose(state, person.id+":"+family_id, "elsewhere")["ok"])
		state.village.households[family_id].relationships["landi"]["trust"] = .9
		var condition: int = state.household["condition"]
		var standing: int = state.marriage.prestige
		assert(state.marriage.favor(state, family_id, person.id)["ok"])
		assert(state.marriage.prestige == standing+1)
		if family_id == "moretti":
			assert(state.household["condition"] == condition+10 and state.village.development.buildings["home"]["condition"] == float(condition+10))
		elif family_id == "ricci": assert("institution" in person.career_access)
		assert(_valid(state))
	# Negotiation, incoming liquidity and proposal expiry recheck live state.
	state = _state()
	person = _adult(state)
	state.marriage.proposals(state, person.id)
	assert(state.marriage.negotiate(state, person.id+":rossi", 9000)["ok"])
	state.village.households["rossi"].cash_cents = 8999
	assert(not state.marriage.propose(state, person.id+":rossi", "home")["ok"])
	state.elapsed_months = 13
	assert(state.marriage.unavailable(state, person.id+":rossi", "home").contains("expired"))
	state.marriage.proposals(state, person.id)
	assert(state.marriage.offers[person.id+":rossi"]["month"] == 13)
	# High resentment can produce reluctant compliance and consequences without forcing a refusal.
	state.village.households["rossi"].cash_cents = 24000
	person.current_state["resentment"] = .8
	person.values["romance"] = .4
	assert(state.marriage.propose(state, person.id+":rossi", "home")["outcome"] == "reluctant")
	assert(person.current_state["resentment"] > .8 and not person.spouse_id.is_empty())
	assert(_valid(state))
	var tampered := {"state":state.to_save_data(),"clock":{"speed_level":1,"month_progress":0.0}}
	tampered["state"]["marriage"]["unions"]["marriage_1"]["capital_cents"] = 1
	assert(not SaveGame._valid_save(tampered))
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	var ui_state = screen.game_clock.state
	person = _adult(ui_state)
	ui_state.economy.cash_cents = 200000
	screen._show_person(person.id)
	for button in screen.details_content.find_children("*","Button",true,false):
		if button.text == "Marriage & dote": button.pressed.emit(); break
	assert(screen.profile_section == "Marriage")
	assert(screen.details_content.find_child("ProposeMarriage_rossi",true,false) == null, "Candidates do not lengthen the profile")
	var find = screen.details_content.find_child("FindMarriageCandidates",true,false)
	assert(find != null)
	find.pressed.emit()
	assert(screen.marriage_popup.visible)
	var candidates = screen.marriage_popup.find_child("CandidateList",true,false)
	assert(candidates.get_child_count() == ui_state.marriage.proposals(ui_state,person.id).size())
	screen.marriage_popup.find_child("Candidate_moretti",true,false).pressed.emit()
	assert(screen.marriage_popup.find_child("ProposeMarriage_moretti",true,false) != null)
	assert(screen.marriage_popup.find_child("ProposeMarriage_rossi",true,false) == null, "Only the selected candidate's terms are shown")
	screen.marriage_popup.find_child("Candidate_rossi",true,false).pressed.emit()
	var marry = screen.marriage_popup.find_child("ProposeMarriage_rossi",true,false)
	assert(marry != null and not marry.disabled)
	marry.pressed.emit()
	assert(not person.spouse_id.is_empty() and not person.in_household and _valid(ui_state))
	assert(not screen.marriage_popup.visible, "A successful marriage closes candidate selection")
	var resident = ui_state.add_person("ResidentSon", {"age":20, "life_state":{"dowry_role":"groom"}})
	ui_state.household["capacity"] = 15
	ui_state.marriage.proposals(ui_state,resident.id)
	assert(ui_state.marriage.propose(ui_state,resident.id+":bianchi","home")["ok"])
	screen._show_screen("Finances")
	var found := false
	for label in screen.finance_content.find_children("*","Label",true,false):
		if "Dowry owed to resident couples" in label.text: found = true
	assert(found, "Finances exposes received dowry liabilities")
	screen.free()
	print("PASS: negotiated dowry, consent, capacity, alliances, favors, money conservation, relocation, death obligations, nearby births, deterministic saves, migration and playable marriage UI")
	quit()
