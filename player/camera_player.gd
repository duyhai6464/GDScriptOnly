class_name Camera_player extends Camera2D

var tween: Tween = null
var target: Camera_player = null
var SHAKE_MID : float = 7.5
var SHAKE_HARD : float = 20
var duration_shake : float = 0.75

func target_to(newtarget: Camera_player):
	if tween != null:
		tween.kill()
	if newtarget != null:
		if target != null:
			global_position = target.global_position
			target.enabled = false
		enabled = true
		target = newtarget
		tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, 'global_position', target.global_position, 0.5)
		tween.finished.connect(func ():
			enabled = false
			target.enabled = true
			tween = null
		)


func fall(center :Vector2):
	if tween != null:
		tween.kill()
	if target != null:
		global_position = target.global_position
		target.enabled = false
	enabled = true
	target = null
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var to = (center - global_position)
	if to != Vector2.ZERO:
		to = to.rotated(PI / 45 * (randf() * 2 - 1))
		if to.length() > center.x:
			to = to.normalized() * ((randf() * 1.25 + 1.75) * center.x / 2)
		else:
			to = to.normalized() * ((randf() * 1.25 + 1) * center.x / 2)
	else:
		to = Vector2(1, 0).rotated(randf() * PI) * ((randf() / 2 + 1.75) * center.x / 2)
	tween.tween_property(self, 'global_position', to, 16).as_relative()
	tween.finished.connect(func ():
		enabled = false
		tween = null
		fall(center)
	)


func shake(hard: bool = false):
	var tween_shake = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT_IN)
	tween_shake.tween_method(func (curoffset: float):
		offset.x = curoffset * (1 - randi() % 2 * 2)
		offset.y = curoffset * (1 - randi() % 2 * 2)
	,SHAKE_HARD if hard else SHAKE_MID, 0, duration_shake)
