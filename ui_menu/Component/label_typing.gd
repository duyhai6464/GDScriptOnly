class_name LabelTyping extends Label

@export var hide_from_beginning: bool = true
@export var auto_start: bool = false
@export_range(0.1, 10) var duration: float = 1
@export var tween_trans : Tween.TransitionType = Tween.TRANS_QUAD
@export var tween_ease : Tween.EaseType = Tween.EASE_OUT_IN
@export_enum('Typing', 'Counting', 'Timer') var type: String = 'Typing'

@export_group('Options')
@export var from: float = -1
@export var to: float = 0

@onready var label_auto_sizer: LabelAutoSizer = $LabelAutoSizer


var tween: Tween = null
signal play_finished


func _ready() -> void:
	match type:
		'Typing':
			visible_ratio = 0
			if hide_from_beginning:
				label_auto_sizer.visible_ratio = 0
		_:
			label_auto_sizer.visible_ratio = 0
			if hide_from_beginning:
				visible_ratio = 0
	if auto_start:
		play()

func play():
	label_auto_sizer.label_settings = label_settings
	match type:
		'Typing':
			label_auto_sizer.visible_ratio = 1
			label_auto_sizer.call_deferred('_check_line_count')
			typing()
		'Counting':
			visible_ratio = 1
			counting(to, from)
		'Timer':
			visible_ratio = 1
			timer_counting(to)

func typing():
	if tween != null:
		return
	label_auto_sizer.horizontal_alignment = horizontal_alignment
	label_auto_sizer.vertical_alignment = vertical_alignment
	label_auto_sizer.text = text
	tween = create_tween().set_trans(tween_trans).set_ease(tween_ease)
	tween.tween_property(label_auto_sizer, 'visible_ratio', 1, duration).from(0)
	await tween.finished
	play_finished.emit()
	tween = null

func counting(to: int, from: int = -1):
	if tween != null:
		return
	from = from if from >= 0 else text.to_int()
	tween = create_tween().set_trans(tween_trans).set_ease(tween_ease)
	tween.tween_method(func (v: int): text = str(v)
	, from, to, duration)
	await tween.finished
	play_finished.emit()
	tween = null

func timer_counting(to: int):
	if tween != null:
		return
	tween = create_tween().set_trans(tween_trans).set_ease(tween_ease)
	tween.tween_method(set_text_time, 0, to, duration)
	await tween.finished
	play_finished.emit()
	tween = null

func set_text_time(v: int):
	text = '%02d:%02d:%02d' % [v / 3600, v / 60 % 60, v % 60]
