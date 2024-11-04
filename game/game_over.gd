class_name GameoverScene extends PanelContainer

@export var player: Player

@onready var table: VBoxContainer = %Table
@onready var table_info: VBoxContainer = %TableInfo
@onready var bonus_container: MarginContainer = %BonusContainer

@onready var money_texture_diamond := %MoneyTextureDiamond
@onready var money_texture_gold := %MoneyTextureGold
@onready var watch_video_button := %WatchVideoButton

@onready var play_again_button: Button = %PlayAgainButton
@onready var continue_button: Button = %ContinueButton
@onready var back_home_button: Button = %BackHomeButton

@onready var savedgame = GlobalConfig.savedgame as SavedGame
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const OVER_INFO = preload("res://ui_menu/Component/over_info.tscn")
const COIN = preload("res://game/Game_asset/ingame/coin.png")
const SQUARE = preload("res://game/Game_asset/ingame/square.png")
const PERCENT = preload("res://game/Game_asset/ingame/percent.png")
const DEATH_SKULL = preload("res://game/Game_asset/ingame/death_skull.png")
const DEATH_SKULL_STREAK = preload("res://game/Game_asset/ingame/death_skull_streak.png")
const BOUNTY_SKULL = preload("res://game/Game_asset/ingame/bounty_skull.png")
const LETTER_P = preload("res://game/Game_asset/ingame/letter_p.png")

var info_items_list: Dictionary = {}
#region var
var total_gold_earn: int = 0:
	set(gold):
		total_gold_earn = gold
		total_changed.emit()
var score_player: int = 0:
	set(score):
		score_player = score
		score_player_changed.emit()
var total_kills: int = 0:
	set(kill):
		total_kills = kill
		total_kills_changed.emit()
var consecutive_kills: int = 0:
	set(kills):
		if kills != consecutive_kills and kills > 1:
			consecutive_kills = kills
			consecutive_kills_changed.emit()
var bounty_received: int = 0:
	set(bounty):
		bounty_received = bounty
		bounty_received_changed.emit()
var captured_areas: int = 0:
	set(area):
		captured_areas = area
		captured_areas_changed.emit()
var last_captured_areas: int = 0:
	set(area):
		last_captured_areas = area
		last_captured_areas_changed.emit()
var occupied_land: int = 0:
	set(land):
		occupied_land = land
		occupied_land_changed.emit()
var play_time: int = 0:
	set(time):
		play_time = time
		play_time_changed.emit()
var rank_player: int = 16:
	set(rank):
		if rank != rank_player:
			rank_player = rank
			rank_player_changed.emit()
var bonus_money: int = 0:
	set(money):
		bonus_money = money
		bonus_money_changed.emit()

signal score_player_changed
signal total_kills_changed
signal consecutive_kills_changed
signal bounty_received_changed
signal captured_areas_changed
signal last_captured_areas_changed
signal occupied_land_changed
signal play_time_changed
signal rank_player_changed
signal bonus_money_changed
signal total_changed
#endregion

signal play
signal quit

func _ready():
	get_tree().paused = true
	continue_button.disabled = true
	continue_button.disabled = true
	continue_button.disabled = true

	money_texture_diamond.value = savedgame.get_d_coin()
	money_texture_gold.value = savedgame.get_g_coin()
	savedgame.g_coinChanged.connect(func (): money_texture_gold.value = savedgame.get_g_coin())

#region connect var
	score_player_changed.connect(_on_score_player_changed, CONNECT_ONE_SHOT)
	total_kills_changed.connect(_on_total_kills_changed, CONNECT_ONE_SHOT)
	consecutive_kills_changed.connect(_on_consecutive_kills_changed, CONNECT_ONE_SHOT)
	bounty_received_changed.connect(_on_bounty_received_changed, CONNECT_ONE_SHOT)
	captured_areas_changed.connect(_on_captured_areas_changed, CONNECT_ONE_SHOT)
	last_captured_areas_changed.connect(_on_last_captured_areas_changed, CONNECT_ONE_SHOT)
	occupied_land_changed.connect(_on_occupied_land_changed, CONNECT_ONE_SHOT)
	play_time_changed.connect(_on_play_time_changed, CONNECT_ONE_SHOT)
	rank_player_changed.connect(_on_rank_player_changed, CONNECT_ONE_SHOT)
	bonus_money_changed.connect(_on_bonus_money_changed, CONNECT_ONE_SHOT)
	total_changed.connect(_on_total_changed, CONNECT_ONE_SHOT)
#endregion

	watch_video_button.fade_in_finished.connect(info_showing, CONNECT_ONE_SHOT)
	animation_player.play('show_up')
	total_gold_earn = calculate()
	await get_tree().create_timer(0.45).timeout
	continue_button.disabled = false
	info_showing()

#region _on_var_changed
func _exit_tree():
	get_tree().paused = false
func _on_score_player_changed():
	add_info('_score_player_', score_player, table, LETTER_P)
func _on_total_kills_changed():
	add_info('_total_kills_', total_kills, table, DEATH_SKULL)
func _on_consecutive_kills_changed():
	add_info('_consecutive_kills_', consecutive_kills, table, DEATH_SKULL_STREAK)
func _on_bounty_received_changed():
	add_info('_bounty_received_', bounty_received, table, BOUNTY_SKULL)
func _on_captured_areas_changed():
	add_info('_captured_areas_', captured_areas, table, SQUARE)
func _on_last_captured_areas_changed():
	add_info('_last_captured_areas_', last_captured_areas, table, PERCENT)
func _on_occupied_land_changed():
	add_info('_occupied_land_', occupied_land, table, SQUARE)
func _on_play_time_changed():
	add_info('_play_time_', play_time, table).label_value.type = 'Timer'
func _on_rank_player_changed():
	add_info('_rank_player_', rank_player, table, null, 11)
func _on_bonus_money_changed():
	add_info('_bonus_earn_', bonus_money, bonus_container, COIN)
func _on_total_changed():
	add_info('_gold_earn_', total_gold_earn, table_info, COIN)
#endregion


func _on_play_again_button_pressed():
	play.emit()
	animation_player.play('fade_in')
	print('_on_play_again_button_pressed')
	call_deferred('queue_free')

func _on_back_home_button_pressed():
	quit.emit()
	animation_player.play('fade_in')
	print('_on_back_home_button_pressed')
	call_deferred('queue_free')

func _on_continue_button_pressed():
	if continue_button.disabled:
		return
	continue_button.disabled = true
	savedgame.add_g_coin(total_gold_earn + bonus_money)
	bonus_money = 0
	savedgame.save()
	watch_video_button.play(false)
	animation_player.play('continue')
	await get_tree().create_timer(0.5).timeout
	play_again_button.disabled = false
	back_home_button.disabled = false


func _on_watch_video_button_earned_reward():
	bonus_money = total_gold_earn * watch_video_button.bonus_percent / 100
	watch_video_button.play(false)


func add_info(name: String, value: int, parent: Control, default_post_texture: Texture2D = null, default_value: int = 0):
	var over_infoline := OVER_INFO.instantiate() as OverInfoline
	over_infoline.info_name = name
	over_infoline.info_value = value
	over_infoline.info_default_value = default_value
	over_infoline.post_texture = default_post_texture
	var info_lines := info_items_list.get_or_add(parent.name, {}) as Dictionary
	info_lines[name] = over_infoline
	parent.add_child(over_infoline)
	return over_infoline

func info_showing():
	if info_items_list.is_empty():
		return
	var key := info_items_list.keys()[0] as StringName
	var info_lines := info_items_list.get(key, {}) as Dictionary
	info_items_list.erase(key)
	for n in info_lines:
		var over_infoline := info_lines[n] as OverInfoline
		over_infoline.play()
		await get_tree().create_timer(0.3).timeout

func calculate():
	if player == null:
		return 0
	var player_data_game = player.data as data_player
	match GlobalConfig.current_game_mode:
		GlobalConfig.GameMode.BOUNTY_HUNTER:
			total_kills = player_data_game.total_kill
			consecutive_kills = player_data_game.consecutive_kills
			bounty_received = player_data_game.bounty
			captured_areas = player_data_game.areas
			score_player = player_data_game.score
			rank_player = player_data_game.rank
			SignalBus.new_score_record.emit('b', score_player)
			SignalBus.new_achievement_stack.emit('_god_killer_', consecutive_kills)
			SignalBus.new_achievement_stack.emit('_old_hunter_',
				savedgame.achievements.get_or_add('_old_hunter_', 0) + 1)

		GlobalConfig.GameMode.SURVIVAL:
			captured_areas = player_data_game.areas
			last_captured_areas = player_data_game.last_zone.aspect() * 100
			total_kills = player_data_game.total_kill
			score_player = player_data_game.score
			rank_player = player_data_game.rank
			SignalBus.new_score_record.emit('s', score_player)
			SignalBus.new_achievement_stack.emit('_map_owner_', last_captured_areas)
			SignalBus.new_achievement_stack.emit('_old_survival_',
				savedgame.achievements.get_or_add('_old_survival_', 0) + 1)

		GlobalConfig.GameMode.NORMAL:
			total_kills = player_data_game.total_kill
			captured_areas = player_data_game.areas
			occupied_land = player_data_game.occupied
			play_time = player_data_game.time_passed
			score_player = player_data_game.score
			SignalBus.new_score_record.emit('f', score_player)
			SignalBus.new_achievement_stack.emit('_10K_point_free_', score_player)
			SignalBus.new_achievement_stack.emit('_old_free_',
				savedgame.achievements.get_or_add('_old_free_', 0) + play_time / 60)

	var score_pass = savedgame.stat_best_score.values().filter(func (x): return x >= 1000)
	SignalBus.new_achievement_stack.emit('_3_game_3_mode_', score_pass.size())

	var gold: int = score_player / 3
	savedgame.stat_moneys += gold
	savedgame.stat_kills += player_data_game.total_kill
	savedgame.stat_zones += player_data_game.areas
	savedgame.stat_death += player_data_game.death_count
	return gold

@export var separation: float:
	set(sep):
		separation = sep
		table.add_theme_constant_override('separation', separation)
