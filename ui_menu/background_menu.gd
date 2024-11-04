extends CanvasLayer

var players: Array[Player] = []
var bot_controllers: Array[Bot_controller] = []
const PLAYER = preload("res://player/player.tscn")

@onready var grid_map = %Grid
@onready var camera_2d = %Camera2D

var cam_state = 0
var cam_offset_x = 450
var cam_offset_y = 300
var tween_duration = 15

signal cam_tween_finish

func _ready():
	#for ci in range(1, 2):
	for ci in range(1, 16):
		var player = PLAYER.instantiate() as Player
		player.init(grid_map, ci, randi_range(1, 4), randi_range(0, 15))
		add_player_to_scene(player)
		var controller = Bot_controller.new(player)
		bot_controllers.append(controller)
		player.ui_player.call_deferred('hide')
		player.ui_player.process_mode = Node.PROCESS_MODE_DISABLED

	for player in players:
		player.end_expanding.connect(func(cell_list: Dictionary):
			for player_2 in players:
				if player == player_2:
					continue
				if cell_list.get(player_2.cur_square(), 0) > 1:
					player.kill(player_2)
		)

	grid_map.color_removed_from_grid.connect(handled_grid_by_color)
	grid_map.cross_path_expand.connect(handled_grid_by_color)

	handled_camera_movement()
	cam_tween_finish.connect(handled_camera_movement)
	SignalBus.request_background_color.connect(change_canvas_modulate)

	var timer_for_bot_act_changed: Timer = $TimerForBotActChanged
	set_physics_process(false)
	await get_tree().create_timer(3).timeout
	set_physics_process(true)
	timer_for_bot_act_changed.start()
	for bot_controller in bot_controllers:
		bot_controller.turn_on.emit()
		timer_for_bot_act_changed.timeout.connect(func ():
			if bot_controller.act != 0 and bot_controller.player.action == 0:
				bot_controller.on_act_changed()
	)

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

func _physics_process(delta):
	for player in players:
		if player.death == true and player.respawn_time_remain <= 0:
			player.respawn.emit(get_spawn_point())
	for players_i1 in range(players.size()):
		for players_i2 in range(players_i1 + 1, players.size()):
			var player_1 = players[players_i1]
			var player_2 = players[players_i2]
			var collision = player_1.check_collision(player_2)
			if collision == 1:
				player_1.kill(player_2)
			elif collision == 2:
				player_2.kill(player_1)

func handled_camera_movement():
	match cam_state:
		0:
			var tw = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(camera_2d, 'offset',Vector2(cam_offset_x, -cam_offset_y),
			tween_duration).from(Vector2(-cam_offset_x, -cam_offset_y))
			await tw.finished
			cam_state = 1
			cam_tween_finish.emit()
			tw = null
		1:
			var tw = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(camera_2d, 'offset',Vector2(cam_offset_x, cam_offset_y),
			tween_duration).from(Vector2(cam_offset_x, -cam_offset_y))
			await tw.finished
			tw.kill()
			cam_state = 2
			cam_tween_finish.emit()
			tw = null
		2:
			var tw = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(camera_2d, 'offset',Vector2(-cam_offset_x, cam_offset_y),
			tween_duration).from(Vector2(cam_offset_x, cam_offset_y))
			await tw.finished
			tw.kill()
			cam_state = 3
			cam_tween_finish.emit()
			tw = null
		3:
			var tw = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(camera_2d, 'offset',Vector2(-cam_offset_x, -cam_offset_y),
			tween_duration).from(Vector2(-cam_offset_x, cam_offset_y))
			await tw.finished
			cam_state = 0
			cam_tween_finish.emit()
			tw = null

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
	p2.kill(p1)

func _exit_tree():
	for bot_controller in bot_controllers:
		bot_controller = null
	bot_controllers.clear()

var tween: Tween = null
@onready var canvas := %Canvas
func change_canvas_modulate(color: Color, duration: float):
	if tween != null:
		tween.kill()
		tween = null
	tween = create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(canvas, 'color', color, duration)
