class_name PopupConf extends CanvasLayer

@onready var confirm_label := %ConfirmLabel
@onready var hold_panel: Control = %HoldPanel
@onready var buttons: HBoxContainer = %Buttons

@export var confirm_text: String = 'confirm text'

signal OK
signal CANCEL

signal tween_exit_finish
signal tween_enter_finish

const tween_duration: float = 0.25
var tween: Tween = null

@onready var ao_top: float = hold_panel.offset_top
@onready var ao_bottom: float = hold_panel.offset_bottom
@onready var ao_size: float = hold_panel.size.y / 2

func _ready() -> void:
	hide()

func set_confirm_text(text: String):
	confirm_text = text
	var confirm_label_text = '[center]' + tr(confirm_text)
	if confirm_label_text != confirm_label.text:
		confirm_label.text = confirm_label_text

func popup_enter():
	if tween != null:
		return
	set_confirm_text(confirm_text)
	show()
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(hold_panel, "offset_top", ao_top, tween_duration).from(ao_top + ao_size)
	tween.tween_property(hold_panel, "offset_bottom", ao_bottom, tween_duration).from(ao_bottom - ao_size)
	tween.tween_property(hold_panel, "modulate:a", 1, tween_duration).from(0.5)
	tween.tween_property(confirm_label, "modulate", Color.WHITE, 3 * tween_duration / 4).from(
		Color8(1500, 1500, 1550)).set_delay(tween_duration / 4)
	tween.tween_property(buttons, 'modulate', Color.WHITE, tween_duration).from(
		Color8(1500, 1500, 1550))
	await tween.finished
	tween = null
	tween_enter_finish.emit()

func popup_exit():
	if tween != null:
		return
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_parallel()
	tween.tween_property(hold_panel, "offset_top", ao_top + ao_size, tween_duration).from(ao_top)
	tween.tween_property(hold_panel, "offset_bottom", ao_bottom - ao_size, tween_duration).from(ao_bottom)
	tween.tween_property(hold_panel, "modulate:a", 0.5, tween_duration).from(1)
	tween.tween_property(confirm_label, "modulate", Color.BLACK, tween_duration).from(Color.WHITE)
	await tween.finished
	hide()
	tween = null
	tween_exit_finish.emit()

func _on_no_button_pressed() -> void:
	popup_exit()
	await tween_exit_finish
	CANCEL.emit()


func _on_yes_button_pressed() -> void:
	popup_exit()
	await tween_exit_finish
	OK.emit()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			_on_no_button_pressed()
