class_name DeathScene extends PanelContainer

@onready var rejoin_button: Button = %RejoinButton
@onready var exit_button: Button = %ExitButton

@onready var time_respawn := %TimeRespawn as LabelTyping
@onready var notify_game := %NotifyGame as LabelTyping
@onready var notify_enemy := %NotifyEnemy as LabelTyping

signal rejoin
signal exit

var rejoin_ready: bool = false
var time_respawn_amount: float = 10

func _ready():
	time_respawn.duration = time_respawn_amount
	time_respawn.from = time_respawn_amount
	time_respawn.play()

func play():
	notify_game.play()
	await get_tree().create_timer(0.4).timeout
	notify_enemy.play()

func _on_exit_button_pressed():
	exit.emit()
	call_deferred('queue_free')

func _on_rejoin_button_pressed():
	if rejoin_ready:
		rejoin.emit()
		call_deferred('queue_free')


func _on_time_respawn_play_finished() -> void:
	time_respawn.text = '_ready_'
	rejoin_ready = true
