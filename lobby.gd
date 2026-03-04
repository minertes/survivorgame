extends Node2D
# ══════════════════════════════════════════════════════════════
#  LOBBY — Karakter + Silah + Bayrak + Stats merkezi
# ══════════════════════════════════════════════════════════════

const VP := Vector2(720.0, 1280.0)

# ── Tab sistemi ───────────────────────────────────────────────
enum Tab { FLAGS, STATS }
var _active_tab: int = Tab.FLAGS

# ── UI kökleri ────────────────────────────────────────────────
var _ui_layer: CanvasLayer
var _root: Control
var _content: Control      # Tab içerikleri burada değişir
var _coin_label: Label
var _char_preview: Control
var _char_name_lbl: Label
var _flag_name_lbl: Label
var _tab_btns: Array[Button] = []

# ── Arka plan animasyonu ───────────────────────────────────────
var _time := 0.0


func _ready() -> void:
	_build_ui()
	_refresh_labels()
	_show_tab(Tab.FLAGS)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if is_instance_valid(_coin_label):
		_coin_label.text = "💰 %d XP" % GameData.xp_coins


# ── Arka plan ─────────────────────────────────────────────────
func _draw() -> void:
	# Koyu gradient
	draw_rect(Rect2(Vector2.ZERO, VP), Color(0.05, 0.04, 0.12))
	for i in 8:
		var a := float(i + 1) / 8.0 * 0.18
		var h := float(i) * 55.0
		draw_rect(Rect2(0, VP.y - 440.0 + h, VP.x, 55.0), Color(0.15, 0.05, 0.35, a))

	# Hex grid pattern (hafif)
	var s := 36.0
	var cols := int(VP.x / (s * 1.73)) + 2
	var rows := int(VP.y / (s * 1.5)) + 2
	for row in rows:
		for col in cols:
			var hx := col * s * 1.73 + (s * 0.87 if row % 2 == 1 else 0.0)
			var hy := row * s * 1.5
			_draw_hex(hx, hy, s * 0.48, Color(0.3, 0.2, 0.6, 0.06 + sin(_time * 0.4 + row * 0.3) * 0.02))

	# Karakter önizleme arka plan hâlesi
	var cx := VP.x / 2.0
	var pulse := sin(_time * 1.8) * 0.5 + 0.5
	var char_cy := 158.0
	for i in 5:
		var gr := 70.0 + float(i) * 16.0 + pulse * 10.0
		var ga := (5.0 - float(i)) / 5.0 * 0.06
		draw_circle(Vector2(cx, char_cy), gr, Color(0.45, 0.2, 0.9, ga))

	# Karakter çizimi
	_draw_warrior_preview(cx, char_cy - 30.0)


func _draw_hex(cx: float, cy: float, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 6:
		var a := i * TAU / 6.0
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	draw_colored_polygon(pts, col)


func _draw_warrior_preview(cx: float, cy: float) -> void:
	# Gölge
	var sh := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		sh.append(Vector2(cx + cos(a) * 22.0, cy + 62.0 + sin(a) * 5.5))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.30))
	# Botlar
	draw_rect(Rect2(cx - 14.0, cy + 50.0, 10.0, 13.0), Color(0.18, 0.18, 0.3))
	draw_rect(Rect2(cx + 4.0,  cy + 50.0, 10.0, 13.0), Color(0.18, 0.18, 0.3))
	# Bacaklar
	draw_rect(Rect2(cx - 15.0, cy + 26.0, 11.0, 26.0), Color(0.2, 0.45, 0.85))
	draw_rect(Rect2(cx + 4.0,  cy + 26.0, 11.0, 26.0), Color(0.2, 0.45, 0.85))
	# Gövde / Zırh
	draw_rect(Rect2(cx - 18.0, cy + 1.0,  36.0, 28.0), Color(0.22, 0.48, 0.9))
	draw_rect(Rect2(cx - 12.0, cy + 7.0,  24.0,  3.0), Color(0.35, 0.6, 1.0, 0.6))
	# Omuzluklar
	draw_circle(Vector2(cx - 20.0, cy + 5.0), 8.5, Color(0.3, 0.55, 1.0))
	draw_circle(Vector2(cx + 20.0, cy + 5.0), 8.5, Color(0.3, 0.55, 1.0))
	# Boyun
	draw_rect(Rect2(cx - 4.0, cy - 8.0, 8.0, 11.0), Color(0.85, 0.7, 0.6))
	# Kask
	draw_arc(Vector2(cx, cy - 14.0), 13.0, PI, TAU, 16, Color(0.28, 0.52, 0.95), 13.0)
	draw_arc(Vector2(cx, cy - 14.0), 13.5, PI * 1.15, PI * 1.85, 10, Color(0.15, 0.3, 0.7), 3.5)
	# Yüz
	draw_circle(Vector2(cx, cy - 11.0), 9.5, Color(0.88, 0.73, 0.62))
	draw_circle(Vector2(cx - 3.0, cy - 12.5), 1.8, Color(0.15, 0.25, 0.5))
	draw_circle(Vector2(cx + 3.0, cy - 12.5), 1.8, Color(0.15, 0.25, 0.5))
	# Sağ kol
	draw_rect(Rect2(cx + 18.0, cy + 3.0, 8.0, 17.0), Color(0.20, 0.45, 0.85))
	# Sol kol (öne uzanmış - silahı destekliyor)
	draw_rect(Rect2(cx - 18.0, cy + 11.0, 44.0, 8.0), Color(0.20, 0.45, 0.85))
	# ── Makineli tüfek ──────────────────────────────────────
	# Stok (ahşap)
	draw_rect(Rect2(cx + 4.0,  cy + 5.0,  12.0,  8.0), Color(0.32, 0.24, 0.16))
	# Ana gövde
	draw_rect(Rect2(cx + 14.0, cy + 5.0,  26.0, 10.0), Color(0.24, 0.24, 0.29))
	# Üst ray
	draw_rect(Rect2(cx + 14.0, cy + 2.5,  29.0,  3.5), Color(0.30, 0.30, 0.36))
	# Namlu (uzun)
	draw_rect(Rect2(cx + 40.0, cy + 6.5,  27.0,  6.5), Color(0.20, 0.20, 0.25))
	# Şarjör
	draw_rect(Rect2(cx + 20.0, cy + 14.0, 10.0, 16.0), Color(0.20, 0.20, 0.26))
	draw_rect(Rect2(cx + 21.0, cy + 28.0,  8.0,  3.0), Color(0.28, 0.28, 0.34))
	# Nişangah
	draw_rect(Rect2(cx + 30.0, cy + 0.0,   8.0,  3.5), Color(0.36, 0.36, 0.42))
	# Mermi alev
	draw_circle(Vector2(cx + 67.0, cy + 9.5), 3.8, Color(1.0, 0.65, 0.10, 0.68))
	draw_circle(Vector2(cx + 67.0, cy + 9.5), 6.5, Color(1.0, 0.35, 0.05, 0.20))


# ══════════════════════════════════════════════════════════════
#  UI İNŞASI
# ══════════════════════════════════════════════════════════════
func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 1
	add_child(_ui_layer)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(_root)

	_build_header()
	_build_char_preview()
	_build_tab_bar()
	_build_content_area()
	_build_play_button()


func _build_header() -> void:
	var header := PanelContainer.new()
	header.position = Vector2.ZERO
	header.size = Vector2(VP.x, 70.0)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.06, 0.04, 0.16, 0.95)
	sty.border_color = Color(0.4, 0.25, 0.8, 0.8)
	sty.set_border_width_all(0)
	sty.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", sty)
	_root.add_child(header)

	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.add_theme_constant_override("separation", 0)
	header.add_child(hb)

	# Geri butonu
	var back := Button.new()
	back.text = "◀"
	back.custom_minimum_size = Vector2(60, 70)
	back.add_theme_font_size_override("font_size", 26)
	back.add_theme_color_override("font_color", Color(0.75, 0.65, 1.0))
	var back_sty := StyleBoxFlat.new()
	back_sty.bg_color = Color(0.10, 0.07, 0.22, 0.0)
	back.add_theme_stylebox_override("normal", back_sty)
	var back_sty_h := StyleBoxFlat.new()
	back_sty_h.bg_color = Color(0.18, 0.10, 0.36)
	back_sty_h.set_corner_radius_all(6)
	back.add_theme_stylebox_override("hover", back_sty_h)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://menu.tscn"))
	hb.add_child(back)

	# Başlık
	var title := Label.new()
	title.text = "SURVIVOR.IO"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.85, 0.65, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(title)

	# XP label
	_coin_label = Label.new()
	_coin_label.text = "💰 0 XP"
	_coin_label.add_theme_font_size_override("font_size", 18)
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_coin_label.custom_minimum_size = Vector2(130, 70)
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(_coin_label)


func _build_char_preview() -> void:
	_char_preview = Control.new()
	_char_preview.position = Vector2(VP.x / 2.0 - 120.0, 70.0)
	_char_preview.size = Vector2(240.0, 210.0)
	_root.add_child(_char_preview)

	# Karakter isim
	_char_name_lbl = Label.new()
	_char_name_lbl.text = "SURVIVOR BIG BOSS"
	_char_name_lbl.add_theme_font_size_override("font_size", 20)
	_char_name_lbl.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0))
	_char_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_char_name_lbl.position = Vector2(0, 170)
	_char_name_lbl.size = Vector2(240, 26)
	_char_preview.add_child(_char_name_lbl)

	# Bayrak isim
	_flag_name_lbl = Label.new()
	_flag_name_lbl.text = "🇹🇷 Türkiye"
	_flag_name_lbl.add_theme_font_size_override("font_size", 17)
	_flag_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_flag_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flag_name_lbl.position = Vector2(0, 192)
	_flag_name_lbl.size = Vector2(240, 24)
	_char_preview.add_child(_flag_name_lbl)


func _refresh_labels() -> void:
	if is_instance_valid(_char_name_lbl):
		_char_name_lbl.text = "SURVIVOR BIG BOSS"
	if is_instance_valid(_flag_name_lbl):
		var fid2 := GameData.equipped_flag if GameData.equipped_flag in GameData.FLAGS else "turkey"
		var fd: Dictionary = GameData.FLAGS[fid2]
		_flag_name_lbl.text = str(fd.get("emoji", "🏳")) + " " + str(fd.get("name", ""))


func _build_tab_bar() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(0, 365.0)
	bar.size = Vector2(VP.x, 54.0)
	bar.add_theme_constant_override("separation", 0)
	_root.add_child(bar)

	var tab_data := [
		["🌍  BAYRAK", Tab.FLAGS],
		["📊  İSTAT",  Tab.STATS],
	]
	for td in tab_data:
		var btn := Button.new()
		btn.text = str(td[0])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 58)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_show_tab.bind(int(td[1])))
		_tab_btns.append(btn)
		bar.add_child(btn)


func _build_content_area() -> void:
	_content = Control.new()
	_content.position = Vector2(0, 419.0)
	_content.size = Vector2(VP.x, 820.0)
	_content.clip_children = Control.CLIP_CHILDREN_ONLY
	_root.add_child(_content)


func _build_play_button() -> void:
	var play := Button.new()
	play.text = "▶  OYUNA BAŞLA"
	play.size = Vector2(420, 72)
	play.position = Vector2(VP.x / 2.0 - 210.0, 287.0)
	play.add_theme_font_size_override("font_size", 28)
	play.add_theme_color_override("font_color", Color(0.92, 1.0, 0.92))
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.14, 0.52, 0.14)
	sty.set_corner_radius_all(12)
	sty.border_color = Color(0.35, 0.88, 0.35, 0.65)
	sty.set_border_width_all(2)
	play.add_theme_stylebox_override("normal", sty)
	var sty_h := StyleBoxFlat.new()
	sty_h.bg_color = Color(0.22, 0.70, 0.22)
	sty_h.set_corner_radius_all(12)
	play.add_theme_stylebox_override("hover", sty_h)
	play.pressed.connect(_start_game)
	_root.add_child(play)


# ══════════════════════════════════════════════════════════════
#  TAB SİSTEMİ
# ══════════════════════════════════════════════════════════════
func _show_tab(tab: int) -> void:
	_active_tab = tab
	_rebuild_tab()
	_update_tab_buttons()


func _update_tab_buttons() -> void:
	for i in _tab_btns.size():
		var is_active := i == _active_tab
		var sty := StyleBoxFlat.new()
		sty.bg_color = Color(0.28, 0.12, 0.58) if is_active else Color(0.08, 0.06, 0.18)
		sty.border_color = Color(0.65, 0.4, 1.0, 0.85) if is_active else Color(0.3, 0.2, 0.5, 0.35)
		sty.set_border_width_all(0)
		sty.border_width_bottom = 3
		_tab_btns[i].add_theme_stylebox_override("normal", sty)
		var sty_h := StyleBoxFlat.new()
		sty_h.bg_color = Color(0.22, 0.10, 0.45)
		sty_h.border_color = Color(0.65, 0.4, 1.0, 0.6)
		sty_h.set_border_width_all(0)
		sty_h.border_width_bottom = 3
		_tab_btns[i].add_theme_stylebox_override("hover", sty_h)
		_tab_btns[i].add_theme_color_override("font_color",
			Color(0.9, 0.75, 1.0) if is_active else Color(0.65, 0.60, 0.80))


func _rebuild_tab() -> void:
	for c in _content.get_children():
		c.queue_free()
	match _active_tab:
		Tab.FLAGS: _build_flags_tab()
		Tab.STATS: _build_stats_tab()


# ── BAYRAK TAB ────────────────────────────────────────────────
func _build_flags_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2.ZERO
	scroll.size = Vector2(VP.x, 820.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	scroll.add_child(margin)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	margin.add_child(grid)

	for flag_id in GameData.FLAGS.keys():
		grid.add_child(_make_flag_card(flag_id))


func _make_flag_card(flag_id: String) -> Control:
	var fd: Dictionary = GameData.FLAGS[flag_id]
	var owned   := flag_id in GameData.owned_flags
	var equipped := GameData.equipped_flag == flag_id
	var cost     := int(fd.get("cost", 0))

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 155)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.55, 0.3, 0.9, 0.22) if equipped else Color(0.08, 0.06, 0.18, 0.90)
	sty.border_color = Color(1.0, 0.85, 0.2, 0.9) if equipped else (Color(0.3, 0.6, 0.3, 0.7) if owned else Color(0.25, 0.2, 0.4, 0.5))
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", sty)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)

	# Emoji + Code badge
	var badge_hb := HBoxContainer.new()
	badge_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_hb.add_theme_constant_override("separation", 6)
	vb.add_child(badge_hb)

	var emoji_lbl := Label.new()
	emoji_lbl.text = str(fd.get("emoji", "🏳️"))
	emoji_lbl.add_theme_font_size_override("font_size", 36)
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_hb.add_child(emoji_lbl)

	var code_panel := PanelContainer.new()
	var code_sty := StyleBoxFlat.new()
	code_sty.bg_color = Color(0.18, 0.12, 0.35)
	code_sty.set_corner_radius_all(5)
	code_panel.add_theme_stylebox_override("panel", code_sty)
	badge_hb.add_child(code_panel)

	var code_lbl := Label.new()
	code_lbl.text = str(fd.get("code", "??"))
	code_lbl.add_theme_font_size_override("font_size", 18)
	code_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 1.0))
	code_panel.add_child(code_lbl)

	var name_lbl := Label.new()
	name_lbl.text = str(fd["name"])
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(name_lbl)

	if equipped:
		var lbl := Label.new()
		lbl.text = "✔ SEÇİLİ"
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(lbl)
	elif owned:
		var eq_btn := Button.new()
		eq_btn.text = "Seç"
		eq_btn.add_theme_font_size_override("font_size", 13)
		eq_btn.pressed.connect(_on_select_flag.bind(flag_id))
		_style_btn(eq_btn, Color(0.2, 0.5, 0.2))
		vb.add_child(eq_btn)
	else:
		var buy_btn := Button.new()
		buy_btn.text = "%d XP" % cost
		buy_btn.add_theme_font_size_override("font_size", 13)
		buy_btn.pressed.connect(_on_buy_flag.bind(flag_id))
		_style_btn(buy_btn, Color(0.6, 0.4, 0.1))
		vb.add_child(buy_btn)

	return card


# ── STATS TAB ─────────────────────────────────────────────────
func _build_stats_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2.ZERO
	scroll.size = Vector2(VP.x, 820.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 16)
	scroll.add_child(vb)

	var fl_name := "-"
	if GameData.equipped_flag in GameData.FLAGS:
		var fd2: Dictionary = GameData.FLAGS[GameData.equipped_flag]
		fl_name = str(fd2.get("name", "-"))

	var stats := [
		["🏆 En İyi Dalga",   str(GameData.best_wave)],
		["💀 Toplam Öldürme", str(GameData.total_kills)],
		["🎮 Toplam Oyun",    str(GameData.total_games)],
		["⭐ Toplam XP",      str(GameData.total_xp_earned)],
		["💰 Mevcut XP",      str(GameData.xp_coins)],
		["🌍 Bayrak",         fl_name],
	]
	for s in stats:
		vb.add_child(_make_stat_row(str(s[0]), str(s[1])))


func _make_stat_row(label: String, value: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 64)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.1, 0.07, 0.22, 0.88)
	sty.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", sty)

	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(hb)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.9))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(lbl)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", 22)
	val_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	val_lbl.custom_minimum_size = Vector2(150, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(val_lbl)

	return card


# ── Yardımcılar ────────────────────────────────────────────────
func _style_btn(btn: Button, col: Color) -> void:
	var sty := StyleBoxFlat.new()
	sty.bg_color = col
	sty.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sty)
	var sty_h := StyleBoxFlat.new()
	sty_h.bg_color = Color(col.r + 0.1, col.g + 0.1, col.b + 0.1)
	sty_h.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", sty_h)


func _flash_not_enough() -> void:
	var flash := ColorRect.new()
	flash.color = Color(0.9, 0.1, 0.1, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.28, 0.15)
	tw.tween_property(flash, "color:a", 0.0, 0.4)
	tw.tween_callback(flash.queue_free)
	# Yetersiz XP mesajı
	var msg := Label.new()
	msg.text = "❌ Yeterli XP yok!"
	msg.add_theme_font_size_override("font_size", 26)
	msg.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.position = Vector2(0, VP.y / 2.0 - 40)
	msg.size = Vector2(VP.x, 50)
	_root.add_child(msg)
	var tw2 := create_tween()
	tw2.tween_interval(1.0)
	tw2.tween_property(msg, "modulate:a", 0.0, 0.5)
	tw2.tween_callback(msg.queue_free)


func _start_game() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://main.tscn"))


# ── Buton yardımcı fonksiyonları (.bind ile kullanılır) ────────
func _on_select_flag(flag_id: String) -> void:
	GameData.equipped_flag = flag_id
	GameData.save_data()
	_refresh_labels()
	_rebuild_tab()


func _on_buy_flag(flag_id: String) -> void:
	if GameData.buy_flag(flag_id):
		GameData.equipped_flag = flag_id
		GameData.save_data()
		_refresh_labels()
		_rebuild_tab()
	else:
		_flash_not_enough()
