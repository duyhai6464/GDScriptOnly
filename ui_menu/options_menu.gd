extends PanelContainer

@onready var savedgame = GlobalConfig.savedgame as SavedGame

@onready var sound_button_touch = %SoundButtonTouch
@onready var music_button_touch = %MusicButtonTouch
@onready var language_button_touch = %LanguageButtonTouch
@onready var input_button_touch = %InputButtonTouch
@onready var play_account_container: VBoxContainer = %PlayAccountContainer

signal go_back

func _ready():
	sound_button_touch.select = int(not savedgame.soundOn)
	music_button_touch.select = savedgame.music + 1
	language_button_touch.select = int(savedgame.lang == 'vi') + 1
	input_button_touch.select = savedgame.inputOption + 1
	if savedgame.privacy_consent:
		change_privacy_consent()
	GooglePlayServices.sign_out_success.connect(on_sign_out_success)
	GooglePlayServices.sign_in_success.connect(on_sign_in_success)
	GooglePlayServices.sign_out_failed.connect(on_sign_out_failed)
	GooglePlayServices.sign_in_failed.connect(on_sign_in_failed)
	change_account_ui(GooglePlayServices.isSignedIn())


func _on_go_back_pressed():
	savedgame.save()
	go_back.emit()


func _on_sound_button_touch_select_changed():
	savedgame.soundOn = sound_button_touch.select != 1
	GlobalMusic.set_sfx_mute(not savedgame.soundOn)

func _on_music_button_touch_select_changed():
	savedgame.music = music_button_touch.select - 1
	GlobalMusic.set_music_background_track(savedgame.music)
	if not GlobalMusic.playing:
		GlobalMusic.play()

func _on_language_button_touch_select_changed():
	if language_button_touch.select == 2:
		savedgame.lang = 'vi'
	elif language_button_touch.select == 1:
		savedgame.lang = 'en'
	TranslationServer.set_locale(savedgame.lang)

func _on_input_button_touch_select_changed():
	savedgame.inputOption = input_button_touch.select - 1

func _on_privacy_consent_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			savedgame.privacy_consent = not savedgame.privacy_consent
			change_privacy_consent()

@onready var state_privacy_consent_texture: TextureRect = %StatePrivacyConsentTexture
@onready var privacy_consent_label: Label = %PrivacyConsentLabel
func change_privacy_consent():
	var ad_colony_app_options := AdColonyAppOptions.new()
	if savedgame.privacy_consent:
		ad_colony_app_options.set_privacy_consent_string(AdColonyAppOptions.CCPA, "_OPTED_IN_")
		ad_colony_app_options.set_privacy_consent_string(AdColonyAppOptions.GDPR, "_OPTED_IN_")
		Vungle.update_consent_status(Vungle.Consent.OPTED_IN, "_OPTED_IN_")
		Vungle.update_ccpa_status(Vungle.Consent.OPTED_IN)
		state_privacy_consent_texture.texture = preload("res://game/Game_asset/achievement/dot_green.png")
		privacy_consent_label.text = '_OPTED_IN_'
	else:
		ad_colony_app_options.set_privacy_consent_string(AdColonyAppOptions.CCPA, "_OPTED_OUT_")
		ad_colony_app_options.set_privacy_consent_string(AdColonyAppOptions.GDPR, "_OPTED_OUT_")
		Vungle.update_consent_status(Vungle.Consent.OPTED_OUT, "_OPTED_OUT_")
		Vungle.update_ccpa_status(Vungle.Consent.OPTED_OUT)
		state_privacy_consent_texture.texture = preload("res://game/Game_asset/achievement/dot_red.png")
		privacy_consent_label.text = '_OPTED_OUT_'

func _on_change_account_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			SignalBus.freeze_start.emit()
			if GooglePlayServices.isSignedIn():
				GooglePlayServices.signOut()
			else:
				GooglePlayServices.signIn()

@onready var change_account_texture: TextureRect = %ChangeAccountTexture
@onready var change_account_label: Label = %ChangeAccountLabel
func change_account_ui(is_sign_in):
	if is_sign_in:
		change_account_label.text = '_change_account_'
		change_account_texture.texture = preload("res://Fonts/icon/google-play-games-switch.png")
	else :
		change_account_label.text = '_log_in_'
		change_account_texture.texture = preload("res://Fonts/icon/google-play-games.png")
	SignalBus.freeze_finish.emit()

func on_sign_out_failed():
	SignalBus.request_popup_nofi.emit(13, '_sign_out_failed_')
	SignalBus.freeze_finish.emit()

func on_sign_in_failed(error: int):
	SignalBus.request_popup_nofi.emit(13, '_sign_in_failed_')
	SignalBus.freeze_finish.emit()

func on_sign_out_success():
	change_account_ui(false)

func on_sign_in_success(data: Dictionary):
	change_account_ui(true)
