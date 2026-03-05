extends Node2D

# ── Sabitler ──────────────────────────────────────────────────
const VP     := Vector2(720.0, 1280.0)
const CARD_W := 340.0
const CARD_H := 430.0

# ── Parçacık sistemleri ──────────────────────────────────────
var _stars:  Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _nebula: Array[Dictionary] = []

# ── Animasyon ─────────────────────────────────────────────────
var _time   := 0.0
var _scan_y := 0.0

# ── UI referansları ───────────────────────────────────────────
var _start_btn: Button
var _sound_btn: Button
var _ui_layer:  CanvasLayer
var _ui_root:   Control


func _ready() -> void:
	_init_particles()
	_scan_y = randf() * VP.y
	_build_ui()
	_animate_entrance()


# ══════════════════════════════════════════════════════════════
#  PARTİKÜL BAŞLATMA
# ══════════════════════════════════════════════════════════════
func _init_particles() -> void:
	var star_colors := [
		Color(0.45, 0.72, 1.0),
		Color(0.72, 0.42, 1.0),
		Color(1.0,  0.87, 0.35),
		Color(1.0,  1.0,  1.0),
		Color(0.35, 1.0,  0.72),
	]
	for _i in 110:
		_stars.append({
			"pos":   Vector2(randf() * VP.x, randf() * VP.y),
			"vel":   Vector2(randf_range(-7.0, 7.0), randf_range(-30.0, -5.0)),
			"size":  randf_range(0.7, 3.4),
			"alpha": randf_range(0.25, 1.0),
			"phase": randf() * TAU,
			"color": star_colors[randi() % star_colors.size()],
		})

	var spark_colors := [Color(0.2, 0.7, 1.0), Color(0.7, 0.3, 1.0), Color(0.2, 1.0, 0.6)]
	for _i in 22:
		var scx := randf() * VP.x
		var scy := randf_range(320.0, 880.0)
		_sparks.append({
			"cx":    scx,
			"cy":    scy,
			"angle": randf() * TAU,
			"speed": randf_range(0.4, 1.1),
			"r":     randf_range(45.0, 110.0),
			"size":  randf_range(2.0, 5.0),
			"alpha": randf_range(0.12, 0.42),
			"color": spark_colors[randi() % spark_colors.size()],
			"pos":   Vector2(scx, scy),
		})

	var ncols := [
		Color(0.14, 0.04, 0.48, 0.08),
		Color(0.48, 0.04, 0.14, 0.07),
		Color(0.04, 0.20, 0.48, 0.07),
		Color(0.32, 0.06, 0.42, 0.055),
	]
	for i in 4:
		_nebula.append({
			"pos":    Vector2(randf() * VP.x, randf() * VP.y),
			"vel":    Vector2(randf_range(-3.5, 3.5), randf_range(-3.5, 3.5)),
			"radius": randf_range(170.0, 310.0),
			"phase":  randf() * TAU,
			"color":  ncols[i],
		})


# ══════════════════════════════════════════════════════════════
#  PROCESS
# ══════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	_time += delta

	for s in _stars:
		var p := s["pos"] as Vector2
		p.x += (s["vel"] as Vector2).x * delta
		p.y += (s["vel"] as Vector2).y * delta
		s["phase"] = float(s["phase"]) + delta * (1.1 + float(s["size"]) * 0.4)
		if p.y < -6.0:
			p.y = VP.y + 6.0
			p.x = randf() * VP.x
		if p.x < -6.0:    p.x = VP.x + 6.0
		elif p.x > VP.x + 6.0: p.x = -6.0
		s["pos"] = p

	for sp in _sparks:
		sp["angle"] = float(sp["angle"]) + float(sp["speed"]) * delta
		var ang := float(sp["angle"])
		var r   := float(sp["r"])
		sp["pos"] = Vector2(
			float(sp["cx"]) + cos(ang) * r,
			float(sp["cy"]) + sin(ang) * r * 0.38
		)

	for n in _nebula:
		n["phase"] = float(n["phase"]) + delta * 0.18
		var np := n["pos"] as Vector2
		np += (n["vel"] as Vector2) * delta
		if np.x < -320.0:         np.x = VP.x + 320.0
		elif np.x > VP.x + 320.0: np.x = -320.0
		if np.y < -320.0:         np.y = VP.y + 320.0
		elif np.y > VP.y + 320.0: np.y = -320.0
		n["pos"] = np

	_scan_y += delta * 175.0
	if _scan_y > VP.y + 50.0:
		_scan_y = -50.0

	queue_redraw()


# ══════════════════════════════════════════════════════════════
#  RENDER
# ══════════════════════════════════════════════════════════════
func _draw() -> void:
	var font := ThemeDB.fallback_font

	# ── Derin uzay arka planı ───────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, VP), Color(0.04, 0.02, 0.10))

	# Nebula lekeleri
	for n in _nebula:
		var np  := n["pos"] as Vector2
		var nr  := float(n["radius"])
		var nc  := n["color"] as Color
		var pls := sin(float(n["phase"])) * 0.3 + 0.7
		for ring in 5:
			var rr := nr * (1.0 - float(ring) * 0.18)
			var ra := nc.a * float(ring + 1) / 5.0 * pls
			draw_circle(np, rr, Color(nc.r, nc.g, nc.b, ra))

	# Izgara deseni
	for gx in range(0, int(VP.x) + 1, 60):
		draw_line(Vector2(gx, 0), Vector2(gx, VP.y), Color(0.25, 0.35, 0.75, 0.018), 1.0)
	for gy in range(0, int(VP.y) + 1, 60):
		draw_line(Vector2(0, gy), Vector2(VP.x, gy), Color(0.25, 0.35, 0.75, 0.018), 1.0)

	# Yıldızlar
	for s in _stars:
		var twinkle := (sin(float(s["phase"])) * 0.4 + 0.6) * float(s["alpha"])
		var c  := s["color"] as Color
		var r  := float(s["size"])
		var sp := s["pos"] as Vector2
		if r > 2.2:
			draw_line(sp - Vector2(r * 2.8, 0), sp + Vector2(r * 2.8, 0),
				Color(c.r, c.g, c.b, twinkle * 0.35), 1.0)
			draw_line(sp - Vector2(0, r * 2.8), sp + Vector2(0, r * 2.8),
				Color(c.r, c.g, c.b, twinkle * 0.35), 1.0)
		draw_circle(sp, r, Color(c.r, c.g, c.b, twinkle))

	# Enerji kıvılcımları
	for sp in _sparks:
		var spos := sp["pos"] as Vector2
		var sc   := sp["color"] as Color
		var sa   := float(sp["alpha"])
		var ss   := float(sp["size"])
		draw_circle(spos, ss,       Color(sc.r, sc.g, sc.b, sa))
		draw_circle(spos, ss * 2.2, Color(sc.r, sc.g, sc.b, sa * 0.18))

	# Tarama çizgisi
	draw_rect(Rect2(0, _scan_y - 1.5, VP.x, 4.0), Color(0.42, 0.72, 1.0, 0.055))
	draw_rect(Rect2(0, _scan_y,       VP.x, 1.5), Color(0.65, 0.88, 1.0, 0.08))

	# Köşe karartmaları
	for i in 10:
		var a := float(i) / 10.0 * 0.3
		var m := float(i) * 24.0
		draw_rect(Rect2(0,        0, m,  VP.y), Color(0, 0, 0, a * 0.5))
		draw_rect(Rect2(VP.x - m, 0, m,  VP.y), Color(0, 0, 0, a * 0.5))
	draw_rect(Rect2(0, VP.y - 220.0, VP.x, 220.0), Color(0, 0, 0, 0.45))

	# Tarama çizgisi overlay
	for i in range(0, int(VP.y), 4):
		draw_line(Vector2(0, i), Vector2(VP.x, i), Color(0, 0, 0, 0.02), 1.0)

	# ── Başlık ──────────────────────────────────────────────
	_draw_title(font)

	# ── Karakter kartı ──────────────────────────────────────
	_draw_warrior_card(font)

	# ── Buton glow ──────────────────────────────────────────
	_draw_button_glow()

	# ── Alt istatistikler ───────────────────────────────────
	_draw_bottom_stats(font)


func _draw_title(font: Font) -> void:
	var pulse := sin(_time * 1.5) * 0.5 + 0.5
	var gx    := VP.x / 2.0
	var gy    := 152.0

	# Arka plan ışık topu
	for i in 6:
		var gr := (5 - i) * 60.0 + 28.0 + pulse * 18.0
		var ga := float(i + 1) / 6.0 * 0.055
		draw_circle(Vector2(gx, gy), gr, Color(0.18, 0.48, 1.0, ga))
	for i in 3:
		var gr := (2 - i) * 48.0 + 22.0
		var ga := float(i + 1) / 3.0 * 0.038
		draw_circle(Vector2(gx, gy), gr, Color(0.55, 0.15, 0.92, ga))

	# Dönen nokta halkası
	var ring_a := pulse * 0.28 + 0.08
	for i in 10:
		var ang := _time * 0.55 + float(i) * TAU / 10.0
		var rx  := gx + cos(ang) * 180.0
		var ry  := gy - 24.0 + sin(ang) * 11.0
		var rs  := 2.8 - float(i % 2) * 1.0
		draw_circle(Vector2(rx, ry), rs, Color(0.42, 0.72, 1.0, ring_a))

	var ts := 88
	# Kromatik sapma efekti
	draw_string(font, Vector2(-4, gy + 2), "SURVIVOR",
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, ts, Color(1.0, 0.12, 0.12, 0.20))
	draw_string(font, Vector2( 4, gy + 2), "SURVIVOR",
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, ts, Color(0.12, 0.32, 1.0, 0.20))
	# Glow katmanları
	draw_string(font, Vector2(0, gy + 5), "SURVIVOR",
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, ts, Color(0.05, 0.22, 0.65, 0.40))
	draw_string(font, Vector2(0, gy + 2), "SURVIVOR",
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, ts, Color(0.12, 0.45, 0.95, 0.55))
	# Ana beyaz metin
	draw_string(font, Vector2(0, gy), "SURVIVOR",
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, ts + 2, Color(0.90, 0.95, 1.0))

	# SEASON 1 rozeti
	var bdg_x := gx - 152.0
	var bdg_y := gy - 62.0
	draw_rect(Rect2(bdg_x, bdg_y, 70, 22), Color(0.55, 0.14, 0.0, 0.92))
	draw_rect(Rect2(bdg_x, bdg_y, 70, 22), Color(1.0, 0.55, 0.12, 0.85), false, 1.5)
	draw_string(font, Vector2(bdg_x, bdg_y + 17), "SEASON 1",
		HORIZONTAL_ALIGNMENT_CENTER, 70, 13, Color(1.0, 0.88, 0.55))

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
	draw_string(font, Vector2(0, div_y + 24), "— Karanlıktan Sağ Kurtulan —",
		HORIZONTAL_ALIGNMENT_CENTER, VP.x, 19, Color(0.52, 0.54, 0.72, 0.85))


func _draw_warrior_card(font: Font) -> void:
	var pulse  := sin(_time * 2.0) * 0.5 + 0.5
	var cpulse := sin(_time * 3.2) * 0.5 + 0.5
	var pos    := Vector2(VP.x / 2.0 - CARD_W / 2.0, 242.0)
	var bcol   := Color(0.22, 0.56, 1.0)
	var gcol   := Color(0.10, 0.90, 0.55)

	# Dış glow katmanları
	for i in 4:
		var gw := float(i + 1) * 10.0
		var ga := float(4 - i) / 4.0 * 0.07 * (0.5 + pulse * 0.5)
		draw_rect(
			Rect2(pos - Vector2(gw, gw), Vector2(CARD_W + gw * 2.0, CARD_H + gw * 2.0)),
			Color(bcol.r, bcol.g, bcol.b, ga), false, 2.5
		)

	# Kart arkaplanı (derinlik hissi için iki katman)
	draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H)), Color(0.06, 0.05, 0.14))
	draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H * 0.48)), Color(0.10, 0.08, 0.20, 0.45))

	# Animasyonlu kenar rengi
	var bt := fmod(_time * 0.75, 1.0)
	var border_col := Color(
		lerpf(bcol.r, gcol.r, bt),
		lerpf(bcol.g, gcol.g, bt),
		lerpf(bcol.b, gcol.b, bt),
		0.62 + cpulse * 0.22
	)
	draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H)), border_col, false, 2.0)

	# Üst renkli şerit
	draw_rect(Rect2(pos, Vector2(CARD_W, 8)), border_col)
	draw_rect(Rect2(pos + Vector2(0, 6), Vector2(CARD_W, 3)), Color(1.0, 1.0, 1.0, 0.22))

	# Köşe L-braket aksan (neon teal)
	var acc := Color(0.10, 0.95, 0.60, 0.92)
	var cs  := 22.0
	var ct  := 2.5
	draw_line(pos,                              pos + Vector2(cs, 0),   acc, ct)
	draw_line(pos,                              pos + Vector2(0, cs),   acc, ct)
	draw_line(pos + Vector2(CARD_W, 0),         pos + Vector2(CARD_W - cs, 0), acc, ct)
	draw_line(pos + Vector2(CARD_W, 0),         pos + Vector2(CARD_W, cs),     acc, ct)
	draw_line(pos + Vector2(0, CARD_H),         pos + Vector2(cs, CARD_H),     acc, ct)
	draw_line(pos + Vector2(0, CARD_H),         pos + Vector2(0, CARD_H - cs), acc, ct)
	draw_line(pos + Vector2(CARD_W, CARD_H),    pos + Vector2(CARD_W - cs, CARD_H), acc, ct)
	draw_line(pos + Vector2(CARD_W, CARD_H),    pos + Vector2(CARD_W, CARD_H - cs), acc, ct)

	# Karakter çizimi
	var cx := pos.x + CARD_W / 2.0
	var cy := pos.y + 90.0
	_draw_warrior(cx, cy)

	# Kart tarama çizgisi
	var card_scan := fmod(_time * 115.0, CARD_H)
	draw_rect(Rect2(pos.x, pos.y + card_scan, CARD_W, 2.0), Color(0.5, 0.8, 1.0, 0.055))

	# İsim
	var name_y := pos.y + 220.0
	draw_string(font, Vector2(pos.x, name_y), "SURVIVOR",
		HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 22,
		Color(bcol.r, bcol.g, bcol.b, 0.88))
	draw_string(font, Vector2(pos.x, name_y + 28), "BIG BOSS",
		HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 30,
		Color(1.0, 0.88, 0.22))

	# Silah rozeti
	var wb_y := name_y + 62.0
	draw_rect(Rect2(pos.x + 55, wb_y, CARD_W - 110, 27), Color(0.14, 0.14, 0.26))
	draw_rect(Rect2(pos.x + 55, wb_y, CARD_W - 110, 27),
		Color(0.32, 0.32, 0.58, 0.65), false, 1.2)
	draw_string(font, Vector2(pos.x + 55, wb_y + 20),
		"⚡  MAKİNELİ TÜFEK",
		HORIZONTAL_ALIGNMENT_CENTER, CARD_W - 110, 15,
		Color(0.90, 0.72, 1.0))

	# Ayraç
	var div_y := wb_y + 40.0
	draw_line(Vector2(pos.x + 18, div_y), Vector2(pos.x + CARD_W - 18, div_y),
		Color(bcol.r, bcol.g, bcol.b, 0.24), 1.0)

	# İstatistikler
	var stats: Array[String] = [
		"❤  Can: 160",
		"⚡  Ateş Hızı: Yüksek",
		"🔫  Hasar: Serisi Ateş",
		"🛡  Zırh: Orta",
	]
	for i in stats.size():
		draw_string(font, Vector2(pos.x + 16, div_y + 14.0 + float(i) * 22.0),
			stats[i], HORIZONTAL_ALIGNMENT_LEFT, CARD_W - 16, 14,
			Color(0.78, 0.82, 0.52, 0.90))


func _draw_warrior(cx: float, cy: float) -> void:
	# Gölge
	draw_ellipse_approx(cx, cy + 88, 33, 8, Color(0, 0, 0, 0.38))
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


func draw_ellipse_approx(cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	draw_colored_polygon(pts, color)


func _draw_button_glow() -> void:
	var btn_pulse := sin(_time * 2.2) * 0.5 + 0.5
	var bcx := VP.x / 2.0
	var bcy := 728.0

	# Arkaya geniş yumuşak halo
	for i in 5:
		var br := (4 - i) * 30.0 + 22.0 + btn_pulse * 15.0
		var ba := float(i + 1) / 5.0 * 0.048
		draw_circle(Vector2(bcx, bcy), br * 3.8, Color(0.18, 0.72, 0.28, ba))

	# Dönen enerji noktaları (yatay oval)
	for i in 14:
		var ang := _time * 1.4 + float(i) * TAU / 14.0
		var rx  := bcx + cos(ang) * 215.0
		var ry  := bcy + sin(ang) * 38.0
		var rs  := 2.2 + btn_pulse * 0.8
		draw_circle(Vector2(rx, ry), rs, Color(0.22, 0.90, 0.40, 0.18 + btn_pulse * 0.06))


func _draw_bottom_stats(font: Font) -> void:
	var bw := GameData.best_wave
	var tk := GameData.total_kills
	var cx := VP.x / 2.0

	# Ayraç
	draw_line(Vector2(55, 875), Vector2(VP.x - 55, 875),
		Color(0.22, 0.35, 0.65, 0.32), 1.0)

	# Sol: En yüksek dalga
	draw_string(font, Vector2(0, 900), "🏆 EN YÜKSEK DALGA",
		HORIZONTAL_ALIGNMENT_CENTER, int(cx), 13, Color(0.52, 0.52, 0.72))
	draw_string(font, Vector2(0, 922), str(bw),
		HORIZONTAL_ALIGNMENT_CENTER, int(cx), 22, Color(1.0, 0.85, 0.25))

	# Sağ: Toplam öldürme
	draw_string(font, Vector2(int(cx), 900), "💀 TOPLAM ÖLDÜRME",
		HORIZONTAL_ALIGNMENT_CENTER, int(cx), 13, Color(0.52, 0.52, 0.72))
	draw_string(font, Vector2(int(cx), 922), str(tk),
		HORIZONTAL_ALIGNMENT_CENTER, int(cx), 22, Color(1.0, 0.55, 0.25))

	# Orta dikey çizgi
	draw_line(Vector2(cx, 877), Vector2(cx, 932), Color(0.22, 0.35, 0.65, 0.28), 1.0)


# ══════════════════════════════════════════════════════════════
#  UI İNŞA
# ══════════════════════════════════════════════════════════════
func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 1
	add_child(_ui_layer)

	_ui_root = Control.new()
	_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(_ui_root)

	# ── Oyuna başla ────────────────────────────────────────
	_start_btn = Button.new()
	_start_btn.text = "▶  OYUNA BAŞLA"
	_start_btn.size = Vector2(400, 80)
	_start_btn.position = Vector2(VP.x / 2.0 - 200.0, 688.0)
	_start_btn.add_theme_font_size_override("font_size", 30)
	_start_btn.add_theme_color_override("font_color", Color(0.95, 1.0, 0.95))

	var sty_s := StyleBoxFlat.new()
	sty_s.bg_color = Color(0.10, 0.44, 0.12)
	sty_s.set_corner_radius_all(14)
	sty_s.border_color = Color(0.30, 0.88, 0.36, 0.88)
	sty_s.set_border_width_all(2)
	_start_btn.add_theme_stylebox_override("normal", sty_s)

	var sty_sh := StyleBoxFlat.new()
	sty_sh.bg_color = Color(0.18, 0.62, 0.20)
	sty_sh.set_corner_radius_all(14)
	sty_sh.border_color = Color(0.48, 1.0, 0.52, 1.0)
	sty_sh.set_border_width_all(2)
	_start_btn.add_theme_stylebox_override("hover", sty_sh)

	var sty_sp := StyleBoxFlat.new()
	sty_sp.bg_color = Color(0.06, 0.30, 0.08)
	sty_sp.set_corner_radius_all(14)
	_start_btn.add_theme_stylebox_override("pressed", sty_sp)

	_start_btn.pressed.connect(_start_game)
	_ui_root.add_child(_start_btn)

	# ── Ses toggle ──────────────────────────────────────────
	_sound_btn = Button.new()
	_sound_btn.text = "🔊  Ses: Açık" if GameData.sound_enabled else "🔇  Ses: Kapalı"
	_sound_btn.size = Vector2(260, 56)
	_sound_btn.position = Vector2(VP.x / 2.0 - 130.0, 792.0)
	_sound_btn.add_theme_font_size_override("font_size", 20)
	_sound_btn.add_theme_color_override("font_color", Color(0.80, 0.87, 1.0))

	var sty_snd := StyleBoxFlat.new()
	sty_snd.bg_color = Color(0.08, 0.10, 0.26)
	sty_snd.set_corner_radius_all(10)
	sty_snd.border_color = Color(0.28, 0.42, 0.82, 0.65)
	sty_snd.set_border_width_all(2)
	_sound_btn.add_theme_stylebox_override("normal", sty_snd)

	var sty_sndh := StyleBoxFlat.new()
	sty_sndh.bg_color = Color(0.14, 0.20, 0.44)
	sty_sndh.set_corner_radius_all(10)
	_sound_btn.add_theme_stylebox_override("hover", sty_sndh)

	_sound_btn.pressed.connect(_toggle_sound)
	_ui_root.add_child(_sound_btn)

	# ── Sürüm ───────────────────────────────────────────────
	var ver := Label.new()
	ver.text = "v0.1  Beta Build"
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", Color(0.28, 0.28, 0.40))
	ver.position = Vector2(12, VP.y - 26)
	_ui_root.add_child(ver)


# ══════════════════════════════════════════════════════════════
#  ENTRANCE ANİMASYON
# ══════════════════════════════════════════════════════════════
func _animate_entrance() -> void:
	_ui_root.modulate.a = 0.0
	modulate.a = 0.0

	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 1.0, 0.6)
	fade.parallel().tween_property(_ui_root, "modulate:a", 1.0, 0.5).set_delay(0.28)

	_start_btn.scale     = Vector2(0.5, 0.5)
	_start_btn.modulate.a = 0.0
	var btn_tw := create_tween()
	btn_tw.tween_interval(0.48)
	btn_tw.tween_property(_start_btn, "scale", Vector2(1.0, 1.0), 0.52) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	btn_tw.parallel().tween_property(_start_btn, "modulate:a", 1.0, 0.34)

	_sound_btn.modulate.a = 0.0
	var sbtn := create_tween()
	sbtn.tween_interval(0.72)
	sbtn.tween_property(_sound_btn, "modulate:a", 1.0, 0.4)


# ══════════════════════════════════════════════════════════════
#  AKSIYONLAR
# ══════════════════════════════════════════════════════════════
func _toggle_sound() -> void:
	GameState.sound_enabled = not GameState.sound_enabled
	GameData.sound_enabled  = GameState.sound_enabled
	GameData.save_data()
	_sound_btn.text = "🔊  Ses: Açık" if GameState.sound_enabled else "🔇  Ses: Kapalı"
	
	# AudioSystem'i güncelle (geçici olarak devre dışı)
	# if GameState.sound_enabled:
	# 	if AudioSystem:
	# 		AudioSystem.unmute_all()
	# else:
	# 	if AudioSystem:
	# 		AudioSystem.mute_all()


func _start_game() -> void:
	GameData.selected_character = "male"
	GameData.save_data()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.parallel().tween_property(_ui_root, "modulate:a", 0.0, 0.30)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://lobby.tscn"))
