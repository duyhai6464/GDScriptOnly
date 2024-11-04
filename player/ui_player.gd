class_name UIplayer extends Control

@export var img_size : int = 64
@export var font_size : int = 26

@onready var ui: VBoxContainer = %UI
@onready var icon_container: HBoxContainer = %IconContainer
@onready var label: Label = %Label

@onready var coin_hold: TextureRect = %CoinHold
@onready var killer_hold: TextureRect = %KillerHold
@onready var death_hold: TextureRect = %DeathHold

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D

var player_name: String = '':
	set(name):
		if name != player_name:
			player_name = name
			label.text = player_name

func _ready() -> void:
	visible_on_screen_notifier_2d.screen_entered.connect(ui.show)
	visible_on_screen_notifier_2d.screen_exited.connect(ui.hide)
	label.label_settings.font_size = font_size
	icon_container.custom_minimum_size.y = img_size
	coin_hold.hide()
	killer_hold.hide()
	death_hold.hide()
	#position = Vector2(300, 500)
	#await get_tree().create_timer(0.5).timeout
	#set_texture(coin_hold, icon_coin[1])
	#await get_tree().create_timer(0.5).timeout
	#set_texture(killer_hold, icon_killer[1])
	#await get_tree().create_timer(0.5).timeout
	#set_texture(death_hold, icon_death[1])
	#await get_tree().create_timer(0.5).timeout
	#set_texture(coin_hold, icon_coin[2])
	#await get_tree().create_timer(0.5).timeout
	#set_texture(killer_hold, null)


const icon_coin := [
	preload("res://game/Game_asset/ingame/coin_0.png"),
	preload("res://game/Game_asset/ingame/coin_1.png"),
	preload("res://game/Game_asset/ingame/coin_2.png"),
	preload("res://game/Game_asset/ingame/coin_3.png"),
	preload("res://game/Game_asset/ingame/coin_4.png"),
]
const icon_killer := [
	preload("res://game/Game_asset/ingame/killer_0.png"),
	preload("res://game/Game_asset/ingame/killer_1.png"),
	preload("res://game/Game_asset/ingame/killer_2.png"),
	preload("res://game/Game_asset/ingame/killer_3.png"),
]
const icon_death := [
	preload("res://game/Game_asset/ingame/rip.png"),
	preload("res://game/Game_asset/ingame/ripwings.png"),
]

func set_icon_coin(id: int):
	if id < 0 or id >= icon_coin.size():
		set_texture(coin_hold, null)
	else:
		set_texture(coin_hold, icon_coin[id])

func set_icon_killer(id: int):
	if id < 0 or id >= icon_killer.size():
		set_texture(killer_hold, null)
	else:
		set_texture(killer_hold, icon_killer[id])

func set_icon_death(id: int):
	match id:
		0:
			set_icon_coin(-1)
			set_icon_killer(-1)
			set_texture(death_hold, icon_death[0])
		1:
			set_icon_coin(-1)
			set_icon_killer(-1)
			set_texture(death_hold, icon_death[1])
		_:
			set_texture(death_hold, null)


func set_texture(root : TextureRect, image: Texture2D):
	var ttr_from = root.get_child(0) as TextureRect
	var ttr_to = root.get_child(1) as TextureRect
	ttr_from.texture = ttr_to.texture
	ttr_to.texture = image
	if ttr_from.texture != null:
		fade_out(ttr_from)
	if ttr_to.texture != null:
		root.show()
		fade_in(ttr_to)
	else:
		if not fade_out_finish.is_connected(root.hide):
			fade_out_finish.connect(root.hide, CONNECT_ONE_SHOT)


signal fade_in_finish
signal fade_out_finish
const tween_duration: float = 0.5
const fade_delta: float = 48

func fade_in(tr: TextureRect):
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_parallel()
	tr.position.y = -fade_delta
	tween.tween_property(tr, 'position:y', fade_delta, tween_duration).as_relative()
	tween.tween_property(tr, 'modulate:a', 1, tween_duration).from(0)
	await tween.finished
	fade_in_finish.emit()

func fade_out(tr: TextureRect):
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_parallel()
	tr.position.y = 0
	tween.tween_property(tr, 'position:y', fade_delta, tween_duration).as_relative()
	tween.tween_property(tr, 'modulate:a', 0, tween_duration).from(1)
	await tween.finished
	fade_out_finish.emit()
