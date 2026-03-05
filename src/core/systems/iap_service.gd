# Faz 4.1–4.3 – IAP altyapısı
# Godot IAP / store plugin soyutlaması; Google Play + Apple App Store için
# Android: GodotGooglePlayBilling veya AndroidIAPP eklentisi bağlanabilir.
# iOS: InAppStore (StoreKit) veya Godot iOS IAP eklentisi bağlanabilir.
# Editör/PC: stub (test satın alma simülasyonu).
extends Node

# 4.2 – Ürün konfigürasyonu (plan: Starter Pack, Gem S/M/L/XL, Character Pack, Weapon Bundle, Cosmetic Set)
# store_id_android / store_id_ios: mağaza konsolunda aynı id ile tanımlanmalı
const PRODUCTS: Dictionary = {
	# Plan: Starter Pack – ilk alım teklifi
	"starter_pack": {
		"gems": 100,
		"character_id": "female_soldier",
		"title": "Başlangıç Paketi",
		"price_string": "₺34,99",
		"store_id_android": "survivor_starter_pack",
		"store_id_ios": "survivor_starter_pack"
	},
	# Plan: Gem Pack S/M/L/XL
	"gems_s": {
		"gems": 250,
		"title": "250 Elmas",
		"price_string": "₺69,99",
		"store_id_android": "survivor_gems_250",
		"store_id_ios": "survivor_gems_250"
	},
	"gems_m": {
		"gems": 700,
		"title": "700 Elmas",
		"price_string": "₺179,99",
		"store_id_android": "survivor_gems_700",
		"store_id_ios": "survivor_gems_700"
	},
	"gems_l": {
		"gems": 1500,
		"title": "1500 Elmas",
		"price_string": "₺349,99",
		"store_id_android": "survivor_gems_1500",
		"store_id_ios": "survivor_gems_1500"
	},
	"gems_xl": {
		"gems": 3500,
		"title": "3500 Elmas + Bonus",
		"price_string": "₺699,99",
		"store_id_android": "survivor_gems_3500",
		"store_id_ios": "survivor_gems_3500"
	},
	# Eski paketler (uyumluluk)
	"gems_small": {
		"gems": 100,
		"title": "100 Elmas",
		"price_string": "₺19,99",
		"store_id_android": "survivor_gems_100",
		"store_id_ios": "survivor_gems_100"
	},
	"gems_medium": {
		"gems": 500,
		"title": "500 Elmas",
		"price_string": "₺79,99",
		"store_id_android": "survivor_gems_500",
		"store_id_ios": "survivor_gems_500"
	},
	"gems_large": {
		"gems": 1200,
		"title": "1200 Elmas",
		"price_string": "₺149,99",
		"store_id_android": "survivor_gems_1200",
		"store_id_ios": "survivor_gems_1200"
	},
	# Plan: Character Pack – özel karakter (sınırlı süre)
	"character_pack": {
		"character_id": "heavy_gunner",
		"title": "Karakter Paketi",
		"price_string": "₺99,99",
		"store_id_android": "survivor_character_pack",
		"store_id_ios": "survivor_character_pack"
	},
	# Plan: Weapon Bundle – 3 epik silah
	"weapon_bundle": {
		"weapon_ids": ["shotgun", "sniper", "magic_wand"],
		"title": "3 Epik Silah Paketi",
		"price_string": "₺129,99",
		"store_id_android": "survivor_weapon_bundle",
		"store_id_ios": "survivor_weapon_bundle"
	},
	# Plan: Cosmetic Set – tam skin seti
	"cosmetic_set": {
		"character_skin_id": "epic_blue",
		"weapon_skin_id": "epic_blue",
		"title": "Epik Görünüm Seti",
		"price_string": "₺69,99",
		"store_id_android": "survivor_cosmetic_set",
		"store_id_ios": "survivor_cosmetic_set"
	}
}

signal purchase_started(product_id: String)
signal purchase_completed(success: bool, product_id: String, gems: int, error: String)
signal products_loaded(success: bool)

var _purchase_in_progress: bool = false
var _pending_product_id: String = ""

func _ready() -> void:
	# Mobilde store bağlandığında products_loaded emit edilir
	if not _is_store_available():
		products_loaded.emit(true)

func _is_store_available() -> bool:
	return OS.has_feature("Android") or OS.has_feature("iOS")

func get_products() -> Dictionary:
	return PRODUCTS.duplicate()

func get_product(product_id: String) -> Dictionary:
	return PRODUCTS.get(product_id, {})

# 4.3 – Satın alma akışı: Başlat → doğrula → ödül
# Receipt validation: ileride server-side tercih edilir; şimdi client-side stub.
func start_purchase(product_id: String) -> void:
	if _purchase_in_progress:
		purchase_completed.emit(false, product_id, 0, "Zaten bir işlem devam ediyor")
		return
	var prod := get_product(product_id)
	if prod.is_empty():
		purchase_completed.emit(false, product_id, 0, "Ürün bulunamadı")
		return

	_purchase_in_progress = true
	_pending_product_id = product_id
	purchase_started.emit(product_id)

	if _is_store_available():
		_do_platform_purchase(product_id, prod)
	else:
		# Editör / PC: test satın alma simülasyonu
		_fulfill_test_purchase(product_id, prod)

func _do_platform_purchase(product_id: String, prod: Dictionary) -> void:
	# Android: GodotGooglePlayBilling veya AndroidIAPP plugin'i burada çağrılacak
	# Örnek: Engine.get_singleton("GodotGooglePlayBilling").purchase(product_id)
	# iOS: InAppStore.purchase(store_id)
	# Şimdilik mobilde de test modunda simüle ediyoruz; gerçek plugin bağlandığında
	# callback'te receipt alınıp doğrulanacak, sonra _grant_gems çağrılacak.
	if OS.has_feature("Android"):
		# TODO: Android plugin purchase flow; callback'te _on_platform_purchase_result
		_fulfill_test_purchase(product_id, prod)
	elif OS.has_feature("iOS"):
		# TODO: iOS InAppStore purchase flow; callback'te _on_platform_purchase_result
		_fulfill_test_purchase(product_id, prod)
	else:
		_fulfill_test_purchase(product_id, prod)

func _fulfill_test_purchase(product_id: String, prod: Dictionary) -> void:
	var gems_granted: int = int(prod.get("gems", 0))
	var ok := _verify_and_grant(product_id, prod, "")
	_purchase_in_progress = false
	_pending_product_id = ""
	purchase_completed.emit(ok, product_id, gems_granted, "" if ok else "Doğrulama başarısız")
	if ok and has_node("/root/BackendService"):
		get_node("/root/BackendService").push_cloud_save()

func _verify_and_grant(product_id: String, prod: Dictionary, _receipt: String) -> bool:
	if not has_node("/root/GameData"):
		return false
	var gd = get_node("/root/GameData")
	var granted_any := false
	# Elmas
	var gems: int = int(prod.get("gems", 0))
	if gems > 0:
		gd.add_gems(gems, "iap", product_id)
		granted_any = true
	# Plan: Starter Pack / Character Pack – karakter aç
	var char_id: String = prod.get("character_id", "")
	if not char_id.is_empty() and char_id in gd.CHARACTERS:
		if char_id not in gd.owned_characters:
			gd.owned_characters.append(char_id)
			gd.save_data()
			granted_any = true
	# Plan: Weapon Bundle – 3 silah aç
	var weapon_ids: Array = prod.get("weapon_ids", [])
	for wid in weapon_ids:
		if wid in gd.WEAPONS and wid not in gd.owned_weapons:
			gd.owned_weapons[wid] = 1
			granted_any = true
	if weapon_ids.size() > 0:
		gd.save_data()
	# Plan: Cosmetic Set – skin aç
	var c_skin: String = prod.get("character_skin_id", "")
	var w_skin: String = prod.get("weapon_skin_id", "")
	if not c_skin.is_empty() and gd.has_method("unlock_character_skin"):
		gd.unlock_character_skin(c_skin)
		granted_any = true
	if not w_skin.is_empty() and gd.has_method("unlock_weapon_skin"):
		gd.unlock_weapon_skin(w_skin)
		granted_any = true
	if not granted_any and gems <= 0:
		return false
	if has_node("/root/AnalyticsService"):
		var analytics = get_node("/root/AnalyticsService")
		if analytics.has_method("purchase_event"):
			analytics.purchase_event(product_id, gems, "")
	return true

func is_purchase_in_progress() -> bool:
	return _purchase_in_progress
