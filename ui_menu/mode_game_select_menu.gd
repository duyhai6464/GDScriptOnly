extends PanelContainer

signal go_back

@onready var button1 := %Button1
@onready var button2 := %Button2
@onready var button3 := %Button3

@onready var info1 := %Info1 as RichLabelAutoSizer
@onready var info2 := %Info2 as RichLabelAutoSizer
@onready var info3 := %Info3 as RichLabelAutoSizer

@onready var savedgame = GlobalConfig.savedgame as SavedGame

const path_game_scene = "res://game/game.tscn"
const path_tutorial_scene := "res://game/tutorial_scene.tscn"

const info_game_text_mode_1 := '_info_game_mode_1_'
const info_game_text_mode_2 := '_info_game_mode_2_'
const info_game_text_mode_3 := '_info_game_mode_3_'

signal game_start_request
signal game_start_accept

func _ready():
	GlobalConfig.current_game_mode = GlobalConfig.GameMode.BOUNTY_HUNTER
	game_start_accept.connect(func (): SignalBus.wait_load_scene.emit(path_game_scene))

func show_on_pressed():
	show_info(GlobalConfig.current_game_mode)
	if not savedgame.skip_tutorial:
		SignalBus.request_scene.emit(path_tutorial_scene)
		var popup_confirm := preload("res://ui_menu/Component/popup_confirm.tscn").instantiate()
		popup_confirm.confirm_text = '_r_u_want_skip_'
		add_child(popup_confirm)
		popup_confirm.popup_enter()
		popup_confirm.CANCEL.connect(func (): SignalBus.wait_load_scene.emit(path_tutorial_scene))
		popup_confirm.OK.connect(func ():savedgame.skip_tutorial = true; savedgame.save())
	SignalBus.request_scene.emit(path_game_scene)

var tween: Tween = null
var tween_duration: float = 1.2

func mode_game_to_info(mode: int) -> RichLabelAutoSizer:
	match mode:
		GlobalConfig.GameMode.BOUNTY_HUNTER:
			return info1
		GlobalConfig.GameMode.SURVIVAL:
			return info2
		GlobalConfig.GameMode.NORMAL:
			return info3
	return null

func hide_typing_info():
	var mode = mode_game_to_info(GlobalConfig.current_game_mode)
	if mode != null:
		mode.visible_ratio = 0

func show_info(mode: int, pre_mode: int = -1):
	var info := mode_game_to_info(mode)
	var pre_info := mode_game_to_info(pre_mode)
	if tween != null:
		tween.kill()
		tween = null
	if pre_info != null and mode != pre_mode:
		pre_info.visible = true
	info.visible = true
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_parallel()
	tween.tween_property(info, 'visible_ratio', 1, tween_duration).from(0)
	tween.tween_property(info, 'size_flags_stretch_ratio', 1, tween_duration/3).from(0)
	if pre_info != null and mode != pre_mode:
		tween.tween_property(pre_info, 'size_flags_stretch_ratio', 0, tween_duration/3).from(1)
		tween.tween_property(pre_info, 'visible', false, tween_duration/3)

func _on_back_button_pressed():
	go_back.emit()


func _on_button_1_pressed():
	if button1.button_pressed:
		button2.button_pressed = false
		button3.button_pressed = false
		info1.text = tr(info_game_text_mode_1)
		show_info(GlobalConfig.GameMode.BOUNTY_HUNTER, GlobalConfig.current_game_mode)
		GlobalConfig.current_game_mode = GlobalConfig.GameMode.BOUNTY_HUNTER
	else:
		game_start_request.emit()


func _on_button_2_pressed():
	if button2.button_pressed:
		button1.button_pressed = false
		button3.button_pressed = false
		info2.text = tr(info_game_text_mode_2)
		show_info(GlobalConfig.GameMode.SURVIVAL, GlobalConfig.current_game_mode)
		GlobalConfig.current_game_mode = GlobalConfig.GameMode.SURVIVAL
	else:
		game_start_request.emit()


func _on_button_3_pressed():
	if button3.button_pressed:
		button1.button_pressed = false
		button2.button_pressed = false
		info3.text = tr(info_game_text_mode_3)
		show_info(GlobalConfig.GameMode.NORMAL, GlobalConfig.current_game_mode)
		GlobalConfig.current_game_mode = GlobalConfig.GameMode.NORMAL
	else:
		game_start_request.emit()
