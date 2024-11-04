class_name Killfeedinfo extends HBoxContainer

const killfeedicon = [
	preload("res://game/Game_asset/ingame/kill.png"),
	preload("res://game/Game_asset/ingame/rampage.png"),
	preload("res://game/Game_asset/ingame/dominate.png"),
	preload("res://game/Game_asset/ingame/shutdown.png"),
	preload("res://game/Game_asset/ingame/skull.png"),
]

@onready var panel_1 = %Panel1
@onready var panel_2 = %Panel2
@onready var label_1 = %Label1
@onready var label_2 = %Label2
@onready var icon = %Icon

const tween_duration: float = 0.5
var tween: Tween = null
var timeoutamount: float = 3

signal tween_enter_finish
signal tween_exit_finish

func set_kill_info(player_1: Player, player_2: Player, time: int = -1):
	if player_1 != player_2:
		panel_1.show()
		panel_1.self_modulate = GlobalConfig.Color_set[player_1.color_id]
		panel_2.self_modulate = GlobalConfig.Color_set[player_2.color_id]
		label_1.text = player_1.player_name
		label_2.text = player_2.player_name
		if player_1.currunt_kill_threshold < player_2.currunt_kill_threshold and\
		player_1.currunt_square_threshold < player_2.currunt_square_threshold:
			icon.texture = killfeedicon[3]
			timeoutamount = 4.5
		elif player_1.currunt_kill_threshold >= 3:
			icon.texture = killfeedicon[2]
			timeoutamount = 6
		elif player_1.currunt_kill_threshold >= 1:
			icon.texture = killfeedicon[1]
			timeoutamount = 4.5
		else:
			icon.texture = killfeedicon[0]
	else:
		panel_1.hide()
		icon.texture = killfeedicon[4]
		panel_2.self_modulate = GlobalConfig.Color_set[player_2.color_id]
		label_2.text = player_2.player_name


func enter_scene():
	if tween != null:
		return
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_parallel()
	position.x += 150
	tween.tween_property(self, "position:x", -150, tween_duration).as_relative()
	tween.tween_property(self, "modulate", Color.WHITE, tween_duration).from(Color8(1500, 1500, 1550))
	await tween.finished
	tween = null
	tween_enter_finish.emit()

func exit_scene():
	if tween != null:
		return
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_parallel()
	position.x -= 100
	tween.tween_property(self, "position:x", 150, tween_duration).as_relative()
	tween.tween_property(self, "modulate", Color8(0, 0, 0, 32), tween_duration).from(Color.WHITE)
	await tween.finished
	tween = null
	tween_exit_finish.emit()
	call_deferred('queue_free')

func _ready() -> void:
	modulate.a = 0

func play():
	enter_scene()
	await tween_enter_finish
	await get_tree().create_timer(timeoutamount).timeout
	exit_scene()
