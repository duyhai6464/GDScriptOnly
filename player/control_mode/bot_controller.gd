class_name Bot_controller

var player: Player = null
var target: int = 0
var act: int = 0:
	set(a):
		if a != act:
			act = a
			act_changed.emit()
var state: int = 0
var clockwise: int = 1
var offsets: Array[int] = [0, 0, 0, 0]
var available: bool = false

signal act_changed
signal turn_on
signal turn_off

var target_direction: Vector2i = Vector2i.ONE
var step_range: int = 1
var smart_speed_up: int = 0

func _init(p: Player):
	player = p
	target_direction = p.grid.get_used_rect().get_center()
	player.square_changed.connect(square_change_control_next)
	act_changed.connect(on_act_changed)
	turn_off.connect(func ():
		available = false
		clockwise = 0
		act = 0
		target = 0
		offsets.fill(0)
	)
	turn_on.connect(func ():
		smart_speed_up = randi() % 3
		available = true
		step_range = randi_range(1, 3)
		clockwise = randi() % 2 * 2 - 1
		act = randi() % 4 + 1
		state = 0
		target = random_target(0, player.cur_square())
		offsets[0] = target
	)
	player.die.connect(on_player_die)
	player.respawn.connect(on_player_respawn)

func on_player_respawn(spawn_point):
	if spawn_point != null:
		turn_on.emit()

func on_player_die():
	turn_off.emit()
	#print('player', player.color_id, 'death')
	if player.was_kill_by == player:
		print('bot dump ', GlobalConfig.Color_names[player.color_id])

func on_act_changed():
	var result_act = 0
	match act:
		1:
			result_act = player.set_action_move_right()
		2:
			result_act = player.set_action_move_down()
		3:
			result_act = player.set_action_move_left()
		4:
			result_act = player.set_action_move_up()
	if act != result_act:
		state += 3
		act = (act + 1 + clockwise) % 4 + 1
		target = random_target(offsets[(state + 2) % 4], player.cur_square())
		offsets[state % 4] = target
	match smart_speed_up:
		0:# speed up all the time
			player.set_speed_up(true)
		2:# low speed all the time
			player.set_speed_up(true)
		#1: speed up while expanding

func square_change_control_next(from: Vector2i, to: Vector2i):
	if not available or from == null or to == null:
		return
	target -= 1
	if target <= 0:
		var ofs = 0
		if player.expanding > 0:
			state += 1
			ofs = offsets[(state + 2) % 4]
		else:
			state = 0
			offsets.fill(0)
			#clockwise = randi() % 2 * 2 - 1
		act = (act + 3 + clockwise) % 4 + 1
		target = random_target(ofs, to)
		offsets[state % 4] = target
		if state == 0 and randf() > 1 - 0.08 * step_range:
			step_range = randi_range(1, 2)
	if smart_speed_up == 1:
		player.set_speed_up(player.expanding > 0)

func random_target(min_step: int , from: Vector2i) -> int:
	var direction := Vector2i(player.action_2_dir[act])
	if direction.length() <= 0:
		return 1
	var temp := (target_direction - from) * direction
	var rand_step := randi_range(0, step_range) + clampi((temp.x + temp.y) / 11, 0, 10)
	var next_step := 1 + min_step + clampi(rand_step, 0, 10)
	var next_target := direction * next_step + from
	var clamp_target := next_target.clamp(Vector2i.ZERO, (player.board_size - Vector2i.ONE))
	if next_target != clamp_target:
		var path := clamp_target - from
		if player.action_2_dir[act].x == 0:
			next_step = path.y / player.action_2_dir[act].y
		else:
			next_step = path.x / player.action_2_dir[act].x
	#print(from, 'go', next_step, 'action', act)
	return next_step
