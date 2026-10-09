extends SceneTree
const Runner = preload("res://Simulation/Testing/SimulationRunner.gd")
const Report = preload("res://Simulation/Testing/SimulationReport.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var config: Dictionary = Runner.DEFAULTS.duplicate(true)
	var output := "res://Reports/Simulations/latest"
	for argument in OS.get_cmdline_user_args():
		var key: String = argument.get_slice("=",0).trim_prefix("--").replace("-","_")
		var value: String = argument.substr(argument.find("=")+1)
		if not argument.begins_with("--") or not argument.contains("="):
			_fail("Use --name=value arguments.")
			return
		if key == "output":
			output = value
		elif key in ["years","seeds","seed_start"]:
			if not value.is_valid_int():
				_fail(key+" must be an integer.")
				return
			config[key] = value.to_int()
		elif key == "strategies":
			config[key] = Array(value.split(",",false))
		elif key in ["bonus","objective"]:
			config[key] = value
		else:
			_fail("Unknown option: "+key)
			return
	var error: String = Runner.validate(config)
	if not error.is_empty():
		_fail(error)
		return
	if not output.begins_with("res://Reports/Simulations/") or ".." in output or "\\" in output:
		_fail("Output must be a directory under res://Reports/Simulations/.")
		return
	var batch: Dictionary = Report.create_batch(config)
	print("SIMULATION: %d strategies × %d seeds × %d years; common bonus %s" % [config["strategies"].size(),config["seeds"],config["years"],config["bonus"]])
	for strategy in config["strategies"]:
		for seed in range(config["seed_start"],config["seed_start"]+config["seeds"]):
			var result: Dictionary = Runner.run_one(config,strategy,seed)
			batch["runs"].append(result)
			batch["summary"] = Runner.summarize(batch["runs"])
			batch["completed"] = batch["runs"].size() == config["strategies"].size()*config["seeds"]
			error = Report.write(batch,output)
			if not error.is_empty():
				_fail(error)
				return
			print("RUN: %s seed %d · %s · %d months · %.0f Italian lire · %d living · %d graduates · %d businesses" % [strategy,seed,result["status"],result["months_simulated"],result["final"]["cash_italian_lire"],result["final"]["living"],result["final"]["graduates"],result["final"]["family_businesses"]])
			await process_frame
	print("PASS: batch reports saved to "+output)
	quit()
func _fail(error: String) -> void:
	push_error(error)
	quit(1)
