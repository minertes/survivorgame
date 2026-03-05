# Faz 4 – Mağaza sahnesi: gems gösterimi, IAP ürün listesi, satın alma akışı
extends Control

@onready var gems_label: Label = $Margin/VBox/Header/GemsRow/GemsLabel
@onready var products_list: VBoxContainer = $Margin/VBox/Scroll/ProductsList
@onready var back_button: Button = $Margin/VBox/BackButton
@onready var status_label: Label = $Margin/VBox/StatusLabel

func _ready() -> void:
	_back_button_style(back_button)
	back_button.pressed.connect(_on_back_pressed)
	if has_node("/root/IAPService"):
		IAPService.purchase_completed.connect(_on_purchase_completed)
	_refresh_gems()
	_build_products()

func _back_button_style(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 22)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.15, 0.18, 0.35)
	st.set_corner_radius_all(10)
	st.border_color = Color(0.4, 0.5, 0.9, 0.8)
	st.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", st)

func _refresh_gems() -> void:
	if not gems_label:
		return
	var gd = get_node_or_null("/root/GameData")
	gems_label.text = "💎 %d" % (gd.gems if gd else 0)

func _build_products() -> void:
	if not products_list:
		return
	for c in products_list.get_children():
		c.queue_free()
	if not has_node("/root/IAPService"):
		_refresh_gems()
		return
	var products = IAPService.get_products()
	for pid in products:
		var p: Dictionary = products[pid]
		var row := PanelContainer.new()
		var row_inner := HBoxContainer.new()
		row_inner.add_theme_constant_override("separation", 16)
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.12, 0.1, 0.2, 0.95)
		row_style.set_corner_radius_all(8)
		row_style.set_border_width_all(1)
		row_style.border_color = Color(0.35, 0.35, 0.5, 0.8)
		row_style.set_content_margin_all(12)
		row.add_theme_stylebox_override("panel", row_style)
		row.add_child(row_inner)
		var title := Label.new()
		title.text = p.get("title", pid) + "  —  " + p.get("price_string", "")
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		row_inner.add_child(title)
		var buy_btn := Button.new()
		buy_btn.text = "Satın Al"
		buy_btn.custom_minimum_size = Vector2(120, 44)
		buy_btn.pressed.connect(_on_buy_pressed.bind(pid))
		var btn_st := StyleBoxFlat.new()
		btn_st.bg_color = Color(0.15, 0.5, 0.25)
		btn_st.set_corner_radius_all(8)
		btn_st.set_border_width_all(1)
		btn_st.border_color = Color(0.3, 0.7, 0.4, 0.9)
		buy_btn.add_theme_stylebox_override("normal", btn_st)
		buy_btn.add_theme_font_size_override("font_size", 16)
		buy_btn.add_theme_color_override("font_color", Color(1, 1, 1))
		row_inner.add_child(buy_btn)
		products_list.add_child(row)
	_refresh_gems()

func _on_buy_pressed(product_id: String) -> void:
	if status_label:
		status_label.text = "İşlem yapılıyor..."
	if IAPService.is_purchase_in_progress():
		return
	IAPService.start_purchase(product_id)

func _on_purchase_completed(success: bool, product_id: String, gems: int, error: String) -> void:
	_refresh_gems()
	if status_label:
		if success:
			status_label.text = "+%d elmas eklendi." % gems
		else:
			status_label.text = "Hata: %s" % error if error else "Satın alınamadı."
	_build_products()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
