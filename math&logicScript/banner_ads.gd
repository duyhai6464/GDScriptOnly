class_name BannerAdsNode extends Node

var ad_view : AdView
var ad_listener := AdListener.new()
@export var adPosition := AdPosition.Values.BOTTOM

@export_multiline var ads_unit_id = 'ca-app-pub-6116335554896623/5929125624'

enum AdsState {NONE, WAIT, FAILED, LOADED, SHOWED}
var state: AdsState = 0

func _ready():
	### load banner ###
	ad_listener.on_ad_failed_to_load = _on_ad_failed_to_load
	ad_listener.on_ad_clicked = _on_ad_clicked
	ad_listener.on_ad_closed = _on_ad_closed
	ad_listener.on_ad_impression = _on_ad_impression
	ad_listener.on_ad_loaded = _on_ad_loaded
	ad_listener.on_ad_opened = _on_ad_opened
	#_on_load_banner_pressed()


func _on_ad_failed_to_load(load_ad_error : LoadAdError) -> void:
	print("_on_ad_failed_to_load: " + load_ad_error.message)
	state = 2

func _on_ad_loaded() -> void:
	print("_on_banner_ad_loaded")
	state = 3

func _on_ad_clicked() -> void:
	print("_on_ad_clicked")


func _on_ad_impression() -> void:
	print("_on_ad_impression")
	state = 4
	await get_tree().create_timer(600).timeout
	destroy()
	_on_load_banner_pressed()


func _on_ad_opened() -> void:
	print("_on_ad_opened")

func _on_ad_closed() -> void:
	print("_on_ad_closed")

func _on_load_banner_pressed() -> void:
	if ad_view:
		return
	if state == 1 or state >= 3:
		return
	var adSizecurrent_orientation := AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	print(["adSizecurrent_orientation: ", adSizecurrent_orientation.width, ", ", adSizecurrent_orientation.height])
	var adSizeportrait := AdSize.get_portrait_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	print(["adSizeportrait: ", adSizeportrait.width, ", ", adSizeportrait.height])
	var adSizelandscape := AdSize.get_landscape_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	print(["adSizelandscape: ", adSizelandscape.width, ", ", adSizelandscape.height])
	var adSizesmart := AdSize.get_smart_banner_ad_size()
	print(["adSizesmart: ", adSizesmart.width, ", ",adSizesmart.height])
	ad_view = AdView.new(ads_unit_id, adSizecurrent_orientation, adPosition)
	ad_view.ad_listener = ad_listener
	var ad_request := AdRequest.new()
	ad_view.load_ad(ad_request)
	state = 1


	#var vungle_mediation_extras := VungleInterstitialMediationExtras.new()
	#vungle_mediation_extras.all_placements = ["Banner_in_menu"]
	#vungle_mediation_extras.sound_enabled = true
	#vungle_mediation_extras.user_id = "asdasda"
	#ad_request.mediation_extras.append(vungle_mediation_extras)
	#var ad_colony_mediation_extras := AdColonyMediationExtras.new()
	#ad_colony_mediation_extras.show_post_popup = false
	#ad_colony_mediation_extras.show_pre_popup = true
	#ad_request.mediation_extras.append(ad_colony_mediation_extras)
	#ad_request.keywords.append("21313")
	#ad_request.extras["ID"] = "value"


func destroy() -> void:
	if ad_view:
		ad_view.destroy()
		ad_view = null
		state = 0

func show_ads() -> void:
	if ad_view != null:
		ad_view.show()
	else:
		_on_load_banner_pressed()

func hide_ads() -> void:
	if ad_view != null:
		ad_view.hide()
