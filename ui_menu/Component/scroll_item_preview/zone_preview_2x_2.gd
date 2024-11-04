class_name PreviewZone extends GridContainer

@export_range(1, 15) var color_ID: int = 1
@export_range(1, 4) var item_ID: int = 1
@export var auto_change_color: bool = true

@onready var zone_preview := %ZonePreview
@onready var zone_preview_2 := %ZonePreview2
@onready var zone_preview_3 := %ZonePreview3
@onready var zone_preview_4 := %ZonePreview4

func _ready() -> void:
	change_color()
	change_ID()
	zone_preview.play()
	await get_tree().create_timer(0.25).timeout
	zone_preview_3.play()
	await get_tree().create_timer(0.25).timeout
	zone_preview_2.play()
	await get_tree().create_timer(0.25).timeout
	zone_preview_4.play()

func change_color(color: int = 0):
	if color > 0:
		auto_change_color = false
		color_ID = color
	else:
		auto_change_color = true
		color_ID = randi_range(1, 10)
	zone_preview.color_ID = color_ID
	zone_preview_2.color_ID = color_ID
	zone_preview_3.color_ID = color_ID
	zone_preview_4.color_ID = color_ID

func change_ID(ID: int = 0):
	if ID > 0:
		item_ID = ID
	zone_preview.item_ID = item_ID
	zone_preview_2.item_ID = item_ID
	zone_preview_3.item_ID = item_ID
	zone_preview_4.item_ID = item_ID

func _on_timer_timeout() -> void:
	if auto_change_color:
		change_color()



var press_down_time : int = 0
var press_down_pos : Vector2 = Vector2()
signal clicked(x: PreviewZone)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				press_down_time = Time.get_ticks_msec()
				press_down_pos = event.global_position
			else:
				if Time.get_ticks_msec() - press_down_time < 750:
					if (event.global_position - press_down_pos).length() < 25:
						clicked.emit(self)
