# 📊 MENU STATS DISPLAY ATOM
# Ana menüdeki alt istatistikleri gösteren bileşen
class_name MenuStatsDisplayAtom
extends Control

# === SIGNALS ===
signal stats_initialized()
signal stats_updated()
signal stat_clicked(stat_name: String)

# === CONSTANTS ===
const VP := Vector2(720.0, 1280.0)

# === EXPORT VARIABLES ===
@export var show_divider: bool = true
@export var show_labels: bool = true
@export var show_values: bool = true
@export var animation_enabled: bool = true
@export var update_interval: float = 1.0  # Saniye

# === ANIMATION ===
var _time: float = 0.0
var _update_timer: float = 0.0
var _pulse_time: float = 0.0

# === STATE ===
var is_initialized: bool = false
var stats_data: Dictionary = {
	"best_wave": 0,
	"total_kills": 0,
	"total_games": 0,
	"total_play_time": 0,
	"accuracy": 0.0,
	"survival_rate": 0.0
}

# === POSITIONS ===
var divider_y: float = 875.0
var stats_y: float = 900.0
var center_x: float = VP.x / 2.0

# === COLORS ===
var label_color := Color(0.52, 0.52, 0.72)
var value_color_1 := Color(1.0, 0.85, 0.25)
var value_color_2 := Color(1.0, 0.55, 0.25)
var divider_color := Color(0.22, 0.35, 0.65, 0.32)
var center_line_color := Color(0.22, 0.35, 0.65, 0.28)

# === LIFECYCLE ===

func _ready() -> void:
	_load_stats_from_gamedata()
	is_initialized = true
	stats_initialized.emit()

func _process(delta: float) -> void:
	if not animation_enabled:
		return
	
	_time += delta
	_pulse_time += delta * 1.5
	
	# Belirli aralıklarla istatistikleri güncelle
	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_load_stats_from_gamedata()
	
	queue_redraw()

# === PUBLIC API ===

func initialize(stats: Dictionary) -> void:
	stats_data = stats
	queue_redraw()
	stats_updated.emit()

func update_stat(stat_name: String, value) -> void:
	if stat_name in stats_data:
		stats_data[stat_name] = value
		queue_redraw()
		stats_updated.emit()

func update_all_stats(stats: Dictionary) -> void:
	for key in stats:
		if key in stats_data:
			stats_data[key] = stats[key]
	queue_redraw()
	stats_updated.emit()

func set_display_position(y_position: float) -> void:
	divider_y = y_position
	stats_y = y_position + 25.0
	queue_redraw()

func set_colors(label_col: Color, value_col1: Color, value_col2: Color) -> void:
	label_color = label_col
	value_color_1 = value_col1
	value_color_2 = value_col2
	queue_redraw()

func set_divider_color(color: Color) -> void:
	divider_color = color
	queue_redraw()

func set_center_line_color(color: Color) -> void:
	center_line_color = color
	queue_redraw()

func get_stat_value(stat_name: String):
	return stats_data.get(stat_name, 0)

func get_all_stats() -> Dictionary:
	return stats_data.duplicate()

func format_play_time(seconds: int) -> String:
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60
	
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	else:
		return "%d:%02d" % [minutes, secs]

func format_percentage(value: float) -> String:
	return "%.1f%%" % (value * 100)

# === PRIVATE METHODS ===

func _load_stats_from_gamedata() -> void:
	# GameData'den istatistikleri yükle
	if not has_node("/root/GameData"):
		return
	
	var game_data = get_node("/root/GameData")
	
	stats_data = {
		"best_wave": game_data.best_wave,
		"total_kills": game_data.total_kills,
		"total_games": game_data.total_games,
		"total_play_time": game_data.total_play_time,
		"accuracy": game_data.accuracy,
		"survival_rate": game_data.survival_rate
	}

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var pulse := sin(_pulse_time) * 0.5 + 0.5
	
	# Ayraç çizgisi
	if show_divider:
		draw_line(Vector2(55, divider_y), Vector2(VP.x - 55, divider_y),
			divider_color, 1.0)
		
		# Animasyonlu ayraç
		if animation_enabled:
			var anim_length = 100.0
			var anim_pos = fmod(_time * 80.0, VP.x - 110.0)
			draw_line(
				Vector2(55 + anim_pos, divider_y),
				Vector2(55 + anim_pos + anim_length, divider_y),
				Color(divider_color.r, divider_color.g, divider_color.b, divider_color.a * (0.5 + pulse * 0.5)),
				2.0
			)
	
	# Sol: En yüksek dalga
	if show_labels:
		draw_string(font, Vector2(0, stats_y), "🏆 EN YÜKSEK DALGA",
			HORIZONTAL_ALIGNMENT_CENTER, int(center_x), 13, label_color)
	
	if show_values:
		var wave_value = str(stats_data["best_wave"])
		var wave_color = Color(
			value_color_1.r,
			value_color_1.g,
			value_color_1.b,
			value_color_1.a * (0.8 + pulse * 0.2)
		)
		draw_string(font, Vector2(0, stats_y + 22), wave_value,
			HORIZONTAL_ALIGNMENT_CENTER, int(center_x), 22, wave_color)
	
	# Sağ: Toplam öldürme
	if show_labels:
		draw_string(font, Vector2(int(center_x), stats_y), "💀 TOPLAM ÖLDÜRME",
			HORIZONTAL_ALIGNMENT_CENTER, int(center_x), 13, label_color)
	
	if show_values:
		var kills_value = str(stats_data["total_kills"])
		var kills_color = Color(
			value_color_2.r,
			value_color_2.g,
			value_color_2.b,
			value_color_2.a * (0.8 + pulse * 0.2)
		)
		draw_string(font, Vector2(int(center_x), stats_y + 22), kills_value,
			HORIZONTAL_ALIGNMENT_CENTER, int(center_x), 22, kills_color)
	
	# Orta dikey çizgi
	if show_divider:
		draw_line(Vector2(center_x, divider_y + 2), Vector2(center_x, stats_y + 20),
			center_line_color, 1.0)
	
	# Alt satır: Ek istatistikler (isteğe bağlı)
	if show_labels and show_values:
		var bottom_y = stats_y + 50.0
		
		# Oyun sayısı
		draw_string(font, Vector2(0, bottom_y), "🎮 OYUNLAR",
			HORIZONTAL_ALIGNMENT_CENTER, int(center_x), 11, Color(label_color.r, label_color.g, label_color.b, 0.7))
		draw_string(font, Vector2(0, bottom_y + 16), str(stats_data["total_games"]),
			HORIZONTAL_ALIGNMENT_CENTER, int(center_x), 16, Color(value_color_1.r, value_color_1.g, value_color_1.b, 0.8))
		
		# Oyun süresi
		draw_string(font, Vector2(int(center_x), bottom_y), "⏱ SÜRE",
			HORIZONTAL_ALIGNMENT_CENTER, int(center_x), 11, Color(label_color.r, label_color.g, label_color.b, 0.7))
		var play_time_str = format_play_time(stats_data["total_play_time"])
		draw_string(font, Vector2(int(center_x), bottom_y + 16), play_time_str,
			HORIZONTAL_ALIGNMENT_CENTER, int(center_x), 16, Color(value_color_2.r, value_color_2.g, value_color_2.b, 0.8))
		
		# Alt ayraç
		draw_line(Vector2(center_x - 100, bottom_y - 5), Vector2(center_x + 100, bottom_y - 5),
			Color(divider_color.r, divider_color.g, divider_color.b, divider_color.a * 0.5), 0.5)

# === INPUT HANDLING ===

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var left_rect = Rect2(Vector2(0, stats_y - 20), Vector2(center_x, 60))
			var right_rect = Rect2(Vector2(center_x, stats_y - 20), Vector2(center_x, 60))
			
			if left_rect.has_point(event.position):
				stat_clicked.emit("best_wave")
			elif right_rect.has_point(event.position):
				stat_clicked.emit("total_kills")

# === DEBUG ===

func print_debug_info() -> void:
	print("=== MenuStatsDisplayAtom ===")
	print("Initialized: %s" % str(is_initialized))
	print("Show Divider: %s" % str(show_divider))
	print("Show Labels: %s" % str(show_labels))
	print("Show Values: %s" % str(show_values))
	print("Animation Enabled: %s" % str(animation_enabled))
	print("Update Interval: %.1f s" % update_interval)
	print("Stats Data:")
	for key in stats_data:
		print("  %s: %s" % [key, str(stats_data[key])])