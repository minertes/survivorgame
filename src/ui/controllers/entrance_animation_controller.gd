# 🎬 ENTRANCE ANIMATION CONTROLLER
# Menü giriş animasyonlarını yöneten controller
class_name EntranceAnimationController
extends Node

# === SIGNALS ===
signal animation_started(animation_name: String)
signal animation_completed(animation_name: String)
signal all_animations_completed()
signal fade_in_completed()
signal fade_out_completed()

# === CONSTANTS ===
const VP := Vector2(720.0, 1280.0)

# === EXPORT VARIABLES ===
@export var enable_fade_in: bool = true
@export var enable_button_animations: bool = true
@export var enable_timing_controls: bool = true
@export var animation_duration: float = 0.6
@export var button_delay: float = 0.48
@export var button_animation_duration: float = 0.52

# === NODE REFERENCES ===
@onready var target_node: Node = get_parent()
var animation_tweens: Dictionary = {}
var active_animations: Array[String] = []

# === STATE ===
var is_initialized: bool = false
var is_animating: bool = false
var animation_sequence: Array[String] = [
	"fade_in",
	"button_entrance",
	"stats_appear",
	"card_entrance"
]

# === LIFECYCLE ===

func _ready() -> void:
	is_initialized = true
	print("EntranceAnimationController initialized")

# === PUBLIC API ===

func play_entrance_animation() -> void:
	if is_animating:
		return
	
	is_animating = true
	active_animations.clear()
	
	# Animasyon sırasını başlat
	_start_animation_sequence()

func play_exit_animation() -> void:
	if is_animating:
		return
	
	is_animating = true
	active_animations.clear()
	
	# Çıkış animasyonu
	_play_fade_out()

func stop_all_animations() -> void:
	for tween_name in animation_tweens:
		var tween = animation_tweens[tween_name]
		if tween and tween.is_valid():
			tween.kill()
	
	animation_tweens.clear()
	active_animations.clear()
	is_animating = false

func reset_animations() -> void:
	stop_all_animations()
	
	# Varsayılan duruma sıfırla
	if target_node:
		target_node.modulate.a = 1.0
		target_node.scale = Vector2.ONE

func add_custom_animation(animation_name: String, property: String, from_value, to_value, duration: float) -> void:
	if not target_node:
		return
	
	var tween = create_tween()
	tween.tween_property(target_node, property, from_value, 0)
	tween.tween_property(target_node, property, to_value, duration)
	
	animation_tweens[animation_name] = tween
	active_animations.append(animation_name)
	
	tween.finished.connect(func(): 
		_on_animation_finished(animation_name)
	)

func set_animation_sequence(sequence: Array[String]) -> void:
	animation_sequence = sequence

func get_active_animations() -> Array[String]:
	return active_animations.duplicate()

func is_animation_running(animation_name: String) -> bool:
	return animation_name in active_animations

func set_timing_controls(fade_duration: float, btn_delay: float, btn_duration: float) -> void:
	if not enable_timing_controls:
		return
	
	animation_duration = fade_duration
	button_delay = btn_delay
	button_animation_duration = btn_duration

# === PRIVATE METHODS ===

func _start_animation_sequence() -> void:
	if animation_sequence.is_empty():
		_all_animations_completed()
		return
	
	# İlk animasyonu başlat
	_play_next_animation(0)

func _play_next_animation(index: int) -> void:
	if index >= animation_sequence.size():
		_all_animations_completed()
		return
	
	var animation_name = animation_sequence[index]
	
	match animation_name:
		"fade_in":
			_play_fade_in()
		"button_entrance":
			_play_button_entrance()
		"stats_appear":
			_play_stats_appear()
		"card_entrance":
			_play_card_entrance()
		_:
			# Bilinmeyen animasyon, bir sonrakine geç
			_play_next_animation(index + 1)
			return
	
	# Animasyon bitince bir sonrakini başlat
	var tween = animation_tweens.get(animation_name)
	if tween:
		tween.finished.connect(func(): 
			_play_next_animation(index + 1)
		, CONNECT_ONE_SHOT)

func _play_fade_in() -> void:
	if not enable_fade_in or not target_node:
		animation_completed.emit("fade_in")
		return
	
	target_node.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(target_node, "modulate:a", 1.0, animation_duration)
	
	animation_tweens["fade_in"] = tween
	active_animations.append("fade_in")
	animation_started.emit("fade_in")
	
	tween.finished.connect(func(): 
		_on_animation_finished("fade_in")
		fade_in_completed.emit()
	)

func _play_fade_out() -> void:
	if not target_node:
		animation_completed.emit("fade_out")
		return
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	
	tween.tween_property(target_node, "modulate:a", 0.0, animation_duration)
	
	animation_tweens["fade_out"] = tween
	active_animations.append("fade_out")
	animation_started.emit("fade_out")
	
	tween.finished.connect(func(): 
		_on_animation_finished("fade_out")
		fade_out_completed.emit()
		_all_animations_completed()
	)

func _play_button_entrance() -> void:
	if not enable_button_animations:
		animation_completed.emit("button_entrance")
		return
	
	# Bu animasyon MenuUIMolecule tarafından yönetiliyor
	# Sadece sinyal gönder
	animation_started.emit("button_entrance")
	
	# Gecikme sonrası tamamlandı sinyali gönder
	var timer = get_tree().create_timer(button_delay + button_animation_duration)
	timer.timeout.connect(func(): 
		_on_animation_finished("button_entrance")
	)

func _play_stats_appear() -> void:
	# MenuStatsDisplayAtom için basit görünme animasyonu
	animation_started.emit("stats_appear")
	
	# Hemen tamamlandı sinyali gönder
	call_deferred("_on_animation_finished", "stats_appear")

func _play_card_entrance() -> void:
	# WarriorCardAtom için basit görünme animasyonu
	animation_started.emit("card_entrance")
	
	# Hemen tamamlandı sinyali gönder
	call_deferred("_on_animation_finished", "card_entrance")

func _on_animation_finished(animation_name: String) -> void:
	active_animations.erase(animation_name)
	animation_tweens.erase(animation_name)
	animation_completed.emit(animation_name)

func _all_animations_completed() -> void:
	is_animating = false
	all_animations_completed.emit()
	print("All entrance animations completed")

# === DEBUG ===

func print_debug_info() -> void:
	print("=== EntranceAnimationController ===")
	print("Initialized: %s" % str(is_initialized))
	print("Animating: %s" % str(is_animating))
	print("Enable Fade In: %s" % str(enable_fade_in))
	print("Enable Button Animations: %s" % str(enable_button_animations))
	print("Enable Timing Controls: %s" % str(enable_timing_controls))
	print("Animation Duration: %.2f" % animation_duration)
	print("Button Delay: %.2f" % button_delay)
	print("Button Animation Duration: %.2f" % button_animation_duration)
	print("Active Animations: %s" % str(active_animations))
	print("Animation Sequence: %s" % str(animation_sequence))
	print("Target Node: %s" % (target_node.name if target_node else "None"))