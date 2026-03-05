# 🎯 WEAPON COMPONENT
# Silah yönetimi için component
class_name WeaponComponent
extends Component

# === WEAPON STATE ===
var current_weapon_id: String = ""
var weapon_data: Dictionary = {}
var current_ammo: int = 0
var fire_cooldown: float = 0.0
var is_firing: bool = false
var upgrades: Array = []
var weapon_kills: int = 0
var evolution_level: int = 1

# === SIGNALS (ek) ===
signal ammo_changed(current: int, max_ammo: int)
signal weapon_fired(weapon_id: String, target_position: Vector2)

# === PROJECTILE SYSTEM ===
var projectile_pool: Array = []  # Reusable projectiles
var max_projectile_pool: int = 20

# === MULTISHOT ===
var multishot_count: int = 1
var spread_angle: float = 0.0

# === HOMING ===
var homing_enabled: bool = false
var homing_strength: float = 0.0

# === PIERCE ===
var pierce_count: int = 0

# === CRITICAL ===
var critical_chance: float = 0.05
var critical_multiplier: float = 2.0

# === SIGNALS ===
signal projectile_created(projectile: Node2D)
signal projectile_fired(projectile: Node2D, target_position: Vector2)
signal multishot_fired(projectiles: Array)
signal critical_hit_occurred(damage: float, multiplier: float)

# === PUBLIC API ===

func _can_fire() -> bool:
	return is_enabled and entity != null and not weapon_data.is_empty()

func start_reload() -> void:
	var mag = weapon_data.get("magazine_size", 1)
	current_ammo = mag
	ammo_changed.emit(current_ammo, mag)

func get_stat(stat_name: String) -> float:
	return float(weapon_data.get(stat_name, 0))

func set_weapon(weapon_id: String) -> bool:
	current_weapon_id = weapon_id
	var cfg = get_node_or_null("/root/ConfigManager")
	if cfg and cfg.has_method("get_weapon_config"):
		weapon_data = cfg.get_weapon_config(weapon_id)
	if weapon_data.is_empty():
		weapon_data = {"damage": 10, "fire_rate": 1.0, "magazine_size": 1, "projectile_speed": 300, "projectile_lifetime": 3, "projectile_size": 1, "knockback": 0}
	start_reload()
	return true

func fire(target_position: Vector2) -> bool:
	if not _can_fire():
		return false
	
	# Ammo kontrolü
	if current_ammo <= 0:
		start_reload()
		return false
	
	# Cooldown kontrolü
	if fire_cooldown > 0:
		return false
	
	# Fire rate'den cooldown hesapla
	fire_cooldown = 1.0 / weapon_data.get("fire_rate", 1.0)
	
	# Ammo azalt
	current_ammo -= 1
	ammo_changed.emit(current_ammo, weapon_data.get("magazine_size", 1))
	
	# Fire event
	is_firing = true
	weapon_fired.emit(current_weapon_id, target_position)
	
	# Projectile oluştur
	var projectiles = _create_projectiles(target_position)
	
	# Stats
	_add_fire_stat()
	
	return true

func set_multishot(count: int) -> void:
	multishot_count = max(1, count)

func set_spread_angle(angle: float) -> void:
	spread_angle = clamp(angle, 0.0, 180.0)

func set_homing(enabled: bool, strength: float = 1.0) -> void:
	homing_enabled = enabled
	homing_strength = strength

func set_pierce(count: int) -> void:
	pierce_count = max(0, count)

func set_critical(chance: float, multiplier: float = 2.0) -> void:
	critical_chance = clamp(chance, 0.0, 1.0)
	critical_multiplier = max(1.0, multiplier)

func get_projectile_damage() -> float:
	var base_damage = get_stat("damage")
	
	# Critical hit kontrolü
	if randf() <= critical_chance:
		var critical_damage = base_damage * critical_multiplier
		critical_hit_occurred.emit(critical_damage, critical_multiplier)
		return critical_damage
	
	return base_damage

func get_projectile_speed() -> float:
	return weapon_data.get("projectile_speed", 300.0)

func get_projectile_lifetime() -> float:
	return weapon_data.get("projectile_lifetime", 3.0)

func get_projectile_size() -> float:
	return weapon_data.get("projectile_size", 1.0)

func get_projectile_knockback() -> float:
	return weapon_data.get("knockback", 0.0)

# === PRIVATE METHODS ===

func _create_projectiles(target_position: Vector2) -> Array:
	var projectiles = []
	
	# Entity pozisyonu
	var entity_position = entity.global_position if entity else Vector2.ZERO
	
	# Hedef yönü
	var direction = (target_position - entity_position).normalized()
	
	# Multishot için açıları hesapla
	var angles = _calculate_multishot_angles(direction)
	
	for angle in angles:
		var projectile = _create_single_projectile(entity_position, angle)
		if projectile:
			projectiles.append(projectile)
	
	# Multishot event
	if projectiles.size() > 1:
		multishot_fired.emit(projectiles)
	
	return projectiles

func _create_single_projectile(start_position: Vector2, direction: Vector2) -> Node2D:
	# Projectile entity oluştur
	var projectile = ProjectileEntity.new()
	var config = {
		"weapon_id": current_weapon_id,
		"damage": get_projectile_damage(),
		"speed": get_projectile_speed(),
		"lifetime": get_projectile_lifetime(),
		"knockback": get_projectile_knockback(),
		"pierce": pierce_count,
		"homing": homing_enabled,
		"homing_strength": homing_strength
	}
	# Önce scene'e ekle (movement_component _ready'de oluşur)
	var parent = entity.get_parent() if entity else null
	if parent:
		parent.add_child(projectile)
	elif entity:
		entity.add_child(projectile)
	else:
		get_tree().current_scene.add_child(projectile)
	# Sonra initialize et (component'lar hazır olmalı)
	projectile.initialize_projectile(config, entity, start_position, direction)
	
	# Event emit et
	projectile_created.emit(projectile)
	projectile_fired.emit(projectile, start_position + direction * 100.0)
	
	# EventBus'a bildir
	EventBus.emit_now_static(EventBus.PROJECTILE_FIRED, {
		"projectile": projectile,
		"weapon_id": current_weapon_id,
		"damage": get_projectile_damage(),
		"position": start_position,
		"direction": direction
	})
	
	return projectile

func _calculate_multishot_angles(base_direction: Vector2) -> Array:
	var angles = []
	
	if multishot_count == 1:
		angles.append(base_direction)
		return angles
	
	# Tek sayıda projectile için
	if multishot_count % 2 == 1:
		# Ortadaki projectile
		angles.append(base_direction)
		
		# Sağ ve sol projectile'lar
		var half_count = (multishot_count - 1) / 2
		for i in range(1, half_count + 1):
			var angle_offset = spread_angle * (float(i) / float(half_count))
			
			# Sağ
			var right_angle = base_direction.rotated(deg_to_rad(angle_offset))
			angles.append(right_angle)
			
			# Sol
			var left_angle = base_direction.rotated(deg_to_rad(-angle_offset))
			angles.append(left_angle)
	else:
		# Çift sayıda projectile için
		var half_count = multishot_count / 2
		for i in range(half_count):
			var angle_offset = spread_angle * (float(i + 0.5) / float(half_count))
			
			# Sağ
			var right_angle = base_direction.rotated(deg_to_rad(angle_offset))
			angles.append(right_angle)
			
			# Sol
			var left_angle = base_direction.rotated(deg_to_rad(-angle_offset))
			angles.append(left_angle)
	
	return angles

func _create_projectile(target_position: Vector2) -> void:
	# Eski method'u yeni sistemle değiştir
	_create_projectiles(target_position)

func _add_fire_stat() -> void:
	# EventBus'a fire stat'ını bildir
	EventBus.emit_now_static(EventBus.WEAPON_CHANGED, {
		"weapon_id": current_weapon_id,
		"action": "fired",
		"ammo_remaining": current_ammo
	})

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data: Dictionary = {}
	data["current_weapon_id"] = current_weapon_id
	data["current_ammo"] = current_ammo
	data["weapon_kills"] = weapon_kills
	data["evolution_level"] = evolution_level
	data["multishot_count"] = multishot_count
	data["spread_angle"] = spread_angle
	data["homing_enabled"] = homing_enabled
	data["homing_strength"] = homing_strength
	data["pierce_count"] = pierce_count
	data["critical_chance"] = critical_chance
	data["critical_multiplier"] = critical_multiplier
	
	return data

func deserialize(data: Dictionary) -> void:
	if "current_weapon_id" in data:
		set_weapon(data.current_weapon_id)
	if "current_ammo" in data:
		current_ammo = data.current_ammo
	if "weapon_kills" in data:
		weapon_kills = data.weapon_kills
	if "evolution_level" in data:
		evolution_level = data.evolution_level
	if "multishot_count" in data:
		multishot_count = data["multishot_count"]
	if "spread_angle" in data:
		spread_angle = data["spread_angle"]
	if "homing_enabled" in data:
		homing_enabled = data["homing_enabled"]
	if "homing_strength" in data:
		homing_strength = data["homing_strength"]
	if "pierce_count" in data:
		pierce_count = data["pierce_count"]
	if "critical_chance" in data:
		critical_chance = data["critical_chance"]
	if "critical_multiplier" in data:
		critical_multiplier = data["critical_multiplier"]

# === DEBUG ===

func _to_string() -> String:
	var ammo_str = "%d/%d" % [current_ammo, weapon_data.get("magazine_size", 1) if current_weapon_id in weapon_data else 0]
	var upgrades_str = ""
	if not upgrades.is_empty():
		upgrades_str = " Upgrades: %s" % str(upgrades)
	
	var special_str = ""
	if multishot_count > 1:
		special_str += " Multishot: %d" % multishot_count
	if pierce_count > 0:
		special_str += " Pierce: %d" % pierce_count
	if homing_enabled:
		special_str += " Homing"
	if critical_chance > 0.05:
		special_str += " Crit: %.0f%%" % (critical_chance * 100)
	
	return "[WeaponComponent: %s | Ammo: %s | Kills: %d | Evolution: %d%s%s]" % [
		current_weapon_id,
		ammo_str,
		weapon_kills,
		evolution_level,
		upgrades_str,
		special_str
	]