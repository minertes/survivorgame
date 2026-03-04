# 🧪 UPGRADE SCREEN TEST MODULE
# UpgradeScreenOrganism testlerini yönetir
class_name UpgradeScreenTestModule
extends UITestBase

# === STATE ===
var test_cases = [
	{
		"name": "UpgradeScreenOrganism Basic",
		"function": "_test_upgradescreen_organism_basic"
	},
	{
		"name": "UpgradeScreenOrganism Weapon Management",
		"function": "_test_upgradescreen_organism_weapon_management"
	},
	{
		"name": "UpgradeScreenOrganism Upgrade Logic",
		"function": "_test_upgradescreen_organism_upgrade_logic"
	}
]

# === LIFECYCLE ===

func _ready() -> void:
	module_name = "UpgradeScreen"
	test_queue = test_cases.duplicate()
	super._ready()

# === TEST CASES IMPLEMENTATION ===

func _test_upgradescreen_organism_basic() -> bool:
	print("Running: UpgradeScreenOrganism Basic Test")
	
	var upgrade_screen = UpgradeScreenOrganism.new()
	upgrade_screen.name = "TestUpgradeScreen"
	
	test_container.add_child(upgrade_screen)
	upgrade_screen.position = Vector2(20, 20)
	upgrade_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Screen initialization
	if not upgrade_screen.is_initialized:
		print("FAIL: UpgradeScreen not initialized")
		test_passed = false
	
	# Test 2: Default visibility
	if not upgrade_screen.show_title:
		print("FAIL: Title should be visible by default")
		test_passed = false
	
	if not upgrade_screen.show_stats:
		print("FAIL: Stats should be visible by default")
		test_passed = false
	
	if not upgrade_screen.show_weapons:
		print("FAIL: Weapons should be visible by default")
		test_passed = false
	
	if not upgrade_screen.show_background:
		print("FAIL: Background should be visible by default")
		test_passed = false
	
	# Test 3: Screen visibility toggle
	upgrade_screen.hide_upgrade_screen()
	
	await get_tree().process_frame
	
	if upgrade_screen.visible:
		print("FAIL: Screen should be hidden")
		test_passed = false
	
	upgrade_screen.show_upgrade_screen()
	
	await get_tree().process_frame
	
	if not upgrade_screen.visible:
		print("FAIL: Screen should be visible")
		test_passed = false
	
	# Test 4: Fade animations
	upgrade_screen.fade_out()
	
	await get_tree().create_timer(upgrade_screen.fade_duration + 0.1).timeout
	
	if upgrade_screen.visible:
		print("FAIL: Screen should be hidden after fade out")
		test_passed = false
	
	upgrade_screen.fade_in()
	
	await get_tree().create_timer(upgrade_screen.fade_duration + 0.1).timeout
	
	if not upgrade_screen.visible:
		print("FAIL: Screen should be visible after fade in")
		test_passed = false
	
	# Test 5: Weapon cards initialization
	# Weapon card'ları başlatılmış olmalı
	if upgrade_screen.weapon_cards.is_empty():
		print("FAIL: Weapon cards should be initialized")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: UpgradeScreenOrganism Basic Test")
	
	return test_passed

func _test_upgradescreen_organism_weapon_management() -> bool:
	print("Running: UpgradeScreenOrganism Weapon Management Test")
	
	var upgrade_screen = UpgradeScreenOrganism.new()
	upgrade_screen.name = "TestUpgradeScreenWeapon"
	
	test_container.add_child(upgrade_screen)
	upgrade_screen.position = Vector2(20, 20)
	upgrade_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Weapon selection
	var initial_weapon = upgrade_screen.selected_weapon_id
	if initial_weapon.is_empty():
		print("FAIL: Should have initial weapon selected")
		test_passed = false
	
	# Test 2: Weapon level setting
	upgrade_screen.set_weapon_level("pistol", 3)
	
	await get_tree().process_frame
	
	if upgrade_screen.weapon_levels.get("pistol", 1) != 3:
		print("FAIL: Weapon level should be set to 3")
		test_passed = false
	
	# Test 3: Max upgrade level
	upgrade_screen.set_max_upgrade_level(15)
	
	if upgrade_screen.max_upgrade_level != 15:
		print("FAIL: Max upgrade level should be 15")
		test_passed = false
	
	# Test 4: Cost multiplier
	upgrade_screen.set_cost_multiplier(2.0)
	
	if upgrade_screen.cost_multiplier != 2.0:
		print("FAIL: Cost multiplier should be 2.0")
		test_passed = false
	
	# Test 5: Upgrade cost calculation
	var cost = upgrade_screen.calculate_upgrade_cost("pistol", 3)
	if cost <= 0:
		print("FAIL: Upgrade cost should be positive")
		test_passed = false
	
	# Test 6: Can upgrade check
	var can_upgrade = upgrade_screen.can_upgrade("pistol")
	if not can_upgrade:
		print("FAIL: Should be able to upgrade weapon")
		test_passed = false
	
	# Test 7: Max level reached
	upgrade_screen.set_weapon_level("pistol", upgrade_screen.max_upgrade_level)
	can_upgrade = upgrade_screen.can_upgrade("pistol")
	if can_upgrade:
		print("FAIL: Should not be able to upgrade max level weapon")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: UpgradeScreenOrganism Weapon Management Test")
	
	return test_passed

func _test_upgradescreen_organism_upgrade_logic() -> bool:
	print("Running: UpgradeScreenOrganism Upgrade Logic Test")
	
	var upgrade_screen = UpgradeScreenOrganism.new()
	upgrade_screen.name = "TestUpgradeScreenLogic"
	
	test_container.add_child(upgrade_screen)
	upgrade_screen.position = Vector2(20, 20)
	upgrade_screen.size = Vector2(800, 600)
	
	var test_passed = true
	
	await get_tree().process_frame
	
	# Test 1: Initial weapon level
	upgrade_screen.set_weapon_level("pistol", 1)
	var initial_level = upgrade_screen.weapon_levels.get("pistol", 1)
	if initial_level != 1:
		print("FAIL: Initial weapon level should be 1")
		test_passed = false
	
	# Test 2: Perform upgrade
	var upgrade_result = upgrade_screen.perform_upgrade("pistol")
	if not upgrade_result:
		print("FAIL: Upgrade should succeed")
		test_passed = false
	
	# Test 3: Level after upgrade
	var new_level = upgrade_screen.weapon_levels.get("pistol", 1)
	if new_level != 2:
		print("FAIL: Weapon level should be 2 after upgrade")
		test_passed = false
	
	# Test 4: Multiple upgrades
	for i in range(3):
		upgrade_screen.perform_upgrade("pistol")
	
	var final_level = upgrade_screen.weapon_levels.get("pistol", 1)
	if final_level != 5:
		print("FAIL: Weapon level should be 5 after multiple upgrades")
		test_passed = false
	
	# Test 5: Max level upgrade
	upgrade_screen.set_weapon_level("pistol", upgrade_screen.max_upgrade_level)
	upgrade_result = upgrade_screen.perform_upgrade("pistol")
	if upgrade_result:
		print("FAIL: Should not be able to upgrade max level weapon")
		test_passed = false
	
	# Test 6: Cost calculation consistency
	upgrade_screen.set_weapon_level("shotgun", 1)
	var cost1 = upgrade_screen.calculate_upgrade_cost("shotgun", 1)
	var cost2 = upgrade_screen.calculate_upgrade_cost("shotgun", 2)
	
	if cost2 <= cost1:
		print("FAIL: Higher level should have higher cost")
		test_passed = false
	
	await get_tree().process_frame
	
	if test_passed:
		print("PASS: UpgradeScreenOrganism Upgrade Logic Test")
	
	return test_passed