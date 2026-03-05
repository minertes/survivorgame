# 💰 CURRENCY DISPLAY ATOM
# Para/XP gösterimi için atomic bileşen
class_name CurrencyDisplayAtom
extends Control

# === SIGNALS ===
signal currency_updated(xp_amount: int)
signal currency_animation_completed()

# === PROPERTIES ===
var current_xp: int = 0
var target_xp: int = 0
var is_animating: bool = false
var animation_speed: float = 100.0  # XP/saniye

# === UI REFERENCES ===
var _xp_label: Label
var _xp_icon: Label
var _animation_timer: Timer
var _particles: CPUParticles2D

# === LIFECYCLE ===

func _ready() -> void:
	_build_ui()
	_setup_animation()

# === PUBLIC API ===

func set_xp_amount(xp: int, animate: bool = false) -> void:
	if animate:
		target_xp = xp
		_start_animation()
	else:
		current_xp = xp
		target_xp = xp
		_update_display()

func add_xp(amount: int, animate: bool = true) -> void:
	target_xp = current_xp + amount
	if animate:
		_start_animation()
	else:
		current_xp = target_xp
		_update_display()
	
	currency_updated.emit(target_xp)

func spend_xp(amount: int, animate: bool = true) -> bool:
	if current_xp < amount:
		return false
	
	target_xp = current_xp - amount
	if animate:
		_start_animation()
	else:
		current_xp = target_xp
		_update_display()
	
	currency_updated.emit(target_xp)
	return true

func get_current_xp() -> int:
	return current_xp

func can_afford(amount: int) -> bool:
	return current_xp >= amount

func play_earn_effect(amount: int) -> void:
	# Partikül efekti
	if _particles:
		_particles.emitting = true
		_particles.amount = min(amount / 10, 50)
	
	# Geçici metin efekti
	var effect_text = Label.new()
	effect_text.text = "+%d XP" % amount
	effect_text.add_theme_font_size_override("font_size", 16)
	effect_text.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	effect_text.position = Vector2(size.x / 2, -20)
	add_child(effect_text)
	
	var tween = create_tween()
	tween.tween_property(effect_text, "position:y", -60, 0.8)
	tween.parallel().tween_property(effect_text, "modulate:a", 0.0, 0.8)
	tween.tween_callback(effect_text.queue_free)

func play_spend_effect(amount: int) -> void:
	# Harcama efekti
	var effect_text = Label.new()
	effect_text.text = "-%d XP" % amount
	effect_text.add_theme_font_size_override("font_size", 16)
	effect_text.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	effect_text.position = Vector2(size.x / 2, -20)
	add_child(effect_text)
	
	var tween = create_tween()
	tween.tween_property(effect_text, "position:y", -60, 0.8)
	tween.parallel().tween_property(effect_text, "modulate:a", 0.0, 0.8)
	tween.tween_callback(effect_text.queue_free)

# === PRIVATE METHODS ===

func _build_ui() -> void:
	# Ana container
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 10)
	add_child(main_hbox)
	
	# XP ikonu
	_xp_icon = Label.new()
	_xp_icon.text = "💰"
	_xp_icon.add_theme_font_size_override("font_size", 24)
	main_hbox.add_child(_xp_icon)
	
	# XP label
	_xp_label = Label.new()
	_xp_label.text = "0 XP"
	_xp_label.add_theme_font_size_override("font_size", 20)
	_xp_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_xp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	main_hbox.add_child(_xp_label)
	
	# Partikül sistemi: CPUParticles2D (Godot 4'te process_material/draw_pass_1 yok, sadece parametreler)
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.amount = 20
	_particles.lifetime = 0.8
	_particles.explosiveness = 0.0
	_particles.direction = Vector2(0, -1)
	_particles.spread = 45.0
	_particles.gravity = Vector2(0, 98)
	_particles.set_param_min(CPUParticles2D.PARAM_INITIAL_LINEAR_VELOCITY, 40.0)
	_particles.set_param_max(CPUParticles2D.PARAM_INITIAL_LINEAR_VELOCITY, 60.0)
	add_child(_particles)

func _setup_animation() -> void:
	_animation_timer = Timer.new()
	_animation_timer.wait_time = 0.016  # ~60 FPS
	_animation_timer.timeout.connect(_on_animation_tick)
	add_child(_animation_timer)

func _start_animation() -> void:
	if not is_animating:
		is_animating = true
		_animation_timer.start()

func _stop_animation() -> void:
	is_animating = false
	_animation_timer.stop()
	current_xp = target_xp
	_update_display()
	currency_animation_completed.emit()

func _on_animation_tick() -> void:
	var difference = target_xp - current_xp
	
	if abs(difference) < 1:
		_stop_animation()
		return
	
	# Animasyon hızını hesapla
	var change = sign(difference) * animation_speed * _animation_timer.wait_time
	current_xp += int(change)
	
	# Hedefe ulaştıysak durdur
	if (difference > 0 and current_xp >= target_xp) or (difference < 0 and current_xp <= target_xp):
		_stop_animation()
	else:
		_update_display()

func _update_display() -> void:
	if _xp_label:
		_xp_label.text = "%d XP" % current_xp
		
		# Renk efekti (düşük XP'de kırmızı, yüksek XP'de yeşil)
		var color_ratio = min(current_xp / 1000.0, 1.0)
		var color = Color(
			lerpf(1.0, 0.3, color_ratio),  # R
			lerpf(0.3, 1.0, color_ratio),  # G
			lerpf(0.3, 0.3, color_ratio)   # B
		)
		_xp_label.add_theme_color_override("font_color", color)

func _process(delta: float) -> void:
	if is_animating:
		# Partikül pozisyonunu güncelle
		if _particles:
			_particles.position = _xp_icon.position + Vector2(_xp_icon.size.x / 2, _xp_icon.size.y / 2)

# === DEBUG ===
func print_debug_info() -> void:
	print("=== CurrencyDisplayAtom ===")
	print("Current XP: %d" % current_xp)
	print("Target XP: %d" % target_xp)
	print("Animating: %s" % str(is_animating))