extends RefCounted
const SYMBOLS := {"enthusiastic": "★", "willing": "✓", "reluctant": "!", "refused": "×", "unavailable": "!"}

static func remember(host, result: Dictionary, person_id: String, context: String) -> void:
	host.assignment_feedback[person_id + ":" + context] = {"response": result.get("action_response", "unavailable"), "dialogue": result["response"], "accepted": result.get("accepted", result.get("ok", false)), "activity_id": result.get("activity_id", ""), "created_msec": Time.get_ticks_msec()}

static func build(host, parent: Node, person_id: String, context: String) -> void:
	var reaction: Dictionary = host.assignment_feedback.get(person_id + ":" + context, {})
	if reaction.is_empty(): return
	var state: String = reaction["response"]
	var color: Color = {"enthusiastic": host.TEXT_KNOWN, "willing": host.TEXT_MAIN, "reluctant": host.TEXT_SUSPECTED, "refused": Color("#9b4033"), "unavailable": host.TEXT_MUTED}[state]
	var panel := PanelContainer.new()
	panel.name = "AssignmentReaction"
	panel.add_theme_stylebox_override("panel", host.Archive.card())
	parent.add_child(panel)
	var text: Label = host._add_label(panel, "", 16, color)
	var status := "Accepted; outcome pending" if reaction["accepted"] else "No action started"
	var simulation = host.game_clock.state
	var id: String = reaction["activity_id"]
	if reaction["accepted"]:
		if simulation.activities.plans.has(id): status = simulation.activities.plans[id].status.capitalize()
		elif simulation.travel.journeys.has(id): status = simulation.travel.journeys[id]["status"].capitalize()
		elif context.begins_with("train:") and simulation.people[person_id].education["study"].get("program_id") != context.get_slice(":", 1): status = "Assignment ended · see journal"
		elif context == "business" and simulation.village.business.commitment(person_id) != id: status = "Responsibility ended"
	var compact: String = SYMBOLS[state] + " " + state.capitalize() + " · " + status
	var remaining := maxf(0, 6.0 - (Time.get_ticks_msec() - int(reaction["created_msec"])) / 1000.0)
	text.text = compact + ("\n“" + str(reaction["dialogue"]) + "”" if remaining > 0 else "")
	if remaining > 0:
		host.get_tree().create_timer(remaining).timeout.connect(func():
			if is_instance_valid(text): text.text = compact)
