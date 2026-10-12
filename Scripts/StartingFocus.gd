extends Control
## Two choices, kept separate: the founder's destination and the family's advantage.

var host
var selected := {"objective": "", "bonus": ""}
var step := 0
var goal_page: VBoxContainer
var bonus_page: VBoxContainer
var back: Button
var next: Button
var begin: Button
var goal_summary: Label
var goal_buttons: Array[Button] = []
var bonus_buttons: Array[Button] = []
var footer_buttons: Array[Button] = []

func _ready() -> void:
	name = "StartingFocus"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = host.InlinePanel.OVERLAY_Z_INDEX
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.12, 0.09, 0.06, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1080, 580)
	panel.add_theme_stylebox_override("panel", host.Archive.modal_frame())
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 1032
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	back = Button.new()
	back.name = "BackToGoal"
	back.text = "← Back to your goal"
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func(): _show_step(0))
	column.add_child(back)
	goal_page = _page(column, "FounderGoal")
	host._add_label(goal_page, "STEP 1 OF 2 · THE FOUNDER'S DREAM", 14, host.TEXT_SUSPECTED)
	host._add_label(goal_page, "What will your family be remembered for?", 30, host.TEXT_MAIN)
	host._add_label(goal_page, "Choose the founder's dream: the goal your family will pursue across a century. This is what you hope future generations will achieve.", 18, host.TEXT_MUTED)
	var legacy = host.game_clock.state.legacy
	goal_buttons = _cards(goal_page, "ObjectiveCards", legacy.OBJECTIVES, ["A house full of voices. A name carried by generations yet to come.", "From a modest purse to a fortune that outlives its founders.", "A family whose voices reach beyond the village, into the halls of power."], "objective")
	bonus_page = _page(column, "FamilyStrength")
	host._add_label(bonus_page, "STEP 2 OF 2 · YOUR FAMILY'S STRENGTH", 14, host.TEXT_SUSPECTED)
	host._add_label(bonus_page, "What comes naturally to your family?", 30, host.TEXT_MAIN)
	host._add_label(bonus_page, "Choose a lasting family bonus: a strength the generations share. It helps you pursue the founder's dream, whatever goal you chose.", 18, host.TEXT_MUTED)
	goal_summary = host._add_label(bonus_page, "", 16, host.TEXT_SUSPECTED)
	bonus_buttons = _cards(bonus_page, "PerkCards", legacy.BONUSES, ["A family that welcomes the next generation with open arms.", "Making the most of every coin is a family habit.", "Curiosity and learning run in the family."], "bonus")
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	next = host._add_menu_button(actions, "Continue → family strength", func(): _show_step(1))
	next.name = "NextFocusStep"
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	begin = host._add_menu_button(actions, "Begin family story", func(): host._start_family_story(selected["objective"], selected["bonus"]))
	begin.name = "BeginFamilyStory"
	begin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_buttons.append(host._add_menu_button(actions, "Load saved family", host._load_game))
	footer_buttons.append(host._add_menu_button(actions, "Main menu", host._return_to_main_menu))
	var portraits: Button = host._add_menu_button(actions, "Start with 100 strangers", func(): preload("res://Scripts/StrangerPortraitPreview.gd").start(host))
	portraits.name = "StartStrangerPortraitTest"
	footer_buttons.append(portraits)
	_show_step(0)

func _page(parent: Node, node_name: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = node_name
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 10)
	parent.add_child(page)
	return page

func _cards(parent: Node, node_name: String, entries: Dictionary, flavor: Array, choice: String) -> Array[Button]:
	var row := HBoxContainer.new()
	row.name = node_name
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var buttons: Array[Button] = []
	var images := ["family", "wealth", "influence"]
	for index in entries.size():
		var key: String = entries.keys()[index]
		var button: Button = host._add_focus_card(row, entries[key], flavor[index], images[index], "Choose this goal" if choice == "objective" else "Choose this strength", 164)
		button.set_meta("choice_id", key)
		button.pressed.connect(func(): _select(choice, key))
		buttons.append(button)
	return buttons

func _select(choice: String, key: String) -> void:
	selected[choice] = key
	var buttons := goal_buttons if choice == "objective" else bonus_buttons
	for button in buttons:
		var active: bool = button.get_meta("choice_id") == key
		button.set_pressed_no_signal(active)
		button.text = "Goal selected" if active and choice == "objective" else ("Strength selected" if active else ("Choose this goal" if choice == "objective" else "Choose this strength"))
	next.disabled = selected["objective"].is_empty()
	begin.disabled = selected["objective"].is_empty() or selected["bonus"].is_empty()
	if not selected["objective"].is_empty():
		goal_summary.text = "The founder's dream · " + host.game_clock.state.legacy.OBJECTIVES[selected["objective"]]["name"]

func _show_step(new_step: int) -> void:
	if new_step == 1 and selected["objective"].is_empty():
		return
	step = new_step
	goal_page.visible = step == 0
	bonus_page.visible = step == 1
	back.visible = step == 1
	next.visible = step == 0
	begin.visible = step == 1
	next.disabled = selected["objective"].is_empty()
	begin.disabled = selected["objective"].is_empty() or selected["bonus"].is_empty()
	var controls: Array[Button] = []
	if step == 1: controls.append(back)
	controls.append_array(goal_buttons if step == 0 else bonus_buttons)
	controls.append(next if step == 0 else begin)
	controls.append_array(footer_buttons)
	for index in controls.size():
		controls[index].focus_next = controls[index].get_path_to(controls[(index + 1) % controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[posmod(index - 1, controls.size())])
	(goal_buttons[0] if step == 0 else bonus_buttons[0]).grab_focus()
