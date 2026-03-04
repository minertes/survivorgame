# 🔫 WEAPON FIRING TEST COMPONENT
# Weapon ve projectile sistemini test etmek için atomic component
class_name WeaponFiringTest
extends Node

# === TEST CONFIG ===
var test_weapons: Array = ["pistol", "shotgun", "machine_gun"]
var test_player: Node = null
var spawned_projectiles: Array = []
var test_results: Dictionary = {}

# === SIGNALS ===
signal test_started(test_name: String)
signal test_completed(test_name: String, result: bool)
signal weapon_fired(weapon_id: String, projectile_count: int)
signal projectile_created(projectile: Node2D)
signal projectile_hit(target: Node2D, damage: float)
signal test_summary(results: Dictionary)

# === LIFECYCLE ===

func _ready() -> void:
	print("WeaponFiringTest initialized")

# === PUBLIC API ===

func run_comprehensive_test(player: Node) -> void:
	test_player = player
	test_results.clear()
	
	print("\n=== WEAPON FIRING COMPREHENSIVE TEST BAŞLATILIYOR ===")
	test_started.emit("comprehensive_weapon_firing_test")
	
	# 1. Weapon component test
	_test_weapon_component()
	
	# 2. Projectile spawning test
	_test_projectile_spawning()
	
	# 3. Damage calculation test
	_test_damage_calculation()
	
	# 4. Multishot test
	_test_multishot()
	
	# 5. Critical hit test
	_test_critical_hits()
	
	# 6. EventBus integration test
	_test_weapon_eventbus_integration()
	
	# 7. Combat system integration test
	_test_combat_integration()
	
	# Test sonuçlarını göster
	_print_test_summary()
	
	test_completed.emit("comprehensive_weapon_firing_test", _all_tests_passed())

func run_quick_test(player: Node) -> void:
	test_player = player
	
	print("\n=== WEAPON FIRING QUICK TEST ===")
	
	# Sadece temel testler
	_test_weapon_component()
	_test_projectile_spawning()
	
	print("Quick test tamamlandı!")

# === INDIVIDUAL TESTS ===

func _test_weapon_component() -> bool:
	print("\n1. Weapon Component Test:")
	
	if not test_player:
		print("   ✗ No player to test")
		test_results["weapon_component"] = false
		return false
	
	var success = true
	
	# Weapon component'ını al
	var weapon_component = test_player.get_component("WeaponComponent")
	if not weapon_component:
		print("   ✗ No WeaponComponent found")
		test_results["weapon_component"] = false
		return false
	
	# Weapon stats'larını kontrol et
	print("   Current Weapon: %s" % weapon_component.current_weapon_id)
	print("   Ammo: %d/%d" % [
		weapon_component.current_ammo,
		weapon_component.weapon_data.get("magazine_size", 1) if weapon_component.current_weapon_id in weapon_component.weapon_data else 0
	])
	
	# Weapon değiştirme testi
	for weapon_id in test_weapons:
		if weapon_component.set_weapon(weapon_id):
			print("   ✓ Switched to %s" % weapon_id)
			
			# Weapon stats'larını kontrol et
			var damage = weapon_component.get_stat("damage")
			var fire_rate = weapon_component.get_stat("fire_rate")
			var magazine = weapon_component.get_stat("magazine_size")
			
			print("     Damage: %.1f, Fire Rate: %.1f, Magazine: %d" % [damage, fire_rate, magazine])
		else:
			print("   ✗ Failed to switch to %s" % weapon_id)
			success = false
	
	test_results["weapon_component"] = success
	return success

func _test_projectile_spawning() -> bool:
	print("\n2. Projectile Spawning Test:")
	
	if not test_player:
		print("   ✗ No player to test")
		test_results["projectile_spawning"] = false
		return false
	
	var success = true
	spawned_projectiles.clear()
	
	# Weapon component'ını al
	var weapon_component = test_player.get_component("WeaponComponent")
	if not weapon_component:
		print("   ✗ No WeaponComponent found")
		test_results["projectile_spawning"] = false
		return false
	
	# Pistol ile test et
	weapon_component.set_weapon("pistol")
	
	# Fire test
	var target_position = test_player.position + Vector2(200, 0)
	var fire_result = weapon_component.fire(target_position)
	
	if fire_result:
		print("   ✓ Weapon fired successfully")
		
		# Projectile'ları kontrol et (bir frame sonra)
		await get_tree().process_frame
		
		# Scene'deki projectile'ları bul
		var projectiles = get_tree().get_nodes_in_group("projectiles")
		if projectiles.size() > 0:
			print("   ✓ %d projectile spawned" % projectiles.size())
			spawned_projectiles = projectiles.duplicate()
			
			# Projectile özelliklerini kontrol et
			for projectile in projectiles:
				if projectile.has_method("get_projectile_info"):
					var info = projectile.get_projectile_info()
					print("     Projectile: %s, Damage: %.1f, Speed: %.1f" % [
						info.get("weapon_id", "unknown"),
						info.get("damage", 0),
						info.get("speed", 0)
					])
					
					projectile_created.emit(projectile)
		else:
			print("   ✗ No projectiles spawned")
			success = false
	else:
		print("   ✗ Weapon failed to fire")
		success = false
	
	test_results["projectile_spawning"] = success
	return success

func _test_damage_calculation() -> bool:
	print("\n3. Damage Calculation Test:")
	
	var success = true
	
	# CombatSystem'i al
	var combat_system = _get_combat_system()
	if not combat_system:
		print("   ✗ CombatSystem not available")
		test_results["damage_calculation"] = false
		return false
	
	# Test entity'leri oluştur
	var attacker = Node2D.new()
	var defender = Node2D.new()
	
	# Damage calculation test
	var base_damage = 50.0
	var damage_result = combat_system.calculate_damage(base_damage, attacker, defender, "physical")
	
	print("   Base Damage: %.1f" % base_damage)
	print("   Final Damage: %.1f" % damage_result.final_damage)
	print("   Critical: %s (%.1fx)" % [
		"✓" if damage_result.is_critical else "✗",
		damage_result.critical_multiplier
	])
	print("   Damage Type: %s" % damage_result.damage_type)
	
	if damage_result.final_damage > 0:
		print("   ✓ Damage calculation working")
	else:
		print("   ✗ Damage calculation failed")
		success = false
	
	# Cleanup
	attacker.queue_free()
	defender.queue_free()
	
	test_results["damage_calculation"] = success
	return success

func _test_multishot() -> bool:
	print("\n4. Multishot Test:")
	
	if not test_player:
		print("   ✗ No player to test")
		test_results["multishot"] = false
		return false
	
	var success = true
	
	# Weapon component'ını al
	var weapon_component = test_player.get_component("WeaponComponent")
	if not weapon_component:
		print("   ✗ No WeaponComponent found")
		test_results["multishot"] = false
		return false
	
	# Multishot ayarla
	weapon_component.set_multishot(3)
	weapon_component.set_spread_angle(30.0)
	
	print("   Multishot: %d projectiles" % weapon_component.multishot_count)
	print("   Spread Angle: %.1f degrees" % weapon_component.spread_angle)
	
	# Fire test
	var target_position = test_player.position + Vector2(200, 0)
	weapon_component.fire(target_position)
	
	# Projectile'ları kontrol et (bir frame sonra)
	await get_tree().process_frame
	
	var projectiles = get_tree().get_nodes_in_group("projectiles")
	var new_projectiles = []
	
	for projectile in projectiles:
		if not projectile in spawned_projectiles:
			new_projectiles.append(projectile)
	
	if new_projectiles.size() >= 3:
		print("   ✓ Multishot spawned %d projectiles" % new_projectiles.size())
		
		# Projectile yönlerini kontrol et
		for i in range(new_projectiles.size()):
			var projectile = new_projectiles[i]
			var direction = projectile.direction if projectile.has_property("direction") else Vector2.ZERO
			print("     Projectile %d direction: %s" % [i + 1, str(direction)])
	else:
		print("   ✗ Multishot failed: %d projectiles" % new_projectiles.size())
		success = false
	
	test_results["multishot"] = success
	return success

func _test_critical_hits() -> bool:
	print("\n5. Critical Hit Test:")
	
	var success = true
	
	# CombatSystem'i al
	var combat_system = _get_combat_system()
	if not combat_system:
		print("   ✗ CombatSystem not available")
		test_results["critical_hits"] = false
		return false
	
	# Critical hit stats'larını al
	var stats = combat_system.get_stats()
	print("   Recent Critical Hits: %d" % stats.recent_critical_hits)
	print("   Critical Hit Chance: %.1f%%" % (stats.critical_hit_chance * 100))
	print("   Average Critical Multiplier: %.1fx" % stats.average_critical_multiplier)
	
	# Multiple damage calculation test (critical chance'ı test et)
	var critical_count = 0
	var total_tests = 100
	
	for i in range(total_tests):
		var damage_result = combat_system.calculate_damage(50.0, Node2D.new(), Node2D.new(), "physical")
		if damage_result.is_critical:
			critical_count += 1
	
	var actual_chance = float(critical_count) / float(total_tests) * 100
	print("   Actual Critical Rate: %.1f%% (%d/%d)" % [actual_chance, critical_count, total_tests])
	
	# Critical chance makul bir aralıkta mı? (0-20%)
	if actual_chance >= 0 and actual_chance <= 20:
		print("   ✓ Critical hit system working")
	else:
		print("   ✗ Critical hit chance out of range")
		success = false
	
	test_results["critical_hits"] = success
	return success

func _test_weapon_eventbus_integration() -> bool:
	print("\n6. EventBus Integration Test:")
	
	var success = true
	var events_received = {
		"weapon_fired": false,
		"projectile_fired": false,
		"damage_dealt": false
	}
	
	# Event listener'ları ekle
	var event_bus = _get_event_bus()
	if not event_bus:
		print("   ✗ EventBus not available")
		test_results["eventbus_integration"] = false
		return false
	
	# Listener fonksiyonları
	var weapon_fired_listener = func(event: EventBus.Event):
		events_received["weapon_fired"] = true
		print("   ✓ WEAPON_FIRED event received")
	
	var projectile_fired_listener = func(event: EventBus.Event):
		events_received["projectile_fired"] = true
		print("   ✓ PROJECTILE_FIRED event received")
	
	var damage_dealt_listener = func(event: EventBus.Event):
		events_received["damage_dealt"] = true
		print("   ✓ DAMAGE_DEALT event received")
	
	# Listener'ları ekle
	event_bus.subscribe(EventBus.WEAPON_FIRED, weapon_fired_listener)
	event_bus.subscribe(EventBus.PROJECTILE_FIRED, projectile_fired_listener)
	event_bus.subscribe(EventBus.DAMAGE_DEALT, damage_dealt_listener)
	
	# Test event'leri gönder
	event_bus.emit_now(EventBus.WEAPON_FIRED, {
		"weapon_id": "test_weapon",
		"position": Vector2.ZERO
	})
	
	event_bus.emit_now(EventBus.PROJECTILE_FIRED, {
		"projectile": Node2D.new(),
		"weapon_id": "test_weapon"
	})
	
	event_bus.emit_now(EventBus.DAMAGE_DEALT, {
		"damage": 25.0,
		"attacker": test_player,
		"target": Node2D.new()
	})
	
	# Listener'ları kaldır
	event_bus.unsubscribe(EventBus.WEAPON_FIRED, weapon_fired_listener)
	event_bus.unsubscribe(EventBus.PROJECTILE_FIRED, projectile_fired_listener)
	event_bus.unsubscribe(EventBus.DAMAGE_DEALT, damage_dealt_listener)
	
	# Sonuçları kontrol et
	var all_events_received = true
	for event_name in events_received:
		if not events_received[event_name]:
			print("   ✗ %s event not received" % event_name)
			all_events_received = false
	
	if all_events_received:
		print("   ✓ All weapon events received")
	else:
		success = false
	
	test_results["eventbus_integration"] = success
	return success

func _test_combat_integration() -> bool:
	print("\n7. Combat System Integration Test:")
	
	var success = true
	
	# CombatSystem'i al
	var combat_system = _get_combat_system()
	if not combat_system:
		print("   ✗ CombatSystem not available")
		test_results["combat_integration"] = false
		return false
	
	# Test entity'leri oluştur
	var attacker = Node2D.new()
	attacker.name = "TestAttacker"
	
	var defender = Node2D.new()
	defender.name = "TestDefender"
	
	# Status effect test
	combat_system.apply_status_effect(defender, CombatSystem.StatusEffect.BURN, 5.0, 10.0, attacker)
	print("   ✓ Applied BURN status effect")
	
	# Knockback test
	combat_system.apply_knockback(defender, Vector2(100, 0), attacker)
	print("   ✓ Applied knockback")
	
	# Combat log test
	combat_system.apply_damage(attacker, defender, 35.0, "fire")
	print("   ✓ Applied fire damage")
	
	# Stats kontrolü
	var stats = combat_system.get_stats()
	print("   Active Status Effects: %d" % stats.active_status_effects)
	print("   Targets with Effects: %d" % stats.targets_with_effects)
	
	if stats.active_status_effects > 0:
		print("   ✓ Combat system integration working")
	else:
		print("   ✗ No active status effects")
		success = false
	
	# Cleanup
	attacker.queue_free()
	defender.queue_free()
	
	test_results["combat_integration"] = success
	return success

# === UTILITY METHODS ===

func _get_event_bus() -> EventBus:
	# EventBus instance'ını bul
	var event_bus = EventBus.get_instance()
	if event_bus:
		return event_bus
	
	# Fallback: Scene'de ara
	var nodes = get_tree().get_nodes_in_group("event_bus")
	if nodes.size() > 0:
		return nodes[0] as EventBus
	
	return null

func _get_combat_system() -> CombatSystem:
	# CombatSystem instance'ını bul
	var nodes = get_tree().get_nodes_in_group("combat_system")
	if nodes.size() > 0:
		return nodes[0] as CombatSystem
	
	return null

func _all_tests_passed() -> bool:
	for test_name in test_results:
		if not test_results[test_name]:
			return false
	return true

func _print_test_summary() -> void:
	print("\n=== WEAPON FIRING TEST SONUÇLARI ===")
	
	var passed = 0
	var total = test_results.size()
	
	for test_name in test_results:
		var result = test_results[test_name]
		var status = "✓" if result else "✗"
		
		print("  %s %s" % [status, test_name])
		if result:
			passed += 1
	
	print("\n  Başarı: %d/%d (%.1f%%)" % [passed, total, (float(passed) / float(total)) * 100])
	
	if passed == total:
		print("\n  🎉 TÜM TESTLER BAŞARILI!")
	else:
		print("\n  ⚠️  BAZI TESTLER BAŞARISIZ!")
	
	# Signal emit et
	test_summary.emit(test_results)

# === DEBUG ===

func _to_string() -> String:
	var passed = 0
	var total = test_results.size()
	
	for result in test_results.values():
		if result:
			passed += 1
	
	return "[WeaponFiringTest: %d/%d passed]" % [passed, total]

func print_test_info() -> void:
	print("=== Weapon Firing Test Info ===")
	print("Test Weapons: %s" % str(test_weapons))
	print("Spawned Projectiles: %d" % spawned_projectiles.size())
	print("Test Results: %s" % str(test_results))