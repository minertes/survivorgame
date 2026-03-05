# Faz 6.1.3 – Entegrasyon testi: Menü → Lobi → Oyun → Kayıt/Yükleme akışı
# Bu script sahne geçişlerini simüle etmez; akış adımlarını ve bağımlılıkları doğrular.
# Tam akış testi için manuel veya UI otomasyon kullanılır.
extends Node

var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	_test_flow_dependencies()
	_test_save_load_after_record()
	var code: int = 0 if _failed == 0 else 1
	get_tree().quit(code)

func _ok(msg: String) -> void:
	_passed += 1
	print("[PASS] ", msg)

func _fail(msg: String, reason: String) -> void:
	_failed += 1
	printerr("[FAIL] ", msg, ": ", reason)

func _test_flow_dependencies() -> void:
	# Menü → Lobi: menu.tscn, lobby.tscn var mı
	if not FileAccess.file_exists("res://menu.tscn"):
		_fail("Menu scene", "res://menu.tscn not found")
	else:
		_ok("Menu scene exists")
	if not FileAccess.file_exists("res://lobby.tscn"):
		_fail("Lobby scene", "res://lobby.tscn not found")
	else:
		_ok("Lobby scene exists")
	if not FileAccess.file_exists("res://main.tscn"):
		_fail("Main game scene", "res://main.tscn not found")
	else:
		_ok("Main game scene exists")
	# Autoloads
	if not has_node("/root/GameData"):
		_fail("GameData autoload", "not in tree")
	else:
		_ok("GameData autoload")
	if not has_node("/root/BackendService"):
		_fail("BackendService autoload", "not in tree")
	else:
		_ok("BackendService autoload")

func _test_save_load_after_record() -> void:
	if not has_node("/root/GameData"):
		return
	var gd = get_node("/root/GameData")
	var bw: int = gd.best_wave
	var tk: int = gd.total_kills
	gd.record_game(5, 30, 120, 100, 40)
	if gd.best_wave < 5 or gd.total_kills < 30:
		_fail("record_game updates stats", "best_wave=%d total_kills=%d" % [gd.best_wave, gd.total_kills])
	else:
		_ok("record_game updates stats")
	gd.best_wave = bw
	gd.total_kills = tk
	gd.total_games -= 1
	gd.save_data()
