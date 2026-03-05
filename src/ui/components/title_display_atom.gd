# 🎯 TITLE DISPLAY ATOM
# Başlık ve efekt gösterimi için atomic bileşen
class_name TitleDisplayAtom
extends Control

# === SIGNALS ===
signal title_animation_started()
signal title_animation_completed()
signal subtitle_changed(new_subtitle: String)

# === CONSTANTS ===
const VP := Vector2(720.0, 1280.0)

# === PROPERTIES ===
var title_text: String = "SURVIVOR"
var subtitle_text: String = "— Karanlıktan Sağ Kurtulan —"
var season_text: String = "SEASON 1"
var is_animating: bool = false

# === ANIMATION ===
var _time: float = 0.0
var _pulse: float = 0.0
var _ring_alpha: float = 0.08

# === UI REFERENCES ===
var _title_font: Font
var _season_badge_position: Vector2

# === LIFECYCLE ===

func _ready() -> void:
	_title_font = ThemeDB.fallback_font
	_season_badge_position = Vector2(VP.x / 2.0 - 152.0, 90.0)
	_start_animation()

func _process(delta: float) -> void:
	if is_animating:
		_time += delta
		_pulse = sin(_time * 1.5) * 0.5 + 0.5
		_ring_alpha = 0.08 + sin(_time * 0.55) * 0.05
		queue_redraw()

# === PUBLIC API ===

func set_title(new_title: String) -> void:
	title_text = new_title
	queue_redraw()

func set_subtitle(new_subtitle: String) -> void:
	subtitle_text = new_subtitle
	subtitle_changed.emit(new_subtitle)
	queue_redraw()

func set_season(season: String) -> void:
	season_text = season
	queue_redraw()

func start_animation() -> void:
	is_animating = true
	title_animation_started.emit()

func stop_animation() -> void:
	is_animating = false
	title_animation_completed.emit()

func set_animation_speed(speed: float) -> void:
	# Animation speed adjustment
	pass

func get_title_size() -> Vector2:
	if _title_font:
		var string_size = _title_font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, VP.x, 88)
		return string_size
	return Vector2.ZERO

# === PRIVATE METHODS ===

func _start_animation() -> void:
	is_animating = true
	title_animation_started.emit()

func _draw() -> void:
	if not _title_font:
		return
	
	var gx := VP.x / 2.0
	var gy := 152.0

	# Arka plan ışık topu
	for i in 6:
		var gr := (5 - i) * 60.0 + 28.0 + _pulse * 18.0
		var ga := float(i + 1) / 6.0 * 0.055
		draw_circle(Vector2(gx, gy), gr, Color(0.18, 0.48, 1.0, ga))
	
	for i in 3:
		var gr := (2 - i) * 48.0 + 22.0
		var ga := float(i + 1) / 3.0 * 0.038
		draw_circle(Vector2(gx, gy), gr, Color(0.55, 0.15, 0.92, ga))

	# Dönen nokta halkası
	for i in 10:
		var ang := _time * 0.55 + float(i) * TAU / 10.0
		var rx  := gx + cos(ang) * 180.0
		var ry  := gy - 24.0 + sin(ang) * 11.0
		var rs  := 2.8 - float(i % 2) * 1.0
		draw_circle(Vector2(rx, ry), rs, Color(0.42, 0.72, 1.0, _ring_alpha))

	var ts := 88
	# Kromatik sapma efekti
	draw_string(_title_font, Vector2(-4, gy + 2), title_text,
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, ts, Color(1.0, 0.12, 0.12, 0.20))
	draw_string(_title_font, Vector2( 4, gy + 2), title_text,
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, ts, Color(0.12, 0.32, 1.0, 0.20))
	
	# Glow katmanları
	draw_string(_title_font, Vector2(0, gy + 5), title_text,
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, ts, Color(0.05, 0.22, 0.65, 0.40))
	draw_string(_title_font, Vector2(0, gy + 2), title_text,
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, ts, Color(0.12, 0.45, 0.95, 0.55))
	
	# Ana beyaz metin
	draw_string(_title_font, Vector2(0, gy), title_text,
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, ts + 2, Color(0.90, 0.95, 1.0))

	# SEASON rozeti
	_draw_season_badge(gx, gy)

	# Alt ayraç
	var div_y := gy + 44.0
	draw_line(Vector2(55, div_y), Vector2(VP.x - 55, div_y),
		Color(0.28, 0.45, 0.88, 0.40), 1.5)
	
	# Orta elmas
	var dm := Vector2(gx, div_y)
	var dpts := PackedVector2Array([
		dm + Vector2(-5, 0), dm + Vector2(0, -5),
		dm + Vector2( 5, 0), dm + Vector2(0,  5),
	])
	draw_colored_polygon(dpts, Color(0.42, 0.70, 1.0, 0.75))
	
	# Alt yazı
	draw_string(_title_font, Vector2(0, div_y + 24), subtitle_text,
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, 19, Color(0.52, 0.54, 0.72, 0.85))

func _draw_season_badge(center_x: float, center_y: float) -> void:
	var bdg_x := center_x - 152.0
	var bdg_y := center_y - 62.0
	
	# Rozet arkaplanı
	draw_rect(Rect2(bdg_x, bdg_y, 70, 22), Color(0.55, 0.14, 0.0, 0.92))
	draw_rect(Rect2(bdg_x, bdg_y, 70, 22), Color(1.0, 0.55, 0.12, 0.85), false, 1.5)
	
	# Rozet metni
	draw_string(_title_font, Vector2(bdg_x, bdg_y + 17), season_text,
		HORIZONTAL_ALIGNMENT_CENTER, 70, 13, Color(1.0, 0.88, 0.55))

func _draw_glow_effect(position: Vector2, radius: float, color: Color, intensity: float) -> void:
	for i in 5:
		var glow_radius = radius + i * 10.0
		var alpha = intensity * (1.0 - float(i) / 5.0) * 0.3
		draw_circle(position, glow_radius, Color(color.r, color.g, color.b, alpha))

# === DEBUG ===
func print_debug_info() -> void:
	print("=== TitleDisplayAtom ===")
	print("Title: %s" % title_text)
	print("Subtitle: %s" % subtitle_text)
	print("Season: %s" % season_text)
	print("Animating: %s" % str(is_animating))
	print("Title Size: %s" % str(get_title_size()))