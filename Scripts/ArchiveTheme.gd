extends RefCounted
## Compact archive panels, walnut controls and readable dashboard typography.

const SERIF = preload("res://Assets/UI/Fonts/ArchiveSerif.ttf")
const ITALIC = preload("res://Assets/UI/Fonts/ArchiveSerif-Italic.ttf")
const HEADING = preload("res://Assets/UI/Fonts/ArchiveSerif-Bold.ttf")
const FRAME = preload("res://Assets/UI/walnut-frame.svg")
const PORTRAIT = preload("res://Assets/UI/portrait-frame.svg")
const WOOD = preload("res://Assets/UI/walnut-panel.svg")
const NORMAL = preload("res://Assets/UI/button.svg")
const HOVER = preload("res://Assets/UI/button-hover.svg")
const ACTIVE = preload("res://Assets/UI/button-active.svg")
const DISABLED = preload("res://Assets/UI/button-disabled.svg")


static func box(texture: Texture2D, edge: float, padding: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, edge)
		style.set_content_margin(side, padding)
	return style


static func window_frame() -> StyleBoxFlat:
	return paper_panel(12, 2)


static func card() -> StyleBoxFlat:
	return paper_panel(6, 1)


static func paper_panel(padding: int, border: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#eee0c3")
	style.border_color = Color("#96734d")
	style.set_border_width_all(border)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, padding)
	return style


static func wood_panel() -> StyleBoxTexture:
	return box(WOOD, 16, 8)


static func style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", box(NORMAL, 16, 5))
	button.add_theme_stylebox_override("hover", box(HOVER, 16, 5))
	button.add_theme_stylebox_override("pressed", box(ACTIVE, 16, 5))
	button.add_theme_stylebox_override("hover_pressed", box(ACTIVE, 16, 5))
	button.add_theme_stylebox_override("disabled", box(DISABLED, 16, 5))
	button.add_theme_color_override("font_color", Color("#f2e0bc"))
	button.add_theme_color_override("font_hover_color", Color("#fff0d0"))
	button.add_theme_color_override("font_pressed_color", Color("#fff1cf"))
	button.add_theme_color_override("font_disabled_color", Color("#a79880"))
	button.add_theme_font_override("font", SERIF)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("#e0c082")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)


static func compact_font_size(size: int) -> int:
	return maxi(11, roundi(size * 0.8))


static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font = SERIF
	theme.default_font_size = 13
	for type in ["HBoxContainer", "VBoxContainer"]:
		theme.set_constant("separation", type, 4)
	for type in ["HFlowContainer", "VFlowContainer", "GridContainer"]:
		theme.set_constant("h_separation", type, 6)
		theme.set_constant("v_separation", type, 4)
	# Keep narrative asides visually quieter than facts and decisions.
	theme.set_type_variation("FlavorText", "Label")
	theme.set_font("font", "FlavorText", ITALIC)
	theme.set_font_size("font_size", "FlavorText", 12)
	theme.set_color("font_color", "FlavorText", Color("#786b59"))
	theme.set_color("font_color", "Label", Color("#392b20"))
	theme.set_stylebox("panel", "PanelContainer", window_frame())
	theme.set_stylebox("panel", "PopupPanel", window_frame())
	theme.set_stylebox("panel", "PopupMenu", window_frame())
	theme.set_color("font_color", "PopupMenu", Color("#392b20"))
	theme.set_color("font_hover_color", "PopupMenu", Color("#f6e6c5"))
	theme.set_stylebox("hover", "PopupMenu", box(HOVER, 16, 5))
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var texture: Texture2D = NORMAL
		if state == "hover": texture = HOVER
		if state in ["pressed", "hover_pressed"]: texture = ACTIVE
		if state == "disabled": texture = DISABLED
		theme.set_stylebox(state, "Button", box(texture, 16, 5))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		theme.set_color(state, "Button", Color("#f2e0bc"))
	theme.set_color("font_disabled_color", "Button", Color("#a79880"))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("#e0c082")
	focus.set_border_width_all(2)
	theme.set_stylebox("focus", "Button", focus)
	var scroll_track := StyleBoxFlat.new()
	scroll_track.bg_color = Color("#c8b18b")
	scroll_track.content_margin_left = 2
	scroll_track.content_margin_right = 2
	theme.set_stylebox("scroll", "VScrollBar", scroll_track)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var thumb := StyleBoxFlat.new()
		thumb.bg_color = Color("#96734d") if state == "grabber" else Color("#b58d54")
		thumb.border_color = Color("#d5b781")
		thumb.set_border_width_all(1)
		thumb.content_margin_left = 4
		thumb.content_margin_right = 4
		theme.set_stylebox(state, "VScrollBar", thumb)
	theme.set_stylebox("panel", "TooltipPanel", card())
	theme.set_color("font_color", "TooltipLabel", Color("#392b20"))
	theme.set_stylebox("panel", "TabContainer", card())
	theme.set_stylebox("tab_selected", "TabContainer", box(ACTIVE, 16, 5))
	theme.set_stylebox("tab_unselected", "TabContainer", box(NORMAL, 16, 5))
	theme.set_stylebox("tab_hovered", "TabContainer", box(HOVER, 16, 5))
	theme.set_color("font_selected_color", "TabContainer", Color("#fff0d0"))
	theme.set_color("font_unselected_color", "TabContainer", Color("#dec9a1"))
	return theme


static func flavor_quote(value: String) -> String:
	var text := value.strip_edges()
	if text.is_empty() or text.begins_with("“") or text.begins_with("\""):
		return text
	return "“%s”" % text
