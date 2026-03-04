# 🧪 SETTINGS SCREEN TEST MODULE
# SettingsScreenOrganism testlerini yönetir
class_name SettingsScreenTestModule
extends UITestBase

# === STATE ===
var test_cases = [
	{
		"name": "SettingsScreenOrganism Basic",
		"function": "_test_settingsscreen_organism_basic"
	},
	{
		"name": "SettingsScreenOrganism Audio Controls",
		"function": "_test_settingsscreen_organism_audio_controls"
	},
	{
		"name": "SettingsScreenOrganism Graphics Controls",
		"function": "_test_settingsscreen_organism_graphics_controls"
	}
]

# === LIFECYCLE ===

func _ready() -> void:
	module_name = "SettingsScreen"
	test_queue = test_cases.duplicate()
	super._ready()

# === TEST CASES IMPLEMENTATION ===

func _test_settingsscreen_organism_basic() -> bool:
	print("Running: SettingsScreenOrganism Basic Test")
	
	var settings_screen = SettingsScreenOrganism.new()
	settings_screen.name = "TestSettingsScreen"
	
	test_container.add_child(settings_screen)
	settings_screen.position = Vector2(20, 20)
	settings_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Screen initialization
	if not settings_screen.is_initialized:
		print("FAIL: SettingsScreen not initialized")
		test_passed = false
	
	# Test 2: Default visibility
	if not settings_screen.show_title:
		print("FAIL: Title should be visible by default")
		test_passed = false
	
	if not settings_screen.show_sections:
		print("FAIL: Sections should be visible by default")
		test_passed = false
	
	if not settings_screen.show_background:
		print("FAIL: Background should be visible by default")
		test_passed = false
	
	# Test 3: Screen visibility toggle
	settings_screen.hide_settings_screen()
	
	await get_tree().process_frame
	
	if settings_screen.visible:
		print("FAIL: Screen should be hidden")
		test_passed = false
	
	settings_screen.show_settings_screen()
	
	await get_tree().process_frame
	
	if not settings_screen.visible:
		print("FAIL: Screen should be visible")
		test_passed = false
	
	# Test 4: Fade animations
	settings_screen.fade_out()
	
	await get_tree().create_timer(settings_screen.fade_duration + 0.1).timeout
	
	if settings_screen.visible:
		print("FAIL: Screen should be hidden after fade out")
		test_passed = false
	
	settings_screen.fade_in()
	
	await get_tree().create_timer(settings_screen.fade_duration + 0.1).timeout
	
	if not settings_screen.visible:
		print("FAIL: Screen should be visible after fade in")
		test_passed = false
	
	# Test 5: Settings changed flag
	if settings_screen.are_settings_changed():
		print("FAIL: Settings should not be changed initially")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: SettingsScreenOrganism Basic Test")
	
	return test_passed

func _test_settingsscreen_organism_audio_controls() -> bool:
	print("Running: SettingsScreenOrganism Audio Controls Test")
	
	var settings_screen = SettingsScreenOrganism.new()
	settings_screen.name = "TestSettingsScreenAudio"
	
	test_container.add_child(settings_screen)
	settings_screen.position = Vector2(20, 20)
	settings_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Initial audio settings
	var initial_master = settings_screen.get_setting("audio", "master_volume", 80)
	if initial_master != 80:
		print("FAIL: Initial master volume should be 80")
		test_passed = false
	
	var initial_music = settings_screen.get_setting("audio", "music_volume", 70)
	if initial_music != 70:
		print("FAIL: Initial music volume should be 70")
		test_passed = false
	
	var initial_sfx = settings_screen.get_setting("audio", "sfx_volume", 90)
	if initial_sfx != 90:
		print("FAIL: Initial SFX volume should be 90")
		test_passed = false
	
	# Test 2: Volume setting
	settings_screen.set_setting("audio", "master_volume", 50)
	
	await get_tree().process_frame
	
	var new_master = settings_screen.get_setting("audio", "master_volume", 80)
	if new_master != 50:
		print("FAIL: Master volume should be 50")
		test_passed = false
	
	# Test 3: Settings changed flag
	if not settings_screen.are_settings_changed():
		print("FAIL: Settings should be marked as changed")
		test_passed = false
	
	# Test 4: Multiple volume changes
	settings_screen.set_setting("audio", "music_volume", 60)
	settings_screen.set_setting("audio", "sfx_volume", 75)
	
	await get_tree().process_frame
	
	var final_music = settings_screen.get_setting("audio", "music_volume", 70)
	var final_sfx = settings_screen.get_setting("audio", "sfx_volume", 90)
	
	if final_music != 60:
		print("FAIL: Music volume should be 60")
		test_passed = false
	
	if final_sfx != 75:
		print("FAIL: SFX volume should be 75")
		test_passed = false
	
	# Test 5: Save settings
	settings_screen.save_settings()
	
	await get_tree().process_frame
	
	if settings_screen.are_settings_changed():
		print("FAIL: Settings should not be changed after save")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: SettingsScreenOrganism Audio Controls Test")
	
	return test_passed

func _test_settingsscreen_organism_graphics_controls() -> bool:
	print("Running: SettingsScreenOrganism Graphics Controls Test")
	
	var settings_screen = SettingsScreenOrganism.new()
	settings_screen.name = "TestSettingsScreenGraphics"
	
	test_container.add_child(settings_screen)
	settings_screen.position = Vector2(20, 20)
	settings_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Initial graphics settings
	var initial_quality = settings_screen.get_setting("graphics", "quality", "medium")
	if initial_quality != "medium":
		print("FAIL: Initial quality should be medium")
		test_passed = false
	
	var initial_resolution = settings_screen.get_setting("graphics", "resolution", "1920x1080")
	if initial_resolution != "1920x1080":
		print("FAIL: Initial resolution should be 1920x1080")
		test_passed = false
	
	var initial_vsync = settings_screen.get_setting("graphics", "vsync", true)
	if not initial_vsync:
		print("FAIL: Initial VSync should be true")
		test_passed = false
	
	# Test 2: Quality setting
	settings_screen.set_setting("graphics", "quality", "high")
	
	await get_tree().process_frame
	
	var new_quality = settings_screen.get_setting("graphics", "quality", "medium")
	if new_quality != "high":
		print("FAIL: Quality should be high")
		test_passed = false
	
	# Test 3: Resolution setting
	settings_screen.set_setting("graphics", "resolution", "1600x900")
	
	await get_tree().process_frame
	
	var new_resolution = settings_screen.get_setting("graphics", "resolution", "1920x1080")
	if new_resolution != "1600x900":
		print("FAIL: Resolution should be 1600x900")
		test_passed = false
	
	# Test 4: VSync setting
	settings_screen.set_setting("graphics", "vsync", false)
	
	await get_tree().process_frame
	
	var new_vsync = settings_screen.get_setting("graphics", "vsync", true)
	if new_vsync:
		print("FAIL: VSync should be false")
		test_passed = false
	
	# Test 5: Reset settings
	settings_screen.reset_settings()
	
	await get_tree().process_frame
	
	var reset_quality = settings_screen.get_setting("graphics", "quality", "")
	var reset_resolution = settings_screen.get_setting("graphics", "resolution", "")
	var reset_vsync = settings_screen.get_setting("graphics", "vsync", false)
	
	if reset_quality != "medium":
		print("FAIL: Quality should be reset to medium")
		test_passed = false
	
	if reset_resolution != "1920x1080":
		print("FAIL: Resolution should be reset to 1920x1080")
		test_passed = false
	
	if not reset_vsync:
		print("FAIL: VSync should be reset to true")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: SettingsScreenOrganism Graphics Controls Test")
	
	return test_passed