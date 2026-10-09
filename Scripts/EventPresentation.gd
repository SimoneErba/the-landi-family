extends RefCounted
## Readable consequences from the actual effects; private psychology stays qualitative.

const GOOD := Color("#37613e")
const BAD := Color("#a13e32")
const NEUTRAL := Color("#786b57")


static func consequences(state, event: Dictionary, effects: Dictionary) -> Array:
	var rows: Array = []
	if effects.has("cash") and int(effects.cash) != 0:
		var amount := int(effects.cash)
		var paid: int = state.economy.purchase_cost(-amount) if amount < 0 else amount
		rows.append(_row("coins", ("− " if amount < 0 else "+ ") + state.economy.money(paid), -1 if amount < 0 else 1))
	if effects.has("cash_loss"):
		rows.append(_row("coins", "Money lost · up to " + state.economy.money(int(effects.cash_loss)), -1))
	if effects.has("delayed_cash"):
		var amount := int(effects.delayed_cash)
		rows.append(_row("coins", ("+ " if amount >= 0 else "− ") + state.economy.money(absi(amount)) + " in %d months" % int(effects.get("delay_months", 0)), 1 if amount > 0 else -1))
	for key in ["condition", "property_condition"]:
		if float(effects.get(key, 0)) != 0:
			var improves := float(effects[key]) > 0
			rows.append(_row("house", ("House" if key == "condition" else "Property") + (" condition improves" if improves else " condition worsens"), 1 if improves else -1))
	if effects.has("room"):
		rows.append(_row("house", "New " + str(effects.room).replace("_", " ") + " · %+d capacity" % int(effects.get("capacity", 0)), 1))
	elif int(effects.get("capacity", 0)) != 0:
		rows.append(_row("house", "%+d household capacity" % int(effects.capacity), 1 if int(effects.capacity) > 0 else -1))
	var person = state.people.get(event.get("person_id", ""))
	var subject: String = person.name.get_slice(" ", 0) if person != null else "Relative"
	for key in ["happiness", "stress", "resentment", "trust", "household_happiness", "household_stress"]:
		var change := float(effects.get(key, 0))
		if change == 0:
			continue
		var stat: String = key.trim_prefix("household_")
		var positive := change > 0 if stat in ["happiness", "trust"] else change < 0
		var owner: String = "Family" if key.begins_with("household_") else subject
		var icon: String = "mood" if stat == "happiness" else ("stress" if stat == "stress" else "bond")
		rows.append(_row(icon, owner + " · " + stat + (" increases" if change > 0 else " decreases"), 1 if positive else -1))
	if effects.has("skill") and float(effects.get("skill_gain", 0)) != 0:
		var improves := float(effects.skill_gain) > 0
		rows.append(_row("skill", subject + " · " + str(effects.skill).replace("_", " ") + (" improves" if improves else " declines"), 1 if improves else -1))
	if effects.get("study", false):
		var program: Dictionary = state.careers.programs.get(event.get("program_id", ""), {})
		rows.append(_row("skill", "Begin " + str(program.get("name", "studies")), 1))
		var tuition: int = state.economy.purchase_cost(int(program.get("monthly_cost_cents", 0)))
		if tuition > 0:
			rows.append(_row("coins", "− " + state.economy.money(tuition) + "/month tuition", -1))
	if effects.has("illness_months"):
		rows.append(_row("health", subject + " · ill for %d months" % int(effects.illness_months), -1))
	if effects.has("shorten_illness") and person != null and not person.life_state.get("illness", {}).is_empty():
		rows.append(_row("health", subject + " · recovery brought forward", 1))
	if effects.get("pregnancy", false):
		rows.append(_row("health", subject + " · expecting a child", 0))
	if effects.get("stay_release", false):
		rows.append(_row("bond", subject + " · free to reconsider staying", 0))
	if float(effects.get("relief", 0)) != 0:
		rows.append(_row("provisions", "Food shortage eases" if float(effects.relief) > 0 else "Food shortage worsens", 1 if float(effects.relief) > 0 else -1))
	if effects.has("currency"):
		rows.append(_row("coins", "Currency reform acknowledged", 0))
	if effects.has("crisis"):
		var crisis: Dictionary = effects.crisis
		var duration := " · %d months" % int(crisis.get("months", 0))
		for key in ["food_multiplier", "income_multiplier"]:
			var multiplier := float(crisis.get(key, 1))
			if is_equal_approx(multiplier, 1):
				continue
			var improves := multiplier < 1 if key == "food_multiplier" else multiplier > 1
			rows.append(_row("provisions" if key == "food_multiplier" else "coins", ("Food costs" if key == "food_multiplier" else "Household income") + " %+d%%" % roundi((multiplier - 1) * 100) + duration, 1 if improves else -1))
		if int(crisis.get("travel_delay_months", 0)) > 0:
			rows.append(_row("calendar", "Travel disrupted · %d months" % int(crisis.travel_delay_months), -1))
	return rows


static func _row(icon: String, text: String, tone: int) -> Dictionary:
	return {"icon": icon, "text": text, "tone": tone}


static func draw_rows(host, parent: Node, rows: Array) -> void:
	for entry in rows:
		var color: Color = GOOD if entry.tone > 0 else (BAD if entry.tone < 0 else NEUTRAL)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		parent.add_child(row)
		var icon := TextureRect.new()
		icon.texture = load("res://Assets/UI/Icons/" + str(entry.icon) + ".svg")
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.self_modulate = color
		row.add_child(icon)
		var label: Label = host._add_label(row, entry.text, 14, color)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
