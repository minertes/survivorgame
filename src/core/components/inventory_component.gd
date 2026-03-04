# 🎒 INVENTORY COMPONENT
# Envanter yönetimi için atomic component
class_name InventoryComponent
extends Component

# === INVENTORY CONFIG ===
var max_slots: int = 20
var max_stack_size: int = 99

# === INVENTORY STATE ===
var items: Array[Dictionary] = []  # Her slot: {id, count, data}
var equipped_items: Dictionary = {}  # slot_type → item_id
var currency: Dictionary = {
	"coins": 0,
	"gems": 0,
	"keys": 0
}

# === QUICK SLOTS ===
var quick_slots: Array = [null, null, null, null]  # 4 quick slot

# === SIGNALS ===
signal inventory_changed()
signal item_added(item_id: String, count: int, slot: int)
signal item_removed(item_id: String, count: int, slot: int)
signal item_used(item_id: String, slot: int)
signal currency_changed(currency_type: String, old_amount: int, new_amount: int)
signal equipment_changed(slot_type: String, old_item: String, new_item: String)
signal quick_slot_changed(slot_index: int, item_id: String)

# === LIFECYCLE ===

func _initialize() -> void:
	# Inventory'yi başlat
	_initialize_inventory()
	
	print("InventoryComponent initialized with %d slots" % max_slots)

func _initialize_inventory() -> void:
	# Tüm slot'ları boş olarak başlat
	items.resize(max_slots)
	for i in range(max_slots):
		items[i] = _create_empty_slot()

# === PUBLIC API ===

func add_item(item_id: String, count: int = 1) -> int:
	if count <= 0:
		return 0
	
	# Önce stack'lenebilir item'lar için mevcut slot'ları kontrol et
	var remaining = count
	
	# Stack'lenebilir item'lar için mevcut slot'ları doldur
	remaining = _add_to_existing_stacks(item_id, remaining)
	
	# Kalan item'lar için yeni slot'lar oluştur
	while remaining > 0 and _has_empty_slots():
		var stack_size = min(remaining, max_stack_size)
		var slot = _find_empty_slot()
		
		if slot == -1:
			break
		
		items[slot] = {
			"id": item_id,
			"count": stack_size,
			"data": _get_item_data(item_id)
		}
		
		item_added.emit(item_id, stack_size, slot)
		remaining -= stack_size
	
	inventory_changed.emit()
	return count - remaining  # Başarıyla eklenen miktar

func remove_item(item_id: String, count: int = 1) -> int:
	if count <= 0:
		return 0
	
	var remaining = count
	
	# Ters sırada dolaş (son eklenenler ilk çıkar)
	for i in range(items.size() - 1, -1, -1):
		if items[i]["id"] == item_id:
			var remove_count = min(items[i]["count"], remaining)
			items[i]["count"] -= remove_count
			remaining -= remove_count
			
			item_removed.emit(item_id, remove_count, i)
			
			# Slot boşsa temizle
			if items[i]["count"] <= 0:
				items[i] = _create_empty_slot()
			
			if remaining <= 0:
				break
	
	if remaining < count:
		inventory_changed.emit()
	
	return count - remaining  # Başarıyla çıkarılan miktar

func use_item(slot: int) -> bool:
	if slot < 0 or slot >= items.size():
		return false
	
	if _is_slot_empty(slot):
		return false
	
	var item = items[slot]
	var item_id = item["id"]
	
	# Item kullan
	if _use_item_effect(item_id):
		# Consumable ise count azalt
		if _is_item_consumable(item_id):
			items[slot]["count"] -= 1
			
			# Slot boşsa temizle
			if items[slot]["count"] <= 0:
				items[slot] = _create_empty_slot()
		
		item_used.emit(item_id, slot)
		inventory_changed.emit()
		return true
	
	return false

func get_item_count(item_id: String) -> int:
	var total = 0
	for item in items:
		if item["id"] == item_id:
			total += item["count"]
	return total

func has_item(item_id: String, count: int = 1) -> bool:
	return get_item_count(item_id) >= count

func find_item_slot(item_id: String) -> int:
	for i in range(items.size()):
		if items[i]["id"] == item_id:
			return i
	return -1

func find_empty_slot() -> int:
	return _find_empty_slot()

func get_item_at_slot(slot: int) -> Dictionary:
	if slot < 0 or slot >= items.size():
		return _create_empty_slot()
	return items[slot].duplicate(true)

func set_item_at_slot(slot: int, item_id: String, count: int = 1) -> bool:
	if slot < 0 or slot >= items.size():
		return false
	
	if count <= 0:
		# Clear slot
		items[slot] = _create_empty_slot()
	else:
		items[slot] = {
			"id": item_id,
			"count": min(count, max_stack_size),
			"data": _get_item_data(item_id)
		}
	
	inventory_changed.emit()
	return true

func swap_slots(slot_a: int, slot_b: int) -> bool:
	if slot_a < 0 or slot_a >= items.size() or slot_b < 0 or slot_b >= items.size():
		return false
	
	var temp = items[slot_a]
	items[slot_a] = items[slot_b]
	items[slot_b] = temp
	
	inventory_changed.emit()
	return true

# === CURRENCY ===

func add_currency(currency_type: String, amount: int) -> int:
	if amount <= 0 or not currency_type in currency:
		return 0
	
	var old_amount = currency[currency_type]
	currency[currency_type] += amount
	
	currency_changed.emit(currency_type, old_amount, currency[currency_type])
	return amount

func remove_currency(currency_type: String, amount: int) -> int:
	if amount <= 0 or not currency_type in currency:
		return 0
	
	var old_amount = currency[currency_type]
	var actual_remove = min(amount, old_amount)
	currency[currency_type] -= actual_remove
	
	currency_changed.emit(currency_type, old_amount, currency[currency_type])
	return actual_remove

func get_currency(currency_type: String) -> int:
	return currency.get(currency_type, 0)

func has_currency(currency_type: String, amount: int) -> bool:
	return get_currency(currency_type) >= amount

# === EQUIPMENT ===

func equip_item(slot_type: String, item_id: String) -> bool:
	if not _is_equippable_item(item_id):
		return false
	
	var old_item = equipped_items.get(slot_type)
	equipped_items[slot_type] = item_id
	
	equipment_changed.emit(slot_type, old_item, item_id)
	return true

func unequip_item(slot_type: String) -> bool:
	if not slot_type in equipped_items:
		return false
	
	var old_item = equipped_items[slot_type]
	equipped_items.erase(slot_type)
	
	equipment_changed.emit(slot_type, old_item, "")
	return true

func get_equipped_item(slot_type: String) -> String:
	return equipped_items.get(slot_type, "")

func is_item_equipped(item_id: String) -> bool:
	return item_id in equipped_items.values()

# === QUICK SLOTS ===

func set_quick_slot(slot_index: int, item_id: String) -> bool:
	if slot_index < 0 or slot_index >= quick_slots.size():
		return false
	
	# Item'ın inventory'de olduğundan emin ol
	if item_id != "" and not has_item(item_id, 1):
		return false
	
	quick_slots[slot_index] = item_id
	quick_slot_changed.emit(slot_index, item_id)
	return true

func use_quick_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= quick_slots.size():
		return false
	
	var item_id = quick_slots[slot_index]
	if item_id == null or item_id == "":
		return false
	
	# Item'ı bul ve kullan
	var slot = find_item_slot(item_id)
	if slot != -1:
		return use_item(slot)
	
	return false

func get_quick_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= quick_slots.size():
		return ""
	return quick_slots[slot_index] if quick_slots[slot_index] != null else ""

# === INVENTORY MANAGEMENT ===

func get_used_slots() -> int:
	var count = 0
	for item in items:
		if not _is_slot_empty_by_item(item):
			count += 1
	return count

func get_empty_slots() -> int:
	return max_slots - get_used_slots()

func is_full() -> bool:
	return get_empty_slots() == 0

func clear_inventory() -> void:
	for i in range(items.size()):
		items[i] = _create_empty_slot()
	
	equipped_items.clear()
	
	for i in range(quick_slots.size()):
		quick_slots[i] = null
	
	inventory_changed.emit()

func get_inventory_weight() -> float:
	var weight = 0.0
	for item in items:
		if not _is_slot_empty_by_item(item):
			var item_data = _get_item_data(item["id"])
			weight += item["count"] * item_data.get("weight", 1.0)
	return weight

# === PRIVATE METHODS ===

func _create_empty_slot() -> Dictionary:
	return {
		"id": "",
		"count": 0,
		"data": {}
	}

func _is_slot_empty(slot: int) -> bool:
	if slot < 0 or slot >= items.size():
		return true
	return items[slot]["id"] == "" or items[slot]["count"] <= 0

func _is_slot_empty_by_item(item: Dictionary) -> bool:
	return item["id"] == "" or item["count"] <= 0

func _find_empty_slot() -> int:
	for i in range(items.size()):
		if _is_slot_empty(i):
			return i
	return -1

func _has_empty_slots() -> bool:
	return _find_empty_slot() != -1

func _add_to_existing_stacks(item_id: String, count: int) -> int:
	var remaining = count
	
	for i in range(items.size()):
		if items[i]["id"] == item_id and items[i]["count"] < max_stack_size:
			var available_space = max_stack_size - items[i]["count"]
			var add_amount = min(remaining, available_space)
			
			items[i]["count"] += add_amount
			remaining -= add_amount
			
			item_added.emit(item_id, add_amount, i)
			
			if remaining <= 0:
				break
	
	return remaining

func _get_item_data(item_id: String) -> Dictionary:
	var config_manager = _get_config_manager()
	if config_manager:
		return config_manager.get_item_config(item_id)
	return {}

func _is_item_consumable(item_id: String) -> bool:
	var item_data = _get_item_data(item_id)
	return item_data.get("type", "") == "consumable"

func _is_equippable_item(item_id: String) -> bool:
	var item_data = _get_item_data(item_id)
	var item_type = item_data.get("type", "")
	return item_type in ["weapon", "armor", "accessory"]

func _use_item_effect(item_id: String) -> bool:
	var item_data = _get_item_data(item_id)
	
	# Entity'ye item effect'ini uygula
	if entity:
		match item_data.get("type", ""):
			"consumable":
				return _apply_consumable_effect(item_id, item_data)
			"buff":
				return _apply_buff_effect(item_id, item_data)
			"currency":
				return _apply_currency_effect(item_id, item_data)
			"experience":
				return _apply_experience_effect(item_id, item_data)
			_:
				return false
	
	return false

func _apply_consumable_effect(item_id: String, item_data: Dictionary) -> bool:
	# Health restore
	if "heal_amount" in item_data:
		var health_component = entity.get_component("HealthComponent") if entity else null
		if health_component:
			health_component.heal(item_data["heal_amount"])
			return true
	
	# Ammo restore
	if "refill_percentage" in item_data:
		var weapon_component = entity.get_component("WeaponComponent") if entity else null
		if weapon_component:
			# Ammo refill logic (sonra implemente edilecek)
			return true
	
	return false

func _apply_buff_effect(item_id: String, item_data: Dictionary) -> bool:
	# Buff component'ı eklendikten sonra implemente edilecek
	print("Applying buff: %s" % item_id)
	return true

func _apply_currency_effect(item_id: String, item_data: Dictionary) -> bool:
	if "coin_amount" in item_data:
		add_currency("coins", item_data["coin_amount"])
		return true
	return false

func _apply_experience_effect(item_id: String, item_data: Dictionary) -> bool:
	if "experience_amount" in item_data and entity and entity.has_method("gain_experience"):
		entity.gain_experience(item_data["experience_amount"])
		return true
	return false

func _get_config_manager():
	if ComponentManager.is_available():
		return ConfigManager.get_instance()
	return null

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	
	data["max_slots"] = max_slots
	data["max_stack_size"] = max_stack_size
	data["items"] = items.duplicate(true)
	data["equipped_items"] = equipped_items.duplicate(true)
	data["currency"] = currency.duplicate(true)
	data["quick_slots"] = quick_slots.duplicate(true)
	
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	if "max_slots" in data:
		max_slots = data["max_slots"]
	if "max_stack_size" in data:
		max_stack_size = data["max_stack_size"]
	if "items" in data:
		items = data["items"]
	if "equipped_items" in data:
		equipped_items = data["equipped_items"]
	if "currency" in data:
		currency = data["currency"]
	if "quick_slots" in data:
		quick_slots = data["quick_slots"]
	
	# Inventory boyutunu ayarla
	items.resize(max_slots)
	for i in range(items.size()):
		if i >= data.get("items", []).size():
			items[i] = _create_empty_slot()

# === DEBUG ===

func _to_string() -> String:
	var used_slots = get_used_slots()
	var currency_str = "Coins: %d" % currency["coins"]
	if currency["gems"] > 0:
		currency_str += ", Gems: %d" % currency["gems"]
	
	return "[InventoryComponent: %d/%d slots | %s]" % [
		used_slots,
		max_slots,
		currency_str
	]

func print_inventory() -> void:
	print("=== Inventory ===")
	print("Slots: %d/%d" % [get_used_slots(), max_slots])
	print("Currency: %s" % str(currency))
	
	if not equipped_items.is_empty():
		print("Equipped Items:")
		for slot_type in equipped_items:
			print("  %s: %s" % [slot_type, equipped_items[slot_type]])
	
	print("Items:")
	for i in range(items.size()):
		if not _is_slot_empty(i):
			var item = items[i]
			print("  Slot %d: %s x%d" % [i, item["id"], item["count"]])
	
	print("Quick Slots:")
	for i in range(quick_slots.size()):
		var item_id = quick_slots[i]
		if item_id != null and item_id != "":
			print("  Quick Slot %d: %s" % [i, item_id])