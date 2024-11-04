extends Node

var devices_id: Array[String] = [
	'BD9FC53CA98ADB217BD354BDF0DE205C',
	'373451D72756CC160B6863B2E722EB19',
	'BFA496C9235900F98994ECEE58DE2589',
	'D2B5B6735FDE2EFE257C7399A1A42312',
	'79380D517D3843D1A09E5731AC460BA9',
	'D4BAACBBDCAA2AE6851D5FD56AD9C15F',
	'335551DADCC8C40283A221E9A854E384',
	'10F7FB7A4E40AA886C212BCCB5442C46',
	'883504E505F983B60225823973F84DD3',
	'6EC9520D9CFFDCDF4A2A67B68CB09266',
	'55EAE032E97911E909DD7F4FDF568F0D',
	'BDB82ED594DB45090FEDC2B5D91FB009',
	'09F8A9508CB135AC53FE37D3CB9AAECD',
	'A962F526F01F869A1A045EE928F278A4',
	'EC2D39FA8DA8E76CD8EF34C6F45BE272',
	'C7D78CA626BE74DD452A59BB33279716',
	'66F706E9DC396407A6E99EACC83D552D',
	'E14519237A08CB3B2AC36D845D452C5A',
	'7DB4DE4B1CB3AC85C314CA112D2EEB9C',
	'641F905091CA3DB9FBF147D554C18663',
	'F73425EA201AB00D441A1F575AB644F1',
	'7ECF5A1130F7009E4C9472882F41B2DC',
	'D68C332977E5E0B62CEF9287C202396A',
	'9C152E129E3A61AE5E3678B69AAA23AC',
]
var start_ready: bool = false
signal init_ads_complete
signal reward_ads_earn_reward
signal ads_dismissed_full_screen

#@onready var banner_ads :BannerAdsNode = $BannerAds
@onready var reward_ads :RewardAdsNode = $RewardAds
@onready var reward_ads_2: RewardAdsNode = $RewardAds2
@onready var reward_ads_3: RewardAdsNode = $RewardAds3
@onready var interstitial_ads: InterstitialAdsNode = $InterstitialAds

@onready var savedgame = GlobalConfig.savedgame as SavedGame

func _ready() -> void:
	var request_configuration := RequestConfiguration.new()
	request_configuration.tag_for_child_directed_treatment = 1
	request_configuration.tag_for_under_age_of_consent = 1
	request_configuration.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	request_configuration.test_device_ids = []
	request_configuration.convert_to_dictionary()
	MobileAds.set_request_configuration(request_configuration)
	#MobileAds.initialize(on_initialization_complete_listener)
	init_ads_complete.connect(func ():
		start_ready = true
		#request_banner_ads()
		request_reward_ads()
		request_interstitial_ads_shop_refresh()
	)
	reward_ads.earned_reward.connect(_on_ads_earn_reward)
	reward_ads_2.earned_reward.connect(_on_ads_earn_reward)
	reward_ads_3.earned_reward.connect(_on_ads_earn_reward)
	reward_ads.ads_dismissed_full_screen_content.connect(_on_ads_dismissed_full_screen)
	reward_ads_2.ads_dismissed_full_screen_content.connect(_on_ads_dismissed_full_screen)
	reward_ads_3.ads_dismissed_full_screen_content.connect(_on_ads_dismissed_full_screen)
	interstitial_ads.ads_dismissed_full_screen_content.connect(_on_ads_dismissed_full_screen)

func _on_initialization_complete(initialization_status : InitializationStatus) -> void:
	print("MobileAds initialization complete\n", initialization_status)
	call_deferred('emit_signal', 'init_ads_complete')
	var ad_colony_app_options := AdColonyAppOptions.new()
	print("set values ad_colony")
	ad_colony_app_options.set_privacy_framework_required(AdColonyAppOptions.CCPA, true)
	ad_colony_app_options.set_privacy_framework_required(AdColonyAppOptions.GDPR, true)
	#ad_colony_app_options.set_test_mode(false)
	if savedgame.privacy_consent:
		ad_colony_app_options.set_privacy_consent_string(AdColonyAppOptions.CCPA, "_OPTED_IN_")
		ad_colony_app_options.set_privacy_consent_string(AdColonyAppOptions.GDPR, "_OPTED_IN_")
		Vungle.update_consent_status(Vungle.Consent.OPTED_IN, "_OPTED_IN_")
		Vungle.update_ccpa_status(Vungle.Consent.OPTED_IN)
	else:
		ad_colony_app_options.set_privacy_consent_string(AdColonyAppOptions.CCPA, "_OPTED_OUT_")
		ad_colony_app_options.set_privacy_consent_string(AdColonyAppOptions.GDPR, "_OPTED_OUT_")
		Vungle.update_consent_status(Vungle.Consent.OPTED_OUT, "_OPTED_OUT_")
		Vungle.update_ccpa_status(Vungle.Consent.OPTED_OUT)

func start():
	if start_ready:
		return
	var on_initialization_complete_listener := OnInitializationCompleteListener.new()
	on_initialization_complete_listener.on_initialization_complete = _on_initialization_complete
	WorkerThreadPool.add_task(MobileAds.initialize.bind(on_initialization_complete_listener))

#func request_banner_ads():
	#if not start_ready:
		#return
	#banner_ads.show_ads()

func request_reward_ads():
	if not start_ready:
		return
	reward_ads._on_load_pressed()
	reward_ads_2._on_load_pressed()
	reward_ads_3._on_load_pressed()


func request_interstitial_ads_shop_refresh():
	if not start_ready:
		return
	interstitial_ads._on_load_pressed()


func show_reward_ads():
	if not start_ready:
		return false
	var x = range(1, 4)
	x.shuffle()
	for i in x:
		if i == 1:
			if reward_ads.state == 3:
				if reward_ads.show_ads():
					return true
		if i == 2:
			if reward_ads_2.state == 3:
				if reward_ads_2.show_ads():
					return true
		if i == 3:
			if reward_ads_3.state == 3:
				if reward_ads_3.show_ads():
					return true
	return false

func _on_ads_earn_reward(amount: int, item: String):
	reward_ads_earn_reward.emit()
	print('_on_ads_earn_reward', amount, item)

func _on_ads_dismissed_full_screen():
	ads_dismissed_full_screen.emit()
