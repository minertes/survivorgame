# 📊 ENEMY STATS COMPONENT
# Düşman istatistikleri için atomic component
class_name EnemyStatsComponent
extends Component

# === ENEMY TYPES ===
enum EnemyType {
	BASIC,
	FAST,
	TANK,
	RANGED,
	BOSS
}

# === ENEMY STATS ===
var enemy_type: EnemyType = EnemyType.BASIC
var enemy_difficulty: int = 1
var enemy_value: int = 10  # Öldürüldüğünde verilen puan/exp
var base_health: float = 50.0
var base_speed: float = 150.0
var base_damage: float = 10.0
var attack_cooldown: float = 1.0

# === SCALING ===
var health_scaling: float = 1.3  # Her difficulty level için health artışı
var damage_scaling: float = 1.2  # Her difficulty level için damage artışı
var value_scaling: float = 1.5   # Her difficulty level için value artışı

# === SIGNALS ===
signal enemy_type_changed(old_type: EnemyType, new_type: EnemyType)
signal difficulty_changed(old_difficulty: int, new_difficulty: int)
signal stats_updated()

# === LIFECYCLE ===

func _initialize() -> void:
	print("EnemyStatsComponent initialized")
	_update_stats()

# === PUBLIC API ===

func set_enemy_type(type: EnemyType) -> void:
	if enemy_type == type:
		return
	
	var old_type = enemy_type
	enemy_type = type
	
	# Type'a göre base stats'ı ayarla
	_set_base_stats_by_type()
	
	enemy_type_changed.emit(old_type, enemy_type)
	stats_updated.emit()

func set_difficulty(difficulty: int) -> void:
	difficulty = max(1, difficulty)
	
	if enemy_difficulty == difficulty:
		return
	
	var old_difficulty = enemy_difficulty
	enemy_difficulty = difficulty
	
	_update_stats()
	
	difficulty_changed.emit(old_difficulty, enemy_difficulty)
	stats_updated.emit()

func get_scaled_health() -> float:
	return base_health * pow(health_scaling, enemy_difficulty - 1)

func get_scaled_speed() -> float:
	return base_speed  # Speed genellikle scaling yapılmaz

func get_scaled_damage() -> float:
	return base_damage * pow(damage_scaling, enemy_difficulty - 1)

func get_scaled_value() -> int:
	return int(enemy_value * pow(value_scaling, enemy_difficulty - 1))

func get_reward() -> Dictionary:
	var scaled_value = get_scaled_value()
	
	return {
		"experience": scaled_value,
		"score": scaled_value,
		"coins": enemy_difficulty * 5,
		"type": enemy_type,
		"difficulty": enemy_difficulty
	}

func get_enemy_type_name() -> String:
	return EnemyType.keys()[enemy_type]

func get_difficulty_multiplier() -> float:
	return 1.0 + (enemy_difficulty - 1) * 0.2

func get_config_for_type() -> Dictionary:
	match enemy_type:
		EnemyType.BASIC:
			return {
				"name": "Basic Enemy",
				"health": 50.0,
				"speed": 150.0,
				"damage": 10.0,
				"value": 10,
				"attack_cooldown": 1.0,
				"detection_range": 250.0,
				"attack_range": 40.0
			}
		
		EnemyType.FAST:
			return {
				"name": "Fast Enemy",
				"health": 30.0,
				"speed": 250.0,
				"damage": 8.0,
				"value": 15,
				"attack_cooldown": 0.8,
				"detection_range": 350.0,
				"attack_range": 30.0
			}
		
		EnemyType.TANK:
			return {
				"name": "Tank Enemy",
				"health": 150.0,
				"speed": 100.0,
				"damage": 20.0,
				"value": 25,
				"attack_cooldown": 1.5,
				"detection_range": 200.0,
				"attack_range": 60.0
			}
		
		EnemyType.RANGED:
			return {
				"name": "Ranged Enemy",
				"health": 40.0,
				"speed": 180.0,
				"damage": 15.0,
				"value": 20,
				"attack_cooldown": 2.0,
				"detection_range": 400.0,
				"attack_range": 150.0
			}
		
		EnemyType.BOSS:
			return {
				"name": "Boss Enemy",
				"health": 500.0,
				"speed": 120.0,
				"damage": 30.0,
				"value": 100,
				"attack_cooldown": 3.0,
				"detection_range": 500.0,
				"attack_range": 80.0
			}
		
		_:
			return {}

# === PRIVATE METHODS ===

func _set_base_stats_by_type() -> void:
	var config = get_config_for_type()
	
	if config.is_empty():
		return
	
	base_health = config["health"]
	base_speed = config["speed"]
	base_damage = config["damage"]
	enemy_value = config["value"]
	attack_cooldown = config["attack_cooldown"]
	
	# Entity name'i güncelle
	if entity:
		entity.entity_name = config["name"]
	
	# AI component'ını güncelle
	var ai_component = entity.get_component("EnemyAIComponent") if entity else null
	if ai_component:
		ai_component.set_detection_range(config["detection_range"])
		ai_component.set_attack_range(config["attack_range"])
		
		# Fast enemy için chase speed multiplier
		if enemy_type == EnemyType.FAST:
			ai_component.set_chase_speed_multiplier(1.5)
		elif enemy_type == EnemyType.TANK:
			ai_component.set_chase_speed_multiplier(0.8)
		else:
			ai_component.set_chase_speed_multiplier(1.2)

func _update_stats() -> void:
	# Scaling uygula
	var scaled_health = get_scaled_health()
	var scaled_damage = get_scaled_damage()
	
	# Health component'ını güncelle
	var health_component = entity.get_component("HealthComponent") if entity else null
	if health_component:
		health_component.set_max_health(scaled_health, true)
	
	# Movement component'ını güncelle
	var movement_component = entity.get_component("MovementComponent") if entity else null
	if movement_component:
		movement_component.speed = base_speed
	
	# Drop component scaling
	var drop_component = entity.get_component("DropComponent") if entity else null
	if drop_component:
		drop_component.apply_difficulty_multiplier(get_difficulty_multiplier())

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	
	data["enemy_type"] = enemy_type
	data["enemy_difficulty"] = enemy_difficulty
	data["enemy_value"] = enemy_value
	data["base_health"] = base_health
	data["base_speed"] = base_speed
	data["base_damage"] = base_damage
	data["attack_cooldown"] = attack_cooldown
	data["health_scaling"] = health_scaling
	data["damage_scaling"] = damage_scaling
	data["value_scaling"] = value_scaling
	
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	if "enemy_type" in data:
		enemy_type = data["enemy_type"]
	if "enemy_difficulty" in data:
		enemy_difficulty = data["enemy_difficulty"]
	if "enemy_value" in data:
		enemy_value = data["enemy_value"]
	if "base_health" in data:
		base_health = data["base_health"]
	if "base_speed" in data:
		base_speed = data["base_speed"]
	if "base_damage" in data:
		base_damage = data["base_damage"]
	if "attack_cooldown" in data:
		attack_cooldown = data["attack_cooldown"]
	if "health_scaling" in data:
		health_scaling = data["health_scaling"]
	if "damage_scaling" in data:
		damage_scaling = data["damage_scaling"]
	if "value_scaling" in data:
		value_scaling = data["value_scaling"]
	
	_update_stats()

# === DEBUG ===

func _to_string() -> String:
	var scaled_health = get_scaled_health()
	var scaled_damage = get_scaled_damage()
	var scaled_value = get_scaled_value()
	
	return "[EnemyStatsComponent: %s | Difficulty: %d | HP: %.1f | DMG: %.1f | Value: %d]" % [
		get_enemy_type_name(),
		enemy_difficulty,
		scaled_health,
		scaled_damage,
		scaled_value
	]

func print_stats_info() -> void:
	print("=== Enemy Stats Info ===")
	print("Type: %s" % get_enemy_type_name())
	print("Difficulty: %d" % enemy_difficulty)
	print("Base Health: %.1f" % base_health)
	print("Base Speed: %.1f" % base_speed)
	print("Base Damage: %.1f" % base_damage)
	print("Attack Cooldown: %.1f" % attack_cooldown)
	print("Value: %d" % enemy_value)
	
	print("=== Scaled Stats ===")
	print("Scaled Health: %.1f" % get_scaled_health())
	print("Scaled Damage: %.1f" % get_scaled_damage())
	print("Scaled Value: %d" % get_scaled_value())
	print("Difficulty Multiplier: %.1f" % get_difficulty_multiplier())
	
	print("=== Scaling Factors ===")
	print("Health Scaling: %.1f" % health_scaling)
	print("Damage Scaling: %.1f" % damage_scaling)
	print("Value Scaling: %.1f" % value_scaling)