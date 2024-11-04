extends PanelContainer
@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var random_color: TextureRect = %RandomColor

var list_color_texture: Array[TextureRect] = []

signal selected(Item_ID: int)

func _ready() -> void:
	list_color_texture.append(random_color)
	for cid in range(1, GlobalConfig.Color_set.size()):
		var color_texture = TextureRect.new()
		color_texture.texture = preload('res://player/player.png')
		color_texture.modulate = GlobalConfig.Color_set[cid]
		color_texture.expand_mode = random_color.expand_mode
		color_texture.custom_minimum_size = random_color.custom_minimum_size

		list_color_texture.append(color_texture)
		h_box_container.add_child(color_texture)

var press_down_time : int = 0
var press_down_pos : Vector2 = Vector2()

func _on_h_box_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				press_down_time = Time.get_ticks_msec()
				press_down_pos = event.global_position
			else:
				if Time.get_ticks_msec() - press_down_time < 750:
					if (event.global_position - press_down_pos).length() < 25:
						for cid in range(list_color_texture.size()):
							if list_color_texture[cid].get_global_rect().has_point(event.global_position):
								selected.emit(cid)

func set_scroll_vertical(sv: int):
	%ScrollContainer.scroll_vertical = sv
