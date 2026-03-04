# 👾 ENEMY DROP TEST COMPONENT
# Enemy drop sistemini test etmek için atomic component
class_name EnemyDropTest
extends Node

# === TEST CONFIG ===
var test_enemies: Array = []
var spawned_items: Array = []
var test_results: Dictionary = {}
var drop_counts: Dictionary = {}

# === SIGNALS ===
signal test_started(test_name: String)
signal test_completed(test_name: String, result: bool)
signal enemy_spawned(enemy_type: String, position: Vector2)
signal enemy_died(enemy: Node, drops: Array)
signal item_dropped(item_id: String, count: int, position: Vector2)
signal test_summary(results: Dictionary)

# === LIFECYCLE ===

func _ready() -> void:
	print("EnemyDropTest initialized")

# === PUBLIC API ===

func run_comprehensive_test() -> void:
	test_results.clear()
	drop_counts.clear()
	
	print("\n=== ENEMY DROP COMPREHENSIVE TEST BAŞLATILIYOR ===")
	test_started.emit("comprehensive_enemy_drop_test")
	
	# 1. Enemy spawn test
	_test_enemy_spawn()
	
	# 2. Drop component test
	_test_drop_component()
	
	# 3. Enemy death drops test
	_test_enemy_death_drops()
	
	# 4. Drop table configuration test
	_test_drop_table_config()
	
	# 5. Rarity distribution test
	_test_rarity_distribution()
	
	# 6. EventBus integration test
	_test_drop_eventbus_integration()
	
	# 7. Multiple enemy types test
	_test_multiple_enemy_types()
	
	# Test sonuçlarını göster
	_print_test_summary()
	
	test_completed.emit("comprehensive_enemy_drop_test", _all_tests_passed())

func run_quick_test() -> void:
	print("\n=== ENEMY DROP QUICK TEST ===")
	
	# Sadece temel testler
	_test_enemy_spawn()
	_test_enemy_death_drops()
	
	print("Quick test tamamlandı!")

# === INDIVIDUAL TESTS ===

func _test_enemy_spawn() -> bool:
	print("\n1. Enemy Spawn Test:")
	
	var success = true
	test_enemies.clear()
	
	# Farklı enemy type'ları spawn et
	var enemy_types = [
		EnemyStatsComponent.EnemyType.BASIC,
		EnemyStatsComponent.EnemyType.FAST,
		EnemyStatsComponent.EnemyType.TANK,
		EnemyStatsComponent.EnemyType.RANGED
	]
	
	for i in range(enemy_types.size()):
		var enemy_type = enemy_types[i]
		var spawn_position = Vector2(400 + i * 150, 300)
		
		# Enemy entity oluştur
		var enemy_scene = preload("res://src/gameplay/entities/enemy_entity.gd")
		var enemy_entity = enemy_scene.new()
		
		# Enemy'yi başlat
		enemy_entity.initialize(enemy_type, 1, spawn_position)
		
		# Scene'e ekle
		if get_parent():
			get_parent().add_child(enemy_entity)
			test_enemies.append(enemy_entity)
		
		var type_name = EnemyStatsComponent.EnemyType.keys()[enemy_type]
		print("   Spawned %s at %s" % [type_name, str(spawn_position)])
		enemy_spawned.emit(type_name, spawn_position)
		
		# Enemy'nin doğru şekilde oluştuğunu kontrol et
		if enemy_entity.enemy_stats.enemy_type == enemy_type:
			print("   ✓ Enemy spawned correctly")
		else:
			print("   ✗ Enemy type mismatch")
			success = false
	
	test_results["enemy_spawn"] = success
	return success

func _test_drop_component() -> bool:
	print("\n2. Drop Component Test:")
	
	if test_enemies.is_empty():
		print("   ✗ No enemies to test")
		test_results["drop_component"] = false
		return false
	
	var success = true
	var enemy = test_enemies[0]
	
	# Drop component'ını al
	var drop_component = enemy.get_component("DropComponent")
	if not drop_component:
		print("   ✗ No DropComponent found")
		test_results["drop_component"] = false
		return false
	
	# Drop table info'yu al
	var drop_info = drop_component.get_drop_table_info()
	
	print("   Drop Table Size: %d" % drop_info["drop_table"].size())
	print("   Total Weight: %d" % drop_info["total_weight"])
	print("   Currency Range: %d-%d" % [drop_info["currency_range"]["min"], drop_info["currency_range"]["max"]])
	print("   Experience Range: %d-%d" % [drop_info["experience_range"]["min"], drop_info["experience_range"]["max"]])
	
	if drop_info["drop_table"].size() > 0:
		print("   ✓ Drop component configured correctly")
	else:
		print("   ✗ Drop table empty")
		success = false
	
	test_results["drop_component"] = success
	return success

func _test_enemy_death_drops() -> bool:
	print("\n3. Enemy Death Drops Test:")
	
	if test_enemies.is_empty():
		print("   ✗ No enemies to test")
		test_results["enemy_death_drops"] = false
		return false
	
	var success = true
	spawned_items.clear()
	drop_counts.clear()
	
	# İlk enemy'yi öldür
	var enemy = test_enemies[0]
	var enemy_type = EnemyStatsComponent.EnemyType.keys()[enemy.enemy_stats.enemy_type]
	
	print("   Killing %s..." % enemy_type)
	
	# Health component'ını al ve öldür
	var health_component = enemy.get_component("HealthComponent")
	if health_component:
		# Enemy'yi öldür
		health_component.take_damage(health_component.current_health + 100, self)
		
		# Bir süre bekle (drop'ların spawn olması için)
		await get_tree().create_timer(0.5).timeout
		
		# Scene'deki item'ları bul
		var items = get_tree().get_nodes_in_group("items")
		spawned_items = items.duplicate()
		
		if spawned_items.size() > 0:
			print("   ✓ Enemy dropped %d items" % spawned_items.size())
			
			# Drop'ları say
			for item in spawned_items:
				if item.has_method("get_item_info"):
					var info = item.get_item_info()
					var item_id = info["id"]
					var count = info["count"]
					
					if not item_id in drop_counts:
						drop_counts[item_id] = 0
					drop_counts[item_id] += count
					
					print("     %s x%d (%s)" % [item_id, count, info["rarity"]])
					item_dropped.emit(item_id, count, item.position)
		else:
			print("   ✗ No items dropped")
			success = false
	else:
		print("   ✗ No HealthComponent found")
		success = false
	
	test_results["enemy_death_drops"] = success
	return success

func _test_drop_table_config() -> bool:
	print("\n4. Drop Table Configuration Test:")
	
	var success = true
	
	# ConfigManager'dan item config'lerini kontrol et
	var config_manager = ConfigManager.get_instance()
	if not config_manager:
		print("   ✗ ConfigManager not available")
		test_results["drop_table_config"] = false
		return false
	
	# Test item'larının config'lerini kontrol et
	var test_item_ids = ["health_pack_small", "coin_small", "experience_gem_small", "speed_boost"]
	
	for item_id in test_item_ids:
		var item_config = config_manager.get_item_config(item_id)
		
		if not item_config.is_empty():
			print("   ✓ %s config loaded" % item_id)
			print("     Name: %s, Type: %s, Rarity: %s" % [
				item_config.get("name", "Unknown"),
				item_config.get("type", "unknown"),
				item_config.get("rarity", "common")
			])
		else:
			print("   ✗ %s config not found" % item_id)
			success = false
	
	# Drop table weight'larını kontrol et
	if test_enemies.size() > 0:
		var enemy = test_enemies[0]
		var drop_component = enemy.get_component("DropComponent")
		
		if drop_component:
			var drop_info = drop_component.get_drop_table_info()
			var total_weight = drop_info["total_weight"]
			
			if total_weight > 0:
				print("   ✓ Drop table weights valid: %d" % total_weight)
			else:
				print("   ✗ Invalid total weight: %d" % total_weight)
				success = false
	
	test_results["drop_table_config"] = success
	return success

func _test_rarity_distribution() -> bool:
	print("\n5. Rarity Distribution Test:")
	
	var success = true
	
	# ConfigManager'dan tüm item'ları al
	var config_manager = ConfigManager.get_instance()
	if not config_manager:
		print("   ✗ ConfigManager not available")
		test_results["rarity_distribution"] = false
		return false
	
	# Item'ları rarity'ye göre grupla
	var rarity_groups = {
		"common": 0,
		"uncommon": 0,
		"rare": 0,
		"epic": 0,
		"legendary": 0
	}
	
	# Tüm item config'lerini al (bu örnek için hardcoded)
	var all_item_ids = [
		"health_pack_small", "health_pack_medium", "health_pack_large",
		"coin_small", "coin_medium", "coin_large",
		"experience_gem_small", "experience_gem_medium", "experience_gem_large",
		"speed_boost", "damage_boost", "invincibility",
		"ammo_pack", "weapon_upgrade", "key",
		"loot_box_common", "loot_box_rare", "loot_box_epic"
	]
	
	for item_id in all_item_ids:
		var item_config = config_manager.get_item_config(item_id)
		if not item_config.is_empty():
			var rarity = item_config.get("rarity", "common")
			if rarity in rarity_groups:
				rarity_groups[rarity] += 1
	
	# Rarity dağılımını göster
	print("   Rarity Distribution:")
	for rarity in rarity_groups:
		var count = rarity_groups[rarity]
		if count > 0:
			print("     %s: %d items" % [rarity.capitalize(), count])
	
	# En az bir common item olmalı
	if rarity_groups["common"] > 0:
		print("   ✓ Rarity distribution valid")
	else:
		print("   ✗ No common items found")
		success = false
	
	test_results["rarity_distribution"] = success
	return success

func _test_drop_eventbus_integration() -> bool:
	print("\n6. EventBus Integration Test:")
	
	var success = true
	var events_received = {
		"enemy_died": false,
		"item_dropped": false,
		"item_picked_up": false
	}
	
	# Event listener'ları ekle
	var event_bus = _get_event_bus()
	if not event_bus:
		print("   ✗ EventBus not available")
		test_results["eventbus_integration"] = false
		return false
	
	# Listener fonksiyonları
	var enemy_died_listener = func(event: EventBus.Event):
		events_received["enemy_died"] = true
		print("   ✓ ENEMY_DIED event received")
	
	var item_dropped_listener = func(event: EventBus.Event):
		events_received["item_dropped"] = true
		print("   ✓ ITEM_DROPPED event received")
	
	var item_picked_up_listener = func(event: EventBus.Event):
		events_received["item_picked_up"] = true
		print("   ✓ ITEM_PICKED_UP event received")
	
	# Listener'ları ekle
	event_bus.subscribe(EventBus.ENEMY_DIED, enemy_died_listener)
	event_bus.subscribe(EventBus.ITEM_DROPPED, item_dropped_listener)
	event_bus.subscribe(EventBus.ITEM_PICKED_UP, item_picked_up_listener)
	
	# Test event'leri gönder
	event_bus.emit_now(EventBus.ENEMY_DIED, {
		"enemy": Node2D.new(),
		"enemy_type": EnemyStatsComponent.EnemyType.BASIC,
		"killer": Node2D.new(),
		"position": Vector2.ZERO
	})
	
	event_bus.emit_now(EventBus.ITEM_DROPPED, {
		"item_id": "test_item",
		"item_count": 1,
		"position": Vector2.ZERO
	})
	
	event_bus.emit_now(EventBus.ITEM_PICKED_UP, {
		"picker": Node2D.new(),
		"item_id": "test_item",
		"item_count": 1
	})
	
	# Listener'ları kaldır
	event_bus.unsubscribe(EventBus.ENEMY_DIED, enemy_died_listener)
	event_bus.unsubscribe(EventBus.ITEM_DROPPED, item_dropped_listener)
	event_bus.unsubscribe(EventBus.ITEM_PICKED_UP, item_picked_up_listener)
	
	# Sonuçları kontrol et
	var all_events_received = true
	for event_name in events_received:
		if not events_received[event_name]:
			print("   ✗ %s event not received" % event_name)
			all_events_received = false
	
	if all_events_received:
		print("   ✓ All drop events received")
	else:
		success = false
	
	test_results["eventbus_integration"] = success
	return success

func _test_multiple_enemy_types() -> bool:
	print("\n7. Multiple Enemy Types Test:")
	
	var success = true
	
	# Farklı enemy type'larının drop table'larını karşılaştır
	if test_enemies.size() < 2:
		print("   ✗ Not enough enemies to compare")
		test_results["multiple_enemy_types"] = false
		return false
	
	var basic_enemy = test_enemies[0]
	var fast_enemy = test_enemies[1]
	
	var basic_drop_component = basic_enemy.get_component("DropComponent")
	var fast_drop_component = fast_enemy.get_component("DropComponent")
	
	if basic_drop_component and fast_drop_component:
		var basic_info = basic_drop_component.get_drop_table_info()
		var fast_info = fast_drop_component.get_drop_table_info()
		
		print("   Basic Enemy Drop Table:")
		for drop in basic_info["drop_table"]:
			print("     %s: weight=%d" % [drop["item_id"], drop["weight"]])
		
		print("   Fast Enemy Drop Table:")
		for drop in fast_info["drop_table"]:
			print("     %s: weight=%d" % [drop["item_id"], drop["weight"]])
		
		# Drop table'ların farklı olup olmadığını kontrol et
		if basic_info["drop_table"] != fast_info["drop_table"]:
			print("   ✓ Different enemy types have different drop tables")
		else:
			print("   ✗ Enemy types have identical drop tables")
			success = false
	else:
		print("   ✗ Could not get drop components")
		success = false
	
	test_results["multiple_enemy_types"] = success
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

func _all_tests_passed() -> bool:
	for test_name in test_results:
		if not test_results[test_name]:
			return false
	return true

func _print_test_summary() -> void:
	print("\n=== ENEMY DROP TEST SONUÇLARI ===")
	
	var passed = 0
	var total = test_results.size()
	
	for test_name in test_results:
		var result = test_results[test_name]
		var status = "✓" if result else "✗"
		
		print("  %s %s" % [status, test_name])
		if result:
			passed += 1
	
	print("\n  Başarı: %d/%d (%.1f%%)" % [passed, total, (float(passed) / float(total)) * 100])
	
	# Drop istatistiklerini göster
	if not drop_counts.is_empty():
		print("\n  Drop Statistics:")
		for item_id in drop_counts:
			print("    %s: %d" % [item_id, drop_counts[item_id]])
	
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
	
	return "[EnemyDropTest: %d/%d passed, %d items dropped]" % [passed, total, spawned_items.size()]

func print_test_info() -> void:
	print("=== Enemy Drop Test Info ===")
	print("Test Enemies: %d" % test_enemies.size())
	print("Spawned Items: %d" % spawned_items.size())
	print("Drop Counts: %s" % str(drop_counts))
	print("Test Results: %s" % str(test_results))