class_name Background
extends Node2D

const TILE := 96

# [zemin_a, zemin_b, detay, isim]
const THEMES := [
	[Color(0.130, 0.120, 0.100), Color(0.112, 0.102, 0.082), Color(0.200, 0.170, 0.140), "Klasik"],
	[Color(0.090, 0.130, 0.080), Color(0.073, 0.112, 0.063), Color(0.140, 0.200, 0.110), "Karanlık Orman"],
	[Color(0.300, 0.240, 0.130), Color(0.268, 0.210, 0.108), Color(0.400, 0.320, 0.180), "Çöl"],
	[Color(0.200, 0.070, 0.040), Color(0.168, 0.053, 0.028), Color(0.350, 0.120, 0.070), "Cehennem"],
]

var _theme_idx := 0

# Faz 7.5 – Tema ID (lobi'den seçilebilir)
const THEME_IDS := {"default": 0, "graveyard": 0, "forest": 1, "desert": 2, "hell": 3}


func set_theme_by_id(theme_id: String) -> void:
	var idx: int = int(THEME_IDS.get(theme_id, 0))
	idx = clampi(idx, 0, THEMES.size() - 1)
	_theme_idx = idx
	RenderingServer.set_default_clear_color(_tc(0))
	queue_redraw()


func _tc(idx: int) -> Color:
	return THEMES[_theme_idx][idx] as Color


func _ready() -> void:
	z_index = -10
	_apply_theme(0)


func set_wave(wave: int) -> void:
	var idx: int
	if wave >= 10:    idx = 3
	elif wave >= 7:   idx = 2
	elif wave >= 4:   idx = 1
	else:             idx = 0
	if idx != _theme_idx:
		_apply_theme(idx)
		_show_map_name(str(THEMES[idx][3]))


func _apply_theme(idx: int) -> void:
	_theme_idx = idx
	RenderingServer.set_default_clear_color(_tc(0))
	queue_redraw()


func _show_map_name(map_name: String) -> void:
	var lbl := Label.new()
	lbl.text = "📍 " + map_name
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	lbl.position = Vector2(200, 400)
	get_parent().get_node("UI").add_child(lbl)
	var tw := get_tree().create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.5)
	tw.tween_callback(lbl.queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _thash(tx: int, ty: int) -> int:
	return abs((tx * 73856093) ^ (ty * 19349663) ^ (ty * 83492791) ^ (tx * 2396003))


func _draw() -> void:
	var cam  := get_viewport().get_camera_2d()
	var cp   := Vector2.ZERO
	var zoom := Vector2.ONE

	if cam:
		cp   = cam.global_position
		zoom = cam.zoom
	else:
		var pl := get_tree().get_nodes_in_group("player")
		if pl.size() > 0 and is_instance_valid(pl[0]):
			cp = (pl[0] as Node2D).global_position

	var vp  := get_viewport_rect().size / zoom
	var pad := TILE * 2
	var sx  := floori((cp.x - vp.x * 0.5 - pad) / TILE) * TILE
	var sy  := floori((cp.y - vp.y * 0.5 - pad) / TILE) * TILE
	var ex  := ceili( (cp.x + vp.x * 0.5 + pad) / TILE) * TILE
	var ey  := ceili( (cp.y + vp.y * 0.5 + pad) / TILE) * TILE

	var ga := _tc(0)  # ana zemin
	var gb := _tc(1)  # hafif farklı zemin (neredeyse aynı)
	var gd := _tc(2)  # detay rengi

	var ty := sy
	while ty < ey:
		var tx := sx
		while tx < ex:
			var ttx := tx / TILE
			var tty := ty / TILE
			var h   := _thash(ttx, tty)

			# İki ton arasında çok hafif geçiş — ızgara görünmez
			var base := ga if h % 3 != 2 else gb
			draw_rect(Rect2(tx, ty, TILE, TILE), base)

			# Seyrek küçük yuvarlak detaylar (doğal doku hissi)
			if h % 15 == 0:
				var ox  := (h % (TILE - 20)) + 10
				var oy  := ((h >> 10) % (TILE - 20)) + 10
				draw_circle(Vector2(tx + ox, ty + oy), 3.5,
					Color(gd.r, gd.g, gd.b, 0.45))
			if h % 23 == 0:
				var ox2 := (h % (TILE - 16)) + 8
				var oy2 := ((h >> 14) % (TILE - 16)) + 8
				draw_circle(Vector2(tx + ox2, ty + oy2), 2.0,
					Color(ga.r * 0.78, ga.g * 0.78, ga.b * 0.78, 0.50))
			if h % 37 == 0:
				var ox3 := (h % (TILE - 24)) + 12
				var oy3 := ((h >> 18) % (TILE - 24)) + 12
				draw_circle(Vector2(tx + ox3, ty + oy3), 1.5,
					Color(gd.r, gd.g, gd.b, 0.30))

			tx += TILE
		ty += TILE
