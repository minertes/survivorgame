# Faz 5.1 – Liderlik tablosu
# Günlük/haftalık skor; backend'de sadece kendi skorunu yaz (device_id ile güvenli).
extends Node

signal leaderboard_loaded(period: String, entries: Array, error: String)
signal score_submitted(period: String, success: bool, error: String)

const PERIOD_DAILY := "daily"
const PERIOD_WEEKLY := "weekly"
var _http: HTTPRequest = null
var _pending_callback: Callable

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func submit_score(score: int, period: String = PERIOD_DAILY) -> void:
	var backend = get_node_or_null("/root/BackendService")
	if not backend:
		score_submitted.emit(period, false, "Backend yok")
		return
	if backend.base_url.is_empty():
		score_submitted.emit(period, true, "")  # Offline: kabul edildi say, kaydetme
		return
	var url := _leaderboard_url(backend, "submit")
	var body := JSON.stringify({"period": period, "score": score})
	var headers := ["Content-Type: application/json", "X-Device-Id: " + backend.get_device_id()]
	if not backend.api_key.is_empty():
		headers.append("Authorization: Bearer " + backend.api_key)
	var err := _http.request(url, headers, HTTPClient.METHOD_PUT, body)
	_pending_callback = _on_submit_done.bind(period)
	if err != OK:
		score_submitted.emit(period, false, "İstek hatası")

func get_leaderboard(period: String = PERIOD_DAILY, limit: int = 20) -> void:
	var backend = get_node_or_null("/root/BackendService")
	if not backend or backend.base_url.is_empty():
		leaderboard_loaded.emit(period, _local_fallback_entries(), "")
		return
	var url := _leaderboard_url(backend, "list") + "?period=" + period + "&limit=" + str(limit)
	var headers: PackedStringArray = ["X-Device-Id: " + backend.get_device_id()]
	if not backend.api_key.is_empty():
		headers.append("Authorization: Bearer " + backend.api_key)
	var err := _http.request(url, headers, HTTPClient.METHOD_GET)
	_pending_callback = _on_list_done.bind(period)
	if err != OK:
		leaderboard_loaded.emit(period, [], "İstek hatası")

func _leaderboard_url(backend: Node, action: String) -> String:
	var base: String = backend.base_url
	if base.ends_with("/"):
		return base + "leaderboard/" + action
	return base + "/leaderboard/" + action

func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _pending_callback.is_valid():
		_pending_callback.call(result, code, body)

func _on_submit_done(result: int, code: int, _body: PackedByteArray, period: String) -> void:
	_pending_callback = Callable()
	var ok := result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300
	score_submitted.emit(period, ok, "" if ok else "HTTP %d" % code)

func _on_list_done(result: int, code: int, body: PackedByteArray, period: String) -> void:
	_pending_callback = Callable()
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		leaderboard_loaded.emit(period, _local_fallback_entries(), "Yüklenemedi")
		return
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		leaderboard_loaded.emit(period, [], "JSON hatası")
		return
	var data = json.get_data()
	var entries: Array = data.get("entries", []) if typeof(data) == TYPE_DICTIONARY else []
	leaderboard_loaded.emit(period, entries, "")

func _local_fallback_entries() -> Array:
	# Backend yokken: kendi skorunu tek satır göster
	if not has_node("/root/GameData"):
		return []
	var gd = get_node("/root/GameData")
	return [{"rank": 1, "score": gd.best_wave, "is_self": true, "masked_id": "Sen"}]
