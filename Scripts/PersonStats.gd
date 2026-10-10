extends RefCounted
## Public essentials and observed skills for the roster; full psychology lives in profiles.


static func refresh(host, card: PanelContainer, person) -> void:
	var stats: HFlowContainer = card.get_node("Row/Details/Stats")
	for child in stats.get_children():
		stats.remove_child(child)
		child.queue_free()
	var state = host.game_clock.state
	_add(host, stats, "health", person.health, "Current health", host.TEXT_KNOWN if person.health == "Well" else host.EventPresentation.BAD)
	_add(host, stats, "skill", str(person.education.get("level", "none")).capitalize(), "Education level", host.TEXT_MAIN)
	var income: int = roundi(person.monthly_income_cents * state.economy.event_income_multiplier * (0.5 if not person.life_state.get("illness", {}).is_empty() else 1.0))
	if not person.in_household or not state.travel.current(person.id).is_empty():
		income = 0
	_add(host, stats, "coins", state.economy.money(income) + "/month", "Current monthly earnings entering the family purse", host.TEXT_KNOWN if income > 0 else host.TEXT_MUTED)
	var observed: Dictionary = person.career_view_for(state.head_id)["skills"]
	var known: Array = []
	for skill in observed:
		if observed[skill] != "Unknown":
			known.append(skill)
	known.sort_custom(func(a, b): return person.skills[a] > person.skills[b])
	for skill in known.slice(0, 2):
		_add(host, stats, "skill", str(skill).capitalize() + " · " + str(observed[skill]), "Your current understanding of this skill", host.TEXT_MAIN)
	if known.is_empty():
		_add(host, stats, "skill", "Skills unknown", "Talk and work together to learn their skills", host.TEXT_UNKNOWN)
	# Keep all chips inside the card's existing click target.
	host._ignore_child_mouse(stats)


static func _add(host, parent: Node, icon_name: String, text: String, hint: String, color: Color) -> void:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 2)
	chip.tooltip_text = hint
	parent.add_child(chip)
	var icon := TextureRect.new()
	icon.texture = load("res://Assets/UI/Icons/" + icon_name + ".svg")
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.self_modulate = color
	chip.add_child(icon)
	var label: Label = host._add_label(chip, text, 14, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
