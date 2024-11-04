class_name Grid extends TileMapLayer

const expand_speed: int = 10
@export var size_grid: int = 50
@onready var expanding_animation = %ExpandingAnimation
@onready var path_expand : TileMapLayer = %PathExpand
const EXPANDING_ANIMATED = preload("res://land/expanding_animated.tscn")
var icolor : Dictionary = {}
var color_count : Dictionary = {}

var expand_color : Dictionary = {}
var excolor_count : Dictionary = {}

signal color_removed_from_grid(removed_color_id, by_color_id)
signal cross_path_expand(from_color_id, to_color_id)

static func random_type_square(type_cell: int):
	match type_cell:
		-1:
			return 6 + randi() % 2
		0, 3, 4:
			return randi() % 10
		1:
			return randi() % 9
		2:
			return randi() % 8
	return 8 + randi() % 2

func _ready():
	var color_count_0 := color_count.get_or_add(0, {}) as Dictionary
	for row in range(size_grid):
		for col in range(size_grid):
			var coords = Vector2i(row, col)
			icolor[coords] = 0
			set_square(coords, 0, 0)
			color_count_0[coords] = 1

	for l in range(25):
		for row in range(-1 - l, size_grid + l + 1):
			if l < 2:
				set_square(Vector2i(row, -1 - l), 0, l % 2 - 2)
				set_square(Vector2i(row, size_grid + l), 0, -l % 2 - 1)
			else:
				set_square(Vector2i(row, -1 - l), 0, 0)
				set_square(Vector2i(row, size_grid + l), 0, 0)
		for col in range(-l, size_grid + l):
			if l < 2:
				set_square(Vector2i(-1 - l, col), 0, l % 2 - 2)
				set_square(Vector2i(size_grid + l, col), 0, -l % 2 - 1)
			else:
				set_square(Vector2i(-1 - l, col), 0, 0)
				set_square(Vector2i(size_grid + l, col), 0, 0)

	for i in range(1 << 3):
		fill_queue_expanding_animated()

func clear_color(color_id: int):
	var count_color_dict := color_count.get_or_add(color_id, {}) as Dictionary
	for coords in count_color_dict.keys():
		fade_animated_cell(coords, color_id)
		break_animated_cell(coords)

func set_square(coords: Vector2i, color_id: int, type_cell: int=1):
	if color_id > 0:
		set_cell(coords, 0, Vector2(Grid.random_type_square(type_cell), type_cell), color_id)
	else:
		set_cell(coords, 0, Vector2(Grid.random_type_square(type_cell), 0), 0)


func set_expand_line(expand_line: Array, color_id: int):
	path_expand.set_cells_terrain_path(expand_line, 0, color_id)
	for i in range(1, expand_line.size() - 1):
		var coords := expand_line[i] as Vector2i
		var old_color: int = expand_color.get(coords, 0)
		expand_color[coords] = color_id
		#var old_color_count = excolor_count.get_or_add(old_color, {}) as Dictionary
		#old_color_count.erase(coords)
		var new_color_count = excolor_count.get_or_add(color_id, {}) as Dictionary
		new_color_count[coords] = 1
		if old_color != 0:
			cross_path_expand.emit(old_color, color_id)
			print('why?')



func del_expand_line(color_id : int):
	var ex_count = excolor_count.get_or_add(color_id, {}) as Dictionary
	for coords in ex_count.keys():
		if ex_count[coords] != 1:
			continue
		path_expand.erase_cell(coords)
		if expand_color.get(coords, -1) == color_id:
			expand_color.erase(coords)
		ex_count.erase(coords)

func del_expand_line_by_list(expand_line: Array):
	for coords in expand_line:
		path_expand.erase_cell(coords)
		var color_id = expand_color.get(coords, -1)
		if color_id != -1:
			expand_color.erase(coords)
			var ex_count = excolor_count.get_or_add(color_id, {}) as Dictionary
			ex_count.erase(coords)


func fade_expand_line(color_id: int):
	var ex_count = excolor_count.get_or_add(color_id, {}) as Dictionary
	for coords in ex_count:
		if ex_count[coords] != 1:
			continue
		fade_animated_cell(coords, color_id)


func get_zone(topleft: Vector2i, botright: Vector2i) -> Dictionary:
	var zone = {}
	for x in range(topleft.x - 1, botright.x + 2):
		for y in range(topleft.y - 1, botright.y + 2):
			var coords = Vector2i(x, y)
			zone[coords] = icolor.get(coords, -1)
	return zone

func get_spawns() -> Dictionary:
	var spawns: Dictionary = {}
	for x in range(1, size_grid - 1):
		spawns[Vector2i(x, 1)] = 1
		spawns[Vector2i(x, size_grid - 2)] = 1
	for y in range(1, size_grid - 1):
		spawns[Vector2i(1, y)] = 1
		spawns[Vector2i(size_grid - 2, y)] = 1
	return spawns

func set_animated_cell(coords: Vector2i, type_cell: int, color_id: int, time_factor: float):
	#set_square(coords, color_id, type_cell) #set coords to color_id right away
	var old_color = icolor.get(coords, -1)
	var color_count_old := color_count.get_or_add(old_color, {}) as Dictionary
	color_count_old.erase(coords) # decrease old color count

	if color_count_old.size() == 0:
		color_removed_from_grid.emit(old_color, color_id)
	var color_count_new = color_count.get_or_add(color_id, {}) as Dictionary
	color_count_new[coords] = 1 # increase new color count

	icolor[coords] = color_id
	if time_factor > 0:
		if get_tree() != null:
			await get_tree().create_timer(time_factor / expand_speed).timeout

	queue_action.put([0, [coords, color_id, type_cell]])

func _set_animated(coords: Vector2i, color_id: int, type_cell: int):
	var expanding_animated_cell = queue_expanding_animated.pop() as ExpandingAnimated
	expanding_animated_cell.show()
	expanding_animated_cell.position = coords * tile_set.tile_size
	expanding_animated_cell.play_expanding(color_id)
	expanding_animated_cell.expand_finish.connect(func ():
		set_square(coords, color_id, type_cell)
		if expand_color.get(coords, -1) == -1:
			path_expand.call_deferred('erase_cell', coords)
		expanding_animated_cell.queue_free()
	, CONNECT_ONE_SHOT)

func break_animated_cell(coords: Vector2i):
	var old_color = icolor.get(coords, -1)
	var color_count_old := color_count.get_or_add(old_color, {}) as Dictionary
	color_count_old.erase(coords) # decrease old color count

	var color_count_0 = color_count.get_or_add(0, {}) as Dictionary
	color_count_0[coords] = 1 # increase color 0 count

	icolor[coords] = 0
	set_square(coords, icolor[coords])
	queue_action.put([1, [coords, old_color]])

func _break_animated(coords: Vector2i, color_id: int):
	var expanding_animated_cell = queue_expanding_animated.pop() as ExpandingAnimated
	expanding_animated_cell.show()
	expanding_animated_cell.position = coords * tile_set.tile_size
	expanding_animated_cell.play_breaking(color_id)
	expanding_animated_cell.break_finish.connect(func ():
		expanding_animated_cell.queue_free()
		if expand_color.get(coords, -1) == -1:
			path_expand.call_deferred('erase_cell', coords)
	, CONNECT_ONE_SHOT)

func fade_animated_cell(coords: Vector2i, color_id: int):
	queue_action.put([2, [coords, color_id]])

func _fade_animated(coords: Vector2i, color_id: int):
	var expanding_animated_cell = queue_expanding_animated.pop() as ExpandingAnimated
	expanding_animated_cell.show()
	expanding_animated_cell.position = coords * tile_set.tile_size
	expanding_animated_cell.play_fade(get_cell_atlas_coords(coords), color_id)
	expanding_animated_cell.fade_finish.connect(func ():
		expanding_animated_cell.queue_free()
	, CONNECT_ONE_SHOT)

var queue_expanding_animated = Queue.new(1 << 9)
signal queue_filled

func _process(delta: float) -> void:
	fill_queue_expanding_animated()

func fill_queue_expanding_animated():
	for x in range(1 << 5):
		if queue_expanding_animated.is_full():
			return
		queue_expanding_animated.put(instantiate_expanding_animated())
	queue_filled.emit()

func instantiate_expanding_animated() -> ExpandingAnimated:
	var expanding_animated_cell := EXPANDING_ANIMATED.instantiate() as ExpandingAnimated
	expanding_animation.add_child(expanding_animated_cell)
	expanding_animated_cell.hide()
	return expanding_animated_cell

var queue_action = Queue.new()
func _physics_process(delta: float) -> void:
	while not queue_action.is_empty():
		if not handle_action():
			await queue_filled
			return

func handle_action():
	if queue_expanding_animated.is_empty():
		return false
	var x: Array = queue_action.pop()
	match x[0]:
		0:
			_set_animated.callv(x[1])
		1:
			_break_animated.callv(x[1])
		2:
			_fade_animated.callv(x[1])
	return true
