# Faz 6.1 – CI uyumlu birim test koşucusu
# Godot --headless -s res://ci/test_runner.gd veya sahne olarak ci/test_runner.tscn çalıştırılır.
# Çıkış kodu: 0 = tüm testler geçti, 1 = en az bir hata.
extends Node

var _failed: int = 0
var _passed: int = 0
var _reports: Array[String] = []

func _ready() -> void:
	_run_all()
	var code: int = 0 if _failed == 0 else 1
	get_tree().quit(code)

func _run_all() -> void:
	_run_gamedata_save_load()
	_run_wave_scale_logic()
	_run_gamedata_currency()
	_print_summary()

func _ok(name: String) -> void:
	_passed += 1
	_reports.append("[PASS] " + name)
	print("[PASS] ", name)

func _fail(name: String, reason: String) -> void:
	_failed += 1
	_reports.append("[FAIL] " + name + ": " + reason)
	printerr("[FAIL] ", name, ": ", reason)

func _run_gamedata_save_load() -> void:
	if not has_node("/root/GameData"):
		_fail("GameData save/load", "GameData autoload not found")
		return
	var gd = get_node("/root/GameData")
	var orig_xp: int = gd.xp_coins
	var orig_wave: int = gd.best_wave
	gd.xp_coins = 99999
	gd.best_wave = 42
	gd.save_data()
	gd.xp_coins = 0
	gd.best_wave = 0
	gd.load_data()
	if gd.xp_coins == 99999 and gd.best_wave == 42:
		_ok("GameData save/load")
	else:
		_fail("GameData save/load", "expected 99999/42, got %d/%d" % [gd.xp_coins, gd.best_wave])
	gd.xp_coins = orig_xp
	gd.best_wave = orig_wave
	gd.save_data()

func _run_wave_scale_logic() -> void:
	# main.gd'deki _get_wave_scale ve _is_boss_wave mantığı
	if _wave_scale(1) < 1.0 or _wave_scale(1) > 2.0:
		_fail("wave_scale(1)", "expected ~1.0")
	else:
		_ok("wave_scale(1)")
	if _wave_scale(10) < 1.5 or _wave_scale(10) > 2.5:
		_fail("wave_scale(10)", "expected ~1.72")
	else:
		_ok("wave_scale(10)")
	if not _is_boss_wave(10):
		_fail("is_boss_wave(10)", "expected true")
	else:
		_ok("is_boss_wave(10)")
	if _is_boss_wave(9):
		_fail("is_boss_wave(9)", "expected false")
	else:
		_ok("is_boss_wave(9)")

func _wave_scale(w: int) -> float:
	if w <= 10:
		return 1.0 + (w - 1) * 0.08
	elif w <= 30:
		return 1.72 + (w - 11) * 0.12
	else:
		return 4.0 + (w - 31) * 0.15

func _is_boss_wave(w: int) -> bool:
	return w > 0 and w % 10 == 0

func _run_gamedata_currency() -> void:
	if not has_node("/root/GameData"):
		return
	var gd = get_node("/root/GameData")
	var orig_gems: int = gd.gems
	gd.add_gems(50, "test", "test_product")
	if gd.gems != orig_gems + 50:
		_fail("GameData add_gems", "expected %d got %d" % [orig_gems + 50, gd.gems])
	else:
		_ok("GameData add_gems")
	gd.spend_gems(50, "test", "test")
	if gd.gems != orig_gems:
		_fail("GameData spend_gems", "expected %d got %d" % [orig_gems, gd.gems])
	else:
		_ok("GameData spend_gems")
	gd.gems = orig_gems
	gd.save_data()

func _print_summary() -> void:
	print("---")
	print("Total: %d passed, %d failed" % [_passed, _failed])
