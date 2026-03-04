# 🧪 TEST ORCHESTRATOR
# Tüm test component'larını koordine eder
class_name TestOrchestrator
extends Node

# === TEST COMPONENTS ===
var item_pickup_test: ItemPickupTest = null
var weapon_firing_test: WeaponFiringTest = null
var enemy_drop_test: EnemyDropTest = null

# === TEST STATE ===
var current_test: String = ""
var test_results: Dictionary = {}
var is_testing: bool = false

# === UI ELEMENTS ===
var info_label: Label = null
var test_status_label: Label = null
var results_label: Label = null

# === SIGNALS ===
signal test_suite_started()
signal test_suite_completed(results: Dictionary)
signal test_progress_updated(test_name: String, progress: float)
signal test_result_received(test_name: String, result: bool)

# === LIFECYCLE ===

func _ready() -> void:
	print("TestOrchestrator initialized")
	
	# Test component'larını oluştur
	_setup_test_components()
	
	# UI oluştur
	_setup_ui()
	
	# Event listener'ları bağla
	_setup_event_listeners()

func _setup_test_components() -> void:
	# Item Pickup Test
	item_pickup_test = ItemPickupTest.new()
	add_child(item_pickup_test)
	
	# Weapon Firing Test
	weapon_firing_test = WeaponFiringTest.new()
	add_child(weapon_firing_test)
	
	# Enemy Drop Test
	enemy_drop_test = EnemyDropTest.new()
	add_child(enemy_drop_test)

func _setup_ui() -> void:
	# Ana bilgi label'ı
	info_label = Label.new()
	info_label.text = "TEST ORCHESTRATOR\nF13: Item Pickup Test\nF14: Weapon Firing Test\nF15: Enemy Drop Test\nF16: Run All Tests\nF17: Show Results\nF18: Reset Tests"
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.position = Vector2(10, 10)
	add_child(info_label)
	
	# Test durumu label'ı
	test_status_label = Label.new()
	test_status_label.add_theme_font_size_override("font_size", 14)
	test_status_label.position = Vector2(10, 200)
	add_child(test_status_label)
	
	# Sonuçlar label'ı
	results_label = Label.new()
	results_label.add_theme_font_size_override("font_size", 12)
	results_label.position = Vector2(10, 250)
	add_child(results_label)

func _setup_event_listeners() -> void:
	# Item Pickup Test signals
	item_pickup_test.test_started.connect(_on_test_started)
	item_pickup_test.test_completed.connect(_on_test_completed)
	item_pickup_test.test_summary.connect(_on_test_summary)
	
	# Weapon Firing Test signals
	weapon_firing_test.test_started.connect(_on_test_started)
	weapon_firing_test.test_completed.connect(_on_test_completed)
	weapon_firing_test.test_summary.connect(_on_test_summary)
	
	# Enemy Drop Test signals
	enemy_drop_test.test_started.connect(_on_test_started)
	enemy_drop_test.test_completed.connect(_on_test_completed)
	enemy_drop_test.test_summary.connect(_on_test_summary)

# === INPUT HANDLING ===

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F13:
				_run_item_pickup_test()
			KEY_F14:
				_run_weapon_firing_test()
			KEY_F15:
				_run_enemy_drop_test()
			KEY_F16:
				_run_all_tests()
			KEY_F17:
				_show_results()
			KEY_F18:
				_reset_tests()

# === TEST RUNNERS ===

func _run_item_pickup_test() -> void:
	if is_testing:
		print("Another test is already running!")
		return
	
	print("\n=== RUNNING ITEM PICKUP TEST ===")
	
	# Player entity'yi bul
	var player = _find_player()
	if not player:
		print("No player found for test!")
		return
	
	is_testing = true
	current_test = "item_pickup"
	
	# Testi başlat
	test_status_label.text = "Running Item Pickup Test..."
	item_pickup_test.run_comprehensive_test(player)

func _run_weapon_firing_test() -> void:
	if is_testing:
		print("Another test is already running!")
		return
	
	print("\n=== RUNNING WEAPON FIRING TEST ===")
	
	# Player entity'yi bul
	var player = _find_player()
	if not player:
		print("No player found for test!")
		return
	
	is_testing = true
	current_test = "weapon_firing"
	
	# Testi başlat
	test_status_label.text = "Running Weapon Firing Test..."
	weapon_firing_test.run_comprehensive_test(player)

func _run_enemy_drop_test() -> void:
	if is_testing:
		print("Another test is already running!")
		return
	
	print("\n=== RUNNING ENEMY DROP TEST ===")
	
	is_testing = true
	current_test = "enemy_drop"
	
	# Testi başlat
	test_status_label.text = "Running Enemy Drop Test..."
	enemy_drop_test.run_comprehensive_test()

func _run_all_tests() -> void:
	if is_testing:
		print("Another test is already running!")
		return
	
	print("\n=== RUNNING ALL TESTS ===")
	
	# Player entity'yi bul
	var player = _find_player()
	if not player:
		print("No player found for tests!")
		return
	
	is_testing = true
	current_test = "all_tests"
	test_suite_started.emit()
	
	# Tüm testleri sırayla çalıştır
	test_status_label.text = "Running All Tests..."
	
	# 1. Item Pickup Test
	test_progress_updated.emit("item_pickup", 0.0)
	item_pickup_test.run_quick_test(player)
	await item_pickup_test.test_completed
	test_progress_updated.emit("item_pickup", 1.0)
	
	# 2. Weapon Firing Test
	test_progress_updated.emit("weapon_firing", 0.0)
	weapon_firing_test.run_quick_test(player)
	await weapon_firing_test.test_completed
	test_progress_updated.emit("weapon_firing", 1.0)
	
	# 3. Enemy Drop Test
	test_progress_updated.emit("enemy_drop", 0.0)
	enemy_drop_test.run_quick_test()
	await enemy_drop_test.test_completed
	test_progress_updated.emit("enemy_drop", 1.0)
	
	# Test suite tamamlandı
	is_testing = false
	current_test = ""
	
	# Sonuçları göster
	_show_results()
	
	test_suite_completed.emit(test_results)
	print("=== ALL TESTS COMPLETED ===")

func _show_results() -> void:
	print("\n=== TEST RESULTS SUMMARY ===")
	
	if test_results.is_empty():
		print("No test results available!")
		results_label.text = "No test results available."
		return
	
	var total_tests = 0
	var passed_tests = 0
	
	# Tüm test sonuçlarını birleştir
	var all_results = {}
	
	# Item Pickup Test results
	var pickup_results = item_pickup_test.test_results if item_pickup_test else {}
	for test_name in pickup_results:
		all_results["pickup_" + test_name] = pickup_results[test_name]
	
	# Weapon Firing Test results
	var weapon_results = weapon_firing_test.test_results if weapon_firing_test else {}
	for test_name in weapon_results:
		all_results["weapon_" + test_name] = weapon_results[test_name]
	
	# Enemy Drop Test results
	var drop_results = enemy_drop_test.test_results if enemy_drop_test else {}
	for test_name in drop_results:
		all_results["drop_" + test_name] = drop_results[test_name]
	
	# Sonuçları hesapla
	for test_name in all_results:
		total_tests += 1
		if all_results[test_name]:
			passed_tests += 1
	
	# UI'da göster
	var results_text = "TEST RESULTS:\n"
	results_text += "Total Tests: %d\n" % total_tests
	results_text += "Passed: %d\n" % passed_tests
	results_text += "Failed: %d\n" % (total_tests - passed_tests)
	results_text += "Success Rate: %.1f%%\n\n" % ((float(passed_tests) / float(total_tests)) * 100)
	
	# Detaylı sonuçlar
	results_text += "Detailed Results:\n"
	for test_name in all_results:
		var status = "✓" if all_results[test_name] else "✗"
		results_text += "  %s %s\n" % [status, test_name]
	
	results_label.text = results_text
	
	# Konsola yaz
	print("Total Tests: %d" % total_tests)
	print("Passed: %d" % passed_tests)
	print("Failed: %d" % (total_tests - passed_tests))
	print("Success Rate: %.1f%%" % ((float(passed_tests) / float(total_tests)) * 100))
	
	if passed_tests == total_tests:
		print("\n🎉 ALL TESTS PASSED!")
	else:
		print("\n⚠️  SOME TESTS FAILED!")

func _reset_tests() -> void:
	print("\n=== RESETTING TESTS ===")
	
	# Test state'ini resetle
	is_testing = false
	current_test = ""
	test_results.clear()
	
	# UI'ı resetle
	test_status_label.text = "Tests reset."
	results_label.text = ""
	
	# Test component'larını resetle
	if item_pickup_test:
		item_pickup_test.test_results.clear()
		item_pickup_test.spawned_items.clear()
	
	if weapon_firing_test:
		weapon_firing_test.test_results.clear()
		weapon_firing_test.spawned_projectiles.clear()
	
	if enemy_drop_test:
		enemy_drop_test.test_results.clear()
		enemy_drop_test.test_enemies.clear()
		enemy_drop_test.spawned_items.clear()
	
	print("Tests reset successfully!")

# === UTILITY METHODS ===

func _find_player() -> Node:
	# Scene'de player entity'yi bul
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0]
	
	# Fallback: PlayerEntity class'ını ara
	var nodes = get_tree().get_nodes_in_group("player_entity")
	if nodes.size() > 0:
		return nodes[0]
	
	return null

# === SIGNAL HANDLERS ===

func _on_test_started(test_name: String) -> void:
	print("Test started: %s" % test_name)
	test_status_label.text = "Running: %s" % test_name

func _on_test_completed(test_name: String, result: bool) -> void:
	print("Test completed: %s - %s" % [test_name, "PASS" if result else "FAIL"])
	
	# Test sonucunu kaydet
	test_results[test_name] = result
	test_result_received.emit(test_name, result)
	
	# Test durumunu güncelle
	test_status_label.text = "Completed: %s - %s" % [test_name, "PASS" if result else "FAIL"]
	
	# Testing state'ini güncelle
	if current_test == test_name:
		is_testing = false
		current_test = ""

func _on_test_summary(results: Dictionary) -> void:
	# Test summary'yi kaydet
	for test_name in results:
		test_results[test_name] = results[test_name]

# === DEBUG ===

func _to_string() -> String:
	var total_tests = 0
	var passed_tests = 0
	
	for test_name in test_results:
		total_tests += 1
		if test_results[test_name]:
			passed_tests += 1
	
	return "[TestOrchestrator: %d/%d tests passed]" % [passed_tests, total_tests]

func print_test_info() -> void:
	print("=== Test Orchestrator Info ===")
	print("Current Test: %s" % current_test)
	print("Is Testing: %s" % str(is_testing))
	print("Test Results: %s" % str(test_results))
	
	if item_pickup_test:
		print("ItemPickupTest: %s" % item_pickup_test)
	if weapon_firing_test:
		print("WeaponFiringTest: %s" % weapon_firing_test)
	if enemy_drop_test:
		print("EnemyDropTest: %s" % enemy_drop_test)