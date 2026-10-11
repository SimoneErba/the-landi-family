extends Node
## One shared stack prevents a single outside click from closing several panels.
var windows: Array[Control] = []

func register(window: Control) -> void:
	window.visibility_changed.connect(_visibility_changed.bind(window))
	window.tree_exiting.connect(func(): windows.erase(window))
	if window.visible: opened(window)

func _visibility_changed(window: Control) -> void:
	if window.visible:
		opened(window)
	else:
		windows.erase(window)

func opened(window: Control) -> void:
	windows.erase(window)
	windows.append(window)
	for index in windows.size():
		windows[index].z_index = 1000 + index
	window.move_to_front()

func dismiss_latest() -> bool:
	if windows.is_empty(): return false
	windows.back().hide()
	return true

func _input(event: InputEvent) -> void:
	if windows.is_empty(): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		dismiss_latest()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for window in windows:
			if window.get_global_rect().has_point(event.position): return
		dismiss_latest()
		# Consume the dismissal so the same click cannot trigger the page below.
		get_viewport().set_input_as_handled()
