extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920,1080)
	var screen = load("res://Scenes/FamilyScreen.tscn").instantiate()
	root.add_child(screen)
	screen._start_family_story("populous","fertility")
	var state = screen.game_clock.state
	state.economy.cash_cents = 100000
	var dev = state.village.development
	var plot: String = dev.buildings["farm"]["parcel_id"]
	var negotiation = preload("res://Simulation/Village/PropertyNegotiation.gd")
	negotiation.propose(state,plot,negotiation.valuation(state,plot))
	screen._refresh_time_controls()
	screen._show_screen("Village")
	screen.village_view.map.parcel_selected.emit(plot)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.godot/property-offer-preview.png") == OK)
	quit()
