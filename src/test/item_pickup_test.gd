# 🎁 ITEM PICKUP TEST COMPONENT
# Item pickup sistemini test etmek için atomic component
class_name ItemPickupTest
extends Node

# === TEST CONFIG ===
var test_items: Array = [
	"health_pack_small",
	"coin_small", 
	"experience_gem_small",
	"speed_boost",
	"ammo_pack"
]

var test_player: Node = null
var spawned_items: Array = []
var test_results: Dictionary = {}

# === SIGNALS ===
signal test_started(test_name: String)
signal test_completed(test_name: String, result: bool)
signal item_spawned(item_id: String, position: Vector2)
signal item_picked_up(item_id: String, picker: Node)
signal test_summary(results: Dictionary)

# === LIFECYCLE ===

func _ready() -> void:
	print("ItemPickupTest initialized")

# === PUBLIC API ===

func run_comprehensive_test(player: Node) -> void:
	test_player = player
	test_results.clear()
	
	print("\n=== ITEM PICKUP COMPREHENSIVE TEST BAŞLATILIYOR ===")
	test_started.emit("comprehensive_item_pickup_test")
	
	# 1. Item spawn test
	_test_item_spawn()
	
	# 2. Auto-pickup test
	_test_auto_pickup()
	
	# 3. Inventory integration test
	_test_inventory_integration()
	
	# 4. EventBus integration test
	_test_eventbus_integration()
	
	# 5. Rarity system test
	_test_rarity_system()
	
	# 6. Drop system test
	_test_drop_system()
	
	# Test sonuçlarını göster
	_print_test_summary()
	
	test_completed.emit("comprehensive_item_pickup_test", _all_tests_passed())

func run_quick_test(player: Node) -> void:
	test_player = player
	
	print("\n=== ITEM PICKUP QUICK TEST ===")
	
	# Sadece temel testler
	_test_item_spawn()
	_test_inventory_integration()
	
	print("Quick test tamamlandı!")

# === INDIVIDUAL TESTS ===

func _test_item_spawn() -> bool:
	print("\n1. Item Spawn Test:")
	
	var success = true
	spawned_items.clear()
	
	for i in range(3):
		var item_id = test_items[i % test_items.size()]
		var spawn_position = Vector2(500 + i * 100, 300)
		
		# Item entity oluştur
		var item_scene = preload("res://src/gameplay/entities/item_entity.gd")
		var item_entity = item_scene.new()
		
		# Item'ı başlat
		item_entity.initialize(item_id, 1, spawn_position)
		
		# Scene'e ekle
		if get_parent():
			get_parent().add_child(item_entity)
			spawned_items.append(item_entity)
		
		print("   Spawned %s at %s" % [item_id, str(spawn_position)])
		item_spawned.emit(item_id, spawn_position)
		
		# Item'ın doğru şekilde oluştuğunu kontrol et
		if item_entity.item_id != item_id:
			print("   ✗ Item ID mismatch: %s != %s" % [item_entity.item_id, item_id])
			success = false
		else:
			print("   ✓ Item spawned correctly")
	
	test_results["item_spawn"] = success
	return success

func _test_auto_pickup() -> bool:
	print("\n2. Auto-Pickup Test:")
	
	if spawned_items.is_empty():
		print("   ✗ No items to test")
		test_results["auto_pickup"] = false
		return false
	
	var success = true
	var item = spawned_items[0]
	
	# Player'ı item'a yaklaştır
	if test_player:
		test_player.position = item.position + Vector2(40, 0)  # Auto-pickup range içinde
		
		# Bir frame bekle
		await get_tree().process_frame
		
		# Item'ın pickup edilip edilmediğini kontrol et
		if not item.is_collectible:
			print("   ✗ Item not collectible")
			success = false
		else:
			print("   ✓ Auto-pickup system working")
	
	test_results["auto_pickup"] = success
	return success

func _test_inventory_integration() -> bool:
	print("\n3. Inventory Integration Test:")
	
	if not test_player:
		print("   ✗ No player to test")
		test_results["inventory_integration"] = false
		return false
	
	var success = true
	
	# Inventory component'ını al
	var inventory_component = test_player.get_component("InventoryComponent")
	if not inventory_component:
		print("   ✗ No InventoryComponent found")
		test_results["inventory_integration"] = false
		return false
	
	# Test item'larını ekle
	for item_id in ["health_pack_small", "coin_small"]:
		var added_count = inventory_component.add_item(item_id, 2)
		
		if added_count == 2:
			print("   ✓ Added %s x2 to inventory" % item_id)
		else:
			print("   ✗ Failed to add %s to inventory" % item_id)
			success = false
	
	# Inventory'yi kontrol et
	var health_count = inventory_component.get_item_count("health_pack_small")
	var coin_count = inventory_component.get_item_count("coin_small")
	
	if health_count >= 2 and coin_count >= 2:
		print("   ✓ Inventory correctly updated")
	else:
		print("   ✗ Inventory counts incorrect")
		success = false
	
	test_results["inventory_integration"] = success
	return success

func _test_eventbus_integration() -> bool:
	print("\n4. EventBus Integration Test:")
	
	var success = true
	var event_received = false
	
	# Event listener ekle
	var listener = func(event: EventBus.Event):
		if event.type == EventBus.ITEM_PICKED_UP:
			event_received = true
			print("   ✓ ITEM_PICKED_UP event received")
	
	# EventBus'ı kontrol et
	var event_bus = _get_event_bus()
	if not event_bus:
		print("   ✗ EventBus not available")
		test_results["eventbus_integration"] = false
		return false
	
	# Listener'ı ekle
	event_bus.subscribe(EventBus.ITEM_PICKED_UP, listener)
	
	# Test event'i gönder
	event_bus.emit_now(EventBus.ITEM_PICKED_UP, {
		"picker": test_player,
		"item_id": "test_item",
		"item_count": 1
	})
	
	# Listener'ı kaldır
	event_bus.unsubscribe(EventBus.ITEM_PICKED_UP, listener)
	
	if event_received:
		print("   ✓ EventBus integration working")
	else:
		print("   ✗ No event received")
		success = false
	
	test_results["eventbus_integration"] = success
	return success

func _test_rarity_system() -> bool:
	print("\n5. Rarity System Test:")
	
	var success = true
	
	# Farklı rarity'de item'lar oluştur
	var rarity_items = [
		{"id": "health_pack_small", "expected_rarity": "common"},
		{"id": "speed_boost", "expected_rarity": "uncommon"},
		{"id": "health_pack_large", "expected_rarity": "rare"},
		{"id": "key", "expected_rarity": "epic"}
	]
	
	for rarity_item in rarity_items:
		var item_scene = preload("res://src/gameplay/entities/item_entity.gd")
		var item_entity = item_scene.new()
		
		# Config'den rarity'yi kontrol et
		var config_manager = ConfigManager.get_instance()
		if config_manager:
			var item_config = config_manager.get_item_config(rarity_item["id"])
			var config_rarity = item_config.get("rarity", "common")
			
			if config_rarity == rarity_item["expected_rarity"]:
				print("   ✓ %s rarity correct: %s" % [rarity_item["id"], config_rarity])
			else:
				print("   ✗ %s rarity mismatch: %s != %s" % [
					rarity_item["id"], 
					config_rarity, 
					rarity_item["expected_rarity"]
				])
				success = false
		else:
			print("   ✗ ConfigManager not available")
			success = false
	
	test_results["rarity_system"] = success
	return success

func _test_drop_system() -> bool:
	print("\n6. Drop System Test:")
	
	var success = true
	
	# Drop component oluştur
	var drop_component = DropComponent.new()
	
	# Drop table ayarla
	drop_component.clear_drop_table()
	drop_component.add_drop("health_pack_small", 50, 1, 1)
	drop_component.add_drop("coin_small", 30, 1, 3)
	drop_component.add_drop("experience_gem_small", 20, 1, 2)
	drop_component.set_currency_drop_range(1, 5)
	drop_component.set_experience_drop_range(5, 10)
	
	# Drop'ları generate et
	var drops = drop_component.generate_drops(1)
	
	if drops.size() > 0:
		print("   ✓ Generated %d drops" % drops.size())
		
		# Drop'ları spawn et
		drop_component.spawn_drops(drops, Vector2(500, 300))
		print("   ✓ Drops spawned successfully")
	else:
		print("   ✗ No drops generated")
		success = false
	
	# Drop table info'yu kontrol et
	var drop_info = drop_component.get_drop_table_info()
	if drop_info["total_weight"] == 100:  # 50 + 30 + 20
		print("   ✓ Drop weights correct")
	else:
		print("   ✗ Drop weights incorrect: %d" % drop_info["total_weight"])
		success = false
	
	test_results["drop_system"] = success
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
	print("\n=== ITEM PICKUP TEST SONUÇLARI ===")
	
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
	
	return "[ItemPickupTest: %d/%d passed]" % [passed, total]

func print_test_info() -> void:
	print("=== Item Pickup Test Info ===")
	print("Test Items: %s" % str(test_items))
	print("Spawned Items: %d" % spawned_items.size())
	print("Test Results: %s" % str(test_results))