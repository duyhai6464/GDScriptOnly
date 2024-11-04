class_name AchievementItem extends PanelContainer

@export var name_achievement: String
@export_multiline var info_achievement: String
@export var state_achievement: int
@export var reward: int

@onready var icon_texture: TextureRect = %IconTexture
@onready var name_label: Label = %NameLabel
@onready var process_label: Label = %ProcessLabel
@onready var dot_state: TextureRect = %DotState
@onready var info_label: Label = %InfoLabel
@onready var reward_container: MarginContainer = %RewardContainer
@onready var reward_label: Label = %RewardLabel

func set_name_achievement(name: String):
	name_achievement = name
	name_label.text = ' ' + tr(name)

func set_info_achievement(info: String):
	info_achievement = info
	info_label.text = ' ' + tr(info)

func set_state_achievement(state: int):
	state_achievement = state
	match state:
		1:
			dot_state.texture = preload("res://game/Game_asset/achievement/dot_red.png")
			set_info_achievement(info_achievement)
			reward_label.text = str(reward)
			reward_container.show()
		2:
			dot_state.texture = preload("res://game/Game_asset/achievement/dot_green.png")
			set_name_achievement(name_achievement)
			set_info_achievement(info_achievement)
			reward_container.hide()
		_:
			dot_state.texture = null
			reward_container.hide()


var press_down_pos : Vector2 = Vector2()
signal clicked
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				press_down_pos = event.global_position
			elif(event.global_position - press_down_pos).length() < 25:
				clicked.emit()
