extends Button

@export_group('Options', 'options')
@export var options: Array[Texture2D] = []
@export var options_layoutpreset: LayoutPreset = PRESET_CENTER
@export_enum('No', 'Yes') var options_include_empty: int = 0
var select: int = 0:
	set(new_select):
		if new_select != select:
			new_select %= options.size() + 1
			if new_select < 0:
				new_select += options.size() + 1
			if new_select == 0 and not options_include_empty:
				new_select = 1
			match switch_animation:
				0:
					texture_rect.texture = options[new_select - 1] if new_select > 0 else null
				1:
					fade_effect(options[new_select - 1] if new_select > 0 else null)
				2:
					slide_effect(options[new_select - 1] if new_select > 0 else null)
			select = new_select
			select_changed.emit()

signal select_changed
@onready var texture_rect := %TextureRect
@onready var front_texture: TextureRect = %FrontTexture


func _ready():
	texture_rect.set_anchors_preset(options_layoutpreset)
	if options_layoutpreset != PRESET_CENTER:
		texture_rect.offset_right -= 8
		texture_rect.offset_left -= 8

func _on_button_down():
	texture_rect.offset_top += 6

func _on_button_up():
	texture_rect.offset_top -= 6
	select += 1

@export_enum('None', 'Fade', 'Slide') var switch_animation: int

var tween: Tween = null
var fade_duration : float = 0.3
func fade_effect(new_texture: Texture2D):
	if tween:
		tween.kill()
	front_texture.texture = texture_rect.texture
	texture_rect.texture = new_texture

	tween = create_tween().set_parallel()
	tween.tween_property(front_texture, 'self_modulate:a', 0,fade_duration).from(1)
	tween.tween_property(texture_rect, 'self_modulate:a', 1, fade_duration).from(0)
	await tween.finished
	tween = null

func slide_effect(new_texture: Texture2D):
	if tween:
		tween.kill()
	front_texture.texture = texture_rect.texture
	texture_rect.texture = new_texture

	var currunt_pos_x = texture_rect.anchor_left * size.x - texture_rect.size.x / 2
	var delta : float = currunt_pos_x / 2
	front_texture.position.x = currunt_pos_x
	texture_rect.position.x = currunt_pos_x - delta

	front_texture.show()
	tween = create_tween().set_parallel()
	tween.tween_property(texture_rect, 'position:x', delta, fade_duration).as_relative()
	tween.tween_property(texture_rect, 'self_modulate:a', 1, fade_duration).from(0)
	tween.tween_property(front_texture, 'position:x', delta, fade_duration).as_relative()
	tween.tween_property(front_texture, 'self_modulate:a', 0,fade_duration).from(1)
	await tween.finished
	front_texture.hide()
	tween = null
