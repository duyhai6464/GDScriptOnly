class_name PreviewTradeBox extends CenterContainer

@export_range(0, 20) var item_ID: int = 0
@export var info: String

@onready var type_box: TextureRect = %TypeBox
@onready var gpu_particles_2d: GPUParticles2D = %GPUParticles2D

func _ready() -> void:
	set_item_ID()

func set_item_ID(id: int = -1):
	if id >= 0:
		item_ID = id
	match item_ID:
		0:
			type_box.texture = preload("res://ui_menu/Component/scroll_item_preview/atlas_texture_gold_0.tres")
		1:
			type_box.texture = preload("res://ui_menu/Component/scroll_item_preview/atlas_texture_gold_1.tres")
		2:
			type_box.texture = preload("res://ui_menu/Component/scroll_item_preview/atlas_texture_gold_2.tres")

		10:
			type_box.texture = preload("res://ui_menu/Component/scroll_item_preview/atlas_texture_gold_10.tres")
		11:
			type_box.texture = preload("res://ui_menu/Component/scroll_item_preview/atlas_texture_gold_11.tres")
		12:
			type_box.texture = preload("res://ui_menu/Component/scroll_item_preview/atlas_texture_gold_12.tres")

	if item_ID < 10:
		gpu_particles_2d.modulate = Color('ffd233')
	else:
		gpu_particles_2d.modulate = Color('4fdcf0')

func get_reward_type() -> int:
	if 'gold'.is_subsequence_ofn(info):
		return GlobalConfig.TypeMoney.GOLD
	if 'diamond'.is_subsequence_ofn(info):
		return GlobalConfig.TypeMoney.DIAMOND
	return -1

func get_reward_amount() -> int:
	return info.to_int()
