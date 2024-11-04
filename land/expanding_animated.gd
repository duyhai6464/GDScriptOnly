class_name ExpandingAnimated extends Node2D

var tween: Tween = null

@onready var fade_sprite := %Sprite2D as Sprite2D
@onready var asprite := %AnimatedSprite2D as AnimatedSprite2D
@onready var visual: Node2D = %Visual
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D

signal expand_finish
signal break_finish
signal fade_finish

func _ready() -> void:
	visible_on_screen_notifier_2d.screen_entered.connect(visual.show)
	visible_on_screen_notifier_2d.screen_exited.connect(visual.hide)

func play_expanding(color_id: int):
	if tween:
		tween.kill()
	fade_sprite.hide()
	asprite.show()
	modulate = GlobalConfig.Color_set[0]
	asprite.frame = 0
	asprite.play("expanding")
	tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(self, 'modulate', GlobalConfig.Color_set[color_id], 0.5).from_current()
	tween.finished.connect(func (): tween = null, CONNECT_ONE_SHOT)
	await asprite.animation_finished
	expand_finish.emit()


func play_breaking(color_id: int):
	fade_sprite.hide()
	asprite.show()
	modulate = GlobalConfig.Color_set[color_id]
	asprite.frame = 0
	asprite.play("breaking")
	await asprite.animation_finished
	break_finish.emit()

func play_fade(frame_coord: Vector2i, color_id: int):
	if tween:
		tween.kill()
	fade_sprite.show()
	asprite.hide()
	fade_sprite.frame_coords = frame_coord
	modulate = GlobalConfig.Color_set[color_id]
	tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, 'modulate:a', 0, 12).from(0.75)
	await tween.finished
	tween = null
	fade_finish.emit()


func _exit_tree():
	if tween:
		tween.kill()
		tween = null
