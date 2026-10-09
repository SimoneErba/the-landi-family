extends SceneTree
const Runner = preload("res://Simulation/Testing/SimulationRunner.gd")
const Report = preload("res://Simulation/Testing/SimulationReport.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var config: Dictionary = Runner.DEFAULTS.duplicate(true)
	config["years"] = 2
	config["seeds"] = 1
	assert(Runner.validate(config).is_empty())
	var invalid: Dictionary = config.duplicate(true)
	invalid["years"] = 0
	assert(not Runner.validate(invalid).is_empty())
	invalid = config.duplicate(true)
	invalid["strategies"] = ["enterprise","enterprise"]
	assert(not Runner.validate(invalid).is_empty())
	assert(Runner.run_one(config,"unknown",1)["status"] == "invalid")
	var first: Dictionary = Runner.run_one(config,"enterprise",7)
	var second: Dictionary = Runner.run_one(config,"enterprise",7)
	assert(first == second, "Same input and seed reproduces every decision and yearly checkpoint")
	assert(first["status"] == "completed" and first["months_simulated"] == 24)
	assert(first["checkpoints"].size() == 3 and first["checkpoints"][0]["month"] == 0 and first["checkpoints"][2]["month"] == 24)
	assert(first["decisions"].get("construction",0) > 0 and first["decisions"].get("land",0) > 0, "Enterprise policy actually buys land and pays for construction")
	assert(first["final"]["family_businesses"] > 0 and first["decisions"].get("manager",0) > 0, "Managers are requested after the construction completes")
	assert(first["last_100_decisions"].size() <= 100)
	var passive: Dictionary = Runner.run_one(config,"passive",7)
	assert(passive["decisions"].get("request",0) == 0 and passive["decisions"].get("construction",0) == 0)
	var state = Runner.State.new()
	state.initialize(JSON.parse_string(FileAccess.get_file_as_string("res://Data/people.json")))
	var player = Runner.Player.new("family")
	var person = state.people["Carlo"]
	person.values["independence"] = 1.0
	person.values["family_loyalty"] = 0.0
	person.current_state["resentment"] = 1.0
	person.relationships[state.head_id] = {"affection":0.0,"trust":0.0,"respect":0.0,"resentment":1.0}
	assert(player._request(state,"Carlo","stay"))
	assert(player.counts["outcome:refused"] == 1 and person.decision_state.get("stay_until",0) == 0, "Bot respects refusal")
	assert(not player._request(state,"Carlo","stay"), "Repeated proposals obey the cooldown")
	state.economy.cash_cents = 0
	state.events.pending = [{"id":"blocked","serial":999,"person_id":"Carlo","choices":[{"label":"Unaffordable","effects":{"cash":-1000000}}]}]
	assert(not player.resolve_events(state).is_empty() and state.events.pending.size() == 1, "Impossible event choices are reported, never skipped")
	var batch: Dictionary = Report.create_batch(config)
	batch["runs"] = [first,passive]
	batch["summary"] = Runner.summarize(batch["runs"])
	assert(batch["summary"]["enterprise"]["metrics"]["family_businesses"]["median"] == first["final"]["family_businesses"])
	assert(Report.annual_csv(batch).split("\n",false).size() == 7)
	assert("Enterprise" in Report.markdown(batch))
	assert(Report.write(batch,"res://.godot/simulation-report-test").is_empty())
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/simulation-report-test/results.json"))
	assert(saved["runs"].size() == 2 and saved["source_sha256"].size() > 10)
	print("PASS: isolated deterministic runs, real player actions and refusals, event stalls, yearly checkpoints, aggregation and report exports")
	quit()
