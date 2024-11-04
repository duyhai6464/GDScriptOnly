class_name Player extends Node2D

const vel_speed: int = 190
const vel_speed_up: int = 300
const action_2_dir: Array[Vector2] = [
	#idle right down left up
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(-1, 0),
	Vector2(0, -1),
]
const dir_2_action: Dictionary = {
	Vector2(0, 0): 0,
	Vector2(1, 0): 1,
	Vector2(0, 1): 2,
	Vector2(-1, 0): 3,
	Vector2(0, -1): 4,
}

var square_size: Vector2i = Vector2.ONE
var board_size: Vector2i = Vector2.ONE
var color_id: int = 1
var type_square: int = 1
var type_eye: int = 0

var speed_up: bool = false
var input_action: int = 0
var action: int = 0: set = _set_action
var direction: Vector2i = Vector2i.ZERO
var expanding: float = 0
var expand_line: Array[Vector2i] = []
var eating: int = 0
var death: bool = true: set = _set_death
var kill_count: int = 0
var square_count: int = 0

var respawn_time_remain: float = 0
var was_kill_by: Player = null
var player_name: String = '':
	set(name):
		if name != player_name:
			player_name = name
			ui_player.player_name = name

func _set_action(act: int) -> void:
	action = clampi(act, 0, 5) % 5
	direction = action_2_dir[action]

func _set_death(_death: bool):
	if death != _death:
		death = _death
		if death == true:
			respawn_time_remain = 10
			expanding = 0
			kill_count = 0
			if was_kill_by == null:
				was_kill_by = self
			ui_player.set_icon_death(randi() % 2)
			grid.fade_expand_line(color_id)
			_change_expand_line(false)
			expand_line.clear()
			if eating > 0:
				base_player.finish_eat.emit()
			die.emit()
			base_player.exploding.emit()
			data.death_count += 1
		else:
			input_action = 0
			action = 0
			was_kill_by = null
			base_player.stop.emit()
			ui_player.set_icon_death(-1)

var ready_2_play: SceneTreeTimer = null
var grid: Grid = null
var data: data_player = data_player.new()

@onready var base_player: BasePlayer = $BasePlayer as BasePlayer
@onready var camera_player: Camera_player = $camera_player as Camera_player
@onready var ui_player: UIplayer = $UI_player as UIplayer
@onready var rect: Sprite2D = $Rect

signal start_eating
signal end_expanding(cell_list: Dictionary)
signal die
signal respawn(spawn_point: Vector2i)
signal square_changed(from: Vector2i, to: Vector2i)
signal end_occupy(cell_list: Dictionary)

var id_task_expanding: int = -1
var id_task_square_change: int = -1

func init(g: Grid, c: int, s: int, e: int):
	grid = g
	color_id = c
	type_square = s
	type_eye = e
	board_size = Vector2i(g.size_grid, g.size_grid)
	square_size = g.tile_set.tile_size

func _ready():
	base_player.set_eye_skin(type_eye)
	base_player.set_body_color(color_id)

	respawn.connect(respawn_player_to_grid)
	end_expanding.connect(end_expand_zone)
	end_occupy.connect(end_occupy_zone)

func respawn_player_to_grid(spawn_point: Vector2i):
	ready_2_play = get_tree().create_timer(1)
	death = false
	position = square_size * spawn_point
	for drow in range(3):
		for dcol in range(3):
			grid.call_deferred('set_animated_cell', spawn_point + Vector2i(dcol - 1, drow - 1),
			type_square, color_id, 2 * (abs(drow - 1) + abs(dcol - 1) + 1))
			#grid.set_animated_cell(spawn_point + Vector2i(dcol - 1, drow - 1),
			#type_square, color_id, 2 * (abs(drow - 1) + abs(dcol - 1) + 1))

func cur_position(action: int) -> Vector2:
	if action == 1:
		return (position + Vector2(square_size.x - 1, square_size.y / 2))
	if action == 2:
		return (position + Vector2(square_size.x / 2, square_size.y - 2))
	if action == 3:
		return (position + Vector2(1, square_size.y / 2))
	if action == 4:
		return (position + Vector2(square_size.x / 2, -1))
	return position + Vector2(square_size / 2)

func cur_square() -> Vector2i:
	return Vector2i(cur_position(action)) / square_size

func set_action_move_right():
	if expanding and action == 3:
		return input_action
	if cur_square().x != board_size.x - 1:
		if not expanding and action == 3:
			input_action = 0
		else:
			input_action = 1
	return input_action

func set_action_move_down():
	if expanding and action == 4:
		return input_action
	if cur_square().y != board_size.y - 1:
		if not expanding and action == 4:
			input_action = 0
		else:
			input_action = 2
	return input_action

func set_action_move_left():
	if expanding and action == 1:
		return input_action
	if cur_square().x != 0:
		if not expanding and action == 1:
			input_action = 0
		else:
			input_action = 3
	return input_action

func set_action_move_up():
	if expanding and action == 2:
		return input_action
	if cur_square().y != 0:
		if expanding and action == 2:
			input_action = 0
		else:
			input_action = 4
	return input_action

#func _physics_process(delta):
	#pass

func set_speed_up(su: bool):
	if su != speed_up:
		speed_up = su

func _process(delta):
	if death:
		respawn_time_remain -= delta
		return
	if ready_2_play.time_left > 0:
		return
	var square = cur_square()
	# check player in center square or not?
	var dtemp = square * square_size - Vector2i(position)
	if abs(dtemp.x) < 28 and abs(dtemp.y) < 28:
		if action != input_action:
			base_player.moving.emit()
		action = input_action
		if action == 0:
			base_player.stop.emit()

	if action % 2 or action == 0:
		if position.y != square.y * square_size.y:
			var dy = (1 if position.y < square.y * square_size.y else -1)
			if abs(position.y - square.y * square_size.y) <= abs(dy):
				position.y = square.y * square_size.y
			else:
				position.y += dy
	if action % 2 == 0:
		if position.x != square.x * square_size.x:
			var dx = (1 if position.x < square.x * square_size.x else -1)
			if abs(position.x - square.x * square_size.x) <= abs(dx):
				position.x = square.x * square_size.x
			else:
				position.x += dx

	position += (vel_speed_up if speed_up else vel_speed) * direction * delta

	var clamp_pos = position.clamp(Vector2.ZERO, (board_size - Vector2i.ONE) * square_size)
	if clamp_pos != position and action > 0:
		base_player.stop.emit()
	position = clamp_pos

	if expanding > 0:
		expanding += delta
	var new_square = cur_square()
	if new_square != square:
		square_changed.emit(square, new_square)
		var ge = grid.expand_color.get(new_square, -1)
		if ge != -1:
			if ge == color_id:
				kill(self)
				return
			grid.cross_path_expand.emit(ge, color_id)
		if id_task_square_change != -1 and not WorkerThreadPool.is_task_completed(id_task_square_change):
			WorkerThreadPool.wait_for_task_completion(id_task_square_change)
		id_task_square_change = WorkerThreadPool.add_task(square_change_fromto.bind(square, new_square))


func square_change_fromto(from: Vector2i, to: Vector2i):
	var ls = grid.icolor.get(from, -1) == color_id
	var cs = grid.icolor.get(to, -1) == color_id
	if ls and not cs:
		expand_line.append(from)
		expand_line.append(to)
	elif not ls and not cs:
		expanding += 10
		expand_line.append(to)
		call_deferred('_change_expand_line', true)
	elif not ls and cs:
		if id_task_expanding != -1 and not WorkerThreadPool.is_task_completed(id_task_expanding):
			WorkerThreadPool.wait_for_task_completion(id_task_expanding)
		id_task_expanding = WorkerThreadPool.add_task(expand_zone.bind(expand_line.duplicate()), true)
	else:
		grid.path_expand.erase_cell(from)
	if cs:
		expanding = 0
		if expand_line.size() > 0:
			call_deferred('_change_expand_line', false)
		expand_line.clear()

		if eating > 0:
			base_player.call_deferred('emit_signal', 'finish_eat')
		eating = 0
	else:
		expanding += 1
		if eating == 0:
			base_player.call_deferred('emit_signal', 'eating')
		eating += 1
		call_deferred('emit_signal', 'start_eating')

func _change_expand_line(set_expand: bool):
	if set_expand:
		if death or expand_line.size() < 3:
			return
		grid.set_expand_line([expand_line[-3], expand_line[-2], expand_line[-1]], color_id)
	else:
		grid.del_expand_line_by_list(expand_line)
		grid.del_expand_line(color_id)

func expand_zone(line: Array[Vector2i]):
	var minx = grid.size_grid + 10
	var miny = grid.size_grid + 10
	var maxx = -10
	var maxy = -10
	for xy in line:
		minx = mini(minx, xy.x)
		miny = mini(miny, xy.y)
		maxx = maxi(maxx, xy.x)
		maxy = maxi(maxy, xy.y)
	for xy in grid.color_count.get_or_add(0, {}) as Dictionary:
		minx = mini(minx, xy.x)
		miny = mini(miny, xy.y)
		maxx = maxi(maxx, xy.x)
		maxy = maxi(maxy, xy.y)
	#var minx = 0
	#var miny = 0
	#var maxx = grid.size_grid - 1
	#var maxy = grid.size_grid - 1
	var zone = grid.get_zone(Vector2i(minx, miny), Vector2i(maxx, maxy))
	# add expand line to zone
	for i in range(1, line.size()):
		zone[line[i]] = color_id

	var visited: Dictionary = {}
	var queue = Queue.new()
	queue.put(Vector2i(minx - 1, miny - 1))
	visited[Vector2i(minx - 1, miny - 1)] = 1
	while not queue.is_empty():
		var xy = queue.pop()
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var new_xy = xy + dir
			if new_xy.x < minx - 1 or new_xy.x > maxx + 1:
				continue
			if new_xy.y < miny - 1 or new_xy.y > maxy + 1:
				continue
			if zone[new_xy] != color_id and not visited.has(new_xy):
				queue.put(new_xy)
				visited[new_xy] = 1

	var need_2_fill: Dictionary = {}

	for x in range(minx, maxx + 1):
		for y in range(miny, maxy + 1):
			var coords = Vector2i(x, y)
			if zone[coords] != color_id and not visited.has(coords):
				need_2_fill[coords] = 0

	for i in range(1, line.size()):
		queue.put(line[i])
		need_2_fill[line[i]] = 1

	while not queue.is_empty():
		var xy = queue.pop()
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var new_xy = xy + dir
			if new_xy.x < minx or new_xy.x > maxx:
				continue
			if new_xy.y < miny or new_xy.y > maxy:
				continue
			if need_2_fill.get(new_xy, -1) == 0:
				queue.put(new_xy)
				need_2_fill[new_xy] = need_2_fill[xy] + 1

	queue = null
	if is_instance_valid(self):
		call_deferred('emit_signal', 'end_expanding', need_2_fill)

func end_expand_zone(need_2_fill: Dictionary):
	for xy in need_2_fill:
		grid.set_animated_cell(xy, type_square, color_id, need_2_fill[xy])
	data.areas += need_2_fill.size()

func end_occupy_zone(need_2_fill: Dictionary):
	data.occupied += need_2_fill.size()
	end_expand_zone(need_2_fill)

func check_collision(player_2: Player) -> int:
	if death or player_2.death:
		return 0
	var p1_rect := rect.get_rect()
	p1_rect.position += position
	var p2_rect := player_2.rect.get_rect()
	p2_rect.position += player_2.position
	var p := p1_rect.intersection(p2_rect)
	if p.has_area():
		var coords := Vector2i(p.get_center()) / square_size
		var p_color: int = grid.icolor.get(coords, -1)
		if p_color == color_id:
			return 1
		if p_color == player_2.color_id:
			return 2
		return 1 if expanding < player_2.expanding else 2
	return 0

func occupy(player_2: Player):
	var player2_squares = grid.color_count.get_or_add(player_2.color_id, {}).keys()
	kill(player_2, false)
	if player2_squares.size() < 9:
		return
	player2_squares.sort_custom(func(a, b):
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x
	)
	var midy = (player2_squares[0].y + player2_squares[-1].y) / 2
	var need_2_fill: Dictionary = {}
	for coords in player2_squares:
		need_2_fill[coords] = midy - player2_squares[0].y - abs(midy - coords.y)
	end_occupy.emit(need_2_fill)

func kill(player_2: Player, clear_color: bool = true):
	if player_2.death:
		return
	if self != player_2:
		set_threshold(kill_count + 1, 'kill')
		data.total_kill += 1
		data.consecutive_kills = max(data.consecutive_kills, kill_count)
		data.bounty += 1 + currunt_kill_threshold * 2 + player_2.currunt_square_threshold
	player_2.was_kill_by = self
	player_2.death = true
	if clear_color:
		grid.clear_color(player_2.color_id)

const square_threshold: Array = [100, 200, 350, 600, 1000]
const kill_threshold: Array = [2, 5, 9, 14]
var currunt_square_threshold: int = 0
var currunt_kill_threshold: int = 0

func set_threshold(new: int, type: String):
	match type:
		'square':
			var new_threshold = square_threshold.bsearch(new)
			if currunt_square_threshold != new_threshold:
				ui_player.set_icon_coin(new_threshold - 1)
			square_count = new
			currunt_square_threshold = new_threshold
		'kill':
			var new_threshold = kill_threshold.bsearch(new)
			if currunt_kill_threshold != new_threshold:
				ui_player.set_icon_killer(new_threshold - 1)
			kill_count = new
			currunt_kill_threshold = new_threshold

func get_score(game_mode: GlobalConfig.GameMode) -> int:
	match game_mode:
		GlobalConfig.GameMode.BOUNTY_HUNTER:
			data.score = data.bounty * 50 + data.consecutive_kills * 75 + (
				data.total_kill - data.death_count / 2) * 100 + data.areas
		GlobalConfig.GameMode.SURVIVAL:
			data.score = data.total_kill * 10 + data.last_zone.aspect() * 100 * 140 + (
				data.consecutive_kills + data.bounty) * 5 + data.areas * 1.25
		GlobalConfig.GameMode.NORMAL:
			data.score = data.total_kill * 10 + data.areas + data.occupied + (
				data.consecutive_kills + data.bounty - data.death_count) * 5 + data.time_passed
	data.score = clampi(data.score, 0, 1000 * data.time_passed)
	return data.score
