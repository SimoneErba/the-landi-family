extends RefCounted

static func build(host) -> void:
	var state = host.game_clock.state
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_overlay.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	host._add_label(column, "Succession & inheritance", 32, host.TEXT_MAIN)
	host._add_label(column, "Current head · " + state.people[state.head_id].name, 22, host.TEXT_SUSPECTED)
	host._add_label(column, "Your equal-share will names your children, including daughters. Descendants represent children who died before you. No child can be arbitrarily disinherited. Choosing the next head does not change the will.", 18, host.TEXT_MAIN)
	host._add_label(column, "This will deliberately includes daughters. Earlier Tuscan intestate rules could favor male lines; from 1866 the Italian code expressly recognized sons and daughters. The shares below concern cash.", 15, host.TEXT_MUTED)
	var projected: Dictionary = state.succession.preview(state)
	host._add_label(column, "Inheritance registration duty · " + state.economy.money(projected["inheritance_tax_cents"]) + " · " + state.Laws.regime(state.year, state.month), 17, host.TEXT_SUSPECTED)
	host._add_label(column, "Available cash estate after loans, reserved dowries and duties · " + state.economy.money(projected["estate_cents"]), 22, host.TEXT_KNOWN)
	if projected["shares"].is_empty():
		host._add_label(column, "No living descendants. The next head is the fallback beneficiary in this cash will.", 17, host.TEXT_MUTED)
	for id in projected["shares"]:
		host._add_label(column, state.people[id].name + " · " + state.economy.money(projected["shares"][id]), 19, host.TEXT_MAIN)
	host._add_label(column, "Next family head", 24, host.TEXT_MAIN)
	var nomination: String = state.succession.nominated_id
	host._add_label(column, "Nominated · " + (state.people[nomination].name if not nomination.is_empty() else "No one yet"), 18, host.TEXT_MUTED)
	for id in state.succession.candidates(state):
		var person = state.people[id]
		var button := Button.new()
		button.text = "Nominate " + person.name + " · " + str(person.age)
		button.custom_minimum_size.y = 36
		button.disabled = state.succession.pending or state.succession.ended
		column.add_child(button)
		button.pressed.connect(func():
			var error: String = state.succession.nominate(state, id)
			host.gameplay_result = error if not error.is_empty() else "The nomination is recorded. Inheritance shares stay equal."
			host._show_screen("Succession"))
	if not host.gameplay_result.is_empty(): host._add_label(column, host.gameplay_result, 17, host.TEXT_KNOWN)
	host._add_label(column, "Past succession", 24, host.TEXT_MAIN)
	for entry in state.succession.history:
		host._add_label(column, entry["date"] + " · " + state.people[entry["previous_head_id"]].name + " → " + state.people[entry["head_id"]].name + " · " + state.economy.money(entry["estate_cents"]), 18, host.TEXT_MAIN)
