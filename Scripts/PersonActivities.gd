extends RefCounted
## Activities belong to the selected person's profile, never a separate page.
static func build(host, parent: VBoxContainer, person_id: String) -> void:
	var state = host.game_clock.state
	var model = state.people[person_id]
	_business(host, parent, person_id)
	var active = state.activities.commitment(person_id)
	if active != null:
		var underway := Button.new()
		underway.text = "Activity underway"
		underway.disabled = true
		parent.add_child(underway)
		host.Reaction.build(host, parent, person_id, "activity")
		host._add_label(parent, state.activities.CATALOG[active.activity_id]["name"], 22, host.TEXT_MAIN)
		host._add_label(parent, "%s · %.1f / %d months · %s per active month" % [active.status.capitalize(), active.progress_months, active.duration_months, state.economy.money(state.economy.purchase_cost(active.monthly_cost_cents))], 16, host.TEXT_MAIN)
		if not active.interruption_reason.is_empty():
			host._add_label(parent, active.interruption_reason, 16, host.TEXT_SUSPECTED)
		var cancel := Button.new()
		cancel.text = "Cancel activity"
		parent.add_child(cancel)
		cancel.pressed.connect(func():
			state.activities.cancel(state, active.id)
			host.gameplay_result = "Activity cancelled. Earlier costs are not refunded."
			host._refresh_time_controls())
	else:
		host._add_label(parent, "No family activity in progress.", 16, host.TEXT_MUTED)
	if not model.education["study"].is_empty():
		host._add_label(parent, "Their current course takes priority over a new activity.", 16, host.TEXT_SUSPECTED)
	var journey: Dictionary = state.travel.current(person_id)
	if not journey.is_empty():
		host._add_label(parent, state.travel.location_text(person_id), 16, host.TEXT_MAIN)
	if model.alive and model.in_household and model.age >= 18 and active == null:
		host._add_label(parent, "Plan an activity", 22, host.TEXT_MAIN)
		var choice := OptionButton.new()
		choice.name = "ActivityChoice"
		choice.custom_minimum_size.y = 28
		var ids: Array = state.activities.CATALOG.keys()
		for id in ids:
			choice.add_item(state.activities.CATALOG[id]["name"])
		choice.select(maxi(0, ids.find(host.gameplay_activity_id)))
		parent.add_child(choice)
		var neighbors := OptionButton.new()
		neighbors.name = "ActivityNeighbor"
		neighbors.custom_minimum_size.y = 28
		var family_ids: Array = state.village.households.keys()
		for id in family_ids:
			neighbors.add_item(state.village.households[id].name)
		neighbors.select(maxi(0, family_ids.find(host.gameplay_target_id)))
		parent.add_child(neighbors)
		var explanation: Label = host._add_label(parent, "", 16, host.TEXT_MUTED)
		var request := Button.new()
		request.name = "ActivityRequest"
		request.custom_minimum_size.y = 28
		request.text = "Begin activity" if person_id == state.head_id else "Ask to take part"
		parent.add_child(request)
		host.Reaction.build(host, parent, person_id, "activity")
		var refresh := func(_index = 0):
			var id: String = ids[choice.selected]
			host.gameplay_activity_id = id
			host.gameplay_target_id = family_ids[neighbors.selected]
			neighbors.visible = id == "visit"
			var entry: Dictionary = state.activities.CATALOG[id]
			var reason: String = state.activities.reason(state, person_id, id, host.gameplay_target_id)
			explanation.text = "%s\n%d months · %s per active month.%s" % [entry["description"], entry["months"], state.economy.money(state.economy.purchase_cost(entry["cost"])), "\n" + reason if not reason.is_empty() else ""]
			request.disabled = not reason.is_empty()
		refresh.call()
		choice.item_selected.connect(refresh)
		neighbors.item_selected.connect(refresh)
		request.pressed.connect(func():
			var result: Dictionary = state.activities.propose(state, person_id, ids[choice.selected], family_ids[neighbors.selected])
			host.Reaction.remember(host, result, person_id, "activity")
			host._refresh_time_controls())
	var recent: Array = []
	for plan in state.activities.plans.values():
		if person_id in plan.accepted_participant_ids and plan.status not in ["active", "interrupted"]:
			recent.append(plan)
	if not recent.is_empty():
		host._add_label(parent, "Recent outcomes", 20, host.TEXT_SUSPECTED)
		for index in range(maxi(0,recent.size()-3), recent.size()):
			var plan = recent[index]
			host._add_label(parent, state.activities.CATALOG[plan.activity_id]["name"] + " · " + plan.status.capitalize(), 16, host.TEXT_MAIN)
			if not plan.outcome.is_empty():
				host._add_label(parent, plan.outcome["description"], 15, host.TEXT_MUTED)

static func _business(host, parent: VBoxContainer, person_id: String) -> void:
	var state = host.game_clock.state
	var business = state.village.business
	var assigned: String = business.commitment(person_id)
	if not assigned.is_empty():
		host.Reaction.build(host, parent, person_id, "business")
		host._add_label(parent, "Managing " + state.village.development.buildings[assigned]["address"], 22, host.TEXT_MAIN)
		host._add_label(parent, "A continuing responsibility: earns business income, builds skill and adds pressure alongside their regular job. Courses, activities and travel need a replacement manager.", 16, host.TEXT_MUTED)
		var release := Button.new()
		release.text = "Release management responsibility"
		parent.add_child(release)
		release.pressed.connect(func():
			business.release(state, assigned)
			host._refresh_time_controls())
		return
	var ids: Array[String] = []
	for building in state.village.development.buildings.values():
		if building["owner_id"] == "landi" and building["type"] in business.CATALOG and building["status"] == "standing" and not business.assignments.has(building["id"]):
			ids.append(building["id"])
	if ids.is_empty():
		return
	host._add_label(parent, "Manage a family business", 22, host.TEXT_MAIN)
	var choice := OptionButton.new()
	for id in ids:
		var building: Dictionary = state.village.development.buildings[id]
		choice.add_item(building["type"].capitalize() + " · " + building["address"])
	parent.add_child(choice)
	var explanation: Label = host._add_label(parent, "", 16, host.TEXT_MUTED)
	var request := Button.new()
	request.text = "Begin managing" if person_id == state.head_id else "Ask to manage"
	parent.add_child(request)
	host.Reaction.build(host, parent, person_id, "business")
	var refresh := func(_index = 0):
		var reason: String = business.reason(state, person_id, ids[choice.selected])
		explanation.text = reason if not reason.is_empty() else "A long-term responsibility; relatives may refuse or later resign under pressure."
		request.disabled = not reason.is_empty()
	refresh.call()
	choice.item_selected.connect(refresh)
	request.pressed.connect(func():
		var result: Dictionary = business.propose(state, person_id, ids[choice.selected])
		host.Reaction.remember(host, result, person_id, "business")
		host._refresh_time_controls())
