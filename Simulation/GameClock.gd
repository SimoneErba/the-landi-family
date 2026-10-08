extends Node
## Converts real time into discrete monthly steps; independent of UI screens.

signal month_advanced
signal playback_changed

const State = preload("res://Simulation/GameState.gd")
const SECONDS_PER_MONTH := [60.0, 30.0, 15.0, 7.5, 3.75]

var state = State.new()
var is_playing: bool = false
var speed_level: int = 3
var month_progress: float = 0.0
var _last_tick_usec: int = Time.get_ticks_usec()
var _updating_month: bool = false


func _process(_delta: float) -> void:
	_update_real_time()


func _update_real_time() -> void:
	# Frame delta can be clamped during slow rendering. Use actual elapsed time.
	var now := Time.get_ticks_usec()
	var seconds := (now - _last_tick_usec) / 1000000.0
	_last_tick_usec = now
	advance_time(seconds)


func advance_time(seconds: float) -> void:
	if state.events.enabled and not state.events.pending.is_empty():
		is_playing = false
		return
	if not is_playing or seconds <= 0.0:
		return
	month_progress += seconds / seconds_per_month()
	while is_playing and month_progress >= 1.0:
		month_progress -= 1.0
		_updating_month = true
		state.advance_month()
		if state.economy.crisis_started or state.major_event:
			# Do not carry unattended catch-up time into an unresolved decision.
			if not state.events.pending.is_empty():
				month_progress = 0.0
			pause()
		# Subscribers see the completed update and can pause for major events.
		month_advanced.emit()
		_updating_month = false


func play() -> void:
	if state.events.enabled and not state.events.pending.is_empty():
		is_playing = false
		playback_changed.emit()
		return
	if not is_playing:
		_last_tick_usec = Time.get_ticks_usec()
	is_playing = true
	playback_changed.emit()


func pause() -> void:
	if not _updating_month:
		_update_real_time()
	is_playing = false
	playback_changed.emit()


func set_speed(level: int) -> void:
	if not _updating_month:
		_update_real_time()
	speed_level = clampi(level, 1, 5)
	# Preserve the fraction of the current month, including across pauses.
	playback_changed.emit()


func seconds_per_month() -> float:
	return SECONDS_PER_MONTH[speed_level - 1]
