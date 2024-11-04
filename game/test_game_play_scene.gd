extends Node

@onready var gameplay: MainGame = %Gameplay
@onready var tool_box: VBoxContainer = %ToolBox
@onready var camera: Camera_player = %camera

enum Tools{CAMERA, DRAW, MOVE, SUMMON}
var in_set_up_mode : bool = false:
	set(isum):
		if isum != in_set_up_mode:
			in_set_up_mode = isum
			if isum:
				show_set_up()
			else:
				hide_set_up()
var color_select_id: int
var tool: Tools = Tools.CAMERA

func show_set_up():
	tool_box.show()
	camera.enabled = true
	if gameplay.main_camera.target != null and gameplay.main_camera.target.enabled:
		gameplay.main_camera.target.enabled = false
		camera.global_position = gameplay.main_camera.target.global_position
	else:
		gameplay.main_camera.enabled = false
		camera.global_position = gameplay.main_camera.global_position
	get_tree().paused = true

func hide_set_up():
	tool_box.hide()
	if gameplay.main_camera.target != null and not gameplay.main_camera.target.enabled:
		gameplay.main_camera.target.enabled = true
	else:
		gameplay.main_camera.enabled = true
	tool = Tools.CAMERA
	camera.enabled = false
	get_tree().paused = false

var color_to_player: Dictionary = {}
func _ready() -> void:
	for player in gameplay.players:
		color_to_player[player.color_id] = player
	gameplay.main_player.base_player.set_eye_skin(4)
	gameplay.main_player.type_square = 3
	gameplay.main_player.respawn.emit(gameplay.main_player.cur_square())
	GlobalMusic.play()
	#await get_tree().create_timer(3).timeout
	#in_set_up_mode = true


var pressed_pos := Vector2()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Accept"):
		in_set_up_mode = not in_set_up_mode
	if not in_set_up_mode:
		return
	if event is InputEventMouseButton:
		pressed_pos = event.position if event.pressed else Vector2.ZERO
		return
	if pressed_pos == Vector2.ZERO:
		return
	if event is InputEventMouseMotion:
		match tool:
			Tools.CAMERA:
				if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
					camera.position -= event.relative
					cam_vel = Vector2.ZERO
				else:
					cam_vel = event.position - pressed_pos
			Tools.DRAW:
				var click_to_game := camera.get_global_mouse_position()
				var coords := gameplay.grid_map.local_to_map(click_to_game)
				if gameplay.grid_map.icolor[coords] != color_select_id:
					if color_select_id > 0:
						gameplay.grid_map.set_animated_cell(coords, color_select_id, (
							color_to_player[color_select_id] as Player).type_square, 0)
					else:
						gameplay.grid_map.break_animated_cell(coords)
				if event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
					cam_vel = event.position - pressed_pos
			Tools.MOVE:
				if color_select_id not in color_to_player:
					return
			Tools.SUMMON:
				if color_select_id not in color_to_player:
					return
				var click_to_game := camera.get_global_mouse_position()
				var coords := gameplay.grid_map.local_to_map(click_to_game)
				var player := color_to_player[color_select_id] as Player
				if coords != Vector2i(player.cur_position(0)) / player.square_size:
					player.respawn_player_to_grid(coords)

var cam_vel := Vector2()
func _process(delta: float) -> void:
	match tool:
		Tools.CAMERA, Tools.DRAW:
			if pressed_pos == Vector2.ZERO:
				return
			camera.position += cam_vel * delta

func _on_list_scroll_color_player_selected(Item_ID: int) -> void:
	color_select_id = Item_ID


func _on_button_pressed() -> void:
	tool = Tools.DRAW


func _on_button_2_pressed() -> void:
	tool = Tools.MOVE


func _on_button_3_pressed() -> void:
	tool = Tools.SUMMON


func _on_button_4_pressed() -> void:
	tool = Tools.CAMERA
