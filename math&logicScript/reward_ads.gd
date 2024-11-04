class_name RewardAdsNode extends Node

var rewarded_ad : RewardedAd
var on_user_earned_reward_listener := OnUserEarnedRewardListener.new()
var rewarded_ad_load_callback := RewardedAdLoadCallback.new()
var full_screen_content_callback := FullScreenContentCallback.new()

@export_multiline var ads_unit_id = 'ca-app-pub-6116335554896623/8696008667'

signal earned_reward(amount: int, item: String)
signal reward_ad_failed_to_load
signal reward_ad_loaded
signal ads_dismissed_full_screen_content

enum AdsState {NONE, WAIT, FAILED, LOADED, SHOWED}
var state: AdsState = 0

func _ready():
	on_user_earned_reward_listener.on_user_earned_reward = on_user_earned_reward

	rewarded_ad_load_callback.on_ad_failed_to_load = on_rewarded_ad_failed_to_load
	rewarded_ad_load_callback.on_ad_loaded = on_rewarded_ad_loaded

	full_screen_content_callback.on_ad_clicked = func() -> void:
		print("on_ad_clicked")
	full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("on_ad_dismissed_full_screen_content")
		destroy()
		ads_dismissed_full_screen_content.emit()
		_on_load_pressed()

	full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(ad_error : AdError) -> void:
		print("on_ad_failed_to_show_full_screen_content", ad_error)
	full_screen_content_callback.on_ad_impression = func() -> void:
		print("on_ad_impression")
	full_screen_content_callback.on_ad_showed_full_screen_content = func() -> void:
		print("on_ad_showed_full_screen_content")
		state = 4

func on_rewarded_ad_failed_to_load(adError : LoadAdError) -> void:
	reward_ad_failed_to_load.emit()
	print("rewarded ad error", adError.message)
	state = 2

func on_rewarded_ad_loaded(_rewarded_ad : RewardedAd) -> void:
	reward_ad_loaded.emit()
	print("rewarded ad loaded " + str(_rewarded_ad._uid))
	_rewarded_ad.full_screen_content_callback = full_screen_content_callback
	self.rewarded_ad = _rewarded_ad
	state = 3

func on_user_earned_reward(rewarded_item : RewardedItem):
	earned_reward.emit(rewarded_item.amount, rewarded_item.type)

func _on_load_pressed():
	if rewarded_ad != null:
		return
	if state == 1 or state >= 3:
		return
	RewardedAdLoader.new().load(ads_unit_id, AdRequest.new(), rewarded_ad_load_callback)
	state = 1

func show_ads() -> bool:
	if rewarded_ad != null:
		rewarded_ad.show(on_user_earned_reward_listener)
		return true
	_on_load_pressed()
	return false


func destroy():
	if rewarded_ad:
		rewarded_ad.destroy()
		rewarded_ad = null #need to load again
		state = 0
