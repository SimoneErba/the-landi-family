extends RefCounted
const Assignment = preload("res://Simulation/Assignment.gd")
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
		var existing: Dictionary = person.education["study"]
		if not existing.get("suspended", false) or existing.get("program_id") != program_id:
			return "They already have a course. Resume it before choosing another."
	var program: Dictionary = programs[program_id]
	if person.age < int(program.get("minimum_age", 0)):
		return "Needs to be at least " + str(program["minimum_age"]) + "."
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
	if action.begins_with("train:") and not state.village.business.commitment(person.id).is_empty():
		return "Release their business responsibility before starting a course."
	if not state.travel.current(person.id).is_empty():
		return "They are away on a journey."
	var key := action.get_slice(":", 1)
	if state.activities.commitment(person.id) != null:
		return "Finish or cancel their family activity first."
	if action.begins_with("train:"):
		var reason := program_reason(person, key)
		if not reason.is_empty():
			return reason
		if not person.in_household:
			return "Family-funded training currently requires living in the house."
		return funding_reason(state, person, key)
	if action.begins_with("work:"):
		if person.career_id == key:
			return "They already do this work."
		if not person.education["study"].is_empty() and not person.education["study"].get("suspended", false):
			return "Finish the current course before taking full-time work."
		var assessment := job_assessment(person, key)
		return "" if assessment["eligible"] else "Needs: " + ", ".join(assessment["missing"])
	return "Unknown career request."


func funding_reason(state, person, program_id: String) -> String:
	# Price the proposed arrangement, including wages, food provision and taxes.
	var prospective = state.Person.from_save_data(person.to_save_data())
	apply_request(prospective, "train:" + program_id)
	var projected_people: Dictionary = state.people.duplicate()
	projected_people[person.id] = prospective
	var budget: Dictionary = state.economy.budget(projected_people, state.household["members"], state.household, state.year, state.month, state.tax_property_assessment())
	var living: int = budget["living_costs_cents"]
	for relative in state.people.values():
		if relative.in_household and not relative.life_state.get("pregnancy", {}).is_empty():
			living += state.economy.purchase_cost(roundi(1050 * state.economy.price_index))
	var deficit := maxi(0, living + int(budget["planned_tuition_cents"]) - int(budget["income_cents"]))
	if int(prospective.education["study"]["monthly_cost_cents"]) == 0 and deficit == 0:
		return "" # A self-funding paid placement needs no invented tuition reserve.
	var duration := maxi(1, ceili(float(programs[program_id]["months"]) - float(prospective.education["study"].get("progress", 0))))
	var required := living * 3 + deficit * duration
	if state.economy.cash_cents < required:
		return "Keep three months of household bills plus the training's expected income shortfall in reserve (" + state.economy.money(required) + ")."
	return ""

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
	person.life_state.erase("job_agreement")
	if action.begins_with("train:"):
		var study: Dictionary = person.education["study"]
		var legacy_contract := not study.is_empty() and not study.has("terms")
		if study.is_empty():
			study = {"program_id": key, "progress": 0.0, "monthly_cost_cents": int(programs[key]["monthly_cost_cents"])}
		study["return_job"] = {"career_id": person.career_id, "job": person.job, "income_cents": person.monthly_income_cents, "food_support_fraction": person.life_state.get("food_support_fraction", 0.0)}
		if not study.has("terms"):
			var program: Dictionary = programs[key]
			study["terms"] = {"mode": program.get("mode", "full_time"), "retained_income_fraction": program.get("retained_income_fraction", 0.0), "stipend_start_cents": int(program.get("stipend_start_cents", 0)), "stipend_end_cents": int(program.get("stipend_end_cents", 0)), "food_support_fraction": program.get("food_support_fraction", 0.0), "monthly_cost_cents": int(program["monthly_cost_cents"]), "tuition_cents": int(program.get("tuition_cents", program["monthly_cost_cents"])), "supplies_cents": int(program.get("supplies_cents", 0)), "duration_months": int(program["months"])}
			if legacy_contract:
				study["terms"].merge({"mode": "full_time", "retained_income_fraction": 0.0, "stipend_start_cents": 0, "stipend_end_cents": 0, "food_support_fraction": 0.0, "monthly_cost_cents": int(study["monthly_cost_cents"]), "tuition_cents": int(study["monthly_cost_cents"]), "supplies_cents": 0}, true)
		study["status"] = "Studying"
		study["suspended"] = false
		study["unfunded_months"] = 0
		person.education["study"] = study
		person.job = ("Working apprentice — " if study["terms"]["mode"] == "apprenticeship" else "Student — ") + programs[key]["name"]
		if float(study["terms"]["retained_income_fraction"]) <= 0: person.career_id = ""
		person.monthly_income_cents = contract_income(study)
	else:
		person.career_id = key
		person.job = jobs[key]["name"]
		person.monthly_income_cents = int(jobs[key]["monthly_income_cents"])
		person.life_state["food_support_fraction"] = float(jobs[key].get("food_support_fraction", 0.0))


func projected_training_income(person, program_id: String) -> int:
	var program: Dictionary = programs[program_id]
	var study: Dictionary = person.education["study"]
	if study.get("program_id") == program_id and study.has("terms"):
		var projection := study.duplicate(true)
		projection["return_job"] = {"income_cents": person.monthly_income_cents, "food_support_fraction": person.life_state.get("food_support_fraction", 0.0)}
		return contract_income(projection)
	return roundi(person.monthly_income_cents * float(program.get("retained_income_fraction", 0.0))) + int(int(program.get("stipend_start_cents", 0)))


static func contract_income(study: Dictionary) -> int:
	var terms: Dictionary = study.get("terms", {})
	var progress := clampf(float(study.get("progress", 0.0)) / maxf(1.0, float(terms.get("duration_months", 1))), 0.0, 1.0)
	var retained := roundi(int(study.get("return_job", {}).get("income_cents", 0)) * float(terms.get("retained_income_fraction", 0.0)))
	return retained + roundi(lerpf(float(terms.get("stipend_start_cents", 0)), float(terms.get("stipend_end_cents", 0)), progress))


static func restore_work(person, study: Dictionary) -> void:
	var previous: Dictionary = study.get("return_job", {})
	person.career_id = previous.get("career_id", "")
	person.monthly_income_cents = int(previous.get("income_cents", 0))
	person.job = previous.get("job", "Seeking work") if person.monthly_income_cents > 0 else "Seeking work"
	person.life_state["food_support_fraction"] = previous.get("food_support_fraction", 0.0)


static func valid_terms(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.get("mode") not in ["full_time", "day_lessons", "apprenticeship"]: return false
	for field in ["retained_income_fraction", "food_support_fraction"]:
		if not (value.get(field) is float or value.get(field) is int) or not is_finite(value[field]) or value[field] < 0 or value[field] > 1: return false
	for field in ["stipend_start_cents", "stipend_end_cents", "monthly_cost_cents", "tuition_cents", "supplies_cents", "duration_months"]:
		if not value.get(field) is int or value[field] < 0: return false
	return value["duration_months"] > 0 and value["stipend_end_cents"] >= value["stipend_start_cents"] and value["tuition_cents"] + value["supplies_cents"] == value["monthly_cost_cents"]


static func program_terms_text(economy, program: Dictionary) -> String:
	var description: String = "Tuition / board " + economy.money(economy.purchase_cost(int(int(program.get("tuition_cents", program["monthly_cost_cents"]))))) + " · supplies " + economy.money(economy.purchase_cost(int(int(program.get("supplies_cents", 0))))) + " per month. "
	if program.get("mode") == "apprenticeship":
		description += "Paid placement · " + economy.money(int(program["stipend_start_cents"])) + " rising to " + economy.money(int(program["stipend_end_cents"])) + "/month with progress."
	elif float(program.get("retained_income_fraction", 0.0)) > 0:
		description += "Lessons retain %d%% of previous paid work." % roundi(float(program["retained_income_fraction"]) * 100)
	else: description += "Full-time study replaces paid work."
	if float(program.get("food_support_fraction", 0.0)) > 0: description += " Meals included while board is paid."
	return description


func monthly_cost(person) -> int:
	var study: Dictionary = person.education["study"]
	if not person.alive or not person.in_household or study.is_empty():
		return 0
	return int(study.get("monthly_cost_cents", 0))


func advance_month(state, person) -> void:
	if person.alive and person.in_household and person.monthly_income_cents > 0:
		var work_agreement: Dictionary = person.life_state.get("job_agreement", {})
		if Assignment.abandons(person, work_agreement):
			var ended: String = person.name + " left work as " + person.job + ". The work no longer fits their plans."
			person.career_id = ""
			person.job = "Seeking work"
			person.monthly_income_cents = 0
			person.life_state["food_support_fraction"] = 0.0
			person.life_state.erase("job_agreement")
			person.memories.append({"kind":"career", "date":state.date_text(), "description":ended})
			state.chronicle.append({"date":state.date_text(), "description":ended})
			state.notify(ended, person.id)
		else: Assignment.progress(person, work_agreement)
	var study: Dictionary = person.education["study"]
	if not person.alive or study.is_empty() or not programs.has(study.get("program_id")):
		return
	if study.get("suspended", false):
		study["status"] = "On hold — working or seeking work"
		return
	if not person.in_household or (int(study.get("monthly_cost_cents", 0)) > 0 and not bool(state.economy.ledger[-1].get("training_funded", false))):
		study["status"] = "Paused — needs household funding"
		if person.in_household:
			study["unfunded_months"] = int(study.get("unfunded_months", 0)) + 1
			if study["unfunded_months"] >= 3 and person.age >= 18:
				study["suspended"] = true
				restore_work(person, study)
				var description: String = person.name + " put studies on hold after three unfunded months. Course progress is kept; paid work can resume."
				state.notify(description, person.id)
				state.chronicle.append({"date": state.date_text(), "description": description})
		return
	study["unfunded_months"] = 0
	var program: Dictionary = programs[study["program_id"]]
	if float(study["progress"]) >= 1 and Assignment.abandons(person, study.get("agreement", {})):
		restore_work(person, study)
		person.education["study"] = {}
		var abandoned: String = person.name + " abandoned " + program["name"] + ". No qualification was awarded."
		person.memories.append({"kind":"education", "date":state.date_text(), "description":abandoned})
		state.chronicle.append({"date":state.date_text(), "description":abandoned})
		state.notify(abandoned, person.id)
		return
	study["status"] = "Working apprentice" if study.get("terms", {}).get("mode") == "apprenticeship" else "Studying"
	# Aptitude speeds learning; discipline can offset slower learning.
	var rate := 0.45 + weighted_ability(person, program["abilities"]) / 100.0 * 0.65 + float(person.temperament["conscientiousness"]) * 0.5
	rate *= state.legacy.learning_multiplier() * Assignment.progress(person, study.get("agreement", {}))
	rate *= 1.0 - float(person.current_state.get("stress", 0.0)) * 0.3
	var remaining := maxf(0.0, float(program["months"]) - float(study["progress"]))
	var step := minf(rate, remaining)
	for skill in program["skills"]:
		# Close a proportion of the remaining gap so completion meets every target.
		var gap := maxf(0.0, float(program["skills"][skill]) - float(person.skills[skill]))
		person.skills[skill] = clampf(float(person.skills[skill]) + gap * step / maxf(remaining, 0.01), 0.0, 100.0)
	study["progress"] = minf(float(program["months"]), float(study["progress"]) + step)
	if study.has("terms"): person.monthly_income_cents = contract_income(study)
	if float(study["progress"]) < float(program["months"]):
		return
	var rank: int = person.EDUCATION_LEVELS.find(program["education_level"])
	if rank > education_rank(person):
		person.education["level"] = program["education_level"]
	if not str(program["qualification"]).is_empty() and program["qualification"] not in person.education["qualifications"]:
		person.education["qualifications"].append(program["qualification"])
	person.education["study"] = {}
	person.job = "Seeking work"
	person.career_id = ""
	person.monthly_income_cents = 0
	if float(study.get("terms", {}).get("retained_income_fraction", 0.0)) > 0:
		restore_work(person, study)
	var description: String = person.name + " completed " + program["name"] + "."
	person.memories.append({"kind": "education", "date": state.date_text(), "description": description})
	state.chronicle.append({"date": state.date_text(), "description": description})
	state.notify(description, person.id)
	var known: Dictionary = person.career_knowledge.get(state.head_id, {"abilities": [], "skills": [], "interests": []})
	for skill in program["skills"]:
		if skill not in known.get("skills", []):
			known["skills"].append(skill)
	person.career_knowledge[state.head_id] = known
	if person.knowledge.has(state.head_id):
		person.knowledge[state.head_id]["evidence"].append(state.date_text() + " — " + description)
