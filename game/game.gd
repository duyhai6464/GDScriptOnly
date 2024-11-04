class_name MainGame extends Node

var players: Array[Player] = []
var bot_controllers: Array[Bot_controller] = []

var game_timer: float
var time_passed: float
const PLAYER = preload("res://player/player.tscn")

@onready var savedgame = GlobalConfig.savedgame as SavedGame
@onready var grid_map := %Grid as Grid
@onready var main_camera := %camera_player as Camera_player
@onready var main_player: Player = PLAYER.instantiate() as Player
@onready var control_layer = %ControlLayer

@onready var timelabel = %Timelabel

@onready var player_dying_sfx = $PlayerDying
@onready var player_expanding_sfx = $PlayerExpanding
@onready var player_killing_sfx = $PlayerKilling
@onready var player_eating_sfx = $PlayerEating

signal player_death(player: Player)
signal game_over
signal main_player_death
signal show_game_over

var players_data: Dictionary = {}

func _ready():
	game_timer = GlobalConfig.Time_per_game[GlobalConfig.current_game_mode]
	var main_player_color_id = savedgame.favourite_color_id if savedgame.favourite_color_id > 0 else randi_range(1, 10)
	main_player.init(grid_map, main_player_color_id, savedgame.square_skin_id, savedgame.eye_skin_id)
	add_player_to_scene(main_player)
	main_player.player_name = savedgame.playerName
	# add more bot
	for ci in range(1, 16):
		if ci != main_player.color_id:
			var bot = PLAYER.instantiate() as Player
			bot.init(grid_map, ci, randi_range(1, 4), randi_range(0, 15))
			add_player_to_scene(bot)
			bot.player_name = GlobalConfig.bot_names.pick_random()
			var controller = Bot_controller.new(bot)
			bot_controllers.append(controller)

	#region main play UI setup
	main_player.die.connect(when_main_player_die)
	main_player.respawn.connect(when_main_player_respawn)
	main_player.end_expanding.connect(when_main_player_expanding)
	main_player.start_eating.connect(func (): player_eating_sfx.play())
	main_camera.target_to(main_player.camera_player)
	#endregion

	#region bot controllers setup
	var timer_for_bot_act_changed = Timer.new()
	control_layer.add_child(timer_for_bot_act_changed)
	timer_for_bot_act_changed.wait_time = 1
	timer_for_bot_act_changed.autostart = true
	timer_for_bot_act_changed.one_shot = false
	for bot_controller in bot_controllers:
		bot_controller.turn_on.emit()
		timer_for_bot_act_changed.timeout.connect(func ():
			if bot_controller.act != 0 and bot_controller.player.action == 0:
				bot_controller.on_act_changed()
	)
	#endregion

	for player in players:
		player.end_expanding.connect(func(cell_list: Dictionary):
			for player_2 in players:
				if player == player_2:
					continue
				if cell_list.get(player_2.cur_square(), 0) > 1:
					player.kill(player_2)
					#handled_player_with_other(player, player_2)
		)
		player.die.connect(func ():
			if player.was_kill_by == null:
				player.was_kill_by = player
			if player.was_kill_by == main_player:
				main_player.camera_player.shake()
				player_killing_sfx.play()
			player_death.emit(player)
		)

	grid_map.color_removed_from_grid.connect(handled_grid_by_color)
	grid_map.cross_path_expand.connect(handled_grid_by_color)
	game_over.connect(_on_game_over)


func add_player_to_scene(player: Player):
	# add player
	players.append(player)
	%Players.add_child(player)
	player.respawn.emit(get_spawn_point())


func get_spawn_point():
	var spawns = []
	var nears = {}
	var dista = 3
	var diste = 1
	# we dont want it collide other player
	for player in players:
		var player_square = player.cur_square()
		for dx in range(-dista, dista + 1):
			for dy in range(-dista, dista + 1):
				nears[player_square + Vector2i(dx, dy)] = 1
		for expand_square in player.expand_line:
			for dx in range(-diste, diste + 1):
				for dy in range(-diste, diste + 1):
					nears[expand_square + Vector2i(dx, dy)] = 1
	# spawn point must be border of grid
	var all_spawn: Array = grid_map.get_spawns().keys()
	for spawn in all_spawn:
		if nears.get(spawn, 0) != 1:
			spawns.append(spawn)
	if spawns.is_empty():
		return all_spawn.pick_random()
	return spawns.pick_random()


func when_main_player_die():
	player_dying_sfx.play()
	if main_player.was_kill_by != null:
		if main_player.was_kill_by != main_player:
			main_camera.target_to(main_player.was_kill_by.camera_player)
		else:
			main_camera.fall(grid_map.get_used_rect().get_center() * grid_map.tile_set.tile_size)
	main_camera.shake(true)
	await main_player.base_player.finish_explode
	main_player_death.emit()


func when_main_player_respawn(spawn_point):
	if spawn_point != null:
		main_camera.target_to(main_player.camera_player)

func when_main_player_expanding(cell_list):
	if cell_list != null:
		player_expanding_sfx.play()


func _input(event):
	if main_player != null and not main_player.death:
		if event.is_action("Move_right"):
			main_player.set_action_move_right()
		if event.is_action("Move_down"):
			main_player.set_action_move_down()
		if event.is_action("Move_left"):
			main_player.set_action_move_left()
		if event.is_action("Move_up"):
			main_player.set_action_move_up()
		if event.is_action("Speed_up"):
			main_player.set_speed_up(event.is_pressed())
		#if event.is_action("Refuse"):
			#game_over.emit()

func _physics_process(delta):
	for player in players:
		if player != main_player and player.death == true and player.respawn_time_remain <= 0:
			player.respawn.emit(get_spawn_point())

func _process(delta):
	for players_i1 in range(players.size()):
		var player_1 = players[players_i1]
		for players_i2 in range(players_i1 + 1, players.size()):
			var player_2 = players[players_i2]
			var collision = player_1.check_collision(player_2)
			if collision == 1:
				handled_player_with_other(player_1, player_2)
			elif collision == 2:
				handled_player_with_other(player_2, player_1)
		player_1.set_threshold(len(grid_map.color_count.get_or_add(player_1.color_id, {})), 'square')

@onready var timer_count: Timer = %TimerCount
func _on_timer_count_timeout():
	if game_timer <= 0: # end time
		timer_count.stop()
		game_over.emit()
		return
	if not main_player.death:
		time_passed += timer_count.wait_time
	if game_timer == INF:# inf time
		return
	game_timer -= timer_count.wait_time
	var time = int(game_timer)
	var space = ' ' if game_timer > int(game_timer) else ':'
	timelabel.text = '%02d%s%02d' % [time / 60, space, time % 60]

func _exit_tree():
	for bot_controller in bot_controllers:
		bot_controller = null
	bot_controllers.clear()

func handled_player_with_other(player_1: Player, player_2: Player):
	match GlobalConfig.current_game_mode:
		GlobalConfig.GameMode.BOUNTY_HUNTER:
			player_1.kill(player_2)
		GlobalConfig.GameMode.SURVIVAL:
			player_1.kill(player_2)
		GlobalConfig.GameMode.NORMAL:
			player_1.occupy(player_2)

func handled_grid_by_color(from_color_id: int, to_color_id: int):
	var p1: Player = null
	var p2: Player = null
	for player in players:
		if player.color_id == from_color_id:
			p1 = player
		if player.color_id == to_color_id:
			p2 = player
	if p1 == null or p2 == null:
		return
	handled_player_with_other(p2, p1)

func _on_game_over():
	var score: Dictionary = {}
	for player in players:
		var data := player.data
		var color_id := player.color_id
		data.time_passed = time_passed
		data.last_zone = Vector2(player.square_count, pow(grid_map.size_grid, 2))
		score[color_id] = player.get_score(GlobalConfig.current_game_mode)
		players_data[color_id] = data

	var sorted_score = score.values().duplicate()
	sorted_score.sort()
	var score_rank_dict: Dictionary = {}
	for i in range(sorted_score.size()):
		if score_rank_dict.has(sorted_score[i]):
			continue
		score_rank_dict[sorted_score[i]] = sorted_score.size() - i
	for color_id in players_data:
		var data := players_data[color_id] as data_player
		data.rank = score_rank_dict.get(data.score, sorted_score.size())
	main_camera.fall(grid_map.get_used_rect().get_center() * grid_map.tile_set.tile_size)
	show_game_over.emit()
