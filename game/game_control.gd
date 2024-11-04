extends Node

const DEATH_MENU = preload("res://game/death_menu.tscn")
const GAME_OVER = preload("res://game/game_over.tscn")

@onready var game_play: MainGame = %Game_play

@onready var popup_menu: Control = %PopupMenu
@onready var ingame_ui: Control = %IngameUI
@onready var pause_menu: Control = %Pause_menu

@onready var menu_buttons: VBoxContainer = %Menu_buttons
@onready var options_menu := %OptionsMenu

const tween_duration: float = 0.55
var tween : Tween = null

signal tween_enter_finish
signal tween_exit_finish

var over_menu: GameoverScene = null
var death_menu: DeathScene = null

func _ready():
	pause_menu.hide()
	options_menu.play_account_container.hide()


func enter_scene(ui: Control, top: float = 0, bottom: float = 1, bgcolor := Color.BLACK):
	if tween != null:
		return
	ui.show()
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_parallel().set_pause_mode(2)
	tween.tween_property(ui, "anchor_top", top, tween_duration).from(0.5)
	tween.tween_property(ui, "anchor_bottom", bottom, tween_duration).from(0.5)
	tween.tween_property(ui, "modulate:a", 1, tween_duration).from(0)
	if bgcolor != Color.BLACK:
		tween.tween_property(game_play, "modulate", bgcolor, tween_duration)
	await tween.finished
	tween = null
	tween_enter_finish.emit()

func exit_scene(ui: Control, top: float = 0, bottom: float = 1, bgcolor := Color.BLACK):
	if tween != null:
		return
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_parallel().set_pause_mode(2)
	tween.tween_property(ui, "anchor_top", 0.5, tween_duration).from(top)
	tween.tween_property(ui, "anchor_bottom", 0.5, tween_duration).from(bottom)
	tween.tween_property(ui, "modulate:a", 0, tween_duration).from(1)
	if bgcolor != Color.BLACK:
		tween.tween_property(game_play, "modulate", bgcolor, tween_duration)
	await tween.finished
	tween = null
	ui.hide()
	tween_exit_finish.emit()

func enter_scene_pause_menu(bgcolor := Color.BLACK):
	enter_scene(pause_menu, 0.1, 0.9, bgcolor)
func exit_scene_pause_menu(bgcolor := Color.BLACK):
	exit_scene(pause_menu, 0.1, 0.9, bgcolor)
func enter_scene_popup_menu(bgcolor := Color.BLACK):
	enter_scene(popup_menu, 0, 1, bgcolor)
func exit_scene_popup_menu(bgcolor := Color.BLACK):
	exit_scene(popup_menu, 0, 1, bgcolor)

func _on_mainmenu_button_pressed():
	SignalBus.request_scene.emit(path_to_menu)
	exit_scene_pause_menu(Color8(96, 96, 96))
	await tween_exit_finish
	SignalBus.wait_load_scene.emit(path_to_menu)


func _on_resume_button_pressed():
	exit_scene_pause_menu(Color.WHITE)
	await tween_exit_finish
	get_tree().paused = false
	pause_menu.hide()
	ingame_ui.show()


func _on_pause_button_pressed():
	get_tree().paused = true
	ingame_ui.hide()
	enter_scene_pause_menu(Color8(192, 192, 192))


func _on_options_button_pressed():
	exit_scene_pause_menu()
	await tween_exit_finish
	menu_buttons.hide()
	options_menu.show()
	enter_scene_pause_menu()


func _on_options_menu_go_back():
	exit_scene_pause_menu()
	await tween_exit_finish
	menu_buttons.show()
	options_menu.hide()
	enter_scene_pause_menu()



func _exit_tree():
	get_tree().paused = false


func _on_game_play_show_game_over() -> void:
	ingame_ui.hide()
	pause_menu.hide()

	over_menu = GAME_OVER.instantiate() as GameoverScene
	over_menu.player = game_play.main_player
	popup_menu.add_child(over_menu)
	over_menu.play.connect(game_over_request_change_scene.bind(path_to_game), CONNECT_ONE_SHOT)
	over_menu.quit.connect(game_over_request_change_scene.bind(path_to_menu), CONNECT_ONE_SHOT)
	enter_scene_popup_menu(Color8(192, 192, 192))
	await tween_enter_finish
	over_menu.info_showing()

const path_to_menu: String = "res://ui_menu/Main_menu.tscn"
const path_to_game: String = "res://game/game.tscn"
func game_over_request_change_scene(path):
	SignalBus.request_scene.emit(path)
	exit_scene_popup_menu(Color8(96, 96, 96))
	await tween_exit_finish
	SignalBus.wait_load_scene.emit(path)


func _on_game_play_main_player_death() -> void:
	death_menu = DEATH_MENU.instantiate() as DeathScene
	var time_respawn = game_play.main_player.respawn_time_remain
	if GlobalConfig.current_game_mode == GlobalConfig.GameMode.NORMAL:
		time_respawn = 0
	death_menu.time_respawn_amount = time_respawn
	popup_menu.add_child(death_menu)
	if GlobalConfig.current_game_mode != GlobalConfig.GameMode.NORMAL:
		death_menu.rejoin.connect(on_rejoin_button_pressed, CONNECT_ONE_SHOT)
		death_menu.exit_button.hide()
	else:
		death_menu.rejoin_button.icon = preload("res://game/Game_asset/ingame/money_type_advertising.png")
		death_menu.rejoin.connect(on_rejoin_ADS_button_pressed, CONNECT_ONE_SHOT)
		death_menu.exit.connect(on_exit_button_pressed, CONNECT_ONE_SHOT)

	enter_scene_popup_menu()
	if game_play.main_player.was_kill_by == null:
		game_play.main_player.was_kill_by = game_play.main_player
	if game_play.main_player.was_kill_by != game_play.main_player:
		var translate_notify_game = tr(GlobalConfig.game_talk.pick_random())
		death_menu.notify_game.set_text(translate_notify_game % game_play.main_player.was_kill_by.player_name)
		death_menu.notify_enemy.text = GlobalConfig.enemy_talk.pick_random()
	else:
		death_menu.notify_game.text = GlobalConfig.game_talk_myself.pick_random()
		death_menu.notify_enemy.text = GlobalConfig.enemy_talk_myself.pick_random()
	await tween_enter_finish
	death_menu.play()

func on_rejoin_button_pressed():
	exit_scene_popup_menu()
	await tween_exit_finish
	game_play.main_player.respawn.emit(game_play.get_spawn_point())
	ingame_ui.show()

func on_rejoin_ADS_button_pressed():
	if not AdsManager.show_reward_ads():
		SignalBus.request_popup_nofi.emit(-1, '_ads_load_failed_')
		if not SignalBus.popup_nofi.OK.is_connected(on_exit_button_pressed):
			SignalBus.popup_nofi.OK.connect(on_exit_button_pressed, CONNECT_ONE_SHOT)
		return
	if not AdsManager.ads_dismissed_full_screen.is_connected(on_exit_button_pressed):
		AdsManager.ads_dismissed_full_screen.connect(on_exit_button_pressed, CONNECT_ONE_SHOT)
	if not AdsManager.reward_ads_earn_reward.is_connected(_on_reward_ads_earned_reward):
		AdsManager.reward_ads_earn_reward.connect(_on_reward_ads_earned_reward, CONNECT_ONE_SHOT)


func _on_reward_ads_earned_reward():
	if AdsManager.ads_dismissed_full_screen.is_connected(on_exit_button_pressed):
		AdsManager.ads_dismissed_full_screen.disconnect(on_exit_button_pressed)
	if not AdsManager.ads_dismissed_full_screen.is_connected(on_rejoin_button_pressed):
		AdsManager.ads_dismissed_full_screen.connect(on_rejoin_button_pressed, CONNECT_ONE_SHOT)

func on_exit_button_pressed():
	exit_scene_popup_menu()
	await tween_exit_finish
	game_play.game_over.emit()
