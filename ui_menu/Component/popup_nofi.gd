class_name PopupNofi extends CanvasLayer

@onready var hold: Control = %Hold
@onready var texture_rect: TextureRect = %TextureRect
@onready var nofi_label: Label = %NofiLabel
@onready var h_box: HBoxContainer = %HBox
@onready var button: Button = %Button

@export var nofi_text: String = 'nofi text'
@export var img: Texture2D = null

signal OK

signal tween_exit_finish
signal tween_enter_finish

const tween_duration: float = 0.25
var tween: Tween = null

@onready var ao_top: float = hold.offset_top
@onready var ao_bottom: float = hold.offset_bottom
@onready var ao_size: float = hold.size.y / 2

func popup_enter():
	if tween != null:
		return
	show()
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(hold, "offset_top", ao_top, tween_duration).from(ao_top + ao_size)
	tween.tween_property(hold, "offset_bottom", ao_bottom, tween_duration).from(ao_bottom - ao_size)
	tween.tween_property(hold, "modulate:a", 1, tween_duration).from(0.5)
	tween.tween_property(h_box, "modulate", Color.WHITE, 3 * tween_duration / 4).from(
		Color8(1500, 1500, 1550)).set_delay(tween_duration / 4)
	tween.tween_property(button, "modulate", Color.WHITE, tween_duration).from(
		Color8(1500, 1500, 1550))
	await tween.finished
	tween = null
	tween_enter_finish.emit()

func popup_exit():
	if tween != null:
		return
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_parallel()
	tween.tween_property(hold, "offset_top", ao_top + ao_size, tween_duration).from(ao_top)
	tween.tween_property(hold, "offset_bottom", ao_bottom - ao_size, tween_duration).from(ao_bottom)
	tween.tween_property(hold, "modulate:a", 0.5, tween_duration).from(1)
	tween.tween_property(h_box, "modulate", Color.BLACK, tween_duration).from(Color.WHITE)
	tween.tween_property(button, "modulate", Color.BLACK, tween_duration).from(Color.WHITE)
	await tween.finished
	hide()
	tween = null
	tween_exit_finish.emit()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			_on_button_pressed()

func _on_button_pressed() -> void:
	popup_exit()
	await tween_exit_finish
	OK.emit()

func _ready() -> void:
	set_nofi_texture(img)
	set_nofi_text(nofi_text)
	hide()

func set_nofi_text(text: String):
	if nofi_label.text == text:
		return
	nofi_label.text = text

func set_nofi_texture(image: Texture2D):
	if image == texture_rect.texture:
		return
	texture_rect.texture = image
	if texture_rect.texture != null:
		texture_rect.show()
	else:
		texture_rect.hide()
