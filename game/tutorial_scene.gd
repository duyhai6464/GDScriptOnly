extends Node

@onready var gameplay: MainGame = %Gameplay
@onready var hand: TextureRect = %Hand
@onready var swipe_detector := %SwipeDetector

@onready var savedgame = GlobalConfig.savedgame as SavedGame

var tween: Tween = null
var duration: float = 0.7

enum State{START, GOLEFT, TURN, FINISH1, FINISH2}
var state: int = 0
const _help_text_list_: Array[String] = [
	'_help_text_1_',
	'_help_text_2_',
	'_help_text_3_',
	'_help_text_4_',
	'_help_text_5_',
]
var path_to_scene: String = "res://ui_menu/Main_menu.tscn"

func _ready() -> void:
	gameplay.main_player.respawn.emit(gameplay.grid_map.get_used_rect().get_center())
	gameplay.main_player.square_changed.connect(main_player_change_square)
	gameplay.main_player.end_expanding.connect(main_player_end_expand)
	gameplay.main_player.die.connect(main_player_die)

	for bc: Bot_controller in gameplay.bot_controllers:
		bc.turn_off.emit()
		bc.player.player_name = 'BOT_%03d' % randi_range(1, 999)
		bc.player.set_process(false)
	gameplay.set_physics_process(false)
	GlobalConfig.current_game_mode = GlobalConfig.GameMode.SURVIVAL
	set_process(false)
	swipe_detector.position = get_viewport().get_visible_rect().size / 2
	await get_tree().create_timer(0.9).timeout
	text_in(_help_text_list_[state])
	%VirtualHandTimer.start()

func swipe_virtual_hand(left_right: int, top_down: int):
	if tween != null:
		return
	tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT).set_parallel()
	if left_right != 0:
		tween.tween_property(hand, 'anchor_left',
		0.5 + signi(left_right) * 0.3, duration).from(0.5 - signi(left_right) * 0.3)
	else :
		hand.anchor_left = 0.6
	if top_down != 0:
		tween.tween_property(hand, "anchor_top",
		0.5 + signi(top_down) * 0.2, duration).from(0.5 - signi(top_down) * 0.2)
	else:
		hand.anchor_top = 0.6
	tween.tween_property(hand, 'modulate:a', 0.6, duration).from(0.9)
	tween.tween_callback(func ():
		hand.modulate.a = 0
		tween = null
	)

func _on_skip_button_pressed() -> void:
	SignalBus.request_scene.emit(path_to_scene)
	savedgame.skip_tutorial = true
	savedgame.save()
	text_out()
	await text_out_finish
	gameplay.game_over.emit()
	SignalBus.request_popup_nofi.emit(20, '_tutorial_finish_')
	if not SignalBus.popup_nofi.OK.is_connected(_on_popup_nofi_ok):
		SignalBus.popup_nofi.OK.connect(_on_popup_nofi_ok, CONNECT_ONE_SHOT)

func _on_popup_nofi_ok() -> void:
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(gameplay, 'modulate', Color8(96, 96, 96), 0.5)
	await get_tree().create_timer(0.47).timeout
	SignalBus.wait_load_scene.emit(path_to_scene)

func _on_timer_timeout() -> void:
	match state:
		State.START:
			if gameplay.main_player.input_action != 1:
				swipe_virtual_hand(1, 0)
		State.GOLEFT:
			if gameplay.main_player.input_action != 2:
				swipe_virtual_hand(0, 1)


func _on_swipe_detector_swipe(action: String) -> void:
	match state:
		State.START:
			if action != 'Move_right':
				return
			parse_input_action(action)
			await get_tree().create_timer(0.5).timeout
			text_out()
		State.GOLEFT:
			if action != 'Move_down':
				return
			parse_input_action(action)
			await get_tree().create_timer(0.5).timeout
			text_out()
			hand.modulate.a = 0
		_:
			parse_input_action(action)

func parse_input_action(action):
	var _event = InputEventAction.new()
	_event.action = action
	_event.pressed = true
	Input.parse_input_event(_event)

@onready var help_text: Label = %HelpText
signal text_in_finish
signal text_out_finish
func text_in(text: String, pos_side: Vector2i = Vector2i(-1, -1)):
	swipe_detector._start()
	swipe_detector.timer.stop()
	gameplay.main_player.input_action = 0
	if tween != null:
		tween.kill()
	help_text.anchor_left = 0.1 + signi(pos_side.x) * 0.05
	help_text.anchor_right = help_text.anchor_left + 0.8
	help_text.anchor_top = 0.4 + signi(pos_side.y) * 0.2
	help_text.anchor_bottom = help_text.anchor_top
	help_text.text = text
	help_text.modulate.a = 1
	swipe_detector.timer.stop()
	tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN_OUT).set_parallel()
	tween.tween_property(help_text, 'modulate', Color.GHOST_WHITE, 0.5).from(Color8(1500, 1500, 1550))
	tween.tween_property(help_text, 'visible_ratio', 1, 0.2).from(0.4)
	await tween.finished
	text_in_finish.emit()
	tween = null

func text_out():
	if tween != null:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN_OUT).set_parallel()
	tween.tween_property(help_text, 'modulate', Color.BLACK, 0.5).from(Color.GHOST_WHITE)
	tween.tween_property(help_text, 'modulate:a', 0, 0.5).from(1)
	await tween.finished
	text_out_finish.emit()
	tween = null

var step: int = 0
func main_player_change_square(from: Vector2i, to: Vector2i):
	match state:
		State.START:
			step += 1
			if step >= 5:
				state += 1
				text_in(_help_text_list_[state])
		State.GOLEFT:
			step -= 1
			if step <= 0:
				state += 1
				text_in(_help_text_list_[state])

var test_bot: Bot_controller = null
func main_player_end_expand(fill_cell_list: Dictionary):
	if state == State.TURN:
		text_out()

		test_bot = gameplay.bot_controllers.pick_random() as Bot_controller
		test_bot.player.respawn.disconnect(test_bot.on_player_respawn)
		test_bot.player.die.connect(bot_player_die, CONNECT_ONE_SHOT)
		var player_square := gameplay.main_player.cur_square()
		test_bot.player.respawn.emit(player_square - Vector2i(0, 4))

		await text_out_finish
		state += 1
		text_in(_help_text_list_[state], Vector2i(1, 1))

const _help_text_player_die_: Array[String] = [
	"_help_text_player_die_1_",
	"_help_text_player_die_2_",
]
var die_2: int = 0
func main_player_die():
	text_out()
	await text_out_finish
	text_in(_help_text_player_die_[die_2], Vector2i(1, -1))
	die_2 = 1
	gameplay.main_player.respawn.emit(gameplay.grid_map.get_used_rect().get_center())
	await get_tree().create_timer(5-die_2).timeout
	if state < State.FINISH1:
		state = State.START
		text_out()
		await text_out_finish
		text_in(_help_text_list_[state])
	else:
		text_out()
		await text_out_finish
		text_in(_help_text_list_[state])

func bot_player_die():
	text_out()

	test_bot.player.die.connect(_on_skip_button_pressed, CONNECT_ONE_SHOT)
	var player_square := gameplay.main_player.cur_square()
	test_bot.player.respawn.emit(player_square - Vector2i(4, 7))
	test_bot.player.ready_2_play.time_left = 0
	test_bot.player.input_action = 1
	test_bot.player.set_process(true)

	await text_out_finish
	state += 1
	text_in(_help_text_list_[state], Vector2i(1, 1))
