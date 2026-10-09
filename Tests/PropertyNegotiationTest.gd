extends SceneTree
const State = preload("res://Simulation/GameState.gd")
const SaveGame = preload("res://Simulation/SaveGame.gd")
const Negotiation = preload("res://Simulation/Village/PropertyNegotiation.gd")
func _initialize() -> void:
	call_deferred("_run")
func _state():
	var state = State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	state.events.enabled = false
	state.economy.cash_cents = 100000
	return state
func _valid(state) -> bool:
	return SaveGame._valid_save({"state":state.to_save_data(),"clock":{"speed_level":1,"month_progress":0.0}})
func _run() -> void:
	var state = _state()
	var dev = state.village.development
	var plot: String = dev.buildings["farm"]["parcel_id"]
	var home: String = dev.buildings["rossi_home"]["parcel_id"]
	var original: Dictionary = dev.view_at(0)
	assert(not Negotiation.propose(state,home,100000)["ok"], "Households retain a home they need")
	var value: int = Negotiation.valuation(state,plot)
	var opening: int = state.economy.cash_cents
	var seller_cash: int = state.village.households["rossi"].cash_cents
	assert(Negotiation.propose(state,plot,value/2)["outcome"] == "refused")
	assert(state.economy.cash_cents == opening and dev.parcels[plot]["owner_id"] == "rossi")
	assert(Negotiation.propose(state,plot,value)["outcome"] == "unavailable", "One offer to a household per month")
	state.elapsed_months = 1
	var result: Dictionary = Negotiation.propose(state,plot,value)
	assert(result["outcome"] == "counteroffer")
	assert(_valid(state))
	var restored = State.new()
	restored.restore_save_data(state.to_save_data())
	assert(restored.to_save_data() == state.to_save_data(), "Offers persist across saves")
	var price: int = dev.property_offers[plot]["asking_cents"]
	state.economy.cash_cents = price-1
	assert(not Negotiation.accept_counteroffer(state,plot)["ok"])
	assert(dev.parcels[plot]["owner_id"] == "rossi")
	state.economy.cash_cents = opening
	state.legacy.choose("populous","discount")
	state.economy.price_multiplier = .9
	assert(Negotiation.accept_counteroffer(state,plot)["ok"])
	assert(state.economy.cash_cents == opening-price, "Agreed prices are paid in full")
	assert(state.village.households["rossi"].cash_cents == seller_cash+price, "Money is conserved across the sale")
	assert(dev.parcels[plot]["owner_id"] == "landi" and dev.buildings["farm"]["owner_id"] == "landi")
	assert(not Negotiation.accept_counteroffer(state,plot)["ok"], "A sale cannot be paid twice")
	assert(dev.view_at(0)["parcels"][plot] == original["parcels"][plot], "Historical ownership remains unchanged")
	assert(_valid(state))
	state = _state()
	dev = state.village.development
	plot = dev.buildings["farm"]["parcel_id"]
	value = Negotiation.valuation(state,plot)
	Negotiation.propose(state,plot,value)
	state.elapsed_months = 3
	assert(not Negotiation.accept_counteroffer(state,plot)["ok"], "Counteroffers expire")
	state = _state()
	dev = state.village.development
	plot = dev.buildings["farm"]["parcel_id"]
	value = Negotiation.valuation(state,plot)
	Negotiation.propose(state,plot,value)
	dev.transfer(state,"farm","moretti")
	assert(not Negotiation.accept_counteroffer(state,plot)["ok"], "Changed ownership invalidates a quote")
	var data := {"state":state.to_save_data(),"clock":{"speed_level":1,"month_progress":0.0}}
	data["state"]["village"]["development"].erase("property_offers")
	assert(SaveGame._valid_save(data), "Previous village saves migrate with no offers")
	data["state"]["village"]["development"]["property_offers"] = {plot:{"owner_id":"missing","month":0,"amount_cents":100,"asking_cents":100,"stage":"counteroffer","response":""}}
	assert(not SaveGame._valid_save(data))
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	screen.game_clock.state.economy.cash_cents = 100000
	screen._show_screen("Village")
	var ui_state = screen.game_clock.state
	var ui_plot: String = ui_state.village.development.buildings["farm"]["parcel_id"]
	screen.village_view.map.parcel_selected.emit(ui_plot)
	for button in screen.village_view.inspector.find_children("*","Button",true,false):
		if button.text == "Make an offer":
			button.pressed.emit()
			break
	assert(ui_state.village.development.property_offers[ui_plot]["stage"] == "counteroffer", "Inspector submits the selected property's offer")
	for button in screen.village_view.inspector.find_children("*","Button",true,false):
		if button.text.begins_with("Accept ·"):
			button.pressed.emit()
			break
	assert(ui_state.village.development.parcels[ui_plot]["owner_id"] == "landi", "Inspector acceptance executes the sale")
	assert(_valid(ui_state))
	screen.free()
	print("PASS: autonomous refusal, counteroffers, cooldown, affordability, ownership and money conservation, expiry, duplicate payment prevention, replay, saved offers and migration")
	quit()
