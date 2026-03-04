# ⭐ EXPERIENCE COMPONENT
# Deneyim ve seviye yönetimi için atomic component
class_name ExperienceComponent
extends Component

# === EXPERIENCE STATE ===
var current_level: int = 1
var current_experience: float = 0.0
var total_experience: float = 0.0
var experience_to_next_level: float = 100.0

# === STATS ===
var stat_points: int = 0
var skill_points: int = 0
var prestige_level: int = 0

# === STAT ALLOCATIONS ===
var allocated_stats: Dictionary = {
	"health": 0,
	"damage": 0,
	"speed": 0,
	"luck": 0,
	"critical_chance": 0,
	"critical_damage": 0
}

# === SKILLS ===
var unlocked_skills: Array = []
var active_skills: Array = []

# === SIGNALS ===
signal level_changed(old_level: int, new_level: int)
signal experience_gained(amount: float, new_total: float)
signal experience_to_next_level_changed(new_required: float)
signal stat_point_gained(points: int, total_points: int)
signal skill_point_gained(points: int, total_points: int)
signal stat_allocated(stat_type: String, amount: int, new_total: int)
signal skill_unlocked(skill_id: String)
signal skill_activated(skill_id: String)
signal prestige_achieved(new_prestige_level: int)

# === LIFECYCLE ===

func _initialize() -> void:
	# Başlangıç değerlerini ayarla
	_calculate_experience_to_next_level()
	
	print("ExperienceComponent initialized at level %d" % current_level)

# === PUBLIC API ===

func gain_experience(amount: float) -> void:
	if amount <= 0:
		return
	
	var old_experience = current_experience
	current_experience += amount
	total_experience += amount
	
	experience_gained.emit(amount, current_experience)
	
	# Level up kontrolü
	_check_level_up()

func level_up() -> void:
	var old_level = current_level
	
	# Experience'ı ayarla
	current_experience = max(0.0, current_experience - experience_to_next_level)
	current_level += 1
	
	# Stat ve skill point'leri ver
	stat_points += _get_stat_points_per_level()
	skill_points += _get_skill_points_per_level()
	
	# Yeni level için required experience'ı hesapla
	_calculate_experience_to_next_level()
	
	# Signal'leri gönder
	level_changed.emit(old_level, current_level)
	stat_point_gained.emit(_get_stat_points_per_level(), stat_points)
	skill_point_gained.emit(_get_skill_points_per_level(), skill_points)
	
	print("Level up! Level %d → %d" % [old_level, current_level])
	
	# Prestige kontrolü
	_check_prestige()

func allocate_stat_point(stat_type: String, amount: int = 1) -> bool:
	if amount <= 0 or stat_points < amount:
		return false
	
	if not stat_type in allocated_stats:
		return false
	
	allocated_stats[stat_type] += amount
	stat_points -= amount
	
	stat_allocated.emit(stat_type, amount, allocated_stats[stat_type])
	
	# Stat'ı entity'ye uygula
	_apply_stat_to_entity(stat_type, amount)
	
	return true

func reset_stats() -> void:
	# Tüm stat point'lerini geri ver
	var total_allocated = 0
	for stat_type in allocated_stats:
		total_allocated += allocated_stats[stat_type]
		allocated_stats[stat_type] = 0
	
	stat_points += total_allocated
	
	# Entity'den stat'ları kaldır
	_remove_stats_from_entity()

func unlock_skill(skill_id: String) -> bool:
	if skill_points <= 0:
		return false
	
	if skill_id in unlocked_skills:
		return false
	
	# Skill data'sını kontrol et
	var skill_data = _get_skill_data(skill_id)
	if skill_data.is_empty():
		return false
	
	# Prerequisite kontrolü
	if not _meets_skill_prerequisites(skill_id):
		return false
	
	# Skill'i unlock et
	unlocked_skills.append(skill_id)
	skill_points -= 1
	
	skill_unlocked.emit(skill_id)
	return true

func activate_skill(skill_id: String) -> bool:
	if not skill_id in unlocked_skills:
		return false
	
	if skill_id in active_skills:
		# Already active, deactivate instead
		active_skills.erase(skill_id)
		_deactivate_skill(skill_id)
		return true
	
	# Max active skills kontrolü
	if active_skills.size() >= _get_max_active_skills():
		return false
	
	# Skill'i activate et
	active_skills.append(skill_id)
	_activate_skill(skill_id)
	
	skill_activated.emit(skill_id)
	return true

func prestige() -> bool:
	# Max level'e ulaşıldı mı kontrol et
	if current_level < _get_max_level():
		return false
	
	# Prestige yap
	prestige_level += 1
	
	# Reset level ve experience
	var old_level = current_level
	current_level = 1
	current_experience = 0.0
	_calculate_experience_to_next_level()
	
	# Reset stats (prestige bonus'ları korunur)
	reset_stats()
	
	# Prestige bonus'larını uygula
	_apply_prestige_bonuses()
	
	prestige_achieved.emit(prestige_level)
	print("Prestige achieved! Prestige Level: %d" % prestige_level)
	
	return true

# === GETTERS ===

func get_experience_percentage() -> float:
	if experience_to_next_level <= 0:
		return 0.0
	return current_experience / experience_to_next_level

func get_total_stat_points() -> int:
	var total = stat_points
	for stat_type in allocated_stats:
		total += allocated_stats[stat_type]
	return total

func get_stat_value(stat_type: String) -> int:
	return allocated_stats.get(stat_type, 0)

func get_stat_multiplier(stat_type: String) -> float:
	var base_value = get_stat_value(stat_type)
	return 1.0 + (base_value * _get_stat_multiplier_per_point(stat_type))

func get_available_skills() -> Array:
	# Unlock edilebilecek skill'leri döndür
	var available = []
	var all_skills = _get_all_skills()
	
	for skill_id in all_skills:
		if not skill_id in unlocked_skills and _meets_skill_prerequisites(skill_id):
			available.append(skill_id)
	
	return available

func get_skill_data(skill_id: String) -> Dictionary:
	return _get_skill_data(skill_id)

func get_prestige_multiplier() -> float:
	return 1.0 + (prestige_level * _get_prestige_bonus_per_level())

func is_max_level() -> bool:
	return current_level >= _get_max_level()

func can_prestige() -> bool:
	return is_max_level() and prestige_level < _get_max_prestige_level()

# === PRIVATE METHODS ===

func _check_level_up() -> void:
	while current_experience >= experience_to_next_level and not is_max_level():
		level_up()

func _check_prestige() -> void:
	if can_prestige():
		# Prestige available notification (sonra UI'a eklenecek)
		print("Prestige available! Current level: %d" % current_level)

func _calculate_experience_to_next_level() -> void:
	var base_exp = _get_base_experience_required()
	var level_multiplier = _get_experience_multiplier_per_level()
	
	experience_to_next_level = base_exp * pow(level_multiplier, current_level - 1)
	experience_to_next_level_changed.emit(experience_to_next_level)

func _apply_stat_to_entity(stat_type: String, amount: int) -> void:
	if not entity:
		return
	
	match stat_type:
		"health":
			var health_component = entity.get_component("HealthComponent")
			if health_component:
				var health_bonus = amount * _get_health_per_stat_point()
				health_component.set_max_health(
					health_component.max_health + health_bonus,
					true
				)
		
		"damage":
			# Damage bonus'u weapon component'a uygulanacak
			pass
		
		"speed":
			var movement_component = entity.get_component("MovementComponent")
			if movement_component:
				var speed_bonus = amount * _get_speed_per_stat_point()
				movement_component.set_speed(
					movement_component.speed + speed_bonus
				)
		
		"luck":
			# Luck drop chance'lara etki edecek
			pass
		
		"critical_chance":
			# Critical chance weapon component'a eklenecek
			pass
		
		"critical_damage":
			# Critical damage weapon component'a eklenecek
			pass

func _remove_stats_from_entity() -> void:
	# Tüm stat'ları entity'den kaldır
	# Bu complex bir operasyon, şimdilik boş bırakıyoruz
	# Gerçek implementasyonda her stat'ın tersini uygulamak gerekecek
	pass

func _activate_skill(skill_id: String) -> void:
	var skill_data = _get_skill_data(skill_id)
	
	# Skill effect'lerini entity'ye uygula
	if entity:
		# Örnek: Health regeneration skill'i
		if skill_id == "health_regen":
			var health_component = entity.get_component("HealthComponent")
			if health_component:
				health_component.health_regeneration += skill_data.get("regen_amount", 1.0)
		
		# Diğer skill'ler sonra implemente edilecek

func _deactivate_skill(skill_id: String) -> void:
	var skill_data = _get_skill_data(skill_id)
	
	# Skill effect'lerini entity'den kaldır
	if entity:
		if skill_id == "health_regen":
			var health_component = entity.get_component("HealthComponent")
			if health_component:
				health_component.health_regeneration -= skill_data.get("regen_amount", 1.0)

func _apply_prestige_bonuses() -> void:
	# Tüm stat'lara prestige bonus'u uygula
	var prestige_multiplier = get_prestige_multiplier()
	
	# Experience gain bonus
	# Damage bonus
	# Drop chance bonus, vb.
	
	print("Prestige bonuses applied: %.1fx multiplier" % prestige_multiplier)

func _meets_skill_prerequisites(skill_id: String) -> bool:
	var skill_data = _get_skill_data(skill_id)
	
	# Level requirement
	if "required_level" in skill_data and current_level < skill_data["required_level"]:
		return false
	
	# Other skill prerequisites
	if "prerequisites" in skill_data:
		for prereq in skill_data["prerequisites"]:
			if not prereq in unlocked_skills:
				return false
	
	return true

# === CONFIG HELPERS ===

func _get_config_manager():
	if ComponentManager.is_available():
		return ConfigManager.get_instance()
	return null

func _get_base_experience_required() -> float:
	var config_manager = _get_config_manager()
	if config_manager:
		return config_manager.get_balance_value("player.base.experience_per_level", 100.0)
	return 100.0

func _get_experience_multiplier_per_level() -> float:
	var config_manager = _get_config_manager()
	if config_manager:
		return config_manager.get_balance_value("player.scaling.experience_required_multiplier", 1.2)
	return 1.2

func _get_max_level() -> int:
	var config_manager = _get_config_manager()
	if config_manager:
		return config_manager.get_balance_value("game.progression.max_level", 100)
	return 100

func _get_max_prestige_level() -> int:
	var config_manager = _get_config_manager()
	if config_manager:
		return config_manager.get_balance_value("game.progression.prestige_levels", 10)
	return 10

func _get_prestige_bonus_per_level() -> float:
	var config_manager = _get_config_manager()
	if config_manager:
		return config_manager.get_balance_value("game.progression.prestige_bonus_per_level", 0.1)
	return 0.1

func _get_stat_points_per_level() -> int:
	# Her level için 1 stat point
	return 1

func _get_skill_points_per_level() -> int:
	# Her 5 level için 1 skill point
	return 1 if current_level % 5 == 0 else 0

func _get_max_active_skills() -> int:
	return 4  # Sabit değer, sonra balance config'den alınacak

func _get_stat_multiplier_per_point(stat_type: String) -> float:
	var config_manager = _get_config_manager()
	if config_manager:
		match stat_type:
			"health":
				return config_manager.get_balance_value("player.scaling.health_per_level", 0.1) - 1.0
			"damage":
				return config_manager.get_balance_value("player.scaling.damage_per_level", 0.05) - 1.0
			_:
				return 0.01
	return 0.01

func _get_health_per_stat_point() -> float:
	return 10.0  # Sabit değer, sonra config'den alınacak

func _get_speed_per_stat_point() -> float:
	return 5.0  # Sabit değer, sonra config'den alınacak

func _get_all_skills() -> Array:
	# Skill data'sı sonra implemente edilecek
	return []

func _get_skill_data(skill_id: String) -> Dictionary:
	# Skill data'sı sonra implemente edilecek
	return {}

# === SERIALIZATION ===

func serialize() -> Dictionary:
	var data = super.serialize()
	
	data["current_level"] = current_level
	data["current_experience"] = current_experience
	data["total_experience"] = total_experience
	data["experience_to_next_level"] = experience_to_next_level
	data["stat_points"] = stat_points
	data["skill_points"] = skill_points
	data["prestige_level"] = prestige_level
	data["allocated_stats"] = allocated_stats.duplicate(true)
	data["unlocked_skills"] = unlocked_skills.duplicate(true)
	data["active_skills"] = active_skills.duplicate(true)
	
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	
	if "current_level" in data:
		current_level = data["current_level"]
	if "current_experience" in data:
		current_experience = data["current_experience"]
	if "total_experience" in data:
		total_experience = data["total_experience"]
	if "experience_to_next_level" in data:
		experience_to_next_level = data["experience_to_next_level"]
	if "stat_points" in data:
		stat_points = data["stat_points"]
	if "skill_points" in data:
		skill_points = data["skill_points"]
	if "prestige_level" in data:
		prestige_level = data["prestige_level"]
	if "allocated_stats" in data:
		allocated_stats = data["allocated_stats"]
	if "unlocked_skills" in data:
		unlocked_skills = data["unlocked_skills"]
	if "active_skills" in data:
		active_skills = data["active_skills"]

# === DEBUG ===

func _to_string() -> String:
	var exp_percentage = get_experience_percentage() * 100
	var prestige_str = ""
	if prestige_level > 0:
		prestige_str = " | Prestige: %d (%.1fx)" % [prestige_level, get_prestige_multiplier()]
	
	return "[ExperienceComponent: Level %d | XP: %.1f/%.1f (%.1f%%) | Stats: %d/%d%s]" % [
		current_level,
		current_experience,
		experience_to_next_level,
		exp_percentage,
		get_total_stat_points() - stat_points,
		get_total_stat_points(),
		prestige_str
	]

func print_experience_stats() -> void:
	print("=== Experience Stats ===")
	print("Level: %d" % current_level)
	print("Experience: %.1f/%.1f (%.1f%%)" % [
		current_experience,
		experience_to_next_level,
		get_experience_percentage() * 100
	])
	print("Total Experience: %.1f" % total_experience)
	print("Stat Points: %d" % stat_points)
	print("Skill Points: %d" % skill_points)
	print("Prestige Level: %d (%.1fx multiplier)" % [prestige_level, get_prestige_multiplier()])
	
	if not allocated_stats.is_empty():
		print("Allocated Stats:")
		for stat_type in allocated_stats:
			if allocated_stats[stat_type] > 0:
				print("  %s: %d (%.1fx)" % [
					stat_type.capitalize(),
					allocated_stats[stat_type],
					get_stat_multiplier(stat_type)
				])
	
	if not unlocked_skills.is_empty():
		print("Unlocked Skills: %s" % str(unlocked_skills))
	
	if not active_skills.is_empty():
		print("Active Skills: %s" % str(active_skills))