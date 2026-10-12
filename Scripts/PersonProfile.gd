extends RefCounted
## A single dossier: urgent concerns, observed psychology, practical life and history.
const Activities = preload("res://Scripts/PersonActivities.gd")
const Marriage = preload("res://Scripts/PersonMarriage.gd")

static func build(host, person_id: String) -> void:
	var state = host.game_clock.state
	var model = state.people[person_id]
	var person: Dictionary = model.view_for(state.head_id)
	var parent: VBoxContainer = host.details_content
	var header := HBoxContainer.new()
	parent.add_child(header)
	var portrait := PanelContainer.new()
	header.add_child(portrait)
	host._install_portrait(portrait, model, 96)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(identity)
	host._add_label(identity, "%s · %d" % [model.name, model.age], 29, host.TEXT_MAIN)
	host._add_label(identity, str(person["relationship"]), 17, host.TEXT_SUSPECTED)
	var facts := HFlowContainer.new()
	identity.add_child(facts)
	_essentials(host, facts, model)
	var location: String = state.travel.location_text(person_id)
	var personal: int = model.life_state.get("personal_cash_cents", 0)
	if personal > 0: host._add_label(identity, "Personal inheritance · " + state.economy.money(personal), 16, host.TEXT_KNOWN)
	if not location.is_empty():
		host._add_label(identity, location, 15, host.TEXT_KNOWN)
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "Close person profile"
	close.custom_minimum_size = Vector2(32, 32)
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_child(close)
	close.pressed.connect(host.details_popup.hide)
	var actions := HBoxContainer.new()
	parent.add_child(actions)
	if person_id != state.head_id:
		var talk := _button(actions, "Talk", "people")
		talk.disabled = not model.alive or (not model.in_household and not model.life_state.has("marriage_id")) or not state.travel.current(person_id).is_empty()
		talk.pressed.connect(host._talk_to_person.bind(person_id))
		var request := _button(actions, "Make a request", "bond")
		request.disabled = not model.alive
		request.pressed.connect(func():
			host.profile_section = "Requests"
			jump_to(host, "Requests"))
	if model.alive and model.age >= 18:
		var marriage := _button(actions, "Marriage & dote", "people")
		marriage.pressed.connect(func():
			host.profile_section = "Marriage"
			jump_to(host, "Marriage"))
	var scroll := ScrollContainer.new()
	scroll.name = "ProfileScroll"

	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# A second clipping boundary keeps wrapped flow cards below the fixed header.
	var viewport := MarginContainer.new()
	viewport.name = "ProfileViewport"
	viewport.clip_contents = true
	viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(viewport)
	viewport.add_child(scroll)
	var content := VBoxContainer.new()
	content.name = "ProfileSectionContent"
	content.add_theme_constant_override("separation", 12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var now := _category(host, content, "At a glance", "warning", "Overview")
	if not str(person["summary"]).is_empty():
		host._add_flavor(now, person["summary"])
	var plan: Dictionary = model.decision_state.get("plan", {})
	if model.in_household and not plan.is_empty():
		host._add_label(now, str(plan["description"]), 18, host.TEXT_SUSPECTED)
		host._add_label(now, "Waiting for agreement on education funding." if str(plan.get("action", "")).begins_with("funding:") else "Preparing to act within %d months." % maxi(0, int(plan.get("due_month", state.elapsed_months)) - state.elapsed_months), 15, host.TEXT_SUSPECTED)
	_current_tasks(host, now, person_id)
	var pregnancy: Dictionary = model.life_state.get("pregnancy", {})
	if not pregnancy.is_empty():
		_task_progress(host, now, "Expecting a child", "Due in about %d months" % maxi(0, pregnancy["due_month"] - state.elapsed_months), 9 - maxi(0, pregnancy["due_month"] - state.elapsed_months), 9)
	if model.life_state.get("recovery_until_month", -1) > state.elapsed_months:
		host._add_label(now, "Recovering after childbirth · %d months of family care remaining" % (model.life_state["recovery_until_month"] - state.elapsed_months), 16, host.TEXT_KNOWN)
	var goals: Array = person["expressed_goals"]
	if person_id == state.head_id:
		goals = []
		for goal in model.goals:
			if goal.get("status") == "active": goals.append(goal["description"])
	_notes(host, now, goals, "No current goals shared with you.")
	var psyche := _category(host, content, "Personality & traits", "mood", "Personality")
	host._add_label(psyche, "Your understanding grows through conversations and shared experiences.", 15, host.TEXT_MUTED)
	var legend := HFlowContainer.new()
	psyche.add_child(legend)
	for certainty in ["known", "suspected", "unknown"]:
		_trait(host, legend, certainty.capitalize(), certainty)
	_layer(host, psyche, "Temperament", person["temperament"])
	_layer(host, psyche, "Habits & responses", person["learned_tendencies"])
	var values := _category(host, content, "Values & emotional state", "bond", "Values")
	_layer(host, values, "What matters to them", person["values"])
	_layer(host, values, "How they seem to feel", person["current_state"])
	var skills := _category(host, content, "Abilities, skills & interests", "skill", "Skills")
	host._add_label(skills, "Bars represent observed levels, rather than exact scores.", 14, host.TEXT_MUTED)
	for layer in ["abilities", "skills", "interests"]:
		host._add_label(skills, str(layer).capitalize(), 18, host.TEXT_MAIN)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 18)
		skills.add_child(grid)
		for key in person["career"][layer]:
			var band: String = person["career"][layer][key]
			var cell := VBoxContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(cell)
			host._add_label(cell, str(key).replace("_", " ").capitalize() + " · " + band, 15, host.TEXT_UNKNOWN if band == "Unknown" else host.TEXT_MAIN)
			if band != "Unknown":
				var levels := {"Needs support": 1, "Developing": 2, "Strong": 3, "Beginner": 1, "Basic": 2, "Competent": 3, "Experienced": 4, "Little interest": 1, "Some interest": 2, "Keen": 3}
				_bar(host, cell, levels[band], 4 if layer == "skills" else 3, band)
	var background := _category(host, content, "Family, work & education", "house", "Background")
	host._add_label(background, "Born %s %d · %s branch" % [state.MONTH_NAMES[model.birth_month - 1], model.birth_year, model.branch_id], 16, host.TEXT_MAIN)
	host._add_label(background, model.job, 18, host.TEXT_MAIN)
	if state.people.has(model.spouse_id):
		host._add_label(background, "Married to " + state.people[model.spouse_id].name, 16, host.TEXT_MAIN)
	for id in model.parent_ids:
		if state.people.has(id): host._add_label(background, "Parent · " + state.people[id].name, 15, host.TEXT_MAIN)
	var children: Array[String] = []
	for relative in state.people.values():
		if person_id in relative.parent_ids: children.append(relative.name)
	if not children.is_empty(): host._add_label(background, "Children · " + ", ".join(children), 16, host.TEXT_MAIN)
	host._add_label(background, "Responsibilities · " + (", ".join(model.roles) if not model.roles.is_empty() else "None assigned"), 16, host.TEXT_MAIN)
	host._add_label(background, "Education · " + str(model.education["level"]).capitalize(), 16, host.TEXT_MAIN)
	var careers := _button(background, "Education & careers", "education")
	careers.pressed.connect(host._show_careers.bind(person_id, true))
	var requests := _category(host, content, "Requests & influence", "bond", "Requests")
	preload("res://Scripts/PersonSocialLife.gd").reports(host, requests, person_id)
	host._add_label(requests, "Their wishes and relationship with you shape their answer.", 15, host.TEXT_MUTED)
	for action in state.Influence.ACTIONS:
		var reason: String = state.Influence.unavailable_reason(state, person_id, action)
		var button := _button(requests, state.Influence.ACTIONS[action], "bond")
		button.disabled = not reason.is_empty()
		button.tooltip_text = reason
		button.pressed.connect(host._make_request.bind(person_id, action))
	var activities := _category(host, content, "Activities & responsibilities", "calendar", "Activities")
	Activities.build(host, activities, person_id)
	var marriage := _category(host, content, "Marriage & family ties", "people", "Marriage")
	Marriage.build(host, marriage, person_id)
	var history := _category(host, content, "Experiences & shared history", "history", "History")
	host._add_label(history, "Formative experiences", 19, host.TEXT_MAIN)
	_notes(host, history, person["experiences"], "No formative experiences known yet.")
	host._add_label(history, "Evidence you have noticed", 19, host.TEXT_MAIN)
	_notes(host, history, person["evidence"], "No observations recorded yet.")
	var memories: Array = []
	for memory in model.memories.slice(maxi(0, model.memories.size() - 8)):
		if person_id != state.head_id and memory.get("kind", "") not in ["activity", "activity_request", "conversation", "request"] and state.head_id not in memory.get("participants", []): continue
		memories.append(str(memory.get("date", "")) + " · " + str(memory.get("description", "")))
	host._add_label(history, "Recent shared history", 19, host.TEXT_MAIN)
	_notes(host, history, memories, "Your shared history will appear here.")
	_response(host, parent, person_id)

static func jump_to(host, category: String) -> void:
	var scroll: ScrollContainer = host.details_content.get_node("ProfileViewport/ProfileScroll")
	var target = scroll.find_child(category, true, false)
	if target != null: scroll.call_deferred("ensure_control_visible", target)

static func _icon(parent: Node, icon_name: String, color: Color) -> void:
	var icon := TextureRect.new()
	icon.texture = load("res://Assets/UI/Icons/" + icon_name + ".svg")
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.self_modulate = color
	parent.add_child(icon)

static func _button(parent: Node, text: String, icon_name: String) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = load("res://Assets/UI/Icons/" + icon_name + ".svg")
	button.add_theme_constant_override("icon_max_width", 18)
	button.custom_minimum_size.y = 30
	parent.add_child(button)
	return button

static func _essentials(host, parent: Node, model) -> void:
	var state = host.game_clock.state
	var income: int = state.economy.earnings(model)
	if not model.alive or not model.in_household or not state.travel.current(model.id).is_empty(): income = 0
	for entry in [["health", model.health if model.alive else "Deceased", "Health"], ["house", "At home" if model.in_household else ("Nearby branch" if model.life_state.has("marriage_id") else "Elsewhere"), "Residence"], ["coins", state.economy.money(income) + "/month", "Contribution to the family purse"]]:
		var row := HBoxContainer.new()
		row.tooltip_text = entry[2]
		parent.add_child(row)
		_icon(row, entry[0], host.TEXT_MUTED)
		var label: Label = host._add_label(row, entry[1], 15, host.TEXT_MAIN)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF

static func _category(host, parent: Node, title: String, icon_name: String, id: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = id
	var style = host.Archive.card()
	style.bg_color = Color("#e5d4b4")
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 7)
	panel.add_child(body)
	var heading := HBoxContainer.new()
	body.add_child(heading)
	_icon(heading, icon_name, host.TEXT_SUSPECTED)
	var label: Label = host._add_label(heading, title, 23, host.TEXT_MAIN)
	host.ConceptHelp.attach(label, "Marriage & dote" if id == "Marriage" else id)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return body

static func _layer(host, parent: Node, title: String, layer: Dictionary) -> void:
	host._add_label(parent, title, 19, host.TEXT_MAIN)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	parent.add_child(flow)
	var count := 0
	for certainty in ["known", "suspected", "unknown"]:
		for entry in layer.get(certainty, []):
			_trait(host, flow, str(entry), certainty)
			count += 1
	if count == 0: host._add_label(parent, "You have not learned enough yet.", 15, host.TEXT_UNKNOWN)

static func _trait(host, parent: Node, text: String, certainty: String) -> void:
	var color: Color = {"known": host.TEXT_KNOWN, "suspected": host.TEXT_SUSPECTED, "unknown": host.TEXT_UNKNOWN}[certainty]
	var panel := PanelContainer.new()
	host.ConceptHelp.attach(panel, certainty.capitalize())
	panel.tooltip_text = text + "\n\n" + panel.tooltip_text
	panel.custom_minimum_size.x = 180
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = {"known": Color("#d5dcc3"), "suspected": Color("#e6d3ac"), "unknown": Color("#ded6c7")}[certainty]
	style.set_corner_radius_all(4)
	style.set_content_margin_all(7)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var row := HBoxContainer.new()
	panel.add_child(row)
	_icon(row, certainty, color)
	var label: Label = host._add_label(row, text, 17, color)
	label.custom_minimum_size.x = 140
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

static func _notes(host, parent: Node, notes: Array, empty: String) -> void:
	if notes.is_empty(): host._add_label(parent, empty, 15, host.TEXT_MUTED)
	for note in notes: host._add_label(parent, "• " + str(note), 16, host.TEXT_MAIN)

static func _bar(host, parent: Node, value: float, maximum: float, hint: String) -> void:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 9
	bar.max_value = maximum
	bar.value = value
	bar.show_percentage = false
	bar.tooltip_text = hint
	for part in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#c4b391") if part == "background" else host.TEXT_KNOWN
		style.set_corner_radius_all(3)
		bar.add_theme_stylebox_override(part, style)
	parent.add_child(bar)


static func _response(host, parent: VBoxContainer, person_id: String) -> void:
	var panel := PanelContainer.new()
	panel.name = "PersonResponse"
	panel.custom_minimum_size.y = 100
	panel.add_theme_stylebox_override("panel", host.Archive.card())
	parent.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	host._add_label(content, "Latest response", 16, host.TEXT_MUTED)
	var context := "request"
	for candidate in ["activity", "business"]:
		var feedback: Dictionary = host.assignment_feedback.get(person_id + ":" + candidate, {})
		var current: Dictionary = host.assignment_feedback.get(person_id + ":" + context, {})
		if not feedback.is_empty() and (current.is_empty() or int(feedback["created_msec"]) >= int(current["created_msec"])):
			context = candidate
	host.Reaction.build(host, content, person_id, context)
	if not host.conversation_result.is_empty():
		host._add_flavor(content, host.conversation_result, false)
	elif not host.assignment_feedback.has(person_id + ":" + context):
		host._add_label(content, "Conversations and requests appear here.", 14, host.TEXT_MUTED)


static func _current_tasks(host, parent: VBoxContainer, person_id: String) -> void:
	var state = host.game_clock.state
	var active = state.activities.commitment(person_id)
	var shared: Dictionary = state.social.commitment(person_id)
	var study: Dictionary = state.people[person_id].education["study"]
	var journey: Dictionary = state.travel.current(person_id)
	if active == null and shared.is_empty() and study.is_empty() and journey.is_empty():
		return
	var section := VBoxContainer.new()
	section.name = "CurrentTasks"
	section.add_theme_constant_override("separation", 5)
	parent.add_child(section)
	host._add_label(section, "Current tasks", 20, host.TEXT_MAIN)
	if not shared.is_empty():
		var pair: Array = shared["participants"]
		var partner: String = pair[1] if pair[0] == person_id else pair[0]
		_task_progress(host, section, state.social.KINDS[shared["kind"]] + " with " + state.people[partner].name, shared["status"].capitalize(), shared["months"], 3.0, shared["reason"])
	if active != null:
		_task_progress(host, section, state.activities.CATALOG[active.activity_id]["name"], active.status.capitalize(), active.progress_months, active.duration_months, active.interruption_reason)
	if not study.is_empty() and state.careers.programs.has(study["program_id"]):
		var program: Dictionary = state.careers.programs[study["program_id"]]
		_task_progress(host, section, program["name"], study["status"], study["progress"], program["months"])
	if not journey.is_empty():
		var city: Dictionary = state.travel.CITIES[journey["city_id"]]
		if journey["status"] == "staying":
			var purpose: Dictionary = state.travel.PURPOSES[journey["purpose_id"]]
			_task_progress(host, section, purpose["name"] + " in " + city["name"], "Staying", journey["progress"], purpose["months"])
		else:
			var duration: float = city["months"]
			var title: String = ("Travel to " if journey["status"] == "outbound" else "Return from ") + city["name"]
			_task_progress(host, section, title, journey["status"].capitalize(), duration - float(journey["remaining_months"]), duration, journey.get("interruption_reason", ""))


static func _task_progress(host, parent: VBoxContainer, title: String, status: String, progress: float, duration: float, reason: String = "") -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	parent.add_child(row)
	host._add_label(row, title + " · " + status, 16, host.TEXT_KNOWN)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = maxf(1.0, duration)
	bar.value = clampf(progress, 0.0, bar.max_value)
	bar.show_percentage = false
	bar.tooltip_text = "%.1f / %d months completed" % [progress, duration]
	var track := StyleBoxFlat.new()
	track.bg_color = Color("#302b25")
	track.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = host.TEXT_KNOWN
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	host._add_label(row, bar.tooltip_text, 14, host.TEXT_MUTED)
	if not reason.is_empty():
		host._add_label(row, reason, 14, host.TEXT_SUSPECTED)
