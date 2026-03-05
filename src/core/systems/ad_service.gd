# Faz 4.4 – Reklam entegrasyonu (opsiyonel)
# Ödüllü video ve/veya interstitial; sıklık sınırı ve kullanıcı onayı (GDPR/CCPA).
# Gerçek implementasyon: AdMob / Unity Ads SDK ile mobilde bağlanır.
extends Node

signal consent_updated(given: bool)
signal rewarded_completed(success: bool)
signal interstitial_closed()

# Kullanıcı reklam onayı (GDPR/CCPA)
var consent_given: bool = false
# Interstitial sıklık sınırı (saniye)
var interstitial_cooldown_sec: int = 120
var _last_interstitial_time: float = -9999.0

func _ready() -> void:
	pass

func set_consent(given: bool) -> void:
	consent_given = given
	consent_updated.emit(given)

func can_show_interstitial() -> bool:
	if not consent_given:
		return false
	var now := Time.get_unix_time_from_system()
	return (now - _last_interstitial_time) >= interstitial_cooldown_sec

# Ödüllü video: izlendikten sonra callback ile ödül verilir
func show_rewarded_video(callback: Callable) -> void:
	if not consent_given:
		callback.call(false)
		return
	# TODO: AdMob/Unity Ads rewarded ad göster; tamamlanınca callback.call(true)
	# PC/Editör: reklam yok
	if OS.has_feature("mobile"):
		# Mobilde gerçek reklam SDK çağrılacak
		callback.call(false)
	else:
		callback.call(false)

# Interstitial: oyun içi geçişlerde (örn. game over sonrası)
func show_interstitial() -> bool:
	if not consent_given or not can_show_interstitial():
		return false
	# TODO: AdMob/Unity Ads interstitial göster; kapanınca interstitial_closed.emit()
	_last_interstitial_time = Time.get_unix_time_from_system()
	return false
