# Faz 3.3 – Analitik (geliştirme odaklı)
# session_start/end, wave_completed, level_up, death; platform ve versiyon.
# İsteğe bağlı: Firebase Analytics veya eşdeğer ile event gönderimi.
extends Node

const GAME_VERSION := "1.0.0"
const LOG_PATH := "user://logs/analytics.log"

var _session_start_time: float = 0.0
var _event_queue: Array[Dictionary] = []
var _log_file: FileAccess = null

signal event_logged(event_name: String, params: Dictionary)


func _ready() -> void:
	# user://logs klasörü
	var dir := DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("logs"):
			dir.make_dir("logs")


func _exit_tree() -> void:
	if _log_file:
		_log_file.close()
		_log_file = null


# 3.3.1 – Temel event'ler
func session_start() -> void:
	_session_start_time = Time.get_unix_time_from_system()
	log_event("session_start", {
		"platform": OS.get_name(),
		"version": GAME_VERSION,
		"locale": OS.get_locale_language()
	})


func session_end() -> void:
	var duration := Time.get_unix_time_from_system() - _session_start_time
	log_event("session_end", {
		"platform": OS.get_name(),
		"duration_seconds": int(duration),
		"version": GAME_VERSION
	})


func wave_completed(wave: int, kills: int = 0) -> void:
	log_event("wave_completed", {
		"wave": wave,
		"kills": kills,
		"platform": OS.get_name(),
		"version": GAME_VERSION
	})


func level_up(level: int) -> void:
	log_event("level_up", {
		"level": level,
		"platform": OS.get_name(),
		"version": GAME_VERSION
	})


func death(wave: int, kills: int) -> void:
	log_event("death", {
		"wave": wave,
		"kills": kills,
		"platform": OS.get_name(),
		"version": GAME_VERSION
	})


# Faz 4 – Satın alma analitiği
func purchase_event(product_id: String, gems: int, price_string: String = "") -> void:
	log_event("purchase", {
		"product_id": product_id,
		"gems": gems,
		"price_string": price_string,
		"platform": OS.get_name(),
		"version": GAME_VERSION
	})


func log_event(event_name: String, params: Dictionary = {}) -> void:
	var payload := {
		"event": event_name,
		"params": params,
		"ts": Time.get_unix_time_from_system()
	}
	_event_queue.append(payload)
	event_logged.emit(event_name, params)
	_write_log_line(payload)
	# 3.3.2 – İleride: Firebase Analytics veya HTTP ile backend'e gönder
	# send_to_backend(payload)


func _write_log_line(payload: Dictionary) -> void:
	var line := JSON.stringify(payload) + "\n"
	_log_file = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if _log_file:
		_log_file.seek_end()
		_log_file.store_string(line)
		_log_file.close()
		_log_file = null


func get_queued_events() -> Array:
	return _event_queue.duplicate()


func flush_events() -> void:
	_event_queue.clear()
