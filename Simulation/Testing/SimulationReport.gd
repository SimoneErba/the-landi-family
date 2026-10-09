extends RefCounted
const Runner = preload("res://Simulation/Testing/SimulationRunner.gd")
static func create_batch(config: Dictionary) -> Dictionary:
	var hashes: Dictionary = {}
	for path in ["Data/people.json","Data/careers.json","Data/events.json","Simulation/GameState.gd","Simulation/Economy.gd","Simulation/Person.gd","Simulation/Careers.gd","Simulation/Influence.gd","Simulation/EventSystem.gd","Simulation/DecisionSystem.gd","Simulation/Legacy.gd","Simulation/Travel.gd","Simulation/Activities/ActivitySystem.gd","Simulation/Village/VillageState.gd","Simulation/Village/VillageBusiness.gd","Simulation/Village/VillageDevelopment.gd","Simulation/Testing/SimulatedPlayer.gd","Simulation/Testing/SimulationRunner.gd"]:
		hashes[path] = FileAccess.get_file_as_string("res://"+path).sha256_text()
	return {"format_version":1,"generated_utc":Time.get_datetime_string_from_system(true),"config":config.duplicate(true),"source_sha256":hashes,"completed":false,"runs":[],"summary":{},"limitations":["Policies use eligibility rules to choose proposals; they are scripted test players, not a model of human knowledge or optimal play.","All policies share the configured bonus, objective and seed list; different actions can cause random streams to diverge.","The runner resolves pauses through legal event choices and records pause months. Debt continues as unpaid bills; it does not fabricate a recovery.","Marriage requests currently create goals, and mortality/succession remain incomplete. Century results do not certify a complete generational game."]}

static func write(batch: Dictionary, output: String) -> String:
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	if error != OK:
		return "Could not create report directory: "+error_string(error)
	var files := {"results.json":JSON.stringify(batch,"  "),"summary.md":markdown(batch),"annual.csv":annual_csv(batch)}
	for name in files:
		var file = FileAccess.open(output.path_join(name),FileAccess.WRITE)
		if file == null:
			return "Could not write "+name+": "+error_string(FileAccess.get_open_error())
		file.store_string(files[name])
	return ""

static func markdown(batch: Dictionary) -> String:
	var config: Dictionary = batch["config"]
	var lines: Array[String] = ["# Century simulation results","","Generated (UTC): "+batch["generated_utc"],"","%d years per run; %d seeds per strategy, beginning at %d. Common bonus: **%s**. Selected objective: **%s**." % [config["years"],config["seeds"],config["seed_start"],config["bonus"],config["objective"]],"","Batch status: "+("complete" if batch["completed"] else "in progress")+". Reported values are medians, except counts. Money is Italian-lira equivalent for comparison across currency reforms.","","| Strategy | Runs completed | Cash (Italian lire) | Living | Graduates | Influential | Businesses | Stress | Debt runs | Objective wins |","| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
	for strategy in batch["summary"]:
		var row: Dictionary = batch["summary"][strategy]
		var m: Dictionary = row["metrics"]
		lines.append("| %s | %d/%d | %.0f | %.0f | %.0f | %.0f | %.0f | %.2f | %d | %d |" % [strategy,row["completed_runs"],row["runs"],m["cash_italian_lire"]["median"],m["living"]["median"],m["graduates"]["median"],m["influential"]["median"],m["family_businesses"]["median"],m["stress"]["median"],row["runs_with_debt"],row["objective_wins"]])
	lines.append_array(["","## Player strategies","","- Passive: first legal event choice; no proactive requests.","- Frugal: favor money and health/property recovery; suggest better eligible employment.","- Education: fund sustainable courses and better jobs; favor learning and supportive event choices.","- Enterprise: preserve six months of household bills; buy land, build up to three businesses, request managers and renovate.","- Family: support relationships, ask departing relatives to stay or return, request marriage and expand overcrowded housing.","","All requests can be refused. Proactive decisions happen quarterly; repeated requests wait two years. Construction and courses pay real costs. No relatives, spouses, qualifications or money are created by the test player.","","## Individual runs","","| Strategy | Seed | Status | Months | Cash | Peak living | Births | First debt month | Requests | Managers asked | Marriage goals remaining |","| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"])
	for run in batch["runs"]:
		var f: Dictionary = run["final"]
		lines.append("| %s | %d | %s | %d | %.0f | %d | %d | %s | %d | %d | %d |" % [run["strategy"],run["seed"],run["status"],run["months_simulated"],f["cash_italian_lire"],run["peak_living"],f["births"],str(run["first_debt_month"]) if run["first_debt_month"] >= 0 else "none",run["decisions"].get("request",0),run["decisions"].get("manager",0),f["unfulfilled_marriage_goals"]])
	lines.append_array(["","## Interpretation limits",""])
	for limitation in batch["limitations"]:
		lines.append("- "+limitation)
	var warnings: Dictionary = {}
	for run in batch["runs"]:
		for warning in run["warnings"]:
			warnings[warning] = true
		if run["status"] != "completed":
			warnings[run["strategy"]+" seed "+str(run["seed"])+": "+run["error"]] = true
	for warning in warnings:
		lines.append("- "+warning)
	lines.append_array(["","[Full results and decision samples](results.json) · [Yearly checkpoints (CSV)](annual.csv)",""])
	return "\n".join(lines)

static func annual_csv(batch: Dictionary) -> String:
	var fields: Array[String] = ["month","year","cash_italian_lire","real_cash_starting_lire","living","residents","births","graduates","influential","stress","resentment","house_condition","house_capacity","family_properties","family_businesses","village_buildings","living_over_100","unfulfilled_marriage_goals","wealth_fraction","population_fraction"]
	var lines: Array[String] = ["strategy,seed,"+",".join(fields)]
	for run in batch["runs"]:
		for point in run["checkpoints"]:
			var values: Array[String] = [run["strategy"],str(run["seed"])]
			for field in fields:
				values.append(str(point[field]))
			lines.append(",".join(values))
	return "\n".join(lines)+"\n"
