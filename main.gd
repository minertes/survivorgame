extends Node2D

const ENEMY_SCENE = preload("res://enemy.tscn")
const BulletPoolClass = preload("res://src/core/pool/bullet_pool.gd")

@onready var player: CharacterBody2D = $Player
@onready var health_bar: ProgressBar = $UI/HUD/HealthBar
@onready var xp_bar: ProgressBar     = $UI/HUD/XPBar
@onready var level_label: Label      = $UI/HUD/LevelLabel
@onready var wave_label: Label       = $UI/HUD/WaveLabel
@onready var spawn_timer: Timer      = $SpawnTimer
@onready var wave_timer: Timer       = $WaveTimer

var wave          := 1
var viewport_size := Vector2.ZERO
# Faz 7 – Oyun modu (GameState'ten okunur)
var _game_mode: String = "normal"
var _daily_challenge_damage_mult: float = 1.5
var upgrade_panel: UpgradePanel = null
var mini_map: MiniMap           = null
var background: Background      = null

var _kills_this_game := 0
var _heart_labels: Array[Label] = []
var _kill_label: Label = null
var _best_wave_label: Label = null
var _pause_menu: Control = null  # ESC ile kapatmak için referans
var _pause_audio_panel: Control = null  # Pause içinde açılan ses ayarları paneli
var _tutorial_overlay: Control = null   # Faz 1.2.5 – İlk açılış öğretici


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC
		if _pause_audio_panel and is_instance_valid(_pause_audio_panel):
			var a = get_node_or_null("/root/AudioSystem")
			if a and a.has_method("save_audio_config"):
				a.save_audio_config()
			_pause_audio_panel.queue_free()
			_pause_audio_panel = null
			get_viewport().set_input_as_handled()
			return
		if _pause_menu and is_instance_valid(_pause_menu):
			_close_pause_menu()
		else:
			_open_pause_menu()
		get_viewport().set_input_as_handled()


func _ready() -> void:
	Log.info("Main: game scene _ready")
	viewport_size = get_viewport_rect().size

	# Faz 3.3.1 – Oturum başlangıcı
	if has_node("/root/AnalyticsService") and AnalyticsService.has_method("session_start"):
		AnalyticsService.session_start()

	# Oyun sahnesi arka plan müziği (Faz 1.1.2)
	var _audio = get_node_or_null("/root/AudioSystem")
	if _audio and _audio.has_method("play_music"):
		_audio.play_music("background_music", 0.5, true)

	background = Background.new()
	add_child(background)
	move_child(background, 0)
	# Faz 7 – Mod ve tema
	if has_node("/root/GameState"):
		var gs = get_node("/root/GameState")
		_game_mode = gs.game_mode
		if gs.theme_id:
			background.set_theme_by_id(gs.theme_id)
		if _game_mode == GameState.MODE_DAILY_CHALLENGE and gs.daily_challenge_seed != 0:
			seed(gs.daily_challenge_seed)

	# Günlük mod: oyuncu hasar çarpanı (örn. 1.5x)
	if _game_mode == GameState.MODE_DAILY_CHALLENGE:
		player.damage_multiplier = _daily_challenge_damage_mult
	player.health_changed.connect(_on_health_changed)
	player.lives_changed.connect(_on_lives_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_level_up)
	player.died.connect(_on_player_died)

	spawn_timer.timeout.connect(_spawn_enemy)
	wave_timer.timeout.connect(_next_wave)

	# Faz 7 – Mod etiketleri
	if _game_mode == GameState.MODE_ENDLESS:
		wave_label.text = "Sonsuz · 1"
	elif _game_mode == GameState.MODE_BOSS_RUSH:
		wave_label.text = "Boss Rush · 1"
	elif _game_mode == GameState.MODE_DAILY_CHALLENGE:
		wave_label.text = "Günlük · 1"
	else:
		wave_label.text = "Dalga 1"
	level_label.text = "Lv 1"
	_update_best_wave_label()
	health_bar.value = 100.0
	xp_bar.value     = 0.0
	_style_bars()
	_setup_hearts()
	_setup_kill_counter()
	_setup_mini_map()
	_setup_upgrade_panel()
	_setup_flag_display()
	_setup_pause_button()
	_setup_bullet_pool()
	_setup_performance_overlay()
	# Faz 1.2.5 – İlk açılışta kısa öğretici (3–5 adım)
	call_deferred("_show_tutorial_if_needed")


func _setup_hearts() -> void:
	var hx := 10.0
	var hy := 4.0
	for i in 3:
		var lbl := Label.new()
		lbl.text = "❤"
		lbl.add_theme_font_size_override("font_size", 32)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.15, 0.15))
		lbl.position = Vector2(hx + i * 38, hy)
		$UI/HUD.add_child(lbl)
		_heart_labels.append(lbl)


func _on_lives_changed(new_lives: int) -> void:
	for i in _heart_labels.size():
		if i < new_lives:
			_heart_labels[i].add_theme_color_override("font_color", Color(0.95, 0.15, 0.15))
			_heart_labels[i].modulate.a = 1.0
		else:
			_heart_labels[i].add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
			_heart_labels[i].modulate.a = 0.45

	var flash := ColorRect.new()
	flash.color = Color(0.8, 0.0, 0.0, 0.35)
	flash.size  = viewport_size
	flash.position = Vector2.ZERO
	flash.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(flash)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(flash, "modulate:a", 0.0, 0.6)
	tw.tween_callback(flash.queue_free)


func _setup_kill_counter() -> void:
	_kill_label = Label.new()
	_kill_label.text = "💀 0"
	_kill_label.add_theme_font_size_override("font_size", 20)
	_kill_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))
	_kill_label.position = Vector2(viewport_size.x / 2.0 - 35, 6)
	$UI/HUD.add_child(_kill_label)

	# Faz 2.2.4 – Yerel en iyi dalga
	_best_wave_label = Label.new()
	_best_wave_label.add_theme_font_size_override("font_size", 14)
	_best_wave_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	_best_wave_label.position = Vector2(viewport_size.x / 2.0 - 50, 28)
	$UI/HUD.add_child(_best_wave_label)


func _style_bars() -> void:
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.18, 0.06, 0.06)
	hp_bg.set_corner_radius_all(6)
	hp_bg.border_color = Color(0.5, 0.15, 0.15, 0.8)
	hp_bg.set_border_width_all(1)
	health_bar.add_theme_stylebox_override("background", hp_bg)

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.85, 0.2, 0.2)
	hp_fill.set_corner_radius_all(6)
	hp_fill.border_color = Color(1.0, 0.4, 0.4, 0.6)
	hp_fill.set_border_width_all(1)
	health_bar.add_theme_stylebox_override("fill", hp_fill)

	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.06, 0.08, 0.22)
	xp_bg.set_corner_radius_all(6)
	xp_bg.border_color = Color(0.2, 0.4, 0.7, 0.6)
	xp_bg.set_border_width_all(1)
	xp_bar.add_theme_stylebox_override("background", xp_bg)

	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.25, 0.55, 0.95)
	xp_fill.set_corner_radius_all(6)
	xp_fill.border_color = Color(0.4, 0.7, 1.0, 0.7)
	xp_fill.set_border_width_all(1)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)


func _setup_mini_map() -> void:
	mini_map = MiniMap.new()
	mini_map.position = Vector2(viewport_size.x - 170.0, 10.0)
	$UI.add_child(mini_map)

	var toggle_btn := Button.new()
	toggle_btn.text = "Harita"
	toggle_btn.size = Vector2(100.0, 28.0)
	toggle_btn.position = Vector2(viewport_size.x - 170.0, 176.0)
	toggle_btn.add_theme_font_size_override("font_size", 14)
	toggle_btn.pressed.connect(func() -> void: mini_map.toggle())
	$UI.add_child(toggle_btn)


func _setup_upgrade_panel() -> void:
	upgrade_panel = UpgradePanel.new()
	add_child(upgrade_panel)


# Faz 1.3: Dalga bantları (1-10 öğrenme, 11-30 ustalık, 31+ zorluk)
func _get_wave_scale() -> float:
	if wave <= 10:
		return 1.0 + (wave - 1) * 0.08   # Yumuşak artış
	elif wave <= 30:
		return 1.72 + (wave - 11) * 0.12  # Orta artış
	else:
		return 4.0 + (wave - 31) * 0.15   # Yüksek zorluk

# Plandaki "her 5 wave'de boss" ile uyumlu (istenirse 10 yapılabilir)
const BOSS_WAVE_INTERVAL := 5
func _is_boss_wave() -> bool:
	if _game_mode == GameState.MODE_BOSS_RUSH:
		return true
	return wave > 0 and wave % BOSS_WAVE_INTERVAL == 0

# Faz 2.2.1 – 5. düşman türü: Boss (tip 4) boss dalgalarında çıkar; Faz 7.3 Boss Rush'ta hep boss
func _get_enemy_type() -> int:
	if _game_mode == GameState.MODE_BOSS_RUSH:
		return 4
	if _is_boss_wave() and randf() < 0.22:
		return 4
	if wave >= 10:
		return randi() % 4
	elif wave >= 7:
		return randi_range(1, 3)
	elif wave >= 4:
		return randi_range(0, 1)
	else:
		return 0


func _spawn_enemy() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	add_child(enemy)
	enemy.tree_exiting.connect(_on_enemy_killed.bind(enemy), CONNECT_ONE_SHOT)

	var angle      := randf() * TAU
	var spawn_dist := viewport_size.length() * 0.6
	enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_dist

	var scale_mult := _get_wave_scale()
	var base_hp    := (30.0 + wave * 10.0) * scale_mult
	var base_speed := 80.0 + wave * 8.0
	var base_dmg   := (10.0 + wave * 2.0) * scale_mult
	var etype      := _get_enemy_type()
	enemy.enemy_type = etype

	# Boss dalgasında tip 3 (İblis) daha güçlü
	if _is_boss_wave() and etype == 3:
		base_hp *= 1.8
		base_dmg *= 1.5

	match etype:
		1:
			base_speed *= 1.65; base_hp *= 0.65; base_dmg *= 0.85
		2:
			base_speed *= 0.55; base_hp *= 2.8;  base_dmg *= 1.6
		3:
			base_speed *= 1.25; base_hp *= 1.6;  base_dmg *= 1.4
		4:
			base_speed *= 0.5; base_hp *= 4.0; base_dmg *= 2.2
			enemy.xp_value = 25

	enemy.speed             = base_speed
	enemy.max_health        = base_hp
	enemy.health            = base_hp
	if etype != 4:
		enemy.xp_value = (2 + etype * 2) * 3
	enemy.damage_per_second = base_dmg
	enemy.queue_redraw()


func _on_enemy_killed(_enemy: Node) -> void:
	_kills_this_game += 1
	if is_instance_valid(_kill_label):
		_kill_label.text = "💀 %d" % _kills_this_game


func _next_wave() -> void:
	wave += 1
	spawn_timer.wait_time = maxf(0.15, 1.0 - wave * 0.04)
	if _game_mode == GameState.MODE_ENDLESS:
		wave_label.text = "Sonsuz · %d" % wave
	elif _game_mode == GameState.MODE_BOSS_RUSH:
		wave_label.text = "Boss Rush · %d" % wave
	elif _game_mode == GameState.MODE_DAILY_CHALLENGE:
		wave_label.text = "Günlük · %d" % wave
	else:
		wave_label.text = "Dalga %d" % wave
	_update_best_wave_label()
	background.set_wave(wave)
	_show_wave_notification()
	# Faz 3.3.1 – Dalga tamamlandı
	if has_node("/root/AnalyticsService") and AnalyticsService.has_method("wave_completed"):
		AnalyticsService.wave_completed(wave, _kills_this_game)


func _update_best_wave_label() -> void:
	if _best_wave_label:
		_best_wave_label.text = "En iyi: Dalga %d" % GameData.best_wave


func _show_wave_notification() -> void:
	var notif := Label.new()
	notif.text = "BOSS DALGASI!" if _is_boss_wave() else "DALGA %d!" % wave
	notif.add_theme_font_size_override("font_size", 52 if not _is_boss_wave() else 44)
	notif.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2) if _is_boss_wave() else Color.YELLOW)
	notif.position = viewport_size / 2.0 - Vector2(100, 30)
	$UI.add_child(notif)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)


func _on_health_changed(new_health: float, max_h: float) -> void:
	health_bar.value = (new_health / max_h) * 100.0


func _on_xp_changed(cur_xp: int, needed: int, lvl: int) -> void:
	xp_bar.value     = (float(cur_xp) / needed) * 100.0
	level_label.text = "Lv %d" % lvl


func _on_level_up(new_level: int) -> void:
	if has_node("/root/AnalyticsService") and AnalyticsService.has_method("level_up"):
		AnalyticsService.level_up(new_level)
	upgrade_panel.show_upgrades(player)
	var notif := Label.new()
	notif.text = "SEVİYE %d!" % new_level
	notif.add_theme_font_size_override("font_size", 44)
	notif.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	notif.position = viewport_size / 2.0 - Vector2(90, 60)
	notif.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(notif)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.8)
	tween.tween_property(notif, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notif.queue_free)


func _setup_flag_display() -> void:
	var fid := GameData.equipped_flag if GameData.equipped_flag in GameData.FLAGS else "turkey"
	var fd  := GameData.FLAGS[fid] as Dictionary
	var lbl := Label.new()
	lbl.text = str(fd.get("emoji", "🏳")) + "  " + str(fd.get("name", ""))
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	lbl.position = Vector2(10.0, viewport_size.y - 38.0)
	$UI.add_child(lbl)


# Faz 2.1.2 – Mermi havuzu
func _setup_bullet_pool() -> void:
	var pool := BulletPoolClass.new()
	pool.name = "BulletPool"
	add_child(pool)
	pool.setup(self, 24, 120)
	player.bullet_pool = pool


# Faz 2.1.1 – FPS ve bellek göstergesi (debug; F9 ile aç/kapa)
var _perf_label: Label = null
var _perf_visible := false

func _setup_performance_overlay() -> void:
	_perf_label = Label.new()
	_perf_label.name = "PerfOverlay"
	_perf_label.add_theme_font_size_override("font_size", 14)
	_perf_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	_perf_label.position = Vector2(viewport_size.x - 140, viewport_size.y - 52)
	_perf_label.visible = false
	$UI.add_child(_perf_label)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		_perf_visible = not _perf_visible
		if _perf_label:
			_perf_label.visible = _perf_visible


func _process(_delta: float) -> void:
	if _perf_visible and _perf_label:
		var mem := Performance.get_monitor(Performance.MEMORY_STATIC) as float
		var fps := Engine.get_frames_per_second()
		_perf_label.text = "FPS: %d\nBellek: %.1f MB" % [fps, mem / 1024.0 / 1024.0]


func _setup_pause_button() -> void:
	var btn := Button.new()
	btn.text = "⏸"
	btn.size = Vector2(50, 28)
	btn.position = Vector2(viewport_size.x - 60.0, 176.0)
	btn.add_theme_font_size_override("font_size", 18)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.12, 0.12, 0.22, 0.88)
	sty.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sty)
	btn.pressed.connect(_on_pause_pressed)
	$UI.add_child(btn)


func _open_pause_menu() -> void:
	if _pause_menu and is_instance_valid(_pause_menu):
		return
	var a = get_node_or_null("/root/AudioSystem")
	if a and a.has_method("play_ui_sound"):
		a.play_ui_sound("click")
	get_tree().paused = true

	var pause_root := Control.new()
	pause_root.name = "PauseMenu"
	pause_root.size = viewport_size
	pause_root.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(pause_root)
	_pause_menu = pause_root

	var overlay := ColorRect.new()
	overlay.color = Color(0.06, 0.06, 0.12, 0.88)
	overlay.size = viewport_size
	pause_root.add_child(overlay)

	var center := viewport_size / 2.0
	var title := Label.new()
	title.text = "DURAKLATILDI"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	title.position = center - Vector2(140, 140)
	pause_root.add_child(title)

	var hint := Label.new()
	hint.text = "ESC — Menüyü kapat"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.75))
	hint.position = center - Vector2(70, 100)
	pause_root.add_child(hint)

	var btn_w := 300
	var btn_h := 52
	var gap := 14
	var by := center.y - 90.0

	var resume_btn := Button.new()
	resume_btn.text = "  ▶  Devam Et"
	resume_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	resume_btn.position = Vector2(center.x - btn_w / 2.0, by)
	resume_btn.add_theme_font_size_override("font_size", 22)
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.18, 0.5, 0.22)
	rs.set_corner_radius_all(8)
	rs.set_border_width_all(1)
	rs.border_color = Color(0.35, 0.8, 0.4, 0.6)
	resume_btn.add_theme_stylebox_override("normal", rs)
	resume_btn.add_theme_stylebox_override("hover", _btn_hover_style(rs))
	resume_btn.pressed.connect(_close_pause_menu)
	pause_root.add_child(resume_btn)

	var lobby_btn2 := Button.new()
	lobby_btn2.text = "  🏠  Lobiye Dön"
	lobby_btn2.custom_minimum_size = Vector2(btn_w, btn_h)
	lobby_btn2.position = Vector2(center.x - btn_w / 2.0, by + (btn_h + gap))
	lobby_btn2.add_theme_font_size_override("font_size", 20)
	var ls := StyleBoxFlat.new()
	ls.bg_color = Color(0.2, 0.2, 0.35)
	ls.set_corner_radius_all(8)
	ls.set_border_width_all(1)
	ls.border_color = Color(0.4, 0.4, 0.65, 0.6)
	lobby_btn2.add_theme_stylebox_override("normal", ls)
	lobby_btn2.add_theme_stylebox_override("hover", _btn_hover_style(ls))
	lobby_btn2.pressed.connect(func() -> void:
		_close_pause_menu()
		if has_node("/root/AnalyticsService") and AnalyticsService.has_method("session_end"):
			AnalyticsService.session_end()
		var _aud = get_node_or_null("/root/AudioSystem")
		if _aud and _aud.has_method("stop_music"):
			_aud.stop_music(0.2)
		get_tree().change_scene_to_file("res://lobby.tscn"))
	pause_root.add_child(lobby_btn2)

	var menu_btn := Button.new()
	menu_btn.text = "  📋  Ana Menü"
	menu_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	menu_btn.position = Vector2(center.x - btn_w / 2.0, by + 2 * (btn_h + gap))
	menu_btn.add_theme_font_size_override("font_size", 20)
	var ms := StyleBoxFlat.new()
	ms.bg_color = Color(0.25, 0.2, 0.2)
	ms.set_corner_radius_all(8)
	ms.set_border_width_all(1)
	ms.border_color = Color(0.55, 0.35, 0.35, 0.6)
	menu_btn.add_theme_stylebox_override("normal", ms)
	menu_btn.add_theme_stylebox_override("hover", _btn_hover_style(ms))
	menu_btn.pressed.connect(func() -> void:
		_close_pause_menu()
		if has_node("/root/AnalyticsService") and AnalyticsService.has_method("session_end"):
			AnalyticsService.session_end()
		var _aud = get_node_or_null("/root/AudioSystem")
		if _aud and _aud.has_method("stop_music"):
			_aud.stop_music(0.2)
		get_tree().change_scene_to_file("res://menu.tscn"))
	pause_root.add_child(menu_btn)

	# Faz 1.2.2 – Pause menüsüne Ses Ayarları (Faz 1.2.1)
	var settings_btn := Button.new()
	settings_btn.text = "  ⚙️  Ses Ayarları"
	settings_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	settings_btn.position = Vector2(center.x - btn_w / 2.0, by + 3 * (btn_h + gap))
	settings_btn.add_theme_font_size_override("font_size", 20)
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0.2, 0.25, 0.35)
	ss.set_corner_radius_all(8)
	ss.set_border_width_all(1)
	ss.border_color = Color(0.4, 0.5, 0.7, 0.6)
	settings_btn.add_theme_stylebox_override("normal", ss)
	settings_btn.add_theme_stylebox_override("hover", _btn_hover_style(ss))
	settings_btn.pressed.connect(_open_pause_audio_settings)
	pause_root.add_child(settings_btn)


func _btn_hover_style(base: StyleBoxFlat) -> StyleBoxFlat:
	var h := base.duplicate() as StyleBoxFlat
	h.bg_color = Color(h.bg_color.r + 0.12, h.bg_color.g + 0.12, h.bg_color.b + 0.12)
	return h


func _close_pause_menu() -> void:
	_pause_audio_panel = null
	get_tree().paused = false
	if _pause_menu and is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
		_pause_menu = null

func _open_pause_audio_settings() -> void:
	if _pause_audio_panel and is_instance_valid(_pause_audio_panel):
		_pause_audio_panel.queue_free()
		_pause_audio_panel = null
		return
	var a = get_node_or_null("/root/AudioSystem")
	if not a:
		return
	var center := viewport_size / 2.0
	var panel := Control.new()
	panel.name = "PauseAudioPanel"
	panel.size = viewport_size
	panel.position = Vector2.ZERO
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_menu.add_child(panel)
	_pause_audio_panel = panel
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.14, 0.92)
	bg.size = viewport_size
	panel.add_child(bg)
	var title := Label.new()
	title.text = "Ses Ayarları"
	title.add_theme_font_size_override("font_size", 28)
	title.position = Vector2(center.x - 80, center.y - 140)
	panel.add_child(title)
	# dB -80..0 -> yüzde 0..100
	var _db_to_pct: Callable = func(db: float) -> int:
		return clampi(int((db + 80.0) / 80.0 * 100.0), 0, 100)
	var _pct_to_db: Callable = func(pct: float) -> float:
		return (pct / 100.0) * 80.0 - 80.0
	var master_val: int = _db_to_pct.call(a.get_volume("Master"))
	var music_val: int = _db_to_pct.call(a.get_volume("Music"))
	var sfx_val: int = _db_to_pct.call(a.get_volume("SFX"))
	var master_slider := HSlider.new()
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.value = master_val
	master_slider.custom_minimum_size = Vector2(280, 36)
	master_slider.position = Vector2(center.x - 140, center.y - 80)
	master_slider.value_changed.connect(func(v: float) -> void:
		if a: a.set_master_volume(_pct_to_db.call(v)))
	panel.add_child(master_slider)
	var master_lbl := Label.new()
	master_lbl.text = "Master: %d%%" % master_val
	master_lbl.position = Vector2(center.x - 140, center.y - 110)
	panel.add_child(master_lbl)
	master_slider.value_changed.connect(func(v: float) -> void: master_lbl.text = "Master: %d%%" % int(v))
	var music_slider := HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = music_val
	music_slider.custom_minimum_size = Vector2(280, 36)
	music_slider.position = Vector2(center.x - 140, center.y - 20)
	music_slider.value_changed.connect(func(v: float) -> void:
		if a: a.set_music_volume(_pct_to_db.call(v)))
	panel.add_child(music_slider)
	var music_lbl := Label.new()
	music_lbl.text = "Müzik: %d%%" % music_val
	music_lbl.position = Vector2(center.x - 140, center.y - 50)
	panel.add_child(music_lbl)
	music_slider.value_changed.connect(func(v: float) -> void: music_lbl.text = "Müzik: %d%%" % int(v))
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.value = sfx_val
	sfx_slider.custom_minimum_size = Vector2(280, 36)
	sfx_slider.position = Vector2(center.x - 140, center.y + 40)
	sfx_slider.value_changed.connect(func(v: float) -> void:
		if a: a.set_sfx_volume(_pct_to_db.call(v)))
	panel.add_child(sfx_slider)
	var sfx_lbl := Label.new()
	sfx_lbl.text = "SFX: %d%%" % sfx_val
	sfx_lbl.position = Vector2(center.x - 140, center.y + 10)
	panel.add_child(sfx_lbl)
	sfx_slider.value_changed.connect(func(v: float) -> void: sfx_lbl.text = "SFX: %d%%" % int(v))
	var close_btn := Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(160, 44)
	close_btn.position = Vector2(center.x - 80, center.y + 100)
	close_btn.pressed.connect(func() -> void:
		if a and a.has_method("save_audio_config"):
			a.save_audio_config()
		_pause_audio_panel = null
		panel.queue_free())
	panel.add_child(close_btn)

func _show_tutorial_if_needed() -> void:
	if not has_node("/root/GameData") or GameData.tutorial_completed:
		return
	if _tutorial_overlay and is_instance_valid(_tutorial_overlay):
		return
	var steps := [
		"Hareket: WASD, yön tuşları veya joystick ile karakteri hareket ettirin.",
		"Ateş: Silah otomatik ateş eder; düşmanlara yaklaşın.",
		"XP: Mor kristalleri toplayın, seviye atlayın.",
		"Güçlendirme: Seviye atlayınca bir upgrade seçin.",
		"Hayatta kalın: Dalgaları atlatın. İyi eğlenceler!"
	]
	# Hafif overlay (arka plan yarı saydam, oyun görünsün)
	var overlay := Control.new()
	overlay.name = "TutorialOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(overlay)
	_tutorial_overlay = overlay
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.08, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 0
	bg.offset_top = 0
	bg.offset_right = 0
	bg.offset_bottom = 0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)
	# Kompakt kart (tüm ekranı kaplamıyor)
	var card_w := minf(380.0, viewport_size.x - 48)
	var card_h := 280.0
	var card := PanelContainer.new()
	card.name = "TutorialCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -card_w / 2
	card.offset_top = -card_h / 2
	card.offset_right = card_w / 2
	card.offset_bottom = card_h / 2
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.1, 0.25, 0.98)
	card_style.set_corner_radius_all(16)
	card_style.border_color = Color(0.4, 0.5, 0.9, 0.9)
	card_style.set_border_width_all(2)
	card_style.set_content_margin_all(24)
	card.add_theme_stylebox_override("panel", card_style)
	overlay.add_child(card)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)
	var title := Label.new()
	title.text = "İpucu"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(card_w - 48, 0)
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	var btn_container := HBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 12)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_container)
	var next_btn := Button.new()
	next_btn.text = "İleri"
	next_btn.custom_minimum_size = Vector2(120, 44)
	btn_container.add_child(next_btn)
	var skip_btn := Button.new()
	skip_btn.text = "Atla"
	skip_btn.custom_minimum_size = Vector2(100, 44)
	btn_container.add_child(skip_btn)
	var next_style := StyleBoxFlat.new()
	next_style.bg_color = Color(0.2, 0.45, 0.25)
	next_style.set_corner_radius_all(10)
	next_style.border_color = Color(0.4, 0.8, 0.5, 0.9)
	next_style.set_border_width_all(1)
	next_btn.add_theme_stylebox_override("normal", next_style)
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var skip_style := StyleBoxFlat.new()
	skip_style.bg_color = Color(0.2, 0.2, 0.35)
	skip_style.set_corner_radius_all(10)
	skip_style.border_color = Color(0.4, 0.4, 0.6, 0.8)
	skip_style.set_border_width_all(1)
	skip_btn.add_theme_stylebox_override("normal", skip_style)
	skip_btn.add_theme_font_size_override("font_size", 14)
	skip_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	# step_ref: GDScript closure capture için array kullan (Next butonu düzgün çalışsın)
	var step_ref := [0]
	var update_step: Callable = func() -> void:
		var idx: int = step_ref[0]
		lbl.text = "(%d/5) %s" % [idx + 1, steps[idx]]
		next_btn.text = "Tamam" if idx >= 4 else "İleri"
	var finish_tutorial: Callable = func() -> void:
		GameData.tutorial_completed = true
		GameData.save_data()
		if _tutorial_overlay == overlay:
			_tutorial_overlay = null
		overlay.queue_free()
	update_step.call()
	next_btn.pressed.connect(func() -> void:
		if step_ref[0] >= 4:
			finish_tutorial.call()
		else:
			step_ref[0] += 1
			update_step.call())
	skip_btn.pressed.connect(finish_tutorial)


func _on_pause_pressed() -> void:
	_open_pause_menu()


func _on_player_died() -> void:
	if has_node("/root/AnalyticsService"):
		if AnalyticsService.has_method("death"):
			AnalyticsService.death(wave, _kills_this_game)
		if AnalyticsService.has_method("session_end"):
			AnalyticsService.session_end()
	GameData.record_game(wave, _kills_this_game, 0, 0, 0)
	var daily_reward_text := ""
	if _game_mode == GameState.MODE_DAILY_CHALLENGE and has_node("/root/GameData") and GameData.can_claim_daily_challenge_reward() and wave >= 5:
		var r = GameData.claim_daily_challenge_reward(wave)
		if r.get("success", false):
			daily_reward_text = "\n+%d XP, +%d elmas (Günlük ödül)" % [r.get("xp", 0), r.get("gems", 0)]
	if has_node("/root/LeaderboardService"):
		LeaderboardService.submit_score(GameData.best_wave, LeaderboardService.PERIOD_DAILY)
		LeaderboardService.submit_score(GameData.best_wave, LeaderboardService.PERIOD_WEEKLY)
	if has_node("/root/AchievementsService"):
		AchievementsService.check_all()
	get_tree().paused = true

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.size  = viewport_size
	overlay.position = Vector2.ZERO
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(overlay)

	var game_over := Label.new()
	game_over.text = "OYUN BİTTİ"
	game_over.add_theme_font_size_override("font_size", 72)
	game_over.add_theme_color_override("font_color", Color.RED)
	game_over.position = viewport_size / 2.0 - Vector2(210, 120)
	game_over.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(game_over)

	var wave_info := Label.new()
	wave_info.text = "Bu oyun: Dalga %d  |  En iyi rekor: %d" % [wave, GameData.best_wave] + daily_reward_text
	wave_info.add_theme_font_size_override("font_size", 26)
	wave_info.add_theme_color_override("font_color", Color.WHITE)
	wave_info.position = viewport_size / 2.0 - Vector2(140, 58)
	wave_info.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(wave_info)

	var kill_info := Label.new()
	kill_info.text = "Öldürme: %d   |   Toplam XP: %d" % [_kills_this_game, GameData.xp_coins]
	kill_info.add_theme_font_size_override("font_size", 20)
	kill_info.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	kill_info.position = viewport_size / 2.0 - Vector2(160, 18)
	kill_info.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(kill_info)

	var restart_btn := Button.new()
	restart_btn.text = "🔄  Yeniden Oyna"
	restart_btn.size = Vector2(280, 62)
	restart_btn.position = viewport_size / 2.0 - Vector2(140, -20)
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	$UI.add_child(restart_btn)

	var lobby_btn := Button.new()
	lobby_btn.text = "🏠  Lobiye Dön"
	lobby_btn.size = Vector2(280, 62)
	lobby_btn.position = viewport_size / 2.0 - Vector2(140, -96)
	lobby_btn.add_theme_font_size_override("font_size", 24)
	lobby_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	lobby_btn.pressed.connect(func():
		get_tree().paused = false
		if has_node("/root/AnalyticsService") and AnalyticsService.has_method("session_end"):
			AnalyticsService.session_end()
		var _aud = get_node_or_null("/root/AudioSystem")
		if _aud and _aud.has_method("stop_music"):
			_aud.stop_music(0.2)
		get_tree().change_scene_to_file("res://lobby.tscn"))
	$UI.add_child(lobby_btn)

	var share_btn := Button.new()
	share_btn.text = "📤  Skoru Paylaş"
	share_btn.size = Vector2(280, 52)
	share_btn.position = viewport_size / 2.0 - Vector2(140, -172)
	share_btn.add_theme_font_size_override("font_size", 20)
	share_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	share_btn.pressed.connect(func():
		if has_node("/root/ShareService"):
			ShareService.share_score(wave, _kills_this_game))
	$UI.add_child(share_btn)

	# Prestij: Dalga 30+ ise “Prestij yap” (kalıcı hasar/can bonusu)
	if wave >= 30 and has_node("/root/GameData") and GameData.can_do_prestige():
		var prestige_btn := Button.new()
		prestige_btn.text = "⭐  Prestij yap (+%d%% hasar/can)" % int((GameData.prestige_level + 1) * 2)
		prestige_btn.size = Vector2(320, 52)
		prestige_btn.position = viewport_size / 2.0 - Vector2(160, -234)
		prestige_btn.add_theme_font_size_override("font_size", 18)
		prestige_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		prestige_btn.pressed.connect(func():
			if GameData.do_prestige():
				get_tree().paused = false
				var _aud = get_node_or_null("/root/AudioSystem")
				if _aud and _aud.has_method("stop_music"):
					_aud.stop_music(0.2)
				get_tree().change_scene_to_file("res://lobby.tscn"))
		$UI.add_child(prestige_btn)
