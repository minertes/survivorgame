# ⚔️ COMBAT SYSTEM
# Damage calculation, knockback, status effects
class_name CombatSystem
extends Node

# === STATIC ACCESS ===
static var instance: CombatSystem = null

# === STATUS EFFECTS ===
enum StatusEffect {
	BURN,
	FREEZE,
	POISON,
	STUN,
	SLOW,
	WEAKEN,
	BLEED
}

# Status effect data structure
class StatusEffectData:
	var type: StatusEffect
	var duration: float
	var intensity: float
	var source: Node = null
	var timer: Timer = null
	
	func _init(effect_type: StatusEffect, effect_duration: float, effect_intensity: float, effect_source: Node = null):
		type = effect_type
		duration = effect_duration
		intensity = effect_intensity
		source = effect_source
	
	func _to_string() -> String:
		return "[StatusEffect: %s, Duration: %.1f, Intensity: %.1f]" % [StatusEffect.keys()[type], duration, intensity]

# === COMBAT DATA ===
var _active_status_effects: Dictionary = {}  # entity_id → Array[StatusEffectData]
var _damage_modifiers: Dictionary = {}       # damage_type → multiplier
var _critical_hit_history: Array = []        # Recent critical hits for display

# === SIGNALS ===
signal damage_calculated(attacker: Node, target: Node, base_damage: float, final_damage: float, is_critical: bool)
signal status_effect_applied(target: Node, effect: StatusEffectData)
signal status_effect_removed(target: Node, effect: StatusEffectData)
signal status_effect_tick(target: Node, effect: StatusEffectData, damage: float)
signal knockback_applied(target: Node, force: Vector2)
signal combat_log(message: String)

# === LIFECYCLE ===

func _ready() -> void:
	if instance != null:
		push_warning("Multiple CombatSystem instances detected!")
		queue_free()
		return
	
	instance = self
	_initialize_damage_modifiers()
	print("CombatSystem initialized")
	
	# Subscribe to EventBus
	EventBus.subscribe_static(EventBus.DAMAGE_DEALT, _on_damage_dealt)
	EventBus.subscribe_static(EventBus.PROJECTILE_HIT, _on_projectile_hit)

func _exit_tree() -> void:
	if instance == self:
		instance = null
		print("CombatSystem destroyed")

func _process(delta: float) -> void:
	_update_status_effects(delta)

# === PUBLIC API ===

# Calculate final damage with all modifiers
func calculate_damage(base_damage: float, attacker: Node = null, target: Node = null, damage_type: String = "physical") -> Dictionary:
	var final_damage = base_damage
	var is_critical = false
	var critical_multiplier = 1.0
	
	# Apply damage type modifier
	if damage_type in _damage_modifiers:
		final_damage *= _damage_modifiers[damage_type]
	
	# Apply attacker bonuses
	if attacker:
		final_damage = _apply_attacker_bonuses(final_damage, attacker)
	
	# Apply target resistances
	if target:
		final_damage = _apply_target_resistances(final_damage, target, damage_type)
	
	# Critical hit chance
	if attacker:
		var crit_chance = _get_critical_chance(attacker)
		var crit_multiplier = _get_critical_multiplier(attacker)
		
		if randf() < crit_chance:
			is_critical = true
			critical_multiplier = crit_multiplier
			final_damage *= critical_multiplier
	
	# Random variance (±10%)
	var variance = randf_range(0.9, 1.1)
	final_damage *= variance
	
	# Ensure minimum damage
	final_damage = max(1.0, final_damage)
	
	var result = {
		"base_damage": base_damage,
		"final_damage": final_damage,
		"is_critical": is_critical,
		"critical_multiplier": critical_multiplier,
		"damage_type": damage_type,
		"variance": variance
	}
	
	damage_calculated.emit(attacker, target, base_damage, final_damage, is_critical)
	
	# Log to combat log
	if attacker and target:
		var log_message = "%s → %s: %.1f damage" % [
			attacker.name if attacker else "Unknown",
			target.name if target else "Unknown",
			final_damage
		]
		if is_critical:
			log_message += " (CRITICAL!)"
		combat_log.emit(log_message)
	
	return result

# Apply damage to target with all combat mechanics
func apply_damage(attacker: Node, target: Node, base_damage: float, damage_type: String = "physical") -> Dictionary:
	var calculation = calculate_damage(base_damage, attacker, target, damage_type)
	var final_damage = calculation.final_damage
	
	# Get target's health component
	var health_component = ComponentManager.instance.get_first_component_of_type(target, "HealthComponent")
	if health_component:
		health_component.take_damage(final_damage)
		
		# Emit damage event
		EventBus.emit_now_static(EventBus.DAMAGE_DEALT, {
			"attacker": attacker,
			"target": target,
			"damage": final_damage,
			"is_critical": calculation.is_critical,
			"damage_type": damage_type
		})
		
		# Apply on-hit effects
		_apply_on_hit_effects(attacker, target, calculation)
	
	return calculation

# Apply status effect to target
func apply_status_effect(target: Node, effect_type: StatusEffect, duration: float, intensity: float = 1.0, source: Node = null) -> bool:
	if not target:
		return false
	
	var target_id = str(target.get_instance_id())
	var effect_data = StatusEffectData.new(effect_type, duration, intensity, source)
	
	if not target_id in _active_status_effects:
		_active_status_effects[target_id] = []
	
	# Check if effect already exists
	for existing_effect in _active_status_effects[target_id]:
		if existing_effect.type == effect_type:
			# Refresh duration if new effect has longer duration
			if duration > existing_effect.duration:
				existing_effect.duration = duration
				existing_effect.intensity = intensity
				existing_effect.source = source
			
			status_effect_applied.emit(target, existing_effect)
			return true
	
	# Add new effect
	_active_status_effects[target_id].append(effect_data)
	
	# Create timer for effect
	var timer = Timer.new()
	timer.wait_time = 1.0  # Tick every second
	timer.timeout.connect(_on_status_effect_tick.bind(target, effect_data))
	add_child(timer)
	timer.start()
	
	effect_data.timer = timer
	
	status_effect_applied.emit(target, effect_data)
	EventBus.emit_now_static("status_effect_applied", {
		"target": target,
		"effect_type": StatusEffect.keys()[effect_type],
		"duration": duration,
		"intensity": intensity,
		"source": source
	})
	
	return true

# Remove status effect from target
func remove_status_effect(target: Node, effect_type: StatusEffect) -> bool:
	var target_id = str(target.get_instance_id())
	if not target_id in _active_status_effects:
		return false
	
	for i in range(_active_status_effects[target_id].size()):
		var effect = _active_status_effects[target_id][i]
		if effect.type == effect_type:
			# Clean up timer
			if effect.timer:
				effect.timer.queue_free()
			
			_active_status_effects[target_id].remove_at(i)
			status_effect_removed.emit(target, effect)
			
			# Clean up empty arrays
			if _active_status_effects[target_id].is_empty():
				_active_status_effects.erase(target_id)
			
			return true
	
	return false

# Remove all status effects from target
func clear_all_status_effects(target: Node) -> void:
	var target_id = str(target.get_instance_id())
	if not target_id in _active_status_effects:
		return
	
	for effect in _active_status_effects[target_id]:
		if effect.timer:
			effect.timer.queue_free()
		
		status_effect_removed.emit(target, effect)
	
	_active_status_effects.erase(target_id)

# Apply knockback to target
func apply_knockback(target: Node, force: Vector2, source: Node = null) -> bool:
	var movement_component = ComponentManager.instance.get_first_component_of_type(target, "MovementComponent")
	if not movement_component:
		return false
	
	movement_component.apply_knockback(force)
	knockback_applied.emit(target, force)
	
	EventBus.emit_now_static("knockback_applied", {
		"target": target,
		"force": force,
		"source": source
	})
	
	return true

# Get active status effects for target
func get_status_effects(target: Node) -> Array:
	var target_id = str(target.get_instance_id())
	return _active_status_effects.get(target_id, []).duplicate()

# Check if target has specific status effect
func has_status_effect(target: Node, effect_type: StatusEffect) -> bool:
	var effects = get_status_effects(target)
	for effect in effects:
		if effect.type == effect_type:
			return true
	return false

# Get recent critical hits (for UI display)
func get_recent_critical_hits(count: int = 5) -> Array:
	return _critical_hit_history.slice(-count) if _critical_hit_history.size() > count else _critical_hit_history.duplicate()

# === STATIC HELPERS ===

static func get_instance() -> CombatSystem:
	return instance

static func is_available() -> bool:
	return instance != null

# === PRIVATE METHODS ===

func _initialize_damage_modifiers() -> void:
	# Default damage modifiers
	_damage_modifiers = {
		"physical": 1.0,
		"fire": 1.0,
		"ice": 1.0,
		"poison": 1.0,
		"lightning": 1.0,
		"holy": 1.0,
		"dark": 1.0
	}
	
	# Load from config if available
	var config = ConfigManager.instance.get_balance_config()
	if config and "damage_modifiers" in config:
		for damage_type in config.damage_modifiers:
			_damage_modifiers[damage_type] = config.damage_modifiers[damage_type]

func _apply_attacker_bonuses(base_damage: float, attacker: Node) -> float:
	var final_damage = base_damage
	
	# Check for damage bonus components
	var weapon_component = ComponentManager.instance.get_first_component_of_type(attacker, "WeaponComponent")
	if weapon_component:
		# Apply weapon damage multiplier
		var weapon_config = ConfigManager.instance.get_weapon_config(weapon_component.current_weapon_id)
		if weapon_config and "damage_multiplier" in weapon_config:
			final_damage *= weapon_config.damage_multiplier
	
	# Check for experience component (level-based damage)
	var exp_component = ComponentManager.instance.get_first_component_of_type(attacker, "ExperienceComponent")
	if exp_component:
		# 1% damage increase per level
		final_damage *= 1.0 + (exp_component.current_level * 0.01)
	
	return final_damage

func _apply_target_resistances(base_damage: float, target: Node, damage_type: String) -> float:
	var final_damage = base_damage
	
	# TODO: Implement resistance system based on target type/armor
	
	return final_damage

func _get_critical_chance(attacker: Node) -> float:
	var base_crit_chance = 0.05  # 5% base
	
	# Check for weapon critical chance
	var weapon_component = ComponentManager.instance.get_first_component_of_type(attacker, "WeaponComponent")
	if weapon_component:
		var weapon_config = ConfigManager.instance.get_weapon_config(weapon_component.current_weapon_id)
		if weapon_config and "critical_chance" in weapon_config:
			base_crit_chance += weapon_config.critical_chance
	
	return min(base_crit_chance, 1.0)  # Cap at 100%

func _get_critical_multiplier(attacker: Node) -> float:
	var base_crit_multiplier = 2.0  # 2x base
	
	# Check for weapon critical multiplier
	var weapon_component = ComponentManager.instance.get_first_component_of_type(attacker, "WeaponComponent")
	if weapon_component:
		var weapon_config = ConfigManager.instance.get_weapon_config(weapon_component.current_weapon_id)
		if weapon_config and "critical_multiplier" in weapon_config:
			base_crit_multiplier = weapon_config.critical_multiplier
	
	return base_crit_multiplier

func _apply_on_hit_effects(attacker: Node, target: Node, calculation: Dictionary) -> void:
	# Apply status effects based on damage type
	if calculation.damage_type == "fire" and randf() < 0.3:
		apply_status_effect(target, StatusEffect.BURN, 3.0, calculation.final_damage * 0.1, attacker)
	
	elif calculation.damage_type == "ice" and randf() < 0.2:
		apply_status_effect(target, StatusEffect.FREEZE, 1.5, 1.0, attacker)
	
	elif calculation.damage_type == "poison" and randf() < 0.4:
		apply_status_effect(target, StatusEffect.POISON, 5.0, calculation.final_damage * 0.05, attacker)
	
	# Record critical hit
	if calculation.is_critical:
		_critical_hit_history.append({
			"attacker": attacker,
			"target": target,
			"damage": calculation.final_damage,
			"timestamp": Time.get_ticks_msec()
		})
		
		# Keep only last 20 critical hits
		if _critical_hit_history.size() > 20:
			_critical_hit_history.pop_front()

func _update_status_effects(delta: float) -> void:
	for target_id in _active_status_effects.keys():
		var target = instance_from_id(int(target_id))
		if not target or not is_instance_valid(target):
			# Clean up invalid target
			for effect in _active_status_effects[target_id]:
				if effect.timer:
					effect.timer.queue_free()
			_active_status_effects.erase(target_id)
			continue
		
		# Update effect durations
		var effects_to_remove = []
		for effect in _active_status_effects[target_id]:
			effect.duration -= delta
			if effect.duration <= 0:
				effects_to_remove.append(effect)
		
		# Remove expired effects
		for effect in effects_to_remove:
			remove_status_effect(target, effect.type)

func _on_status_effect_tick(target: Node, effect: StatusEffectData) -> void:
	if not target or not is_instance_valid(target):
		return
	
	var damage = 0.0
	
	match effect.type:
		StatusEffect.BURN:
			damage = effect.intensity
			var health_component = ComponentManager.instance.get_first_component_of_type(target, "HealthComponent")
			if health_component:
				health_component.take_damage(damage)
		
		StatusEffect.POISON:
			damage = effect.intensity
			var health_component = ComponentManager.instance.get_first_component_of_type(target, "HealthComponent")
			if health_component:
				health_component.take_damage(damage)
		
		StatusEffect.FREEZE:
			# Slow movement
			var movement_component = ComponentManager.instance.get_first_component_of_type(target, "MovementComponent")
			if movement_component:
				movement_component.speed_multiplier = 0.3  # 70% slow
		
		StatusEffect.SLOW:
			var movement_component = ComponentManager.instance.get_first_component_of_type(target, "MovementComponent")
			if movement_component:
				movement_component.speed_multiplier = 0.5  # 50% slow
		
		StatusEffect.WEAKEN:
			# Reduce damage output
			# TODO: Implement damage reduction
			pass
	
	status_effect_tick.emit(target, effect, damage)
	
	# Reset movement multiplier for non-persistent effects
	if effect.type == StatusEffect.FREEZE or effect.type == StatusEffect.SLOW:
		var movement_component = ComponentManager.instance.get_first_component_of_type(target, "MovementComponent")
		if movement_component:
			movement_component.speed_multiplier = 1.0

# === EVENT HANDLERS ===

func _on_damage_dealt(event: EventBus.Event) -> void:
	var data = event.data
	# Could add visual effects, sound effects, etc.

func _on_projectile_hit(event: EventBus.Event) -> void:
	var data = event.data
	# Could add hit particles, screen shake, etc.

# === DEBUG & STATS ===

func get_stats() -> Dictionary:
	var total_effects = 0
	for target_id in _active_status_effects:
		total_effects += _active_status_effects[target_id].size()
	
	return {
		"active_status_effects": total_effects,
		"targets_with_effects": _active_status_effects.size(),
		"recent_critical_hits": _critical_hit_history.size(),
		"damage_modifiers": _damage_modifiers
	}

func print_stats() -> void:
	var stats = get_stats()
	print("=== CombatSystem Stats ===")
	print("Active Status Effects: %d" % stats.active_status_effects)
	print("Targets with Effects: %d" % stats.targets_with_effects)
	print("Recent Critical Hits: %d" % stats.recent_critical_hits)
	print("Damage Modifiers: %s" % str(stats.damage_modifiers))

# === DEBUG ===

func _to_string() -> String:
	return "[CombatSystem: %d active effects]" % get_stats().active_status_effects