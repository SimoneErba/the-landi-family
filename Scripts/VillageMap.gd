extends Control
## Fixed geography and persistent structure nodes; drag with middle/right mouse, wheel to zoom.
signal place_selected(place_id: String)
signal building_selected(building_id: String)
signal parcel_selected(parcel_id: String)
const MAP_LETTERING = preload("res://Assets/UI/Fonts/ArchiveSerif-Italic.ttf")
const Development = preload("res://Simulation/Village/VillageDevelopment.gd")
const LANDMARKS := {"home": "Landi House", "church": "Church", "tavern": "Tavern", "market": "Market square", "school": "School", "farm": "Farm", "workshop": "Workshop", "town_hall": "Town hall"}
var development = null
var influence: Dictionary = {}
var map_texture: ImageTexture
var buttons: Dictionary = {}
var building_nodes: Dictionary = {}
var textures: Dictionary = {}
var world: Control
var overlay_mode := "Places"
var selected_id := ""
var replay_month := -1
var zoom := 1.0
var pan := Vector2.ZERO
var dragging := false
var view: Dictionary = {}
var seen_revision := -1

func _ready() -> void:
	custom_minimum_size = Vector2(650, 530)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if development == null:
		development = Development.new()
		development.initialize()
	var image := Image.new()
	if FileAccess.file_exists("res://Assets/Maps/village-terrain-1800.png"):
		image = Image.load_from_file("res://Assets/Maps/village-terrain-1800.png")
	else:
		image.load_svg_from_string(FileAccess.get_file_as_string("res://Assets/Maps/village-terrain.svg"), 2.0)
	map_texture = ImageTexture.create_from_image(image)
	world = Control.new()
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.size = Vector2(1100,650)
	add_child(world)
	resized.connect(_place_world)
	refresh(true)

func _map_rect() -> Rect2:
	var dimensions := Vector2(1100, 650) * minf(size.x / 1100.0, size.y / 650.0) * zoom
	return Rect2((size - dimensions) / 2 + pan, dimensions)

func _place_world() -> void:
	if world == null:
		return
	var rect := _map_rect()
	world.position = rect.position
	world.scale = rect.size / Vector2(1100,650)
	queue_redraw()

func reset_view() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	_place_world()

func set_replay(month: int) -> void:
	replay_month = month
	refresh(true)

func _sprite(type: String, variant: int) -> ImageTexture:
	var engraving := "res://Assets/Maps/Buildings/" + type + "-engraving.png"
	var key := type + "-engraving" if FileAccess.file_exists(engraving) else type + "-" + str(variant)
	if not textures.has(key):
		var image := Image.new()
		if FileAccess.file_exists(engraving):
			image = Image.load_from_file(engraving)
		else:
			image.load_svg_from_string(FileAccess.get_file_as_string("res://Assets/Maps/Buildings/" + key + ".svg"), 2.0)
		textures[key] = ImageTexture.create_from_image(image)
	return textures[key]

func refresh(force: bool = false) -> void:
	if world == null or (not force and development.revision == seen_revision):
		return
	seen_revision = development.revision
	view = development.view_at(replay_month)
	# Parcel hit areas persist across monthly rendering updates.
	if world.get_child_count() == 0:
		for id in view["parcels"]:
			var parcel: Dictionary = view["parcels"][id]
			var button := Button.new()
			button.flat = true
			button.focus_mode = Control.FOCUS_NONE
			button.modulate.a = 0.0
			button.position = Vector2(parcel["x"] - 40, parcel["y"] - 12)
			button.size = Vector2(80, 40)
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.mouse_filter = Control.MOUSE_FILTER_PASS
			button.tooltip_text = "Inspect " + id.replace("_", " ")
			button.pressed.connect(func(): parcel_selected.emit(id))
			world.add_child(button)
	for id in building_nodes.keys():
		if not view["buildings"].has(id) or view["buildings"][id]["status"] == "demolished":
			building_nodes[id].queue_free()
			building_nodes.erase(id)
			buttons.erase(id)
	for id in view["buildings"]:
		var building: Dictionary = view["buildings"][id]
		if building["status"] == "demolished":
			continue
		var parcel: Dictionary = view["parcels"][building["parcel_id"]]
		var button: TextureButton
		if not building_nodes.has(id):
			button = TextureButton.new()
			button.ignore_texture_size = true
			button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			button.size = Vector2(110, 105)
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.mouse_filter = Control.MOUSE_FILTER_PASS
			button.pressed.connect(func():
				selected_id = id
				building_selected.emit(id)
				queue_redraw())
			world.add_child(button)
			building_nodes[id] = button
			buttons[id] = button
			if LANDMARKS.has(id):
				var label := Label.new()
				label.text = LANDMARKS[id]
				label.position = Vector2(-20, 100)
				label.size.x = 150
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.mouse_filter = Control.MOUSE_FILTER_IGNORE
				label.add_theme_font_override("font", MAP_LETTERING)
				label.add_theme_font_size_override("font_size", 13)
				label.add_theme_color_override("font_color", Color("#fff2cf"))
				label.add_theme_color_override("font_shadow_color", Color("#241b12"))
				label.add_theme_color_override("font_outline_color", Color("#241b12"))
				label.add_theme_constant_override("outline_size", 5)
				label.add_theme_constant_override("shadow_offset_x", 1)
				label.add_theme_constant_override("shadow_offset_y", 1)
				button.add_child(label)
		else:
			button = building_nodes[id]
		button.texture_normal = _sprite(building["type"], building["visual_variant"])
		# Building feet stay anchored to the saved parcel, independent of art size.
		var growth := 1.0 + float(building["visual_variant"]) * .055
		button.size = Vector2(110, 105) * growth
		button.position = Vector2(parcel["x"] - button.size.x / 2, parcel["y"] - button.size.y + 20)
		button.z_index = int(parcel["y"])
		if button.get_child_count() > 0:
			button.get_child(0).position = Vector2((button.size.x - 150) / 2, button.size.y - 5)
		button.modulate = Color("#8a8274") if building["status"] == "abandoned" else Color.WHITE
		button.tooltip_text = building["address"] + " · " + building["type"].capitalize() + "\nOwner: " + building["owner_id"].capitalize() + " · Built " + str(building["built_year"])
	_place_world()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			dragging = event.pressed
			accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var old_rect := _map_rect()
			var relative: Vector2 = (event.position - old_rect.position) / old_rect.size
			zoom = clampf(zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), 1.0, 2.8)
			var new_rect := _map_rect()
			pan += event.position - (new_rect.position + relative * new_rect.size)
			_clamp_pan()
			_place_world()
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		pan += event.relative
		_clamp_pan()
		_place_world()
		accept_event()

func _clamp_pan() -> void:
	var extent := (_map_rect().size - size).max(Vector2.ZERO) / 2 + Vector2(100,80)
	pan.x = clampf(pan.x, -extent.x, extent.x)
	pan.y = clampf(pan.y, -extent.y, extent.y)

func _draw() -> void:
	if map_texture == null or view.is_empty():
		return
	var rect := _map_rect()
	var factor := rect.size / Vector2(1100,650)
	draw_texture_rect(map_texture, rect, false)
	for parcel in view["parcels"].values():
		var point := rect.position + Vector2(parcel["x"], parcel["y"]) * factor
		var color := Color(0,0,0,0)
		if overlay_mode == "Ownership":
			color = Color("#648155") if parcel["owner_id"] == "landi" else (Color("#a88d61") if parcel["owner_id"] == "village" else Color("#986457"))
		elif overlay_mode == "Wealth" and replay_month < 0:
			color = Color("#b28c3e")
			color.a = .1 + parcel["value_cents"] / 18000.0
		elif overlay_mode == "Influence" and replay_month < 0:
			color = Color("#985f51").lerp(Color("#648155"), float(influence.get(parcel["owner_id"], .5)))
		elif overlay_mode == "Development":
			color = Color("#69805b") if parcel["cultivated"] or not parcel["building_id"].is_empty() else Color("#b6a57b")
		if overlay_mode != "Places" and not (replay_month >= 0 and overlay_mode in ["Wealth", "Influence"]):
			if overlay_mode != "Wealth":
				color.a = .24
			draw_rect(Rect2(point - Vector2(42,18)*factor, Vector2(84,38)*factor), color)
		if not selected_id.is_empty() and (parcel["id"] == selected_id or parcel["building_id"] == selected_id):
			draw_arc(point, 32*factor.x, 0, TAU, 32, Color("#855431"), 2, true)
	# Infrastructure is a structural layer rather than a new terrain image.
	if view["infrastructure"]["paved_roads"]:
		var points := PackedVector2Array()
		for point in [Vector2(120,630),Vector2(265,480),Vector2(480,375),Vector2(710,260),Vector2(1000,65)]:
			points.append(rect.position + point*factor)
		draw_polyline(points, Color("#b1a58b"), 9*factor.x, true)
	if view["infrastructure"]["railway"]:
		var a := rect.position + Vector2(30,610)*factor
		var b := rect.position + Vector2(1060,610)*factor
		draw_line(a,b,Color("#776954"),4,true)
		draw_dashed_line(a+Vector2(0,4),b+Vector2(0,4),Color("#776954"),2,8)
	if view["infrastructure"]["electricity"]:
		for point in [Vector2(280,465),Vector2(500,395),Vector2(705,265),Vector2(900,155)]:
			var base: Vector2 = rect.position + point*factor
			draw_line(base, base-Vector2(0,20)*factor, Color("#806c4d"), 2)
			draw_circle(base-Vector2(0,20)*factor, 4, Color("#bd9a55"))
	if replay_month < 0:
		for project in development.projects.values():
			var parcel: Dictionary = view["parcels"][project["parcel_id"]]
			var point := rect.position + Vector2(parcel["x"],parcel["y"])*factor
			draw_rect(Rect2(point-Vector2(25,12)*factor,Vector2(50,25)*factor),Color("#9a7450"),false,2)
			draw_line(point-Vector2(20,8)*factor,point+Vector2(20,8)*factor,Color("#9a7450"),2)
