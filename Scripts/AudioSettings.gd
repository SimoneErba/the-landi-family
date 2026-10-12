extends "res://Scripts/InlinePanel.gd"

const Archive = preload("res://Scripts/ArchiveTheme.gd")
var soundtrack: Node
var mute: CheckButton
var music_slider: HSlider
var ambience_slider: HSlider
var music_level: Label
var ambience_level: Label

func _ready() -> void:
	super._ready()
	name = "AudioSettings"
	var surface := Archive.modal_frame()
	surface.shadow_color = Color(0.08, 0.05, 0.03, 0.25)
	surface.shadow_size = 12
	surface.shadow_offset = Vector2(0, 5)
	add_theme_stylebox_override("panel", surface)
	soundtrack = get_node("/root/Soundtrack")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.name = "CloseSettings"
	close.text = "Close"
	Archive.style_button(close)
	close.pressed.connect(hide)
	header.add_child(close)
	mute = CheckButton.new()
	mute.name = "MuteAudio"
	mute.text = "Mute all audio"
	mute.tooltip_text = "Silence piano and courtyard sounds. Your volume settings are kept."
	column.add_child(mute)
	music_level = Label.new()
	music_slider = _volume_control(column, "MusicVolume", "Music volume", music_level)
	ambience_level = Label.new()
	ambience_slider = _volume_control(column, "AmbienceVolume", "Ambience volume", ambience_level)
	var note := Label.new()
	note.text = "Birdsong, wind and distant church bells fill the\n30–60 second intervals between piano pieces.\nSettings are saved automatically."
	note.add_theme_font_size_override("font_size", 14)
	column.add_child(note)
	_sync_controls()
	mute.toggled.connect(soundtrack.set_muted)
	music_slider.value_changed.connect(func(value: float): soundtrack.set_music_volume(value / 100.0))
	ambience_slider.value_changed.connect(func(value: float): soundtrack.set_ambience_volume(value / 100.0))
	soundtrack.settings_changed.connect(_sync_controls)

func _volume_control(column: VBoxContainer, node_name: String, caption: String, level: Label) -> HSlider:
	var row := HBoxContainer.new()
	column.add_child(row)
	var label := Label.new()
	label.text = caption
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(level)
	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.custom_minimum_size = Vector2(320, 28)
	slider.tooltip_text = caption + " · 0% is silent"
	column.add_child(slider)
	return slider

func _sync_controls() -> void:
	mute.set_pressed_no_signal(soundtrack.muted)
	music_slider.set_value_no_signal(roundf(soundtrack.music_volume * 100.0))
	ambience_slider.set_value_no_signal(roundf(soundtrack.ambience_volume * 100.0))
	music_level.text = "%d%%" % music_slider.value
	ambience_level.text = "%d%%" % ambience_slider.value
