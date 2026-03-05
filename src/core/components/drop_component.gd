# 🎁 DROP COMPONENT
# Item drop sistemi için atomic component
class_name DropComponent
extends Component

# ItemEntity class'ını kullanabilmek için
const ItemEntity = preload("res://src/gameplay/entities/item_entity.gd")

# === DROP CONFIG ===
var drop_table: Array = []  # {item_id, weight, min_count, max_count}
var guaranteed_drops: Array = []  # Her ölümde kesin düşen item'lar
var currency_drop_range: Dictionary = {"min": 0, "max": 10}
var experience_drop_range: Dictionary = {"min": 5, "max": 20}
var drop_radius: float = 30.0  # Drop'ların yayılma yarıçapı

# === SIGNALS ===
signal item_dropped(item_id: String, count: int, position: Vector2)
signal currency_dropped(amount: int, position: Vector2)
signal experience_dropped(amount: int, position: Vector2)
signal drops_generated(drops: Array)
signal drop_table_changed()

# === LIFECYCLE ===

func _initialize() -> void:
	print("DropComponent initialized")

# === PUBLIC API ===

func generate_drops(difficulty: int = 1) -> Array:
	var drops = []
	
	# Guaranteed drops
	for item_id in guaranteed_drops:
		var drop_data = _find_drop_data(item_id)
		if drop_data:
			var count = randi_range(drop_data["min_count"], drop_data["max_count"])
			drops.append({"item_id": item_id, "count": count})
	
	# Weighted random drops
	var total_weight = _calculate_total_weight()
	
	if total_weight > 0:
		# Difficulty'ye göre drop sayısı
		var drop_count = randi_range(1, max(1, difficulty))
		
		for i in range(drop_count):
			var random_weight = randi_range(1, total_weight)
			var current_weight = 0
			
			for drop in drop_table:
				current_weight += drop["weight"]
				if random_weight <= current_weight:
					var count = randi_range(drop["min_count"], drop["max_count"])
					drops.append({
						"item_id": drop["item_id"],
						"count": count
					})
					break
	
	# Currency drop
	var currency_amount = randi_range(currency_drop_range["min"], currency_drop_range["max"])
	if currency_amount > 0:
		drops.append({
			"item_id": "currency",
			"count": currency_amount,
			"type": "currency"
		})
	
	# Experience drop
	var experience_amount = randi_range(experience_drop_range["min"], experience_drop_range["max"])
	if experience_amount > 0:
		drops.append({
			"item_id": "experience",
			"count": experience_amount,
			"type": "experience"
		})
	
	drops_generated.emit(drops)
	return drops

func spawn_drops(drops: Array, spawn_position: Vector2) -> void:
	var drop_positions = _calculate_drop_positions(spawn_position, drops.size())
	
	for i in range(drops.size()):
		var drop = drops[i]
		var drop_position = spawn_position
		
		if i < drop_positions.size():
			drop_position = drop_positions[i]
		
		_spawn_single_drop(drop, drop_position)

func add_drop(item_id: String, weight: int, min_count: int = 1, max_count: int = 1) -> void:
	# Mevcut drop'u güncelle veya yeni ekle
	for drop in drop_table:
		if drop["item_id"] == item_id:
			drop["weight"] = weight
			drop["min_count"] = min_count
			drop["max_count"] = max_count
			drop_table_changed.emit()
			return
	
	# Yeni drop ekle
	drop_table.append({
		"item_id": item_id,
		"weight": weight,
		"min_count": min_count,
		"max_count": max_count
	})
	drop_table_changed.emit()

func remove_drop(item_id: String) -> bool:
	for i in range(drop_table.size()):
		if drop_table[i]["item_id"] == item_id:
			drop_table.remove_at(i)
			drop_table_changed.emit()
			return true
	return false

func set_currency_drop_range(min_amount: int, max_amount: int) -> void:
	currency_drop_range = {
		"min": max(0, min_amount),
		"max": max(min_amount, max_amount)
	}

func set_experience_drop_range(min_amount: int, max_amount: int) -> void:
	experience_drop_range = {
		"min": max(0, min_amount),
		"max": max(min_amount, max_amount)
	}

func add_guaranteed_drop(item_id: String) -> void:
	if not item_id in guaranteed_drops:
		guaranteed_drops.append(item_id)

func remove_guaranteed_drop(item_id: String) -> bool:
	var index = guaranteed_drops.find(item_id)
	if index != -1:
		guaranteed_drops.remove_at(index)
		return true
	return false

func clear_drop_table() -> void:
	drop_table.clear()
	guaranteed_drops.clear()
	currency_drop_range = {"min": 0, "max": 10}
	experience_drop_range = {"min": 5, "max": 20}
	drop_table_changed.emit()

func get_drop_table_info() -> Dictionary:
	var total_weight = _calculate_total_weight()
	
	return {
		"drop_table": drop_table.duplicate(true),
		"guaranteed_drops": guaranteed_drops.duplicate(true),
		"total_weight": total_weight,
		"currency_range": currency_drop_range.duplicate(true),
		"experience_range": experience_drop_range.duplicate(true)
	}

func apply_difficulty_multiplier(multiplier: float) -> void:
	# Drop chance'ları artır
	for drop in drop_table:
		drop["weight"] = int(drop["weight"] * multiplier)
	
	# Currency ve experience range'leri artır
	currency_drop_range["min"] = int(currency_drop_range["min"] * multiplier)
	currency_drop_range["max"] = int(currency_drop_range["max"] * multiplier)
	experience_drop_range["min"] = int(experience_drop_range["min"] * multiplier)
	experience_drop_range["max"] = int(experience_drop_range["max"] * multiplier)

# === PRIVATE METHODS ===

func _calculate_total_weight() -> int:
	var total = 0
	for drop in drop_table:
		total += drop["weight"]
	return total

func _find_drop_data(item_id: String) -> Dictionary:
	for drop in drop_table:
		if drop["item_id"] == item_id:
			return drop
	return {}

func _calculate_drop_positions(center: Vector2, count: int) -> Array:
	var positions = []
	
	for i in range(count):
		var angle = (float(i) / float(count)) * 2.0 * PI
		var offset = Vector2(cos(angle), sin(angle)) * drop_radius
		positions.append(center + offset)
	
	return positions

func _spawn_single_drop(drop: Dictionary, drop_position: Vector2) -> void:
	if drop.get("type") == "currency":
		# Currency drop
		currency_dropped.emit(drop["count"], drop_position)
		
		# EventBus'a bildir
		EventBus.emit_now_static(EventBus.ITEM_PICKED_UP, {
			"picker": null,
			"item_id": "currency",
			"item_count": drop["count"],
			"position": drop_position,
			"source": "drop_component"
		})
		
	elif drop.get("type") == "experience":
		# Experience drop
		experience_dropped.emit(drop["count"], drop_position)
		
		# EventBus'a bildir
		EventBus.emit_now_static(EventBus.ITEM_PICKED_UP, {
			"picker": null,
			"item_id": "experience",
			"item_count": drop["count"],
			"position": drop_position,
			"source": "drop_component"
		})
		
	else:
		# Item drop
		var item_id = drop["item_id"]
		var count = drop["count"]
		
		# Item entity oluştur
		var item_entity = ItemEntity.new()
		
		# Item'ı başlat
		item_entity.initialize(item_id, count, drop_position)
		
		# Scene'e ekle
		if entity and entity.get_parent():
			entity.get_parent().add_child(item_entity)
		
		# Signal emit et
		item_dropped.emit(item_id, count, drop_position)
		
		# EventBus'a bildir
		EventBus.emit_now_static(EventBus.ITEM_DROPPED, {
			"item_id": item_id,
			"item_count": count,
			"position": drop_position,
			"source_entity": entity,
			"item_entity": item_entity
		})

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	
	data["drop_table"] = drop_table.duplicate(true)
	data["guaranteed_drops"] = guaranteed_drops.duplicate(true)
	data["currency_drop_range"] = currency_drop_range.duplicate(true)
	data["experience_drop_range"] = experience_drop_range.duplicate(true)
	data["drop_radius"] = drop_radius
	
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	if "drop_table" in data:
		drop_table = data["drop_table"]
	if "guaranteed_drops" in data:
		guaranteed_drops = data["guaranteed_drops"]
	if "currency_drop_range" in data:
		currency_drop_range = data["currency_drop_range"]
	if "experience_drop_range" in data:
		experience_drop_range = data["experience_drop_range"]
	if "drop_radius" in data:
		drop_radius = data["drop_radius"]

# === DEBUG ===

func _to_string() -> String:
	var total_weight = _calculate_total_weight()
	var drop_count = drop_table.size()
	var guaranteed_count = guaranteed_drops.size()
	
	return "[DropComponent: %d drops (%d guaranteed) | Total Weight: %d]" % [
		drop_count,
		guaranteed_count,
		total_weight
	]

func print_drop_info() -> void:
	var info = get_drop_table_info()
	
	print("=== Drop Component Info ===")
	print("Total Drop Weight: %d" % info["total_weight"])
	print("Guaranteed Drops: %s" % str(info["guaranteed_drops"]))
	print("Currency Range: %d-%d" % [info["currency_range"]["min"], info["currency_range"]["max"]])
	print("Experience Range: %d-%d" % [info["experience_range"]["min"], info["experience_range"]["max"]])
	
	print("Drop Table:")
	for drop in info["drop_table"]:
		print("  %s: weight=%d, count=%d-%d" % [
			drop["item_id"],
			drop["weight"],
			drop["min_count"],
			drop["max_count"]
		])