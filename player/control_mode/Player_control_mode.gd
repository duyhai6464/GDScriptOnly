extends Node2D

@onready var swipe = %SwipeDetector
@onready var wasd = %WASD
@onready var joystick = %Joystick
@onready var savedgame = GlobalConfig.savedgame as SavedGame

enum Control_Mode {SWIPE, WASD, JOYSTICK}
var control_mode: Control_Mode
var _viewport: Viewport

func set_mode(mode: Control_Mode):
	# turn off currunt control mode
	swipe.visible = false
	wasd.visible = false
	joystick.visible = false
	# turn on new mode
	match mode:
		Control_Mode.SWIPE:
			swipe.visible = true
		Control_Mode.WASD:
			wasd.visible = true
		Control_Mode.JOYSTICK:
			joystick.visible = true
	control_mode = mode

func auto_resize():
	if not _viewport:
		return
	var windowsize = _viewport.get_visible_rect().size
	swipe.position = windowsize / 2
	wasd.position.x = windowsize.x - 350
	joystick.position.x = windowsize.x - 350
	wasd.position.y = 3 * windowsize.y / 4 - 65
	joystick.position.y = 3 * windowsize.y / 4 - 65

func _ready():
	_viewport = get_viewport() as Viewport
	_viewport.size_changed.connect(auto_resize)
	savedgame.inputOptionChanged.connect(func ():
		set_mode(savedgame.inputOption)
	)
	set_mode(savedgame.inputOption)
	auto_resize()

func click_action(action):
	var _event = InputEventAction.new()
	_event.action = action
	_event.pressed = true
	Input.parse_input_event(_event)
