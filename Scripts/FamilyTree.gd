extends Control
## Portrait diagram built from saved parent and spouse links, including departed relatives.

const Portrait = preload("res://Scripts/PersonPortrait.gd")
const CARD := Vector2(144, 164)
const GAP := 16.0
const ROW := 216.0
var positions: Dictionary = {}
var couples: Array = []
var descent: Array = []


static func build(host) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	host.content_overlay.add_child(column)
	host._add_label(column, "Albero genealogico", 32, host.TEXT_MAIN)
	var scroll := ScrollContainer.new()
	scroll.name = "FamilyTreeViewport"
	scroll.tooltip_text = "Select a portrait · horizontal lines join spouses · descending lines join parents and children"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var graph := new()
	graph.name = "FamilyTreeDiagram"
	scroll.add_child(graph)
	graph._populate(host)


func _populate(host) -> void:
	var people: Dictionary = host.game_clock.state.people
	var roots := {}
	for id in people:
		roots[id] = id
	for person in people.values():
		if people.has(person.spouse_id):
			roots[_root(roots, person.spouse_id)] = _root(roots, person.id)
	var groups := {}
	var levels := {}
	for id in people:
		var group: String = _root(roots, id)
		if not groups.has(group):
			groups[group] = []
			levels[group] = 0
		groups[group].append(id)
	# Resolve generations from ancestry, keeping spouses on the same row.
	for iteration in groups.size():
		var changed := false
		for person in people.values():
			var group: String = _root(roots, person.id)
			for parent_id in person.parent_ids:
				if not people.has(parent_id):
					continue
				var parent_group: String = _root(roots, parent_id)
				if group != parent_group and levels[group] <= levels[parent_group]:
					levels[group] = mini(groups.size(), levels[parent_group] + 1)
					changed = true
		if not changed:
			break
	var rows := {}
	for group in groups:
		var level: int = levels[group]
		if not rows.has(level):
			rows[level] = []
		rows[level].append(group)
	var widest := 0.0
	for level in rows:
		rows[level].sort_custom(func(a, b): return people[groups[a][0]].birth_year < people[groups[b][0]].birth_year)
		var x := 32.0
		for group in rows[level]:
			for id in groups[group]:
				positions[id] = Vector2(x, 24 + level * ROW)
				x += CARD.x + GAP
			x += 54.0
		widest = maxf(widest, x)
	custom_minimum_size = Vector2(maxf(800, widest), (rows.keys().max() + 1) * ROW)
	for id in positions:
		var person = people[id]
		var button := Button.new()
		button.name = "TreePerson_" + id
		button.position = positions[id]
		button.size = CARD
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = person.name + " · " + ("Family head" if id == host.game_clock.state.head_id else ("Deceased" if not person.alive else ("At home" if person.in_household else "Living elsewhere")))
		button.add_theme_stylebox_override("normal", host.Archive.card())
		button.pressed.connect(func(): host._show_person(id))
		add_child(button)
		var column := VBoxContainer.new()
		column.position = Vector2(6, 6)
		column.size = CARD - Vector2(12, 12)
		column.add_theme_constant_override("separation", 2)
		button.add_child(column)
		var face := Portrait.new()
		face.custom_minimum_size = Vector2(0, 88)
		face.show_person(person)
		if not person.alive:
			face.modulate = Color("#8b8172")
		column.add_child(face)
		var label: Label = host._add_label(column, person.name, 16, host.TEXT_MAIN)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var status: String = "Family head" if id == host.game_clock.state.head_id else ("Deceased" if not person.alive else ("At home" if person.in_household else "Elsewhere"))
		label = host._add_label(column, "%d · %s" % [person.age, status], 13, host.TEXT_MUTED)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		host._ignore_child_mouse(column)
		if positions.has(person.spouse_id) and id < person.spouse_id:
			var a: Vector2 = positions[id] + CARD / 2
			var b: Vector2 = positions[person.spouse_id] + CARD / 2
			couples.append([a, b])
		var parent_groups := {}
		for parent_id in person.parent_ids:
			if not positions.has(parent_id):
				continue
			var group: String = _root(roots, parent_id)
			if parent_groups.has(group):
				continue
			parent_groups[group] = true
			var origin := Vector2.ZERO
			for relative_id in groups[group]:
				origin += positions[relative_id] + Vector2(CARD.x / 2, CARD.y)
			origin /= groups[group].size()
			if groups[group].size() > 1:
				origin.y -= CARD.y / 2
			descent.append([origin, positions[id] + Vector2(CARD.x / 2, 0)])
	queue_redraw()


static func _root(roots: Dictionary, id: String) -> String:
	var result := id
	while roots[result] != result:
		result = roots[result]
	return result


func _draw() -> void:
	for pair in couples:
		draw_line(pair[0], pair[1], Color("#9a6533"), 2, true)
	for link in descent:
		var a: Vector2 = link[0]
		var b: Vector2 = link[1]
		var midway := b.y - (ROW - CARD.y) / 2
		draw_polyline(PackedVector2Array([a, Vector2(a.x, midway), Vector2(b.x, midway), b]), Color("#786b57"), 2, true)
