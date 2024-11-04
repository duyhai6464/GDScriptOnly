class_name BasePlayer extends Node2D

signal moving
signal stop
signal exploding
signal finish_explode
signal eating
signal finish_eat

@onready var player_physics: Node2D = %PlayerPhysics
@onready var body := %Body as AnimatedSprite2D
@onready var eye := %Eye as AnimatedSprite2D
@onready var light_eye: PointLight2D = %LightEye

@onready var particles: Node2D = %Particles
@onready var death_player := %ParticlesDeathPlayer as GPUParticles2D
@onready var player_eating := %ParticlesPlayerEating as GPUParticles2D

@onready var visible_on_screen_notifier_2d := %VisibleOnScreenNotifier2D as VisibleOnScreenNotifier2D
@onready var player_visual: Node2D = %PlayerVisual

var is_eating: bool = false

func _ready():
	moving.connect(func ():
		player_physics.visible = true
		body.animation = 'moving'
		if is_eating:
			player_eating.emitting = true
	)
	stop.connect(func ():
		player_physics.visible = true
		body.animation = 'idle'
		if is_eating:
			player_eating.emitting = false
	)
	exploding.connect(func ():
		player_physics.visible = false
		death_player.emitting = true
		await death_player.finished
		finish_explode.emit()
	)
	eye.animation_finished.connect(func ():
		var end = randf() > 0.5
		var speed = randf_range(0.7, 1.5) * (-1 if end else 1)
		eye.play('default', speed, end)
	)
	eating.connect(func ():
		is_eating = true
		player_eating.emitting = true
	)
	finish_eat.connect(func ():
		is_eating = false
		player_eating.emitting = false
	)

	visible_on_screen_notifier_2d.screen_entered.connect(player_visual.show)
	visible_on_screen_notifier_2d.screen_exited.connect(player_visual.hide)

func set_body_color(color_id: int):
	if body != null:
		body.modulate = GlobalConfig.Color_set[color_id]
	if particles != null:
		particles.modulate = GlobalConfig.Color_set[color_id]
	if light_eye != null:
		light_eye.color = GlobalConfig.Color_set[color_id]

func set_eye_skin(skin_id: int):
	if eye != null:
		eye.sprite_frames = GlobalConfig.eye_skins.get(skin_id, GlobalConfig.eye_skins[0])
		eye.play()
		if not light_energy.get(skin_id, 0):
			light_eye.energy = 0
		else:
			light_eye.energy = abs(light_energy[skin_id])
			light_eye.blend_mode = Light2D.BLEND_MODE_ADD if light_energy[skin_id] > 0 else Light2D.BLEND_MODE_SUB

		if not light_offset.get(skin_id):
			light_eye.offset.y = 0
		else:
			light_eye.offset.y = light_offset[skin_id]
const light_energy := {
	1:-0.25,
	3:-0.5,
	4:1.25,
	5:1,
	6:1,
	7:0.75,
	8:-0.25,
	9:1,
	10:-0.25,
	11:-0.5,
	13:-0.75,
	14:0.5,
	15:0.75,
}
const light_offset := {
	2:6,
	8:6,
	9:-5,
	13:6,
	14:-5,
}
