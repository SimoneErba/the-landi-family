extends Node
## Real-time soundtrack, independent of the family's clock and save files.
signal settings_changed

const SETTINGS_PATH := "user://audio-settings.cfg"
const TRACKS := [
	"res://Assets/Audio/Music/gymnopedie-no-1.ogg",
	"res://Assets/Audio/Music/consolation-no-3.ogg",
	"res://Assets/Audio/Music/reverie.ogg",
]
const AMBIENCE_PATH := "res://Assets/Audio/Ambience/courtyard.ogg"
const MIN_GAP := 30.0
const MAX_GAP := 60.0
const FADE_SECONDS := 3.0

var muted := false
var music_volume := 0.55
var ambience_volume := 0.35
var settings_path := SETTINGS_PATH
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var track_index := -1
var gap_remaining := 0.0
var gap_duration := 0.0
var phase_elapsed := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	load_settings()
	music = AudioStreamPlayer.new()
	music.name = "Piano"
	add_child(music)
	ambience = AudioStreamPlayer.new()
	ambience.name = "Courtyard"
	ambience.stream = load(AMBIENCE_PATH)
	add_child(ambience)
	music.finished.connect(_begin_gap)
	_play_next_track()

func _process(delta: float) -> void:
	phase_elapsed += delta
	if gap_remaining > 0.0:
		gap_remaining = maxf(0.0, gap_remaining - delta)
		if gap_remaining == 0.0:
			_play_next_track()
	_apply_levels()

func _play_next_track() -> void:
	ambience.stop()
	gap_remaining = 0.0
	phase_elapsed = 0.0
	track_index = (track_index + 1) % TRACKS.size()
	music.stream = load(TRACKS[track_index])
	_apply_levels()
	music.play()

func _begin_gap() -> void:
	music.stop()
	gap_duration = rng.randf_range(MIN_GAP, MAX_GAP)
	gap_remaining = gap_duration
	phase_elapsed = 0.0
	_apply_levels()
	ambience.play()

func _apply_levels() -> void:
	if music == null or ambience == null: return
	var fade_in := clampf(phase_elapsed / FADE_SECONDS, 0.0, 1.0)
	var music_fade := fade_in
	if music.stream != null:
		music_fade = minf(music_fade, clampf((music.stream.get_length() - music.get_playback_position()) / FADE_SECONDS, 0.0, 1.0))
	var ambience_fade := minf(fade_in, clampf(gap_remaining / FADE_SECONDS, 0.0, 1.0))
	music.volume_linear = 0.0 if muted else music_volume * music_fade
	ambience.volume_linear = 0.0 if muted else ambience_volume * ambience_fade

func set_muted(value: bool) -> void:
	muted = value
	_settings_updated()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_settings_updated()

func set_ambience_volume(value: float) -> void:
	ambience_volume = clampf(value, 0.0, 1.0)
	_settings_updated()

func _settings_updated() -> void:
	_apply_levels()
	save_settings()
	settings_changed.emit()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "muted", muted)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "ambience_volume", ambience_volume)
	var error := config.save(settings_path)
	if error != OK: push_warning("Could not save audio settings: " + error_string(error))

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK: return
	var saved_mute: Variant = config.get_value("audio", "muted", false)
	muted = saved_mute if saved_mute is bool else false
	music_volume = _read_volume(config, "music_volume", 0.55)
	ambience_volume = _read_volume(config, "ambience_volume", 0.35)
	_apply_levels()

func _read_volume(config: ConfigFile, key: String, fallback: float) -> float:
	var value: Variant = config.get_value("audio", key, fallback)
	if not (value is float or value is int): return fallback
	if not is_finite(float(value)): return fallback
	return clampf(float(value), 0.0, 1.0)
