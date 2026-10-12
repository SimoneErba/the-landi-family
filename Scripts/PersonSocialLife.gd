extends RefCounted
## Shared-time controls and secondhand impressions in the existing person dossier.

static func activities(host, parent: VBoxContainer, person_id: String) -> void:
	var state = host.game_clock.state
	host._add_label(parent, "Time together", 22, host.TEXT_MAIN)
	host._add_label(parent, "Life at home slowly reveals habits. Shared work and social time reveal more; each person learns for themselves.", 15, host.TEXT_MUTED)
	var active: Dictionary = state.social.commitment(person_id)
	if not active.is_empty():
		var pair: Array = active["participants"]
		var partner: String = pair[1] if pair[0] == person_id else pair[0]
		host._add_label(parent, state.social.KINDS[active["kind"]] + " · " + state.people[partner].name, 18, host.TEXT_MAIN)
		host._add_label(parent, "%s · %.1f / 3 months" % [active["status"].capitalize(), active["months"]], 15, host.TEXT_MUTED)
		if not active["reason"].is_empty(): host._add_label(parent, active["reason"], 15, host.TEXT_SUSPECTED)
		var cancel := Button.new()
		cancel.text = "Cancel shared time"
		parent.add_child(cancel)
		cancel.pressed.connect(func(): state.social.cancel(state, active["id"]); host._refresh_time_controls())
		return
	var ids: Array[String] = []
	var companions := OptionButton.new()
	companions.name = "SharedCompanion"
	for id in state.household["members"]:
		if id != person_id and state.people[id].alive and state.people[id].age >= 6:
			ids.append(id)
			companions.add_item(state.people[id].name)
	if ids.is_empty() or not state.social.available(state, person_id) or state.people[person_id].age < 6: return
	parent.add_child(companions)
	if state.head_id in ids: companions.select(ids.find(state.head_id))
	var kind := OptionButton.new()
	kind.name = "SharedTimeKind"
	for key in state.social.KINDS: kind.add_item(state.social.KINDS[key])
	kind.select(1)
	parent.add_child(kind)
	var explanation: Label = host._add_label(parent, "", 15, host.TEXT_MUTED)
	var request := Button.new()
	request.name = "SharedTimeRequest"
	request.text = "Ask to spend time together"
	parent.add_child(request)
	var refresh := func(_index = 0):
		var choice: String = state.social.KINDS.keys()[kind.selected]
		var blocked: String = state.social.reason(state, person_id, ids[companions.selected], choice)
		explanation.text = "Three months of regular shared time, alongside everyday life. Both relatives must agree. Household work also improves the house's condition." if blocked.is_empty() else blocked
		request.disabled = not blocked.is_empty()
	refresh.call()
	companions.item_selected.connect(refresh)
	kind.item_selected.connect(refresh)
	request.pressed.connect(func():
		var result: Dictionary = state.social.propose(state, person_id, ids[companions.selected], state.social.KINDS.keys()[kind.selected])
		host.Reaction.remember(host, result, person_id, "activity")
		host._refresh_time_controls())

static func reports(host, parent: VBoxContainer, reporter_id: String) -> void:
	var state = host.game_clock.state
	if reporter_id == state.head_id or not state.social.available(state, reporter_id): return
	host._add_label(parent, "Ask about another relative", 20, host.TEXT_MAIN)
	host._add_label(parent, "They share only what they believe they know. Reports become suspicions, with the speaker recorded as evidence.", 15, host.TEXT_MUTED)
	var ids: Array[String] = []
	var choice := OptionButton.new()
	choice.name = "AskAboutRelative"
	for id in state.people:
		if id not in [reporter_id, state.head_id]:
			ids.append(id)
			choice.add_item(state.people[id].name)
	if ids.is_empty(): return
	parent.add_child(choice)
	var ask := Button.new()
	ask.name = "AskForImpressions"
	ask.text = "What do you know about them?"
	parent.add_child(ask)
	ask.pressed.connect(func():
		host.conversation_result = state.social.ask_about(state, reporter_id, ids[choice.selected])
		host._show_person(reporter_id, false))
