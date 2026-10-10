extends PanelContainer
## A nonmodal context panel: the player can still use the map and clock.
const OVERLAY_Z_INDEX := 1000

func _init() -> void:
	# Village buildings use their map Y coordinate as their draw order.
	z_as_relative = false
	z_index = OVERLAY_Z_INDEX

func popup_centered(dimensions: Vector2i) -> void:
	var viewport_size := get_viewport_rect().size
	size = Vector2(minf(dimensions.x, viewport_size.x - 32), minf(dimensions.y, viewport_size.y - 112))
	position = Vector2(maxf(16, viewport_size.x - size.x - 12), 92)
	show()
	move_to_front()

# Preview tools capture this panel from the actual game viewport.
func get_texture() -> ImageTexture:
	var rendered := get_viewport().get_texture().get_image()
	return ImageTexture.create_from_image(rendered.get_region(Rect2i(get_global_rect())))
