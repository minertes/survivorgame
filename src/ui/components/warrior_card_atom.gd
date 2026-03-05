# 🛡️ WARRIOR CARD ATOM
# Karakter kartı görselini ve istatistiklerini gösteren atomic bileşen
class_name WarriorCardAtom
extends Control

# === SIGNALS ===
signal card_initialized()
signal card_clicked()
signal animation_completed(animation_name: String)

# === CONSTANTS ===
const VP := Vector2(720.0, 1280.0)
const CARD_W := 340.0
const CARD_H := 430.0

# === EXPORT VARIABLES ===
@export var show_animations: bool = true
@export var show_scan_line: bool = true
@export var show_stats: bool = true
@export var animation_speed: float = 1.0

# === ANIMATION ===
var _time: float = 0.0
var _scan_y: float = 0.0
var _pulse_time: float = 0.0
var _border_time: float = 0.0

# === STATE ===
var is_initialized: bool = false
var is_animating: bool = false
var character_data: Dictionary = {}
var weapon_data: Dictionary = {}

# === COLORS ===
var border_color_1 := Color(0.22, 0.56, 1.0)
var border_color_2 := Color(0.10, 0.90, 0.55)
var accent_color := Color(0.10, 0.95, 0.60, 0.92)

# === LIFECYCLE ===

func _ready() -> void:
	_scan_y = randf() * CARD_H
	_load_default_data()
	is_initialized = true
	card_initialized.emit()

func _process(delta: float) -> void:
	if not show_animations:
		return
	
	_time += delta * animation_speed
	_pulse_time += delta * 2.0
	_border_time += delta * 0.75
	
	if show_scan_line:
		_scan_y += delta * 175.0
		if _scan_y > CARD_H + 50.0:
			_scan_y = -50.0
	
	queue_redraw()

# === PUBLIC API ===

func initialize(character: Dictionary, weapon: Dictionary) -> void:
	character_data = character
	weapon_data = weapon
	queue_redraw()

func set_character_data(data: Dictionary) -> void:
	character_data = data
	queue_redraw()

func set_weapon_data(data: Dictionary) -> void:
	weapon_data = data
	queue_redraw()

func set_border_colors(color1: Color, color2: Color) -> void:
	border_color_1 = color1
	border_color_2 = color2
	queue_redraw()

func set_accent_color(color: Color) -> void:
	accent_color = color
	queue_redraw()

func start_animation(animation_name: String = "pulse") -> void:
	is_animating = true
	match animation_name:
		"pulse":
			_pulse_time = 0.0
		"border_cycle":
			_border_time = 0.0
		"scan_line":
			_scan_y = -50.0
	
	animation_completed.emit(animation_name + "_started")

func stop_animation() -> void:
	is_animating = false

func get_card_size() -> Vector2:
	return Vector2(CARD_W, CARD_H)

func get_character_stats() -> Dictionary:
	return character_data.get("stats", {})

func get_weapon_info() -> Dictionary:
	return weapon_data

# === PRIVATE METHODS ===

func _load_default_data() -> void:
	# Varsayılan karakter verisi
	character_data = {
		"name": "BIG BOSS",
		"type": "male_soldier",
		"stats": {
			"health": 160,
			"fire_rate": "Yüksek",
			"damage": "Serisi Ateş",
			"armor": "Orta"
		}
	}
	
	# Varsayılan silah verisi
	weapon_data = {
		"name": "MAKİNELİ TÜFEK",
		"icon": "⚡",
		"type": "machinegun",
		"level": 1
	}

func _draw() -> void:
	var pos := Vector2.ZERO
	var pulse := sin(_pulse_time) * 0.5 + 0.5
	var border_pulse := sin(_border_time) * 0.5 + 0.5
	
	# Dış glow katmanları
	if show_animations:
		for i in 4:
			var gw := float(i + 1) * 10.0
			var ga := float(4 - i) / 4.0 * 0.07 * (0.5 + pulse * 0.5)
			draw_rect(
				Rect2(pos - Vector2(gw, gw), Vector2(CARD_W + gw * 2.0, CARD_H + gw * 2.0)),
				Color(border_color_1.r, border_color_1.g, border_color_1.b, ga), false, 2.5
			)
	
	# Kart arkaplanı
	draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H)), Color(0.06, 0.05, 0.14))
	draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H * 0.48)), Color(0.10, 0.08, 0.20, 0.45))
	
	# Animasyonlu kenar rengi
	if show_animations:
		var border_col := Color(
			lerpf(border_color_1.r, border_color_2.r, border_pulse),
			lerpf(border_color_1.g, border_color_2.g, border_pulse),
			lerpf(border_color_1.b, border_color_2.b, border_pulse),
			0.62 + pulse * 0.22
		)
		draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H)), border_col, false, 2.0)
	else:
		draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H)), border_color_1, false, 2.0)
	
	# Üst renkli şerit
	draw_rect(Rect2(pos, Vector2(CARD_W, 8)), border_color_1)
	draw_rect(Rect2(pos + Vector2(0, 6), Vector2(CARD_W, 3)), Color(1.0, 1.0, 1.0, 0.22))
	
	# Köşe L-braket aksan
	var cs := 22.0
	var ct := 2.5
	draw_line(pos,                              pos + Vector2(cs, 0),   accent_color, ct)
	draw_line(pos,                              pos + Vector2(0, cs),   accent_color, ct)
	draw_line(pos + Vector2(CARD_W, 0),         pos + Vector2(CARD_W - cs, 0), accent_color, ct)
	draw_line(pos + Vector2(CARD_W, 0),         pos + Vector2(CARD_W, cs),     accent_color, ct)
	draw_line(pos + Vector2(0, CARD_H),         pos + Vector2(cs, CARD_H),     accent_color, ct)
	draw_line(pos + Vector2(0, CARD_H),         pos + Vector2(0, CARD_H - cs), accent_color, ct)
	draw_line(pos + Vector2(CARD_W, CARD_H),    pos + Vector2(CARD_W - cs, CARD_H), accent_color, ct)
	draw_line(pos + Vector2(CARD_W, CARD_H),    pos + Vector2(CARD_W, CARD_H - cs), accent_color, ct)
	
	# Karakter çizimi
	var cx := pos.x + CARD_W / 2.0
	var cy := pos.y + 90.0
	_draw_warrior(cx, cy)
	
	# Kart tarama çizgisi
	if show_scan_line and show_animations:
		var card_scan := fmod(_time * 115.0, CARD_H)
		draw_rect(Rect2(pos.x, pos.y + card_scan, CARD_W, 2.0), Color(0.5, 0.8, 1.0, 0.055))
	
	# İsim
	var name_y := pos.y + 220.0
	var font := ThemeDB.fallback_font
	
	draw_string(font, Vector2(pos.x, name_y), "SURVIVOR",
		HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 22,
		Color(border_color_1.r, border_color_1.g, border_color_1.b, 0.88))
	
	draw_string(font, Vector2(pos.x, name_y + 28), character_data.get("name", "BIG BOSS"),
		HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 30,
		Color(1.0, 0.88, 0.22))
	
	# Silah rozeti
	if show_stats:
		var wb_y := name_y + 62.0
		draw_rect(Rect2(pos.x + 55, wb_y, CARD_W - 110, 27), Color(0.14, 0.14, 0.26))
		draw_rect(Rect2(pos.x + 55, wb_y, CARD_W - 110, 27),
			Color(0.32, 0.32, 0.58, 0.65), false, 1.2)
		
		var weapon_text = weapon_data.get("icon", "⚡") + "  " + weapon_data.get("name", "MAKİNELİ TÜFEK")
		draw_string(font, Vector2(pos.x + 55, wb_y + 20),
			weapon_text,
			HORIZONTAL_ALIGNMENT_CENTER, CARD_W - 110, 15,
			Color(0.90, 0.72, 1.0))
		
		# Ayraç
		var div_y := wb_y + 40.0
		draw_line(Vector2(pos.x + 18, div_y), Vector2(pos.x + CARD_W - 18, div_y),
			Color(border_color_1.r, border_color_1.g, border_color_1.b, 0.24), 1.0)
		
		# İstatistikler
		var stats = character_data.get("stats", {})
		var stat_lines: Array[String] = [
			"❤  Can: " + str(stats.get("health", 160)),
			"⚡  Ateş Hızı: " + str(stats.get("fire_rate", "Yüksek")),
			"🔫  Hasar: " + str(stats.get("damage", "Serisi Ateş")),
			"🛡  Zırh: " + str(stats.get("armor", "Orta")),
		]
		
		for i in stat_lines.size():
			draw_string(font, Vector2(pos.x + 16, div_y + 14.0 + float(i) * 22.0),
				stat_lines[i], HORIZONTAL_ALIGNMENT_LEFT, CARD_W - 16, 14,
				Color(0.78, 0.82, 0.52, 0.90))

func _draw_warrior(cx: float, cy: float) -> void:
	# Gölge
	_draw_ellipse_approx(cx, cy + 88, 33, 8, Color(0, 0, 0, 0.38))
	
	# Ayaklar
	draw_rect(Rect2(cx - 20, cy + 70, 15, 18), Color(0.16, 0.16, 0.28))
	draw_rect(Rect2(cx +  6, cy + 70, 15, 18), Color(0.16, 0.16, 0.28))
	
	# Bacaklar
	draw_rect(Rect2(cx - 22, cy + 36, 16, 36), Color(0.20, 0.45, 0.85))
	draw_rect(Rect2(cx +  6, cy + 36, 16, 36), Color(0.20, 0.45, 0.85))
	
	# Gövde / Zırh
	draw_rect(Rect2(cx - 26, cy,      52, 40), Color(0.22, 0.48, 0.90))
	draw_rect(Rect2(cx - 18, cy +  8, 36,  4), Color(0.35, 0.62, 1.0, 0.60))
	draw_rect(Rect2(cx -  5, cy + 14, 10, 22), Color(0.30, 0.56, 0.96, 0.50))
	
	# Omuzluklar
	draw_circle(Vector2(cx - 28, cy + 6), 12.0, Color(0.30, 0.55, 1.0))
	draw_circle(Vector2(cx + 28, cy + 6), 12.0, Color(0.30, 0.55, 1.0))
	
	# Boyun
	draw_rect(Rect2(cx - 6, cy - 14, 12, 16), Color(0.85, 0.70, 0.60))
	
	# Kask
	draw_arc(Vector2(cx, cy - 22), 18.0, PI, TAU, 16, Color(0.28, 0.52, 0.95), 16.0)
	draw_arc(Vector2(cx, cy - 22), 19.0, PI * 1.15, PI * 1.85, 10, Color(0.15, 0.30, 0.70), 4.0)
	
	# Yüz
	draw_circle(Vector2(cx, cy - 18), 13.0, Color(0.88, 0.73, 0.62))
	draw_circle(Vector2(cx - 4, cy - 20), 2.5, Color(0.15, 0.25, 0.50))
	draw_circle(Vector2(cx + 4, cy - 20), 2.5, Color(0.15, 0.25, 0.50))
	draw_circle(Vector2(cx - 3.2, cy - 21.0), 0.8, Color(1.0, 1.0, 1.0, 0.65))
	draw_circle(Vector2(cx + 4.8, cy - 21.0), 0.8, Color(1.0, 1.0, 1.0, 0.65))
	
	# Sağ kol
	draw_rect(Rect2(cx + 26.0, cy + 4.0, 11.0, 24.0), Color(0.20, 0.45, 0.85))
	
	# Sol kol öne uzanmış (silahı destekliyor)
	draw_rect(Rect2(cx - 26.0, cy + 16.0, 60.0, 10.0), Color(0.20, 0.45, 0.85))
	
	# ── Makineli tüfek ──────────────────────────────────────
	# Stok (arka, ahşap)
	draw_rect(Rect2(cx + 7.0,  cy + 8.0,  16.0, 10.0), Color(0.32, 0.24, 0.16))
	
	# Ana gövde
	draw_rect(Rect2(cx + 21.0, cy + 7.0,  36.0, 14.0), Color(0.24, 0.24, 0.29))
	
	# Üst ray
	draw_rect(Rect2(cx + 21.0, cy + 4.0,  40.0,  4.0), Color(0.30, 0.30, 0.36))
	
	# Namlu (uzun)
	draw_rect(Rect2(cx + 57.0, cy + 9.0,  36.0,  8.0), Color(0.20, 0.20, 0.25))
	
	# Namlu ucu
	draw_rect(Rect2(cx + 90.0, cy + 10.0,  8.0,  6.0), Color(0.15, 0.15, 0.20))
	
	# Şarjör
	draw_rect(Rect2(cx + 29.0, cy + 20.0, 14.0, 22.0), Color(0.20, 0.20, 0.26))
	draw_rect(Rect2(cx + 31.0, cy + 40.0, 10.0,  4.0), Color(0.28, 0.28, 0.34))
	
	# Nişangah
	draw_rect(Rect2(cx + 46.0, cy + 1.0,  10.0,  4.0), Color(0.36, 0.36, 0.42))
	draw_rect(Rect2(cx + 48.0, cy - 2.0,   6.0,  4.0), Color(0.46, 0.46, 0.54))
	
	# Isı kanalları (namlu üstünde çizgiler)
	for pi in 5:
		draw_line(
			Vector2(cx + 61.0 + float(pi) * 5.5, cy + 9.0),
			Vector2(cx + 61.0 + float(pi) * 5.5, cy + 17.0),
			Color(0.15, 0.15, 0.20), 1.2
		)
	
	# Mermi alev / kıvılcımı (animasyonlu)
	if show_animations:
		var mfl := sin(_time * 14.0) * 0.5 + 0.5
		draw_circle(Vector2(cx + 98.0, cy + 13.0), 5.0 + mfl * 3.5,
			Color(1.0, 0.65, 0.10, 0.72 + mfl * 0.28))
		draw_circle(Vector2(cx + 98.0, cy + 13.0), 10.0 + mfl * 5.0,
			Color(1.0, 0.35, 0.05, 0.25))
		draw_circle(Vector2(cx + 98.0, cy + 13.0), 16.0,
			Color(1.0, 0.15, 0.0, 0.07))
		
		# Mermi izi noktaları
		for bi in 4:
			draw_circle(
				Vector2(cx + 98.0 + float(bi + 1) * 14.0, cy + 13.0),
				2.2 - float(bi) * 0.4,
				Color(1.0, 0.88, 0.4, 0.42 - float(bi) * 0.10)
			)

func _draw_ellipse_approx(cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	draw_colored_polygon(pts, color)

# === INPUT HANDLING ===

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var rect := Rect2(Vector2.ZERO, Vector2(CARD_W, CARD_H))
			if rect.has_point(event.position):
				card_clicked.emit()

# === DEBUG ===

func print_debug_info() -> void:
	print("=== WarriorCardAtom ===")
	print("Initialized: %s" % str(is_initialized))
	print("Animating: %s" % str(is_animating))
	print("Show Animations: %s" % str(show_animations))
	print("Show Scan Line: %s" % str(show_scan_line))
	print("Show Stats: %s" % str(show_stats))
	print("Animation Speed: %.2f" % animation_speed)
	print("Character: %s" % character_data.get("name", "Unknown"))
	print("Weapon: %s" % weapon_data.get("name", "Unknown"))