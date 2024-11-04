extends CenterContainer

@onready var texture_button = %TextureButton
@onready var connection_error = %ConnectionError
@onready var ads_label = %AdsLabel

@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal earned_reward

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#animation_player.play('show_up')

func weighted_random(min, max):
	var rand_value = pow(randf(), 1.6)
	return roundi(lerp(min, max, rand_value))

var bonus_percent: int = weighted_random(75, 150)
func _ready():
	connection_error.hide()
	AdsManager.reward_ads_earn_reward.connect(_on_reward_ads_earned_reward, CONNECT_ONE_SHOT)
	var trans_text := tr(ads_label.text)
	ads_label.set_text(trans_text % bonus_percent)

func _on_ads_label_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			texture_button.pressed.emit()


func _on_texture_button_pressed():
	if texture_button.disabled:
		return
	if not AdsManager.show_reward_ads():
		connection_error.show()
	else:
		connection_error.hide()

func _on_reward_ads_earned_reward():
	print("on_user_earned_reward, rewarded_item_after_play")
	earned_reward.emit()
	texture_button.disabled = true
	connection_error.hide()

func play(show_up: bool):
	if animation_player.is_playing():
		return
	if show_up:
		if not isshowup:
			animation_player.play('show_up')
		isshowup = true
	else:
		if isshowup:
			animation_player.play('fade_in')
		isshowup = false

signal show_up_finished
signal fade_in_finished
var isshowup = false
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		'show_up':
			show_up_finished.emit()
		'fade_in':
			fade_in_finished.emit()
