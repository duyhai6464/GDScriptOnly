class_name PreviewMoneyBox extends CenterContainer

@export_range(0, 3) var item_ID: int = 0
@export var info: String

@onready var hold_box: TextureRect = %HoldBox
@onready var type_box: TextureRect = %TypeBox
@onready var gpu_particles_2d: GPUParticles2D = %GPUParticles2D

var _seed := randi_range(1000, 10000)
var _amount := -1
func get_reward_amount() -> int:
	if _amount != -1:
		return _amount - _seed
	var range_amount = info.split('-', false, 1)
	_amount = weighted_random(int(range_amount[0]), int(range_amount[1])) + _seed
	return _amount

func weighted_random(min, max):
	var rand_value = pow(randf(), 1.6)
	return roundi(lerp(min, max, rand_value))

func _ready() -> void:
	set_item_ID()

func set_item_ID(id: int = -1):
	if id >= 0:
		item_ID = id
	match item_ID:
		0:
			hold_box.texture = preload("res://ui_menu/Component/scroll_item_preview/treasurelock.png")
			type_box.texture = preload("res://game/Game_asset/ingame/money_type_gold.png")
			gpu_particles_2d.modulate = Color('ffd233')
			gpu_particles_2d.emitting = false
		1:
			hold_box.texture = preload("res://ui_menu/Component/scroll_item_preview/treasureunlock.png")
			type_box.texture = preload("res://game/Game_asset/ingame/money_type_gold.png")
			gpu_particles_2d.modulate = Color('ffd233')
			gpu_particles_2d.emitting = true
		2:
			hold_box.texture = preload("res://ui_menu/Component/scroll_item_preview/treasureunlock.png")
			type_box.texture = preload("res://game/Game_asset/ingame/money_type_diamond.png")
			gpu_particles_2d.modulate = Color('4fdcf0')
			gpu_particles_2d.emitting = true
		3:
			hold_box.texture = preload("res://ui_menu/Component/scroll_item_preview/treasurelock.png")
			type_box.texture = preload("res://game/Game_asset/ingame/money_type_gold.png")
			gpu_particles_2d.emitting = false
