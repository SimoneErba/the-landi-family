extends RefCounted
## Public run objectives; bonuses never bypass a relative's consent.

const OBJECTIVES := {
	"populous": {"name": "Populous family", "description": "Have 100 living family members, including relatives living elsewhere."},
	"wealth": {"name": "Family fortune", "description": "Reach 1,000,000 Italian lire in the shared purse (equivalent value before currency reforms)."},
	"influence": {"name": "An influential family", "description": "Have a living member in a senior career with competent leadership and persuasion skills. Eligible careers: business manager, entrepreneur, lawyer, doctor, scientist or journalist."},
}
const BONUSES := {
	"fertility": {"name": "Fertility", "description": "Fertility +25%. Eligible couples are more likely to have pregnancy events. Age, spouse and recovery requirements still apply."},
	"discount": {"name": "Thrifty family", "description": "10% discount on food, tuition and event purchases."},
	"learning": {"name": "Quick learners", "description": "+25% learning progress in courses, practice and event skill gains."},
}
const INFLUENTIAL_CAREERS := ["manager", "entrepreneur", "lawyer", "doctor", "researcher", "journalist"]
const WEALTH_TARGET := 100000000.0 / 0.84

var objective_id: String = ""
var bonus_id: String = ""
var completed: bool = false


func choose(objective: String, bonus: String) -> bool:
	if not objective_id.is_empty() or not OBJECTIVES.has(objective) or not BONUSES.has(bonus):
		return false
	objective_id = objective
	bonus_id = bonus
	return true


func learning_multiplier() -> float:
	return 1.25 if bonus_id == "learning" else 1.0


func fertility_multiplier() -> float:
	return 1.25 if bonus_id == "fertility" else 1.0


func price_multiplier() -> float:
	return 0.9 if bonus_id == "discount" else 1.0


func progress(state) -> Dictionary:
	var living := 0
	var influential := 0
	for person in state.people.values():
		if not person.alive:
			continue
		living += 1
		if person.career_id in INFLUENTIAL_CAREERS and person.skills["leadership"] >= 50 and person.skills["persuasion"] >= 50:
			influential += 1
	match objective_id:
		"populous": return {"value": living, "target": 100.0, "text": "%d / 100 living family members" % living}
		"wealth": return {"value": state.economy.cash_cents, "target": WEALTH_TARGET, "text": "Shared purse: %s\nTarget in current currency: %s" % [state.economy.money(state.economy.cash_cents), state.economy.money(ceili(WEALTH_TARGET))]}
		"influence": return {"value": influential, "target": 1.0, "text": "%d / 1 highly influential family members" % influential}
	return {"value": 0, "target": 1.0, "text": "Choose a starting objective."}


func evaluate(state) -> void:
	if objective_id.is_empty() or completed:
		return
	var current := progress(state)
	if float(current["value"]) < float(current["target"]):
		return
	completed = true
	state.major_event = true
	state.chronicle.append({"date": state.date_text(), "description": "Family objective achieved: " + OBJECTIVES[objective_id]["name"] + "."})


func to_save_data() -> Dictionary:
	return {"objective_id": objective_id, "bonus_id": bonus_id, "completed": completed}


func restore_save_data(data: Dictionary) -> void:
	objective_id = data.get("objective_id", "")
	bonus_id = data.get("bonus_id", "")
	completed = data.get("completed", false)
