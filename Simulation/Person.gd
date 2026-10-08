extends RefCounted
## A person's actual psychology is separate from each observer's understanding.

const LAYERS := ["temperament", "values", "learned_tendencies", "current_state"]
const TRAITS := ["openness", "conscientiousness", "extraversion", "agreeableness", "emotional_stability"]
const VALUES := ["family_loyalty", "independence", "wealth", "status", "achievement", "tradition", "security", "romance"]
const TENDENCIES := ["trust", "need_for_approval", "risk_tolerance", "conflict_avoidance", "jealousy", "forgiveness", "sensitivity_to_rejection", "need_for_autonomy"]
const ABILITIES := ["reasoning", "verbal", "spatial", "memory", "learning_speed"]
const SKILLS := ["literacy", "mathematics", "technical", "commerce", "accounting", "persuasion", "leadership", "empathy", "care", "household", "craft", "agriculture", "cooking", "art", "design", "medicine", "law", "science", "teaching", "music"]
const INTERESTS := ["technical", "commercial", "artistic", "academic", "social", "practical"]
const EDUCATION_LEVELS := ["none", "primary", "secondary", "university", "advanced"]
const PortraitIdentity = preload("res://Simulation/PortraitIdentity.gd")

var id: String
var name: String
var birth_year: int
var birth_month: int
var age: int
var job: String
var monthly_income_cents: int
var branch_id: String
var parent_ids: Array = []
var spouse_id: String
var alive: bool = true
var in_household: bool = true
var health: String = "Well"
var roles: Array = []
var goals: Array = []
var decision_state: Dictionary = {}
var life_state: Dictionary = {}
var temperament: Dictionary = {}
var values: Dictionary = {}
var learned_tendencies: Dictionary = {}
var current_state: Dictionary = {}
var relationships: Dictionary = {}
var memories: Array = []
var knowledge: Dictionary = {}
var education: Dictionary = {}
var abilities: Dictionary = {}
var skills: Dictionary = {}
var interests: Dictionary = {}
var career_access: Array = []
var career_knowledge: Dictionary = {}
var career_id: String = ""
var portrait: RefCounted
var _profile: Dictionary = {}
var _conversation_topics: Array = []
var _last_conversation: Dictionary = {}


func _init(person_id: String, source: Dictionary, year: int, month: int, observer_id: String) -> void:
	id = person_id
	portrait = PortraitIdentity.new(person_id, source.get("portrait", {}))
	_profile = source.duplicate(true)
	name = str(source.get("name", person_id))
	var birth: Dictionary = source.get("birth", {"year": year - int(source.get("age", 0)), "month": month})
	birth_year = int(birth["year"])
	birth_month = clampi(int(birth["month"]), 1, 12)
	job = str(source.get("job", "No paid work"))
	monthly_income_cents = int(source.get("monthly_income_cents", 0))
	branch_id = str(source.get("branch_id", "family"))
	parent_ids = source.get("parent_ids", []).duplicate()
	spouse_id = str(source.get("spouse_id", ""))
	alive = bool(source.get("alive", true))
	health = str(source.get("health", "Well"))
	life_state = source.get("life_state", {}).duplicate(true)
	age = maxi(0, year - birth_year - (1 if month < birth_month else 0))
	roles = source.get("roles", []).duplicate()
	goals = source.get("goals", []).duplicate(true)
	education = source.get("education", {}).duplicate(true)
	if education.get("level", "none") not in EDUCATION_LEVELS:
		education["level"] = "none"
	education["level"] = education.get("level", "none")
	education["qualifications"] = education.get("qualifications", []).duplicate()
	education["study"] = education.get("study", {}).duplicate(true)
	abilities = _scores(source.get("abilities", {}), ABILITIES, 50.0)
	skills = _scores(source.get("skills", {}), SKILLS, 0.0)
	interests = _scores(source.get("interests", {}), INTERESTS, 50.0)
	career_access = source.get("career_access", []).duplicate()
	career_knowledge = source.get("career_knowledge", {}).duplicate(true)
	career_id = str(source.get("career_id", ""))
	var psychology: Dictionary = source.get("psychology", {})
	temperament = psychology.get("temperament", {}).duplicate(true)
	for trait_name in TRAITS:
		temperament[trait_name] = clampf(float(temperament.get(trait_name, 0.5)), 0.0, 1.0)
	values = psychology.get("values", {}).duplicate(true)
	learned_tendencies = psychology.get("learned_tendencies", {}).duplicate(true)
	for key in VALUES:
		values[key] = clampf(float(values.get(key, 0.5)), 0.0, 1.0)
	for key in TENDENCIES:
		learned_tendencies[key] = clampf(float(learned_tendencies.get(key, 0.5)), 0.0, 1.0)
	current_state = psychology.get("current_state", {"stress": 0.2, "happiness": 0.6, "resentment": 0.0}).duplicate(true)
	relationships = source.get("relationships", {}).duplicate(true)
	memories = source.get("memories", []).duplicate(true)
	_conversation_topics = source.get("conversation_topics", []).duplicate(true)
	var understanding: Dictionary = {}
	for layer in LAYERS:
		understanding[layer] = source.get(layer, {"known": [], "suspected": [], "unknown": []}).duplicate(true)
	understanding["evidence"] = source.get("evidence", []).duplicate()
	understanding["experiences"] = source.get("experiences", []).duplicate()
	knowledge[observer_id] = understanding
	update_age(year, month)


func update_age(year: int, month: int) -> void:
	if alive:
		age = maxi(0, year - birth_year - (1 if month < birth_month else 0))


func advance_month(year: int, month: int, financial_pressure: bool) -> void:
	update_age(year, month)
	if not alive:
		return
	# Pressure affects people differently; temperament moderates the response.
	var stress := float(current_state.get("stress", 0.2))
	var change := 0.04 * (1.5 - float(temperament["emotional_stability"])) if financial_pressure and in_household else -0.01
	current_state["stress"] = clampf(stress + change, 0.0, 1.0)
	current_state["happiness"] = clampf(float(current_state.get("happiness", 0.6)) - change * 0.5, 0.0, 1.0)


func view_for(observer_id: String) -> Dictionary:
	var view := {"name": name, "age": age, "relationship": _profile.get("relationship", "Relative"), "summary": decision_state.get("observation", _profile.get("summary", "")), "job": job}
	var understanding: Dictionary = knowledge.get(observer_id, {})
	for layer in LAYERS:
		view[layer] = understanding.get(layer, {"known": [], "suspected": [], "unknown": ["You have not learned enough about this person."]}).duplicate(true)
	view["evidence"] = understanding.get("evidence", []).duplicate()
	view["experiences"] = understanding.get("experiences", []).duplicate()
	view["expressed_goals"] = understanding.get("expressed_goals", []).duplicate()
	view["education"] = education.duplicate(true)
	view["career"] = career_view_for(observer_id)
	return view


static func _scores(source: Dictionary, keys: Array, fallback: float) -> Dictionary:
	var result: Dictionary = {}
	for key in keys:
		result[key] = clampf(float(source.get(key, fallback)), 0.0, 100.0)
	return result


func cognitive_index() -> float:
	# A fictional 0–100 game summary, not a psychometric IQ measurement.
	var total := 0.0
	for value in abilities.values():
		total += float(value)
	return total / ABILITIES.size()


static func ability_band(value: float) -> String:
	if value >= 75.0:
		return "Strong"
	if value >= 50.0:
		return "Developing"
	return "Needs support"


static func skill_band(value: float) -> String:
	if value >= 75.0:
		return "Experienced"
	if value >= 50.0:
		return "Competent"
	if value >= 25.0:
		return "Basic"
	return "Beginner"


func career_view_for(observer_id: String) -> Dictionary:
	var observed: Dictionary = career_knowledge.get(observer_id, {})
	var view := {"abilities": {}, "skills": {}, "interests": {}}
	for key in ABILITIES:
		view["abilities"][key] = ability_band(abilities[key]) if observer_id == id or key in observed.get("abilities", []) else "Unknown"
	for key in SKILLS:
		view["skills"][key] = skill_band(skills[key]) if observer_id == id or key in observed.get("skills", []) else "Unknown"
	for key in INTERESTS:
		view["interests"][key] = ("Keen" if interests[key] >= 70.0 else ("Little interest" if interests[key] < 35.0 else "Some interest")) if observer_id == id or key in observed.get("interests", []) else "Unknown"
	return view


func status_text() -> String:
	if not alive:
		return "Deceased"
	return "%s · %s · %s" % [health, "Living at home" if in_household else "Living elsewhere", job]


func experience_event(kind: String, description: String, date: String, participants: Array, severity: float) -> void:
	memories.append({"kind": kind, "description": description, "date": date, "participants": participants.duplicate()})
	# Experiences act through temperament, age, values, and existing relationships.
	var attachment := 0.0
	for participant in participants:
		var bond: Dictionary = relationships.get(participant, {})
		attachment = maxf(attachment, float(bond.get("affection", 0.0)) * float(bond.get("trust", 0.5)))
	var vulnerability := (1.0 - float(temperament["emotional_stability"])) * (1.25 if age < 18 else 1.0)
	var impact := clampf(severity, 0.0, 1.0) * (0.25 + vulnerability + attachment * 0.5)
	current_state["stress"] = clampf(float(current_state.get("stress", 0.2)) + impact * 0.2, 0.0, 1.0)
	current_state["happiness"] = clampf(float(current_state.get("happiness", 0.6)) - impact * 0.1, 0.0, 1.0)
	if kind == "financial_crisis":
		values["security"] = clampf(float(values["security"]) + impact * 0.03, 0.0, 1.0)
		learned_tendencies["risk_tolerance"] = clampf(float(learned_tendencies["risk_tolerance"]) - impact * 0.02, 0.0, 1.0)


func converse(observer_id: String, month_index: int, date: String) -> String:
	if not alive or not in_household:
		return "They are not here to talk."
	if int(_last_conversation.get(observer_id, -1)) == month_index:
		return "You have already had a conversation this month. Give them some time."
	_last_conversation[observer_id] = month_index
	if not knowledge.has(observer_id):
		var empty: Dictionary = {}
		for layer in LAYERS:
			empty[layer] = {"known": [], "suspected": [], "unknown": []}
		empty["evidence"] = []
		empty["experiences"] = []
		knowledge[observer_id] = empty
	var understanding: Dictionary = knowledge[observer_id]
	for topic in _conversation_topics:
		var layer: Dictionary = understanding[topic["layer"]]
		if topic["finding"] in layer["known"]:
			continue
		layer["known"].append(topic["finding"])
		layer["suspected"].erase(topic.get("replaces", ""))
		layer["unknown"].erase(topic.get("replaces", ""))
		understanding["evidence"].append(date + " — " + str(topic["evidence"]))
		memories.append({"date": date, "kind": "conversation", "person_id": observer_id, "description": topic["evidence"]})
		return str(topic["response"])
	var expressed: Array = understanding.get("expressed_goals", [])
	for goal in goals:
		if goal.get("status") != "active" or str(goal["description"]) in expressed:
			continue
		expressed.append(str(goal["description"]))
		understanding["expressed_goals"] = expressed
		var response: String = "What I want is to " + str(goal["description"]).to_lower() + "."
		understanding["evidence"].append(date + " — " + response)
		memories.append({"date": date, "kind": "conversation", "person_id": observer_id, "description": response})
		return response
	return "You spend some time together. No new concern comes up today."


# Include private observer history: loading must not reset conversations or beliefs.
const SAVE_FIELDS := ["id", "name", "birth_year", "birth_month", "age", "job", "monthly_income_cents", "branch_id", "parent_ids", "spouse_id", "alive", "in_household", "health", "roles", "goals", "decision_state", "life_state", "temperament", "values", "learned_tendencies", "current_state", "relationships", "memories", "knowledge", "education", "abilities", "skills", "interests", "career_access", "career_knowledge", "career_id", "_profile", "_conversation_topics", "_last_conversation"]


func to_save_data() -> Dictionary:
	var data: Dictionary = {}
	for field in SAVE_FIELDS:
		var value: Variant = get(field)
		data[field] = value.duplicate(true) if value is Dictionary or value is Array else value
	data["portrait"] = portrait.to_data()
	return data


static func from_save_data(data: Dictionary) -> RefCounted:
	var person = load("res://Simulation/Person.gd").new(data["id"], {}, 1800, 1, "")
	for field in SAVE_FIELDS:
		person.set(field, data.get(field, {}) if field in ["decision_state", "life_state"] else data[field])
	person.portrait = PortraitIdentity.new(data["id"], data["portrait"])
	return person
