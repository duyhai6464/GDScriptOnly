class_name InterstitialAdsNode extends Node

@export_multiline var ads_unit_id = 'ca-app-pub-6116335554896623/9871814375'

var interstitial_ad : InterstitialAd
var interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
var full_screen_content_callback := FullScreenContentCallback.new()

enum AdsState {NONE, WAIT, FAILED, LOADED, SHOWED}
var state: AdsState = 0

signal ads_dismissed_full_screen_content

func _ready():
	interstitial_ad_load_callback.on_ad_failed_to_load = on_interstitial_ad_failed_to_load
	interstitial_ad_load_callback.on_ad_loaded = on_interstitial_ad_loaded

	full_screen_content_callback.on_ad_clicked = func() -> void:
		print("on_ad_clicked")
	full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("on_ad_dismissed_full_screen_content")
		destroy()
		ads_dismissed_full_screen_content.emit()
		_on_load_pressed()

	full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(ad_error : AdError) -> void:
		print("on_ad_failed_to_show_full_screen_content")
	full_screen_content_callback.on_ad_impression = func() -> void:
		print("on_ad_impression")
	full_screen_content_callback.on_ad_showed_full_screen_content = func() -> void:
		print("on_ad_showed_full_screen_content")
		state = 4


func on_interstitial_ad_failed_to_load(adError : LoadAdError) -> void:
	print(adError.message)
	state = 2

func on_interstitial_ad_loaded(_interstitial_ad : InterstitialAd) -> void:
	print("interstitial ad loaded" + str(_interstitial_ad._uid))
	_interstitial_ad.full_screen_content_callback = full_screen_content_callback
	self.interstitial_ad = _interstitial_ad
	state = 3

func _on_load_pressed():
	if interstitial_ad != null:
		return
	if state == 1 or state >= 3:
		return
	InterstitialAdLoader.new().load(ads_unit_id, AdRequest.new(), interstitial_ad_load_callback)
	state = 1


func show_ads():
	if interstitial_ad != null:
		interstitial_ad.show()
	else:
		_on_load_pressed()

func destroy():
	if interstitial_ad:
		interstitial_ad.destroy()
		interstitial_ad = null #need to load again
		state = 0
