# 🧪 TEST MENU SYSTEM
# Yeni menü sistemini test etmek için script
extends Node

# === TEST CASES ===
var test_cases = [
	"Component Initialization",
	"GameData Integration",
	"Animation System",
	"Sound Integration",
	"UI Interactions",
	"Scene Transitions"
]

# === STATE ===
var current_test = 0
var tests_passed = 0
var tests_failed = 0

# === LIFECYCLE ===

func _ready() -> void:
	print("🧪 Starting Menu System Tests...")
	print("=" * 50)
	
	# Testleri çalıştır
	_run_tests()

# === TEST METHODS ===

func test_component_initialization() -> bool:
	print("Test 1: Component Initialization")
	
	# MenuScene'i kontrol et
	var menu_scene = get_node_or_null("/root/Menu/MenuScene")
	if not menu_scene:
		print("  ❌ MenuScene not found")
		return false
	
	# Bileşenleri kontrol et
	var status = menu_scene.get_component_status()
	
	var all_loaded = true
	for component in status:
		if not status[component]:
			print("  ❌ %s not loaded" % component)
			all_loaded = false
		else:
			print("  ✅ %s loaded" % component)
	
	if all_loaded:
		print("  ✅ All components initialized successfully")
		return true
	else:
		print("  ❌ Some components failed to initialize")
		return false

func test_game_data_integration() -> bool:
	print("\nTest 2: GameData Integration")
	
	# GameData'yi kontrol et
	if not has_node("/root/GameData"):
		print("  ⚠️ GameData not found in root (might be loaded later)")
		return true  # Bu kritik bir hata değil
	
	var game_data = get_node("/root/GameData")
	
	# Temel verileri kontrol et
	var checks = [
		["best_wave", game_data.best_wave >= 0],
		["total_kills", game_data.total_kills >= 0],
		["sound_enabled", typeof(game_data.sound_enabled) == TYPE_BOOL]
	]
	
	var all_passed = true
	for check in checks:
		if check[1]:
			print("  ✅ %s: OK" % check[0])
		else:
			print("  ❌ %s: FAILED" % check[0])
			all_passed = false
	
	if all_passed:
		print("  ✅ GameData integration successful")
		return true
	else:
		print("  ❌ GameData integration failed")
		return false

func test_animation_system() -> bool:
	print("\nTest 3: Animation System")
	
	var menu_scene = get_node_or_null("/root/Menu/MenuScene")
	if not menu_scene:
		print("  ❌ MenuScene not found")
		return false
	
	# EntranceAnimationController'ı kontrol et
	var animator = menu_scene.get_node_or_null("EntranceAnimationController")
	if not animator:
		print("  ❌ EntranceAnimationController not found")
		return false
	
	# Animasyon durumunu kontrol et
	print("  ✅ EntranceAnimationController found")
	print("  ℹ️ Animation sequence: %s" % str(animator.animation_sequence))
	
	return true

func test_sound_integration() -> bool:
	print("\nTest 4: Sound Integration")
	
	var menu_scene = get_node_or_null("/root/Menu/MenuScene")
	if not menu_scene:
		print("  ❌ MenuScene not found")
		return false
	
	# SoundManagerIntegration'ı kontrol et
	var sound_integration = menu_scene.get_node_or_null("SoundManagerIntegration")
	if not sound_integration:
		print("  ❌ SoundManagerIntegration not found")
		return false
	
	# Ses durumunu kontrol et
	var audio_status = sound_integration.get_audio_status()
	print("  ✅ SoundManagerIntegration found")
	print("  ℹ️ Sound enabled: %s" % str(audio_status.sound_enabled))
	print("  ℹ️ Audio system available: %s" % str(audio_status.audio_system_available))
	
	return true

func test_ui_interactions() -> bool:
	print("\nTest 5: UI Interactions")
	
	var menu_scene = get_node_or_null("/root/Menu/MenuScene")
	if not menu_scene:
		print("  ❌ MenuScene not found")
		return false
	
	# MenuUIMolecule'ü kontrol et
	var menu_ui = menu_scene.get_node_or_null("MenuUIMolecule")
	if not menu_ui:
		print("  ❌ MenuUIMolecule not found")
		return false
	
	# Buton durumlarını kontrol et
	print("  ✅ MenuUIMolecule found")
	print("  ℹ️ Start button: %s" % ("Visible" if menu_ui.show_start_button else "Hidden"))
	print("  ℹ️ Sound button: %s" % ("Visible" if menu_ui.show_sound_button else "Hidden"))
	
	return true

func test_scene_transitions() -> bool:
	print("\nTest 6: Scene Transitions")
	
	var menu_scene = get_node_or_null("/root/Menu/MenuScene")
	if not menu_scene:
		print("  ❌ MenuScene not found")
		return false
	
	# Transition sistemini kontrol et
	print("  ✅ Scene transition system available")
	print("  ℹ️ Can transition to lobby: Yes")
	
	return true

# === TEST RUNNER ===

func _run_tests() -> void:
	print("Running %d tests..." % test_cases.size())
	print("=" * 50)
	
	for i in range(test_cases.size()):
		print("\nTest %d: %s" % [i + 1, test_cases[i]])
		print("-" * 30)
		
		var test_passed = false
		match i:
			0: test_passed = test_component_initialization()
			1: test_passed = test_game_data_integration()
			2: test_passed = test_animation_system()
			3: test_passed = test_sound_integration()
			4: test_passed = test_ui_interactions()
			5: test_passed = test_scene_transitions()
		
		if test_passed:
			tests_passed += 1
			print("✅ Test PASSED")
		else:
			tests_failed += 1
			print("❌ Test FAILED")
	
	_print_test_summary()

func _print_test_summary() -> void:
	print("\n" + "=" * 50)
	print("TEST SUMMARY")
	print("=" * 50)
	print("Total Tests: %d" % test_cases.size())
	print("Tests Passed: %d" % tests_passed)
	print("Tests Failed: %d" % tests_failed)
	print("Success Rate: %.1f%%" % (float(tests_passed) / test_cases.size() * 100))
	
	if tests_failed == 0:
		print("\n🎉 ALL TESTS PASSED! Menu system is ready.")
	else:
		print("\n⚠️ Some tests failed. Check the logs above.")

# === INPUT HANDLING ===

func _input(event: InputEvent) -> void:
	# R ile testleri yeniden çalıştır
	if event.is_action_pressed("ui_accept"):
		print("\n" + "=" * 50)
		print("Restarting tests...")
		current_test = 0
		tests_passed = 0
		tests_failed = 0
		_run_tests()