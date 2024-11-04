extends TouchScreenButton

@onready var timer: Timer = $SwipeTimer

var start_position := Vector2()
signal swipe(action:String)

func _start():
	start_position = get_global_mouse_position()
	timer.start()

func _end():
	timer.stop()
	timer.timeout.emit()

func _on_swipe_timer_timeout():
	var end_position := get_global_mouse_position()
	var dir := (end_position - start_position)
	if dir.length() < 10:
		return
	var swipe_act = ''
	if abs(dir.x) > abs(dir.y):
		swipe_act = 'Move_right' if dir.x > 0 else 'Move_left'
	else:
		swipe_act = 'Move_down' if dir.y > 0 else 'Move_up'
	swipe.emit(swipe_act)
