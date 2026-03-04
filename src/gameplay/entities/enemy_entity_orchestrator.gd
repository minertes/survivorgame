# 👾 ENEMY ENTITY ORCHESTRATOR
# Düşman entity'si - Atomic component'ları koordine eder
class_name EnemyEntity
extends Entity

# === COMPONENT REFERENCES ===
var enemy_stats: EnemyStatsComponent = null
var enemy_ai: EnemyAIComponent = null
var health_component: HealthComponent = null
var movement_component: MovementComponent = null
var drop_component: DropComponent = null

# === SIGNALS ===
signal enemy_spotted_target(target: Node2D)
signal enemy_lost_target()
signal enemy_attacked(target: Node2D)
signal enemy_killed(killer: Node = null)
signal enemy_despawned()

# === LIFECYCLE ===

func _initialize_entity() -> void:
	entity_type = "enemy"
	
	# Component'ları oluştur
	_setup_components()
	
	# Event listener'ları bağla
	_setup_event_listeners()
	
	print("EnemyEntity initialized: %s" % entity_name)

func _setup_components() -> void:
	# Enemy Stats Component
	enemy_stats = EnemyStatsComponent.new()
	add_component(enemy_stats)
	
	# Enemy AI Component
	enemy_ai = EnemyAIComponent.new()
	add_component(enemy_ai)
	
	# Health Component
	health_component = HealthComponent.new()
	health_component.max_health = enemy_stats.get_scaled_health()
	health_component.current_health = enemy_stats.get_scaled_health()
	add_component(health_component)
	
	# Movement Component
	movement_component = MovementComponent.new()
	movement_component.speed = enemy_stats.get_scaled_speed()
	add_component(movement_component)
	
	# Drop Component
	drop_component = DropComponent.new()
	_setup_drop_table()
	add_component(drop_component)

func _setup_drop_table() -> void:
	var enemy_type = enemy_stats.enemy_type
	
	match enemy_type:
		EnemyStatsComponent.EnemyType.BASIC:
			drop_component.clear_drop_table()
			drop_component.add_drop("health_pack_small", 15, 1, 1)
			drop_component.add_drop("coin_small", 40, 1, 3)
			drop_component.add_drop("experience_gem_small", 30, 1, 2)
			drop_component.add_drop("ammo_pack", 5, 1, 1)
			drop_component.set_currency_drop_range(1, 5)
			drop_component.set_experience_drop_range(5, 15)
		
		EnemyStatsComponent.EnemyType.FAST:
			drop_component.clear_drop_table()
			drop_component.add_drop("health_pack_small", 10, 1, 1)
			drop_component.add_drop("coin_medium", 25, 1, 2)
			drop_component.add_drop("experience_gem_small", 35, 1, 3)
			drop_component.add_drop("speed_boost", 5, 1, 1)
			drop_component.set_currency_drop_range(3, 8)
			drop_component.set_experience_drop_range(8, 20)
		
		EnemyStatsComponent.EnemyType.TANK:
			drop_component.clear_drop_table()
			drop_component.add_drop("health_pack_medium", 20, 1, 1)
			drop_component.add_drop("coin_small", 30, 2, 5)
			drop_component.add_drop("experience_gem_medium", 25, 1, 2)
			drop_component.add_drop("damage_boost", 8, 1, 1)
			drop_component.add_drop("weapon_upgrade", 2, 1, 1)
			drop_component.set_currency_drop_range(5, 12)
			drop_component.set_experience_drop_range(15, 30)
		
		EnemyStatsComponent.EnemyType.RANGED:
			drop_component.clear_drop_table()
			drop_component.add_drop("health_pack_small", 12, 1, 1)
			drop_component.add_drop("coin_medium", 20, 1, 2)
			drop_component.add_drop("experience_gem_medium", 40, 1, 3)
			drop_component.add_drop("ammo_pack", 15, 1, 1)
			drop_component.add_drop("loot_box_common", 3, 1, 1)
			drop_component.set_currency_drop_range(4, 10)
			drop_component.set_experience_drop_range(12, 25)
		
		EnemyStatsComponent.EnemyType.BOSS:
			drop_component.clear_drop_table()
			drop_component.add_drop("health_pack_large", 30, 1, 2)
			drop_component.add_drop("coin_large", 25, 2, 5)
			drop_component.add_drop("experience_gem_large", 35, 2, 4)
			drop_component.add_drop("invincibility", 10, 1, 1)
			drop_component.add_drop("weapon_upgrade", 15, 1, 2)
			drop_component.add_drop("loot_box_rare", 8, 1, 1)
			drop_component.add_drop("loot_box_epic", 2, 1, 1)
			drop_component.add_drop("key", 5, 1, 1)
			drop_component.add_guaranteed_drop("health_pack_large")
			drop_component.add_guaranteed_drop("coin_large")
			drop_component.set_currency_drop_range(20, 50)
			drop_component.set_experience_drop_range(50, 100)
	
	# Difficulty multiplier uygula
	drop_component.apply_difficulty_multiplier(enemy_stats.get_difficulty_multiplier())

func _setup_event_listeners() -> void:
	# Health component signals
	if health_component:
		health_component.died.connect(_on_health_died)
		health_component.damaged.connect(_on_health_damaged)
	
	# AI component signals
	if enemy_ai:
		enemy_ai.target_spotted.connect(_on_ai_target_spotted)
		enemy_ai.target_lost.connect(_on_ai_target_lost)
		enemy_ai.attack_triggered.connect(_on_ai_attack_triggered)
		enemy_ai.flee_triggered.connect(_on_ai_flee_triggered)
	
	# Drop component signals
	if drop_component:
		drop_component.item_dropped.connect(_on_item_dropped)
		drop_component.currency_dropped.connect(_on_currency_dropped)
		drop_component.experience_dropped.connect(_on_experience_dropped)

# === UPDATE LOOP ===

func update(delta: float) -> void:
	if not is_active or is_destroyed:
		return
	
	# AI movement
	_update_movement(delta)
	
	# Attack cooldown
	_update_attack_cooldown(delta)

func _update_movement(delta: float) -> void:
	if not movement_component or not enemy_ai:
		return
	
	# AI'dan movement direction al
	var direction = enemy_ai.get_movement_direction()
	var speed_multiplier = enemy_ai.get_movement_speed_multiplier()
	
	# Movement component'ı güncelle
	movement_component.speed = enemy_stats.get_scaled_speed() * speed_multiplier
	movement_component.move(direction)
	
	# Hareketi uygula
	if movement_component.velocity.length() > 0:
		position += movement_component.velocity * delta

func _update_attack_cooldown(delta: float) -> void:
	# Attack cooldown mekaniği sonra implemente edilecek
	pass

# === PUBLIC API ===

func initialize(enemy_type: EnemyStatsComponent.EnemyType = EnemyStatsComponent.EnemyType.BASIC, 
			   difficulty: int = 1, spawn_position: Vector2 = Vector2.ZERO) -> void:
	
	# Enemy type ve difficulty ayarla
	enemy_stats.set_enemy_type(enemy_type)
	enemy_stats.set_difficulty(difficulty)
	
	# Position ayarla
	if spawn_position != Vector2.ZERO:
		position = spawn_position
	
	# Entity name'i güncelle
	entity_name = enemy_stats.get_config_for_type().get("name", "Enemy")

func take_damage(amount: float, source: Node = null) -> void:
	if health_component:
		health_component.take_damage(amount, source)

func get_difficulty_multiplier() -> float:
	return enemy_stats.get_difficulty_multiplier()

func get_reward() -> Dictionary:
	return enemy_stats.get_reward()

# === SIGNAL HANDLERS ===

func _on_health_died(killer: Node = null) -> void:
	print("%s died! Killer: %s" % [entity_name, killer.get_name() if killer else "Unknown"])

	# Reward'ı ver
	var reward = get_reward()
	if killer and killer.has_method("gain_experience"):
		killer.gain_experience(reward["experience"])
	if killer and killer.has_method("add_score"):
		killer.add_score(reward["score"])
	
	# Drop'ları oluştur ve spawn et
	if drop_component:
		var drops = drop_component.generate_drops(enemy_stats.enemy_difficulty)
		drop_component.spawn_drops(drops, position)
	
	# EventBus'a enemy died event'i gönder
	EventBus.emit_now_static(EventBus.ENEMY_DIED, {
		"enemy": self,
		"enemy_type": enemy_stats.enemy_type,
		"enemy_difficulty": enemy_stats.enemy_difficulty,
		"killer": killer,
		"position": position,
		"reward": reward
	})
	
	enemy_killed.emit(killer)
	
	# 2 saniye sonra despawn ol
	var despawn_timer = get_tree().create_timer(2.0)
	despawn_timer.timeout.connect(_despawn)

func _on_health_damaged(amount: float, source: Node) -> void:
	# Damage aldığında AI'ya bildir
	if enemy_ai and source:
		enemy_ai.set_target(source)

func _on_ai_target_spotted(target: Node2D) -> void:
	enemy_spotted_target.emit(target)

func _on_ai_target_lost() -> void:
	enemy_lost_target.emit()

func _on_ai_attack_triggered(target: Node2D) -> void:
	# Attack yap
	if target.has_method("take_damage"):
		var damage = enemy_stats.get_scaled_damage()
		target.take_damage(damage, self)
		enemy_attacked.emit(target)

func _on_ai_flee_triggered() -> void:
	print("%s is fleeing!" % entity_name)

func _on_item_dropped(item_id: String, count: int, position: Vector2) -> void:
	# Item dropped event
	pass

func _on_currency_dropped(amount: int, position: Vector2) -> void:
	# Currency dropped event
	pass

func _on_experience_dropped(amount: int, position: Vector2) -> void:
	# Experience dropped event
	pass

func _despawn() -> void:
	print("%s despawned" % entity_name)
	enemy_despawned.emit()
	destroy()

# === CONFIGURATION ===

func set_enemy_type(type: EnemyStatsComponent.EnemyType) -> void:
	enemy_stats.set_enemy_type(type)
	_setup_drop_table()

func set_difficulty(difficulty: int) -> void:
	enemy_stats.set_difficulty(difficulty)

func set_patrol_points(points: Array[Vector2]) -> void:
	if enemy_ai:
		enemy_ai.set_patrol_points(points)

func start_patrolling() -> void:
	if enemy_ai:
		enemy_ai.start_patrolling()

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	
	# Component'lar serialize edilecek
	# (ComponentManager zaten component'ları serialize ediyor)
	
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	# Component'lar deserialize edilecek
	# (ComponentManager zaten component'ları deserialize ediyor)

# === DEBUG ===

func _to_string() -> String:
	var health_str = "N/A"
	if health_component:
		health_str = "%.1f/%.1f" % [health_component.current_health, health_component.max_health]
	
	var ai_state = "N/A"
	if enemy_ai:
		ai_state = enemy_ai.get_state_name()
	
	var target_str = "None"
	if enemy_ai and enemy_ai.target:
		target_str = enemy_ai.target.name
	
	return "[EnemyEntity: %s | Type: %s | HP: %s | AI: %s | Target: %s]" % [
		entity_name,
		enemy_stats.get_enemy_type_name(),
		health_str,
		ai_state,
		target_str
	]

func print_enemy_info() -> void:
	print("=== Enemy Entity Info ===")
	print("Name: %s" % entity_name)
	print("Type: %s" % enemy_stats.get_enemy_type_name())
	print("Difficulty: %d" % enemy_stats.enemy_difficulty)
	print("Value: %d" % enemy_stats.get_scaled_value())
	
	if health_component:
		print("Health: %.1f/%.1f (%.1f%%)" % [
			health_component.current_health,
			health_component.max_health,
			health_component.get_health_percentage() * 100
		])
	
	if enemy_ai:
		print("AI State: %s" % enemy_ai.get_state_name())
		print("Target: %s" % (enemy_ai.target.name if enemy_ai.target else "None"))
	
	if drop_component:
		drop_component.print_drop_info()