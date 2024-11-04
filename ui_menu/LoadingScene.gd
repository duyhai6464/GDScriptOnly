extends Control

var path: String = "res://ui_menu/Main_menu.tscn"
var process: Array = []

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var logo_container: AspectRatioContainer = %LogoContainer
@onready var light: DirectionalLight2D = %Light

func _ready():
	AdsManager.start()
	SignalBus.request_scene.emit(path)
	var duration = 1.5
	var tween := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT).set_parallel()
	tween.tween_property(logo_container, 'modulate:a', 1, duration * 1.5).from(0)
	#tween.tween_property(logo_container, 'offset_left', -400, duration).from(400)
	tween.tween_property(logo_container, 'offset_top', -350, duration).from(-150)
	tween.tween_property(logo_container, 'offset_bottom', 50, duration).from(-150)
	tween.tween_property(light, 'energy', 1, duration).from(0).set_delay(duration * 0.25)
	await tween.finished
	tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT).set_parallel()
	tween.tween_property(logo_container, 'modulate:a', 0, duration).from(1)
	#tween.tween_property(logo_container, 'offset_right', -400, duration).from(400)
	tween.tween_property(logo_container, 'offset_top', -150, duration).from(-350)
	tween.tween_property(logo_container, 'offset_bottom', -150, duration).from(50)
	await tween.finished
	if not GooglePlayServices.isSignedIn():
		GooglePlayServices.signIn()
	progress_bar.visible = true
	tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(progress_bar, 'value', 99, 5).from(6)
	await tween.finished
	SignalBus.wait_load_scene.emit(path)
