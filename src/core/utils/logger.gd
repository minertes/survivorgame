# 📋 LOGGER - Temel loglama (Faz 0.5)
# Seviyeli log; dosyaya yazım (user://logs/game.log)
class_name GameLogger
extends RefCounted

enum Level { DEBUG, INFO, WARN, ERROR, FATAL }

const LOG_DIR := "user://logs"
const LOG_FILE := "user://logs/game.log"
const ERROR_LOG_FILE := "user://logs/error.log"
const MAX_FILE_SIZE_KB := 512

static var _min_level: Level = Level.DEBUG
static var _file_path: String = LOG_FILE
static var _to_file: bool = true
static var _initialized: bool = false

# === SETUP ===

static func setup(min_level: Level = Level.DEBUG, log_to_file: bool = true) -> void:
	_min_level = min_level
	_to_file = log_to_file
	if _to_file:
		_ensure_log_dir()
	_initialized = true

static func _ensure_log_dir() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("logs"):
			dir.make_dir("logs")

# === LOGGING ===

static func debug(message: String, context: Dictionary = {}) -> void:
	_log(Level.DEBUG, message, context)

static func info(message: String, context: Dictionary = {}) -> void:
	_log(Level.INFO, message, context)

static func warn(message: String, context: Dictionary = {}) -> void:
	_log(Level.WARN, message, context)

static func error(message: String, context: Dictionary = {}) -> void:
	_log(Level.ERROR, message, context)

static func fatal(message: String, context: Dictionary = {}) -> void:
	_log(Level.FATAL, message, context)

static func _log(level: Level, message: String, context: Dictionary) -> void:
	if level < _min_level:
		return
	var level_name: String = Level.keys()[level]
	var timestamp := Time.get_datetime_string_from_system()
	var line := "[%s][%s] %s" % [timestamp, level_name, message]
	if context.size() > 0:
		line += " " + str(context)
	# Konsol
	var color := _level_color(level)
	print_rich("[color=%s]%s[/color]" % [color, line])
	# Dosya: INFO+ game.log; ERROR/FATAL ayrıca error.log (Faz 6.3.1 – production'da toplama)
	if _to_file and level >= Level.INFO:
		_write_to_file(_file_path, line)
	if level >= Level.ERROR:
		_write_to_file(ERROR_LOG_FILE, line)

static func _level_color(level: Level) -> String:
	match level:
		Level.DEBUG: return "gray"
		Level.INFO: return "white"
		Level.WARN: return "yellow"
		Level.ERROR: return "orange"
		Level.FATAL: return "red"
		_: return "white"

static func _write_to_file(path: String, line: String) -> void:
	_ensure_log_dir()
	var f = FileAccess.open(path, FileAccess.READ_WRITE)
	if not f:
		return
	f.seek_end()
	f.store_line(line)
	f.close()
