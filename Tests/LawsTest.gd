extends SceneTree
const State = preload("res://Simulation/GameState.gd")
const Clock = preload("res://Simulation/GameClock.gd")
const Save = preload("res://Simulation/SaveGame.gd")

func _initialize() -> void:
	call_deferred("_run")

func _state(year: int = 1800, month: int = 1):
	var state = State.new()
	state.year = year
	state.month = month
	state.initialize({"Giovanni": {"age": 50, "career_id": "farmer", "monthly_income_cents": 8000}, "Son": {"age": 25, "parent_ids": ["Giovanni"], "monthly_income_cents": 5000}, "Daughter": {"age": 23, "parent_ids": ["Giovanni"]}})
	state.events.enabled = false
	state.succession.enabled = false
	return state

func _run() -> void:
	var state = _state()
	# The 1800 household roll counts people aged three and over, across sexes.
	state.add_person("Infant", {"age": 2, "monthly_income_cents": 0})
	var roll: Dictionary = state.economy.budget(state.people, state.household["members"], state.household)
	assert(roll["taxable_mouths"] == 3)
	state.people["Infant"].age = 3
	var larger: Dictionary = state.economy.budget(state.people, state.household["members"], state.household)
	assert(larger["taxable_mouths"] == 4 and larger["household_tax_cents"] > 0)
	state.people["Son"].in_household = false
	state.household["members"].erase("Son")
	assert(state.economy.budget(state.people, state.household["members"], state.household)["taxable_mouths"] == 3)
	var poor: Dictionary = State.Laws.assessment(State.Laws.rules(1800, 1), 0, 4, 4.0, 0, 0, 1.0)
	var rich: Dictionary = State.Laws.assessment(State.Laws.rules(1800, 1), 50000, 4, 4.0, 0, -10000, 1.0)
	assert(poor["household_tax_class"] == 0 and poor["household_tax_cents"] == 0)
	assert(rich["household_tax_class"] == 1 and rich["household_tax_cents"] == 400, "Debt alone cannot make a wealthy earner exempt")
	assert(State.Laws.rules(1808, 12)["household_macinato"])
	assert(not State.Laws.rules(1809, 1)["household_macinato"])
	assert(not State.Laws.rules(1816, 9)["household_macinato"], "Do not silently reinstate the abolished Tuscan assessment")
	assert(not State.Laws.rules(1868, 12)["milling_duty"])
	assert(State.Laws.rules(1869, 1)["milling_duty"])
	assert(not State.Laws.rules(1884, 1)["milling_duty"])
	var grain: Dictionary = State.Laws.assessment(State.Laws.rules(1869, 1), 0, 4, 4.0, 0, 0, 1.0)
	assert(grain["milling_tax_cents"] == 95 and grain["household_tax_cents"] == 0, "Wheat duty uses grain volume and the accounting conversion, not a household class")
	assert(State.Laws.assessment(State.Laws.rules(1884, 1), 0, 4, 4.0, 0, 0, 1.0)["milling_tax_cents"] == 0)
	assert(State.Laws.assessment(State.Laws.rules(1861, 2), 0, 0, 0.0, 184000, 0, 1.0)["property_tax_cents"] == State.Laws.assessment(State.Laws.rules(1861, 3), 0, 0, 0.0, 184000, 0, 1.0)["property_tax_cents"], "No invented proclamation tax increase")
	var holdings = _state()
	var base: int = holdings.tax_property_assessment()
	assert(holdings.village.development.transfer(holdings, "workshop", "landi"))
	assert(holdings.tax_property_assessment() > base)
	assert(holdings.village.development.transfer(holdings, "workshop", "moretti"))
	assert(holdings.tax_property_assessment() == base)
	holdings.household["rooms"].append("Nursery")
	assert(holdings.tax_property_assessment() == base + 20000)
	state = _state()
	assert(not State.Laws.rules(1861, 2)["national"])
	assert(State.Laws.rules(1861, 3)["national"])
	assert(State.Laws.rules(1862, 3)["estate_rate"] == 0.0)
	assert(State.Laws.rules(1862, 4)["estate_rate"] == 0.02)
	assert(State.Laws.rules(1864, 6)["income_rate"] == 0.0)
	assert(State.Laws.rules(1864, 7)["income_rate"] == 0.06)
	assert(not State.Laws.rules(1865, 12)["civil_code"])
	assert(State.Laws.rules(1866, 1)["civil_code"])
	var before: Dictionary = state.economy.budget(state.people, state.household["members"], state.household, 1864, 6)
	var after: Dictionary = state.economy.budget(state.people, state.household["members"], state.household, 1864, 7)
	assert(after["income_tax_cents"] == 300, "Farm earnings are not also taxed as non-agricultural wages")
	assert(before["net_cents"] - after["net_cents"] == 300)
	state.economy.price_multiplier = 0.5
	var discounted: Dictionary = state.economy.budget(state.people, state.household["members"], state.household, 1864, 7)
	assert(discounted["taxes_cents"] == after["taxes_cents"], "Discount bonuses cannot discount taxes")
	state.economy.cash_cents = -1
	var frugal: Dictionary = state.economy.budget(state.people, state.household["members"], state.household, 1864, 7)
	assert(frugal["property_tax_cents"] == after["property_tax_cents"] and frugal["income_tax_cents"] == after["income_tax_cents"])
	assert(frugal["salt_duty_cents"] < after["salt_duty_cents"], "Buying less reduces consumption duties, not direct assessment rates")
	# Completion pays June at its old rate; July's budget sees the new rate.
	state = _state(1864, 6)
	state.advance_month()
	assert(state.economy.ledger[-1]["income_tax_cents"] == 0)
	assert(state.major_event and state.notifications[-1]["description"].contains("Ricchezza mobile"))
	state.advance_month()
	assert(state.economy.ledger[-1]["income_tax_cents"] == 300)
	assert(state.notifications.filter(func(n): return n["description"].contains("Ricchezza mobile")).size() == 1)
	# Positive workshop profits pay tax, and settlement uses the completed month's law.
	var enterprise = _state(1864, 7)
	enterprise.economy.cash_cents = 100000
	assert(enterprise.village.development.transfer(enterprise, "workshop", "landi"))
	assert(enterprise.village.business.propose(enterprise, "Giovanni", "workshop")["ok"])
	var estimate: Dictionary = enterprise.village.business.estimate(enterprise, "workshop")
	assert(estimate["tax_cents"] > 0)
	assert(estimate["net_cents"] == estimate["revenue_cents"] - estimate["cost_cents"] - estimate["tax_cents"])
	assert(enterprise.village.business.estimate(enterprise, "workshop", 99, true)["tax_cents"] == 0, "June production cannot be taxed under July's new law")
	enterprise.month = 8
	var opening: int = enterprise.economy.cash_cents
	var settled: Dictionary = enterprise.village.business.estimate(enterprise, "workshop", 99, true)
	enterprise.village.business.advance_month(enterprise)
	assert(enterprise.economy.cash_cents == opening + settled["net_cents"])
	assert(Save._valid_save({"state": enterprise.to_save_data(), "clock": {"speed_level": 1, "month_progress": 0.0}}), "Taxed business reports must remain valid save data")
	enterprise.people["Giovanni"].life_state["illness"] = {"until_month": 12}
	assert(enterprise.village.business.estimate(enterprise, "workshop")["tax_cents"] == 0, "No tax on idle or loss-making production")
	# Inheritance preview and actual distribution conserve money after the duty.
	state = _state(1866)
	state.economy.cash_cents = 10001
	var projected: Dictionary = state.succession.preview(state)
	assert(projected["inheritance_tax_cents"] == 200)
	assert(projected["shares"] == {"Son": 4901, "Daughter": 4900})
	state.succession.die(state, "Giovanni")
	assert(state.succession.continue_as(state, "Son").is_empty())
	assert(state.economy.cash_cents == 4901 and state.people["Daughter"].life_state["personal_cash_cents"] == 4900)
	assert(state.succession.history[-1]["estate_cents"] == 9801)
	# Personal estates also pay duties, including the cash passed to a new head.
	state.people["Daughter"].life_state["personal_cash_cents"] = 10000
	state.add_person("Grandchild", {"age": 2, "parent_ids": ["Daughter"]})
	state.succession.die(state, "Daughter")
	assert(state.people["Grandchild"].life_state["personal_cash_cents"] == 9800)
	# Current date reconstructs all legal rules when loading; old ledgers remain intact.
	var clock = Clock.new()
	clock.state = state
	assert(Save.save_game(clock, "user://laws_test.save").is_empty())
	var restored = Clock.new()
	assert(Save.load_game(restored, "user://laws_test.save").is_empty())
	assert(restored.state.to_save_data() == state.to_save_data())
	assert(State.Laws.rules(restored.state.year, restored.state.month)["civil_code"])
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://laws_test.save"))
	clock.free()
	restored.free()
	assert(state.economy.earnings(state.people["Son"]) == 5000, "No automatic pension payments")
	state.people["Son"].age = 95
	assert(state.economy.earnings(state.people["Son"]) == 0)
	# Native screen remains accessible and refreshes when the legal calendar changes.
	root.size = Vector2i(1280, 800)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._show_screen("Laws")
	assert(screen.content_overlay.find_child("LawsInfo", true, false) != null)
	assert(screen.get_node("Navigation").find_children("*", "Button", true, false).any(func(b): return b.get_meta("screen", "") == "Laws"))
	screen.game_clock.state.year = 1866
	screen._refresh_time_controls()
	var texts := ""
	for label in screen.content_overlay.find_children("*", "Label", true, false): texts += label.text + "\n"
	assert(texts.contains("Kingdom of Italy") and texts.contains("protected half"))
	screen.free()
	print("PASS: dated laws, tax budgets, reform pauses, estate conservation, personal duties, saves and laws UI")
	quit()
