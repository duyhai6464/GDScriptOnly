extends Control

@onready var menu := %Menu
@onready var mode_game_select_menu := %ModeGameSelectMenu
@onready var character_menu := %CharacterMenu
@onready var shop_menu := %ShopMenu
@onready var options_menu := %OptionsMenu
@onready var credit_menu := %CreditMenu

@onready var uiroot: Control = %UIroot
@onready var block: CenterContainer = %Block

const tween_duration: float = 0.5
var tween: Tween = null
var is_tween_running: bool = false

@onready var a_left = uiroot.anchor_left
@onready var a_top = uiroot.anchor_top
@onready var a_right = uiroot.anchor_right
@onready var a_bottom = uiroot.anchor_bottom

signal tween_enter_finish
signal tween_exit_finish
signal change_scene_finish

func _ready():
	enter_scene()
	if not GlobalMusic.playing:
		GlobalMusic.play()
	SignalBus.freeze_start.connect(block_usser_ui)
	SignalBus.freeze_finish.connect(unblock_usser_ui)

func change_scene(from: Control, to: Control):
	if is_tween_running:
		return
	is_tween_running = true
	exit_scene()
	await tween_exit_finish
	from.hide()
	to.show()
	enter_scene()
	await tween_enter_finish
	is_tween_running = false
	#print('_from_', from.name, '_to_', to.name, '_done_')
	change_scene_finish.emit()

func enter_scene():
	if tween != null:
		return
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(uiroot, "anchor_left", a_left, tween_duration).from(0.5)
	tween.tween_property(uiroot, "anchor_top", a_top, tween_duration).from(0.5)
	tween.tween_property(uiroot, "anchor_right", a_right, tween_duration).from(0.5)
	tween.tween_property(uiroot, "anchor_bottom", a_bottom, tween_duration).from(0.5)
	tween.tween_property(uiroot, "modulate:a", 1, tween_duration).from(0)
	await tween.finished
	tween = null
	tween_enter_finish.emit()

func exit_scene():
	if tween != null:
		return
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_parallel()
	tween.tween_property(uiroot, "anchor_left", 0.5, tween_duration).from(a_left)
	tween.tween_property(uiroot, "anchor_top", 0.5, tween_duration).from(a_top)
	tween.tween_property(uiroot, "anchor_right", 0.5, tween_duration).from(a_right)
	tween.tween_property(uiroot, "anchor_bottom", 0.5, tween_duration).from(a_bottom)
	tween.tween_property(uiroot, "modulate:a", 0, tween_duration).from(1)
	await tween.finished
	tween = null
	tween_exit_finish.emit()

func _on_play_button_press():
	change_scene(menu, mode_game_select_menu)
	mode_game_select_menu.hide_typing_info()
	await change_scene_finish
	mode_game_select_menu.show_on_pressed()


func _on_mode_game_select_menu_go_back():
	change_scene(mode_game_select_menu, menu)


func _on_option_button_pressed():
	change_scene(menu, options_menu)



func _on_options_menu_go_back():
	change_scene(options_menu, menu)



func _on_character_edit_button_pressed():
	change_scene(menu, character_menu)
	character_menu.set_scroll_vertical(0)



func _on_character_menu_go_back():
	change_scene(character_menu, menu)



func _on_credit_button_pressed():
	change_scene(menu, credit_menu)



func _on_credit_menu_go_back():
	change_scene(credit_menu, menu)



func _on_shop_button_pressed() -> void:
	change_scene(menu, shop_menu)
	shop_menu.set_scroll_vertical(0)
	AdsManager.request_reward_ads()


func _on_shop_menu_go_back() -> void:
	change_scene(shop_menu, menu)


func _on_mode_game_select_menu_game_start_request() -> void:
	if is_tween_running:
		return
	is_tween_running = true
	exit_scene()
	AdsManager.request_reward_ads()
	SignalBus.request_background_color.emit(Color8(128, 128, 128), tween_duration + 1)
	SignalBus.freeze_start.emit()
	await tween_exit_finish
	await get_tree().create_timer(1).timeout
	is_tween_running = false
	mode_game_select_menu.game_start_accept.emit()


func block_usser_ui():
	block.show()
	SignalBus.request_background_color.emit(Color.WHITE.darkened(0.4), 0.5)

func unblock_usser_ui():
	block.hide()
	SignalBus.request_background_color.emit(Color.WHITE, 0.5)
