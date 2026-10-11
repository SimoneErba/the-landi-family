extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _button(parent, text: String):
	for button in parent.find_children("*", "Button", true, false):
		if button.text == text: return button
	return null
func _run() -> void:
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous", "fertility")
	screen._show_person("Carlo")
	assert(screen.details_content.get_node_or_null("ProfileSections") == null)
	var content = screen.details_content.get_node("ProfileViewport/ProfileScroll/ProfileSectionContent")
	for category in ["Overview", "Personality", "Values", "Skills", "Background", "Requests", "Activities", "Marriage", "History"]:
		assert(content.get_node_or_null(category) != null, "Every category is present without selecting a section")
	assert(_button(content, "Education & careers") != null)
	assert(_button(content, "Ask to take part") != null)
	var observed = screen.game_clock.state.people["Carlo"].view_for(screen.game_clock.state.head_id)
	var labels = content.get_node("Personality").find_children("*", "Label", true, false)
	for entry in observed["temperament"]["known"]:
		assert(labels.any(func(label): return label.text == entry))
	assert(content.get_node("Personality").find_children("*", "ProgressBar", true, false).is_empty(), "Private psychology is never exposed as a numeric score")
	assert(content.get_node("Skills").find_children("*", "ProgressBar", true, false).size() > 0)
	screen._show_person("Giovanni")
	screen._open_person_activity("repair")
	_button(screen.details_content, "Begin activity").pressed.emit()
	assert(screen.game_clock.state.activities.commitment("Giovanni") != null)
	assert(_button(screen.details_content, "Cancel activity") != null)
	assert(_button(screen.details_content, "Begin activity") == null)
	var tasks = screen.details_content.find_child("CurrentTasks", true, false)
	assert(tasks != null and tasks.find_children("*", "ProgressBar", true, false).size() == 1)
	assert(tasks.find_children("*", "ProgressBar", true, false)[0].value == 0)
	_button(screen.details_content, "Cancel activity").pressed.emit()
	assert(screen.game_clock.state.activities.commitment("Giovanni") == null)
	var state = screen.game_clock.state
	var person = state.people["Carlo"]
	person.interests["academic"] = 100
	person.values["family_loyalty"] = 1
	person.current_state["resentment"] = 0
	person.current_state["stress"] = 0
	person.learned_tendencies["need_for_autonomy"] = 0
	screen._show_person("Carlo")
	screen._open_person_activity("study")
	_button(screen.details_content, "Ask to take part").pressed.emit()
	assert(state.activities.commitment("Carlo") != null and state.activities.commitment("Giovanni") == null)
	await process_frame
	await process_frame
	var bounds = screen.details_popup.get_rect()
	var scroll: ScrollContainer = screen.details_content.get_node("ProfileViewport/ProfileScroll")
	scroll.scroll_vertical = 120
	screen._make_request("Carlo", "stay")
	await process_frame
	await process_frame
	assert(screen.details_popup.get_rect() == bounds)
	assert(screen.details_content.get_node("ProfileViewport/ProfileScroll").scroll_vertical == 120, "Responses preserve reading position")
	assert(screen.details_content.get_node("PersonResponse").visible)
	screen._show_person("Carlo", false)
	await process_frame
	await process_frame
	assert(screen.details_content.get_node("ProfileViewport/ProfileScroll").scroll_vertical == 120)
	# Unknown skills have no bar that could reveal their private score.
	person.career_knowledge[state.head_id] = {}
	screen._show_person("Carlo", false)
	assert(screen.details_content.find_child("Skills", true, false).find_children("*", "ProgressBar", true, false).is_empty())
	screen._show_screen("Village")
	screen._open_person_activity("visit", "bianchi")
	assert(screen.profile_section == "Activities" and screen.gameplay_target_id == "bianchi")
	assert(screen.current_screen == "Village")
	await process_frame
	await process_frame
	scroll = screen.details_content.get_node("ProfileViewport/ProfileScroll")
	assert(scroll.scroll_vertical > 0, "Activity links jump to the relevant controls")
	# The dossier still fits a smaller viewport without growing the panel.
	root.size = Vector2i(800, 600)
	screen._show_person("Carlo")
	await process_frame
	await process_frame
	assert(screen.details_popup.size.x <= screen.get_viewport_rect().size.x and screen.details_popup.size.y <= screen.get_viewport_rect().size.y)
	assert(screen.details_content.get_node("ProfileViewport/ProfileScroll").horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	screen.free()
	print("PASS: unified dossier, observed traits, skill privacy, task progress, person-bound actions, stable scrolling and activity links")
	quit()
