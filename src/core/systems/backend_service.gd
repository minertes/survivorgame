# Faz 3.2 – Backend başlangıç (Firebase veya Supabase)
# Cihaz bazlı anonim kimlik, bulut kayıt (son yazma kazanır). Godot 4.x uyumlu.
# Proje kurulumu: Firebase veya Supabase projesi oluşturup base_url / api_key ayarlanır.
extends Node

const DEVICE_ID_PATH := "user://device_id.cfg"
const CLOUD_SAVE_KEY := "gamedata"

# 3.2.1 – Backend seçimi: Supabase veya Firebase projesi oluşturup base_url/api_key ayarlayın.
# Örnek Supabase: base_url = "https://xxxx.supabase.co/rest/v1/", api_key = "anon key"
var base_url: String = ""
var api_key: String = ""
var anon_uid: String = ""

var _device_id: String = ""
var _http: HTTPRequest = null
var _pending_callback: Callable

signal cloud_save_pushed(success: bool, error: String)
signal cloud_save_pulled(success: bool, data: Dictionary, error: String)
signal auth_ready(success: bool)


func _ready() -> void:
	_device_id = _get_or_create_device_id()
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_http_request_completed)
	# Faz 6.2.3 – Ortam config’ten backend URL (varsa)
	if has_node("/root/EnvConfig"):
		var ec = get_node("/root/EnvConfig")
		if ec.backend_url:
			base_url = ec.backend_url
	# Anonim kimlik: cihaz ID ile başla (3.2.2)
	anon_uid = _device_id
	auth_ready.emit(true)


# 3.2.2 – Cihaz bazlı ID (e-posta zorunlu değil)
func _get_or_create_device_id() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(DEVICE_ID_PATH) == OK:
		var id: String = cfg.get_value("device", "id", "")
		if not id.is_empty():
			return id
	var id := _generate_device_id()
	cfg.set_value("device", "id", id)
	cfg.save(DEVICE_ID_PATH)
	return id


func _generate_device_id() -> String:
	# OS.get_unique_id() varsa kullan (Android/iOS); yoksa rastgele + zaman
	var raw := ""
	if OS.has_feature("mobile") and OS.has_method("get_unique_id"):
		raw = OS.get_unique_id()
	if raw.is_empty():
		raw = str(Time.get_ticks_usec()) + str(randi()) + str(Time.get_unix_time_from_system())
	return raw.sha256_text().left(24)


func get_device_id() -> String:
	return _device_id


func get_anon_uid() -> String:
	return anon_uid


# 3.2.3 – Bulut kayıt: ilerleme verisini yaz (son yazma kazanır)
func push_cloud_save() -> void:
	if base_url.is_empty():
		cloud_save_pushed.emit(false, "Backend URL not set")
		return
	var root := get_tree().root
	var gd = root.get_node_or_null("GameData")
	if gd == null:
		cloud_save_pushed.emit(false, "GameData not available")
		return
	var payload := _serialize_gamedata_for_cloud()
	_push_to_backend(payload)


func _serialize_gamedata_for_cloud() -> Dictionary:
	var gd = get_tree().root.get_node_or_null("GameData")
	if gd == null:
		return {}
	# GameData autoload – erişilebilir alanları JSON uyumlu yap
	return {
		"xp_coins": gd.xp_coins,
		"selected_character": gd.selected_character,
		"owned_characters": gd.owned_characters,
		"owned_weapons": gd.owned_weapons,
		"equipped_weapon": gd.equipped_weapon,
		"equipped_flag": gd.equipped_flag,
		"owned_flags": gd.owned_flags,
		"best_wave": gd.best_wave,
		"total_kills": gd.total_kills,
		"total_games": gd.total_games,
		"sound_enabled": gd.sound_enabled,
		"gems": gd.gems,
		"gem_spend_log": gd.gem_spend_log,
		"achievement_unlocked": gd.achievement_unlocked,
		"last_login_ymd": gd.last_login_ymd,
		"login_streak": gd.login_streak,
		"last_claim_ymd": gd.last_claim_ymd,
		"claimed_day_index": gd.claimed_day_index,
		"prestige_level": gd.prestige_level,
		"daily_challenge_claimed_ymd": gd.daily_challenge_claimed_ymd,
		"daily_quests_ymd": gd.daily_quests_ymd,
		"daily_quests": gd.daily_quests,
		"battle_pass_season": gd.battle_pass_season,
		"battle_pass_level": gd.battle_pass_level,
		"battle_pass_xp": gd.battle_pass_xp,
		"battle_pass_premium": gd.battle_pass_premium,
		"character_skin_id": gd.character_skin_id,
		"weapon_skin_id": gd.weapon_skin_id,
		"owned_character_skins": gd.owned_character_skins,
		"owned_weapon_skins": gd.owned_weapon_skins,
		"is_vip": gd.is_vip,
		"vip_expires_at": gd.vip_expires_at,
		"device_id": _device_id,
		"updated_at": Time.get_unix_time_from_system()
	}


func _push_to_backend(payload: Dictionary) -> void:
	var body := JSON.stringify(payload)
	var url := base_url + "/save" if base_url.ends_with("/") == false else base_url + "save"
	var headers := ["Content-Type: application/json"]
	if not api_key.is_empty():
		headers.append("Authorization: Bearer " + api_key)
	headers.append("X-Device-Id: " + _device_id)
	var err := _http.request(url, headers, HTTPClient.METHOD_PUT, body)
	_pending_callback = _on_push_done
	if err != OK:
		cloud_save_pushed.emit(false, "Request failed: %s" % error_string(err))


func pull_cloud_save() -> void:
	if base_url.is_empty():
		cloud_save_pulled.emit(false, {}, "Backend URL not set")
		return
	var url := base_url + "/save?device_id=" + _device_id if not base_url.ends_with("/") else base_url + "save?device_id=" + _device_id
	var headers: PackedStringArray = []
	if not api_key.is_empty():
		headers.append("Authorization: Bearer " + api_key)
	headers.append("X-Device-Id: " + _device_id)
	var err := _http.request(url, headers, HTTPClient.METHOD_GET)
	_pending_callback = _on_pull_done
	if err != OK:
		cloud_save_pulled.emit(false, {}, "Request failed: %s" % error_string(err))


func _on_http_request_completed(result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _pending_callback.is_valid():
		_pending_callback.call(result, body)


func _on_push_done(result: int, body: PackedByteArray) -> void:
	_pending_callback = Callable()
	if result != HTTPRequest.RESULT_SUCCESS:
		cloud_save_pushed.emit(false, "HTTP error: %d" % result)
		return
	cloud_save_pushed.emit(true, "")


func _on_pull_done(result: int, body: PackedByteArray) -> void:
	_pending_callback = Callable()
	if result != HTTPRequest.RESULT_SUCCESS:
		cloud_save_pulled.emit(false, {}, "HTTP error: %d" % result)
		return
	var json := JSON.new()
	var err := json.parse(body.get_string_from_utf8())
	if err != OK:
		cloud_save_pulled.emit(false, {}, "JSON parse error")
		return
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		cloud_save_pulled.emit(false, {}, "Invalid response")
		return
	# İsteğe bağlı: GameData'ya uygula (son yazma kazanır)
	cloud_save_pulled.emit(true, data, "")


# 3.2.4 – Güvenlik: Backend tarafında kullanıcı sadece kendi verisini okur/yazar (device_id veya anon_uid ile).
# Bu script sadece client; kurallar Supabase RLS veya Firebase Rules ile tanımlanır.
