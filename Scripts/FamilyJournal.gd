extends PanelContainer
## A view of existing simulation state; all mutations go through ActivitySystem.
var host
var tab := 0
var person_filter := ""
var body: VBoxContainer
var scroll: ScrollContainer
var feedback := ""
var history_category := "All history"
var category_choice: OptionButton
var last_snapshot := ""
var person_choice: OptionButton

func _ready() -> void:
	name = "FamilyJournal"
	add_theme_stylebox_override("panel", host.Archive.window_frame())
	var column := VBoxContainer.new()
	add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	host._add_label(heading, "Family Journal", 22, host.TEXT_MAIN).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(heading, "Back", func(): host._show_screen("People"))
	var tabs := HBoxContainer.new()
	column.add_child(tabs)
	for index in 3:
		var button := _button(tabs, ["Activities", "Queue", "History"][index], func(): tab = index; refresh())
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var filter := OptionButton.new()
	person_choice = filter
	filter.add_item("Everyone")
	filter.set_item_metadata(0, "")
	for id in host.game_clock.state.people:
		filter.add_item(host.game_clock.state.people[id].name)
		filter.set_item_metadata(filter.item_count - 1, id)
	filter.item_selected.connect(func(index): person_filter = filter.get_item_metadata(index); refresh())
	column.add_child(filter)
	var categories := OptionButton.new()
	category_choice = categories
	for category in ["All history", "Projects", "Family events"]: categories.add_item(category)
	categories.item_selected.connect(func(index): history_category = categories.get_item_text(index); refresh())
	column.add_child(categories)
	categories.name = "HistoryCategory"
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)
	refresh()

func _button(parent, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.add_theme_font_size_override("font_size", 14)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func refresh() -> void:
	if body == null: return
	var state = host.game_clock.state
	# Playback buttons can refresh the host repeatedly within one month.
	# Rebuild rows only when observable state or the selected view has changed.
	var snapshot: Array = [tab, person_filter, history_category, feedback, state.elapsed_months, state.head_id, state.economy.cash_cents, state.economy.price_index, state.household["members"], state.last_requests, state.chronicle.size(), state.village.development.projects, state.social.plans]
	for person in state.people.values():
		snapshot.append([person.id, person.age, person.alive, person.job, person.monthly_income_cents, person.education["study"], person.decision_state.get("observation", ""), person.life_state.get("illness", {}), state.travel.current(person.id), state.village.business.commitment(person.id)])
	for plan in state.activities.plans.values():
		if plan.status in ["queued", "paused", "active", "interrupted"]: snapshot.append(plan.to_save_data())
	var signature := JSON.stringify(snapshot)
	if signature == last_snapshot: return
	last_snapshot = signature
	# Children born or relatives added after opening the panel must be filterable.
	if person_choice.item_count != state.people.size() + 1:
		person_choice.clear()
		person_choice.add_item("Everyone")
		person_choice.set_item_metadata(0, "")
		for id in state.people:
			person_choice.add_item(state.people[id].name)
			var index := person_choice.item_count - 1
			person_choice.set_item_metadata(index, id)
			if id == person_filter: person_choice.select(index)
	var old_scroll := scroll.scroll_vertical
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	category_choice.visible = tab == 2
	if not feedback.is_empty(): host._add_label(body, feedback, 15, host.TEXT_KNOWN)
	if tab == 0 and person_filter.is_empty():
		for project in state.village.development.projects.values():
			if project["owner_id"] != "landi": continue
			var card = host.GameplayScreens._card(host, body)
			host._add_label(card, "Property · " + project["kind"].capitalize() + " · " + project["type"].capitalize(), 18, host.TEXT_MAIN)
			_progress(card, project["duration_months"] - project["remaining"], project["duration_months"])
			_button(card, "Manage property", host._show_screen.bind("Village"))
	if tab == 2:
		var date := ""
		for index in range(state.chronicle.size() - 1, -1, -1):
			var entry: Dictionary = state.chronicle[index]
			if history_category == "Projects" and entry.get("category", "") != "project": continue
			if history_category == "Family events" and entry.get("category", "") == "project": continue
			if not person_filter.is_empty():
				if entry.has("participant_ids"):
					if person_filter not in entry["participant_ids"]: continue
				elif entry.has("person_id"):
					if entry["person_id"] != person_filter: continue
				elif state.people[person_filter].name not in entry["description"] and person_filter not in entry["description"]: continue
			if entry["date"] != date:
				date = entry["date"]
				host._add_label(body, date, 18, host.TEXT_SUSPECTED)
			host._add_label(body, entry["description"], 15, host.TEXT_MAIN)
	else:
		var visible_ids: Array = state.household["members"].duplicate()
		if tab == 0:
			for id in state.people:
				if id not in visible_ids and not state.travel.current(id).is_empty(): visible_ids.append(id)
		for id in visible_ids:
			if not person_filter.is_empty() and id != person_filter: continue
			var person = state.people[id]
			if not person.alive: continue
			var card = host.GameplayScreens._card(host, body)
			var heading := HBoxContainer.new()
			card.add_child(heading)
			var portrait = host.PersonPortrait.new()
			portrait.custom_minimum_size = Vector2(40, 48)
			heading.add_child(portrait)
			portrait.show_person(person)
			host._add_label(heading, "%s · %d" % [person.name, person.age], 18, host.TEXT_MAIN).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_button(heading, "Manage", host._show_person.bind(id))
			if tab == 0: _activity(card, state, person)
			else: _queue(card, state, person)
	scroll.set_deferred("scroll_vertical", old_scroll)

func _progress(parent, progress: float, duration: float) -> void:
	var bar := ProgressBar.new()
	bar.max_value = duration
	bar.value = progress
	bar.show_percentage = false
	bar.custom_minimum_size.y = 10
	parent.add_child(bar)
	host._add_label(parent, "%.1f / %.0f study or work months · about %.0f remaining" % [progress, duration, ceil(maxf(0, duration - progress))], 14, host.TEXT_MUTED)

func _activity(card, state, person) -> void:
	var shared: Dictionary = state.social.commitment(person.id)
	if not shared.is_empty():
		var pair: Array = shared["participants"]
		var partner: String = pair[1] if pair[0] == person.id else pair[0]
		host._add_label(card, state.social.KINDS[shared["kind"]] + " · " + state.people[partner].name, 16, host.TEXT_MAIN)
		_progress(card, shared["months"], 3.0)
		if not shared["reason"].is_empty(): host._add_label(card, shared["reason"], 15, host.TEXT_SUSPECTED)
	var plan = state.activities.commitment(person.id)
	var study: Dictionary = person.education["study"]
	var journey: Dictionary = state.travel.current(person.id)
	var business: String = state.village.business.commitment(person.id)
	if not journey.is_empty(): host._add_label(card, "Travel · " + state.travel.location_text(person.id), 16, host.TEXT_MAIN)
	if not study.is_empty():
		var program: Dictionary = state.careers.programs.get(study["program_id"], {"name": study["program_id"], "months": maxf(1, study["progress"])})
		host._add_label(card, "Education · " + program["name"], 16, host.TEXT_MAIN)
		_progress(card, study["progress"], study.get("terms", {}).get("duration_months", program["months"]))
		if study.get("suspended", false): host._add_label(card, "Attention · course suspended; needs funding", 15, host.TEXT_SUSPECTED)
		elif study.get("unfunded_months", 0) > 0: host._add_label(card, "Attention · waiting for course fees", 15, host.TEXT_SUSPECTED)
	if not business.is_empty(): host._add_label(card, "Business · managing " + state.village.development.buildings[business]["address"] + " · ongoing", 16, host.TEXT_MAIN)
	if plan != null:
		host._add_label(card, "Project · " + state.activities.CATALOG[plan.activity_id]["name"], 16, host.TEXT_MAIN)
		_progress(card, plan.progress_months, plan.duration_months)
		if not plan.interruption_reason.is_empty(): host._add_label(card, "Attention · " + plan.interruption_reason, 15, host.TEXT_SUSPECTED)
		_controls(card, state, plan)
	if person.monthly_income_cents > 0 and study.is_empty():
		host._add_label(card, "Work · " + person.job + " · ongoing", 16, host.TEXT_MAIN)
	elif plan == null and study.is_empty() and business.is_empty() and journey.is_empty():
		host._add_label(card, "Daily life · " + person.job + " · no assigned project", 16, host.TEXT_MUTED)
	if not person.life_state.get("illness", {}).is_empty(): host._add_label(card, "Attention · recovering from illness", 15, host.TEXT_SUSPECTED)
	var observation: String = person.decision_state.get("observation", "")
	if not observation.is_empty(): host._add_label(card, observation, 14, host.TEXT_MUTED)

func _controls(card, state, plan) -> void:
	var row := HBoxContainer.new()
	card.add_child(row)
	_button(row, "Resume" if plan.status == "paused" else "Pause", func(): state.activities.pause_plan(state, plan.id); refresh())
	_button(row, "Cancel", func(): state.activities.cancel(state, plan.id); refresh())
	if plan.started_month < 0:
		var queue: Array = state.activities.queue_for(plan.participant_ids[0])
		_button(row, "↑", func(): state.activities.move(plan.id, -1); refresh()).disabled = queue.find(plan) == 0
		_button(row, "↓", func(): state.activities.move(plan.id, 1); refresh()).disabled = queue.find(plan) == queue.size() - 1

func _queue(card, state, person) -> void:
	var queue: Array = state.activities.queue_for(person.id)
	if queue.is_empty(): host._add_label(card, "No plans waiting.", 15, host.TEXT_MUTED)
	for plan in queue:
		host._add_label(card, state.activities.CATALOG[plan.activity_id]["name"], 16, host.TEXT_MAIN)
		var reason: String = state.activities.queue_reason(state, plan)
		var status := "Paused" if plan.status == "paused" else ("Waiting" if reason.begins_with("Waiting") or "already" in reason else "Blocked")
		host._add_label(card, "Ready · will seek agreement next month" if reason.is_empty() else status + " · " + reason, 14, host.TEXT_SUSPECTED)
		_controls(card, state, plan)
	if person.age < 18: return
	var choice := OptionButton.new()
	var ids: Array = state.activities.CATALOG.keys()
	for id in ids: choice.add_item(state.activities.CATALOG[id]["name"])
	card.add_child(choice)
	var terms: Label = host._add_label(card, "", 14, host.TEXT_MUTED)
	var show_terms := func(index):
		var entry: Dictionary = state.activities.CATALOG[ids[index]]
		terms.text = "%d months · %s per active month" % [entry["months"], state.economy.money(state.economy.purchase_cost(entry["cost"]))]
		choice.tooltip_text = entry["description"]
	show_terms.call(choice.selected)
	choice.item_selected.connect(show_terms)
	var neighbors := OptionButton.new()
	var targets: Array = state.village.households.keys()
	for id in targets: neighbors.add_item(state.village.households[id].name)
	card.add_child(neighbors)
	neighbors.visible = ids[choice.selected] == "visit"
	choice.item_selected.connect(func(index): neighbors.visible = ids[index] == "visit")
	_button(card, "Add to their queue", func():
		var target: String = targets[neighbors.selected] if neighbors.item_count > 0 else ""
		state.activities.enqueue(state, person.id, ids[choice.selected], target)
		feedback = "Plan added. Relatives can refuse when asked to start."
		refresh())
