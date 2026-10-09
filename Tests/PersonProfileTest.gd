extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _button(parent, text: String):
	for button in parent.find_children("*","Button",true,false):
		if button.text == text:
			return button
	return null
func _run() -> void:
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	assert(_button(screen.get_node("Navigation"),"Projects") == null)
	screen._show_person("Carlo")
	assert(not screen.profile_expanded)
	assert(screen.details_content.get_node_or_null("ProfileSections") == null)
	assert(_button(screen.details_content,"Education & careers") == null)
	_button(screen.details_content,"Show more").pressed.emit()
	assert(screen.profile_expanded and screen.details_content.get_node_or_null("ProfileSections") != null)
	assert(_button(screen.details_content,"Ask to take part") != null)
	_button(screen.details_content,"Personality").pressed.emit()
	assert(screen.profile_section == "Personality")
	_button(screen.details_content,"Background").pressed.emit()
	assert(_button(screen.details_content,"Education & careers") != null)
	_button(screen.details_content,"Show less").pressed.emit()
	assert(not screen.profile_expanded)
	assert(screen.details_content.get_node_or_null("ProfileSectionContent") == null)
	screen._show_person("Giovanni")
	assert(not screen.profile_expanded, "Different people start with essential information")
	screen._open_person_activity("repair")
	assert(screen.selected_person_id == "Giovanni")
	_button(screen.details_content,"Begin activity").pressed.emit()
	assert(screen.game_clock.state.activities.commitment("Giovanni") != null)
	assert(_button(screen.details_content,"Cancel activity") != null)
	assert(_button(screen.details_content,"Begin activity") == null, "One commitment is enforced through the profile")
	_button(screen.details_content,"Cancel activity").pressed.emit()
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
	_button(screen.details_content,"Ask to take part").pressed.emit()
	assert(state.activities.commitment("Carlo") != null and state.activities.commitment("Giovanni") == null, "Profile requests bind to the selected person")
	screen._show_screen("Village")
	screen._open_person_activity("visit","bianchi")
	assert(screen.profile_section == "Activities" and screen.gameplay_target_id == "bianchi")
	assert(screen.current_screen == "Village", "Village activity links open a profile without changing pages")
	screen.free()
	print("PASS: compact profile, optional sections, removed activity navigation, person-bound requests, progress, cancellation and village links")
	quit()
