extends SceneTree
const State = preload("res://Simulation/GameState.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")

func _initialize() -> void:
	call_deferred("_run")

func _state():
	var state = State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.events.enabled = false
	state.economy.cash_cents = 100000
	state.legacy.choose("populous", "discount")
	state.economy.price_multiplier = .9
	return state

func _valid(state) -> bool:
	return SaveGame._valid_save({"state":state.to_save_data(), "clock":{"speed_level":1,"month_progress":0.0}})

func _run() -> void:
	var state = _state()
	var dev = state.village.development
	var business = state.village.business
	assert(dev.transfer(state, "workshop", "landi"))
	var opening: int = state.economy.cash_cents
	business.advance_month(state)
	assert(state.economy.cash_cents == opening - state.economy.purchase_cost(100), "Idle property still incurs upkeep")
	assert(business.propose(state, "Giovanni", "workshop")["ok"])
	assert(not state.activities.reason(state, "Giovanni", "repair").is_empty())
	assert(not state.careers.request_reason(state, state.people["Giovanni"], "train:secondary").is_empty())
	state.elapsed_months += 1
	var expected: Dictionary = business.estimate(state, "workshop")
	opening = state.economy.cash_cents
	var skill: float = state.people["Giovanni"].skills["craft"]
	business.advance_month(state)
	assert(state.economy.cash_cents == opening + expected["net_cents"])
	assert(state.people["Giovanni"].skills["craft"] > skill)
	assert(business.reports.back()["rows"].any(func(row): return row["building_id"] == "workshop" and row["status"] == "Operating"))
	opening = state.economy.cash_cents
	business.advance_month(state)
	assert(state.economy.cash_cents == opening, "Monthly production cannot pay twice")
	state.people["Giovanni"].life_state["illness"] = {"until_month":10, "previous_health":"Well"}
	assert(business.estimate(state,"workshop")["revenue_cents"] == 0)
	state.people["Giovanni"].life_state["illness"] = {}
	state.economy.cash_cents = 0
	state.elapsed_months += 1
	business.advance_month(state)
	assert(state.economy.cash_cents == 0, "Materials must be affordable before production")
	assert(_valid(state))
	var restored = State.new()
	restored.restore_save_data(state.to_save_data())
	state.economy.cash_cents = 100000
	restored.economy.cash_cents = 100000
	state.advance_month()
	restored.advance_month()
	assert(state.to_save_data() == restored.to_save_data(), "Business continuation is deterministic")
	assert(dev.transfer(state,"workshop","moretti"))
	state.elapsed_months += 1
	opening = state.economy.cash_cents
	business.advance_month(state)
	assert(business.commitment("Giovanni").is_empty() and state.economy.cash_cents == opening, "Sold businesses stop paying the former owner")
	assert(dev.transfer(state,"workshop","landi"))
	var person = state.people["Carlo"]
	person.interests["practical"] = 0.0
	person.values["family_loyalty"] = 0.0
	person.current_state["resentment"] = 1.0
	assert(not business.propose(state,"Carlo","workshop")["ok"], "Relatives can refuse")
	state.elapsed_months += 1
	person.interests["practical"] = 100.0
	person.values["family_loyalty"] = 1.0
	person.current_state["resentment"] = 0.0
	person.current_state["stress"] = 0.0
	assert(business.propose(state,"Carlo","workshop")["ok"])
	assert(not state.travel.reason(state,"Carlo","milan","work").is_empty())
	person.current_state["resentment"] = .9
	state.elapsed_months += 1
	business.advance_month(state)
	assert(business.commitment("Carlo").is_empty() and not state.notifications.is_empty(), "Unhappy relatives resign")
	state.economy.cash_cents = 100000
	opening = state.economy.cash_cents
	dev.renovate(state,"home")
	var paid: int = opening-state.economy.cash_cents
	assert(paid == 10800)
	dev.projects["home"]["remaining"] = 3
	var refund: int = dev.cancellation_refund("home")
	assert(refund == 4320, "Refund uses actual discounted payment and unfinished work")
	opening = state.economy.cash_cents
	dev.cancel_project(state,"home")
	assert(state.economy.cash_cents == opening+refund and not dev.projects.has("home"))
	dev.cancel_project(state,"home")
	assert(state.economy.cash_cents == opening+refund, "Cancellation cannot pay twice")
	assert(_valid(state))
	dev.renovate(state,"home")
	var legacy := {"state":state.to_save_data(), "clock":{"speed_level":1,"month_progress":0.0}}
	legacy["state"]["village"].erase("business")
	legacy["state"]["village"]["development"]["projects"]["home"].erase("paid_cents")
	legacy["state"]["village"]["development"]["projects"]["home"].erase("duration_months")
	assert(SaveGame._valid_save(legacy))
	assert(legacy["state"]["village"]["development"]["projects"]["home"]["paid_cents"] == 0, "Migration never invents refundable payments")
	var invalid := {"state":state.to_save_data(), "clock":{"speed_level":1,"month_progress":0.0}}
	invalid["state"]["village"]["business"]["reports"].back()["rows"][0]["net_cents"] += 1
	assert(not SaveGame._valid_save(invalid))
	var construction = _state()
	construction.economy.cash_cents = 1000000
	var plots = construction.village.development
	var parcel_id: String = plots.best_parcel("house", "landi")
	plots.buy_parcel(construction, parcel_id)
	plots.begin_construction(construction, parcel_id, "house", "landi")
	var project_id: String = plots.projects.keys()[0]
	plots.projects[project_id]["remaining"] = 6
	assert(plots.cancellation_refund(project_id) == 4320)
	plots.cancel_project(construction, project_id)
	assert(plots.parcels[parcel_id]["owner_id"] == "landi" and plots.parcels[parcel_id]["building_id"].is_empty())
	assert(not plots.buildings.has(project_id) and _valid(construction), "Cancelled construction preserves owned land and valid replay")
	plots.begin_construction(construction, parcel_id, "house", "landi", true)
	assert(plots.cancellation_refund(plots.projects.keys()[0]) == 0, "Unrecorded prepaid work cannot create a free refund")
	var neighbors = _state()
	neighbors.village.development.household_sizes["rossi"] = 1
	neighbors.village.business.advance_month(neighbors)
	var operating := 0
	for row in neighbors.village.business.reports.back()["rows"]:
		if row["owner_id"] == "rossi" and row["status"] == "Operating":
			operating += 1
	assert(operating == 1, "Multiple businesses share finite household labor")
	neighbors.month = 1
	var winter: int = neighbors.village.business.estimate(neighbors,"farm")["revenue_cents"]
	neighbors.month = 7
	assert(neighbors.village.business.estimate(neighbors,"farm")["revenue_cents"] > winter, "Harvest season affects farm sales")
	print("PASS: productive property costs and sales, manager consent and pressure, commitments, ownership, funding, deterministic saves, refunds and migration")
	quit()
