extends Control
## Geographic parchment map; markers share the coastline projection.

signal city_selected(city_id: String)
const MAP_LETTERING = preload("res://Assets/UI/Fonts/ArchiveSerif-Italic.ttf")
const Travel = preload("res://Simulation/Travel.gd")
# Approximate period travel corridors, in the same projection as the atlas.
# Island itineraries include coastal embarkation and a sea crossing.
const ROUTES := {
	"florence": [Vector2(.37,.39), Vector2(.38,.375), Vector2(.393,.365), Vector2(.404683,.351758)],
	"bologna": [Vector2(.37,.39), Vector2(.394,.363), Vector2(.405,.343), Vector2(.392,.325), Vector2(.410635,.291921)],
	"milan": [Vector2(.37,.39), Vector2(.394,.363), Vector2(.392,.325), Vector2(.410635,.291921), Vector2(.359,.279), Vector2(.321,.254), Vector2(.285,.239), Vector2(.263029,.211954)],
	"turin": [Vector2(.37,.39), Vector2(.394,.363), Vector2(.392,.325), Vector2(.410635,.291921), Vector2(.359,.279), Vector2(.321,.254), Vector2(.275,.243), Vector2(.219,.254), Vector2(.189,.249), Vector2(.159959,.244450)],
	"venice": [Vector2(.37,.39), Vector2(.394,.363), Vector2(.392,.325), Vector2(.410635,.291921), Vector2(.439,.271), Vector2(.455,.243), Vector2(.477349,.213884)],
	"genoa": [Vector2(.37,.39), Vector2(.352,.348), Vector2(.326,.322), Vector2(.297,.304), Vector2(.270,.293), Vector2(.246318,.299288)],
	"rome": [Vector2(.37,.39), Vector2(.397,.416), Vector2(.424,.44), Vector2(.454,.468), Vector2(.473,.491), Vector2(.489753,.505769)],
	"naples": [Vector2(.37,.39), Vector2(.397,.416), Vector2(.424,.44), Vector2(.454,.468), Vector2(.489753,.505769), Vector2(.53,.531), Vector2(.56,.55), Vector2(.583,.574), Vector2(.611241,.592477)],
	"bari": [Vector2(.37,.39), Vector2(.397,.416), Vector2(.424,.44), Vector2(.463,.453), Vector2(.506,.457), Vector2(.539,.48), Vector2(.573,.506), Vector2(.621,.523), Vector2(.669,.537), Vector2(.722,.548), Vector2(.759,.56), Vector2(.789787,.570589)],
}
# Sea itineraries begin offshore; no overland approach is drawn for boats.
const SEA_ROUTES := {
	"palermo": [Vector2(.312,.405), Vector2(.303,.455), Vector2(.335,.51), Vector2(.38,.58), Vector2(.425,.67), Vector2(.48,.748), Vector2(.535,.79), Vector2(.549,.803)],
	"cagliari": [Vector2(.312,.405), Vector2(.303,.455), Vector2(.33,.505), Vector2(.35,.56), Vector2(.35,.63), Vector2(.327,.696), Vector2(.29,.755), Vector2(.268,.75)],
}
var ship_texture: ImageTexture
var map_texture: ImageTexture
const CITY_IMAGE_SIZE := Vector2(152, 114)
const OFFSETS := {"turin": Vector2(-130, -80), "milan": Vector2(-55, -120), "venice": Vector2(12, -80), "genoa": Vector2(-150, 0), "bologna": Vector2(15, -60), "florence": Vector2(-130, 5)}
static var city_textures: Dictionary = {}
var selected_city: String = "florence"
var markers: Dictionary = {}
var dragging := false

static func city_texture(city_id: String) -> ImageTexture:
	if not city_textures.has(city_id):
		var path := "res://Assets/Maps/Cities/" + city_id + "-engraving.png"
		var image: Image
		if FileAccess.file_exists(path):
			image = Image.load_from_file(path)
		else:
			image = Image.new()
			image.load_svg_from_string(FileAccess.get_file_as_string("res://Assets/Maps/Cities/" + city_id + ".svg"), 2.0)
		city_textures[city_id] = ImageTexture.create_from_image(image)
	return city_textures[city_id]

func _ready() -> void:
	var atlas := Image.load_from_file("res://Assets/Maps/italy-1800.png")
	map_texture = ImageTexture.create_from_image(atlas)
	if FileAccess.file_exists("res://Assets/Maps/boat-1800.png"):
		ship_texture = ImageTexture.create_from_image(Image.load_from_file("res://Assets/Maps/boat-1800.png"))
	custom_minimum_size = Vector2(1400, 1600)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for city_id in Travel.CITIES:
		var marker := TextureRect.new()
		marker.texture = city_texture(city_id)
		marker.name = city_id.capitalize() + "Engraving"
		marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		marker.size = CITY_IMAGE_SIZE
		marker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		marker.focus_mode = Control.FOCUS_ALL
		marker.tooltip_text = "Explore " + Travel.CITIES[city_id]["name"]
		marker.gui_input.connect(func(event):
			if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or event.is_action_pressed("ui_accept"):
				marker.accept_event()
				city_selected.emit(city_id))
		marker.mouse_entered.connect(func(): marker.modulate = Color(1.15, 1.1, 1.0))
		marker.mouse_exited.connect(func(): marker.modulate = Color.WHITE)
		marker.focus_entered.connect(queue_redraw)
		marker.focus_exited.connect(queue_redraw)
		add_child(marker)
		var label := Label.new()
		label.text = Travel.CITIES[city_id]["name"]
		label.position = Vector2(-10, CITY_IMAGE_SIZE.y + 2)
		label.size = Vector2(CITY_IMAGE_SIZE.x + 20, 30)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#533d2a"))
		label.add_theme_color_override("font_shadow_color", Color("#eee0c3"))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_font_override("font", MAP_LETTERING)
		label.add_theme_font_size_override("font_size", 18)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.add_child(label)
		markers[city_id] = marker
	resized.connect(_place_markers)
	_place_markers()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	if event is InputEventMouseMotion and dragging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var viewport := get_parent() as ScrollContainer
		if viewport != null:
			viewport.scroll_horizontal -= int(event.relative.x)
			viewport.scroll_vertical -= int(event.relative.y)
			accept_event()

func _place_markers() -> void:
	for city_id in markers:
		var point: Vector2 = _point(Travel.CITIES[city_id]["position"])
		markers[city_id].position = point + OFFSETS.get(city_id, Vector2(10, -80))
	queue_redraw()


func _map_rect() -> Rect2:
	var scale_factor := minf(size.x / 700.0, size.y / 800.0)
	var dimensions := Vector2(700, 800) * scale_factor
	return Rect2((size - dimensions) / 2, dimensions)


func _point(normalized: Vector2) -> Vector2:
	var rect := _map_rect()
	return rect.position + normalized * rect.size


func _route_curve(city_id: String) -> Curve2D:
	var itinerary: Array = SEA_ROUTES[city_id] if SEA_ROUTES.has(city_id) else ROUTES[city_id]
	var curve := Curve2D.new()
	for index in range(itinerary.size()):
		var point := _point(itinerary[index])
		var previous := _point(itinerary[maxi(index - 1, 0)])
		var following := _point(itinerary[mini(index + 1, itinerary.size() - 1)])
		var tangent := (following - previous) * .12
		curve.add_point(point, -tangent if index > 0 else Vector2.ZERO, tangent if index < itinerary.size() - 1 else Vector2.ZERO)
	curve.bake_interval = 3.0
	return curve

func _draw_route() -> void:
	var curve := _route_curve(selected_city)
	var ink := Color("#2e6481") if selected_city in ["palermo", "cagliari"] else Color("#795238")
	var sea_start := 0.0 if SEA_ROUTES.has(selected_city) else -1.0
	var road := PackedVector2Array()
	var length := curve.get_baked_length()
	var road_length := sea_start if sea_start >= 0 else length
	var offset := 0.0
	while offset < road_length:
		road.append(curve.sample_baked(offset))
		offset += 3.0
	road.append(curve.sample_baked(road_length))
	if road.size() > 1:
		_draw_cobbled_road(curve, road, ink)
	if sea_start >= 0:
		offset = sea_start
		while offset < length:
			var dash := PackedVector2Array()
			var dash_end := minf(offset + 11.0, length)
			var sample := offset
			while sample < dash_end:
				dash.append(curve.sample_baked(sample))
				sample += 2.0
			dash.append(curve.sample_baked(dash_end))
			if dash.size() > 1:
				draw_polyline(dash, Color("#eddfc2"), 5.5, true)
				draw_polyline(dash, ink, 2.6, true)
			offset += 19.0
		var port := curve.sample_baked(sea_start)
		draw_circle(port, 6, Color("#ebdcb9"))
		draw_arc(port, 6, 0, TAU, 24, ink, 1.5, true)
		_draw_ship(curve.sample_baked(lerpf(sea_start, length, .52)), ink)

func _draw_cobbled_road(curve: Curve2D, road: PackedVector2Array, ink: Color) -> void:
	draw_polyline(road, Color(ink, .16), 12, true)
	draw_polyline(road, ink, 9.5, true)
	draw_polyline(road, Color("#dac8a6"), 7.8, true)
	var offset := 2.5
	var row := 0
	while offset < curve.get_baked_length() - 2:
		for course in range(2):
			var along := offset + (2.2 if course == row % 2 else 0.0)
			var center := curve.sample_baked(along)
			var direction := (curve.sample_baked(along + 1.5) - curve.sample_baked(maxf(0, along - 1.5))).normalized()
			var normal := Vector2(-direction.y, direction.x)
			center += normal * (-2.0 if course == 0 else 2.0)
			var corners := PackedVector2Array([center - direction * 1.9 - normal * 1.55, center + direction * 1.9 - normal * 1.55, center + direction * 1.9 + normal * 1.55, center - direction * 1.9 + normal * 1.55, center - direction * 1.9 - normal * 1.55])
			var stone := Color("#c5b18e").lerp(Color("#eee0c1"), float((row * 7 + course * 3) % 5) / 5.0)
			draw_colored_polygon(corners, stone)
			draw_polyline(corners, Color("#8f7856"), .65, true)
		offset += 4.6
		row += 1

func _draw_ship(center: Vector2, _ink: Color) -> void:
	if ship_texture != null:
		draw_texture_rect(ship_texture, Rect2(center - Vector2(60, 70), Vector2(120, 90)), false)

func _draw() -> void:
	if map_texture != null:
		draw_texture_rect(map_texture, _map_rect(), false)
	var home := _point(Vector2(.37, .39))
	_draw_route()
	draw_circle(home, 5, Color("#4d6046"))
	draw_string(MAP_LETTERING, home + Vector2(-205, 20), "Tuscan home", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#4d6046"))
	for city_id in Travel.CITIES:
		if city_id == selected_city or markers[city_id].has_focus():
			draw_arc(markers[city_id].position + CITY_IMAGE_SIZE / 2, 78, 0, TAU, 64, Color("#2e6481") if city_id in ["palermo", "cagliari"] else Color("#9a6533"), 2, true)
		draw_circle(_point(Travel.CITIES[city_id]["position"]), 5 if city_id == selected_city else 3, Color("#753e30"))
