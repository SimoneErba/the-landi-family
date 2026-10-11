extends PanelContainer
## A nonmodal context panel: the player can still use the map and clock.
const OVERLAY_Z_INDEX := 1000
signal popup_hide
var manager: Node

func _ready() -> void:
	manager = get_parent().get_node_or_null("WindowManager")
	if manager != null: manager.register(self)
	visibility_changed.connect(func():
		if not visible: popup_hide.emit()
	)

func _init() -> void:
	# Village buildings use their map Y coordinate as their draw order.
	z_as_relative = false
	z_index = OVERLAY_Z_INDEX

func popup_centered(dimensions: Vector2i, raise_window: bool = true) -> void:
	var viewport_size := get_viewport_rect().size
	size = Vector2(minf(dimensions.x, viewport_size.x - 32), minf(dimensions.y, viewport_size.y - 92))
	position = Vector2(maxf(16, viewport_size.x - size.x - 12), 72)
	show()
	if raise_window:
		if manager != null: manager.opened(self)
		else: move_to_front()

func popup(bounds: Rect2i) -> void:
	size = Vector2(bounds.size)
	position = Vector2(bounds.position)
	show()
	if manager != null: manager.opened(self)
	else: move_to_front()

# Preview tools capture this panel from the actual game viewport.
func get_texture() -> ImageTexture:
	var rendered := get_viewport().get_texture().get_image()
	return ImageTexture.create_from_image(rendered.get_region(Rect2i(get_global_rect())))
