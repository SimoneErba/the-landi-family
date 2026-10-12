extends SceneTree

const State = preload("res://Simulation/GameState.gd")
const Clock = preload("res://Simulation/GameClock.gd")
const Save = preload("res://Simulation/SaveGame.gd")
const PATH := "user://loans_succession_test.save"

func _initialize() -> void:
	call_deferred("_run")

func _state():
	var state = State.new()
	state.initialize({"Giovanni": {"age": 60, "monthly_income_cents": 8000}, "Son": {"age": 30, "parent_ids": ["Giovanni"]}, "Daughter": {"age": 28, "parent_ids": ["Giovanni"], "portrait": {"appearance": {"presentation": "feminine"}}}})
	state.events.enabled = false
	state.succession.enabled = false
	state.economy.cash_cents = 1000000
	return state

func _run() -> void:
	var state = _state()
	assert(not state.loans.borrow(state, 0).is_empty())
	assert(state.loans.borrow(state, 10000).is_empty())
	assert(state.economy.cash_cents == 1010000 and state.loans.principal_cents() == 10000)
	assert(not state.loans.borrow(state, state.loans.CREDIT_LIMIT_CENTS).is_empty())
	for month in 11: state.advance_month()
	assert(state.loans.accrued_cents() == 459 and state.loans.loans["loan_1"]["next_interest_month"] == 12)
	var opening: int = state.economy.cash_cents
	var budget: Dictionary = state.economy.budget(state.people, state.household["members"], state.household)
	state.advance_month()
	assert(state.economy.cash_cents == opening + budget["net_cents"] - 500)
	assert(state.loans.principal_cents() == 10000 and state.loans.accrued_cents() == 0)
	assert(state.loans.loans["loan_1"]["next_interest_month"] == 24, "Annual billing is anchored to the loan, not calendar January")
	var early = _state()
	assert(early.loans.borrow(early, 10000).is_empty())
	for month in 6: early.advance_month()
	assert(early.loans.repayment_cost("loan_1", 5000) == 5125)
	assert(early.loans.repay(early, "loan_1", 5000).is_empty())
	assert(early.loans.principal_cents() == 5000 and early.loans.accrued_cents() == 125)
	for month in 6: early.advance_month()
	assert(early.loans.principal_cents() == 5000 and early.loans.accrued_cents() == 0)
	assert(early.loans.repay(early, "loan_1", 5000).is_empty())
	assert(early.loans.loans.is_empty())
	var inheritance = _state()
	inheritance.economy.cash_cents = 10001
	assert(not inheritance.succession.disinherit(inheritance, "Daughter").is_empty())
	assert(inheritance.succession.nominate(inheritance, "Daughter").is_empty())
	assert(inheritance.succession.preview(inheritance)["shares"] == {"Son": 5001, "Daughter": 5000})
	var old_knowledge: Dictionary = inheritance.people["Son"].knowledge.duplicate(true)
	assert(inheritance.succession.die(inheritance, "Giovanni"))
	assert(not inheritance.succession.die(inheritance, "Giovanni"), "A death cannot settle twice")
	assert(inheritance.succession.pending and not inheritance.people["Giovanni"].in_household)
	var month: int = inheritance.elapsed_months
	inheritance.advance_month()
	assert(inheritance.elapsed_months == month, "A successor is required before time resumes")
	assert(inheritance.succession.default_successor(inheritance) == "Daughter")
	assert(inheritance.succession.continue_as(inheritance, "Daughter").is_empty())
	assert(inheritance.head_id == "Daughter" and inheritance.economy.cash_cents == 5000)
	assert(inheritance.people["Son"].life_state["personal_cash_cents"] == 5001)
	assert(inheritance.people["Son"].knowledge == old_knowledge, "The new head does not inherit the old observer's knowledge")
	assert(inheritance.people["Daughter"].view_for("Daughter")["relationship"] == "You · Family head")
	assert(not inheritance.succession.continue_as(inheritance, "Son").is_empty())
	# A deceased child's branch is represented, without counting grandchildren as extra siblings.
	var branches = _state()
	branches.add_person("Granddaughter", {"age": 8, "parent_ids": ["Son"]})
	branches.add_person("Grandson", {"age": 6, "parent_ids": ["Son"]})
	branches.people["Son"].alive = false
	branches.people["Son"].in_household = false
	branches.household["members"].erase("Son")
	assert(branches.succession.descendant_shares(branches, "Giovanni", 10000) == {"Granddaughter": 2500, "Grandson": 2500, "Daughter": 5000})
	var indebted = _state()
	indebted.economy.cash_cents = 0
	assert(indebted.loans.borrow(indebted, 10000).is_empty())
	indebted.economy.cash_cents = 6000
	indebted.succession.die(indebted, "Giovanni")
	assert(indebted.succession.continue_as(indebted, "Son").is_empty())
	assert(indebted.loans.principal_cents() == 4000 and indebted.economy.cash_cents == 0, "Debts are paid before heirs; a shortfall survives the head's death")
	var clock = Clock.new()
	clock.state = _state()
	clock.state.loans.borrow(clock.state, 10000)
	for index in 4: clock.state.advance_month()
	clock.state.succession.die(clock.state, "Giovanni")
	assert(Save.save_game(clock, PATH).is_empty())
	var restored = Clock.new()
	assert(Save.load_game(restored, PATH).is_empty())
	assert(restored.state.to_save_data() == clock.state.to_save_data())
	restored.play()
	assert(not restored.is_playing, "Pending succession stays paused after load")
	for saved_clock in [clock, restored]:
		assert(saved_clock.state.succession.continue_as(saved_clock.state, "Daughter").is_empty())
		saved_clock.state.advance_month()
	assert(restored.state.to_save_data() == clock.state.to_save_data())
	var previous_save: Dictionary = restored.state.to_save_data()
	previous_save.erase("succession")
	previous_save.erase("loans")
	assert(Save._valid_save({"state": previous_save, "clock": {"speed_level": 3, "month_progress": 0.0}}), "Earlier saves migrate")
	var malformed: Dictionary = clock.state.to_save_data()
	malformed["succession"]["pending"] = true
	assert(not Save._valid_save({"state": malformed, "clock": {"speed_level": 3, "month_progress": 0.0}}))
	clock.free()
	restored.free()
	DirAccess.remove_absolute(PATH)
	# Natural age-related death is playable and interrupts catch-up even without random events.
	var natural = Clock.new()
	natural.state = _state()
	natural.state.people["Giovanni"].birth_year = 1705
	natural.state.succession.enabled = true
	natural.play()
	natural.advance_time(natural.seconds_per_month() * 12)
	assert(natural.state.elapsed_months == 1 and natural.state.succession.pending and not natural.is_playing)
	natural.free()
	# Actual UI: loan controls, will planning, mandatory death choice and new head.
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("wealth", "learning")
	screen._show_screen("Finances")
	assert(screen.finance_content.find_child("LoanAmount", true, false) != null)
	screen._show_screen("Succession")
	screen.game_clock.state.succession.die(screen.game_clock.state, "Giovanni")
	screen._refresh_time_controls()
	assert(screen.succession_overlay.visible)
	screen._continue_after_succession("Anna")
	assert(screen.game_clock.state.head_id == "Anna" and not screen.succession_overlay.visible)
	screen.free()
	await process_frame
	print("PASS: annual interest, early/partial repayment, credit limit, daughters and protected shares, branch representation, estate debts, natural death, paused succession, new observer, save migration and UI")
	quit()
