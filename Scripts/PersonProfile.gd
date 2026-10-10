extends RefCounted
## Essential identity first; deeper information is opened deliberately.
const Activities = preload("res://Scripts/PersonActivities.gd")
const Marriage = preload("res://Scripts/PersonMarriage.gd")
const SECTIONS := ["Activities", "Marriage", "Background", "Personality", "Values & state", "History"]
static func build(host, person_id: String) -> void:
	var state = host.game_clock.state
	var model = state.people[person_id]
	var person: Dictionary = model.view_for(state.head_id)
	var parent: VBoxContainer = host.details_content
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	parent.add_child(header)
	var title: Label = host._add_label(header, "%s · %d" % [model.name, model.age], 27, host.TEXT_MAIN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := Button.new()
	close.text = "Close"
	header.add_child(close)
	close.pressed.connect(host.details_popup.hide)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 9)
	parent.add_child(identity)
	var portrait := PanelContainer.new()
	portrait.name = "Portrait"
	identity.add_child(portrait)
	host._install_portrait(portrait, model, 88)
	var essentials := VBoxContainer.new()
	essentials.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	essentials.add_theme_constant_override("separation", 4)
	identity.add_child(essentials)
	host._add_label(essentials, str(person["relationship"]).get_slice("·",0).strip_edges(), 16, host.TEXT_SUSPECTED)
	host._add_label(essentials, model.status_text(), 16, host.TEXT_MAIN)
	var location: String = state.travel.location_text(person_id)
	if model.life_state.has("marriage_id") and not model.in_household and location.is_empty():
		host._add_label(essentials, "Nearby branch household · still part of the family", 16, host.TEXT_KNOWN)
	if not location.is_empty():
		host._add_label(essentials, location, 16, host.TEXT_KNOWN)
	var pregnancy: Dictionary = model.life_state.get("pregnancy", {})
	if not pregnancy.is_empty():
		host._add_label(essentials, "Expecting a child · due in about %d months" % maxi(0,pregnancy["due_month"]-state.elapsed_months), 16, host.TEXT_KNOWN)
	var active = state.activities.commitment(person_id)
	if model.life_state.get("recovery_until_month",-1) > state.elapsed_months:
		host._add_label(essentials,"Recovering after childbirth · %d months of family care remaining" % (model.life_state["recovery_until_month"]-state.elapsed_months),16,host.TEXT_KNOWN)
	if active != null:
		host._add_label(essentials, "%s · %s · %.1f / %d months" % [state.activities.CATALOG[active.activity_id]["name"],active.status,active.progress_months,active.duration_months],16,host.TEXT_KNOWN)
	elif not model.education["study"].is_empty():
		host._add_label(essentials,"Currently studying",16,host.TEXT_KNOWN)
	elif not state.village.business.commitment(person_id).is_empty():
		host._add_label(essentials,"Managing " + state.village.development.buildings[state.village.business.commitment(person_id)]["address"],16,host.TEXT_KNOWN)
	var observation: String = person["summary"]
	if not observation.is_empty():
		host._add_flavor(parent, observation)
	var plan: Dictionary = model.decision_state.get("plan", {})
	if model.in_household and not plan.is_empty():
		host._add_label(parent,"Current intention · " + str(plan["description"]),16,host.TEXT_SUSPECTED)
		var timing: String = "Waiting for agreement on education funding." if str(plan.get("action", "")).begins_with("funding:") else "Preparing to act within %d months." % maxi(0, int(plan.get("due_month", state.elapsed_months)) - state.elapsed_months)
		host._add_label(parent, timing, 16, host.TEXT_SUSPECTED)
	if not host.conversation_result.is_empty():
		host._add_flavor(parent, host.conversation_result, false)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	parent.add_child(actions)
	if person_id != state.head_id:
		var talk := Button.new()
		talk.text = "Talk"
		talk.disabled = not model.alive or (not model.in_household and not model.life_state.has("marriage_id")) or not state.travel.current(person_id).is_empty()
		talk.pressed.connect(host._talk_to_person.bind(person_id))
		actions.add_child(talk)
		var request := Button.new()
		request.text = "Make a request"
		request.disabled = not model.alive
		request.pressed.connect(host._open_influence_menu.bind(person_id))
		actions.add_child(request)
	if model.alive and model.age >= 18:
		var marriage := Button.new()
		marriage.text = "Marriage & dote"
		marriage.pressed.connect(func():
			host.profile_expanded = true
			host.profile_section = "Marriage"
			host._show_person(person_id, false))
		actions.add_child(marriage)
	var more := Button.new()
	more.name = "ShowMore"
	more.text = "Show less" if host.profile_expanded else "Show more"
	more.pressed.connect(func():
		host.profile_expanded = not host.profile_expanded
		host._show_person(person_id,false))
	actions.add_child(more)
	for button in actions.get_children():
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 28
	host.Reaction.build(host, parent, person_id, "request")
	if not host.profile_expanded:
		return
	var tabs := HBoxContainer.new()
	tabs.name = "ProfileSections"
	tabs.add_theme_constant_override("separation", 3)
	parent.add_child(tabs)
	for section in SECTIONS:
		var button := Button.new()
		button.text = section
		button.toggle_mode = true
		button.button_pressed = host.profile_section == section
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(button)
		button.pressed.connect(func():
			host.profile_section = section
			host._show_person(person_id,false))
	var content := VBoxContainer.new()
	content.name = "ProfileSectionContent"
	content.add_theme_constant_override("separation", 5)
	parent.add_child(content)
	match host.profile_section:
		"Activities":
			Activities.build(host, content, person_id)
		"Marriage":
			Marriage.build(host, content, person_id)
		"Background":
			host._add_label(content,"Born %s %d · %s branch" % [state.MONTH_NAMES[model.birth_month-1], model.birth_year,model.branch_id],16,host.TEXT_MAIN)
			if state.people.has(model.spouse_id):
				host._add_label(content,"Married to " + state.people[model.spouse_id].name,16,host.TEXT_MAIN)
			host._add_label(content,"Responsibilities · " + (", ".join(model.roles) if not model.roles.is_empty() else "None assigned"),16,host.TEXT_MAIN)
			host._add_label(content,"Education · " + str(model.education["level"]).capitalize(),16,host.TEXT_MAIN)
			var careers := Button.new()
			careers.text = "Education & careers"
			content.add_child(careers)
			careers.pressed.connect(host._show_careers.bind(person_id,true))
			var goals: Array = person["expressed_goals"]
			if person_id == state.head_id:
				goals = []
				for goal in model.goals:
					if goal.get("status") == "active":
						goals.append(goal["description"])
			host._add_notes("Current goals",goals,content)
		"Personality":
			host._add_label(content,"Your understanding, based on conversations and observed behavior.",15,host.TEXT_MUTED)
			host._add_layer("Temperament",person["temperament"],content)
			host._add_layer("Learned tendencies",person["learned_tendencies"],content)
		"Values & state":
			host._add_layer("Values",person["values"],content)
			host._add_layer("Current state",person["current_state"],content)
		"History":
			host._add_notes("Formative experiences",person["experiences"],content)
			host._add_notes("Evidence you have noticed",person["evidence"],content)
			var memories: Array = []
			for memory in model.memories.slice(maxi(0,model.memories.size()-8)):
				if person_id != state.head_id and memory.get("kind","") not in ["activity", "activity_request", "conversation", "request"] and state.head_id not in memory.get("participants",[]):
					continue
				memories.append(str(memory.get("date","")) + " · " + str(memory.get("description","")))
			host._add_notes("Recent shared history",memories,content)
