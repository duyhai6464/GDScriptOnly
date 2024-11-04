class_name OverInfoline extends HBoxContainer

@export var info_name: String
@export var info_value: int
@export var info_default_value: int
@export var post_texture: Texture2D
@export var label_settings: LabelSettings

@onready var label_name: LabelTyping = %LabelName
@onready var label_value: LabelTyping = %LabelValue
@onready var bonus_texture: TextureRect = %BonusTexture

func _ready() -> void:
	if post_texture != null:
		bonus_texture.texture = post_texture
	if label_settings != null:
		label_name.label_settings = label_settings
		label_value.label_settings = label_settings
	bonus_texture.modulate.a = 0
	label_name.text = info_name
	label_value.text = str(info_default_value)
	label_value.from = info_default_value
	label_value.to = info_value


func play() -> void:
	label_name.play()
	label_value.play()
	var tw = create_tween()
	tw.tween_property(bonus_texture, 'modulate:a', 1, 1).from(0)

func set_info_value(value: int):
	info_value = value
	label_value.to = info_value

var press_down_pos : Vector2 = Vector2()
signal clicked
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				press_down_pos = event.global_position
			elif(event.global_position - press_down_pos).length() < 25:
				clicked.emit()
