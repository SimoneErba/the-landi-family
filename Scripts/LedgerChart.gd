extends Control
const Economy = preload("res://Simulation/Economy.gd")
## Read-only chart of actual settled accounts, in the game's stable lire currency.
const Archive = preload("res://Scripts/ArchiveTheme.gd")
const SERIES := {"treasury": "Household treasury", "income": "Household income", "expenses": "Household expenses", "savings": "Net household savings"}
var entries: Array = []
var series := "treasury"
var hovered_index := -1

func _ready() -> void:
	custom_minimum_size = Vector2(240, 255)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	mouse_exited.connect(func():
		hovered_index = -1
		queue_redraw())

func set_series(value: String) -> void:
	if not SERIES.has(value): return
	series = value
	hovered_index = -1
	tooltip_text = ""
	queue_redraw()

func amount(entry: Dictionary) -> int:
	match series:
		"income": return int(entry["income_cents"])
		"expenses": return Economy.total_expenses(entry)
		"savings": return int(entry["net_cents"])
	return int(entry["closing_cents"])

func _plot() -> Rect2:
	return Rect2(78, 18, maxf(1, size.x - 100), maxf(1, size.y - 57))

func _range() -> Vector2:
	var low := 0.0
	var high := 0.0
	for entry in entries:
		low = minf(low, amount(entry) / 100.0)
		high = maxf(high, amount(entry) / 100.0)
	var step := pow(10.0, floorf(log(maxf(1.0, (high - low) / 4.0)) / log(10.0)))
	step *= ceilf(maxf(1.0, (high - low) / 4.0) / step)
	return Vector2(floorf(low / step) * step, maxf(step, ceilf(high / step) * step))

func _point(index: int, bounds: Vector2, plot: Rect2) -> Vector2:
	var fraction := float(index) / (entries.size() - 1) if entries.size() > 1 else 0.5
	return Vector2(plot.position.x + fraction * plot.size.x, plot.end.y - (amount(entries[index]) / 100.0 - bounds.x) / (bounds.y - bounds.x) * plot.size.y)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not entries.is_empty():
		var plot := _plot()
		hovered_index = clampi(roundi((event.position.x - plot.position.x) / plot.size.x * (entries.size() - 1)), 0, entries.size() - 1)
		var entry: Dictionary = entries[hovered_index]
		tooltip_text = "%s\n%s · %.2f L." % [entry["date"], SERIES[series], amount(entry) / 100.0]
		queue_redraw()

func _draw() -> void:
	var plot := _plot()
	var ink := Color("#786b57")
	if entries.is_empty():
		draw_string(Archive.ITALIC, Vector2(plot.position.x, plot.position.y + 80), "History begins after the first month settles.", HORIZONTAL_ALIGNMENT_LEFT, plot.size.x, 16, ink)
		return
	var bounds := _range()
	for index in range(5):
		var fraction := index / 4.0
		var y := plot.end.y - fraction * plot.size.y
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color("#9f8b68", 0.24), 1)
		var value := lerpf(bounds.x, bounds.y, fraction)
		var caption := ("%.2f L." if bounds.y - bounds.x < 4 else "%.0f L.") % value
		draw_string(Archive.SERIF, Vector2(0, y + 5), caption, HORIZONTAL_ALIGNMENT_RIGHT, plot.position.x - 12, 14, ink)
	if bounds.x < 0:
		var zero_y := plot.end.y + bounds.x / (bounds.y - bounds.x) * plot.size.y
		draw_line(Vector2(plot.position.x, zero_y), Vector2(plot.end.x, zero_y), Color("#9a6533", 0.5), 1)
	var points := PackedVector2Array()
	for index in range(entries.size()): points.append(_point(index, bounds, plot))
	if points.size() > 1:
		var area := PackedVector2Array([Vector2(points[0].x, plot.end.y)])
		area.append_array(points)
		area.append(Vector2(points[-1].x, plot.end.y))
		draw_colored_polygon(area, Color("#4d6046", 0.08))
		draw_polyline(points, Color("#4d6046"), 2.5, true)
	for point in points: draw_circle(point, 3.5, Color("#4d6046"), true, -1, true)
	var interval := maxi(1, ceili(float(entries.size()) / maxi(1, int(plot.size.x / 110))))
	for index in range(entries.size()):
		if index % interval != 0 and index != entries.size() - 1: continue
		# Avoid an overlapping final date label.
		if index != entries.size() - 1 and index + interval >= entries.size() - 1 and index != 0: continue
		var parts: PackedStringArray = str(entries[index]["date"]).split(" ")
		var caption: String = parts[0].left(3) + " " + parts[-1]
		draw_string(Archive.SERIF, Vector2(points[index].x - 45, plot.end.y + 27), caption, HORIZONTAL_ALIGNMENT_CENTER, 90, 14, ink)
	if hovered_index >= 0:
		var point: Vector2 = points[hovered_index]
		draw_line(Vector2(point.x, plot.position.y), Vector2(point.x, plot.end.y), Color("#9a6533", 0.45), 1)
		draw_circle(point, 5, Color("#9a6533"), true, -1, true)
