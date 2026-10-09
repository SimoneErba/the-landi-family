extends VBoxContainer
## Inspection and replay UI. Historical views never mutate simulation state.
const Negotiation = preload("res://Simulation/Village/PropertyNegotiation.gd")
const Map = preload("res://Scripts/VillageMap.gd")
var host
var map
var inspector: VBoxContainer
var timeline: HSlider
var date_label: Label
var selected_kind := ""
var selected_id := ""
var message := ""
var neighbors: VBoxContainer

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	add_child(toolbar)
	var overlays := OptionButton.new()
	for label in ["Places", "Ownership", "Wealth", "Influence", "Development"]:
		overlays.add_item(label)
	toolbar.add_child(overlays)
	var reset := Button.new()
	reset.text = "Reset view"
	toolbar.add_child(reset)
	date_label = host._add_label(toolbar, "", 17, host.TEXT_MAIN)
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var live := Button.new()
	live.text = "Present day"
	toolbar.add_child(live)
	timeline = HSlider.new()
	timeline.min_value = host.game_clock.state.village.development.origin_month
	timeline.max_value = maxi(int(timeline.min_value) + 1, host.game_clock.state.elapsed_months)
	timeline.step = 1
	timeline.value = timeline.max_value
	timeline.custom_minimum_size.y = 24
	add_child(timeline)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	add_child(row)
	map = Map.new()
	map.development = host.game_clock.state.village.development
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(map)
	var frame := PanelContainer.new()
	frame.custom_minimum_size.x = 360
	frame.add_theme_stylebox_override("panel", host.Archive.card())
	row.add_child(frame)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	frame.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	inspector = VBoxContainer.new()
	inspector.custom_minimum_size.x = 328
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector.add_theme_constant_override("separation", 10)
	scroll.add_child(inspector)
	host._add_label(self, "Wheel to zoom · drag with the middle or right mouse button · click a building or open land to inspect it.", 15, host.TEXT_MUTED)
	map.building_selected.connect(func(id):
		selected_kind = "building"
		selected_id = id
		message = ""
		_inspect())
	map.parcel_selected.connect(func(id):
		selected_kind = "parcel"
		selected_id = id
		map.selected_id = id
		map.queue_redraw()
		message = ""
		_inspect())
	overlays.item_selected.connect(func(index):
		map.overlay_mode = overlays.get_item_text(index)
		map.queue_redraw()
		_inspect())
	reset.pressed.connect(map.reset_view)
	live.pressed.connect(func():
		timeline.set_value_no_signal(timeline.max_value)
		map.set_replay(-1)
		refresh())
	timeline.value_changed.connect(func(value):
		map.set_replay(-1 if int(value) >= host.game_clock.state.elapsed_months else int(value))
		_update_date()
		_inspect())
	refresh()

func refresh() -> void:
	if map == null:
		return
	var elapsed: int = host.game_clock.state.elapsed_months
	var was_live: bool = map.replay_month < 0
	timeline.max_value = maxi(int(timeline.min_value)+1, elapsed)
	if was_live:
		timeline.set_value_no_signal(timeline.max_value)
	map.influence = {"landi": 1.0, "village": .5}
	for family in host.game_clock.state.village.households.values():
		map.influence[family.id] = clampf(family.relationships["landi"]["trust"] - family.relationships["landi"]["resentment"], 0.0, 1.0)
	map.refresh()
	map.queue_redraw()
	_update_date()
	_inspect()

func _update_date() -> void:
	var state = host.game_clock.state
	if map.replay_month < 0:
		date_label.text = state.date_text() + " · Present day"
	else:
		var offset: int = map.replay_month - map.development.origin_month
		date_label.text = "%d · Historical view" % (map.development.start_year + offset / 12)

func _owner_name(id: String) -> String:
	if id == "landi":
		return "Landi family"
	if id == "village":
		return "Village commons"
	return host.game_clock.state.village.households[id].name

func _button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 36
	inspector.add_child(button)
	button.pressed.connect(action)

func _result(result: String) -> void:
	host.game_clock.pause()
	message = result
	map.refresh(true)
	host._refresh_time_controls()

func _inspect() -> void:
	for child in inspector.get_children():
		inspector.remove_child(child)
		child.queue_free()
	var state = host.game_clock.state
	var dev = state.village.development
	var historical: bool = map.replay_month >= 0
	if selected_id.is_empty():
		host._add_label(inspector, "Village memory", 25, host.TEXT_MAIN)
		host._add_label(inspector, "Select a building to see its owner, use and history. Select open land to inspect a parcel.", 17, host.TEXT_MUTED)
		host._add_label(inspector, "%d parcels · %d standing buildings" % [map.view["parcels"].size(), _standing_count()], 17, host.TEXT_MAIN)
		if not historical:
			host._add_label(inspector, "%d projects in progress" % dev.projects.size(), 17, host.TEXT_MAIN)
			host._add_label(inspector, "Public investment fund · " + state.economy.money(dev.public_fund_cents), 16, host.TEXT_MUTED)
			host._add_label(inspector, "Wealth shades land value. Influence shades the household's relationship with the Landi family. These two overlays describe the present day.", 15, host.TEXT_MUTED)
		return
	if not message.is_empty():
		host._add_label(inspector, message, 17, host.TEXT_KNOWN)
	if historical:
		host._add_label(inspector, "History is read-only. Return to the present to act.", 15, host.TEXT_SUSPECTED)
	var parcel: Dictionary
	if selected_kind == "building":
		if not map.view["buildings"].has(selected_id):
			host._add_label(inspector, "This building had not yet been constructed.", 18, host.TEXT_MUTED)
			return
		var building: Dictionary = map.view["buildings"][selected_id]
		parcel = map.view["parcels"][building["parcel_id"]]
		host._add_label(inspector, Map.LANDMARKS.get(selected_id, building["address"]), 24, host.TEXT_MAIN)
		host._add_label(inspector, building["address"], 16, host.TEXT_MUTED)
		host._add_label(inspector, "%s · Built %d\nOwner · %s\nCondition · %d%% · Level %d\n%s" % [building["type"].replace("_", " ").capitalize(), building["built_year"], _owner_name(building["owner_id"]), building["condition"], building["level"], building["status"].capitalize()], 17, host.TEXT_MAIN)
		if not historical:
			if building["type"] in state.village.business.CATALOG and building["owner_id"] != "village":
				var estimate: Dictionary = state.village.business.estimate(state, selected_id)
				host._add_label(inspector, "Business · " + estimate["status"], 20, host.TEXT_SUSPECTED)
				host._add_label(inspector, "Monthly estimate\nSales · %s\nCosts · %s\nNet · %s" % [state.economy.money(estimate["revenue_cents"]), state.economy.money(estimate["cost_cents"]), state.economy.money(estimate["net_cents"])], 16, host.TEXT_MAIN)
				if building["owner_id"] == "landi":
					_button("Manage through a person profile", func():
						if state.village.business.assignments.has(selected_id):
							host.gameplay_person_id = state.village.business.assignments[selected_id]["person_id"]
						host._open_person_activity())
			if state.village.households.has(building["owner_id"]):
				var owner = state.village.households[building["owner_id"]]
				host._add_label(inspector, "Household · %d residents (aggregate)\nAmbition · %s" % [dev.household_sizes[owner.id], owner.ambitions[0]], 16, host.TEXT_MUTED)
			elif building["owner_id"] == "landi":
				host._add_label(inspector, "Family at home · %d members" % state.household["members"].size(), 16, host.TEXT_MUTED)
			if selected_id in ["home", "school", "tavern"]:
				_button("Plan an activity here", func():
					host.gameplay_activity_id = {"home":"repair","school":"study","tavern":"visit"}[selected_id]
					host._open_person_activity({"home":"repair","school":"study","tavern":"visit"}[selected_id]))
			if building["owner_id"] == "landi" and building["status"] != "demolished":
				_button("Renovate · " + state.economy.money(state.economy.purchase_cost(dev.COST)), func(): _result(dev.renovate(state, selected_id)))
			for project in dev.projects.values():
				if project["building_id"] == selected_id:
					host._add_label(inspector, "%s · %d months remaining" % [project["kind"].capitalize(), project["remaining"]], 17, host.TEXT_SUSPECTED)
					_cancellation(project)
		if not historical and state.village.households.has(parcel["owner_id"]):
			_negotiation(parcel["id"])
		host._add_label(inspector, "Building history", 21, host.TEXT_SUSPECTED)
		for event in building["history"]:
			host._add_label(inspector, "%d — %s" % [event["year"], event["description"]], 15, host.TEXT_MUTED)
	else:
		parcel = map.view["parcels"][selected_id]
		host._add_label(inspector, selected_id.replace("_", " ").capitalize(), 24, host.TEXT_MAIN)
		host._add_label(inspector, "Owner · %s\nLand value · %s\nFertility · %d%%\nPermitted uses · %s" % [_owner_name(parcel["owner_id"]), state.economy.money(parcel["value_cents"]), parcel["fertility"]*100, ", ".join(parcel["uses"])], 17, host.TEXT_MAIN)
		if not historical:
			if parcel["for_sale"]:
				_button("Buy land · " + state.economy.money(state.economy.purchase_cost(parcel["value_cents"])), func(): _result(dev.buy_parcel(state, selected_id)))
			if parcel["owner_id"] == "landi" and parcel["building_id"].is_empty():
				for type in parcel["uses"]:
					_button("Build " + type + " · " + state.economy.money(state.economy.purchase_cost(dev.COST)), func(): _result(dev.begin_construction(state, selected_id, type, "landi")))
			for project in dev.projects.values():
				if project["parcel_id"] == selected_id:
					host._add_label(inspector, "Construction · %d months remaining" % project["remaining"], 16, host.TEXT_SUSPECTED)
					_cancellation(project)

	if not historical and selected_kind == "parcel" and state.village.households.has(parcel["owner_id"]):
		_negotiation(parcel["id"])

func _cancellation(project: Dictionary) -> void:
	if project["owner_id"] != "landi":
		return
	var state = host.game_clock.state
	var id: String = project["id"]
	host._add_label(inspector, "Cancellation returns 80% of unused work payments. Earlier saves without recorded payments have no refund.", 15, host.TEXT_MUTED)
	_button("Cancel work · refund " + state.economy.money(state.village.development.cancellation_refund(id)), func(): _result(state.village.development.cancel_project(state, id)))

func _negotiation(parcel_id: String) -> void:
	var state = host.game_clock.state
	var dev = state.village.development
	host._add_label(inspector,"Property negotiation",20,host.TEXT_SUSPECTED)
	var unavailable: String = Negotiation.unavailable(state,parcel_id)
	if not unavailable.is_empty():
		if message != unavailable:
			host._add_label(inspector,unavailable,16,host.TEXT_MUTED)
		return
	var offer: Dictionary = dev.property_offers.get(parcel_id,{})
	if not offer.is_empty():
		if offer["stage"] == "counteroffer" and state.elapsed_months - offer["month"] > 2:
			host._add_label(inspector,"The previous counteroffer has expired.",16,host.TEXT_MUTED)
		elif message != offer["response"]:
			host._add_label(inspector,offer["response"],16,host.TEXT_KNOWN)
		if offer["stage"] == "counteroffer" and state.elapsed_months - offer["month"] <= 2 and offer["owner_id"] == dev.parcels[parcel_id]["owner_id"]:
			_button("Accept · " + state.economy.money(offer["asking_cents"]),func(): _result(Negotiation.accept_counteroffer(state,parcel_id)["response"]))
	for recent in dev.property_offers.values():
		if recent["owner_id"] == dev.parcels[parcel_id]["owner_id"] and recent["month"] == state.elapsed_months:
			host._add_label(inspector,"You can make another offer to this household next month.",15,host.TEXT_MUTED)
			return
	var value: int = Negotiation.valuation(state,parcel_id)
	var choices := OptionButton.new()
	var amounts: Array[int] = [roundi(value*.75),value,roundi(value*1.3)]
	for amount in amounts:
		choices.add_item("Offer " + state.economy.money(amount))
	choices.select(1)
	inspector.add_child(choices)
	_button("Make an offer",func(): _result(Negotiation.propose(state,parcel_id,amounts[choices.selected])["response"]))

func _standing_count() -> int:
	var count := 0
	for building in map.view["buildings"].values():
		if building["status"] != "demolished":
			count += 1
	return count
