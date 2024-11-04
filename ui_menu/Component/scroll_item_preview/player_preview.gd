class_name PreviewPlayer extends CenterContainer

@export var item_ID: int
@export var auto_change_color: bool = true
@export_range(1, 15) var body_color: int

@onready var base_player: BasePlayer = %BasePlayer
@onready var hold_node_2d: Control = %HoldNode2D

func _ready() -> void:
	base_player.stop.emit()
	set_eye_skin_by_item_ID()
	set_body_color(body_color)


func _on_timer_timeout() -> void:
	if auto_change_color:
		set_body_color()

func set_eye_skin_by_item_ID(ID: int = -1):
	if ID >= 0:
		item_ID = ID
	base_player.set_eye_skin(item_ID)

func set_body_color(color: int = 0):
	if color > 0 and color < GlobalConfig.Color_set.size():
		body_color = color
		auto_change_color = false
	else:
		body_color = randi_range(1, 10)
		auto_change_color = true
	base_player.set_body_color(body_color)

var press_down_time : int = 0
var press_down_pos : Vector2 = Vector2()
signal clicked(x: PreviewPlayer)

func _on_event_input_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				press_down_time = Time.get_ticks_msec()
				press_down_pos = event.global_position
			else:
				if Time.get_ticks_msec() - press_down_time < 750:
					if (event.global_position - press_down_pos).length() < 25:
						clicked.emit(self)
