# Faz 6.2.3 – Ortam ayrımı: Dev/Staging/Prod config (API URL, analytics, log seviyesi)
extends Node

const CONFIG_PATH := "res://config/default_env.cfg"

var environment: String = "dev"
var backend_url: String = ""
var analytics_enabled: bool = true
var crash_reporting_enabled: bool = true
var log_level: String = "debug"

func _ready() -> void:
	_load()
	_apply_log_level()

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	environment = cfg.get_value("env", "environment", "dev")
	backend_url = cfg.get_value("env", "backend_url", "")
	analytics_enabled = cfg.get_value("env", "analytics_enabled", true)
	crash_reporting_enabled = cfg.get_value("env", "crash_reporting_enabled", true)
	var log_val = cfg.get_value("env", "log_level", "debug")
	log_level = str(log_val).strip_edges().trim_prefix("\"").trim_suffix("\"")

func _apply_log_level() -> void:
	var LoggerScript: GDScript = load("res://src/core/utils/logger.gd") as GDScript
	if not LoggerScript:
		return
	var level: int = LoggerScript.Level.DEBUG
	match log_level.to_lower():
		"info": level = LoggerScript.Level.INFO
		"warn": level = LoggerScript.Level.WARN
		"error": level = LoggerScript.Level.ERROR
		"fatal": level = LoggerScript.Level.FATAL
		_: level = LoggerScript.Level.DEBUG
	LoggerScript.setup(level, true)

func is_production() -> bool:
	return environment == "prod"
