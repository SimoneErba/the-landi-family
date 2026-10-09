extends Control
## Geographic parchment map; markers share the coastline projection.

signal city_selected(city_id: String)
const Travel = preload("res://Simulation/Travel.gd")
var map_texture: ImageTexture
const OFFSETS := {"turin": Vector2(-100,0), "milan": Vector2(-25,-40), "venice": Vector2(12,-20), "genoa": Vector2(-145,-12), "bologna": Vector2(12,-8), "florence": Vector2(-100,8), "bari": Vector2(12,-35)}
var selected_city: String = "florence"
var buttons: Dictionary = {}


func _ready() -> void:
	var image := Image.new()
	image.load_svg_from_string(FileAccess.get_file_as_string("res://Assets/Maps/italy.svg"), 2.0)
	map_texture = ImageTexture.create_from_image(image)
	custom_minimum_size = Vector2(580, 620)
	for city_id in Travel.CITIES:
		var button := Button.new()
		button.text = Travel.CITIES[city_id]["name"]
		button.custom_minimum_size = Vector2(105, 32)
		button.toggle_mode = true
		button.button_pressed = city_id == selected_city
		button.pressed.connect(func(): city_selected.emit(city_id))
		add_child(button)
		buttons[city_id] = button
	resized.connect(_place_buttons)
	_place_buttons()


func _place_buttons() -> void:
	for city_id in buttons:
		var point: Vector2 = _point(Travel.CITIES[city_id]["position"])
		var offset: Vector2 = OFFSETS.get(city_id, Vector2(12,-12))
		buttons[city_id].position = Vector2(clampf(point.x + offset.x, 4, size.x - 110), point.y + offset.y)
	queue_redraw()


func _map_rect() -> Rect2:
	var scale_factor := minf(size.x / 700.0, size.y / 800.0)
	var dimensions := Vector2(700, 800) * scale_factor
	return Rect2((size - dimensions) / 2, dimensions)


func _point(normalized: Vector2) -> Vector2:
	var rect := _map_rect()
	return rect.position + normalized * rect.size


func _draw() -> void:
	if map_texture != null:
		draw_texture_rect(map_texture, _map_rect(), false)
	var home := _point(Vector2(.37, .39))
	var target := _point(Travel.CITIES[selected_city]["position"])
	draw_dashed_line(home, target, Color("#9a6533"), 2, 8)
	draw_circle(home, 5, Color("#4d6046"))
	draw_string(ThemeDB.fallback_font, home + Vector2(-85, 42), "Tuscan home", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#4d6046"))
	for city_id in Travel.CITIES:
		draw_circle(_point(Travel.CITIES[city_id]["position"]), 5 if city_id == selected_city else 3, Color("#753e30"))
	draw_string(ThemeDB.fallback_font, _point(Vector2(.09,.53)), "Tyrrhenian Sea", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#786b57"))
	draw_string(ThemeDB.fallback_font, _point(Vector2(.67,.32)), "Adriatic Sea", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#786b57"))
