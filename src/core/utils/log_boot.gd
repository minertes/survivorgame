# 📋 LOG BOOT - Autoload için Logger başlatıcı (Faz 0.5)
# _ready'de GameLogger.setup() çağrılır; tüm sahneler Log.info() vb. kullanabilir
extends Node

const GameLogger = preload("res://src/core/utils/logger.gd")

func _ready() -> void:
	GameLogger.setup(GameLogger.Level.DEBUG, true)

func debug(message: String, context: Dictionary = {}) -> void:
	GameLogger.debug(message, context)

func info(message: String, context: Dictionary = {}) -> void:
	GameLogger.info(message, context)

func warn(message: String, context: Dictionary = {}) -> void:
	GameLogger.warn(message, context)

func error(message: String, context: Dictionary = {}) -> void:
	GameLogger.error(message, context)

func fatal(message: String, context: Dictionary = {}) -> void:
	GameLogger.fatal(message, context)
