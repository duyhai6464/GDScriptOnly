extends CenterContainer
@export_range(1, 10) var color_ID: int = 1
@export_range(1, 3) var item_ID: int = 1
@export var auto_play: bool = false
@export var loop: bool = true

@onready var expanding_scene: ExpandingAnimated = %Expanding_scene
@onready var nine_patch_rect: NinePatchRect = %NinePatchRect

signal play_finish

func _ready() -> void:
	expanding_scene.hide()
	play_finish.connect(play)
	if auto_play:
		play()

func play():
	set_nine_patch_rect(0, Grid.random_type_square(0))
	expanding_scene.show()
	expanding_scene.play_expanding(color_ID)
	await expanding_scene.expand_finish
	expanding_scene.hide()
	set_nine_patch_rect(item_ID, Grid.random_type_square(item_ID))
	await get_tree().create_timer(1).timeout
	if loop:
		play_finish.emit()

func set_nine_patch_rect(row: int, col: int):
	nine_patch_rect.region_rect.position = Vector2(64 * col, 64 * row)
	if row > 0:
		nine_patch_rect.modulate = GlobalConfig.Color_set[color_ID]
	else:
		nine_patch_rect.modulate = GlobalConfig.Color_set[0]
