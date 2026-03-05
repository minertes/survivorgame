# Faz 5 – Sosyal ve canlı ops: Liderlik tablosu, Başarılar, Günlük ödül
extends Control

@onready var leaderboard_list: ItemList = $Margin/VBox/Tabs/Leaderboard/Scroll/List
@onready var period_btn_daily: Button = $Margin/VBox/Tabs/Leaderboard/PeriodDaily
@onready var period_btn_weekly: Button = $Margin/VBox/Tabs/Leaderboard/PeriodWeekly
@onready var achievements_list: ItemList = $Margin/VBox/Tabs/Achievements/Scroll/List
@onready var daily_streak_label: Label = $Margin/VBox/Tabs/Daily/StreakLabel
@onready var daily_claim_btn: Button = $Margin/VBox/Tabs/Daily/ClaimButton
@onready var daily_status_label: Label = $Margin/VBox/Tabs/Daily/StatusLabel
@onready var back_btn: Button = $Margin/VBox/Header/BackButton
@onready var tabs: TabContainer = $Margin/VBox/Tabs

func _ready() -> void:
	_apply_ui_styles()
	back_btn.pressed.connect(_on_back)
	period_btn_daily.pressed.connect(_on_period_daily)
	period_btn_weekly.pressed.connect(_on_period_weekly)
	daily_claim_btn.pressed.connect(_on_daily_claim)
	_refresh_leaderboard("daily")
	_refresh_achievements()
	_refresh_daily()
	if has_node("/root/LeaderboardService"):
		LeaderboardService.leaderboard_loaded.connect(_on_leaderboard_loaded)

func _apply_ui_styles() -> void:
	# Geri butonu - belirgin ve tıklanabilir
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.18, 0.22, 0.42)
	st.set_corner_radius_all(12)
	st.border_color = Color(0.45, 0.55, 0.95, 0.9)
	st.set_border_width_all(2)
	st.set_content_margin_all(12)
	back_btn.add_theme_stylebox_override("normal", st)
	var st_hover := StyleBoxFlat.new()
	st_hover.bg_color = Color(0.25, 0.3, 0.55)
	st_hover.set_corner_radius_all(12)
	st_hover.border_color = Color(0.5, 0.6, 1.0, 0.95)
	st_hover.set_border_width_all(2)
	st_hover.set_content_margin_all(12)
	back_btn.add_theme_stylebox_override("hover", st_hover)
	back_btn.add_theme_stylebox_override("pressed", st_hover)
	# Tab butonları
	for btn in [period_btn_daily, period_btn_weekly]:
		if btn:
			btn.add_theme_font_size_override("font_size", 16)
			var tb := StyleBoxFlat.new()
			tb.bg_color = Color(0.12, 0.1, 0.22)
			tb.set_corner_radius_all(8)
			tb.set_content_margin_all(10)
			btn.add_theme_stylebox_override("normal", tb)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")

func _on_period_daily() -> void:
	_refresh_leaderboard("daily")

func _on_period_weekly() -> void:
	_refresh_leaderboard("weekly")

func _refresh_leaderboard(period: String) -> void:
	if not has_node("/root/LeaderboardService"):
		if leaderboard_list:
			leaderboard_list.clear()
			leaderboard_list.add_item("Liderlik tablosu sunucuya bağlandığında aktif olacak.")
		return
	LeaderboardService.get_leaderboard(period, 20)

func _on_leaderboard_loaded(period: String, entries: Array, error: String) -> void:
	if not leaderboard_list:
		return
	leaderboard_list.clear()
	if not error.is_empty():
		leaderboard_list.add_item("Hata: " + error)
		return
	for i in range(entries.size()):
		var e = entries[i]
		if e is Dictionary:
			var rank: int = int(e.get("rank", i + 1))
			var score: int = int(e.get("score", 0))
			var mid: String = str(e.get("masked_id", "Oyuncu"))
			leaderboard_list.add_item("%d. %s — %d" % [rank, mid, score])
		else:
			leaderboard_list.add_item(str(e))

func _refresh_achievements() -> void:
	if not achievements_list or not has_node("/root/AchievementsService"):
		return
	achievements_list.clear()
	var all = AchievementsService.get_all()
	for aid in all:
		var a: Dictionary = all[aid]
		var prog = AchievementsService.get_progress(aid)
		var unlocked: bool = bool(prog.get("unlocked", false))
		var cur: int = int(prog.get("current", 0))
		var tgt: int = int(prog.get("target", 0))
		var line := "%s %s: %s (%d/%d)" % [a.get("icon", "?"), a.get("name", aid), "✓" if unlocked else "-", cur, tgt]
		achievements_list.add_item(line)

func _refresh_daily() -> void:
	if not has_node("/root/GameData"):
		return
	var gd = get_node("/root/GameData")
	var state = gd.get_daily_reward_state()
	if daily_streak_label:
		daily_streak_label.text = "Seri: %d gün" % state.get("streak", 0)
	if daily_claim_btn:
		daily_claim_btn.visible = state.get("can_claim", false)
		daily_claim_btn.disabled = not state.get("can_claim", false)
	if daily_status_label:
		if state.get("can_claim", false):
			daily_status_label.text = "Bugünkü ödül: +%d XP" % state.get("reward_xp", 0)
			if state.get("reward_gems", 0) > 0:
				daily_status_label.text += ", +%d elmas" % state.reward_gems
		else:
			daily_status_label.text = "Bugünkü ödülü zaten aldın. Yarın tekrar gel!"

func _on_daily_claim() -> void:
	if not has_node("/root/GameData"):
		return
	var gd = get_node("/root/GameData")
	var result = gd.claim_daily_reward()
	if daily_status_label:
		if result.get("success", false):
			daily_status_label.text = "Ödül alındı! +%d XP" % result.get("xp", 0)
			if result.get("gems", 0) > 0:
				daily_status_label.text += ", +%d elmas" % result.gems
		else:
			daily_status_label.text = result.get("reason", "Alınamadı")
	_refresh_daily()
