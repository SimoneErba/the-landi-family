extends RefCounted
## Proposal requirements are public; personal acceptance remains qualitative.
static func build(host, parent: VBoxContainer, person_id: String) -> void:
	var state = host.game_clock.state
	var person = state.people[person_id]
	host._add_label(parent, "Marriage & dote", 24, host.TEXT_MAIN)
	if not host.gameplay_result.is_empty(): host._add_flavor(parent, host.gameplay_result, false)
	if state.people.has(person.spouse_id):
		host._add_label(parent, "Married to " + state.people[person.spouse_id].name, 18, host.TEXT_MAIN)
		var union: Dictionary = state.marriage.unions.get(person.life_state.get("marriage_id", ""), {})
		if not union.is_empty():
			host._add_label(parent, "%s · Couple's capital: %s" % ["Landi House" if union["residence"] == "home" else "Nearby branch household", state.economy.money(union["capital_cents"])], 16, host.TEXT_MAIN)
			if union["held_at_home"]: host._add_label(parent, "This dowry is in the shared purse, but owed to the couple. If they leave or a spouse dies, it must be released, even if this creates a cash shortfall.", 16, host.TEXT_SUSPECTED)
	else:
		var reason: String = state.marriage.reason(state, person_id)
		if not reason.is_empty(): host._add_label(parent, reason, 16, host.TEXT_SUSPECTED)
		else:
			var bride: bool = state.marriage.role(person) == "bride"
			host._add_label(parent, "Your family pays the bride's dowry." if bride else "The bride's family provides the dowry. It enters your purse only if the couple stays here.", 16, host.TEXT_MAIN)
			var find := Button.new()
			find.name = "FindMarriageCandidates"
			find.text = "Find a marriage partner"
			parent.add_child(find)
			find.pressed.connect(func(): open_candidates(host, person_id))
	if not state.marriage.alliances.is_empty():
		host._add_label(parent, "Allied families · Standing %d" % state.marriage.prestige, 22, host.TEXT_MAIN)
		for family_id in state.marriage.alliances:
			var entry: Dictionary = state.marriage.FAMILIES[family_id]
			var alliance: Dictionary = state.marriage.alliances[family_id]
			host._add_label(parent, state.village.households[family_id].name + " · " + entry["occupation"], 18, host.TEXT_MAIN)
			host._add_label(parent, entry["description"] + " They may refuse or ask for repayment.", 16, host.TEXT_MUTED)
			var favor := Button.new()
			favor.text = "Ask for " + entry["favor"].to_lower() + " for " + person.name
			favor.disabled = not person.alive or alliance["obligation_cents"] > 0 or state.elapsed_months - int(alliance["last_favor"]) < 12
			parent.add_child(favor)
			favor.pressed.connect(func(): _finish(host, state.marriage.favor(state, family_id, person_id)))
			if alliance["obligation_cents"] > 0:
				var repay := Button.new()
				repay.text = "Repay favor · " + state.economy.money(alliance["obligation_cents"])
				repay.disabled = state.economy.cash_cents < int(alliance["obligation_cents"])
				parent.add_child(repay)
				repay.pressed.connect(func(): _finish(host, state.marriage.repay(state, family_id)))

static func open_candidates(host, person_id: String) -> void:
	var state = host.game_clock.state
	if not state.people.has(person_id): return
	if not state.marriage.reason(state, person_id).is_empty():
		if is_instance_valid(host.marriage_popup): host.marriage_popup.hide()
		return
	if not is_instance_valid(host.marriage_popup):
		host.marriage_popup = PopupPanel.new()
		host.marriage_popup.name = "MarriageCandidates"
		host.marriage_popup.add_theme_stylebox_override("panel", host.Archive.window_frame())
		host.add_child(host.marriage_popup)
	if host.marriage_person_id != person_id:
		host.marriage_candidate_id = ""
	host.marriage_person_id = person_id
	var popup: PopupPanel = host.marriage_popup
	var viewport_size: Vector2 = host.get_viewport_rect().size
	var dimensions := Vector2i(int(minf(860, viewport_size.x - 32)), int(minf(480, viewport_size.y - 32)))
	popup.size = dimensions
	for child in popup.get_children():
		popup.remove_child(child)
		child.queue_free()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	popup.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title: Label = host._add_label(header, "Marriage partners · " + state.people[person_id].name, 24, host.TEXT_MAIN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := Button.new()
	close.text = "Close"
	header.add_child(close)
	close.pressed.connect(popup.hide)
	if not host.gameplay_result.is_empty(): host._add_flavor(column, host.gameplay_result, false)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size.x = 220
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(list_scroll)
	var list := VBoxContainer.new()
	list.name = "CandidateList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(list)
	var proposals: Array = state.marriage.proposals(state, person_id)
	if not proposals.is_empty() and not proposals.any(func(proposal): return proposal["id"] == host.marriage_candidate_id):
		host.marriage_candidate_id = proposals[0]["id"]
	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail.name = "CandidateDetails"
	detail.custom_minimum_size.x = maxf(180, dimensions.x - 280)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(detail)
	for proposal in proposals:
		var button := Button.new()
		button.name = "Candidate_" + str(proposal["offer"]["family_id"])
		button.text = proposal["offer"]["source"]["name"] + "\n" + proposal["family"]["occupation"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = proposal["id"] == host.marriage_candidate_id
		list.add_child(button)
		button.pressed.connect(func():
			host.marriage_candidate_id = proposal["id"]
			open_candidates(host, person_id))
		if button.button_pressed: _proposal(host, detail, person_id, proposal)
	if proposals.is_empty(): host._add_label(detail, "No available candidates.", 16, host.TEXT_MUTED)
	if popup.visible:
		popup.size = dimensions
	else:
		popup.popup_centered(dimensions)
	# Shrink after the first layout pass, when wrapped text has its final width.
	popup.set_deferred("size", dimensions)
	popup.set_deferred("position", Vector2i((viewport_size - Vector2(dimensions)) / 2))

static func _proposal(host, parent: VBoxContainer, person_id: String, proposal: Dictionary) -> void:
	var state = host.game_clock.state
	var offer: Dictionary = proposal["offer"]
	var entry: Dictionary = proposal["family"]
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	parent.add_child(box)
	var age: int = state.year - int(offer["source"]["birth"]["year"]) - (1 if state.month < offer["source"]["birth"]["month"] else 0)
	host._add_label(box, "%s · %d · %s" % [offer["source"]["name"], age, entry["occupation"]], 20, host.TEXT_MAIN)
	host._add_label(box, "Dote: %s · %s" % [state.economy.money(offer["dowry_cents"]), "Values independence and social ambition; compatibility is uncertain." if entry["prestige"] > 0 else "Describes a strong attachment to family and shared work."], 16, host.TEXT_SUSPECTED)
	host._add_label(box, "Possible connection: " + entry["description"], 16, host.TEXT_MUTED)
	var terms := HBoxContainer.new()
	box.add_child(terms)
	var amount := SpinBox.new()
	amount.min_value = .01
	amount.max_value = 100000
	amount.step = .01
	amount.value = float(offer["dowry_cents"]) / 100.0
	amount.suffix = "lire"
	amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terms.add_child(amount)
	var negotiate := Button.new()
	negotiate.text = "Negotiate dote"
	terms.add_child(negotiate)
	negotiate.pressed.connect(func(): _finish(host, state.marriage.negotiate(state, proposal["id"], roundi(amount.value * 100))))
	var residence := OptionButton.new()
	residence.add_item("Settle in a nearby household")
	residence.add_item("Stay in Landi House")
	residence.select(1 if person_id == state.head_id else 0)
	box.add_child(residence)
	var explanation: Label = host._add_label(box, "", 16, host.TEXT_SUSPECTED)
	var marry := Button.new()
	marry.name = "ProposeMarriage_" + offer["family_id"]
	marry.text = "Propose marriage"
	box.add_child(marry)
	var refresh := func(_index = 0):
		var place := "home" if residence.selected == 1 else "elsewhere"
		var reason: String = state.marriage.unavailable(state, proposal["id"], place)
		explanation.text = reason if not reason.is_empty() else ("The couple needs space. Received dowry remains owed to them." if place == "home" else "The relative leaves the house. The couple keeps its dowry, wages and living costs separately.")
		marry.disabled = not reason.is_empty()
	refresh.call()
	residence.item_selected.connect(refresh)
	marry.pressed.connect(func(): _finish(host, state.marriage.propose(state, proposal["id"], "home" if residence.selected == 1 else "elsewhere"), true))

static func _finish(host, result: Dictionary, major: bool = false) -> void:
	if major: host.game_clock.pause()
	host.gameplay_result = result["response"]
	host._refresh_time_controls()
