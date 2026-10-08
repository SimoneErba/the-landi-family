extends RefCounted
## Authored prototype career rules. Numeric suitability is simulation-only.

var jobs: Dictionary = {}
var programs: Dictionary = {}


func _init() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Data/careers.json"))
	for entry in catalog["jobs"]:
		jobs[entry["id"]] = entry
	for entry in catalog["programs"]:
		programs[entry["id"]] = entry


func education_rank(person) -> int:
	return person.EDUCATION_LEVELS.find(person.education["level"])


func job_assessment(person, job_id: String) -> Dictionary:
	if not jobs.has(job_id):
		return {"eligible": false, "missing": ["Unknown occupation"]}
	var job: Dictionary = jobs[job_id]
	var missing: Array = []
	if not person.alive or person.age < 18:
		missing.append("Adult, living applicant")
	if education_rank(person) < int(job["education_level"]):
		missing.append(person.EDUCATION_LEVELS[int(job["education_level"])].capitalize() + " education")
	if not str(job["qualification"]).is_empty() and job["qualification"] not in person.education["qualifications"]:
		missing.append(str(job["qualification"]).replace("_", " ").capitalize())
	for skill in job["skills"]:
		if person.skills[skill] < float(job["skills"][skill]):
			missing.append(skill.capitalize() + " practice")
	for resource in job["access"]:
		if resource not in person.career_access:
			missing.append("Access to " + str(resource))
	var aptitude := weighted_ability(person, job["abilities"])
	var habits := 0.0
	var weight := 0.0
	for trait_name in job["helpful_traits"]:
		habits += float(person.temperament[trait_name]) * float(job["helpful_traits"][trait_name])
		weight += float(job["helpful_traits"][trait_name])
	return {"eligible": missing.is_empty(), "missing": missing, "aptitude": aptitude, "performance": aptitude * 0.5 + habits / maxf(weight, 1.0) * 50.0, "interest": person.interests[job["interest"]]}


func weighted_ability(person, weights: Dictionary) -> float:
	var total := 0.0
	var count := 0.0
	for key in weights:
		total += float(person.abilities[key]) * float(weights[key])
		count += float(weights[key])
	return total / maxf(count, 0.01)


func program_reason(person, program_id: String) -> String:
	if not programs.has(program_id):
		return "Unknown training program."
	if not person.education["study"].is_empty():
		return "They are already studying."
	var program: Dictionary = programs[program_id]
	if education_rank(person) < int(program["required_level"]):
		return "Needs " + person.EDUCATION_LEVELS[int(program["required_level"])] + " education first."
	if not str(program["qualification"]).is_empty() and program["qualification"] in person.education["qualifications"]:
		return "They already hold this qualification."
	var level: int = person.EDUCATION_LEVELS.find(program["education_level"])
	if str(program["qualification"]).is_empty() and education_rank(person) >= level:
		var complete := true
		for skill in program["skills"]:
			if person.skills[skill] < float(program["skills"][skill]):
				complete = false
		if complete:
			return "They have already mastered this course."
	for skill in program["entry_skills"]:
		if person.skills[skill] < float(program["entry_skills"][skill]):
			return "Needs preparation in " + str(skill) + "."
	return ""


func request_label(action: String) -> String:
	var key := action.get_slice(":", 1)
	if action.begins_with("train:") and programs.has(key):
		return "Ask to study: " + programs[key]["name"]
	if action.begins_with("work:") and jobs.has(key):
		return "Suggest work: " + jobs[key]["name"]
	return "Career request"


func request_reason(state, person, action: String) -> String:
	var key := action.get_slice(":", 1)
	if action.begins_with("train:"):
		var reason := program_reason(person, key)
		if not reason.is_empty():
			return reason
		if not person.in_household:
			return "Family-funded training currently requires living in the house."
		if state.economy.cash_cents < int(programs[key]["monthly_cost_cents"]):
			return "The family cannot afford the first month's fees."
		return ""
	if action.begins_with("work:"):
		if person.career_id == key:
			return "They already do this work."
		if not person.education["study"].is_empty():
			return "Finish the current course before taking full-time work."
		var assessment := job_assessment(person, key)
		return "" if assessment["eligible"] else "Needs: " + ", ".join(assessment["missing"])
	return "Unknown career request."


func willingness(person, action: String) -> float:
	var key := action.get_slice(":", 1)
	var entry: Dictionary = programs[key] if action.begins_with("train:") else jobs[key]
	var score := float(person.interests[entry["interest"]]) / 100.0 * 0.45
	score += float(person.values["achievement"]) * 0.2 + float(person.temperament["openness"]) * 0.1
	score -= float(person.current_state.get("stress", 0.0)) * 0.15
	if action.begins_with("train:"):
		score -= float(person.values["security"]) * 0.1
	else:
		score += float(person.values["wealth"]) * 0.1
		score -= float(person.values["security"]) * (0.15 if not person.career_id.is_empty() else 0.05)
	return score - 0.1


func apply_request(person, action: String) -> void:
	var key := action.get_slice(":", 1)
	if action.begins_with("train:"):
		person.education["study"] = {"program_id": key, "progress": 0.0, "status": "Studying", "monthly_cost_cents": int(programs[key]["monthly_cost_cents"])}
		# Full-time training sacrifices earnings, so an education choice has a cost.
		person.job = "Student — " + programs[key]["name"]
		person.career_id = ""
		person.monthly_income_cents = 0
	else:
		person.career_id = key
		person.job = jobs[key]["name"]
		person.monthly_income_cents = int(jobs[key]["monthly_income_cents"])


func monthly_cost(person) -> int:
	var study: Dictionary = person.education["study"]
	if not person.alive or not person.in_household or study.is_empty():
		return 0
	return int(programs.get(study.get("program_id"), {}).get("monthly_cost_cents", 0))


func advance_month(state, person) -> void:
	var study: Dictionary = person.education["study"]
	if not person.alive or study.is_empty() or not programs.has(study.get("program_id")):
		return
	if not person.in_household or not bool(state.economy.ledger[-1].get("training_funded", false)):
		study["status"] = "Paused — needs household funding"
		return
	var program: Dictionary = programs[study["program_id"]]
	study["status"] = "Studying"
	# Aptitude speeds learning; discipline can offset slower learning.
	var rate := 0.45 + weighted_ability(person, program["abilities"]) / 100.0 * 0.65 + float(person.temperament["conscientiousness"]) * 0.5
	rate *= 1.0 - float(person.current_state.get("stress", 0.0)) * 0.3
	var remaining := maxf(0.0, float(program["months"]) - float(study["progress"]))
	var step := minf(rate, remaining)
	for skill in program["skills"]:
		# Close a proportion of the remaining gap so completion meets every target.
		var gap := maxf(0.0, float(program["skills"][skill]) - float(person.skills[skill]))
		person.skills[skill] = clampf(float(person.skills[skill]) + gap * step / maxf(remaining, 0.01), 0.0, 100.0)
	study["progress"] = minf(float(program["months"]), float(study["progress"]) + step)
	if float(study["progress"]) < float(program["months"]):
		return
	var rank: int = person.EDUCATION_LEVELS.find(program["education_level"])
	if rank > education_rank(person):
		person.education["level"] = program["education_level"]
	if not str(program["qualification"]).is_empty() and program["qualification"] not in person.education["qualifications"]:
		person.education["qualifications"].append(program["qualification"])
	person.education["study"] = {}
	person.job = "Seeking work"
	var description: String = person.name + " completed " + program["name"] + "."
	person.memories.append({"kind": "education", "date": state.date_text(), "description": description})
	state.chronicle.append({"date": state.date_text(), "description": description})
	state.major_event = true
	state.events.queue_milestone(state, "graduation", person.id, {"course": program["name"]})
	var known: Dictionary = person.career_knowledge.get(state.head_id, {"abilities": [], "skills": [], "interests": []})
	for skill in program["skills"]:
		if skill not in known.get("skills", []):
			known["skills"].append(skill)
	person.career_knowledge[state.head_id] = known
	if person.knowledge.has(state.head_id):
		person.knowledge[state.head_id]["evidence"].append(state.date_text() + " — " + description)
